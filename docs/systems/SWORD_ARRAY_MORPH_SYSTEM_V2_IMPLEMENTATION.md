# 剑阵形变系统 V2 实现说明（2026-03-29）

## 1. 文档定位

本文档记录当前仓库里已经落地的 V2 实现规则，不再重复设计目标。  
如果要恢复上下文，建议按以下顺序阅读：

1. `docs/systems/SWORD_ARRAY_MORPH_SYSTEM_V2.md`
2. `docs/systems/SWORD_ARRAY_MORPH_SYSTEM_V2_IMPLEMENTATION.md`
3. `docs/reviews/SWORD_ARRAY_MORPH_TRAJECTORY_ALIGNMENT.md`


## 2. 当前实现入口

当前 V2 主要集中在以下脚本：

- `scripts/system/sword_array_controller.gd`
  - 负责 `morph state`、预览几何、待发站位、发射目标、发射节奏参数
- `scripts/system/main.gd`
  - 负责持续发射循环、齐射取源、单颗弹丸起飞、已射出弹丸短时引导
- `scripts/system/game_renderer.gd`
  - 负责环阵、带状扇阵、收束到贯穿前的 section 预览绘制
- `scripts/system/sword_array_config.gd`
  - 负责距离阈值、基础形态参数、发射基础数值


## 3. 预览图形的变化

### 3.1 同一套几何驱动预览、站位与发射

V2 当前最核心的改动，是把阵图逻辑收拢到同一套 live preview 几何上。

- `get_preview_data()` 先根据当前准星距离返回当前有效预览
- `get_slot_position()` 直接按这份预览求吸附剑丸站位
- `get_fire_target()` 也直接按这份预览求发射目标

这意味着现在“玩家看到的图形”“吸附弹丸站的位置”“发射时采样的方向”使用的是同一套阵图语言，而不是三套近似逻辑。

### 3.2 `ring -> fan` 改为连续 band / crescent

`ring_stable_end` 到 `fan_stable_end` 不再在圆环和扇形之间硬切。

当前实现是：

- 先从稳定环阵进入 `crescent` / 前开口 band
- 外弧角度从 `TAU` 连续收缩到扇阵弧长
- band 的中心会先被朝准星方向轻微前拉，再逐步回到稳定扇阵位置
- 厚度与外半径独立变化，避免只靠缩弧读成“月牙突然变窄”

结果是这段变化更接近“护体圆环被向前牵开”，而不是“圆环瞬间换成扇形模板”。

### 3.3 `fan -> pierce` 改为单一 section-band 收束

`fan_stable_end` 之后，系统先保持 band 家族，再逐步塌缩到贯穿线。

当前实现分两段：

- `continuous band`
  - 从稳定 band 逐步收窄，仍保留闭合带状轮廓
- `band -> line`
  - 再把带宽继续压到接近 0，最后读成贯穿线

这里不再依赖早期那种独立的“箭簇轮廓切换”，而是让同一组 sections 持续收束，所以 `fan -> pierce` 的拓扑关系更稳定。

### 3.4 预览渲染增加 section 级别表现规则

`game_renderer.gd` 现在对 section-based 预览做了额外处理：

- 环阵辐条数量跟随当前 `absorbed_ids` 数量，而不是固定值
- band / fan 预览使用左右 outline + 前后 cap 曲线绘制
- `edge_curve_strength` 控制弧边从圆滑到近直线的释放过程
- `spine_focus` 与 `tip_focus` 分离，允许先出现中轴提示，再出现尖端强调
- `preview_state` 可继续传递过渡态颜色语义，减少几何已经变了但配色突然跳态的感觉


## 4. 弹幕发射的机制规则

### 4.1 发射节奏不再只按固定模式表

持续发射现在由 `release profile` 驱动，而不是简单依赖旧的固定 `burst` 模板。

当前每帧都会根据 live morph geometry 计算：

- `release_rate`
- `packet_size_target`
- `coverage_weight`
- `center_bias`

