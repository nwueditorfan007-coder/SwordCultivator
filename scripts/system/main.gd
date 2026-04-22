extends Node2D

const AttackProfiles = preload("res://scripts/combat/attack_profiles.gd")
const DamageResolver = preload("res://scripts/combat/damage_resolver.gd")
const HitDetection = preload("res://scripts/combat/hit_detection.gd")
const HurtboxRegistry = preload("res://scripts/combat/hurtbox_registry.gd")
const GameBossController = preload("res://scripts/system/game_boss_controller.gd")
const GameRenderer = preload("res://scripts/system/game_renderer.gd")
const GameStateFactory = preload("res://scripts/system/game_state_factory.gd")
const HitRegistry = preload("res://scripts/combat/hit_registry.gd")
const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayController = preload("res://scripts/system/sword_array_controller.gd")
const SwordVfxProfile = preload("res://scripts/vfx/sword_vfx_profile.gd")
const TargetDescriptors = preload("res://scripts/combat/target_descriptors.gd")
const TargetDescriptorRegistry = preload("res://scripts/combat/target_descriptor_registry.gd")
const TargetEventSystem = preload("res://scripts/combat/target_event_system.gd")
const TargetProfiles = preload("res://scripts/combat/target_profiles.gd")
const TargetWritebackAdapters = preload("res://scripts/combat/target_writeback_adapters.gd")
const DEFAULT_SWORD_VFX_PROFILE = preload("res://resources/vfx/sword_vfx_profile_default.tres")
const DEFAULT_LOOKDEV_SWORD_VFX_PROFILE = preload("res://resources/vfx/sword_vfx_profile_lookdev.tres")

enum CombatMode {
	MELEE,
	RANGED,
}

enum SwordState {
	ORBITING,
	POINT_STRIKE,
	SLICING,
	RECALLING,
}

enum ArrayEnergyForecastLevel {
	NONE,
	WARNING,
	CRITICAL,
}

enum LookdevPreviewMode {
	POINT,
	SLICE,
	RECALL,
}

const LOOKDEV_PANEL_TARGET_WIDTH := 320.0
const LOOKDEV_PANEL_MARGIN := 16.0
const LOOKDEV_CONTROLS := [
	{
		"title": "拖尾",
		"items": [
			{"prop": "trail_duration", "label": "拖尾持续", "min": 0.02, "max": 0.3, "step": 0.005},
			{"prop": "trail_base_half_width", "label": "拖尾宽度", "min": 2.0, "max": 24.0, "step": 0.5},
			{"prop": "trail_point_width_scale", "label": "点刺拖尾", "min": 0.2, "max": 1.4, "step": 0.02},
			{"prop": "trail_slice_width_scale", "label": "连斩拖尾", "min": 0.4, "max": 1.8, "step": 0.02},
			{"prop": "trail_recall_width_scale", "label": "回收拖尾", "min": 0.2, "max": 1.2, "step": 0.02},
		],
	},
	{
		"title": "气流",
		"items": [
			{"prop": "air_wake_duration", "label": "气流持续", "min": 0.02, "max": 0.3, "step": 0.005},
			{"prop": "air_wake_min_speed", "label": "触发速度", "min": 200.0, "max": 1200.0, "step": 10.0},
			{"prop": "air_wake_base_length", "label": "气流长度", "min": 4.0, "max": 48.0, "step": 1.0},
			{"prop": "air_wake_base_width", "label": "气流宽度", "min": 2.0, "max": 18.0, "step": 0.5},
			{"prop": "air_wake_turn_threshold", "label": "转向阈值", "min": 0.01, "max": 0.2, "step": 0.01},
		],
	},
	{
		"title": "前锋破空",
		"items": [
			{"prop": "front_speed_start", "label": "起效速度", "min": 0.0, "max": 0.5, "step": 0.01},
			{"prop": "front_length_max", "label": "前锋长度", "min": 8.0, "max": 48.0, "step": 0.5},
			{"prop": "front_width_max", "label": "前锋宽度", "min": 2.0, "max": 12.0, "step": 0.25},
			{"prop": "front_point_pulse", "label": "点刺脉冲", "min": 0.0, "max": 4.5, "step": 0.1},
			{"prop": "front_recall_pulse", "label": "回收脉冲", "min": 0.0, "max": 4.0, "step": 0.1},
		],
	},
	{
		"title": "剑体辉光",
		"items": [
			{"prop": "local_glow_point_base", "label": "点刺辉光", "min": 0.0, "max": 0.45, "step": 0.01},
			{"prop": "local_glow_slice_base", "label": "连斩辉光", "min": 0.0, "max": 0.4, "step": 0.01},
			{"prop": "local_glow_recall_base", "label": "回收辉光", "min": 0.0, "max": 0.35, "step": 0.01},
			{"prop": "local_glow_tip_radius_scale", "label": "剑尖光团", "min": 0.0, "max": 5.0, "step": 0.1},
			{"prop": "local_glow_spine_alpha_scale", "label": "剑脊亮度", "min": 0.0, "max": 0.16, "step": 0.01},
		],
	},
	{
		"title": "回收归阵",
		"items": [
			{"prop": "return_catch_duration", "label": "归位持续", "min": 0.02, "max": 0.35, "step": 0.01},
			{"prop": "return_catch_base_radius", "label": "归位半径", "min": 8.0, "max": 48.0, "step": 1.0},
		],
	},
]

const ARENA_SIZE := Vector2(800.0, 600.0)
const ARENA_ORIGIN := Vector2(240.0, 72.0)
const ARENA_RECT := Rect2(ARENA_ORIGIN, ARENA_SIZE)

const PLAYER_RADIUS := 15.0
const PLAYER_MAX_HEALTH := 100.0
const PLAYER_MAX_ENERGY := 100.0
const PLAYER_SPEED := 300.0

const SWORD_RADIUS := 25.0
const SWORD_MELEE_RANGE := 100.0
const SWORD_MELEE_COOLDOWN := 10.0 / 60.0
const SWORD_MELEE_ARC := PI * 1.2
const SWORD_TAP_THRESHOLD := 0.15
const SWORD_POINT_STRIKE_SPEED := 80.0 * 60.0
const SWORD_RECALL_SPEED := 60.0 * 60.0
const SWORD_ORBIT_DISTANCE := 25.0
const SWORD_SLICE_MIN_HIT_SPEED := 90.0

const BULLET_RADIUS := 5.0
const BULLET_LARGE_RADIUS := 12.0
const BULLET_SPEED := 2.5 * 60.0
const BULLET_LARGE_SPEED := 1.5 * 60.0
const BULLET_DAMAGE := 10.0
const BULLET_LARGE_DAMAGE := 25.0
const BULLET_FAMILY_NEEDLE := "needle"
const BULLET_FAMILY_WEAVE := "weave"
const BULLET_FAMILY_FANG := "fang"
const BULLET_FAMILY_CORE := "core"

const BULLET_TIME_START_MULTIPLIER := 0.1
const BULLET_TIME_RECOVERY_DURATION := 2.0
const PLAYER_BULLET_TIME_SPEED_MULTIPLIER := 0.85
const TIME_STOP_VISUAL_MAX_STRENGTH := 0.84
const TIME_STOP_VISUAL_ENTER_SPEED := 12.0
const TIME_STOP_VISUAL_EXIT_SPEED := 4.8
const TIME_STOP_VISUAL_RELEASE_HOLD := 0.28
const TIME_STOP_VISUAL_HOLD_FLOOR := 0.26
const TIME_STOP_VISUAL_ENTRY_PULSE_DURATION := 0.12
const TIME_STOP_VISUAL_WASH_SUSTAIN_ALPHA := 0.072
const TIME_STOP_VISUAL_WASH_PULSE_ALPHA := 0.045
const UNSHEATH_FLASH_DURATION := 0.08
const UNSHEATH_FLASH_REPEAT_SUPPRESSION := 0.16
const UNSHEATH_FLASH_BASE_STRENGTH := 0.34
const UNSHEATH_FLASH_REPEAT_STRENGTH := 0.12
const UNSHEATH_PRESS_FLASH_DURATION := 0.045
const UNSHEATH_PRESS_FLASH_STRENGTH := 1
const UNSHEATH_PRESS_FLASH_REPEAT_SUPPRESSION := 0.11
const UNSHEATH_PRESS_FLASH_BASE_STRENGTH := 0.22
const UNSHEATH_PRESS_FLASH_REPEAT_STRENGTH := 0.08
const UNSHEATH_FLASH_LENGTH_SCALE := 1.08
const UNSHEATH_FLASH_WIDTH_SCALE := 0.92
const UNSHEATH_FLASH_ANCHOR_LERP := 0.68
const UNSHEATH_PRESS_FLASH_ANCHOR_LERP := 0.6
const UNSHEATH_FLASH_ROOT_BACK_OFFSET := 2.5
const UNSHEATH_FLASH_SWORD_FORWARD_OFFSET := 10.0
const UNSHEATH_FLASH_RELEASE_MIN_DISTANCE := 72.0
const UNSHEATH_FLASH_RELEASE_MAX_DISTANCE := 152.0
const UNSHEATH_FLASH_POINT_RELEASE_PREDICT_TIME := 1.0 / 60.0
const UNSHEATH_FLASH_SLICE_RELEASE_RATIO := 0.32
const SWORD_AFTERIMAGE_DURATION := 0.09
const SWORD_AFTERIMAGE_BURST_DURATION := 0.09
const SWORD_AFTERIMAGE_EMIT_INTERVAL := 0.016
const SWORD_AFTERIMAGE_MIN_SPEED := 600.0
const SWORD_AFTERIMAGE_MAX_COUNT := 10
const SWORD_AFTERIMAGE_ALPHA_SCALE := 0.95
const SWORD_TRAIL_DURATION := 0.11
const SWORD_TRAIL_SAMPLE_INTERVAL := 0.012
const SWORD_TRAIL_MIN_SPEED := 560.0
const SWORD_TRAIL_MAX_POINTS := 12
const SWORD_TRAIL_BASE_HALF_WIDTH := 11.0
const SWORD_TRAIL_POINT_WIDTH_SCALE := 0.66
const SWORD_TRAIL_SLICE_WIDTH_SCALE := 1.08
const SWORD_TRAIL_RECALL_WIDTH_SCALE := 0.58
const SWORD_TRAIL_FORWARD_OFFSET := 11.0
const SWORD_TRAIL_POINT_LIFE_SCALE := 0.9
const SWORD_TRAIL_SLICE_LIFE_SCALE := 1.12
const SWORD_TRAIL_RECALL_LIFE_SCALE := 0.96
const SWORD_AIR_WAKE_DURATION := 0.1
const SWORD_AIR_WAKE_MIN_SPEED := 680.0
const SWORD_AIR_WAKE_MAX_COUNT := 14
const SWORD_AIR_WAKE_BASE_LENGTH := 24.0
const SWORD_AIR_WAKE_BASE_WIDTH := 12.0
const SWORD_AIR_WAKE_TURN_THRESHOLD := 0.12
const SWORD_AIR_WAKE_EMIT_INTERVAL_MIN := 0.016
const SWORD_AIR_WAKE_EMIT_INTERVAL_MAX := 0.042
const SWORD_RETURN_CATCH_DURATION := 0.24
const SWORD_RETURN_CATCH_MAX_COUNT := 8
const SWORD_RETURN_CATCH_BASE_RADIUS := 30.0
const SWORD_HIT_EFFECT_DURATION := 0.09
const SWORD_HIT_EFFECT_MAX_COUNT := 18
const SWORD_HIT_EFFECT_BASE_LENGTH := 18.0
const SWORD_HIT_EFFECT_BASE_WIDTH := 7.0
const SWORD_HIT_EFFECT_POINT_LENGTH_SCALE := 0.9
const SWORD_HIT_EFFECT_POINT_WIDTH_SCALE := 0.42
const SWORD_HIT_EFFECT_SLICE_LENGTH_SCALE := 1.28
const SWORD_HIT_EFFECT_SLICE_WIDTH_SCALE := 0.96
const SWORD_HIT_EFFECT_SPARK_COUNT := 2
const MELEE_ATTACK_FLASH_DURATION := 0.08
const ENERGY_GAIN_FEEDBACK_DURATION := 0.24
const ENERGY_GAIN_FEEDBACK_MAX_STRENGTH := 1.0
const FLYING_SWORD_POINT_HITSTOP_BASE_DURATION := 0.045
const FLYING_SWORD_POINT_HITSTOP_CHAIN_GAP := 0.014
const FLYING_SWORD_POINT_HITSTOP_MAX_DURATION := 0.07
const SILK_SEVER_HITSTOP_DURATION := 0.07
const ENEMY_HIT_FLASH_DURATION := 0.14
const ENEMY_HIT_REACTION_DURATION := 0.2
const ENEMY_HIT_REACTION_SHAKE_CYCLES := 4
const ENEMY_HIT_REACTION_INTENSITY := 0.8
const HIT_REACTION_BACKSWING_SCALE := 0.42
const HIT_REACTION_DECAY_EXPONENT := 0.72
const ENEMY_HIT_REACTION_RETURN_SPEED := 132.0
const ENEMY_HIT_REACTION_MAX_OFFSET := 18.0
const ENEMY_DEATH_FEEDBACK_DURATION := 0.18
const BOSS_HIT_FLASH_DURATION := 0.17
const BOSS_HIT_REACTION_DURATION := 0.22
const BOSS_HIT_REACTION_SHAKE_CYCLES := 2.8
const BOSS_HIT_REACTION_INTENSITY := 0.9
const BOSS_HIT_REACTION_RETURN_SPEED := 92.0
const BOSS_HIT_REACTION_MAX_OFFSET := 12.0
const SILK_CONTACT_FEEDBACK_DURATION := 0.1
const SILK_SEVER_FEEDBACK_DURATION := 0.18
const SILK_CONTACT_SELF_FEEDBACK_POINT_INTERVAL := 0.12
const SILK_CONTACT_SELF_FEEDBACK_SLICE_INTERVAL := 0.08
const SILK_CONTACT_IMPACT_OFFSET_SCALE := 0.58
const SILK_CONTACT_IMPACT_ANGLE_SCALE := 0.52
const SILK_CONTACT_IMPACT_SCREEN_SHAKE_SCALE := 0.22
const SILK_CONTACT_IMPACT_LOCAL_HIT_SCALE := 0.82
const SILK_CONTACT_IMPACT_DURATION_SCALE := 0.72
const SILK_CONTACT_IMPACT_SIDE_OFFSET_SCALE := 0.84
const SWORD_IMPACT_FEEDBACK_DURATION := 0.18
const SWORD_IMPACT_RETURN_SPEED := 150
const SWORD_IMPACT_ANGLE_RETURN_SPEED := 5.2
const SWORD_IMPACT_MAX_OFFSET := 20
const SWORD_IMPACT_MAX_ANGLE_OFFSET := 0.3
const SWORD_SLICE_IMPACT_FEEDBACK_DURATION := 0.24
const SWORD_SLICE_IMPACT_SIDE_OFFSET_RATIO := 0.46

const ENERGY_RECOVERY_MELEE_NATURAL := 3.0
const ENERGY_GAIN_MELEE_HIT := 3.0
const ENERGY_GAIN_MELEE_DEFLECT := 10.0
const ARRAY_SWORD_COUNT := 12
const ARRAY_SWORD_RADIUS := 6.0
const ARRAY_SWORD_RETURN_SPEED := 32.0 * 60.0
const ARRAY_SWORD_RETURN_CATCH_RADIUS := 18.0
const ARRAY_SWORD_ENERGY_COST_RING := 0.95
const ARRAY_SWORD_ENERGY_COST_FAN := 1.00
const ARRAY_SWORD_ENERGY_COST_PIERCE := 1.10
const ARRAY_SWORD_MAX_TRAVEL_DISTANCE := 540.0
const ARRAY_SWORD_MIN_SORTIE_DISTANCE := 220.0
const ARRAY_SWORD_HIT_FOLLOW_THROUGH_DISTANCE := 130.0
const ARRAY_MORPH_CONTROL_SMOOTH_SPEED_IDLE := 12.0
const ARRAY_MORPH_CONTROL_SMOOTH_SPEED_HELD := 9.0
const ARRAY_MORPH_CONTROL_SMOOTH_SPEED_FIRING := 6.5
const ARRAY_SWORD_FIRE_SPEED_SCALE := 1.35
const ARRAY_SWORD_RETURN_SPEED_SCALE := 1.0
const ARRAY_SWORD_RELEASE_RATE_SCALE := 0.78
const ACTION_FAILURE_REPEAT_DELAY := 0.35
const ACTION_FAILURE_FLASH_DURATION := 0.28
const ARRAY_ENERGY_WARNING_HOLD_RATIO_THRESHOLD := 0.55
const ARRAY_ENERGY_WARNING_FADE_SPEED := 7.5
const ARRAY_ENERGY_BREAK_DURATION := 0.24
const ARRAY_MODE_CONFIRM_DURATION := 0.16
const ARRAY_MODE_CONFIRM_COOLDOWN := 0.12
const FOCUS_STATUS_DURATION := 0.46
const FOCUS_STATUS_Y_OFFSET := 58.0
const DEFLECT_BULLET_SPEED_MULTIPLIER := 8.0
const RING_GUARD_BULLET_CLEAR_RADIUS := 34.0
const RING_GUARD_PLAYER_CLEAR_RADIUS := 58.0

const DAMAGE_SOURCE_NONE := ""
const DAMAGE_SOURCE_MELEE := "melee"
const DAMAGE_SOURCE_FLYING_SWORD := "flying_sword"
const DAMAGE_SOURCE_ARRAY_SWORD := "array_sword"
const DAMAGE_SOURCE_SYSTEM := "system"

const WAVE_BASE_ENEMIES := 3
const BOSS_WAVE_INTERVAL := 5
const SPAWN_MARGIN := 50.0
const SPAWN_INTERVAL := 0.35

const SHOOTER := "shooter"
const TANK := "tank"
const CASTER := "caster"
const HEAVY := "heavy"
const RING_LEECH := "ring_leech"
const DRAPE_PRIEST := "drape_priest"
const MIRROR_NEEDLER := "mirror_needler"
const PUPPET := "puppet"

const SPAWN_ENTRY_ENEMY := "enemy"
const SPAWN_ENTRY_PACKAGE := "package"

const ENEMY_PACKAGE_RING_LEECH_CLOSE := "ring_leech_close"
const ENEMY_PACKAGE_PHASE_ASSEMBLE := "assemble"
const ENEMY_PACKAGE_PHASE_COLLAPSE := "collapse"
const ENEMY_PACKAGE_PHASE_ENGAGE := "engage"
const ENEMY_PACKAGE_PHASE_BREAK := "break"

const BOSS_IDLE := "idle"
const BOSS_THOUSAND_SILKS := "thousand_silks"
const BOSS_PUPPET_AMBUSH := "puppet_ambush"
const BOSS_SILK_CAGE := "silk_cage"
const BOSS_NEEDLE_RETURN := "needle_return"

const SHOOTER_RADIUS := 25.0
const SHOOTER_HEALTH := 20.0
const SHOOTER_SPEED := 1.5 * 60.0
const SHOOTER_COOLDOWN := 120.0 / 60.0

const TANK_RADIUS := 40.0
const TANK_HEALTH := 100.0
const TANK_SPEED := 0.8 * 60.0

const CASTER_RADIUS := 30.0
const CASTER_HEALTH := 40.0
const CASTER_SPEED := 1.2 * 60.0
const CASTER_COOLDOWN := 180.0 / 60.0

const HEAVY_RADIUS := 35.0
const HEAVY_HEALTH := 60.0
const HEAVY_SPEED := 1.0 * 60.0
const HEAVY_COOLDOWN := 150.0 / 60.0

const RING_LEECH_RADIUS := 18.0
const RING_LEECH_HEALTH := 18.0
const RING_LEECH_SPEED := 2.35 * 60.0
const RING_LEECH_COOLDOWN := 72.0 / 60.0
const RING_LEECH_BULLET_SPEED := 2.1 * 60.0
const RING_LEECH_BULLET_DAMAGE := 7.0
const RING_LEECH_ORBIT_DISTANCE := 86.0
const RING_LEECH_ORBIT_ANGULAR_SPEED := 2.2
const RING_LEECH_FIRE_DISTANCE := 170.0
const RING_LEECH_SPREAD_ANGLE := 0.3
const RING_LEECH_PACKAGE_DEFAULT_COUNT := 10
const RING_LEECH_PACKAGE_MIN_COUNT := 6
const RING_LEECH_PACKAGE_MAX_COUNT := 9
const RING_LEECH_PACKAGE_SPAWN_RADIUS := 320.0
const RING_LEECH_PACKAGE_ENGAGE_RADIUS := 114.0
const RING_LEECH_PACKAGE_ENGAGE_RADIUS_SWAY := 12.0
const RING_LEECH_PACKAGE_ASSEMBLE_DURATION := 0.22
const RING_LEECH_PACKAGE_COLLAPSE_DURATION := 0.82
const RING_LEECH_PACKAGE_ENGAGE_DURATION := 1.75
const RING_LEECH_PACKAGE_BREAK_MEMBER_THRESHOLD := 3
const RING_LEECH_PACKAGE_ASSEMBLE_ROTATION_SPEED := 0.2
const RING_LEECH_PACKAGE_COLLAPSE_ROTATION_SPEED := 0.48
const RING_LEECH_PACKAGE_ENGAGE_ROTATION_SPEED := 1.18
const RING_LEECH_PACKAGE_COLLAPSE_FIRE_PROGRESS := 0.8

const DRAPE_PRIEST_RADIUS := 22.0
const DRAPE_PRIEST_HEALTH := 32.0
const DRAPE_PRIEST_SPEED := 0.95 * 60.0
const DRAPE_PRIEST_SUPPORT_RANGE := 240.0
const DRAPE_PRIEST_APPROACH_DISTANCE := 330.0
const DRAPE_PRIEST_RETREAT_DISTANCE := 245.0
const DRAPE_PRIEST_SUPPORT_DAMAGE_MULTIPLIER := 0.38
const DRAPE_PRIEST_RELINK_COOLDOWN := 2.8
const DRAPE_PRIEST_THREAD_CONTACT_RADIUS := 5.0
const DRAPE_PRIEST_THREAD_STAGGER_DURATION := 0.75
const DRAPE_PRIEST_BOLT_COOLDOWN := 156.0 / 60.0
const DRAPE_PRIEST_BOLT_SPEED := 2.0 * 60.0
const DRAPE_PRIEST_BOLT_DAMAGE := 8.0

const MIRROR_NEEDLER_RADIUS := 24.0
const MIRROR_NEEDLER_HEALTH := 50.0
const MIRROR_NEEDLER_SPEED := 1.15 * 60.0
const MIRROR_NEEDLER_COOLDOWN := 192.0 / 60.0
const MIRROR_NEEDLER_CHARGE_DURATION := 48.0 / 60.0
const MIRROR_NEEDLER_BULLET_SPEED := 1.1 * 60.0
const MIRROR_NEEDLER_BULLET_DAMAGE := 22.0
const MIRROR_NEEDLER_BULLET_RADIUS := 18.0
const MIRROR_NEEDLER_MIN_DISTANCE := 220.0
const MIRROR_NEEDLER_MAX_DISTANCE := 320.0
const MIRROR_NEEDLER_SHELL_DAMAGE_MULTIPLIER := 0.58
const MIRROR_NEEDLER_CHARGE_DAMAGE_MULTIPLIER := 1.12
const MIRROR_NEEDLER_VULNERABLE_DURATION := 1.45
const MIRROR_NEEDLER_AFTER_FIRE_VULNERABLE_DURATION := 0.55
const MIRROR_NEEDLER_BREAK_STAGGER_DURATION := 0.95
const MIRROR_NEEDLER_BREAK_RECOVERY := 0.6

const PUPPET_RADIUS := 25.0
const PUPPET_HEALTH := 200.0
const PUPPET_SPEED := 2.0 * 60.0
const PUPPET_MELEE_RANGE := 80.0
const PUPPET_MELEE_COOLDOWN := 120.0 / 60.0
const PUPPET_MELEE_DAMAGE := 20.0
const PUPPET_MELEE_PREP_TIME := 40.0 / 60.0

const BOSS_RADIUS := 60.0
const BOSS_MAX_HEALTH := 5000.0
const BOSS_SPEED := 60.0
const SILK_MAX_HEALTH := 10.0

const COLORS := {
	"background": Color("0a0a0a"),
	"grid": Color("1b1b1b"),
	"player": Color("4ade80"),
	"melee_sword": Color("facc15"),
	"ranged_sword": Color("38bdf8"),
	"shooter": Color("f87171"),
	"tank": Color("ef4444"),
	"caster": Color("dc2626"),
	"heavy": Color("991b1b"),
	"ring_leech": Color("fb7185"),
	"drape_priest": Color("38bdf8"),
	"mirror_needler": Color("e5e7eb"),
	"puppet": Color("a78bfa"),
	"bullet": Color("f5efe6"),
	"frozen": Color("00ffff"),
	"array_sword": Color("7dd3fc"),
	"array_sword_return": Color("facc15"),
	"energy": Color("facc15"),
	"health": Color("ef4444"),
	"boss_body": Color("7c3aed"),
	"boss_vulnerable": Color("facc15"),
	"silk": Color("ffffff"),
	"silk_main": Color("ef4444"),
}

const START_MENU_OPERATION_TEXT := """[b]WASD 移动[/b]
在场地内走位、躲开敌弹、拉开或压近敌人。移动本身不消耗剑意，适合先把敌人带到有利距离再出剑。

[b]鼠标移动 瞄准/控距[/b]
角色、近战挥剑、御剑目标和剑阵方向都会参考鼠标位置。鼠标离角色越近越偏环阵，中距离变为扇阵，远距离变为刺阵。

[b]左键点击 近战挥剑[/b]
立即朝鼠标方向斩击，适合处理贴脸敌人和弹开敌弹。命中敌人或成功弹反敌弹会回复剑意，是维持后续剑阵的主要来源。

[b]左键长按 剑阵压制[/b]
按住约 0.1 秒后持续发射飞剑。近距离环阵守身，中距离扇阵横扫，远距离刺阵穿线。每把飞剑会消耗剑意，剑意不足或飞剑未回收时会中断。

[b]右键短按 御剑点刺[/b]
按下后快速松开，飞剑会刺向鼠标位置；飞剑离身期间会触发子弹时间，适合点杀远处目标、穿过弹幕空隙或打断一条直线上的威胁。

[b]右键长按 御剑连斩[/b]
按住超过短按阈值后进入连斩，拖动鼠标让飞剑追随并切割路径；松开右键后飞剑召回。适合持续切割移动中的目标或清理一片压力。

[b]死亡后左键 重新开始[/b]
力竭身亡后，在结算提示出现时点击左键即可重新开始本局。"""

@export var sword_vfx_profile: SwordVfxProfile = DEFAULT_SWORD_VFX_PROFILE
@export var lookdev_mode := false
@export var lookdev_auto_cycle := true
@export var lookdev_preview_mode: LookdevPreviewMode = LookdevPreviewMode.POINT
@export_range(0.25, 3.0, 0.05) var lookdev_playback_speed := 1.0

var player: Dictionary = {}
var sword: Dictionary = {}
var enemies: Array = []
var bullets: Array = []
var array_swords: Array = []
var particles: Array = []
var sword_afterimages: Array = []
var sword_trail_points: Array = []
var sword_air_wakes: Array = []
var sword_return_catches: Array = []
var sword_hit_effects: Array = []
var boss: Dictionary = {}
var hit_registry: HitRegistry = HitRegistry.new()
var hurtbox_registry: HurtboxRegistry = HurtboxRegistry.new()
var damage_resolver: DamageResolver = DamageResolver.new()
var hit_detection: HitDetection = HitDetection.new()
var target_descriptor_registry: TargetDescriptorRegistry = TargetDescriptorRegistry.new()
var target_event_system: TargetEventSystem = TargetEventSystem.new()
var target_writeback_adapters: TargetWritebackAdapters = TargetWritebackAdapters.new()
var combat_runtime: Dictionary = {}
var enemy_packages: Dictionary = {}

var wave: int = 1
var enemies_to_spawn: int = WAVE_BASE_ENEMIES
var wave_spawn_queue: Array = []
var spawn_timer: float = 0.0
var score: int = 0
var is_game_over: bool = false
var screen_shake: float = 0.0
var elapsed_time: float = 0.0
var id_counter: int = 0
var status_message: String = ""
var status_message_timer: float = 0.0
var status_message_color: Color = Color.WHITE
var action_failure_cooldowns: Dictionary = {}
var energy_feedback_timer: float = 0.0
var energy_feedback_color: Color = Color.WHITE
var array_feedback_timer: float = 0.0
var array_feedback_color: Color = Color.WHITE
var focus_status_message: String = ""
var focus_status_message_timer: float = 0.0
var focus_status_message_color: Color = Color.WHITE
var array_energy_forecast_level: int = ArrayEnergyForecastLevel.NONE
var array_energy_warning_display: float = 0.0
var array_energy_break_timer: float = 0.0
var array_mode_confirm_timer: float = 0.0
var array_mode_confirm_cooldown: float = 0.0
var array_mode_confirm_mode: String = ""
var array_mode_confirm_angle: float = 0.0
var energy_gain_feedback_timer: float = 0.0
var energy_gain_feedback_strength: float = 0.0
var energy_gain_feedback_color: Color = Color.WHITE
var hitstop_timer: float = 0.0
var hitstop_queue: Array = []
var hitstop_gap_timer: float = 0.0

var mouse_world: Vector2 = ARENA_SIZE * 0.5
var left_mouse_held: bool = false
var right_mouse_held: bool = false
var is_start_menu_active: bool = true
var start_menu: Control = null
var start_button: Button = null
var lookdev_preview_time := 0.0
var lookdev_preview_loop_index := -1
var lookdev_preview_events: Dictionary = {}
var lookdev_control_panel: PanelContainer = null
var lookdev_slider_rows: Array = []
var lookdev_reset_button: Button = null
var lookdev_save_preview_button: Button = null
var lookdev_save_game_button: Button = null
var lookdev_source_sword_vfx_profile: SwordVfxProfile = null


func get_sword_vfx_profile() -> SwordVfxProfile:
	if sword_vfx_profile == null:
		sword_vfx_profile = DEFAULT_SWORD_VFX_PROFILE
	return sword_vfx_profile
var debug_battle_mode: bool = false
var debug_flags: Dictionary = {}
var debug_calibration_mode: bool = false
var debug_dragging_player: bool = false
var visual_time_stop_strength: float = 0.0
var visual_time_stop_hold_timer: float = 0.0
var visual_time_stop_entry_pulse_timer: float = 0.0
var unsheath_flash_timer: float = 0.0
var unsheath_flash_origin: Vector2 = ARENA_SIZE * 0.5
var unsheath_flash_direction: Vector2 = Vector2.RIGHT
var unsheath_flash_strength: float = 0.0
var unsheath_flash_repeat_timer: float = 0.0
var unsheath_press_flash_timer: float = 0.0
var unsheath_press_flash_origin: Vector2 = ARENA_SIZE * 0.5
var unsheath_press_flash_direction: Vector2 = Vector2.RIGHT
var unsheath_press_flash_strength: float = 0.0
var unsheath_press_flash_repeat_timer: float = 0.0

const DEBUG_ENEMY_LAYOUT := [
	Vector2(120.0, 110.0),
	Vector2(260.0, 110.0),
	Vector2(400.0, 110.0),
	Vector2(540.0, 110.0),
	Vector2(680.0, 110.0),
	Vector2(120.0, 280.0),
	Vector2(260.0, 280.0),
	Vector2(400.0, 280.0),
	Vector2(540.0, 280.0),
	Vector2(680.0, 280.0),
	Vector2(120.0, 450.0),
	Vector2(260.0, 450.0),
	Vector2(400.0, 450.0),
	Vector2(540.0, 450.0),
	Vector2(680.0, 450.0),
]

@onready var health_label: Label = $CanvasLayer/HealthLabel
@onready var energy_label: Label = $CanvasLayer/EnergyLabel
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var mode_label: Label = $CanvasLayer/ModeLabel
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var focus_status_label: Label = $CanvasLayer/FocusStatusLabel
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var game_over_label: Label = $CanvasLayer/GameOverLabel
@onready var canvas_layer: CanvasLayer = $CanvasLayer


func _ready() -> void:
	randomize()
	SwordArrayConfig.load_morph_distances_from_project()
	_reset_game()
	_apply_demo_art_label_style()
	if lookdev_mode:
		_enter_lookdev_mode()
		return
	_build_start_menu()
	_show_start_menu()


