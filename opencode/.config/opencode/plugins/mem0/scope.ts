// Ported from mem0's agent-plugin-core (typescript/src/scoping.ts) plus the
// scope helpers in integrations/opencode-plugin/scope.ts.
import { existsSync, readFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

export type Scope = "project" | "session" | "global"

export interface ScopeContext {
  userId: string
  appId: string
  runId: string
}

export function normalizeScope(value: unknown): Scope {
  return value === "session" || value === "global" ? value : "project"
}

export const asScope = normalizeScope

export function resolveToolScope(requested: Scope | undefined, configured: Scope): Scope {
  const scope = requested ?? configured
  if (scope === "global" && configured !== "global") {
    throw new Error("Select global scope in the plugin settings or /mem0-scope command first.")
  }
  return scope
}

function validateContext(scope: Scope, context: ScopeContext): void {
  const keys: Array<keyof ScopeContext> = ["userId"]
  if (scope !== "global") keys.push("appId")
  if (scope === "session") keys.push("runId")
  for (const key of keys) {
    if (!context[key]?.trim() || /^\*+$/.test(context[key].trim())) {
      throw new Error(`Invalid memory scope ${key}`)
    }
  }
}

export function scopeSearchFilters(scope: Scope, context: ScopeContext): Record<string, string> {
  validateContext(scope, context)
  if (scope === "session") {
    return { user_id: context.userId, app_id: context.appId, run_id: context.runId }
  }
  return scope === "global"
    ? { user_id: context.userId }
    : { user_id: context.userId, app_id: context.appId }
}

export function scopeAddParams(scope: Scope, context: ScopeContext): Record<string, string> {
  validateContext(scope, context)
  if (scope === "session") {
    return { userId: context.userId, appId: context.appId, runId: context.runId }
  }
  return scope === "global"
    ? { userId: context.userId }
    : { userId: context.userId, appId: context.appId }
}

function context(userId: string, appId: string, runId: string): ScopeContext {
  return { userId, appId, runId }
}

export function scopeFilters(scope: Scope, userId: string, appId: string, runId: string): Record<string, string> {
  return scopeSearchFilters(scope, context(userId, appId, runId))
}

export function scopeWrites(
  scope: Scope,
  userId: string,
  appId: string,
  runId: string,
): { user_id: string; app_id?: string; run_id?: string } {
  const values = scopeAddParams(scope, context(userId, appId, runId))
  return {
    user_id: values.userId,
    ...(values.appId ? { app_id: values.appId } : {}),
    ...(values.runId ? { run_id: values.runId } : {}),
  }
}

/** Read and parse `~/.mem0/settings.json`, returning {} when missing or invalid. */
export function loadSettings(): Record<string, unknown> {
  try {
    const settingsPath = join(homedir(), ".mem0", "settings.json")
    if (!existsSync(settingsPath)) return {}
    return JSON.parse(readFileSync(settingsPath, "utf8"))
  } catch {
    return {}
  }
}

export function loadGlobalSearch(): boolean {
  return loadSettings().global_search === true
}

/** The user's persisted default scope, read fresh on every operation. */
export function loadDefaultScope(): Scope {
  return resolveDefaultScope(loadSettings())
}

export function resolveDefaultScope(settings: Record<string, unknown> | null | undefined): Scope {
  return normalizeScope(settings?.default_scope)
}

export const SCOPE_GUIDANCE =
  'Memory tools accept an optional `scope`: omit it (or "project") for normal queries; use "session" to limit to the current run; use "global" only after the user enables /mem0-scope global.'
