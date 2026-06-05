# 御剑第一关背景实现落地记录 2026-06-04

## 结论

今天这套实现的核心结论是：御剑大地图背景不应该继续靠手写 profile 数值反复猜构图。背景需要被当成关卡对象来编辑，尤其是第一关海上群岛这种需要同时满足飞行参照、海平线可信度、岛屿不遮挡角色、上下飞行不穿帮的场景。

当前已经落地三部分：

- 独立背景 renderer：负责正式游戏预览和运行时绘制。
- JSON profile：负责关卡背景数据和岛屿摆放。
- 背景摆放编辑器：让关卡作者手工拖岛、看海平线、切高度预览、保存 profile。

这套实现不是最终美术方案，而是把背景从“代码里猜数值”推进到“可编辑、可验证、可迭代”的阶段。

## 已落地文件

### 运行时

```text
res://scripts/background/yujian_level_background_renderer.gd
```

职责：

- 读取关卡 profile。
- 绘制天空、海面、远景岛带、实体岛、水纹、边界云。
- 计算稳定海平线。
- 投影 `scenic_islands`。
- 使用最终投影 bounds 做屏幕边缘淡出和离屏剔除。

关键约束：

- 海平线只响应 `flight_pos.y`，不响应速度、look-ahead、`camera_zoom`。
- 实体岛屿的主 Y 运动使用 `flight_pos.y`，不使用被边界钳制后的 `camera_center.y`。
- `layer` 影响 X 视差、体量表现和实体岛主 Y 速度；Y 速度必须按层级保持线性。
- `depth` 只影响缩放、空气透视、顶面压缩，不直接决定屏幕纵向摆放。
- 实体 scenic island 不做地平线 alpha fade；否则会出现“岛屿在画面中渐隐消失”的飞行参照问题。

### 原型宿主

```text
res://scripts/prototypes/yujian_sprite_sequence_prototype.gd
res://scenes/prototypes/YujianSpriteSequencePrototype.tscn
```

职责：

- 创建 `YujianLevelBackgroundRenderer`。
- 传入 `VIEW_SIZE`、`PLAY_RECT`、`FLIGHT_START_POS`、固定背景 zoom。
- 每帧同步飞行位置、相机位置、速度和调试状态。

宿主不再直接维护第一关背景绘制细节。后续不要把具体岛屿摆放写回原型脚本。

### 第一关 Profile

```text
res://resources/flight/background/level_01_immortal_sea_background.json
```

结构：

```json
{
  "settings": {},
  "far_island_bands": [],
  "scenic_islands": []
}
```

字段分工：

| 字段 | 职责 |
| --- | --- |
| `settings` | 天空、海面、海平线、强度、颜色和整体气质 |
| `far_island_bands` | 低信息远景岛带，只负责空间尺度，不作为强记忆点实体岛 |
| `scenic_islands` | 有形体记忆的实体岛、礁、地标，按世界锚点摆放 |

`scenic_islands` 的核心字段：

| 字段 | 说明 |
| --- | --- |
| `x`, `y` | 世界锚点；`y` 是相对 `FLIGHT_START_POS.y` 的偏移 |
| `layer` | `far` / `mid` / `near`，影响 X 视差和表现强度 |
| `band` | `horizon` / `mid_sea` / `near_sea`，决定海平线下方表现带 |
| `depth` | 体量、空气透视、顶面压缩 |
| `width`, `length`, `height` | 岛屿平面宽度、纵深压缩、崖壁高度 |
| `kind` | 程序岛屿变体 |
| `landmark` | 地标变体；`-1` 表示没有 |

## 背景摆放编辑器

入口：

```text
res://scenes/tools/YujianBackgroundMapEditor.tscn
```

脚本：

```text
res://tools/yujian_background_map_editor.gd
```

截图验证：

```text
res://tools/capture_yujian_background_map_editor.gd
res://artifacts/yujian_background_map_editor.png
```

编辑器用途：

- 读取 `level_01_immortal_sea_background.json`。
- 复用正式 `YujianLevelBackgroundRenderer` 作为唯一预览来源，画布只负责显示和交互。
- 在右侧列出全部 `scenic_islands`，界面文字全部中文。
- 支持选择、框选、多选、拖动、复制、新增、删除实体岛。
- 支持编辑 `x/y/layer/band/depth/width/length/height/kind/landmark`。
- 支持切换 `起点`、`上升`、`高空`、`顶部`、`底部` 高度预览。
- 支持手动 `保存` 写回 profile；编辑过程中只标记“未保存”，不会自动写 JSON。