func _apply_demo_art_label_style() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	_style_demo_label(health_label, 18, Color("f1e3bc"), HORIZONTAL_ALIGNMENT_LEFT)
	_style_demo_label(energy_label, 17, Color("d7bb79"), HORIZONTAL_ALIGNMENT_LEFT)
	_style_demo_label(wave_label, 17, Color("f1e3bc"), HORIZONTAL_ALIGNMENT_LEFT)
	_style_demo_label(score_label, 16, Color("9cb0c2"), HORIZONTAL_ALIGNMENT_LEFT)
	_style_demo_label(status_label, 24, Color("f1e3bc"), HORIZONTAL_ALIGNMENT_CENTER)
	_style_demo_label(mode_label, 22, Color("f1e3bc"), HORIZONTAL_ALIGNMENT_CENTER)
	_style_demo_label(focus_status_label, 22, Color("f1e3bc"), HORIZONTAL_ALIGNMENT_CENTER)
	_style_demo_label(hint_label, 18, Color("9cb0c2"), HORIZONTAL_ALIGNMENT_CENTER)
	_style_demo_label(game_over_label, 34, Color("f1e3bc"), HORIZONTAL_ALIGNMENT_CENTER)
	health_label.position = Vector2(96.0, 16.0)
	health_label.size = Vector2(260.0, 24.0)
	energy_label.position = Vector2(96.0, 48.0)
	energy_label.size = Vector2(260.0, 24.0)
	wave_label.position = Vector2(96.0, 86.0)
	wave_label.size = Vector2(260.0, 24.0)
	score_label.position = Vector2(96.0, 112.0)
	score_label.size = Vector2(520.0, 96.0)
	status_label.position = Vector2(viewport_size.x * 0.5 - 220.0, 24.0)
	status_label.size = Vector2(440.0, 36.0)
	mode_label.position = Vector2(viewport_size.x - 116.0, 34.0)
	mode_label.size = Vector2(108.0, 52.0)
	hint_label.position = Vector2(220.0, viewport_size.y - 36.0)
	hint_label.size = Vector2(viewport_size.x - 440.0, 28.0)
	game_over_label.position = Vector2(viewport_size.x * 0.5 - 280.0, viewport_size.y * 0.5 - 120.0)
	game_over_label.size = Vector2(560.0, 240.0)


func _style_demo_label(label: Label, font_size: int, font_color: Color, alignment: HorizontalAlignment) -> void:
	label.horizontal_alignment = alignment
	label.clip_text = false
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.68))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _process(delta: float) -> void:
	if lookdev_mode:
		_process_lookdev(delta)
		return
	if is_start_menu_active:
		queue_redraw()
		return
	if is_game_over:
		queue_redraw()
		return
	if _consume_hitstop(delta):
		queue_redraw()
		return

	elapsed_time += delta

	var is_flying_sword: bool = sword["state"] != SwordState.ORBITING
	if is_flying_sword:
		sword["time_slow_timer"] += delta
	else:
		sword["time_slow_timer"] = 0.0
	_update_time_stop_visual(delta, is_flying_sword)
	unsheath_flash_timer = max(unsheath_flash_timer - delta, 0.0)
	unsheath_flash_repeat_timer = max(unsheath_flash_repeat_timer - delta, 0.0)
	unsheath_press_flash_timer = max(unsheath_press_flash_timer - delta, 0.0)
	unsheath_press_flash_repeat_timer = max(unsheath_press_flash_repeat_timer - delta, 0.0)

	var bullet_time_ratio: float = 1.0
	var player_time_ratio: float = 1.0
	if is_flying_sword:
		var time_slow_timer: float = float(sword["time_slow_timer"])
		bullet_time_ratio = _get_bullet_time_ratio(time_slow_timer)
		player_time_ratio = _get_player_bullet_time_ratio(time_slow_timer)

	var bullet_time_delta: float = delta * bullet_time_ratio
	var player_delta: float = delta * player_time_ratio

	if right_mouse_held:
		var previous_press_timer: float = sword["press_timer"]
		sword["press_timer"] += delta
		if previous_press_timer <= SWORD_TAP_THRESHOLD and sword["press_timer"] > SWORD_TAP_THRESHOLD and sword["state"] == SwordState.ORBITING:
			_start_slicing()

	_update_array_morph_control(delta)
	_refresh_sword_array_live_state()

	if debug_calibration_mode:
		_ensure_debug_calibration_state()

	if not _can_use_array_attack() and bool(player.get("array_is_firing", false)):
		_reset_sword_array_hold_state()

	player["array_hold_ratio"] = 0.0
	if left_mouse_held:
		player["array_hold_timer"] = min(
			float(player.get("array_hold_timer", 0.0)) + delta,
			SwordArrayConfig.HOLD_THRESHOLD
		)
		player["array_hold_ratio"] = clampf(float(player.get("array_hold_timer", 0.0)) / SwordArrayConfig.HOLD_THRESHOLD, 0.0, 1.0)
	else:
		player["array_hold_timer"] = 0.0
	if _can_use_array_attack():
		if not player["array_is_firing"]:
			if _get_ready_array_sword_count() > 0:
				_begin_sword_array_firing()
		else:
			player["array_hold_ratio"] = 1.0
			_update_sword_array_continuous_firing(delta)

	_update_status_feedback(delta)
	_update_focus_status_feedback(delta)
	_update_action_feedback(delta)
	_update_array_energy_feedback_state(delta)
	_update_array_mode_confirm_feedback(delta)
	_update_player(delta, player_delta)
	_update_sword(delta)
	_update_boss(delta, bullet_time_delta)
	_update_enemies(bullet_time_delta)
	_update_bullets(delta, bullet_time_delta)
	_update_array_swords(delta)
	_update_particles(bullet_time_delta)
	_update_sword_hit_effects(delta)
	_update_wave(delta)
	_apply_debug_runtime_overrides()

	if player["health"] <= 0.0:
		_set_game_over()

	screen_shake = lerpf(screen_shake, 0.0, min(delta * 10.0, 1.0))
	_update_ui()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if lookdev_mode:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_1:
					lookdev_preview_mode = LookdevPreviewMode.POINT
					_reset_lookdev_preview()
				KEY_2:
					lookdev_preview_mode = LookdevPreviewMode.SLICE
					_reset_lookdev_preview()
				KEY_3:
					lookdev_preview_mode = LookdevPreviewMode.RECALL
					_reset_lookdev_preview()
				KEY_SPACE:
					set_process(not is_processing())
				KEY_R:
					_reset_lookdev_preview()
		return
	if is_start_menu_active:
		if event is InputEventMouseMotion:
			mouse_world = _screen_to_world(event.position)
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
				_start_game_from_menu()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _handle_debug_key_input(event):
			return
	if event is InputEventMouseMotion:
		mouse_world = _screen_to_world(event.position)
		if debug_calibration_mode and debug_dragging_player:
			_set_debug_player_position(mouse_world)
	elif event is InputEventMouseButton:
		mouse_world = _screen_to_world(event.position)
		if debug_calibration_mode and event.button_index == MOUSE_BUTTON_MIDDLE:
			debug_dragging_player = event.pressed
			if event.pressed:
				_set_debug_player_position(mouse_world)
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_game_over:
					_reset_game()
					return
				left_mouse_held = true
				if sword["state"] == SwordState.ORBITING and player["attack_cooldown"] <= 0.0:
					_perform_melee_attack()
			else:
				left_mouse_held = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_game_over:
				return
			if event.pressed:
				right_mouse_held = true
				sword["press_timer"] = 0.0
				sword["target_pos"] = mouse_world
				if sword["state"] == SwordState.ORBITING:
					_trigger_unsheath_press_flash(mouse_world - player["pos"])
			else:
				right_mouse_held = false
				if sword["state"] == SwordState.ORBITING:
					if sword["press_timer"] < SWORD_TAP_THRESHOLD:
						_start_point_strike()
				elif sword["state"] == SwordState.SLICING:
					sword["state"] = SwordState.RECALLING


func _draw() -> void:
	GameRenderer.draw_game(self )


func _draw_hud_bars() -> void:
	GameRenderer.draw_hud_bars(self )


func _build_start_menu() -> void:
	if start_menu != null:
		return

	start_menu = Control.new()
	start_menu.name = "StartMenu"
	start_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	start_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	$CanvasLayer.add_child(start_menu)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.012, 0.024, 0.042, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_menu.add_child(backdrop)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_menu.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "MenuPanel"
	panel.custom_minimum_size = Vector2(860.0, 620.0)
	panel.add_theme_stylebox_override("panel", _make_start_menu_style(Color(0.03, 0.055, 0.09, 0.92), Color("d7bb79"), 1, 8))
	center.add_child(panel)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 34)
	margins.add_theme_constant_override("margin_top", 26)
	margins.add_theme_constant_override("margin_right", 34)
	margins.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margins)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	margins.add_child(content)

	var title_label := Label.new()
	title_label.text = "剑修试炼"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 46)
	title_label.add_theme_color_override("font_color", Color("f1e3bc"))
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = "御剑成阵，近守远破。先看操作，再入试炼。"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color("9cb0c2"))
	content.add_child(subtitle_label)

	start_button = Button.new()
	start_button.text = "开始游戏"
	start_button.custom_minimum_size = Vector2(0.0, 54.0)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.add_theme_color_override("font_color", Color("f1e3bc"))
	start_button.add_theme_color_override("font_hover_color", Color("f6fbff"))
	start_button.add_theme_color_override("font_pressed_color", Color("f6fbff"))
	start_button.add_theme_stylebox_override("normal", _make_start_menu_style(Color(0.09, 0.13, 0.16, 0.94), Color("d7bb79"), 1, 6))
	start_button.add_theme_stylebox_override("hover", _make_start_menu_style(Color(0.11, 0.18, 0.22, 0.98), Color("88d8ff"), 1, 6))
	start_button.add_theme_stylebox_override("pressed", _make_start_menu_style(Color(0.13, 0.16, 0.13, 0.98), Color("f1e3bc"), 1, 6))
	start_button.pressed.connect(_start_game_from_menu)
	content.add_child(start_button)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0.0, 1.0)
	divider.color = Color(0.84, 0.74, 0.5, 0.28)
	content.add_child(divider)

	var guide_title := Label.new()
	guide_title.text = "操作说明"
	guide_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_title.add_theme_font_size_override("font_size", 26)
	guide_title.add_theme_color_override("font_color", Color("f1e3bc"))
	content.add_child(guide_title)

	var guide_label := RichTextLabel.new()
	guide_label.bbcode_enabled = true
	guide_label.text = START_MENU_OPERATION_TEXT
	guide_label.custom_minimum_size = Vector2(0.0, 350.0)
	guide_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.scroll_active = true
	guide_label.selection_enabled = false
	guide_label.add_theme_font_size_override("normal_font_size", 18)
	guide_label.add_theme_font_size_override("bold_font_size", 18)
	guide_label.add_theme_color_override("default_color", Color("d8e2ea"))
	content.add_child(guide_label)


func _make_start_menu_style(background_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	return style


func _show_start_menu() -> void:
	is_start_menu_active = true
	left_mouse_held = false
	right_mouse_held = false
	if start_menu != null:
		start_menu.visible = true
		start_menu.move_to_front()
	if start_button != null:
		start_button.grab_focus()
	queue_redraw()


func _start_game_from_menu() -> void:
	if not is_start_menu_active:
		return
	is_start_menu_active = false
	left_mouse_held = false
	right_mouse_held = false
	if start_menu != null:
		start_menu.visible = false
	_reset_game()


func _enter_lookdev_mode() -> void:
	is_start_menu_active = false
	left_mouse_held = false
	right_mouse_held = false
	if start_menu != null:
		start_menu.visible = false
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_layout_lookdev_control_panel):
		viewport.size_changed.connect(_layout_lookdev_control_panel)
	lookdev_source_sword_vfx_profile = sword_vfx_profile if sword_vfx_profile != null else DEFAULT_LOOKDEV_SWORD_VFX_PROFILE
	sword_vfx_profile = lookdev_source_sword_vfx_profile.duplicate(true)
	debug_flags["no_spawn"] = true
	debug_flags["infinite_health"] = true
	debug_flags["infinite_energy"] = true
	_configure_lookdev_runtime()
	_reset_lookdev_preview()
	_create_lookdev_control_panel()
	_update_ui()
	queue_redraw()


func _configure_lookdev_runtime() -> void:
	player["health"] = PLAYER_MAX_HEALTH
	player["energy"] = PLAYER_MAX_ENERGY
	player["pos"] = ARENA_SIZE * Vector2(0.32, 0.54)
	mouse_world = player["pos"] + Vector2(200.0, -80.0)
	enemies.clear()
	bullets.clear()
	array_swords.clear()
	enemy_packages.clear()
	particles.clear()
	sword_afterimages.clear()
	sword_trail_points.clear()
	sword_air_wakes.clear()
	sword_return_catches.clear()
	sword_hit_effects.clear()
	boss.clear()
	enemies_to_spawn = 0
	wave_spawn_queue.clear()
	spawn_timer = 9999.0
	wave = 1
	score = 0


func _process_lookdev(delta: float) -> void:
	if is_game_over:
		is_game_over = false
	var scaled_delta: float = delta * lookdev_playback_speed
	elapsed_time += scaled_delta
	lookdev_preview_time += scaled_delta

	var is_flying_sword: bool = sword["state"] != SwordState.ORBITING
	if is_flying_sword:
		sword["time_slow_timer"] += scaled_delta
	else:
		sword["time_slow_timer"] = 0.0
	_update_time_stop_visual(scaled_delta, is_flying_sword)
	unsheath_flash_timer = max(unsheath_flash_timer - scaled_delta, 0.0)
	unsheath_flash_repeat_timer = max(unsheath_flash_repeat_timer - scaled_delta, 0.0)
	unsheath_press_flash_timer = max(unsheath_press_flash_timer - scaled_delta, 0.0)
	unsheath_press_flash_repeat_timer = max(unsheath_press_flash_repeat_timer - scaled_delta, 0.0)

	_drive_lookdev_preview()
	_update_status_feedback(scaled_delta)
	_update_focus_status_feedback(scaled_delta)
	_update_action_feedback(scaled_delta)
	_update_array_energy_feedback_state(scaled_delta)
	_update_array_mode_confirm_feedback(scaled_delta)
	_update_sword(scaled_delta)
	_update_particles(scaled_delta)
	_update_sword_hit_effects(scaled_delta)

	screen_shake = lerpf(screen_shake, 0.0, min(scaled_delta * 10.0, 1.0))
	_update_ui()
	queue_redraw()


func _reset_lookdev_preview() -> void:
	lookdev_preview_time = 0.0
	lookdev_preview_loop_index = -1
	lookdev_preview_events.clear()
	_reset_game()
	_configure_lookdev_runtime()
	sword["pos"] = player["pos"] + Vector2(34.0, -18.0)
	sword["prev_pos"] = sword["pos"]
	sword["angle"] = 0.0
	sword["state"] = SwordState.ORBITING
	player["mode"] = CombatMode.RANGED
	status_message = "御剑特效预览"
	status_message_timer = 0.0
	hint_label.text = "1 点刺 | 2 连斩 | 3 回收 | Space 暂停/继续 | R 重播"


func _drive_lookdev_preview() -> void:
	var duration: float = _get_lookdev_preview_duration()
	var loop_index: int = int(floor(lookdev_preview_time / maxf(duration, 0.001)))
	if loop_index != lookdev_preview_loop_index:
		lookdev_preview_loop_index = loop_index
		lookdev_preview_events.clear()
	if lookdev_auto_cycle and lookdev_preview_time >= duration * 3.0:
		lookdev_preview_mode = (int(lookdev_preview_mode) + 1) % LookdevPreviewMode.size()
		_reset_lookdev_preview()
		return
	var local_time: float = fmod(lookdev_preview_time, duration)
	match lookdev_preview_mode:
		LookdevPreviewMode.POINT:
			_update_lookdev_point(local_time, duration)
		LookdevPreviewMode.SLICE:
			_update_lookdev_slice(local_time, duration)
		LookdevPreviewMode.RECALL:
			_update_lookdev_recall(local_time, duration)


func _get_lookdev_preview_duration() -> float:
	match lookdev_preview_mode:
		LookdevPreviewMode.SLICE:
			return 3.4
		LookdevPreviewMode.RECALL:
			return 2.4
		_:
			return 2.8


func _update_lookdev_point(local_time: float, duration: float) -> void:
	var player_pos: Vector2 = Vector2(player["pos"])
	var prep_duration: float = duration * 0.18
	var idle_start: float = duration * 0.82
	var launch_pos: Vector2 = player_pos + Vector2(38.0, -24.0)
	var target_pos: Vector2 = Vector2(ARENA_SIZE.x * 0.74, ARENA_SIZE.y * 0.3)
	mouse_world = target_pos
	if local_time < prep_duration:
		sword["pos"] = player_pos.lerp(launch_pos, local_time / maxf(prep_duration, 0.001))
		sword["prev_pos"] = sword["pos"]
	elif local_time < idle_start and _consume_lookdev_event("point_start"):
		_start_point_strike()
	elif local_time >= idle_start and sword["state"] == SwordState.ORBITING:
		sword["pos"] = player_pos.lerp(launch_pos, clampf((duration - local_time) / maxf(duration - idle_start, 0.001), 0.0, 1.0))
		sword["prev_pos"] = sword["pos"]


func _update_lookdev_slice(local_time: float, duration: float) -> void:
	var player_pos: Vector2 = Vector2(player["pos"])
	var prep_duration: float = duration * 0.16
	var slice_end: float = prep_duration + duration * 0.62
	var launch_pos: Vector2 = player_pos + Vector2(46.0, -26.0)
	var curve_center: Vector2 = Vector2(ARENA_SIZE.x * 0.58, ARENA_SIZE.y * 0.46)
	var radius_x: float = 180.0
	var radius_y: float = 104.0
	if local_time < prep_duration:
		sword["pos"] = player_pos.lerp(launch_pos, local_time / maxf(prep_duration, 0.001))
		sword["prev_pos"] = sword["pos"]
	elif _consume_lookdev_event("slice_start"):
		mouse_world = curve_center + Vector2(radius_x, 0.0)
		_start_slicing()
	if local_time >= prep_duration and local_time < slice_end:
		var slice_ratio: float = (local_time - prep_duration) / maxf(slice_end - prep_duration, 0.001)
		var angle: float = lerpf(-1.2, 2.55, slice_ratio) + sin(slice_ratio * TAU * 2.0) * 0.14
		mouse_world = curve_center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
	elif local_time >= slice_end and sword["state"] == SwordState.SLICING:
		sword["state"] = SwordState.RECALLING


func _update_lookdev_recall(local_time: float, duration: float) -> void:
	var player_pos: Vector2 = Vector2(player["pos"])
	var start_pos: Vector2 = Vector2(ARENA_SIZE.x * 0.78, ARENA_SIZE.y * 0.28)
	var end_pos: Vector2 = player_pos + Vector2(10.0, -10.0)
	mouse_world = end_pos
	if _consume_lookdev_event("recall_seed"):
		sword["pos"] = start_pos
		sword["prev_pos"] = start_pos
		sword["state"] = SwordState.RECALLING
		player["mode"] = CombatMode.RANGED
		_start_sword_attack_instance(AttackProfiles.PROFILE_FLYING_SWORD_SLICE)
	if local_time < duration:
		sword["target_pos"] = end_pos


func _consume_lookdev_event(event_key: String) -> bool:
	if lookdev_preview_events.has(event_key):
		return false
	lookdev_preview_events[event_key] = true
	return true


func _reset_game() -> void:
	GameStateFactory.reset_runtime(self )
	action_failure_cooldowns.clear()
	energy_feedback_timer = 0.0
	energy_feedback_color = Color.WHITE
	array_feedback_timer = 0.0
	array_feedback_color = Color.WHITE
	focus_status_message = ""
	focus_status_message_timer = 0.0
	focus_status_message_color = Color.WHITE
	array_energy_forecast_level = ArrayEnergyForecastLevel.NONE
	array_energy_warning_display = 0.0
	array_energy_break_timer = 0.0
	array_mode_confirm_timer = 0.0
	array_mode_confirm_cooldown = 0.0
	array_mode_confirm_mode = ""
	array_mode_confirm_angle = 0.0


func _update_player(delta: float, player_delta: float) -> void:
	if debug_calibration_mode and debug_dragging_player:
		player["vel"] = Vector2.ZERO
		player["attack_cooldown"] = max(player["attack_cooldown"] - delta, 0.0)
		player["attack_flash_timer"] = max(player["attack_flash_timer"] - delta, 0.0)
		return
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not move_input.is_zero_approx():
		player["vel"] = move_input.normalized() * PLAYER_SPEED
	else:
		player["vel"] = player["vel"].lerp(Vector2.ZERO, min(delta * 8.0, 1.0))

	player["pos"] += player["vel"] * player_delta
	player["pos"] = player["pos"].clamp(Vector2(PLAYER_RADIUS, PLAYER_RADIUS), ARENA_SIZE - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))

	player["attack_cooldown"] = max(player["attack_cooldown"] - delta, 0.0)
	player["attack_flash_timer"] = max(player["attack_flash_timer"] - delta, 0.0)


func _get_bullet_time_recovery_duration() -> float:
	return BULLET_TIME_RECOVERY_DURATION


func _get_bullet_time_ratio(time_slow_timer: float) -> float:
	var recovery_duration: float = _get_bullet_time_recovery_duration()
	var recovery_progress: float = clampf(time_slow_timer / recovery_duration, 0.0, 1.0)
	return lerpf(BULLET_TIME_START_MULTIPLIER, 1.0, recovery_progress)


func _get_player_bullet_time_ratio(time_slow_timer: float) -> float:
	var recovery_duration: float = _get_bullet_time_recovery_duration()
	var recovery_progress: float = clampf(time_slow_timer / recovery_duration, 0.0, 1.0)
	return lerpf(PLAYER_BULLET_TIME_SPEED_MULTIPLIER, 1.0, recovery_progress)


func _update_time_stop_visual(delta: float, is_flying_sword: bool) -> void:
	var had_visual_presence: bool = _has_time_stop_visual_presence()
	visual_time_stop_hold_timer = max(visual_time_stop_hold_timer - delta, 0.0)
	visual_time_stop_entry_pulse_timer = max(visual_time_stop_entry_pulse_timer - delta, 0.0)
	var target_strength: float = 0.0
	if is_flying_sword:
		target_strength = _get_time_stop_gameplay_strength() * TIME_STOP_VISUAL_MAX_STRENGTH
		visual_time_stop_hold_timer = TIME_STOP_VISUAL_RELEASE_HOLD
		if not had_visual_presence:
			visual_time_stop_entry_pulse_timer = TIME_STOP_VISUAL_ENTRY_PULSE_DURATION
	elif visual_time_stop_hold_timer > 0.0 and TIME_STOP_VISUAL_RELEASE_HOLD > 0.0:
		var hold_ratio: float = clampf(visual_time_stop_hold_timer / TIME_STOP_VISUAL_RELEASE_HOLD, 0.0, 1.0)
		target_strength = TIME_STOP_VISUAL_HOLD_FLOOR * hold_ratio
	var smoothing_speed: float = TIME_STOP_VISUAL_ENTER_SPEED if target_strength > visual_time_stop_strength else TIME_STOP_VISUAL_EXIT_SPEED
	visual_time_stop_strength = move_toward(visual_time_stop_strength, target_strength, delta * smoothing_speed)


func _has_time_stop_visual_presence() -> bool:
	return (
		visual_time_stop_strength > 0.04
		or visual_time_stop_hold_timer > 0.0
		or visual_time_stop_entry_pulse_timer > 0.0
	)


func _get_time_stop_gameplay_strength() -> float:
	var bullet_time_ratio: float = _get_bullet_time_ratio(float(sword.get("time_slow_timer", 0.0)))
	var max_slow_amount: float = maxf(1.0 - BULLET_TIME_START_MULTIPLIER, 0.001)
	return clampf((1.0 - bullet_time_ratio) / max_slow_amount, 0.0, 1.0)


func _get_time_stop_visual_strength() -> float:
	return visual_time_stop_strength


func _get_time_stop_entry_pulse_strength() -> float:
	if TIME_STOP_VISUAL_ENTRY_PULSE_DURATION <= 0.0:
		return 0.0
	var pulse_ratio: float = clampf(visual_time_stop_entry_pulse_timer / TIME_STOP_VISUAL_ENTRY_PULSE_DURATION, 0.0, 1.0)
	return pow(pulse_ratio, 1.6)


func _get_time_stop_world_color(color: Color) -> Color:
	var strength: float = _get_time_stop_visual_strength()
	if strength <= 0.0:
		return color
	var shaped_strength: float = clampf(pow(strength, 0.72) * 1.06, 0.0, 1.0)
	var luminance: float = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
	var frozen_color := Color(luminance, luminance, luminance, color.a)
	frozen_color = frozen_color.darkened(0.08 * shaped_strength)
	frozen_color = frozen_color.lerp(Color(0.8, 0.9, 1.0, color.a), 0.3 * shaped_strength)
	return color.lerp(frozen_color, minf(shaped_strength * 1.04, 1.0))


func _get_time_stop_world_wash_alpha() -> float:
	var sustain_alpha: float = TIME_STOP_VISUAL_WASH_SUSTAIN_ALPHA * sqrt(_get_time_stop_visual_strength())
	var pulse_alpha: float = TIME_STOP_VISUAL_WASH_PULSE_ALPHA * _get_time_stop_entry_pulse_strength()
	return sustain_alpha + pulse_alpha


func _get_unsheath_flash_progress() -> float:
	if UNSHEATH_FLASH_DURATION <= 0.0:
		return 0.0
	return clampf(unsheath_flash_timer / UNSHEATH_FLASH_DURATION, 0.0, 1.0)


func _get_unsheath_press_flash_progress() -> float:
	if UNSHEATH_PRESS_FLASH_DURATION <= 0.0:
		return 0.0
	return clampf(unsheath_press_flash_timer / UNSHEATH_PRESS_FLASH_DURATION, 0.0, 1.0)


func _can_use_array_attack() -> bool:
	if not left_mouse_held:
		return false
	return float(player.get("array_hold_timer", 0.0)) >= SwordArrayConfig.HOLD_THRESHOLD


func _get_active_array_sword_count() -> int:
	return array_swords.size()


func _get_current_array_sword_capacity() -> int:
	return ARRAY_SWORD_COUNT


func _get_array_sortie_profile(mode: String) -> Dictionary:
	return SwordArrayConfig.get_profile(mode)


func _should_array_consume_energy() -> bool:
	return true


func _get_array_batch_mode() -> String:
	return String(_get_sword_array_fire_state().get("dominant_mode", SwordArrayConfig.MODE_RING))


func _get_array_mode_energy_cost_per_sword(mode: String) -> float:
	match mode:
		SwordArrayConfig.MODE_RING:
			return ARRAY_SWORD_ENERGY_COST_RING
		SwordArrayConfig.MODE_FAN:
			return ARRAY_SWORD_ENERGY_COST_FAN
		_:
			return ARRAY_SWORD_ENERGY_COST_PIERCE


func _get_array_sword_energy_cost(fire_count: int, mode := "") -> float:
	if fire_count <= 0 or not _should_array_consume_energy():
		return 0.0
	var resolved_mode: String = mode if mode != "" else _get_array_batch_mode()
	return float(fire_count) * _get_array_mode_energy_cost_per_sword(resolved_mode)


func _get_array_mode_batch_target(mode: String) -> int:
	var capacity: int = _get_current_array_sword_capacity()
	match mode:
		SwordArrayConfig.MODE_RING:
			return capacity
		SwordArrayConfig.MODE_FAN:
			return maxi(int(ceil(float(capacity) * 0.5)), 1)
		_:
			return 1


func _can_fire_array_batch(mode: String, ready_count: int) -> bool:
	return ready_count >= _get_array_mode_batch_target(mode)


func _get_array_mode_speed_scale(mode: String) -> float:
	match mode:
		SwordArrayConfig.MODE_RING:
			return 0.92
		SwordArrayConfig.MODE_FAN:
			return 1.0
		_:
			return 1.12


func _get_current_array_sword_speed(mode := "") -> float:
	var resolved_mode: String = mode if mode != "" else _get_array_batch_mode()
	return SwordArrayConfig.FIRED_SPEED * ARRAY_SWORD_FIRE_SPEED_SCALE * _get_array_mode_speed_scale(resolved_mode)


func _get_array_mode_return_speed_scale(mode: String) -> float:
	match mode:
		SwordArrayConfig.MODE_RING:
			return 0.9
		SwordArrayConfig.MODE_FAN:
			return 1.04
		_:
			return 1.32


func _get_current_array_sword_return_speed(mode := "") -> float:
	var resolved_mode: String = mode if mode != "" else _get_array_batch_mode()
	return ARRAY_SWORD_RETURN_SPEED * ARRAY_SWORD_RETURN_SPEED_SCALE * _get_array_mode_return_speed_scale(resolved_mode)


func _get_current_array_release_rate(base_rate: float) -> float:
	return maxf(base_rate, 0.0) * ARRAY_SWORD_RELEASE_RATE_SCALE


func _get_ready_array_sword_count() -> int:
	var ready_count: int = 0
	for array_sword in array_swords:
		if array_sword["state"] == "ready":
			ready_count += 1
	return ready_count


func _get_ready_array_swords() -> Array:
	var ready_swords: Array = []
	for array_sword in array_swords:
		if array_sword["state"] == "ready":
			ready_swords.append(array_sword)
	ready_swords.sort_custom(_sort_array_swords_by_slot)
	return ready_swords


func _sort_array_swords_by_slot(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("slot_index", 0)) < int(b.get("slot_index", 0))


func _build_array_sword(slot_index: int) -> Dictionary:
	return {
		"id": _next_id("array_sword"),
		"pos": player["pos"],
		"vel": Vector2.ZERO,
		"radius": ARRAY_SWORD_RADIUS,
		"slot_index": slot_index,
		"state": "ready",
		"attack_instance_id": "",
		"attack_profile_id": "",
		"travel_mode": SwordArrayConfig.MODE_RING,
		"trail_timer": 0.0,
		"guidance_active": false,
		"guidance_elapsed": 0.0,
		"guidance_distance": 0.0,
		"guidance_fire_index": - 1,
		"guidance_volley_count": - 1,
		"guidance_burst_step": 0,
		"guidance_total_count": - 1,
		"has_hit_target": false,
		"remaining_penetration": 1,
		"hit_target_cooldowns": {},
		"batch_id": "",
		"batch_return_ready": false,
		"return_unlock_distance": ARRAY_SWORD_MIN_SORTIE_DISTANCE,
		"flow_side": 1.0,
		"pending_remove": false,
	}


func _reset_array_sword_sortie_state(array_sword: Dictionary) -> void:
	var travel_mode: String = String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
	_clear_array_sword_attack_instance(array_sword)
	array_sword["trail_timer"] = 0.0
	array_sword["guidance_active"] = false
	array_sword["guidance_elapsed"] = 0.0
	array_sword["guidance_distance"] = 0.0
	array_sword["guidance_fire_index"] = -1
	array_sword["guidance_volley_count"] = -1
	array_sword["guidance_burst_step"] = 0
	array_sword["guidance_total_count"] = -1
	array_sword["has_hit_target"] = false
	array_sword["remaining_penetration"] = _get_array_sword_penetration_targets(travel_mode)
	array_sword["hit_target_cooldowns"] = {}
	array_sword["batch_id"] = ""
	array_sword["batch_return_ready"] = false
	array_sword["return_unlock_distance"] = _get_array_sword_min_sortie_distance(travel_mode)
	array_sword["flow_side"] = 1.0


func _get_array_attack_profile_id(travel_mode: String) -> String:
	match travel_mode:
		SwordArrayConfig.MODE_RING:
			return AttackProfiles.PROFILE_ARRAY_RING
		SwordArrayConfig.MODE_FAN:
			return AttackProfiles.PROFILE_ARRAY_FAN
		_:
			return AttackProfiles.PROFILE_ARRAY_PIERCE


func _start_array_sword_attack_instance(array_sword: Dictionary) -> void:
	var profile_id: String = _get_array_attack_profile_id(String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING)))
	if profile_id == "":
		return
	_clear_array_sword_attack_instance(array_sword)
	var source_node: String = str(array_sword.get("id", "array_sword"))
	var attack_instance: Dictionary = _build_attack_instance(profile_id, "player", source_node)
	array_sword["attack_instance_id"] = str(attack_instance.get("id", ""))
	array_sword["attack_profile_id"] = profile_id


