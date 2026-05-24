---
name: flight-rider-body-v10-atlas
description: Recombine SwordCultivator flight rider body V10 runtime atlases from existing 8-frame body strips. Use when Codex needs to stitch, rebuild, repair, validate, or explain `flight_rider_body_v10_sheet.png` or `flight_rider_body_v10_transitions.png`, especially from `resources/flight/rider/body_v9_sources`.
---

# Flight Rider Body V10 Atlas

## Purpose

Use this skill to rebuild the V10 rider body atlases for SwordCultivator without re-generating AI art.

The runtime contract is fixed:

- Main body atlas: `2048x2816`, `8 columns x 11 rows`, `256x256` cells.
- Transition atlas: `2048x3584`, `8 columns x 14 rows`, `256x256` cells.
- Source strips are normally under `resources/flight/rider/body_v9_sources`.
- Runtime outputs belong under `resources/flight/rider`.

## Row Order

Main atlas rows:

1. `idle`
2. `forward`
3. `back`
4. `parry`
5. `sword_control_idle`
6. `array_ring_idle`
7. `array_fan_idle`
8. `array_pierce_idle`
9. `array_ring_release`
10. `array_fan_release`
11. `array_pierce_release`

Transition atlas rows:

1. `idle_to_sword_control`
2. `sword_control_to_idle`
3. `idle_to_array_ring`
4. `array_ring_to_idle`
5. `idle_to_array_fan`
6. `array_fan_to_idle`
7. `idle_to_array_pierce`
8. `array_pierce_to_idle`
9. `array_ring_to_fan`
10. `array_fan_to_ring`
11. `array_fan_to_pierce`
12. `array_pierce_to_fan`
13. `array_pierce_to_ring`
14. `array_ring_to_pierce`

## Rebuild Workflow

1. Check source files exist:
   - `body_v9_main_idle_8.png`
   - `body_v9_main_forward_8.png`
   - `body_v9_main_back_8.png`
   - `body_v9_main_parry_8.png`
   - `body_v9_main_unsheath_8.png`
   - `body_v9_main_array_morph_8.png`
   - `body_v9_main_array_release_8.png`
2. Run the bundled script:

```powershell
py .codex/skills/flight-rider-body-v10-atlas/scripts/recombine_v10_body_atlases.py `
  --source-dir resources/flight/rider/body_v9_sources `
  --out-main resources/flight/rider/flight_rider_body_v10_sheet.png `
  --out-transitions resources/flight/rider/flight_rider_body_v10_transitions.png
```

3. Validate runtime PNGs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_flight_rider_body_assets.ps1 `
  -MainSheet resources/flight/rider/flight_rider_body_v10_sheet.png `
  -TransitionSheet resources/flight/rider/flight_rider_body_v10_transitions.png
```

4. If code was changed too, run Godot headless:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs '--quit-after','2'
```

## Composition Rules

Do not change row names or dimensions unless the runtime code is changed at the same time.

Use these semantic interpretations:

- `sword_control_idle` is the sustained right-mouse sword-control pose, recombined from stable `unsheath` frames.
- `array_ring_idle`, `array_fan_idle`, and `array_pierce_idle` are sustained form poses, not morph loops. They should hold one readable posture with only tiny variation:
  - ring: held embrace / guarding circle
  - fan: opened-arm fan control
  - pierce: pointing / line-control intent
- `array_*_release` rows are short pulses. Frame 1 and frame 8 should land near the corresponding form idle.
- Transition rows are pragmatic production rows made from source-frame combinations. They are allowed to use larger body changes than idle rows, but frame 8 must land near the target form's held posture.

Default frame recipes are embedded in `scripts/recombine_v10_body_atlases.py`. Prefer using the script over retyping frame lists.

## Safety Notes

- Preserve original source strips. Do not overwrite files in `body_v9_sources` unless explicitly asked.
- If a source strip was hand-corrected, rerun the script instead of editing the final atlas manually.
- If the three array idle rows feel too similar in-game, the correct fix is new source strips or a revised recipe, not runtime state-machine changes.
