export const CANVAS_WIDTH = 800;
export const CANVAS_HEIGHT = 600;

export const PLAYER_SPEED = 5.0;
export const PLAYER_DASH_SPEED = 15;
export const PLAYER_DASH_DURATION = 10;
export const PLAYER_DASH_COOLDOWN = 45;
export const PLAYER_RADIUS = 15;
export const PLAYER_MAX_HEALTH = 100;
export const PLAYER_MAX_ENERGY = 100;

export const SWORD_RADIUS = 25;
export const SWORD_SPEED = 22;
export const SWORD_SLICING_SPEED = 120;
export const SWORD_POINT_STRIKE_SPEED = 80;
export const SWORD_RECALL_SPEED = 60;
export const SWORD_ROTATION_SPEED = 0.2;
export const SWORD_MELEE_RANGE = 100;
export const SWORD_MELEE_COOLDOWN = 10;
export const SWORD_MELEE_ARC = Math.PI * 1.2;
export const SWORD_RANGED_DAMAGE = 100;
export const SWORD_MELEE_DAMAGE = 100;
export const SWORD_AUTO_HUNT_RANGE = 200;
export const SWORD_TAP_THRESHOLD = 0.15; // Seconds

export const BULLET_TIME_MULTIPLIER = 0.5;
export const PLAYER_BULLET_TIME_SPEED_MULTIPLIER = 0.85;
export const ENEMY_HIT_COOLDOWN = 0.05; // Seconds

export const ENERGY_CONSUMPTION_RANGED = 0.25; // Per frame
export const ENERGY_RECOVERY_MELEE_NATURAL = 0.05; // Per frame
export const ENERGY_GAIN_MELEE_HIT = 2;
export const ENERGY_GAIN_MELEE_DEFLECT = 8;

export const ENEMY_SHOOTER_RADIUS = 25;
export const ENEMY_SHOOTER_HEALTH = 20;
export const ENEMY_SHOOTER_SPEED = 1.5;
export const ENEMY_SHOOTER_COOLDOWN = 120;

export const ENEMY_TANK_RADIUS = 40;
export const ENEMY_TANK_HEALTH = 100;
export const ENEMY_TANK_SPEED = 0.8;

export const ENEMY_CASTER_RADIUS = 30;
export const ENEMY_CASTER_HEALTH = 40;
export const ENEMY_CASTER_SPEED = 1.2;
export const ENEMY_CASTER_COOLDOWN = 180;

export const ENEMY_HEAVY_RADIUS = 35;
export const ENEMY_HEAVY_HEALTH = 60;
export const ENEMY_HEAVY_SPEED = 1.0;
export const ENEMY_HEAVY_COOLDOWN = 150;

export const BULLET_RADIUS = 5;
export const BULLET_SPEED = 2.5;
export const BULLET_DAMAGE = 10;

export const BULLET_LARGE_RADIUS = 12;
export const BULLET_LARGE_SPEED = 1.5;
export const BULLET_LARGE_DAMAGE = 25;

export const WAVE_SPAWN_INTERVAL = 300;
export const WAVE_BASE_ENEMIES = 3;

export const COLORS = {
  PLAYER: '#4ade80',
  PLAYER_DASH: '#86efac',
  MELEE_SWORD: '#facc15',
  RANGED_SWORD: '#38bdf8',
  ENEMY_SHOOTER: '#f87171',
  ENEMY_TANK: '#ef4444',
  ENEMY_CASTER: '#dc2626',
  ENEMY_HEAVY: '#991b1b',
  BULLET: '#ffffff',
  BULLET_REFLECTED: '#38bdf8',
  ENERGY: '#facc15',
  HEALTH: '#ef4444',
  BACKGROUND: '#0a0a0a',
  ARENA: '#1a1a1a',
  FROZEN_MARBLE: '#00ffff',
  FROZEN_GLOW: 'rgba(0, 255, 255, 0.5)',
};

// Frozen Sword Intent Parameters
export const FROZEN_DECEL_TIME = 0.3; // Seconds
export const FROZEN_LIFETIME = 3.0; // Seconds
export const MAX_BULLETS_PER_ENEMY = 8;
export const MAX_TOTAL_FROZEN = 20;

export const MARBLE_ABSORB_RANGE = 250;
export const MARBLE_MAX_ABSORBED = 12;
export const MARBLE_ENERGY_COST_HOLD = 10 / 60; // 10 per second
export const MARBLE_FIRED_SPEED = 45;
export const MARBLE_FIRED_DAMAGE = 100;
export const MARBLE_FIRE_RATE = 0.15; // Seconds between sequential shots

export const BOSS_RADIUS = 60;
export const BOSS_MAX_HEALTH = 5000;
export const BOSS_SPEED = 1.0;
export const BOSS_WAVE_INTERVAL = 5;

export const PUPPET_RADIUS = 25;
export const PUPPET_HEALTH = 200;
export const PUPPET_SPEED = 2.0;
export const PUPPET_MELEE_RANGE = 80;
export const PUPPET_MELEE_COOLDOWN = 120;
export const PUPPET_MELEE_DAMAGE = 20;
export const PUPPET_MELEE_PREP_TIME = 40; // Wind-up time

export const SILK_MAX_HEALTH = 10; // Very low so a few frames of contact or 1-2 hits cut it
export const SILK_COLOR = 'rgba(255, 255, 255, 0.6)';
export const SILK_MAIN_COLOR = 'rgba(255, 100, 100, 0.8)';

export const BOSS_COLORS = {
  BODY: '#7c3aed',
  PUPPET: '#a78bfa',
  SILK: '#ffffff',
  SILK_MAIN: '#ef4444',
  VULNERABLE: '#facc15',
};
