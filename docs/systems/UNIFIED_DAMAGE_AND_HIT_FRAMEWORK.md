# 统一伤害与命中框架

## 1. 文档定位

本文档用于定义战斗系统下一阶段的统一伤害与命中框架。

目标不是只修当前 `御剑 / 剑阵 / Boss / 丝线` 的数值问题，而是搭建一套后续可以稳定扩展到以下内容的底层骨架：

- 新武器流派，例如 `重剑`
- 持续接触型武器，例如 `回旋刃`
- 多段命中、穿透、切割、破甲、击韧
- Boss 本体、核心、丝线、护甲等多部位目标
- 后续可能增加的 DoT、护盾、霸体、部位破坏等系统

本文档将作为后续重构 `main.gd` 中分散命中逻辑的直接依据。


## 2. 现状问题

当前项目中的命中与伤害逻辑已经分散在多个位置：

- `scripts/system/main.gd`
  - `_perform_melee_attack()`
  - `_damage_enemies_with_sword()`
  - `_array_sword_hits_enemy()`
- `scripts/system/game_boss_controller.gd`
  - `update_silk_damage()`

这导致了 4 个结构性问题：

1. 普通敌人、Boss 本体、丝线分别使用不同的伤害模型
2. 重复命中节流依赖目标上的全局 `hit_cooldown`，扩展性差
3. 新武器一旦加入，就容易继续复制一套新的特判逻辑
4. Boss 的特殊性容易落成“额外系数”，而不是体现在目标结构上

当前系统还能继续迭代，但如果后续加入 `重剑`、`回旋刃` 等流派，继续沿用现在的写法，复杂度会迅速失控。


## 3. 设计目标

本框架要同时满足以下目标：

1. 所有攻击共享同一套命中与结算流程
2. 所有目标共享同一套受击接口
3. 允许不同武器拥有不同的命中节奏，而不是强行共用一个 `ENEMY_HIT_COOLDOWN`
4. 不再通过 `Boss 专属伤害倍率` 来维持分工
5. Boss 的特殊性应体现在 `目标结构 / 部位 / 窗口 / 韧性` 上
6. 第一版实现尽量兼容当前基于 `Dictionary` 的运行时数据结构，避免一次性推翻现有工程


## 4. 非目标

本框架首版不追求一次性覆盖所有战斗系统。

以下内容不属于第一阶段必须实现的目标：

- 暴击系统
- 属性克制
- 复杂乘区
- 装备词条系统
- 网络同步需求
- 编辑器可视化配置工具

第一阶段的重点是先统一“命中、重击节奏、伤害结算、目标响应”的骨架。


## 5. 核心原则

### 5.1 攻击定义和目标定义分离

攻击只定义“我怎么打”。

目标只定义“我怎么被打”。

攻击不应该关心自己是在打普通敌人、Boss 本体还是丝线；目标也不应该关心自己是被普攻、点刺还是剑阵命中。

### 5.2 重复命中节流属于攻击实例，不属于目标全局状态

当前的全局 `enemy["hit_cooldown"]` 会带来明显限制：

- 同一目标无法同时正确响应多种攻击
- 无法支持“点刺单次命中”和“回旋刃持续接触”并存
- 无法把命中节奏设计成武器特性

因此，后续节流应属于：

- 某个 `攻击实例`
- 对某个 `目标 / 部位`
- 在某段时间内

### 5.3 Boss 特殊性来自目标结构，不来自隐藏倍率

后续不再建议采用：

- `if boss then damage *= x`
- `if silk then another formula`

而应改为：

- Boss 本体拥有自己的受击部位
- 核心只在脆弱期开放
- 丝线主要吃 `切割值`
- 护甲主要吸收 `生命伤害` 但正常承受 `韧性伤害`

### 5.4 持续接触伤害不等于“重复命中冷却为 0”

对于 `回旋刃` 这类“只要接触就持续伤害”的流派，不应直接把 `rehit_interval` 设为 `0` 并按帧重复触发离散命中。

正确实现应为：

- `continuous_contact` 模式
- 以 `damage_per_second * overlap_time` 或固定 tick 频率结算

否则高帧率会自然造成更高伤害，系统会失去稳定性。


## 6. 统一框架总览

后续整个命中结算链条统一为：

