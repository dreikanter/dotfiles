#!/usr/bin/env python3
"""Print primary Claude Code conversation context for an EOD report."""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import date, datetime
from pathlib import Path
from typing import Any


GENERATED_USER_PREFIXES = (
    "<task-notification>",
    "<system-reminder>",
    "<command-message>",
    "<local-command",
    "[Image:",
)


def clipped(value: str, limit: int) -> str:
    value = " ".join(value.split())
    if len(value) <= limit:
        return value
    return value[: limit - 3].rstrip() + "..."


def local_date(timestamp: Any) -> date | None:
    if not isinstance(timestamp, str):
        return None

    try:
        parsed = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
    except ValueError:
        return None

    return parsed.astimezone().date()


def content_text(content: Any) -> str:
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""

    return "\n".join(
        part.get("text", "")
        for part in content
        if isinstance(part, dict)
        and part.get("type") == "text"
        and part.get("text")
    )


def human_request(record: dict[str, Any]) -> str:
    message = record.get("message", {})
    content = message.get("content")
    if not isinstance(content, str):
        return ""

    value = content.strip()
    if not value or value.startswith(GENERATED_USER_PREFIXES):
        return ""
    return value


def assistant_text(record: dict[str, Any]) -> str:
    return content_text(record.get("message", {}).get("content")).strip()


def read_session(path: Path, target_date: date) -> dict[str, Any] | None:
    requests: list[str] = []
    final_answers: list[str] = []
    latest_assistant = ""
    workspace = ""
    session_id = path.stem

    try:
        lines = path.open(encoding="utf-8")
    except OSError:
        return None

    with lines:
        for line in lines:
            try:
                record = json.loads(line)
            except (json.JSONDecodeError, UnicodeDecodeError):
                continue

            if record.get("isSidechain") is True:
                continue
            if local_date(record.get("timestamp")) != target_date:
                continue

            record_type = record.get("type")
            if record_type not in {"user", "assistant"}:
                continue

            workspace = record.get("cwd") or workspace
            session_id = record.get("sessionId") or session_id

            if record_type == "user":
                request = human_request(record)
                if request:
                    requests.append(request)
                continue

            response = assistant_text(record)
            if not response:
                continue
            latest_assistant = response
            if record.get("message", {}).get("stop_reason") == "end_turn":
                final_answers.append(response)

    if not requests and not final_answers and not latest_assistant:
        return None

    return {
        "id": session_id,
        "workspace": workspace,
        "requests": requests,
        "outcomes": final_answers[-2:] or ([latest_assistant] if latest_assistant else []),
    }


def project_roots() -> list[Path]:
    """Session directories to scan, default plus CLAUDE_CONFIG_DIR if it differs."""
    roots: list[Path] = []
    configured = os.environ.get("CLAUDE_CONFIG_DIR")
    candidates = [Path.home() / ".claude"]
    if configured:
        candidates.append(Path(configured).expanduser())

    for candidate in candidates:
        projects = candidate / "projects"
        if projects.is_dir() and projects not in roots:
            roots.append(projects)
    return roots


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("target_date", help="local date in YYYY-MM-DD format")
    args = parser.parse_args()

    try:
        target_date = date.fromisoformat(args.target_date)
    except ValueError:
        parser.error("target_date must use YYYY-MM-DD format")

    roots = project_roots()
    if not roots:
        print("No readable Claude session directory found.", file=sys.stderr)
        return 0

    sessions: list[dict[str, Any]] = []
    for path in sorted(p for root in roots for p in root.rglob("*.jsonl")):
        if "subagents" in path.parts:
            continue
        try:
            if datetime.fromtimestamp(path.stat().st_mtime).astimezone().date() < target_date:
                continue
        except OSError:
            continue

        session = read_session(path, target_date)
        if session:
            sessions.append(session)

    if not sessions:
        print(f"No primary Claude sessions found for {args.target_date}.")
        return 0

    print(f"=== CLAUDE SESSIONS FOR {args.target_date} ===")
    for session in sessions:
        print(f"\n--- SESSION {session['id']} ---")
        print(f"Workspace: {session['workspace']}")
        if session["requests"]:
            print("Requests:")
            for message in session["requests"][-4:]:
                print(f"- {clipped(message, 1200)}")
        if session["outcomes"]:
            print("Outcomes:")
            for message in session["outcomes"]:
                print(f"- {clipped(message, 2200)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
