#!/bin/bash
# Claude Code SessionEnd hook: warn when the session state file needs pruning
#
# production/session-state/active.md is a CHECKPOINT, not a log. Left unpruned it
# grows by accretion and starts carrying contradictory state from different
# sessions — a checklist complete in one section and empty in another, a resolved
# blocker still flagged pending. At that point it actively misleads the next
# session, which is worse than having no state file at all.
#
# The pruning rule itself lives in .claude/docs/context-management.md (loaded every
# session via the CLAUDE.md @import). This hook is only the safety net for when
# the session ends without it happening.
#
# Threshold override: ACTIVE_MD_MAX_LINES=300 claude
#
# Input schema (SessionEnd): JSON on stdin, unused here.
# Output: JSON with systemMessage when over threshold; silent otherwise.

STATE_FILE="production/session-state/active.md"
MAX_LINES="${ACTIVE_MD_MAX_LINES:-200}"

# Nothing to check — no state file is a valid state.
[ -f "$STATE_FILE" ] || exit 0

LINES=$(wc -l < "$STATE_FILE" 2>/dev/null | tr -d '[:space:]')

# Unreadable or non-numeric: stay silent rather than emit a bogus warning.
case "$LINES" in
    ''|*[!0-9]*) exit 0 ;;
esac

[ "$LINES" -le "$MAX_LINES" ] && exit 0

OVER=$((LINES - MAX_LINES))

printf '{"systemMessage":"active.md has %s lines (%s over the %s-line threshold). It is a checkpoint, not a log — prune it at the start of the next session: promote current state, condense durable decisions, delete what is superseded. Rule: .claude/docs/context-management.md"}\n' \
    "$LINES" "$OVER" "$MAX_LINES"

exit 0
