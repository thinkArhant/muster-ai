#!/usr/bin/env bash
# muster-lint-founder-surface.sh — lint: founder-facing files lead with the product, not a bare identifier (family: lint — reports, never mutates).
#
# Doctrine: founder-facing speech is plain, product-first, never a bare identifier — the founder
# reads without the file open and does not carry step or handoff numbers in their head. Chat
# cannot be linted; these files can: the gate packet, the notices, the queue's Founder Decisions.
#   WARN — a bullet or paragraph whose first words are an identifier (HO-/REQ-/DEC-/BUG-NNN,
#          Step N, S<n>-N<n>) and whose rest is under six words — the identifier IS the message
#   WARN — identifier density above 4 per 100 words in a file — the reader has to decode
# Exempt: table rows (keyed tables are structure, the walk needs the keys), fenced blocks, HTML
# comments, and the `## Verdict` section (the founder's own answers in the gate vocabulary).
# Warn-only (ramp rule). Exit: 0 · 3 usage.
#
# Usage: muster-lint-founder-surface.sh [kb-dir]      default knowledge-base
set -uo pipefail
KB="${1:-knowledge-base}"
[ -d "$KB" ] || { echo "muster-lint-founder-surface: no directory $KB" >&2; exit 3; }

ID='(HO|REQ|DEC|BUG)-[0-9]+|S[0-9]+-N[0-9]+[a-z]?|Step[[:space:]-]+[0-9]+[a-z]?'
warns=0

scan(){ # $1=file $2=section-filter: "" whole file | "founder-decisions" only that section
  local f="$1" mode="${2:-}"
  [ -f "$f" ] || return 0
  local out
  out="$(awk -v mode="$mode" -v ID="$ID" '
    BEGIN{ infence=0; incomment=0; skip=0; words=0; ids=0 }
    /^```/ { infence=!infence; next }
    infence { next }
    { line=$0
      if (incomment) { if (index(line,"-->")) { incomment=0 }; next }
      if (index(line,"<!--")) { if (!index(line,"-->")) incomment=1; next } }
    /^## / { if (mode=="founder-decisions") { skip = ($0 !~ /^## Founder Decisions/) }
             else { skip = ($0 ~ /^## Verdict/) } ; next }
    skip { next }
    /^[[:space:]]*\|/ { next }
    { t=$0; gsub(/[*_>#`]/, "", t); sub(/^[[:space:]]*[-*][[:space:]]*/, "", t); sub(/^[[:space:]]+/, "", t)
      sub(/^\[?20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]\]?[[:space:]]+[A-Za-z\/-]+:[[:space:]]*/, "", t)   # entry prefix: date + role
      if (t=="") next
      nw=split(t, w, /[[:space:]]+/); words+=nw
      tmp=t; ids+=gsub("(" ID ")", "", tmp)
      if (match(t, "^(" ID ")")) {
        rest=substr(t, RLENGTH+1); gsub(/^[[:space:]:—–-]+/, "", rest)
        nr=split(rest, r, /[[:space:]]+/); if (rest=="") nr=0
        if (nr<6) printf "WARN\t%d\tleads with an identifier and says little else: %s\n", NR, substr(t,1,70)
      } }
    END{ if (words>0) { d=ids*100/words; if (d>4) printf "WARN\t0\tidentifier density %.1f per 100 words (%d ids / %d words) — the founder has to decode\n", d, ids, words } }
  ' "$f")"
  if [ -n "$out" ]; then
    while IFS=$'\t' read -r kind ln msg; do
      [ -n "$kind" ] || continue
      warns=$((warns+1))
      if [ "$ln" = "0" ]; then echo "WARN: $f — $msg"; else echo "WARN: $f:$ln — $msg"; fi
    done <<<"$out"
  fi
}

scan "$KB/wave-review.md"
scan "$KB/founder-notices.md"
scan "$KB/orchestration-queue.md" founder-decisions

if [ "$warns" -gt 0 ]; then echo "OK (warn-only): $warns founder-surface warning(s) — say what it does before its number"
else echo "OK: founder surfaces lead with the product"; fi
exit 0
