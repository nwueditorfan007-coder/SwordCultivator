# 御剑序列帧飞行测试场景说明

- 日期：`2026-05-27`
- 状态：飞行测试场景已改为“超大战场 + 3 倍飞行速度 + V4 程序化骨骼缩放参数 + 航向角速度输入 + 方向切换特效 + 油门 + 短滑悬停 + 回锋弧线”原型
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

- `W / A / S / D`：给目标航向一个转向输入；按键方向仍对应 12 点、9 点、6 点、3 点，但不再瞬间写入航向，而是让目标航向每帧只转过一段角度
- `Space`：催剑油门，使用现有 `dash` action
- 松开 `Space`：进入极短滑行，然后悬停
- `K`：切换绿幕抠像显示
- `T`：切换自动演示
- `R`：重播当前 clip

约束：

- 鼠标不参与飞行方向控制
- 方向键目前是飞行测试脚本内的局部 fallback；项目 `move_*` action 仍只作为正式输入映射来源
- `Direct intent` 和 `Steer throttle` 两种测试模式都必须通过角速度更新 `target_heading`，不能把按键方向一次性写进去
- 本原型不接攻击、不接闪避、不接无敌窗口
- 未来手柄摇杆可直接复用 `Input.get_vector("move_left", "move_right", "move_up", "move_down")`，摇杆幅度可以自然影响目标航向的转向速度

## 3. 运动模型

当前移动由三层状态驱动：

- `heading_input`：玩家当前给出的转向方向，由 `WASD`/方向键得到
- `target_heading`：目标航向，由 `heading_input` 按 `INPUT_HEADING_TURN_RATE` 逐帧旋转过去，不再被按键直接覆盖
- `body_heading`：角色/剑身实际朝向，以角速度追向 `target_heading`
- `velocity`：真实位移速度，按 `body_heading` 加速或短滑归零

实际手感语义：

- 只按方向键时：目标航向先缓慢转过去，角色再追向目标航向；玩家能原地调头或微调姿态，但不会因为按键瞬间改朝向
- 按住 `Space` 时：速度向 `body_heading * BOOST_SPEED` 追赶，像赛车油门一样持续给推力
- 松开 `Space` 时：`SLIP_DURATION = 0.12` 秒短滑，随后用高刹势进入悬停
- 高速大角度反向时：触发 `carve_timer`，速度保留一部分并叠加侧向回锋力，轨迹会实际画出弧线
- 贴近边界时：提前把航向和速度拉回场内；越界时才用兜底反弹，表现上应读作云海结界折返

关键常量：

- `FLIGHT_SPEED_MULTIPLIER = 3.0`
- `CRUISE_SPEED = 1170.0`
- `BOOST_SPEED = 2280.0`
- `ACCELERATION = 3960.0`
- `BOOST_ACCELERATION = 6900.0`
- `DIRECT_BOOST_ACCELERATION = 9000.0`
- `HOVER_BRAKE = 15600.0`
- `SLIP_BRAKE = 12600.0`
- `SLIP_DURATION = 0.12`
- `INPUT_HEADING_TURN_RATE = 4.8`
- `HEADING_TURN_RATE = 5.6`
- `HOVER_HEADING_TURN_RATE = 8.4`
- `HARD_HEADING_TURN_RATE = 9.0`
- `HARD_TURN_MIN_ANGLE = 2.06`
- `HARD_TURN_MIN_SPEED = 1260.0`
- `CARVE_DURATION = 0.24`
- `BOUNDARY_SOFT_MARGIN = 840.0`

## 4. 动画与表现语义

当前视觉层只保留 V4 程序化骨骼飞行 rig 作为主线：

- 入口：`res://scenes/prototypes/YujianSpriteSequencePrototype.tscn`
- 人物表现脚本：`res://scripts/prototypes/humanoid_8way_skeleton_visual.gd`
- V4 像素化 3D 场景入口：`res://scenes/prototypes/YujianV4Pixel3DViewPrototype.tscn`
- V4 像素化 3D 场景脚本：`res://scripts/prototypes/yujian_v4_pixel_3d_view_prototype.gd`

V1/V2/V3/V5/V6/V7、3D 模型试验、Google parts 试验、八向生图候选和对应捕获工具没有删除，已统一移动到：

