# Video recording

Use video for a visual demo; use [tracing](tracing.md) for DOM, network, and
console diagnosis. Playwright CLI records WebM.

## Full-width recording

Set the viewport and video frame size explicitly. Without `--size`,
`video-start` fits the recording within 800x800, which can shrink a wide page.
A full-width demo captures the entire viewport width; scroll when the scenario
needs content below it. Screenshot DPR requirements do not determine video size.

```bash
playwright-cli -s=upload-demo open https://example.com
playwright-cli -s=upload-demo resize 1440 900
# Authenticate and prepare the starting state before recording.
playwright-cli -s=upload-demo video-start demo.webm --size=1440x900
# Perform the requested flow with refs/locators from the current snapshot.
playwright-cli -s=upload-demo video-stop
playwright-cli -s=upload-demo close
```

Choose a session name not already owned by another task. For an existing session,
reuse its name and omit `open`. Keep the viewport fixed during the recording.
Stop recording before closing the browser so the file is finalized.

## Scripted demos

For repeatable timing, put a single async function expression in a file and run
it with `playwright-cli -s=upload-demo run-code --filename=demo.js`. The
`page.screencast` API below is available in the CLI runtime; check support before
using it in a different Playwright installation.

Wait for actual UI states before adding short pauses for the viewer to read.
Pauses control presentation, not application readiness. If responses are mocked
or deliberately slowed, disclose that in the recording or accompanying text.

```js
async page => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.screencast.start({
    path: 'demo.webm',
    size: { width: 1440, height: 900 },
  });
  try {
    await page.screencast.showChapter('Add an item', { duration: 1500 });
    const input = page.getByRole('textbox', { name: 'What needs to be done?' });
    await input.pressSequentially('Walk the dog', { delay: 60 });
    await input.press('Enter');
    await page.getByText('Walk the dog', { exact: true }).waitFor({ timeout: 10000 });
    await page.waitForTimeout(1500);
  } finally {
    await page.screencast.stop();
  }
}
```

This example assumes the TodoMVC page is already open. Use either CLI
`video-start`/`video-stop` or the script's `screencast.start`/`stop`, not both.

Optional annotations:

| API | Purpose |
|---|---|
| `page.screencast.showChapter(title, { description?, duration? })` | Temporary chapter card; waits for its duration |
| `page.screencast.showOverlay(html, { duration? })` | Callout or highlight; overlays do not intercept pointer events |
| `disposable.dispose()` | Remove the value returned by a persistent overlay |
| `page.screencast.hideOverlays()` / `showOverlays()` | Temporarily hide or restore overlays |

## Verify and deliver

Inspect representative frames or play the file. Confirm dimensions, readable
feedback, pacing, and the intended final state. Return the absolute output path.
Convert to MP4 with existing tools only when the destination needs it; preserve
frame dimensions and elapsed timing.
