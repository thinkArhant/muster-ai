#!/usr/bin/env bash
# muster-lint-context-dup.sh — lint: an agent-context file holds only what the three layers above it do not (family: lint — reports, never mutates).
#
# Every bind pays for the project CLAUDE.md, muster/CLAUDE.md and the role's brain file before it
# reads agent-context. A line repeated in the context file is paid twice per session, forever. The
# founder's rule: agent-context holds only PM-filtered synthesis not already in those files. This
# WARNs every substantive line (40+ chars, not a heading, comment or placeholder) of
# knowledge-base/agent-context/<role>.md that also appears, whitespace-normalised, in CLAUDE.md,
# muster/CLAUDE.md, muster/system-guide.md or muster/team/<role>/CLAUDE.md. Warn-only.
# Exit: 0 · 3 no agent-context directory.
#
# Usage: muster-lint-context-dup.sh [role…]   default: every <role>.md under knowledge-base/agent-context/
set -uo pipefail
CTX="knowledge-base/agent-context"
[ -d "$CTX" ] || { echo "muster-lint-context-dup: no $CTX" >&2; exit 3; }
if [ $# -gt 0 ]; then roles="$*"; else roles="$(ls "$CTX"/*.md 2>/dev/null | sed 's#.*/##; s/\.md$//' | tr '\n' ' ')"; fi
export CD_CTX="$CTX" CD_ROLES="$roles"
python3 - <<'PY'
import os, re, sys
ctx=os.environ["CD_CTX"]; roles=os.environ["CD_ROLES"].split()
def norm(l):
    l=re.sub(r"^[\s>*-]+","",l).strip(); l=re.sub(r"\s+"," ",l); return l
def lines(p):
    try: return open(p,encoding="utf-8",errors="replace").read().split("\n")
    except OSError: return []
def substantive(l):
    n=norm(l)
    return len(n)>=40 and not l.lstrip().startswith(("#","<!--")) and "[" not in n and not n.startswith("|")
warns=0; checked=0
for r in roles:
    f=f"{ctx}/{r}.md"
    if not os.path.isfile(f): print(f"muster-lint-context-dup: no {f}"); continue
    above={}
    for src in ["CLAUDE.md","muster/CLAUDE.md","muster/system-guide.md",f"muster/team/{r}/CLAUDE.md"]:
        for l in lines(src):
            if substantive(l): above.setdefault(norm(l), src)
    for i,l in enumerate(lines(f),1):
        if not substantive(l): continue
        checked+=1
        n=norm(l)
        if n in above:
            warns+=1; print(f"WARN: {f}:{i} duplicates {above[n]} — {n[:90]}")
print(f"checked {checked} substantive line(s) across {len(roles)} context file(s); {warns} duplicate(s)")
print("OK (warn-only): a duplicated line is paid twice per bind — point at it instead" if warns else "OK: agent-context files carry only what the layers above do not")
sys.exit(0)
PY
