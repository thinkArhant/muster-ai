# Plan Hardening — the plan is proven before a stranger runs it

A queue step is executed by a cold agent with no memory of the planning. Arogh learned three
things the hard way: anchors verified before a driver run drifted at about 1.4 per code step
(fourteen after ten steps, one ledger still naming the old engine version); a reviewer given write
access ran a generator's `--help` and rewrote a bundle; and a 300k-token plan audit found mostly
citations the author could have checked while writing. Hardening is the pass between "the plan
is written" and "the driver starts", and again between "the driver landed code" and "the next wave
starts". Read it at both points. The plan gate proves structure; this proves truth.

## Two passes, one shape

**Before the first driver start**: the readiness pass, then one cold review, then the gate.
**After any run that landed code, before the next wave**: the readiness pass again (the re-sweep),
no review unless the wave changed shape. A code step moves symbols; a paper step does not.

The readiness pass is a table you build and act on, never a feeling:

| Step | Anchor | Symbol | Current line | Verdict |
|---|---|---|---|---|
| 12 | `Sources/Engine.swift:41` | `computeDose` | 58 | moved — patch |
| 13 | `Tests/SetTests.swift` | — | — | missing — a later step produces it; reorder or skeleton |

`bash muster/scripts/muster-lint-anchors.sh` builds the mechanical rows: every backticked path
in the queue and in every agent-context file must exist, its `:line` must be inside the file, its
named symbol must be there and near the line, its `→ Section` must be a heading. You patch the
queue, the agent-context pointers and any ledger the steps cite, then run it again. The table is the
lint's output plus your verdict column — never a second session re-deriving what a script printed.
Nothing is patched from memory: open the file.

## The anchor grammar

Write every citation so a script and a stranger can both resolve it: `` `path/file.ext:41` ``
followed by the symbol in backticks in parentheses, `` (`computeDose`) ``; for a document,
`` `knowledge-base/spec.md` → Section Title ``. Never "per the design", never "the usual place",
never a step number as a reference — restate the decision or cite the file it landed in. A step
whose scope an earlier step decides points at that step's handoff as the authoritative source and
says the listed items are examples; a step that consumes a component not yet built states its
halt-to-PM inline.

## Producers before consumers

A blind test net is written from the charter's numbers, never from source — so the names it uses
must exist before it is written. `bash muster/scripts/muster-lint-order.sh` fails any step that
consumes a path a later step produces. The fix is a types-only skeleton step ahead of the net: the
Developer declares every type, setting and event the net will name, nothing behaves differently
yet, and the suite stays green. Reorder only when the skeleton would be the whole step.

Counter-case: a path that already exists is a modify, not a produce; a later step changing a file an
earlier step reads is ordinary and the lint says nothing.

## One cold reviewer — the exception, read-only, priced first

A review is a whole session reading the whole plan; it is the only real spend in hardening, so it
is not run by default. Run it when one of three triggers is present: the first wave of a sprint
that creates new seams; a step whose scope depends on an earlier step's output; a founder add that
changed the wave's shape. A small, settled wave with green lints gets no review. Lints first,
always, so the reviewer never re-finds what a script catches. Before commissioning one, write two
numbers down: its budget, and the cost of one fix round (the driver logs the price of a step); run
it only when it is cheaper than the rework it prevents. One well-briefed reviewer beats parallel
auditors: redundancy re-finds, it does not cover.

The reviewer is a fresh session on a cheaper model (reading and comparing, not creating), in a
separate worktree with no write access, briefed with the commit SHA and the budget, and asked to
read as the headless agent will. Fold its findings yourself. A reviewer with write access is the
field failure above; `git diff` before you trust anything it touched
(`muster-lint-write-lane.sh --deliverable` lists strays). The brief:

```
You are reviewing a sprint plan as the cold agent who will execute it. Read-only: change nothing.
Repo at <absolute path>, commit <SHA>. The skills live at <absolute path to muster/team/> — the
submodule is empty in a fresh worktree, so use that path. Read, in order:
knowledge-base/orchestration-queue.md (Next Step and Upcoming), knowledge-base/current-sprint.md,
each queued role's knowledge-base/agent-context/<role>.md, and knowledge-base/sprint-charter.md.
For every step, answer as that agent: which decisions would I have to make that the step does
not state or cite? Which cited file, line or symbol did I open and find different? Which input is
produced by a later step? Which number has only a manual red check? Report one table — step ·
finding · the fix you would make — and nothing else. Budget: <N> tokens.
```

## What hardening flags, not fixes

Numbers whose red check is manual (`muster-lint-charter.sh` warns on them): list them in the gate
packet's "parked for the device gate" so the founder knows which numbers only a person will catch.
Premium-model steps without a recorded founder yes. A wave with no gate step that produces
something only a human can judge. These are rulings, not patches; they go to the founder in the
hand-back message, one per paragraph, with your recommendation.

## The gate

Hardening is done when `bash muster/scripts/muster-plan-gate.sh` prints ALL GREEN (it runs the
charter, queue, step, order, board, context and budget checks) and `muster-lint-anchors.sh` is
clean. Then hand back: the plan is ready, here is what the first wave does for the user, here are
the manual checks and the premium steps for your yes, the driver is yours.

## Followed-check

Hardening was run to this skill when: the readiness table exists for this wave and every "moved"
or "missing" row has a patch commit; the anchors lint and the plan gate are green at the hand-back;
no second session built the table; a review ran only on a named trigger, on a cheaper model, with a
budget in its brief and no write access; every blind net has a producer ahead of it; and the manual
red checks appear in the packet's parked section.
