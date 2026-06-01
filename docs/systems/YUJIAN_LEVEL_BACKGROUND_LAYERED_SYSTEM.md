# 御剑关卡背景分层系统落地方案

## 目标

这套系统解决的是御剑飞行关卡的背景和地图表现问题，不直接负责敌人、碰撞和事件。

玩家应该感觉自己在一个可信的大空间中飞行：远处地平线稳定，中景岛群有中等位移，近景大岛和礁石会在玩家向上飞时从画面下方退场。背景不能再像横向贴图铺满，也不能让岛屿因为视差逻辑飘到天上。

当前第一关已经按这套规则落到：

- 渲染脚本：`res://scripts/prototypes/yujian_sprite_sequence_prototype.gd`
- 场景：`res://scenes/prototypes/YujianSpriteSequencePrototype.tscn`
- 第一关背景 profile：`res://resources/flight/background/level_01_immortal_sea_background.json`
- 截图验证脚本：`res://tools/capture_yujian_sprite_sequence_prototype.gd`

## 核心判断

关卡背景不能再用单个 `depth` 同时承担四件事：

- 离玩家远近
- 相机移动幅度
- 屏幕纵向摆放
- 岛屿自身的形体透视

这样会产生一个典型错误：地平线附近的远岛逻辑上很远，位移幅度正确，但表现上被推到天空区域，看起来像浮在天上。

当前采用三层字段拆分：

| 字段 | 作用 | 示例 |
| --- | --- | --- |
| `layer` | 逻辑层，决定随镜头移动的视差幅度 | `far`, `mid`, `near` |
| `band` | 表现带，决定物件位于地平线下哪个区域 | `horizon`, `mid_sea`, `foreground` |
| `depth` | 绘制深度，决定缩放、压扁、空气透视、顶面可见度 | `0.18` 到 `0.92` |

例如一个很远但仍然在海上的岛：

```json
{
  "layer": "far",
  "band": "horizon",
  "depth": 0.24
}
```

一个近景大岛：

```json
{
  "layer": "near",
  "band": "foreground",
  "depth": 0.88
}
```

## 投影规则

背景物件的屏幕位置由三部分组成：

```gdscript
screen_y = horizon_y
  + band_offset
  + (object_world_y - camera_y) * layer_parallax_y
```

其中：

- `horizon_y` 是地平线，第一关有极小的纵向响应，避免死板贴屏。
- `band_offset` 只负责把物件放到地平线以下的海面区域。
- `layer_parallax_y` 只由 `layer` 决定，让近景随 Y 轴飞行明显退场。
- `depth` 不直接决定屏幕摆放，只影响大小、空气透视和岛屿顶面压缩。

X 方向类似：

```gdscript
screen_x = screen_center_x + (object_world_x - camera_x) * layer_parallax_x
```

这样可以做到：远岛在地平线附近，物理归属仍是海面；近景岛有大体量，但玩家向上飞时会从下方离开镜头。

## 第一关 Profile

第一关 profile 是 `level_01_immortal_sea_background.json`。它目前有三块：

```json
{
  "settings": {},
  "far_island_bands": [],
  "scenic_islands": []
}
```

`settings` 控制关卡整体气质：

- `sky_top_color`, `sky_mid_color`, `sky_bottom_color`
- `horizon_ratio`, `horizon_y_response`
- `sea_base_color`, `sea_base_alpha`
- `far_strength`, `mid_strength`, `near_strength`
- `island_color_strength`, `vertical_exit_strength`

`far_island_bands` 是低信息远景岛带，只贴近地平线，允许弱循环。它们没有强记忆点，负责尺度和空间，不负责“具体经过某个岛”。

`scenic_islands` 是有形状记忆的岛屿、礁石和地标。它们必须作为世界锚点出现，不能横向铺满。每个条目至少需要：

```json
{
  "x": 13300.0,
  "y": 80.0,
  "layer": "near",
  "band": "foreground",
  "depth": 0.70,
  "width": 560.0,
  "length": 0.165,
  "height": 58.0,
  "kind": 1,
  "landmark": 0
}
```

字段说明：

| 字段 | 含义 |
| --- | --- |
| `x`, `y` | 世界锚点。`y` 是相对玩家起点的偏移 |
| `layer` | 远中近逻辑层，影响相机视差 |
| `band` | 屏幕表现带，保证物件在海面区域 |
| `depth` | 画法深度，影响体量和空气透视 |
| `width`, `length`, `height` | 岛屿平面宽度、纵深压缩和崖壁高度 |
| `kind` | 程序形体和植被变体 |
| `landmark` | 小地标类型；`-1` 表示无地标 |

## 第一关美术规则

第一关主题是“清亮、开阔、初入仙海”。

- 远景：天空和地平线干净，只有低对比远岛和云雾。
- 中景：少量岛礁提供航路纵深，不横向铺满。
- 近景：大岛只露局部，用来说明高度和速度；向上飞时从画面下方退场。
- 色彩：不用纯水墨，保留清亮海蓝、浅金岸线和少量绿色岛面，避免全场单调灰墨。
- 读性：角色、飞剑、敌弹必须永远比背景更清楚。

## 后续每关怎么编辑

新关卡不要改第一关 profile。复制一份 profile：

```text
res://resources/flight/background/level_02_xxx_background.json
```

然后在关卡场景或原型节点上设置：

```text
关卡背景配置路径 = res://resources/flight/background/level_02_xxx_background.json
```

编辑顺序：

1. 先定 `settings`：天空、海面、地平线和整体强度。
2. 再放 `far_island_bands`：只做低信息远景。
3. 最后放 `scenic_islands`：每屏最多保留少量中近景 set piece。
4. 如果某个岛要参与碰撞、落脚或事件，不要只写进背景 profile；玩法层要另建碰撞/交互对象，并用同一世界锚点对齐视觉。

## 验证标准

每次改 profile 或渲染函数，至少检查：

- 初始静帧：清亮、开阔，岛屿不遮挡角色。
- 向上飞行帧：近景岛从下方退场，中景移动适中，远景仍贴近地平线。
- Boost 帧：速度线和水纹提供速度感，但不出现横线穿帮、矩形贴片或重复岛链。

推荐命令：

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs @('--quit-after','3','res://scenes/prototypes/YujianSpriteSequencePrototype.tscn')
.\tools\show_godot_errors.ps1 -Tail 260
.\tools\start_godot_with_log.ps1 -Mode run -Wait -ExtraArgs @('--script','res://tools/capture_yujian_sprite_sequence_prototype.gd')
```

截图输出：

```text
artifacts/yujian_sprite_sequence_first_level_static.png
artifacts/yujian_sprite_sequence_first_level_y_up.png
artifacts/yujian_sprite_sequence_first_level_y_high.png
artifacts/yujian_sprite_sequence_first_level_boost.png
```

## 当前边界

这仍然是原型阶段 renderer，先放在 `YujianSpriteSequencePrototype` 里以便快速验证。稳定后可以抽成：

```text
scripts/background/yujian_level_background_renderer.gd
resources/flight/background/*.json
```

抽出去之前，profile 已经是关卡编辑入口；脚本里的渲染函数只应继续承担“怎么画”，不再把具体关卡岛屿布置写死。
