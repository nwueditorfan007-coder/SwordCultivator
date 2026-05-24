# 御剑序列帧飞行测试场景说明

- 日期：`2026-05-24`
- 状态：飞行测试场景已改为“航向角速度输入 + Gemini 八向巡航静帧 + 油门 + 短滑悬停 + 回锋弧线”原型
- 范围：仅覆盖 `YujianSpriteSequencePrototype` 飞行动画/手感测试，不接入正式 `Main.tscn`
- 入口：`res://scenes/prototypes/YujianSpriteSequencePrototype.tscn`
- 脚本：`res://scripts/prototypes/yujian_sprite_sequence_prototype.gd`

## 1. 原型目标

本原型用于验证“人站在剑上飞”的二维大战场御空手感。

这轮目标不是把 Jet Lancer 的操控方式照搬进项目，而是吸收它在二维大战场中的速度读法、转向读法和镜头读法，再转译成《SwordCultivator》的御剑调性：

- 玩家用方向键给目标航向施加转向角速度，不用鼠标控制飞行方向
- `Space` 是催剑油门；按住才持续前进，松开后只短滑一小段并自然悬停
- 高速反向不是瞬间掉头，而是实际走出一段回锋弧线
- 动画可以表现急转、压剑、爬升、下潜，但不能锁住移动控制
- 大战场优先给速度感、穿行感和御空余量，而不是小房间横移

## 2. 当前输入

默认输入语义：

- `W / A / S / D`：给目标航向一个转向输入；按键方向仍对应 12 点、9 点、6 点、3 点，但不再瞬间写入航向，而是让目标航向按角速度慢慢追过去
- `Space`：催剑油门，使用现有 `dash` action
- 松开 `Space`：进入极短滑行，然后悬停
- `K`：切换绿幕抠像显示
- `T`：切换自动演示
- `R`：重播当前 clip

约束：

- 鼠标不参与飞行方向控制
- 方向键目前是飞行测试脚本内的局部 fallback；项目 `move_*` action 仍只作为正式输入映射来源
- 本原型不接攻击、不接闪避、不接无敌窗口
- 未来手柄摇杆可直接复用 `Input.get_vector("move_left", "move_right", "move_up", "move_down")`，摇杆幅度可以自然影响目标航向的转向速度

## 3. 运动模型

当前移动由三层状态驱动：

- `heading_input`：玩家当前给出的转向方向，由 `WASD`/方向键得到
- `target_heading`：目标航向，由 `heading_input` 按角速度推过去，不再被按键直接覆盖
- `body_heading`：角色/剑身实际朝向，以角速度追向 `target_heading`
- `velocity`：真实位移速度，按 `body_heading` 加速或短滑归零

实际手感语义：

- 只按方向键时：目标航向先缓慢转过去，角色再追向目标航向；玩家能原地调头或微调姿态，但不会因为按键瞬间改朝向
- 按住 `Space` 时：速度向 `body_heading * BOOST_SPEED` 追赶，像赛车油门一样持续给推力
- 松开 `Space` 时：`SLIP_DURATION = 0.12` 秒短滑，随后用高刹势进入悬停
- 高速大角度反向时：触发 `carve_timer`，速度保留一部分并叠加侧向回锋力，轨迹会实际画出弧线
- 贴近边界时：提前把航向和速度拉回场内；越界时才用兜底反弹，表现上应读作云海结界折返

关键常量：

- `BOOST_SPEED = 650.0`
- `ACCELERATION = 1320.0`
- `BOOST_ACCELERATION = 1920.0`
- `HOVER_BRAKE = 5200.0`
- `SLIP_BRAKE = 4200.0`
- `SLIP_DURATION = 0.12`
- `INPUT_HEADING_TURN_RATE = 4.8`
- `HEADING_TURN_RATE = 5.6`
- `HOVER_HEADING_TURN_RATE = 8.4`
- `HARD_HEADING_TURN_RATE = 9.0`
- `HARD_TURN_MIN_ANGLE = 2.06`
- `CARVE_DURATION = 0.24`
- `BOUNDARY_SOFT_MARGIN = 280.0`