`archive/flight_visual_non_v4_20260530/`

后续查询废弃方案时先看这个归档目录，不要从空白重新做同类试验。主线脚本的 `eight_way_character_set` 现在只暴露 `V4 skeleton rig`，运行时不再通过 `V` 键切换旧版本。

V4 不是传统地面角色八向站姿，也不是趴伏飞行姿态。它继续读取 `visual_heading`，但骨骼姿态只人工维护四个主方向：右、上、左、下。右上、左上、左下、右下不再单独调骨骼点，而是由程序按实际航向在相邻两个主方向之间插值生成；插值前会按屏幕侧重映射 `near/far` 肢体，避免左上、左下把不同身体侧的手脚硬插到一起。每个主方向都保持“人站在飞剑上”的御剑姿态：飞剑按航向前进，脚和骨盆锁在剑上方，躯干短窄、腿部更长。当前默认外观是 `Video stickman`：沿用 V4 骨骼点，但绘制时重建成视频式连续火柴人结构，大圆头压在脊柱顶端，躯干是一条从头下缘到单一骨盆点的胶囊线，两条腿从同一个骨盆点连续分叉，双臂从上躯干小分叉接出，手脚只保留圆端/短端帽；旧的体积化 `Clean capsule` 外观仍可通过 `visual_style` 导出参数切回。因此 V4 骨骼版验证的是飞行读感：爬升、下潜、斜飞、回锋压身，而不是角色站在地面看上下左右。

V4 速度姿态参考 `C:/Users/Han_112/Downloads/加速&减速/matted_frames/`：低速参考 `matte_00001.png` 的直立控剑手势，高速参考 `matte_00025.png` 的前压冲刺手势。程序骨骼按真实速度、油门和 boost 能量在两套姿态间插值，不直接使用这两张图作为运行时贴图。

V4 外形目前由程序绘制，不是单独贴图资源。默认火柴人外观只替换绘制壳，不改 F4 面板中保存的关节坐标、骨段长度、四向姿态和运行时姿态 FX。`Clean capsule` 旧外观仍保留黑灰水墨剪影、束髻长发、飘发、发带、宽袖、长袍下摆、腰间飘带、暗色靴子和少量灰白描边；这些外观只包裹骨骼点，不改变姿态数据。头发、袖口、袍摆和腰间飘带的二级运动只在旧外观中绘制，火柴人模式会跳过这些服饰层，避免线架读法被黑灰布片遮住。

飞剑同样走程序绘制路线，不使用贴图贴片。默认 `云岚载人剑` 参考 B 站 `BV1hbLM6JEQ6` 里“人站在真实长剑上”的读法：先用多边形画出宽扁剑身、三角剑尖、中央剑脊、分面剑刃、深色剑柄、护手和尾端装饰，再把蓝白灵光压在剑刃与脚下作为辅助，不再用单根发光线冒充剑。剑身根部避免平直矩形端面，采用窄剑根、展宽剑肩、收束剑尖的连续轮廓；护手也用梭形轮廓，避免在所有飞剑底部出现方块感。`HumanoidEightWaySkeletonVisual.sword_style` 当前提供 6 款可选外观：`云岚载人剑`、`墨骨残锋`、`青霜灵脉`、`断星飞剑`、`符刃法剑`、`血线破妄`。这些版本共用同一个脚底锁剑点和航向，只改变剑身线条、剑尖、护手、光晕、断裂刻痕、符文碎片、星屑或血线等轻量特效，因此不会破坏已经调好的 V4 骨骼姿态。运行时按 `F6` 可循环切换，调试文字会显示当前飞剑名，方便实机挑选。

V4 服饰二级运动在场景风带修正后只负责“角色衣物受风”，不再承担速度条职责；运行时会降低长发、发带、袍摆和腰间飘带的拖拽距离、透明度和转向跟随速度，避免黑灰贴身条被误读成另一层风带。

骨骼角色基础大小也有单独参数：

- `skeleton_size_scale`：`YujianSpriteSequencePrototype` 脚本导出参数，当前默认 `0.3`；数值越小，V4 程序角色越小
- F2 面板里的 `全局缩放` 和 `方向缩放` 仍会叠加在 `skeleton_size_scale` 之上，用于运行时微调

运行时也有调参面板：

