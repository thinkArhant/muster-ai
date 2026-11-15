#!/usr/bin/env bash
# test-edit-insert-step.sh — fixture gate for muster-edit-insert-step.sh (one fenced step, three places, lints after).
# Asserts: dry run writes nothing; --after inserts between the anchor and the next step; --as-next
# makes the new step the single Next Step and moves the old one to the top of Upcoming;
# --first-upcoming lands under the heading's comments; a missing anchor, a fenceless body and a body
# the step lint rejects are refused with the queue byte-identical.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/scripts"
for s in muster-edit-insert-step.sh muster-lint-queue.sh muster-lint-step.sh muster-read-queue.sh; do cp "$HERE/$s" "$T/scripts/"; done
INS="$T/scripts/muster-edit-insert-step.sh"
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }; ko(){ echo "FAIL: $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/  got: /'; fail=$((fail+1)); }
Q="$T/queue.md"
seed(){ cat > "$Q" <<'EOF'
# Orchestration Queue

## Founder Decisions

## Next Step
<!-- the single next invocation -->
### Step 3 — Developer (ios): the hero streams the log

```
Role: developer

**Task:** stream it
**Inputs:**
- `Sources/Hero.swift`
**Deliverable:** `Sources/Hero.swift`
**Acceptance criteria:** See `knowledge-base/current-sprint.md`. Summary: streams.
**On completion:** File handoff in `agent-requests.md`.
```

## Upcoming
<!-- Ordered sequence of remaining steps for this sprint. -->
### Step 4 — QA (ios): blind net for the stream

```
Role: qa

**Task:** net
**Inputs:**
- `Tests/`
**Deliverable:** `Tests/StreamTests.swift`
**Acceptance criteria:** See `knowledge-base/current-sprint.md`. Summary: RED today.
**On completion:** File handoff in `agent-requests.md`.
```

### Step 5 — Founder: Wave 1 gate (halt)

```
Role: halt

Review `knowledge-base/wave-review.md`.
```

## Done (Last 10)
EOF
}
cat > "$T/step4b.md" <<'EOF'
### Step 4b — Developer (ios): name the stream event type

```
Role: developer

**Task:** types only
**Inputs:**
- `Sources/Events.swift`
**Deliverable:** `Sources/Events.swift`
**Acceptance criteria:** See `knowledge-base/current-sprint.md`. Summary: compiles, no behaviour.
**On completion:** File handoff in `agent-requests.md`.
```
EOF

seed; before="$(cat "$Q")"
out="$(bash "$INS" --queue "$Q" --body "$T/step4b.md" --after "### Step 4 — QA (ios): blind net for the stream" 2>&1)"; rc=$?
[ "$rc" = 0 ] && grep -qF "DRY RUN" <<<"$out" && [ "$(cat "$Q")" = "$before" ] && ok "dry run writes nothing" || ko "dry run" "$out"

out="$(bash "$INS" --queue "$Q" --body "$T/step4b.md" --after "### Step 4 — QA (ios): blind net for the stream" --apply 2>&1)"; rc=$?
order="$(grep -n '^### Step' "$Q" | sed 's/:.*Step / /' | awk '{print $2}' | tr '\n' ' ')"
[ "$rc" = 0 ] && [ "$order" = "3 4 4b 5 " ] && grep -qF "lints green" <<<"$out" && ok "--after inserts between 4 and 5" || ko "--after" "$out
order=[$order]"
[ ! -f "$Q.muster-edit.bak" ] && ok "backup removed after green lints" || ko "backup lingered"

seed
out="$(bash "$INS" --queue "$Q" --body "$T/step4b.md" --as-next --apply 2>&1)"; rc=$?
order="$(grep -n '^### Step' "$Q" | sed 's/:.*Step / /' | awk '{print $2}' | tr '\n' ' ')"
nextrole="$(QUEUE="$Q" bash "$T/scripts/muster-read-queue.sh" role "$Q")"
[ "$rc" = 0 ] && [ "$order" = "4b 3 4 5 " ] && [ "$nextrole" = "developer" ] && ok "--as-next: new step is Next Step, old one leads Upcoming" || ko "--as-next" "$out
order=[$order] role=[$nextrole]"
[ "$(awk '/^## Next Step/{f=1} /^## Upcoming/{f=0} f' "$Q" | grep -c '^```')" = 2 ] && ok "Next Step holds exactly one fenced step" || ko "one step in Next Step" "$(awk '/^## Next Step/{f=1} /^## Upcoming/{f=0} f' "$Q")"

seed
out="$(bash "$INS" --queue "$Q" --body "$T/step4b.md" --first-upcoming --apply 2>&1)"; rc=$?
order="$(grep -n '^### Step' "$Q" | sed 's/:.*Step / /' | awk '{print $2}' | tr '\n' ' ')"
[ "$rc" = 0 ] && [ "$order" = "3 4b 4 5 " ] && ok "--first-upcoming lands under the heading comment" || ko "--first-upcoming" "$out
order=[$order]"
grep -qF "Step 4b" <<<"$(awk '/^## Upcoming/{f=1;next} f&&/^### /{print; exit}' "$Q")" && ok "comment line stays above the inserted step" || ko "comment order" "$(sed -n '/^## Upcoming/,/^### Step 4b/p' "$Q")"

seed; before="$(cat "$Q")"
out="$(bash "$INS" --queue "$Q" --body "$T/step4b.md" --after "### Step 9 — nobody" --apply 2>&1)"; rc=$?
[ "$rc" = 1 ] && grep -qF "found 0 time(s)" <<<"$out" && [ "$(cat "$Q")" = "$before" ] && ok "missing anchor refused, queue unchanged" || ko "missing anchor" "$out"

printf '### Step 4c — PM: no fence here\n\nplain text\n' > "$T/bad.md"
out="$(bash "$INS" --queue "$Q" --body "$T/bad.md" --first-upcoming --apply 2>&1)"; rc=$?
[ "$rc" = 1 ] && grep -qF "needs a fenced block" <<<"$out" && [ "$(cat "$Q")" = "$before" ] && ok "fenceless body refused" || ko "fenceless body" "$out"

sed 's/\*\*Task:\*\* types only/**Task:** ask @developer to help/' "$T/step4b.md" > "$T/mention.md"
out="$(bash "$INS" --queue "$Q" --body "$T/mention.md" --first-upcoming --apply 2>&1)"; rc=$?
[ "$rc" = 1 ] && grep -qF "lints red after insert — queue restored" <<<"$out" && [ "$(cat "$Q")" = "$before" ] && [ ! -f "$Q.muster-edit.bak" ] && ok "step lint red → queue restored byte-identical" || ko "restore on red lint" "$out"

out="$(bash "$INS" --queue "$Q" --body "$T/step4b.md" 2>&1)"; rc=$?; [ "$rc" = 3 ] && ok "no placement exits 3" || ko "usage" "$out"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
