# Yujian 8-Way Cruise Imagegen Production Contract

## Project Paths

- Output root: `G:/SwordCultivator/resources/flight/yujian_8way_cruise_generated_v1/`
- Accepted root: `G:/SwordCultivator/resources/flight/yujian_8way_cruise_generated_v1/accepted/`
- Master character: `G:/SwordCultivator/resources/flight/Gemini_Generated_Image_193qyk193qyk193q.png`
- 3D direction references: `G:/SwordCultivator/docs/mockups/nanzhujue_8way_reference_from_model/`
- Unified prompt doc: `G:/SwordCultivator/resources/flight/yujian_8way_cruise_generated_v1/accepted/prompts_diagonals.md`

## Current Inventory

Accepted images:

- `accepted/01_right.png`
- `accepted/03_up.png`
- `accepted/07_down.png`
- `accepted/02_up_right.png`
- `accepted/05_left.png`
- `accepted/08_down_right.png`

Useful candidates:

- `04_up_left_candidate_v1.png`
- `06_down_left_candidate_v1.png`

Prompt docs:

- `accepted/prompts_up_down.md`: original accepted UP/DOWN prompts.
- `accepted/prompts_diagonals.md`: unified direction prompt doc, currently includes all 8 direction prompt sections.

## Direction Contract

| Direction | Visual read | Camera and pose requirement |
|---|---|---|
| `01 RIGHT` | face/body toward screen-right | midpoint between `02_up_right` and `08_down_right`; side-right yujian cruise, hair and robe trail left |
| `02 UP_RIGHT` | diagonal away to upper-right | high top-down 3/4 back-right; face mostly hidden; hair and robe trail lower-left |
| `03 UP` | away from camera, screen-up | high top-down back view; compact foreshortened torso; vertical centerline lock |
| `04 UP_LEFT` | diagonal away to upper-left | high top-down 3/4 back-left; not mirrored from right; hair and robe trail lower-right |
| `05 LEFT` | face/body toward screen-left | midpoint between `04_up_left` and `06_down_left`; side-left yujian cruise, hair and robe trail right |
| `06 DOWN_LEFT` | diagonal toward camera lower-left | high top-down 3/4 front-left; chest/front planes visible from above |
| `07 DOWN` | toward camera, screen-down | high-angle front view; chest and head top visible; hair and robe trail upward |
| `08 DOWN_RIGHT` | diagonal toward camera lower-right | high top-down 3/4 front-right; chest/front planes visible from above |

## Prompt Skeleton

Use the exact accepted prompt section when available. When drafting a new variant, keep this skeleton:

```text
Create exactly one raster image: a single full-body 2D game character sprite, direction <NN NAME>. No text, no labels, no UI, no diagram, no infographic, no multiple panels.

Use the previously shown master character as strict identity: black ink wuxia male, dark faceless face, black-gray robe, wide sleeves, sash, layered robe panels, boots, top bun, very long flowing black hair. Preserve costume, silhouette, ink-wash style, grayscale palette, hair direction details, and asymmetrical character design.

Use the previously shown <direction> camera reference only for direction and orientation. Use the accepted adjacent cruise sprites as the posture family. The result must feel like a yujian cruise sprite, not a separate standing illustration.

View: fixed orthographic 2.5D game sprite camera, <direction-specific view>.

Direction lock: flight direction exactly <screen direction>. The invisible flying sword axis, head, torso, hips, robe flow, and feet align along <axis>.

Pose: yujian cruise pose, standing on an invisible narrow flying sword, but do not draw the sword. Feet staggered front-back along the flight axis, knees slightly bent, lowered center of gravity, torso leaning subtly into the flight direction. Arms asymmetrical for balance: one hand low forward pressing air, the other pulled slightly back near body. Not A-pose, not T-pose, not idle, not walking, not running, not posing.

Motion: hair, sleeves, robe hems, ribbons stream backward opposite the travel direction.

Neutral gray background, centered, full body visible, game sprite asset. No sword, no weapon, no platform, no VFX, no trail, no text, no watermark.
```

## Lessons Learned

- 八向角色不能用单张图绕航向旋转；朝左时会倒立或倒飞。
- “人物始终朝右，剑旋转”也错；移动方向、剑尖/飞剑轴、人物面向必须一致。
- 正确方案是 8 个 body pose：上背向、下正面、左右侧向、斜向 3/4。
- 生图时“视角正确”和“姿势正确”要分开判断。`03 UP` 曾经视角对但姿势像滑翔，后来用站在隐形飞剑上的低重心描述修正。
- 通过稿要保存到 `accepted/`，未确认图保持候选名。