V2 画布状态：

| 状态 | 说明 |
| --- | --- |
| `canvas_zoom` | 编辑器视口缩放，只影响画布显示，不改变游戏 `camera_zoom` |
| `canvas_pan` | 画布显示偏移，只影响编辑器视口 |
| `flight_pos` | 当前预览玩家锚点；右键拖动画布时会按“抓住画布”的方向反向移动 |
| `selected_indices` | 当前选中的实体岛索引，可多选 |
| 撤销栈 / 重做栈 | 记录移动、属性修改、新增、复制、删除和批量移动 |

画布操作：

| 操作 | 行为 |
| --- | --- |
| 左键点击岛屿 | 选择岛屿 |
| 左键拖动选中岛屿 | 修改选中岛屿的 `x/y` |
| Shift + 左键点击 | 增减选择 |
| 空白左键拖动 | 框选岛屿 |
| 右键拖动画布 | 平移预览地图；鼠标向右拖，画面内容跟着向右走，底层 `flight_pos` 反向变化 |
| 鼠标滚轮 | 以鼠标位置为中心缩放画布，不改 profile |
| Ctrl + S | 保存 JSON |
| Ctrl + Z / Ctrl + Y | 撤销 / 重做 |
| Delete | 删除选中岛屿 |
| F | 适配视图 |
| 1 | 恢复 100% 画布缩放 |
| G | 显示 / 隐藏网格 |
| H | 显示帮助 |

叠层默认：

- 默认显示海平线、玩家投影点、岛屿选框和红色穿帮警告。
- 默认不显示网格、对象编号和屏幕边界。
- 网格吸附默认关闭；开启后岛屿 `x/y` 按 100 世界单位吸附。

预览标记：

| 标记 | 含义 |
| --- | --- |
| 黄色水平线 | 当前海平线 |
| 黑白圆点 | 玩家当前位置投影 |
| 黄色框 | 当前选中岛 |
| 绿色框 | 正常可见实体岛 |
| 红色框 | 可见实体岛已经进入海平线以上区域 |

红色框不是渲染解决方案，只是作者警告。出现红框时，应该手工调整 `y`、`band`、`depth`、`width` 或删掉该实体岛，不要再靠运行时 alpha fade 把它隐藏。

## 为什么要做编辑器

今天反复出现的问题不是单个 bug，而是“空间构图需要人工判断”：

- 岛屿不能横向铺满，否则没有 2.5D 空间感。
- 岛屿不能透明消失，否则飞行参照断裂。
- 岛屿不能飞到天空，否则海面物理归属错误。
- 近景岛向上飞时应从下方退场，但向下飞时不能从上方穿出天空。
- 中景和远景需要不同存在感，但主 Y 运动不能分层非线性，否则玩家会觉得背景漂。

这些条件很难靠固定公式一次性满足所有关卡。公式负责稳定投影，编辑器负责关卡构图。

## 当前投影契约

实体岛中心点的主 Y 投影可概括为：

```gdscript
screen_y = horizon_y
  + band_offset
  + (object_world_y - flight_y) * layer_sea_anchor_parallax_y
```

含义：

- `horizon_y` 是海平线，是稳定物理参照。
- `band_offset` 把岛放入海平线下方的表现带。
- `object_world_y - flight_y` 决定玩家上下飞行时，岛在屏幕上的线性移动。
- `layer_sea_anchor_parallax_y` 按 `far` / `mid` / `near` 分层，默认 far 最慢、mid 居中、near 最快。

这条投影链必须保持线性。可以按层级调整斜率，但不要再引入：

- `smoothstep` 纵向压缩。
- 按屏幕位置动态改变 Y 速度。
- `max(horizon_guard - min_y)` 这类把岛屿吸回海平线下方的屏幕空间补偿。
- 地平线 alpha fade 直接淡掉实体岛。

这些方法都会破坏飞行参照。

当前默认层级倍率：

