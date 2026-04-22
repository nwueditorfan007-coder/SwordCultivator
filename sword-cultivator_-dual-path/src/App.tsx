import React, { useEffect, useRef, useState } from 'react';
import { 
  CombatMode, 
  GameState, 
  Player, 
  Sword, 
  Enemy, 
  Bullet, 
  Particle, 
  EnemyType, 
  BulletType,
  Vector 
} from './types';
import { 
  CANVAS_WIDTH, 
  CANVAS_HEIGHT, 
  PLAYER_SPEED, 
  PLAYER_DASH_SPEED, 
  PLAYER_DASH_DURATION, 
  PLAYER_DASH_COOLDOWN, 
  PLAYER_RADIUS, 
  PLAYER_MAX_HEALTH, 
  PLAYER_MAX_ENERGY, 
  SWORD_RADIUS, 
  SWORD_SPEED, 
  SWORD_ROTATION_SPEED, 
  SWORD_MELEE_RANGE, 
  SWORD_MELEE_COOLDOWN, 
  SWORD_MELEE_ARC, 
  SWORD_RANGED_DAMAGE,
  SWORD_MELEE_DAMAGE,
  ENEMY_SHOOTER_RADIUS, 
  ENEMY_SHOOTER_HEALTH, 
  ENEMY_SHOOTER_SPEED, 
  ENEMY_SHOOTER_COOLDOWN, 
  ENEMY_TANK_RADIUS, 
  ENEMY_TANK_HEALTH, 
  ENEMY_TANK_SPEED, 
  ENEMY_CASTER_RADIUS, 
  ENEMY_CASTER_HEALTH, 
  ENEMY_CASTER_SPEED, 
  ENEMY_CASTER_COOLDOWN, 
  ENEMY_HEAVY_RADIUS,
  ENEMY_HEAVY_HEALTH,
  ENEMY_HEAVY_SPEED,
  ENEMY_HEAVY_COOLDOWN,
  BULLET_RADIUS, 
  BULLET_SPEED, 
  BULLET_DAMAGE, 
  BULLET_LARGE_RADIUS,
  BULLET_LARGE_SPEED,
  BULLET_LARGE_DAMAGE,
  WAVE_SPAWN_INTERVAL, 
  WAVE_BASE_ENEMIES, 
  COLORS,
  ENERGY_CONSUMPTION_RANGED,
  ENERGY_RECOVERY_MELEE_NATURAL,
  ENERGY_GAIN_MELEE_HIT,
  ENERGY_GAIN_MELEE_DEFLECT,
  SWORD_AUTO_HUNT_RANGE,
  SWORD_TAP_THRESHOLD,
  BULLET_TIME_MULTIPLIER,
  PLAYER_BULLET_TIME_SPEED_MULTIPLIER,
  ENEMY_HIT_COOLDOWN,
  SWORD_POINT_STRIKE_SPEED,
  SWORD_SLICING_SPEED,
  SWORD_RECALL_SPEED,
  FROZEN_DECEL_TIME,
  FROZEN_LIFETIME,
  MAX_BULLETS_PER_ENEMY,
  MAX_TOTAL_FROZEN,
  MARBLE_ABSORB_RANGE,
  MARBLE_MAX_ABSORBED,
  MARBLE_ENERGY_COST_HOLD,
  MARBLE_FIRED_SPEED,
  MARBLE_FIRED_DAMAGE,
  MARBLE_FIRE_RATE,
  BOSS_RADIUS,
  BOSS_MAX_HEALTH,
  BOSS_SPEED,
  BOSS_WAVE_INTERVAL,
  PUPPET_RADIUS,
  PUPPET_HEALTH,
  PUPPET_SPEED,
  PUPPET_MELEE_RANGE,
  PUPPET_MELEE_COOLDOWN,
  PUPPET_MELEE_DAMAGE,
  PUPPET_MELEE_PREP_TIME,
  SILK_MAX_HEALTH,
  SILK_COLOR,
  SILK_MAIN_COLOR,
  BOSS_COLORS
} from './constants';
import { SwordState, BulletState, BossState } from './types';
import { Sword as SwordIcon, Shield, Zap, Target, Play, Skull, Magnet } from 'lucide-react';

