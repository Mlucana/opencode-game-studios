// CCGS hooks for OpenCode — ported from Claude Code Game Studios (.claude/hooks/*.sh).
// Reuses the original bash scripts so validation behavior stays identical.
// Every hook fails gracefully: if bash/scripts are missing, the session continues
// normally (same philosophy as the original template).

import { execFileSync } from "node:child_process"

function runScript(cwd, script, stdinJson, timeoutMs) {
  try {
    const out = execFileSync("bash", [script], {
      input: stdinJson || "",
      cwd,
      encoding: "utf8",
      timeout: timeoutMs || 15000,
    })
    return { code: 0, output: out || "" }
  } catch (e) {
    // execFileSync throws on non-zero exit; Claude hooks use exit 2 = block.
    return {
      code: typeof e.status === "number" ? e.status : 1,
      output: String(e.stdout || "") + String(e.stderr || e.message || ""),
    }
  }
}

async function log(client, message) {
  try {
    await client.app.log({
      body: { service: "ccgs-hooks", level: "info", message: String(message).slice(0, 2000) },
    })
  } catch {
    // logging must never break the session
  }
}

export const CcgsHooks = async ({ directory, client }) => {
  const cwd = directory || process.cwd()
  const hook = (name) => `.claude/hooks/${name}`

  return {
    // PreToolUse equivalent: validate git commit / push commands.
    "tool.execute.before": async (input, output) => {
      try {
        const tool = input.tool || ""
        const args = (output && output.args) || {}

        if (tool === "bash" && typeof args.command === "string") {
          const stdinJson = JSON.stringify({ tool_name: "Bash", tool_input: { command: args.command } })
          const commit = runScript(cwd, hook("validate-commit.sh"), stdinJson)
          if (commit.code === 2) throw new Error(commit.output.trim() || "Commit blocked by validate-commit.sh")
          if (commit.output.trim()) await log(client, commit.output.trim())
          const push = runScript(cwd, hook("validate-push.sh"), stdinJson)
          if (push.output.trim()) await log(client, push.output.trim())
        }

        // SubagentStart equivalent: audit trail when a subagent is spawned via task.
        if (tool === "task") {
          const agentType =
            args.subagent_type || args.agent || args.description || "unknown"
          runScript(
            cwd,
            hook("log-agent.sh"),
            JSON.stringify({ session_id: "", agent_id: "", agent_type: String(agentType) }),
            5000,
          )
        }
      } catch (e) {
        // Re-throw blocks the tool call (only for real validations above).
        // runScript itself never throws, so this is a validation block.
        if (e && /BLOCKED|blocked by/i.test(e.message || "")) throw e
      }
    },

    // PostToolUse equivalent: asset validation + skill-change advice.
    "tool.execute.after": async (input, output) => {
      try {
        const tool = input.tool || ""
        const args = (output && output.args) || {}
        if ((tool === "write" || tool === "edit") && typeof args.filePath === "string") {
          const stdinJson = JSON.stringify({
            tool_name: tool === "write" ? "Write" : "Edit",
            tool_input: { file_path: args.filePath },
          })
          const assets = runScript(cwd, hook("validate-assets.sh"), stdinJson, 10000)
          if (assets.code !== 0) throw new Error(assets.output.trim() || "Asset validation failed")
          if (assets.output.trim()) await log(client, assets.output.trim())
          const skill = runScript(cwd, hook("validate-skill-change.sh"), stdinJson, 5000)
          if (skill.output.trim()) await log(client, skill.output.trim())
        }
        // SubagentStop equivalent.
        if (tool === "task") {
          runScript(cwd, hook("log-agent-stop.sh"), JSON.stringify({}), 5000)
        }
      } catch (e) {
        if (e && /BLOCKED|Asset validation failed|not valid JSON/i.test(e.message || "")) throw e
      }
    },

    // SessionStart / Stop / Notification equivalents.
    event: async ({ event }) => {
      try {
        const type = (event && event.type) || ""
        if (type === "session.created") {
          const start = runScript(cwd, hook("session-start.sh"), "", 10000)
          if (start.output.trim()) await log(client, start.output.trim())
          const gaps = runScript(cwd, hook("detect-gaps.sh"), "", 10000)
          if (gaps.output.trim()) await log(client, gaps.output.trim())
        }
        if (type === "session.idle" || type === "session.deleted") {
          runScript(cwd, hook("session-stop.sh"), "", 10000)
        }
      } catch {
        // never break the session
      }
    },

    // PreCompact / PostCompact equivalent: keep file-backed state across compaction.
    "experimental.session.compacting": async (input, output) => {
      try {
        const pre = runScript(cwd, hook("pre-compact.sh"), "", 10000)
        if (pre.output.trim() && output && Array.isArray(output.context)) {
          output.context.push(pre.output.trim().slice(0, 4000))
        }
      } catch {
        // never break compaction
      }
    },
  }
}
