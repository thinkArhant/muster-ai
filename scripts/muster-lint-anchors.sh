#!/usr/bin/env bash
# muster-lint-anchors.sh — lint: every anchor a queue step or agent context cites resolves on disk, to its line, to its symbol (family: lint — reports, never mutates).
#
# A headless agent reads a step and opens what it cites. Arogh measured ~1.4 drifted anchors per
# driver code step — fourteen after ten steps — and each one makes a cold agent misread or guess.
# This resolves every backticked path in the queue's steps and in agent-context files:
#   FAIL — the file does not exist
#   FAIL — `path:N` and the file has fewer than N lines
#   FAIL — a named symbol (`path:N` (`symbol`) or `path` → `symbol`) appears nowhere in the file
#   WARN — the symbol exists but not within 5 lines of N — moved; the new line is printed
#   WARN — `file.md` → Section text names a heading the file does not have
# Skipped: template placeholders (`path/to/…`, `[`, `<`), URLs, globs. Run before every driver start
# and after every run that landed code (the re-sweep). Exit: 0 clean (WARNs allowed) · 1 FAIL · 3 usage.
#
# Usage: muster-lint-anchors.sh [FILE…]   default: knowledge-base/orchestration-queue.md knowledge-base/agent-context/*.md
set -uo pipefail
if [ $# -gt 0 ]; then files=("$@"); else files=(knowledge-base/orchestration-queue.md knowledge-base/agent-context/*.md); fi
export LA_FILES="$(printf '%s\n' "${files[@]}")"
python3 - <<'PY'
import os, re, sys
files=[f for f in os.environ["LA_FILES"].split("\n") if f and os.path.isfile(f)]
if not files: print("muster-lint-anchors: no input files found", file=sys.stderr); sys.exit(3)
TOK=re.compile(r"`([^`\s]+)`")
fails=warns=checked=0
def is_path(t):
    if t.startswith(("http://","https://")) or any(c in t for c in "*[<>{}") or "path/to" in t: return False
    core=t.split(":")[0]
    return "/" in core or re.search(r"\.[A-Za-z0-9]{1,6}$", core) is not None
def lines_of(p):
    try: return open(p,encoding="utf-8",errors="replace").read().splitlines()
    except OSError: return None
for f in files:
    src=open(f,encoding="utf-8",errors="replace").read().split("\n")
    fence=False
    for ln,line in enumerate(src,1):
        if line.startswith("```"): fence=not fence; continue
        if line.lstrip().startswith("<!--"): continue
        for m in TOK.finditer(line):
            tok=m.group(1)
            if not is_path(tok): continue
            mm=re.match(r"^(.*?)(?::(\d+)(?:-\d+)?)?$", tok); path, lno = mm.group(1), mm.group(2)
            if not path or not is_path(path): continue
            checked+=1
            target=lines_of(path)
            if target is None:
                print(f"FAIL: {f}:{ln} — `{tok}` does not exist (a cold agent cannot open it)"); fails+=1; continue
            if lno and int(lno)>len(target):
                print(f"FAIL: {f}:{ln} — `{tok}` points past the end of the file ({len(target)} lines)"); fails+=1; continue
            rest=line[m.end():]
            sym=None; sec=None
            sm=re.match(r"^\s*(?:\(\s*`([^`]+)`\s*\)|→\s*`([^`]+)`)", rest)
            if sm: sym=sm.group(1) or sm.group(2)
            elif path.endswith(".md"):
                hm=re.match(r"^\s*→\s*[\"“]?([^→·`\"”(]+?)[\"”]?\s*(?=$|→|·|\(|,|;)", rest)
                if hm: sec=hm.group(1).strip()
            if sym:
                hits=[i for i,l in enumerate(target,1) if sym in l]
                if not hits: print(f"FAIL: {f}:{ln} — `{tok}` names `{sym}`, which is not in the file"); fails+=1
                elif lno and not any(abs(i-int(lno))<=5 for i in hits):
                    print(f"WARN: {f}:{ln} — `{tok}` (`{sym}`) moved: now at line {hits[0]}"); warns+=1
            elif sec and len(sec)>=3:
                if not any(re.match(r"^#{1,6} ", l) and sec.lower() in l.lower() for l in target):
                    print(f"WARN: {f}:{ln} — `{path}` → \"{sec}\" names a section the file does not have"); warns+=1
print(f"checked {checked} anchor(s) in {len(files)} file(s); {fails} FAIL, {warns} WARN")
if fails: print("FAILED — fix the anchors before the driver reads them"); sys.exit(1)
print("OK: every anchor resolves" + (f" ({warns} moved/section warning(s) to patch)" if warns else "")); sys.exit(0)
PY
