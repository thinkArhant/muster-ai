#!/usr/bin/env bash
# muster-sprint-report.sh — action: assemble the mechanical half of the halt or gate report (family: sprint — reports, never mutates).
#
# Between gates the founder gets one report in product words: what landed, whether tests were
# written, which notices are live, what happens next. Three of those four are mechanical, and the
# arogh PM re-typed them three to five times a sprint. This prints them as a pasteable block; PM
# adds only the judgment lines (known issues, the ask). Commit subjects are outcome-first by Rule
# 16, so they already read as product sentences. Default BASE is the last commit that touched
# knowledge-base/wave-review.md (the last gate), else the first commit on the branch.
#
# Usage: muster-sprint-report.sh [BASE]        (run from the project root)
# Exit: 0 printed · 3 not a git repo / bad ref
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUEUE="${QUEUE:-knowledge-base/orchestration-queue.md}"
NOTICES="knowledge-base/founder-notices.md"
PACKET="knowledge-base/wave-review.md"
source "$SCRIPT_DIR/muster-read-queue.sh" || { echo "muster-sprint-report: queue parser missing" >&2; exit 3; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "muster-sprint-report: not a git repo" >&2; exit 3; }
if [ -n "${1:-}" ]; then
  base="$1"
else
  base="$(git log -1 --format=%H -- "$PACKET" 2>/dev/null || true)"
  [ -n "$base" ] && [ "$base" != "$(git rev-parse HEAD)" ] || base="$(git rev-list --max-parents=0 HEAD | tail -1)"
fi
git rev-parse --verify -q "$base" >/dev/null || { echo "muster-sprint-report: unknown ref '$base'" >&2; exit 3; }
short="$(git rev-parse --short "$base")"

subjects="$(git log --reverse --format=%s "$base..HEAD")"
n="$(printf '%s\n' "$subjects" | sed '/^$/d' | wc -l | tr -d ' ')"

echo "## What landed since $short ($n commit(s))"
if [ "$n" -eq 0 ]; then echo "- nothing committed since the last gate"; else
  printf '%s\n' "$subjects" | sed '/^$/d' | grep -v '^sprint step boundary:' | sed 's/^/- /'
  sweeps="$(printf '%s\n' "$subjects" | grep -c '^sprint step boundary:' || true)"
  [ "${sweeps:-0}" -gt 0 ] && echo "- (${sweeps} step-boundary sweep commit(s) by the driver — work an agent left uncommitted)"
fi
echo
echo "## Tests"
bash "$SCRIPT_DIR/muster-lint-test-delta.sh" "$base..HEAD" 2>&1 | sed 's/^/- /'
echo
echo "### Notices since last gate"
if [ -f "$NOTICES" ]; then
  live="$(grep -E '^- 20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$NOTICES" || true)"
  [ -n "$live" ] && printf '%s\n' "$live" || echo "none"
else echo "none"; fi
echo
echo "## Next"
role="$(next_role)"
if [ -z "$role" ]; then echo "- queue complete — nothing queued"; else
  title="$(next_block | grep -m1 -E '^#{2,4} ' | sed 's/^#* //')"
  echo "- next step (${role}): ${title:-see ## Next Step}"
fi
if [ -f "$QUEUE" ]; then
  open="$(awk '/^## Founder Decisions/{f=1;next} f&&/^## /{f=0} f&&/^- /{n++} END{print n+0}' "$QUEUE")"
  echo "- founder decisions waiting: $open"
fi
echo
echo "## PM writes (judgment)"
echo "- known issues, in product words:"
echo "- what you do next, and from where:"
exit 0
