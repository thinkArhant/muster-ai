#!/usr/bin/env bash
# muster-lint-order.sh — lint: no queue step consumes a path a later step produces (family: lint — reports, never mutates).
#
# The field failure: a blind QA net written against an interface a later Developer step was going to
# declare — nobody had produced the name, QA invented one, and wrong-signature code compiled. In queue
# order (Next Step, then Upcoming; Done is history), for each step's Inputs path: if it exists on disk
# it is a modify, not a produce — fine; if it does not exist and a LATER step lists it as a
# Deliverable, the consumer runs before its producer → FAIL, naming both steps. The fix is a
# types-only skeleton step ahead of the net, or a reorder. Inputs nobody produces are left to
# muster-lint-anchors.sh. Exit: 0 clean · 1 FAIL · 3 usage.
#
# Usage: muster-lint-order.sh [queue-file]   default knowledge-base/orchestration-queue.md
set -uo pipefail
Q="${1:-knowledge-base/orchestration-queue.md}"
[ -f "$Q" ] || { echo "muster-lint-order: no queue at $Q" >&2; exit 3; }
export LO_Q="$Q"
python3 - <<'PY'
import os, re, sys
q=os.environ["LO_Q"]; lines=open(q,encoding="utf-8",errors="replace").read().split("\n")
TOK=re.compile(r"`([^`\s]+)`")
def is_path(t):
    if t.startswith(("http://","https://")) or any(c in t for c in "*[<>{}") or "path/to" in t: return False
    core=t.split(":")[0]
    return "/" in core or re.search(r"\.[A-Za-z0-9]{1,6}$", core) is not None
def paths(text): return [m.group(1).split(":")[0] for m in TOK.finditer(text) if is_path(m.group(1))]
steps=[]; fence=False; cur=None; heading=""; section=""; field=None
for l in lines:
    if not fence and re.match(r"^## ", l): section=l;
    if section.startswith("## Done"): break
    if l.startswith("```"):
        if not fence:
            fence=True; cur={"heading":heading or "(unnamed step)","inputs":[],"deliv":[]}; field=None
        else:
            fence=False; steps.append(cur); cur=None
        continue
    if not fence:
        if re.match(r"^### ", l): heading=re.sub(r"^### +","",l)
        continue
    low=l.lower().lstrip("*")
    if re.match(r"^inputs?[:*]", low): field="inputs"
    elif re.match(r"^deliverable[:*]", low): field="deliv"
    elif re.match(r"^[a-z][a-z -]*[:*]", low) and re.match(r"^(\*\*)?[A-Z]", l): field=None
    if field: cur[field].extend(paths(l))
fails=0
for i,s in enumerate(steps):
    for p in s["inputs"]:
        if os.path.exists(p): continue
        for j in range(i+1,len(steps)):
            if p in steps[j]["deliv"]:
                print(f"FAIL: \"{s['heading']}\" consumes `{p}` before \"{steps[j]['heading']}\" produces it — a cold agent will invent the interface; add a types-only step ahead of it or reorder"); fails+=1; break
print(f"checked {len(steps)} step(s) in {q}; {fails} ordering FAIL")
if fails: sys.exit(1)
print("OK: every producer precedes its consumers"); sys.exit(0)
PY
