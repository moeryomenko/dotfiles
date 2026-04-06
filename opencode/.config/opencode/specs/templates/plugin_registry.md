# Plugin Registry Skill

This skill provides a summary of all installed plugins and their known capabilities to help agents leverage extended functionality.

## Capability Summary

To use this skill, an agent should invoke it when they need to understand the "menu" of available enhancements in the current environment.

### How to Use

1.  **Identify Need**: When a mission requires advanced capabilities (memory, complex tasking, specialized formatting).
2.  **Call Skill**: Invoke `skill("plugin-registry")`.
3.  **Analyze Output**: Parse the returned list of plugins and their associated skills/commands.
4.  **Execute**: Proceed to use the identified plugin via the appropriate tool (`skill`, `bash`, or `write`).

## Implementation Note for Developers

When creating a new plugin, ensure you include:
- A clear description in your documentation.
- At least one `SKILL.md` file that defines a standard interface for agent interaction.
- Registration of any custom tools in the local environment.