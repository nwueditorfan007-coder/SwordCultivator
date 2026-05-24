# FrameRonin Pixel Asset Pipeline for Sword Flight

## Purpose

This document records how to use FrameRonin pixel generation and processing for the current `御剑航行` prototype.

Design read: the current flight mode already has a solid control fantasy: side-scrolling sword travel, readable sword actions, and a playable cloud-lane combat loop. The weak point is not combat structure. It is that the rider and scenery still read like prototype art, so the player feels "a debug sword-flight test with nice VFX" before they feel "a cultivator crossing a dangerous cloud sea".

The correct iteration is therefore asset-facing and low impact: improve rider silhouette, parallax, and pixel consistency while preserving current sword control, enemy readability, and array-form roles.

## What FrameRonin Is Good For

FrameRonin can generate pixel characters and pixel scenes, then continue into cleanup and Sprite Sheet processing. Treat it as an end-to-end browser toolchain, not just as a video/frame utility. The relevant modules are:

- `nanobanana` pixel character presets: character sheets based on Gemini/Nano Banana image models.
- `nanobanana预设像素角色生成器 V2-V3`: generated character motion presets such as movement, downed, and attack.
- `nanob全人物动作生成测试`: includes horizontal character generation, 8-direction top-down generation, riding actions, and one-image/all-actions presets.
- Horizontal character and "all actions in one image" presets: useful for this project.
- Pixel scene generation: includes front view, 45-degree, Terra-like, and arcade/side-scrolling scene prompts.
- Image processing: pixel conversion, hard nearest-neighbor scaling, inner stroke, crop, matte, watermark cleanup, and transparent padding.
- Video to frames: extract frames by time range and FPS, crop, matte, outline, then export PNG, ZIP, or Sprite Sheet.
- Sprite Sheet tools: split by rows/columns, preview as GIF, reorder frames, recombine, shift frames by pixels, fix one pixel color across frames, remove duplicate frames, and interpolate in-between frames.

Important caveat: non-API AI preset generation depends on access to Google/Gemini. If direct generation is inconvenient, use FrameRonin for processing, cleanup, sheet adjustment, and export after generating the source image elsewhere.

Sources studied:

