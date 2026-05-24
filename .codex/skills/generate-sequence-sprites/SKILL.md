---
name: generate-sequence-sprites
description: "Generate AI-assisted 2D sprite sequence strips from a master reference, then chroma-key, normalize, inspect, stitch, and validate them. Use when Codex needs to create or redo pixel-art animation rows, 8-frame action strips, transition strips, or SwordCultivator flight rider body source rows such as idle, forward, parry, unsheath, array_morph, or array_release."
---

# Generate Sequence Sprites

## Purpose

Use this skill for project-bound sequence-frame image generation, not for final atlas stitching from existing strips. It covers the fragile path from master reference to production strip:

1. read the task package and master image,
2. generate a chroma-key source strip with `image_gen`,
3. remove the key color,
4. normalize cells to the required anchor and height,
5. replace only the requested row in a runtime sheet,
6. run validation and report unrelated failures separately.

If the task is only to rebuild SwordCultivator V10 atlases from existing source strips, use `$flight-rider-body-v10-atlas` instead.

## Default Workflow

1. Inspect the task package before prompting. For SwordCultivator V9, read `AI/御剑人物Body序列帧任务包_V9.md` and `references/sword-cultivator-v9.md`.
2. View the master reference and any relevant existing rows. Label roles explicitly: master reference, action source row, runtime sheet, transition row.
3. Prompt `image_gen` for a flat chroma-key source, usually `#ff00ff` for teal/blue characters and `#00ff00` otherwise.
4. Copy the generated file into the project as `*_chroma.png`; leave the generated original in place.
5. Remove chroma key with the installed imagegen helper, not a project-local reimplementation.
6. Normalize the transparent source into the final strip with the project normalization tool.
7. Inspect the normalized strip visually. Reject it if it changes character identity, moves the anchor, changes head size, invents weapons/platforms, or uses whole-body scaling instead of pose motion.
8. Replace only the requested row in the runtime sheet with `scripts/replace_sprite_row.py`.
9. Run the project validator. If it fails on unrelated existing rows, say that clearly instead of hiding the successful target-row result.

## Prompt Rules

The prompt must make the master binding stronger than the action description.

Include these constraints in every production prompt:

- same character as the master: head size, face, hair, shoulder width, belt height, cuffs, robe design, palette, and silhouette
- exact output structure: one horizontal strip, 8 isolated frames, no grid, no labels, no text
- flat solid chroma-key background with no shadows, gradients, texture, floor plane, or reflections
- fixed visual anchor near `x=128, y=219` for each 256x256 cell
- action expressed through body parts, sleeves, robe hem, hair, and ribbons, not whole-body scaling, random translation, stretching, or perspective warp
- body only unless the task package explicitly allows otherwise
- no held sword, flying platform, complete sword array, long trails, large VFX, watermark, or background

For combat actions, use the combat-ready master pose as the body template. Keep lower body, feet, belt, and robe base nearly fixed unless the task specifically asks for a locomotion row. Move hands, sleeves, shoulder line, hair, and ribbons first.

### 4x4 Bottom-Row Cropping Fallback

For 16-frame SwordCultivator rows, a `4 columns x 4 rows` source grid is acceptable only while all four rows have safe padding. If `image_gen` crops the fourth row once, retry with a stricter square-canvas prompt that says:

- use a large square source sheet
- each sprite occupies only 24-32 percent of its implied cell height
- leave a large flat chroma-key margin below the feet in the fourth row
- no hair, ribbon, robe hem, sleeve, foot, or toe may touch any image edge

If the retry also crops the fourth row, stop using 4x4 for that action. Switch immediately to a single horizontal 16-frame source strip prompt:

- exactly 16 isolated sprite frames in one horizontal row
- no multiple rows
- wide horizontal source sheet
- generous chroma-key padding above, below, behind ribbons, and in front of hands

Then normalize it with `tools/normalize_imagegen_body_row.py --cells 16`. Do not spend more generations trying to force a bad 4x4 layout. The runtime target is the 16x1 strip, so a horizontal source is a valid production fallback when it preserves complete sprites better.

After generating a horizontal strip, count usable sprite components before accepting it. If the model produced fewer than the requested frame count, do not treat normalization as the problem. Regenerate once with exact-count wording. If it still misses frames, switch layout or repair the strip explicitly by reusing nearby loop frames only when the action is a sustained idle where a repeated pose is acceptable.

For very wide poses such as `array_fan_idle` and release peaks, avoid blind equal-width slicing unless each sprite clearly fits inside one source slice. If sleeves, hands, or ribbons cross slice boundaries, prefer component extraction or a 4x4 square source with smaller sprites. Equal slicing is only a fallback for evenly spaced narrow poses.

## Commands

Chroma-key removal:

```powershell
py C:\Users\A\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py `
  --input resources\flight\rider\body_v9_sources\<name>_chroma.png `
  --out resources\flight\rider\body_v9_sources\<name>_alpha_raw.png `
  --key-color '#ff00ff' `
  --soft-matte `
  --transparent-threshold 55 `
  --opaque-threshold 210 `
  --despill `
  --force
```

Normalize a generated row:

```powershell
py tools\normalize_imagegen_body_row.py `
  --source resources\flight\rider\body_v9_sources\<name>_alpha_raw.png `
  --out resources\flight\rider\body_v9_sources\<name>.png `
  --cells 8 `
  --target-height 166 `
  --anchor-x 128 `
  --anchor-y 219 `
  --min-area 3000
```

Replace one runtime sheet row:

```powershell
py .codex\skills\generate-sequence-sprites\scripts\replace_sprite_row.py `
  --sheet resources\flight\rider\flight_rider_body_v9_sheet.png `
  --strip resources\flight\rider\body_v9_sources\body_v9_main_unsheath_8.png `
  --row 5 `
  --in-place
```

Validate:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate_flight_rider_body_assets.ps1 `
  -MainSheet resources\flight\rider\flight_rider_body_v9_sheet.png `
  -SkipTransitions
```

## Quality Gate

Before accepting a generated strip, check:

- Dimensions: source strip target is normally `2048x256`, with `8 x 1` cells of `256x256`.
- Anchor: each frame's visible bottom should land near `y=219`; SwordCultivator body rows use `x=128`.
- Height: use the task package range; for combat/control rows, `158-172px` is typical.
- Identity: the sprite must read as the same adult sword cultivator at game scale.
- Motion: the sequence must have visible action progression and loop endpoints that make sense.
- Layering: do not bake weapons, platforms, full arrays, or large effects into body rows.

When the image is visually close but mechanically wrong, prefer one targeted regeneration with stricter body-lock wording over manual pixel surgery.
