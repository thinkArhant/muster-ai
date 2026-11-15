#!/usr/bin/env bash
# muster-commit.sh — action: one commit, on the right branch, with a subject that passes Rule 16, or no commit (family: verb — acts, refuses cleanly).
#
# Three founder rules lived only in memory and slipped anyway: verify the branch before committing;
# count the subject before pushing (a long subject on origin is permanent — force-push is denied);
# one commit per work unit. This is those rules as one command: it refuses on main (or off the
# configured work branch), refuses a subject over 100 characters before touching git, commits once,
# lints the subject with muster-lint-commit.sh and undoes the commit if the lint is red, and pushes
# only when everything is green. A `pm:` subject also runs the PM write-lane lint (warn-only) first.
#   --staged      commit only what is staged (default: stage everything, `git add -A`)
#   --push        push after a green lint
#   --allow-main  permit a commit on main/master (release commits)
# Branch rule: .muster/config MUSTER_WORK_BRANCH=<name> pins the branch; without it, any branch but
# main/master is accepted. Exit: 0 committed (or nothing to commit) · 1 refused · 3 usage.
#
# Usage: muster-commit.sh [--staged] [--push] [--allow-main] "<role>: <outcome>" [body…]
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
staged=0; push=0; allow_main="${MUSTER_ALLOW_MAIN:-0}"
while [ $# -gt 0 ]; do
  case "$1" in --staged) staged=1; shift ;; --push) push=1; shift ;; --allow-main) allow_main=1; shift ;; --*) echo "muster-commit: unknown flag $1" >&2; exit 3 ;; *) break ;; esac
done
subject="${1:-}"; shift || true
[ -n "$subject" ] || { echo "muster-commit: a subject is required" >&2; exit 3; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "muster-commit: not a git repo" >&2; exit 3; }

n="$(printf '%s' "$subject" | wc -m | tr -d ' ')"
[ "$n" -le 100 ] || { echo "REFUSED: subject is $n chars (max 100) — nothing committed: $subject"; exit 1; }

branch="$(git rev-parse --abbrev-ref HEAD)"
want=""; [ -f .muster/config ] && want="$(sed -n 's/^MUSTER_WORK_BRANCH=//p' .muster/config | tr -d "\"'" | head -1)"
if [ -n "$want" ] && [ "$branch" != "$want" ]; then echo "REFUSED: on '$branch', work branch is '$want' (.muster/config) — nothing committed"; exit 1; fi
if [ -z "$want" ] && [ "$allow_main" != 1 ]; then
  case "$branch" in main|master) echo "REFUSED: on '$branch' — commit on a work branch, or pass --allow-main for a release commit"; exit 1 ;; esac
fi

[ "$staged" -eq 1 ] || git add -A
git diff --cached --quiet && { echo "OK: nothing to commit on $branch"; exit 0; }

case "$subject" in pm:*) [ -x "$SCRIPT_DIR/muster-lint-write-lane.sh" ] && bash "$SCRIPT_DIR/muster-lint-write-lane.sh" --role pm 2>/dev/null | sed 's/^/  /' ;; esac

msg="$subject"; if [ $# -gt 0 ]; then msg="$subject"$'\n\n'"$(printf '%s\n' "$@")"; fi
git commit -q -m "$msg" || { echo "REFUSED: git commit failed"; exit 1; }
if ! lint="$(bash "$SCRIPT_DIR/muster-lint-commit.sh" HEAD 2>&1)"; then
  git reset -q --soft HEAD~1
  echo "REFUSED: subject fails Rule 16 — commit undone, changes left staged:"; printf '%s\n' "$lint" | sed 's/^/  /'; exit 1
fi
sha="$(git rev-parse --short HEAD)"
echo "COMMITTED $sha on $branch ($n-char subject): $subject"
if [ "$push" -eq 1 ]; then
  git push -q 2>&1 | sed 's/^/  /' && echo "PUSHED $branch" || { echo "REFUSED: push failed — commit kept locally"; exit 1; }
fi
exit 0
