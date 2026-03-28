Original prompt: 目前有个问题，我感觉射出的弹幕速度的延长线不是指向玩家这个圆心的，比如环阵下，速度的延长线都不指向圆形，你检查下所有阵型是否都有这个问题。以你专业的游戏设计能力来看，这个现象是在设计中的吗？

- Found two issues: source-slot selection was not paired with per-shot target direction in ring/fan style volleys, and ring preview spokes were hard-coded to 6 while the live slot count varies.
- Planned fix: choose each firing marble by best alignment to the current shot direction, use live slot count for ring firing angles, and align ring preview spokes with the absorbed marble count.
- Implemented the fix in `scripts/system/sword_array_controller.gd`, `scripts/system/main.gd`, and `scripts/system/game_renderer.gd`.
- Follow-up fix after screenshot review: `ring`, `fan`, and `crescent` now extend shots using the actual source bullet direction instead of an idealized pattern ray, removing residual off-center trajectories caused by discrete slot mismatch.
- Validation status: static code-path check only. No local `godot` / `godot4` executable was available in PATH, so runtime verification is still pending.