## 4. 动画与表现语义

当前视觉层先启用 Gemini 生成的八向巡航静帧，用于验证八方向读法和飞行手感：

- V1：`res://resources/flight/yujian_8way_cruise_generated_v1/prototype/`
- V2：`res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v2/`
- V3：`res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/`

原型脚本通过 `eight_way_character_set` 导出选项选择 V1/V2/V3；默认使用 V3，运行时按 `V` 可以直接切换。V2 来自 `accepted/` 目录，统一为 `768x768` 透明画布，并按头部宽度约 `86px` 做了一轮人物大小规格化。V3 同样来自 `accepted/` 目录，但改用脸部可见区域作为标准；背向方向使用后脑/发髻核心作为同级替代，所有方向只做等比缩放，不做横纵分开拉伸。

V2 的缩放和位置可以手调：

- 调整文件：`res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v2_adjustments.json`
- 重建命令：`py tools\build_yujian_8way_cruise_v2.py`
- `target_head_width`：全局头部基准，数值越大整体越大
- `global_scale`：全局倍率，`0.95` 会整体缩小 5%，`1.05` 会整体放大 5%
- 每个方向的 `scale`：单方向倍率，例如 `07_down` 设为 `0.92` 就只缩小下方向
- 每个方向的 `offset`：单方向位置偏移，`[12, -8]` 表示向右 12px、向上 8px

运行时也有调参面板：

- `F2`：显示/隐藏八向人物调参面板
- 面板内可切换 V1/V2/V3 资源集，也可以跟随当前飞行方向自动选中对应方向
- `全局缩放`：当前资源集整体倍率
- `方向缩放`：当前方向单独倍率
- `X/Y 偏移`：当前方向运行时位置微调
- `保存 JSON`：写入 `res://resources/flight/yujian_8way_cruise_generated_v1/prototype_runtime_adjustments.json`

方向顺序：

- `01_right.png`
- `02_up_right.png`
- `03_up.png`
- `04_up_left.png`
- `05_left.png`
- `06_down_left.png`
- `07_down.png`
- `08_down_right.png`

这些图来自同目录下的 `Gemini_Generated_Image_*.png` 原图，已做浅背景抠像和 `768x768` 统一画布处理。当前是“八向静态巡航模拟”，不是最终序列帧成品。

旧动作资源仍保留在：

`res://resources/flight/generated/`

使用的 flight-only sheet 继续负责 clip graph 的节奏/状态语义，并作为后续回退资源：

- `yujian_v2_cruise_idle.png`：低速/悬停巡航读法
- `yujian_v2_cruise_turn.png`：低速完整转身
- `yujian_v2_boost_enter.png`：进入高速
- `yujian_v2_boost_idle.png`：高速巡航
- `yujian_v2_boost_exit.png`：退出高速
- `yujian_v2_hard_turn_core.png`：高速急转核心
- `yujian_v2_hard_turn_to_boost.png`：急转后接高速
- `yujian_v2_hard_turn_to_cruise.png`：急转后接低速

重要改变：

- clip 不再驱动移动速度，不再在转身 clip 里把水平速度硬推到 `0`
- `speed_mode` 仍由真实速度阈值决定，用于选择高速/低速动画语义
- `hard_turn_core` 由高速大角度回锋请求触发，只服务表现，不阻塞输入
- `USE_GEMINI_8WAY_CRUISE = true` 时，`body_heading` 被量化成八方向选图
- 八向图模式下不再用 `sprite_root.rotation` 整张旋转，也不再用 `render_sign` 镜像左右
- `character_sprite.rotation`、缩放和偏移只保留很小的姿态层：转向压身、回锋拉伸
- 关闭八向图模式后，旧 sheet 仍可回到 root rotation + clip graph 的表现方式
- 拖尾锚点、残影旋转、相机缩放都跟随当前航向和速度

资源边界：

