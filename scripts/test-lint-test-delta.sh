#!/usr/bin/env bash
# test-lint-test-delta.sh — fixture gate for muster-lint-test-delta.sh (tests added/removed, untested source).
# Throwaway repo with swift + ts files; asserts per-platform counts, both WARN classes, the
# unknown-platform no-op, the empty range, and the bad-ref exit.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/scripts"; cp "$HERE/muster-lint-test-delta.sh" "$HERE/muster-read-test-patterns.sh" "$T/scripts/"
LINT="$T/scripts/muster-lint-test-delta.sh"
pass=0; fail=0
check(){ # name want-exit want-substring [range]
  local out rc; out="$(cd "$T/repo" && bash "$LINT" ${4:+"$4"} 2>&1)"; rc=$?
  if [ "$rc" = "$2" ] && grep -qF -- "$3" <<<"$out"; then echo "PASS: $1"; pass=$((pass+1))
  else echo "FAIL: $1 (rc=$rc want=$2)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); fi
}
nowarn(){ # name range — asserts no WARN line
  local out; out="$(cd "$T/repo" && bash "$LINT" "$2" 2>&1)"
  if grep -q '^WARN' <<<"$out"; then echo "FAIL: $1 (unexpected WARN)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1))
  else echo "PASS: $1"; pass=$((pass+1)); fi
}

mkdir -p "$T/repo/Sources" "$T/repo/Tests" "$T/repo/src" && cd "$T/repo" && git init -q && git config user.email t@t && git config user.name t
cat > Sources/Foo.swift <<'EOF'
struct Foo { func run() -> Int { 1 } }
EOF
cat > Tests/FooTests.swift <<'EOF'
import XCTest
final class FooTests: XCTestCase {
    func testRun() { XCTAssertEqual(Foo().run(), 1) }
    func testRunTwice() { XCTAssertEqual(Foo().run(), 1) }
}
EOF
cat > src/a.ts <<'EOF'
export const a = () => 1;
EOF
cat > src/a.test.ts <<'EOF'
it("returns one", () => { expect(a()).toBe(1); });
EOF
git add -A && git commit -qm "init"

# +1 swift test, +1 ts test
cat >> Tests/FooTests.swift <<'EOF'
extension FooTests {
    func testThird() { XCTAssertTrue(true) }
}
EOF
cat >> src/a.test.ts <<'EOF'
test.only("still one", () => { expect(a()).toBe(1); });
EOF
git add -A && git commit -qm "qa: a third run case and a focused ts case"
check "swift +1 counted"            0 "swift: tests +1 -0 across 1 test file(s); 0 source file(s) changed" HEAD~1
check "ts +1 counted"               0 "ts: tests +1 -0 across 1 test file(s); 0 source file(s) changed"    HEAD~1
nowarn "tests-only commit warns nothing" HEAD~1

# source only, no tests touched -> WARN
echo "// tweak" >> Sources/Foo.swift && git add -A && git commit -qm "developer: tweak"
check "untested source change warns" 0 "WARN: swift — 1 source file(s) changed with no test change" HEAD~1
check "warn-only exit stays 0"       0 "OK (warn-only)" HEAD~1

# remove two swift tests -> WARN more removed than added
cat > Tests/FooTests.swift <<'EOF'
import XCTest
final class FooTests: XCTestCase {
    func testRun() { XCTAssertEqual(Foo().run(), 1) }
}
EOF
git add -A && git commit -qm "developer: drop two cases"
check "removed > added warns"        0 "WARN: swift — more tests removed (2) than added (0)" HEAD~1

# unknown platform is a no-op
echo "puts 1" > z.rb && git add -A && git commit -qm "developer: ruby file"
check "unknown platform skipped"     0 "OK: no files on a known test platform changed" HEAD~1

# range forms + edge cases
check "explicit A..B range"          0 "swift: tests +1 -0" "HEAD~4..HEAD~3"
check "empty range"                  0 "OK: no file changes" "HEAD..HEAD"
check "bad ref exits 3"              3 "unknown ref" "nope-not-a-ref"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
