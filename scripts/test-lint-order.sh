#!/usr/bin/env bash
# test-lint-order.sh — fixture gate for muster-lint-order.sh (no consumer before its producer).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
L="$HERE/muster-lint-order.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
run(){ out="$(cd "$T" && bash "$L" "$@" 2>&1)"; rc=$?; }
has(){ grep -qF -- "$2" <<<"$out" && { echo "PASS: $1"; pass=$((pass+1)); } || { echo "FAIL: $1"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); }; }
not(){ grep -qF -- "$2" <<<"$out" && { echo "FAIL: $1 (unexpected)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); } || { echo "PASS: $1"; pass=$((pass+1)); }; }
rcis(){ [ "$rc" = "$2" ] && { echo "PASS: $1"; pass=$((pass+1)); } || { echo "FAIL: $1 (rc=$rc want=$2)"; fail=$((fail+1)); }; }

mkdir -p "$T/Sources"; echo "struct Existing {}" > "$T/Sources/Existing.swift"
cat > "$T/q.md" <<'EOF'
## Next Step
### Step 1 — QA (ios): blind net for sets
```
Role: qa
**Inputs:**
- `knowledge-base/sprint-charter.md`
- `Sources/SetPrescription.swift`
**Deliverable:** `Tests/SetTests.swift`
```
## Upcoming
### Step 2 — Developer (ios): modify an existing file
```
Role: developer
**Inputs:**
- `Sources/Existing.swift`
**Deliverable:** `Sources/Existing.swift`
```
### Step 3 — Developer (ios): build sets
```
Role: developer
**Inputs:**
- `Tests/SetTests.swift`
**Deliverable:** `Sources/SetPrescription.swift`
```
## Done (Last 10)
- old: produced `Sources/SetPrescription.swift` long ago (history, ignored)
EOF
run q.md
has "consumer before producer fails"   'FAIL: "Step 1 — QA (ios): blind net for sets" consumes `Sources/SetPrescription.swift` before "Step 3 — Developer (ios): build sets" produces it'
not "existing file is a modify, not a produce" "Sources/Existing.swift"
not "later consumer of earlier producer is fine" "Tests/SetTests.swift"
has "summary"                           "checked 3 step(s)"
rcis "FAIL → 1" 1

# skeleton step ahead of the net makes it green
cat > "$T/ok.md" <<'EOF'
## Next Step
### Step 1 — Developer (ios): types-only skeleton
```
Role: developer
**Inputs:**
- `knowledge-base/sprint-charter.md`
**Deliverable:** `Sources/SetPrescription.swift`
```
## Upcoming
### Step 2 — QA (ios): blind net for sets
```
Role: qa
**Inputs:**
- `Sources/SetPrescription.swift`
**Deliverable:** `Tests/SetTests.swift`
```
EOF
run ok.md
has "skeleton first passes"             "OK: every producer precedes its consumers"
rcis "clean → 0" 0

printf '## Next Step\n_(empty — sprint complete)_\n## Upcoming\n' > "$T/empty.md"
run empty.md; has "empty queue passes" "checked 0 step(s)"; rcis "empty → 0" 0
run nope.md; rcis "missing queue → 3" 3

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
