# Plugin Awareness

This file documents currently installed plugins and their purpose.
Load this BEFORE making changes that interact with plugin behavior.

## Currently Installed Plugins

| Plugin | Purpose | Source |
|--------|---------|--------|
| `@franlol/opencode-md-table-formatter@latest` | Formats markdown tables consistently | npm |
| `opencode-mem` | Persistent cross-session memory for agents | npm |
| `@plannotator/opencode@latest` | Interactive annotation UI for plans and reviews | npm |
| `@spoons-and-mirrors/subtask2@latest` | Sub-task decomposition and tracking | npm |
| `./plugins/revdiff-plan-review.ts` | Plan review via revdiff TUI | local |

## How to Check for New Plugins

Plugins are registered in `opencode.json` under the `plugin` array.
Auto-discovered plugins (no config entry needed) live in `.opencode/plugin/`
or `.opencode/plugins/`.