func _clear_array_sword_attack_instance(array_sword: Dictionary) -> void:
	var attack_instance_id: String = str(array_sword.get("attack_instance_id", ""))
	if attack_instance_id != "":
		_clear_attack_instance(attack_instance_id)
	array_sword["attack_instance_id"] = ""
	array_sword["attack_profile_id"] = ""


func _rebuild_array_sword_pool() -> void:
	array_swords.clear()
	var sword_index: int = 0
	var target_count: int = _get_current_array_sword_capacity()
	while sword_index < target_count:
		array_swords.append(_build_array_sword(sword_index))
		sword_index += 1
	_layout_ready_array_swords(1.0)


func _sync_array_sword_pool_capacity() -> void:
	var target_count: int = _get_current_array_sword_capacity()
	var current_count: int = array_swords.size()
	if current_count < target_count:
		var add_index: int = current_count
		while add_index < target_count:
			array_swords.append(_build_array_sword(add_index))
			add_index += 1
	elif current_count > target_count:
		var sword_index: int = array_swords.size() - 1
		while sword_index >= 0 and array_swords.size() > target_count:
			var array_sword: Dictionary = array_swords[sword_index]
			if array_sword["state"] == "ready":
				array_swords.remove_at(sword_index)
			sword_index -= 1
		for array_sword in array_swords:
			array_sword["pending_remove"] = array_swords.size() > target_count
	array_swords.sort_custom(_sort_array_swords_by_slot)


func _get_array_sword_slot_position(slot_index: int, formation_ratio := -1.0) -> Vector2:
	var slot_count: int = _get_current_array_sword_capacity()
	if formation_ratio < 0.0:
		formation_ratio = _get_sword_array_formation_ratio()
	return SwordArrayController.get_slot_position(
		self ,
		_get_sword_array_morph_state(),
		slot_index,
		slot_count,
		formation_ratio
	)


func _layout_ready_array_swords(delta: float) -> void:
	var formation_ratio: float = _get_sword_array_formation_ratio()
	for array_sword in array_swords:
		if String(array_sword.get("state", "")) != "ready":
			continue
		var target_pos: Vector2 = _get_array_sword_slot_position(int(array_sword.get("slot_index", 0)), formation_ratio)
		array_sword["pos"] = array_sword["pos"].lerp(target_pos, min(delta * 18.0, 1.0))
		array_sword["vel"] = Vector2.ZERO


func _update_status_feedback(delta: float) -> void:
	status_message_timer = maxf(status_message_timer - delta, 0.0)
	if is_zero_approx(status_message_timer):
		status_message = ""


func _update_focus_status_feedback(delta: float) -> void:
	focus_status_message_timer = maxf(focus_status_message_timer - delta, 0.0)
	if is_zero_approx(focus_status_message_timer):
		focus_status_message = ""


func _update_action_feedback(delta: float) -> void:
	energy_feedback_timer = maxf(energy_feedback_timer - delta, 0.0)
	array_feedback_timer = maxf(array_feedback_timer - delta, 0.0)
	energy_gain_feedback_timer = maxf(energy_gain_feedback_timer - delta, 0.0)
	if energy_gain_feedback_timer <= 0.0:
		energy_gain_feedback_strength = 0.0


func _consume_hitstop(delta: float) -> bool:
	if hitstop_timer > 0.0:
		hitstop_timer = maxf(hitstop_timer - delta, 0.0)
		return true
	if hitstop_gap_timer > 0.0:
		hitstop_gap_timer = maxf(hitstop_gap_timer - delta, 0.0)
		return false
	if hitstop_queue.is_empty():
		return false
	hitstop_timer = maxf(float(hitstop_queue[0]), 0.0)
	hitstop_queue.remove_at(0)
	hitstop_gap_timer = FLYING_SWORD_POINT_HITSTOP_CHAIN_GAP if not hitstop_queue.is_empty() else 0.0
	hitstop_timer = maxf(hitstop_timer - delta, 0.0)
	return true


func _update_array_energy_feedback_state(delta: float) -> void:
	array_energy_break_timer = maxf(array_energy_break_timer - delta, 0.0)
	var forecast: Dictionary = _build_array_energy_forecast()
	array_energy_forecast_level = int(forecast.get("level", ArrayEnergyForecastLevel.NONE))
	var target_display: float = 0.0
	match array_energy_forecast_level:
		ArrayEnergyForecastLevel.WARNING:
			target_display = 0.58
		ArrayEnergyForecastLevel.CRITICAL:
			target_display = 1.0
	if array_energy_break_timer > 0.0:
		target_display = maxf(target_display, 1.0)
	array_energy_warning_display = move_toward(
		array_energy_warning_display,
		target_display,
		delta * ARRAY_ENERGY_WARNING_FADE_SPEED
	)


func _update_array_mode_confirm_feedback(delta: float) -> void:
	array_mode_confirm_timer = maxf(array_mode_confirm_timer - delta, 0.0)
	array_mode_confirm_cooldown = maxf(array_mode_confirm_cooldown - delta, 0.0)
	var fire_state: Dictionary = _get_sword_array_fire_state()
	var stable_mode: String = _get_array_stable_mode_from_state(fire_state)
	var is_array_engaged: bool = left_mouse_held or bool(player.get("array_is_firing", false))
	if not is_array_engaged:
		player["array_confirm_observed_stable_mode"] = stable_mode
		return
	if stable_mode == "":
		player["array_confirm_observed_stable_mode"] = ""
		return
	var observed_mode: String = str(player.get("array_confirm_observed_stable_mode", ""))
	if stable_mode == observed_mode:
		return
	player["array_confirm_observed_stable_mode"] = stable_mode
	if array_mode_confirm_cooldown > 0.0:
		return
	_trigger_array_mode_confirm(stable_mode)


func _show_status_message(message: String, color: Color, duration: float) -> void:
	status_message = message
	status_message_color = color
	status_message_timer = duration


func _show_focus_status_message(message: String, color: Color, duration: float) -> void:
	focus_status_message = message
	focus_status_message_color = color
	focus_status_message_timer = duration


func _get_energy_failure_color() -> Color:
	return COLORS["energy"].lerp(COLORS["health"], 0.4)


func _get_array_failure_color() -> Color:
	return COLORS["array_sword"].lerp(COLORS["health"], 0.38)


func _trigger_action_feedback(channel: String, color: Color, duration := ACTION_FAILURE_FLASH_DURATION) -> void:
	match channel:
		"energy":
			energy_feedback_timer = maxf(energy_feedback_timer, duration)
			energy_feedback_color = color
		"array":
			array_feedback_timer = maxf(array_feedback_timer, duration)
			array_feedback_color = color


func _show_action_failure(message: String, reason_key: String, color: Color, channel := "", duration := 0.8, repeat_delay := ACTION_FAILURE_REPEAT_DELAY) -> void:
	if channel != "":
		_trigger_action_feedback(channel, color)
	var next_allowed_time: float = float(action_failure_cooldowns.get(reason_key, 0.0))
	if elapsed_time < next_allowed_time:
		return
	action_failure_cooldowns[reason_key] = elapsed_time + repeat_delay
	if reason_key == "array_energy":
		_trigger_array_energy_break_feedback()
	_show_status_message(message, color, duration)
	_show_focus_status_message(message, color, minf(duration, FOCUS_STATUS_DURATION))
	_emit_action_feedback_sfx(reason_key)


func _emit_action_feedback_sfx(_reason_key: String) -> void:
	# Intentionally left as a hook until the project grows a shared SFX entry point.
	pass


func _trigger_array_energy_break_feedback() -> void:
	array_energy_break_timer = maxf(array_energy_break_timer, ARRAY_ENERGY_BREAK_DURATION)


func _trigger_array_mode_confirm(mode: String) -> void:
	array_mode_confirm_timer = ARRAY_MODE_CONFIRM_DURATION
	array_mode_confirm_cooldown = ARRAY_MODE_CONFIRM_COOLDOWN
	array_mode_confirm_mode = mode
	var aim_vector: Vector2 = mouse_world - player["pos"]
	if aim_vector.is_zero_approx():
		aim_vector = Vector2.RIGHT
	array_mode_confirm_angle = aim_vector.angle()


func _should_evaluate_array_energy_forecast() -> bool:
	if not left_mouse_held:
		return false
	if bool(player.get("array_is_firing", false)):
		return true
	return float(player.get("array_hold_ratio", 0.0)) >= ARRAY_ENERGY_WARNING_HOLD_RATIO_THRESHOLD


func _build_array_energy_forecast() -> Dictionary:
	var forecast: Dictionary = {
		"level": ArrayEnergyForecastLevel.NONE,
		"energy_cost": 0.0,
		"shots_remaining": 0,
	}
	if not _should_array_consume_energy() or not _should_evaluate_array_energy_forecast():
		return forecast
	var mode: String = _get_array_batch_mode()
	var ready_count: int = _get_ready_array_sword_count()
	if ready_count <= 0 or not _can_fire_array_batch(mode, ready_count):
		return forecast
	var fire_count: int = mini(_get_array_mode_batch_target(mode), ready_count)
	var energy_cost: float = _get_array_sword_energy_cost(fire_count, mode)
	forecast["energy_cost"] = energy_cost
	if energy_cost <= 0.0:
		return forecast
	var shots_remaining: int = int(floor(float(player.get("energy", 0.0)) / energy_cost))
	forecast["shots_remaining"] = shots_remaining
	if shots_remaining <= 0:
		forecast["level"] = ArrayEnergyForecastLevel.CRITICAL
	elif shots_remaining == 1:
		forecast["level"] = ArrayEnergyForecastLevel.WARNING
	return forecast


func _get_array_energy_warning_strength() -> float:
	return clampf(array_energy_warning_display, 0.0, 1.0)


func _get_array_energy_break_strength() -> float:
	if ARRAY_ENERGY_BREAK_DURATION <= 0.0:
		return 0.0
	return clampf(array_energy_break_timer / ARRAY_ENERGY_BREAK_DURATION, 0.0, 1.0)


func _get_array_stable_mode_from_state(state: Dictionary) -> String:
	var completed_state: Dictionary = SwordArrayConfig.complete_morph_state(state)
	var visual_from_mode: String = str(completed_state.get("visual_from_mode", ""))
	var visual_to_mode: String = str(completed_state.get("visual_to_mode", visual_from_mode))
	if visual_from_mode != "" and visual_from_mode == visual_to_mode:
		return str(completed_state.get("dominant_mode", visual_from_mode))
	return ""


func _get_array_mode_confirm_strength() -> float:
	if ARRAY_MODE_CONFIRM_DURATION <= 0.0:
		return 0.0
	return clampf(array_mode_confirm_timer / ARRAY_MODE_CONFIRM_DURATION, 0.0, 1.0)


func _get_sword_array_formation_ratio() -> float:
	if bool(player.get("array_is_firing", false)):
		return 1.0
	return clampf(float(player.get("array_hold_ratio", 0.0)), 0.0, 1.0)


func _should_draw_sword_array_preview() -> bool:
	return left_mouse_held and not bool(player.get("array_is_firing", false)) and float(player.get("array_hold_ratio", 0.0)) > 0.08


func _update_array_morph_control(delta: float) -> void:
	var raw_distance: float = player["pos"].distance_to(mouse_world)
	var control_distance: float = float(player.get("array_control_distance", raw_distance))
	var smoothing_speed: float = ARRAY_MORPH_CONTROL_SMOOTH_SPEED_IDLE
	if left_mouse_held:
		smoothing_speed = ARRAY_MORPH_CONTROL_SMOOTH_SPEED_HELD
	if bool(player.get("array_is_firing", false)):
		smoothing_speed = ARRAY_MORPH_CONTROL_SMOOTH_SPEED_FIRING
	control_distance = lerpf(control_distance, raw_distance, min(delta * smoothing_speed, 1.0))
	player["array_raw_aim_distance"] = raw_distance
	player["array_control_distance"] = control_distance


func _refresh_sword_array_live_state() -> void:
	var raw_distance: float = float(player.get("array_raw_aim_distance", player["pos"].distance_to(mouse_world)))
	var control_distance: float = float(player.get("array_control_distance", raw_distance))
	var visual_state: Dictionary = SwordArrayConfig.get_morph_state_for_distance(raw_distance)
	var fire_state: Dictionary = SwordArrayConfig.get_control_morph_state_for_distance(control_distance)
	player["array_morph_state"] = visual_state
	player["array_fire_morph_state"] = fire_state
	player["array_mode"] = fire_state["dominant_mode"]


func _begin_sword_array_firing() -> void:
	if not _can_use_array_attack():
		return
	var mode: String = _get_array_batch_mode()
	if not _can_fire_array_batch(mode, _get_ready_array_sword_count()):
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return
	_refresh_sword_array_live_state()
	player["array_is_firing"] = true
	player["array_release_progress"] = 1.0
	player["array_packet_remainder"] = 0.0
	if not _fire_array_swords():
		player["array_is_firing"] = false
		player["array_release_progress"] = 0.0
		player["array_packet_remainder"] = 0.0


