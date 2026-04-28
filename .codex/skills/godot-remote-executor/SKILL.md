---
name: godot-remote-executor
description: Use when controlling or inspecting the live Godot editor for SwordCultivator through the Hastur Operation Plugin, including scene/node edits, editor operations, project settings, live game runtime inspection, or executing GDScript through the local broker.
---

# Godot Remote Executor

Use this skill when a task benefits from interacting with a running Godot editor instead of only editing files. The project is wired for the Hastur Operation Plugin:

- Godot plugin: `addons/hasturoperationgd`
- Broker server: `tools/hastur-operation-plugin/broker-server`
- Start broker: `tools/start_hastur_broker.ps1`
- List status/executors: `tools/hastur_status.ps1`
- Execute snippets: `tools/hastur_execute.ps1`
- Token file: `tools/hastur-operation-plugin/.hastur-auth-token`

## Workflow

1. Start or verify the broker:
   ```powershell
   tools/start_hastur_broker.ps1
   ```
2. Ensure the Godot editor is open for this project. `START_GODOT.cmd` starts the broker automatically before launching Godot, and the editor plugin also tries to start the same script when the project opens.
3. Discover connected executors:
   ```powershell
   tools/hastur_status.ps1
   ```
4. Execute GDScript against the editor:
   ```powershell
   tools/hastur_execute.ps1 -Type editor -Code 'executeContext.output("project", ProjectSettings.get_setting("application/config/name"))'
   ```
5. Check `compile_success`, `run_success`, `compile_error`, `run_error`, and `outputs` before assuming the operation worked.

## GDScript Snippet Rules

Snippet mode is used when the code does not contain `extends`. The executor wraps it in a `@tool extends RefCounted` object, so access the editor through:

```gdscript
var plugin = executeContext.editor_plugin
var ei = plugin.get_editor_interface()
var tree = Engine.get_main_loop() as SceneTree
var edited_scene = ei.get_edited_scene_root()
executeContext.output("scene", str(edited_scene.name if edited_scene else "<none>"))
```

Return data with `executeContext.output(key, value)`, converting values to strings. Keep snippets short and avoid long loops or blocking operations because they run on the Godot main thread.

## Editor Operations

Prefer Godot editor APIs through `EditorInterface` and `EditorPlugin`. For file saves, scene edits, import/reload operations, and project settings, verify return codes or resulting state. Many Godot APIs return `OK` on success instead of throwing.

When changing user-visible scene state, inspect the current scene first, make a small targeted change, then read back enough state to confirm it landed.

## Runtime Executor

The plugin includes `addons/hasturoperationgd/game_executor.gd`, but do not add it as an Autoload or start/stop the game without explicit user approval. If the user asks for live runtime inspection, first check `tools/hastur_status.ps1` for a `type: "game"` executor. If none exists, explain whether the game is running and whether the GameExecutor autoload is configured before making changes.

## Error Handling

- HTTP 404 usually means no matching executor; rerun `tools/hastur_status.ps1`.
- HTTP 504 means the editor/game did not respond within the broker timeout; simplify the snippet or check whether the runtime is paused.
- Compilation failures are usually GDScript syntax issues: use `func`, lowercase `true/false/null`, tabs/consistent indentation, `var x: int` for types, and `%`/`format()` for string formatting.
- Never expose the broker outside localhost and do not print the auth token unless the user explicitly needs it.
