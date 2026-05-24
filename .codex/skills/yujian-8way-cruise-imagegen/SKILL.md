---
name: yujian-8way-cruise-imagegen
description: Use when generating, regenerating, judging, accepting, or documenting SwordCultivator Yujian 8-way cruise direction stills, especially resources/flight/yujian_8way_cruise_generated_v1, accepted direction prompts, and 2.5D high-angle wuxia sword-riding character images. Covers prompt reuse, reference loading, candidate naming, acceptance checks, and known failure modes for UP, DOWN, LEFT, RIGHT, and diagonal Yujian cruise poses.
---

# Yujian 8-Way Cruise Imagegen

默认用中文回答。这个技能服务于《SwordCultivator》的御剑八向巡航角色生图，不负责把成图接成运行时序列帧；序列帧替换和 Godot 校验仍用 `yujian-sprite-sequence-assets`。

## Scope

Use for:

- 生成或重生 `resources/flight/yujian_8way_cruise_generated_v1/` 下的八方向单张角色图。
- 补充或修订 `accepted/prompts_diagonals.md`、`accepted/prompts_up_down.md`。
- 判断候选图是否可以进入 `accepted/`。
- 复盘方向语义、视角、姿势族是否统一。

Read `references/production_contract.md` when you need the direction table, current asset inventory, or detailed failure modes.

## Core Rule

八向御剑巡航的玩家读法必须锁定：

`移动方向 = 隐形飞剑轴/剑尖方向 = 人物面向`

但人物本体不能整张旋转 360 度。方向语义是：

- `03 UP`: 背向/远离镜头，高机位俯视，身体压缩。
- `07 DOWN`: 正面/靠近镜头，高机位俯视，胸口和头顶可见。
- `01 RIGHT` / `05 LEFT`: 侧向飞行，头仍在画面上方，不倒立，不倒飞。
- 斜向: 对应 3/4 背侧或 3/4 正侧，不靠镜像偷懒。

美术气质是“站在隐形飞剑上控平衡”，不是滑翔、奔跑、普通立绘或 A/T-pose。

## Generation Workflow

1. 先读当前提示词文件：
   - `resources/flight/yujian_8way_cruise_generated_v1/accepted/prompts_diagonals.md`
   - 必要时读 `accepted/prompts_up_down.md`
2. 用 `view_image` 放入上下文：
   - 母版：`resources/flight/Gemini_Generated_Image_193qyk193qyk193q.png`
   - 当前方向 3D 参考：`docs/mockups/nanzhujue_8way_reference_from_model/<direction>.png`
   - 已通过的相邻方向图，例如右向要看 `02_up_right.png` 和 `08_down_right.png`
3. 用内置 `image_gen` 生成。提示词开头要硬锁：
   - `Create exactly one raster image`
   - `single full-body 2D game character sprite`
   - `No text, no labels, no UI, no diagram, no infographic, no multiple panels`
4. 生成后从 `$CODEX_HOME/generated_images/...` 复制到项目目录，候选命名用：
   - `<direction>_candidate_vN.png`
   - 不要覆盖旧候选。
5. 用 `view_image` 检查候选，不要只看文件是否存在。
6. 只有用户明确确认后，才复制到：
   - `resources/flight/yujian_8way_cruise_generated_v1/accepted/<direction>.png`
   - 同步更新 accepted prompt 文档和 accepted outputs 列表。

## Acceptance Checks

候选图至少满足：

- 方向一眼能读对，没有 UP 偏成 UP_RIGHT、LEFT 偏成 LOWER_LEFT。
- 机位匹配方向：上/下和斜向要有 2.5D 高机位压缩，左右可略低但仍是游戏 sprite。
- 姿势族统一：低重心、脚沿隐形飞剑轴错开、手臂不展开成滑翔。
- 衣发、袖摆、袍摆朝速度反方向拖拽。
- 不画飞剑、武器、平台、特效、文字、水印。
- 左右独立生成，不直接镜像；如果镜像会破坏发型、衣服左右关系，要重生。

## Known Fixes

- `03 UP` 容易跑成右上：加入“vertical screen-up, centerline, no 3/4 right-back view, no yaw toward the right”。
- `03 UP` 容易变成长背影立绘：强调“top-down game sprite, crown/head bun from above, foreshortened compact torso, very short legs”。
- 左右方向容易变普通侧身站姿：要求它是相邻斜向巡航姿势的中间方向。
- 生图工具偶尔跑成信息图：把“single raster character, no text, no infographic, no multiple panels”放在最前面。
- 漂亮但姿势错误的图要判废；本任务优先级是方向语义和姿势可读性高于插画完整度。