func _update_sword_array_continuous_firing(delta: float) -> void:
	if not _can_use_array_attack():
		_reset_sword_array_hold_state()
		return
	var morph_state: Dictionary = _get_sword_array_fire_state()
	var mode: String = String(morph_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	var ready_count: int = _get_ready_array_sword_count()
	var release_profile: Dictionary = SwordArrayController.get_fire_release_profile(
		self ,
		morph_state,
		maxi(ready_count, 1)
	)
	var release_rate: float = _get_current_array_release_rate(float(release_profile.get("release_rate", 0.0)))
	player["array_release_progress"] = min(float(player.get("array_release_progress", 0.0)) + delta * release_rate, 1.25)
	var release_count: int = 0
	while player["array_release_progress"] >= 1.0 and release_count < 12:
		ready_count = _get_ready_array_sword_count()
		if not _can_fire_array_batch(mode, ready_count):
			_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
			player["array_release_progress"] = min(float(player.get("array_release_progress", 0.0)), 1.0)
			return
		if not _fire_array_swords():
			player["array_is_firing"] = false
			player["array_release_progress"] = 0.0
			player["array_packet_remainder"] = 0.0
			return
		player["array_release_progress"] -= 1.0
		release_count += 1
		morph_state = _get_sword_array_fire_state()
		release_profile = SwordArrayController.get_fire_release_profile(
			self ,
			morph_state,
			_get_ready_array_sword_count()
		)


func _get_sword_array_morph_state() -> Dictionary:
	return SwordArrayConfig.complete_morph_state(player.get("array_morph_state", {}))


func _get_sword_array_fire_state() -> Dictionary:
	return SwordArrayConfig.complete_morph_state(player.get("array_fire_morph_state", player.get("array_morph_state", {})))


func _get_array_sword_max_travel_distance(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_max_distance", ARRAY_SWORD_MAX_TRAVEL_DISTANCE))


func _get_array_sword_guidance_max_distance(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_guidance_max_distance", SwordArrayConfig.FIRED_GUIDANCE_MAX_DISTANCE))


func _get_array_sword_min_sortie_distance(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_min_distance", ARRAY_SWORD_MIN_SORTIE_DISTANCE))


func _get_array_sword_hit_follow_through_distance(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_hit_follow_through_distance", ARRAY_SWORD_HIT_FOLLOW_THROUGH_DISTANCE))


func _get_array_sword_hit_radius_bonus(mode: String) -> float:
	return float(_get_array_sortie_profile(mode).get("sortie_hit_radius_bonus", 0.0))


func _get_array_sword_penetration_targets(mode: String) -> int:
	return maxi(int(_get_array_sortie_profile(mode).get("sortie_penetration_targets", 1)), 1)


func _get_array_sword_rehit_cooldown(mode: String) -> float:
	return maxf(float(_get_array_sortie_profile(mode).get("sortie_rehit_cooldown", 0.0)), 0.0)


func _get_array_sword_launch_tangent_bias(mode: String) -> float:
	return maxf(float(_get_array_sortie_profile(mode).get("sortie_launch_tangent_bias", 0.0)), 0.0)


func _get_array_sword_guidance_tangent_bias(mode: String) -> float:
	return maxf(float(_get_array_sortie_profile(mode).get("sortie_guidance_tangent_bias", 0.0)), 0.0)


func _get_array_sword_return_swirl_strength(mode: String) -> float:
	return maxf(float(_get_array_sortie_profile(mode).get("sortie_return_swirl_strength", 0.0)), 0.0)


func _get_array_sword_return_turn_rate(mode: String) -> float:
	return maxf(float(_get_array_sortie_profile(mode).get("sortie_return_turn_rate", 10.0)), 0.0)


func _get_array_sword_flow_phase(array_sword: Dictionary) -> float:
	var slot_index: float = float(int(array_sword.get("slot_index", 0)))
	var fire_index: float = float(int(array_sword.get("guidance_fire_index", 0)))
	return sin(slot_index * 1.618 + fire_index * 0.73)


func _get_array_sword_flow_slot_weight(array_sword: Dictionary, travel_mode: String) -> float:
	var fire_count: int = maxi(int(array_sword.get("guidance_volley_count", 0)), 0)
	if fire_count <= 0:
		fire_count = _get_array_mode_batch_target(travel_mode)
	var fire_index: int = int(array_sword.get("guidance_fire_index", int(array_sword.get("slot_index", 0))))
	if fire_count > 0:
		fire_index = posmod(fire_index, fire_count)
	var center_weight: float = 1.0
	if fire_count > 1:
		var center_index: float = float(fire_count - 1) * 0.5
		center_weight = absf(float(fire_index) - center_index) / maxf(center_index, 1.0)
	var base_weight: float = 0.62
	match travel_mode:
		SwordArrayConfig.MODE_FAN:
			base_weight = lerpf(0.3, 0.72, center_weight)
		SwordArrayConfig.MODE_PIERCE:
			base_weight = lerpf(0.14, 0.28, center_weight)
		_:
			base_weight = 0.62
	return maxf(base_weight * (1.0 + _get_array_sword_flow_phase(array_sword) * 0.05), 0.0)


func _resolve_array_sword_flow_side(array_sword: Dictionary, reference_pos: Vector2, forward_dir: Vector2) -> float:
	var resolved_forward: Vector2 = forward_dir.normalized()
	if resolved_forward.is_zero_approx():
		resolved_forward = mouse_world - player["pos"]
	if resolved_forward.is_zero_approx():
		resolved_forward = Vector2.RIGHT
	var relative: Vector2 = reference_pos - player["pos"]
	var cross_value: float = resolved_forward.cross(relative)
	if absf(cross_value) > 0.001:
		return 1.0 if cross_value >= 0.0 else -1.0
	return 1.0 if int(array_sword.get("slot_index", 0)) % 2 == 0 else -1.0


func _blend_array_sword_direction_with_tangent(base_direction: Vector2, tangent_direction: Vector2, tangent_bias: float) -> Vector2:
	var resolved_base: Vector2 = base_direction.normalized()
	if resolved_base.is_zero_approx():
		return tangent_direction.normalized() if not tangent_direction.is_zero_approx() else Vector2.RIGHT
	if tangent_direction.is_zero_approx() or tangent_bias <= 0.0:
		return resolved_base
	var blended: Vector2 = resolved_base + tangent_direction.normalized() * tangent_bias
	if blended.is_zero_approx():
		return resolved_base
	return blended.normalized()


func _get_array_sword_launch_tangent_direction(travel_mode: String, launch_origin: Vector2, forward_dir: Vector2, flow_side: float) -> Vector2:
	var resolved_forward: Vector2 = forward_dir.normalized()
	if resolved_forward.is_zero_approx():
		resolved_forward = mouse_world - player["pos"]
	if resolved_forward.is_zero_approx():
		resolved_forward = Vector2.RIGHT
	match travel_mode:
		SwordArrayConfig.MODE_RING:
			var radial: Vector2 = launch_origin - player["pos"]
			if radial.is_zero_approx():
				radial = resolved_forward
			var tangent: Vector2 = radial.orthogonal().normalized()
			if tangent.dot(resolved_forward) < 0.0:
				tangent = - tangent
			return tangent
		_:
			if is_zero_approx(flow_side):
				flow_side = 1.0
			return resolved_forward.orthogonal().normalized() * flow_side


func _get_array_sword_return_tangent_direction(array_sword: Dictionary, to_target: Vector2) -> Vector2:
	var resolved_target: Vector2 = to_target.normalized()
	if resolved_target.is_zero_approx():
		return Vector2.ZERO
	var flow_side: float = float(array_sword.get("flow_side", 1.0))
	if is_zero_approx(flow_side):
		flow_side = 1.0
	return resolved_target.orthogonal().normalized() * flow_side


func _decay_array_sword_target_cooldowns(array_sword: Dictionary, delta: float) -> void:
	var hit_target_cooldowns: Dictionary = array_sword.get("hit_target_cooldowns", {})
	if typeof(hit_target_cooldowns) != TYPE_DICTIONARY:
		hit_target_cooldowns = {}
	var expired_targets: Array = []
	for target_id in hit_target_cooldowns.keys():
		var remaining_cooldown: float = maxf(float(hit_target_cooldowns[target_id]) - delta, 0.0)
		if remaining_cooldown <= 0.0:
			expired_targets.append(target_id)
		else:
			hit_target_cooldowns[target_id] = remaining_cooldown
	for target_id in expired_targets:
		hit_target_cooldowns.erase(target_id)
	array_sword["hit_target_cooldowns"] = hit_target_cooldowns


func _can_array_sword_hit_target(array_sword: Dictionary, target_id: String) -> bool:
	if target_id == "":
		return true
	var hit_target_cooldowns: Dictionary = array_sword.get("hit_target_cooldowns", {})
	if typeof(hit_target_cooldowns) != TYPE_DICTIONARY:
		return true
	return not hit_target_cooldowns.has(target_id)


func _register_array_sword_target_hit(array_sword: Dictionary, target_id: String, travel_mode: String) -> bool:
	var hit_target_cooldowns: Dictionary = array_sword.get("hit_target_cooldowns", {})
	if typeof(hit_target_cooldowns) != TYPE_DICTIONARY:
		hit_target_cooldowns = {}
	var rehit_cooldown: float = _get_array_sword_rehit_cooldown(travel_mode)
	if target_id != "" and rehit_cooldown > 0.0:
		hit_target_cooldowns[target_id] = rehit_cooldown
	array_sword["hit_target_cooldowns"] = hit_target_cooldowns
	var remaining_penetration: int = maxi(int(array_sword.get("remaining_penetration", _get_array_sword_penetration_targets(travel_mode))), 0)
	if remaining_penetration > 0:
		remaining_penetration -= 1
	array_sword["remaining_penetration"] = remaining_penetration
	return remaining_penetration <= 0


func _uses_fan_batch_return(array_sword: Dictionary) -> bool:
	return (
		String(array_sword.get("travel_mode", "")) == SwordArrayConfig.MODE_FAN
		and String(array_sword.get("batch_id", "")) != ""
	)


func _mark_fan_batch_member_ready(array_sword: Dictionary) -> void:
	array_sword["batch_return_ready"] = true
	array_sword["guidance_active"] = false
	array_sword["vel"] = Vector2.ZERO


func _is_fan_batch_ready_to_return(batch_id: String) -> bool:
	if batch_id == "":
		return false
	var has_batch_member: bool = false
	for array_sword in array_swords:
		if String(array_sword.get("batch_id", "")) != batch_id:
			continue
		if String(array_sword.get("state", "")) != "outbound":
			continue
		has_batch_member = true
		if not bool(array_sword.get("batch_return_ready", false)):
			return false
	return has_batch_member


func _begin_fan_batch_return(batch_id: String) -> void:
	if batch_id == "":
		return
	for array_sword in array_swords:
		if String(array_sword.get("batch_id", "")) != batch_id:
			continue
		if String(array_sword.get("state", "")) != "outbound":
			continue
		array_sword["has_hit_target"] = true
		array_sword["batch_return_ready"] = false
		_begin_array_sword_return(array_sword)


func _reset_sword_array_hold_state() -> void:
	player["array_hold_timer"] = 0.0
	player["array_hold_ratio"] = 0.0
	player["array_is_firing"] = false
	player["array_release_progress"] = 0.0
	player["array_packet_remainder"] = 0.0
	player["array_fire_index"] = 0
	_refresh_sword_array_live_state()


func _update_sword(delta: float) -> void:
	sword["prev_pos"] = sword["pos"]
	sword["impact_feedback_timer"] = maxf(float(sword.get("impact_feedback_timer", 0.0)) - delta, 0.0)
	sword["impact_feedback_offset"] = Vector2(sword.get("impact_feedback_offset", Vector2.ZERO)).move_toward(
		Vector2.ZERO,
		delta * SWORD_IMPACT_RETURN_SPEED
	)
	sword["impact_angle_offset"] = move_toward(
		float(sword.get("impact_angle_offset", 0.0)),
		0.0,
		delta * SWORD_IMPACT_ANGLE_RETURN_SPEED
	)
	_update_sword_return_catches(delta)

	if sword["state"] == SwordState.ORBITING:
		if str(sword.get("attack_instance_id", "")) != "":
			_end_sword_attack_instance()
		_add_player_energy(ENERGY_RECOVERY_MELEE_NATURAL * delta, false)
		var orbit_direction: Vector2 = mouse_world - player["pos"]
		if orbit_direction.is_zero_approx():
			orbit_direction = Vector2.RIGHT.rotated(sword["angle"])
		else:
			orbit_direction = orbit_direction.normalized()
		sword["angle"] = orbit_direction.angle()
		var target: Vector2 = player["pos"] + orbit_direction * SWORD_ORBIT_DISTANCE
		sword["vel"] = Vector2.ZERO
		sword["pos"] = sword["pos"].lerp(target, min(delta * 18.0, 1.0))
		_update_sword_trail(delta, Vector2.ZERO)
		_update_sword_air_wakes(delta, Vector2.ZERO)
		_update_sword_afterimages(delta, Vector2.ZERO)
		return

	if sword["state"] == SwordState.SLICING:
		sword["pos"] = sword["pos"].lerp(mouse_world, min(delta * 18.0, 1.0))
		sword["vel"] = mouse_world - sword["pos"]
	elif sword["state"] == SwordState.POINT_STRIKE:
		var to_target: Vector2 = sword["target_pos"] - sword["pos"]
		var move_distance: float = SWORD_POINT_STRIKE_SPEED * delta
		if to_target.length() > move_distance and to_target.length() > 10.0:
			sword["vel"] = to_target.normalized() * SWORD_POINT_STRIKE_SPEED
			sword["pos"] += sword["vel"] * delta
		else:
			sword["pos"] = sword["target_pos"]
			sword["vel"] = Vector2.ZERO
			sword["state"] = SwordState.RECALLING
			_set_sword_attack_profile(AttackProfiles.PROFILE_FLYING_SWORD_SLICE)
			screen_shake = max(screen_shake, 6.0)
			_create_particles(sword["pos"], COLORS["ranged_sword"], 12)
	elif sword["state"] == SwordState.RECALLING:
		var to_player: Vector2 = player["pos"] - sword["pos"]
		var recall_distance: float = SWORD_RECALL_SPEED * delta
		if to_player.length() > recall_distance and to_player.length() > 20.0:
			sword["vel"] = to_player.normalized() * SWORD_RECALL_SPEED
			sword["pos"] += sword["vel"] * delta
		else:
			var recall_direction: Vector2 = to_player.normalized()
			if recall_direction.is_zero_approx():
				recall_direction = Vector2.RIGHT.rotated(sword["angle"])
			if recall_direction.is_zero_approx():
				recall_direction = Vector2.RIGHT
			_emit_sword_return_catch(player["pos"], recall_direction)
			_create_particles(player["pos"], COLORS["array_sword_return"], 5)
			sword["pos"] = player["pos"]
			sword["vel"] = Vector2.ZERO
			sword["state"] = SwordState.ORBITING
			player["mode"] = CombatMode.MELEE
			sword["press_timer"] = 0.0
			_end_sword_attack_instance()

	if sword["vel"].length_squared() > 1.0:
		sword["angle"] = sword["vel"].angle()
	var frame_velocity: Vector2 = (sword["pos"] - sword["prev_pos"]) / maxf(delta, 0.001)
	if frame_velocity.length_squared() > 1.0:
		sword["angle"] = frame_velocity.angle()
	_update_sword_trail(delta, frame_velocity)
	_update_sword_air_wakes(delta, frame_velocity)
	_update_sword_afterimages(delta, frame_velocity)

	_damage_enemies_with_sword(delta)


func _damage_enemies_with_sword(delta: float) -> void:
	var swing_direction: Vector2 = sword["pos"] - sword["prev_pos"]
	var detection_result := {
		"contacts": [],
		"boss_contact": {},
	}
	var can_slice_hit: bool = true
	if sword["state"] == SwordState.SLICING:
		var swing_speed: float = swing_direction.length() / maxf(delta, 0.001)
		can_slice_hit = swing_speed >= SWORD_SLICE_MIN_HIT_SPEED
	if can_slice_hit:
		# Keep start-inside hits valid for large targets; attack-instance rehit gating handles repeat damage.
		detection_result = hit_detection.collect_segment_sweep_targets(
			self ,
			sword["prev_pos"],
			sword["pos"],
			float(sword.get("radius", SWORD_RADIUS)),
			str(sword.get("attack_profile_id", "")),
			DAMAGE_SOURCE_FLYING_SWORD,
			delta,
			{
				"exclude_enemy_types": [PUPPET],
			}
		)
	for contact_variant in detection_result.get("contacts", []):
		var contact: Dictionary = contact_variant
		var attack_result: Dictionary = _apply_sword_hit_to_target(
			str(contact.get("target_id", "")),
			str(contact.get("hurtbox_id", "")),
			str(contact.get("target_profile_id", "")),
			DAMAGE_SOURCE_FLYING_SWORD,
			float(contact.get("contact_time", delta)),
			str(contact.get("target_state", "")),
			bool(contact.get("is_currently_overlapping", true)),
			{
				"contact_point": contact.get("contact_point", sword["pos"]),
			}
		)
		if not bool(attack_result.get("allowed", false)):
			continue
		var enemy: Variant = contact.get("entity", null)
		if enemy == null:
			continue
		var contact_point: Vector2 = contact.get("contact_point", sword["pos"])
		var effect_color: Color = COLORS["ranged_sword"].lerp(COLORS[str(enemy.get("type", SHOOTER))], 0.24)
		_emit_sword_hit_effect(contact_point, swing_direction, effect_color)

	_update_drape_priest_threads(delta)

	if _has_boss():
		_update_silk_damage(delta)
		var boss_contact: Dictionary = detection_result.get("boss_contact", {})
		if not boss_contact.is_empty():
			var boss_hit_result: Dictionary = _apply_boss_attack_instance_hit(
				str(sword.get("attack_instance_id", "")),
				str(sword.get("attack_profile_id", "")),
				boss_contact.get("contact_point", sword["pos"]),
				DAMAGE_SOURCE_FLYING_SWORD,
				float(boss_contact.get("contact_time", delta)),
				bool(boss_contact.get("is_currently_overlapping", true))
			)
			if bool(boss_hit_result.get("allowed", false)):
				var boss_contact_point: Vector2 = boss_contact.get("contact_point", sword["pos"])
				_emit_sword_hit_effect(boss_contact_point, swing_direction, COLORS["ranged_sword"].lerp(COLORS["boss_body"], 0.28), 1.12)


func _damage_enemy(enemy: Dictionary, damage: float, damage_source: String) -> void:
	if damage <= 0.0:
		return
	if bool(enemy.get("is_dying", false)):
		return
	var resolved_damage: float = damage
	if not _has_debug_flag("one_hit_kill"):
		resolved_damage *= maxf(float(enemy.get("damage_taken_multiplier", 1.0)), 0.0)
	if resolved_damage <= 0.0 and not _has_debug_flag("one_hit_kill"):
		return
	if _has_debug_flag("one_hit_kill"):
		enemy["health"] = 0.0
	else:
		enemy["health"] = maxf(float(enemy.get("health", 0.0)) - resolved_damage, 0.0)
	enemy["last_damage_source"] = damage_source
	if enemy["health"] <= 0.0:
		_begin_enemy_death(enemy)


func _begin_enemy_death(enemy: Dictionary) -> void:
	if bool(enemy.get("is_dying", false)):
		return
	if bool(enemy.get("is_debug_static", false)) and debug_calibration_mode:
		return
	enemy["is_dying"] = true
	enemy["death_feedback_timer"] = ENEMY_DEATH_FEEDBACK_DURATION
	enemy["death_feedback_color"] = Color.WHITE
	enemy["stagger_timer"] = 0.0
	enemy["vel"] = Vector2.ZERO
	if enemy.has("melee_timer"):
		enemy["melee_timer"] = 0.0
	_clear_target_runtime_state(str(enemy.get("id", "")))
	_clear_target_hurtboxes(str(enemy.get("id", "")))
	if enemy["type"] != PUPPET:
		score += enemy["score"]
		_add_player_energy(ENERGY_GAIN_MELEE_HIT * 2.0)


func _finalize_enemy_death(enemy: Dictionary, index: int) -> void:
	var death_pos: Vector2 = enemy["pos"] + Vector2(enemy.get("hit_reaction_offset", Vector2.ZERO))
	_create_particles(death_pos, COLORS[enemy["type"]], 14)
	enemies.remove_at(index)


func _reset_enemy_runtime_modifiers() -> void:
	for enemy in enemies:
		enemy["support_source_id"] = ""
		var enemy_type: String = str(enemy.get("type", ""))
		match enemy_type:
			MIRROR_NEEDLER:
				if float(enemy.get("mirror_vulnerable_timer", 0.0)) > 0.0:
					enemy["damage_taken_multiplier"] = 1.0
				elif float(enemy.get("charge_timer", 0.0)) > 0.0:
					enemy["damage_taken_multiplier"] = MIRROR_NEEDLER_CHARGE_DAMAGE_MULTIPLIER
				else:
					enemy["damage_taken_multiplier"] = MIRROR_NEEDLER_SHELL_DAMAGE_MULTIPLIER
			_:
				enemy["damage_taken_multiplier"] = 1.0


func _clamp_enemy_to_arena(enemy: Dictionary) -> void:
	var enemy_radius: float = float(enemy.get("radius", SHOOTER_RADIUS))
	var clamp_min: Vector2 = Vector2.ONE * enemy_radius
	var clamp_max: Vector2 = ARENA_SIZE - clamp_min
	enemy["pos"] = Vector2(enemy.get("pos", Vector2.ZERO)).clamp(clamp_min, clamp_max)


func _clear_enemy_package_state(enemy: Dictionary) -> void:
	var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
	enemy["package_id"] = ""
	enemy["package_type"] = ""
	enemy["package_phase"] = ""
	enemy["package_slot_index"] = -1
	enemy["package_slot_count"] = 0
	enemy["package_desired_pos"] = enemy_pos
	enemy["package_center"] = enemy_pos
	enemy["package_radius"] = 0.0
	enemy["package_fire_enabled"] = false
	enemy["package_speed_multiplier"] = 1.0


func _collect_active_package_member_ids(package: Dictionary) -> Array:
	var active_member_ids: Array = []
	for member_id_variant in package.get("member_ids", []):
		var member_id: String = str(member_id_variant)
		if member_id == "":
			continue
		var member_variant: Variant = _find_enemy_by_id(member_id)
		if member_variant == null:
			continue
		var member: Dictionary = member_variant
		if bool(member.get("is_dying", false)):
			continue
		if float(member.get("health", 0.0)) <= 0.0:
			continue
		active_member_ids.append(member_id)
	return active_member_ids


func _release_enemy_package(package: Dictionary) -> void:
	for member_id_variant in package.get("member_ids", []):
		var member_variant: Variant = _find_enemy_by_id(str(member_id_variant))
		if member_variant == null:
			continue
		var member: Dictionary = member_variant
		_clear_enemy_package_state(member)
		if str(member.get("type", "")) == RING_LEECH:
			member["orbit_angle"] = (Vector2(member.get("pos", Vector2.ZERO)) - player["pos"]).angle()
			member["orbit_direction"] = 1.0 if randf() < 0.5 else -1.0
			member["shoot_cooldown"] = maxf(
				float(member.get("shoot_cooldown", 0.0)),
				randf_range(0.08, RING_LEECH_COOLDOWN * 0.55)
			)


func _get_ring_leech_package_slot_position(center: Vector2, rotation_angle: float, slot_count: int, slot_index: int, radius: float) -> Vector2:
	var resolved_slot_count: int = max(slot_count, 1)
	var slot_angle: float = rotation_angle + (TAU / float(resolved_slot_count)) * float(slot_index)
	var slot_pos: Vector2 = center + Vector2.RIGHT.rotated(slot_angle) * radius
	var clamp_margin: Vector2 = Vector2.ONE * RING_LEECH_RADIUS
	return slot_pos.clamp(clamp_margin, ARENA_SIZE - clamp_margin)


func _update_ring_leech_package(package: Dictionary, delta: float) -> bool:
	var active_member_ids: Array = package.get("member_ids", [])
	var member_count: int = active_member_ids.size()
	if member_count <= 0:
		return false
	var break_member_threshold: int = max(
		int(package.get("break_member_threshold", RING_LEECH_PACKAGE_BREAK_MEMBER_THRESHOLD)),
		RING_LEECH_PACKAGE_BREAK_MEMBER_THRESHOLD
	)
	if member_count < break_member_threshold:
		package["phase"] = ENEMY_PACKAGE_PHASE_BREAK
	var phase: String = str(package.get("phase", ENEMY_PACKAGE_PHASE_ASSEMBLE))
	var phase_timer: float = maxf(float(package.get("phase_timer", 0.0)) - delta, 0.0)
	if phase == ENEMY_PACKAGE_PHASE_ASSEMBLE and phase_timer <= 0.0:
		phase = ENEMY_PACKAGE_PHASE_COLLAPSE
		phase_timer = RING_LEECH_PACKAGE_COLLAPSE_DURATION
	elif phase == ENEMY_PACKAGE_PHASE_COLLAPSE and phase_timer <= 0.0:
		phase = ENEMY_PACKAGE_PHASE_ENGAGE
		phase_timer = RING_LEECH_PACKAGE_ENGAGE_DURATION
	elif phase == ENEMY_PACKAGE_PHASE_ENGAGE and phase_timer <= 0.0:
		phase = ENEMY_PACKAGE_PHASE_BREAK
	package["phase"] = phase
	package["phase_timer"] = phase_timer
	if phase == ENEMY_PACKAGE_PHASE_BREAK:
		return false

	var package_center: Vector2 = Vector2(package.get("center", player["pos"]))
	var follow_speed: float = 1.2
	match phase:
		ENEMY_PACKAGE_PHASE_COLLAPSE:
			follow_speed = 1.85
		ENEMY_PACKAGE_PHASE_ENGAGE:
			follow_speed = 2.35
	package_center = package_center.lerp(player["pos"], min(delta * follow_speed, 1.0))
	package["center"] = package_center

	var rotation_angle: float = float(package.get("rotation_angle", 0.0))
	var rotation_direction: float = float(package.get("rotation_direction", 1.0))
	var current_radius: float = RING_LEECH_PACKAGE_SPAWN_RADIUS
	var fire_enabled: bool = false
	var speed_multiplier: float = 0.9
	match phase:
		ENEMY_PACKAGE_PHASE_ASSEMBLE:
			current_radius = RING_LEECH_PACKAGE_SPAWN_RADIUS
			rotation_angle = wrapf(
				rotation_angle + rotation_direction * RING_LEECH_PACKAGE_ASSEMBLE_ROTATION_SPEED * delta,
				- PI,
				PI
			)
		ENEMY_PACKAGE_PHASE_COLLAPSE:
			var collapse_progress: float = 1.0 - clampf(
				phase_timer / maxf(RING_LEECH_PACKAGE_COLLAPSE_DURATION, 0.001),
				0.0,
				1.0
			)
			var collapse_eased: float = collapse_progress * collapse_progress * (3.0 - 2.0 * collapse_progress)
			current_radius = lerpf(RING_LEECH_PACKAGE_SPAWN_RADIUS, RING_LEECH_PACKAGE_ENGAGE_RADIUS, collapse_eased)
			rotation_angle = wrapf(
				rotation_angle + rotation_direction * RING_LEECH_PACKAGE_COLLAPSE_ROTATION_SPEED * delta,
				- PI,
				PI
			)
			fire_enabled = collapse_progress >= RING_LEECH_PACKAGE_COLLAPSE_FIRE_PROGRESS
			speed_multiplier = 1.18 + 0.14 * collapse_progress
		ENEMY_PACKAGE_PHASE_ENGAGE:
			current_radius = RING_LEECH_PACKAGE_ENGAGE_RADIUS + sin(elapsed_time * 4.0) * RING_LEECH_PACKAGE_ENGAGE_RADIUS_SWAY
			rotation_angle = wrapf(
				rotation_angle + rotation_direction * RING_LEECH_PACKAGE_ENGAGE_ROTATION_SPEED * delta,
				- PI,
				PI
			)
			fire_enabled = true
			speed_multiplier = 1.06
	package["rotation_angle"] = rotation_angle
	package["current_radius"] = current_radius

	var slot_count: int = max(int(package.get("slot_count", member_count)), 1)
	for member_id_variant in active_member_ids:
		var member_variant: Variant = _find_enemy_by_id(str(member_id_variant))
		if member_variant == null:
			continue
		var member: Dictionary = member_variant
		var slot_index: int = int(member.get("package_slot_index", -1))
		if slot_index < 0:
			slot_index = active_member_ids.find(str(member_id_variant))
			member["package_slot_index"] = slot_index
		var desired_pos: Vector2 = _get_ring_leech_package_slot_position(
			package_center,
			rotation_angle,
			slot_count,
			slot_index,
			current_radius
		)
		member["package_id"] = str(package.get("id", ""))
		member["package_type"] = ENEMY_PACKAGE_RING_LEECH_CLOSE
		member["package_phase"] = phase
		member["package_slot_count"] = slot_count
		member["package_desired_pos"] = desired_pos
		member["package_center"] = package_center
		member["package_radius"] = current_radius
		member["package_fire_enabled"] = fire_enabled
		member["package_speed_multiplier"] = speed_multiplier
		member["orbit_angle"] = (desired_pos - package_center).angle()
		member["orbit_direction"] = rotation_direction
	return true


func _update_enemy_packages(delta: float) -> void:
	if enemy_packages.is_empty():
		return
	var package_ids: Array = enemy_packages.keys()
	for package_id_variant in package_ids:
		var package_id: String = str(package_id_variant)
		var package: Dictionary = enemy_packages.get(package_id, {})
		if package.is_empty():
			enemy_packages.erase(package_id)
			continue
		package["member_ids"] = _collect_active_package_member_ids(package)
		if package["member_ids"].is_empty():
			enemy_packages.erase(package_id)
			continue
		var should_keep: bool = true
		match str(package.get("type", "")):
			ENEMY_PACKAGE_RING_LEECH_CLOSE:
				should_keep = _update_ring_leech_package(package, delta)
			_:
				should_keep = false
		if should_keep:
			enemy_packages[package_id] = package
			continue
		_release_enemy_package(package)
		enemy_packages.erase(package_id)


func _can_receive_drape_priest_support(candidate: Dictionary, priest_id: String) -> bool:
	if str(candidate.get("id", "")) == priest_id:
		return false
	if bool(candidate.get("is_dying", false)):
		return false
	if float(candidate.get("health", 0.0)) <= 0.0:
		return false
	var candidate_type: String = str(candidate.get("type", ""))
	return candidate_type != PUPPET and candidate_type != DRAPE_PRIEST


func _pick_drape_priest_target(priest: Dictionary) -> Dictionary:
	var best_target := {}
	var best_score := INF
	var priest_id: String = str(priest.get("id", ""))
	for candidate in enemies:
		if not _can_receive_drape_priest_support(candidate, priest_id):
			continue
		var score: float = Vector2(candidate.get("pos", Vector2.ZERO)).distance_to(player["pos"])
		score += Vector2(candidate.get("pos", Vector2.ZERO)).distance_to(Vector2(priest.get("pos", Vector2.ZERO))) * 0.35
		match str(candidate.get("type", "")):
			TANK:
				score -= 48.0
			HEAVY:
				score -= 26.0
			MIRROR_NEEDLER:
				score -= 12.0
		if score < best_score:
			best_score = score
			best_target = candidate
	return best_target


func _get_drape_priest_target(priest: Dictionary) -> Dictionary:
	var target_id: String = str(priest.get("support_target_id", ""))
	if target_id == "":
		return {}
	var target: Variant = _find_enemy_by_id(target_id)
	if target == null:
		priest["support_target_id"] = ""
		return {}
	var target_enemy: Dictionary = target
	if not _can_receive_drape_priest_support(target_enemy, str(priest.get("id", ""))):
		priest["support_target_id"] = ""
		return {}
	return target_enemy


func _apply_drape_priest_support(priest: Dictionary) -> Dictionary:
	if float(priest.get("support_relink_timer", 0.0)) > 0.0:
		priest["support_target_id"] = ""
		return {}
	var target: Dictionary = _get_drape_priest_target(priest)
	if not target.is_empty() and Vector2(priest.get("pos", Vector2.ZERO)).distance_to(Vector2(target.get("pos", Vector2.ZERO))) > DRAPE_PRIEST_SUPPORT_RANGE * 1.25:
		priest["support_target_id"] = ""
		target = {}
	if target.is_empty():
		target = _pick_drape_priest_target(priest)
	if target.is_empty():
		priest["support_target_id"] = ""
		return {}
	priest["support_target_id"] = str(target.get("id", ""))
	target["damage_taken_multiplier"] = minf(float(target.get("damage_taken_multiplier", 1.0)), DRAPE_PRIEST_SUPPORT_DAMAGE_MULTIPLIER)
	target["support_source_id"] = str(priest.get("id", ""))
	return target


func _sever_drape_priest_thread(priest: Dictionary, target: Dictionary, contact_point: Vector2) -> void:
	if priest.is_empty() or target.is_empty():
		return
	priest["support_target_id"] = ""
	priest["support_relink_timer"] = DRAPE_PRIEST_RELINK_COOLDOWN
	priest["stagger_timer"] = maxf(float(priest.get("stagger_timer", 0.0)), DRAPE_PRIEST_THREAD_STAGGER_DURATION)
	target["stagger_timer"] = maxf(float(target.get("stagger_timer", 0.0)), DRAPE_PRIEST_THREAD_STAGGER_DURATION)
	_emit_silk_sever_effect(Vector2(priest.get("pos", contact_point)), Vector2(target.get("pos", contact_point)), contact_point)
	_create_particles(contact_point, COLORS["silk"], 14)
	screen_shake = max(screen_shake, 4.8)
	_trigger_silk_sever_hitstop()


func _update_drape_priest_threads(_delta: float) -> void:
	var is_sword_attack_active: bool = sword["state"] == SwordState.SLICING or sword["state"] == SwordState.POINT_STRIKE
	if not is_sword_attack_active:
		return
	for enemy_variant in enemies:
		var priest: Dictionary = enemy_variant
		if str(priest.get("type", "")) != DRAPE_PRIEST:
			continue
		var target: Dictionary = _get_drape_priest_target(priest)
		if target.is_empty():
			continue
		var thread_from: Vector2 = Vector2(priest.get("pos", Vector2.ZERO))
		var thread_to: Vector2 = Vector2(target.get("pos", Vector2.ZERO))
		if GameBossController.dist_to_segment(sword["pos"], thread_from, thread_to) > float(sword.get("radius", SWORD_RADIUS)) + DRAPE_PRIEST_THREAD_CONTACT_RADIUS:
			continue
		var contact_point: Vector2 = HitDetection.closest_point_on_segment(sword["pos"], thread_from, thread_to)
		_sever_drape_priest_thread(priest, target, contact_point)
		return


func _fire_ring_leech_spread(enemy: Dictionary, aim_direction: Vector2) -> void:
	if aim_direction.is_zero_approx():
		aim_direction = Vector2.RIGHT
	for angle_offset_variant in [-RING_LEECH_SPREAD_ANGLE, -RING_LEECH_SPREAD_ANGLE * 0.45, 0.0, RING_LEECH_SPREAD_ANGLE * 0.45, RING_LEECH_SPREAD_ANGLE]:
		var angle_offset: float = float(angle_offset_variant)
		_spawn_bullet(
			enemy["pos"],
			aim_direction.rotated(angle_offset) * RING_LEECH_BULLET_SPEED,
			"small",
			str(enemy.get("id", "")),
			COLORS["bullet"],
			{
				"damage": RING_LEECH_BULLET_DAMAGE,
				"family": BULLET_FAMILY_FANG,
				"source_enemy_type": RING_LEECH,
			}
		)


func _update_ring_leech_package_member(enemy: Dictionary, to_player: Vector2, distance: float, delta: float) -> bool:
	var package_id: String = str(enemy.get("package_id", ""))
	if package_id == "" or not enemy_packages.has(package_id):
		return false
	var package_phase: String = str(enemy.get("package_phase", ""))
	if package_phase == "":
		return false
	var move_direction: Vector2 = Vector2(enemy.get("package_desired_pos", enemy.get("pos", Vector2.ZERO))) - enemy["pos"]
	if distance < PLAYER_RADIUS + float(enemy.get("radius", RING_LEECH_RADIUS)) + 12.0:
		var push_weight: float = 0.55 if package_phase == ENEMY_PACKAGE_PHASE_COLLAPSE else 0.85
		move_direction -= to_player.normalized() * push_weight
	var step_scale: float = 1.0
	match package_phase:
		ENEMY_PACKAGE_PHASE_ASSEMBLE:
			step_scale = 0.82
		ENEMY_PACKAGE_PHASE_COLLAPSE:
			step_scale = 1.2
		ENEMY_PACKAGE_PHASE_ENGAGE:
			step_scale = 1.0
	var max_step: float = RING_LEECH_SPEED * float(enemy.get("package_speed_multiplier", 1.0)) * step_scale * delta
	if not move_direction.is_zero_approx():
		var catchup_scale: float = clampf(move_direction.length() / maxf(float(enemy.get("package_radius", 1.0)), 1.0), 0.72, 1.35)
		enemy["pos"] += move_direction.limit_length(max_step * catchup_scale)
	_clamp_enemy_to_arena(enemy)
	enemy["shoot_cooldown"] -= delta
	if not bool(enemy.get("package_fire_enabled", false)):
		return true
	var fire_distance: float = maxf(RING_LEECH_FIRE_DISTANCE, float(enemy.get("package_radius", RING_LEECH_ORBIT_DISTANCE)) + 20.0)
	if enemy["shoot_cooldown"] > 0.0 or distance > fire_distance:
		return true
	enemy["shoot_cooldown"] = RING_LEECH_COOLDOWN
	_fire_ring_leech_spread(enemy, to_player.normalized())
	return true


func _update_ring_leech_enemy(enemy: Dictionary, to_player: Vector2, distance: float, delta: float) -> void:
	if _update_ring_leech_package_member(enemy, to_player, distance, delta):
		return
	var move_direction: Vector2 = Vector2.ZERO
	if distance > RING_LEECH_ORBIT_DISTANCE + 24.0:
		move_direction = to_player.normalized()
		enemy["orbit_angle"] = (enemy["pos"] - player["pos"]).angle()
	else:
		var orbit_angle: float = float(enemy.get("orbit_angle", (enemy["pos"] - player["pos"]).angle()))
		var orbit_direction: float = float(enemy.get("orbit_direction", 1.0))
		orbit_angle = wrapf(orbit_angle + orbit_direction * RING_LEECH_ORBIT_ANGULAR_SPEED * delta, -PI, PI)
		enemy["orbit_angle"] = orbit_angle
		var desired_pos: Vector2 = player["pos"] + Vector2.RIGHT.rotated(orbit_angle) * RING_LEECH_ORBIT_DISTANCE
		move_direction = desired_pos - enemy["pos"]
	if distance < PLAYER_RADIUS + float(enemy.get("radius", RING_LEECH_RADIUS)) + 10.0:
		move_direction -= to_player.normalized() * 0.75
	if not move_direction.is_zero_approx():
		enemy["pos"] += move_direction.normalized() * RING_LEECH_SPEED * delta
	_clamp_enemy_to_arena(enemy)
	enemy["shoot_cooldown"] -= delta
	if enemy["shoot_cooldown"] > 0.0 or distance > RING_LEECH_FIRE_DISTANCE:
		return
	enemy["shoot_cooldown"] = RING_LEECH_COOLDOWN
	_fire_ring_leech_spread(enemy, to_player.normalized())


func _update_drape_priest_enemy(enemy: Dictionary, to_player: Vector2, distance: float, delta: float) -> void:
	enemy["support_relink_timer"] = maxf(float(enemy.get("support_relink_timer", 0.0)) - delta, 0.0)
	var target: Dictionary = _apply_drape_priest_support(enemy)
	var move_direction: Vector2 = Vector2.ZERO
	if distance < DRAPE_PRIEST_RETREAT_DISTANCE:
		move_direction -= to_player.normalized()
	elif distance > DRAPE_PRIEST_APPROACH_DISTANCE:
		move_direction += to_player.normalized()
	if not target.is_empty():
		var to_target: Vector2 = Vector2(target.get("pos", enemy["pos"])) - enemy["pos"]
		var target_distance: float = to_target.length()
		if target_distance > DRAPE_PRIEST_SUPPORT_RANGE * 0.92:
			move_direction += to_target.normalized() * 0.85
		elif target_distance < DRAPE_PRIEST_SUPPORT_RANGE * 0.55:
			move_direction -= to_target.normalized() * 0.3
	if not move_direction.is_zero_approx():
		enemy["pos"] += move_direction.normalized() * DRAPE_PRIEST_SPEED * delta
	_clamp_enemy_to_arena(enemy)
	enemy["shoot_cooldown"] -= delta
	if enemy["shoot_cooldown"] > 0.0 or distance > DRAPE_PRIEST_APPROACH_DISTANCE + 24.0:
		return
	enemy["shoot_cooldown"] = DRAPE_PRIEST_BOLT_COOLDOWN
	var bolt_direction: Vector2 = to_player.normalized()
	if bolt_direction.is_zero_approx():
		bolt_direction = Vector2.RIGHT
	_spawn_bullet(
		enemy["pos"],
		bolt_direction * DRAPE_PRIEST_BOLT_SPEED,
		"small",
		str(enemy.get("id", "")),
		COLORS["bullet"],
		{
			"damage": DRAPE_PRIEST_BOLT_DAMAGE,
			"family": BULLET_FAMILY_NEEDLE,
			"source_enemy_type": DRAPE_PRIEST,
		}
	)


func _break_mirror_needler_shell(enemy: Dictionary) -> void:
	var was_protected: bool = float(enemy.get("mirror_vulnerable_timer", 0.0)) <= 0.0
	enemy["mirror_vulnerable_timer"] = maxf(float(enemy.get("mirror_vulnerable_timer", 0.0)), MIRROR_NEEDLER_VULNERABLE_DURATION)
	enemy["damage_taken_multiplier"] = 1.0
	enemy["charge_timer"] = 0.0
	enemy["shoot_cooldown"] = maxf(float(enemy.get("shoot_cooldown", 0.0)), MIRROR_NEEDLER_BREAK_RECOVERY)
	enemy["stagger_timer"] = maxf(float(enemy.get("stagger_timer", 0.0)), MIRROR_NEEDLER_BREAK_STAGGER_DURATION)
	if was_protected:
		screen_shake = max(screen_shake, 4.5)
		_create_particles(enemy["pos"], COLORS["melee_sword"], 10)


func _update_mirror_needler_enemy(enemy: Dictionary, to_player: Vector2, distance: float, delta: float) -> void:
	var charge_timer: float = float(enemy.get("charge_timer", 0.0))
	if charge_timer > 0.0:
		charge_timer = maxf(charge_timer - delta, 0.0)
		enemy["charge_timer"] = charge_timer
		if charge_timer <= 0.0:
			var shot_direction: Vector2 = to_player.normalized()
			if shot_direction.is_zero_approx():
				shot_direction = Vector2.RIGHT
			_spawn_bullet(
				enemy["pos"],
				shot_direction * MIRROR_NEEDLER_BULLET_SPEED,
				"large",
				str(enemy.get("id", "")),
				COLORS["bullet"],
				{
					"damage": MIRROR_NEEDLER_BULLET_DAMAGE,
					"family": BULLET_FAMILY_CORE,
					"radius": MIRROR_NEEDLER_BULLET_RADIUS,
					"source_owner_id": str(enemy.get("id", "")),
					"source_enemy_type": MIRROR_NEEDLER,
				}
			)
			enemy["mirror_vulnerable_timer"] = maxf(float(enemy.get("mirror_vulnerable_timer", 0.0)), MIRROR_NEEDLER_AFTER_FIRE_VULNERABLE_DURATION)
			enemy["shoot_cooldown"] = MIRROR_NEEDLER_COOLDOWN
		return
	enemy["shoot_cooldown"] -= delta
	if float(enemy.get("mirror_vulnerable_timer", 0.0)) <= 0.0 and enemy["shoot_cooldown"] <= 0.0:
		enemy["charge_timer"] = MIRROR_NEEDLER_CHARGE_DURATION
		return
	enemy["move_timer"] -= delta
	if enemy["move_timer"] <= 0.0:
		enemy["move_timer"] = randf_range(0.8, 1.4)
		var current_strafe: float = float(enemy.get("strafe_dir", 1.0))
		enemy["strafe_dir"] = - current_strafe if randf() < 0.72 else (1.0 if randf() < 0.5 else -1.0)
	var move_direction: Vector2 = to_player.orthogonal().normalized() * float(enemy.get("strafe_dir", 1.0))
	if distance > MIRROR_NEEDLER_MAX_DISTANCE:
		move_direction += to_player.normalized() * 0.85
	elif distance < MIRROR_NEEDLER_MIN_DISTANCE:
		move_direction -= to_player.normalized() * 1.1
	if not move_direction.is_zero_approx():
		enemy["pos"] += move_direction.normalized() * MIRROR_NEEDLER_SPEED * delta
	_clamp_enemy_to_arena(enemy)


func _update_enemy_visual_feedback(enemy: Dictionary, delta: float) -> void:
	enemy["hit_flash_timer"] = maxf(float(enemy.get("hit_flash_timer", 0.0)) - delta, 0.0)
	enemy["hit_reaction_timer"] = maxf(float(enemy.get("hit_reaction_timer", 0.0)) - delta, 0.0)
	enemy["hit_reaction_offset"] = _resolve_hit_reaction_offset(
		Vector2(enemy.get("hit_reaction_vector", Vector2.ZERO)),
		float(enemy.get("hit_reaction_timer", 0.0)),
		ENEMY_HIT_REACTION_DURATION,
		ENEMY_HIT_REACTION_SHAKE_CYCLES
	)
	if float(enemy.get("hit_reaction_timer", 0.0)) <= 0.0:
		enemy["hit_reaction_vector"] = Vector2.ZERO
	if bool(enemy.get("is_dying", false)):
		enemy["death_feedback_timer"] = maxf(float(enemy.get("death_feedback_timer", 0.0)) - delta, 0.0)


func _update_enemies(delta: float) -> void:
	_reset_enemy_runtime_modifiers()
	_update_enemy_packages(delta)
	var index: int = enemies.size() - 1
	while index >= 0:
		var enemy: Dictionary = enemies[index]
		if enemy.get("is_debug_static", false):
			if enemy["health"] <= 0.0 and debug_calibration_mode:
				enemy["health"] = enemy["max_health"]
				enemy["is_dying"] = false
				enemy["death_feedback_timer"] = 0.0
				enemy["hit_flash_timer"] = 0.0
				enemy["hit_reaction_timer"] = 0.0
				enemy["hit_reaction_offset"] = Vector2.ZERO
				enemy["hit_reaction_vector"] = Vector2.ZERO
				enemy["death_feedback_color"] = Color.WHITE
			index -= 1
			continue
		if bool(enemy.get("is_dying", false)):
			_update_enemy_visual_feedback(enemy, delta)
			if float(enemy.get("death_feedback_timer", 0.0)) <= 0.0:
				_finalize_enemy_death(enemy, index)
			index -= 1
			continue
		if enemy["health"] <= 0.0:
			_begin_enemy_death(enemy)
			index -= 1
			continue
		if enemy.has("mirror_vulnerable_timer"):
			enemy["mirror_vulnerable_timer"] = maxf(float(enemy.get("mirror_vulnerable_timer", 0.0)) - delta, 0.0)
		enemy["stagger_timer"] = maxf(float(enemy.get("stagger_timer", 0.0)) - delta, 0.0)
		_update_enemy_visual_feedback(enemy, delta)
		if float(enemy.get("stagger_timer", 0.0)) > 0.0:
			enemy["vel"] = Vector2.ZERO
			index -= 1
			continue
		var to_player: Vector2 = player["pos"] - enemy["pos"]
		var distance: float = max(to_player.length(), 0.001)
		match enemy["type"]:
			SHOOTER:
				if distance > 200.0:
					enemy["pos"] += to_player.normalized() * SHOOTER_SPEED * delta
				elif distance < 150.0:
					enemy["pos"] -= to_player.normalized() * SHOOTER_SPEED * delta
				enemy["shoot_cooldown"] -= delta
				if enemy["shoot_cooldown"] <= 0.0:
					enemy["shoot_cooldown"] = SHOOTER_COOLDOWN
					_spawn_bullet(
						enemy["pos"],
						to_player.normalized() * BULLET_SPEED,
						"small",
						enemy["id"],
						COLORS["bullet"],
						{
							"family": BULLET_FAMILY_NEEDLE,
							"source_enemy_type": SHOOTER,
						}
					)
			TANK:
				enemy["pos"] += to_player.normalized() * TANK_SPEED * delta
				if distance < enemy["radius"] + PLAYER_RADIUS:
					if _apply_player_damage(30.0 * delta, TANK):
						screen_shake = max(screen_shake, 2.0)
			CASTER:
				enemy["move_timer"] -= delta
				if enemy["move_timer"] <= 0.0:
					enemy["move_timer"] = randf_range(1.0, 2.0)
					enemy["vel"] = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * CASTER_SPEED
				enemy["pos"] += enemy["vel"] * delta
				enemy["pos"] = enemy["pos"].clamp(Vector2(enemy["radius"], enemy["radius"]), ARENA_SIZE - Vector2(enemy["radius"], enemy["radius"]))
				enemy["shoot_cooldown"] -= delta
				if enemy["shoot_cooldown"] <= 0.0:
					enemy["shoot_cooldown"] = CASTER_COOLDOWN
					var spoke: int = 0
					while spoke < 8:
						var angle: float = (TAU / 8.0) * float(spoke)
						_spawn_bullet(
							enemy["pos"],
							Vector2.RIGHT.rotated(angle) * BULLET_SPEED * 0.7,
							"small",
							enemy["id"],
							COLORS["bullet"],
							{
								"family": BULLET_FAMILY_WEAVE,
								"source_enemy_type": CASTER,
							}
						)
						spoke += 1
			HEAVY:
				enemy["pos"] += to_player.normalized() * HEAVY_SPEED * delta
				enemy["shoot_cooldown"] -= delta
				if enemy["shoot_cooldown"] <= 0.0:
					enemy["shoot_cooldown"] = HEAVY_COOLDOWN
					_spawn_bullet(
						enemy["pos"],
						to_player.normalized() * BULLET_LARGE_SPEED,
						"large",
						enemy["id"],
						COLORS["bullet"],
						{
							"family": BULLET_FAMILY_CORE,
							"source_enemy_type": HEAVY,
						}
					)
			RING_LEECH:
				_update_ring_leech_enemy(enemy, to_player, distance, delta)
			DRAPE_PRIEST:
				_update_drape_priest_enemy(enemy, to_player, distance, delta)
			MIRROR_NEEDLER:
				_update_mirror_needler_enemy(enemy, to_player, distance, delta)
			PUPPET:
				if not _has_boss() or not _is_silk_active(enemy["id"]):
					enemy["last_damage_source"] = DAMAGE_SOURCE_SYSTEM
					enemy["health"] = 0.0
				elif enemy["melee_timer"] <= 0.0:
					if distance > PUPPET_MELEE_RANGE * 0.8:
						enemy["pos"] += to_player.normalized() * PUPPET_SPEED * delta
					if distance < PUPPET_MELEE_RANGE:
						enemy["melee_timer"] = PUPPET_MELEE_COOLDOWN
				else:
					var previous_timer: float = enemy["melee_timer"]
					enemy["melee_timer"] -= delta
					var attack_progress: float = PUPPET_MELEE_COOLDOWN - enemy["melee_timer"]
					var previous_progress: float = PUPPET_MELEE_COOLDOWN - previous_timer
					if previous_progress < PUPPET_MELEE_PREP_TIME and attack_progress >= PUPPET_MELEE_PREP_TIME:
						if distance < PUPPET_MELEE_RANGE + 10.0:
							if _apply_player_damage(PUPPET_MELEE_DAMAGE, PUPPET):
								screen_shake = max(screen_shake, 5.0)
								_create_particles(player["pos"], COLORS["puppet"], 10)

		if enemy["health"] <= 0.0:
			_begin_enemy_death(enemy)
		index -= 1


func _update_bullets(delta: float, bullet_time_delta: float) -> void:
	var index: int = bullets.size() - 1
	while index >= 0:
		var bullet: Dictionary = bullets[index]
		match bullet["state"]:
			"deflected":
				bullet["pos"] += bullet["vel"] * delta
				if _deflected_bullet_hits_enemy(bullet):
					_remove_bullet(index)
					index -= 1
					continue
				if not _is_inside_extended_bounds(bullet["pos"]):
					_remove_bullet(index)
					index -= 1
					continue
			_:
				bullet["pos"] += bullet["vel"] * bullet_time_delta
				if not _is_inside_extended_bounds(bullet["pos"]):
					_remove_bullet(index)
					index -= 1
					continue
				if _ring_guard_clears_bullet(bullet):
					_create_particles(bullet["pos"], COLORS["array_sword"], 4)
					screen_shake = max(screen_shake, 1.6)
					_remove_bullet(index)
					index -= 1
					continue
				if _player_hit_by_bullet(bullet):
					_remove_bullet(index)
					index -= 1
					continue
		index -= 1


func _update_array_swords(delta: float) -> void:
	var sword_index: int = array_swords.size() - 1
	while sword_index >= 0:
		var array_sword: Dictionary = array_swords[sword_index]
		match String(array_sword.get("state", "")):
			"outbound":
				var travel_mode: String = String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
				var uses_fan_batch_return: bool = _uses_fan_batch_return(array_sword)
				var batch_return_ready: bool = bool(array_sword.get("batch_return_ready", false))
				if not batch_return_ready:
					_update_guided_array_sword(array_sword, delta)
					array_sword["pos"] += array_sword["vel"] * delta
					array_sword["guidance_distance"] = float(array_sword.get("guidance_distance", 0.0)) + array_sword["vel"].length() * delta
					_emit_array_sword_trail(array_sword, delta, false)
				_decay_array_sword_target_cooldowns(array_sword, delta)
				if not batch_return_ready:
					_clear_bullets_near_ring_guard_sword(array_sword, travel_mode)
				if not batch_return_ready and not bool(array_sword.get("has_hit_target", false)):
					var hit_result: Dictionary = _array_sword_hits_enemy(array_sword)
					if bool(hit_result.get("hit", false)):
						array_sword["guidance_active"] = false
						array_sword["return_unlock_distance"] = maxf(
							float(array_sword.get("return_unlock_distance", _get_array_sword_min_sortie_distance(travel_mode))),
							float(array_sword.get("guidance_distance", 0.0)) + _get_array_sword_hit_follow_through_distance(travel_mode)
						)
						if bool(hit_result.get("should_return", false)):
							array_sword["has_hit_target"] = true
				var can_return: bool = float(array_sword.get("guidance_distance", 0.0)) >= float(array_sword.get("return_unlock_distance", _get_array_sword_min_sortie_distance(travel_mode)))
				var reached_max_distance: bool = float(array_sword.get("guidance_distance", 0.0)) >= _get_array_sword_max_travel_distance(travel_mode)
				var left_bounds: bool = can_return and not _is_inside_extended_bounds(array_sword["pos"])
				if uses_fan_batch_return:
					if not batch_return_ready and (
						(bool(array_sword.get("has_hit_target", false)) and can_return)
						or reached_max_distance
						or left_bounds
					):
						_mark_fan_batch_member_ready(array_sword)
						batch_return_ready = true
					if _is_fan_batch_ready_to_return(String(array_sword.get("batch_id", ""))):
						_begin_fan_batch_return(String(array_sword.get("batch_id", "")))
				else:
					if bool(array_sword.get("has_hit_target", false)) and can_return:
						_begin_array_sword_return(array_sword)
					elif reached_max_distance:
						_begin_array_sword_return(array_sword)
					elif left_bounds:
						_begin_array_sword_return(array_sword)
			"returning":
				var return_target: Vector2 = player["pos"] if bool(array_sword.get("pending_remove", false)) else _get_array_sword_slot_position(int(array_sword.get("slot_index", 0)), 1.0)
				var to_player: Vector2 = return_target - array_sword["pos"]
				if to_player.length() <= ARRAY_SWORD_RETURN_CATCH_RADIUS:
					if bool(array_sword.get("pending_remove", false)):
						array_swords.remove_at(sword_index)
						sword_index -= 1
						continue
					array_sword["state"] = "ready"
					array_sword["pos"] = return_target
					array_sword["vel"] = Vector2.ZERO
					_reset_array_sword_sortie_state(array_sword)
					_create_particles(return_target, COLORS["array_sword_return"], 4)
				else:
					var travel_mode: String = String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
					var desired_return_direction: Vector2 = to_player.normalized()
					var return_swirl_strength: float = _get_array_sword_return_swirl_strength(travel_mode)
					if return_swirl_strength > 0.0:
						var swirl_window: float = maxf(_get_array_sword_min_sortie_distance(travel_mode), ARRAY_SWORD_RETURN_CATCH_RADIUS + 1.0)
						var swirl_fade: float = clampf(to_player.length() / swirl_window, 0.0, 1.0)
						swirl_fade *= swirl_fade
						desired_return_direction = _blend_array_sword_direction_with_tangent(
							desired_return_direction,
							_get_array_sword_return_tangent_direction(array_sword, to_player),
							return_swirl_strength * _get_array_sword_flow_slot_weight(array_sword, travel_mode) * swirl_fade
						)
					var desired_return_velocity: Vector2 = desired_return_direction * _get_current_array_sword_return_speed(travel_mode)
					var return_turn_alpha: float = min(delta * _get_array_sword_return_turn_rate(travel_mode), 1.0)
					array_sword["vel"] = desired_return_velocity if array_sword["vel"].is_zero_approx() else array_sword["vel"].lerp(desired_return_velocity, return_turn_alpha)
					array_sword["pos"] += array_sword["vel"] * delta
					_emit_array_sword_trail(array_sword, delta, true)
		sword_index -= 1
	_layout_ready_array_swords(delta)
	_clear_bullets_near_ready_ring_guard_swords()


func _array_sword_hits_enemy(array_sword: Dictionary) -> Dictionary:
	var travel_mode: String = String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
	var hit_radius_bonus: float = _get_array_sword_hit_radius_bonus(travel_mode)
	var hit_result := {
		"hit": false,
		"should_return": false,
	}
	var detection_result: Dictionary = hit_detection.collect_circle_contact_targets(
		self ,
		array_sword["pos"],
		float(array_sword.get("radius", ARRAY_SWORD_RADIUS)),
		str(array_sword.get("attack_profile_id", "")),
		DAMAGE_SOURCE_ARRAY_SWORD,
		0.0,
		{
			"exclude_enemy_types": [PUPPET],
			"contact_radius_bonus": hit_radius_bonus,
		}
	)
	for contact_variant in detection_result.get("contacts", []):
		var contact: Dictionary = contact_variant
		var target_id: String = str(contact.get("target_id", ""))
		if not _can_array_sword_hit_target(array_sword, target_id):
			continue
		var attack_result: Dictionary = _apply_array_sword_hit_to_target(
			array_sword,
			target_id,
			str(contact.get("hurtbox_id", "")),
			str(contact.get("target_profile_id", "")),
			DAMAGE_SOURCE_ARRAY_SWORD,
			str(contact.get("target_state", "")),
			bool(contact.get("is_currently_overlapping", true))
		)
		if not bool(attack_result.get("allowed", false)):
			continue
		hit_result["hit"] = true
		hit_result["should_return"] = _register_array_sword_target_hit(array_sword, target_id, travel_mode)
		_create_particles(array_sword["pos"], COLORS["array_sword"], 10)
		return hit_result
	if _has_boss():
		var boss_contact: Dictionary = detection_result.get("boss_contact", {})
		if not boss_contact.is_empty() and _can_array_sword_hit_target(array_sword, "boss"):
			var boss_hit_result: Dictionary = _apply_boss_attack_instance_hit(
				str(array_sword.get("attack_instance_id", "")),
				str(array_sword.get("attack_profile_id", "")),
				boss_contact.get("contact_point", array_sword["pos"]),
				DAMAGE_SOURCE_ARRAY_SWORD,
				float(boss_contact.get("contact_time", 0.0)),
				bool(boss_contact.get("is_currently_overlapping", true))
			)
			if not bool(boss_hit_result.get("allowed", false)):
				return hit_result
			hit_result["hit"] = true
			hit_result["should_return"] = _register_array_sword_target_hit(array_sword, "boss", travel_mode)
			_create_particles(array_sword["pos"], COLORS["array_sword"], 15)
			return hit_result
	return hit_result


func _clear_bullets_near_ring_guard_sword(array_sword: Dictionary, travel_mode: String) -> void:
	if not _is_ring_guard_active() or travel_mode != SwordArrayConfig.MODE_RING:
		return
	var bullet_index: int = bullets.size() - 1
	var cleared_count: int = 0
	while bullet_index >= 0:
		var bullet: Dictionary = bullets[bullet_index]
		if String(bullet.get("state", "")) != "normal":
			bullet_index -= 1
			continue
		if bullet["pos"].distance_to(array_sword["pos"]) > bullet["radius"] + array_sword["radius"] + RING_GUARD_BULLET_CLEAR_RADIUS:
			bullet_index -= 1
			continue
		_create_particles(bullet["pos"], COLORS["array_sword"], 4)
		_remove_bullet(bullet_index)
		cleared_count += 1
		bullet_index -= 1
	if cleared_count > 0:
		screen_shake = max(screen_shake, 1.8)


func _clear_bullets_near_ready_ring_guard_swords() -> void:
	if not _is_ring_guard_active():
		return
	for array_sword in array_swords:
		if String(array_sword.get("state", "")) != "ready":
			continue
		_clear_bullets_near_ring_guard_sword(array_sword, SwordArrayConfig.MODE_RING)


func _ring_guard_clears_bullet(bullet: Dictionary) -> bool:
	if not _is_ring_guard_active():
		return false
	if String(bullet.get("state", "")) != "normal":
		return false
	if player["pos"].distance_to(bullet["pos"]) <= RING_GUARD_PLAYER_CLEAR_RADIUS + float(bullet.get("radius", BULLET_RADIUS)):
		return true
	for array_sword in array_swords:
		if String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING)) != SwordArrayConfig.MODE_RING:
			continue
		if String(array_sword.get("state", "")) == "":
			continue
		if bullet["pos"].distance_to(array_sword["pos"]) <= float(bullet.get("radius", BULLET_RADIUS)) + float(array_sword.get("radius", ARRAY_SWORD_RADIUS)) + RING_GUARD_BULLET_CLEAR_RADIUS:
			return true
	return false


func _is_ring_guard_active() -> bool:
	return bool(player.get("array_is_firing", false)) and _get_array_batch_mode() == SwordArrayConfig.MODE_RING


func _begin_array_sword_return(array_sword: Dictionary) -> void:
	_clear_array_sword_attack_instance(array_sword)
	array_sword["state"] = "returning"
	array_sword["guidance_active"] = false
	array_sword["trail_timer"] = 0.0


func _update_guided_array_sword(array_sword: Dictionary, delta: float) -> void:
	if not array_sword.get("guidance_active", false):
		return
	var travel_mode: String = String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
	array_sword["guidance_elapsed"] = float(array_sword.get("guidance_elapsed", 0.0)) + delta
	var should_keep_guiding: bool = bool(player.get("array_is_firing", false))
	should_keep_guiding = should_keep_guiding and float(array_sword.get("guidance_elapsed", 0.0)) <= SwordArrayConfig.FIRED_GUIDANCE_DURATION
	should_keep_guiding = should_keep_guiding and float(array_sword.get("guidance_distance", 0.0)) <= _get_array_sword_guidance_max_distance(travel_mode)
	if not should_keep_guiding:
		array_sword["guidance_active"] = false
		return
	var target_point: Vector2 = SwordArrayController.get_fire_target(
		self ,
		_get_sword_array_fire_state(),
		int(array_sword.get("guidance_fire_index", 0)),
		array_sword["pos"],
		int(array_sword.get("guidance_volley_count", -1)),
		int(array_sword.get("guidance_burst_step", 0)),
		int(array_sword.get("guidance_total_count", -1))
	)
	var desired_direction: Vector2 = target_point - array_sword["pos"]
	if desired_direction.is_zero_approx():
		desired_direction = array_sword["vel"]
	if desired_direction.is_zero_approx():
		desired_direction = mouse_world - player["pos"]
	if desired_direction.is_zero_approx():
		desired_direction = Vector2.RIGHT
	var desired_forward: Vector2 = desired_direction.normalized()
	var guidance_tangent_bias: float = _get_array_sword_guidance_tangent_bias(travel_mode)
	if guidance_tangent_bias > 0.0:
		var guidance_progress: float = clampf(float(array_sword.get("guidance_elapsed", 0.0)) / maxf(SwordArrayConfig.FIRED_GUIDANCE_DURATION, 0.001), 0.0, 1.0)
		var tangent_fade: float = 1.0 - guidance_progress
		tangent_fade *= tangent_fade
		desired_forward = _blend_array_sword_direction_with_tangent(
			desired_forward,
			_get_array_sword_launch_tangent_direction(
				travel_mode,
				array_sword["pos"],
				desired_forward,
				float(array_sword.get("flow_side", 1.0))
			),
			guidance_tangent_bias * _get_array_sword_flow_slot_weight(array_sword, travel_mode) * tangent_fade
		)
	var current_forward: Vector2 = array_sword["vel"].normalized()
	if not current_forward.is_zero_approx():
		var forward_component: float = desired_forward.dot(current_forward)
		var min_forward_component: float = 0.18
		if forward_component < min_forward_component:
			var lateral_component: Vector2 = desired_forward - current_forward * forward_component
			var adjusted_forward: Vector2 = lateral_component + current_forward * min_forward_component
			desired_forward = adjusted_forward.normalized() if not adjusted_forward.is_zero_approx() else current_forward
	var desired_velocity: Vector2 = desired_forward * _get_current_array_sword_speed(String(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING)))
	array_sword["vel"] = array_sword["vel"].lerp(desired_velocity, min(delta * SwordArrayConfig.FIRED_GUIDANCE_TURN_RATE, 1.0))


func _emit_array_sword_trail(array_sword: Dictionary, delta: float, is_returning: bool) -> void:
	var trail_timer: float = float(array_sword.get("trail_timer", 0.0)) - delta
	if trail_timer > 0.0:
		array_sword["trail_timer"] = trail_timer
		return
	array_sword["trail_timer"] = 0.032 if bool(player.get("array_is_firing", false)) else 0.055
	var trail_color: Color = COLORS["array_sword_return"] if is_returning else COLORS["array_sword"]
	_create_particles(array_sword["pos"], trail_color, 1)


func _deflected_bullet_hits_enemy(bullet: Dictionary) -> bool:
	var attack_instance_id: String = str(bullet.get("attack_instance_id", ""))
	var attack_profile_id: String = str(bullet.get("attack_profile_id", AttackProfiles.PROFILE_DEFLECTED_BULLET))
	var channel_scalar: float = maxf(float(bullet.get("channel_scalar", float(bullet.get("damage", BULLET_DAMAGE)) / maxf(BULLET_DAMAGE, 0.001))), 0.0)
	var detection_result: Dictionary = hit_detection.collect_circle_contact_targets(
		self ,
		bullet["pos"],
		float(bullet.get("radius", BULLET_RADIUS)),
		attack_profile_id,
		DAMAGE_SOURCE_MELEE,
		0.0,
		{
			"exclude_enemy_types": [PUPPET],
		}
	)
	for contact_variant in detection_result.get("contacts", []):
		var contact: Dictionary = contact_variant
		var enemy_entity: Variant = contact.get("entity", null)
		if enemy_entity != null and str(enemy_entity.get("type", "")) == MIRROR_NEEDLER:
			if str(bullet.get("source_enemy_type", "")) == MIRROR_NEEDLER and str(bullet.get("source_owner_id", "")) == str(contact.get("target_id", "")):
				_break_mirror_needler_shell(enemy_entity)
		var attack_result: Dictionary = _apply_attack_instance_hit_to_target(
			attack_instance_id,
			attack_profile_id,
			contact.get("contact_point", bullet["pos"]),
			str(contact.get("target_id", "")),
			str(contact.get("hurtbox_id", "")),
			str(contact.get("target_profile_id", "")),
			DAMAGE_SOURCE_MELEE,
			float(contact.get("contact_time", 0.0)),
			str(contact.get("target_state", "")),
			bool(contact.get("is_currently_overlapping", true)),
			{
				"channel_scalar": channel_scalar,
			}
		)
		if not bool(attack_result.get("allowed", false)):
			continue
		_create_particles(bullet["pos"], COLORS["melee_sword"], 8)
		return true
	if _has_boss():
		var boss_contact: Dictionary = detection_result.get("boss_contact", {})
		if not boss_contact.is_empty():
			var boss_hit_result: Dictionary = _apply_boss_attack_instance_hit(
				attack_instance_id,
				attack_profile_id,
				boss_contact.get("contact_point", bullet["pos"]),
				DAMAGE_SOURCE_MELEE,
				float(boss_contact.get("contact_time", 0.0)),
				bool(boss_contact.get("is_currently_overlapping", true)),
				{
					"channel_scalar": channel_scalar,
				}
			)
			if not bool(boss_hit_result.get("allowed", false)):
				return false
			_create_particles(bullet["pos"], COLORS["melee_sword"], 10)
			return true
	return false


func _player_hit_by_bullet(bullet: Dictionary) -> bool:
	if String(bullet.get("state", "")) == "deflected":
		return false
	if player["pos"].distance_to(bullet["pos"]) > PLAYER_RADIUS + bullet["radius"]:
		return false
	if _apply_player_damage(bullet["damage"], str(bullet.get("owner_id", DAMAGE_SOURCE_NONE))):
		screen_shake = max(screen_shake, 5.0)
		_create_particles(bullet["pos"], bullet["color"], 6)
	return true


func _update_particles(delta: float) -> void:
	var index: int = particles.size() - 1
	while index >= 0:
		var particle: Dictionary = particles[index]
		particle["pos"] += particle["vel"] * delta
		particle["life"] -= delta
		if particle["life"] <= 0.0:
			particles.remove_at(index)
		index -= 1


func _update_wave(delta: float) -> void:
	if debug_calibration_mode:
		return
	if _has_boss() and boss["health"] <= 0.0:
		_create_particles(boss["pos"], COLORS["boss_body"], 40)
		_clear_target_runtime_state("boss")
		_clear_target_hurtboxes("boss")
		boss.clear()
		score += 5000
		enemies_to_spawn = WAVE_BASE_ENEMIES + wave * 2
		_prepare_wave_spawn_queue()
		spawn_timer = 0.5
		return

	if enemies_to_spawn <= 0 and enemies.is_empty():
		wave += 1
		if wave % BOSS_WAVE_INTERVAL == 0:
			wave_spawn_queue.clear()
			_spawn_boss()
			spawn_timer = 0.6
			return
		enemies_to_spawn = WAVE_BASE_ENEMIES + wave * 2
		_prepare_wave_spawn_queue()
		spawn_timer = 0.6

	if enemies_to_spawn <= 0 or _has_boss():
		return
	if _has_debug_flag("no_spawn"):
		return
	if wave_spawn_queue.is_empty():
		_prepare_wave_spawn_queue()

	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	var next_spawn_entry: Variant = wave_spawn_queue.pop_front() if not wave_spawn_queue.is_empty() else _roll_spawn_entry(enemies_to_spawn)
	var spawned_enemy_count: int = max(_spawn_wave_entry(next_spawn_entry), 1)
	spawn_timer = SPAWN_INTERVAL * (1.0 + 0.12 * float(spawned_enemy_count - 1))
	enemies_to_spawn = max(enemies_to_spawn - spawned_enemy_count, 0)


func _perform_melee_attack() -> void:
	player["attack_cooldown"] = SWORD_MELEE_COOLDOWN
	player["attack_flash_timer"] = MELEE_ATTACK_FLASH_DURATION
	var attack_direction: Vector2 = mouse_world - player["pos"]
	if attack_direction.is_zero_approx():
		attack_direction = Vector2.RIGHT
	var melee_attack_instance: Dictionary = _build_attack_instance(AttackProfiles.PROFILE_MELEE_SLASH, "player", "melee")
	var melee_attack_instance_id: String = str(melee_attack_instance.get("id", ""))
	var melee_attack_profile_id: String = str(melee_attack_instance.get("profile_id", AttackProfiles.PROFILE_MELEE_SLASH))
	var detection_result: Dictionary = hit_detection.collect_melee_arc_targets(
		self ,
		player["pos"],
		attack_direction,
		SWORD_MELEE_RANGE,
		SWORD_MELEE_ARC,
		melee_attack_profile_id,
		DAMAGE_SOURCE_MELEE,
		{
			"exclude_enemy_types": [PUPPET],
			"bullet_range_bonus": 20.0,
		}
	)

	for bullet_contact_variant in detection_result.get("bullet_contacts", []):
		var bullet_contact: Dictionary = bullet_contact_variant
		var bullet: Variant = bullet_contact.get("bullet", null)
		if bullet == null:
			continue
		var bullet_color: Color = bullet.get("color", COLORS["bullet"])
		_deflect_enemy_bullet(bullet, attack_direction)
		_emit_sword_hit_effect(
			bullet_contact.get("contact_point", bullet["pos"]),
			attack_direction,
			COLORS["melee_sword"].lerp(bullet_color, 0.18),
			1.0,
			"deflect",
			{
				"spark_count": 4,
			}
		)
		_add_player_energy(ENERGY_GAIN_MELEE_DEFLECT * (1.5 if bullet["type"] == "large" else 1.0))
		screen_shake = max(screen_shake, 3.0)

	for contact_variant in detection_result.get("contacts", []):
		var contact: Dictionary = contact_variant
		var enemy: Variant = contact.get("entity", null)
		if enemy == null:
			continue
		var attack_result: Dictionary = _apply_attack_instance_hit_to_target(
			melee_attack_instance_id,
			melee_attack_profile_id,
			contact.get("contact_point", enemy["pos"]),
			str(contact.get("target_id", "")),
			str(contact.get("hurtbox_id", "")),
			str(contact.get("target_profile_id", "")),
			DAMAGE_SOURCE_MELEE,
			float(contact.get("contact_time", 0.0)),
			str(contact.get("target_state", "")),
			bool(contact.get("is_currently_overlapping", true))
		)
		if not bool(attack_result.get("allowed", false)):
			continue
		_add_player_energy(ENERGY_GAIN_MELEE_HIT)
		_emit_sword_hit_effect(
			contact.get("contact_point", enemy["pos"]),
			attack_direction,
			COLORS["melee_sword"].lerp(COLORS[str(enemy.get("type", SHOOTER))], 0.24),
			1.06,
			"melee",
			{
				"spark_count": 3,
			}
		)
		_create_particles(enemy["pos"], COLORS[enemy["type"]], 5)
		screen_shake = max(screen_shake, 4.0)

	if _has_boss():
		var boss_contact: Dictionary = detection_result.get("boss_contact", {})
		if not boss_contact.is_empty():
			var boss_hit_result: Dictionary = _apply_boss_attack_instance_hit(
				melee_attack_instance_id,
				melee_attack_profile_id,
				boss_contact.get("contact_point", boss["pos"]),
				DAMAGE_SOURCE_MELEE,
				float(boss_contact.get("contact_time", 0.0)),
				bool(boss_contact.get("is_currently_overlapping", true))
			)
			if bool(boss_hit_result.get("allowed", false)):
				_add_player_energy(ENERGY_GAIN_MELEE_HIT)
				_emit_sword_hit_effect(
					boss_contact.get("contact_point", boss["pos"]),
					attack_direction,
					COLORS["melee_sword"].lerp(COLORS["boss_body"], 0.28),
					1.12,
					"melee",
					{
						"spark_count": 4,
					}
				)
				_create_particles(boss["pos"], COLORS["boss_body"], 8)
				screen_shake = max(screen_shake, 5.0)
	_clear_attack_instance(melee_attack_instance_id)


func _deflect_enemy_bullet(bullet: Dictionary, attack_direction: Vector2) -> void:
	var deflect_direction: Vector2 = (bullet["pos"] - player["pos"]).normalized()
	if deflect_direction.is_zero_approx():
		deflect_direction = attack_direction.normalized()
	if deflect_direction.is_zero_approx():
		deflect_direction = Vector2.RIGHT
	var blended_direction: Vector2 = deflect_direction.lerp(attack_direction.normalized(), 0.5)
	if blended_direction.is_zero_approx():
		blended_direction = deflect_direction
	_clear_attack_instance(str(bullet.get("attack_instance_id", "")))
	var attack_instance: Dictionary = _build_attack_instance(AttackProfiles.PROFILE_DEFLECTED_BULLET, "player", str(bullet.get("id", "bullet")))
	bullet["state"] = "deflected"
	bullet["owner_id"] = "player"
	bullet["color"] = COLORS["melee_sword"]
	bullet["attack_instance_id"] = str(attack_instance.get("id", ""))
	bullet["attack_profile_id"] = str(attack_instance.get("profile_id", AttackProfiles.PROFILE_DEFLECTED_BULLET))
	bullet["channel_scalar"] = float(bullet.get("damage", BULLET_DAMAGE)) / maxf(BULLET_DAMAGE, 0.001)
	bullet["vel"] = blended_direction.normalized() * maxf(bullet["vel"].length(), BULLET_SPEED) * DEFLECT_BULLET_SPEED_MULTIPLIER
	_create_particles(bullet["pos"], COLORS["melee_sword"], 4)


func _start_point_strike() -> void:
	var unsheath_direction: Vector2 = mouse_world - player["pos"]
	_trigger_unsheath_flash(
		unsheath_direction,
		_get_unsheath_flash_release_anchor(unsheath_direction, SwordState.POINT_STRIKE)
	)
	_start_sword_attack_instance(AttackProfiles.PROFILE_FLYING_SWORD_POINT)
	sword["state"] = SwordState.POINT_STRIKE
	sword["target_pos"] = mouse_world
	player["mode"] = CombatMode.RANGED


func _start_slicing() -> void:
	var unsheath_direction: Vector2 = mouse_world - player["pos"]
	_trigger_unsheath_flash(
		unsheath_direction,
		_get_unsheath_flash_release_anchor(unsheath_direction, SwordState.SLICING)
	)
	_start_sword_attack_instance(AttackProfiles.PROFILE_FLYING_SWORD_SLICE)
	sword["state"] = SwordState.SLICING
	player["mode"] = CombatMode.RANGED


func _trigger_unsheath_flash(direction: Vector2, flash_origin: Vector2) -> void:
	var flash_direction: Vector2 = direction.normalized()
	if flash_direction.is_zero_approx():
		flash_direction = Vector2.RIGHT
	var is_repeated_trigger: bool = unsheath_flash_repeat_timer > 0.0
	unsheath_flash_timer = UNSHEATH_FLASH_DURATION * (0.72 if is_repeated_trigger else 1.0)
	unsheath_flash_direction = flash_direction
	unsheath_flash_origin = flash_origin
	unsheath_flash_strength = UNSHEATH_FLASH_REPEAT_STRENGTH if is_repeated_trigger else UNSHEATH_FLASH_BASE_STRENGTH
	unsheath_flash_repeat_timer = UNSHEATH_FLASH_REPEAT_SUPPRESSION
	sword["afterimage_burst_timer"] = SWORD_AFTERIMAGE_BURST_DURATION
	sword["afterimage_emit_timer"] = 0.0


func _trigger_unsheath_press_flash(direction: Vector2) -> void:
	var flash_direction: Vector2 = direction.normalized()
	if flash_direction.is_zero_approx():
		flash_direction = Vector2.RIGHT
	var is_repeated_trigger: bool = unsheath_press_flash_repeat_timer > 0.0
	unsheath_press_flash_timer = UNSHEATH_PRESS_FLASH_DURATION
	unsheath_press_flash_direction = flash_direction
	unsheath_press_flash_origin = _get_unsheath_press_flash_anchor(flash_direction, UNSHEATH_PRESS_FLASH_ANCHOR_LERP)
	unsheath_press_flash_strength = UNSHEATH_PRESS_FLASH_REPEAT_STRENGTH if is_repeated_trigger else UNSHEATH_PRESS_FLASH_BASE_STRENGTH
	unsheath_press_flash_repeat_timer = UNSHEATH_PRESS_FLASH_REPEAT_SUPPRESSION


func _get_unsheath_flash_release_anchor(flash_direction: Vector2, next_sword_state: int) -> Vector2:
	if flash_direction.is_zero_approx():
		flash_direction = Vector2.RIGHT
	else:
		flash_direction = flash_direction.normalized()
	var target_distance: float = player["pos"].distance_to(mouse_world)
	var desired_distance: float = SWORD_ORBIT_DISTANCE + UNSHEATH_FLASH_SWORD_FORWARD_OFFSET
	match next_sword_state:
		SwordState.POINT_STRIKE:
			desired_distance = SWORD_ORBIT_DISTANCE + SWORD_POINT_STRIKE_SPEED * UNSHEATH_FLASH_POINT_RELEASE_PREDICT_TIME
		SwordState.SLICING:
			desired_distance = lerpf(
				SWORD_ORBIT_DISTANCE + UNSHEATH_FLASH_SWORD_FORWARD_OFFSET,
				target_distance,
				UNSHEATH_FLASH_SLICE_RELEASE_RATIO
			)
	var clamped_distance: float = _get_unsheath_flash_release_distance(target_distance, desired_distance)
	return player["pos"] + flash_direction * (clamped_distance + UNSHEATH_FLASH_SWORD_FORWARD_OFFSET)


func _get_unsheath_flash_release_distance(target_distance: float, desired_distance: float) -> float:
	var max_distance: float = minf(
		maxf(target_distance - 10.0, SWORD_ORBIT_DISTANCE + 12.0),
		UNSHEATH_FLASH_RELEASE_MAX_DISTANCE
	)
	var min_distance: float = minf(UNSHEATH_FLASH_RELEASE_MIN_DISTANCE, max_distance)
	return clampf(desired_distance, min_distance, max_distance)


func _get_unsheath_press_flash_anchor(flash_direction: Vector2, anchor_lerp: float) -> Vector2:
	var contact_anchor: Vector2 = player["pos"].lerp(sword["pos"], anchor_lerp)
	return contact_anchor - flash_direction * UNSHEATH_FLASH_ROOT_BACK_OFFSET


func _update_sword_trail(delta: float, frame_velocity: Vector2) -> void:
	var vfx: SwordVfxProfile = get_sword_vfx_profile()
	var index: int = sword_trail_points.size() - 1
	while index >= 0:
		var trail_point: Dictionary = sword_trail_points[index]
		trail_point["life"] = max(float(trail_point.get("life", 0.0)) - delta, 0.0)
		if trail_point["life"] <= 0.0:
			sword_trail_points.remove_at(index)
		else:
			sword_trail_points[index] = trail_point
		index -= 1

	if sword["state"] != SwordState.POINT_STRIKE and sword["state"] != SwordState.SLICING and sword["state"] != SwordState.RECALLING:
		sword["trail_emit_timer"] = 0.0
		return

	var emit_timer: float = max(float(sword.get("trail_emit_timer", 0.0)) - delta, 0.0)
	var min_speed: float = float(vfx.trail_min_speed) * (0.82 if sword["state"] == SwordState.RECALLING else 1.0)
	if frame_velocity.length() < min_speed:
		sword["trail_emit_timer"] = emit_timer
		return
	if emit_timer > 0.0:
		sword["trail_emit_timer"] = emit_timer
		return

	sword["trail_emit_timer"] = float(vfx.trail_sample_interval)
	_emit_sword_trail_point(frame_velocity)


func _emit_sword_trail_point(frame_velocity: Vector2) -> void:
	var vfx: SwordVfxProfile = get_sword_vfx_profile()
	var direction: Vector2 = frame_velocity.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT.rotated(sword["angle"])
	var is_slice: bool = sword["state"] == SwordState.SLICING
	var is_recalling: bool = sword["state"] == SwordState.RECALLING
	var speed_reference: float = SWORD_RECALL_SPEED if is_recalling else SWORD_POINT_STRIKE_SPEED
	var speed_ratio: float = clampf(frame_velocity.length() / maxf(speed_reference, 0.001), 0.0, 1.0)
	var width_scale: float = float(vfx.trail_point_width_scale)
	var life_scale: float = float(vfx.trail_point_life_scale)
	var style: String = "point"
	if is_slice:
		width_scale = float(vfx.trail_slice_width_scale)
		life_scale = float(vfx.trail_slice_life_scale)
		style = "slice"
	elif is_recalling:
		width_scale = float(vfx.trail_recall_width_scale)
		life_scale = float(vfx.trail_recall_life_scale)
		style = "recall"
	var previous_forward: Vector2 = direction
	if not sword_trail_points.is_empty():
		var previous_point: Dictionary = sword_trail_points[sword_trail_points.size() - 1]
		previous_forward = Vector2(previous_point.get("forward", direction))
	if previous_forward.is_zero_approx():
		previous_forward = direction
	var turn_delta: float = wrapf(direction.angle() - previous_forward.angle(), -PI, PI)
	var turn_strength: float = clampf(absf(turn_delta) / 0.52, 0.0, 1.0)
	sword_trail_points.append({
		"pos": sword["pos"] + direction * float(vfx.trail_forward_offset),
		"life": float(vfx.trail_duration) * life_scale,
		"max_life": float(vfx.trail_duration) * life_scale,
		"half_width": lerpf(float(vfx.trail_base_half_width) * 0.82, float(vfx.trail_base_half_width) * 1.24, speed_ratio) * width_scale,
		"alpha_scale": lerpf(0.7, 1.0, speed_ratio) * (0.86 if is_recalling else 1.0),
		"style": style,
		"forward": direction,
		"speed_ratio": speed_ratio,
		"turn_strength": turn_strength,
		"turn_sign": 1.0 if turn_delta >= 0.0 else -1.0,
	})
	if sword_trail_points.size() > int(vfx.trail_max_points):
		sword_trail_points.remove_at(0)


func _update_sword_air_wakes(delta: float, frame_velocity: Vector2) -> void:
	var vfx: SwordVfxProfile = get_sword_vfx_profile()
	var index: int = sword_air_wakes.size() - 1
	while index >= 0:
		var wake: Dictionary = sword_air_wakes[index]
		wake["life"] = max(float(wake.get("life", 0.0)) - delta, 0.0)
		if wake["life"] <= 0.0:
			sword_air_wakes.remove_at(index)
		else:
			sword_air_wakes[index] = wake
		index -= 1

	if sword["state"] == SwordState.ORBITING:
		sword["air_wake_emit_timer"] = 0.0
		sword["last_motion_forward"] = Vector2.RIGHT.rotated(sword["angle"])
		return

	var current_forward: Vector2 = frame_velocity.normalized()
	if current_forward.is_zero_approx():
		current_forward = Vector2.RIGHT.rotated(sword["angle"])
	if current_forward.is_zero_approx():
		current_forward = Vector2.RIGHT
	current_forward = current_forward.normalized()

	var emit_timer: float = max(float(sword.get("air_wake_emit_timer", 0.0)) - delta, 0.0)
	var speed: float = frame_velocity.length()
	var previous_forward: Vector2 = Vector2(sword.get("last_motion_forward", current_forward))
	if previous_forward.is_zero_approx():
		previous_forward = current_forward
	var turn_delta: float = wrapf(current_forward.angle() - previous_forward.angle(), -PI, PI)
	var turn_strength: float = clampf(
		(absf(turn_delta) - float(vfx.air_wake_turn_threshold)) / maxf(0.56 - float(vfx.air_wake_turn_threshold), 0.001),
		0.0,
		1.0
	)
	var can_emit: bool = speed >= float(vfx.air_wake_min_speed) and turn_strength > 0.0
	if can_emit and emit_timer <= 0.0:
		_emit_sword_air_wake(current_forward, turn_delta, turn_strength, speed)
		sword["air_wake_emit_timer"] = lerpf(float(vfx.air_wake_emit_interval_max), float(vfx.air_wake_emit_interval_min), turn_strength)
	else:
		sword["air_wake_emit_timer"] = emit_timer
	sword["last_motion_forward"] = current_forward


func _emit_sword_air_wake(current_forward: Vector2, turn_delta: float, turn_strength: float, speed: float) -> void:
	var vfx: SwordVfxProfile = get_sword_vfx_profile()
	var turn_sign: float = 1.0 if turn_delta >= 0.0 else -1.0
	var outward: Vector2 = current_forward.rotated(turn_sign * PI * 0.5)
	var is_recalling: bool = sword["state"] == SwordState.RECALLING
	var speed_reference: float = SWORD_RECALL_SPEED if is_recalling else SWORD_POINT_STRIKE_SPEED
	var speed_ratio: float = clampf(speed / maxf(speed_reference, 0.001), 0.0, 1.0)
	var center: Vector2 = sword["pos"] - current_forward * (8.0 + 6.0 * speed_ratio) + outward * (4.0 + 9.0 * turn_strength)
	var wake_width_scale: float = float(vfx.trail_recall_width_scale) * 1.16 if is_recalling else 1.0
	var wake_style: String = "point"
	if is_recalling:
		wake_style = "recall"
	elif not sword_trail_points.is_empty():
		wake_style = str(sword_trail_points[sword_trail_points.size() - 1].get("style", "point"))
	sword_air_wakes.append({
		"pos": center,
		"life": float(vfx.air_wake_duration),
		"max_life": float(vfx.air_wake_duration),
		"forward": current_forward,
		"outward": outward,
		"turn_strength": turn_strength,
		"speed_ratio": speed_ratio,
		"length": float(vfx.air_wake_base_length) * lerpf(0.86, 1.32, speed_ratio) * lerpf(0.92, 1.26, turn_strength),
		"width": float(vfx.air_wake_base_width) * wake_width_scale * lerpf(0.82, 1.18, turn_strength),
		"style": wake_style,
	})
	if sword_air_wakes.size() > int(vfx.air_wake_max_count):
		sword_air_wakes.remove_at(0)


func _update_sword_return_catches(delta: float) -> void:
	var index: int = sword_return_catches.size() - 1
	while index >= 0:
		var catch_effect: Dictionary = sword_return_catches[index]
		catch_effect["life"] = max(float(catch_effect.get("life", 0.0)) - delta, 0.0)
		if catch_effect["life"] <= 0.0:
			sword_return_catches.remove_at(index)
		else:
			sword_return_catches[index] = catch_effect
		index -= 1


func _emit_sword_return_catch(catch_pos: Vector2, direction: Vector2) -> void:
	var vfx: SwordVfxProfile = get_sword_vfx_profile()
	var resolved_direction: Vector2 = direction
	if resolved_direction.is_zero_approx():
		resolved_direction = Vector2.RIGHT.rotated(sword["angle"])
	if resolved_direction.is_zero_approx():
		resolved_direction = Vector2.RIGHT
	sword_return_catches.append({
		"pos": catch_pos,
		"forward": resolved_direction.normalized(),
		"life": float(vfx.return_catch_duration),
		"max_life": float(vfx.return_catch_duration),
		"radius": float(vfx.return_catch_base_radius),
	})
	if sword_return_catches.size() > int(vfx.return_catch_max_count):
		sword_return_catches.remove_at(0)


func _update_sword_afterimages(delta: float, frame_velocity: Vector2) -> void:
	var index: int = sword_afterimages.size() - 1
	while index >= 0:
		var afterimage: Dictionary = sword_afterimages[index]
		afterimage["life"] = max(float(afterimage.get("life", 0.0)) - delta, 0.0)
		if afterimage["life"] <= 0.0:
			sword_afterimages.remove_at(index)
		else:
			sword_afterimages[index] = afterimage
		index -= 1

	if sword["state"] == SwordState.ORBITING or sword["state"] == SwordState.RECALLING:
		sword["afterimage_burst_timer"] = 0.0
		sword["afterimage_emit_timer"] = 0.0
		return

	var burst_timer: float = max(float(sword.get("afterimage_burst_timer", 0.0)) - delta, 0.0)
	var emit_timer: float = max(float(sword.get("afterimage_emit_timer", 0.0)) - delta, 0.0)
	sword["afterimage_burst_timer"] = burst_timer
	if burst_timer <= 0.0:
		sword["afterimage_emit_timer"] = 0.0
		return
	if frame_velocity.length() < SWORD_AFTERIMAGE_MIN_SPEED:
		sword["afterimage_emit_timer"] = emit_timer
		return
	if emit_timer > 0.0:
		sword["afterimage_emit_timer"] = emit_timer
		return

	sword["afterimage_emit_timer"] = SWORD_AFTERIMAGE_EMIT_INTERVAL
	_emit_sword_afterimage(frame_velocity)


func _emit_sword_afterimage(frame_velocity: Vector2) -> void:
	var direction: Vector2 = frame_velocity.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT.rotated(sword["angle"])
	var speed_ratio: float = clampf(frame_velocity.length() / SWORD_POINT_STRIKE_SPEED, 0.0, 1.0)
	sword_afterimages.append({
		"pos": sword["pos"],
		"angle": direction.angle(),
		"life": SWORD_AFTERIMAGE_DURATION,
		"max_life": SWORD_AFTERIMAGE_DURATION,
		"stretch": lerpf(1.0, 1.28, speed_ratio),
		"width_scale": lerpf(1.0, 1.14, speed_ratio),
		"color": COLORS["ranged_sword"],
	})
	if sword_afterimages.size() > SWORD_AFTERIMAGE_MAX_COUNT:
		sword_afterimages.remove_at(0)


func _update_sword_hit_effects(delta: float) -> void:
	var index: int = sword_hit_effects.size() - 1
	while index >= 0:
		var hit_effect: Dictionary = sword_hit_effects[index]
		hit_effect["life"] = max(float(hit_effect.get("life", 0.0)) - delta, 0.0)
		if hit_effect["life"] <= 0.0:
			sword_hit_effects.remove_at(index)
		else:
			sword_hit_effects[index] = hit_effect
		index -= 1


func _emit_sword_hit_effect(
	contact_pos: Vector2,
	swing_direction: Vector2,
	effect_color: Color,
	intensity := 1.0,
	style_override := "",
	extra := {}
) -> void:
	var direction: Vector2 = swing_direction
	if direction.is_zero_approx():
		direction = sword["vel"]
	if direction.is_zero_approx():
		direction = Vector2.RIGHT.rotated(sword["angle"])
	var speed_ratio: float = clampf(maxf(direction.length(), sword["vel"].length()) / SWORD_POINT_STRIKE_SPEED, 0.0, 1.0)
	var attack_profile_id: String = str(sword.get("attack_profile_id", ""))
	var is_slice: bool = attack_profile_id == AttackProfiles.PROFILE_FLYING_SWORD_SLICE
	var style: String = str(style_override)
	if style == "":
		style = "slice" if is_slice else "point"
	var length_scale: float = SWORD_HIT_EFFECT_POINT_LENGTH_SCALE
	var width_scale: float = SWORD_HIT_EFFECT_POINT_WIDTH_SCALE
	var spark_count: int = SWORD_HIT_EFFECT_SPARK_COUNT
	match style:
		"slice":
			length_scale = SWORD_HIT_EFFECT_SLICE_LENGTH_SCALE
			width_scale = SWORD_HIT_EFFECT_SLICE_WIDTH_SCALE
			spark_count = 3
		"melee":
			length_scale = 1.42
			width_scale = 1.2
			spark_count = 3
		"deflect":
			length_scale = 0.96
			width_scale = 0.72
			spark_count = 4
		"sever":
			length_scale = 1.28
			width_scale = 0.68
			spark_count = 5
	direction = direction.normalized()
	var hit_effect := {
		"pos": contact_pos,
		"direction": direction,
		"life": SWORD_HIT_EFFECT_DURATION,
		"max_life": SWORD_HIT_EFFECT_DURATION,
		"length": (SWORD_HIT_EFFECT_BASE_LENGTH + 10.0 * speed_ratio) * length_scale * intensity,
		"width": (SWORD_HIT_EFFECT_BASE_WIDTH + 3.0 * speed_ratio) * width_scale * intensity,
		"spark_count": spark_count,
		"seed": randf() * TAU,
		"color": effect_color,
		"style": style,
	}
	if typeof(extra) == TYPE_DICTIONARY:
		for key_variant in extra.keys():
			hit_effect[key_variant] = extra[key_variant]
	sword_hit_effects.append(hit_effect)
	if sword_hit_effects.size() > SWORD_HIT_EFFECT_MAX_COUNT:
		sword_hit_effects.remove_at(0)


func _emit_silk_sever_effect(from_pos: Vector2, to_pos: Vector2, contact_pos: Vector2, is_main := false) -> void:
	var silk_color: Color = COLORS["silk_main"] if is_main else COLORS["silk"]
	_emit_sword_hit_effect(
		contact_pos,
		to_pos - from_pos,
		silk_color,
		1.18 if is_main else 1.0,
		"sever",
		{
			"from": from_pos,
			"to": to_pos,
			"is_main": is_main,
			"spark_count": 6 if is_main else 5,
		}
	)


func _request_hitstop(duration: float) -> void:
	if duration <= 0.0:
		return
	hitstop_timer = maxf(hitstop_timer, duration)
	hitstop_queue.clear()
	hitstop_gap_timer = 0.0


func _queue_point_strike_hitstop_pulse() -> void:
	var hitstop_duration: float = minf(FLYING_SWORD_POINT_HITSTOP_BASE_DURATION, FLYING_SWORD_POINT_HITSTOP_MAX_DURATION)
	hitstop_queue.append(hitstop_duration)


func _trigger_silk_sever_hitstop() -> void:
	_request_hitstop(SILK_SEVER_HITSTOP_DURATION)


func _get_silk_contact_self_feedback_interval(attack_profile_id: String) -> float:
	match attack_profile_id:
		AttackProfiles.PROFILE_FLYING_SWORD_POINT:
			return SILK_CONTACT_SELF_FEEDBACK_POINT_INTERVAL
		AttackProfiles.PROFILE_FLYING_SWORD_SLICE:
			return SILK_CONTACT_SELF_FEEDBACK_SLICE_INTERVAL
		_:
			return SILK_CONTACT_SELF_FEEDBACK_SLICE_INTERVAL


# Silk sever still ticks continuously; only the heavy sword impact feedback is throttled.
func _consume_silk_contact_self_feedback(target_id: String, attack_profile_id: String) -> bool:
	if target_id == "":
		return true
	var attack_instance_id: String = str(sword.get("attack_instance_id", ""))
	if attack_instance_id == "":
		return true
	var attack_instances: Dictionary = combat_runtime.get("attack_instances", {})
	if not attack_instances.has(attack_instance_id):
		return true
	var attack_instance: Dictionary = attack_instances[attack_instance_id]
	var runtime: Dictionary = attack_instance.get("runtime", {})
	var silk_feedback_runtime: Dictionary = runtime.get("silk_contact_feedback", {})
	var feedback_key: String = "%s::%s" % [attack_profile_id, target_id]
	var feedback_interval: float = _get_silk_contact_self_feedback_interval(attack_profile_id)
	var last_feedback_time: float = float(silk_feedback_runtime.get(feedback_key, -INF))
	if elapsed_time - last_feedback_time < feedback_interval:
		return false
	silk_feedback_runtime[feedback_key] = elapsed_time
	runtime["silk_contact_feedback"] = silk_feedback_runtime
	attack_instance["runtime"] = runtime
	attack_instances[attack_instance_id] = attack_instance
	combat_runtime["attack_instances"] = attack_instances
	return true


func _trigger_sword_self_hit_feedback(contact_point: Vector2, attack_profile_id: String, target_kind := "") -> void:
	var sword_forward: Vector2 = sword["vel"]
	if sword_forward.is_zero_approx():
		sword_forward = Vector2.RIGHT.rotated(float(sword.get("angle", 0.0)))
	if sword_forward.is_zero_approx():
		sword_forward = Vector2.RIGHT
	sword_forward = sword_forward.normalized()
	var contact_direction: Vector2 = contact_point - sword["pos"]
	if contact_direction.is_zero_approx():
		contact_direction = sword_forward
	else:
		contact_direction = contact_direction.normalized()
	var side_sign: float = 1.0 if sword_forward.cross(contact_direction) >= 0.0 else -1.0
	var side_axis: Vector2 = sword_forward.rotated(PI * 0.5) * side_sign
	var offset_distance: float = 4.6
	var angle_offset: float = 0.1 * side_sign
	var screen_shake_strength: float = 4.2
	var local_hit_intensity: float = 0.72
	var local_hit_style: String = "slice"
	var side_offset_ratio: float = 0.34
	var feedback_duration: float = SWORD_IMPACT_FEEDBACK_DURATION
	var force_max_rebound: bool = false
	match attack_profile_id:
		AttackProfiles.PROFILE_FLYING_SWORD_POINT:
			offset_distance = 9.8
			angle_offset = 0.24 * side_sign
			screen_shake_strength = 6.8
			local_hit_intensity = 0.88
			local_hit_style = "point"
		AttackProfiles.PROFILE_FLYING_SWORD_SLICE:
			offset_distance = SWORD_IMPACT_MAX_OFFSET
			angle_offset = SWORD_IMPACT_MAX_ANGLE_OFFSET * side_sign
			screen_shake_strength = 0.0
			local_hit_intensity = 1.0
			local_hit_style = "slice"
			side_offset_ratio = SWORD_SLICE_IMPACT_SIDE_OFFSET_RATIO
			feedback_duration = SWORD_SLICE_IMPACT_FEEDBACK_DURATION
			force_max_rebound = true
	if target_kind == "silk":
		offset_distance *= SILK_CONTACT_IMPACT_OFFSET_SCALE
		angle_offset *= SILK_CONTACT_IMPACT_ANGLE_SCALE
		screen_shake_strength *= SILK_CONTACT_IMPACT_SCREEN_SHAKE_SCALE
		local_hit_intensity *= SILK_CONTACT_IMPACT_LOCAL_HIT_SCALE
		feedback_duration *= SILK_CONTACT_IMPACT_DURATION_SCALE
		side_offset_ratio *= SILK_CONTACT_IMPACT_SIDE_OFFSET_SCALE
		force_max_rebound = false
	var target_offset: Vector2 = - sword_forward * offset_distance + side_axis * (offset_distance * side_offset_ratio)
	var new_offset: Vector2 = Vector2(sword.get("impact_feedback_offset", Vector2.ZERO)) + target_offset
	if force_max_rebound:
		new_offset = target_offset.normalized() * SWORD_IMPACT_MAX_OFFSET
	elif new_offset.length() > SWORD_IMPACT_MAX_OFFSET:
		new_offset = new_offset.normalized() * SWORD_IMPACT_MAX_OFFSET
	sword["impact_feedback_offset"] = new_offset
	var next_angle_offset: float = float(sword.get("impact_angle_offset", 0.0)) + angle_offset
	if force_max_rebound:
		next_angle_offset = angle_offset
	sword["impact_angle_offset"] = clampf(
		next_angle_offset,
		- SWORD_IMPACT_MAX_ANGLE_OFFSET,
		SWORD_IMPACT_MAX_ANGLE_OFFSET
	)
	sword["impact_feedback_timer"] = maxf(float(sword.get("impact_feedback_timer", 0.0)), feedback_duration)
	var local_hit_pos: Vector2 = sword["pos"] - sword_forward * (2.0 + offset_distance * 0.18) + side_axis * (offset_distance * 0.12)
	var local_hit_color: Color = COLORS["ranged_sword"].lerp(Color.WHITE, 0.2)
	_emit_sword_hit_effect(local_hit_pos, sword_forward + side_axis * 0.16, local_hit_color, local_hit_intensity, local_hit_style)
	screen_shake = max(screen_shake, screen_shake_strength)


func _try_consume_energy(amount: float) -> bool:
	return _consume_player_energy(amount)


func _fire_array_swords() -> bool:
	if not _can_use_array_attack():
		return false
	var ready_count: int = _get_ready_array_sword_count()
	if ready_count <= 0:
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return false
	var morph_state: Dictionary = _get_sword_array_fire_state()
	var mode: String = String(morph_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	if not _can_fire_array_batch(mode, ready_count):
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return false
	var fire_count: int = mini(_get_array_mode_batch_target(mode), ready_count)
	var energy_cost: float = _get_array_sword_energy_cost(fire_count, mode)
	if energy_cost > 0.0 and not _try_consume_energy(energy_cost):
		_show_action_failure("剑意不足", "array_energy", _get_energy_failure_color(), "energy")
		return false
	player["array_packet_remainder"] = 0.0
	var source_snapshot: Array = _build_array_sword_source_snapshot()
	fire_count = mini(fire_count, source_snapshot.size())
	if fire_count <= 0:
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return false
	var batch_id: String = _next_id("array_batch") if mode == SwordArrayConfig.MODE_FAN else ""
	var burst_step: int = 0
	var fired_count: int = 0
	while fired_count < fire_count:
		var snapshot_positions: Array = []
		for source in source_snapshot:
			snapshot_positions.append(source["pos"])
		var source_snapshot_index: int = SwordArrayController.get_fire_source_snapshot_index(
			self ,
			morph_state,
			snapshot_positions,
			fired_count,
			fire_count,
			burst_step,
			ready_count
		)
		if source_snapshot_index < 0 or source_snapshot_index >= source_snapshot.size():
			source_snapshot_index = 0
		var sword_id: String = str(source_snapshot[source_snapshot_index]["id"])
		_fire_single_array_sword(sword_id, fired_count, fire_count, burst_step, ready_count, batch_id)
		source_snapshot.remove_at(source_snapshot_index)
		fired_count += 1
	_emit_sword_array_fire_effect(morph_state, fire_count)
	return true


func _build_array_sword_source_snapshot() -> Array:
	var source_snapshot: Array = []
	for array_sword in _get_ready_array_swords():
		source_snapshot.append({
			"id": array_sword["id"],
			"pos": array_sword["pos"],
		})
	return source_snapshot


func _get_array_sword_by_id(sword_id: String) -> Dictionary:
	for array_sword in array_swords:
		if String(array_sword.get("id", "")) == sword_id:
			return array_sword
	return {}


func _fire_single_array_sword(sword_id: String, volley_fire_index: int, volley_fire_count: int, burst_step: int, total_count_before_fire: int, batch_id := "") -> void:
	if sword_id == "":
		return
	var array_sword: Dictionary = _get_array_sword_by_id(sword_id)
	if array_sword.is_empty() or String(array_sword.get("state", "")) != "ready":
		return
	var travel_mode: String = _get_array_batch_mode()
	var launch_origin: Vector2 = SwordArrayController.get_fire_launch_origin(
		self ,
		_get_sword_array_fire_state(),
		volley_fire_index,
		array_sword["pos"],
		volley_fire_count,
		burst_step,
		total_count_before_fire
	)
	var target_point: Vector2 = _get_sword_array_target(volley_fire_index, launch_origin, volley_fire_count, burst_step, total_count_before_fire)
	var direction: Vector2 = target_point - launch_origin
	if direction.is_zero_approx():
		direction = mouse_world - player["pos"]
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	array_sword["pos"] = launch_origin
	array_sword["state"] = "outbound"
	array_sword["travel_mode"] = travel_mode
	_reset_array_sword_sortie_state(array_sword)
	_start_array_sword_attack_instance(array_sword)
	array_sword["batch_id"] = String(batch_id)
	array_sword["guidance_active"] = true
	array_sword["guidance_fire_index"] = volley_fire_index
	array_sword["guidance_volley_count"] = volley_fire_count
	array_sword["guidance_burst_step"] = burst_step
	array_sword["guidance_total_count"] = total_count_before_fire
	var base_direction: Vector2 = direction.normalized()
	var flow_side: float = _resolve_array_sword_flow_side(array_sword, launch_origin, base_direction)
	array_sword["flow_side"] = flow_side
	var launch_velocity_direction: Vector2 = _blend_array_sword_direction_with_tangent(
		base_direction,
		_get_array_sword_launch_tangent_direction(travel_mode, launch_origin, base_direction, flow_side),
		_get_array_sword_launch_tangent_bias(travel_mode) * _get_array_sword_flow_slot_weight(array_sword, travel_mode)
	)
	array_sword["vel"] = launch_velocity_direction * _get_current_array_sword_speed(travel_mode)
	player["array_fire_index"] += 1
	_create_particles(array_sword["pos"], COLORS["array_sword"], 5)
	screen_shake = max(screen_shake, 2.0)


func _emit_sword_array_fire_effect(state_source, fire_count: int) -> void:
	var effect: Dictionary = SwordArrayController.get_fire_effect(self , state_source, fire_count)
	_create_particles(effect["position"], effect["color"], effect["particles"])
	screen_shake = max(screen_shake, effect["shake"])


func _spawn_enemy(enemy_type: String) -> Dictionary:
	var spawn_pos: Vector2 = _roll_spawn_position()
	var enemy: Dictionary = {
		"id": _next_id(enemy_type),
		"type": enemy_type,
		"target_profile_id": TargetProfiles.get_enemy_profile_id(enemy_type),
		"descriptor_provider_id": TargetDescriptorRegistry.PROVIDER_ENEMY,
		"pos": spawn_pos,
		"vel": Vector2.ZERO,
		"move_timer": randf_range(0.2, 1.4),
		"shoot_cooldown": randf_range(0.2, 1.0),
		"radius": SHOOTER_RADIUS,
		"health": SHOOTER_HEALTH,
		"max_health": SHOOTER_HEALTH,
		"last_damage_source": DAMAGE_SOURCE_NONE,
		"score": 20,
		"stagger_timer": 0.0,
		"hit_flash_timer": 0.0,
		"hit_flash_color": Color.WHITE,
		"hit_reaction_timer": 0.0,
		"hit_reaction_offset": Vector2.ZERO,
		"hit_reaction_vector": Vector2.ZERO,
		"is_dying": false,
		"death_feedback_timer": 0.0,
		"death_feedback_color": Color.WHITE,
		"damage_taken_multiplier": 1.0,
		"support_source_id": "",
		"package_id": "",
		"package_type": "",
		"package_phase": "",
		"package_slot_index": - 1,
		"package_slot_count": 0,
		"package_desired_pos": spawn_pos,
		"package_center": spawn_pos,
		"package_radius": 0.0,
		"package_fire_enabled": false,
		"package_speed_multiplier": 1.0,
	}
	match enemy_type:
		PUPPET:
			enemy["radius"] = PUPPET_RADIUS
			enemy["health"] = PUPPET_HEALTH
			enemy["max_health"] = PUPPET_HEALTH
			enemy["score"] = 0
			enemy["shoot_cooldown"] = 0.0
			enemy["melee_timer"] = 0.0
		TANK:
			enemy["radius"] = TANK_RADIUS
			enemy["health"] = TANK_HEALTH
			enemy["max_health"] = TANK_HEALTH
			enemy["score"] = 50
		CASTER:
			enemy["radius"] = CASTER_RADIUS
			enemy["health"] = CASTER_HEALTH
			enemy["max_health"] = CASTER_HEALTH
			enemy["shoot_cooldown"] = randf_range(0.4, CASTER_COOLDOWN)
		HEAVY:
			enemy["radius"] = HEAVY_RADIUS
			enemy["health"] = HEAVY_HEALTH
			enemy["max_health"] = HEAVY_HEALTH
			enemy["score"] = 40
			enemy["shoot_cooldown"] = randf_range(0.4, HEAVY_COOLDOWN)
		RING_LEECH:
			enemy["radius"] = RING_LEECH_RADIUS
			enemy["health"] = RING_LEECH_HEALTH
			enemy["max_health"] = RING_LEECH_HEALTH
			enemy["score"] = 25
			enemy["shoot_cooldown"] = randf_range(0.2, RING_LEECH_COOLDOWN)
			enemy["orbit_angle"] = randf_range(-PI, PI)
			enemy["orbit_direction"] = 1.0 if randf() < 0.5 else -1.0
		DRAPE_PRIEST:
			enemy["radius"] = DRAPE_PRIEST_RADIUS
			enemy["health"] = DRAPE_PRIEST_HEALTH
			enemy["max_health"] = DRAPE_PRIEST_HEALTH
			enemy["score"] = 35
			enemy["shoot_cooldown"] = randf_range(0.4, DRAPE_PRIEST_BOLT_COOLDOWN)
			enemy["support_target_id"] = ""
			enemy["support_relink_timer"] = 0.0
		MIRROR_NEEDLER:
			enemy["radius"] = MIRROR_NEEDLER_RADIUS
			enemy["health"] = MIRROR_NEEDLER_HEALTH
			enemy["max_health"] = MIRROR_NEEDLER_HEALTH
			enemy["score"] = 45
			enemy["shoot_cooldown"] = randf_range(0.6, MIRROR_NEEDLER_COOLDOWN)
			enemy["move_timer"] = randf_range(0.3, 1.0)
			enemy["strafe_dir"] = 1.0 if randf() < 0.5 else -1.0
			enemy["charge_timer"] = 0.0
			enemy["mirror_vulnerable_timer"] = 0.0
		_:
			enemy["shoot_cooldown"] = randf_range(0.4, SHOOTER_COOLDOWN)
	enemies.append(enemy)
	_register_enemy_hurtboxes(enemy)
	return enemy


func _spawn_bullet(position: Vector2, velocity: Vector2, bullet_type: String, owner_id: String, color: Color, extra := {}) -> void:
	var base_radius: float = BULLET_LARGE_RADIUS if bullet_type == "large" else BULLET_RADIUS
	var base_damage: float = BULLET_LARGE_DAMAGE if bullet_type == "large" else BULLET_DAMAGE
	bullets.append({
		"id": _next_id("bullet"),
		"pos": position,
		"vel": velocity,
		"radius": float(extra.get("radius", base_radius)),
		"damage": float(extra.get("damage", base_damage)),
		"family": str(extra.get("family", BULLET_FAMILY_NEEDLE)),
		"type": bullet_type,
		"owner_id": owner_id,
		"source_owner_id": str(extra.get("source_owner_id", owner_id)),
		"source_enemy_type": str(extra.get("source_enemy_type", "")),
		"color": color,
		"state": "normal",
		"attack_instance_id": "",
		"attack_profile_id": "",
		"channel_scalar": 1.0,
		"freeze_timer": 0.0,
		"life_timer": 0.0,
		"guidance_active": false,
		"guidance_elapsed": 0.0,
		"guidance_distance": 0.0,
		"guidance_fire_index": - 1,
		"guidance_volley_count": - 1,
		"guidance_burst_step": 0,
		"guidance_total_count": - 1,
	})


func _create_particles(position: Vector2, color: Color, count: int) -> void:
	var particle_index: int = 0
	while particle_index < count:
		particles.append({
			"pos": position,
			"vel": Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0)),
			"life": randf_range(0.2, 0.45),
			"max_life": 0.45,
			"color": color,
			"size": randf_range(2.0, 4.5),
		})
		particle_index += 1


func _remove_bullet(index: int) -> void:
	if index < 0 or index >= bullets.size():
		return
	_clear_attack_instance(str(bullets[index].get("attack_instance_id", "")))
	bullets.remove_at(index)


func _set_game_over() -> void:
	is_game_over = true
	left_mouse_held = false
	right_mouse_held = false
	game_over_label.visible = true


func _update_ui() -> void:
	if lookdev_mode:
		health_label.text = "预览场景"
		energy_label.text = "真实 Main 状态机"
		wave_label.text = "模式 %s" % [_get_lookdev_mode_label()]
		score_label.text = "点刺 / 连斩 / 回收 | 使用真实御剑逻辑与渲染"
		mode_label.text = "御剑特效预览"
		if status_message_timer > 0.0 and status_message != "":
			status_label.text = status_message
			status_label.modulate = status_message_color
		else:
			status_label.text = "权威预览"
			status_label.modulate = Color("f1e3bc")
		energy_label.modulate = Color("d7bb79")
		score_label.modulate = Color("9cb0c2")
		focus_status_label.visible = false
		hint_label.text = "1 点刺 | 2 连斩 | 3 回收 | Space 暂停/继续 | R 重播"
		game_over_label.visible = false
		return
	health_label.text = "生命 %.0f / %.0f" % [player["health"], PLAYER_MAX_HEALTH]
	energy_label.text = "剑意 %.0f / %.0f" % [
		player["energy"],
		PLAYER_MAX_ENERGY
	]
	if debug_calibration_mode:
		var raw_distance: float = float(player.get("array_raw_aim_distance", player["pos"].distance_to(mouse_world)))
		var control_distance: float = float(player.get("array_control_distance", raw_distance))
		var morph_state: Dictionary = _get_sword_array_morph_state()
		var fire_state: Dictionary = _get_sword_array_fire_state()
		var default_distances: Dictionary = SwordArrayConfig.get_default_morph_distances()
		var distances: Dictionary = SwordArrayConfig.get_morph_distances()
		var control_distances: Dictionary = SwordArrayConfig.get_control_morph_distances()
		wave_label.text = "校准模式 | 视觉 %.1f | 控制 %.1f | 显示 %s -> %s (%.2f) | 发射 %s -> %s (%.2f)" % [
			raw_distance,
			control_distance,
			morph_state["visual_from_mode"],
			morph_state["visual_to_mode"],
			morph_state["visual_blend"],
			fire_state["visual_from_mode"],
			fire_state["visual_to_mode"],
			fire_state["visual_blend"]
		]
		score_label.text = "默认 | 1 %.0f | 2 %.0f | 3 %.0f | 4 %.0f\n当前 | 1 %.0f | 2 %.0f | 3 %.0f | 4 %.0f\n控制 | 1 %.0f | 2 %.0f | 3 %.0f | 4 %.0f\n差值 | 1 %s | 2 %s | 3 %s | 4 %s" % [
			default_distances["ring_stable_end"],
			default_distances["ring_to_fan_end"],
			default_distances["fan_stable_end"],
			default_distances["fan_to_pierce_end"],
			distances["ring_stable_end"],
			distances["ring_to_fan_end"],
			distances["fan_stable_end"],
			distances["fan_to_pierce_end"],
			control_distances["ring_stable_end"],
			control_distances["ring_to_fan_end"],
			control_distances["fan_stable_end"],
			control_distances["fan_to_pierce_end"],
			_format_distance_delta(distances["ring_stable_end"] - default_distances["ring_stable_end"]),
			_format_distance_delta(distances["ring_to_fan_end"] - default_distances["ring_to_fan_end"]),
			_format_distance_delta(distances["fan_stable_end"] - default_distances["fan_stable_end"]),
			_format_distance_delta(distances["fan_to_pierce_end"] - default_distances["fan_to_pierce_end"])
		]
	else:
		wave_label.text = "波次 %d%s" % [wave, " | 战斗调试" if debug_battle_mode else ""]
		score_label.text = "得分 %d | 飞剑 %d / %d%s" % [
			score,
			_get_ready_array_sword_count(),
			_get_current_array_sword_capacity(),
			_get_debug_status_suffix()
		]
	var sword_mode_text: String = "近战" if sword["state"] == SwordState.ORBITING else "御剑"
	var bullet_time_text: String = " | 子弹时间" if sword["state"] != SwordState.ORBITING else ""
	var debug_mode_text: String = " | DEBUG" if debug_battle_mode else ""
	mode_label.text = "%s%s%s" % [sword_mode_text, bullet_time_text, debug_mode_text]
	energy_label.modulate = Color.WHITE
	if array_energy_warning_display > 0.0:
		var warning_color: Color = COLORS["energy"].lerp(
			COLORS["health"],
			0.44 if array_energy_forecast_level >= ArrayEnergyForecastLevel.CRITICAL or array_energy_break_timer > 0.0 else 0.18
		)
		var warning_pulse: float = 0.28 + 0.28 * absf(sin(elapsed_time * 12.0))
		energy_label.modulate = energy_label.modulate.lerp(
			warning_color,
			(0.14 + warning_pulse) * clampf(array_energy_warning_display, 0.0, 1.0)
		)
	if energy_feedback_timer > 0.0:
		var energy_feedback_strength: float = clampf(energy_feedback_timer / ACTION_FAILURE_FLASH_DURATION, 0.0, 1.0)
		energy_label.modulate = energy_label.modulate.lerp(
			energy_feedback_color,
			(0.45 + 0.35 * absf(sin(elapsed_time * 22.0))) * energy_feedback_strength
		)
	score_label.modulate = Color.WHITE
	if array_feedback_timer > 0.0:
		var array_feedback_strength: float = clampf(array_feedback_timer / ACTION_FAILURE_FLASH_DURATION, 0.0, 1.0)
		score_label.modulate = score_label.modulate.lerp(
			array_feedback_color,
			(0.45 + 0.35 * absf(sin(elapsed_time * 22.0))) * array_feedback_strength
		)
	status_label.text = status_message
	status_label.modulate = status_message_color
	focus_status_label.visible = focus_status_message_timer > 0.0 and focus_status_message != ""
	if focus_status_label.visible:
		focus_status_label.text = focus_status_message
		var label_alpha: float = clampf(focus_status_message_timer / FOCUS_STATUS_DURATION, 0.0, 1.0)
		var label_pulse: float = 0.7 + 0.3 * absf(sin(elapsed_time * 18.0))
		var focus_color: Color = focus_status_message_color.lerp(Color.WHITE, 0.1 * label_pulse)
		focus_color.a = 0.5 + 0.5 * label_alpha
		focus_status_label.modulate = focus_color
		var focus_label_size: Vector2 = focus_status_label.size
		if focus_label_size.x <= 0.0 or focus_label_size.y <= 0.0:
			focus_label_size = Vector2(240.0, 32.0)
		var viewport_size: Vector2 = get_viewport_rect().size
		var focus_anchor: Vector2 = _to_screen(player["pos"]) + Vector2(0.0, - (PLAYER_RADIUS + FOCUS_STATUS_Y_OFFSET))
		var focus_position: Vector2 = focus_anchor + Vector2(-focus_label_size.x * 0.5, 0.0)
		focus_position.x = clampf(focus_position.x, 0.0, viewport_size.x - focus_label_size.x)
		focus_position.y = clampf(focus_position.y, ARENA_ORIGIN.y - 28.0, viewport_size.y - focus_label_size.y)
		focus_status_label.position = focus_position
	else:
		focus_status_label.text = ""
	if debug_calibration_mode:
		hint_label.text = "校准模式 | WASD 移动 | 中键拖拽玩家 | 1~4 记录距离 | P 保存 | L 读取 | R 重置 | F6 退出"
	elif debug_battle_mode:
		hint_label.text = "战斗调试 | 1 无限生命 | 2 无限剑意 | 3 一击击杀 | 4 停刷怪 | 5 清敌弹 | F7 退出 | F6 校准"
	else:
		hint_label.text = "WASD 移动 | 左键 挥剑/长按维持剑阵 | 右键 御剑点刺或连斩 | F7 战斗调试 | F6 校准调试"
	game_over_label.text = "力竭身亡\n最终得分 %d  波次 %d\n左键重新开始" % [score, wave]


func _get_lookdev_mode_label() -> String:
	match lookdev_preview_mode:
		LookdevPreviewMode.SLICE:
			return "连斩"
		LookdevPreviewMode.RECALL:
			return "回收"
		_:
			return "点刺"


func _create_lookdev_control_panel() -> void:
	if lookdev_control_panel != null:
		lookdev_control_panel.queue_free()
	lookdev_slider_rows.clear()

	lookdev_control_panel = PanelContainer.new()
	lookdev_control_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(lookdev_control_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 12)
	panel_margin.add_theme_constant_override("margin_top", 12)
	panel_margin.add_theme_constant_override("margin_right", 12)
	panel_margin.add_theme_constant_override("margin_bottom", 12)
	lookdev_control_panel.add_child(panel_margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_margin.add_child(scroll)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(root_vbox)

	var title := Label.new()
	title.text = "御剑特效实时调参"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("f1e3bc"))
	root_vbox.add_child(title)

	var sub_title := Label.new()
	sub_title.text = "这里拖动，直接影响真实 Main 预览"
	sub_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_title.add_theme_font_size_override("font_size", 13)
	sub_title.add_theme_color_override("font_color", Color("9cb0c2"))
	root_vbox.add_child(sub_title)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	root_vbox.add_child(button_row)

	lookdev_reset_button = Button.new()
	lookdev_reset_button.text = "恢复推荐值"
	lookdev_reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lookdev_reset_button.pressed.connect(_reset_lookdev_vfx_profile)
	button_row.add_child(lookdev_reset_button)

	lookdev_save_preview_button = Button.new()
	lookdev_save_preview_button.text = "保存预览"
	lookdev_save_preview_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lookdev_save_preview_button.pressed.connect(_save_lookdev_profile_to_preview_resource)
	button_row.add_child(lookdev_save_preview_button)

	lookdev_save_game_button = Button.new()
	lookdev_save_game_button.text = "保存到主游戏"
	lookdev_save_game_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lookdev_save_game_button.pressed.connect(_save_lookdev_profile_to_game_resource)
	root_vbox.add_child(lookdev_save_game_button)

	for group_spec in LOOKDEV_CONTROLS:
		var group_label := Label.new()
		group_label.text = str(group_spec["title"])
		group_label.add_theme_font_size_override("font_size", 16)
		group_label.add_theme_color_override("font_color", Color("d7bb79"))
		root_vbox.add_child(group_label)
		for item in group_spec["items"]:
			var row := _create_lookdev_slider_row(item)
			root_vbox.add_child(row["container"])
			lookdev_slider_rows.append(row)

	_sync_lookdev_slider_rows_from_profile()
	_layout_lookdev_control_panel()


func _create_lookdev_slider_row(spec: Dictionary) -> Dictionary:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	container.add_child(title_row)

	var name_label := Label.new()
	name_label.text = str(spec["label"])
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color("e7dec3"))
	title_row.add_child(name_label)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(60.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", Color("88d8ff"))
	title_row.add_child(value_label)

	var slider := HSlider.new()
	slider.min_value = float(spec["min"])
	slider.max_value = float(spec["max"])
	slider.step = float(spec["step"])
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_lookdev_slider_value_changed.bind(String(spec["prop"]), value_label, float(spec["step"])))
	container.add_child(slider)

	return {
		"container": container,
		"slider": slider,
		"value_label": value_label,
		"prop": String(spec["prop"]),
		"step": float(spec["step"]),
	}


