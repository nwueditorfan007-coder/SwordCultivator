# 剑阵连续阵型框架设计

## 1. 文档定位

本文档用于定义剑阵系统后续可持续扩展的统一框架。

目标不是只解决当前 `ring -> fan -> pierce` 的跳变问题，而是为未来以下需求提供稳定骨架：

- 近 / 中 / 远距离可使用不同图形
- 不同图形之间可以连续演化，而不是硬切
- 预览、待发站位、发射目标、视觉反馈共享同一套几何语言
- 后续新增剑阵系统时，以“扩展”代替“推倒重写”

本文档是对现有 V1 / V2 文档的补充，不替代其战术语义定义。


## 2. 核心结论

后续剑阵系统不应继续围绕“固定三形态 + 每段单独特判”扩展。

更合适的方向是：

1. 保留 `ring / fan / pierce` 这类主导战术语义
2. 将几何系统升级为“连续阵型框架”
3. 用统一接口描述“阵型家族”“阵型预设”“预设之间的连续形变”
4. 让预览、站位、发射、特效都消费同一份几何结果

换句话说：

- `dominant_mode` 负责回答“当前战术偏向是什么”
- `formation_family` 负责回答“当前图形用哪种几何语言表达”


## 3. 为什么需要这个框架

当前系统的主要风险不是参数不够细，而是结构上容易出现以下问题：

- 边界处切换不同几何家族，导致画面跳变
- 预览、站位、发射目标来自不同求解链，导致读感不一致
- 新增一个阵型时，需要改多个分支函数和多个渲染分支
- 中间态越来越依赖补丁式混合，维护成本持续上升

如果未来不仅有 `ring / fan / pierce`，还会有更多近中远图形，并要求它们继续连续形变，那么系统必须从“模式逻辑”转向“连续几何逻辑”。


## 4. 设计原则

### 4.1 几何连续，语义稳定

几何层追求连续变化。

玩法层仍然允许保留离散语义，例如：

- 近距离偏护体
- 中距离偏压制
- 远距离偏贯穿

因此：

- 图形可以连续
- 节奏、批次、覆盖权重、命中规则仍可按 `dominant_mode` 决定

### 4.2 同一份几何驱动全部表现

以下内容必须尽量共用同一份几何结果：

- 预览轮廓
- 吸附剑丸站位
- 发射起点
- 发射目标点
- 局部引导方向
- 主要特效锚点

### 4.3 家族可扩展，预设可替换

系统不应该把 `band` 写死成唯一真理。

应该允许未来扩展多个 `formation_family`，例如：

- `band`
- `fork`
- `cross`
- `cluster`

当前版本只需要先把 `band` 家族做好，但数据结构必须允许后续增加其他家族。

### 4.4 连续演化必须基于可对应的采样语义

如果两个图形要做连续形变，它们必须共享一套可对应的采样点语义。

例如：

- 同一条中轴 `spine`
- 同数量的 section
- 同顺序的左右轮廓点
- 同意义的前缘 / 后缘控制点

否则所谓“连续形变”最后还是会退化成视觉切换。


## 5. 推荐的系统分层

### 5.1 语义层

负责战术意义，不负责几何细节。

建议保留：

- `dominant_mode`
- `release_profile`
- `coverage_profile`
- `damage_profile`
- `fx_profile`

它回答的问题是：

- 当前更偏环阵、扇阵还是贯穿阵
- 当前发射节奏和批次是什么
- 当前覆盖权重更偏外扩还是中轴

### 5.2 几何层

负责连续阵型求解。

建议新增统一概念：

- `formation_family`
- `shape_preset`
- `morph_profile`
- `geometry_result`

它回答的问题是：

- 当前图形属于哪类几何家族
- 在该家族中当前接近哪种预设
- 当前从哪个预设向哪个预设演化
- 当前轮廓、站位、目标点具体在哪里

### 5.3 渲染层

只消费 `geometry_result`，不再自行判断模式切换。

渲染层职责应限制为：

- 绘制轮廓
- 绘制填充
- 绘制中轴/尖端强调
- 绘制调试信息

### 5.4 发射层

发射层不直接理解复杂阵图，只从 `geometry_result` 读取：

- 槽位位置
- 发射源锚点
- 目标采样点
- 局部法向 / 中轴方向


## 6. 关键数据结构

## 6.1 MorphState

建议保留并扩展现有 `morph_state`：

```gdscript
{
    "dominant_mode": "fan",
    "visual_from_mode": "fan",
    "visual_to_mode": "pierce",
    "visual_blend": 0.32,
    "distance_ratio": 0.41,

    "formation_family": "band",
    "preset_from": "fan_wide_band",
    "preset_to": "pierce_narrow_band",
    "preset_blend": 0.32
}
```

说明：

- `dominant_mode` 服务玩法层
- `formation_family / preset_*` 服务几何层

## 6.2 ShapePreset

`ShapePreset` 表示某个家族下的一个稳定图形。

以 `band` 家族为例：

```gdscript
{
    "id": "fan_wide_band",
    "family": "band",
    "section_count": 8,
    "arc": 1.75,
    "center_offset": 18.0,
    "forward_length": 142.0,
    "band_thickness": 88.0,
    "front_taper": 0.08,
    "rear_taper": 0.0,
    "tip_emphasis": 0.0,
    "spine_emphasis": 0.2
}
```

这些参数不是渲染结果，而是几何求解参数。

## 6.3 MorphProfile

定义两个预设之间如何连续形变。

```gdscript
{
    "from": "fan_wide_band",
    "to": "pierce_narrow_band",
    "curve": "smoothstep",
    "blend_windows": {
        "arc": [0.0, 1.0],
        "center_offset": [0.1, 0.9],
        "band_thickness": [0.2, 1.0],
        "tip_emphasis": [0.72, 1.0]
    }
}
```

