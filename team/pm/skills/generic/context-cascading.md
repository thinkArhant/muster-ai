# Context Cascading Skill

## Purpose
When cascading product context to specialist agents, tailor what each role needs to know. Each agent should receive filtered, relevant context — not a dump of everything. The goal is to give each agent exactly what they need to do their job without overwhelming them or leaving gaps.

## Per-Agent Context Guide

### Developer
**Needs to know**: What to build and technical constraints.
- Tech stack and architecture constraints (platform, language, framework, backend)
- Core algorithm/logic requirements (key business rules, constraints — from research/validation)
- Content/asset pipeline requirements (file types, delivery mechanism, storage)
- Data model considerations (key entities, relationships, storage strategy)
- Performance requirements (rendering, load time, offline behavior)
- Device/platform support matrix

**Key references**: product-spec.md, architecture.md, relevant research files

### UI/UX Designer
**Needs to know**: Who the users are, what they experience, and the brand's visual identity.
- Target personas with behavioral details (from user-insights.md)
- User journey: onboarding → core experience → progress/retention loop
- Onboarding requirements (what data to collect, how many steps)
- Key flow UX requirements (primary interaction patterns, content display, transitions)
- Visual content direction (characters, imagery, animation style — from brand-guidelines)
- Brand aesthetic direction (from brand-guidelines.md)
- Platform conventions (platform-specific design guidelines)

**Key references**: research/user-insights.md, product-brief.md, brand-guidelines.md

### Content
**Needs to know**: Brand voice, character personalities, and what copy is needed.
- Brand voice and personality traits (from brand-guidelines.md)
- Brand characters or mascots, if the brand has them (from brand-guidelines)
- In-app copy surfaces: onboarding, core feature UI, system messages, notifications, error states
- Naming conventions (consistent terminology across the product)
- Domain messaging tone (how to communicate expertise/credibility without jargon)
- Naming conventions for app sections and features

**Key references**: brand-guidelines.md, research/user-insights.md

### Marketing
**Needs to know**: How to position and sell the product.
- Positioning vs. competitors (from competitive-analysis.md — key differentiators, gaps the product fills)
- Pricing strategy and rationale (from monetization research)
- App Store/marketplace optimization insights (keyword opportunities, category positioning)
- Target personas for acquisition messaging (which persona to target first, where they are)
- Launch strategy considerations (pre-launch, beta, public launch phases)
- Success metrics related to acquisition (downloads, conversion targets)

**Key references**: research/competitive-analysis.md, research/monetization.md, research/app-store-intel.md, research/market-landscape.md

### Legal
**Needs to know**: Compliance and liability requirements.
- Content IP considerations (AI-generated or licensed content ownership)
- Domain-specific liability and disclaimers
- Terms of service scope (subscription billing, content licensing, user data)
- Privacy policy needs (data types collected, sensitivity classification)
- App Store/platform compliance requirements
- Data storage and processing practices

**Key references**: product-brief.md, product-spec.md

### QA
**Needs to know**: What to test and how to validate quality.
- MVP feature scope for test plan creation (from product-spec.md)
- Device/platform matrix (target devices and versions)
- Key user flows to test (from product-spec feature list)
- Acceptance criteria from product-spec.md (the definition of "done" for each feature)
- Content quality validation (asset rendering, accuracy, consistency)
- Performance benchmarks (rendering, responsiveness, load times)

**Key references**: product-spec.md, test-strategy.md

## Cascading Principles

1. **Filter for relevance**: Developer doesn't need marketing strategy. Marketing doesn't need data model details. Each agent should receive only what's actionable for their role.

2. **Include references to source docs**: Instead of copying entire sections, say "See knowledge-base/research/competitive-analysis.md for detailed competitor teardowns." This lets agents go deeper when needed without bloating their context.

3. **Cascade in dependency order**: Update upstream agents first so their outputs are available when downstream agents start:
   - **First wave**: UI/UX (design direction), Content (voice and copy), Legal (compliance requirements)
   - **Second wave**: Developer (needs design specs from UI/UX), Marketing (needs brand voice from Content)
   - **Third wave**: QA (needs feature specs from Developer, content from Content)

4. **Keep PM-MANAGED sections concise**: Use bullet points, not paragraphs. Link to docs instead of duplicating. Each agent's Product Context should be 10-20 lines max.

5. **Verify completeness**: After cascading, review each agent's agent-context file to confirm they have enough context to begin their assigned tasks without needing to ask clarifying questions.