- `F2`：显示/隐藏人物资源调参面板
- `F6`：循环切换 V4 程序飞剑外观，用于在 6 款飞剑设计之间快速比较
- 面板内只保留 V4 资源集，也可以跟随当前飞行方向自动选中对应方向
- `全局缩放`：V4 整体倍率
- `方向缩放`：当前方向单独倍率
- `X/Y 偏移`：当前方向运行时位置微调
- `预判时间 / 预判X / 预判Y / 预判平滑 / 急转预判`：镜头抗眩晕参数；`急转预判` 越低，急转时镜头越贴身，但太低会更容易出现回弹
- `保存调参 JSON`：写入 `res://resources/flight/yujian_8way_cruise_generated_v1/prototype_runtime_adjustments.json`

V4 程序骨骼还有独立姿态编辑面板：

- `F4`：显示/隐藏 V4 骨骼姿态编辑面板
- `姿态`：切换低速 `low` 或高速 `fast` 基准姿态
- `主方向`：切换当前要编辑的四向主姿态，只有右、上、左、下；斜向由运行时骨骼插值生成
- `前景侧`：指定当前姿态/主方向里哪一侧骨骼按前景绘制；垂直方向尤其用于决定左侧或右侧肢体高亮、加粗并配合层级置前
- `关节`：选择头、肩、肘、腕、髋、膝、踝等骨骼点
- `锁骨长`：拖动或输入关节偏移时，保持当前关节到父关节的标准骨长；默认关闭，方便先自由摆姿态
- `骨段` / `标准骨长`：手动设置 `躯干 / 大臂 / 小臂 / 大腿 / 小腿` 的锁定长度，近侧和远侧共用同一组长度
- `X/Y 偏移`：写入当前姿态/方向/关节的偏移量
- `头大小`：调整当前姿态/方向的头部半径倍率
- `层级`：选择当前要调整前后关系的身体层，`后移`/`前移`/`置顶` 会改变绘制顺序
- 鼠标可点选并拖拽角色身上的关节点；方向键可做 1px 微调，`Shift + 方向键` 为 5px 微调
- `校正骨长`：把当前选中关节立即拉回标准骨长；`取当前骨长`：把当前骨段的实际长度写成标准骨长；`重置骨长`：恢复程序默认骨长
- `重置点`：清掉当前关节偏移；`重置方向`：清掉当前姿态下当前方向的所有关节偏移
- `复制对向`：把当前姿态/方向的偏移复制到 180 度对向
- `左右镜像`：把当前姿态/方向镜像到左右对应方向；近侧/远侧肢体会互换，X 偏移会取反
- `应用全部`：把当前姿态/方向的偏移铺到四个主方向，适合先统一改一个整体问题再逐向修正
- `复制姿态JSON`：把当前姿态/方向的实际骨骼点位复制到剪贴板
- `导入姿态JSON`：从剪贴板读取姿态点位，并换算成当前姿态/方向的 offset；可先在 `low` 复制，再切到 `fast` 导入，作为高速姿态起点
- `保存 JSON`：写入 `res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v4_skeleton_pose_overrides.json`，其中 `bone_lengths` 是全局骨段长度，`poses` 是各姿态/方向的点位偏移、头大小、绘制层级和前景侧；旧八向 key 仍可保留在 JSON 中兼容读取，但 V4 运行时只使用四个主方向生成斜向

V4 的 F4 基准姿态仍然不被运行时写回或改动；运行时只在最终姿态上叠加一层可关闭的 `V4 Idle Pose FX`。这层会按真实速度、boost、turn、carve、throttle 和动作释放后的回收压力，对头、肩、髋、肘、腕、膝做小幅 additive 微动：悬停偏慢呼吸，巡航偏控剑手腕，高速偏压身小震动，急转偏压剑，急转/加速释放后有短回收。脚踝不参与这层偏移，继续保持脚底锁剑。真实速度仍决定 `low` 到 `fast` 的插值，但当高速权重接近完成时会吸附到完整 `fast` 姿态，避免右向高速飞行时偏离编辑面板里摆好的骨骼。

当前原型人物基础缩放已减半：V4 程序角色额外叠加 `skeleton_size_scale = 0.3`。

旧动作 sheet 仍保留在：

`res://resources/flight/generated/`

