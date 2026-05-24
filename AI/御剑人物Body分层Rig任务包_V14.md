# 御剑人物 Body 分层 Rig 任务包 V14

## Summary

V14 不再以“整张 body 序列帧图集”作为源资产，而是改为“分层角色 Runtime Rig”。

核心目标：

- 解决 AI 文生图序列帧帧间不连贯、人物比例漂移、头部忽大忽小的问题。
- 保留当前御剑玩法需要的持续状态、阵型切换、释放动作和普通攻击动作。
- 让头发、披帛、袖袍、衣摆能根据速度和动作强度自然摆动。
- 最终运行时由 Godot 直接控制分层部件，不再依赖完整 body 序列帧。
- 如果后续仍需要 PNG 图集，可从 Godot rig 离线导出 sprite sheet。

V14 的核心判断：

```text
AI 负责画清楚角色和分层部件。
程序负责动作连续性。
```

## What AI Must Generate

本轮 AI 需要生成这些图：

1. `body_v14_master_full.png`
   完整角色母版，确定最终人物风格和比例。

2. `body_v14_rig_exploded_parts_clean.png`
   分层部件干净图，透明背景，不带文字、不带轴点标记，用于切图入库。

3. `body_v14_rig_exploded_parts_pivot_guide.png`
   分层部件轴点参考图，可以有彩色小点和英文部件名，只用于技术美术标注，不进游戏。

4. `body_v14_pose_bible.png`
   关键姿态圣经图，用于定义 idle、forward、back、御剑、三阵型、parry、release 的姿态语言。

5. `body_v14_layering_preview.png`
   分层部件重新组装后的预览图，检查部件能否组成完整角色。

可选生成：

6. `body_v14_expression_head_variants.png`
   头部/发型小变体，如果后续想做受击、专注、爆发神情。

7. `body_v14_cloth_variants.png`
   袖袍、披帛、衣摆的 2-3 个形变版本，用于 release 或高速移动时切换。

## Source Directory

建议文件放在：

```text
resources/flight/rider/body_v14_rig/
```

建议结构：

```text
resources/flight/rider/body_v14_rig/
  source/
    body_v14_master_full.png
    body_v14_rig_exploded_parts_clean.png
    body_v14_rig_exploded_parts_pivot_guide.png
    body_v14_pose_bible.png
    body_v14_layering_preview.png
  parts/
    torso.png
    pelvis_belt.png
    head.png
    hair_back.png
    hair_tail.png
    arm_front_upper.png
    arm_front_forearm_sleeve.png
    hand_front.png
    arm_back_upper.png
    arm_back_forearm_sleeve.png
    hand_back.png
    leg_front.png
    leg_back.png
    robe_front.png
    robe_back.png
    sash_front_root.png
    sash_front_mid.png
    sash_front_tip.png
    sash_back_root.png
    sash_back_mid.png
    sash_back_tip.png
  body_v14_rig_manifest.json
  body_v14_pose_library.json
```

## Working Resolution

为了避免像素风部件在旋转时破碎，V14 建议使用 2x 工作分辨率：

- 单个完整角色工作单元：`512 x 512`
- 角色视觉高度：约 `332-340px`
- 工作锚点：`x=256, y=438`
- 游戏中显示时再缩放到约 0.5 倍，接近原 `256 x 256` body 规格。

如果 AI 只能稳定生成 `256 x 256` 风格，也可以使用 1x，但运行时旋转角度要更小。

推荐：

```text
生成源图用 512 分辨率。
运行时显示约 0.5 倍。
部件旋转尽量控制在小角度。
```

## Character Art Direction

V14 仍然必须是“元素像素风横版角色人物”，不是抽象符号，不是图标，不是法术标记。

必须保留：

- 年轻成年剑修，清瘦修长比例。
- 深青黑外袍。
- 冷白内衫。
- 古金腰带。
- 古金袖口。
- 冷白青蓝披帛。
- 黑发束起，有明确发髻或发束轮廓。
- 小脸克制，但必须有头脸结构。
- 双臂、双腿、长袍衣摆都必须可读。

风格关键词：

