// 战斗回归测试：固定种子 + 虚拟时钟 + 固定脚本输入，跑 60 秒（3600 帧）战斗，逐 10 帧记录状态并算出哈希。
// 用途：重构战斗框架（例如槽位化、换默认模块）时，结果必须与重构前逐帧一致，证明手感没有被改动。
//
// 用法（浏览器控制台，页面需可见尺寸 ≥ 1280×720，否则鼠标映射建立不起来）：
//   1. 打开 yujian_combat_proto.html，等 __combat.state.modelState 不再是 "loading"（角色模型异步加载，加载前后骨骼和手的位置不同，结果会走另一条轨迹），再等约 0.5 秒
//   2. 粘贴本文件全部内容执行，返回 { hash, cov, ... }；逐帧记录在 window.__trace
//   3. 与基准对比 hash；不一致时比较 window.__trace 找到第一处分叉
//
// 可选参数：执行前设置 window.__regOpts = { arrMode: 'action' | 'manual' | 'auto', modules: { slot: id, ... } }
//   modules 用于换模块后的冒烟测试（只看有没有报错、覆盖面是否正常，不对比哈希）
//
// 基准哈希（每次有意改变默认玩法后要重新记录，并写明原因）：
//   2026-10-03 槽位化重构前后一致：action 1611097287
//   2026-10-03 入场敌人改为按自身最高速度朝玩家飞（修墨鸦吊在画面外 18 米）后：
//     action -2123506860 · manual -1503913887 · auto -77565895
//   2026-10-03 测试本身改为固定模拟时钟（setSimTime），并要求等模型加载完、每个页面只跑一次（之前的基准受这几点影响，不再可比）：
//     action -966557004 · manual -1758001412 · auto 724591807   ← 当前基准（加入剑修后默认玩法不变，已逐一核对）
//   已知问题：浏览器空闲一段时间后第一次加载页面，action 偶尔得到 143067119（另一条轨迹，起始战斗状态快照完全相同，原因未查明，
//   怀疑与隐藏的浏览器面板 / 首帧布局有关）。加入剑修前后的代码在同样条件下都会出这个值，所以它不是代码改动造成的。
//   遇到不一致时：刷新页面再跑一次；连续两次一致才算结果。
// cov 是覆盖面统计：御剑各阶段帧数、剑阵出击帧数、挨打次数、反弹子弹帧数等，用来确认测试真的走到了这些逻辑。
(() => {
  const C = window.__combat, cb = C.cb, s = C.sim, G = C.G, V2 = s.vel.constructor;
  const realNow = performance.now.bind(performance); let virt = 100000;
  performance.now = () => virt; // 居合炸散延迟、镜头等用真实时钟的逻辑改走虚拟时钟
  try {
    if (C.state.modelState === 'loading') throw new Error('角色模型还在加载：等 __combat.state.modelState 不是 loading 再跑');
    if (window.__regRan) throw new Error('同一个页面只能跑一次：上一次运行留下的状态（主剑位置、计时器等）没有全部归位，请先刷新页面');
    window.__regRan = true;
    const r = { width: 800, height: 450 };
    const O = window.__regOpts || {};
    C.state.paused = false; C.state.arrMode = O.arrMode || 'action';
    for (const slot in C.SLOTS) C.equip(slot, (O.modules && O.modules[slot]) || 'basic');
    G.flow = 'free'; G.boss = null; cb.fire = true; cb.god = false; cb.specials = true;
    C.resetCombat(); C.reseed(424242); C.setSimTime(1000); C.anim.snap(0); // 模拟时钟与动画也归位：悬停起伏的相位按 simTime 走
    // 清掉上一次运行或标题画面残留的计时器与状态
    const st = C.state; st.zoomT = st.camT = st.fgT = st.washT = undefined; st.camZoom = 1; st.camFocus = null; st.camLook = null;
    cb.swordReady = false; cb.swordFxT = undefined; cb.arrayRR = 0; cb.arrayQAcc = 0; cb.arrayQueue = 0; cb.lastPress = -9; cb.slashSide = 1; cb.deflectChain = 0; cb.lastDeflectT = -9; cb.failT = -9; cb.sparkAcc = 0;
    // 预热 30 帧（不刷怪），稳住镜头和鼠标映射
    cb.specials = false; cb.squadT = 1e9;
    C.keys.clear(); C.mouse.has = true; C.mouse.x = 400; C.mouse.y = 225;
    for (let i = 0; i < 30; i++) { virt += 1000 / 60; C.tick(1 / 60); }
    cb.pendingSquads.length = 0; while (cb.enemies.length) C.removeEnemy(cb.enemies[0]); cb.specials = true; cb.specialT = 2; cb.squadT = 0.2;
    C.reseed(424242);
    const r6 = x => Math.round(x * 1e4) / 1e4;
    const trace = []; let hash = 0;
    const mix = str => { for (let i = 0; i < str.length; i++) hash = (Math.imul(hash, 31) + str.charCodeAt(i)) | 0; };
    cb.hp = 1e6; // 不会死，但挨打照样扣血、照样记录
    const cov = { yj: {}, arrOut: 0, hpLoss: 0, bullets: 0 }; let lastHp = cb.hp;
    for (let f = 0; f < 3600; f++) {
      // 鼠标绕圈转向；每 700 帧里有一段贴近中心（缓飞）
      const a = f * 0.012 + Math.sin(f * 0.003) * 2, rad = (f % 700 < 250 ? 15 : 60) + 140 * (0.5 + 0.5 * Math.sin(f * 0.02));
      C.mouse.x = r.width / 2 + Math.cos(a) * rad; C.mouse.y = r.height / 2 + Math.sin(a) * rad;
      if (f % 300 === 0) C.keys.add('w'); if (f % 300 === 160) C.keys.delete('w');      // 油门
      if (f % 23 === 20) { const p = C.playerC(), h = C.headingW(); for (const k of [-1, 0, 1]) C.fireBullet(new V2(p.x + h.x * 6 - h.y * k * 0.6, p.y + h.y * 6 + h.x * k * 0.6), new V2(-h.x, -h.y), 14); } // 迎面三发：测斩弹
      if (f % 23 === 0) C.pressSlash();
      if (C.state.arrMode === 'manual' && f % 200 === 10) C.castArray();          // 手动剑阵：E
      if (f % 170 === 85) C.doDodge();
      if (f % 400 === 300) cb.energy = Math.max(cb.energy, 60);
      if (f % 400 === 310) C.pressYj();
      if (f % 400 === 350) C.releaseYj();                                                // 连斩
      if (f % 400 === 380) { cb.energy = Math.max(cb.energy, 30); C.pressYj(); }
      if (f % 400 === 383) C.releaseYj();                                                // 点刺
      if (f % 90 === 45) { const cx = C.camera.position.x, cy = C.camera.position.y, k = Math.floor(f / 90) % 4; C.spawnAt(['crow', 'fan', 'diver', 'guard'][k], cx + (k % 2 ? -6 : 7), cy + 2 + k); C.spawnAt('crow', cx + 9, cy - 2); }
      if (f % 600 === 200) { const cx = C.camera.position.x, cy = C.camera.position.y; C.spawnAt('crow', cx + 12, cy + 3); C.spawnAt('fan', cx - 10, cy + 6); C.spawnAt('guard', cx + 6, cy - 4); C.spawnAt('diver', cx - 8, cy - 3); }
      virt += 1000 / 60; C.tick(1 / 60);
      cov.yj[cb.yj.state] = (cov.yj[cb.yj.state] || 0) + 1; cov.arrOut += cb.array.filter(x => x.state !== 'ready').length ? 1 : 0; if (cb.hp < lastHp) cov.hpLoss++; lastHp = cb.hp; cov.bullets += cb.bullets.filter(b => b.friendly).length ? 1 : 0; cov.enemyBullets = (cov.enemyBullets || 0) + (cb.bullets.length ? 1 : 0);
      if (f % 10 === 0) {
        const row = [f, r6(cb.hp), r6(cb.energy), cb.kills, r6(s.pos.x), r6(s.pos.y), r6(s.vel.x), r6(s.vel.y), cb.yj.state, r6(cb.worldScale),
          cb.enemies.length, cb.bullets.length, cb.array.map(x => x.state[0]).join(''),
          cb.enemies.map(e => e.type[0] + r6(e.pos.x) + ',' + r6(e.pos.y) + ':' + e.hp).join('|')];
        const str = JSON.stringify(row); mix(str); trace.push(str);
      }
    }
    C.keys.clear();
    for (const slot in C.SLOTS) C.equip(slot, 'basic'); C.state.arrMode = 'action';
    window.__trace = trace;
    return { cov, hash, kills: cb.kills, hp: cb.hp, energy: r6(cb.energy), maxEnemies: Math.max(...trace.map(t => JSON.parse(t)[10])) };
  } finally { performance.now = realNow; }
})()
