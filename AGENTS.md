# OpenCode Game Studios — Game Studio Agent Architecture

Ported from [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
for [OpenCode](https://opencode.ai/docs). Same studio, same workflows — adapted to how
OpenCode discovers agents, commands, skills, rules and hooks.

Indie game development managed through 49 coordinated subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.7 (see `docs/engine-reference/godot/VERSION.md`)
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## How OpenCode discovers this studio

| Original (Claude Code)              | Port (OpenCode — this repo)                              |
|-------------------------------------|----------------------------------------------------------|
| `.claude/agents/*.md` (49)          | `.opencode/agents/*.md` (49, `mode: subagent`) — invoke with `@name` or the `task` tool. Originals kept in `.claude/agents/` |
| `.claude/skills/*/SKILL.md` (73, slash commands) | `.opencode/commands/*.md` (73: `/start`, `/brainstorm`, `/dev-story`…) — self-contained wrappers. Originals kept in `.claude/skills/` and auto-discovered via the `skill` tool |
| `.claude/settings.json` hooks       | `.opencode/plugins/ccgs-hooks.js` — reuses `.claude/hooks/*.sh` unchanged |
| `.claude/rules/*.md` (path-scoped)  | Listed in `opencode.json` → `instructions`, plus the table below |
| `AskUserQuestion` tool              | `question` tool                                          |
| `TodoWrite` tool                    | `todowrite` tool                                         |

Agent models are inherited from your OpenCode session (no `model:` pinned, works
with any provider). The original tier (opus/sonnet/haiku) is noted at the top of
each agent file — pin a `model:` in frontmatter if you want a fixed one.

## Project Structure

Read `.claude/docs/directory-structure.md` (via the Read tool) for the full layout.
Top level: `src/` game source · `assets/` art/audio/data · `design/` GDDs and narrative
· `docs/` technical docs and ADRs · `tests/` test suites · `tools/` build pipeline
· `prototypes/` throwaway builds (isolated from `src/`) · `production/` sprints,
milestones, release tracking and session state.

## Engine Version Reference

See `docs/engine-reference/godot/VERSION.md`.

## Technical Preferences

Read `.claude/docs/technical-preferences.md` (via the Read tool).

## Coordination Rules

Read `.claude/docs/coordination-rules.md` (via the Read tool). Summary: vertical
delegation (directors → leads → specialists), horizontal consultation without binding
cross-domain decisions, conflicts escalate to the shared parent (`creative-director`
for design, `technical-director` for technical), cross-department changes coordinated
by `producer`. Invoke agents with the `task` tool or `@name` mentions.

## Path-scoped rules

Before editing under these paths, read the matching rule file (all auto-loaded via
`opencode.json`, but the table decides which one governs):

- `src/gameplay/**` → `.claude/rules/gameplay-code.md`
- `src/core/**`, engine code → `.claude/rules/engine-code.md`
- `src/ai/**` → `.claude/rules/ai-code.md`
- `src/networking/**` → `.claude/rules/network-code.md`
- `src/ui/**` → `.claude/rules/ui-code.md`
- shaders/VFX → `.claude/rules/shader-code.md`
- `assets/data/**`, data files → `.claude/rules/data-files.md`
- `design/gdd/**` → `.claude/rules/design-docs.md`
- narrative/dialogue → `.claude/rules/narrative.md`
- `tests/**` → `.claude/rules/test-standards.md`
- `prototypes/**` (relaxed) → `.claude/rules/prototype-code.md`

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

Read `.claude/docs/coding-standards.md` (via the Read tool).

## Context Management

Read `.claude/docs/context-management.md` (via the Read tool). Session state lives in
`production/session-state/active.md` — the hooks plugin surfaces it at session start
and preserves it across compaction.
