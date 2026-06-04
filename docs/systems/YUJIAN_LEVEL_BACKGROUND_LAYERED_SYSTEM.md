# 御剑关卡背景分层系统落地方案

## 目标

这套系统解决的是御剑飞行关卡的背景和地图表现问题，不直接负责敌人、碰撞和事件。

玩家应该感觉自己在一个可信的大空间中飞行：远处地平线稳定，中景岛群有中等位移，近景大岛和礁石会在玩家向上飞时从画面下方退场。背景不能再像横向贴图铺满，也不能让岛屿因为视差逻辑飘到天上。

当前第一关已经按这套规则落到：

- 渲染脚本：`res://scripts/background/yujian_level_background_renderer.gd`
- 原型宿主：`res://scripts/prototypes/yujian_sprite_sequence_prototype.gd`
- 场景：`res://scenes/prototypes/YujianSpriteSequencePrototype.tscn`
- 第一关背景 profile：`res://resources/flight/background/level_01_immortal_sea_background.json`
- 截图验证脚本：`res://tools/capture_yujian_sprite_sequence_prototype.gd`

2026-06-04 的具体实现、编辑器入口、验证命令和已知边界见：

```text
res://docs/systems/YUJIAN_LEVEL_BACKGROUND_IMPLEMENTATION_2026-06-04.md
```

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
| `band` | 表现带，决定物件位于地平线下哪个区域 | `horizon`, `mid_sea`, `near_sea` |
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
  "band": "near_sea",
  "depth": 0.88
}
```

`foreground_bottom` 不再用于实体岛屿。它只保留为旧 profile 的兼容输入，renderer 内部会按 `near_sea` 处理；需要贴屏幕边缘的速度参照、云缕、边界视觉，应放在屏幕/特效层，不要混进世界岛屿层。

## 投影规则

背景物件的屏幕位置由三部分组成：

```gdscript
screen_y = horizon_y
  + band_offset
  + (object_world_y - flight_y) * sea_anchor_parallax_y
