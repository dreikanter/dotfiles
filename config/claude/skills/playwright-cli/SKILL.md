---
name: playwright-cli
description: Use Playwright CLI for browser interaction, UI verification, screenshots, video demos, and debugging Playwright tests.
allowed-tools: Bash(playwright-cli:*) Bash(npx:*) Bash(npm:*)
---

# Playwright CLI

Reuse an installed `playwright-cli` or the project's local binary. Check
`playwright-cli --version` and `playwright-cli --help <command>` for supported
options. If unavailable, use the project's working browser stack; install
`@playwright/cli` only when the task needs it.

## UI workflow

Use a task-specific session name and keep it on every command. Examples use
`ui-review`; choose a distinct name when another task already owns that session.
Read project guidance for startup, authentication, and scenario data.

```bash
playwright-cli -s=ui-review open https://example.com
playwright-cli -s=ui-review resize 1440 900
playwright-cli -s=ui-review --raw snapshot
# Use a ref from this snapshot, or a unique selector.
playwright-cli -s=ui-review click "getByRole('link', { name: 'Sign in' })"
playwright-cli -s=ui-review --raw snapshot
```

Sign in once per persona. Navigate with `goto` in the same session to preserve
authentication; reserve `open` for starting a browser. Check the final host and
visible account before interpreting results. To switch personas, use another
session.

Wait for the intended visible state with a bounded locator wait. A generic
network-idle wait is unsuitable for pages with ongoing requests.

```bash
playwright-cli -s=ui-review run-code "async page => {
  await page.getByRole('heading', { name: 'Dashboard' }).waitFor({ timeout: 10000 });
}"
```

Use snapshot refs for immediate interactions. After navigation or replacement
of the target DOM, take a new snapshot or use a stable locator. Verify test IDs
exist in the rendered page. `--raw` returns just the result; `--json` wraps the
reply as JSON.

For non-obvious selection, dialog, CSS, and baseline issues, read
[UI verification](references/ui-verification.md).

## Screenshots and video

For screenshot quality, readiness, and comparison rules, use `web-screenshots`
when available. The CLI defaults to the visible viewport:

```bash
playwright-cli -s=ui-review screenshot --filename=page.png
playwright-cli -s=ui-review screenshot '#component' --filename=component.png
playwright-cli -s=ui-review screenshot --full-page --filename=document.png
```

For video demos, read [video recording](references/video-recording.md). It
covers explicit frame dimensions, pacing, annotations, and output inspection.
Full page width means the viewport's entire width; it does not mean recording
the full scrollable document at once.

Close only the session you created when finished:

```bash
playwright-cli -s=ui-review close
```

For an attached external browser, use `detach` instead. Avoid `close-all` and
`kill-all` unless the task explicitly covers every affected session.

## Task-specific references

Read only the reference needed for the task. Use CLI help for the command catalog.

- [Custom Playwright code](references/running-code.md): multi-step interactions and waits.
- [Sessions](references/session-management.md): profiles, isolation, and attaching to browsers.
- [Element attributes](references/element-attributes.md): inspect properties missing from snapshots.
- [Storage state](references/storage-state.md): save and restore authentication.
- [Request mocking](references/request-mocking.md): intercept browser requests for a scenario.
- [Tracing](references/tracing.md): diagnose actions, network, and DOM state.
- [Playwright tests](references/playwright-tests.md): run and debug existing tests.
- [Test generation](references/test-generation.md): turn interactions into tests.
- [Spec-driven testing](references/spec-driven-testing.md): plan, generate, or repair tests when requested.
