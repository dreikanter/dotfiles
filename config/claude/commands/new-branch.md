---
argument-hint: branch-name
---

Create new git branch with name "#$ARGUMENTS".

Pre-checks (interrupt if failed):
- Verify git repository exists
- Branch name provided (prompt if missing)
- Branch doesn't already exist
- Branch name ≤50 characters

Normalize branch name:
- Lowercase, single dashes for words, no special chars except dashes/slashes
- Trim whitespace

Examples: feature/user-auth, fix/redirect-bug, chore/update-deps
