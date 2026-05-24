# SwordCultivator V9 Sprite Generation Reference

Load this reference when generating or repairing SwordCultivator flight rider body V9 source strips.

## Key Files

- Task package: `AI/御剑人物Body序列帧任务包_V9.md`
- Master reference: `resources/flight/rider/body_v9_sources/body_v9_master_reference.png`
- Runtime sheet: `resources/flight/rider/flight_rider_body_v9_sheet.png`
- Main source strips: `resources/flight/rider/body_v9_sources/body_v9_main_<action>_8.png`
- Chroma sources: `resources/flight/rider/body_v9_sources/body_v9_main_<action>_8_chroma.png`
- Alpha raw sources: `resources/flight/rider/body_v9_sources/body_v9_main_<action>_8_alpha_raw.png`
- Transition strips: `resources/flight/rider/body_v9_transitions/body_v9_transition_<from>_to_<to>_8.png`

## Runtime Main Row Order

Use 1-based row numbers when replacing rows in the runtime sheet:

1. `idle`
2. `forward`
3. `back`
4. `parry`
5. `unsheath`
6. `array_release`
7. `array_morph`

The main sheet is `2048x1792`, `8 columns x 7 rows`, `256x256` per cell.

## Height Targets

- `idle`: `166-170px`
- `forward`: `145-155px`, slim forward lean, not prone
- `back`: `150-160px`
- `parry`: `158-172px`
- `unsheath`: `158-172px`
- `array_release`: `158-172px`
- `array_morph`: `158-172px`

The normal anchor is `x=128, y=219`, with no more than about `2px` drift.

## Master Binding

The master reference contains four pose types:

1. idle hover
2. forward extreme
3. back extreme
4. combat-ready

Use the pose type that matches the target action:

- `idle` uses idle hover.
- `forward` uses forward extreme.
- `back` uses back extreme.
- `parry`, `unsheath`, `array_release`, and `array_morph` use combat-ready as the body template.

For combat-ready-derived rows, keep lower body, foot spacing, waist, belt, head size, face, and robe base close to the master. The generated motion should mostly change hands, wrists, sleeves, shoulder line, hair, and cyan ribbons.

## Action Prompt Notes

`unsheath`:
Start near combat-ready. Move from hands close to chest/waist into right-hand remote sword-control traction, with left hand assisting the seal. Do not draw a sword. Frame 8 should return near frame 1 or frame 5 without a jump.

`parry`:
Use a prepared guard and sleeve/body recoil. The external weapon/VFX layer owns the sword arc; the body row only shows hand and sleeve force.

`array_release`:
Show double-hand outward release and sleeve opening. Do not draw a full sword array.

`array_morph`:
Show continuous hand-seal rotation and directional changes. It must not look like `array_release`; avoid simple double-hand push poses.

## Common Failure Modes

- The generated strip invents a new fighting stance instead of using the combat-ready master.
- The character becomes chibi, big-headed, or too thick.
- The strip includes a sword blade, platform, full array, text, labels, or grid lines.
- Frames are distributed unevenly, making component extraction choose the wrong blobs.
- A row passes size checks but visually changes face, hair, belt, robe color, or shoulder width.
- `array_release` and `array_morph` become visually identical.
