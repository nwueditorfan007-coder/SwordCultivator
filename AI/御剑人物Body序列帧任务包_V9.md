# 御剑人物 Body 序列帧任务包 V9

## 1. 目标

本任务包用于生成当前御剑飞行模式的人物 body 序列帧。产出分为两类：

- 运行表：`flight_rider_body_v9_sheet.png`，`2048 x 1792`，`8 列 x 7 行`，每格 `256 x 256`。
- 过渡源表：每条过渡单独一张 `2048 x 256`，`8 列 x 1 行`，只作为制作源和后续扩展素材。

本轮只生成 body。不要画手持剑、御剑平台、完整剑阵、长拖尾或大型 VFX。当前 Godot 运行时只接主动作运行表，过渡帧先不接入代码。

## 2. 固定规格

运行表行顺序固定：

1. `idle`
2. `forward`
3. `back`
4. `parry`
5. `unsheath`
6. `array_release`
7. `array_morph`

注意：上面是当前 `FlightRiderSpriteFx` 已经能读取的旧 7 行运行表。经过运行时代码审计，当前玩法实际需要把 `array_morph` 拆成阵型持续状态与阵型切换过渡；把 `unsheath` 理解为右键御剑持续状态；把 `array_release` 理解为释放脉冲，而不是一个永久待机行。第 7 节按这个修正版状态机组织。

硬规格：

- 每格 `256 x 256`，透明背景。
- 角色朝右，横版侧视。
- body sheet 总尺寸 `2048 x 1792`。
- 单条主动作或过渡源表尺寸 `2048 x 256`。
- 人物脚底/御剑站位锚点固定在 `x=128, y=219`，误差不超过 `2px`。
- 不用整体缩放、整体平移、拉伸或透视变形表现动作。
- 头部尺寸变化不超过 `1px`，腰带高度变化不超过 `2px`。
- 缩到游戏内 `0.72` 视觉缩放后，人物仍然像同一个成年剑修。

高度目标：

- `idle`：`166-170px`。
- `forward`：`145-155px`，修长前倾，不趴伏。
- `back`：`150-160px`。
- `parry / unsheath / array_release / array_morph`：`158-172px`。
- 同一动作行内高度变化一般不超过 `3px`。

## 3. 角色规格母版 Prompt

```text
生成一张中国修仙题材横版御剑人物 body 角色规格母版图，透明背景，像素风。

角色：年轻成年剑修，清瘦修长比例，不是 Q 版，不是大头角色。深青黑外袍，内层冷白长衫，古金腰带和袖口，冷白青蓝剑气披帛，黑发束起，脸部小而克制，肩宽、腰带、袖口、披帛剪影清楚。

母版内容：同一个角色的四个参考姿态并排展示：
1 idle 正常御剑悬停站姿。
2 forward extreme 向右修长前倾加速姿态，高度约 145-155px，不趴伏。
3 back extreme 后压减速姿态，高度约 150-160px。
4 combat-ready 战斗/施法预备姿态，高度约 158-172px。

同时在画面角落展示服装局部色板：头发、皮肤、深青黑外袍、冷白内衫、古金腰带、袖口、青蓝披帛。

用途：这张图作为后续所有主动作和过渡动作的唯一角色规格参考。必须固定角色比例、头部大小、脸型、肩宽、腰带位置、袖口颜色、披帛形状、主色板和像素风格。

锚点：每个姿态脚底/御剑站位锚点固定在单格 x=128, y=219 附近。透明背景，不画御剑平台。

禁止项：手持剑，飞剑平台，完整剑阵，长拖尾，大型特效，写实厚涂，RPGMaker 俯视角，大头 Q 版，现代科幻装备，复杂背景，地面阴影，文字，水印，角色比例夸张。
```

## 4. 通用主动作 Prompt 模板

