# Sprint Planning — the lifecycle spine

**Read this skill in full before planning, every time.** The field failure it answers: a PM
planned from a content-complete prompt, skipped the boundary gates, and the founder had to step
in. When closeout writes the next sprint's planning step, that prompt's first line is "Read the
`sprint-planning` skill in full before planning." This file holds the judgment of planning;
everything a script can check, a script checks (`muster-plan-gate.sh`).

## The lifecycle

A sprint is seven phases, each with one artifact. Planning is the second.
1. **Charter** — the founder ratifies scope first: ranked candidates, each number with its evidence and its red check, non-goals with a reason (the `sprint-charter` skill).
2. **Plan** — this skill: the ratified charter becomes waves, steps, contexts and a board.
3. **Harden** — before any driver run: one cold read-only reviewer, every anchor resolved against source, a skeleton step ahead of blind nets (the `plan-hardening` skill).
4. **Gate** — the packet certifies what the machine proved; the founder walks the felt residue only, one item per turn (the `wave-gate` skill).
5. **Verdict** — rulings written in place as they land; founder adds become inserted steps, never moved numbers; behaviour fixes test-first (the `verdict-processing` skill).
6. **Encode** — packet, code and spec reconciled three ways; durable docs hold current truth only.
7. **Closeout** — board reconciled, archives moved, retro written, next charter seeded.

## Planning process

1. **Reset the boundary.** Numbering restarts at 1. `wave-review.md` carries only the live gate.
   Every `agent-context/*.md` Current Tasks block is replaced, not appended — roles with no step
   get "no active step; standing disciplines carry". Stale blocks are deleted, never commented
   out; extract any standing doctrine a task block carried before deleting it.
2. **Read what the last sprint left.** `bash muster/scripts/muster-list-open-items.sh` for
   anything an interrupted closeout left open; decisions awaiting implementation;
   `triage-log.md` DEFER entries as candidates; the carry list from closeout.
3. **Sequence before assigning.** Upstream producers before consumers — design before build,
   build before test, a name before the blind test that uses it. An agent whose tasks all wait
   on another agent has zero tasks.
4. **Cut waves.** A wave is the largest run of steps one review pass can verify; it ends where
   the surface changes (logic → UI) or a deliverable needs human eyes. Logic covered by tests
   flows through; a UI or behavioural wave ends in a gate step. Interleave `Role: pm` review
   steps after each wave's deliverables rather than batching review at the end.
5. **Size steps by cohesion**, never by turn count. Changes sharing files and mental model are
   one step; unrelated changes are separate even when small. A too-large cohesive step splits
   along its natural seam (data model → UI → wiring), not by raising the turn cap.
6. **Write the three surfaces.** Each affected agent's Current Tasks holds the full task spec —
   deliverable, effort, acceptance — self-contained, never a pointer. The board indexes the
   sprint (Task Definition Standard). The queue carries the prompts (Queue Step Format). Clear
   Done; mirror dependencies in both agents' files.
7. **Pick models.** Opus-family by default; the gates buy correctness, so premium buys only
   judgment. Premium is for steps that create or reshape a foundation seam and needs the
   founder's yes at planning. Cheaper models suit reviews, microcopy, mechanical cascades.
8. **Cold-Start Sufficiency Test, on every step you author or edit.** The reader is a stranger
   with no memory. List the decisions the agent must make to satisfy the deliverable; each is
   specified or cited, or the agent guesses and nothing catches it. Cite the source, don't
   inline it. Heaviest where scope depends on an earlier step.
9. **Cite nothing you have not opened.** Every path, line, symbol or harness claim is checked
   against the artifact as you write it. A step whose scope an earlier step decides points at
   that handoff ("implement everything in it; examples non-exhaustive"); a step consuming an
   unlanded component states its halt-to-PM inline.
10. **Scan for skill gaps** from each queued role's skill index only. A gap becomes a "PM: create
    missing skills" step first in the queue (`skill-gap-classification` skill), never inline.
11. **Run the plan gate**: `bash muster/scripts/muster-plan-gate.sh`; planning is complete when
    it prints ALL GREEN. Then price the hardening pass before commissioning it — one well-briefed
    cold reviewer plus this gate beats parallel auditors.

Autonomous vocabulary: a prompt never says "tell the founder" — nobody reads that chat. A notice
is a dated line in `knowledge-base/founder-notices.md`; a question routes through PM. No agent
advances past a red build or failing tests: the specialist routes to a `Role: pm` step and only
PM sets `Role: halt`. High-context PM work (closeout, exit prep) runs in a live PM tab.

## Queue Step Format

The prompt standard. Every step, PM steps included, is a fenced block whose first line is
`Role: <developer|ui-ux|qa|content|marketing|legal|research|pm>` — never `@<agent>`, which the
platform auto-routes. An optional `Model: <id>` line follows. Headings are `### Step N — [Agent
(platform)]: [title]`; numbers match the board 1:1; inserted fixes take suffixed numbers (11b).
`## Next Step` holds exactly one step; a fix goes there, its re-review gate first in `## Upcoming`.

```
Role: <agent-name>
**Task:** [one line]
**Inputs:**
- `path/to/file.md` (`file:line` or symbol where it pins a spot; name the single source to copy)
**Deliverable:** `path/to/output` (or handoff ID)
**Acceptance criteria:** See `knowledge-base/current-sprint.md` for full criteria. Summary: [2-3 bullets].
**On completion:** File handoff in `agent-requests.md`. Run the Pre-Handoff Self-Review Checklist (`muster/system-guide.md`) before filing.
```

A gate step is `Role: halt`, titled for its wave, pointing at the build and at
`knowledge-base/wave-review.md` where PM writes the human-only checklist and the founder the
verdict. Its packet always carries a `Notices since last gate` heading (`muster-lint-gate-packet.sh`).
Before diagnosing a gate finding, confirm the build is from current source. Platform tag:
`(ios)`, `(web)`, `cross-platform`, or none.

## Task Definition Standard

The board is the wave-table, one per `### Phase … — <name>` heading, agreeing with the queue
(`muster-lint-sprint.sh`). An index, not a third copy of the specs.
```
| Step | Role | Deliverable | Verification |
|---|---|---|---|
| 1 | Developer | [one-line deliverable] | [pinned assertion / test / gate — or "—"] |
```
Role is one of the eight agent names or `founder (halt)`. Verification names the mechanical
proof; `—` for paper steps. Order is the priority, position resolves dependencies, effort lives
in the agent-context spec.

## Bug Routing Protocol

PM classifies severity and type alone. Visual or layout → UI/UX → PM review → Developer → QA.
Copy → Content → PM review → Developer → QA (both upstream when a layout break is copy-driven).
Logic, data, integration → Developer → QA. Upstream agents fix the spec first; the updated spec
is the Developer's instruction. Group a mixed batch by route, then size by cohesion. A blocker
is logged the turn it appears: re-sequence, decide-and-log, or file the research request.

## Sprint Closeout

The mechanics are one gate, `bash muster/scripts/muster-closeout.sh`: the open-items worklist
plus a ✓/✗ block over board closure, entries, decisions, budgets, durability and notices; red
anywhere refuses green. The judgment is yours: close a handoff only when its deliverable was
validated, by its reviewers or a later regression pass — otherwise carry it; never close on
assumption. Move the finished board to `sprint-archive.md`, pre-sprint decisions to
`decision-log-archive.md`; sweep notices older than the sprint. Then, for every artifact the
next sprint needs: tracked `knowledge-base/` file, or a worktree about to be deleted? Promote it.
Write the retro (`sprint-retrospective` skill), the next charter input, then plan.