- Gemini 八向图只覆盖巡航姿态读法，暂不表达完整转身序列帧、急转关键帧和高速变形
- `cruise_turn`、`hard_turn_core`、`hard_turn_to_boost`、`hard_turn_to_cruise` 的播放状态仍存在，但八向模式下视觉会继续按当前 `body_heading` 选图
- 如果后续美术要补资源，优先把这套八向巡航扩成“巡航循环 + 高速上扬/下潜 + 大角度压剑回锋”三类，不要直接回到整图旋转方案
- 朝向符号切换时会清理方向性拖尾/残影，避免旧剑尾锚点从另一侧穿身

## 5. 大战场与镜头

飞行测试场景已扩展：

- 横向：`5.0x`
- 纵向：`3.0x`

镜头策略：

- 以 `flight_pos` 为中心跟随
- 用速度做轻微提前量，避免高速时贴脸
- 高速时从 `CAMERA_MIN_ZOOM = 1.0` 拉到 `CAMERA_MAX_ZOOM = 1.18`
- 不使用震屏，避免御剑飞行变晕

速度参照物：

- 世界网格显示大地图尺度
- 云层和山带作为低频参照
- 拖尾和残影作为高速近身参照
- 边界框暂时是调试读法，后续应换成云海/结界视觉

## 6. Clip Graph

低速链路：

`CRUISE_IDLE -> CRUISE_TURN -> CRUISE_IDLE`

高速链路：

`CRUISE_IDLE -> BOOST_ENTER -> BOOST_IDLE`

高速急转链路：

`BOOST_IDLE -> HARD_TURN_CORE -> HARD_TURN_TO_BOOST -> BOOST_IDLE`

急转后如果真实速度已经降到低速语义：

`HARD_TURN_CORE -> HARD_TURN_TO_CRUISE -> CRUISE_IDLE`

当前 clip graph 只负责“看起来是什么动作”。真实位移由 `target_heading/body_heading/velocity` 决定。

## 7. 调参方向

如果手感还不对，优先按玩家感受调这些点：

- 松油门仍滑太远：提高 `SLIP_BRAKE` 或降低 `SLIP_DURATION`
- 悬停太硬：降低 `HOVER_BRAKE`，但不要让停止超过约 0.18 秒
- 按键转向目标太慢：提高 `INPUT_HEADING_TURN_RATE`
- 身体追目标航向不跟手：提高 `HEADING_TURN_RATE` 或 `HOVER_HEADING_TURN_RATE`
- 高速回锋不够明显：延长 `CARVE_DURATION` 或提高 `CARVE_SIDE_FORCE`
- 高速回锋像瞬移：降低 `HARD_HEADING_TURN_RATE`，让速度方向和身体方向有更清楚的夹角
- 镜头太近：提高 `CAMERA_MAX_ZOOM`，但不建议超过 `1.25`
- 边界太硬：提高 `BOUNDARY_SOFT_MARGIN`，让折返更早发生

## 8. 验收方式

场景启动验证：

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs @('--quit-after','3','res://scenes/prototypes/YujianSpriteSequencePrototype.tscn')
.\tools\show_godot_errors.ps1 -Tail 220
```

人工验收重点：

- 只按方向键时，角色能原地调整航向，不漂走；`WASD` 不会把航向瞬间改成八方向
- 按住 `Space` 后，角色沿当前航向持续加速
- 松开 `Space` 后，角色只短滑一小段并自然悬停
- 从朝右高速切到上/左/下时，速度方向不是瞬间变向，而是走出回锋弧线
- 连续反复转向时，移动不再被转身 clip 刹停
- 高速反向触发急转动画，但玩家仍能继续改变航向
- 上升、下潜、斜飞能通过旋转和姿态层读出来
- 大地图穿行时镜头拉远、拖尾和云层能给出速度感

## 9. 当前边界

本原型当前不处理：

- 正式主战斗场景接入
- 攻击朝向和鼠标瞄准
- 闪避、无敌、受击
- 云海结界正式美术资源
- 手柄摇杆死区和 UI 提示
- 正式飞行组件抽象

后续如果要进主场景，建议先在本测试场景里把“航向、油门、短滑、回锋、镜头”五件事调顺，再拆成独立飞行组件接入正式移动/战斗状态机。