1. 攻击系统生成 `AttackInstance`
2. 命中检测系统收集潜在目标
3. `HitRegistry` 判断本次是否允许命中
4. 攻击与目标共同生成 `HitRequest`
5. `DamageResolver` 统一结算各个伤害通道
6. 目标返回 `HitResult`
7. 攻击实例根据结果决定是否继续、穿透、返航、打断或结束

这套链条适用于：

- 普攻
- 点刺
- 连斩
- 剑阵环 / 扇 / 贯
- 重剑
- 回旋刃


## 7. 核心对象

### 7.1 AttackProfile

`AttackProfile` 用于定义一类攻击的静态特征。

它应该描述：

- 这是什么攻击
- 命中的几何形状
- 命中的节流方式
- 造成哪些类型的数值效果
- 是否穿透、是否切割、是否击韧

第一版建议字段如下：

```gdscript
{
	"id": "flying_sword_slice",
	"tags": ["slash", "contact", "flying_sword"],
	"shape": {
		"kind": "segment_sweep",
		"radius": 25.0
	},
	"hit_mode": "instant", # instant / interval / continuous
	"rehit_policy": "interval_per_target", # once_per_instance / once_per_entry / interval_per_target / continuous_contact
	"rehit_interval": 0.05,
	"pierce_targets": 1,
	"channels": {
		"hp": 16.0,
		"poise": 8.0,
		"sever": 4.0
	},
	"effects": {
		"screen_shake": 2.0
	}
}
```

### 7.2 AttackInstance

`AttackInstance` 表示某一次真正出手的运行时对象。

它和 `AttackProfile` 的区别是：

- `AttackProfile` 是模板
- `AttackInstance` 是本次战斗中的实际攻击

第一版建议字段如下：

```gdscript
{
	"id": "attack_1024",
	"profile_id": "flying_sword_slice",
	"owner_id": "player",
	"team": "player",
	"source_node": "sword",
	"spawn_time": 12.34,
	"alive": true,
	"runtime": {
		"pierce_left": 1,
		"elapsed": 0.08
	}
}
```

### 7.3 TargetProfile

`TargetProfile` 描述某类目标的受击规则。

目标不是只有“敌人”一种。后续至少应拆为：

- 普通敌人本体
- Boss 本体
- Boss 核心
- 丝线
- 护甲部位

第一版建议字段如下：

```gdscript
{
	"id": "boss_body",
	"team": "enemy",
	"hurtbox_kind": "body", # body / core / silk / armor
	"hp_pool_key": "boss.health",
	"resource_channel": "hp",
	"armor": 0.0,
	"poise_resist": 20.0,
	"accept_tags": ["slash", "thrust", "array"],
	"requires_state": "" # 例如 vulnerable
}
```

说明：

- `hp_pool_key` 定义这次命中最终写回哪个资源池
- `resource_channel` 定义从 `HitResult.applied_channels` 中取哪个通道来写回
- 普通敌人 / Boss 通常是 `hp -> health`
- 丝线这类可切断部位则可以是 `sever -> silk.health`

### 7.4 Hurtbox

`Hurtbox` 是战场上真正参与碰撞检测的受击体。

一个目标可以有多个 `Hurtbox`：

- `Boss body`
- `Boss core`
- `Silk segment`
- `Heavy armor plate`

`Hurtbox` 负责告诉系统：

- 自己属于哪个目标
- 自己代表哪个部位
- 当前几何形状是什么
- 当前是否激活

### 7.5 HitRegistry

`HitRegistry` 是后续取代全局 `enemy["hit_cooldown"]` 的核心模块。

它记录的是：

- 哪个 `AttackInstance`
- 对哪个 `target_id`
- 对哪个 `hurtbox_id`
- 在什么时间点命中过

它负责回答一个问题：

`这一帧，这个攻击实例，是否允许再次命中这个目标/部位？`

### 7.6 DamageResolver

`DamageResolver` 是全项目唯一允许做最终伤害结算的地方。

它负责：

- 接收 `HitRequest`
- 读取攻击模板
- 读取目标模板
- 计算各伤害通道最终数值
- 写回目标生命/韧性/切割进度
- 返回 `HitResult`


## 8. 伤害通道

第一版建议只保留 3 个核心通道。

### 8.1 生命伤害 `hp`

- 用于减少目标生命
- 绝大部分武器都拥有该通道

### 8.2 韧性伤害 `poise`