```text
基于提供的角色规格母版，生成【动作名】主动作序列帧。

输出规格：8 列 x 1 行，每格 256 x 256，整图 2048 x 256，透明背景。

必须保持同一个角色：头部大小、发型、脸型、肩宽、腰带位置、袖口颜色、披帛形状、主色板完全一致，不要重新设计角色。

锚点规则：每格脚底/御剑站位锚点固定在 x=128, y=219，误差不超过 2px。不要让人物在单元格内上下乱跳，不要通过整体缩放、拉伸、平移表现动作。

body only：不要画手持剑，不要画御剑平台，不要画完整剑阵，不要画长拖尾，不要画大型 VFX。只允许少量贴身剑气或手势引导光。

动作节奏：
【填写 1-8 帧节奏】

高度规则：
【填写该动作高度范围】

风格：清晰像素边缘，有限色板，低抗锯齿或无抗锯齿。缩小到游戏内尺寸后轮廓仍然清楚。

禁止项：角色变脸，头部变大或变小，服装变款式，色板漂移，锚点漂移，动作跳帧，复杂背景，文字，水印，Q 版化，柔光糊边，厚涂。
```

## 5. 主动作逐帧规格

### idle

```text
动作节奏：
1 标准悬停，身体直立，双袖自然垂落。
2 头发和披帛轻微后摆，肩线不变。
3 袖袍下摆轻抬，腰带位置稳定。
4 呼吸最高点，身体只允许 1px 以内微动。
5 回落到中位，披帛继续缓动。
6 袍角轻落，头部尺寸不变。
7 接近第 1 帧，手势和肩线回稳。
8 与第 1 帧无缝相接。

高度规则：视觉高度 166-170px。
```

### forward

```text
动作节奏：
1 从站姿进入修长前倾，胸口向右压，脚底锚点不动。
2 肩线继续向右下倾，披帛向左后拉。
3 加速主姿态，身体最长，袍角向后打开。
4 速度峰值，头部仍保持同样大小，不能趴伏。
5 稳定高速姿态，手臂贴身减少风阻。
6 袍角回弹一点，身体不抬高。
7 接近第 3 帧姿态，形成循环。
8 接第 1 帧或第 3 帧都不能跳。

高度规则：视觉高度 145-155px，读作修长前倾加速，不读作变矮。
```

### back

```text
动作节奏：
1 从站姿后压，胸口向左后收。
2 前手略抬成防备，披帛和袍角向右前浮。
3 减速主姿态，重心后坐但脚底锚点不动。
4 后压峰值，肩线向左后倾，脸型不变。
5 保持减速姿态，袖袍被气流顶起。
6 身体略回正，披帛继续向前飘。
7 接近第 2 帧。
8 接第 1 帧或第 3 帧都不能跳。

高度规则：视觉高度 150-160px。
```

### parry

```text
动作节奏：
1 战斗预备，肩线压低，右臂准备挥挡。
2 蓄势后拉，袖袍随手臂向后收。
3 快速起挥，手臂打开，身体只小幅前顶。
4 爆发弹反帧，剑弧由外部武器/VFX 层承担，body 只画最亮手势和袖口动势。
5 余势，披帛和袖袍被挥击带起。
6 收势，肩线回正。
7 身体回到 combat-ready。
8 接近 idle 或下一动作入口。

高度规则：视觉高度 158-172px。
```

### unsheath

```text
动作节奏：
1 手在腰侧起诀，身体稳定。
2 右手向前牵引，左手辅助结印。
3 剑诀拉开，手与身体形成清楚空隙，但不要画剑。
4 牵引峰值，胸口微前压，袖袍向外开。
5 远控维持，手指指向右前。
6 气息回收，披帛轻摆。
7 回到可循环的远控姿态。
8 接近第 5 帧或 idle 入口。

高度规则：视觉高度 158-172px。
```

### array_release

```text
动作节奏：
1 从控阵预备进入，双手收在胸前，阵力聚合感。
2 双袖开始打开，肩线展开。
3 双手向外推，身体仍稳定。
4 推阵峰值，双袖最开，手势最清楚。
5 释放脉冲延续，披帛和袖袍被向外带起。
6 手势开始回收，保持释放姿态。
7 回到可持续发射的控阵姿态。
8 接第 2 帧或 array_morph 入口都不能跳。

高度规则：视觉高度 158-172px。
注意：不要画完整剑阵。只表现袖袍打开、手势外推和少量贴身引导光。
```

