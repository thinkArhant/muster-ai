#!/usr/bin/env bash
# test-lint-anchors.sh — fixture gate for muster-lint-anchors.sh (anchors resolve on disk, to line, to symbol, to section).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
L="$HERE/muster-lint-anchors.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
run(){ out="$(cd "$T" && bash "$L" "$@" 2>&1)"; rc=$?; }
has(){ grep -qF -- "$2" <<<"$out" && { echo "PASS: $1"; pass=$((pass+1)); } || { echo "FAIL: $1"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); }; }
not(){ grep -qF -- "$2" <<<"$out" && { echo "FAIL: $1 (unexpected)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); } || { echo "PASS: $1"; pass=$((pass+1)); }; }
rcis(){ [ "$rc" = "$2" ] && { echo "PASS: $1"; pass=$((pass+1)); } || { echo "FAIL: $1 (rc=$rc want=$2)"; fail=$((fail+1)); }; }

mkdir -p "$T/Sources" "$T/knowledge-base/agent-context"
{ for i in $(seq 1 40); do echo "line $i"; done; echo "func computeDose() {}"; for i in $(seq 42 60); do echo "line $i"; done; } > "$T/Sources/Engine.swift"   # symbol at 41
printf '# Spec\n\n## Queue Step Format\ntext\n\n## Sprint Closeout\ntext\n' > "$T/knowledge-base/spec.md"
cat > "$T/knowledge-base/orchestration-queue.md" <<'EOF'
## Next Step
### Step 1 — Developer: all good
```
Role: developer
**Inputs:**
- `Sources/Engine.swift:41` (`computeDose`)
- `knowledge-base/spec.md` → Queue Step Format
- `path/to/placeholder.md` and `https://example.com/x.md` and `[design spec]`
**Deliverable:** `Sources/Engine.swift`
```
## Upcoming
### Step 2 — QA: drifted and broken anchors
```
Role: qa
**Inputs:**
- `Sources/Engine.swift:12` (`computeDose`)
- `Sources/Engine.swift:99`
- `Sources/Missing.swift`
- `Sources/Engine.swift` → `noSuchSymbol`
- `knowledge-base/spec.md` → Verdict Walk
**Deliverable:** `Tests/EngineTests.swift`
```
EOF
printf '# Dev\n## Current Tasks\n- read `Sources/Engine.swift:41` (`computeDose`) and `Sources/Gone.swift`\n' > "$T/knowledge-base/agent-context/developer.md"

run knowledge-base/orchestration-queue.md
has "symbol at line resolves silently"      "checked"
not "good anchor not reported"               "Step 1"
has "moved symbol warns with new line"       "WARN: knowledge-base/orchestration-queue.md:16 — \`Sources/Engine.swift:12\` (\`computeDose\`) moved: now at line 41"
has "line past EOF fails"                    "FAIL: knowledge-base/orchestration-queue.md:17 — \`Sources/Engine.swift:99\` points past the end of the file (60 lines)"
has "missing file fails"                     "FAIL: knowledge-base/orchestration-queue.md:18 — \`Sources/Missing.swift\` does not exist"
has "absent symbol fails"                    "FAIL: knowledge-base/orchestration-queue.md:19 — \`Sources/Engine.swift\` names \`noSuchSymbol\`, which is not in the file"
has "missing section warns"                  "WARN: knowledge-base/orchestration-queue.md:20 — \`knowledge-base/spec.md\` → \"Verdict Walk\" names a section the file does not have"
not "existing section is quiet"              "Queue Step Format"
not "placeholders, urls and brackets skipped" "path/to"
has "summary counts"                         "FAIL, 2 WARN"
rcis "FAIL → exit 1" 1

run
has "default set includes agent-context"     "FAIL: knowledge-base/agent-context/developer.md:3 — \`Sources/Gone.swift\` does not exist"

printf '## Next Step\n### Step 1 — Developer: fine\n```\nRole: developer\n**Inputs:**\n- `Sources/Engine.swift:41` (`computeDose`)\n**Deliverable:** `Sources/Engine.swift`\n```\n' > "$T/clean.md"
run clean.md
has "clean queue passes"                     "OK: every anchor resolves"
rcis "clean → exit 0" 0

run nope.md; rcis "no input files → 3" 3

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
