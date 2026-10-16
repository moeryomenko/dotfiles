// Ported from mem0's agent-plugin-core (typescript/src/telemetry.ts) and
// integrations/opencode-plugin/telemetry.ts.
//
// DEVIATION FROM UPSTREAM: upstream sends events to PostHog by default and only
// stops when MEM0_TELEMETRY is set to a falsey value. This port inverts that
// default, because a local plugin should not phone a third-party analytics
// endpoint unless the user opts in. Set MEM0_TELEMETRY=true to restore
// upstream's behavior. Event names and payload shape are unchanged.
import { createHash, randomUUID } from "node:crypto"
import { release } from "node:os"

import { redactSecrets } from "./lifecycle.ts"

const POSTHOG_API_KEY = "phc_hgJkUVJFYtmaJqrvf6CYN67TIQ8yhXAkWzUn9AMU4yX"
const POSTHOG_BATCH_URL = "https://us.i.posthog.com/batch/"
const PORTED_VERSION = "0.4.1"
const ON_VALUES = new Set(["true", "1", "yes", "on"])

const PRIVATE_KEYS = new Set([
  "apikey",
  "authorization",
  "password",
  "query",
  "secret",
  "prompt",
  "token",
  "text",
  "memory",
  "message",
  "error",
  "path",
  "cwd",
  "userid",
  "agentid",
  "runid",
  "repoid",
  "repositoryid",
  "projectid",
  "appid",
  "filters",
])

/** Opt-in only: telemetry is off unless MEM0_TELEMETRY is explicitly enabled. */
export function isTelemetryEnabled(): boolean {
  const value = process.env.MEM0_TELEMETRY
  return value !== undefined && ON_VALUES.has(value.toLowerCase())
}

function safeValue(value: unknown): unknown {
  if (typeof value === "string") return redactSecrets(value)
  if (Array.isArray(value)) return value.map(safeValue)
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value)
        .filter(([key]) => !PRIVATE_KEYS.has(key.toLowerCase().replace(/[^a-z]/g, "")))
        .map(([key, nested]) => [key, safeValue(nested)]),
    )
  }
  return value
}

function distinctId(apiKey: string): string {
  return createHash("sha256").update(apiKey).digest("hex").slice(0, 32)
}

/**
 * Salted so the hash is not enumerable: an unsalted SHA-256 of a project id is
 * reversible by anyone who can guess the id. The API key is the salt.
 */
function projectHash(projectId?: string, apiKey?: string): Record<string, string> {
  if (!projectId || !apiKey) return {}
  return { project_hash: createHash("sha256").update(`${apiKey}:${projectId}`).digest("hex") }
}

export function buildEvent(
  eventType: string,
  properties: Record<string, unknown>,
  apiKey: string | undefined,
  projectId?: string,
): Record<string, unknown> | null {
  if (!apiKey) return null
  try {
    return {
      event: `plugin.${eventType}`,
      distinct_id: distinctId(apiKey),
      uuid: randomUUID(),
      timestamp: new Date().toISOString(),
      properties: {
        ...(safeValue({ ...properties, ...projectHash(projectId, apiKey) }) as Record<string, unknown>),
        platform: "opencode",
        os_version: release(),
        sample_rate: 1.0,
        host: "opencode",
        source: "OPENCODE_PLUGIN",
        language: "node",
        plugin_version: PORTED_VERSION,
        node_version: process.version,
        os: process.platform,
        $process_person_profile: false,
        $lib: "posthog-node",
      },
    }
  } catch {
    return null
  }
}

export function captureEvent(
  eventType: string,
  properties: Record<string, unknown>,
  apiKey: string | undefined,
  projectId?: string,
): void {
  try {
    if (!isTelemetryEnabled()) return
    const payload = buildEvent(eventType, properties, apiKey, projectId)
    if (!payload) return
    void fetch(POSTHOG_BATCH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ api_key: POSTHOG_API_KEY, batch: [payload] }),
      signal: AbortSignal.timeout(3_000),
    }).catch(() => {})
  } catch {
    // Telemetry must never affect plugin behavior.
  }
}
