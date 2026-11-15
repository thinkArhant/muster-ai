# Wave Gate — the founder's hour, spent only where a machine cannot

The gate is where the founder rules. Twelve arogh sprints converged on one shape and paid for it
three times first: a gate presented as a list produced a blanket "approve", re-opened items a
week later, and one QA net written against an interface nobody had declared; a halt report that
quoted a green test count got the question "prove tests were added, not just passing". This skill
is that converged shape. Read it when a wave ends in a `Role: halt` step, when the driver halts
between gates, and before you write anything the founder will read.

## Two gates and a report

- **Paper gate** — numbers, screens, copy and scope rulings; no device. Use it when the wave
  produced decisions, not behaviour: a chartering packet, designs, a types-only skeleton.
- **Device gate** — the founder feels the build. Use it when the wave changed what the user
  sees or does. It re-feels the previous gate's fixes first, then the new surface end to end.
- **Halt report** — between gates, every time the driver stops. Not a ruling; the founder reads
  it to decide whether to look. One per halt, however small.

Counter-case: a logic wave fully covered by tests gets no gate; the report is enough. A wave
that is both (an engine change and the screen that shows it) is one device gate whose first
section is the paper walk.

## The halt report

`bash muster/scripts/muster-sprint-report.sh` prints the mechanical half: what landed since the
last gate (commit subjects, which Rule 16 makes product sentences), tests added and removed per
platform with any source changed untested, live notices, the next step and open founder
decisions. You add two things, in product words: known issues the founder would otherwise meet
by surprise, and what they do next and from where (which tab, which file). Nothing else. A
report that says "1060 tests green" and stops is the failure this exists to end.

## The gate packet — `knowledge-base/wave-review.md`

One active gate per file; the previous packet and verdict go to `sprint-archive.md` when the
gate closes. The founder decides whether to spend an hour from the first paragraph, so it says
what kind of gate, how long, and whether a phone is needed. Then, in order:

1. **What the founder is judging** — three things at most, each one sentence of product.
2. **The numbers** (paper gates) — one row each: what changes for the user in plain words ·
   the evidence (cited) · your recommendation · what it costs · the check that goes red if the
   number is missed. A number with no red check is not ready to be ratified; a manual check is
   allowed but named, and the hardening pass flags it. The row's key (an ID) exists so the
   verdict can name it — the sentence leads, the key follows.
3. **Design-implied behaviour** — every behaviour a screen or copy decided that no number
   states, pulled out one per line so none slips through an approve. Each line ends with your
   recommendation.
4. **Screens and scope calls** — per screen: what it does in two seconds, then "Would Apple ship
   it?" answered per state (first run, empty, error, long content). Scope calls as one question
   with the cheapest shape that carries the risk.
5. **Already green** — what the machine certified, with the evidence (suite counts, lints,
   fixtures). The founder does not re-test it. This is the certify half of the gate: name what
   landed against the roadmap, and when something did not land, name the mechanism, including a
   fix squashed by a later fix. Never produce a parallel to-do list.
6. **Parked for the device gate** — what this paper gate cannot settle.
7. **Notices since last gate** — every live `founder-notices.md` entry verbatim, or `none`.
   The heading is always present; `muster-lint-gate-packet.sh` fails its absence or a dropped
   notice. Luck is not a delivery mechanism.
8. **Verdict** — empty until the walk; one ruling per line, in the vocabulary below.

Before any of it: confirm the build under review is from current source. A stale build makes a
fixed bug look live and spends the founder's hour diagnosing nothing.

## The walk — one item per turn

The founder does not read the packet alone; you walk it with them, live, one item per turn.
Each turn is one item in one shape: **the product change → why → cost → benefit → your
recommendation.** Before any number, one worked example ("a beginner doing three exercises in
twenty minutes gets…"). Where research exists, the science's answer comes before your
recommendation; the founder's preference is recorded and does not move the number.

The founder answers in a fixed vocabulary, so a ruling is never ambiguous:

| Item | Answers |
|---|---|
| a number | **RATIFY** · **AMEND** (with the new value) · **DEFER** (with what unblocks it) |
| a copy line | **ACCEPT** · **CHANGE** (with the wording) |
| a screen | **APPROVE** · **CHANGES** (listed) |
| a scope call | **CARRY** (to a named sprint) · **IN** |

Write each ruling into the Verdict before you open the next item. A founder add during the walk
is recorded as an **add**, never as a moved number; it cascades after the walk, in one pass. An
add that needs a name (a type, a setting, an event) gets a types-only Developer step ahead of any
blind test net, never an interface invented inside QA. A mid-walk question is answered with repo
evidence (the spec line, the research section), not from memory. Close by marking the packet
RATIFIED with a one-line tally, then post the closing notice.

Counter-case: when the founder asks "is there a better way", propose the cheapest step shape the
risk allows (merge a trivial RED-then-fix into one step; skip the handoff ceremony on a copy
tweak). Keep the full chain for engine rules and ratified numbers.

## Device gate triage

Every finding gets one of three dispositions, decided in the walk:

- **Catchable mechanically** → a permanent test is back-filled before the fix ships; the finding
  becomes a RED-first fix step. The goal is that the next device gate finds only what a test
  cannot.
- **Felt** (taste, pacing, "does this read right") → the founder's call; record it as a ruling.
- **By design** → say so, cite the decision, and drop it. A deliberate placeholder is not a bug;
  a working-but-incomplete affordance is not a removal candidate. Log soft observations as notes,
  not fixes.

Certify first, then triage: the walk opens with which planned items landed, so the founder is
not asked to re-find what the machine already proved.

## What the founder reads, and how

Every surface the founder reads obeys the brain's Talking to the Founder rule. Three contracts:

- **A notice** (`founder-notices.md`): one event · what changes for the user · what it cost ·
  whether they must act and by when. No codes, no step numbers.
- **A verdict request** (a Founder Decisions entry or a walk item): one item · the question · the
  science's answer · your recommendation · the trade-off · what each answer cascades into · the
  vocabulary to answer in.
- **The packet**: as above. `bash muster/scripts/muster-lint-founder-surface.sh` warns on a
  line that leads with an identifier and says nothing else, and on identifier density. It is a
  floor; the rule is the sentence before the number.

## Followed-check

A gate was run to this skill when: the packet passes `muster-lint-gate-packet.sh`; every item in
the Verdict carries a word from the vocabulary table; every add in the Verdict names its inserted
step; every device finding carries one of the three dispositions; and the halt report that
preceded the gate shows a test delta, not a count. Process the Verdict per the lifecycle's verdict
phase (the `sprint-planning` skill names it); do not start the driver — the founder runs it.