```text
元素像素风横版角色人物，清晰像素边缘，有限色板，硬边像素块面，深青黑长袍，冷白内衫，古金腰带，古金袖口，冷白青蓝披帛，黑发束起，小脸克制，成人清瘦修长比例，完整人物结构，能看清双臂双腿和服装层次，不是抽象符号，不是图标，不是能量团。
```

## Rig Design Principles

V14 不是完全自由骨骼动画，而是“受控分层 Pose Rig”。

原则：

- 头、躯干、腰带是角色比例锚点，尽量稳定。
- 手臂和袖袍可以旋转、位移，但不要像廉价纸片人一样大幅扭动。
- 披帛、发尾、衣摆适合程序二级运动。
- 阵型切换通过姿态混合实现，不再需要单独序列帧。
- release 和 parry 是短 clip，但仍由同一套部件驱动。
- 所有部件必须有足够重叠区，避免旋转时露缝。

## Required Parts

最低可用拆分：

```text
root
torso
pelvis_belt
head
hair_back
hair_tail
arm_front_upper
arm_front_forearm_sleeve
hand_front
arm_back_upper
arm_back_forearm_sleeve
hand_back
leg_front
leg_back
robe_front
robe_back
sash_front_root
sash_front_mid
sash_front_tip
sash_back_root
sash_back_mid
sash_back_tip
```

说明：

- `torso`：胸腔、肩部、上身衣领。
- `pelvis_belt`：腰带和胯部，是比例锚点，尽量不形变。
- `head`：脸和基础头部。
- `hair_back / hair_tail`：用于风动延迟。
- `arm_front_*`：画面前侧手臂，通常层级在 torso 上方。
- `arm_back_*`：画面后侧手臂，通常层级在 torso 后方。
- `robe_front / robe_back`：长袍下摆和衣摆，用于前后层次。
- `sash_*`：披帛建议拆成 root/mid/tip 三段，方便程序摆动。

可选增强拆分：

```text
collar
robe_left_flap
robe_right_flap
sleeve_front_extra
sleeve_back_extra
hair_front
shadow_contact_soft
```

## Layer Order

建议从后到前：

```text
sash_back_tip
sash_back_mid
sash_back_root
hair_back
arm_back_upper
arm_back_forearm_sleeve
hand_back
leg_back
robe_back
torso
pelvis_belt
leg_front
robe_front
head
hair_tail
hair_front
arm_front_upper
arm_front_forearm_sleeve
hand_front
sash_front_root
sash_front_mid
sash_front_tip
```

实际实现时可按遮挡效果微调。

## Pivot Rules

每个部件必须有明确旋转轴点：

- `root`：角色脚下御剑站位锚点，工作分辨率 `x=256, y=438`。
- `torso`：腰部中心。
- `pelvis_belt`：腰带中心。
- `head`：颈部连接点。
- `hair_tail`：发束根部。
- `arm_front_upper`：前侧肩关节。
- `arm_front_forearm_sleeve`：前侧肘关节。
- `hand_front`：前侧腕关节。
- `arm_back_upper`：后侧肩关节。
- `arm_back_forearm_sleeve`：后侧肘关节。
- `hand_back`：后侧腕关节。
- `leg_front`：前侧髋部。
- `leg_back`：后侧髋部。
- `robe_front / robe_back`：腰带下缘。
- `sash_*_root`：披帛根部。
- `sash_*_mid`：上一段末端。
- `sash_*_tip`：上一段末端。

`body_v14_rig_exploded_parts_pivot_guide.png` 允许用彩色小点标记轴点：

- 红点：父级连接点。
- 黄点：当前部件旋转轴。
- 蓝点：子级连接点。

注意：pivot guide 可以有标记和英文名，clean 图不能有任何标记。

## Image 1: Master Full Character

文件：

```text
body_v14_master_full.png
```

用途：

- 锁定角色最终风格。
- 锁定头部大小、肩宽、腰带高度、披帛长度、服装层次。
- 后续所有部件都必须从这张角色延展。

Prompt：