```

其中：

- `horizon_y` 是地平线，只根据角色垂直高度变化，不吃被边界钳制后的相机 Y、look-ahead、速度或 zoom。
- `band_offset` 只负责把物件放到地平线以下的海面区域。
- `sea_anchor_parallax_y` 是所有海面实体岛屿共用的主 Y 投影速度。`far`、`mid`、`near` 不能在这里给不同速度，否则玩家会觉得岛屿不是固定在海面世界里，而是在屏幕上各自漂。
- `object_world_y - flight_y` 使用角色真实飞行位置作为背景纵向参考。角色接近底部边界时，即使相机已经钳制，近景岛仍会按飞行高度从画面下方进出，不会跟着相机死区同向漂移。
- `band_offset` 是固定表现带，不随 `sea_height` 做 `min`/`max` 分段。这样同一层岛屿在恒定 Y 速度下有稳定屏幕步进。
- `depth` 不直接决定屏幕摆放，只影响大小、空气透视和岛屿顶面压缩。
- `layer` 可以影响 X 方向视差、体量修正、透明度和细节密度，但不能影响海面实体岛屿的主 Y 速度。
- 非线性压缩、look-ahead 构图补偿、局部透视修饰不能进入实体岛屿中心锚点。它们可以用于水纹、雾、速度参照或岛屿内部细节，但不能改变主锚点的 Y 轴运动节奏。

X 方向类似：

```gdscript
screen_x = screen_center_x + (object_world_x - camera_x) * layer_parallax_x
```

这样可以做到：远岛在地平线附近，物理归属仍是海面；近景岛有大体量，但玩家向上飞时会从下方离开镜头。

实体岛屿的剔除也必须发生在完整投影之后：

1. 先投影岛屿顶面轮廓。
2. 生成可见边、崖壁下沿、地标 bounds。
3. 用最终 `bounds` 判断是否离屏，并在屏幕边缘做 alpha fade。
4. 地平线不能参与实体岛屿本体的 alpha fade。地平线关系只能通过 profile 摆放、缩放、空气透视、低信息远景岛带和非实体雾层解决。

不要再用岛屿中心点提前剔除。中心点可能已经越过旧阈值，但顶面、崖壁或地标仍在画面内；提前 return 会造成岛屿在屏幕中直接消失。

也不要用 `max(horizon_guard - min_y)` 这类屏幕空间补偿去移动最终轮廓。它会让岛屿先按实体世界速度移动，碰到地平线保护后突然改为跟随地平线速度，玩家看到的就是岛屿 Y 轴不匀速。实体岛屿的几何位置和 alpha 必须保持同一条线性投影链；地平线关系由 profile 摆放、体量缩放、空气透视和非实体雾层解决，不能靠把 scenic island 淡没解决。

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
  "band": "near_sea",
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
| `layer` | 远中近逻辑层，影响 X 视差和表现强度，不影响实体岛屿主 Y 速度 |
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
4. 以玩家处于底部飞行边界的状态检查近景岛：仍可见的实体岛必须在海平线下方，不能靠地平线透明度隐藏。
5. 如果某个岛要参与碰撞、落脚或事件，不要只写进背景 profile；玩法层要另建碰撞/交互对象，并用同一世界锚点对齐视觉。

## 背景摆放编辑器

手工调整第一关岛屿时，优先打开：

```text
res://scenes/tools/YujianBackgroundMapEditor.tscn
```

它会读取并保存：

```text
res://resources/flight/background/level_01_immortal_sea_background.json
```

编辑器左侧复用正式 `YujianLevelBackgroundRenderer`，所以预览结果和游戏里同一套投影一致。右侧可以：

- 切换 `Start`、`Up`、`High`、`Top`、`Bottom` 预览玩家高度。
- 用 `Flight X/Y` 检查不同横向和纵向位置。
- 在岛屿列表选择 `scenic_islands` 条目。
- 在预览里拖动选中岛屿，或用右侧数值精调 `x`、`y`、`depth`、`width`、`length`、`height`。
- 使用 `Add`、`Duplicate`、`Delete` 管理实体岛。
- 使用 `Save` 写回 profile。

左侧黄色线是海平线，黄色框是选中岛，绿色框是正常可见岛，红色框表示可见实体岛已经进入海平线以上区域。红框不是最终解决方案，它只提醒关卡作者需要重新摆放或改层级。

## 代码结构

`YujianSpriteSequencePrototype` 不再直接画第一关背景。它只负责：

- 创建 `YujianLevelBackgroundRenderer`。
- 传入 `VIEW_SIZE`、`PLAY_RECT`、`FLIGHT_START_POS` 和固定背景 zoom。
- 每帧同步 `flight_pos`、`camera_center`、`camera_zoom`、速度与能量状态。

`YujianLevelBackgroundRenderer` 负责：

- 读取关卡 profile。
- 计算稳定海平线。
- 投影远景、中景、近景世界岛屿。
- 按完整投影 bounds 做剔除和屏幕边缘淡出；实体岛屿不做地平线 alpha fade。
- 绘制天空、海面、水纹、速度参照和边界层。

实现边界是：实体背景世界层不使用被钳制的 `camera_center.y` 做纵向参考；屏幕边界、速度线这类特效层可以继续使用相机或屏幕坐标。

更具体地说，背景 renderer 内部有三类坐标责任：

| 输入 | 用途 |
| --- | --- |
| `flight_pos.y` | 海平线、实体岛屿纵向世界位移 |
| `camera_center.x` | 横向取景和横向视差 |
| `camera_center.y` | 只用于屏幕边界、调试网格等相机层；不用于实体岛屿 Y 锚点 |

## 验证标准

每次改 profile 或渲染函数，至少检查：

- 初始静帧：清亮、开阔，岛屿不遮挡角色。
- 向上飞行帧：近景岛从下方退场，中景移动适中，远景仍贴近地平线。
- 恒速 Y 运动：所有海面实体岛屿的最终可见 bounds Y 步进必须相等，不能因 `far`、`mid`、`near`、`depth` 或地平线保护产生非线性速度。
- 相机 vertical look-ahead：可以影响角色屏幕构图，但不能改变实体岛屿中心锚点 Y。
- 屏幕边缘：岛屿必须先按投影 bounds 进入淡出，再完全离屏剔除，不能在画面内硬消失。
- 地平线附近：实体 scenic island 不能因为地平线 guard 改透明；仍可见的实体岛应由 profile 放在海平线下方。
- Boost 帧：速度线和水纹提供速度感，但不出现横线穿帮、矩形贴片或重复岛链。

推荐命令：

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs @('--quit-after','3','res://scenes/prototypes/YujianSpriteSequencePrototype.tscn')
.\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs @('--script','res://tools/verify_yujian_horizon_linear.gd')
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

renderer 已经从原型脚本中抽出。后续新增关卡优先复制 profile 并在关卡/原型宿主上切换 `关卡背景配置路径`，不要把具体关卡岛屿布置写回宿主脚本。
