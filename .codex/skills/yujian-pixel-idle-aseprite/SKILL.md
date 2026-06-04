---
name: yujian-pixel-idle-aseprite
description: Use when creating, refining, validating, or previewing SwordCultivator Yujian body-only pixel sprite idle sequences in Aseprite, especially 96x96 or 512-cell right-facing hover idle frames. Prefer this skill when image_gen sprite rows create visible swords, unstable anchors, split body parts, or unsuitable animation motion.
---

# Yujian Pixel Idle Aseprite

## Purpose

Use this skill to make controllable SwordCultivator Yujian character body sprites with Aseprite/Python scripts instead of asking `image_gen` to draw final animation frames.

This workflow intentionally prioritizes:

- body-only character sprites; no visible flying sword, platform, weapon, trail, or VFX baked into the body
- fixed feet/center anchor across frames
- small idle motion that preserves the base pose
- clean pixel silhouettes without AI chroma-key split artifacts

It is for production-direction prototyping. The first pass can be visually simple; stability and editability matter more than AI illustration quality.

## When To Use

Use this skill when the user asks for:

- direct Aseprite drawing of a SwordCultivator Yujian pixel character
- body-only Yujian rider/character idle frames
- right-facing hover idle pixel animation
- fixing problems from `image_gen` rows: visible sword, anchor drift, split robes/hair/feet, broken frame-to-frame motion
- a repeatable Aseprite `.aseprite` source plus PNG sprite sheet and preview

Do not use this skill for:

- AI concept generation; use `imagegen` or `yujian-8way-cruise-imagegen`
- replacing the runtime 7x7 `yujian_cruise_idle.png`; use `yujian-sprite-sequence-assets`
- Godot runtime VFX tuning; use Godot/VFX skills

## Core Contract

For the first right-facing hover idle pass:

- Direction: `01_right`; body and invisible sword axis read toward screen right.
- Character: black/gray wuxia cultivator, long hair, top bun, robe, wide sleeve, sash/ribbon.
- Body-only: no visible sword under feet and no held sword.
- Anchor: feet/lowest body pixels must stay fixed. Do not let robe hem or ribbons become the lowest point.
- Motion: 8 frames, about `120ms` each. Keep legs and feet locked; move head/torso by 0-1 px and hair/sleeves/robe by 1-3 px.
- Canvas: draw source at `96x96` unless the user requests another size. Export a `512x512`-cell sheet for project preview if useful.

Player-facing feel: the figure is balancing on an invisible flying sword, not walking, gliding, standing on a platform, or posing as a normal side-view NPC.

## Recommended Workflow

1. Confirm the target scope.
   - Default: right-facing `01_right`, body-only, 8-frame hover idle.
   - Do not integrate into the main prototype unless the user asks.

2. Generate/edit the Aseprite source.
   - Prefer `tools/draw_yujian_pixel_right_idle.lua`.
   - It creates `01_right_hover_idle_pixel_8f.aseprite`, a `96x96` horizontal strip, and a scaled preview.
   - Edit the Lua drawing script for shape changes, then regenerate.

3. Create a 512-cell project preview sheet.
   - Scale `96x96` frames by an integer factor, usually `5x` to `480x480`, centered inside `512x512`.
   - Use nearest-neighbor scaling only.

4. Validate with commands, not just visual impression.
   - Check Aseprite frame count and tag range.
   - Check PNG dimensions and transparent corners.
   - Check per-frame bbox bottom is identical.
   - Open Aseprite for playback.

5. Report the limitations honestly.
   - A script-drawn pixel pass is stable and editable, but not final illustration quality.
   - If the user wants higher art quality, the next step should be hand-edited Aseprite layers, not returning to `image_gen` animation rows.

## Commands

Create/update the right-facing 96x96 Aseprite animation:

```powershell
$dir = 'E:\SwordCultivator\resources\flight\yujian_hover_idle_right_pixel_v1'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
aseprite --batch `
  --script-param "out_file=$dir/01_right_hover_idle_pixel_8f.aseprite" `
  --script-param "sheet_file=$dir/01_right_hover_idle_pixel_8f_96.png" `
  --script-param "preview_file=$dir/01_right_hover_idle_pixel_preview.png" `
  --script-param 'frame_count=8' `
  --script-param 'frame_seconds=0.12' `
  --script 'tools\draw_yujian_pixel_right_idle.lua'
```

