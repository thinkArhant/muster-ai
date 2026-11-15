# Wave Review
<!-- File-mediated I/O contract between the autonomous sprint loop and the founder at a wave gate. PM-owned. Tier-2: read on demand only (at a wave gate / on resume), never a startup read. -->
<!-- The loop does NOT parse this file. PM writes the Output block at the gate; the founder writes the Verdict block; PM reads the verdict on resume (muster/scripts/muster-sprint-resume.sh). Keeping human feedback here — not in the orchestration queue — is the seam a future remote/mobile bridge plugs into. -->

## Current Wave

<!-- PM writes this block when the loop hits a wave-gate halt step (or at planning). One entry per active gate; clear or archive once resumed. -->

**Wave:** [N — short name] — [PAPER | DEVICE] gate, about [N] minutes, [phone needed | no phone]
**Build at:** [worktree path, e.g. ../<proj>-sprint-auto-YYYYMMDD-HHMMSS]

<!-- Packet contract (PM's `wave-gate` skill). First paragraph: what the founder is judging, three
things at most, one product sentence each. Then the sections below, in this order; delete the ones
a gate does not need, never reorder. Every line the founder reads says what the thing does for the
user before it names a number or an ID. -->

### 1. The numbers
<!-- One row per number: what changes for the user · evidence (cited) · PM recommendation · cost ·
the check that goes red if it is missed. No red check = not ready to ratify. -->

### 2. Design-implied behaviour
<!-- Every behaviour a screen or copy decided that no number states — one per line, ending with
"PM rec: …". -->

### 3. Screens and scope calls
<!-- Per screen: what it does in two seconds, then "Would Apple ship it?" per state. Scope calls as
one question with the cheapest shape that carries the risk. -->

### 4. Already green
<!-- What the machine certified, with evidence (suite counts, lints, fixtures). Which planned items
landed; for anything that did not, the mechanism. The founder does not re-test this. -->

### 5. Parked for the device gate

### Notices since last gate
<!-- PM folds every live founder-notices.md entry here VERBATIM (or writes "none"). The heading is
always present — muster-lint-gate-packet.sh fails its absence or a dropped notice. -->
none

## Verdict

<!-- Written during the walk, one ruling per line, before the next item opens. Vocabulary:
numbers RATIFY / AMEND <value> / DEFER <what unblocks>; copy ACCEPT / CHANGE <wording>; screens
APPROVE / CHANGES <list>; scope CARRY <sprint> / IN. A founder add is recorded as an add, never as a
moved number. Device findings: catchable mechanically (test first, then fix) / felt (ruling) / by
design (dropped, decision cited). Then the founder (or PM, after a live walk) sets Status and runs
muster/scripts/muster-sprint-resume.sh from inside the sprint worktree. -->

**Status:** [approve | changes-requested]
**Findings:**
- [bug / finding 1 — what's wrong, where to see it]
- [bug / finding 2]
