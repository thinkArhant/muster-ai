#!/usr/bin/env bash
# test-commit.sh — fixture gate for muster-commit.sh (branch rule, 100-char subject, Rule 16 lint, undo on red, push on green).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/scripts"; for s in muster-commit.sh muster-lint-commit.sh muster-lint-write-lane.sh muster-read-test-patterns.sh; do cp "$HERE/$s" "$T/scripts/"; done
C="$T/scripts/muster-commit.sh"
pass=0; fail=0
run(){ out="$(cd "$T/repo" && bash "$C" "$@" 2>&1)"; rc=$?; }
t(){ local name="$1" wrc="$2" want="$3"; shift 3; run "$@"
  if [ "$rc" = "$wrc" ] && grep -qF -- "$want" <<<"$out"; then echo "PASS: $name"; pass=$((pass+1))
  else echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); fi; }
head_is(){ [ "$(cd "$T/repo" && git log -1 --format=%s)" = "$1" ]; }

git init -q -b main "$T/repo" 2>/dev/null || { git init -q "$T/repo"; git -C "$T/repo" checkout -q -b main; }
cd "$T/repo" && git config user.email t@t && git config user.name t && echo a > a && git add a && git commit -qm "init" && git checkout -q -b develop
git init -q --bare "$T/remote.git" && git remote add origin "$T/remote.git" && git push -q -u origin develop 2>/dev/null

echo b > b; t "commits on a work branch"             0 "COMMITTED"                     "developer: the hero streams the live run log"
head_is "developer: the hero streams the live run log" && { echo "PASS: subject landed"; pass=$((pass+1)); } || { echo "FAIL: subject"; fail=$((fail+1)); }
echo c > c; long="pm: $(printf 'x%.0s' {1..100})"
t "over-100 subject refused before git"    1 "subject is 104 chars (max 100)" "$long"
head_is "developer: the hero streams the live run log" && { echo "PASS: no commit made"; pass=$((pass+1)); } || { echo "FAIL: commit slipped"; fail=$((fail+1)); }
t "bad role prefix: commit undone"          1 "subject fails Rule 16 — commit undone" "Fix stuff"
head_is "developer: the hero streams the live run log" && [ -n "$(git diff --cached --name-only)" ] && { echo "PASS: HEAD unchanged, changes left staged"; pass=$((pass+1)); } || { echo "FAIL: undo"; fail=$((fail+1)); }
t "then a good subject commits the staged work" 0 "COMMITTED" --staged "qa: the stream has a blind net"
t "nothing to commit is OK"                 0 "OK: nothing to commit"          "qa: no-op"
echo d > d; t "pm subject runs the write lane (quiet here)" 0 "COMMITTED" "pm: gate one closed"
echo e > e; t "--push pushes after green"            0 "PUSHED develop"                 --push "developer: pushed change"
[ "$(git -C "$T/remote.git" log -1 --format=%s develop)" = "developer: pushed change" ] && { echo "PASS: remote has it"; pass=$((pass+1)); } || { echo "FAIL: remote"; fail=$((fail+1)); }
git checkout -q main; echo f > f
t "main refused by default"                 1 "REFUSED: on 'main'"             "xo: release"
t "--allow-main permits a release commit"   0 "COMMITTED"                     --allow-main "xo: release 5.1 tagged"
git checkout -q develop; mkdir -p .muster; echo 'MUSTER_WORK_BRANCH=sprint-13' > .muster/config; echo g > g
t "configured work branch enforced"         1 "work branch is 'sprint-13'"      "developer: wrong branch"
git checkout -q -b sprint-13
t "on the configured branch commits"        0 "COMMITTED"                     "developer: right branch"
t "no subject exits 3"                      3 "a subject is required"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
