---
name: autoconfirm
description: Toggle automatic tool confirmation hooks on/off for the current project. Use when the user types /autoconfirm or wants to enable/disable auto-approval of tool calls.
user_invocable: true
arguments: on|off (optional)
---

# autoconfirm

Toggle a prompt-based safety-reviewer hook in `.claude/settings.local.json` for the current project. When enabled, an LLM automatically approves safe tool calls and blocks dangerous ones.

## Usage

- `/autoconfirm` — show current status
- `/autoconfirm on` — enable the safety-reviewer hook
- `/autoconfirm off` — disable it

## Hook Definition

```json
{
  "id": "autoconfirm",
  "hooks": [{
    "type": "prompt",
    "prompt": "You are a safety reviewer for an automated Claude Code session. Decide whether this tool call should be ALLOWED or should ASK the user for confirmation.\n\nALLOW if:\n- Writing or editing code files in the project directory\n- Running common dev commands (test, build, lint, format, echo, cat, ls, git status, git diff, git log, git add, git commit, git checkout, git branch)\n- GitHub CLI commands (gh pr, gh issue, gh repo, gh api, gh gist, gh run, etc.)\n- Reading files, searching, globbing\n- Creating/editing configuration files in the project (including .claude/settings.local.json)\n- jq commands for JSON processing\n- mv commands within the project or from /tmp to the project\n\nASK (escalate to user) if:\n- Destructive commands: rm -rf, git push --force, git reset --hard, DROP TABLE, etc.\n- Touching sensitive files: .env, credentials, secrets, private keys, tokens\n- Network requests to unknown endpoints\n- Installing packages globally or running sudo\n- Modifying files outside the project directory\n- Any command that could cause irreversible damage\n- Anything you are uncertain about\n\nNever DENY outright — either ALLOW or ASK.\n\nTool call to evaluate:\n$ARGUMENTS",
    "model": "claude-haiku-4-5-20251001",
    "statusMessage": "autoconfirm reviewing..."
  }]
}
```

## Implementation Instructions

When the user invokes this skill, follow these steps exactly:

### Step 1: Parse arguments

Extract the action from `$ARGUMENTS`. Valid values: `on`, `off`, or empty/missing (status check).

### Step 2: Read current settings

Read `.claude/settings.local.json` in the current project directory. If the file doesn't exist:
- For `on`: create it with `{}`
- For `off` or status: report that no hooks are configured

### Step 2a: Status check (no arguments)

If no action was provided, check whether the autoconfirm hook exists in `.hooks.PreToolUse[]` (look for an entry with `"id": "autoconfirm"`). Report concisely:
- **Enabled** if the hook is present
- **Disabled** if absent or file doesn't exist

Then stop — do not proceed to Step 3.

### Step 3: Execute action

**For `on`:**

Use `jq` via Bash to merge the hook into the existing settings file. Do NOT overwrite other keys (permissions, env, etc.). If the hook already exists, replace it.

```bash
jq --argjson hook '<HOOK_JSON_FROM_ABOVE>' '
  .hooks //= {} |
  .hooks.PreToolUse //= [] |
  .hooks.PreToolUse |= [.[] | select(.id != $hook.id)] + [$hook]
' .claude/settings.local.json > /tmp/autoconfirm-tmp.json && mv /tmp/autoconfirm-tmp.json .claude/settings.local.json
```

**For `off`:**

Use `jq` to remove the hook. Clean up empty arrays/objects.

```bash
jq '
  if .hooks.PreToolUse then
    .hooks.PreToolUse |= [.[] | select(.id != "autoconfirm")]
  else . end |
  if .hooks.PreToolUse == [] then del(.hooks.PreToolUse) else . end |
  if .hooks == {} then del(.hooks) else . end
' .claude/settings.local.json > /tmp/autoconfirm-tmp.json && mv /tmp/autoconfirm-tmp.json .claude/settings.local.json
```

### Step 4: Verify

Read the file back and confirm the result to the user concisely.