```text
生成一张中国修仙题材横版御剑人物 body 完整角色母版图，透明背景，元素像素风横版角色人物。

工作规格：512x512，角色朝右，侧视，完整人物站在画面中央。脚下御剑站位锚点约 x=256, y=438，但不要画御剑平台。

角色：年轻成年剑修，清瘦修长但有力量感，非 Q 版，非大头。深青黑外袍，冷白内衫，古金腰带和袖口，冷白青蓝披帛，黑发束起，脸部小而克制。

风格：清晰像素边缘，有限色板，硬边像素块面，少量像素高光。不是抽象符号，不是图标，不是能量团，不是写实厚涂。缩小到游戏内尺寸后仍能看清头发、脸部、长袍、腰带、袖口、披帛、双臂、双腿。

姿态：普通御剑悬停 idle，身体稳定，双腿自然分开，双臂自然但不要贴死身体，袖袍和披帛有清楚轮廓，便于后续拆层。

禁止：手持剑，御剑平台，完整剑阵，大型特效，复杂背景，地面阴影，文字，水印，Q版化，厚涂，柔光糊边，抽象化。
```

## Image 2: Exploded Parts Clean

文件：

```text
body_v14_rig_exploded_parts_clean.png
```

用途：

- 切出 runtime rig 使用的透明 PNG 部件。
- 这是最重要的生产图。

建议规格：

- `2048 x 2048` 或更大。
- 透明背景。
- 每个部件独立摆放，部件之间留足间距。
- 不要文字、不要编号、不要轴点标记。

Prompt：

```text
基于 body_v14_master_full 的同一个角色，生成角色分层 rig 的 exploded parts clean 图，透明背景。

画面规格：2048x2048，透明背景。把同一个角色拆成独立部件平铺展示，每个部件之间留出足够空白，不能相互接触。不要文字、不要编号、不要网格、不要轴点标记。

必须保持同一个角色的像素风格、色板和服装元素：深青黑外袍，冷白内衫，古金腰带，古金袖口，冷白青蓝披帛，黑发束起，小脸克制。

需要绘制这些独立部件：
torso 上身衣领和肩部
pelvis_belt 腰带和胯部
head 头和脸
hair_back 后发
hair_tail 束发尾
arm_front_upper 前侧上臂
arm_front_forearm_sleeve 前侧前臂和袖袍
hand_front 前侧手
arm_back_upper 后侧上臂
arm_back_forearm_sleeve 后侧前臂和袖袍
hand_back 后侧手
leg_front 前侧腿
leg_back 后侧腿
robe_front 前侧衣摆
robe_back 后侧衣摆
sash_front_root 前侧披帛根部
sash_front_mid 前侧披帛中段
sash_front_tip 前侧披帛末端
sash_back_root 后侧披帛根部
sash_back_mid 后侧披帛中段
sash_back_tip 后侧披帛末端

部件要求：
- 每个部件必须像从同一个完整角色上拆出来，不要重新设计。
- 关节处保留 8-16px 的隐藏重叠区域，避免旋转时露缝。
- 袖袍、披帛、衣摆要有完整轮廓，不要被裁切。
- 手臂部件要能围绕肩、肘、腕轻微旋转。
- 披帛三段要能首尾连接。

禁止：重新设计服装，改变色板，画武器，画御剑平台，画完整剑阵，画大型特效，画背景，画文字，画编号，画网格，画轴点。
```

## Image 3: Exploded Parts Pivot Guide

文件：

```text
body_v14_rig_exploded_parts_pivot_guide.png
```

用途：

- 给技术美术和代码标记切图、父子层级、旋转轴。
- 不进游戏。

Prompt：

```text
基于 body_v14_rig_exploded_parts_clean 的同一布局，生成一张 pivot guide 标注图。

要求：保持 clean 图中所有部件的位置和外形完全一致。允许添加英文部件名、父子连接线、彩色轴点。

标记规则：
红点表示父级连接点。
黄点表示当前部件旋转轴。
蓝点表示子级连接点。

需要标注每个部件名称：
torso, pelvis_belt, head, hair_back, hair_tail,
arm_front_upper, arm_front_forearm_sleeve, hand_front,
arm_back_upper, arm_back_forearm_sleeve, hand_back,
leg_front, leg_back, robe_front, robe_back,
sash_front_root, sash_front_mid, sash_front_tip,
sash_back_root, sash_back_mid, sash_back_tip.

这张图只用于技术参考，可以有文字和标记，但不要改变角色本体。
```

