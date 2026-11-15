# Sprint Closeout — the board is clean, the next sprint has what it needs, the lessons leave the room

Twelve arogh closeouts converged on this shape after paying for the gaps: handoffs left in-review
across a boundary for weeks because nothing swept the board; stale notices surfacing in every later
packet; a retro of real framework findings that was never dispatched; three reusable artifact shapes
the PM invented and never wrote down; and a long session that lost two rulings and their reasons at
compaction. Read this when the last gate of a sprint is closed, and the session-carry section
whenever a session runs long.

## The gate, then the judgment

`bash muster/scripts/muster-closeout.sh` prints the open-items worklist, then one ✓/✗ block over
board closure, entry bodies, decision reconciliation, budgets, durability and gate-packet notices,
and refuses green on any red. The worklist is detection; the disposition is yours, one line each:
a handoff is **closed** only when its deliverable was validated — by its own reviewers or by a
later regression pass that covered it, cited by name; otherwise it is **carried** with a note.
Requests and research items are carried or deferred explicitly. Never close on assumption: the
default is carry. No prior-sprint handoff stays in review after closeout.

## The moves

In this order, because each is read by the next: the finished board to `sprint-archive.md`
(only the active sprint stays in `current-sprint.md`); the Charter section of
`sprint-charter.md` to the archive, leaving Candidates; the last gate's packet and Verdict to
the archive, leaving `wave-review.md` empty; decisions older than the current sprint to
`decision-log-archive.md`; notices dated before this sprint deleted (an FYI that survived a whole
sprint unacted is stale; git keeps it). Then the `durable-encode` skill's promotion check: nothing
the next sprint needs lives only in a worktree. Clear the queue's Done section.

## The retro

Keep a retro-notes file all sprint and write a line the moment something breaks; memory of
friction fades within hours. Each finding carries a tag and a shape: **framework** (muster itself
fell short), **process** (how this team ran it), or **observation** (worth a note, not a fix); what
broke, the evidence, which earlier finding it repeats, and the fix you would make. At closeout,
compress:

- **Framework findings** go upstream, batched, as a field report through the framework guide (run
  `/muster` in this tab and ask for one); the payload is shown verbatim and sent only on the
  founder's yes. Never
  edit `muster/` from a project. A this-sprint workaround for a muster gap lives in the retro notes
  or a step prompt, never as a standing agent-context note — it goes stale when muster fixes it.
- **Process findings** become one decision-log entry: fixes accepted, with the files touched;
  fixes rejected, with the reason. A fix is prose that every later session pays to read, so it
  earns its lines: it prevents a failure that recurs at least once a sprint or costs more than one
  rework round. One line in an existing skill beats a new section. Two retros, same failure: fix it
  regardless of cost.
- **Observations** become Candidates for the next charter, source-tagged.

Then the question that keeps the PM from re-deriving its own work: **what did I write twice this
sprint?** A packet shape, a brief, a script. If it is product-specific, it becomes a project skill
under `knowledge-base/agent-skills/pm/`; if it is generic, it is a framework finding for the field
report. Project-held skills reach muster only through that report.

## Seed the next charter

The Candidates section has grown all sprint. Add what closeout knows: handoffs carried
unvalidated, device-gate items parked, numbers deferred with what unblocks them, and the retro's
observations. Then write the next sprint's planning step as the queue's only entry, its first
instruction "Read the `sprint-planning` skill in full before planning." The merge to `develop` is
the founder's call; you leave the branch ready and say so.

## The session-carry brief

When a session runs long, write this before compaction, to a tracked file, in product words:

```
Role and place: <role>, <project>, <phase and step we are in>
Standing rules this session: <each rule the founder set, one line>
Where we are: <what is done, what is mid-flight, what is next>
Rulings and why: <every decision taken this session, each with its reason>
Process patterns agreed: <how we agreed to run things, one line each>
Pending: <open asks, unread notices, questions waiting on the founder>
Drop list: <what the next session should NOT carry>
```

Rulings without their why are the field failure: the next session re-opens them.

## Followed-check

Closeout was run to this skill when: the closeout gate is green and every worklist line has a
written disposition; the five moves are made and the queue holds only the planning step; the retro
is dispatched, logged or parked by tag; the skillify question has an answer; the charter's
Candidates carry the carry list; and the branch is handed to the founder, not merged.
