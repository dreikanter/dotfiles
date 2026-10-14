---
name: web-screenshots
description: Capture and inspect screenshots of rendered web pages for UI review, responsive layout checks, or before/after comparisons. Use project-specific guidance for startup and authentication.
---

# Web screenshots

Use an available browser tool or the Ferrum helper below. Reuse the project's
working browser stack; do not install another one merely to capture an image.
Read an applicable private/project screenshot skill for startup, authentication,
and scenario data. Keep those details out of this public skill.

## Capture workflow

1. Confirm the target application is serving the expected page. A listening
   port does not establish that migrations, assets, or authentication are ready.
   Diagnose an error response before retrying browser selectors.
2. Sign in once per persona and retain that browser session. Verify the final
   host and visible account/organization before navigating to the target.
3. Inspect the rendered DOM before selecting controls. Scope selectors to the
   relevant region; source-code test attributes may not exist at runtime.
4. Wait for a visible page-specific selector or text, then fonts and relevant
   images. Prefer bounded state checks to sleeps or global network-idle waits
   on pages with polling or persistent connections.
5. Capture a viewport by default. Choose an element crop for component review;
   request full-page capture explicitly for long pages. Use equal viewport,
   persona, data, and scroll position for before/after comparisons. Preserve
   ongoing edits when obtaining a baseline.
6. Inspect the actual PNG with an image-viewing tool. Check framing, loaded
   assets, and the intended UI state. A written file alone is not validation.

Capture the basic page before optional interactions. Missing scenario data
should be reported separately instead of discarding useful captures. Screenshot
requests do not imply changes to application data or server configuration.

A narrow desktop Chromium viewport checks responsive layout; it is not mobile
Safari/device validation. Record which browser and viewport were used. Upload
images only as part of a requested sharing workflow; inspect them first.

## Ferrum helper

Requires Ruby, the `ferrum` gem, and Chrome/Chromium already available. The helper
uses Ferrum browser discovery; `BROWSER_PATH` or `--browser` can override it.
Use the absolute path to this skill's `scripts/capture.rb` from other directories.

```sh
ruby scripts/capture.rb --url 'http://localhost:3000/example' \
  --ready-selector 'main h1' --output /tmp/page-desktop.png

ruby scripts/capture.rb --url 'http://localhost:3000/example' \
  --ready-text 'Example' --viewport 390x1000 --output /tmp/page-narrow.png
```

`--selector` crops to an element; `--full-page` captures the document. They are
mutually exclusive. `--timeout` bounds readiness waits. `--insecure` is only for
known local development HTTPS. `--keep-animations` preserves motion when that
is the subject of the review. Outputs include PNG paths, viewport, and horizontal
overflow in JSON; failures produce a separate `.error.png` when possible.

For authentication or multiple states, require the same helper from a **local**
Ruby script. The block owns application-specific navigation and interactions:

```ruby
require File.expand_path('~/.codex/skills/web-screenshots/scripts/capture')

ok = WebScreenshots.run(error_path: '/tmp/page.error.png') do |session|
  # Perform the project's documented login using session.browser, if needed.
  session.navigate('http://localhost:3000/example', ready_selector: 'main h1')
  session.save('/tmp/page-desktop.png')
  session.save('/tmp/page-narrow.png', width: 390, height: 1000)
end
exit(ok ? 0 : 1)
```

`session.wait('step label') { condition }` provides a bounded wait for redirects
and interactions. `session.browser` exposes Ferrum. `save` also accepts
`selector:`, `full:`, and `stabilize:`. Recheck responsive content after resizing
when it loads different data. For a full-page capture with lazy images, scroll
through the relevant content first to trigger loading. The helper closes only
its own browser and does not persist cookies or print page bodies. Failure output names the step and
error class; inspect the failure image and relevant local logs for diagnosis.
