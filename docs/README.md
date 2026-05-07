# 文档结构说明

本项目的设计文档按“用途”而不是按时间分类，方便后续持续迭代时快速恢复上下文。

当前阅读时请先区分两件事：

- `当前实装`：以 [docs/project/CURRENT_PROJECT_DESIGN.md](/E:/SwordCultivator/docs/project/CURRENT_PROJECT_DESIGN.md) 为准
- `目标方向 / 已定案方案`：以 `docs/decisions/` 与相关系统文档为准

如果两者冲突，不表示文档有一份一定错了，更常见的情况是：

- `docs/project/` 记录的是当前代码里已经能玩的版本
- `docs/decisions/` 记录的是准备继续推进、但未必全部落地的方向
- `docs/discussions/` 和部分 `docs/reviews/` 保留了历史阶段判断，不应直接当作当前实现说明

## 分类规则

### `docs/project/`

- 项目层总览文档
- 记录当前项目是什么、当前版本实现了什么、核心战斗循环是什么
- 适合新会话快速建立整体理解
- 当前主入口是 `docs/project/CURRENT_PROJECT_DESIGN.md`

### `docs/decisions/`

- 已定案的设计决策
- 只记录已经确认、可以作为实现依据的规则
- 不放脑暴内容，不放过程性讨论

### `docs/systems/`

- 单个系统的定稿或准定稿设计文档
- 例如战斗系统、剑阵系统、Boss 系统
- 这些文档是实现和调参时的直接依据

### `docs/levels/`

- 关卡、波次、章节节奏与教学推进文档
- 记录敌人组合如何引导玩家进入核心循环
- 适合把设计方案直接落到刷怪表或关卡配置

### `docs/reviews/`

- 评估类文档
- 记录专业分析、优缺点、风险、优先级建议
- 适合在讨论方向和质量判断时参考

### `docs/discussions/`

- 未定案、仍在讨论中的方案
- 这里的文档不应直接作为最终实现依据
- 当方案定案后，应移动或重写到 `docs/decisions/` 或 `docs/systems/`

### `docs/internal/`

- 面向开发连续性的内部文档
- 例如进度记录、交接信息、临时工作笔记
- 不作为正式设计定稿依据

## 建议阅读顺序

如果要快速恢复项目上下文，建议按以下顺序阅读：

1. `docs/project/CURRENT_PROJECT_DESIGN.md`
2. `docs/decisions/PROJECT_DECISIONS.md`
3. `docs/systems/`
4. `docs/reviews/`
5. `docs/discussions/`
6. `docs/internal/`

## 当前说明

当前项目已经把以下内容归类：

- 项目当前策划案
- 项目设计评估报告
- 剑阵形变系统 V1
- 剑阵形变系统 V2
- 剑阵飞剑出入阵轨迹终版设计
- 统一伤害与命中框架
- 第一章关卡波次引导方案
- 已定案设计决策清单
- 内部进度记录
