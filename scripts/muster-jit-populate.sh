#!/usr/bin/env bash
# muster-jit-populate.sh — action: the just-in-time populate lock and timestamp on .populated (family: verb — acts on the state file, never on content).
#
# When a specialist halts with `HALT: agent-context null`, PM writes that role's agent-context file
# from the knowledge base and marks it populated. The lock-and-timestamp dance around that write was
# fifteen lines of prose in context-cascading.md; prose forgets to release a lock or stamps a file
# full of placeholders. The judgment (what to write) stays with PM; the mechanics live here.
#   lock <role>     take the populate lock; refuses while another populate is under 15 minutes old
#   commit <role>   verify knowledge-base/agent-context/<role>.md is real (no template placeholders,
#                   has a Current Tasks section), stamp agents.<role> with now, release the lock
#   release         drop the lock without stamping (abort)
#   status          print the lock and every role's stamp
# Exit: 0 ok · 1 refused (lock held, placeholders, missing file) · 3 usage / no .populated
#
# Usage: muster-jit-populate.sh lock|commit|release|status [role]   (run from the project root)
set -uo pipefail
POP="${POP:-knowledge-base/agent-context/.populated}"
[ -f "$POP" ] || { echo "muster-jit-populate: no $POP — run the setup script first" >&2; exit 3; }
verb="${1:-}"; role="${2:-}"
case "$verb" in lock|commit) [ -n "$role" ] || { echo "muster-jit-populate: $verb needs a role" >&2; exit 3; } ;; release|status) ;; *) echo "muster-jit-populate: lock|commit|release|status" >&2; exit 3 ;; esac
export JP_POP="$POP" JP_VERB="$verb" JP_ROLE="$role" JP_CTX="knowledge-base/agent-context/${role}.md"
python3 - <<'PY'
import json, os, sys, datetime, re
pop=os.environ["JP_POP"]; verb=os.environ["JP_VERB"]; role=os.environ["JP_ROLE"]; ctx=os.environ["JP_CTX"]
try: d=json.load(open(pop))
except Exception as e: print(f"muster-jit-populate: {pop} is not valid JSON ({e})"); sys.exit(3)
now=datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0)
iso=now.isoformat().replace("+00:00","Z")
def save(): json.dump(d, open(pop,"w"), indent=2); open(pop,"a").write("\n")
agents=d.get("agents")
if not isinstance(agents, dict): print(f"muster-jit-populate: {pop} has no agents block"); sys.exit(3)
if verb in ("lock","commit") and role not in agents:
    print(f"muster-jit-populate: unknown role '{role}' (agents: {', '.join(agents)})"); sys.exit(3)
lock=d.get("lock")
def lock_age():
    try: return (now-datetime.datetime.fromisoformat(lock["since"].replace("Z","+00:00"))).total_seconds()
    except Exception: return None
if verb=="status":
    print(f"lock: {json.dumps(lock)}")
    for r,v in agents.items(): print(f"{r}: {v}")
    sys.exit(0)
if verb=="lock":
    if isinstance(lock, dict) and (lock_age() is None or lock_age()<900):
        print(f"REFUSED: populate lock held by {lock.get('role')} since {lock.get('since')} — wait for it or `release` if it is dead"); sys.exit(1)
    d["lock"]={"role":role,"since":iso}; save(); print(f"LOCKED {role} at {iso}"); sys.exit(0)
if verb=="release":
    d["lock"]=None; save(); print("RELEASED"); sys.exit(0)
# commit
if not isinstance(lock, dict) or lock.get("role")!=role:
    print(f"REFUSED: no populate lock held for {role} — run `lock {role}` first"); sys.exit(1)
if not os.path.isfile(ctx): print(f"REFUSED: {ctx} does not exist — write it before committing"); sys.exit(1)
body=open(ctx,encoding="utf-8").read()
ph=[p for p in ["[Project Name]","[Name]","[Tagline]","[1-2 sentence","[Platform,","[Key entities"] if p in body]
if ph: print(f"REFUSED: {ctx} still carries template placeholders: {', '.join(ph)}"); sys.exit(1)
if not re.search(r"(?m)^## Current Tasks", body): print(f"REFUSED: {ctx} has no '## Current Tasks' section"); sys.exit(1)
agents[role]=iso; d["lock"]=None; save(); print(f"POPULATED {role} at {iso}"); sys.exit(0)
PY
