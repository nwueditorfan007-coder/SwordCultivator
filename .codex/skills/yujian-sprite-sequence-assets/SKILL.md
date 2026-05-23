---
name: yujian-sprite-sequence-assets
description: Use when replacing, converting, validating, or wiring SwordCultivator Yujian flight sprite sequence assets, especially resources/flight/yujian_*.png and scripts/prototypes/yujian_sprite_sequence_prototype.gd. Covers single combined sheets, zipped frame folders, 7x7 49-frame sheets, green-key backgrounds, scale/frame config, and Godot headless validation.
---

# Yujian Sprite Sequence Assets

## Scope

Use this skill for SwordCultivator's 2D Yujian flight prototype sprite sheets:

- Resource folder: `resources/flight/`
- Current prototype script: `scripts/prototypes/yujian_sprite_sequence_prototype.gd`
- Prototype scene: `scenes/prototypes/YujianSpriteSequencePrototype.tscn`

Default answer language is Chinese.

## Current Project Format

The normalized `yujian_*` flight sheets should use:

- Whole sheet: `3584x3584`
- Grid: `7x7`
- Cell: `512x512`
- Full loop: frames `0..48` for 49 frames
- Idle cruise path: `res://resources/flight/yujian_cruise_idle.png`

For `ACTION_CRUISE_IDLE`, the expected config is:

```gdscript
"columns": 7,
"rows": 7,
"start": 0,
"end": 48,
"scale": 0.46,
"key_mode": KEY_MODE_GREEN,
```

Only use shorter `end` values when the supplied animation truly has fewer usable frames.

## Workflow

1. Inspect the target action in `yujian_sprite_sequence_prototype.gd`.
2. Inspect the source asset:
   - If it is a zip of frames, list entries, count PNG frames, and verify frame dimensions.
   - If it is a combined sheet, verify width, height, grid, and blank cells.
3. Convert the source into the normalized sheet format instead of compensating with script scale when the user asks for asset-size consistency.
4. Preserve the source background and alpha unless the user explicitly asks to matte, key, or make transparent.
   - The prototype already uses `KEY_MODE_GREEN` for green-key display.
5. Update code only for real animation metadata changes:
   - `end=48` for 49-frame sheets.
   - `rows=7` for normalized `3584x3584` sheets.
   - Keep `scale=0.46` for `512x512` cruise idle cells unless visual review suggests otherwise.
6. Validate by reading image dimensions and running the prototype scene headlessly.

## PowerShell Checks

Check a PNG sheet:

```powershell
Add-Type -AssemblyName System.Drawing
$p = 'E:\SwordCultivator\resources\flight\yujian_cruise_idle.png'
$img = [System.Drawing.Image]::FromFile($p)
Write-Output "$p`t$($img.Width)x$($img.Height)`tFrame7x7=$([int]($img.Width/7))x$([int]($img.Height/7))"
$img.Dispose()
```

List and inspect zip frames:

```powershell
$zip = 'C:\Users\Han_112\Downloads\matted_frames (2).zip'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing
$archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
$entries = $archive.Entries | Where-Object { $_.FullName -match '\.png$' } | Sort-Object FullName
Write-Output "count=$($entries.Count)"
$stream = $entries[0].Open()
$img = [System.Drawing.Image]::FromStream($stream)
Write-Output "first=$($img.Width)x$($img.Height) $($img.PixelFormat)"
$img.Dispose()
$stream.Dispose()
$archive.Dispose()
```

## Stitching Zip Frames

For 49 separate `960x960` frames, stitch into `3584x3584` / `7x7`:

```powershell
$zip = 'C:\Users\Han_112\Downloads\matted_frames (2).zip'
$dst = 'E:\SwordCultivator\resources\flight\yujian_cruise_idle.png'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing
$archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
$entries = $archive.Entries | Where-Object { $_.FullName -match '\.png$' } | Sort-Object FullName
if ($entries.Count -ne 49) { throw "Expected 49 PNG frames, got $($entries.Count)" }
$cell = 512
$canvas = [System.Drawing.Bitmap]::new($cell * 7, $cell * 7, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
$graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
for ($i = 0; $i -lt $entries.Count; $i++) {
    $stream = $entries[$i].Open()
    $frame = [System.Drawing.Bitmap]::FromStream($stream)
    $dstRect = [System.Drawing.Rectangle]::new(($i % 7) * $cell, [int]([Math]::Floor($i / 7)) * $cell, $cell, $cell)
    $srcRect = [System.Drawing.Rectangle]::new(0, 0, $frame.Width, $frame.Height)
    $graphics.DrawImage($frame, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $frame.Dispose()
    $stream.Dispose()
}
$graphics.Dispose()
$archive.Dispose()
$canvas.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
```

## Validation

After changing assets or script metadata, run:

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs '--quit-after','2','res://scenes/prototypes/YujianSpriteSequencePrototype.tscn'
.\tools\show_godot_errors.ps1 -Tail 120
```

Report only validations actually run.
