# Sprint Charter
<!-- PM-owned. Tier-2: read at chartering, planning and gates — never a startup read. One live
charter per file: at closeout the Charter section moves to sprint-archive.md and the Candidates
section becomes the next charter's input. Contract: PM's `sprint-charter` skill. Shape is checked by
muster-lint-charter.sh, which also runs first in muster-plan-gate.sh — planning cannot start while a
number is still PROPOSED. Every line the founder reads says what it does for the user before any ID. -->

## Charter — Sprint [N]

**Scope:** [one sentence: what the user can do when this sprint ships] — [DRAFT | RATIFIED YYYY-MM-DD]

### §1 Scope line
<!-- One sentence of product, then the waves: the small, settled work first; the one big workstream
second, chartered live at the first wave's exit gate when its inputs are not yet in hand. -->

### §2 Ratified decisions
<!-- One row per ruling the founder took at chartering. -->
| ID | Decision | Alternatives rejected |
|---|---|---|

### §3 Numbers
<!-- One row per number the build is tested against. Red check = the blind test, or the manual check,
that goes red if the number is missed; a manual check is allowed but written "manual: …" — the
hardening pass flags it. No red check = cannot be ratified. Status: PROPOSED → RATIFIED | AMENDED
<value> | DEFERRED <what unblocks>. QA writes nets from this table only, never from source. -->
| ID | What changes for the user | Evidence | PM rec | Cost | Red check | Status |
|---|---|---|---|---|---|---|

### §4 Success criteria
<!-- Definition of done. Each line provable — mechanically where it can be (a test, a lint, a count) —
with the felt remainder named as the device gate's residue. -->

### §5 Non-goals
<!-- One bullet each: what is out · why · "wake: <what pulls it back in>". Descoping hides the
surface and keeps the seam (the enum case, the row, the flag, the tests). -->
- [out of scope] — [reason] — wake: [condition]

### §6 Already ratified — do not re-litigate
<!-- Pointers to prior rulings this sprint builds on; the walk never reopens them. -->

### §7 Process notes
<!-- The model plan (premium only where a step creates or reshapes a seam, with the founder's yes),
the RED-net-first pattern, anything execution must keep. -->

### §8 Evidence
<!-- The research files and sections every number cites. -->

## Candidates — next sprint
<!-- Append-only during the sprint; any agent may add a line. One bullet: what · why · source tag
(`founder` · `gate` · `retro` · `carry` · `research`). Ranked at the next chartering. -->