const App: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const requestRef = useRef<number>(0);
  const keys = useRef<Record<string, boolean>>({});
  const mousePos = useRef<Vector>({ x: 0, y: 0 });
  const mouseClicked = useRef<boolean>(false);
  const lastTime = useRef<number>(0);

  // React state for UI
  const [uiState, setUiState] = useState({
    health: PLAYER_MAX_HEALTH,
    energy: 0,
    wave: 1,
    score: 0,
    isGameOver: false,
    mode: CombatMode.MELEE,
    swordState: SwordState.ORBITING,
    dashCooldown: 0,
  });

  // Game state ref for performance
  const gameState = useRef<GameState>({
    player: {
      id: 'player',
      pos: { x: CANVAS_WIDTH / 2, y: CANVAS_HEIGHT / 2 },
      vel: { x: 0, y: 0 },
      radius: PLAYER_RADIUS,
      health: PLAYER_MAX_HEALTH,
      maxHealth: PLAYER_MAX_HEALTH,
      mode: CombatMode.MELEE,
      energy: 0,
      maxEnergy: PLAYER_MAX_ENERGY,
      dashCooldown: 0,
      attackCooldown: 0,
      isDashing: false,
      dashTimer: 0,
      leftClickTimer: 0,
      isCharging: false,
      absorbedMarbles: [],
      fireTimer: 0,
      spacePressTimer: 0,
    },
    sword: {
      id: 'sword',
      pos: { x: CANVAS_WIDTH / 2, y: CANVAS_HEIGHT / 2 },
      vel: { x: 0, y: 0 },
      radius: SWORD_RADIUS,
      health: 1,
      maxHealth: 1,
      targetPos: { x: 0, y: 0 },
      isActive: true,
      angle: 0,
      rotationSpeed: SWORD_ROTATION_SPEED,
      state: SwordState.ORBITING,
      pressTimer: 0,
    },
    enemies: [],
    boss: null,
    bullets: [],
    particles: [],
    wave: 1,
    enemiesToSpawn: WAVE_BASE_ENEMIES,
    isGameOver: false,
    score: 0,
    screenShake: 0,
  });

  const initGame = () => {
    gameState.current = {
      player: {
        id: 'player',
        pos: { x: CANVAS_WIDTH / 2, y: CANVAS_HEIGHT / 2 },
        vel: { x: 0, y: 0 },
        radius: PLAYER_RADIUS,
        health: PLAYER_MAX_HEALTH,
        maxHealth: PLAYER_MAX_HEALTH,
        mode: CombatMode.MELEE,
        energy: 0,
        maxEnergy: PLAYER_MAX_ENERGY,
        dashCooldown: 0,
        attackCooldown: 0,
        isDashing: false,
        dashTimer: 0,
        leftClickTimer: 0,
        spacePressTimer: 0,
        isCharging: false,
        absorbedMarbles: [],
      },
      sword: {
        id: 'sword',
        pos: { x: CANVAS_WIDTH / 2, y: CANVAS_HEIGHT / 2 },
        vel: { x: 0, y: 0 },
        radius: SWORD_RADIUS,
        health: 1,
        maxHealth: 1,
        targetPos: { x: 0, y: 0 },
        isActive: true,
        angle: 0,
        rotationSpeed: SWORD_ROTATION_SPEED,
        state: SwordState.ORBITING,
        pressTimer: 0,
      },
      enemies: [],
      boss: null,
      bullets: [],
      particles: [],
      wave: 1,
      enemiesToSpawn: WAVE_BASE_ENEMIES,
      isGameOver: false,
      score: 0,
      screenShake: 0,
    };
    setUiState({
      health: PLAYER_MAX_HEALTH,
      energy: 0,
      wave: 1,
      score: 0,
      isGameOver: false,
      mode: CombatMode.MELEE,
      swordState: SwordState.ORBITING,
      dashCooldown: 0,
    });
  };

  const distToSegment = (p: Vector, a: Vector, b: Vector) => {
    const l2 = (a.x - b.x) ** 2 + (a.y - b.y) ** 2;
    if (l2 === 0) return Math.sqrt((p.x - a.x) ** 2 + (p.y - a.y) ** 2);
    let t = ((p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y)) / l2;
    t = Math.max(0, Math.min(1, t));
    return Math.sqrt((p.x - (a.x + t * (b.x - a.x))) ** 2 + (p.y - (a.y + t * (b.y - a.y))) ** 2);
  };

  const spawnBullet = (pos: Vector, vel: Vector, type: BulletType, ownerId: string, color: string = COLORS.BULLET) => {
    gameState.current.bullets.push({
      id: Math.random().toString(36).substr(2, 9),
      pos: { ...pos },
      vel: { ...vel },
      radius: type === BulletType.LARGE ? BULLET_LARGE_RADIUS : BULLET_RADIUS,
      isReflected: false,
      damage: type === BulletType.LARGE ? BULLET_LARGE_DAMAGE : BULLET_DAMAGE,
      color,
      state: BulletState.NORMAL,
      type,
      freezeTimer: 0,
      lifeTimer: 0,
      ownerId,
    });
  };

  const spawnEnemy = (type: EnemyType) => {
    const rand = Math.random();
    let x, y;
    if (rand < 0.5) { // Top (50%)
      x = Math.random() * CANVAS_WIDTH;
      y = -50;
    } else if (rand < 0.75) { // Right (25%)
      x = CANVAS_WIDTH + 50;
      y = Math.random() * CANVAS_HEIGHT;
    } else { // Left (25%)
      x = -50;
      y = Math.random() * CANVAS_HEIGHT;
    }

    const enemy: Enemy = {
      id: Math.random().toString(36).substr(2, 9),
      pos: { x, y },
      vel: { x: 0, y: 0 },
      radius: type === EnemyType.SHOOTER ? ENEMY_SHOOTER_RADIUS : 
              type === EnemyType.TANK ? ENEMY_TANK_RADIUS : 
              type === EnemyType.CASTER ? ENEMY_CASTER_RADIUS : 
              type === EnemyType.PUPPET ? PUPPET_RADIUS :
              ENEMY_HEAVY_RADIUS,
      health: type === EnemyType.SHOOTER ? ENEMY_SHOOTER_HEALTH : 
              type === EnemyType.TANK ? ENEMY_TANK_HEALTH : 
              type === EnemyType.CASTER ? ENEMY_CASTER_HEALTH : 
              type === EnemyType.PUPPET ? PUPPET_HEALTH :
              ENEMY_HEAVY_HEALTH,
      maxHealth: type === EnemyType.SHOOTER ? ENEMY_SHOOTER_HEALTH : 
                 type === EnemyType.TANK ? ENEMY_TANK_HEALTH : 
                 type === EnemyType.CASTER ? ENEMY_CASTER_HEALTH : 
                 type === EnemyType.PUPPET ? PUPPET_HEALTH :
                 ENEMY_HEAVY_HEALTH,
      type,
      shootCooldown: Math.random() * 60,
      moveTimer: 0,
      targetPos: { x: Math.random() * CANVAS_WIDTH, y: Math.random() * CANVAS_HEIGHT },
      hitCooldown: 0,
      lastHitBySword: false,
      meleeTimer: 0,
    };
    gameState.current.enemies.push(enemy);
  };

  const spawnBoss = () => {
    gameState.current.boss = {
      id: 'boss-' + Date.now(),
      pos: { x: CANVAS_WIDTH / 2, y: -150 },
      vel: { x: 0, y: 0 },
      radius: BOSS_RADIUS,
      health: BOSS_MAX_HEALTH,
      maxHealth: BOSS_MAX_HEALTH,
      state: BossState.IDLE,
      stateTimer: 180,
      phase: 1,
      silks: [],
      isVulnerable: false,
      vulnerableTimer: 0,
      moveTimer: 0,
      targetPos: { x: CANVAS_WIDTH / 2, y: 150 },
    };
  };

  const createParticle = (pos: Vector, color: string, count = 1) => {
    for (let i = 0; i < count; i++) {
      gameState.current.particles.push({
        id: Math.random().toString(36).substr(2, 9),
        pos: { ...pos },
        vel: { 
          x: (Math.random() - 0.5) * 5, 
          y: (Math.random() - 0.5) * 5 
        },
        life: 30 + Math.random() * 20,
        maxLife: 50,
        color,
        size: 2 + Math.random() * 3,
      });
    }
  };

  const fireSingleAbsorbedMarble = () => {
    const { player, bullets } = gameState.current;
    if (player.absorbedMarbles.length === 0) return;
    
    const id = player.absorbedMarbles.shift();
    const b = bullets.find(bullet => bullet.id === id);
    if (b) {
      const attackAngle = Math.atan2(mousePos.current.y - player.pos.y, mousePos.current.x - player.pos.x);
      b.state = BulletState.FIRED;
      b.vel.x = Math.cos(attackAngle) * MARBLE_FIRED_SPEED;
      b.vel.y = Math.sin(attackAngle) * MARBLE_FIRED_SPEED;
      createParticle(b.pos, COLORS.FROZEN_MARBLE, 5);
      gameState.current.screenShake = 2;
    }
  };

  const updateBoss = (dt: number, bulletTimeDt: number) => {
    const { boss, player, sword, enemies, bullets } = gameState.current;
    if (!boss) return;

    // Movement
    const dx = boss.targetPos.x - boss.pos.x;
    const dy = boss.targetPos.y - boss.pos.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    if (dist > 5) {
      boss.pos.x += (dx / dist) * BOSS_SPEED * dt;
      boss.pos.y += (dy / dist) * BOSS_SPEED * dt;
    }

    boss.stateTimer -= bulletTimeDt;

    // Update Silks positions
    boss.silks.forEach(silk => {
      silk.from = { ...boss.pos };
      const target = enemies.find(e => e.id === silk.id);
      if (target) {
        silk.to = { ...target.pos };
      }
    });

    // Silk Collision with Sword
    if (sword.state === SwordState.SLICING || sword.state === SwordState.POINT_STRIKE) {
      boss.silks.forEach(silk => {
        if (silk.isActive) {
          if (distToSegment(sword.pos, silk.from, silk.to) < sword.radius + 5) {
            const damage = sword.state === SwordState.POINT_STRIKE ? 5 : 0.5;
            silk.health -= damage * dt;
            if (silk.health <= 0) {
              silk.isActive = false;
              createParticle(sword.pos, BOSS_COLORS.SILK, 20);
              const puppet = enemies.find(e => e.id === silk.id);
              if (puppet) {
                puppet.health = 0; // Puppet dies when silk is cut
                createParticle(puppet.pos, BOSS_COLORS.PUPPET, 30);
              }
            }
          }
        }
      });
    }

    // State Machine
    if (boss.stateTimer <= 0) {
      const nextStates = [
        BossState.THOUSAND_SILKS,
        BossState.PUPPET_AMBUSH,
        BossState.SILK_CAGE,
        BossState.NEEDLE_RETURN,
      ];
      
      let possibleStates = nextStates;
      if (boss.phase === 1) {
        possibleStates = [BossState.THOUSAND_SILKS, BossState.PUPPET_AMBUSH];
      }

      const nextState = possibleStates[Math.floor(Math.random() * possibleStates.length)];
      boss.state = nextState;
      
      switch (nextState) {
        case BossState.THOUSAND_SILKS:
          boss.stateTimer = 240;
          boss.targetPos = { x: CANVAS_WIDTH / 2, y: 100 };
          break;
        case BossState.PUPPET_AMBUSH:
          boss.stateTimer = 400;
          boss.targetPos = { x: CANVAS_WIDTH / 2, y: 100 };
          spawnPuppets(boss.phase === 1 ? 2 : 4);
          break;
        case BossState.SILK_CAGE:
          boss.stateTimer = 300;
          boss.targetPos = { x: CANVAS_WIDTH / 2, y: CANVAS_HEIGHT / 2 };
          break;
        case BossState.NEEDLE_RETURN:
          boss.stateTimer = 200;
          boss.targetPos = { x: CANVAS_WIDTH / 2, y: 150 };
          break;
      }
    }

    // State Actions
    switch (boss.state) {
      case BossState.THOUSAND_SILKS:
        if (Math.floor(boss.stateTimer) % 30 === 0) {
          for (let i = -3; i <= 3; i++) {
            const angle = Math.PI / 2 + i * 0.25;
            spawnBullet(boss.pos, { x: Math.cos(angle) * 4, y: Math.sin(angle) * 4 }, BulletType.SMALL, boss.id, BOSS_COLORS.SILK);
          }
        }
        break;
      case BossState.NEEDLE_RETURN:
        if (Math.floor(boss.stateTimer) % 8 === 0) {
          const angle = Math.random() * Math.PI * 2;
          const spawnPos = {
            x: player.pos.x + Math.cos(angle) * 400,
            y: player.pos.y + Math.sin(angle) * 400
          };
          const velAngle = Math.atan2(player.pos.y - spawnPos.y, player.pos.x - spawnPos.x);
          spawnBullet(spawnPos, { x: Math.cos(velAngle) * 6, y: Math.sin(velAngle) * 6 }, BulletType.SMALL, boss.id, BOSS_COLORS.SILK);
        }
        break;
      case BossState.SILK_CAGE:
        if (Math.floor(boss.stateTimer) % 60 === 0) {
           // Create temporary silk walls? Or just more puppets
           spawnPuppets(1);
        }
        break;
    }

    // Phase transition
    if (boss.phase === 1 && boss.health < boss.maxHealth * 0.7) boss.phase = 2;
    if (boss.phase === 2 && boss.health < boss.maxHealth * 0.3) boss.phase = 3;

    // Boss vulnerability
    if (boss.silks.filter(s => s.isActive).length === 0 && boss.state === BossState.PUPPET_AMBUSH) {
        boss.isVulnerable = true;
        boss.vulnerableTimer = 120;
    }
  };

  const spawnPuppets = (count: number) => {
    const { boss } = gameState.current;
    if (!boss) return;
    
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const dist = 200 + Math.random() * 100;
      const x = CANVAS_WIDTH / 2 + Math.cos(angle) * dist;
      const y = CANVAS_HEIGHT / 2 + Math.sin(angle) * dist;
      
      const puppetId = 'puppet-' + Date.now() + Math.random();
      spawnEnemy(EnemyType.PUPPET);
      const puppet = gameState.current.enemies[gameState.current.enemies.length - 1];
      puppet.id = puppetId;
      puppet.pos = { x, y };
      puppet.targetPos = { x, y };
      puppet.meleeTimer = 0;
      
      boss.silks.push({
        id: puppetId,
        from: { ...boss.pos },
        to: { ...puppet.pos },
        isMain: false,
        health: SILK_MAX_HEALTH,
        maxHealth: SILK_MAX_HEALTH,
        isActive: true,
      });
    }
  };

  const update = (time: number) => {
    if (gameState.current.isGameOver) return;

    // Calculate deltaTime (baseline 60fps)
    const dt = lastTime.current ? (time - lastTime.current) / (1000 / 60) : 1;
    lastTime.current = time;

    const { player, sword, enemies, bullets, particles } = gameState.current;

    // Bullet Time Logic
    const isFlyingSwordActive = sword.state !== SwordState.ORBITING;
    const bulletTimeDt = dt * (isFlyingSwordActive ? BULLET_TIME_MULTIPLIER : 1);
    const playerSpeedDt = dt * (isFlyingSwordActive ? PLAYER_BULLET_TIME_SPEED_MULTIPLIER : 1);

    // RMB Input Tracking
    if (keys.current['mouse2']) { // Right mouse button
      sword.pressTimer += dt / 60; // Convert to seconds
      if (sword.pressTimer > SWORD_TAP_THRESHOLD && sword.state === SwordState.ORBITING) {
        sword.state = SwordState.SLICING;
        player.mode = CombatMode.RANGED;
      }
    }

    // LMB Input Tracking (Melee & Sequential Fire)
    if (mouseClicked.current) {
      player.leftClickTimer += dt / 60;
      
      // Melee Attack (Initial or tap)
      if (player.attackCooldown <= 0 && player.leftClickTimer < SWORD_TAP_THRESHOLD && sword.state === SwordState.ORBITING) {
        player.attackCooldown = SWORD_MELEE_COOLDOWN;
        const attackAngle = Math.atan2(mousePos.current.y - player.pos.y, mousePos.current.x - player.pos.x);
        
        // Deflect bullets
        for (let i = bullets.length - 1; i >= 0; i--) {
          const b = bullets[i];
          const dx = b.pos.x - player.pos.x;
          const dy = b.pos.y - player.pos.y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          const angleToBullet = Math.atan2(dy, dx);
          
          let angleDiff = angleToBullet - attackAngle;
          while (angleDiff > Math.PI) angleDiff -= Math.PI * 2;
          while (angleDiff < -Math.PI) angleDiff += Math.PI * 2;

          if (dist < SWORD_MELEE_RANGE + 20 && Math.abs(angleDiff) < SWORD_MELEE_ARC / 2) {
            if (b.state === BulletState.NORMAL && !b.isReflected) {
              // All bullets: Enter frozen state
              b.state = BulletState.FREEZING;
              b.freezeTimer = FROZEN_DECEL_TIME;
              b.lifeTimer = FROZEN_LIFETIME;
              const energyGain = b.type === BulletType.SMALL ? ENERGY_GAIN_MELEE_DEFLECT : ENERGY_GAIN_MELEE_DEFLECT * 1.5;
              player.energy = Math.min(player.maxEnergy, player.energy + energyGain);
              createParticle(b.pos, COLORS.FROZEN_MARBLE, b.type === BulletType.SMALL ? 5 : 8);
              gameState.current.screenShake = b.type === BulletType.SMALL ? 2 : 4;
            }
          }
        }

        // Damage enemies
        enemies.forEach(e => {
          const dx = e.pos.x - player.pos.x;
          const dy = e.pos.y - player.pos.y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          const angleToEnemy = Math.atan2(dy, dx);
          
          let angleDiff = angleToEnemy - attackAngle;
          while (angleDiff > Math.PI) angleDiff -= Math.PI * 2;
          while (angleDiff < -Math.PI) angleDiff += Math.PI * 2;

          if (dist < SWORD_MELEE_RANGE + e.radius && Math.abs(angleDiff) < SWORD_MELEE_ARC / 2 && e.type !== EnemyType.PUPPET) {
            e.health -= SWORD_MELEE_DAMAGE;
            e.lastHitBySword = false;
            player.energy = Math.min(player.maxEnergy, player.energy + ENERGY_GAIN_MELEE_HIT);
            createParticle(e.pos, COLORS.ENEMY_SHOOTER, 5);
            gameState.current.screenShake = 4;
          }
        });
      }

      // Sequential Fire (Long press)
      if (player.leftClickTimer > SWORD_TAP_THRESHOLD && player.absorbedMarbles.length > 0) {
        player.fireTimer -= dt / 60;
        if (player.fireTimer <= 0) {
          player.fireTimer = MARBLE_FIRE_RATE;
          fireSingleAbsorbedMarble();
        }
      }
    }

    // Space Input Tracking (Absorption Only)
    if (keys.current[' ']) {
      player.isCharging = true;
      // Absorb marbles
      if (player.energy > 0) {
        player.energy = Math.max(0, player.energy - MARBLE_ENERGY_COST_HOLD * dt);
        bullets.forEach(b => {
          if (b.state === BulletState.FROZEN && !player.absorbedMarbles.includes(b.id) && player.absorbedMarbles.length < MARBLE_MAX_ABSORBED) {
            const dx = b.pos.x - player.pos.x;
            const dy = b.pos.y - player.pos.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < MARBLE_ABSORB_RANGE) {
              player.absorbedMarbles.push(b.id);
            }
          }
        });
      } else {
         player.isCharging = false;
         keys.current[' '] = false; // Force release
      }
    } else {
      player.isCharging = false;
    }

    // Player Movement
    let dxMove = 0;
    let dyMove = 0;
    if (keys.current['w'] || keys.current['ArrowUp']) dyMove -= 1;
    if (keys.current['s'] || keys.current['ArrowDown']) dyMove += 1;
    if (keys.current['a'] || keys.current['ArrowLeft']) dxMove -= 1;
    if (keys.current['d'] || keys.current['ArrowRight']) dxMove += 1;

    if (dxMove !== 0 || dyMove !== 0) {
      const mag = Math.sqrt(dxMove * dxMove + dyMove * dyMove);
      player.vel.x = (dxMove / mag) * PLAYER_SPEED;
      player.vel.y = (dyMove / mag) * PLAYER_SPEED;
    } else {
      player.vel.x *= Math.pow(0.8, dt);
      player.vel.y *= Math.pow(0.8, dt);
    }

    if (player.attackCooldown > 0) player.attackCooldown -= dt;

    player.pos.x += player.vel.x * playerSpeedDt;
    player.pos.y += player.vel.y * playerSpeedDt;

    // Bounds check
    player.pos.x = Math.max(player.radius, Math.min(CANVAS_WIDTH - player.radius, player.pos.x));
    player.pos.y = Math.max(player.radius, Math.min(CANVAS_HEIGHT - player.radius, player.pos.y));

    // Sword Logic
    if (sword.state === SwordState.ORBITING) {
      // Natural energy recovery in melee mode
      player.energy = Math.min(player.maxEnergy, player.energy + ENERGY_RECOVERY_MELEE_NATURAL * dt);

      // Sword orbits player or stays close
      const targetX = player.pos.x + Math.cos(sword.angle) * 25;
      const targetY = player.pos.y + Math.sin(sword.angle) * 25;
      sword.pos.x += (targetX - sword.pos.x) * 0.3;
      sword.pos.y += (targetY - sword.pos.y) * 0.3;
      sword.angle += sword.rotationSpeed;
    } else {
      // Flying Sword States
      if (sword.state === SwordState.SLICING) {
        player.energy -= ENERGY_CONSUMPTION_RANGED * dt;
        if (player.energy <= 0) {
          player.energy = 0;
          sword.state = SwordState.RECALLING;
        }

        // Follow mouse - Ultra-Sticky Lerp Logic
        const lerpFactor = 0.6; // High responsiveness
        sword.pos.x += (mousePos.current.x - sword.pos.x) * lerpFactor * dt;
        sword.pos.y += (mousePos.current.y - sword.pos.y) * lerpFactor * dt;
        
        // Update velocity for angle calculation
        sword.vel.x = (mousePos.current.x - sword.pos.x) / dt;
        sword.vel.y = (mousePos.current.y - sword.pos.y) / dt;
      } else {
        if (sword.state === SwordState.POINT_STRIKE) {
          // Fly to target
          const dx = sword.targetPos.x - sword.pos.x;
          const dy = sword.targetPos.y - sword.pos.y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          const moveDist = SWORD_POINT_STRIKE_SPEED * dt;

          if (dist > moveDist && dist > 10) {
            sword.vel.x = (dx / dist) * SWORD_POINT_STRIKE_SPEED;
            sword.vel.y = (dy / dist) * SWORD_POINT_STRIKE_SPEED;
          } else {
            // Reached or overshot target
            sword.pos.x = sword.targetPos.x;
            sword.pos.y = sword.targetPos.y;
            sword.vel.x = 0;
            sword.vel.y = 0;
            sword.state = SwordState.RECALLING;
            gameState.current.screenShake = 6;
            createParticle(sword.pos, COLORS.RANGED_SWORD, 10);
          }
        } else if (sword.state === SwordState.RECALLING) {
          // Fly back to player
          const dx = player.pos.x - sword.pos.x;
          const dy = player.pos.y - sword.pos.y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          const moveDist = SWORD_RECALL_SPEED * dt;

          if (dist > moveDist && dist > 20) {
            sword.vel.x = (dx / dist) * SWORD_RECALL_SPEED;
            sword.vel.y = (dy / dist) * SWORD_RECALL_SPEED;
          } else {
            // Reached or overshot player
            sword.pos.x = player.pos.x;
            sword.pos.y = player.pos.y;
            sword.vel.x = 0;
            sword.vel.y = 0;
            sword.state = SwordState.ORBITING;
            player.mode = CombatMode.MELEE;
            sword.pressTimer = 0;
          }
        }

        sword.pos.x += sword.vel.x * dt;
        sword.pos.y += sword.vel.y * dt;
      }
      
      sword.angle = Math.atan2(sword.vel.y, sword.vel.x);

      // Damage enemies on contact (for all flying states)
      enemies.forEach(e => {
        const dx = e.pos.x - sword.pos.x;
        const dy = e.pos.y - sword.pos.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < sword.radius + e.radius && e.hitCooldown <= 0 && e.type !== EnemyType.PUPPET) {
          e.health -= SWORD_RANGED_DAMAGE * (sword.state === SwordState.POINT_STRIKE ? 1.5 : 0.5);
          e.hitCooldown = ENEMY_HIT_COOLDOWN;
          e.lastHitBySword = true;
          createParticle(sword.pos, COLORS.RANGED_SWORD, 3);
          if (sword.state === SwordState.POINT_STRIKE) gameState.current.screenShake = 3;
        }
      });

      // Damage Boss on contact
      if (gameState.current.boss) {
        const b = gameState.current.boss;
        const dx = b.pos.x - sword.pos.x;
        const dy = b.pos.y - sword.pos.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < sword.radius + b.radius && (b.isVulnerable || b.phase === 1)) {
          b.health -= SWORD_RANGED_DAMAGE * (sword.state === SwordState.POINT_STRIKE ? 1.5 : 0.5) * dt;
          createParticle(sword.pos, BOSS_COLORS.BODY, 2);
        }
      }
    }

    // Update Boss
    if (gameState.current.boss) {
      updateBoss(dt, bulletTimeDt);
    }

    // Enemies Logic
    for (let i = enemies.length - 1; i >= 0; i--) {
      const e = enemies[i];
      if (e.hitCooldown > 0) e.hitCooldown -= dt / 60;
      
      // Movement
      const dx = player.pos.x - e.pos.x;
      const dy = player.pos.y - e.pos.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      
      if (e.type === EnemyType.SHOOTER) {
        if (dist > 200) {
          e.pos.x += (dx / dist) * ENEMY_SHOOTER_SPEED * bulletTimeDt;
          e.pos.y += (dy / dist) * ENEMY_SHOOTER_SPEED * bulletTimeDt;
        } else if (dist < 150) {
          e.pos.x -= (dx / dist) * ENEMY_SHOOTER_SPEED * bulletTimeDt;
          e.pos.y -= (dy / dist) * ENEMY_SHOOTER_SPEED * bulletTimeDt;
        }
        
        e.shootCooldown -= bulletTimeDt;
        if (e.shootCooldown <= 0) {
          e.shootCooldown = ENEMY_SHOOTER_COOLDOWN;
          bullets.push({
            id: Math.random().toString(36).substr(2, 9),
            pos: { ...e.pos },
            vel: { x: (dx / dist) * BULLET_SPEED, y: (dy / dist) * BULLET_SPEED },
            radius: BULLET_RADIUS,
            isReflected: false,
            damage: BULLET_DAMAGE,
            color: COLORS.BULLET,
            state: BulletState.NORMAL,
            type: BulletType.SMALL,
            freezeTimer: 0,
            lifeTimer: 0,
            ownerId: e.id,
          });
        }
      } else if (e.type === EnemyType.TANK) {
        e.pos.x += (dx / dist) * ENEMY_TANK_SPEED * bulletTimeDt;
        e.pos.y += (dy / dist) * ENEMY_TANK_SPEED * bulletTimeDt;
        
        // Contact damage
        if (dist < e.radius + player.radius && !player.isDashing) {
          player.health -= 0.5 * bulletTimeDt;
          gameState.current.screenShake = 2;
        }
      } else if (e.type === EnemyType.CASTER) {
        // Moves randomly to stay away
        e.moveTimer -= bulletTimeDt;
        if (e.moveTimer <= 0) {
          e.moveTimer = 60 + Math.random() * 60;
          const angle = Math.random() * Math.PI * 2;
          e.vel.x = Math.cos(angle) * ENEMY_CASTER_SPEED;
          e.vel.y = Math.sin(angle) * ENEMY_CASTER_SPEED;
        }
        e.pos.x += e.vel.x * bulletTimeDt;
        e.pos.y += e.vel.y * bulletTimeDt;
        
        // Keep in bounds
        e.pos.x = Math.max(e.radius, Math.min(CANVAS_WIDTH - e.radius, e.pos.x));
        e.pos.y = Math.max(e.radius, Math.min(CANVAS_HEIGHT - e.radius, e.pos.y));

        e.shootCooldown -= bulletTimeDt;
        if (e.shootCooldown <= 0) {
          e.shootCooldown = ENEMY_CASTER_COOLDOWN;
          // Spiral pattern
          for (let j = 0; j < 8; j++) {
            const angle = (j / 8) * Math.PI * 2;
            bullets.push({
              id: Math.random().toString(36).substr(2, 9),
              pos: { ...e.pos },
              vel: { x: Math.cos(angle) * BULLET_SPEED * 0.7, y: Math.sin(angle) * BULLET_SPEED * 0.7 },
              radius: BULLET_RADIUS * 1.5,
              isReflected: false,
              damage: BULLET_DAMAGE * 1.5,
              color: COLORS.ENEMY_CASTER,
              state: BulletState.NORMAL,
              type: BulletType.SMALL,
              freezeTimer: 0,
              lifeTimer: 0,
              ownerId: e.id,
            });
          }
        }
      } else if (e.type === EnemyType.HEAVY) {
        // Moves slowly towards player
        e.pos.x += (dx / dist) * ENEMY_HEAVY_SPEED * bulletTimeDt;
        e.pos.y += (dy / dist) * ENEMY_HEAVY_SPEED * bulletTimeDt;

        e.shootCooldown -= bulletTimeDt;
        if (e.shootCooldown <= 0) {
          e.shootCooldown = ENEMY_HEAVY_COOLDOWN;
          bullets.push({
            id: Math.random().toString(36).substr(2, 9),
            pos: { ...e.pos },
            vel: { x: (dx / dist) * BULLET_LARGE_SPEED, y: (dy / dist) * BULLET_LARGE_SPEED },
            radius: BULLET_LARGE_RADIUS,
            isReflected: false,
            damage: BULLET_LARGE_DAMAGE,
            color: COLORS.ENEMY_HEAVY,
            state: BulletState.NORMAL,
            type: BulletType.LARGE,
            freezeTimer: 0,
            lifeTimer: 0,
            ownerId: e.id,
          });
        }
      } else if (e.type === EnemyType.PUPPET) {
        // Safety check: if boss is gone or silk is gone, puppet should die
        const boss = gameState.current.boss;
        const silk = boss?.silks.find(s => s.id === e.id);
        if (!boss || !silk || !silk.isActive) {
          e.health = 0;
        }
        
        // Puppets move towards player and perform melee attacks
        if (e.meleeTimer <= 0) {
          // Move towards player
          if (dist > PUPPET_MELEE_RANGE * 0.8) {
            e.pos.x += (dx / dist) * PUPPET_SPEED * bulletTimeDt;
            e.pos.y += (dy / dist) * PUPPET_SPEED * bulletTimeDt;
          }
          
          // Start melee attack if close
          if (dist < PUPPET_MELEE_RANGE) {
            e.meleeTimer = PUPPET_MELEE_COOLDOWN;
          }
        } else {
          // Attack logic
          const prevTimer = e.meleeTimer;
          e.meleeTimer -= bulletTimeDt;
          
          const attackProgress = PUPPET_MELEE_COOLDOWN - e.meleeTimer;
          const prevProgress = PUPPET_MELEE_COOLDOWN - prevTimer;
          
          // During prep time, maybe move slightly slower or stop
          if (attackProgress < PUPPET_MELEE_PREP_TIME) {
             // Wind-up
          } else if (prevProgress < PUPPET_MELEE_PREP_TIME && attackProgress >= PUPPET_MELEE_PREP_TIME) {
            // Strike!
            if (dist < PUPPET_MELEE_RANGE + 10 && !player.isDashing) {
              player.health -= PUPPET_MELEE_DAMAGE;
              gameState.current.screenShake = 5;
              createParticle(player.pos, BOSS_COLORS.PUPPET, 10);
            }
          }
        }
      }

      if (e.health <= 0) {
        createParticle(e.pos, e.type === EnemyType.PUPPET ? BOSS_COLORS.PUPPET : COLORS.ENEMY_SHOOTER, 15);
        
        enemies.splice(i, 1);
        if (e.type !== EnemyType.PUPPET) {
          gameState.current.score += e.type === EnemyType.TANK ? 50 : e.type === EnemyType.HEAVY ? 40 : 20;
          // Use consistent energy gain constant
          player.energy = Math.min(player.maxEnergy, player.energy + ENERGY_GAIN_MELEE_HIT * 2);
        }
      }
    }

    // Bullets Logic
    for (let i = bullets.length - 1; i >= 0; i--) {
      const b = bullets[i];
      
      if (b.state === BulletState.FREEZING) {
        b.freezeTimer -= dt / 60;
        if (b.freezeTimer <= 0) {
          b.state = BulletState.FROZEN;
          b.vel.x = 0;
          b.vel.y = 0;
        } else {
          const ratio = b.freezeTimer / FROZEN_DECEL_TIME;
          b.vel.x *= ratio;
          b.vel.y *= ratio;
        }
      } else if (b.state === BulletState.FROZEN) {
        if (!player.absorbedMarbles.includes(b.id)) {
          b.lifeTimer -= dt / 60;
          if (b.lifeTimer <= 0) {
            bullets.splice(i, 1);
            continue;
          }
        }
        
        // If being absorbed, move towards player
        if (player.absorbedMarbles.includes(b.id)) {
          const dx = player.pos.x - b.pos.x;
          const dy = player.pos.y - b.pos.y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist > 40) {
             b.pos.x += (dx / dist) * 15 * dt;
             b.pos.y += (dy / dist) * 15 * dt;
          } else {
             // Orbit logic
             const index = player.absorbedMarbles.indexOf(b.id);
             const orbitAngle = (time / 200) + (index * Math.PI * 2 / MARBLE_MAX_ABSORBED);
             b.pos.x = player.pos.x + Math.cos(orbitAngle) * 40;
             b.pos.y = player.pos.y + Math.sin(orbitAngle) * 40;
          }
        }
      } else if (b.state === BulletState.FIRED) {
         // Fired marbles move fast and hit enemies
         b.pos.x += b.vel.x * dt;
         b.pos.y += b.vel.y * dt;
         
         for (let j = enemies.length - 1; j >= 0; j--) {
           const e = enemies[j];
           const dx = b.pos.x - e.pos.x;
           const dy = b.pos.y - e.pos.y;
           const dist = Math.sqrt(dx * dx + dy * dy);
           if (dist < b.radius + e.radius && e.type !== EnemyType.PUPPET) {
             e.health -= MARBLE_FIRED_DAMAGE;
             createParticle(b.pos, COLORS.FROZEN_MARBLE, 10);
             bullets.splice(i, 1);
             break;
           }
         }
         
         // Hit Boss
         if (gameState.current.boss && bullets[i] === b) {
           const boss = gameState.current.boss;
           const dx = b.pos.x - boss.pos.x;
           const dy = b.pos.y - boss.pos.y;
           const dist = Math.sqrt(dx * dx + dy * dy);
           if (dist < b.radius + boss.radius && (boss.isVulnerable || boss.phase === 1)) {
             boss.health -= MARBLE_FIRED_DAMAGE * 2; // Fired marbles deal more damage to boss
             createParticle(b.pos, COLORS.FROZEN_MARBLE, 15);
             bullets.splice(i, 1);
           }
         }
         
         if (bullets[i] === b) { // If not spliced
            if (b.pos.x < -50 || b.pos.x > CANVAS_WIDTH + 50 || b.pos.y < -50 || b.pos.y > CANVAS_HEIGHT + 50) {
              bullets.splice(i, 1);
            }
         }
         continue;
      } else {
        // NORMAL state
        b.pos.x += b.vel.x * bulletTimeDt;
        b.pos.y += b.vel.y * bulletTimeDt;
      }

      // Offscreen (for normal bullets)
      if (b.state === BulletState.NORMAL) {
        if (b.pos.x < -50 || b.pos.x > CANVAS_WIDTH + 50 || b.pos.y < -50 || b.pos.y > CANVAS_HEIGHT + 50) {
          bullets.splice(i, 1);
          continue;
        }
      }

      if (b.state === BulletState.NORMAL) {
        if (b.isReflected) {
          // Hit enemies
          for (let j = enemies.length - 1; j >= 0; j--) {
            const e = enemies[j];
            const dx = b.pos.x - e.pos.x;
            const dy = b.pos.y - e.pos.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < b.radius + e.radius && e.type !== EnemyType.PUPPET) {
              e.health -= 10;
              createParticle(b.pos, COLORS.BULLET_REFLECTED, 5);
              bullets.splice(i, 1);
              break;
            }
          }
          
          
          // Hit Boss
          if (bullets[i] === b && gameState.current.boss) {
            const bBoss = gameState.current.boss;
            const dx = b.pos.x - bBoss.pos.x;
            const dy = b.pos.y - bBoss.pos.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < b.radius + bBoss.radius && (bBoss.isVulnerable || bBoss.phase === 1)) {
              bBoss.health -= 10;
              createParticle(b.pos, COLORS.BULLET_REFLECTED, 5);
              bullets.splice(i, 1);
              continue;
            }
          }
        } else {
          // Hit player
          const dx = b.pos.x - player.pos.x;
          const dy = b.pos.y - player.pos.y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < b.radius + player.radius && !player.isDashing) {
            player.health -= b.damage;
            createParticle(b.pos, COLORS.BULLET, 5);
            bullets.splice(i, 1);
            gameState.current.screenShake = 5;
          }
        }
      }
    }

    // Particles Logic
    for (let i = particles.length - 1; i >= 0; i--) {
      const p = particles[i];
      p.pos.x += p.vel.x * bulletTimeDt;
      p.pos.y += p.vel.y * bulletTimeDt;
      p.life -= bulletTimeDt;
      if (p.life <= 0) particles.splice(i, 1);
    }

    // Wave Logic
    if (enemies.length === 0 && gameState.current.enemiesToSpawn <= 0 && !gameState.current.boss) {
      gameState.current.wave++;
      if (gameState.current.wave % BOSS_WAVE_INTERVAL === 0) {
        spawnBoss();
        gameState.current.enemiesToSpawn = 0;
      } else {
        gameState.current.enemiesToSpawn = WAVE_BASE_ENEMIES + gameState.current.wave * 2;
      }
    }

    if (gameState.current.boss && gameState.current.boss.health <= 0) {
      createParticle(gameState.current.boss.pos, BOSS_COLORS.BODY, 50);
      gameState.current.boss = null;
      gameState.current.score += 5000;
      gameState.current.enemiesToSpawn = WAVE_BASE_ENEMIES + gameState.current.wave * 2;
    }

    if (gameState.current.enemiesToSpawn > 0 && Math.random() < 0.01) {
      const rand = Math.random();
      let type = EnemyType.SHOOTER;
      if (rand > 0.6) type = EnemyType.TANK;
      if (rand > 0.8) type = EnemyType.CASTER;
      if (rand > 0.9) type = EnemyType.HEAVY;
      spawnEnemy(type);
      gameState.current.enemiesToSpawn--;
    }

    // Game Over Check
    if (player.health <= 0) {
      gameState.current.isGameOver = true;
      setUiState(prev => ({ ...prev, isGameOver: true }));
    }

    // Update UI State
    setUiState({
      health: player.health,
      energy: player.energy,
      wave: gameState.current.wave,
      score: gameState.current.score,
      isGameOver: gameState.current.isGameOver,
      mode: player.mode,
      swordState: sword.state,
      dashCooldown: player.dashCooldown,
    });

    if (gameState.current.screenShake > 0) gameState.current.screenShake *= 0.9;
    if (gameState.current.screenShake < 0.1) gameState.current.screenShake = 0;

    draw();
    requestRef.current = requestAnimationFrame(update);
  };

  const drawBoss = (ctx: CanvasRenderingContext2D) => {
    const { boss } = gameState.current;
    if (!boss) return;

    // Draw Silks
    boss.silks.forEach(silk => {
      if (silk.isActive) {
        ctx.strokeStyle = silk.isMain ? BOSS_COLORS.SILK_MAIN : BOSS_COLORS.SILK;
        ctx.lineWidth = silk.isMain ? 3 : 1;
        ctx.beginPath();
        ctx.moveTo(silk.from.x, silk.from.y);
        ctx.lineTo(silk.to.x, silk.to.y);
        ctx.stroke();
        
        // Health bar for silk if damaged
        if (silk.health < silk.maxHealth) {
            const midX = (silk.from.x + silk.to.x) / 2;
            const midY = (silk.from.y + silk.to.y) / 2;
            ctx.fillStyle = '#444';
            ctx.fillRect(midX - 15, midY - 2, 30, 4);
            ctx.fillStyle = BOSS_COLORS.SILK;
            ctx.fillRect(midX - 15, midY - 2, 30 * (silk.health / silk.maxHealth), 4);
        }
      }
    });

    // Draw Boss Body
    ctx.fillStyle = boss.isVulnerable ? BOSS_COLORS.VULNERABLE : BOSS_COLORS.BODY;
    ctx.beginPath();
    ctx.arc(boss.pos.x, boss.pos.y, boss.radius, 0, Math.PI * 2);
    ctx.fill();
    
    // Boss Glow
    ctx.shadowBlur = 20;
    ctx.shadowColor = BOSS_COLORS.BODY;
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Boss Health Bar
    const barWidth = 400;
    const barHeight = 10;
    const x = (CANVAS_WIDTH - barWidth) / 2;
    const y = 40;
    
    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(x, y, barWidth, barHeight);
    ctx.fillStyle = BOSS_COLORS.BODY;
    ctx.fillRect(x, y, barWidth * (boss.health / boss.maxHealth), barHeight);
    ctx.strokeStyle = '#fff';
    ctx.strokeRect(x, y, barWidth, barHeight);
    
    // Boss Name
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 16px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('千机傀宗·玄丝上人', CANVAS_WIDTH / 2, y - 10);
  };

  const draw = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const { player, sword, enemies, bullets, particles, screenShake } = gameState.current;

    ctx.save();
    if (screenShake > 0) {
      ctx.translate((Math.random() - 0.5) * screenShake, (Math.random() - 0.5) * screenShake);
    }

    // Clear
    ctx.fillStyle = COLORS.BACKGROUND;
    ctx.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);

    // Arena Grid
    ctx.strokeStyle = '#222';
    ctx.lineWidth = 1;
    for (let x = 0; x < CANVAS_WIDTH; x += 50) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, CANVAS_HEIGHT);
      ctx.stroke();
    }
    for (let y = 0; y < CANVAS_HEIGHT; y += 50) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(CANVAS_WIDTH, y);
      ctx.stroke();
    }

    drawBoss(ctx);

    // Particles
    particles.forEach(p => {
      ctx.globalAlpha = p.life / p.maxLife;
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.pos.x, p.pos.y, p.size, 0, Math.PI * 2);
      ctx.fill();
    });
    ctx.globalAlpha = 1;

    // Bullets
    bullets.forEach(b => {
      if (b.state === BulletState.FROZEN || b.state === BulletState.FREEZING) {
        ctx.fillStyle = COLORS.FROZEN_MARBLE;
        ctx.beginPath();
        ctx.arc(b.pos.x, b.pos.y, b.radius * 1.2, 0, Math.PI * 2);
        ctx.fill();
        
        // Extra Glow
        ctx.shadowBlur = 15;
        ctx.shadowColor = COLORS.FROZEN_MARBLE;
        ctx.strokeStyle = '#fff';
        ctx.lineWidth = 1;
        ctx.stroke();
        ctx.shadowBlur = 0;
      } else if (b.state === BulletState.FIRED) {
        ctx.fillStyle = COLORS.FROZEN_MARBLE;
        ctx.beginPath();
        ctx.arc(b.pos.x, b.pos.y, b.radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowBlur = 10;
        ctx.shadowColor = COLORS.FROZEN_MARBLE;
        ctx.stroke();
        ctx.shadowBlur = 0;
      } else {
        ctx.fillStyle = b.color;
        ctx.beginPath();
        ctx.arc(b.pos.x, b.pos.y, b.radius, 0, Math.PI * 2);
        ctx.fill();
        
        // Glow
        ctx.shadowBlur = 10;
        ctx.shadowColor = b.color;
        ctx.stroke();
        ctx.shadowBlur = 0;
      }
    });

    // Enemies
    enemies.forEach(e => {
      ctx.fillStyle = e.type === EnemyType.SHOOTER ? COLORS.ENEMY_SHOOTER : 
                      e.type === EnemyType.TANK ? COLORS.ENEMY_TANK : 
                      e.type === EnemyType.CASTER ? COLORS.ENEMY_CASTER : 
                      e.type === EnemyType.PUPPET ? BOSS_COLORS.PUPPET :
                      COLORS.ENEMY_HEAVY;
      ctx.beginPath();
      ctx.arc(e.pos.x, e.pos.y, e.radius, 0, Math.PI * 2);
      ctx.fill();
      
      // Health bar
      if (e.type !== EnemyType.PUPPET) {
        ctx.fillStyle = '#333';
        ctx.fillRect(e.pos.x - e.radius, e.pos.y - e.radius - 10, e.radius * 2, 4);
        ctx.fillStyle = '#ef4444';
        ctx.fillRect(e.pos.x - e.radius, e.pos.y - e.radius - 10, (e.radius * 2) * (e.health / e.maxHealth), 4);
      }

      // Melee attack visual for puppets
      if (e.type === EnemyType.PUPPET && e.meleeTimer > 0) {
        const attackProgress = PUPPET_MELEE_COOLDOWN - e.meleeTimer;
        const dx = player.pos.x - e.pos.x;
        const dy = player.pos.y - e.pos.y;
        const angle = Math.atan2(dy, dx);

        if (attackProgress < PUPPET_MELEE_PREP_TIME) {
          // Wind-up: Red arc filling up
          ctx.strokeStyle = 'rgba(255, 0, 0, 0.5)';
          ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.arc(e.pos.x, e.pos.y, PUPPET_MELEE_RANGE, angle - 0.5, angle + 0.5);
          ctx.stroke();
          
          // Progress line
          ctx.beginPath();
          ctx.arc(e.pos.x, e.pos.y, PUPPET_MELEE_RANGE * (attackProgress / PUPPET_MELEE_PREP_TIME), angle - 0.5, angle + 0.5);
          ctx.stroke();
        } else if (attackProgress < PUPPET_MELEE_PREP_TIME + 10) {
          // Strike: Bright red flash
          ctx.strokeStyle = '#ff0000';
          ctx.lineWidth = 4;
          ctx.beginPath();
          ctx.arc(e.pos.x, e.pos.y, PUPPET_MELEE_RANGE, angle - 0.8, angle + 0.8);
          ctx.stroke();
          
          ctx.shadowBlur = 10;
          ctx.shadowColor = '#ff0000';
          ctx.stroke();
          ctx.shadowBlur = 0;
        }
      }
    });

    // Player
    ctx.fillStyle = player.isDashing ? COLORS.PLAYER_DASH : COLORS.PLAYER;
    ctx.beginPath();
    ctx.arc(player.pos.x, player.pos.y, player.radius, 0, Math.PI * 2);
    ctx.fill();
    
    // Player Aura
    ctx.strokeStyle = player.mode === CombatMode.MELEE ? COLORS.MELEE_SWORD : COLORS.RANGED_SWORD;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(player.pos.x, player.pos.y, player.radius + 5, 0, Math.PI * 2);
    ctx.stroke();

    // Charging Visual
    if (player.isCharging) {
      ctx.strokeStyle = COLORS.FROZEN_MARBLE;
      ctx.lineWidth = 1;
      ctx.setLineDash([5, 5]);
      ctx.beginPath();
      ctx.arc(player.pos.x, player.pos.y, MARBLE_ABSORB_RANGE, 0, Math.PI * 2);
      ctx.stroke();
      ctx.setLineDash([]);
      
      // Inner glow
      const gradient = ctx.createRadialGradient(player.pos.x, player.pos.y, player.radius, player.pos.x, player.pos.y, MARBLE_ABSORB_RANGE);
      gradient.addColorStop(0, 'rgba(0, 255, 255, 0.1)');
      gradient.addColorStop(1, 'transparent');
      ctx.fillStyle = gradient;
      ctx.beginPath();
      ctx.arc(player.pos.x, player.pos.y, MARBLE_ABSORB_RANGE, 0, Math.PI * 2);
      ctx.fill();
    }

    // Sword
    ctx.save();
    ctx.translate(sword.pos.x, sword.pos.y);
    ctx.rotate(sword.angle);
    ctx.fillStyle = player.mode === CombatMode.MELEE ? COLORS.MELEE_SWORD : COLORS.RANGED_SWORD;
    
    // Sword Shape
    ctx.beginPath();
    ctx.moveTo(sword.radius * 1.5, 0);
    ctx.lineTo(-sword.radius * 0.5, -sword.radius * 0.5);
    ctx.lineTo(-sword.radius * 0.5, sword.radius * 0.5);
    ctx.closePath();
    ctx.fill();
    
    // Sword Glow
    ctx.shadowBlur = 15;
    ctx.shadowColor = player.mode === CombatMode.MELEE ? COLORS.MELEE_SWORD : COLORS.RANGED_SWORD;
    ctx.stroke();
    ctx.restore();

    // Melee Arc Visual
    if (player.mode === CombatMode.MELEE && player.attackCooldown > 0) {
      const attackAngle = Math.atan2(mousePos.current.y - player.pos.y, mousePos.current.x - player.pos.x);
      ctx.strokeStyle = COLORS.MELEE_SWORD;
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.arc(player.pos.x, player.pos.y, SWORD_MELEE_RANGE, attackAngle - SWORD_MELEE_ARC / 2, attackAngle + SWORD_MELEE_ARC / 2);
      ctx.stroke();
    }

    ctx.restore();
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      keys.current[e.key.toLowerCase()] = true;
      if (e.key === ' ') {
        gameState.current.player.spacePressTimer = 0;
      }
    };
    const handleKeyUp = (e: KeyboardEvent) => {
      keys.current[e.key.toLowerCase()] = false;
      if (e.key === ' ') {
        const player = gameState.current.player;
        player.isCharging = false;
        player.spacePressTimer = 0;
      }
    };
    const handleMouseMove = (e: MouseEvent) => {
      const canvas = canvasRef.current;
      if (canvas) {
        const rect = canvas.getBoundingClientRect();
        mousePos.current = {
          x: e.clientX - rect.left,
          y: e.clientY - rect.top
        };
      }
    };
    const handleMouseDown = (e: MouseEvent) => {
      if (e.button === 0) {
        mouseClicked.current = true;
        gameState.current.player.leftClickTimer = 0;
      }
      if (e.button === 2) {
        keys.current['mouse2'] = true;
        gameState.current.sword.pressTimer = 0;
        gameState.current.sword.targetPos = { ...mousePos.current };
      }
    };
    const handleMouseUp = (e: MouseEvent) => {
      if (e.button === 0) {
        mouseClicked.current = false;
        const player = gameState.current.player;
        player.leftClickTimer = 0;
      }
      if (e.button === 2) {
        keys.current['mouse2'] = false;
        const sword = gameState.current.sword;
        const player = gameState.current.player;

        if (sword.state === SwordState.ORBITING) {
          if (sword.pressTimer < SWORD_TAP_THRESHOLD) {
            // Short press: Point Strike
            sword.state = SwordState.POINT_STRIKE;
            sword.targetPos = { ...mousePos.current };
            player.mode = CombatMode.RANGED;
          }
        } else if (sword.state === SwordState.SLICING) {
          // Release from long press: Recall
          sword.state = SwordState.RECALLING;
        }
      }
    };
    const handleContextMenu = (e: MouseEvent) => e.preventDefault();

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);
    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mousedown', handleMouseDown);
    window.addEventListener('mouseup', handleMouseUp);
    window.addEventListener('contextmenu', handleContextMenu);

    requestRef.current = requestAnimationFrame(update);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mousedown', handleMouseDown);
      window.removeEventListener('mouseup', handleMouseUp);
      window.removeEventListener('contextmenu', handleContextMenu);
      cancelAnimationFrame(requestRef.current);
    };
  }, []);

  return (
    <div className="min-h-screen bg-neutral-950 text-white flex flex-col items-center justify-center p-4 font-sans overflow-hidden">
      <div className="relative group">
        {/* Game Canvas */}
        <canvas
          ref={canvasRef}
          width={CANVAS_WIDTH}
          height={CANVAS_HEIGHT}
          className="rounded-xl shadow-2xl border border-neutral-800 cursor-crosshair"
        />

        {/* UI Overlay */}
        <div className="absolute top-0 left-0 w-full p-6 pointer-events-none flex justify-between items-start">
          <div className="space-y-4">
            {/* Health Bar */}
            <div className="w-64 h-4 bg-neutral-900 rounded-full border border-neutral-800 overflow-hidden">
              <div 
                className="h-full bg-red-500 transition-all duration-200"
                style={{ width: `${(uiState.health / PLAYER_MAX_HEALTH) * 100}%` }}
              />
            </div>
            {/* Energy Bar */}
            <div className="w-64 h-3 bg-neutral-900 rounded-full border border-neutral-800 overflow-hidden">
              <div 
                className="h-full bg-yellow-400 transition-all duration-200"
                style={{ width: `${(uiState.energy / PLAYER_MAX_ENERGY) * 100}%` }}
              />
            </div>
            <div className="flex gap-4 items-center">
              <div className="flex items-center gap-2 bg-neutral-900/80 px-3 py-1 rounded-lg border border-neutral-800">
                <Skull size={16} className="text-red-400" />
                <span className="text-sm font-mono tracking-wider">第 {uiState.wave} 波</span>
              </div>
              <div className="bg-neutral-900/80 px-3 py-1 rounded-lg border border-neutral-800">
                <span className="text-sm font-mono tracking-wider text-yellow-400">{uiState.score.toLocaleString()}</span>
              </div>
            </div>
          </div>

          <div className="flex flex-col items-end gap-3">
             <div className={`flex items-center gap-3 px-4 py-2 rounded-xl border-2 transition-all duration-300 ${uiState.swordState === SwordState.ORBITING ? 'bg-yellow-500/10 border-yellow-500 text-yellow-500' : 'bg-sky-500/10 border-sky-500 text-sky-500'}`}>
                {uiState.swordState === SwordState.ORBITING ? <Shield size={20} /> : <Target size={20} />}
                <span className="font-bold tracking-widest uppercase text-sm">
                  {uiState.swordState === SwordState.ORBITING ? '近战模式' : '御剑模式'}
                </span>
             </div>
             {uiState.swordState !== SwordState.ORBITING && (
               <div className="flex items-center gap-2 text-sky-400 animate-pulse">
                 <Zap size={12} />
                 <span className="text-[10px] font-mono uppercase tracking-widest font-bold">子弹时间已激活</span>
               </div>
             )}
             <div className="text-[10px] text-neutral-500 font-mono uppercase tracking-widest text-right">
               右键点按：刺击<br/>右键长按：连斩
             </div>
          </div>
        </div>

        {/* Abilities HUD */}
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-4 pointer-events-none">
          <div className={`w-12 h-12 rounded-lg border-2 flex items-center justify-center relative ${uiState.energy <= 0 ? 'bg-neutral-900 border-neutral-800 text-neutral-600' : 'bg-neutral-800/50 border-neutral-400 text-white'}`}>
            <Magnet size={20} />
            <div className="absolute -bottom-5 text-[8px] font-bold text-neutral-500 uppercase">空格 吸收</div>
          </div>
        </div>

        {/* Game Over Screen */}
        {uiState.isGameOver && (
          <div className="absolute inset-0 bg-black/80 backdrop-blur-sm flex flex-col items-center justify-center rounded-xl animate-in fade-in duration-500">
            <h2 className="text-6xl font-black text-red-500 mb-2 tracking-tighter italic">力竭身亡</h2>
            <p className="text-neutral-400 mb-8 font-mono uppercase tracking-[0.3em]">修行已止</p>
            <div className="grid grid-cols-2 gap-8 mb-12 text-center">
              <div>
                <div className="text-xs text-neutral-500 uppercase tracking-widest mb-1">最终得分</div>
                <div className="text-3xl font-bold text-yellow-500">{uiState.score.toLocaleString()}</div>
              </div>
              <div>
                <div className="text-xs text-neutral-500 uppercase tracking-widest mb-1">存活波次</div>
                <div className="text-3xl font-bold text-white">{uiState.wave}</div>
              </div>
            </div>
            <button 
              onClick={initGame}
              className="group flex items-center gap-3 bg-white text-black px-8 py-4 rounded-full font-bold hover:bg-yellow-400 transition-all duration-200 pointer-events-auto"
            >
              <Play size={20} fill="black" />
              重新开始
            </button>
          </div>
        )}
      </div>

      {/* Instructions */}
      <div className="mt-8 max-w-2xl w-full grid grid-cols-1 md:grid-cols-3 gap-6 text-neutral-400">
        <div className="bg-neutral-900/50 p-4 rounded-xl border border-neutral-800">
          <h3 className="text-white font-bold mb-2 flex items-center gap-2">
            <SwordIcon size={16} className="text-yellow-500" />
            近战模式
          </h3>
          <p className="text-xs leading-relaxed">
            左键挥剑。冻结弹幕或击中敌人以获得剑意。长按左键发射已吸收的弹幕。
          </p>
        </div>
        <div className="bg-neutral-900/50 p-4 rounded-xl border border-neutral-800">
          <h3 className="text-white font-bold mb-2 flex items-center gap-2">
            <Target size={16} className="text-sky-500" />
            御剑模式
          </h3>
          <p className="text-xs leading-relaxed">
            右键进入御剑状态。减缓时间 (0.5x)。点按刺击，长按连斩。剑回时造成伤害。
          </p>
        </div>
        <div className="bg-neutral-900/50 p-4 rounded-xl border border-neutral-800">
          <h3 className="text-white font-bold mb-2 flex items-center gap-2">
            <Magnet size={16} className="text-white" />
            操作说明
          </h3>
          <ul className="text-[10px] space-y-1 font-mono uppercase tracking-wider">
            <li>WASD：移动</li>
            <li>右键：御剑 (点按/长按)</li>
            <li>空格：长按吸收冻结弹幕 (耗能)</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default App;
