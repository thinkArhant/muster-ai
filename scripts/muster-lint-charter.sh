#!/usr/bin/env bash
# muster-lint-charter.sh — lint: the sprint charter has its shape, and every number can go red (family: lint — reports, never mutates).
#
# The field failure: numbers were "ratified" with no test that could fail them, so QA had nothing to
# write blind and the number was untestable until a wave of rework. The charter's shape is the
# contract (templates/knowledge-base/sprint-charter.md; PM's `sprint-charter` skill):
#   FAIL — a required section is missing (§1 Scope line, §3 Numbers, §4 Success criteria,
#          §5 Non-goals, Candidates)
#   FAIL — a §3 row has no red check (empty, —, TBD, or still a [placeholder])
#   FAIL — a §3 row's Status is not PROPOSED / RATIFIED / AMENDED … / DEFERRED …
#   FAIL — (--ratified only) a §3 row is still PROPOSED: planning cannot start on an unratified number
#   WARN — a red check is manual ("manual: …") — allowed, named, flagged for the hardening pass
#   WARN — a §3 row says what changes in fewer than four words (an identifier is not a change)
#   WARN — a §5 non-goal has no "wake:" condition
# No charter file, or a Scope line still a [placeholder] → OK, nothing to lint.
#
# Usage: muster-lint-charter.sh [--ratified] [charter-file]   default knowledge-base/sprint-charter.md
# Exit: 0 clean (WARNs allowed) · 1 FAIL findings · 3 wiring error
set -uo pipefail
ratified=0; F="knowledge-base/sprint-charter.md"
for a in "$@"; do case "$a" in --ratified) ratified=1 ;; *) F="$a" ;; esac; done
[ -f "$F" ] || { echo "OK: no charter at $F — nothing to lint"; exit 0; }

scope="$(grep -m1 '^\*\*Scope:\*\*' "$F" | sed 's/^\*\*Scope:\*\*[[:space:]]*//')"
case "$scope" in ""|*"["*) echo "OK: no active charter in $F (scope is a placeholder) — nothing to lint"; exit 0 ;; esac

fails=0; warns=0
need(){ grep -qF -- "$1" "$F" || { echo "FAIL: $F lacks '$1' — the charter shape is the contract (template: templates/knowledge-base/sprint-charter.md)"; fails=$((fails+1)); }; }
need '### §1 Scope line'; need '### §3 Numbers'; need '### §4 Success criteria'; need '### §5 Non-goals'; need '## Candidates'

# §3 rows: between the Numbers heading and the next heading, table rows that are not header/separator
out="$(awk -v ratified="$ratified" '
  function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
  /^### §3 Numbers/ { sec=3; next }
  /^### §5 Non-goals/ { sec=5; next }
  /^#/ { sec=0; next }
  sec==3 && /^[[:space:]]*\|/ {
    if ($0 ~ /^[[:space:]]*\|[[:space:]]*-+/) next                       # separator
    n=split($0, c, /\|/)                                                  # c[2..n-1] are cells
    if (n<9) { printf "FAIL\t%d\t§3 row has %d cells, needs 7 (ID · what changes · evidence · rec · cost · red check · status)\n", NR, n-2; next }
    id=trim(c[2]); what=trim(c[3]); red=trim(c[7]); st=trim(c[8])
    gsub(/\*/, "", id); gsub(/\*/, "", red); gsub(/\*/, "", st); gsub(/\*/, "", what)
    if (id=="ID") next                                                    # header row
    lred=tolower(red)
    if (red=="" || red=="—" || red=="-" || lred=="tbd" || red ~ /\[/) printf "FAIL\t%d\t%s has no red check — a number nothing can fail cannot be ratified\n", NR, id
    else if (lred ~ /^manual/) printf "WARN\t%d\t%s is checked by hand (%s) — allowed; the hardening pass flags it\n", NR, id, red
    if (st !~ /^(PROPOSED|RATIFIED|AMENDED|DEFERRED)/) printf "FAIL\t%d\t%s status \"%s\" is not PROPOSED / RATIFIED / AMENDED <value> / DEFERRED <unblocks>\n", NR, id, st
    else if (ratified==1 && st ~ /^PROPOSED/) printf "FAIL\t%d\t%s is still PROPOSED — planning cannot start on an unratified number\n", NR, id
    nw=split(what, w, /[[:space:]]+/); if (what=="") nw=0
    if (nw<4) printf "WARN\t%d\t%s says what changes in %d word(s) — say what the user gets before the number\n", NR, id, nw
    next }
  sec==5 && /^[[:space:]]*-[[:space:]]/ {
    if ($0 ~ /\[/) next                                                   # template placeholder bullet
    if (tolower($0) !~ /wake:/) printf "WARN\t%d\tnon-goal has no \"wake:\" condition — say what pulls it back in\n", NR
    next }
' "$F")"
while IFS=$'\t' read -r kind ln msg; do
  [ -n "$kind" ] || continue
  echo "$kind: $F:$ln — $msg"
  case "$kind" in FAIL) fails=$((fails+1)) ;; WARN) warns=$((warns+1)) ;; esac
done <<<"$out"

if [ "$fails" -gt 0 ]; then echo "FAILED — $fails charter finding(s), $warns warning(s) in $F"; exit 1; fi
if [ "$warns" -gt 0 ]; then echo "OK: charter shape holds in $F ($warns warning(s) for the hardening pass)"; else echo "OK: charter shape holds in $F"; fi
exit 0