### array_morph

```text
动作节奏：
1 环阵守势，双手低镇，身体稳定。
2 换诀扭环，一手上挑，一手下压。
3 横引成扇，肩线轻微旋转，披帛跟随横向节奏。
4 贯阵定线，双手向右前指，身体不乱跳。
5 手诀回旋，袖口形成清楚方向变化。
6 回到中位，阵势仍在变化。
7 接近第 2 帧，准备循环。
8 接第 1 帧无缝。

高度规则：视觉高度 158-172px。
注意：必须和 array_release 区分。array_morph 是连续换势和手诀扭转，不是双袖外推释放。
```

## 6. 过渡源表 Prompt 模板

```text
基于提供的角色规格母版、【来源动作】主动作行和【目标动作】主动作行，生成从【来源动作】切换到【目标动作】的过渡序列帧。

输出规格：8 列 x 1 行，每格 256 x 256，整图 2048 x 256，透明背景。

第 1 帧必须接近【来源动作】的可用姿态，第 8 帧必须接近【目标动作】的第 1 帧或循环入口。中间 6 帧只改变身体重心、肩线、手势、袖袍、披帛和发梢。

锚点规则：每格脚底/御剑站位锚点固定在 x=128, y=219，误差不超过 2px。不要整体缩放、拉伸或平移。

保持同一角色：头部大小、发型、脸型、肩宽、腰带位置、袖口颜色、披帛形状、主色板完全一致。

body only：不要画手持剑，不要画御剑平台，不要画完整剑阵，不要画长拖尾，不要画大型 VFX。

过渡意图：
【填写该条过渡的设计意图】

禁止项：变脸，换服装，头部忽大忽小，锚点漂移，跳帧，复杂背景，文字，水印。
```

## 7. 运行时状态审计与过渡覆盖清单

### 7.1 审计结论

当前玩法不是简单的 `array_morph -> array_release` 单向流程。

- 默认控阵方案是 `distance_aim`：鼠标距离驱动 `ring / fan / pierce`，向外和向内移动都成立，因此需要支持反向切换。
- 手动控阵方案是 `space_toggle`：顺序为 `ring -> fan -> pierce -> ring`，其中 `pierce -> ring` 还有一次特殊回环打击。
- 右键御剑不是一次性 `unsheath`，而是只要右键按住或飞剑未回到身边，就持续播放御剑控剑状态。
- `array_release` 当前代码里既承担开始释放的 timed action，也在 `array_is_firing` 时被当成持续行。修正版资源应拆成“释放脉冲”和“阵型待机/持续控阵”。

### 7.2 修正版持续动作

从现有动作库重组时，优先整理这些持续行：

- `idle`
- `forward`
- `back`
- `sword_control_idle`：右键御剑持续控剑状态，可由原 `unsheath` 的稳定远控帧重组。
- `array_ring_idle`：环阵持续控阵状态，从 `array_morph` 里抽低镇、护体、收势帧重组。
- `array_fan_idle`：扇阵持续控阵状态，从 `array_morph` 里抽横引、展开、横向控势帧重组。
- `array_pierce_idle`：贯穿阵持续控阵状态，从 `array_morph` 里抽前指、定线、收束帧重组。
- `parry`：弹反一次性动作。
- `array_release_pulse`：阵型释放脉冲，播放完回到当前 `array_*_idle`。

### 7.3 必须覆盖的阵型切换

阵型切换源表统一保存到 `resources/flight/rider/body_v9_transitions/`。这些过渡可以从现有帧库抽帧重组，不要求全部重新 AI 生成。

- `body_v9_transition_array_ring_to_fan_8.png`：环阵向外牵开成扇阵。
- `body_v9_transition_array_fan_to_ring_8.png`：扇阵向内收回护体环阵。
- `body_v9_transition_array_fan_to_pierce_8.png`：扇阵收束成贯穿阵。
- `body_v9_transition_array_pierce_to_fan_8.png`：贯穿阵重新展开成扇阵。
- `body_v9_transition_array_pierce_to_ring_8.png`：贯穿阵快速收回成环阵，对应手动 `pierce -> ring` 回环和远距急收。
- `body_v9_transition_array_ring_to_pierce_8.png`：环阵直收成贯穿爆发，只作为共鸣/跳距保险，不作为普通高频切换。