意义：

- 不同参数不一定同步变化
- 可以显式控制“先缩弧角，再收带宽，最后强调尖端”

## 6.4 GeometryResult

最终对外只暴露一种统一结果：

```gdscript
{
    "family": "band",
    "sections": [...],
    "left_outline": [...],
    "right_outline": [...],
    "spine_points": [...],
    "slot_points": [...],
    "launch_anchors": [...],
    "target_samples": [...],
    "tail": Vector2,
    "tip": Vector2,
    "outer_cap_control": Vector2,
    "inner_cap_control": Vector2,
    "debug": {...}
}
```

渲染、站位、发射都只认这个结果。


## 7. 推荐的几何表达方式

### 7.1 当前第一家族：Band Family

`band family` 适合表达以下连续演化：

- 闭合环带
- 开口弧带
- 前向扇带
- 窄带
- 近似直线的贯穿带

这一家族建议统一采用：

- 一条主轴 `spine`
- 固定数量的横截面 `sections`
- 左右轮廓点
- 前后封口控制点

在这个框架下：

- 近距离看起来像环带
- 中距离看起来像前向扇带
- 远距离看起来像收束窄带 / 穿刺线

### 7.2 为什么它适合当前项目

因为当前已知主线阵型都可以被描述成：

- 同一团围绕玩家或前推的剑势
- 只是开口度、前移量、厚度、尖锐度不同

这天然适合 band family。

### 7.3 它的边界

以下形状如果未来要做，可能不适合继续硬塞进 band：

- 双翼分叉
- 十字分布
- 多核心团块
- 明显断裂的多段阵图

这些应该作为新的 `formation_family`。


## 8. 如何支持未来“近中远放不同图形”

### 8.1 不再直接绑定“距离 = 模式”

推荐改为：

- 距离决定当前 `preset lane`
- 语义层决定当前 `dominant_mode`
- 形变系统决定当前 `preset_from -> preset_to`

例如：

```text
近距离：closed_guard_band
中距离：wide_pressure_band
远距离：narrow_pierce_band
```

未来也可以是：

```text
近距离：closed_guard_band
中距离：fork_pressure_shape
远距离：narrow_pierce_band
```

只要 family 内部或 family 间存在合法的 morph bridge，就可以连续变化。

### 8.2 近中远只是默认轨道，不是唯一拓扑

也就是说：

- 现在可以先做近中远三段
- 未来可以增加技能把中距离切到别的 preset
- 也可以增加装备改变某一段的阵型家族

只要对外接口保持一致，玩法扩展不会要求重写控制器。


## 9. 推荐接口

建议控制器层最终收敛为以下接口：

```gdscript
get_morph_state(main) -> Dictionary
get_geometry_result(main, state_source, formation_ratio := 1.0) -> Dictionary
get_slot_position(main, state_source, slot_index, slot_count, formation_ratio := 1.0) -> Vector2
get_launch_anchor(main, state_source, bullet_pos, fire_index, volley_count) -> Vector2
get_fire_target(main, state_source, fire_index, bullet_pos, volley_count) -> Vector2
get_release_profile(main, state_source) -> Dictionary
```

要求：

- `get_slot_position / get_launch_anchor / get_fire_target` 都从 `get_geometry_result()` 读取
- 渲染层不得自行复制几何逻辑


## 10. 对当前项目的具体建议

### 10.1 短期

先把当前 `ring -> fan -> pierce` 重构成单一 `band family`。

这一步的收益：

- 修复当前边界跳变的结构根因
- 让预览、站位、发射重新回到同一套几何
- 形成后续扩展的第一版 family 骨架

### 10.2 中期

把当前文档中的 `crescent / diamond` 从“独立图形家族”调整为：

- `band family` 在不同阶段的视觉读感描述
- 而不是独立、长期存在的结构分支

### 10.3 长期

当未来确实需要明显不同拓扑时，再新增新的 `formation_family`：

- 不改发射层接口
- 不改渲染层消费方式
- 只新增新的 family solver 和对应 morph bridge


## 11. 迁移策略

建议分三步迁移，避免一次性重做过大。

### 第一步：统一几何输出

先保留现有 `dominant_mode` 与释放语义，只把以下部分统一到 `geometry_result`：

- preview
- slot position
- launch anchor
- fire target

### 第二步：收束 band family 内部分支

将当前 `crescent / continuous_band / fan_to_pierce / pierce preview` 的多段接力，整理为：

- `band preset solver`
- `band morph profile`
- `band geometry builder`

### 第三步：为未来 family 预留桥接点

新增抽象层：

- `formation_family`
- `preset registry`
- `morph bridge registry`

此时即使未来加新阵型，也不需要推翻第一版 band 管线。


## 12. 验收标准

新框架至少应满足：

1. 在近 / 中 / 远边界附近拖动准星时，不出现明显硬切
2. 预览、待发排布、发射轨迹读取同一套几何结果
3. 后续增加一个新 preset 时，不需要修改多处分支判断
4. 后续增加一个新 family 时，不需要重写发射层和渲染层总接口
5. 当前 `ring / fan / pierce` 的战术辨识度仍然存在


## 13. 最终建议

对当前项目而言，最值得推进的不是继续补某个边界，而是尽快把剑阵系统从“阶段性特判集合”升级成“连续阵型框架”。

当前最合适的落地顺序是：

1. 先用 `band family` 统一现有主线阵型
2. 保留 `dominant_mode` 作为战术语义锚点
3. 用 `preset + morph profile + geometry result` 取代大量边界特判
4. 为未来新增不同图形预留 `formation_family` 扩展口

这样可以同时满足：

- 当前画面连续性
- 当前代码可维护性
- 后续新阵型扩展性

