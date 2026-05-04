import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36";

function decodeEntities(s: string): string {
  return s
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(parseInt(d, 10)));
}

function stripTags(html: string): string {
  return decodeEntities(html.replace(/<[^>]+>/g, ""));
}

// DuckDuckGo's redirect URLs look like //duckduckgo.com/l/?uddg=<encoded>&...
function unwrapDdgUrl(href: string): string {
  try {
    const u = href.startsWith("//") ? `https:${href}` : href;
    const parsed = new URL(u);
    const target = parsed.searchParams.get("uddg");
    if (target) return decodeURIComponent(target);
    return u;
  } catch {
    return href;
  }
}

interface SearchResult {
  title: string;
  url: string;
  snippet: string;
}

async function ddgSearch(query: string, limit: number, signal?: AbortSignal): Promise<SearchResult[]> {
  const url = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "User-Agent": UA,
      "Content-Type": "application/x-www-form-urlencoded",
      Accept: "text/html",
    },
    body: `q=${encodeURIComponent(query)}`,
    signal,
  });
  if (!res.ok) throw new Error(`DuckDuckGo HTTP ${res.status}`);
  const html = await res.text();

  const results: SearchResult[] = [];
  // Each result block: <div class="result ...">...<a class="result__a" href="...">TITLE</a>...
  // <a class="result__snippet" ...>SNIPPET</a>...
  const blockRe = /<div class="result[ "][^]*?(?=<div class="result[ "]|<div class="nav-link|$)/g;
  const blocks = html.match(blockRe) ?? [];
  for (const block of blocks) {
    const titleM = block.match(/<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/);
    if (!titleM) continue;
    const href = unwrapDdgUrl(decodeEntities(titleM[1]));
    const title = stripTags(titleM[2]).trim();
    const snipM = block.match(/<a[^>]*class="result__snippet"[^>]*>([\s\S]*?)<\/a>/);
    const snippet = snipM ? stripTags(snipM[1]).trim() : "";
    if (!href || !title) continue;
    if (href.includes("duckduckgo.com/y.js")) continue; // ads
    results.push({ title, url: href, snippet });
    if (results.length >= limit) break;
  }
  return results;
}

function htmlToText(html: string): string {
  // Drop script/style/noscript blocks first
  let s = html
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
    .replace(/<noscript\b[^>]*>[\s\S]*?<\/noscript>/gi, " ")
    .replace(/<!--[\s\S]*?-->/g, " ");
  // Convert block-level breaks to newlines
  s = s.replace(/<\/(p|div|li|h[1-6]|tr|br|section|article|header|footer|main|nav)\s*>/gi, "\n");
  s = s.replace(/<br\s*\/?>/gi, "\n");
  s = stripTags(s);
  // Collapse whitespace
  s = s.replace(/[ \t]+/g, " ").replace(/\n[ \t]+/g, "\n").replace(/\n{3,}/g, "\n\n").trim();
  return s;
}

async function fetchUrl(url: string, maxBytes: number, signal?: AbortSignal): Promise<{
  status: number;
  contentType: string;
  finalUrl: string;
  text: string;
  truncated: boolean;
}> {
  const res = await fetch(url, {
    headers: { "User-Agent": UA, Accept: "text/html,application/xhtml+xml,*/*" },
    redirect: "follow",
    signal,
  });
  const contentType = res.headers.get("content-type") ?? "";
  const buf = await res.arrayBuffer();
  let truncated = false;
  let bytes = new Uint8Array(buf);
  if (bytes.byteLength > maxBytes) {
    bytes = bytes.slice(0, maxBytes);
    truncated = true;
  }
  const raw = new TextDecoder("utf-8", { fatal: false }).decode(bytes);
  let text: string;
  if (/html|xml/i.test(contentType) || /^\s*<(!doctype|html)/i.test(raw)) {
    text = htmlToText(raw);
  } else {
    text = raw;
  }
  return { status: res.status, contentType, finalUrl: res.url, text, truncated };
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web via DuckDuckGo and return a list of results (title, URL, snippet). Use web_fetch to read a result's full content.",
    promptSnippet: "Search the web (DuckDuckGo) for up-to-date information",
    promptGuidelines: [
      "Use web_search when the user asks for information that may be outside your training data, or when they explicitly ask to search the web.",
      "Follow up web_search with web_fetch to read the most relevant result(s) before answering.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
      limit: Type.Optional(
        Type.Integer({ minimum: 1, maximum: 20, default: 8, description: "Max number of results (1-20)" }),
      ),
    }),
    async execute(_id, params, signal) {
      const limit = params.limit ?? 8;
      const results = await ddgSearch(params.query, limit, signal);
      if (results.length === 0) {
        return {
          content: [{ type: "text", text: `No results for: ${params.query}` }],
          details: { query: params.query, results: [] },
        };
      }
      const lines = results.map(
        (r, i) => `${i + 1}. ${r.title}\n   ${r.url}\n   ${r.snippet}`,
      );
      return {
        content: [{ type: "text", text: `Results for "${params.query}":\n\n${lines.join("\n\n")}` }],
        details: { query: params.query, results },
      };
    },
  });

  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description:
      "Fetch a URL and return its content as plain text. HTML pages are stripped of tags. Useful after web_search to read a specific page.",
    promptSnippet: "Fetch a URL and return its text content",
    promptGuidelines: [
      "Use web_fetch to read pages discovered via web_search or URLs the user provides.",
      "Prefer modest max_bytes (default ~200KB) to keep context small.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "Absolute http(s) URL to fetch" }),
      max_bytes: Type.Optional(
        Type.Integer({
          minimum: 1024,
          maximum: 2_000_000,
          default: 200_000,
          description: "Maximum response bytes to read (default 200000)",
        }),
      ),
    }),
    async execute(_id, params, signal) {
      if (!/^https?:\/\//i.test(params.url)) {
        return {
          content: [{ type: "text", text: `Invalid URL (must start with http:// or https://): ${params.url}` }],
          isError: true,
          details: {},
        };
      }
      const maxBytes = params.max_bytes ?? 200_000;
      const r = await fetchUrl(params.url, maxBytes, signal);
      const header =
        `URL: ${r.finalUrl}\nStatus: ${r.status}\nContent-Type: ${r.contentType}` +
        (r.truncated ? `\nTruncated: yes (limit ${maxBytes} bytes)` : "");
      return {
        content: [{ type: "text", text: `${header}\n\n${r.text}` }],
        details: {
          url: params.url,
          finalUrl: r.finalUrl,
          status: r.status,
          contentType: r.contentType,
          truncated: r.truncated,
          bytes: maxBytes,
        },
        isError: r.status >= 400,
      };
    },
  });
}
