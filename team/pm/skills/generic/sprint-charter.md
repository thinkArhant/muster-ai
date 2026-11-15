# Sprint Charter — the founder ratifies scope before a step is written

Arogh invented the chartering packet in its eighth sprint and paid for the shape twice first: a
number was "ratified" with no test that could fail it, so QA had nothing to write blind and a wave
of rework followed; and a sprint planned straight from a carry list re-opened scope at the first
gate. The charter answers both. It is the paper gate that precedes planning: every number the
build will be tested against is proposed with its evidence and its red check, the founder rules on
each, and only then does the `sprint-planning` skill turn it into waves. Read this at the start of
every sprint and whenever a later wave is chartered live at a gate.

## When, and from what

Charter at sprint start, in a live PM tab, with the founder. Charter the second wave at the first
wave's exit gate when its inputs (a device verdict, a research answer) are not in hand at sprint
start — do not pre-queue it. The inputs are the file's own **Candidates** section (grown all sprint
by any agent, source-tagged `founder` · `gate` · `retro` · `carry` · `research`), research files at
`status: researched`, `triage-log.md` DEFER entries, and resolved Founder Decisions.

The file is `knowledge-base/sprint-charter.md`, one live charter at a time; at closeout the Charter
section moves to `sprint-archive.md` and Candidates becomes the next input. If the file is absent
(a project seeded before it existed), copy `muster/templates/knowledge-base/sprint-charter.md`
into place first — the updater never writes into a project's knowledge-base.

## Ranking the candidates

Score each candidate before the session, not in it. **ICE**: impact (how much it moves the user's
outcome), confidence (how sure the evidence makes you), ease (how cheaply it lands), each 1–10,
averaged; then adjust for strategic fit and say so. ICE orders a list; three rules decide what the
list may contain:

- **No number before its science.** If a candidate needs a value nobody has evidence for, it goes
  to Research first (a `change-log.md` entry with the question and the blocked section), and the
  research doc gets a "For the founder" section the walk can read. Convenient beats researched
  only when the founder has been told the science is missing and ruled anyway.
- **Small and settled first.** Wave 1 takes everything the research settled and every carry that is
  one short step; the one big workstream is Wave 2, chartered live when Wave 1's gate has run.
- **Descoping hides the surface and keeps the seam.** A feature that leaves the sprint keeps its
  enum case, its row, its flag and its tests; only the screen goes. "Hide it" is the last resort
  after a research check, never the first move.

Counter-case: a founder-elevated item outranks its ICE score once; record the elevation in §2 so
the next charter does not relitigate it.

## The packet

Fill the template's sections in order. Each has one job:

1. **Scope line** — one sentence of what the user can do when the sprint ships, then the waves.
2. **Ratified decisions** — one row per ruling: the decision in product words, the alternatives
   rejected. The next sprint reads this before it proposes the same thing again.
3. **Numbers** — one row per value the build is tested against: what changes for the user, in
   plain words first · the evidence, cited to a file and section · your recommendation · cost ·
   **the red check** · status. The red check is the blind test that goes red if the number is
   missed. A number without one cannot be ratified. A manual check is allowed when no test can
   see the behaviour, written "manual: who checks what, when"; the hardening pass flags every
   manual row so the founder knows which numbers only a person will catch. QA writes its RED net
   from this table and never from engine source; the table is the oracle.
4. **Success criteria** — the definition of done, each line provable: a test, a lint, a count, or
   the named felt residue the device gate carries.
5. **Non-goals** — each with its reason and a wake condition, so "out" is a decision with a
   trigger, not a loss. Include the things the founder asked about and you are declining.
6. **Already ratified** — pointers, so the walk never reopens a settled ruling.
7. **Process notes** — the model plan (premium only where a step creates or reshapes a seam, with
   the founder's yes at this session), the RED-net-first pattern, anything execution must keep.
8. **Evidence** — every file and section a number cites.

**Definition of ready**, before the founder sees a number: every row has evidence and a red check;
every screen in scope has its privacy implication and its accessibility floor named in the
success criteria or the non-goals; every science question has a Research answer or an explicit
"ruled without it". `bash muster/scripts/muster-lint-charter.sh` checks the shape and the red
checks; readiness is your judgment.

## The chartering walk

The chartering session is a paper gate: run it with the `wave-gate` skill's walk, one item per
turn, in its vocabulary. A number is **RATIFIED**, **AMENDED** with its new value, or **DEFERRED**
with what unblocks it; write the status into the row before the next item opens. Before any
number, one worked example in the product; where research exists, its answer before your
recommendation; the founder's preference is recorded in §2 and does not move the number. A founder
add is a new row or a new candidate, never a moved number. Close by setting the Scope line to
RATIFIED with the date, then post one notice: what the sprint will do for the user, how many
numbers, what was carried.

## Hand-off to planning

Planning starts only on a ratified charter: `muster-plan-gate.sh` runs the charter lint first and
refuses while any row is PROPOSED. The queue's first steps are the RED nets written from §3, then
a types-only skeleton for any name a net needs, then the build. The charter is cited by every step
that implements a number (the row, not the value — the row carries the evidence).

## Followed-check

A charter was run to this skill when: the lint is green with its manual-check warnings listed in
§7; every Candidates line that did not enter the sprint appears in §5 or stays a candidate with a
source tag; §2 records the founder's preferences separately from the numbers; and the first queue
steps are RED nets whose Inputs cite §3 rows.
