# 御剑人物 Body 状态机与重绘任务包 V12

## Summary

本任务包用于修复当前御剑人物 body 动画的两个核心问题：

- 状态动作僵硬：持续御剑、环阵、扇阵、贯穿阵目前能读出来，但缺少自然呼吸和稳定的状态质感。
- 切换动作生硬：阵型切换和释放动作来自旧素材拼接，动作意图不够明确，容易像硬切或闪帧。

V12 不重新设计角色，不改武器、御剑平台、大型剑阵 VFX。本轮只优化 body 动画资产和对应状态机语义。

最终目标：

- 每个持续状态都有自己的慢速保持动作。
- 每个阵型切换都是从一个明确姿态移动到另一个明确姿态。
- 每个释放动作是可读的短脉冲，播放后回到当前阵型保持动作。
- 运行时仍使用固定图集结构，避免大改代码。

## Current Runtime Contract

保持当前 V10/V11 图集结构不变，只生成 V12 版本资源。

主动作图集：

- 文件：`resources/flight/rider/flight_rider_body_v12_sheet.png`
- 尺寸：`2048 x 2816`
- 切片：`8列 x 11行`
- 单格：`256 x 256`
- 背景：最终必须透明

主动作行顺序固定：

1. `idle`
2. `forward`
3. `back`
4. `parry`
5. `sword_control_idle`
6. `array_ring_idle`
7. `array_fan_idle`
8. `array_pierce_idle`
9. `array_ring_release`
10. `array_fan_release`
11. `array_pierce_release`

过渡图集：

- 文件：`resources/flight/rider/flight_rider_body_v12_transitions.png`
- 尺寸：`2048 x 3584`
- 切片：`8列 x 14行`
- 单格：`256 x 256`
- 背景：最终必须透明

过渡行顺序固定：

1. `idle_to_sword_control`
2. `sword_control_to_idle`
3. `idle_to_array_ring`
4. `array_ring_to_idle`
5. `idle_to_array_fan`
6. `array_fan_to_idle`
7. `idle_to_array_pierce`
8. `array_pierce_to_idle`
9. `array_ring_to_fan`
10. `array_fan_to_ring`
11. `array_fan_to_pierce`
12. `array_pierce_to_fan`
13. `array_pierce_to_ring`
14. `array_ring_to_pierce`

## State Machine Meaning

V12 的资产必须围绕状态机语义制作，不要把所有动作都当成一次性技能。

持续状态：

- `idle`：普通御剑悬停，没有控剑、没有剑阵。
- `forward`：向前推进姿态。
- `back`：后退/制动姿态。
- `sword_control_idle`：右键御剑持续控剑状态，只要飞剑离手或右键控剑中就保持。
- `array_ring_idle`：环阵持续状态，怀抱、护体、守圆。
- `array_fan_idle`：扇阵持续状态，双臂打开、控面、清场。
- `array_pierce_idle`：贯穿阵持续状态，指向、凝线、破线。

一次性事件：

- `parry`：普通攻击/弹反 body 动作，短但必须看清起手、爆发、收势。
- `array_ring_release`：环阵释放脉冲，结束后回到 `array_ring_idle`。
- `array_fan_release`：扇阵释放脉冲，结束后回到 `array_fan_idle`。
- `array_pierce_release`：贯穿阵释放脉冲，结束后回到 `array_pierce_idle`。

过渡事件：

- 只在进入御剑、退出御剑、进入阵型、退出阵型、阵型之间切换时播放。
- 过渡播放完毕后，必须落到目标持续状态。
- 过渡动作幅度可以比 idle 大，但第 1 帧要接近来源状态，第 8 帧要接近目标状态。

## Asset Source Directory

新素材源文件建议放在：

```text
resources/flight/rider/body_v12_sources/
resources/flight/rider/body_v12_transitions/
```

主动作源条命名：

```text
body_v12_main_idle_8.png
body_v12_main_forward_8.png
body_v12_main_back_8.png
body_v12_main_parry_8.png
body_v12_main_sword_control_idle_8.png
body_v12_main_array_ring_idle_8.png
body_v12_main_array_fan_idle_8.png
body_v12_main_array_pierce_idle_8.png
body_v12_main_array_ring_release_8.png
body_v12_main_array_fan_release_8.png
body_v12_main_array_pierce_release_8.png
```

过渡源条命名：

```text
body_v12_transition_idle_to_sword_control_8.png
body_v12_transition_sword_control_to_idle_8.png
body_v12_transition_idle_to_array_ring_8.png
body_v12_transition_array_ring_to_idle_8.png
body_v12_transition_idle_to_array_fan_8.png
body_v12_transition_array_fan_to_idle_8.png
body_v12_transition_idle_to_array_pierce_8.png
body_v12_transition_array_pierce_to_idle_8.png
body_v12_transition_array_ring_to_fan_8.png
body_v12_transition_array_fan_to_ring_8.png
body_v12_transition_array_fan_to_pierce_8.png
body_v12_transition_array_pierce_to_fan_8.png
body_v12_transition_array_pierce_to_ring_8.png
body_v12_transition_array_ring_to_pierce_8.png
```

