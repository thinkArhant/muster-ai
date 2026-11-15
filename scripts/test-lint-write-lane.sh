#!/usr/bin/env bash
# test-lint-write-lane.sh — fixture gate for muster-lint-write-lane.sh (PM test lane + subagent deliverable guard).
# Asserts: a known-issue wrap and a rename pass the PM lane; a changed assertion value warns, in a
# range and in the working tree; an untracked test file's assertions warn; the deliverable guard
# allows the deliverable, directory prefixes and the four protocol files, and warns on tracked and
# untracked strays with the right revert command; usage errors exit 3; warn-only exit is 0.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/scripts"; cp "$HERE/muster-lint-write-lane.sh" "$HERE/muster-read-test-patterns.sh" "$T/scripts/"
L="$T/scripts/muster-lint-write-lane.sh"
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }; ko(){ echo "FAIL: $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/  got: /'; fail=$((fail+1)); }
run(){ out="$(cd "$T/repo" && bash "$L" "$@" 2>&1)"; rc=$?; }

mkdir -p "$T/repo/Sources" "$T/repo/Tests" "$T/repo/knowledge-base" && cd "$T/repo" && git init -q && git config user.email t@t && git config user.name t
cat > Tests/FooTests.swift <<'EOF'
import XCTest
final class FooTests: XCTestCase {
    func testRun() {
        XCTAssertEqual(Foo().run(), 1)
    }
}
EOF
echo "struct Foo { func run() -> Int { 1 } }" > Sources/Foo.swift
echo "struct B {}" > Sources/B.swift
echo "# requests" > knowledge-base/agent-requests.md
git add -A && git commit -qm "init"

# --- PM lane: a known-issue wrap + a rename carry no behavioural meaning
cat > Tests/FooTests.swift <<'EOF'
import XCTest
final class FooTests: XCTestCase {
    func testRunReturnsOne() {
        withKnownIssue("DEC-12: sets land in wave 2") {
            XCTAssertEqual(Foo().run(), 1)
        }
    }
}
EOF
run --role pm
[ "$rc" = 0 ] && grep -qF "OK: every write stayed in its lane" <<<"$out" && ok "marker wrap + rename pass (worktree)" || ko "wrap/rename" "$out"
git add -A && git commit -qm "pm: known-issue marker cites the decision"
run --role pm HEAD~1..HEAD
[ "$rc" = 0 ] && grep -qF "OK: every write" <<<"$out" && ok "marker wrap + rename pass (range)" || ko "wrap/rename range" "$out"

# --- PM lane: a changed assertion value warns
sed -i.bak 's/XCTAssertEqual(Foo().run(), 1)/XCTAssertEqual(Foo().run(), 2)/' Tests/FooTests.swift && rm Tests/FooTests.swift.bak
run --role pm
[ "$rc" = 0 ] && grep -qF "WARN: pm lane — assertion added or changed in Tests/FooTests.swift" <<<"$out" && grep -qF "OK (warn-only)" <<<"$out" && ok "assertion change warns (worktree), exit 0" || ko "assertion worktree" "$out"
git add -A && git commit -qm "pm: moved a threshold (should not)"
run --role pm HEAD~1..HEAD
grep -qF "WARN: pm lane — assertion added or changed" <<<"$out" && ok "assertion change warns (range)" || ko "assertion range" "$out"

# --- PM lane: untracked test file with assertions warns; source file ignored
cat > Tests/NewTests.swift <<'EOF'
import XCTest
final class NewTests: XCTestCase { func testX() { XCTAssertTrue(true) } }
EOF
echo "// tweak" >> Sources/Foo.swift
run --role pm
grep -qF "assertion added or changed in Tests/NewTests.swift" <<<"$out" && ! grep -qF "Sources/Foo.swift" <<<"$out" && ok "untracked test assertions warn; source ignored" || ko "untracked test" "$out"
rm Tests/NewTests.swift && git checkout -q -- Sources/Foo.swift

# --- deliverable guard
echo "struct B { let x = 1 }" > Sources/B.swift
echo "- HO-1 filed" >> knowledge-base/agent-requests.md
echo "- note" > knowledge-base/orchestration-queue.md
echo "struct Other {}" > Sources/Other.swift
echo "scratch" > notes.md
run --deliverable Sources/B.swift
grep -qF "WARN: out-of-lane write — Sources/Other.swift (untracked; remove: git clean -f -- 'Sources/Other.swift')" <<<"$out" && ok "untracked stray warns with clean command" || ko "untracked stray" "$out"
grep -qF "WARN: out-of-lane write — notes.md (untracked" <<<"$out" && ok "untracked root stray warns" || ko "notes stray" "$out"
! grep -qF "Sources/B.swift" <<<"$out" && ! grep -qF "agent-requests.md" <<<"$out" && ! grep -qF "orchestration-queue.md" <<<"$out" && ok "deliverable + protocol files allowed" || ko "allowed set" "$out"
[ "$rc" = 0 ] && grep -qF "OK (warn-only): 2 write-lane warning(s)" <<<"$out" && ok "two warnings, exit 0" || ko "count" "$out"
git add Sources/Other.swift && git commit -qm "developer: other" >/dev/null
echo "struct Other { let y = 2 }" > Sources/Other.swift
run --deliverable Sources/B.swift
grep -qF "WARN: out-of-lane write — Sources/Other.swift (revert: git checkout -- 'Sources/Other.swift')" <<<"$out" && ok "tracked stray warns with checkout command" || ko "tracked stray" "$out"
run --deliverable Sources/
! grep -qF "Sources/Other.swift" <<<"$out" && ok "directory prefix allows the whole tree" || ko "dir prefix" "$out"
rm -f notes.md; git checkout -q -- . ; git clean -fdq
run --deliverable Sources/B.swift
grep -qF "OK: no changes to check" <<<"$out" && ok "clean tree → nothing to check" || ko "clean tree" "$out"

run; [ "$rc" = 3 ] && ok "no mode exits 3" || ko "no mode" "$out"
run --role qa; [ "$rc" = 3 ] && ok "only pm lane defined" || ko "role qa" "$out"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