func _sync_lookdev_slider_rows_from_profile() -> void:
	var profile: SwordVfxProfile = get_sword_vfx_profile()
	for row_variant in lookdev_slider_rows:
		var row: Dictionary = row_variant
		var prop: String = str(row["prop"])
		var slider: HSlider = row["slider"]
		var value_label: Label = row["value_label"]
		var step: float = float(row["step"])
		var value: float = float(profile.get(prop))
		slider.set_block_signals(true)
		slider.value = value
		slider.set_block_signals(false)
		value_label.text = _format_lookdev_slider_value(value, step)


func _on_lookdev_slider_value_changed(value: float, prop: String, value_label: Label, step: float) -> void:
	get_sword_vfx_profile().set(prop, value)
	value_label.text = _format_lookdev_slider_value(value, step)


func _format_lookdev_slider_value(value: float, step: float) -> String:
	if step >= 1.0:
		return str(int(round(value)))
	if step >= 0.1:
		return "%.1f" % value
	if step >= 0.01:
		return "%.2f" % value
	return "%.3f" % value


func _reset_lookdev_vfx_profile() -> void:
	sword_vfx_profile = lookdev_source_sword_vfx_profile.duplicate(true)
	_sync_lookdev_slider_rows_from_profile()
	_show_status_message("已恢复推荐值", Color("d7bb79"), 1.2)