`main.gd` 用 `array_release_progress` 做累积，用 `array_packet_remainder` 保留批次数的余量，所以同一轮持续按住时，发射频率和单次包大小可以连续过渡。

### 4.2 `ring -> fan` 的发射语义按“包围感”退场

这段不是只看形态状态名，而是看当前 preview 还像不像“环绕近身清场”。

当前规则：

- 如果当前 preview 仍是 `crescent`，就额外计算 `ring_fan_encircle_weight`
- 这个权重同时参考 band 覆盖弧长和 band 圆心相对玩家的偏移
- 包围感越强，越接近环阵语义：发射更整包、覆盖更广
- 包围感越弱，越接近扇阵语义：包大小缩小、覆盖收前

这解决了“视觉还像环阵，但节奏已经提前切成扇阵”的错位问题。

### 4.3 `fan -> pierce` 会连续提速、减包、收中

这段发射规则明确朝贯穿语义收束。

- `release_rate` 逐步向 `pierce` 提升
- `packet_size_target` 逐步减到 `1`
- `coverage_weight` 下降，减少两翼铺开
- `center_bias` 上升，采样更靠近中轴

结果是玩家在拖远准星时，会感到从“面压制”连续过渡到“线刺穿”。

### 4.4 每轮齐射先快照实际发射源

`_fire_absorbed_marbles()` 现在会先构建一次 `source_snapshot`，记录本轮开始时每颗吸附弹丸的实际屏幕位置。

之后本轮每一发：

- 从这份快照里选最符合当前目标方向的弹丸
- 发完后只从快照里移除，不立刻让剩余弹丸按理论新阵位重排

这样同一轮齐射的出射顺序会和玩家眼前看到的站位一致，不会出现“理论阵型已经缩了，但画面上剩余剑丸还没动”的错位。

### 4.5 发射起点改为 preview-aware

`get_fire_launch_origin()` 现在允许预览几何直接决定起飞锚点。

当前规则：

- 普通环阵 / 普通扇阵可以直接从当前弹丸位置起飞
- 晚期收束 band 和稳定 `pierce` 会把弹丸先拉到前锋起飞点，再赋予速度

这保证了稳定贯穿和 late collapse 阶段有统一的“从中轴前锋出射”的读感。

### 4.6 实际速度始终由“目标点 - 当前起飞点”得到

系统不再直接把预览法线或理论扇角当成最终速度。

当前流程是：

1. 先用 preview 求目标点
2. 再用 `target_point - launch_origin` 求实际飞行方向
3. 最后把弹丸速度设为该方向乘以 `FIRED_SPEED`

所以即使 source slot 是离散的，实际轨迹也会优先对齐当前看到的阵图几何。

### 4.7 已射出弹丸保留短时 live guidance，但禁止回头

左键持续按住时，已射出弹丸会在短时间内继续按当前阵图重采样目标点。

这层机制的边界如下：

- 只在 `FIRED_GUIDANCE_DURATION` 和 `FIRED_GUIDANCE_MAX_DISTANCE` 内生效
- 一旦左键松开或超过近场引导距离，就回到纯弹道
- 引导时会强制保留最小前向分量，避免因为阵图突变让弹丸向后掉头

因此当前实现允许“继续弯向当前阵势”，但不允许出现明显的反向折返。


## 5. 当前实现结论

到 `2026-03-29` 这一阶段，V2 的实现重点已经明确为两条：

1. 预览图形必须连续，并且和待发站位、发射目标共享同一套几何。
2. 弹幕发射规则必须随着阵势连续变化，但仍保持可读的战术语义过渡。

如果后续继续调参，优先检查的入口应是：

- `SwordArrayController.get_preview_data()`
- `SwordArrayController.get_fire_release_profile()`
- `SwordArrayController.get_fire_target()`
- `Main._fire_absorbed_marbles()`
- `Main._update_guided_fired_bullet()`

这些位置共同决定了“图形怎么变”和“弹怎么发”。
