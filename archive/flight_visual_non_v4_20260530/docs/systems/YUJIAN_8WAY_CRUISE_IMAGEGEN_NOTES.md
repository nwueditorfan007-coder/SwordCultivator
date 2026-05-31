# 御剑八向巡航生图任务总结

## 背景

`Yujian Sprite Sequence Prototype` 已经改成八向飞行操作，但原动画仍像单一巡航循环，无法自然匹配玩家的八向输入。玩家按右、左、上、下或斜向时，角色面向、隐形飞剑轴、衣发拖拽和身体重心必须共同表达同一个航向。

这次任务先从动画表达方案讨论开始，随后落到 AI 生图流程：为御剑巡航制作八个方向的单张角色图和可复用提示词。

动画表现规则、视角定义、素材清单和技术路线详见：

`docs/systems/YUJIAN_8WAY_FLIGHT_ANIMATION_EXPRESSION.md`

## 核心结论

正确规则不是“把一张人物图按航向旋转”，而是：

`移动方向 = 隐形飞剑轴/剑尖方向 = 人物面向`

但人物头部不能因为整图旋转而倒立。八向身体语义应当固定为：

- `03 UP`: 背向画面，向屏幕上方远离镜头，高机位俯视压缩。
- `07 DOWN`: 面向画面，向屏幕下方靠近镜头，高机位俯视。
- `01 RIGHT`: 右侧向，人物面向屏幕右侧，头仍朝画面上方。
- `05 LEFT`: 左侧向，人物面向屏幕左侧，头仍朝画面上方。
- `02/04` 斜上: 3/4 背侧姿态。
- `06/08` 斜下: 3/4 正侧姿态。

从玩家体验看，这样读起来才像“人在控剑、压剑、借风转向”，而不是角色被速度方向拖着翻滚。

## 动态 SVG 讨论沉淀

前面对话里做了多版 SVG 示意，主要踩出了三条设计边界：

- 只让人物整体跟航向旋转会失败：朝左时人会头朝下，读成失控翻滚。
- 让人物永远直立但面向不跟航向走也会失败：会出现往左移动但人物和剑仍朝右的倒飞。
- 正确示意必须用八方向姿态切换：移动方向、人物面向、剑尖方向同向；上方向是背向，下方向是正面，左右是侧向。

制作 SVG 预览时还要做实际可视边界检查。之前出现过 `<symbol>` 被某些渲染器异常放大、人物超出画布的问题，所以后续动作示意尽量用普通 `<g>`、显式尺寸和保守边界。

## 生图流程

本轮使用的主要资源：

- 母版角色：`resources/flight/Gemini_Generated_Image_193qyk193qyk193q.png`
- 3D 八向参考：`docs/mockups/nanzhujue_8way_reference_from_model/`
- 输出目录：`resources/flight/yujian_8way_cruise_generated_v1/`
- 通过稿目录：`resources/flight/yujian_8way_cruise_generated_v1/accepted/`
- 统一提示词：`resources/flight/yujian_8way_cruise_generated_v1/accepted/prompts_diagonals.md`

工作方式：

1. 先用母版锁定身份、服装、发型、黑白水墨风。
2. 用 3D 方向参考锁定方向和大机位。
3. 用已通过相邻方向图锁定姿势族。
4. 每张图先保存为候选，不覆盖旧图。
5. 用户明确确认后再复制进 `accepted/`。
6. 提示词随通过稿同步保存，避免下一轮从聊天记忆重建。

## 当前产物

已通过并保存到 `accepted/`：

- `accepted/01_right.png`: 右向，侧向御剑巡航姿势。
- `accepted/03_up.png`: 高机位俯视背向，上方向。
- `accepted/07_down.png`: 高机位俯视正面，下方向。
- `accepted/02_up_right.png`: 右上，3/4 背侧。
- `accepted/05_left.png`: 左向，侧向御剑巡航姿势。
- `accepted/08_down_right.png`: 右下，3/4 正侧。

已生成但尚未转入 `accepted/` 的候选：

- `04_up_left_candidate_v1.png`: 左上候选。
- `06_down_left_candidate_v1.png`: 左下候选。

提示词文件：

- `accepted/prompts_up_down.md`: 上下方向原始通过提示词。
- `accepted/prompts_diagonals.md`: 已扩展为八方向统一提示词文档，包含 `01 RIGHT`、`03 UP`、`05 LEFT`、`07 DOWN`、四个斜向。

## 关键提示词经验

`03 UP` 的主要难点是方向轴和机位分离：

- 如果只说上方向，AI 容易画成右上。
- 如果只说背向，AI 容易画成长背影立绘。
- 有效修正是同时锁定“screen-up vertical centerline”和“top-down game sprite camera”，并要求头顶、发髻、肩背顶面可见，腿脚短小压缩。

左右方向的主要难点是姿势族：

- 普通侧面参考会把图带回站姿或立绘。
- 有效修正是把右向描述成 `02 UP_RIGHT` 和 `08 DOWN_RIGHT` 的中间方向，把左向描述成 `04 UP_LEFT` 和 `06 DOWN_LEFT` 的中间方向。
- 提示词开头必须先排除信息图、多面板、文字和 UI，否则生图工具可能跑偏。

## 验收标准

候选图是否通过，不先看“画得漂亮不漂亮”，先看玩家能否读对动作：

- 方向轴一眼读对。
- 人物面向、飞行方向、隐形飞剑轴一致。
- 上方向背向，下方向正面，左右侧向，斜向 3/4。
- 姿势像站在隐形飞剑上控平衡，不是滑翔、奔跑、悬浮或普通站姿。
- 衣发、袖摆、袍摆向速度反方向拖。
- 不出现飞剑、武器、平台、特效、文字、水印。
- 同一套角色身份和水墨服装语言不漂移。

## 后续建议

下一步可以把用户确认可用的 `04_up_left_candidate_v1.png`、`06_down_left_candidate_v1.png` 按需复制进 `accepted/`，再用统一提示词文档回填 accepted outputs。之后再进入 sprite sheet 或序列帧阶段时，使用 `yujian-sprite-sequence-assets` 负责图集规格和 Godot 验证。
