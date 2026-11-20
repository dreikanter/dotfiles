# UI verification

## Selectors and controls

A re-render can replace the target element without replacing the whole page.
Refresh snapshot refs when their targets change; stable role or ID locators are
useful across repeated interactions. Scope ambiguous selectors to the relevant
component.

`select` takes an option value. Inspect actual values and labels before guessing:

```bash
playwright-cli -s=ui-review --raw eval \
  'el => [...el.options].map(o => ({value: o.value, text: o.text}))' '#some-select'
playwright-cli -s=ui-review select '#some-select' actual-value
```

For selection by label, use `run-code` with
`page.locator('#some-select').selectOption({ label: 'Actual label' })`.

A native alert, confirmation, or before-unload dialog can block navigation.
Inspect its message, then deliberately accept or dismiss it according to the
task. Do not accept an unknown dialog merely to unblock a command.

## Page and CSS failures

For 404/500 responses, inspect application logs and verify route identifiers
before retrying selectors. For missing visual changes, check the loaded asset
URLs, build output, and computed style; reload only when stale assets explain
the mismatch.

```bash
playwright-cli -s=ui-review console
playwright-cli -s=ui-review requests
playwright-cli -s=ui-review request 22
playwright-cli -s=ui-review response-body 22
playwright-cli -s=ui-review --raw eval \
  'el => { const cs = getComputedStyle(el); return {display: cs.display, width: cs.width}; }' '#component'
playwright-cli -s=ui-review --raw eval \
  '() => [...document.querySelectorAll("link[rel=stylesheet]")].map(l => l.href)'
```

## Before/after comparisons

Use the same viewport, persona, data, and scroll position for both captures.
Obtain a baseline in a separate checkout/worktree when code must change; do not
replace files in an active checkout with `git checkout SHA -- path`, which can
lose existing edits. Run the baseline on its own development server when needed.

Inspect the resulting images with an image-viewing tool. Report missing scenario
data separately from rendering failures. Use `web-screenshots`, when available,
for capture resolution and readiness requirements.
