---
name: update-go-tools
description: Routine dependency-update workflow for my Go CLI tools installed via bin/sync-tools (notes, npub, dotfiles-cli, remail, ...). Use when asked to update Go tool dependencies, refresh the tools, or run the deps-update routine.
---

# Update Go tools

Update dependencies for every Go CLI installed by `bin/sync-tools`, one release PR
per repo. The user merges the PRs and runs `sync-tools` themselves — never run it.

## Tool list

Parse active (non-commented) `go install github.com/dreikanter/<repo>/cmd/<tool>@latest`
lines in `bin/sync-tools` (dotfiles repo). Never hardcode the list.

## How releases work

Every repo: base branch `main`, semver tags, and `.github/workflows/tag.yml` that
auto-tags `v<version>` on PR merge when the topmost released CHANGELOG.md heading
changes. `go install @latest` resolves the newest tag, so a merged PR with a
CHANGELOG patch bump IS the release. Never create or push tags.

## Per-tool procedure (parallelize: one agent per tool)

1. Read the repo's CLAUDE.md first and follow it. Shared conventions: one-line
   commit messages, author = repo owner, no AI/tooling attribution anywhere.
2. Branch `deps-update-<YYYY-MM-DD>` off latest `main`.
3. `go get -u ./...`; if go.mod has a `tool` directive, also `go get -u tool`;
   then `go mod tidy`. No go.mod/go.sum diff → status `up-to-date`, stop, no PR.
4. Catch stragglers: `go list -m -u all` — a direct or tool dep still showing an
   upgrade gets an explicit `go get <mod>@latest`.
5. Validate: `go build ./... && go vet ./... && go test ./...` plus the repo's
   linter (`go tool golangci-lint run` or `make lint`). Generous timeouts —
   first golangci-lint compile is slow.
6. Breakage from changed dep APIs → minimal refactor matching existing style,
   re-validate. Critical incompatibility → status `failed`, report, don't push.
7. Version: latest remote tag (`git ls-remote --tags origin`) must match the top
   CHANGELOG heading; new version = patch bump over it. Re-check right before
   pushing — another PR may have released the same day (then take the next number).
8. CHANGELOG: insert `## [<version>] - <date>` under the untouched `[Unreleased]`.
   Entries cover end-user-relevant changes only — no internal details, no
   dependency specifics. Short: 1 line, ideally <80 chars (ok up to 120).
   Usually just `- Updated dependencies.`; also note a raised Go version or a
   security fix that matters.
9. Commit (one line, e.g. `Update dependencies`), push, open a PR to `main`.
   Technical detail belongs in the PR body: direct deps old → new, refactors,
   checks that passed, "merging auto-tags v<version>". After creating the PR,
   fetch the body back and strip any injected attribution footer.
10. Verify before finishing: branch pushed, tree clean, checks green, PR
    mergeable. If `main` moved meanwhile: rebase, resolve (keep both CHANGELOG
    entries, renumber yours), force-push with lease.

## Gotchas

- Tools may depend on each other (npub → notes): a dependent only sees the
  other's *tagged* release, so same-day updates leave it one release behind.
  Fine — the next run catches up.
- Updated linters may require a newer `go` directive; harmless
  (GOTOOLCHAIN=auto fetches it), worth a CHANGELOG line.
- A large go.sum shrink after a golangci-lint bump is normal: module-graph
  pruning drops stale transitive entries.

## Report

Per tool: status (updated / up-to-date / failed / skipped), version old → new,
PR URL, refactors made, critical incompatibilities. Remind that merging each PR
tags the release and `sync-tools` then installs it.
