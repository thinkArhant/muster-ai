#!/usr/bin/env bash
# test-lint-context-dup.sh — fixture gate for muster-lint-context-dup.sh (context lines duplicated from the layers above).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
L="$HERE/muster-lint-context-dup.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
run(){ out="$(cd "$T" && bash "$L" "$@" 2>&1)"; rc=$?; }
has(){ grep -qF -- "$2" <<<"$out" && { echo "PASS: $1"; pass=$((pass+1)); } || { echo "FAIL: $1"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); }; }
not(){ grep -qF -- "$2" <<<"$out" && { echo "FAIL: $1 (unexpected)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); } || { echo "PASS: $1"; pass=$((pass+1)); }; }

mkdir -p "$T/knowledge-base/agent-context" "$T/muster/team/developer"
printf '# Project\n- **Tech stack**: Swift 6, SwiftUI, SwiftData, Supabase backend, pnpm for the web tool\n' > "$T/CLAUDE.md"
printf '# Muster\n1. **PM is the hub** — PM is the ONLY role that writes to agent-context files and protocol files.\n' > "$T/muster/CLAUDE.md"
printf '# Guide\nAgents communicate via agent-requests.md using requests and handoffs, checked at session start.\n' > "$T/muster/system-guide.md"
printf '# Developer Agent\n## Role\nYou write production-quality code following platform best practices and modern architecture patterns.\n' > "$T/muster/team/developer/CLAUDE.md"
cat > "$T/knowledge-base/agent-context/developer.md" <<'EOF'
# Developer Context — Arogh
<!-- PM-MANAGED -->
## Product Context
- **Tech stack**: Swift 6, SwiftUI, SwiftData, Supabase backend, pnpm for the web tool
- The recovery engine serves one workout a day from the readiness map; the player is hands-free.
- You write production-quality code following platform best practices and modern architecture patterns.
- [Feature directory mapping placeholder stays ignored]
## Current Tasks
- Build the hands-free player per the approved spec section 4.
EOF
run
has "duplicate of project CLAUDE.md warns"   "developer.md:4 duplicates CLAUDE.md"
has "duplicate of brain file warns"           "developer.md:6 duplicates muster/team/developer/CLAUDE.md"
not "unique synthesis line is quiet"           "readiness map"
not "placeholder line skipped"                 "placeholder"
has "count and warn-only summary"              "2 duplicate(s)"
[ "$rc" = 0 ] && { echo "PASS: exit 0"; pass=$((pass+1)); } || { echo "FAIL: exit $rc"; fail=$((fail+1)); }
printf '# Developer Context — Arogh\n## Product Context\n- The recovery engine serves one workout a day from the readiness map; the player is hands-free.\n## Current Tasks\n- Build the player.\n' > "$T/knowledge-base/agent-context/developer.md"
run developer
has "clean context passes"                    "OK: agent-context files carry only what the layers above do not"
run nope; has "unknown role reported, no crash" "no knowledge-base/agent-context/nope.md"
rm -r "$T/knowledge-base/agent-context"; run; [ "$rc" = 3 ] && { echo "PASS: missing dir exits 3"; pass=$((pass+1)); } || { echo "FAIL: missing dir rc=$rc"; fail=$((fail+1)); }

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
