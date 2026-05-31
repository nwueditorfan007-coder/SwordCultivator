# 最近一周对话沉淀：Skill 候选与废弃草案

日期：2026-05-31

性质：内部复盘 / skill 候选清单 / 防回滚记录草案。

范围：根据最近一周围绕御剑飞行原型、Godot 验证、美术参考、GitHub 发布流和角色表现原型的对话整理。本文不替代正式设计定案；若后续确认，应再拆分到 `.codex/skills/`、`docs/decisions/` 或 `docs/systems/`。

## 0. 总判断

这一周最值得沉淀的不是某一组数值，而是几条稳定的工作方式：

- 御剑飞行的玩家手感优先级：先看转向是否符合“慢慢旋转过去”，再谈动画张数、缩放、战场大小和素材接入。
- 原型调试的证据链：先定位真实输入归属、绘制层、资源、材质、状态路径，再声明修复。
- Godot 报错排查：运行时启动干净不等于编辑器扫描干净；重复 UID、嵌套 `project.godot`、参考库导入噪音要单独查。
- 美术原型身份约束：如果目标是当前男主，就不能先做一个看起来毫不相干的新角色再解释为技术演示。
- 发布流要保持干净：脏工作区里只提交本任务范围，不能把历史实验、参考素材和无关删除混进同一个提交。

建议优先新增或强化的 skill 有两类：

- 高优先级：御剑飞行原型调参 / Godot 根因验证。
- 中优先级：身份敏感的角色表现原型 / V15 水墨剪影资料库 / 项目内 GitHub 发布流。

## 1. 能成为 Skill 的内容

### 1.1 `yujian-flight-prototype-tuning`

状态：建议新增，或并入现有 `.codex/skills/yujian-sprite-sequence-assets/` 后再观察是否需要拆分。

适用触发：

- “御剑飞行手感不对”
- “WASD 不要直接转向，要慢慢旋转过去”
- “改成四项动画试试”
- “缩小人物，扩大飞行战场”
- “保留之前接入的上下方向角色”

应沉淀的核心规则：

- 先从玩家体感判断：输入是否像给旋转角速度，而不是像八方向瞬移。
- 保留 `target_heading`、`body_heading`、`velocity` 的分层，不要把输入向量直接写成朝向。
- 调整读感先用四向、滞后、缩放和战场尺寸，避免马上堆更多过渡动画。
- V1 素材接入是混合模式：左右可用生成序列，上下保留已接受静态方向。
- 急转过渡动画未明确接受前，不自动接入主原型。
- 改完不能只做 headless 启动；涉及热键、读感、方向判断时要做真实窗口交互验证。

推荐落点：

- 如果它继续主要服务 `scripts/prototypes/yujian_sprite_sequence_prototype.gd`，先更新 `yujian-sprite-sequence-assets`。
- 如果后续开始覆盖 3D、骨架、部件、V4/V5/V6 多条原型路线，就拆成独立 skill。

### 1.2 `swordcultivator-godot-validation`

状态：建议新增。记忆里已有这条 skill 的概念，但当前项目 `.codex/skills/` 下没有对应目录。

适用触发：

- “修复下报错”
- “Godot 打不开 / 有红字”
- “UID duplicate detected”
- “运行没问题但编辑器还有错误”
- “这个视觉问题先别改，先分析原因”

应沉淀的核心规则：

- 报错先分清运行时、编辑器扫描、导入系统、脚本解析、资源路径。
- 常规验证顺序：`git diff --check`，`tools/start_godot_with_log.ps1`，`tools/show_godot_errors.ps1`。
- 运行时干净但编辑器仍报错时，切到 editor/headless 模式查导入和文件系统扫描。
- 对参考库、备份树、下载素材，优先用 `.gdignore` 阻止 Godot 扫描，不轻易删除或移动。
- 对“飞剑外面有方形/矩形层”这类视觉反馈，先找真实绘制层、纹理、材质或 SubViewport，不把问题猜成剑身几何。

推荐落点：

- 新增 `.codex/skills/swordcultivator-godot-validation/SKILL.md`。
- 可带一个很短的 `references/validation_paths.md`，记录本机 Godot 路径、工具脚本、常见误判。

### 1.3 `swordcultivator-root-cause-debugging`

状态：不建议单独新增，建议合并到 `swordcultivator-godot-validation` 和 `sword-cultivator-core`。

原因：

- 它是一条横向协作原则，不是一个独立任务域。
- 对代码 bug、视觉 bug、控制手感、美术身份漂移都适用。
- 单独做成 skill 容易触发过宽，反而不如放进每个相关 skill 的“先定位真实来源”步骤。

