# mem0 plugin (OpenCode V2 port)

Local port of [`@mem0/opencode-plugin`](https://github.com/mem0ai/mem0/tree/main/integrations/opencode-plugin)
to the OpenCode **V2** plugin API.

The published package implements the V1 plugin API only. On OpenCode 2.x it fails
to load:

```
level=WARN message="failed to load plugin" target=@mem0/opencode-plugin
cause="Plugin must export a default definition with an id and an effect or setup function."
```

V1 plugin implementations do not run in V2, so this directory reimplements the
same behavior against `@opencode/plugin` 2.x.

## Layout

| File | Origin |
|------|--------|
| `index.ts` | Port of `integrations/opencode-plugin/opencode-mem0.ts` |
| `api-key.ts` | Port of `integrations/opencode-plugin/api-key.ts` |
| `identity.ts` | Port of `agent-plugin-core/typescript/src/identity.ts` `parseProjectFromRemote` |
| `scope.ts` | Port of `agent-plugin-core/typescript/src/scoping.ts` + `opencode-plugin/scope.ts` |
| `lifecycle.ts` | Secret redaction from `agent-plugin-core/typescript/src/lifecycle.ts` |
| `telemetry.ts` | Port of `opencode-plugin/telemetry.ts` (default inverted, see below) |
| `skills/` | Copy of `opencode-plugin/opencode-skills/` (7 skills) |

Dependencies (`@opencode/plugin`, `mem0ai`) come from the config directory's
`node_modules`. Both are gitignored, so no per-plugin `package.json` is tracked.

## How it is wired

V1 extension point -> V2 API:

| V1 | V2 |
|----|----|
| `tool` map | `ctx.tool.transform` (10 tools, JSON Schema inputs) |
| `config` hook (`skills.paths` + `command` map) | `ctx.skill.transform` + `ctx.command.transform` |
| `chat.message` | `ctx.session.hook("prompt", ...)` |
| `experimental.chat.messages.transform` | `ctx.session.hook("context", ...)` pushing to `event.system` |
| `experimental.session.compacting` | `ctx.session.hook("compaction", ...)` |
| `tool.execute.before` / `tool.execute.after` | `ctx.tool.hook("execute.before" / "execute.after", ...)` |
| `shell.env` | `ctx.shell.hook("create.before", ...)` |
| returned `dispose` | cleanup function returned by `setup` |
| `$` (Bun shell) | `node:child_process` `execFile` |
| `client.app.log` | `console.error` (V2 `ctx.app` has no log method) |

Tools: `add_memory`, `search_memories`, `get_memories`, `get_memory`,
`update_memory`, `delete_memory`, `delete_all_memories`, `delete_entities`,
`list_entities`, `get_event_status`.

Skills and slash commands: `mem0-context-loader`, `mem0-forget`,
`mem0-remember`, `mem0-scope`, `mem0-search`, `mem0-status`, `mem0-tour`.

## Configuration

`MEM0_API_KEY` must be in the environment. It is resolved by
`api-key.ts` from `process.env`, then from the usual shell profiles
(`.zshrc`, `.bashrc`, `.zprofile`, `.bash_profile`, `.profile`); fish users
export it with `set -gx` so the child process inherits it.

Optional environment variables, unchanged from upstream:

- `MEM0_USER_ID` — override the resolved OS user name
- `MEM0_APP_ID` — override the project id (default: git remote `owner-repo`)
- `MEM0_TELEMETRY` — see below

Scope state lives in `~/.mem0/settings.json` (`default_scope`,
`global_search`), written by the `mem0-scope` skill.

## Deviations from upstream

1. **Telemetry is opt-in.** Upstream sends PostHog events unless
   `MEM0_TELEMETRY` is falsey. A local plugin should not phone a third-party
   analytics endpoint by default, so the check is inverted: nothing is sent
   unless `MEM0_TELEMETRY` is `true`/`1`/`yes`/`on`. Event names and payload
   shape are unchanged.
2. **Command arguments are forwarded.** Upstream's `/mem0-*` templates dropped
   any text typed after the command, so `/mem0-scope global` would lose
   `global`. This port appends it as `Arguments: <text>` and attaches the skill
   to the submitted prompt.
3. **Context is injected as system text.** Upstream prepended a
   `## Mem0 Memory Context` block to the first user message once per session.
   V2 injects it into `event.system`, which is rebuilt for every model request,
   so the block is present on each turn instead of once.
4. **Session-scope `run_id` is still a plugin-instance id** (`ses_<ts>_<rand>`),
   matching upstream. It is stable for the lifetime of the OpenCode process
   rather than per conversation.
5. **`delete_entities` requires an id.** Upstream forwarded an empty parameter
   set to `mem0ai`'s `deleteUsers()`, which then enumerates and deletes every
   entity in the account. This port throws unless `user_id`, `agent_id`,
   `app_id`, or `run_id` is supplied, so the account-wide path is unreachable
   from a tool call.
6. **`delete_all_memories` prefers explicit ids over `scope`.** Upstream
   resolved the target only from `scope`, silently ignoring ids passed
   alongside it. This port uses any explicit `user_id`/`app_id`/`agent_id`/
   `run_id` first and falls back to `scope` only when none are given.
7. **The shell tool is matched as `shell`.** V2 registers the shell tool under
   the name `shell`; upstream matched `bash` only, so its error-recall hook
   never fired on 2.x. This port matches both names.
8. **Shell output is read from `content` parts or `output`.** V2 returns a
   tool result's `content` as either a string or an array of content parts, and
   the shell tool uses the array form (`[{type:"text",text:...}]`). Upstream
   assumed a string, so the error-recall hook would see nothing; this port
   flattens both shapes (and the raw `output`) before scanning for errors.
9. **The MEMORY.md guard also scans `patchText`.** V2's `patch` tool passes only
   the unified diff in `patchText`, with no file-path field. Upstream read a
   path only, so a `patch` targeting `MEMORY.md` would slip through; this port
   scans the patch body as well.

`console.log`/`console.error` from plugins are not captured in
`~/.local/share/opencode/log/opencode.log`; only load failures are.

## Verification

Load state:

```bash
opencode reload
opencode plugin list          # shows: mem0  local  .../plugins/mem0/index.ts
grep 'plugins/mem0' ~/.local/share/opencode/log/opencode.log
```

Behavioral self-test against a fake V2 context (registers everything from
`setup`, then exercises tools, hooks, skills and commands against the real mem0
API):

```bash
cd /tmp/opencode && bun run mem0-selftest.ts
```

The self-test writes to a dedicated `mem0-port-selftest` user/app scope and
deletes it afterwards.
