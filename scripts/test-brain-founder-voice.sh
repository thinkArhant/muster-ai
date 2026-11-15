#!/usr/bin/env bash
# test-brain-founder-voice.sh — fixture gate: every role's brain file carries the founder-voice rule.
#
# The rule ("Talking to the Founder": plain words, product first, never lead with an ID) is doctrine
# for all eight roles and lives in the always-read brain file because chat cannot be linted. This
# pins the section heading and its anchor sentence in each brain so a trim or rewrite cannot drop
# it silently. Identical wording across roles is intentional — one rule, eight copies, one check.
set -uo pipefail
cd "$(dirname "$0")/.."
fails=0
for r in pm research developer ui-ux content marketing legal qa; do
  f="team/$r/CLAUDE.md"
  if grep -qF '## Talking to the Founder' "$f" && grep -qF 'Plain words, product first.' "$f"; then
    echo "PASS: $f carries the founder-voice rule"
  else
    echo "FAIL: $f lost the founder-voice rule (heading or anchor sentence)"; fails=$((fails+1))
  fi
done
[ "$fails" -eq 0 ] && { echo "OK — founder-voice rule present in all eight brains"; exit 0; }
echo "FAILED — $fails brain file(s)"; exit 1