- [FrameRonin](https://frameronin.com/)
- [FrameRonin GitHub](https://github.com/systemchester/FrameRonin)

## Use These Modules

### Rider

Use these:

- `横版人物生成`
- `一图全动作`
- `一图全动作2`
- `Sprite Sheet 调整`
- `一键处理、精细处理`

Avoid these for the flight rider:

- `RPGMaker角色生成`: wrong perspective and grid semantics.
- `八方向 TopDown`: useful for a top-down player, not this side flight view.
- Generic monster presets: useful later for small enemies, not for the rider.

### Background

Use the arcade/side-scrolling pixel scene route for the flight background. The front-view and 45-degree scene routes are better for top-down maps, not a horizontal cloud lane.

Generate or process separate layers:

- far mountain silhouette
- mid mountain silhouette
- cloud bank
- wind veil

Do not generate a single complete painting and drop it under combat. A single merged scene fights the sword VFX and removes the parallax advantage.

## Current Project Intake Spec

The current scene reads the following background files directly:

- `res://resources/flight/background/flight_mountain_far.png` at `1024 x 150`
- `res://resources/flight/background/flight_mountain_mid.png` at `1024 x 172`
- `res://resources/flight/background/flight_cloud_bank.png` at `1024 x 190`
- `res://resources/flight/background/flight_wind_veil.png` at `640 x 112`

The current rider runtime sheets are:

- main body: `res://resources/flight/rider/flight_rider_body_v10_sheet.png`
- body transitions: `res://resources/flight/rider/flight_rider_body_v10_transitions.png`
- legacy fallback: `res://resources/flight/rider/flight_rider_body_v9_sheet.png`
- main size: `2048 x 2816`, `8 columns x 11 rows`
- transition size: `2048 x 3584`, `8 columns x 14 rows`
- cell: `256 x 256`
- transparent background required
- body only: no handheld sword, flying mount platform, complete sword array, long wind trail, or large VFX

V10 main rows are fixed:

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

V10 transition rows are fixed:

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

`FlightRiderSpriteFx` exposes the main body sheet, transition sheet, cell size, frame count, and pixel filter in the inspector. Future FrameRonin outputs can be tested without code changes if they keep this row order and `256 x 256` body cells.

The old V9 prompt package remains useful as source material. V10 reinterprets `unsheath` as the sustained `sword_control_idle`, splits `array_morph` into three sustained array idles plus directed transitions, and treats `array_release` as a short pulse that returns to the current array idle.

## Rider Prompt

Use this as the base prompt in FrameRonin's horizontal character or all-actions preset:

```text
生成一张中国修仙题材横版御剑角色像素 Sprite Sheet，透明背景。

角色：年轻剑修，深青黑长袍，古金腰带和袖口，冷白青蓝剑气披帛，身形清瘦但剪影清楚。整体像素风，硬边缘，低色数，适合 2D 横版动作游戏，不要写实厚涂，不要 RPGMaker 俯视角，不要大头 Q 版。

输出规格：单行动作条时使用 8 列 x 1 行，每格 256 x 256 像素，总图 2048 x 256 像素。每一格角色站在同一锚点，脚底/御剑站位锚点固定在 x=128, y=219 附近，误差不超过 2px。人物不要出格。

动作语义：
- sword_control_idle：右键御剑持续控剑状态，不是一次性出鞘
- array_ring_idle / array_fan_idle / array_pierce_idle：三种剑阵持续待机状态
- array_ring_release / array_fan_release / array_pierce_release：对应阵型释放脉冲，播放完回到对应阵型待机
- array_*_to_*：阵型变化过渡，只在 dominant mode 改变时播放

画面规则：这是 body only 人物表，不画手持剑、不画御剑平台、不画完整剑阵、不画长拖尾。人物本体压暗但轮廓清楚，袖袍、披帛和手势负责读动作。禁止文字、水印、阴影地面、复杂背景、过度发光、现代科幻装备。
```

After generation or recombination, run this cleanup pass:

1. Remove visible watermark if needed.
2. Matte by top-left background color or alpha.
3. Hard scale with nearest-neighbor only if dimensions differ.
4. Use Sprite Sheet adjustment to check `8 x 7`.
5. Recombine, export PNG, then test as `flight_rider_body_v10_sheet.png` or `flight_rider_body_v10_transitions.png`.
6. Validate with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_flight_rider_body_assets.ps1 -MainSheet resources/flight/rider/flight_rider_body_v10_sheet.png -TransitionSheet resources/flight/rider/flight_rider_body_v10_transitions.png`.

For the full V9 action and transition prompt package, use `AI/御剑人物Body序列帧任务包_V9.md`.

## Background Prompts

Generate each layer separately. Keep the palette below the sword brightness.

### Far Mountain

```text
横版 2D 像素游戏远景山脉透明 PNG，中国修仙云海航行背景。深蓝黑山脊，极少冷青描边，低亮度，长条横向构图，无人物，无建筑，无文字，无月亮。尺寸 1024 x 150，左右可循环，透明背景。
```

### Mid Mountain

```text
横版 2D 像素游戏中景山脉透明 PNG，中国修仙云海航行背景。山形比远景更高，深青黑块面，少量冷白山脊线，低对比，不抢主角。尺寸 1024 x 172，左右可循环，透明背景，无人物，无文字。
```

### Cloud Bank

```text
横版像素云海长条透明 PNG，适合 2D 御剑飞行关卡。云层轻、薄、可循环，冷白、浅青、少量古金暖光，底部留透明，不能像厚棉花，不能遮挡战斗主体。尺寸 1024 x 190。
```

### Wind Veil

```text
横版像素风速线和风幕透明 PNG，长条可循环。冷白青蓝为主，少量古金细线，线条纤长、断续、方向一致，用于表现高速御剑航行。尺寸 640 x 112，无背景，无文字。
```

## Acceptance Checklist

- At `1x` and `2x` zoom, the rider reads as a sword cultivator before it reads as a generic cloak.
- Each row has a different silhouette, not only different sword glow.
- The sword hand/socket stays plausible enough for `get_hand_hilt_pose`.
- Background layers remain darker than the player sword and enemy warning colors.
- Clouds do not sit directly behind the player head for most of the scroll cycle.
- The wind veil adds speed but never masks bullets, silk, or sword-array previews.
- No merged full-scene background should replace the four-layer setup unless it is split afterward.

## Next Playtest Question

After the first generated asset pass, test one thing first: does the flight mode feel more like "crossing a living cloud sea" without making bullets, silk, and array intent harder to read?

If readability drops, reduce background alpha and cloud density before changing combat colors.
