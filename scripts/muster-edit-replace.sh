#!/usr/bin/env bash
# muster-edit-replace.sh — edit: replace exactly one text match or one heading's body, or refuse (family: edit — mutates only with --apply, asserts first).
#
# The verdict cascade is a dozen exact replacements across six files. The arogh PM hand-wrote a
# Python script for it at every gate (60–90 minutes) and once truncated the gate packet when a
# bare index() matched the same phrase inside a blockquote. This is that script, once, with the
# defect designed out: a match must be EXACTLY ONE or nothing is written; headings match only at
# column 0 and never inside a fenced block; the default run is a dry run that prints the diff.
#
# Two modes:
#   --text OLD --to NEW          replace the one occurrence of OLD (any string, may span lines)
#   --section "## Heading" --with BODYFILE   replace the body under that heading (the heading line
#                               stays; the body runs to the next heading of the same or higher
#                               level); BODYFILE "-" reads stdin
# Three verbs: (none) dry run → diff only · --check assert only, no output on success · --apply write
# Cascade pattern: run every operation with --check, then every one with --apply — nothing is
# written until all matches are proven unique.
#
# Usage: muster-edit-replace.sh --file F (--text OLD --to NEW | --section H --with BODYFILE) [--check|--apply]
# Exit: 0 ok · 1 zero or several matches (nothing written) · 3 usage
set -uo pipefail
file=""; mode=""; old=""; new=""; heading=""; bodyfile=""; verb="dry"
while [ $# -gt 0 ]; do
  case "$1" in
    --file) file="$2"; shift 2 ;;
    --text) mode="text"; old="$2"; shift 2 ;;
    --to) new="$2"; shift 2 ;;
    --section) mode="section"; heading="$2"; shift 2 ;;
    --with) bodyfile="$2"; shift 2 ;;
    --check) verb="check"; shift ;;
    --apply) verb="apply"; shift ;;
    *) echo "muster-edit-replace: unknown argument $1" >&2; exit 3 ;;
  esac
done
[ -n "$file" ] && [ -f "$file" ] || { echo "muster-edit-replace: --file F required (and F must exist)" >&2; exit 3; }
case "$mode" in
  text) [ -n "$old" ] || { echo "muster-edit-replace: --text OLD must be non-empty" >&2; exit 3; } ;;
  section) [ -n "$heading" ] && [ -n "$bodyfile" ] || { echo "muster-edit-replace: --section H --with BODYFILE required" >&2; exit 3; } ;;
  *) echo "muster-edit-replace: choose --text or --section" >&2; exit 3 ;;
esac
if [ "$mode" = section ]; then
  if [ "$bodyfile" = "-" ]; then new="$(cat)"; else [ -f "$bodyfile" ] || { echo "muster-edit-replace: no body file $bodyfile" >&2; exit 3; }; new="$(cat "$bodyfile")"; fi
fi
export MR_FILE="$file" MR_MODE="$mode" MR_OLD="$old" MR_NEW="$new" MR_HEADING="$heading" MR_VERB="$verb"
python3 - <<'PY'
import os, sys, re, difflib
f=os.environ["MR_FILE"]; mode=os.environ["MR_MODE"]; verb=os.environ["MR_VERB"]
src=open(f, encoding="utf-8").read()
if mode=="text":
    old=os.environ["MR_OLD"]; new=os.environ["MR_NEW"]
    n=src.count(old)
    if n!=1:
        print(f"REFUSED: --text matches {n} time(s) in {f} (need exactly 1); nothing written"); sys.exit(1)
    out=src.replace(old,new,1)
else:
    heading=os.environ["MR_HEADING"].rstrip(); body=os.environ["MR_NEW"]
    lines=src.split("\n"); fence=False; hits=[]
    for i,l in enumerate(lines):
        if l.startswith("```"): fence=not fence; continue
        if fence: continue
        if l.rstrip()==heading and re.match(r"^#{1,6} ", l): hits.append(i)
    if len(hits)!=1:
        print(f"REFUSED: heading {heading!r} found {len(hits)} time(s) at column 0 outside fences in {f} (need exactly 1); nothing written"); sys.exit(1)
    h=hits[0]; level=len(re.match(r"^(#+)", lines[h]).group(1))
    fence=False; end=len(lines)
    for j in range(h+1,len(lines)):
        l=lines[j]
        if l.startswith("```"): fence=not fence; continue
        if fence: continue
        m=re.match(r"^(#{1,6}) ", l)
        if m and len(m.group(1))<=level: end=j; break
    newbody=body.split("\n")
    if newbody and newbody[-1]=="": newbody=newbody[:-1]
    out="\n".join(lines[:h+1]+newbody+[""]+lines[end:]) if end<len(lines) else "\n".join(lines[:h+1]+newbody)+"\n"
if out==src:
    print(f"REFUSED: replacement is a no-op in {f}; nothing written"); sys.exit(1)
if verb=="check": sys.exit(0)
diff="".join(difflib.unified_diff(src.splitlines(True), out.splitlines(True), fromfile=f, tofile=f+" (new)"))
if verb=="dry":
    print(diff, end=""); print(f"DRY RUN: {f} unchanged — add --apply to write"); sys.exit(0)
tmp=f+".muster-edit.tmp"
with open(tmp,"w",encoding="utf-8") as w: w.write(out)
os.replace(tmp,f)
print(diff, end=""); print(f"APPLIED: {f}")
PY
