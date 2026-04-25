import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

function formatTokens(count: number): string {
  if (count < 1000) return count.toString();
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1000000) return `${Math.round(count / 1000)}k`;
  if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
  return `${Math.round(count / 1000000)}M`;
}

function formatDuration(ms: number): string {
  const total = Math.max(0, Math.floor(ms / 1000));
  const m = Math.floor(total / 60);
  const s = total % 60;
  return m > 0 ? `${m}m${s.toString().padStart(2, "0")}s` : `${s}s`;
}

function runGit(cwd: string, args: string[]): string | undefined {
  try {
    const { execFileSync } = require("node:child_process");
    return execFileSync("git", args, {
      cwd,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 1000,
    }).trim();
  } catch {
    return undefined;
  }
}

function getGitDiffStats(cwd: string): string | undefined {
  const out = runGit(cwd, ["diff", "--numstat"]);
  if (!out) return undefined;

  let added = 0;
  let deleted = 0;

  for (const line of out.split("\n")) {
    const [a, d] = line.split(/\s+/);
    if (/^\d+$/.test(a ?? "")) added += Number(a);
    if (/^\d+$/.test(d ?? "")) deleted += Number(d);
  }

  if (added === 0 && deleted === 0) return undefined;
  return `git+${added}-${deleted}`;
}

function getCommitsAheadBase(cwd: string): number | undefined {
  const base =
    process.env.PI_STATUS_BASE_BRANCH ??
    runGit(cwd, ["symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"])
      ?.replace(/^origin\//, "origin/") ??
    "origin/main";

  const out = runGit(cwd, ["rev-list", "--count", `${base}..HEAD`]);
  if (!out || !/^\d+$/.test(out)) return undefined;
  return Number(out);
}

export default function (pi: ExtensionAPI) {
  let turnStartMs: number | undefined;
  let lastTurnDurationMs = 0;

  pi.on("turn_start", async () => {
    turnStartMs = Date.now();
  });

  pi.on("turn_end", async () => {
    if (turnStartMs !== undefined) {
      lastTurnDurationMs = Date.now() - turnStartMs;
    }
    turnStartMs = undefined;
  });

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setFooter((tui, theme, footerData) => {
      const branchUnsub = footerData.onBranchChange(() => tui.requestRender());

      const timer = setInterval(() => {
        if (turnStartMs !== undefined) tui.requestRender();
      }, 1000);

      return {
        dispose() {
          branchUnsub();
          clearInterval(timer);
        },

        invalidate() {},

        render(width: number): string[] {
          let pwd = ctx.sessionManager.getCwd();
          const home = process.env.HOME || process.env.USERPROFILE;
          if (home && pwd.startsWith(home)) pwd = `~${pwd.slice(home.length)}`;

          const branch = footerData.getGitBranch();
          if (branch) pwd += ` (${branch})`;

          const sessionName = ctx.sessionManager.getSessionName();
          if (sessionName) pwd += ` • ${sessionName}`;

          let input = 0;
          let output = 0;
          let cacheRead = 0;
          let cacheWrite = 0;
          let cost = 0;
          let turns = 0;

          for (const entry of ctx.sessionManager.getEntries()) {
            if (entry.type !== "message") continue;
            const msg: any = entry.message;
            if (msg.role !== "assistant") continue;

            turns++;
            input += msg.usage?.input ?? 0;
            output += msg.usage?.output ?? 0;
            cacheRead += msg.usage?.cacheRead ?? 0;
            cacheWrite += msg.usage?.cacheWrite ?? 0;
            cost += msg.usage?.cost?.total ?? 0;
          }

          const parts: string[] = [];
          if (input) parts.push(`↑${formatTokens(input)}`);
          if (output) parts.push(`↓${formatTokens(output)}`);
          if (cacheRead) parts.push(`R${formatTokens(cacheRead)}`);
          if (cacheWrite) parts.push(`W${formatTokens(cacheWrite)}`);

          const usingSub = ctx.model ? ctx.modelRegistry.isUsingOAuth(ctx.model) : false;
          if (cost || usingSub) {
            parts.push(`$${cost.toFixed(3)}${usingSub ? " (sub)" : ""}`);
          }

          const usage = ctx.getContextUsage();
          const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          const contextPercent =
            usage?.percent === null || usage?.percent === undefined
              ? "?"
              : usage.percent.toFixed(1);

          parts.push(`${contextPercent}%/${formatTokens(contextWindow)} (auto)`);

          // Additions
          parts.push(`T${turns}`);

          const cacheRatio =
            input + cacheRead > 0 ? Math.round((cacheRead / (input + cacheRead)) * 100) : 0;
          parts.push(`cache ${cacheRatio}%`);

          const durationMs =
            turnStartMs !== undefined ? Date.now() - turnStartMs : lastTurnDurationMs;
          if (durationMs > 0) parts.push(formatDuration(durationMs));

          const gitStats = getGitDiffStats(ctx.cwd);
          if (gitStats) parts.push(gitStats);

          const ahead = getCommitsAheadBase(ctx.cwd);
          if (ahead !== undefined) parts.push(`(${ahead})`);

          let left = parts.join(" ");

          const modelName = ctx.model?.id ?? "no-model";
          let right = modelName;
          if (ctx.model?.reasoning) {
            // If you want thinking level here too, this can be extended.
            right = modelName;
          }

          if (visibleWidth(left) > width) {
            left = truncateToWidth(left, width, "...");
          }

          const leftWidth = visibleWidth(left);
          const rightWidth = visibleWidth(right);

          let statsLine: string;
          if (leftWidth + 2 + rightWidth <= width) {
            statsLine = left + " ".repeat(width - leftWidth - rightWidth) + right;
          } else {
            statsLine = left;
          }

          return [
            truncateToWidth(theme.fg("dim", pwd), width, theme.fg("dim", "...")),
            theme.fg("dim", truncateToWidth(statsLine, width, "...")),
          ];
        },
      };
    });
  });
}
