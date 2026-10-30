import { execFile } from "node:child_process"
import { promisify } from "node:util"
import { Plugin } from "@opencode/plugin"

const execFileAsync = promisify(execFile)

/**
 * code-review-graph plugin for OpenCode.
 *
 * Keeps the knowledge graph up-to-date and surfaces status
 * information automatically during coding sessions.
 */

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
    const controller = new AbortController()

    void (async () => {
      for await (const event of ctx.event.subscribe({
        types: ["file.edited", "session.created"],
        signal: controller.signal,
      })) {
        const cwd = event.location?.directory ?? ctx.location.directory

        if (event.type === "file.edited") {
          await run(["update", "--skip-flows"], cwd)
        } else if (event.type === "session.created") {
          const output = await run(["status"], cwd)
          if (output) console.log("[code-review-graph]", output)
        }
      }
    })().catch(() => {
      // Event delivery must never affect the OpenCode session.
    })

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
