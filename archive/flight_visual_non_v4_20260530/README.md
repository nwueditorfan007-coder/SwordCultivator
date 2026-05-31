# 御剑飞行非 V4 表现方案归档

- 归档日期：`2026-05-30`
- 处理方式：移动到归档目录，不删除
- 当前主线：V4 程序骨骼小人 + V4 像素化 3D 场景表现原型

## 当前保留在主线的入口

- `scenes/prototypes/YujianSpriteSequencePrototype.tscn`
- `scripts/prototypes/yujian_sprite_sequence_prototype.gd`
- `scripts/prototypes/humanoid_8way_skeleton_visual.gd`
- `scenes/prototypes/YujianV4Pixel3DViewPrototype.tscn`
- `scripts/prototypes/yujian_v4_pixel_3d_view_prototype.gd`
- `resources/flight/yujian_8way_cruise_generated_v1/prototype_v4_skeleton_pose_overrides.json`
- `resources/flight/yujian_8way_cruise_generated_v1/prototype_v4_skeleton_pose_refs/`

## 本目录归档的内容

这里保留的是已经探索过、但暂时不作为主线继续推进的方案：

- V1/V2/V3 四向或两向静帧候选
- V5 水墨部件、V6/V7 Google parts 分支
- 3D 模型转 2D 飞行表现分支
- 早期独立御剑、侧视转身、堆叠 sprite、vector bone rig 等原型
- 八向生图候选、提示词、accepted 图、sequence/video candidates
- 对应的截图、捕获脚本、构建脚本和说明文档
- 归档前的多版本调参 JSON：`resources/flight/yujian_8way_cruise_generated_v1/prototype_runtime_adjustments_with_non_v4_sets.json`

这些文件保留原项目相对路径，例如旧的 `scenes/prototypes/YujianSpriteSequenceV5Prototype.tscn` 现在位于：

`archive/flight_visual_non_v4_20260530/scenes/prototypes/YujianSpriteSequenceV5Prototype.tscn`

## 使用规则

后续如果需要查询废弃方案，先从本目录找，不要重新做同一类试验。

如果某个归档方案要重新启用，先把它作为一个明确的新实验分支恢复出来，再更新主线文档；不要直接从归档目录接回运行时引用。
