#!/usr/bin/env bash
# test-jit-populate.sh — fixture gate for muster-jit-populate.sh (populate lock, placeholder refusal, stamp).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
J="$HERE/muster-jit-populate.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/knowledge-base/agent-context" && cp "$HERE/../templates/knowledge-base/agent-context/.populated" "$T/knowledge-base/agent-context/"
cp "$HERE/../templates/knowledge-base/agent-context/developer.md" "$T/knowledge-base/agent-context/"
pass=0; fail=0
run(){ out="$(cd "$T" && bash "$J" "$@" 2>&1)"; rc=$?; }
t(){ # name want-rc want-substring args…
  local name="$1" wrc="$2" want="$3"; shift 3; run "$@"
  if [ "$rc" = "$wrc" ] && grep -qF -- "$want" <<<"$out"; then echo "PASS: $name"; pass=$((pass+1))
  else echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fail=$((fail+1)); fi
}
stamp(){ python3 -c "import json,sys; print(json.load(open('$T/knowledge-base/agent-context/.populated'))['agents']['$1'])"; }

t "status prints the lock and stamps"      0 "developer: None"            status
t "commit without lock refused"            1 "no populate lock held"       commit developer
t "lock taken"                             0 "LOCKED developer"            lock developer
t "second lock refused while fresh"        1 "populate lock held by developer" lock qa
t "commit refuses template placeholders"   1 "still carries template placeholders" commit developer
printf '# Developer Context — Arogh\n## Product Context\nA recovery-driven workout app.\n## Current Tasks\n- build the hero\n' > "$T/knowledge-base/agent-context/developer.md"
t "commit stamps and releases"             0 "POPULATED developer at"      commit developer
[ "$(stamp developer)" != "None" ] && { echo "PASS: stamp written"; pass=$((pass+1)); } || { echo "FAIL: stamp missing"; fail=$((fail+1)); }
t "lock free after commit"                 0 "LOCKED qa"                   lock qa
t "release drops the lock"                 0 "RELEASED"                    release
t "commit for a role without its lock refused" 1 "no populate lock held for qa" commit qa
# a stale lock (20 minutes old) is overridden
python3 - "$T/knowledge-base/agent-context/.populated" <<'PY'
import json,sys,datetime
p=sys.argv[1]; d=json.load(open(p)); old=(datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(minutes=20)).replace(microsecond=0).isoformat().replace("+00:00","Z")
d["lock"]={"role":"content","since":old}; json.dump(d,open(p,"w"),indent=2)
PY
t "stale lock overridden"                  0 "LOCKED qa"                   lock qa
t "unknown role exits 3"                   3 "unknown role 'designer'"     lock designer
t "no verb exits 3"                        3 "lock|commit|release|status"
rm "$T/knowledge-base/agent-context/.populated"; t "missing state file exits 3" 3 "no knowledge-base/agent-context/.populated" status

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