## Post-Cascade Verification Checklist
After updating all agent-context files, run this check before closing the cascade:

- [ ] Each agent's Product Context reflects the current state of `product-spec.md` — no references to deprecated features or old priorities
- [ ] Every cross-agent dependency appears in BOTH the providing and receiving agent's file
- [ ] No agent's file contains information that belongs exclusively to another agent's domain (e.g., Developer doesn't have marketing strategy in their context)
- [ ] Each agent has enough context to complete their tasks without guessing at an unstated requirement — in autonomous mode the agent cannot ask a clarifying question; it fills the gap with a guess and ships it (the Cold-Start Sufficiency Test, `sprint-planning.md`). Close gaps by citing the source doc, not inlining it
- [ ] `knowledge-base/current-sprint.md` reflects the same task list as each agent's agent-context file (`knowledge-base/agent-context/<agent>.md`) Current Tasks section
- [ ] `decision-log.md` has an entry for any context change driven by a product decision

If any item fails: fix the gap before declaring the cascade complete.

## Cascade lag

Lag is a decision that reached the spec and the log but not the files agents read. Rule 11 is the
floor: grep the repo for the old term before the decision entry is final, and `bash
muster/scripts/muster-lint-decisions.sh` fails an Impact that names a role with no agent-context
update. Then re-read each named role's Product Context and Current Tasks for the old state; check
active handoffs in `agent-requests.md` and add a revision line where a deliverable in review is
affected; stale wording in `research/*.md` goes to Research through `change-log.md`, never edited
by PM. The patterns that slip: a completed PM task still listed, a descoped feature still named, an
old format or tier surviving a rename.

## The agent-context contract

- Only `<!-- PM-MANAGED -->` sections are PM's; the Agent-Specific Context section belongs to the
  agent. Read the whole file before writing it.
- A Current Task is self-contained: deliverable, priority, effort, dependencies (which agent must
  finish what first), acceptance criteria, key references. Never a pointer to the board. Never a
  skill path — the brain file indexes every skill; the task names the need, the agent picks the file.
- **Nothing the three layers above already say.** The project CLAUDE.md, muster/CLAUDE.md and the
  role's brain file are paid for at every bind; a line repeated here is paid twice, forever. Write
  the synthesis those files cannot have. `bash muster/scripts/muster-lint-context-dup.sh` warns on
  every duplicated line.
- Cross-agent dependencies live in brain files, both sides, checked by `muster-lint-deps.sh`.
- A brief to a specialist ends with "decide and act": cascade the context and the constraints, name
  the decision the specialist owns, and do not pre-make the design or architecture call.
- Three or more revision rounds on one handoff is a misalignment for the founder, not a fourth round.

## Just-in-time mode

Activated when a specialist returns `HALT: agent-context null (first invocation)` from a Task invocation. Goal: populate the agent's agent-context file from the current knowledge base, apply any decisions accrued since onboarding, then re-invoke the agent with the original task in the same turn. User-transparent — surface only a brief "populating <agent> context (~30s, one-time)…" note; do not treat as an error.

### Procedure

The lock and the stamp are mechanical: `bash muster/scripts/muster-jit-populate.sh lock <role>`
(refuses while another populate is under fifteen minutes old), write the file, then
`muster-jit-populate.sh commit <role>` (refuses placeholders or a missing Current Tasks section,
stamps `.populated`, releases the lock). The judgment is the filter: read what this role's guide
above names, plus `current-sprint.md` for its tasks; write Product Context in 10–20 lines that
reference docs rather than copy them; apply the decisions logged since `onboarded_at` whose Impact
names this role (Rule 11); then re-invoke the agent with its original prompt. One short note to
the founder — "populating <role> context, one time" — never a question.

### When NOT to JIT-populate
- `.populated` missing entirely → halt with: "Muster setup incomplete — `.populated` state file missing. Re-run `scripts/setup-existing-project.sh --resume`."
- Agent-context file has **real product context** (filled-in role summary, current tasks, project specifics — not just the unfilled template scaffolding with placeholder text like `[Project Name]` or empty section headers) but `.populated` says `null` → set the `.populated` timestamp to match the file's git mtime (or current time if untracked), re-invoke. Do not overwrite. If the file is just the unfilled template, treat it as empty and do a full populate (Procedure above).
- Required source docs (`product-spec.md`, `architecture.md`) empty or placeholder → halt with: "Knowledge base not populated — complete reverse-discovery first (`reverse-discovery.md`)." Indicates onboarding didn't finish.
