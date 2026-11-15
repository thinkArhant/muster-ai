#!/usr/bin/env bash
# muster-lint-write-lane.sh — lint: writes stay in their lane — PM never edits an assertion, a subagent never leaves its deliverable (family: lint — reports, never mutates).
#
# Two field failures, one check: (1) the arogh PM made nine commits editing tests after rulings and
# no rule bounded it — the role drifted toward integrator; (2) spawned subagents edited PM-owned
# queue and generated files outside their task and the result was trusted. Both are "which lines
# changed, and were they allowed". Two modes over the same change set:
#   --role pm            WARN every added or removed ASSERTION line in a test file (patterns per
#                        platform from muster-read-test-patterns.sh). Markers, renames, fixtures,
#                        plumbing and reverts carry no behavioural meaning and pass; an assertion
#                        body, threshold or tolerance is QA's (RED first) then Developer's.
#   --deliverable P…     WARN every changed file outside the allowed paths P… (files or directory
#                        prefixes). The protocol files every role writes at closeout are always
#                        allowed: agent-requests.md, orchestration-queue.md, decision-log.md,
#                        founder-notices.md. Each warning prints the revert command.
# Change set: a git RANGE (A..B) when given, else the working tree vs HEAD (staged, unstaged and
# untracked). Warn-only (ramp rule; founder call: lint warns first). Exit: 0 · 3 usage.
#
# Usage: muster-lint-write-lane.sh --role pm [RANGE]
#        muster-lint-write-lane.sh --deliverable PATH [PATH…] [RANGE]
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/muster-read-test-patterns.sh" || { echo "muster-lint-write-lane: pattern table missing" >&2; exit 3; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "muster-lint-write-lane: not a git repo" >&2; exit 3; }

mode=""; role=""; allowed=""; range=""
while [ $# -gt 0 ]; do
  case "$1" in
    --role) mode="role"; role="$2"; shift 2 ;;
    --deliverable) mode="deliverable"; shift; while [ $# -gt 0 ] && [ "${1#--}" = "$1" ] && [ "${1##*..*}" = "$1" ]; do allowed="$allowed$1"$'\n'; shift; done ;;
    *..*) range="$1"; shift ;;
    *) echo "muster-lint-write-lane: unknown argument $1" >&2; exit 3 ;;
  esac
done
[ -n "$mode" ] || { echo "muster-lint-write-lane: --role pm or --deliverable PATH… required" >&2; exit 3; }
[ "$mode" = role ] && [ "$role" != pm ] && { echo "muster-lint-write-lane: only --role pm is defined" >&2; exit 3; }

if [ -n "$range" ]; then
  git rev-parse --verify -q "${range%%..*}" >/dev/null || { echo "muster-lint-write-lane: unknown ref in $range" >&2; exit 3; }
  files="$(git diff --name-only "$range")"
  diff_of(){ git diff "$range" -- "$1"; }
else
  files="$(git status --porcelain --untracked-files=all | awk '{print $NF}')"
  diff_of(){ if git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; then git diff HEAD -- "$1"; else sed 's/^/+/' "$1"; fi; }
fi
[ -n "$files" ] || { echo "OK: no changes to check"; exit 0; }
warns=0

if [ "$mode" = role ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    p="$(platform_of "$f")"; [ -n "$p" ] || continue
    is_test_file "$f" || continue
    re="$(assert_regex "$p")"
    d="$(diff_of "$f" | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' || true)"
    # trimmed assertion lines removed vs added; a wrap, move or re-indent cancels out, a changed body does not
    rem="$(sed -n 's/^-//p' <<<"$d" | grep -E -- "$re" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sort || true)"
    add="$(sed -n 's/^+//p' <<<"$d" | grep -E -- "$re" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sort || true)"
    only_rem="$(comm -23 <(printf '%s\n' "$rem" | sed '/^$/d') <(printf '%s\n' "$add" | sed '/^$/d'))"
    only_add="$(comm -13 <(printf '%s\n' "$rem" | sed '/^$/d') <(printf '%s\n' "$add" | sed '/^$/d'))"
    while IFS= read -r h; do [ -n "$h" ] || continue; warns=$((warns+1)); echo "WARN: pm lane — assertion removed in $f: ${h:0:110}"; done <<<"$only_rem"
    while IFS= read -r h; do [ -n "$h" ] || continue; warns=$((warns+1)); echo "WARN: pm lane — assertion added or changed in $f: ${h:0:110}"; done <<<"$only_add"
  done <<<"$files"
  [ "$warns" -gt 0 ] && echo "    an assertion body, threshold or tolerance is QA's to change (RED first), then Developer's — route it as a step"
else
  always=$'knowledge-base/agent-requests.md\nknowledge-base/orchestration-queue.md\nknowledge-base/decision-log.md\nknowledge-base/founder-notices.md'
  allowed="$allowed$always"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    ok=0
    while IFS= read -r a; do
      [ -n "$a" ] || continue
      a="${a%/}"
      if [ "$f" = "$a" ] || [ "${f#"$a"/}" != "$f" ]; then ok=1; break; fi
    done <<<"$allowed"
    [ "$ok" -eq 1 ] && continue
    warns=$((warns+1))
    if git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then echo "WARN: out-of-lane write — $f (revert: git checkout -- '$f')"
    else echo "WARN: out-of-lane write — $f (untracked; remove: git clean -f -- '$f')"; fi
  done <<<"$files"
fi

if [ "$warns" -gt 0 ]; then echo "OK (warn-only): $warns write-lane warning(s)"; else echo "OK: every write stayed in its lane"; fi
exit 0
