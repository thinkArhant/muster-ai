#!/usr/bin/env bash
# muster-lint-test-delta.sh — lint: tests added and removed, and source changed without tests, over a commit range (family: lint — reports, never mutates).
#
# A green pass count proves nothing broke; it does not prove tests were written. The founder asked
# for that proof after a halt report quoted only the count ("prove the tests were added, not just
# passing"). Per platform over BASE..HEAD this prints: test files changed, test functions added and
# removed (diff lines matching the platform's test-function pattern from
# muster-read-test-patterns.sh), and
#   WARN — source files changed on a platform with no test file change on that platform
#   WARN — more test functions removed than added
# Warn-only (ramp rule: promoted to FAIL in a later commit once the field corpus is green).
# Unknown platforms are skipped. Exit: 0 reported · 3 bad ref / not a git repo.
#
# Usage: muster-lint-test-delta.sh [BASE[..HEAD]]      default BASE = HEAD~1
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/muster-read-test-patterns.sh" || { echo "muster-lint-test-delta: pattern table missing" >&2; exit 3; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "muster-lint-test-delta: not a git repo" >&2; exit 3; }
range="${1:-HEAD~1}"
case "$range" in *..*) ;; *) range="$range..HEAD" ;; esac
base="${range%%..*}"
git rev-parse --verify -q "$base" >/dev/null || { echo "muster-lint-test-delta: unknown ref '$base'" >&2; exit 3; }

files="$(git diff --name-only "$range" 2>/dev/null)"
if [ -z "$files" ]; then echo "OK: no file changes in $range"; exit 0; fi

count_matches(){ # $1=regex, stdin=lines -> count (0 when none; never fails the pipeline)
  local n; n="$(grep -cE -- "$1" || true)"; printf '%s' "${n:-0}"
}

warns=0; reported=0
for p in $PLATFORMS; do
  tfiles=""; sfiles=""; ntest=0; nsrc=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "$(platform_of "$f")" = "$p" ] || continue
    if is_test_file "$f"; then tfiles="$tfiles$f"$'\n'; ntest=$((ntest+1))
    else sfiles="$sfiles$f"$'\n'; nsrc=$((nsrc+1)); fi
  done <<<"$files"
  [ $((ntest+nsrc)) -gt 0 ] || continue
  reported=1
  re="$(test_fn_regex "$p")"
  added=0; removed=0
  if [ "$ntest" -gt 0 ]; then
    diff=""
    while IFS= read -r f; do [ -n "$f" ] && diff="$diff$(git diff "$range" -- "$f")"$'\n'; done <<<"$tfiles"
    added="$(sed -n 's/^+//p' <<<"$diff" | grep -v '^++' | count_matches "$re")"
    removed="$(sed -n 's/^-//p' <<<"$diff" | grep -v '^--' | count_matches "$re")"
  fi
  echo "$p: tests +$added -$removed across $ntest test file(s); $nsrc source file(s) changed"
  if [ "$nsrc" -gt 0 ] && [ "$ntest" -eq 0 ]; then
    warns=$((warns+1))
    echo "WARN: $p — $nsrc source file(s) changed with no test change on this platform:"
    printf '%s' "$sfiles" | sed '/^$/d; s/^/    /'
  fi
  if [ "$removed" -gt "$added" ]; then
    warns=$((warns+1)); echo "WARN: $p — more tests removed ($removed) than added ($added) in $range"
  fi
done

[ "$reported" -eq 1 ] || echo "OK: no files on a known test platform changed in $range"
if [ "$warns" -gt 0 ]; then echo "OK (warn-only): $warns warning(s) in $range"; else echo "OK: test delta clean in $range"; fi
exit 0
