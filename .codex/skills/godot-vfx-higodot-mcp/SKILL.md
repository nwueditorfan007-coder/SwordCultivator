---
name: godot-vfx-higodot-mcp
description: Use when creating, tuning, or discussing implementation of SwordCultivator visual effects, particles, trails, glows, hit sparks, sword aura, spell effects, material effects, animation-driven effects, or other art VFX in Godot. Prefer HiGodot/Godot AI MCP tools and engine-native effect systems instead of writing custom code.
---

# Godot VFX With HiGodot MCP

Use this skill for SwordCultivator art-effect work: particles, sword trails, aura, slash arcs, hit sparks, impact bursts, environmental wisps, material glow, UI effect polish, and animation-timed VFX.

## Core Rule

When the user asks to make or adjust visual effects, use Godot's engine-native effect systems through HiGodot MCP (`godot-ai`) rather than starting from handwritten GDScript.

Default to:

- `particle_manage` for `GPUParticles2D` / `GPUParticles3D`, `ParticleProcessMaterial`, draw passes, presets, restart, and parameter tuning.
- `material_manage` for StandardMaterial/CanvasItemMaterial/ShaderMaterial resource creation, assignment, and parameter changes.
- `animation_manage` for timed visibility, scale, color, alpha, burst timing, shake, fade, and pulse tracks.
- `resource_manage` for gradients, curves, noise textures, environments, and reusable resources.
- `node_create`, `node_set_property`, `node_find`, `scene_get_hierarchy`, `scene_save`, `logs_read`, and `editor_screenshot` for placement, inspection, persistence, and validation.

Do not create a new VFX script, procedural drawing script, or custom simulation as the first move. Only write code if the user explicitly asks for code, or if the desired effect cannot be represented cleanly with Godot nodes/resources; explain that exception before coding.

## Workflow

1. Start from the player's read: what combat event the effect communicates, where attention should go, how long it should live, and how it avoids hiding the character/enemy/sword action.
2. Inspect the current scene with HiGodot MCP before changing it. Find the target node, existing effect nodes, materials, animation players, and scene path.
3. Build the effect using engine resources first: particles, materials, gradients, curves, lights, animation tracks, and scene-node composition.
4. Keep the edit small and reversible. Prefer adding a named child node or reusable `.tres` resource over altering unrelated gameplay scripts.
5. Validate through the editor: read logs, check hierarchy/properties, restart particles if relevant, save the scene/resource, and capture a screenshot when possible.
6. Report the result in Chinese with the effect's player-facing purpose, the nodes/resources changed, and any validation gaps.

## HiGodot Availability

The project is wired for HiGodot at:

- Plugin: `addons/godot_ai`
- MCP URL: `http://127.0.0.1:8000/mcp`
- Codex config entry: `[mcp_servers."godot-ai"]`

If the current Codex thread cannot see HiGodot MCP tools, do not silently fall back to hand-written code. First verify the Godot editor is open and the plugin log shows the server connected. If the MCP server was added after this Codex thread started, tell the user a Codex restart/new thread may be needed for tool discovery.

Use the older Hastur remote executor only for emergency inspection or project-specific editor actions that HiGodot cannot perform; for VFX creation and tuning, HiGodot MCP is the preferred path.

## Effect Judgment

For SwordCultivator, visual effects should support wuxia sword fantasy and combat readability:

- sword effects should clarify intent, rhythm, direction, and impact instead of becoming decorative noise;
- particles should carry motion shape: entry, sustain, release, dissipation;
- color/brightness should separate player action, enemy danger, interactables, and background ambience;
- bursts and trails should respect input timing and not mask control feedback;
- validate in motion when possible, not only by static hierarchy/property checks.