### 7.4 进入、退出与释放脉冲

进入和退出不需要为 `idle / forward / back` 三种移动姿态各做一套。当前资源阶段先做“中性站姿入口”，运行时以后可以按当前移动姿态挑起始帧。

- `body_v9_transition_idle_to_sword_control_8.png`
- `body_v9_transition_sword_control_to_idle_8.png`
- `body_v9_transition_idle_to_array_ring_8.png`
- `body_v9_transition_array_ring_to_idle_8.png`
- `body_v9_transition_idle_to_array_fan_8.png`
- `body_v9_transition_array_fan_to_idle_8.png`
- `body_v9_transition_idle_to_array_pierce_8.png`
- `body_v9_transition_array_pierce_to_idle_8.png`
- `body_v9_transition_array_ring_to_release_8.png`
- `body_v9_transition_array_release_to_ring_8.png`
- `body_v9_transition_array_fan_to_release_8.png`
- `body_v9_transition_array_release_to_fan_8.png`
- `body_v9_transition_array_pierce_to_release_8.png`
- `body_v9_transition_array_release_to_pierce_8.png`

移动基础过渡仍然保留为低优先级素材：`idle <-> forward`、`idle <-> back`、`forward <-> back`。它们不是剑阵状态机的核心，不应挤占阵型待机和阵型切换的制作优先级。

不要生成 7 个旧动作两两之间的全连接过渡。正确做法是按“持续状态 + 一次性动作 + 阵型切换”分层覆盖。

## 8. 文件交付

建议输出文件：

- `resources/flight/rider/flight_rider_body_v9_sheet.png`
- `resources/flight/rider/body_v9_sources/body_v9_master_reference.png`
- `resources/flight/rider/body_v9_sources/body_v9_main_idle_8.png`
- `resources/flight/rider/body_v9_sources/body_v9_main_forward_8.png`
- `resources/flight/rider/body_v9_sources/body_v9_main_back_8.png`
- `resources/flight/rider/body_v9_sources/body_v9_main_parry_8.png`
- `resources/flight/rider/body_v9_sources/body_v9_main_unsheath_8.png`
- `resources/flight/rider/body_v9_sources/body_v9_main_array_release_8.png`
- `resources/flight/rider/body_v9_sources/body_v9_main_array_morph_8.png`
- `resources/flight/rider/body_v9_transitions/body_v9_transition_*_8.png`

运行时默认仍然只需要 `flight_rider_body_v9_sheet.png`。过渡源表不放进运行表。

## 9. 验收命令

导出 PNG 后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_flight_rider_body_assets.ps1 -MainSheet resources/flight/rider/flight_rider_body_v9_sheet.png -TransitionDir resources/flight/rider/body_v9_transitions
```

如果只检查主动作运行表：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_flight_rider_body_assets.ps1 -MainSheet resources/flight/rider/flight_rider_body_v9_sheet.png -SkipTransitions
```

验收重点：

- 主表尺寸必须是 `2048 x 1792`。
- 每帧 bbox 底部必须接近 `y=219`。
- `forward` 必须是 `145-155px` 的修长前倾，不是当前那种过低趴伏。
- `array_release` 和 `array_morph` 不能再相同或近似相同。
- 每条过渡第 1 帧接来源动作，第 8 帧接目标动作。

## 10. 定向修复 Prompt

```text
只修复【动作名/过渡名】这一条 8 帧序列，不要重绘其他动作，不要重新设计角色。

问题：
【填写验收失败点，例如：第4帧锚点下移4px；forward 高度只有132px；array_release 太像 array_morph；第8帧接不上 idle。】

修复要求：
保持同一角色、同一色板、同一锚点 x=128 y=219。只调整失败帧附近的身体重心、肩线、手势、袖袍和披帛。不要画剑、平台、完整剑阵、背景、文字或水印。
```