- 用于击晕、打断、破势、制造失衡窗口
- `重剑` 应主要强化这一通道

### 8.3 切割伤害 `sever`

- 用于丝线、部位切断、切割型机制体
- `连斩 / 点刺 / 特定剑阵` 可以按设计分配不同强度

第一版不建议额外加入更多核心通道，避免系统一开始就过宽。


## 9. 命中节流策略

后续所有攻击必须声明自己的重复命中策略，而不是共享全局规则。

### 9.1 once_per_instance

同一个 `AttackInstance` 对同一目标只生效一次。

适合：

- 普攻
- 点刺
- 重剑重斩

### 9.2 once_per_entry

进入目标时生效一次，离开后再次进入才允许再次命中。

适合：

- 回旋镖
- 来回切过的飞行武器

### 9.3 interval_per_target

只要持续接触，就按固定时间间隔对同一目标跳伤。

适合：

- 连斩
- 高频擦碰类攻击

### 9.4 continuous_contact

只要持续接触，就按持续伤害模型累计结算。

适合：

- 回旋刃
- 激光
- 火焰锯

此模式下不建议再依赖“离散命中次数”，而是按接触时长结算。


## 10. 命中几何

伤害框架必须和几何检测解耦。

也就是说：

- 伤害系统不关心你是圆、线、扇形还是曲线
- 几何检测系统只负责提供“本帧命中了哪些 hurtbox”

第一版建议支持以下几类形状：

- `arc`
- `segment_sweep`
- `circle_overlap`
- `projectile_contact`
- `ray_pierce`
- `capsule_path`

这已经足够覆盖：

- 普攻扇形
- 点刺穿体线段
- 连斩扫线
- 飞剑投射物
- 回旋刃轨道接触


## 11. 统一结算流程

后续所有命中都按以下顺序处理：

### 11.1 收集命中

攻击系统通过几何检测得到 `candidate hurtboxes`。

### 11.2 过滤目标有效性

例如：

- 目标是否还活着
- 部位是否激活
- 当前是否允许受击
- 是否处于脆弱期

### 11.3 查询 HitRegistry

根据攻击实例的 `rehit_policy` 与 `rehit_interval` 决定本次是否允许命中。

### 11.4 构建 HitRequest

`HitRequest` 建议包含：

```gdscript
{
	"attack_instance_id": "attack_1024",
	"attack_profile_id": "flying_sword_slice",
	"target_id": "boss_1",
	"hurtbox_id": "boss_core",
	"contact_time": 0.016,
	"contact_point": Vector2.ZERO,
	"channel_scalar": 1.0
}
```

补充约定：

- `channel_scalar` 表示本次 `AttackInstance` 的运行时统一倍率
- 它适合处理“模板不变，但这一次强度不同”的情况
- 例如：
  - 弹反后根据子弹口径保留不同伤害
  - 后续重剑按蓄力层数放大单次伤害
  - 后续终结技按资源层数放大爆发
- 如果某个倍率已经是稳定规则，优先沉到 `AttackProfile / TargetProfile`，不要长期堆在调用侧

### 11.5 DamageResolver 计算最终值

第一版结算公式建议尽量直接：

```text
final_hp = max(raw_hp - armor, 0)
final_poise = max(raw_poise - poise_resist, 0)
final_sever = raw_sever if hurtbox_kind == silk else 0
```

### 11.6 目标响应

目标根据 `HitResult` 做后续响应：

- 扣血
- 进入硬直
- 部位断裂
- 打开核心
- 触发返航、穿透、特效


## 12. 现有武器映射建议

### 12.1 普攻

- `shape`: `arc`
- `rehit_policy`: `once_per_instance`
- `channels`:
  - `hp`: 中
  - `poise`: 中
  - `sever`: 低

定位：

- 近身兑现
- 补刀
- 反制后收头

### 12.2 御剑点刺

- `shape`: `segment_sweep`
- `rehit_policy`: `once_per_instance`
- `channels`:
  - `hp`: 高
  - `poise`: 高
  - `sever`: 中

定位：

- 精确处决
- 打破绽
- 切高价值目标

### 12.3 御剑连斩

- `shape`: `segment_sweep`
- `rehit_policy`: `interval_per_target`
- `rehit_interval`: 较短
- `channels`:
  - `hp`: 低到中
  - `poise`: 低
  - `sever`: 高

