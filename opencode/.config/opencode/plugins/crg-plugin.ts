import { Plugin } from "@opencode/plugin"
import { execFile } from "node:child_process"
import { promisify } from "node:util"

/**
 * code-review-graph plugin for OpenCode.
 *
 * Keeps the knowledge graph up-to-date and surfaces status
 * information automatically during coding sessions.
 *
 * Installed by: code-review-graph install --platform opencode
 */

const execFileAsync = promisify(execFile)

// Run a code-review-graph command without allowing failures to affect the
// OpenCode session.
async function run(args: string[], cwd: string): Promise<string> {
  try {
    const result = await execFileAsync("code-review-graph", args, { cwd })
    return result.stdout.trim()
  } catch {
    return ""
  }
}

export default Plugin.define({
  id: "code-review-graph",

  async setup(ctx) {
    // Auto-update the graph after file edits and show its status for new
    // sessions. Event subscriptions are scoped to this plugin instance.
    const controller = new AbortController()
    void (async () => {
      for await (const event of ctx.event.subscribe({
        types: ["file.edited", "session.created"],
        signal: controller.signal,
      })) {
        if (event.type === "file.edited") {
          await run(["update", "--skip-flows"], ctx.location.directory)
        } else if (event.type === "session.created") {
          const output = await run(["status"], ctx.location.directory)
          if (output) console.log("[code-review-graph]", output)
        }
      }
    })().catch(() => {
      // Event delivery must never affect the OpenCode session.
    })

    // Detect changes before shell commands that create a git commit.
    await ctx.shell.hook("create.before", async (event) => {
      if (!/^git\s+commit(?:\s|$)/i.test(event.command)) return
      const output = await run(
        ["detect-changes", "--brief"],
        event.cwd,
      )
      if (output) {
        console.log("[code-review-graph] Pre-commit analysis:\n" + output)
      }
    })

    return () => controller.abort()
  },
})
