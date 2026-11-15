#!/usr/bin/env bash
# test-lint-charter.sh — fixture gate for muster-lint-charter.sh (charter shape; every number can go red).
# Asserts: no file / placeholder scope → OK; the seeded template is quiet; a full charter passes;
# missing section, empty red check, bad status FAIL; manual check, short "what changes", non-goal
# without wake WARN; --ratified FAILs a PROPOSED row and passes a RATIFIED one.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/muster-lint-charter.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
t(){ # name want-exit want-substring [args…]
  local name="$1" wrc="$2" want="$3"; shift 3
  local out rc; out="$(bash "$LINT" "$@" 2>&1)"; rc=$?
  if [ "$rc" = "$wrc" ] && grep -qF -- "$want" <<<"$out"; then echo "PASS: $name"; pass=$((pass+1))
  else echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); fi
}
nowarn(){ local out; out="$(bash "$LINT" "$2" 2>&1)"; if grep -q '^WARN' <<<"$out"; then echo "FAIL: $1 (unexpected WARN)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); else echo "PASS: $1"; pass=$((pass+1)); fi; }

t "missing file is OK"        0 "OK: no charter"                     "$T/none.md"
t "seeded template is quiet"  0 "OK: no active charter"              "$HERE/../templates/knowledge-base/sprint-charter.md"

good="$T/good.md"
cat > "$good" <<'EOF'
# Sprint Charter
## Charter — Sprint 13
**Scope:** A beginner with three days a week gets an honest week that the engine honours as rest — RATIFIED 2026-11-20
### §1 Scope line
One sentence, two waves.
### §2 Ratified decisions
| ID | Decision | Alternatives rejected |
|---|---|---|
| C13-1 | Two waves, small first | one big wave |
### §3 Numbers
| ID | What changes for the user | Evidence | PM rec | Cost | Red check | Status |
|---|---|---|---|---|---|---|
| **S13-N1** | Planned off days count as real rest for the engine | research §3.2 | ratify | S | `RestDayTests.testOffDayIsRest` red today | RATIFIED |
| **S13-N2** | The weekly streak counts weeks you hit your chosen days | research §1.4 | ratify | M | manual: founder checks the Plan tab on day 8 | AMENDED 3 of N |
### §4 Success criteria
1. The low-frequency harness arm is green.
### §5 Non-goals
- Multi-set prescription — needs the player first — wake: the player ships
### §6 Already ratified — do not re-litigate
### §7 Process notes
### §8 Evidence
## Candidates — next sprint
- Lock-screen pause `gate`
EOF
t "full charter passes"       0 "OK: charter shape holds"            "$good"
t "manual check warns"        0 "WARN: $good:14 — S13-N2 is checked by hand" "$good"
t "--ratified passes when ratified" 0 "OK: charter shape holds"       --ratified "$good"

bad="$T/bad.md"
sed -e 's/^### §5 Non-goals$/### Out of scope/' "$good" > "$bad"
t "missing required section FAILs" 1 "FAIL: $bad lacks '### §5 Non-goals'" "$bad"

sed -e 's/`RestDayTests.testOffDayIsRest` red today/—/' "$good" > "$bad"
t "empty red check FAILs"     1 "S13-N1 has no red check"             "$bad"
sed -e 's/`RestDayTests.testOffDayIsRest` red today/[blind test]/' "$good" > "$bad"
t "placeholder red check FAILs" 1 "S13-N1 has no red check"           "$bad"

sed -e 's/| RATIFIED |/| approved |/' "$good" > "$bad"
t "bad status FAILs"          1 'S13-N1 status "approved" is not'      "$bad"

sed -e 's/| RATIFIED |/| PROPOSED |/' "$good" > "$bad"
t "PROPOSED passes without --ratified" 0 "OK: charter shape holds"    "$bad"
t "PROPOSED FAILs under --ratified"    1 "S13-N1 is still PROPOSED — planning cannot start" --ratified "$bad"

sed -e 's/Planned off days count as real rest for the engine/S13-N1/' "$good" > "$bad"
t "short what-changes warns"  0 "says what changes in 1 word(s)"       "$bad"

sed -e 's/ — wake: the player ships//' "$good" > "$bad"
t "non-goal without wake warns" 0 'non-goal has no "wake:" condition'  "$bad"

sed -e '/^| \*\*S13-N1\*\*/s/| RATIFIED |/| RATIFIED/' "$good" > "$bad"
t "wrong cell count FAILs"    1 "needs 7"                              "$bad"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