定位：

- 高频扫线
- 切丝
- 快速处理轻目标

### 12.4 环阵

- `shape`: `projectile_contact`
- `rehit_policy`: `once_per_instance`
- `channels`:
  - `hp`: 单剑低
  - `poise`: 中
  - `sever`: 低

定位：

- 近身总量爆发
- 贴脸解压

### 12.5 扇阵

- `shape`: `projectile_contact`
- `rehit_policy`: `once_per_instance`
- `channels`:
  - `hp`: 单剑中
  - `poise`: 中
  - `sever`: 低到中

定位：

- 中距压制
- 稳定面扫

### 12.6 贯穿阵

- `shape`: `projectile_contact`
- `rehit_policy`: `once_per_instance`
- `pierce_targets`: 大于 1
- `channels`:
  - `hp`: 单剑高
  - `poise`: 中到高
  - `sever`: 中

定位：

- 远距高价值目标处理
- 穿透破线


## 13. 未来流派扩展示例

### 13.1 重剑

目标体验：

- 慢
- 重
- 单次命中价值高
- 容易打出失衡和硬直

建议建模：

- `rehit_policy`: `once_per_instance`
- `hp`: 中到高
- `poise`: 很高
- `sever`: 低
- 可选增加 `armor_break` 标签

重剑的差异不应来自“隐藏 Boss 伤害加成”，而应来自：

- 更高 `poise`
- 更强打断能力
- 更适合打装甲和开窗口

### 13.2 回旋刃

目标体验：

- 挂在敌人路径上持续刮伤
- 单次命中不重，但接触期间持续有效

建议建模：

- `hit_mode`: `continuous`
- `rehit_policy`: `continuous_contact`
- 使用 `dps_channels`

建议字段如下：

```gdscript
{
	"id": "boomerang_blade",
	"hit_mode": "continuous",
	"rehit_policy": "continuous_contact",
	"dps_channels": {
		"hp": 40.0,
		"poise": 8.0,
		"sever": 20.0
	}
}
```

这样实现后：

- 不依赖 `ENEMY_HIT_COOLDOWN = 0`
- 不受帧率影响
- 更符合“持续接触”设计语言


## 14. 模块划分与实现落点

第一阶段建议新增以下模块：

- `scripts/combat/attack_profiles.gd`
  - 维护攻击模板库
- `scripts/combat/target_profiles.gd`
  - 维护目标与部位模板库
- `scripts/combat/target_descriptors.gd`
  - 提供部位 descriptor 的基础构建函数
- `scripts/combat/target_descriptor_registry.gd`
  - 以 provider registry 的方式生成某类目标的 hurtbox descriptors
- `scripts/combat/hurtbox_registry.gd`
  - 管理战场中的 hurtbox descriptors，并负责按状态选择实际可命中的部位
- `scripts/combat/hit_registry.gd`
  - 管理攻击实例对目标的重复命中记录
- `scripts/combat/hit_detection.gd`
  - 作为独立 detection service，集中处理扇形、线段、接触等几何命中发现
- `scripts/combat/damage_resolver.gd`
  - 以 gate / channel stage / mitigation / post rule 四段注册管线统一进行伤害通道结算
- `scripts/combat/target_writeback_adapters.gd`
  - 以 adapter registry 的方式把统一结算结果写回不同资源池
- `scripts/combat/target_event_system.gd`
  - 统一收集目标响应事件，并通过 handler/rule registry 分发带 payload 的事件记录

当前已经落地的结构约束：

- `main.gd` 负责出招、VFX、资源反馈，但不再直接展开四条主要命中发现循环
- `HitDetection` 负责返回标准化 contact record，供飞剑、剑阵、弹反、普攻共用
- `DamageResolver` 不再写死为单条静态函数链，后续新流派可直接插入新 gate / mitigation / post rule
- `TargetEventSystem` 输出的是 event record，而不是纯字符串数组；后续可继续扩展 `part_break / core_exposure / buildup / guard_break` 的 payload

第一版为了兼容当前工程，可继续使用 `Dictionary` 作为运行时数据承载，不强制引入新的复杂类体系。


## 15. 分阶段实施计划

### 阶段 1：搭框架，不改手感

目标：

- 新增 `AttackProfile / TargetProfile / HitRegistry / DamageResolver`
- 保证项目仍可运行
- 不在这一阶段大改手感和数值

