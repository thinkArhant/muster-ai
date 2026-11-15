# Durable Encode — the approved product becomes the written truth

After a gate, three things can disagree: what the founder approved (the packet), what the code now
does (the commits and tests), and what the durable documents say. Arogh met every form of it: a
product spec still describing a tap-to-advance player two gates after hands-free was approved;
agent-context tasks saying "before Step 10 every number is proposed" a day after the gate passed;
carried findings living only in a worktree that was merged and deleted. Encoding is the pass that
makes the durable set tell the truth again. Read it after each verdict is cascaded, before the next
wave's Developer reads the spec, and once more at closeout.

## The three-way reconcile

Walk the gate's rulings against the two other sources, one ruling at a time:

1. **Packet → docs.** Every RATIFIED or AMENDED number lives in exactly one durable place — the
   product spec section that owns the behaviour, or the engine ledger the project names — written
   as current truth with its reason. The charter row's "evidence" cites where it now lives. An
   approved screen rewrites the live design spec; the old screen is archived whole, never left as
   "previously X, now Y". A CARRY ruling leaves the surface described as absent and the seam
   described as kept.
2. **Code → docs.** The halt report's commit list and test delta say what actually landed. A doc
   that describes behaviour the code does not have is corrected or the gap becomes a candidate;
   `architecture.md` names every seam the wave added or reshaped.
3. **Docs → contexts.** Each affected role's agent-context points at the updated section and says
   nothing time-bound: "the player is hands-free (spec §4)", never "once the gate passes". Gate-
   dependent wording is the field failure above.

## The durability lens

Durable artifacts (the spec, design specs, architecture, brand, test strategy, assumptions, product
skills) carry only the current truth and the reason for it. Would a new team adopting the product
from these files need this line? Rationale stays; archaeology goes: no handoff or bug IDs, no
sprint or step numbers, no dated edit bullets, no "revised per". History belongs in the transient
files and in git. `bash muster/scripts/muster-lint-durability.sh` is the floor; the lens is the rule.

When a ruling invalidates an assumption in `foundational-assumptions.md`, follow its touchpoint
list and cascade every file it names in the same pass.

## Promote before the worktree dies

An autonomous sprint runs in a worktree that is merged, then deleted; anything gitignored or
worktree-local goes with it. Before closeout, every artifact the next sprint needs — carried gate
findings, an open punch list, the decision a charter builds on — lives in a tracked
`knowledge-base/` file. The lens: a fresh worktree with no memory of this session has what it
needs, or it does not.

## Followed-check

Encoding was run to this skill when: the durability lint is green on the durable set; every
ratified row cites the durable place it lives in and that place describes the approved behaviour;
the design spec for each approved screen matches the build; no agent-context line names a gate or a
step as a time; and nothing the next sprint reads lives only in a worktree.