应沉淀的核心规则：

- 不从相似症状直接跳到“已修复”。
- 未证明的解释要标成假设。
- 先定位具体代码路径、输入所有者、绘制调用、资源、材质、状态迁移或数据文件。

### 1.4 `stacked-sprite-protagonist-prototype`

状态：中优先级候选。建议先作为 `docs/systems/STACKED_SPRITE_CHARACTER_PROTOTYPE.md` 的恢复/重建依据，等下一次真的继续做堆叠角色时再技能化。

适用触发：

- “做一个跟现在角色一致的堆叠精灵人物”
- “用当前男主模型切片”
- “新开一个原型，不要改 live 原型”

应沉淀的核心规则：

- 方案先行，再新建隔离原型。
- 身份锚点是当前男主模型，不是临时生成一个相似题材小人。
- 堆叠层只负责表现，不接管移动和动画状态机。
- 统一 pivot、共享 frame index、用 `SubViewport` 或模型渲染作为真实来源。

推荐落点：

- 若继续推进，新增 `.codex/skills/stacked-sprite-protagonist-prototype/`。
- 当前阶段先把防漂移规则写进原型文档或本清单即可。

### 1.5 `v15-silhouette-art-reference-study`

状态：中优先级候选。更像美术生产 brief 和资料库工作流，不一定要立刻做成 skill。

适用触发：

- “V15 素材任务包”
- “水墨剪影方向再审一下”
- “找/下载可以学习的开源素材”
- “哪些人物比例接近项目需要”

应沉淀的核心规则：

- V15 是生产合约，不只是 moodboard。
- 优先评估小体量战斗剪影、头身比、横版动作可读性。
- 本地参考库要能打开、能学习、能说明来源；直接复用前必须重查授权。
- OpenDuelyst 更适合比例和动作参考；LPC 更适合组件分层参考，不是直接风格目标。

推荐落点：

- 先保持在 `AI/V15_水墨剪影美术素材任务包.md` 和 `AI/reference_assets/V15_open_source_study/README.md`。
- 如果后续反复让 Codex 找资料、下载、筛选、写 production brief，再新增 skill。

### 1.6 `swordcultivator-git-scoped-publish`

状态：中低优先级候选。项目发布任务反复出现时值得做成 skill；现在也可以先作为内部流程写入。

适用触发：

- “从 GitHub 上面更新项目”
- “做完提交到 GitHub”
- “更新并推上去”
- “这个任务单独开分支”

应沉淀的核心规则：

- 更新项目默认走 `git status --short --branch` 与 `git pull --ff-only origin main`。
- 发布任务先建/确认分支，再验证，再显式 stage 本任务文件。
- 脏工作区里不带无关素材、历史实验和意外删除。
- Godot 新脚本通常要带 `.gd.uid`，避免之后再生 churn。
- 当前机器没有 `gh` 时，推送后给 PR 创建 URL 作为交接。

推荐落点：

- 若经常需要一键发布，新增 `.codex/skills/swordcultivator-git-scoped-publish/`。
- 否则放进 `docs/internal/` 就够了。

## 2. 已有 Skill 的更新建议

### `.codex/skills/yujian-sprite-sequence-assets/`

建议补充：

- V1 混合素材模式：左右生成序列，上下保留已接受静态图。
- 四向读感优先于八向完整表达。
- 方向素材替换前先确认哪些方向已经被接受，不能整套覆盖。
- afterimage / debug label 要跟随当前帧来源区分静态图与序列帧。

### `.codex/skills/yujian-8way-cruise-imagegen/`

建议补充：

- 方向图生成时，已经接受的上下方向是保护对象。
- 对角线和左右可以继续探索，但不要默认影响当前主原型接线。

### `.codex/skills/sword-cultivator-core/`

建议补充：

- “慢慢旋转过去”表示玩家要的是转向速率和惯性，不是方向 snap。
- 控制手感讨论先讲玩家面对敌群时的读感、节奏和主动性，再落到参数。
- 视觉或输入反馈被指出不对时，先承认玩家看到的是结果，再定位真实路径。

### `.codex/skills/godot-vfx-higodot-mcp/`

建议保持现状。它适合 VFX/粒子/材质/动画驱动效果，不应承包御剑控制逻辑、资源接线或 Git 发布流。

## 3. 最近一周应记录为“不要无意识恢复”的草案

这些不是说永远不能再试，而是如果以后重新打开，必须说明：当前玩家体验问题是什么、旧失败原因为什么不成立、最小原型是什么、成功/失败怎么判定。