产出：

- 新模块文件
- 一套最小接口
- 文档中的字段结构先落地为 `Dictionary` 版本

### 阶段 2：先接御剑

目标：

- 把 `点刺 / 连斩` 从 `main.gd` 的现有特判迁到统一命中框架
- 删除对普通敌人与 Boss 本体分别使用不同伤害模型的写法

产出：

- 点刺改为 `once_per_instance`
- 连斩改为 `interval_per_target`
- `enemy["hit_cooldown"]` 不再承担御剑重复命中节流

### 阶段 3：接入剑阵

目标：

- 把 `环 / 扇 / 贯` 三种飞剑命中改为统一结算流程
- 保留现有几何、返航、穿透、回收语义

产出：

- `_array_sword_hits_enemy()` 改为只负责“发现命中”
- 真实扣血移交给 `DamageResolver`

### 阶段 4：接入 Boss 与丝线

目标：

- 把 Boss 本体、丝线改造成统一 `TargetProfile + Hurtbox` 结构
- 移除 `update_silk_damage()` 这种独立伤害函数

产出：

- 丝线不再使用单独的帧伤害公式
- Boss 本体、丝线、脆弱核心共享同一套受击流程

### 阶段 5：接入目标响应

目标：

- 在统一命中结算后补上统一的目标响应层
- 不再把 `硬直 / 破防 / 开窗` 散落在各个攻击入口
- 让后续新增流派只需要声明响应配置，不需要重复写状态机分支

产出：

- `combat_runtime.target_states` 作为目标侧运行时状态容器
- `TargetProfile` 新增 `max_poise / poise_recovery_delay / poise_recovery_rate / poise_break_events / break_duration`
- 普通敌人通过 `poise_break_events = ["stagger"]` 进入短硬直
- Boss 本体通过 `poise_break_events = ["boss_vulnerable"]` 打开统一脆弱窗口

### 阶段 6：清理旧逻辑

目标：

- 删除旧的全局 `enemy["hit_cooldown"]` 依赖
- 删除散落的特判乘区
- 收敛到统一接口

产出：

- 命中、伤害、部位响应入口收敛
- 调用层统一改为“发现命中后交给通用 hit-apply helper”，不再在每个攻击入口重复写 resolve + apply 模板
- 写回层拆为 `target binding + writeback adapter`，不再让 `_apply_hit_result_to_target()` 直接展开 `health / boss.health / silk.health` 分支
- 响应层复用同一份 `target binding`，不再在 `stagger / boss_vulnerable` 里重复查找目标
- Boss 命中改为统一 `body / core` 路由辅助入口，而不是每个攻击点自己判断 `vulnerable`
- Boss 脆弱窗口开启改为统一辅助函数，而不是在状态机与受击响应里分别直接改字段
- 删除 `ultimate -> boss` 的调用侧临时倍率补丁
- 后续新增武器只需加 profile 和 detection，不需新抄一套结算

### 阶段 7：扩展新流派

目标：

- 基于统一框架加入 `重剑`
- 再加入 `回旋刃`
- 验证框架对高单次武器和持续接触武器都成立

验收标准：

- 不需要引入新的全局 `hit_cooldown`
- 不需要写新的 `if boss` 专属伤害路径
- 不需要为 `回旋刃` 使用按帧离散多段 hit 的临时方案


## 16. 验证清单

框架落地后，至少要验证以下问题：

1. 点刺是否仍保持“一次穿过只打一次”的清晰读感
2. 连斩是否可以稳定按预期频率跳伤，而不是因为目标数量变化失真
3. 剑阵的穿透、返航、批次回收是否仍然正常
4. 丝线是否能通过统一 `sever` 通道被正确处理
5. Boss 是否可以通过部位和窗口实现差异，而不需要隐藏倍率补丁
6. 普通敌人的硬直是否来自统一 `poise` 破韧，而不是单独攻击特判
7. Boss 的脆弱窗口是否来自统一事件，而不是 `if boss` 的隐藏乘区
6. 回旋刃在不同帧率下的 DPS 是否稳定一致


## 17. 未来可扩展伤害能力

本节用于定义后续最值得纳入统一伤害框架的扩展方向。

重点不是把系统做得更“复杂”，而是让伤害系统能回答更多真正影响战斗选择的问题：

