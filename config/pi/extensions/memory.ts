/**
 * Memory Extension — minimal viable agentic memory for pi.
 *
 * Storage layout (under $PI_MEMORY_DIR or ~/.pi/agent/memory/):
 *   MEMORY.md             curated long-term memory (always injected)
 *   daily/YYYY-MM-DD.md   append-only daily log (today + yesterday injected)
 *   notes/<name>.md       on-demand notes (searched, not injected)
 *
 * Tools: memory_write, memory_read, memory_search.
 *
 * Memory is injected as heuristic context: a hint, not ground truth.
 * Prefer current repo state and explicit user instructions when they conflict.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

const MEMORY_DIR =
  process.env.PI_MEMORY_DIR ?? path.join(os.homedir(), ".pi", "agent", "memory");

const LONG_TERM_FILE = "MEMORY.md";
const DAILY_DIR = "daily";
const NOTES_DIR = "notes";

const INJECT_LONG_TERM_MAX = 6_000;
const INJECT_DAILY_MAX = 3_000;
const SEARCH_MAX_HITS = 20;
const SEARCH_SNIPPET_CHARS = 160;
const READ_MAX_BYTES = 200_000;

function ensureDir(dir: string): void {
  fs.mkdirSync(dir, { recursive: true });
}

function todayStamp(d: Date = new Date()): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function yesterdayStamp(): string {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return todayStamp(d);
}

function safeNoteName(name: string): string | null {
  // No path traversal, no slashes, must be a sane stem.
  if (!name || name.includes("/") || name.includes("\\") || name.includes("..")) return null;
  if (!/^[A-Za-z0-9._-]+$/.test(name)) return null;
  return name.endsWith(".md") ? name : `${name}.md`;
}

function readFileTrimmed(file: string, maxBytes: number): { text: string; truncated: boolean } {
  const buf = fs.readFileSync(file);
  if (buf.byteLength <= maxBytes) return { text: buf.toString("utf8"), truncated: false };
  return { text: buf.subarray(0, maxBytes).toString("utf8"), truncated: true };
}

function tail(text: string, maxChars: number): string {
  if (text.length <= maxChars) return text;
  return `…(truncated to last ${maxChars} chars)…\n${text.slice(text.length - maxChars)}`;
}

function middleTruncate(text: string, maxChars: number): string {
  if (text.length <= maxChars) return text;
  const head = Math.floor(maxChars * 0.6);
  const tailLen = maxChars - head - 32;
  return `${text.slice(0, head)}\n…(${text.length - maxChars} chars omitted)…\n${text.slice(text.length - tailLen)}`;
}

function readIfExists(file: string): string | null {
  try {
    return fs.readFileSync(file, "utf8");
  } catch {
    return null;
  }
}

function listFiles(rel: string): string[] {
  const dir = path.join(MEMORY_DIR, rel);
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir, { withFileTypes: true })
    .filter((e) => e.isFile() && e.name.endsWith(".md"))
    .map((e) => e.name)
    .sort();
}

function searchAll(query: string): { path: string; line: number; snippet: string }[] {
  const q = query.toLowerCase();
  const hits: { path: string; line: number; snippet: string }[] = [];
  const roots: { rel: string; recursive: boolean }[] = [
    { rel: "", recursive: false },
    { rel: DAILY_DIR, recursive: false },
    { rel: NOTES_DIR, recursive: true },
  ];
  const visit = (absDir: string, relDir: string, recursive: boolean) => {
    if (!fs.existsSync(absDir)) return;
    for (const e of fs.readdirSync(absDir, { withFileTypes: true })) {
      const abs = path.join(absDir, e.name);
      const rel = relDir ? `${relDir}/${e.name}` : e.name;
      if (e.isDirectory()) {
        if (recursive) visit(abs, rel, recursive);
        continue;
      }
      if (!e.isFile() || !e.name.endsWith(".md")) continue;
      let text: string;
      try {
        text = fs.readFileSync(abs, "utf8");
      } catch {
        continue;
      }
      const lines = text.split("\n");
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().includes(q)) {
          const start = Math.max(0, lines[i].toLowerCase().indexOf(q) - 40);
          const snippet = lines[i].slice(start, start + SEARCH_SNIPPET_CHARS).trim();
          hits.push({ path: rel, line: i + 1, snippet });
          if (hits.length >= SEARCH_MAX_HITS) return;
        }
      }
    }
  };
  for (const r of roots) {
    if (hits.length >= SEARCH_MAX_HITS) break;
    visit(path.join(MEMORY_DIR, r.rel), r.rel, r.recursive);
  }
  return hits;
}

function buildInjection(): string | null {
  ensureDir(MEMORY_DIR);
  ensureDir(path.join(MEMORY_DIR, DAILY_DIR));
  ensureDir(path.join(MEMORY_DIR, NOTES_DIR));

  const longTerm = readIfExists(path.join(MEMORY_DIR, LONG_TERM_FILE));
  const today = readIfExists(path.join(MEMORY_DIR, DAILY_DIR, `${todayStamp()}.md`));
  const yesterday = readIfExists(path.join(MEMORY_DIR, DAILY_DIR, `${yesterdayStamp()}.md`));
  const noteFiles = listFiles(NOTES_DIR);

  if (!longTerm && !today && !yesterday && noteFiles.length === 0) return null;

  const sections: string[] = [];
  sections.push(
    "## Persistent Memory",
    "",
    "The following memory was carried over from previous sessions. **Treat it as heuristic context, not ground truth:**",
    "",
    "- Use it to inform your plan (likely conventions, prior decisions, user preferences).",
    "- Verify against the current repo state before acting on it.",
    "- Prefer the user's current instruction and current repo state when they conflict with memory.",
    "- When memory changes your plan, cite the file path (e.g. `MEMORY.md`) so the user can correct it.",
    "- Treat conflicting memory as possibly stale; offer to update it via `memory_write`.",
    "",
    `Memory directory: \`${MEMORY_DIR}\``,
    "",
  );

  if (longTerm?.trim()) {
    sections.push("### MEMORY.md (long-term)", "", middleTruncate(longTerm.trim(), INJECT_LONG_TERM_MAX), "");
  }
  if (today?.trim()) {
    sections.push(`### daily/${todayStamp()}.md (today)`, "", tail(today.trim(), INJECT_DAILY_MAX), "");
  }
  if (yesterday?.trim()) {
    sections.push(`### daily/${yesterdayStamp()}.md (yesterday)`, "", tail(yesterday.trim(), INJECT_DAILY_MAX), "");
  }
  if (noteFiles.length > 0) {
    sections.push(
      "### notes/ (available on demand — not injected)",
      "",
      noteFiles.map((f) => `- notes/${f}`).join("\n"),
      "",
      "Use `memory_read` or `memory_search` to load notes when relevant.",
      "",
    );
  }

  return sections.join("\n").trimEnd();
}

export default function memoryExtension(pi: ExtensionAPI) {
  // Tool: memory_write
  pi.registerTool({
    name: "memory_write",
    label: "Memory Write",
    description:
      "Persist information to long-term memory across sessions. Targets: " +
      "`long_term` (MEMORY.md, curated facts/decisions/preferences), " +
      "`daily` (daily/YYYY-MM-DD.md, append-only journal for today), " +
      "`note` (notes/<name>.md, on-demand reference material). " +
      "Modes: `append` (default) adds to the end; `overwrite` replaces the file.",
    promptSnippet: "Write to persistent memory (long-term facts, daily log, or named notes)",
    promptGuidelines: [
      "Use memory_write to capture durable facts the user will benefit from in future sessions: stable preferences, project conventions, recurring pitfalls, decisions and their rationale.",
      "Prefer `long_term` for curated facts; `daily` for session-by-session journal entries; `note` for larger reference material that should not bloat the always-injected context.",
      "Do not store secrets, tokens, or one-off ephemeral details.",
      "When the user explicitly asks you to remember something, write it to long_term.",
    ],
    parameters: Type.Object({
      target: Type.Union(
        [Type.Literal("long_term"), Type.Literal("daily"), Type.Literal("note")],
        { description: "Where to write" },
      ),
      content: Type.String({ description: "Markdown content to write" }),
      mode: Type.Optional(
        Type.Union([Type.Literal("append"), Type.Literal("overwrite")], {
          default: "append",
          description: "append (default) or overwrite",
        }),
      ),
      name: Type.Optional(
        Type.String({
          description:
            "Required when target=note. Filename stem (alphanumerics, '.', '_', '-'). '.md' added automatically.",
        }),
      ),
    }),
    async execute(_id, params) {
      ensureDir(MEMORY_DIR);
      ensureDir(path.join(MEMORY_DIR, DAILY_DIR));
      ensureDir(path.join(MEMORY_DIR, NOTES_DIR));
      const mode = params.mode ?? "append";

      let file: string;
      if (params.target === "long_term") {
        file = path.join(MEMORY_DIR, LONG_TERM_FILE);
      } else if (params.target === "daily") {
        file = path.join(MEMORY_DIR, DAILY_DIR, `${todayStamp()}.md`);
      } else {
        const safe = params.name ? safeNoteName(params.name) : null;
        if (!safe) {
          return {
            content: [
              {
                type: "text",
                text: "memory_write: target=note requires `name` (alphanumerics, '.', '_', '-' only).",
              },
            ],
            isError: true,
            details: {},
          };
        }
        file = path.join(MEMORY_DIR, NOTES_DIR, safe);
      }

      const body = params.content.endsWith("\n") ? params.content : `${params.content}\n`;
      if (mode === "overwrite") {
        fs.writeFileSync(file, body, "utf8");
      } else {
        const stamp =
          params.target === "daily"
            ? `\n## ${new Date().toISOString().replace("T", " ").replace(/\..+/, "")}\n\n`
            : "";
        const sep = fs.existsSync(file) ? stamp || "\n" : "";
        fs.appendFileSync(file, `${sep}${body}`, "utf8");
      }

      const rel = path.relative(MEMORY_DIR, file);
      return {
        content: [{ type: "text", text: `Wrote (${mode}) to ${rel}` }],
        details: { path: file, mode, target: params.target },
      };
    },
  });

  // Tool: memory_read
  pi.registerTool({
    name: "memory_read",
    label: "Memory Read",
    description:
      "Read from persistent memory. Targets: `long_term` (MEMORY.md), `daily` (a specific date or today), " +
      "`note` (notes/<name>.md), or `list` (enumerate all memory files).",
    promptSnippet: "Read persistent memory files (long-term, daily logs, notes)",
    promptGuidelines: [
      "Use memory_read to retrieve detail beyond what was auto-injected (older daily logs, individual notes).",
      "Use target=list to discover what notes exist before reading them.",
    ],
    parameters: Type.Object({
      target: Type.Union(
        [
          Type.Literal("long_term"),
          Type.Literal("daily"),
          Type.Literal("note"),
          Type.Literal("list"),
        ],
        { description: "What to read" },
      ),
      name: Type.Optional(
        Type.String({
          description: "Required for target=note. For target=daily, a YYYY-MM-DD date (defaults to today).",
        }),
      ),
    }),
    async execute(_id, params) {
      ensureDir(MEMORY_DIR);
      if (params.target === "list") {
        const longTermExists = fs.existsSync(path.join(MEMORY_DIR, LONG_TERM_FILE));
        const daily = listFiles(DAILY_DIR);
        const notes = listFiles(NOTES_DIR);
        const lines: string[] = [`Memory directory: ${MEMORY_DIR}`, ""];
        lines.push(longTermExists ? "- MEMORY.md" : "- MEMORY.md (empty)");
        lines.push(`- daily/ (${daily.length} files)`);
        for (const f of daily.slice(-10)) lines.push(`  - daily/${f}`);
        if (daily.length > 10) lines.push(`  …(${daily.length - 10} older)`);
        lines.push(`- notes/ (${notes.length} files)`);
        for (const f of notes) lines.push(`  - notes/${f}`);
        return { content: [{ type: "text", text: lines.join("\n") }], details: { daily, notes } };
      }

      let file: string;
      if (params.target === "long_term") {
        file = path.join(MEMORY_DIR, LONG_TERM_FILE);
      } else if (params.target === "daily") {
        const date = params.name?.trim() || todayStamp();
        if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
          return {
            content: [{ type: "text", text: `memory_read: invalid date '${date}', expected YYYY-MM-DD` }],
            isError: true,
            details: {},
          };
        }
        file = path.join(MEMORY_DIR, DAILY_DIR, `${date}.md`);
      } else {
        const safe = params.name ? safeNoteName(params.name) : null;
        if (!safe) {
          return {
            content: [{ type: "text", text: "memory_read: target=note requires a valid `name`." }],
            isError: true,
            details: {},
          };
        }
        file = path.join(MEMORY_DIR, NOTES_DIR, safe);
      }

      if (!fs.existsSync(file)) {
        return {
          content: [{ type: "text", text: `(empty) ${path.relative(MEMORY_DIR, file)} does not exist` }],
          details: { path: file, exists: false },
        };
      }
      const { text, truncated } = readFileTrimmed(file, READ_MAX_BYTES);
      const rel = path.relative(MEMORY_DIR, file);
      const header = `# ${rel}${truncated ? ` (truncated to ${READ_MAX_BYTES} bytes)` : ""}\n\n`;
      return { content: [{ type: "text", text: header + text }], details: { path: file, truncated } };
    },
  });

  // Tool: memory_search
  pi.registerTool({
    name: "memory_search",
    label: "Memory Search",
    description:
      "Case-insensitive substring search across all memory files (MEMORY.md, daily/, notes/). Returns matching path, line number, and a snippet.",
    promptSnippet: "Search persistent memory files for a substring",
    promptGuidelines: [
      "Use memory_search to surface details from older daily logs or notes that aren't auto-injected.",
      "Search is plain substring; try multiple keywords if the first attempt misses.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Substring to find (case-insensitive)" }),
    }),
    async execute(_id, params) {
      const q = params.query.trim();
      if (!q) {
        return {
          content: [{ type: "text", text: "memory_search: empty query" }],
          isError: true,
          details: {},
        };
      }
      const hits = searchAll(q);
      if (hits.length === 0) {
        return {
          content: [{ type: "text", text: `No matches for "${q}" in ${MEMORY_DIR}` }],
          details: { query: q, hits: [] },
        };
      }
      const lines = hits.map((h) => `${h.path}:${h.line}: ${h.snippet}`);
      const more = hits.length >= SEARCH_MAX_HITS ? `\n…(stopped at ${SEARCH_MAX_HITS} hits)` : "";
      return {
        content: [{ type: "text", text: `Matches for "${q}":\n${lines.join("\n")}${more}` }],
        details: { query: q, hits },
      };
    },
  });

  // Inject memory into the system prompt before each turn.
  pi.on("before_agent_start", async (event) => {
    const block = buildInjection();
    if (!block) return;
    return { systemPrompt: `${event.systemPrompt}\n\n${block}` };
  });
}