## Generation Priorities

优先级 1：必须重绘

- `sword_control_idle`
- `array_ring_idle`
- `array_fan_idle`
- `array_pierce_idle`
- `array_ring_to_fan`
- `array_fan_to_ring`
- `array_fan_to_pierce`
- `array_pierce_to_fan`
- `array_pierce_to_ring`
- `array_ring_to_pierce`

优先级 2：强烈建议重绘

- `array_ring_release`
- `array_fan_release`
- `array_pierce_release`
- `idle_to_sword_control`
- `sword_control_to_idle`
- `idle_to_array_ring`
- `array_ring_to_idle`
- `idle_to_array_fan`
- `array_fan_to_idle`
- `idle_to_array_pierce`
- `array_pierce_to_idle`

优先级 3：如果时间允许再重绘

- `idle`
- `forward`
- `back`
- `parry`

## Global Art Rules

每条动画都必须遵守：

- 同一角色，不重新设计人物。
- 横版侧视，角色朝右。
- 成人修仙剑修比例，不要 Q 版，不要大头。
- body only，不画手持剑、不画御剑平台、不画完整剑阵、不画大型拖尾。
- 可以有衣袖、头发、披帛的轻微自然运动。
- 不要复杂背景、文字、水印、地面阴影。
- 最终交付透明 PNG。如果生成工具透明不稳定，可以先用纯白背景出源图，但最终必须抠成透明。
- 锚点固定：脚下御剑站位锚点 `x=128, y=219`，误差不超过 `2px`。
- 不通过整体缩放表现动作。
- 同一条持续状态里，头部尺寸变化不超过 `1px`，身体高度变化不超过 `2px`。
- 持续状态是慢呼吸，不是技能动作。

## Sustained State Prompts

### sword_control_idle

```text
基于提供的角色母版，生成 sword_control_idle 御剑持续控剑状态序列帧。

规格：8列x1行，每格256x256，最终透明背景，角色朝右，body only。
锚点固定 x=128, y=219，误差不超过2px。

动作语义：右键御剑持续控剑状态。人物不是正在拔剑，也不是爆发出招，而是在飞剑离手后持续以手诀远控飞剑。

姿态要求：
- 身体稳定悬停，重心略向前。
- 一手在胸前或身前掐诀，另一手自然协助控剑。
- 袖袍、披帛、发梢只有非常轻微的呼吸和风动。
- 第1帧和第8帧必须几乎相同，可以无缝慢速循环。

逐帧：
1 稳定控剑入口姿态。
2 肩线微微上提，袖口轻浮。
3 手诀向前半步，披帛微扬。
4 控剑呼吸峰值，身体不位移。
5 回落到稳定姿态。
6 袖袍向后慢摆。
7 接近第1帧。
8 与第1帧近似闭环。

禁止：出鞘大动作、挥剑、剑光爆发、角色变脸、服装变款、身体跳动、整体缩放。
```

### array_ring_idle

```text
基于提供的角色母版，生成 array_ring_idle 环阵持续状态序列帧。

规格：8列x1行，每格256x256，最终透明背景，角色朝右，body only。
锚点固定 x=128, y=219，误差不超过2px。

动作语义：环阵保持状态。角色以怀抱、护体、守圆的姿态维持近身防护阵。

姿态要求：
- 双臂在身前形成收拢的圆意，像抱住一圈无形剑阵。
- 肩膀略收，身体稳定，气质是防守和守势。
- 动作幅度很小，只表现呼吸、袖口、披帛轻动。
- 第1帧和第8帧必须闭环。

逐帧：
1 怀抱守圆基准姿态。
2 呼吸轻起，手肘不大幅移动。
3 袖口微浮，头发轻动。
4 守圆气息最满，但仍然稳定。
5 呼吸回落。
6 披帛轻轻下沉。
7 回到基准姿态附近。
8 与第1帧近似闭环。

禁止：双臂大开、指向攻击、释放爆发、阵法图案、完整飞剑阵。
```

### array_fan_idle