- 这招更适合打哪里
- 这招为什么适合现在这个时机
- 这招命中后会改变什么战场状态
- 下一招为什么应该接这一招

### 17.1 新伤害通道

这类扩展最适合以“新结算通道”的形式进入框架。

建议优先考虑以下方向：

- `guard`
  - 用于护盾、格挡条、护甲层、屏障
  - 不是直接扣生命，而是先处理防护层
- `armor_break`
  - 用于降低目标护甲、打开更高后续承伤窗口
  - 非常适合 `重剑`
- `stability`
  - 比 `poise` 更偏持续压制和站立稳定度
  - 适合未来需要区分“硬直”和“失衡”时使用
- `wound`
  - 表示持续创伤
  - 可用于后续派生移动减速、部位脆化、治疗压制等效果
- `execute`
  - 只在低血线、破势或特定状态下生效
  - 适合处决型、收头型流派

设计建议：

- 第一批优先考虑 `guard` 与 `armor_break`
- `stability / wound / execute` 暂时保留为第二层扩展，不急于首版落地

### 17.2 条件化伤害

这类扩展用于回答：

`在什么条件下，这个攻击比平时更值钱？`

推荐方向：

- `backstab`
  - 背后或侧后命中时，特定通道增强
- `distance_band_bonus`
  - 根据近距 / 中距 / 远距处于不同甜区，调整攻击表现
  - 很适合 `环 / 扇 / 贯`
- `speed_based_damage`
  - 速度越高、飞行越远、旋转越快，伤害越高
- `entry_vs_exit_bonus`
  - 进体命中和出体命中表现不同
  - 适合穿刺、回旋、来回切过的武器
- `timed_release_bonus`
  - 蓄满、完美释放、精确时机带来额外收益

设计建议：

- 条件化伤害应优先来自玩家可读、可掌握的战术条件
- 不建议加入大量玩家难以察觉的隐藏乘区

### 17.3 积累与爆发

这类扩展用于建立流派之间的节奏差异。

推荐方向：

- `mark`
  - 命中叠印记，达到阈值后引爆
- `bleed`
  - 高频命中流派的持续兑现机制
- `sever_buildup`
  - 丝线或部位不是一刀切断，而是累积切割进度
- `resonance`
  - 一类攻击负责埋层，另一类攻击负责兑现
- `charge_harvest`
  - 先积累，再收割

设计建议：

- `回旋刃` 更适合高频叠层
- `重剑` 更适合低频高兑现
- 如果后续做流派联动，这是非常值得优先启用的一层

### 17.4 部位与结构伤害

这类扩展最适合 Boss 和机制体设计。

推荐方向：

- `part_break`
  - 打断翅膀、手臂、护甲片、武器模块
- `core_exposure`
  - 先破外层，再打开核心输出窗口
- `tether_sever`
  - 将当前的丝线切断机制泛化
- `summon_anchor_damage`
  - 优先打掉召唤锚点或法阵节点，而不是直接打本体
- `weapon_clash_point`
  - 攻击敌方武器或法器节点，影响其出招能力

设计建议：

- Boss 的特殊性优先通过这一层表达
- 不要回退到 `Boss 额外伤害系数` 方案

### 17.5 空间与控制型伤害

这类扩展不只关注“扣了多少血”，还关注“命中后战场发生什么变化”。

推荐方向：

- `knockback`
  - 击退
- `launch`
  - 挑飞
- `pull`
  - 牵引
- `pin`
  - 钉住、限制位移
- `zone_damage`
  - 留下持续伤害区域
- `projectile_interaction_power`
  - 清弹、切弹、偏转、吞噬
- `collision_conversion`
  - 撞墙、撞阵、撞飞剑时产生二次效果

设计建议：

- 动作弹幕类项目很适合在这一层做差异化
- 这层的价值不在于单纯提高输出，而在于改变空间控制能力

### 17.6 资源联动型伤害

这类扩展用于把伤害和资源循环更紧密地绑在一起。

推荐方向：

- `energy_gain_modifier`
  - 命中时提供额外剑意收益
- `refund_on_condition`
  - 命中弱点、切断丝线、穿透多个目标时返资源
- `overload_damage`
  - 资源溢出或满层时进入高压状态
- `debt_damage`
  - 先透支换爆发，之后承受代价
- `finisher_consume`
  - 消耗资源或标记换终结伤害

设计建议：