## Image 4: Pose Bible

文件：

```text
body_v14_pose_bible.png
```

用途：

- 定义运行时 pose。
- 给程序和 AnimationPlayer 制作目标姿态。
- 不是最终序列帧。

建议规格：

- `4列 x 4行`
- 每格 `512 x 512`
- 总尺寸 `2048 x 2048`
- 透明背景或纯白背景均可，最终只作参考。

Prompt：

```text
基于 body_v14_master_full 的同一个角色，生成 V14 body rig pose bible，4列x4行，每格512x512，共16个关键姿态。

角色必须完全一致：头部大小、脸型、发型、肩宽、腰带高度、袖口颜色、披帛长度、服装色板一致。每个姿态都是同一个角色，不要重新设计。

风格：元素像素风横版角色人物，清晰像素边缘，有限色板，硬边像素块面。

姿态内容：
1 idle 普通御剑悬停
2 forward 弓步前倾，双腿岔开
3 back 双腿岔开后仰制动
4 sword_control_idle 远控飞剑手诀
5 array_ring_idle 怀抱守圆
6 array_fan_idle 双臂展开控面
7 array_pierce_idle 单指凝线
8 parry_ready 弹反起手
9 parry_peak 弹反爆发峰值
10 parry_recover 弹反收势
11 array_ring_release_peak 环阵推出峰值
12 array_fan_release_peak 扇阵推出峰值
13 array_pierce_release_peak 贯穿指向释放峰值
14 ring_to_fan_mid 怀抱打开到扇面的中间姿态
15 fan_to_pierce_mid 双臂控面收束到指向的中间姿态
16 pierce_to_ring_mid 指向撤回到守圆的中间姿态

锚点：每格脚下御剑站位锚点约 x=256, y=438。不要画御剑平台。

禁止：手持剑，完整剑阵，大型特效，复杂背景，文字水印，Q版化，抽象符号化，人物比例漂移。
```

## Image 5: Layering Preview

文件：

```text
body_v14_layering_preview.png
```

用途：

- 检查 exploded parts 能否重新组成完整角色。
- 检查遮挡层级、披帛、袖袍、衣摆是否合理。

Prompt：

```text
基于 body_v14_rig_exploded_parts_clean 的所有部件，重新组装出同一个角色的 4 个预览姿态。

画面：4列x1行，每格512x512，透明背景或纯白背景。

姿态：
1 idle
2 sword_control_idle
3 array_ring_idle
4 array_fan_idle

要求：必须像由同一套分层部件组装出来。头部、躯干、腰带大小完全一致。可以轻微移动和旋转手臂、披帛、衣摆，但不要重画成新角色。

目的：检查分层部件是否足够完整，是否会露缝，是否能支持御剑和阵型姿态。
```

## Runtime Pose Set

持续状态：

```text
idle
forward
back
sword_control_idle
array_ring_idle
array_fan_idle
array_pierce_idle
```

一次性动作：

```text
parry
array_ring_release
array_fan_release
array_pierce_release
```

程序过渡：

```text
idle <-> sword_control_idle
idle <-> array_ring_idle
idle <-> array_fan_idle
idle <-> array_pierce_idle
array_ring_idle <-> array_fan_idle
array_fan_idle <-> array_pierce_idle
array_pierce_idle <-> array_ring_idle
array_ring_idle <-> array_pierce_idle
```

V14 不需要为这些过渡生成完整序列帧。程序直接在两个 pose 之间 blend。

## Recommended Pose Parameters

`body_v14_pose_library.json` 建议描述这些属性：

```json
{
  "pose_name": {
    "part_name": {
      "position": [0, 0],
      "rotation_degrees": 0,
      "scale": [1, 1],
      "z_index": 0
    }
  }
}
```

每个 pose 至少包含：

