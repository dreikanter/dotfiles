#!/usr/bin/env python3
"""Print primary Codex conversation context for an EOD report."""

from __future__ import annotations

import argparse
import glob
import json
import os
import sqlite3
import sys
from datetime import date
from pathlib import Path


def newest(pattern: str) -> str | None:
    paths = glob.glob(pattern)
    return max(paths, key=os.path.getmtime) if paths else None


def text_content(item_json: str, item_type: str) -> str:
    try:
        item = json.loads(item_json)
    except json.JSONDecodeError:
        return ""

    if item_type == "agentMessage":
        return item.get("text", "")

    parts = item.get("content", [])
    return "\n".join(
        part.get("text", "")
        for part in parts
        if part.get("type") == "text" and part.get("text")
    )


def clipped(value: str, limit: int) -> str:
    value = " ".join(value.split())
    if len(value) <= limit:
        return value
    return value[: limit - 3].rstrip() + "..."


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("target_date", help="local date in YYYY-MM-DD format")
    args = parser.parse_args()

    try:
        date.fromisoformat(args.target_date)
    except ValueError:
        parser.error("target_date must use YYYY-MM-DD format")

    codex_root = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    state_db = newest(str(codex_root / "state_*.sqlite"))
    history_db = newest(str(codex_root / "thread_history_*.sqlite"))
    if not state_db or not history_db:
        print("No readable Codex session databases found.", file=sys.stderr)
        return 0

    # Both databases use WAL, which SQLite cannot open in mode=ro unless the -shm
    # file already exists. Open them read-write and let query_only block writes.
    state = sqlite3.connect(f"file:{state_db}?mode=rw", uri=True)
    state.row_factory = sqlite3.Row
    state.execute("PRAGMA query_only = ON")
    state.execute("ATTACH DATABASE ? AS history", (f"file:{history_db}?mode=rw",))
    threads = state.execute(
        """
        SELECT id, cwd, source, title
        FROM threads
        WHERE source NOT LIKE '{"subagent"%'
          AND id IN (
            SELECT DISTINCT thread_id
            FROM history.thread_items
            WHERE date(created_at_ms / 1000, 'unixepoch', 'localtime') = ?
              AND item_type IN ('userMessage', 'agentMessage')
          )
        ORDER BY created_at_ms
        """,
        (args.target_date,),
    ).fetchall()

    if not threads:
        print(f"No primary Codex sessions found for {args.target_date}.")
        return 0

    print(f"=== CODEX SESSIONS FOR {args.target_date} ===")
    for thread in threads:
        items = state.execute(
            """
            SELECT item_type, item_json, rollout_ordinal
            FROM history.thread_items
            WHERE thread_id = ?
              AND date(created_at_ms / 1000, 'unixepoch', 'localtime') = ?
              AND item_type IN ('userMessage', 'agentMessage')
            ORDER BY rollout_ordinal
            """,
            (thread["id"], args.target_date),
        ).fetchall()

        user_messages: list[str] = []
        final_answers: list[str] = []
        latest_agent = ""
        for item in items:
            value = text_content(item["item_json"], item["item_type"])
            if not value:
                continue
            if item["item_type"] == "userMessage":
                user_messages.append(value)
                continue
            latest_agent = value
            parsed = json.loads(item["item_json"])
            if parsed.get("phase") == "final_answer":
                final_answers.append(value)

        print(f"\n--- SESSION {thread['id']} ---")
        print(f"Workspace: {thread['cwd']}")
        if user_messages:
            print("Requests:")
            for message in user_messages[-4:]:
                print(f"- {clipped(message, 1200)}")

        outcomes = final_answers[-2:] or ([latest_agent] if latest_agent else [])
        if outcomes:
            print("Outcomes:")
            for message in outcomes:
                print(f"- {clipped(message, 2200)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
