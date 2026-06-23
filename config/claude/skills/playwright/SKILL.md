---
name: playwright
description: Fast-path Playwright CLI recipes for ad-hoc browser testing and screenshots. Use when manually verifying UI changes in a local dev environment - covers installation, the open-snapshot-interact-screenshot loop, stable element targeting, and the gotchas that waste time.
allowed-tools: Bash(playwright-cli:*) Bash(npm:*) Bash(npx:*)
---

# Playwright Quick Reference

A focused, opinionated cheat sheet for ad-hoc UI verification - not a full
reference. The verbose canonical version lives in the `playwright-cli`
skill; check there if a command isn't covered here.

## Install (once)

```bash
playwright-cli --version || npm install -g @playwright/cli@latest
```

Versions stick around. No need to reinstall every session.

## The 90% loop

```bash
playwright-cli open https://example.com           # opens a fresh in-memory browser
playwright-cli --raw snapshot | head -40          # ARIA tree with [ref=eNN]
playwright-cli fill e17 "user@example.com"        # interact via ref
playwright-cli click e27
playwright-cli screenshot "#some-id" \
  --filename .playwright-cli/after.png            # save to local file
playwright-cli close
```

Read screenshots back into the conversation with the `Read` tool on the
file path - they render inline.

**Navigate within a session - don't re-`open`.** `open` starts a fresh
in-memory browser and drops cookies/auth. Once logged in, go to another URL
in the SAME session via `run-code`:

```bash
playwright-cli run-code "async page => { await page.goto(URL); await page.waitForLoadState('networkidle'); }"
```

**Viewport** - `open` has no viewport flag (default ~1280 wide). Set it via
`run-code` before navigating/screenshotting:

```bash
playwright-cli run-code "async page => page.setViewportSize({ width: 1440, height: 1200 })"
```

## `--raw` is your friend

Strips the status/code/snapshot/events sections - only the result remains.
Pipe it, JSON-parse it, diff it.

```bash
playwright-cli --raw snapshot > before.yml
# ...interact...
playwright-cli --raw snapshot > after.yml
diff before.yml after.yml

# get a select's options as JSON, before guessing labels
playwright-cli --raw eval \
  "el => JSON.stringify([...el.options].map(o => ({value: o.value, text: o.text})))" e409

# computed style debugging
playwright-cli --raw eval \
  "el => { const cs = getComputedStyle(el); return JSON.stringify({width: cs.width, display: cs.display}); }" e409

# loaded stylesheets - useful when wondering "why doesn't my CSS apply"
playwright-cli --raw eval \
  "() => [...document.querySelectorAll('link[rel=stylesheet]')].map(l => l.href).join('\\n')"
```

`run-code` return values are easy to miss in the command output. To reliably
read page state, use `--raw eval` returning a JSON string:

```bash
playwright-cli --raw eval \
  "() => JSON.stringify({ url: location.href, title: document.title, hasX: document.body.innerText.includes('X') })"
```

## Targeting elements

In order of preference:

1. **Stable id via `run-code`** when a re-render will invalidate refs:
   ```bash
   playwright-cli run-code "async page => { await page.locator('#some-select').selectOption({label: 'Option A'}); }"
   ```
2. **Refs from `snapshot`** for one-shot interactions. They're invalidated
   by any DOM-replacing event (Turbo Streams, React re-renders, HTMX
   swaps, plain AJAX). Re-snapshot after such events.
3. **CSS selector or Playwright locator** as inline argument:
   `playwright-cli click "getByRole('button', { name: 'Submit' })"`

## Screenshots

```bash
# whole page
playwright-cli screenshot --filename .playwright-cli/page.png
# specific element (use a stable selector, not a ref, for repeatability)
playwright-cli screenshot "#some-component" \
  --filename .playwright-cli/component-after.png
```

A full-page `screenshot` with no selector may anchor at the top of the page.
For below-the-fold content, pass a stable selector, or scroll it into view
first:

```bash
playwright-cli run-code "async page => page.getByText('Section title').first().scrollIntoViewIfNeeded()"
```

For before/after comparisons in a PR: `git checkout` the parent commit of
the visual change (just for the affected view/CSS files via
`git checkout SHA -- path/to/file`), take the "before" shot, then
`git checkout HEAD -- path/to/file` to restore. Keep the in-page state
identical (same data, same selections) between shots.

## Common gotchas (this is the section that saves real time)

### Refs go stale after re-renders

If the DOM was replaced by a Turbo Stream, React state change, HTMX swap,
or any AJAX response, every ref in your earlier snapshot is now wrong.
Either re-snapshot, or target by stable `#id` via `run-code`.

### Modal/dialog blocks navigation

`reload`, `goto`, and `close` can hang for 60s with the error
"does not handle the modal state" when a browser-native dialog
(confirm/alert/beforeunload) is open.

```bash
playwright-cli dialog-accept     # OK on the dialog
playwright-cli dialog-dismiss    # Cancel
```

If unsure whether a dialog is up, just call `dialog-accept` defensively
before `goto`/`reload`.

### `select` retries silently when the label doesn't exist

```bash
playwright-cli select e409 "Option that does not exist"
# - retrying select option action
# - waiting 500ms ...
```

It will eventually time out (60s). Always list the actual options first
with `--raw eval` (see above) before calling `select`.

### Auth persists across commands

A login persists across subsequent CLI commands (same server-side browser),
so log in once. To switch users or start clean, clear cookies and re-login:

```bash
playwright-cli run-code "async page => page.context().clearCookies()"
```

### Server returns 404/500 instead of expected content

Stop guessing at URLs. Read the source of truth: check the app/server log for
the exact query or exception, and verify the identifier in your URL matches
what the server actually looks up (route param vs the column/field the backend
queries by). One check here saves many failed navigation attempts.

### Network introspection

```bash
playwright-cli requests          # list of network requests
playwright-cli request 22        # headers/timing/etc for request #22
playwright-cli response-body 22  # response body
playwright-cli request-body 22   # request body
```

Pairs well with server logs - confirm both that the right params went
out and that the server saw them.

### Persistent sessions across runs

```bash
playwright-cli open --persistent     # default profile, on-disk
playwright-cli -s=mysession open ... # named session
playwright-cli list                  # all sessions
playwright-cli close-all
```

Most ad-hoc work doesn't need this - the default in-memory browser is
fine. Reach for `--persistent` only when you need to keep auth cookies
between sessions.

## When CSS / JS changes don't take effect

In order of likelihood:

1. **Stale browser cache** - `playwright-cli reload` (after dismissing any
   dialog). Fingerprinted asset URLs usually rebust automatically, but
   service workers and aggressive cache headers can still bite.
2. **Wrong stylesheet bundle loaded** - dump `[...document.styleSheets]`
   hrefs (snippet above). Check if your stylesheet is even present.
   Conditionally-loaded bundles (theme switches, feature flags,
   environment guards) may not link the file you expect.
3. **Build pipeline didn't rebuild** - check the dev server logs for the
   asset compiler (webpack, esbuild, Vite, etc.).
4. **Selector specificity** - `getComputedStyle` tells you what actually
   applied. Compare to what's in the source CSS.

## Closing the loop

```bash
playwright-cli close       # close the default browser
playwright-cli close-all   # close every browser session
playwright-cli kill-all    # if processes are stuck
```