func _save_lookdev_profile_to_preview_resource() -> void:
	var preview_path: String = lookdev_source_sword_vfx_profile.resource_path
	_save_current_lookdev_profile(preview_path, "已保存到预览配置")


func _save_lookdev_profile_to_game_resource() -> void:
	var game_path: String = DEFAULT_SWORD_VFX_PROFILE.resource_path
	_save_current_lookdev_profile(game_path, "已保存到主游戏默认配置")


func _save_current_lookdev_profile(target_path: String, success_message: String) -> void:
	if target_path == "":
		_show_status_message("保存失败：目标路径为空", COLORS["health"], 1.8)
		push_error("Lookdev save failed: empty target path.")
		return
	var save_profile: SwordVfxProfile = get_sword_vfx_profile().duplicate(true)
	var save_error: Error = ResourceSaver.save(save_profile, target_path)
	if save_error != OK:
		_show_status_message("保存失败：%s" % str(save_error), COLORS["health"], 2.0)
		push_error("Lookdev save failed for %s: %s" % [target_path, save_error])
		return
	if target_path == lookdev_source_sword_vfx_profile.resource_path:
		lookdev_source_sword_vfx_profile = save_profile
	_show_status_message(success_message, Color("88d8ff"), 1.6)


func _layout_lookdev_control_panel() -> void:
	if lookdev_control_panel == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_width: float = minf(LOOKDEV_PANEL_TARGET_WIDTH, viewport_size.x * 0.28)
	panel_width = maxf(panel_width, 220.0)
	lookdev_control_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lookdev_control_panel.anchor_left = 1.0
	lookdev_control_panel.anchor_right = 1.0
	lookdev_control_panel.anchor_top = 0.0
	lookdev_control_panel.anchor_bottom = 1.0
	lookdev_control_panel.offset_left = -panel_width - LOOKDEV_PANEL_MARGIN
	lookdev_control_panel.offset_right = -LOOKDEV_PANEL_MARGIN
	lookdev_control_panel.offset_top = 88.0
	lookdev_control_panel.offset_bottom = -LOOKDEV_PANEL_MARGIN


