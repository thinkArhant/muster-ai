# Verdict Processing — the founder's rulings land everywhere, once

The founder rules in the walk; this skill is what happens next. Arogh paid for the shape four
times before it converged: a one-off Python cascade hand-written after every gate (an hour or
more), a gate packet truncated when a bare text match hit the same phrase in a blockquote, a
founder add encoded as a moved number that nobody could trace, and a PM quietly editing tests
after rulings until its role had drifted into the integrator's. Read this when a Verdict exists in
`knowledge-base/wave-review.md` and the queue does not yet reflect it. The default path is this
one, live in the PM tab; `muster-sprint-resume.sh` is the headless fallback for when nobody is at
the keyboard, and it has produced worse fix steps every time it was the first choice.

## One pass, in this order

The Verdict is one ruling per line in the gate vocabulary. Cascade it once, in order, so each
surface is written from the one before it and nothing is read twice.

1. **Charter rows.** Every number's Status becomes RATIFIED, AMENDED with the value, or DEFERRED
   with what unblocks it. An amended value is written into the row's "what changes" sentence too;
   the old value survives only in the Verdict and the archive.
2. **The packet.** Mark it closed with the one-line tally (how many ratified, amended, carried;
   which screens approved). It is archived to `sprint-archive.md` when the next gate opens.
3. **The queue.** A CHANGES item becomes steps, each sized by cohesion, ahead of the re-review
   gate: the first fix goes in as the single Next Step, the re-review `Role: halt` gate goes first
   in Upcoming, further fixes between them. A fix that changes behaviour gets its failing test
   first (a QA step that is RED on today's tree), then the Developer step. A founder add is an
   inserted step with a suffixed number (11b), never a renumbering and never a moved number; an
   add that needs a name (a type, a setting, an event) gets a types-only Developer step ahead of
   any blind net that will use it. Every inserted step passes the Cold-Start Sufficiency Test and
   cites the Verdict line it serves.
4. **The board.** One row per inserted step in the wave's table; the board agrees with the queue
   1:1 or the sprint lint says so.
5. **Agent context.** One-line pointer per affected role in Current Tasks (the step and its
   findings source, never the findings themselves). Write it time-neutrally: "after the gate",
   not "before Step 14", which goes stale the moment the gate passes.
6. **Decisions.** One `decision-log.md` entry per ruling that changes the product, with Impact
   naming each role; the decisions lint fails a cascade that skipped one.
7. **The notice.** One closing line in `founder-notices.md`: what the gate decided for the user,
   what it carried, what the founder does next.

Then `bash muster/scripts/muster-plan-gate.sh` must print ALL GREEN again before the queue is
handed back.

## The tools, and the rule they enforce

Every write above is an exact replacement or an insertion, so none is typed by hand:

- `bash muster/scripts/muster-edit-replace.sh --file F --text OLD --to NEW` for a status word, a
  value in a row, a tally line; `--section "## Heading" --with body.md` for a whole section. A
  match must be exactly one or nothing is written. Run every operation with `--check` first, then
  every one with `--apply`: the cascade either lands whole or not at all.
- `bash muster/scripts/muster-edit-insert-step.sh --body step.md --as-next` (or `--after
  "### Step 11 — …"`, or `--first-upcoming`) inserts one fenced step and runs the queue and step
  lints on the result; red lints restore the file.

Counter-case: a verdict with one copy ACCEPT and nothing else does not need the pass; edit the
line, run the decisions lint, post the notice. Collapse the process when the risk is low and keep
the whole chain for engine rules and ratified numbers.

## The PM write lane

You read anything. You write a test file only when the change has no behavioural meaning:
wrapping or unwrapping a known-issue marker that cites a recorded decision; renaming or
re-anchoring a test after a ratified number or symbol moved; fixture tables and configurations;
file moves and harness plumbing; reverting an out-of-lane write. You never edit an assertion
body, a threshold or a tolerance. Anything that changes what passes is a QA step (RED first) and
then a Developer step — routing a rename through two steps costs more than the risk, routing a
threshold change around QA costs the oracle. The charter's numbers table is yours; its test
readers are QA's.

`bash muster/scripts/muster-lint-write-lane.sh --role pm` warns on every assertion line a PM
change adds or removes; run it before any PM commit that touches a test file.

## Subagent writes

A subagent you spawn to fix or review can write where it was not asked: the queue, a generated
bundle, a test. Before trusting any subagent result, run
`bash muster/scripts/muster-lint-write-lane.sh --deliverable <the step's deliverable paths>` and
revert every out-of-lane write it lists. A reviewer never has write access: brief it read-only in a
worktree, with the commit SHA and absolute paths to the skills (the submodule is empty in a fresh
worktree), and fold its findings yourself. `git diff` before `git commit`, every time.

## Hand-back

You never start the driver. Leave the queue ready — plan gate green, the first fix as Next Step,
the re-review gate in Upcoming — and tell the founder in one message: what the gate decided for
the user, which fixes are queued and why each is shaped as it is, and that the driver is theirs to
run from the sprint worktree.

## Followed-check

The verdict was processed to this skill when: every Verdict line maps to a charter row status, a
queued step, or a recorded decision; every behaviour-changing fix has a RED step ahead of it;
every add is a suffixed step and no number was renumbered or moved; agent-context pointers carry
no step-relative wording; the plan gate and decisions lint are green; the write-lane lint is
quiet on your commits; and the founder, not you, ran the driver.
