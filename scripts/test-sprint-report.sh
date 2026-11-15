#!/usr/bin/env bash
# test-sprint-report.sh — fixture gate for muster-sprint-report.sh (the mechanical half of the halt report).
# Throwaway project repo: a gate commit (wave-review.md touched), then work commits, a driver
# sweep commit, a swift test, a live notice, a queued Developer step and one open founder decision.
# Asserts every section, the default base (last gate), an explicit base, and the bad-ref exit.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
P="$T/proj"; mkdir -p "$P/muster/scripts" "$P/knowledge-base" "$P/Tests" "$P/Sources"
for s in muster-sprint-report.sh muster-read-queue.sh muster-lint-test-delta.sh muster-read-test-patterns.sh; do cp "$HERE/$s" "$P/muster/scripts/"; done
REP="$P/muster/scripts/muster-sprint-report.sh"
pass=0; fail=0
run(){ out="$(cd "$P" && bash "$REP" ${1:+"$1"} 2>&1)"; rc=$?; }
has(){ grep -qF -- "$2" <<<"$out" && { echo "PASS: $1"; pass=$((pass+1)); } || { echo "FAIL: $1"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); }; }
not(){ grep -qF -- "$2" <<<"$out" && { echo "FAIL: $1 (unexpected)"; fail=$((fail+1)); } || { echo "PASS: $1"; pass=$((pass+1)); }; }

cd "$P" && git init -q && git config user.email t@t && git config user.name t
cat > knowledge-base/orchestration-queue.md <<'EOF'
# Queue
## Founder Decisions
- [2026-11-10] PM: Re-ask the reminder once or never? Recommendation: once.
## Next Step
### Step 3 — Developer: the hero streams the live run log

```
Role: developer
**Task:** stream it
```
## Upcoming
EOF
cat > knowledge-base/founder-notices.md <<'EOF'
# Founder Notices
- 2026-11-10 developer: The second migration must be applied right after the first when Supabase is set up.
EOF
echo "# Wave Review" > knowledge-base/wave-review.md
echo "struct A {}" > Sources/A.swift
git add -A && git commit -qm "pm: gate one closed"
git -c commit.gpgsign=false commit -q --allow-empty -m "noise before gate"
echo "# Wave Review (gate 2 packet)" > knowledge-base/wave-review.md && git add -A && git commit -qm "pm: wave 2 gate packet written"
GATE="$(git rev-parse --short HEAD)"

echo "struct B {}" > Sources/B.swift && git add -A && git commit -qm "developer: the hero streams the live run log"
cat > Tests/ATests.swift <<'EOF'
import XCTest
final class ATests: XCTestCase {
    func testStreams() { XCTAssertTrue(true) }
}
EOF
git add -A && git commit -qm "qa: the stream has a blind net"
echo "x" > scratch.txt && git add -A && git commit -qm "sprint step boundary: ### Step 2 — QA: net"

run
has "header names the gate base"      "## What landed since $GATE (3 commit(s))"
has "work commit listed as product"   "- developer: the hero streams the live run log"
has "qa commit listed"                "- qa: the stream has a blind net"
has "driver sweep summarised"         "1 step-boundary sweep commit(s)"
not "sweep not listed as work"        "- sprint step boundary"
not "pre-gate commit excluded"        "noise before gate"
has "tests section shows delta"       "swift: tests +1 -0"
has "notice verbatim"                 "- 2026-11-10 developer: The second migration must be applied right after the first when Supabase is set up."
has "next step named with role"       "- next step (developer): Step 3 — Developer: the hero streams the live run log"
has "open founder decisions counted"  "- founder decisions waiting: 1"
has "PM judgment stub present"        "## PM writes (judgment)"
[ "$rc" = 0 ] && { echo "PASS: exit 0"; pass=$((pass+1)); } || { echo "FAIL: exit $rc"; fail=$((fail+1)); }

run "HEAD~1"
has "explicit base honoured"          "## What landed since $(git rev-parse --short HEAD~1) (1 commit(s))"

run "not-a-ref"; [ "$rc" = 3 ] && { echo "PASS: bad ref exits 3"; pass=$((pass+1)); } || { echo "FAIL: bad ref rc=$rc"; fail=$((fail+1)); }

# queue complete + no notices file
printf '# Queue\n## Next Step\n_(empty — sprint complete)_\n' > knowledge-base/orchestration-queue.md
rm knowledge-base/founder-notices.md
run "HEAD~1"
has "queue complete reported"         "- queue complete — nothing queued"
has "no notices file -> none"         "none"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