- 这一层很适合剑修题材
- 但不建议太早做复杂，否则战斗会变成算账流程


## 18. 推荐扩展优先级

如果以后只扩最有价值、最能拉开流派身份的内容，建议优先级如下：

### 18.1 第一优先级

- `armor_break`
- `continuous_contact`
- `part_break / core_exposure / tether_sever`

原因：

- 这三项最能直接支撑 `重剑`、`回旋刃`、Boss 部位机制
- 它们都能明显改变战斗语言，而不仅仅是多一个乘区

### 18.2 第二优先级

- `mark / resonance / bleed / sever_buildup`
- `projectile_interaction_power`
- `knockback / pin / zone_damage`

原因：

- 这批内容最适合扩战场控制和流派联动
- 对项目题材和现有动作弹幕结构都比较匹配

### 18.3 第三优先级

- `stability`
- `wound`
- `execute`
- `resource-linked damage`

原因：

- 有价值，但更适合在基础框架和主流派稳定后再加

### 18.4 暂不建议过早引入

- 暴击
- 五行或元素克制
- 大量复杂乘区
- Boss 专属隐藏抗性表
- 大量装备词条式异常伤害

原因：

- 这些机制容易让系统看起来更大，但未必更好玩
- 对当前项目阶段来说，收益通常低于 `部位 / 节流 / 连续接触 / 破甲`


## 19. 未来字段扩展示意

为了保证后续扩展不破坏现有骨架，建议未来新能力优先接在以下位置。

### 19.1 AttackProfile 可扩字段

```gdscript
{
	"channels": {
		"hp": 0.0,
		"poise": 0.0,
		"sever": 0.0,
		"guard": 0.0,
		"armor_break": 0.0
	},
	"dps_channels": {
		"hp": 0.0,
		"sever": 0.0
	},
	"buildup": {
		"bleed": 0.0,
		"mark": 0.0,
		"wound": 0.0
	},
	"condition_rules": [
		{
			"type": "backstab",
			"channel": "hp",
			"multiplier": 1.3
		}
	],
	"on_hit_effects": [
		{
			"type": "knockback",
			"power": 12.0
		}
	]
}
```

### 19.2 TargetProfile 可扩字段

```gdscript
{
	"armor": 0.0,
	"guard_hp": 0.0,
	"resource_channel": "hp",
	"poise_resist": 0.0,
	"buildup_resist": {
		"bleed": 0.0,
		"mark": 0.0
	},
	"weakness_rules": [
		{
			"tag": "thrust",
			"channel": "poise",
			"multiplier": 1.2
		}
	],
	"state_gates": [
		{
			"state": "vulnerable",
			"required_for": ["core"]
		}
	]
}
```

### 19.3 HitResult 可扩字段

```gdscript
{
	"applied_channels": {
		"hp": 0.0,
		"poise": 0.0,
		"sever": 0.0,
		"guard": 0.0
	},
	"applied_buildup": {
		"bleed": 0.0,
		"mark": 0.0
	},
	"triggered_events": [
		"part_break",
		"core_exposed"
	]
}
```

设计原则：

- 新能力尽量作为字段扩展进入统一结构
- 不建议为每种新流派新写一套单独的命中结算函数


## 20. 后续扩展的实现约束

为了避免系统再次走向分裂，后续新增能力必须遵守以下约束：

1. 新伤害能力优先接入 `AttackProfile / TargetProfile / HitResult`
2. 新命中频率优先扩展 `rehit_policy`，不要恢复目标全局冷却
3. 新 Boss 机制优先做成新 `hurtbox_kind` 或部位状态，不要补隐藏倍率
4. 持续接触型伤害必须走 `continuous_contact` 或固定 tick，不要用 `rehit_interval = 0`
5. 新流派如果只是为了拉开差异，应优先考虑：
   - 新通道
   - 新条件
   - 新积累
   - 新空间控制
   而不是先加新的乘区


## 21. 当前结论

本框架的核心不是把所有目标做成“同一块血包”，而是：

- 让所有攻击共享同一条命中结算管线
- 让所有目标共享同一套受击接口
- 把 Boss 的特殊性从“乘系数”迁移到“目标结构”
- 把重复命中规则从“目标全局状态”迁移到“攻击实例策略”

一句话概括：

`统一的是流程，不是表现；统一的是结算接口，不是战术身份。`
