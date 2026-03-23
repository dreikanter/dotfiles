#!/usr/bin/env bash
# Fetch GitHub activity for a given date.
# Usage: eod_github.sh <YYYY-MM-DD>
# Output: TSV lines grouped under === headers

set -euo pipefail

LOCAL_DATE="${1:?Usage: eod_github.sh YYYY-MM-DD}"
SEARCH_FROM=$(date -v-1d -j -f "%Y-%m-%d" "$LOCAL_DATE" +%Y-%m-%d)

echo "=== MY PRs ==="
gh pr list --author @me --state all --limit 30 \
  --json number,title,url,updatedAt,state,mergedAt \
  | python3 -c "
import sys, json
target = '$LOCAL_DATE'
search_from = '$SEARCH_FROM'
prs = json.load(sys.stdin)
for p in prs:
    updated = p['updatedAt'][:10]
    merged  = (p.get('mergedAt') or '')[:10]
    if updated >= search_from and (updated <= target or merged <= target):
        print(f\"{p['state']}\t{p['number']}\t{p['title']}\t{p['url']}\")
"

echo "=== REVIEWED ==="
# Two-step: search for candidate PRs, then verify review submission date.
# Reviews are permanent PR sub-resources — works for any date, no expiry.
python3 -c "
import subprocess, json

target = '$LOCAL_DATE'

_name_cache = {}
def resolve_name(login):
    if login in _name_cache:
        return _name_cache[login]
    r = subprocess.run(
        ['gh', 'api', f'/users/{login}', '--jq', '.name // empty'],
        capture_output=True, text=True)
    name = r.stdout.strip() if r.returncode == 0 else ''
    # Use first name only
    name = name.split()[0] if name else login
    _name_cache[login] = name
    return name

# Step 1: Find candidate PRs via search
result = subprocess.run(
    ['gh', 'search', 'prs', '--reviewed-by=@me', '--updated=>=' + target,
     '--limit', '50', '--json', 'number,repository'],
    capture_output=True, text=True)
if result.returncode != 0:
    exit(0)
candidates = json.loads(result.stdout)

# Step 2: Verify each candidate has a review submitted on the target date
seen = set()
for pr in candidates:
    repo = pr['repository']['nameWithOwner']
    num = pr['number']
    if (repo, num) in seen:
        continue
    seen.add((repo, num))
    result = subprocess.run(
        ['gh', 'api', f'/repos/{repo}/pulls/{num}/reviews',
         '--jq', '.[] | select(.user.login==\"dreikanter\") | .submitted_at'],
        capture_output=True, text=True)
    if result.returncode != 0:
        continue
    dates = [line[:10] for line in result.stdout.strip().split('\n') if line.strip()]
    if target not in dates:
        continue
    result = subprocess.run(
        ['gh', 'api', f'/repos/{repo}/pulls/{num}',
         '--jq', '.title + \"\t\" + .user.login'],
        capture_output=True, text=True)
    parts = result.stdout.strip().split('\t') if result.returncode == 0 else ['(unknown)', '']
    title = parts[0]
    login = parts[1] if len(parts) > 1 else ''
    name = resolve_name(login) if login else ''
    url = f'https://github.com/{repo}/pull/{num}'
    print(f'{num}\t{title}\t{name}\t{url}')
"
