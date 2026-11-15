#!/usr/bin/env bash
# test-lint-founder-surface.sh — fixture gate for muster-lint-founder-surface.sh (product-first founder files).
# Asserts: clean files pass; a bare-identifier bullet warns; identifier density warns; table rows,
# the Verdict section, fenced blocks and non-Founder-Decisions queue sections are exempt; warn-only
# exit stays 0; a missing directory exits 3.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/muster-lint-founder-surface.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
run(){ out="$(bash "$LINT" "$1" 2>&1)"; rc=$?; }
has(){ grep -qF -- "$2" <<<"$out" && { echo "PASS: $1"; pass=$((pass+1)); } || { echo "FAIL: $1"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); }; }
not(){ grep -qF -- "$2" <<<"$out" && { echo "FAIL: $1 (unexpected)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); } || { echo "PASS: $1"; pass=$((pass+1)); }; }

KB="$T/kb"; mkdir -p "$KB"
# --- clean corpus: product-first lines, a keyed table, a Verdict with IDs, a fence with IDs
cat > "$KB/wave-review.md" <<'EOF'
# Wave Review
<!-- HO-1 HO-2 HO-3 inside a comment are ignored -->
## Current Wave
**Wave:** 2 — PAPER gate, about 40 minutes, no phone
What you are judging: three numbers that decide how many sets a beginner does.

| ID | What changes | PM rec |
|---|---|---|
| **S12-N15** | Strength exercises get sets, two for beginners | ratify |

- Strength exercises get sets; beginners do two, everyone else three. Evidence in the research file. PM rec: ratify.
```
Step 12 HO-246 S12-N15 inside a fence is code, not speech
```
## Verdict
- S12-N15 — RATIFY
- HO-246 — done
EOF
cat > "$KB/founder-notices.md" <<'EOF'
# Founder Notices
- 2026-11-10 pm: The paper gate is ready — forty minutes, no phone needed, the packet is in wave-review.md.
EOF
cat > "$KB/orchestration-queue.md" <<'EOF'
## Founder Decisions
- [2026-11-10] PM: Should the reminder re-ask after five sessions or never? Recommendation: once, after five.
## Next Step
### Step 12 — Developer: HO-246 Step 13 S12-N15 HO-1 HO-2 (not a founder surface)
EOF
run "$KB"
has "clean corpus passes"            "OK: founder surfaces lead with the product"
not "table row with ID exempt"       "WARN: $KB/wave-review.md"
not "non-founder queue section exempt" "orchestration-queue.md"
[ "$rc" = 0 ] && { echo "PASS: clean exit 0"; pass=$((pass+1)); } || { echo "FAIL: clean exit $rc"; fail=$((fail+1)); }

# --- bare identifier bullets warn
cat > "$KB/founder-notices.md" <<'EOF'
# Founder Notices
- 2026-11-10 pm: HO-246 done.
- 2026-11-10 pm: Step 12 landed.
- 2026-11-10 pm: S12-N15 — RATIFIED.
EOF
run "$KB"
has "bare HO- lead warns"            "founder-notices.md:2 — leads with an identifier"
has "bare Step N lead warns"         "founder-notices.md:3 — leads with an identifier"
has "bare S-N lead warns"            "founder-notices.md:4 — leads with an identifier"
has "warn-only summary"              "OK (warn-only): 4 founder-surface warning(s)"   # 3 bare leads + density on a 15-word file
[ "$rc" = 0 ] && { echo "PASS: warn-only exit 0"; pass=$((pass+1)); } || { echo "FAIL: warn exit $rc"; fail=$((fail+1)); }

# --- a long sentence after the identifier does not warn (the key then the product words)
cat > "$KB/founder-notices.md" <<'EOF'
# Founder Notices
- 2026-11-10 pm: HO-246 — the hero now streams the live run log so you can watch a step land without opening the terminal.
EOF
run "$KB"
not "identifier followed by product words passes" "leads with an identifier"

# --- density warns
cat > "$KB/founder-notices.md" <<'EOF'
# Founder Notices
- 2026-11-10 pm: HO-240 HO-241 HO-242 closed; Step 31 Step 32 Step 33 done; S12-N15 S12-N16 S12-N17 S12-N18 ratified today.
EOF
run "$KB"
has "identifier density warns"       "identifier density"

# --- Founder Decisions bullet leading with an ID warns; the Next Step section still exempt
cat > "$KB/founder-notices.md" <<'EOF'
# Founder Notices
EOF
cat > "$KB/orchestration-queue.md" <<'EOF'
## Founder Decisions
- [2026-11-10] PM: Step 12 blocked.
## Next Step
### Step 12 — Developer: HO-246 HO-1 HO-2 HO-3
EOF
run "$KB"
has "Founder Decisions bare lead warns" "orchestration-queue.md:2 — leads with an identifier"

# --- missing dir
run "$T/nope"; [ "$rc" = 3 ] && { echo "PASS: missing dir exits 3"; pass=$((pass+1)); } || { echo "FAIL: missing dir rc=$rc"; fail=$((fail+1)); }

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