```text
基于提供的角色母版，生成 array_fan_idle 扇阵持续状态序列帧。

规格：8列x1行，每格256x256，最终透明背景，角色朝右，body only。
锚点固定 x=128, y=219，误差不超过2px。

动作语义：扇阵保持状态。角色双臂打开，维持中距离扇面控场。

姿态要求：
- 双臂比环阵明显展开，像把无形剑阵铺成扇面。
- 胸口打开，肩线展开，身体仍然稳定。
- 手掌或手诀朝外，读作控面，不是释放爆发。
- 第1帧和第8帧必须闭环。

逐帧：
1 双臂展开控面基准姿态。
2 手腕和袖口轻微外展。
3 披帛随气流微微后拉。
4 扇面维持峰值，身体不位移。
5 手腕回落一点。
6 袖袍轻摆。
7 接近基准姿态。
8 与第1帧近似闭环。

禁止：怀抱守圆、单指贯穿、释放强光、身体左右跳动。
```

### array_pierce_idle

```text
基于提供的角色母版，生成 array_pierce_idle 贯穿阵持续状态序列帧。

规格：8列x1行，每格256x256，最终透明背景，角色朝右，body only。
锚点固定 x=128, y=219，误差不超过2px。

动作语义：贯穿阵保持状态。角色以凝线、指向、破线的姿态维持远距离贯穿阵。

姿态要求：
- 一手向前指或剑指，另一手收在身侧或胸前稳定气机。
- 身体可以略向前，但不要趴伏。
- 姿态要像持续瞄准和凝线，不是一次性发射。
- 第1帧和第8帧必须闭环。

逐帧：
1 指向凝线基准姿态。
2 指尖微微前探。
3 袖口和披帛轻轻后浮。
4 凝线气息最集中，身体稳定。
5 指尖微回。
6 披帛轻落。
7 接近基准姿态。
8 与第1帧近似闭环。

禁止：双臂大开、怀抱守圆、大幅发射、剑光贯穿特效、角色缩放。
```

## Release Prompts

释放动作必须是短脉冲，但不能闪烁。每条 release 的第1帧和第8帧必须接近对应 idle。

### array_ring_release

```text
生成 array_ring_release 环阵释放序列帧，8列x1行，每格256x256，最终透明背景，角色朝右，body only。

第1帧接近 array_ring_idle，第8帧回到 array_ring_idle。
动作语义：从怀抱守圆姿态向外推出一次近身护体冲击，然后收回守圆。

逐帧：
1 环阵怀抱守圆。
2 双臂微微压缩蓄力。
3 袖口向外推开。
4 近身守圆释放峰值。
5 力量外推后开始回收。
6 手臂回到怀抱轨迹。
7 接近守圆。
8 回到 array_ring_idle。

禁止：变成扇阵双臂大开、变成贯穿指向、画完整剑阵或长拖尾。
```

### array_fan_release

```text
生成 array_fan_release 扇阵释放序列帧，8列x1行，每格256x256，最终透明背景，角色朝右，body only。

第1帧接近 array_fan_idle，第8帧回到 array_fan_idle。
动作语义：从双臂打开的控面姿态向前方扇面推出一次清场脉冲，然后回到控面。

逐帧：
1 扇阵双臂展开控面。
2 双手略向内收，准备推面。
3 双臂向外展开推动。
4 扇面释放峰值，肩线最打开。
5 推力通过，袖袍后摆。
6 手臂回到控面宽度。
7 接近基准控面。
8 回到 array_fan_idle。

禁止：收成环阵、单指贯穿、身体大跳、爆闪。
```

### array_pierce_release

```text
生成 array_pierce_release 贯穿阵释放序列帧，8列x1行，每格256x256，最终透明背景，角色朝右，body only。

第1帧接近 array_pierce_idle，第8帧回到 array_pierce_idle。
动作语义：从凝线指向姿态向前刺出一次贯穿脉冲，然后恢复持续指向。

逐帧：
1 贯穿阵指向凝线。
2 指尖微收，肩线蓄力。
3 身体略向前压。
4 指向释放峰值，线性意图最强。
5 力量穿出，袖袍后拉。
6 身体回稳。
7 接近持续指向。
8 回到 array_pierce_idle。

禁止：双臂大开成扇阵、怀抱成环阵、画长激光、角色趴伏。
```

## Transition Prompts

每条过渡都是 8 帧。第1帧接近来源状态，第8帧接近目标状态。

通用要求：

```text
基于提供的角色母版和来源/目标状态参考，生成【来源】到【目标】的过渡序列帧。
规格：8列x1行，每格256x256，最终透明背景，角色朝右，body only。
锚点固定 x=128, y=219，误差不超过2px。
第1帧必须接近【来源】状态，第8帧必须接近【目标】状态。
过渡只改变身体重心、肩线、手势、袖袍、披帛，不使用整体缩放或平移。
禁止角色变脸、服装变款、头部忽大忽小、复杂背景、武器、御剑平台、完整剑阵。
```

核心阵型切换：

