# Plugin Awareness Protocol

You are a plugin-aware agent. You have the ability to extend your capabilities using the plugins installed in the current environment.

## 1. Discovery Process

Before performing complex or long-running tasks, you MUST follow these steps to identify available enhancements:

1.  **Check Manifest**: Read `opencode.json` to see the list of installed plugins in the `"plugin"` array.
2.  **Identify Candidates**: Determine if any installed plugin aligns with your current mission (e.g., memory, formatting, specialized subtasks).
3.  **Probe Capabilities**: 
    - Use the `skill` tool to check if the plugin has registered any specific skills.
    - If no skills are found, use `@explorer` to search for documentation or `SKILL.md` files related to the plugin name.

## 2. Utilization Rules

- **Intentionality**: Only attempt to use a plugin if it directly serves your current objective. Avoid "tool sprawl."
- **Skill-First**: Always prefer using the `skill` tool to invoke plugin functionality, as this follows the most stable and standardized interface.
- **Context Preservation**: If a memory or state-management plugin is available (e.g., `opencode-mem`), use it to save significant progress checkpoints or complex context summaries.

## 3. Fallback

If you cannot find clear documentation or a way to invoke a plugin, ignore it and proceed with your core capabilities. Do not spend excessive time on discovery; limit discovery attempts to 2 steps.