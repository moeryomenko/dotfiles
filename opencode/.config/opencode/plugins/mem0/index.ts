// Mem0 memory plugin for OpenCode (V2 plugin API).
//
// Ported from mem0's @mem0/opencode-plugin (integrations/opencode-plugin/opencode-mem0.ts),
// which targets the V1 plugin API and therefore does not load on OpenCode 2.x.
//
// V1 -> V2 translation:
//   tool map              -> ctx.tool.transform
//   config hook           -> ctx.skill.transform + ctx.command.transform
//   chat.message          -> ctx.session.hook("prompt")
//   messages.transform    -> ctx.session.hook("context")   (event.system)
//   session.compacting    -> ctx.session.hook("compaction")
//   tool.execute.*        -> ctx.tool.hook("execute.before" / "execute.after")
//   shell.env             -> ctx.shell.hook("create.before")
//   dispose               -> cleanup function returned by setup
import { Plugin } from "@opencode/plugin"
import { MemoryClient } from "mem0ai"
import { execFile } from "node:child_process"
import { createHash, randomBytes } from "node:crypto"
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs"
import { userInfo } from "node:os"
import { homedir } from "node:os"
import { basename, dirname, join, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { promisify } from "node:util"

import { resolveApiKey } from "./api-key.ts"
import { parseProjectFromRemote } from "./identity.ts"
import { prepareUserText } from "./lifecycle.ts"
import {
  SCOPE_GUIDANCE,
  asScope,
  loadDefaultScope,
  loadGlobalSearch,
  resolveToolScope,
  scopeFilters,
  scopeWrites,
  type Scope,
} from "./scope.ts"
import { captureEvent } from "./telemetry.ts"

const execFileAsync = promisify(execFile)

const SEARCH_WHEN = "before repeating investigation or when earlier decisions, fixes, commands, or results may help"
const SEARCH_TOOL_DESCRIPTION = `Search memories from earlier work in this repository. Use it ${SEARCH_WHEN}.`
const SEARCH_QUERY_DESCRIPTION = "A direct question about earlier work in this repository."

const CODING_CATEGORIES = [
  "architecture_decisions",
  "api_design",
  "data_models",
  "algorithms",
  "dependencies",
  "environment_setup",
  "testing_strategy",
  "debugging_notes",
  "performance",
  "security",
  "deployment",
  "code_conventions",
  "error_handling",
  "refactoring_history",
  "integrations",
  "onboarding",
  "project_meta",
]

const NUDGE_RE =
  /\b(remember\s+(this|that)|memorize|save\s+this|note\s+(this|that)|don'?t\s+forget|always\s+remember|never\s+forget|keep\s+(this|that)\s+in\s+(mind|memory)|store\s+(this|that))\b/i

const RESUME_RE =
  /where\s+(did\s+)?(we|I)\s+(leave|left)\s+off|continue\s+(from\s+)?(where|last)|what\s+were\s+we\s+(working|doing)|pick\s+up\s+where|resume\s+(from\s+|where\s+)|what.s\s+the\s+(current|latest)\s+(state|status)|catch\s+me\s+up|where\s+are\s+we/i

const ERROR_STRONG_RE = /Traceback \(most recent call last\)|panic: |FATAL:|error\[E\d+\]/
const ERROR_MULTI_RE = /(Error:|Exception:)/g
const WRITE_TOOLS = new Set([
  "Write",
  "Edit",
  "MultiEdit",
  "write",
  "edit",
  "multiEdit",
  "patch",
  "apply_patch",
])

interface Memory {
  id?: string
  memory?: string
  categories?: string[]
  createdAt?: string | Date
  status?: string
  eventId?: string
  event_id?: string
}

interface ToolArgs {
  text?: string
  id?: string
  query?: string
  user_id?: string
  app_id?: string
  agent_id?: string
  run_id?: string
  event_id?: string
  metadata?: Record<string, unknown>
  filters?: Record<string, unknown>
  infer?: boolean
  scope?: string
  limit?: number
  top_k?: number
  page?: number
  page_size?: number
}

interface Filters {
  AND?: Array<Record<string, string>>
  OR?: Array<Record<string, string>>
}

/** JSON Schema fragment helpers, kept short because ten tools repeat the same fields. */
const str = (description: string) => ({ type: "string", description })
const num = (description: string) => ({ type: "number", description })
const record = (description: string) => ({ type: "object", description, additionalProperties: true })

function extractMemories(result: unknown): Memory[] {
  const value = result as { results?: unknown } | unknown[] | null
  const list = Array.isArray(value) ? value : ((value as { results?: unknown })?.results ?? [])
  if (!Array.isArray(list)) return []
  return list.map((item) => item as Memory)
}

/**
 * Flatten a `Tool.Result` into plain text. V2 returns `content` as either a
 * string or an array of content parts (shell output is an array of text parts),
 * with the raw value optionally in `output`.
 */
function resultText(result: { content?: unknown; output?: unknown } | undefined): string {
  if (!result) return ""
  const { content } = result
  if (typeof content === "string") return content
  if (Array.isArray(content)) {
    return content
      .map((part) =>
        part && typeof part === "object" && (part as { type?: string }).type === "text"
          ? String((part as { text?: unknown }).text ?? "")
          : "",
      )
      .filter((text) => text.length > 0)
      .join("\n")
  }
  return typeof result.output === "string" ? result.output : ""
}

function generateSessionId(): string {
  return `ses_${Math.floor(Date.now() / 1000)}_${randomBytes(3).toString("hex")}`
}

async function getUserId(): Promise<string> {
  if (process.env.MEM0_USER_ID) return process.env.MEM0_USER_ID
  try {
    return userInfo().username
  } catch {
    // Fall through to the environment.
  }
  return process.env.USER || process.env.USERNAME || "unknown"
}

async function runGit(args: string[], cwd: string): Promise<string> {
  const { stdout } = await execFileAsync("git", args, { cwd })
  return stdout
}

async function getProjectId(cwd: string): Promise<string> {
  if (process.env.MEM0_APP_ID) return process.env.MEM0_APP_ID
  // Prefer the git remote's owner/repo - stable across clones, worktrees, and
  // sub-directories (handles https + ssh, incl. custom host aliases).
  try {
    const project = parseProjectFromRemote(await runGit(["remote", "get-url", "origin"], cwd))
    if (project) return project
  } catch {
    // No usable remote.
  }
  // Fall back to the git repo ROOT dir name, not cwd (which may be a
  // sub-directory, or the home dir if OpenCode was launched outside a repo).
  try {
    const top = (await runGit(["rev-parse", "--show-toplevel"], cwd)).trim()
    if (top) return basename(top)
  } catch {
    // Not a git repository.
  }
  return basename(cwd)
}

async function getBranch(cwd: string): Promise<string> {
  try {
    const branch = (await runGit(["branch", "--show-current"], cwd)).trim()
    return branch || "main"
  } catch {
    return "main"
  }
}

function categoriesFingerprint(): string {
  return createHash("sha256").update([...CODING_CATEGORIES].sort().join("\n")).digest("hex").slice(0, 16)
}

function apiKeyFingerprint(apiKey: string): string {
  return createHash("sha256").update(apiKey).digest("hex").slice(0, 16)
}

/** Configure the coding categories in the mem0 project once per API key. */
async function autoSetupCategories(mem0: MemoryClient, apiKey: string): Promise<void> {
  const stateDir = join(homedir(), ".mem0")
  const stateFile = join(stateDir, "categories_setup.json")
  const keyFp = apiKeyFingerprint(apiKey)
  const catFp = categoriesFingerprint()

  let state: Record<string, string> = {}
  try {
    if (existsSync(stateFile)) state = JSON.parse(readFileSync(stateFile, "utf8"))
  } catch {
    state = {}
  }

  if (state[keyFp] === catFp) return

  try {
    const project = (await mem0.getProject({ fields: ["customCategories"] })) as {
      custom_categories?: string[]
      customCategories?: string[]
    }
    const existing = project?.custom_categories ?? project?.customCategories ?? []
    const same =
      JSON.stringify([...existing].sort()) === JSON.stringify([...CODING_CATEGORIES].sort())
    if (!same) await mem0.updateProject({ customCategories: CODING_CATEGORIES })

    state[keyFp] = catFp
    mkdirSync(stateDir, { recursive: true })
    writeFileSync(stateFile, `${JSON.stringify(state, null, 2)}\n`)
  } catch {
    // Category setup is best effort and must never block the session.
  }
}

/**
 * Read filters for the memory tools. Precedence: an explicit `scope` arg wins;
 * then explicit `filters`/`agent_id`; otherwise the user's persisted default
 * scope, read fresh so /mem0-scope applies at once.
 */
function resolveFilters(args: ToolArgs, globalSearch: boolean, userId: string, appId: string): Filters {
  const existing = args.filters as Filters | undefined
  if (existing) {
    const andClauses = existing.AND
    if (Array.isArray(andClauses)) {
      const hasUserId = andClauses.some((clause) => clause && "user_id" in clause)
      const hasAppId = andClauses.some((clause) => clause && "app_id" in clause)
      const hasAgentId = andClauses.some((clause) => clause && "agent_id" in clause)
      const next = [...andClauses]
      if (args.agent_id || hasAgentId) {
        if (!hasAgentId) next.push({ agent_id: args.agent_id as string })
      } else if (!hasUserId) {
        next.push({ user_id: args.user_id ?? userId })
      }
      if (!hasAppId) next.push({ app_id: args.app_id ?? appId })
      return { AND: next }
    }
    if (andClauses === undefined) {
      const hasUserId = "user_id" in existing
      const hasAppId = "app_id" in existing
      const hasAgentId = "agent_id" in existing
      if (!hasAppId || (!hasUserId && !hasAgentId)) {
        const next = Object.entries(existing).map(([key, value]) => ({ [key]: value }))
        if (args.agent_id || hasAgentId) {
          if (!hasAgentId) next.push({ agent_id: args.agent_id as string })
        } else if (!hasUserId) {
          next.push({ user_id: args.user_id ?? userId })
        }
        if (!hasAppId) next.push({ app_id: args.app_id ?? appId })
        return { AND: next }
      }
    }
    return existing
  }

  if (globalSearch) return { OR: [{ user_id: "*" }] }

  if (args.agent_id) return { AND: [{ agent_id: args.agent_id }, { app_id: args.app_id ?? appId }] }

  return { AND: [{ user_id: args.user_id ?? userId }, { app_id: args.app_id ?? appId }] }
}

interface SkillFile {
  name: string
  description?: string
  path: string
  content: string
}

function readSkillFile(dir: string, name: string): SkillFile | undefined {
  const path = resolve(dir, name, "SKILL.md")
  if (!existsSync(path)) return undefined

  let raw: string
  try {
    raw = readFileSync(path, "utf8")
  } catch {
    return undefined
  }

  const frontmatter = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?/)
  const description = frontmatter?.[1].match(/^description:\s*(.+)$/m)?.[1].trim()
  return { name, description, path, content: frontmatter ? raw.slice(frontmatter[0].length) : raw }
}

function loadSkills(skillsDir: string | undefined): SkillFile[] {
  if (!skillsDir) return []
  try {
    return readdirSync(skillsDir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => readSkillFile(skillsDir, entry.name))
      .filter((skill): skill is SkillFile => skill !== undefined)
  } catch {
    return []
  }
}

/** The plugin's own skills directory, resolved next to this module. */
function resolveSkillsDir(): string | undefined {
  const here = import.meta.dir ?? dirname(fileURLToPath(import.meta.url))
  return [resolve(here, "skills"), resolve(here, "opencode-skills")].find((candidate) => existsSync(candidate))
}

export default Plugin.define({
  id: "mem0",

  async setup(ctx) {
    const apiKey = resolveApiKey(process.env, process.env.HOME ?? homedir())
    if (!apiKey) {
      console.error("[mem0] MEM0_API_KEY is not set; memory tools are disabled. Create one at https://app.mem0.ai/dashboard/api-keys")
      return
    }

    const mem0 = new MemoryClient({ apiKey })
    const cwd = ctx.location.directory
    const userId = await getUserId()
    const appId = await getProjectId(cwd)
    const branch = await getBranch(cwd)
    const sessionId = generateSessionId()
    const globalSearch = loadGlobalSearch()

    const stats = { adds: 0, searches: 0, messages: 0 }
    const systemContext: string[] = []
    const pushContext = (text: string) => {
      if (!systemContext.includes(text)) systemContext.push(text)
    }

    let initialized = false
    let memoryCount = 0
    let msgCount = 0

    // Emit a session_stop telemetry event once when the process winds down.
    // Registered after every registration below so a mid-setup throw cannot leak it.
    let sessionStopSent = false
    const emitSessionStop = () => {
      if (sessionStopSent) return
      sessionStopSent = true
      captureEvent(
        "session_stop",
        { adds: stats.adds, searches: stats.searches, messages: stats.messages },
        apiKey,
        appId,
      )
    }

    // Auto-configure coding categories in the background (idempotent, never blocks).
    void autoSetupCategories(mem0, apiKey).catch(() => {})

    // ---- Skills -----------------------------------------------------------
    // Upstream pointed OpenCode at its own skills directory via `skills.paths`.
    // V2 has no mutable global config, so the skills are registered explicitly.
    const skills = loadSkills(resolveSkillsDir())
    if (skills.length > 0) {
      await ctx.skill.transform((editor) => {
        for (const skill of skills) {
          editor.add({
            id: skill.name,
            name: skill.name,
            description: skill.description,
            path: skill.path,
            content: skill.content,
          })
        }
      })
    }

    // ---- Commands ---------------------------------------------------------
    // Upstream registered one `/mem0-*` command per skill so the TUI slash menu
    // reaches them. Command executors must submit the prompt themselves in V2.
    if (skills.length > 0) {
      await ctx.command.transform((editor) => {
        for (const skill of skills) {
          editor.add({
            name: skill.name,
            description: skill.description ?? `Mem0 ${skill.name} skill`,
            execute: async ({ sessionID, prompt, delivery }) => {
              const identity = [
                "Identity context (resolved at plugin startup):",
                `- user_id: ${userId}`,
                `- app_id: ${appId}`,
                `- session_id: ${sessionId}`,
                `- branch: ${branch}`,
              ].join("\n")
              const body = prompt.text.trim()
              await ctx.session.prompt({
                ...prompt,
                sessionID,
                text: `Load and execute the \`${skill.name}\` skill.\n\n${identity}${body ? `\n\nArguments: ${body}` : ""}`,
                skills: [...(prompt.skills ?? []), { id: skill.name }],
                delivery,
              })
            },
          })
        }
      })
    }

    // ---- Tools ------------------------------------------------------------
    await ctx.tool.transform((editor) => {
      editor.add({
        name: "add_memory",
        description:
          "Add a new memory. This method is called everytime the user informs anything about themselves, their preferences, or anything that has any relevant information which can be useful in the future conversation. This can also be called when the user asks you to remember something. Set infer to false to store the memory verbatim without LLM fact extraction.",
        input: {
          type: "object",
          properties: {
            text: str("Memory text content"),
            user_id: str("User ID"),
            app_id: str("App/Project ID"),
            agent_id: str("Agent ID"),
            metadata: record("Metadata key-value pairs"),
            infer: {
              type: "boolean",
              description: "Set to false to store memory verbatim without LLM fact extraction",
            },
            scope: str(
              'Write scope: "project" (this repo, default), "session" (this run), or "global" (user-wide, all projects). Use "global" only when explicitly asked.',
            ),
          },
          required: ["text"],
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          stats.adds++
          captureEvent("tool_use", { tool: "add_memory" }, apiKey, appId)
          const scope: Scope = resolveToolScope(args.scope ? asScope(args.scope) : undefined, loadDefaultScope())
          const write = scopeWrites(scope, userId, appId, sessionId)
          const finalUserId = args.agent_id ? args.user_id : (args.user_id ?? write.user_id)
          const finalAppId = args.app_id ?? write.app_id

          const metadata: Record<string, unknown> = { ...(args.metadata ?? {}) }
          if (metadata.confidence === undefined) metadata.confidence = 0.7
          if (!metadata.source) metadata.source = "opencode"
          if (!metadata.type) metadata.type = "task_learning"
          if (!metadata.session_id) metadata.session_id = sessionId
          if (!metadata.files) metadata.files = ["*"]
          if (!metadata.branch) metadata.branch = branch

          let infer = args.infer
          if ((metadata.confidence as number) >= 1.0 && infer === undefined) infer = false

          const result = await mem0.add([{ role: "user", content: prepareUserText(args.text) }], {
            user_id: finalUserId,
            app_id: finalAppId,
            run_id: write.run_id,
            agent_id: args.agent_id,
            metadata,
            infer,
          })
          return { content: JSON.stringify(result) }
        },
      })

      editor.add({
        name: "search_memories",
        description: SEARCH_TOOL_DESCRIPTION,
        input: {
          type: "object",
          properties: {
            query: str(SEARCH_QUERY_DESCRIPTION),
            user_id: str("User ID"),
            app_id: str("App/Project ID"),
            agent_id: str("Agent ID"),
            filters: record("Key-value filters (e.g. metadata or user/app filters)"),
            limit: num("Maximum number of results to return (top_k)"),
            top_k: num("Maximum number of results to return (alternative parameter)"),
            scope: str(
              'Search scope: "project" (this repo, default), "session" (this run only), or "global" (across ALL your projects). Only use "global" when the user explicitly asks to search across projects.',
            ),
          },
          required: ["query"],
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          stats.searches++
          captureEvent("tool_use", { tool: "search_memories" }, apiKey, appId)
          const topK = args.limit ?? args.top_k ?? 10
          const filters = readScopeFilters(args)
          const result = await mem0.search(prepareUserText(args.query), { filters, topK })
          return { content: JSON.stringify(result) }
        },
      })

      editor.add({
        name: "get_memories",
        description:
          "List or browse stored memories without a search query -- useful for auditing what is remembered or paging through everything in a scope. To find memories relevant to a question, use search_memories instead (it ranks by semantic relevance).",
        input: {
          type: "object",
          properties: {
            user_id: str("User ID"),
            app_id: str("App/Project ID"),
            agent_id: str("Agent ID"),
            filters: record("Metadata/identity filters"),
            page: num("Page number"),
            page_size: num("Page size"),
            scope: str(
              'Scope: "project" (default), "session", or "global" (across ALL your projects). Use "global" only when explicitly asked.',
            ),
          },
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          captureEvent("tool_use", { tool: "get_memories" }, apiKey, appId)
          const result = await mem0.getAll({
            page: args.page,
            pageSize: args.page_size,
            filters: readScopeFilters(args),
          })
          return { content: JSON.stringify(result) }
        },
      })

      editor.add({
        name: "get_memory",
        description:
          "Fetch one memory by its exact ID (e.g. an ID returned by search_memories or get_memories) to read its full content and metadata.",
        input: {
          type: "object",
          properties: { id: str("The ID of the memory to retrieve") },
          required: ["id"],
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          captureEvent("tool_use", { tool: "get_memory" }, apiKey, appId)
          return { content: JSON.stringify(await mem0.get(args.id as string)) }
        },
      })

      editor.add({
        name: "update_memory",
        description:
          "Update an existing memory in place when a stored fact has changed -- requires the memory ID. Preserves the ID and history, so prefer this over deleting and re-adding.",
        input: {
          type: "object",
          properties: {
            id: str("The ID of the memory to update"),
            text: str("New text content for the memory"),
            metadata: record("New metadata key-value pairs"),
          },
          required: ["id"],
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          captureEvent("tool_use", { tool: "update_memory" }, apiKey, appId)
          const result = await mem0.update(args.id as string, {
            text: args.text === undefined ? undefined : prepareUserText(args.text),
            metadata: args.metadata,
          })
          return { content: JSON.stringify(result) }
        },
      })

      editor.add({
        name: "delete_memory",
        description:
          "Delete one or more memories by ID when they are wrong, obsolete, or the user asks to forget them. Irreversible -- only delete what is clearly no longer wanted.",
        input: {
          type: "object",
          properties: { id: str("The ID of the memory to delete") },
          required: ["id"],
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          captureEvent("tool_use", { tool: "delete_memory" }, apiKey, appId)
          return { content: JSON.stringify(await mem0.delete(args.id as string)) }
        },
      })

      editor.add({
        name: "delete_all_memories",
        description:
          "Delete ALL memories in the given scope. Destructive and irreversible -- only use when the user explicitly asks to wipe their memory. Never call speculatively. Pass either an explicit user_id/app_id/agent_id/run_id, or a scope (not both): explicit ids win when supplied.",
        input: {
          type: "object",
          properties: {
            user_id: str("User ID whose memories to delete"),
            app_id: str("App ID whose memories to delete"),
            agent_id: str("Agent ID whose memories to delete"),
            run_id: str("Run ID whose memories to delete"),
            scope: str(
              'Scope to delete: "project" (default), "session", or "global" (user-wide). Ignored when explicit ids are supplied. Use "global" only when explicitly asked.',
            ),
          },
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          captureEvent("tool_use", { tool: "delete_all_memories" }, apiKey, appId)

          // Explicit ids win over scope so the caller can always target exactly
          // what it named; scope is only a fallback that supplies the ids.
          let ids: { user_id?: string; app_id?: string; run_id?: string; agent_id?: string }
          if (args.agent_id) {
            ids = { user_id: args.user_id, app_id: args.app_id, agent_id: args.agent_id }
          } else if (args.user_id || args.app_id || args.run_id) {
            ids = { user_id: args.user_id, app_id: args.app_id, run_id: args.run_id }
          } else if (args.scope) {
            const write = scopeWrites(
              resolveToolScope(asScope(args.scope), loadDefaultScope()),
              userId,
              appId,
              sessionId,
            )
            ids = { user_id: write.user_id, app_id: write.app_id, run_id: write.run_id }
          } else {
            ids = { user_id: userId, app_id: appId }
          }

          const result = await mem0.deleteAll(ids)
          return { content: JSON.stringify(result) }
        },
      })

      editor.add({
        name: "delete_entities",
        description:
          "Delete entire user/agent/app/run entities and every memory attached to them. Destructive and irreversible -- only on explicit user request to remove a whole user, agent, or project. Requires at least one of user_id, agent_id, app_id, or run_id.",
        input: {
          type: "object",
          properties: {
            user_id: str("User ID of the entity to delete"),
            agent_id: str("Agent ID of the entity to delete"),
            app_id: str("App/Project ID of the entity to delete"),
            run_id: str("Run ID of the entity to delete"),
          },
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          captureEvent("tool_use", { tool: "delete_entities" }, apiKey, appId)

          // mem0ai's deleteUsers() with no ids enumerates and deletes EVERY
          // entity in the account. Never let a tool call reach that path.
          if (!args.user_id && !args.agent_id && !args.app_id && !args.run_id) {
            throw new Error(
              "delete_entities requires at least one of user_id, agent_id, app_id, or run_id; refusing to delete every entity in the account",
            )
          }

          const result = await mem0.deleteUsers({
            userId: args.user_id,
            agentId: args.agent_id,
            appId: args.app_id,
            runId: args.run_id,
          })
          return { content: JSON.stringify(result) }
        },
      })

      editor.add({
        name: "list_entities",
        description:
          "List the user/agent/app/run entities that have memories. Use to discover which scopes exist before searching, listing, or deleting within a specific one.",
        input: {
          type: "object",
          properties: { page: num("Page number"), page_size: num("Page size") },
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          captureEvent("tool_use", { tool: "list_entities" }, apiKey, appId)
          const result = await mem0.users({ page: args.page, pageSize: args.page_size })
          return { content: JSON.stringify(result) }
        },
      })

      editor.add({
        name: "get_event_status",
        description:
          "Check whether an asynchronous memory write (add/update/delete) finished, using the event_id that call returned. Poll this when you need to confirm a write was persisted before relying on it.",
        input: {
          type: "object",
          properties: { event_id: str("The ID of the event/async operation to check") },
          required: ["event_id"],
        },
        execute: async (raw) => {
          const args = raw as ToolArgs
          captureEvent("tool_use", { tool: "get_event_status" }, apiKey, appId)
          const response = await mem0.client.get(`/v1/event/${args.event_id}/`)
          return { content: JSON.stringify(response.data) }
        },
      })
    })

    // ---- Hooks ------------------------------------------------------------

    /** Filters for the plugin's own recall, honouring the global_search setting. */
    const recallFilters = (): Filters =>
      globalSearch ? { OR: [{ user_id: "*" }] } : { AND: [{ user_id: userId }, { app_id: appId }] }

    /** Read filters for a tool call, honouring an explicit scope then the default scope. */
    function readScopeFilters(args: ToolArgs): Filters {
      if (args.scope) {
        return scopeFilters(resolveToolScope(asScope(args.scope), loadDefaultScope()), userId, appId, sessionId)
      }
      if (args.filters || args.agent_id) return resolveFilters(args, globalSearch, userId, appId)
      const defaultScope = loadDefaultScope()
      return defaultScope === "project"
        ? resolveFilters(args, globalSearch, userId, appId)
        : scopeFilters(defaultScope, userId, appId, sessionId)
    }

    await ctx.session.hook("prompt", async (event) => {
      const userText = event.prompt.text
      if (!userText || userText.length < 10) return

      const safeText = prepareUserText(userText)
      msgCount++
      stats.messages++

      if (!initialized) {
        initialized = true

        try {
          const all = await mem0.getAll({ filters: recallFilters(), page: 1, pageSize: 1 })
          const page = all as { count?: number; results?: unknown[] }
          memoryCount =
            typeof page?.count === "number"
              ? page.count
              : Array.isArray(page)
                ? page.length
                : Array.isArray(page?.results)
                  ? page.results.length
                  : 0

          if (globalSearch) {
            pushContext(
              `Global search is ON - searches return all memories across all users and projects. Writes still use user_id="${userId}", app_id="${appId}".`,
            )
          } else {
            pushContext(
              `Always include user_id="${userId}" and app_id="${appId}" in every search_memories filter and add_memory call.`,
            )
          }

          if (memoryCount === 0) {
            pushContext(
              "New project with 0 memories. Capture decisions, conventions, and learnings as you work via the add_memory tool or the remember skill.",
            )
          }

          if (memoryCount > 0) {
            try {
              const res = await mem0.search("recent session state decisions and learnings", {
                filters: recallFilters(),
                topK: 5,
              })
              stats.searches++
              const memories = extractMemories(res)
              if (memories.length > 0) {
                pushContext(`Prior context from mem0:\n${memories.map((m) => `- ${m.memory ?? ""}`).join("\n")}`)
              }
            } catch {
              // Recall is best effort.
            }
          }

          pushContext(SCOPE_GUIDANCE)
          const activeScope = loadDefaultScope()
          if (activeScope !== "project") {
            pushContext(
              `Active default memory scope is "${activeScope}" (set via /mem0-scope). Memory tools use this when no explicit scope is given: "session" limits to this run (run_id="${sessionId}"); "global" spans all your projects (app_id="*"). Pass an explicit scope to override per call. delete_all_memories still requires an explicit scope="global" to delete user-wide.`,
            )
          }
        } catch (error) {
          console.error(`[mem0] session init error: ${(error as Error)?.message}`)
        }

        captureEvent("session_start", { memory_count: memoryCount }, apiKey, appId)
      }

      const hasRemember = NUDGE_RE.test(safeText)
      if (hasRemember) {
        pushContext(
          "[MEMORY TRIGGER] User asked to remember something. Call add_memory with the user's statement, confidence=1.0, infer=false.",
        )
      }

      const hasResume = RESUME_RE.test(safeText)
      if (hasResume) {
        try {
          const [stateRes, decisionsRes] = await Promise.all([
            mem0.search("session state current task", { filters: recallFilters(), topK: 3 }),
            mem0.search("recent decisions and learnings", { filters: recallFilters(), topK: 3 }),
          ])
          stats.searches += 2
          const seen = new Set<string>()
          const unique = [...extractMemories(stateRes), ...extractMemories(decisionsRes)].filter((memory) => {
            const id = memory.id ?? ""
            if (seen.has(id)) return false
            seen.add(id)
            return true
          })
          if (unique.length > 0) {
            pushContext(
              `Session resume context:\n${unique.map((m) => `- ${m.memory ?? ""}`).join("\n")}\n\nThese memories provide context for resuming work.`,
            )
          }
        } catch {
          // Resume recall is best effort.
        }
      }

      if (!hasResume && memoryCount > 0) {
        try {
          const res = await mem0.search(safeText, { filters: recallFilters(), topK: 5 })
          stats.searches++
          const memories = extractMemories(res)
          if (memories.length > 0) {
            pushContext(`Relevant memories:\n${memories.map((m) => `- ${m.memory ?? ""}`).join("\n")}`)
          }
        } catch {
          // Per-message recall is best effort.
        }
      }

      if (msgCount % 3 === 0) {
        void (async () => {
          try {
            await mem0.add([{ role: "user", content: safeText }], {
              user_id: userId,
              app_id: appId,
              metadata: {
                type: "auto_capture",
                source: "opencode",
                confidence: 0.7,
                session_id: sessionId,
                branch,
              },
              infer: true,
            })
            stats.adds++
          } catch {
            // Auto capture is best effort.
          }
        })()
      }

      if (msgCount % 5 === 0 && stats.adds < Math.floor(msgCount / 3)) {
        pushContext(
          "After responding, store any new decisions, learnings, or preferences from this exchange via add_memory. Keep it to 1 sentence per memory.",
        )
      }

      captureEvent(
        "user_prompt",
        { remember_detected: hasRemember, resume_detected: hasResume },
        apiKey,
        appId,
      )
    })

    // Replaces V1 `experimental.chat.messages.transform`: the assembled context
    // is rebuilt for every request, so pushing to `system` is idempotent.
    await ctx.session.hook("context", (event) => {
      if (systemContext.length === 0) return
      event.system.push({ type: "text", text: `## Mem0 Memory Context\n\n${systemContext.join("\n\n")}` })
    })

    await ctx.session.hook("compaction", async (event) => {
      try {
        const compactSessionId = event.sessionID ?? sessionId
        captureEvent(
          "pre_compact",
          { adds: stats.adds, searches: stats.searches, messages: stats.messages },
          apiKey,
          appId,
        )

        const summaryContent = `Session compacting. Project: ${appId}. Branch: ${branch}. Session: ${compactSessionId}. Stats: ${stats.adds} memories stored, ${stats.searches} searches, ${stats.messages} messages.`
        void mem0
          .add([{ role: "user", content: summaryContent }], {
            user_id: userId,
            app_id: appId,
            metadata: {
              type: "session_state",
              source: "pre-compaction",
              session_id: compactSessionId,
              branch,
            },
            infer: true,
          })
          .catch(() => {})

        const res = await mem0.search("session state decisions learnings", {
          filters: recallFilters(),
          topK: 10,
        })
        const memories = extractMemories(res)
        if (memories.length > 0) {
          event.system.push({
            type: "text",
            text: `## Mem0 Memories (preserve across compaction)\n\n${memories
              .map((m) => `- ${m.memory ?? ""}`)
              .join("\n")}\n\nIMPORTANT: After compaction, store any key decisions or learnings using the add_memory tool.`,
          })
        }
      } catch {
        // Compaction enrichment is best effort.
      }
    })

    await ctx.tool.hook("execute.before", (event) => {
      if (!WRITE_TOOLS.has(event.tool)) return
      const args = event.input as
        | { file_path?: string; filePath?: string; path?: string; patchText?: string }
        | undefined
      const filePath = String(args?.file_path ?? args?.filePath ?? args?.path ?? "")
      // V2's `patch` tool carries no file path, only the unified diff in
      // `patchText`, so scan the patch body for the guarded path too.
      const patchText = String(args?.patchText ?? "")
      if (/MEMORY\.md|\.claude\/memory/i.test(filePath) || /MEMORY\.md|\.claude\/memory/i.test(patchText)) {
        throw new Error("Use the add_memory tool instead of writing to MEMORY.md")
      }
    })

    await ctx.tool.hook("execute.after", async (event) => {
      // V1 named the shell tool `bash`; V2 registers it as `shell`.
      if (event.tool !== "shell" && event.tool !== "bash") return

      const command = String((event.input as { command?: string } | undefined)?.command ?? "")
      if (/git\s+(commit|merge|rebase)/.test(command)) return

      const output =
        event.status === "completed" ? resultText(event.result) : (event.error.message ?? "")
      if (output.length < 50) return

      const hasStrongError = ERROR_STRONG_RE.test(output)
      const multiErrors = (output.match(ERROR_MULTI_RE) ?? []).length
      if (!hasStrongError && multiErrors < 2) return

      try {
        const errorLine =
          output
            .split("\n")
            .find((line) => /Error:|Exception:|panic:|FAIL:|fatal:/i.test(line))
            ?.replace(/^\s+/, "")
            .slice(0, 120) ?? ""

        const traceFiles = [
          ...new Set(
            output.match(/[a-zA-Z0-9_./-]+\.(py|ts|tsx|js|jsx|rs|go|rb|java|sh)(:\d+)?/g) ?? [],
          ),
        ].slice(0, 5)

        const errorQuery = errorLine.slice(0, 80)
        if (errorQuery.length < 10) return

        captureEvent("bash_error", { error_detected: true }, apiKey, appId)

        const res = await mem0.search(`error: ${errorQuery}`, { filters: recallFilters(), topK: 6 })
        stats.searches++
        const memories = extractMemories(res)

        let context = `Error detected: \`${command.slice(0, 100)}\` produced:\n> ${errorLine}`
        if (traceFiles.length > 0) context += `\nFiles in stack trace: ${traceFiles.join(", ")}`
        if (memories.length > 0) {
          context += `\nPrior error memories:\n${memories.map((m) => `- ${m.memory ?? ""}`).join("\n")}`
        }
        context += "\nStore resolved errors as anti_pattern or bug_fix memories for future reference."
        pushContext(context)
      } catch {
        // Error recall is best effort.
      }
    })

    await ctx.shell.hook("create.before", (event) => {
      event.env.MEM0_USER_ID = userId
      event.env.MEM0_APP_ID = appId
      event.env.MEM0_SESSION_ID = sessionId
      event.env.MEM0_BRANCH = branch
      event.env.MEM0_GLOBAL_SEARCH = globalSearch ? "true" : "false"
    })

    try {
      process.on("beforeExit", emitSessionStop)
    } catch {
      // Some embedders disallow process listeners; telemetry is optional.
    }

    return () => {
      emitSessionStop()
      process.off("beforeExit", emitSessionStop)
    }
  },
})