### 3.1 御剑输入直接八方向 snap

结论：不要恢复为默认飞行手感。

原因：

- 玩家想要的是“WASD 给一个旋转角的速度”。
- 直接把输入向量写成朝向，会破坏御剑飞行的身体惯性和可预判性。
- 以后如果要做八方向动画，也应该服务于身体追随和读感，而不是把输入逻辑退回 snap。

### 3.2 当前主原型里强推完整八向 + 急转过渡

结论：不要作为默认接线恢复。

原因：

- 本周已经明确转向四项动画、缩小人物、扩大飞行战场，以降低读感噪音。
- 急转过渡动画没有被明确接受，先不接入。
- 八向资源可以作为素材库保留，但主原型不应为了“完整”牺牲当前更清楚的战斗读感。

### 3.3 用生成序列整套覆盖已接受方向

结论：不要恢复。

原因：

- 上下方向已被要求保留。
- 当前接受的是混合接入，不是全量替换。
- 以后替换方向图时，应先列出“保护方向”和“可探索方向”。

### 3.4 F5 面板由父子节点同时处理

结论：不要恢复为多 owner 热键。

原因：

- 热键看似存在，但运行时仍可能打不开。
- 外层原型应拥有 F5；子节点暴露 toggle API。
- 涉及真实键盘输入时，headless 启动不等于验证完成。

### 3.5 把飞剑矩形包围层猜成剑身几何问题

结论：不要在未定位前改剑身几何。

原因：

- 用户说的“方形/矩形层”是围绕飞剑的渲染框或图层感，不是剑刃形状本身。
- 必须先找纹理边界、材质透明、SubViewport、Sprite region、afterimage 或 debug 绘制来源。

### 3.6 直接调用 `_draw_*` 辅助方法做烟测

结论：不要把这种报错当作项目真实 bug。

原因：

- Godot 的绘制生命周期由 `_draw()` 管，直接调 helper 可能制造误报。
- 验证视觉绘制要用真实节点、真实场景和日志，而不是脱离 draw lifecycle 的脚本调用。

### 3.7 脱离当前男主身份的堆叠角色草案

结论：不要恢复。

原因：

- 用户要的是“跟现在角色一致”的堆叠精灵人物。
- 技术演示不能先牺牲身份识别。
- 堆叠精灵方案应该从当前男主模型或已接受资产中取样，而不是新造一个题材相近但身份不同的角色。

## 4. 已有废弃档案不需要重复改写的内容

`docs/decisions/REJECTED_IMPLEMENTED_DESIGNS.md` 已经记录了更早确认不要直接恢复的系统级方向，例如：

- 扇阵作为独立第三阵型。
- 完整剑灵 / 剑相 / 武器锻造系统。
- 冻结弹幕 -> 主动吸收 -> 再发射。
- `Q` 必杀。
- 剑丸资源与 `Space` 强化剑技。
- 剑阵共鸣 / 余韵连招。
- 阵型距离引导圈。

本周新增的“不要恢复”更多是原型路线和协作方式，不一定要立刻塞进同一个正式负面决策文档。等某条已经反复造成回滚风险，再移入 `docs/decisions/REJECTED_IMPLEMENTED_DESIGNS.md`。

## 5. 建议落地顺序

1. 新增 `swordcultivator-godot-validation` skill。
2. 更新 `yujian-sprite-sequence-assets`，加入四向读感、V1 混合素材、已接受方向保护。
3. 将“飞剑矩形包围层先定位真实渲染来源”补进 Godot 验证 skill。
4. 视后续原型频率，决定是否新增 `stacked-sprite-protagonist-prototype`。
5. V15 方向先继续作为生产 brief 和本地参考库维护，等再次进入批量产出时再技能化。
6. 如果近期还要频繁提交/开 PR，再新增 `swordcultivator-git-scoped-publish`。

## 6. 当前沉淀状态

已沉淀：

- 本文作为最近一周复盘和分类入口。
- `.codex/skills/` 已有御剑素材、八向图生成、序列帧生成、Godot 远程执行、VFX、核心设计判断等基础 skill。

未直接执行：

- 尚未新建新的 skill 目录。
- 尚未改写 `docs/decisions/REJECTED_IMPLEMENTED_DESIGNS.md`。
- 尚未把上述建议并入现有 skill。

建议下一步先确认：`yujian-flight-prototype-tuning` 是独立 skill，还是先并入 `yujian-sprite-sequence-assets`。这个决定会影响之后 Codex 触发时是按“飞行手感调参”进入，还是按“素材接线/验证”进入。