| 层级 | Y 速度倍率 | 目的 |
| --- | --- | --- |
| `far` | `0.48` | 远景岛接近海平线，纵向变化最慢 |
| `mid` | `0.78` | 中景岛提供航路参照，变化中等 |
| `near` | `1.12` | 近景岛最贴近玩家，纵向变化最大 |

倍率可通过 profile `settings` 覆盖：

```json
{
  "far_scenic_y_parallax": 0.48,
  "mid_scenic_y_parallax": 0.78,
  "near_scenic_y_parallax": 1.12
}
```

## 当前已知边界

### 1. 编辑器只负责第一关 profile

当前编辑器固定读取：

```text
res://resources/flight/background/level_01_immortal_sea_background.json
```

后续如果要做成通用关卡编辑器，需要增加 profile 路径选择、另存为、关卡 ID 切换。

### 2. 红框只报警，不自动修复

如果岛屿进入海平线以上，编辑器会标红，但不会自动裁切、下压或淡出。

原因是自动修复会重新引入今天已经确认有问题的几类行为：

- 不匀速。
- 画面中突然消失。
- 海平线附近被隐藏。
- 运行时和编辑器构图不一致。

正确做法是作者在编辑器里调整 profile。

### 3. 玩法对象还没有和背景岛绑定

当前 `scenic_islands` 是纯背景实体。若未来岛屿要承载落脚点、事件、碰撞、敌人刷点，需要另建玩法层对象，并用同一世界锚点或独立关卡对象 ID 对齐。

### 4. `far_island_bands` 仍是低信息循环远景

它适合表现海平线尺度，不适合承担“玩家正在经过某个具体岛”的记忆点。强记忆点应该放在 `scenic_islands`，并用编辑器检查上下飞行表现。

## 推荐编辑流程

1. 打开 `res://scenes/tools/YujianBackgroundMapEditor.tscn`。
2. 先用 `起点` 检查初始构图：角色周围要开阔，岛屿不能遮挡。
3. 用 `上升`、`高空` 检查向上飞时近景岛是否从下方退场。
4. 用 `底部` 检查低空边界：仍可见实体岛必须在海平线下方，不能飞到天空。
5. 用 `预览 X/Y` 或右键拖动画布检查玩家在航路不同位置时的空间感。
6. 出现红框时，优先调整 `y` 和 `band`，其次调整 `depth`、`width`、`height`。
7. 满意后点击 `保存` 或按 `Ctrl + S`。
8. 运行截图验证和数值验证。

## 验证命令

启动编辑器：

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs @('--quit-after','2','res://scenes/tools/YujianBackgroundMapEditor.tscn')
.\tools\show_godot_errors.ps1 -Tail 260
```

导出编辑器截图：

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Wait -ExtraArgs @('--script','res://tools/capture_yujian_background_map_editor.gd')
.\tools\show_godot_errors.ps1 -Tail 260
```

验证编辑器 V2 交互契约：

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs @('--script','res://tools/verify_yujian_background_map_editor_v2.gd')
.\tools\show_godot_errors.ps1 -Tail 260
```

验证背景投影契约：

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs @('--script','res://tools/verify_yujian_horizon_linear.gd')
.\tools\show_godot_errors.ps1 -Tail 260
```

导出第一关飞行预览截图：

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Wait -ExtraArgs @('--script','res://tools/capture_yujian_sprite_sequence_prototype.gd')
.\tools\show_godot_errors.ps1 -Tail 260
```

静态检查：

```powershell
git diff --check
```

## 后续建议

短期：

- 用编辑器手工重新摆第一关 `scenic_islands`。
- 删除或降级容易穿过海平线的 `horizon` band scenic island，把它们改为 `far_island_bands` 或更低存在感的实体岛。
- 增加 `Bottom` 和几个横向航路点的截图样例，形成第一关构图基准。

中期：

- 编辑器支持 profile 路径选择和另存为。
- `scenic_islands` 增加作者备注字段，例如 `name`、`role`、`route_note`。
- 编辑器增加多点巡航预览，不只看单个 `Flight X/Y`。

长期：

- 背景 profile 和玩法关卡对象建立共享锚点。
- 把 `scenic_islands` 升级为真正的关卡视觉对象层。
- 支持每关独立的气候、云层、海面色彩和远景密度配置。