- `torso`
- `pelvis_belt`
- `head`
- `arm_front_upper`
- `arm_front_forearm_sleeve`
- `hand_front`
- `arm_back_upper`
- `arm_back_forearm_sleeve`
- `hand_back`
- `leg_front`
- `leg_back`
- `robe_front`
- `robe_back`
- `sash_front_root/mid/tip`
- `sash_back_root/mid/tip`

## Programmatic Secondary Motion

推荐运行时程序控制：

头发：

- 根据玩家速度反向滞后。
- `hair_tail` 延迟最大。
- 上下移动时有轻微垂坠和上浮。

披帛：

- 拆成 root/mid/tip 链。
- tip 延迟最大。
- 向前飞时向后拉。
- 向上飞时向下拖。
- 向下飞时向上浮。
- release 时短暂向后甩，再回弹。

袖袍：

- 跟随手臂 pose。
- release 和 parry 时增加一点摆动延迟。
- 不要自由乱甩，幅度要受动作强度限制。

衣摆：

- forward 时后摆。
- back 时前浮。
- idle 时小幅呼吸。

## Godot Node Proposal

建议新建：

```text
scripts/vfx/flight_rider_body_rig_fx.gd
```

节点结构：

```text
FlightRiderBodyRigFx
  Root
    SashBackTip
    SashBackMid
    SashBackRoot
    HairBack
    ArmBackUpper
    ArmBackForearmSleeve
    HandBack
    LegBack
    RobeBack
    Torso
    PelvisBelt
    LegFront
    RobeFront
    Head
    HairTail
    HairFront
    ArmFrontUpper
    ArmFrontForearmSleeve
    HandFront
    SashFrontRoot
    SashFrontMid
    SashFrontTip
```

状态解析可以复用当前 `FlightRiderSpriteFx` 的逻辑：

- 右键御剑中或飞剑未回收：`sword_control_idle`
- 左键剑阵中：`array_${mode}_idle`
- 否则按速度：`forward / back / idle`
- parry 和 release 是 timed action。

## Acceptance Criteria

AI 图像验收：

- `body_v14_master_full.png` 必须是完整角色，不是抽象符号。
- `body_v14_rig_exploded_parts_clean.png` 每个部件都必须来自同一角色。
- 部件之间不能互相接触，方便切图。
- 关节处必须有隐藏重叠区。
- 腰带、袖口、披帛、头发必须保持同一色板。
- pivot guide 必须能看懂每个部件轴点。
- pose bible 中 16 个姿态必须是同一角色比例。

运行时验收：

- idle、御剑、三阵型之间切换不再像换人。
- ring -> fan 是怀抱打开到双臂控面。
- fan -> pierce 是双臂收束到单指凝线。
- pierce -> ring 是指向撤回到怀抱守圆。
- release 播放后自然回到当前阵型状态。
- 披帛、头发、袖袍能根据飞行方向自然摆动。
- 不出现明显纸片感、部件露缝、关节断裂。

## First Prototype Scope

不要一上来做全量完美系统。建议第一版 V14 prototype 只做：

1. `body_v14_master_full.png`
2. `body_v14_rig_exploded_parts_clean.png`
3. `body_v14_rig_exploded_parts_pivot_guide.png`
4. Godot 中组装 idle pose
5. 做 `idle -> sword_control_idle -> array_ring_idle -> array_fan_idle -> array_pierce_idle` 的姿态切换
6. 披帛和头发做最简单的速度滞后

第一版不需要：

- 完整 release。
- 完整 parry。
- 离线导出 sprite sheet。
- 所有布料变体。

先验证：

```text
分层角色是否像同一个人？
阵型切换是否比序列帧顺？
披帛和头发是否自然？
像素风旋转是否能接受？
```

这四点通过后，再补齐 parry、release 和高级布料。

## Notes For AI Workers

- 不要再生成完整 16 帧 body 序列帧作为 V14 源资产。
- 不要把部件画成新角色。所有部件都必须像从同一个 master_full 上拆出来。
- clean parts 图不能带文字、编号、轴点、网格。
- pivot guide 可以带文字和点，但不能进游戏。
- pose bible 是姿态参考，不是最终 runtime 图集。
- 角色一致性比单张图好看更重要。
