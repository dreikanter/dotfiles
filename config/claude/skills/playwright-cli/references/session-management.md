# Browser sessions

Use a distinct session name per task or persona, and keep it on every command.
Each new session has separate cookies, storage, and tabs unless deliberately
configured to share an external browser or profile.

```bash
playwright-cli -s=auth-review open https://app.example.com/login
playwright-cli -s=public-review open https://example.com
playwright-cli -s=auth-review fill '#email' user@example.com
playwright-cli -s=public-review snapshot
playwright-cli -s=auth-review goto https://app.example.com/dashboard
```

`goto` retains the browser and authentication. `open` starts a browser; do not
use it for ordinary navigation after login. Inspect sessions with
`playwright-cli list` before choosing a name that might already be in use.

## Profiles and configuration

Default profiles are in memory. Use `--persistent` only when authentication
must survive browser restarts. A custom `--profile` directory should belong to
the task; do not reuse someone else's active profile.

```bash
playwright-cli -s=auth-review open https://example.com --persistent
# Alternatives when starting a session:
playwright-cli -s=auth-review open https://example.com --profile=/path/to/profile
playwright-cli -s=auth-review open https://example.com --config=my-cli.json
playwright-cli -s=auth-review open https://example.com --browser=firefox
```

`PLAYWRIGHT_CLI_SESSION` sets a default session name for commands without `-s`.
An explicit `-s` makes ownership clearer in shared environments. For transferring
login state, see [storage state](storage-state.md).

## Attaching to an existing browser

Use `attach` only for the intended browser. CDP attachment requires remote
debugging to be enabled; extension attachment requires the Playwright extension.
Check `playwright-cli --help attach` for supported channels and options.

```bash
playwright-cli -s=browser-review attach --cdp=chrome
# Alternatives:
playwright-cli -s=browser-review attach --cdp=http://localhost:9222
playwright-cli -s=browser-review attach --extension=chrome
```

## Cleanup

Close sessions you created; detach from externally owned browsers:

```bash
playwright-cli -s=auth-review close
playwright-cli -s=public-review close
playwright-cli -s=browser-review detach
```

`detach` applies to attached sessions and leaves the browser running. Delete a
persistent profile with `-s=<name> delete-data` only when its stored data is no
longer needed. `close-all` and `kill-all` affect other tasks too; reserve them for
explicitly requested cleanup of all affected sessions.