Create a `4096x512` sheet by integer-scaling each `96x96` frame into a `512x512` cell:

```powershell
@'
from pathlib import Path
from PIL import Image
base = Path('resources/flight/yujian_hover_idle_right_pixel_v1')
raw = Image.open(base / '01_right_hover_idle_pixel_8f_96.png').convert('RGBA')
cell, src_cell, scale, frames = 512, 96, 5, 8
sheet = Image.new('RGBA', (cell * frames, cell), (0, 0, 0, 0))
for i in range(frames):
    frame = raw.crop((i * src_cell, 0, (i + 1) * src_cell, src_cell))
    large = frame.resize((src_cell * scale, src_cell * scale), Image.Resampling.NEAREST)
    canvas = Image.new('RGBA', (cell, cell), (0, 0, 0, 0))
    canvas.alpha_composite(large, ((cell - large.width) // 2, (cell - large.height) // 2))
    sheet.alpha_composite(canvas, (i * cell, 0))
sheet.save(base / '01_right_hover_idle_pixel_8f_512.png')
'@ | py -
```

Validate Aseprite frame metadata:

```powershell
aseprite --batch `
  'resources\flight\yujian_hover_idle_right_pixel_v1\01_right_hover_idle_pixel_8f.aseprite' `
  --list-tags `
  --data 'artifacts\yujian_hover_idle_right_v1\aseprite_pixel_animation_metadata.json'
```

Validate dimensions and transparent corners:

```powershell
Add-Type -AssemblyName System.Drawing
$paths = @(
  'resources\flight\yujian_hover_idle_right_pixel_v1\01_right_hover_idle_pixel_8f_96.png',
  'resources\flight\yujian_hover_idle_right_pixel_v1\01_right_hover_idle_pixel_8f_512.png'
)
foreach ($p in $paths) {
  $img = [System.Drawing.Bitmap]::FromFile($p)
  $corners = @(
    $img.GetPixel(0,0).A,
    $img.GetPixel($img.Width-1,0).A,
    $img.GetPixel(0,$img.Height-1).A,
    $img.GetPixel($img.Width-1,$img.Height-1).A
  ) -join ','
  Write-Output "$p`t$($img.Width)x$($img.Height)`tcornersA=$corners"
  $img.Dispose()
}
```

Open the animation in Aseprite:

```powershell
$aseprite = 'C:\Users\Han_112\Tools\Aseprite\1.3.17.2-source-build\aseprite.exe'
$file = 'E:/SwordCultivator/resources/flight/yujian_hover_idle_right_pixel_v1/01_right_hover_idle_pixel_8f.aseprite'
$script = 'E:/SwordCultivator/tools/open_yujian_right_hover_idle_in_aseprite.lua'
Start-Process -FilePath $aseprite -ArgumentList @('--script-param', "file=$file", '--script', $script) -WorkingDirectory 'E:\SwordCultivator'
```

## Quality Gate

Before calling the output acceptable, verify:

- no visible flying sword, platform, trail, or held weapon in body frames
- Aseprite metadata has exactly 8 frames, tag from `0` to `7`
- `96x96` sheet is `768x96`; `512` sheet is `4096x512`
- transparent corners are alpha `0` for sheets/frames
- bbox bottom is identical across all frames after 512-cell export
- motion reads as hover idle: stable legs/feet, minor body breathing, hair/sleeve/robe lag
- silhouette remains one connected readable body; no split hair/robe/foot artifacts

If the user flags a visual problem, inspect the generated preview and patch the drawing script. Do not try to fix pixel-rig issues by reintroducing `image_gen` row generation.

## Known Failure Modes

- Long low ribbons can become the lowest bbox point and appear as anchor drift. Keep them above the foot line.
- Large robe sway makes the character look like walking or floating cloth instead of controlled hover.
- Too much black fill destroys small-scale readability; add sparse gray/rim pixels.
- A 512 preview can look coarse because it is a 5x integer enlargement of 96x96 source; judge animation stability at source scale and readability at target scale.
