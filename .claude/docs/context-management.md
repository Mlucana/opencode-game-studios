# Context Management

Context is the most critical resource in a Claude Code session. Manage it actively.

## File-Backed State (Primary Strategy)

**The file is the memory, not the conversation.** Conversations are ephemeral and
will be compacted or lost. Files on disk persist across compactions and session crashes.

### Session State File

Maintain `production/session-state/active.md` as a living checkpoint. Update it
after each significant milestone:

- Design section approved and written to file
- Architecture decision made
- Implementation milestone reached
- Test results obtained

The state file should contain: current task, progress checklist, key decisions
made, files being worked on, and open questions.

#### Pruning — mandatory at session close

`active.md` must be **pruned when a session wraps up**, not left to accumulate.
It is a *checkpoint*, not a log: the review logs, GDDs, ADRs and git history are
where history belongs.

**Why this is a rule and not a preference**: left unpruned, the file grows by
accretion and starts carrying *contradictory* state from different sessions —
a checklist marked complete in one section and empty in another, a resolved
blocker still flagged as pending, an engine version that three other files
already moved past. At that point the file actively misleads the next session,
which is worse than having no state file at all. This is not hypothetical: it
happened by 2026-08-03, when the file had reached 355 lines spanning four
sessions with all four of those defects present.

**When to prune** (any of these — do not wait to be asked):
- The user signals the session is wrapping up
- A major workflow completes (a GDD approved, a review closed, a sprint task done)
- Before recommending `/clear`, and at natural compaction points

**What to do:**
1. **Promote** the current session's outcome to the top, as the authoritative state
2. **Condense** durable knowledge worth carrying forward — decisions and their
   rationale, open gaps, cross-system constraints, risks
3. **Delete** anything superseded: completed checklists, resolved alerts, stale
   `<!-- STATUS -->` blocks, duplicated sections
4. **Reconcile contradictions rather than keeping both sides.** Verify against the
   actual files before declaring something resolved — never resolve a
   contradiction from memory of the conversation
5. **Say what was removed** in the reply, so the user can object if something
   mattered

**What never gets pruned**: unresolved blockers, open questions with an owner,
constraints one system imposes on another, and architecture decisions deferred to
`/create-architecture`. When in doubt, condense it — do not drop it.

**Safety net**: a `SessionEnd` hook (`.claude/hooks/check-state-size.sh`) warns
when `active.md` exceeds **200 lines**, so an unpruned file gets flagged instead
of silently rotting. Override the threshold with `ACTIVE_MD_MAX_LINES=300 claude`.
The hook is a backstop, not the mechanism — it fires *after* the session, so it
cannot prune anything. Pruning is still your job during the session.

### Status Line Block (Production+ only)

When the project is in Production, Polish, or Release stage, include a structured
status block in `active.md` that the status line script can parse:

```markdown
<!-- STATUS -->
Epic: Combat System
Feature: Melee Combat
Task: Implement hitbox detection
<!-- /STATUS -->
```

- All three fields (Epic, Feature, Task) are optional — include only what applies
- Update this block when switching focus areas
- The status line displays it as a breadcrumb: `Combat System > Melee Combat > Hitboxes`
- Remove or empty the block when no active work focus exists

After any disruption (compaction, crash, `/clear`), read the state file first.

### Incremental File Writing

When creating multi-section documents (design docs, architecture docs, lore entries):

1. Create the file immediately with a skeleton (all section headers, empty bodies)
2. Discuss and draft one section at a time in conversation
3. Write each section to the file as soon as it's approved
4. Update the session state file after each section
5. After writing a section, previous discussion about that section can be safely
   compacted — the decisions are in the file

This keeps the context window holding only the *current* section's discussion
(~3-5k tokens) instead of the entire document's conversation history (~30-50k tokens).

## Proactive Compaction

- **Compact proactively** at ~60-70% context usage, not reactively at the limit
- **Use `/clear`** between unrelated tasks, or after 2+ failed correction attempts
- **Natural compaction points:** after writing a section to file, after committing,
  after completing a task, before starting a new topic
- **Focused compaction:** `/compact Focus on [current task] — sections 1-3 are
  written to file, working on section 4`

## Context Budgets by Task Type

- Light (read/review): ~3k tokens startup
- Medium (implement feature): ~8k tokens
- Heavy (multi-system refactor): ~15k tokens

## Subagent Delegation

Use subagents for research and exploration to keep the main session clean.
Subagents run in their own context window and return only summaries:

- **Use subagents** when investigating across multiple files, exploring unfamiliar code,
  or doing research that would consume >5k tokens of file reads
- **Use direct reads** when you know exactly which 1-2 files to check
- Subagents do not inherit conversation history — provide full context in the prompt

## Compaction Instructions

When context is compacted, preserve the following in the summary:

- Reference to `production/session-state/active.md` (read it to recover state)
- List of files modified in this session and their purpose
- Any architectural decisions made and their rationale
- Active sprint tasks and their current status
- Agent invocations and their outcomes (success/failure/blocked)
- Test results (pass/fail counts, specific failures)
- Unresolved blockers or questions awaiting user input
- The current task and what step we are on
- Which sections of the current document are written to file vs. still in progress

**After compaction:** Read `production/session-state/active.md` and any files being
actively worked on to recover full context. The files contain the decisions; the
conversation history is secondary.

## Recovery After Session Crash

If a session dies ("prompt too long") or you start a new session to continue work:

1. The `session-start.sh` hook will detect and preview `active.md` automatically
2. Read the full state file for context
3. Read the partially-completed file(s) listed in the state
4. Continue from the next incomplete section or task
