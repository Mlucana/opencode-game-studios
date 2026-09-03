#!/bin/bash
# Claude Code PostToolUse hook: Validates asset files after Write/Edit
# Checks naming conventions for files in assets/ directory
#
# Exit behavior:
#   exit 0 = success or advisory warnings only (non-blocking)
#   exit 1 = blocking error (build-breaking issues: invalid JSON, missing required fields)
#
# Input schema (PostToolUse for Write/Edit):
# { "tool_name": "Write", "tool_input": { "file_path": "assets/data/foo.json", "content": "..." } }

INPUT=$(cat)

# Parse file path -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Normalize path separators (Windows backslash to forward slash)
FILE_PATH=$(echo "$FILE_PATH" | sed 's|\\|/|g')

# Only check files in assets/
if ! echo "$FILE_PATH" | grep -qE '(^|/)assets/'; then
    exit 0
fi

FILENAME=$(basename "$FILE_PATH")
WARNINGS=""   # Style/convention issues -- exit 0 with advisory message
ERRORS=""     # Build-breaking issues -- exit 1 to block the operation

# ADVISORY: Check naming convention (lowercase with underscores only)
# Naming issues are style violations -- warn but do not block
# Uses grep -E (POSIX) not grep -P (Perl) for Windows Git Bash compatibility
if echo "$FILENAME" | grep -qE '[A-Z[:space:]-]'; then
    WARNINGS="$WARNINGS\n  NAMING: $FILE_PATH must be lowercase with underscores (got: $FILENAME)"
fi

# BLOCKING: Check JSON validity for data files
# Invalid JSON will break runtime loading -- this is a build-breaking error
if echo "$FILE_PATH" | grep -qE '(^|/)assets/data/.*\.json$'; then
    if [ -f "$FILE_PATH" ]; then
        # Find a working Python command.
        # Probe EXECUTION, not presence: on Windows the Microsoft Store
        # execution aliases put `python`/`python3` on PATH as stubs that exit 49
        # instead of running. `command -v` finds those, so a presence check
        # reports an interpreter that does not work — and the json.tool call
        # below then reads that exit code as "invalid JSON" and reports a
        # blocking error on a perfectly valid file.
        PYTHON_CMD=""
        for cmd in python python3 py; do
            if "$cmd" -c "pass" >/dev/null 2>&1; then
                PYTHON_CMD="$cmd"
                break
            fi
        done

        if [ -n "$PYTHON_CMD" ]; then
            if ! "$PYTHON_CMD" -m json.tool "$FILE_PATH" > /dev/null 2>&1; then
                ERRORS="$ERRORS\n  FORMAT: $FILE_PATH is not valid JSON — fix syntax errors before continuing"
            fi
        else
            # Say so out loud. A validator that silently does not validate is
            # worse than no validator: it reads as a clean pass. Matches the
            # warning validate-commit.sh already emits in this same situation.
            WARNINGS="$WARNINGS\n  SKIPPED: cannot check JSON validity of $FILE_PATH (no working Python interpreter found)"
        fi
    fi
fi

# Report warnings (advisory -- non-blocking)
if [ -n "$WARNINGS" ]; then
    echo -e "=== Asset Validation: Warnings ===$WARNINGS\n==================================\n(Warnings are advisory. Fix before final commit.)" >&2
fi

# Report errors and block if any build-breaking issues found
if [ -n "$ERRORS" ]; then
    echo -e "=== Asset Validation: ERRORS (Blocking) ===$ERRORS\n===========================================\nFix these errors before proceeding." >&2
    exit 1
fi

exit 0
