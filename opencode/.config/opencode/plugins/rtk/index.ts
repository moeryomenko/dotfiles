import { Plugin } from "@opencode/plugin"
import { execFile } from "node:child_process"
import { promisify } from "node:util"

const execFileAsync = promisify(execFile)

// RTK OpenCode plugin — rewrites commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating plugin: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.

export default Plugin.define({
  id: "rtk",

  async setup(ctx) {
    try {
      await execFileAsync("rtk", ["--version"])
    } catch {
      console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
      return
    }

    await ctx.shell.hook("create.before", async (event) => {
      try {
        const result = await execFileAsync("rtk", ["rewrite", event.command], {
          cwd: event.cwd,
          env: { ...process.env, ...event.env },
        })
        const rewritten = result.stdout.trim()
        if (rewritten && rewritten !== event.command) {
          event.command = rewritten
        }
      } catch {
        // rtk rewrite failed — pass through unchanged
      }
    })
  },
})