- `array_ring_to_fan`：怀抱守圆逐渐打开成双臂控面。第3-6帧是打开过程，第8帧落到扇阵。
- `array_fan_to_ring`：双臂控面逐渐收回成怀抱守圆。第3-6帧是收势过程，第8帧落到环阵。
- `array_fan_to_pierce`：双臂控面收束成单指凝线。第3-5帧双臂向中线聚拢，第8帧落到贯穿。
- `array_pierce_to_fan`：单指凝线撤回并打开成扇面。第3-6帧从指向扩展，第8帧落到扇阵。
- `array_pierce_to_ring`：单指凝线撤回，双手收成护体圆。第8帧落到环阵。
- `array_ring_to_pierce`：怀抱守圆压缩后向前凝线。第8帧落到贯穿。

进入/退出状态：

- `idle_to_sword_control`：普通悬停进入远控飞剑手诀。
- `sword_control_to_idle`：远控飞剑手诀回到普通悬停。
- `idle_to_array_ring`：普通悬停收手成怀抱守圆。
- `array_ring_to_idle`：怀抱守圆放松回普通悬停。
- `idle_to_array_fan`：普通悬停打开双臂成扇阵。
- `array_fan_to_idle`：扇阵双臂收回普通悬停。
- `idle_to_array_pierce`：普通悬停凝出指向姿态。
- `array_pierce_to_idle`：指向姿态放松回普通悬停。

## Runtime Integration Rules

尽量不改状态名和行顺序。V12 接入优先使用同一套状态机，只替换图集路径。

推荐接入：

- `FlightRiderSpriteFx.DEFAULT_BODY_SHEET` 指向 `flight_rider_body_v12_sheet.png`。
- `FlightRiderSpriteFx.DEFAULT_BODY_TRANSITION_SHEET` 指向 `flight_rider_body_v12_transitions.png`。
- `BODY_ACTION_ROWS` 和 `BODY_TRANSITION_ROWS` 不变。
- `sword_control_idle_animation_fps` 保持慢速，建议 `3.0 - 4.0fps`。
- `array_idle_animation_fps` 保持极慢，建议 `1.5 - 2.5fps`。
- 阵型过渡时长建议 `0.50 - 0.65s`。
- 释放动作时长建议 `0.45 - 0.60s`。
- 普通攻击 body 表现建议 `0.30 - 0.38s`，不要影响真实判定。

## Acceptance Criteria

主动作验收：

- `flight_rider_body_v12_sheet.png` 必须是 `2048 x 2816`。
- 每格 `256 x 256`，共 `8 x 11`。
- `sword_control_idle` 必须读作持续控剑，不是拔剑或闪现。
- `array_ring_idle` 必须读作怀抱守圆。
- `array_fan_idle` 必须读作双臂展开控面。
- `array_pierce_idle` 必须读作单指凝线。
- 三个阵型 idle 不能互相像同一动作。
- 所有 idle 第1帧和第8帧必须可闭环。

过渡验收：

- `flight_rider_body_v12_transitions.png` 必须是 `2048 x 3584`。
- 每格 `256 x 256`，共 `8 x 14`。
- 每条过渡第1帧接来源状态，第8帧接目标状态。
- `ring -> fan` 必须是怀抱打开。
- `fan -> pierce` 必须是打开收束到指向。
- `pierce -> ring` 必须是指向撤回到守圆。
- 过渡不能出现角色缩放、锚点跳动、变脸或换服装。

游戏内验收：

- 右键御剑持续状态不能闪烁，要像慢速控剑呼吸。
- 不按左键但剑阵可用时，阵型状态应能常驻显示当前阵型姿态。
- 切换阵型时先播放过渡，过渡后稳定保持目标阵型。
- 发射时播放对应 release，结束后回到当前阵型 idle。
- 普通攻击 body 动作能看清，不因为判定短而一闪而过。
- 缩到游戏内尺寸后，姿态语义仍然清楚。

## Suggested Work Order

1. 先生成 4 条持续状态：`sword_control_idle`、`array_ring_idle`、`array_fan_idle`、`array_pierce_idle`。
2. 在游戏内只替换这 4 行做预览，确认状态语义成立。
3. 再生成 6 条核心阵型切换：`ring/fan/pierce` 双向过渡。
4. 再生成 3 条 release。
5. 最后补齐进入/退出：`idle_to_*` 和 `*_to_idle`。
6. 全部通过后拼成 V12 主图集和 V12 过渡图集。

## Notes

- 如果 AI 只能一次生成 `3x3`，第9格用于重复第1帧或留空；最终切图时只取前8帧。
- 如果 AI 只能一次生成白底图，允许白底源图，但交付前必须抠成透明。
- 不建议继续从旧 `array_morph` 拼持续状态。旧素材适合临时验证，不适合最终手感。
- 如果状态帧本身不稳定，不要靠运行时降 FPS 强行修复。正确做法是重画状态帧。
- 这次目标是让状态动作“站得住”，过渡动作“看得懂”，释放动作“来得及看见”。