func _format_distance_delta(delta: float) -> String:
	if is_zero_approx(delta):
		return "0"
	return "%+.0f" % delta


func _get_sword_array_mode() -> String:
	return SwordArrayController.get_mode(self )


func _get_sword_array_direction(fire_index: int, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	return SwordArrayController.get_fire_direction(self , _get_sword_array_fire_state(), fire_index, volley_count, burst_step, total_count)


func _get_sword_array_target(fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	return SwordArrayController.get_fire_target(self , _get_sword_array_fire_state(), fire_index, bullet_pos, volley_count, burst_step, total_count)


func _update_boss(delta: float, bullet_time_delta: float) -> void:
	GameBossController.update_boss(self , delta, bullet_time_delta)


func _draw_boss() -> void:
	GameBossController.draw_boss(self )


func _draw_boss_world() -> void:
	GameBossController.draw_boss_world(self )


func _draw_boss_hud() -> void:
	GameBossController.draw_boss_hud(self )


func _update_boss_silks(delta: float) -> void:
	GameBossController._update_boss_silks(self , delta)


func _update_silk_damage(delta: float) -> void:
	GameBossController.update_silk_damage(self , delta)


func _choose_next_boss_state() -> void:
	GameBossController._choose_next_boss_state(self )


func _spawn_boss() -> void:
	GameBossController.spawn_boss(self )


func _spawn_puppets(count: int) -> void:
	GameBossController.spawn_puppets(self , count)


func _count_active_silks() -> int:
	return GameBossController.count_active_silks(self )


func _is_silk_active(enemy_id: String) -> bool:
	return GameBossController.is_silk_active(self , enemy_id)


func _find_enemy_by_id(enemy_id: String) -> Variant:
	return GameBossController.find_enemy_by_id(self , enemy_id)


func _resolve_silk_binding(silk_id: String) -> Dictionary:
	return GameBossController.resolve_silk_binding(self , silk_id)


func _register_hurtbox_descriptor(descriptor: Dictionary) -> void:
	hurtbox_registry.register_descriptor(descriptor)


func _register_hurtbox_descriptors(descriptors: Array) -> void:
	hurtbox_registry.register_descriptors(descriptors)


func _clear_target_hurtboxes(target_id: String) -> void:
	hurtbox_registry.clear_target(target_id)


func _get_hurtbox_descriptor(hurtbox_id: String) -> Dictionary:
	return hurtbox_registry.get_descriptor(hurtbox_id)


func _resolve_target_hurtbox_descriptor(target_id: String, descriptor_role := TargetDescriptors.ROLE_PRIMARY, active_states: Array = []) -> Dictionary:
	return hurtbox_registry.select_descriptor(target_id, descriptor_role, active_states)


func _get_enemy_primary_hurtbox(enemy: Dictionary) -> Dictionary:
	return _resolve_target_hurtbox_descriptor(str(enemy.get("id", "")))


func _get_target_primary_hurtbox(target_id: String, active_states: Array = []) -> Dictionary:
	return _resolve_target_hurtbox_descriptor(target_id, TargetDescriptors.ROLE_PRIMARY, active_states)


func _build_target_hurtbox_descriptors(source_data: Dictionary, provider_id := "") -> Array:
	var context := {}
	if provider_id != "":
		context["provider_id"] = provider_id
	return target_descriptor_registry.build_descriptors(source_data, context)


func _register_target_hurtboxes(source_data: Dictionary, provider_id := "") -> void:
	var descriptors: Array = _build_target_hurtbox_descriptors(source_data, provider_id)
	if descriptors.is_empty():
		return
	_register_hurtbox_descriptors(descriptors)


func _kill_enemy_by_id(enemy_id: String) -> void:
	GameBossController.kill_enemy_by_id(self , enemy_id)


func _has_boss() -> bool:
	return GameBossController.has_boss(self )


func _to_screen(world_pos: Vector2) -> Vector2:
	return ARENA_ORIGIN + world_pos


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - ARENA_ORIGIN).clamp(Vector2.ZERO, ARENA_SIZE)


func _roll_spawn_position() -> Vector2:
	var roll: float = randf()
	if roll < 0.5:
		return Vector2(randf_range(0.0, ARENA_SIZE.x), -SPAWN_MARGIN)
	if roll < 0.75:
		return Vector2(ARENA_SIZE.x + SPAWN_MARGIN, randf_range(0.0, ARENA_SIZE.y))
	return Vector2(-SPAWN_MARGIN, randf_range(0.0, ARENA_SIZE.y))


func _roll_enemy_type() -> String:
	var enemy_weights := [
		{"type": SHOOTER, "weight": 0.44},
		{"type": TANK, "weight": 0.2},
		{"type": CASTER, "weight": 0.16},
		{"type": HEAVY, "weight": 0.11},
	]
	if wave >= 2:
		enemy_weights.append({"type": RING_LEECH, "weight": 0.16})
	if wave >= 3:
		enemy_weights.append({"type": DRAPE_PRIEST, "weight": 0.05})
	if wave >= 4:
		enemy_weights.append({"type": MIRROR_NEEDLER, "weight": 0.06})
	return _roll_weighted_enemy_type(enemy_weights)


func _make_enemy_spawn_entry(enemy_type: String) -> Dictionary:
	return {
		"kind": SPAWN_ENTRY_ENEMY,
		"enemy_type": enemy_type,
		"cost": 1,
	}


func _make_package_spawn_entry(package_type: String, cost: int, extra := {}) -> Dictionary:
	var entry := {
		"kind": SPAWN_ENTRY_PACKAGE,
		"package_type": package_type,
		"cost": max(cost, 1),
	}
	for key_variant in extra.keys():
		entry[key_variant] = extra[key_variant]
	return entry


func _make_ring_leech_package_entry(member_count := RING_LEECH_PACKAGE_DEFAULT_COUNT) -> Dictionary:
	var resolved_count: int = clampi(member_count, RING_LEECH_PACKAGE_MIN_COUNT, RING_LEECH_PACKAGE_MAX_COUNT)
	return _make_package_spawn_entry(
		ENEMY_PACKAGE_RING_LEECH_CLOSE,
		resolved_count,
		{
			"member_count": resolved_count,
		}
	)


func _get_spawn_entry_cost(entry_variant: Variant) -> int:
	if typeof(entry_variant) == TYPE_DICTIONARY:
		return max(int((entry_variant as Dictionary).get("cost", 1)), 1)
	return 1


func _roll_spawn_entry(remaining_enemy_count: int, wave_index := wave) -> Dictionary:
	if wave_index >= 3 and remaining_enemy_count >= RING_LEECH_PACKAGE_MIN_COUNT:
		var package_chance: float = 0.1
		if wave_index >= 5:
			package_chance = 0.14
		if randf() < package_chance:
			var max_member_count: int = mini(remaining_enemy_count, RING_LEECH_PACKAGE_MAX_COUNT)
			var min_member_count: int = mini(RING_LEECH_PACKAGE_MIN_COUNT, max_member_count)
			return _make_ring_leech_package_entry(randi_range(min_member_count, max_member_count))
	return _make_enemy_spawn_entry(_roll_enemy_type())


func _spawn_ring_leech_package(entry: Dictionary) -> int:
	var member_count: int = clampi(
		int(entry.get("member_count", RING_LEECH_PACKAGE_DEFAULT_COUNT)),
		RING_LEECH_PACKAGE_MIN_COUNT,
		RING_LEECH_PACKAGE_MAX_COUNT
	)
	if member_count <= 0:
		return 0
	var package_center: Vector2 = Vector2(player.get("pos", ARENA_SIZE * 0.5))
	var rotation_angle: float = randf_range(-PI, PI)
	var rotation_direction: float = 1.0 if randf() < 0.5 else -1.0
	var package_id: String = _next_id("enemy_package")
	var package := {
		"id": package_id,
		"type": ENEMY_PACKAGE_RING_LEECH_CLOSE,
		"phase": ENEMY_PACKAGE_PHASE_ASSEMBLE,
		"phase_timer": RING_LEECH_PACKAGE_ASSEMBLE_DURATION,
		"center": package_center,
		"rotation_angle": rotation_angle,
		"rotation_direction": rotation_direction,
		"slot_count": member_count,
		"initial_member_count": member_count,
		"current_radius": RING_LEECH_PACKAGE_SPAWN_RADIUS,
		"break_member_threshold": max(member_count - 2, RING_LEECH_PACKAGE_BREAK_MEMBER_THRESHOLD),
		"member_ids": [],
	}
	var slot_index: int = 0
	while slot_index < member_count:
		var enemy: Dictionary = _spawn_enemy(RING_LEECH)
		var spawn_pos: Vector2 = _get_ring_leech_package_slot_position(
			package_center,
			rotation_angle,
			member_count,
			slot_index,
			RING_LEECH_PACKAGE_SPAWN_RADIUS
		)
		enemy["pos"] = spawn_pos
		enemy["shoot_cooldown"] = RING_LEECH_COOLDOWN * float(slot_index) / float(max(member_count, 1)) + randf_range(0.0, 0.18)
		enemy["orbit_angle"] = (spawn_pos - package_center).angle()
		enemy["orbit_direction"] = rotation_direction
		enemy["package_id"] = package_id
		enemy["package_type"] = ENEMY_PACKAGE_RING_LEECH_CLOSE
		enemy["package_phase"] = ENEMY_PACKAGE_PHASE_ASSEMBLE
		enemy["package_slot_index"] = slot_index
		enemy["package_slot_count"] = member_count
		enemy["package_desired_pos"] = spawn_pos
		enemy["package_center"] = package_center
		enemy["package_radius"] = RING_LEECH_PACKAGE_SPAWN_RADIUS
		enemy["package_fire_enabled"] = false
		enemy["package_speed_multiplier"] = 0.9
		package["member_ids"].append(str(enemy.get("id", "")))
		slot_index += 1
	enemy_packages[package_id] = package
	return member_count


func _spawn_enemy_package(entry: Dictionary) -> int:
	match str(entry.get("package_type", "")):
		ENEMY_PACKAGE_RING_LEECH_CLOSE:
			return _spawn_ring_leech_package(entry)
	return 0


func _spawn_wave_entry(entry_variant: Variant) -> int:
	if typeof(entry_variant) != TYPE_DICTIONARY:
		_spawn_enemy(str(entry_variant))
		return 1
	var entry: Dictionary = entry_variant
	match str(entry.get("kind", SPAWN_ENTRY_ENEMY)):
		SPAWN_ENTRY_PACKAGE:
			var spawned_count: int = _spawn_enemy_package(entry)
			if spawned_count > 0:
				return spawned_count
	_spawn_enemy(str(entry.get("enemy_type", SHOOTER)))
	return 1


func _prepare_wave_spawn_queue() -> void:
	wave_spawn_queue = _build_wave_spawn_queue(wave, enemies_to_spawn)


func _build_wave_spawn_queue(wave_index: int, enemy_count: int) -> Array:
	var queue: Array = []
	if enemy_count <= 0:
		return queue
	var remaining_enemy_count: int = enemy_count
	match wave_index:
		2:
			if remaining_enemy_count >= RING_LEECH_PACKAGE_DEFAULT_COUNT:
				var leech_ring_entry: Dictionary = _make_ring_leech_package_entry(RING_LEECH_PACKAGE_DEFAULT_COUNT)
				queue.append(leech_ring_entry)
				remaining_enemy_count -= _get_spawn_entry_cost(leech_ring_entry)
			if remaining_enemy_count > 0:
				queue.append(_make_enemy_spawn_entry(SHOOTER))
				remaining_enemy_count -= 1
		3:
			for enemy_type in [DRAPE_PRIEST, TANK, SHOOTER]:
				if remaining_enemy_count <= 0:
					break
				queue.append(_make_enemy_spawn_entry(str(enemy_type)))
				remaining_enemy_count -= 1
		4:
			for enemy_type in [MIRROR_NEEDLER, SHOOTER, HEAVY]:
				if remaining_enemy_count <= 0:
					break
				queue.append(_make_enemy_spawn_entry(str(enemy_type)))
				remaining_enemy_count -= 1
	while remaining_enemy_count > 0:
		var next_entry: Dictionary = _roll_spawn_entry(remaining_enemy_count, wave_index)
		var next_cost: int = min(_get_spawn_entry_cost(next_entry), remaining_enemy_count)
		if next_cost <= 0:
			next_entry = _make_enemy_spawn_entry(SHOOTER)
			next_cost = 1
		queue.append(next_entry)
		remaining_enemy_count -= next_cost
	return queue


func _roll_weighted_enemy_type(weighted_entries: Array) -> String:
	var total_weight := 0.0
	for entry_variant in weighted_entries:
		var entry: Dictionary = entry_variant
		total_weight += maxf(float(entry.get("weight", 0.0)), 0.0)
	if total_weight <= 0.0:
		return SHOOTER
	var roll: float = randf() * total_weight
	var running_weight := 0.0
	for entry_variant in weighted_entries:
		var entry: Dictionary = entry_variant
		running_weight += maxf(float(entry.get("weight", 0.0)), 0.0)
		if roll <= running_weight:
			return str(entry.get("type", SHOOTER))
	return str(weighted_entries.back().get("type", SHOOTER))


func _is_inside_extended_bounds(position: Vector2) -> bool:
	return position.x >= -SPAWN_MARGIN and position.x <= ARENA_SIZE.x + SPAWN_MARGIN and position.y >= -SPAWN_MARGIN and position.y <= ARENA_SIZE.y + SPAWN_MARGIN


func _next_id(prefix: String) -> String:
	id_counter += 1
	return "%s_%d" % [prefix, id_counter]


func _reset_combat_runtime() -> void:
	hit_registry = HitRegistry.new()
	hurtbox_registry = HurtboxRegistry.new()
	damage_resolver = DamageResolver.new()
	hit_detection = HitDetection.new()
	combat_runtime = {
		"attack_instances": {},
		"target_states": {},
	}


func _get_attack_profile(profile_id: String) -> Dictionary:
	return AttackProfiles.get_profile(profile_id)


func _get_target_profile(profile_id: String) -> Dictionary:
	return TargetProfiles.get_profile(profile_id)


func _register_enemy_hurtboxes(enemy: Dictionary) -> void:
	_register_target_hurtboxes(enemy, TargetDescriptorRegistry.PROVIDER_ENEMY)


func _register_boss_hurtboxes() -> void:
	if not _has_boss():
		return
	_register_target_hurtboxes(boss, TargetDescriptorRegistry.PROVIDER_BOSS)


func _register_silk_hurtbox(silk: Dictionary) -> void:
	_register_target_hurtboxes(silk, TargetDescriptorRegistry.PROVIDER_SILK_SEGMENT)


func _is_boss_core_open() -> bool:
	return _has_boss() and (bool(boss.get("is_vulnerable", false)) or int(boss.get("phase", 0)) == 1)


func _get_boss_hit_context(attack_profile_id := "", damage_source := DAMAGE_SOURCE_NONE) -> Dictionary:
	var active_states: Array = []
	var target_state := ""
	if _is_boss_core_open() or _should_bypass_boss_window(attack_profile_id, damage_source):
		active_states.append("vulnerable")
		target_state = "vulnerable"
	var descriptor: Dictionary = _resolve_target_hurtbox_descriptor("boss", TargetDescriptors.ROLE_PRIMARY, active_states)
	if descriptor.is_empty():
		var fallback_descriptors: Array = _build_target_hurtbox_descriptors(boss, TargetDescriptorRegistry.PROVIDER_BOSS)
		if not fallback_descriptors.is_empty():
			descriptor = fallback_descriptors[0]
		else:
			descriptor = TargetDescriptors.build_boss_body(boss)
	return {
		"target_id": "boss",
		"hurtbox_id": str(descriptor.get("hurtbox_id", "boss:body")),
		"target_profile_id": str(descriptor.get("target_profile_id", TargetProfiles.PROFILE_BOSS_BODY)),
		"target_state": target_state,
		"descriptor": descriptor,
	}


func _should_bypass_boss_window(attack_profile_id: String, _damage_source := DAMAGE_SOURCE_NONE) -> bool:
	if attack_profile_id == "":
		return false
	var attack_profile: Dictionary = _get_attack_profile(attack_profile_id)
	return str(attack_profile.get("boss_window_mode", AttackProfiles.BOSS_WINDOW_GATED)) == AttackProfiles.BOSS_WINDOW_BYPASS


func _open_boss_vulnerability_window(duration: float, show_feedback := true) -> bool:
	if not _has_boss() or duration <= 0.0 or float(boss.get("health", 0.0)) <= 0.0:
		return false
	var was_vulnerable: bool = bool(boss.get("is_vulnerable", false))
	boss["is_vulnerable"] = true
	boss["vulnerable_timer"] = maxf(float(boss.get("vulnerable_timer", 0.0)), duration)
	if show_feedback and not was_vulnerable:
		_create_particles(boss["pos"], COLORS["boss_vulnerable"], 18)
		_show_status_message("破绽显现", COLORS["boss_vulnerable"], 0.6)
	return true


func _get_target_runtime_state_key(target_id: String, target_profile_id: String) -> String:
	return "%s::%s" % [target_id, target_profile_id]


func _ensure_target_runtime_state(target_id: String, target_profile_id: String, target_profile: Dictionary) -> Dictionary:
	var target_states: Dictionary = combat_runtime.get("target_states", {})
	var state_key: String = _get_target_runtime_state_key(target_id, target_profile_id)
	if not target_states.has(state_key):
		var max_poise: float = maxf(float(target_profile.get("max_poise", 0.0)), 0.0)
		var initial_state := {
			"target_id": target_id,
			"target_profile_id": target_profile_id,
			"current_poise": max_poise,
			"last_poise_hit_time": - 1000000.0,
			"last_poise_eval_time": elapsed_time,
			"poise_broken_until": 0.0,
		}
		target_states[state_key] = target_event_system.prime_target_state(initial_state)
		combat_runtime["target_states"] = target_states
	return target_event_system.prime_target_state(target_states[state_key])


func _store_target_runtime_state(target_id: String, target_profile_id: String, target_state: Dictionary) -> void:
	var target_states: Dictionary = combat_runtime.get("target_states", {})
	target_states[_get_target_runtime_state_key(target_id, target_profile_id)] = target_state
	combat_runtime["target_states"] = target_states


func _clear_target_runtime_state(target_id: String, target_profile_id := "") -> void:
	if target_id == "":
		return
	var target_states: Dictionary = combat_runtime.get("target_states", {})
	if target_profile_id == "":
		var state_prefix: String = "%s::" % [target_id]
		var erase_keys: Array = []
		for state_key_variant in target_states.keys():
			var state_key: String = str(state_key_variant)
			if state_key.begins_with(state_prefix):
				erase_keys.append(state_key)
		for erase_key_variant in erase_keys:
			target_states.erase(str(erase_key_variant))
	else:
		target_states.erase(_get_target_runtime_state_key(target_id, str(target_profile_id)))
	combat_runtime["target_states"] = target_states


func _resolve_target_binding(target_id: String, target_profile_id: String, target_profile: Dictionary) -> Dictionary:
	return target_writeback_adapters.resolve_binding(self , target_id, target_profile_id, target_profile)


func _apply_target_binding_resource(target_binding: Dictionary, amount: float, damage_source := DAMAGE_SOURCE_NONE) -> Dictionary:
	return target_writeback_adapters.apply(self , target_binding, amount, damage_source)


func _refresh_target_poise_state(target_state: Dictionary, target_profile: Dictionary) -> Dictionary:
	var max_poise: float = maxf(float(target_profile.get("max_poise", 0.0)), 0.0)
	if max_poise <= 0.0:
		target_state["current_poise"] = 0.0
		target_state["last_poise_eval_time"] = elapsed_time
		return target_state
	var current_poise: float = clampf(float(target_state.get("current_poise", max_poise)), 0.0, max_poise)
	var poise_broken_until: float = float(target_state.get("poise_broken_until", 0.0))
	if elapsed_time < poise_broken_until:
		target_state["current_poise"] = 0.0
		target_state["last_poise_eval_time"] = elapsed_time
		return target_state
	if poise_broken_until > 0.0:
		target_state["poise_broken_until"] = 0.0
	var poise_recovery_rate: float = maxf(float(target_profile.get("poise_recovery_rate", 0.0)), 0.0)
	var poise_recovery_delay: float = maxf(float(target_profile.get("poise_recovery_delay", 0.0)), 0.0)
	var last_poise_hit_time: float = float(target_state.get("last_poise_hit_time", -1000000.0))
	var recovery_start: float = last_poise_hit_time + poise_recovery_delay
	var last_poise_eval_time: float = float(target_state.get("last_poise_eval_time", recovery_start))
	var recover_from: float = maxf(last_poise_eval_time, recovery_start)
	if poise_recovery_rate > 0.0 and elapsed_time > recover_from and current_poise < max_poise:
		current_poise = minf(current_poise + (elapsed_time - recover_from) * poise_recovery_rate, max_poise)
	target_state["current_poise"] = current_poise
	target_state["last_poise_eval_time"] = elapsed_time
	return target_state


func _apply_target_response(
	target_binding: Dictionary,
	hit_result: Dictionary,
	writeback_result: Dictionary,
	damage_source := DAMAGE_SOURCE_NONE
) -> Dictionary:
	var target_id: String = str(target_binding.get("target_id", ""))
	var target_profile_id: String = str(target_binding.get("target_profile_id", ""))
	var target_profile: Dictionary = target_binding.get("target_profile", {})
	var response_events: Array = []
	var result := {
		"poise_applied": 0.0,
		"poise_before": 0.0,
		"poise_after": 0.0,
		"response_events": response_events,
		"response_event_names": [],
		"applied_response_events": [],
		"applied_response_event_names": [],
	}
	var max_poise: float = maxf(float(target_profile.get("max_poise", 0.0)), 0.0)
	var applied_channels: Dictionary = hit_result.get("applied_channels", {})
	var poise_amount: float = maxf(float(applied_channels.get(AttackProfiles.CHANNEL_POISE, 0.0)), 0.0)
	var target_state: Dictionary = _ensure_target_runtime_state(target_id, target_profile_id, target_profile)
	target_state = target_event_system.prime_target_state(target_state)
	var base_event_payload: Dictionary = target_event_system.build_base_payload(
		target_binding,
		target_profile,
		hit_result,
		writeback_result,
		damage_source
	)
	if max_poise > 0.0:
		target_state = _refresh_target_poise_state(target_state, target_profile)
		var poise_before: float = float(target_state.get("current_poise", max_poise))
		result["poise_before"] = poise_before
		if poise_amount > 0.0:
			result["poise_applied"] = poise_amount
			if elapsed_time < float(target_state.get("poise_broken_until", 0.0)):
				target_state["last_poise_hit_time"] = elapsed_time
				target_state["last_poise_eval_time"] = elapsed_time
			else:
				var poise_after: float = maxf(poise_before - poise_amount, 0.0)
				target_state["current_poise"] = poise_after
				target_state["last_poise_hit_time"] = elapsed_time
				target_state["last_poise_eval_time"] = elapsed_time
				if poise_after <= 0.0:
					var break_duration: float = maxf(float(target_profile.get("break_duration", 0.0)), 0.0)
					target_state["poise_broken_until"] = elapsed_time + break_duration
					var poise_event_payload: Dictionary = base_event_payload.duplicate(true)
					poise_event_payload["poise_damage"] = poise_amount
					poise_event_payload["poise_before"] = poise_before
					poise_event_payload["poise_after"] = poise_after
					poise_event_payload["break_duration"] = break_duration
					for event_variant in target_profile.get("poise_break_events", []):
						target_event_system.append_event_record(
							response_events,
							event_variant,
							poise_event_payload,
							{
								"trigger": "poise_break",
								"poise_before": poise_before,
								"poise_after": poise_after,
								"break_duration": break_duration,
							}
						)
		result["poise_after"] = float(target_state.get("current_poise", poise_before))
	var event_collection_result: Dictionary = target_event_system.collect_events(
		target_binding,
		target_profile,
		hit_result,
		writeback_result,
		target_state,
		damage_source
	)
	target_state = event_collection_result.get("target_state", target_state)
	for event_variant in event_collection_result.get("events", []):
		target_event_system.append_event_record(response_events, event_variant)
	_store_target_runtime_state(target_id, target_profile_id, target_state)
	var event_result: Dictionary = target_event_system.dispatch_events(self , target_binding, target_profile, response_events)
	result["response_events"] = response_events
	result["response_event_names"] = target_event_system.list_event_names(response_events)
	result["applied_response_events"] = event_result.get("applied_response_events", [])
	result["applied_response_event_names"] = event_result.get("applied_response_event_names", [])
	return result


func _apply_hit_result_to_target(target_id: String, target_profile_id: String, hit_result: Dictionary, damage_source := DAMAGE_SOURCE_NONE) -> Dictionary:
	var result := {
		"target_found": false,
		"target_kind": "",
		"applied": false,
		"amount": 0.0,
		"killed": false,
		"pool_key": "",
		"resource_channel": "",
		"poise_applied": 0.0,
		"poise_before": 0.0,
		"poise_after": 0.0,
		"response_events": [],
		"response_event_names": [],
		"applied_response_events": [],
		"applied_response_event_names": [],
	}
	if not bool(hit_result.get("allowed", false)):
		return result
	var target_profile: Dictionary = _get_target_profile(target_profile_id)
	var target_binding: Dictionary = _resolve_target_binding(target_id, target_profile_id, target_profile)
	var pool_key: String = str(target_binding.get("pool_key", ""))
	var resource_channel: String = str(target_binding.get("resource_channel", AttackProfiles.CHANNEL_HP))
	var applied_channels: Dictionary = hit_result.get("applied_channels", {})
	var amount: float = maxf(float(applied_channels.get(resource_channel, 0.0)), 0.0)
	result["pool_key"] = pool_key
	result["resource_channel"] = resource_channel
	result["target_kind"] = str(target_binding.get("target_kind", ""))
	var writeback_result: Dictionary = _apply_target_binding_resource(target_binding, amount, damage_source)
	writeback_result["pool_key"] = pool_key
	writeback_result["resource_channel"] = resource_channel
	result["target_found"] = bool(writeback_result.get("target_found", false))
	result["applied"] = bool(writeback_result.get("applied", false))
	result["amount"] = float(writeback_result.get("amount", 0.0))
	result["killed"] = bool(writeback_result.get("killed", false))
	if not bool(result.get("target_found", false)):
		return result
	var response_result: Dictionary = _apply_target_response(target_binding, hit_result, writeback_result, damage_source)
	var applied_response_events: Array = response_result.get("applied_response_events", [])
	result["poise_applied"] = float(response_result.get("poise_applied", 0.0))
	result["poise_before"] = float(response_result.get("poise_before", 0.0))
	result["poise_after"] = float(response_result.get("poise_after", 0.0))
	result["response_events"] = response_result.get("response_events", [])
	result["response_event_names"] = response_result.get("response_event_names", [])
	result["applied_response_events"] = applied_response_events
	result["applied_response_event_names"] = response_result.get("applied_response_event_names", [])
	result["applied"] = bool(result.get("applied", false)) or float(result.get("poise_applied", 0.0)) > 0.0 or not applied_response_events.is_empty()
	return result


func _apply_target_hit_feedback(
	target_id: String,
	_target_profile_id: String,
	contact_point: Vector2,
	attack_profile_id: String,
	damage_source: String,
	_hit_result: Dictionary,
	apply_result: Dictionary
) -> void:
	if not bool(apply_result.get("target_found", false)):
		return
	if not bool(apply_result.get("applied", false)):
		return
	var target_kind: String = str(apply_result.get("target_kind", ""))
	if damage_source == DAMAGE_SOURCE_FLYING_SWORD:
		var should_emit_self_hit_feedback: bool = true
		var should_queue_point_hitstop: bool = attack_profile_id == AttackProfiles.PROFILE_FLYING_SWORD_POINT
		if target_kind == "silk":
			should_emit_self_hit_feedback = _consume_silk_contact_self_feedback(target_id, attack_profile_id)
			should_queue_point_hitstop = false
		if should_emit_self_hit_feedback:
			_trigger_sword_self_hit_feedback(contact_point, attack_profile_id, target_kind)
		if should_queue_point_hitstop:
			_queue_point_strike_hitstop_pulse()
	var feedback_color: Color = _resolve_target_hit_feedback_color(target_id, target_kind, attack_profile_id, damage_source)
	match target_kind:
		"enemy":
			var enemy: Variant = _find_enemy_by_id(target_id)
			if enemy != null:
				_apply_enemy_hit_feedback(enemy, contact_point, feedback_color, attack_profile_id)
		"boss":
			_apply_boss_hit_feedback(contact_point, feedback_color, attack_profile_id)
		"silk":
			_mark_silk_contact_feedback(target_id, contact_point, feedback_color, attack_profile_id)


func _resolve_target_hit_feedback_color(_target_id: String, _target_kind: String, _attack_profile_id: String, _damage_source: String) -> Color:
	return Color.WHITE


func _get_hit_feedback_direction(target_pos: Vector2, contact_point: Vector2) -> Vector2:
	var direction: Vector2 = target_pos - contact_point
	if direction.is_zero_approx():
		direction = target_pos - player["pos"]
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	return direction.normalized()


func _resolve_hit_reaction_offset(
	reaction_vector: Vector2,
	reaction_timer: float,
	reaction_duration: float,
	shake_cycles: float
) -> Vector2:
	if reaction_duration <= 0.0 or reaction_timer <= 0.0 or reaction_vector.is_zero_approx():
		return Vector2.ZERO
	var timer_ratio: float = clampf(reaction_timer / reaction_duration, 0.0, 1.0)
	var progress: float = 1.0 - timer_ratio
	var amplitude: float = pow(timer_ratio, HIT_REACTION_DECAY_EXPONENT)
	var wave: float = cos(progress * TAU * shake_cycles)
	if wave < 0.0:
		wave *= HIT_REACTION_BACKSWING_SCALE
	return reaction_vector * amplitude * wave


func _get_target_hit_reaction_distance(attack_profile_id: String, damage_source: String, target_kind: String) -> float:
	var reaction_distance: float = 5.2
	match attack_profile_id:
		AttackProfiles.PROFILE_FLYING_SWORD_POINT:
			reaction_distance = 12.0
		AttackProfiles.PROFILE_FLYING_SWORD_SLICE:
			reaction_distance = 7.8
		AttackProfiles.PROFILE_MELEE_SLASH:
			reaction_distance = 7.0
		AttackProfiles.PROFILE_ARRAY_PIERCE:
			reaction_distance = 5.2
		AttackProfiles.PROFILE_ARRAY_FAN:
			reaction_distance = 4.4
		AttackProfiles.PROFILE_ARRAY_RING:
			reaction_distance = 4.0
		AttackProfiles.PROFILE_DEFLECTED_BULLET:
			reaction_distance = 5.0
		_:
			if damage_source == DAMAGE_SOURCE_MELEE:
				reaction_distance = 6.6
	if target_kind == "boss":
		reaction_distance *= 0.72
	return reaction_distance


func _apply_enemy_hit_feedback(enemy: Dictionary, contact_point: Vector2, feedback_color: Color, attack_profile_id: String) -> void:
	var reaction_vector: Vector2 = _get_hit_feedback_direction(enemy.get("pos", contact_point), contact_point) * _get_target_hit_reaction_distance(
		attack_profile_id,
		str(enemy.get("last_damage_source", DAMAGE_SOURCE_NONE)),
		"enemy"
	) * ENEMY_HIT_REACTION_INTENSITY
	if reaction_vector.length() > ENEMY_HIT_REACTION_MAX_OFFSET:
		reaction_vector = reaction_vector.normalized() * ENEMY_HIT_REACTION_MAX_OFFSET
	enemy["hit_reaction_vector"] = reaction_vector
	enemy["hit_reaction_timer"] = ENEMY_HIT_REACTION_DURATION
	enemy["hit_reaction_offset"] = reaction_vector
	enemy["hit_flash_timer"] = maxf(float(enemy.get("hit_flash_timer", 0.0)), ENEMY_HIT_FLASH_DURATION)
	enemy["hit_flash_color"] = feedback_color
	if bool(enemy.get("is_dying", false)):
		enemy["death_feedback_color"] = feedback_color


func _apply_boss_hit_feedback(contact_point: Vector2, feedback_color: Color, attack_profile_id: String) -> void:
	if not _has_boss():
		return
	var reaction_vector: Vector2 = _get_hit_feedback_direction(boss.get("pos", contact_point), contact_point) * _get_target_hit_reaction_distance(
		attack_profile_id,
		DAMAGE_SOURCE_NONE,
		"boss"
	) * BOSS_HIT_REACTION_INTENSITY
	if reaction_vector.length() > BOSS_HIT_REACTION_MAX_OFFSET:
		reaction_vector = reaction_vector.normalized() * BOSS_HIT_REACTION_MAX_OFFSET
	boss["hit_reaction_vector"] = reaction_vector
	boss["hit_reaction_timer"] = BOSS_HIT_REACTION_DURATION
	boss["hit_reaction_offset"] = reaction_vector
	boss["hit_flash_timer"] = maxf(float(boss.get("hit_flash_timer", 0.0)), BOSS_HIT_FLASH_DURATION)
	boss["hit_flash_color"] = feedback_color


func _mark_silk_contact_feedback(target_id: String, contact_point: Vector2, feedback_color: Color, attack_profile_id: String) -> void:
	if not _has_boss():
		return
	var silk_binding: Dictionary = _resolve_silk_binding(target_id)
	if not bool(silk_binding.get("found", false)):
		return
	var silk_index: int = int(silk_binding.get("index", -1))
	if silk_index < 0 or silk_index >= boss["silks"].size():
		return
	var silk: Dictionary = boss["silks"][silk_index]
	silk["contact_feedback_timer"] = maxf(float(silk.get("contact_feedback_timer", 0.0)), SILK_CONTACT_FEEDBACK_DURATION)
	silk["contact_feedback_pos"] = contact_point
	silk["contact_feedback_color"] = feedback_color
	silk["contact_feedback_is_point"] = attack_profile_id == AttackProfiles.PROFILE_FLYING_SWORD_POINT
	boss["silks"][silk_index] = silk


func _mark_silk_sever_feedback(target_id: String, from_pos: Vector2, to_pos: Vector2, contact_point: Vector2, is_main := false) -> void:
	if not _has_boss():
		return
	var silk_binding: Dictionary = _resolve_silk_binding(target_id)
	if not bool(silk_binding.get("found", false)):
		return
	var silk_index: int = int(silk_binding.get("index", -1))
	if silk_index < 0 or silk_index >= boss["silks"].size():
		return
	var silk: Dictionary = boss["silks"][silk_index]
	silk["cut_feedback_timer"] = SILK_SEVER_FEEDBACK_DURATION
	silk["cut_feedback_from"] = from_pos
	silk["cut_feedback_to"] = to_pos
	silk["cut_feedback_center"] = contact_point
	silk["cut_feedback_is_main"] = is_main
	silk["contact_feedback_timer"] = 0.0
	boss["silks"][silk_index] = silk


func _apply_boss_attack_instance_hit(
	attack_instance_id: String,
	attack_profile_id: String,
	contact_point: Vector2,
	damage_source := DAMAGE_SOURCE_NONE,
	contact_time := 0.0,
	is_currently_overlapping := true,
	hit_request_overrides := {}
) -> Dictionary:
	var result := {
		"allowed": false,
		"blocked_reason": "no_boss",
		"target_profile_id": "",
		"hurtbox_id": "",
		"target_state": "",
		"hit_result": {},
		"apply_result": {},
	}
	if not _has_boss():
		return result
	var bypass_boss_window: bool = _should_bypass_boss_window(attack_profile_id, damage_source)
	if not bypass_boss_window and not _is_boss_core_open():
		result["blocked_reason"] = "boss_window_closed"
		return result
	var boss_hit_context: Dictionary = _get_boss_hit_context(attack_profile_id, damage_source)
	var target_profile_id: String = str(boss_hit_context.get("target_profile_id", TargetProfiles.PROFILE_BOSS_BODY))
	var hurtbox_id: String = str(boss_hit_context.get("hurtbox_id", "boss:body"))
	var target_state: String = str(boss_hit_context.get("target_state", ""))
	var attack_result: Dictionary = _apply_attack_instance_hit_to_target(
		attack_instance_id,
		attack_profile_id,
		contact_point,
		"boss",
		hurtbox_id,
		target_profile_id,
		damage_source,
		contact_time,
		target_state,
		is_currently_overlapping,
		hit_request_overrides
	)
	var hit_result: Dictionary = attack_result.get("hit_result", {})
	result["target_profile_id"] = target_profile_id
	result["hurtbox_id"] = hurtbox_id
	result["target_state"] = target_state
	result["hit_result"] = hit_result
	result["apply_result"] = attack_result.get("apply_result", {})
	result["allowed"] = bool(attack_result.get("allowed", false))
	result["blocked_reason"] = str(attack_result.get("blocked_reason", ""))
	return result


func _build_attack_instance(profile_id: String, owner_id: String, source_node: String, team := "player") -> Dictionary:
	var attack_instance := {
		"id": _next_id("attack"),
		"profile_id": profile_id,
		"owner_id": owner_id,
		"team": team,
		"source_node": source_node,
		"spawn_time": elapsed_time,
		"alive": true,
		"runtime": {},
	}
	combat_runtime["attack_instances"][attack_instance["id"]] = attack_instance
	return attack_instance


func _clear_attack_instance(attack_instance_id: String) -> void:
	if attack_instance_id == "":
		return
	hit_registry.clear_attack_instance(attack_instance_id)
	var attack_instances: Dictionary = combat_runtime.get("attack_instances", {})
	attack_instances.erase(attack_instance_id)
	combat_runtime["attack_instances"] = attack_instances


func _resolve_attack_instance_hit(
	attack_instance_id: String,
	attack_profile_id: String,
	contact_point: Vector2,
	target_id: String,
	hurtbox_id: String,
	target_profile_id: String,
	contact_time := 0.0,
	target_state := "",
	is_currently_overlapping := true,
	hit_request_overrides := {}
) -> Dictionary:
	if attack_instance_id == "" or attack_profile_id == "":
		return {
			"allowed": false,
			"blocked_reason": "no_attack_instance",
		}
	var attack_profile: Dictionary = _get_attack_profile(attack_profile_id)
	var target_profile: Dictionary = _get_target_profile(target_profile_id)
	var hurtbox_kind: String = String(target_profile.get("hurtbox_kind", ""))
	var rehit_policy: String = AttackProfiles.get_rehit_policy_for_hurtbox(attack_profile, hurtbox_kind)
	var rehit_interval: float = AttackProfiles.get_rehit_interval_for_hurtbox(attack_profile, hurtbox_kind)
	if not hit_registry.is_hit_allowed(
		attack_instance_id,
		target_id,
		hurtbox_id,
		rehit_policy,
		elapsed_time,
		rehit_interval,
		is_currently_overlapping
	):
		return {
			"allowed": false,
			"blocked_reason": "rehit_blocked",
		}
	var hit_request := {
		"attack_instance_id": attack_instance_id,
		"attack_profile_id": attack_profile_id,
		"target_id": target_id,
		"hurtbox_id": hurtbox_id,
		"contact_time": contact_time,
		"contact_point": contact_point,
		"target_state": target_state,
	}
	if typeof(hit_request_overrides) == TYPE_DICTIONARY:
		for key in hit_request_overrides.keys():
			hit_request[key] = hit_request_overrides[key]
	var hit_result: Dictionary = damage_resolver.resolve_hit(hit_request, attack_profile, target_profile)
	if not bool(hit_result.get("allowed", false)):
		return hit_result
	hit_registry.register_hit(attack_instance_id, target_id, hurtbox_id, elapsed_time, is_currently_overlapping)
	return hit_result


func _apply_attack_instance_hit_to_target(
	attack_instance_id: String,
	attack_profile_id: String,
	contact_point: Vector2,
	target_id: String,
	hurtbox_id: String,
	target_profile_id: String,
	damage_source := DAMAGE_SOURCE_NONE,
	contact_time := 0.0,
	target_state := "",
	is_currently_overlapping := true,
	hit_request_overrides := {}
) -> Dictionary:
	var result := {
		"allowed": false,
		"blocked_reason": "",
		"target_id": target_id,
		"hurtbox_id": hurtbox_id,
		"target_profile_id": target_profile_id,
		"target_state": target_state,
		"hit_result": {},
		"apply_result": {},
	}
	var hit_result: Dictionary = _resolve_attack_instance_hit(
		attack_instance_id,
		attack_profile_id,
		contact_point,
		target_id,
		hurtbox_id,
		target_profile_id,
		contact_time,
		target_state,
		is_currently_overlapping,
		hit_request_overrides
	)
	result["hit_result"] = hit_result
	result["allowed"] = bool(hit_result.get("allowed", false))
	result["blocked_reason"] = str(hit_result.get("blocked_reason", ""))
	if not bool(result.get("allowed", false)):
		return result
	result["apply_result"] = _apply_hit_result_to_target(target_id, target_profile_id, hit_result, damage_source)
	_apply_target_hit_feedback(
		target_id,
		target_profile_id,
		contact_point,
		attack_profile_id,
		damage_source,
		hit_result,
		result["apply_result"]
	)
	return result


func _apply_sword_hit_to_target(
	target_id: String,
	hurtbox_id: String,
	target_profile_id: String,
	damage_source := DAMAGE_SOURCE_NONE,
	contact_time := 0.0,
	target_state := "",
	is_currently_overlapping := true,
	hit_request_overrides := {}
) -> Dictionary:
	return _apply_attack_instance_hit_to_target(
		str(sword.get("attack_instance_id", "")),
		str(sword.get("attack_profile_id", "")),
		sword["pos"],
		target_id,
		hurtbox_id,
		target_profile_id,
		damage_source,
		contact_time,
		target_state,
		is_currently_overlapping,
		hit_request_overrides
	)


func _apply_array_sword_hit_to_target(
	array_sword: Dictionary,
	target_id: String,
	hurtbox_id: String,
	target_profile_id: String,
	damage_source := DAMAGE_SOURCE_NONE,
	target_state := "",
	is_currently_overlapping := true,
	hit_request_overrides := {}
) -> Dictionary:
	return _apply_attack_instance_hit_to_target(
		str(array_sword.get("attack_instance_id", "")),
		str(array_sword.get("attack_profile_id", "")),
		array_sword["pos"],
		target_id,
		hurtbox_id,
		target_profile_id,
		damage_source,
		0.0,
		target_state,
		is_currently_overlapping,
		hit_request_overrides
	)


func _start_sword_attack_instance(profile_id: String) -> void:
	if profile_id == "":
		return
	_end_sword_attack_instance()
	var attack_instance: Dictionary = _build_attack_instance(profile_id, "player", "sword")
	sword["attack_instance_id"] = str(attack_instance.get("id", ""))
	sword["attack_profile_id"] = profile_id


func _set_sword_attack_profile(profile_id: String) -> void:
	if profile_id == "":
		return
	var attack_instance_id: String = str(sword.get("attack_instance_id", ""))
	if attack_instance_id == "":
		_start_sword_attack_instance(profile_id)
		return
	sword["attack_profile_id"] = profile_id
	var attack_instances: Dictionary = combat_runtime.get("attack_instances", {})
	if not attack_instances.has(attack_instance_id):
		return
	var attack_instance: Dictionary = attack_instances[attack_instance_id]
	attack_instance["profile_id"] = profile_id
	attack_instances[attack_instance_id] = attack_instance
	combat_runtime["attack_instances"] = attack_instances


func _end_sword_attack_instance() -> void:
	var attack_instance_id: String = str(sword.get("attack_instance_id", ""))
	_clear_attack_instance(attack_instance_id)
	sword["attack_instance_id"] = ""
	sword["attack_profile_id"] = ""


func _set_sword_hit_overlap(target_id: String, hurtbox_id: String, is_overlapping: bool) -> void:
	var sword_attack_instance_id: String = str(sword.get("attack_instance_id", ""))
	if sword_attack_instance_id == "":
		return
	hit_registry.set_overlap_state(sword_attack_instance_id, target_id, hurtbox_id, is_overlapping, elapsed_time)


func _resolve_hit_preview(hit_request: Dictionary, attack_profile_id: String, target_profile_id: String) -> Dictionary:
	return damage_resolver.resolve_hit(hit_request, _get_attack_profile(attack_profile_id), _get_target_profile(target_profile_id))


func _handle_debug_key_input(event: InputEventKey) -> bool:
	if event.keycode == KEY_F6:
		_toggle_debug_calibration_mode()
		return true
	if event.keycode == KEY_F7:
		if debug_calibration_mode:
			return true
		_toggle_debug_battle_mode()
		return true
	if debug_calibration_mode:
		var aim_distance: float = player["pos"].distance_to(mouse_world)
		match event.keycode:
			KEY_1:
				SwordArrayConfig.set_morph_distance("ring_stable_end", aim_distance)
				_refresh_sword_array_live_state()
				return true
			KEY_2:
				SwordArrayConfig.set_morph_distance("ring_to_fan_end", aim_distance)
				_refresh_sword_array_live_state()
				return true
			KEY_3:
				SwordArrayConfig.set_morph_distance("fan_stable_end", aim_distance)
				_refresh_sword_array_live_state()
				return true
			KEY_4:
				SwordArrayConfig.set_morph_distance("fan_to_pierce_end", aim_distance)
				_refresh_sword_array_live_state()
				return true
			KEY_R:
				SwordArrayConfig.reset_morph_distances()
				_refresh_sword_array_live_state()
				return true
			KEY_P:
				SwordArrayConfig.save_morph_distances_to_project()
				_refresh_sword_array_live_state()
				return true
			KEY_L:
				SwordArrayConfig.load_morph_distances_from_project()
				_refresh_sword_array_live_state()
				return true
			_:
				return false
	if not debug_battle_mode:
		return false

	match event.keycode:
		KEY_1:
			_toggle_debug_flag("infinite_health")
			return true
		KEY_2:
			_toggle_debug_flag("infinite_energy")
			return true
		KEY_3:
			_toggle_debug_flag("one_hit_kill")
			return true
		KEY_4:
			_toggle_debug_flag("no_spawn")
			return true
		KEY_5:
			_clear_enemy_bullets()
			return true
		_:
			return false


func _toggle_debug_battle_mode() -> void:
	debug_battle_mode = not debug_battle_mode
	if not debug_battle_mode:
		_reset_debug_battle_flags()
	_apply_debug_runtime_overrides()
	_update_ui()
	queue_redraw()


func _reset_debug_battle_flags() -> void:
	debug_flags = {
		"infinite_health": false,
		"infinite_energy": false,
		"one_hit_kill": false,
		"no_spawn": false,
	}


func _toggle_debug_flag(flag_name: String) -> void:
	debug_flags[flag_name] = not _has_debug_flag(flag_name)
	_apply_debug_runtime_overrides()
	_update_ui()
	queue_redraw()


func _has_debug_flag(flag_name: String) -> bool:
	return bool(debug_flags.get(flag_name, false))


func _apply_debug_runtime_overrides() -> void:
	if _has_debug_flag("infinite_health"):
		player["health"] = PLAYER_MAX_HEALTH
	if _has_debug_flag("infinite_energy"):
		player["energy"] = PLAYER_MAX_ENERGY


func _apply_player_damage(amount: float, _damage_source: String = DAMAGE_SOURCE_NONE) -> bool:
	if amount <= 0.0:
		return false
	if _has_debug_flag("infinite_health"):
		player["health"] = PLAYER_MAX_HEALTH
		return false
	player["health"] = max(player["health"] - amount, 0.0)
	return true


func _add_player_energy(amount: float, show_feedback := true) -> void:
	if amount <= 0.0:
		return
	if _has_debug_flag("infinite_energy"):
		player["energy"] = PLAYER_MAX_ENERGY
		return
	var previous_energy: float = float(player.get("energy", 0.0))
	player["energy"] = min(previous_energy + amount, PLAYER_MAX_ENERGY)
	var gained_amount: float = player["energy"] - previous_energy
	if show_feedback and gained_amount > 0.0:
		_trigger_energy_gain_feedback(gained_amount)


func _trigger_energy_gain_feedback(amount: float) -> void:
	if amount <= 0.0:
		return
	var normalized_strength: float = clampf(
		amount / maxf(ENERGY_GAIN_MELEE_DEFLECT * 1.5, 1.0),
		0.18,
		ENERGY_GAIN_FEEDBACK_MAX_STRENGTH
	)
	energy_gain_feedback_timer = maxf(energy_gain_feedback_timer, ENERGY_GAIN_FEEDBACK_DURATION)
	energy_gain_feedback_strength = maxf(energy_gain_feedback_strength, normalized_strength)
	energy_gain_feedback_color = COLORS["energy"].lerp(Color.WHITE, 0.18)


func _drain_player_energy(amount: float) -> void:
	if amount <= 0.0:
		return
	if _has_debug_flag("infinite_energy"):
		player["energy"] = PLAYER_MAX_ENERGY
		return
	player["energy"] = max(player["energy"] - amount, 0.0)


func _consume_player_energy(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if _has_debug_flag("infinite_energy"):
		player["energy"] = PLAYER_MAX_ENERGY
		return true
	if player["energy"] < amount:
		return false
	player["energy"] -= amount
	return true


func _damage_boss(damage: float) -> void:
	if not _has_boss() or damage <= 0.0:
		return
	if _has_debug_flag("one_hit_kill"):
		boss["health"] = 0.0
		return
	boss["health"] = max(boss["health"] - damage, 0.0)


func _clear_enemy_bullets() -> void:
	var index: int = bullets.size() - 1
	while index >= 0:
		_remove_bullet(index)
		index -= 1


func _get_debug_status_suffix() -> String:
	if not debug_battle_mode:
		return ""
	var active_flags: Array = []
	if _has_debug_flag("infinite_health"):
		active_flags.append("无限生命")
	if _has_debug_flag("infinite_energy"):
		active_flags.append("无限剑意")
	if _has_debug_flag("one_hit_kill"):
		active_flags.append("一击击杀")
	if _has_debug_flag("no_spawn"):
		active_flags.append("停刷怪")
	return " | %s" % ("已启用" if active_flags.is_empty() else " / ".join(active_flags))


func _toggle_debug_calibration_mode() -> void:
	debug_calibration_mode = not debug_calibration_mode
	debug_dragging_player = false
	if debug_calibration_mode:
		_enter_debug_calibration_mode()
	else:
		_reset_game()


func _enter_debug_calibration_mode() -> void:
	_reset_game()
	debug_calibration_mode = true
	debug_dragging_player = false
	player["health"] = PLAYER_MAX_HEALTH
	player["energy"] = PLAYER_MAX_ENERGY
	player["pos"] = ARENA_SIZE * 0.5
	sword["pos"] = player["pos"]
	sword["prev_pos"] = player["pos"]
	bullets.clear()
	array_swords.clear()
	enemies.clear()
	enemy_packages.clear()
	particles.clear()
	sword_afterimages.clear()
	sword_trail_points.clear()
	sword_air_wakes.clear()
	sword_return_catches.clear()
	sword_hit_effects.clear()
	_clear_target_runtime_state("boss")
	_clear_target_hurtboxes("boss")
	boss.clear()
	wave = 0
	score = 0
	enemies_to_spawn = 0
	wave_spawn_queue.clear()
	spawn_timer = 9999.0
	_spawn_debug_calibration_enemies()
	_rebuild_array_sword_pool()
	_refresh_sword_array_live_state()
	_update_ui()
	queue_redraw()


func _ensure_debug_calibration_state() -> void:
	player["health"] = PLAYER_MAX_HEALTH
	player["energy"] = PLAYER_MAX_ENERGY
	enemies_to_spawn = 0
	spawn_timer = 9999.0
	if enemies.size() < DEBUG_ENEMY_LAYOUT.size():
		_spawn_debug_calibration_enemies()
	if array_swords.size() != _get_current_array_sword_capacity():
		_rebuild_array_sword_pool()


func _spawn_debug_calibration_enemies() -> void:
	enemies.clear()
	enemy_packages.clear()
	for enemy_pos in DEBUG_ENEMY_LAYOUT:
		var enemy: Dictionary = _spawn_enemy(SHOOTER)
		enemy["pos"] = enemy_pos
		enemy["vel"] = Vector2.ZERO
		enemy["shoot_cooldown"] = 9999.0
		enemy["is_debug_static"] = true
		enemy["health"] = enemy["max_health"]


func _set_debug_player_position(target_pos: Vector2) -> void:
	player["pos"] = target_pos.clamp(Vector2(PLAYER_RADIUS, PLAYER_RADIUS), ARENA_SIZE - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))
	sword["pos"] = player["pos"] if sword["state"] == SwordState.ORBITING else sword["pos"]
	sword["prev_pos"] = sword["pos"]
	_refresh_sword_array_live_state()
