#!/usr/bin/env bash
# muster-edit-insert-step.sh — edit: insert a queue step where the verdict puts it, or refuse (family: edit — mutates only with --apply, lints after).
#
# After a gate, PM inserts fix steps and founder adds into the queue by hand, and the hand slips:
# a step without a fence (the driver reads it as "sprint complete"), two steps in Next Step (the
# re-review gate gets dropped), a heading inside a fence. This inserts one step body — a
# `### Step N — Role: title` heading plus its fenced `Role:` block — at one of three places, then
# runs the queue and step lints on the result and RESTORES the file if either fails.
#   --after "### Step 11 — …"   after that step's block (heading matched exactly, col 0, not in a fence)
#   --first-upcoming           right after the `## Upcoming` heading and its comment lines
#   --as-next                  as the single Next Step; the current Next Step moves to the top of Upcoming
# Default is a dry run (diff only). Board rows are not touched: add the matching wave-table row with
# muster-edit-replace.sh --text (the lints prove queue and board agree).
#
# Usage: muster-edit-insert-step.sh --body STEPFILE (--after H | --first-upcoming | --as-next) [--queue Q] [--apply]
# Exit: 0 ok · 1 refused (anchor not unique, body malformed, or lints red after insert; queue unchanged) · 3 usage
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
queue="knowledge-base/orchestration-queue.md"; body=""; where=""; anchor=""; apply=0
while [ $# -gt 0 ]; do
  case "$1" in
    --queue) queue="$2"; shift 2 ;;
    --body) body="$2"; shift 2 ;;
    --after) where="after"; anchor="$2"; shift 2 ;;
    --first-upcoming) where="first"; shift ;;
    --as-next) where="next"; shift ;;
    --apply) apply=1; shift ;;
    *) echo "muster-edit-insert-step: unknown argument $1" >&2; exit 3 ;;
  esac
done
[ -f "$queue" ] || { echo "muster-edit-insert-step: no queue at $queue" >&2; exit 3; }
[ -n "$body" ] && [ -f "$body" ] || { echo "muster-edit-insert-step: --body STEPFILE required" >&2; exit 3; }
[ -n "$where" ] || { echo "muster-edit-insert-step: choose --after H, --first-upcoming or --as-next" >&2; exit 3; }

export IS_QUEUE="$queue" IS_BODY="$body" IS_WHERE="$where" IS_ANCHOR="$anchor" IS_APPLY="$apply"
python3 - <<'PY'
import os, sys, re, difflib
q=os.environ["IS_QUEUE"]; where=os.environ["IS_WHERE"]; anchor=os.environ["IS_ANCHOR"].rstrip(); apply=os.environ["IS_APPLY"]=="1"
body=open(os.environ["IS_BODY"],encoding="utf-8").read().rstrip("\n").split("\n")
if not re.match(r"^### Step \S+ — ", body[0]):
    print("REFUSED: step body must start with a '### Step N — Role: title' heading"); sys.exit(1)
if sum(1 for l in body if l.startswith("```"))<2 or not any(re.match(r"^Role:\s*\S", l) for l in body):
    print("REFUSED: step body needs a fenced block with a 'Role:' line (a fenceless step reads as sprint complete)"); sys.exit(1)
lines=open(q,encoding="utf-8").read().split("\n")
def headings():  # (index, line) for column-0 headings outside fences
    fence=False; out=[]
    for i,l in enumerate(lines):
        if l.startswith("```"): fence=not fence; continue
        if fence: continue
        if re.match(r"^#{1,6} ", l): out.append((i,l))
    return out
H=headings()
def find(pred, what):
    hits=[i for i,l in H if pred(l)]
    if len(hits)!=1: print(f"REFUSED: {what} found {len(hits)} time(s) (need exactly 1); queue unchanged"); sys.exit(1)
    return hits[0]
def block_end(start):  # first col-0 heading after start (outside fences), else EOF
    for i,l in H:
        if i>start: return i
    return len(lines)
up=find(lambda l: re.match(r"^#+ Upcoming\s*$", l), "'Upcoming' heading")
if where=="after":
    a=find(lambda l: l.rstrip()==anchor, f"step heading {anchor!r}")
    at=block_end(a)
    new=lines[:at]+body+[""]+lines[at:]
elif where=="first":
    at=up+1
    while at<len(lines) and (lines[at].startswith("<!--") or lines[at].strip()==""): at+=1
    new=lines[:at]+body+[""]+lines[at:]
else:
    ns=find(lambda l: l.startswith("## Next Step"), "'## Next Step' heading")
    # current step = from its first heading after Next Step to the Upcoming heading
    cur_start=next((i for i,l in H if ns<i<up), None)
    cur=lines[cur_start:up] if cur_start is not None else []
    while cur and cur[-1].strip()=="": cur.pop()
    head=lines[:cur_start] if cur_start is not None else lines[:up]
    while head and head[-1].strip()=="": head.pop()
    rest=lines[up+1:]
    k=0
    while k<len(rest) and (rest[k].startswith("<!--") or rest[k].strip()==""): k+=1
    new=head+[""]+body+[""]+[lines[up]]+rest[:k]+(cur+[""] if cur else [])+rest[k:]
out="\n".join(new)
diff="".join(difflib.unified_diff(lines, new, fromfile=q, tofile=q+" (new)", lineterm=""))
print(diff)
if not apply: print(f"DRY RUN: {q} unchanged — add --apply to write"); sys.exit(0)
open(q+".muster-edit.bak","w",encoding="utf-8").write("\n".join(lines))
open(q,"w",encoding="utf-8").write(out)
print(f"APPLIED: {q} (backup at {q}.muster-edit.bak until the lints pass)")
PY
rc=$?; [ "$rc" -eq 0 ] || exit "$rc"
[ "$apply" -eq 1 ] || exit 0
bak="$queue.muster-edit.bak"
if bash "$SCRIPT_DIR/muster-lint-queue.sh" "$queue" >/tmp/muster-insert-q.$$ 2>&1 && bash "$SCRIPT_DIR/muster-lint-step.sh" "$queue" >/tmp/muster-insert-s.$$ 2>&1; then
  rm -f "$bak" /tmp/muster-insert-q.$$ /tmp/muster-insert-s.$$; echo "OK: queue and step lints green after insert"; exit 0
fi
cat /tmp/muster-insert-q.$$ /tmp/muster-insert-s.$$ 2>/dev/null | sed 's/^/    /'; rm -f /tmp/muster-insert-q.$$ /tmp/muster-insert-s.$$
mv "$bak" "$queue"; echo "REFUSED: lints red after insert — queue restored unchanged"; exit 1