这些 flight-only sheet 不再作为人物版本切换入口，只继续服务 clip graph 的节奏/状态语义，并作为 V4 主线的低风险回退资源：

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
- `USE_GEMINI_8WAY_CRUISE = true` 时，V4 驱动程序化骨骼姿态并在主方向之间插值生成斜向读法
- V4 模式下不再用 `sprite_root.rotation` 整张旋转，也不再用 `render_sign` 镜像左右
- `character_sprite.rotation`、缩放和偏移只保留很小的姿态层：转向压身、回锋拉伸
- 四向 index 切换时会触发程序方向切换特效：旧方向短残影、新方向前缘亮边、剑尾弯月形回锋弧线、轻微压身回弹
- 方向切换特效只解释视觉过程，不改写 `target_heading/body_heading/velocity`，也不阻塞玩家继续转向
- 拖尾锚点、残影旋转、相机缩放都跟随当前航向和速度

资源边界：

- V4 外观仍由程序骨骼与轻量服饰二级运动表达，不依赖已归档的 Gemini 四向静帧候选
- `cruise_turn`、`hard_turn_core`、`hard_turn_to_boost`、`hard_turn_to_cruise` 的播放状态仍存在，但人物读法由 V4 骨骼姿态承接
- 如果后续美术要补资源，优先沿 V4 的“程序骨骼/挂点/小尺寸御剑读法”推进，不要直接回到整图旋转或静态贴图换向方案
- 朝向符号切换时会清理方向性拖尾/残影，避免旧剑尾锚点从另一侧穿身

## 5. 大战场与镜头

飞行测试场景已扩展：

- `BATTLEFIELD_SIZE_MULTIPLIER = 8.0`
- 横向：`80.0x`
- 纵向：`48.0x`

镜头策略：

- 以 `flight_pos` 为硬锚点，减少高速转向时的相机拖拽感
- 只平滑速度预判量 `camera_look_ahead`，不再让整个镜头中心慢慢追旧方向
- 用更短的速度提前量避免高速时贴脸；急转、回锋和方向切换时会压低预判距离
- 高速时从 `CAMERA_MIN_ZOOM = 1.12` 拉到 `CAMERA_MAX_ZOOM = 1.30`
- 不使用震屏，避免御剑飞行变晕

当前抗眩晕镜头常量：

- `CAMERA_LOOK_AHEAD_TIME = 0.10`
- `CAMERA_MAX_LOOK_AHEAD = Vector2(360.0, 110.0)`
- `CAMERA_LOOK_AHEAD_HALF_LIFE = 0.075`
- `CAMERA_HARD_TURN_LOOK_AHEAD_SCALE = 0.58`
- F2 面板可以运行时调整并保存这些镜头参数

速度参照物：

- 世界网格显示大地图尺度
- 云层和山带作为低频参照
- 拖尾和残影作为高速近身参照
- 边界框暂时是调试读法，后续应换成云海/结界视觉

场景效果测试接入：

- 参考工程本地拉取在 `third_party/ffttasd/wind_ribbon` 和 `third_party/ffttasd/godot_fog_card`
- 这两个仓库当前作为测试引用，不作为正式发布资源边界
- 原型通过透明 3D `SubViewport` 直接挂载 `wind_ribbon/scripts/wind_ribbon_effect.gd`
- 云雾卡片直接使用 `godot_fog_card/scripts/fog_card_3d.gd` 和 `reference_fog/shaders/fog-card.gdshader`
- `SubViewport` 的合成图贴回 2D 原型，作为人物下方、背景上方的测试效果层

当前触发规则：

