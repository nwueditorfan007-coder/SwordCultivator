export enum CombatMode {
  MELEE = 'MELEE',
  RANGED = 'RANGED',
}

export enum SwordState {
  ORBITING = 'ORBITING',
  POINT_STRIKE = 'POINT_STRIKE',
  SLICING = 'SLICING',
  RECALLING = 'RECALLING',
}

export interface Vector {
  x: number;
  y: number;
}

export interface Entity {
  id: string;
  pos: Vector;
  vel: Vector;
  radius: number;
  health: number;
  maxHealth: number;
}

export interface Player extends Entity {
  mode: CombatMode;
  energy: number;
  maxEnergy: number;
  dashCooldown: number;
  attackCooldown: number;
  isDashing: boolean;
  dashTimer: number;
  leftClickTimer: number;
  spacePressTimer: number;
  isCharging: boolean;
  absorbedMarbles: string[]; // IDs of bullets being held
  fireTimer: number;
}

export interface Sword extends Entity {
  targetPos: Vector;
  isActive: boolean;
  angle: number;
  rotationSpeed: number;
  state: SwordState;
  pressTimer: number;
}

export enum EnemyType {
  SHOOTER = 'SHOOTER',
  TANK = 'TANK',
  CASTER = 'CASTER',
  HEAVY = 'HEAVY',
  PUPPET = 'PUPPET',
}

export interface Enemy extends Entity {
  type: EnemyType;
  shootCooldown: number;
  moveTimer: number;
  targetPos: Vector;
  hitCooldown: number;
  lastHitBySword: boolean;
  meleeTimer: number; // For puppet melee attacks
}

export enum BulletState {
  NORMAL = 'NORMAL',
  FREEZING = 'FREEZING', // Slowing down
  FROZEN = 'FROZEN',   // Stationary, ready to be used
  FIRED = 'FIRED',     // Fired by player
}

export enum BulletType {
  SMALL = 'SMALL',
  LARGE = 'LARGE',
}

export interface Bullet {
  id: string;
  pos: Vector;
  vel: Vector;
  radius: number;
  isReflected: boolean;
  damage: number;
  color: string;
  state: BulletState;
  type: BulletType;
  freezeTimer: number;
  lifeTimer: number;
  ownerId?: string; // To track which enemy fired it
}

export interface Particle {
  id: string;
  pos: Vector;
  vel: Vector;
  life: number;
  maxLife: number;
  color: string;
  size: number;
}

export enum BossState {
  IDLE = 'IDLE',
  THOUSAND_SILKS = 'THOUSAND_SILKS',
  PUPPET_AMBUSH = 'PUPPET_AMBUSH',
  SILK_CAGE = 'SILK_CAGE',
  NEEDLE_RETURN = 'NEEDLE_RETURN',
  PUPPET_EXECUTION = 'PUPPET_EXECUTION',
  REVERSE_NET = 'REVERSE_NET',
  VULNERABLE = 'VULNERABLE',
}

export interface Silk {
  id: string;
  from: Vector;
  to: Vector;
  isMain: boolean;
  health: number;
  maxHealth: number;
  isActive: boolean;
}

export interface Boss extends Entity {
  state: BossState;
  stateTimer: number;
  phase: number;
  silks: Silk[];
  isVulnerable: boolean;
  vulnerableTimer: number;
  moveTimer: number;
  targetPos: Vector;
}

export interface GameState {
  player: Player;
  sword: Sword;
  enemies: Enemy[];
  boss: Boss | null;
  bullets: Bullet[];
  particles: Particle[];
  wave: number;
  enemiesToSpawn: number;
  isGameOver: boolean;
  score: number;
  screenShake: number;
}
