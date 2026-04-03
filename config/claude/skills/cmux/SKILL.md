---
name: cmux
description: Use when the user asks to open tabs, manage panes, read other terminal screens, send commands to other terminals, control browser panes, or interact with the cmux terminal multiplexer in any way.
---

# cmux

Terminal multiplexer with built-in browser. Control via `cmux` CLI. Environment auto-sets `CMUX_WORKSPACE_ID` and `CMUX_SURFACE_ID` for the current terminal.

## Addressing

Use short refs: `window:1`, `workspace:2`, `pane:3`, `surface:4`. Pass `--json` for structured output.

## Quick Reference

| Task | Command |
|------|---------|
| List workspaces | `cmux list-workspaces` |
| New workspace (tab) | `cmux new-workspace` |
| New workspace with cmd | `cmux new-workspace --command "cmd"` |
| Select workspace | `cmux select-workspace --workspace <ref>` |
| Rename workspace | `cmux rename-workspace --workspace <ref> "title"` |
| Close workspace | `cmux close-workspace --workspace <ref>` |
| Current workspace | `cmux current-workspace` |

### Panes and Splits

| Task | Command |
|------|---------|
| Split right | `cmux new-split right` |
| Split down | `cmux new-split down` |
| List panes | `cmux list-panes` |
| Focus pane | `cmux focus-pane --pane <ref>` |
| Resize pane | `cmux resize-pane --pane <ref> -R --amount 20` |
| Close surface | `cmux close-surface --surface <ref>` |

### Reading and Sending

| Task | Command |
|------|---------|
| Read current screen | `cmux read-screen` |
| Read other surface | `cmux read-screen --surface <ref>` |
| Read with scrollback | `cmux read-screen --scrollback --lines 200` |
| Send text to surface | `cmux send --surface <ref> "text"` |
| Send keypress | `cmux send-key --surface <ref> Enter` |

### Browser

| Task | Command |
|------|---------|
| Open browser pane | `cmux browser open <url>` |
| Open as split | `cmux browser open-split <url>` |
| Navigate | `cmux browser navigate <url>` |
| Take snapshot | `cmux browser snapshot` |
| Interactive snapshot | `cmux browser snapshot --interactive` |
| Click element | `cmux browser click "selector"` |
| Type into field | `cmux browser type "selector" "text"` |
| Evaluate JS | `cmux browser eval "document.title"` |
| Get current URL | `cmux browser url` |
| Back/forward/reload | `cmux browser back` / `forward` / `reload` |

### Notifications and Sidebar

| Task | Command |
|------|---------|
| Desktop notification | `cmux notify --title "Done" --body "Task complete"` |
| Set sidebar status | `cmux set-status key "value" --icon name` |
| Set progress | `cmux set-progress 0.5 --label "Halfway"` |
| Log message | `cmux log "message"` |

## Tips

- Omit `--workspace` and `--surface` to target the current terminal (uses env vars).
- Use `--workspace <ref>` or `--surface <ref>` to target other terminals.
- `cmux identify` shows the current workspace/surface/pane context.
- `cmux list-pane-surfaces` shows tabs within a pane.
- Run `cmux help` or `cmux <command> --help` for full flag details.