- 远山和中景山常驻，使用低倍率视差；玩家向右移动时，山体向左慢速滑动
- 远/中/近三层云雾常驻，只受时间慢流动和相机位置视差影响，不直接吃玩家加速度
- 低速悬停时不显示风带，只保留慢速云雾
- `Space` boost、高速巡航和稳定高速航道时显示风带，但风带不再作为唯一速度反馈
- 风带表达“稳定航道的空气流形”，不表达转向轨迹；检测到急转、carve、方向切换或航向仍在变化时，所有风带停发并渐隐，避免旧航道风带和当前飞行方向冲突
- 当前稳定航道还要求速度方向与身体航向、目标航向基本对齐；风带一旦开始发射，当前段不会再追着航向持续旋转，新的航道稳定后才会重新软启动
- 航向稳定累计一小段时间后，风带才在新航道软启动；转向期间的速度感主要交给 2D 世界空间短白线和角色自身拖尾
- 旧航道风带释放要快，避免转向后残留风带和新飞行方向冲突；当前会缩短第三方粒子 trail 生命周期、降低非激活段释放半衰期，并更早隐藏旧段
- 运行时风带开关直接控制 `StrandParticles` / `VeilParticles`，不再在转向中调用第三方脚本的 `emitting` setter，避免重建粒子材质和 trail mesh 带来的卡顿
- 速度感新增一层 2D 世界空间短白线，按真实速度、油门和 carve 生成；这层负责“画面掠过”的速度反馈，3D `wind_ribbon` 只负责低透明空气流形质感
- 风带颜色和透明度在 `scripts/prototypes/yujian_sprite_sequence_prototype.gd` 顶部常量调节：`REFERENCE_WIND_STRAND_COLOR`、`REFERENCE_WIND_VEIL_COLOR`、`REFERENCE_WIND_STRAND_OPACITY`、`REFERENCE_WIND_VEIL_OPACITY`
- 风带转向抑制和淡入/释放调节：`REFERENCE_WIND_TURN_SUPPRESS_PRESSURE`、`REFERENCE_WIND_STABLE_ANGLE`、`REFERENCE_WIND_REAPPEAR_STABLE_TIME`、`REFERENCE_WIND_START_PREPROCESS`、`REFERENCE_WIND_ACTIVE_HALF_LIFE`、`REFERENCE_WIND_RELEASE_HALF_LIFE`、`REFERENCE_WIND_RELEASE_HIDE_THRESHOLD`、`REFERENCE_WIND_RELEASE_MIN_SCALE`、`REFERENCE_WIND_STRAND_TRAIL_LIFETIME`、`REFERENCE_WIND_VEIL_TRAIL_LIFETIME`
- 稳定航道判定调节：`REFERENCE_WIND_HEADING_SETTLE_ANGLE`、`REFERENCE_WIND_VELOCITY_ALIGN_ANGLE`、`REFERENCE_WIND_HEADING_RATE_LIMIT`
- 速度线调节：`SCENE_SPEED_STREAK_MAX_COUNT`、`SCENE_SPEED_STREAK_MIN_ENERGY`、`SCENE_SPEED_STREAK_SPAWN_RATE`、`SCENE_SPEED_STREAK_LIFE`、`SCENE_SPEED_STREAK_MIN_LENGTH`、`SCENE_SPEED_STREAK_MAX_LENGTH`

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
- 方向切换还是像跳图：提高 `EIGHT_WAY_SWITCH_GHOST_LIFE`、`DIRECTION_SWITCH_FX_LIFE` 或 `DIRECTION_SWITCH_ARC_RADIUS`
- 轻微转向太吵：降低 `DIRECTION_SWITCH_ARC_RADIUS`，或提高触发强度计算里的最低可见强度
- 镜头回弹太明显：先降低 `预判时间` 或 `预判X/Y`；如果是急转后弹回来，适当提高 `急转预判`
- 镜头仍然拖拽发晕：先降低 `预判时间` 或 `预判Y`
- 镜头太近：提高 `CAMERA_MAX_ZOOM`，但不建议超过 `1.42`
- 边界太硬：提高 `BOUNDARY_SOFT_MARGIN`，让折返更早发生

## 8. 验收方式

场景启动验证：

```powershell
.\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs @('--quit-after','3','res://scenes/prototypes/YujianSpriteSequencePrototype.tscn')
.\tools\show_godot_errors.ps1 -Tail 220
```

人工验收重点：

- 只按方向键时，角色能原地调整航向，不漂走；`WASD` 不会把航向瞬间改成四方向
- 按住 `Space` 后，角色沿当前航向持续加速
- 松开 `Space` 后，角色只短滑一小段并自然悬停
- 从朝右高速切到上/左/下时，速度方向不是瞬间变向，而是走出回锋弧线
- 四向静帧切换时，新方向要立刻可读，旧方向残影只表达残势，不能把人物轮廓糊成双影
- 45 度轻转只应有短尾迹和轻压身，90 度以上高速转向才应读到明显弯月剑气
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
