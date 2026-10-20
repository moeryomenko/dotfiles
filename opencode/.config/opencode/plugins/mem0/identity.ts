// Ported from mem0's agent-plugin-core (typescript/src/identity.ts).
// Derives a stable project id from a git remote URL (https, ssh, or host alias).
export function parseProjectFromRemote(remote: string): string | null {
  const match = remote.trim().match(/[:/]([^/:]+)\/([^/:]+?)(?:\.git)?\/?$/)
  return match ? `${match[1]}-${match[2]}` : null
}
