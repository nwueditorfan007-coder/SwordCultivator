extends Node2D

const AttackProfiles = preload("res://scripts/combat/attack_profiles.gd")
const DamageResolver = preload("res://scripts/combat/damage_resolver.gd")
const DemoLevelController = preload("res://scripts/system/demo_level_controller.gd")
const HitDetection = preload("res://scripts/combat/hit_detection.gd")
const HurtboxRegistry = preload("res://scripts/combat/hurtbox_registry.gd")
const GameBossController = preload("res://scripts/system/game_boss_controller.gd")
const GameRenderer = preload("res://scripts/system/game_renderer.gd")
const GameStateFactory = preload("res://scripts/system/game_state_factory.gd")
const HitRegistry = preload("res://scripts/combat/hit_registry.gd")
const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayController = preload("res://scripts/system/sword_array_controller.gd")
const SwordResonanceController = preload("res://scripts/system/sword_resonance_controller.gd")
const SwordFlightFxScript = preload("res://scripts/vfx/sword_flight_fx.gd")
const SwordVfxProfile = preload("res://scripts/vfx/sword_vfx_profile.gd")
const TargetDescriptors = preload("res://scripts/combat/target_descriptors.gd")
const TargetDescriptorRegistry = preload("res://scripts/combat/target_descriptor_registry.gd")
const TargetEventSystem = preload("res://scripts/combat/target_event_system.gd")
const TargetProfiles = preload("res://scripts/combat/target_profiles.gd")
const TargetWritebackAdapters = preload("res://scripts/combat/target_writeback_adapters.gd")
const HumanoidEightWaySkeletonVisual = preload("res://scripts/prototypes/humanoid_8way_skeleton_visual.gd")
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
	PIERCE_DRAWING,
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

const ARRAY_TOGGLE_MODES := [
	SwordArrayConfig.MODE_RING,
	SwordArrayConfig.MODE_FAN,
	SwordArrayConfig.MODE_PIERCE,
]
const RUN_MODE_DEMO_LEVEL := "demo_level"
const RUN_MODE_LEGACY_WAVES := "legacy_waves"
const RUN_MODE_FLIGHT_PROTOTYPE := "flight_prototype"
const RUN_MODE_FLIGHT_ANCHORED_PROTOTYPE := "flight_anchored_prototype"
const ARRAY_CONTROL_SCHEME_DISTANCE := "distance_aim"
const ARRAY_CONTROL_SCHEME_MANUAL := "space_toggle"
const ARRAY_RING_SWITCH_STRIKE_VISUAL_BLEND := 0.62

const LOOKDEV_PANEL_TARGET_WIDTH := 320.0
const LOOKDEV_PANEL_MARGIN := 16.0
const LOOKDEV_CONTROLS := [
	{
		"title": "拖尾",
		"items": [
			{"prop": "trail_duration", "label": "拖尾持续", "min": 0.02, "max": 0.3, "step": 0.005},
			{"prop": "trail_sample_interval", "label": "采样间隔", "min": 0.004, "max": 0.05, "step": 0.001},
			{"prop": "trail_max_points", "label": "轨迹点数", "min": 4.0, "max": 32.0, "step": 1.0},
			{"prop": "trail_forward_offset", "label": "前推距离", "min": 0.0, "max": 24.0, "step": 0.5},
			{"prop": "trail_base_half_width", "label": "拖尾宽度", "min": 2.0, "max": 24.0, "step": 0.5},
			{"prop": "trail_point_width_scale", "label": "点刺拖尾", "min": 0.2, "max": 1.4, "step": 0.02},
			{"prop": "trail_slice_width_scale", "label": "连斩拖尾", "min": 0.4, "max": 1.8, "step": 0.02},
			{"prop": "trail_recall_width_scale", "label": "回收拖尾", "min": 0.2, "max": 1.2, "step": 0.02},
			{"prop": "trail_point_life_scale", "label": "点刺寿命", "min": 0.3, "max": 1.6, "step": 0.02},
			{"prop": "trail_slice_life_scale", "label": "连斩寿命", "min": 0.3, "max": 1.8, "step": 0.02},
			{"prop": "trail_recall_life_scale", "label": "回收寿命", "min": 0.3, "max": 1.6, "step": 0.02},
			{"prop": "node_trail_width_base_scale", "label": "节点基础宽", "min": 0.4, "max": 2.0, "step": 0.02},
			{"prop": "node_trail_halo_width_scale", "label": "节点外晕宽", "min": 0.4, "max": 2.4, "step": 0.02},
			{"prop": "node_trail_ribbon_width_scale", "label": "节点中层宽", "min": 0.2, "max": 1.4, "step": 0.02},
			{"prop": "node_trail_core_width_scale", "label": "节点核心宽", "min": 0.05, "max": 0.6, "step": 0.01},
			{"prop": "node_trail_warm_width_scale", "label": "暖芯宽度", "min": 0.0, "max": 0.4, "step": 0.01},
			{"prop": "node_trail_head_clearance_point", "label": "点刺净空", "min": 4.0, "max": 36.0, "step": 0.5},
			{"prop": "node_trail_head_clearance_slice", "label": "连斩净空", "min": 4.0, "max": 40.0, "step": 0.5},
			{"prop": "node_trail_head_clearance_recall", "label": "回收净空", "min": 4.0, "max": 32.0, "step": 0.5},
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
		"title": "剑体流光",
		"items": [
			{"prop": "body_flow_idle_strength", "label": "常驻强度", "min": 0.0, "max": 0.5, "step": 0.01},
			{"prop": "body_flow_speed_strength", "label": "速度增益", "min": 0.0, "max": 1.0, "step": 0.01},
			{"prop": "body_flow_turn_strength", "label": "转向增益", "min": 0.0, "max": 0.6, "step": 0.01},
			{"prop": "body_flow_shell_width_scale", "label": "流带摆幅", "min": 0.4, "max": 2.2, "step": 0.02},
			{"prop": "body_flow_core_width_scale", "label": "流带宽度", "min": 0.2, "max": 1.4, "step": 0.02},
			{"prop": "body_flow_scroll_speed", "label": "流动速度", "min": 0.5, "max": 8.0, "step": 0.05},
			{"prop": "body_flow_band_density", "label": "流纹密度", "min": 2.0, "max": 20.0, "step": 0.1},
			{"prop": "body_flow_tip_bias", "label": "剑尖偏置", "min": -0.4, "max": 0.8, "step": 0.01},
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
const BASE_ARENA_SIZE := ARENA_SIZE
const LARGE_ARENA_SIZE := Vector2(4000.0, 1800.0)
const LARGE_ARENA_PLAYER_START := Vector2(500.0, 900.0)
const LARGE_ARENA_CORE_POS := Vector2(3150.0, 900.0)
const LARGE_ARENA_UPPER_EYE_POS := Vector2(2100.0, 430.0)
const LARGE_ARENA_LOWER_EYE_POS := Vector2(2300.0, 1370.0)
const LARGE_ARENA_BOSS_SPAWN_POS := Vector2(3150.0, 620.0)
const LARGE_ARENA_BOSS_ANCHOR_POS := Vector2(3150.0, 760.0)
const LARGE_ARENA_BOSS_CENTER_POS := Vector2(3150.0, 900.0)
const LARGE_ARENA_CORE_KEY := "core"
const LARGE_ARENA_UPPER_EYE_KEY := "upper_eye"
const LARGE_ARENA_LOWER_EYE_KEY := "lower_eye"
const LARGE_ARENA_STATE_SEALED := "sealed"
const LARGE_ARENA_STATE_VULNERABLE := "vulnerable"
const LARGE_ARENA_STATE_DESTROYED := "destroyed"
const LARGE_ARENA_PLAYER_SPEED := 430.0
const LARGE_ARENA_EYE_RADIUS := 46.0
const LARGE_ARENA_CORE_RADIUS := 64.0
const LARGE_ARENA_EYE_HEALTH := 520.0
const LARGE_ARENA_CORE_HEALTH := 980.0
const LARGE_ARENA_MAX_PURSUERS := 2
const LARGE_ARENA_GUARDS_PER_EYE := 1
const LARGE_ARENA_MAX_INTERCEPTORS := 2
const LARGE_ARENA_PURSUER_INTERVAL := 4.6
const LARGE_ARENA_GUARD_CHECK_INTERVAL := 2.0
const LARGE_ARENA_INTERCEPTOR_INTERVAL := 6.0
const LARGE_ARENA_UPPER_THREAT_RECT := Rect2(Vector2(1700.0, 750.0), Vector2(1200.0, 300.0))
const LARGE_ARENA_LOWER_THREAT_RECT := Rect2(Vector2(1680.0, 1140.0), Vector2(1080.0, 360.0))
const LARGE_ARENA_TOP_ROUTE_RECT := Rect2(Vector2(1380.0, 180.0), Vector2(1700.0, 260.0))
const LARGE_ARENA_THREAT_DAMAGE_PER_SECOND := 7.5
const LARGE_ARENA_WIND_SPEED_MULTIPLIER := 0.58
const LARGE_ARENA_PURSUER_HEALTH := 78.0
const LARGE_ARENA_GUARD_HEALTH := 92.0
const LARGE_ARENA_INTERCEPTOR_SHOOTER_HEALTH := 110.0
const LARGE_ARENA_INTERCEPTOR_HEAVY_HEALTH := 190.0
const LARGE_ARENA_PURSUER_SPEED_SCALE := 3.25
const LARGE_ARENA_INTERCEPTOR_SPEED_SCALE := 2.35
const LARGE_ARENA_STRAY_GUARD_SPEED_SCALE := 1.55
const LARGE_ARENA_GUARD_ORBIT_ANGULAR_SPEED := 1.18
const LARGE_ARENA_GUARD_REPOSITION_SPEED := 340.0
const LARGE_ARENA_GUARD_PLAYER_BIAS_RADIUS := 620.0
const LARGE_ARENA_GUARD_PLAYER_BIAS := 0.28

const PLAYER_RADIUS := 15.0
const PLAYER_MAX_HEALTH := 100.0
const PLAYER_MAX_ENERGY := 100.0
const PLAYER_SPEED := 300.0

const SWORD_RADIUS := 25.0
const SWORD_MELEE_RANGE := 100.0
const SWORD_MELEE_COOLDOWN := 10.0 / 60.0
const SWORD_MELEE_ARC := PI * 1.2
const MELEE_SWORD_SWING_DURATION := 0.15
const MELEE_SWORD_SWING_ARC := SWORD_MELEE_ARC
const MELEE_SWORD_VISUAL_SCALE := 1.6
const MELEE_SWORD_TIP_FORWARD_OFFSET := 24.4 * MELEE_SWORD_VISUAL_SCALE
const MELEE_SWORD_CENTER_DISTANCE := SWORD_MELEE_RANGE - MELEE_SWORD_TIP_FORWARD_OFFSET
const MELEE_SWORD_READY_SIDE := -1.0
const MELEE_SWORD_SWING_SIDE := -MELEE_SWORD_READY_SIDE
const MELEE_COMBO_STAGE_COUNT := 3
const MELEE_COMBO_RESET_WINDOW := 0.74
const MELEE_FOCUSED_CHAIN_GAP := 0.04
const MELEE_INPUT_BUFFER_WINDOW := 0.22
const MELEE_SHADOW_STRIKE_DELAY := 0.07
const MELEE_SHADOW_DAMAGE_SCALAR := 0.3
const MELEE_SHADOW_FLASH_DURATION := 0.12
const MELEE_HITSTOP_BASE_DURATION := 0.018
const MELEE_FOCUSED_SLASH_DAMAGE_SCALAR := 0.86
const MELEE_FOCUSED_SLASH_RANGE := 138.0
const MELEE_FOCUSED_SLASH_VISUAL_RANGE := 96.0
const MELEE_FOCUSED_SLASH_ARC := PI * 24.0 / 180.0
const MELEE_FOCUSED_SLASH_HIT_WIDTH := 13.0
const MELEE_ACTION_PHASE_IDLE := "idle"
const MELEE_ACTION_PHASE_STARTUP := "startup"
const MELEE_ACTION_PHASE_ACTIVE := "active"
const MELEE_ACTION_PHASE_RECOVERY := "recovery"
const MELEE_TEST_PROFILE_LIGHT_BROAD_SPLIT := "light_broad_split"
const MELEE_TEST_PROFILE_LIGHT_LONG_FOCUS := "light_long_focus"
const MELEE_TEST_PROFILE_HEAVY_BROAD_FOCUS := "heavy_broad_focus"
const MELEE_TEST_PROFILE_HEAVY_LONG_SPLIT := "heavy_long_split"
const MELEE_TEST_PROFILE_IDS := [
	MELEE_TEST_PROFILE_LIGHT_BROAD_SPLIT,
	MELEE_TEST_PROFILE_LIGHT_LONG_FOCUS,
	MELEE_TEST_PROFILE_HEAVY_BROAD_FOCUS,
	MELEE_TEST_PROFILE_HEAVY_LONG_SPLIT,
]
const MELEE_TEST_PROFILES := {
	MELEE_TEST_PROFILE_LIGHT_BROAD_SPLIT: {
		"name": "流萤阔刃分光剑",
		"traits": ["轻灵", "阔刃", "分光"],
		"tempo_shape": "light",
		"blade_shape": "broad",
		"spirit_shape": "split",
		"time_scalar": 0.76,
		"hitstop_scalar": 0.72,
		"shake_scalar": 0.82,
		"poise_scalar": 0.9,
		"split": true,
		"shadow_delay": 0.055,
		"shadow_damage_scalar": 0.28,
		"color": Color("7dd3fc"),
	},
	MELEE_TEST_PROFILE_LIGHT_LONG_FOCUS: {
		"name": "惊鸿长锋凝锋剑",
		"traits": ["轻灵", "长锋", "凝锋"],
		"tempo_shape": "light",
		"blade_shape": "long",
		"spirit_shape": "focus",
		"time_scalar": 0.78,
		"hitstop_scalar": 0.82,
		"shake_scalar": 0.86,
		"poise_scalar": 0.92,
		"split": false,
		"color": Color("a7f3d0"),
	},
	MELEE_TEST_PROFILE_HEAVY_BROAD_FOCUS: {
		"name": "沉岳阔刃凝锋剑",
		"traits": ["重势", "阔刃", "凝锋"],
		"tempo_shape": "heavy",
		"blade_shape": "broad",
		"spirit_shape": "focus",
		"time_scalar": 1.16,
		"hitstop_scalar": 1.42,
		"shake_scalar": 1.36,
		"poise_scalar": 1.28,
		"split": false,
		"color": Color("fca5a5"),
	},
	MELEE_TEST_PROFILE_HEAVY_LONG_SPLIT: {
		"name": "坠星长锋分光剑",
		"traits": ["重势", "长锋", "分光"],
		"tempo_shape": "heavy",
		"blade_shape": "long",
		"spirit_shape": "split",
		"time_scalar": 1.14,
		"hitstop_scalar": 1.32,
		"shake_scalar": 1.28,
		"poise_scalar": 1.22,
		"split": true,
		"shadow_delay": 0.085,
		"shadow_damage_scalar": 0.32,
		"color": Color("c084fc"),
	},
}
const SWORD_TAP_THRESHOLD := 0.15
const SWORD_POINT_STRIKE_SPEED := 80.0 * 60.0
const SWORD_RECALL_SPEED := 60.0 * 60.0
const SWORD_ORBIT_DISTANCE := 25.0
const SWORD_SLICE_MIN_HIT_SPEED := 90.0
const SWORD_SLICE_FOLLOW_SPEED := 36.0
const SWORD_HOVER_PRESETS := [
	{
		"name": "稳悬",
		"enter_speed": 76.0,
		"exit_speed": 156.0,
		"enter_delay": 0.08,
		"blend_in_duration": 0.2,
		"blend_out_duration": 0.12,
		"float_amplitude": 4.4,
		"drift_amplitude": 0.8,
		"float_frequency": 1.2,
		"drift_frequency": 0.72,
		"angle_amplitude": 0.03,
	},
	{
		"name": "均衡",
		"enter_speed": 84.0,
		"exit_speed": 180.0,
		"enter_delay": 0.06,
		"blend_in_duration": 0.14,
		"blend_out_duration": 0.08,
		"float_amplitude": 6.0,
		"drift_amplitude": 1.3,
		"float_frequency": 1.55,
		"drift_frequency": 0.95,
		"angle_amplitude": 0.055,
	},
	{
		"name": "灵动",
		"enter_speed": 92.0,
		"exit_speed": 210.0,
		"enter_delay": 0.05,
		"blend_in_duration": 0.12,
		"blend_out_duration": 0.07,
		"float_amplitude": 7.0,
		"drift_amplitude": 1.9,
		"float_frequency": 1.8,
		"drift_frequency": 1.12,
		"angle_amplitude": 0.075,
	},
	{
		"name": "仙逸",
		"enter_speed": 80.0,
		"exit_speed": 168.0,
		"enter_delay": 0.09,
		"blend_in_duration": 0.22,
		"blend_out_duration": 0.12,
		"float_amplitude": 8.2,
		"drift_amplitude": 1.1,
		"float_frequency": 1.08,
		"drift_frequency": 0.68,
		"angle_amplitude": 0.04,
	},
]

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

const BULLET_TIME_START_MULTIPLIER := 0.2
const BULLET_TIME_ENTRY_HOLD_DURATION := 0.2
const BULLET_TIME_RECOVERY_DURATION := 2.0
const PLAYER_BULLET_TIME_SPEED_MULTIPLIER := 0.85
const TIME_RIFT_FREEZE_MARKER_LIMIT := 22
const UNSHEATH_FLASH_DURATION := 0.08
const UNSHEATH_FLASH_REPEAT_SUPPRESSION := 0.16
const UNSHEATH_FLASH_BASE_STRENGTH := 0.34
const UNSHEATH_FLASH_REPEAT_STRENGTH := 0.12
const UNSHEATH_PRESS_FLASH_DURATION := 0.045
const UNSHEATH_PRESS_FLASH_STRENGTH := 1
const UNSHEATH_PRESS_FLASH_REPEAT_SUPPRESSION := 0.11
const UNSHEATH_PRESS_FLASH_BASE_STRENGTH := 0.22
const UNSHEATH_PRESS_FLASH_REPEAT_STRENGTH := 0.087
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
const MELEE_ATTACK_FLASH_DURATION := 0.14
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
const SCORE_LOOT_PICKUP_DISTANCE := 34.0
const SCORE_LOOT_LIFE_DURATION := 8.0
const SCORE_LOOT_WARNING_DURATION := 2.0
const SCORE_LOOT_RADIUS := 13.0
const SCORE_LOOT_PICKUP_ARM_DELAY := 0.16
const SCORE_LOOT_FEEDBACK_DURATION := 0.34
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
const FAN_TIME_STOP_COMBO_DURATION := 2.5
const FAN_TIME_STOP_SPLIT_DURATION := 0.2
const FAN_TIME_STOP_MERGE_DURATION := 0.24
const FAN_TIME_STOP_TRANSITION_PARTICLE_COUNT := 8
const FAN_TIME_STOP_SPLIT_SHAKE := 4.0
const FAN_TIME_STOP_MERGE_SHAKE := 3.2
const FAN_TIME_STOP_CLONE_SIDE_OFFSET_BASE := 24.0
const FAN_TIME_STOP_CLONE_SIDE_OFFSET_SCALE := 10.0
const FAN_TIME_STOP_CLONE_FORWARD_OFFSET := 4.0
const FAN_TIME_STOP_CLONE_DAMAGE_SCALAR := 0.55
const FAN_TIME_STOP_CLONE_HIT_EFFECT_INTENSITY := 0.72
const PIERCE_TIME_STOP_COMBO_MIN_SWEEP_DISTANCE := 4.0
const PIERCE_TIME_STOP_COMBO_POINT_SPACING := 18.0
const PIERCE_TIME_STOP_COMBO_MAX_POINTS := 384
# Set to <= 0.0 to disable distance-based auto release.
const PIERCE_TIME_STOP_COMBO_AUTO_RELEASE_DRAW_DISTANCE := 0.0
const PIERCE_TIME_STOP_DRAW_DURATION := 2
const PIERCE_TIME_STOP_RELEASE_COMBO_DURATION := 1.15
const PIERCE_TIME_STOP_DRAW_BULLET_TIME_MULTIPLIER := 0.06
const PIERCE_TIME_STOP_DRAW_PLAYER_TIME_MULTIPLIER := 0.96
const PIERCE_TIME_STOP_ROUTE_REACHED_DISTANCE := 1.5
const PIERCE_TIME_STOP_COMBO_FLIGHT_SPEED_MULTIPLIER := 1.14
const PIERCE_TIME_STOP_RELEASE_SHAKE := 8.0
const PIERCE_TIME_STOP_RELEASE_PARTICLE_COUNT := 24

const ENERGY_RECOVERY_MELEE_NATURAL := 3.0
const ENERGY_GAIN_MELEE_HIT := 3.0
const ENERGY_GAIN_MELEE_DEFLECT := 10.0
const SWORD_MOMENTUM_HEAT_START_RATIO := 0.82
const SWORD_MOMENTUM_HEAT_FADE_SPEED := 5.5
const SWORD_MOMENTUM_FULL_FLASH_DURATION := 0.78
const SWORD_MOMENTUM_FULL_EPSILON := 0.01
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
const ARRAY_MODE_CONFIRM_DURATION := 0.24
const ARRAY_MODE_CONFIRM_COOLDOWN := 0.10
const RIDER_ARRAY_TRANSITION_DURATION := 0.58
const RIDER_ARRAY_TRANSITION_CONFIRM_DURATION := 0.14
const RIDER_ARRAY_TRANSITION_PROTECTED_PROGRESS := 0.72
const RIDER_ARRAY_RELEASE_DURATION := 0.54
const RIDER_ARRAY_RELEASE_VISUAL_COOLDOWN := 0.68
const RIDER_ARRAY_ENTER_DURATION := 0.42
const RIDER_ARRAY_EXIT_DURATION := 0.36
const RIDER_SWORD_CONTROL_ENTER_DURATION := 0.38
const RIDER_SWORD_CONTROL_EXIT_DURATION := 0.34
const RIDER_MELEE_BODY_DURATION := 0.34
const RIDER_REPEATED_ACTION_RESTART_PROGRESS := 0.18
const ARRAY_DISTANCE_GUIDE_ENABLED := false
const ARRAY_DISTANCE_GUIDE_INTRO_DURATION := 0.0
const ARRAY_DISTANCE_GUIDE_MOUSE_FADE_DURATION := 0.0
const ARRAY_DISTANCE_GUIDE_HOLD_STRENGTH := 0.0
const CURSOR_INTENT_FAST_SPEED := 520.0
const CURSOR_INTENT_MAX_SPEED := 1420.0
const CURSOR_INTENT_MODE_SWITCH_DURATION := 0.22
const CURSOR_INTENT_PRESSURE_RADIUS := 170.0
const CURSOR_INTENT_PRESSURE_ENTER_SCORE := 0.65
const CURSOR_INTENT_PRESSURE_EXIT_SCORE := 0.35
const CURSOR_INTENT_PRESSURE_ENTER_HOLD := 0.10
const CURSOR_INTENT_PRESSURE_FADE_IN_SPEED := 9.0
const CURSOR_INTENT_PRESSURE_FADE_OUT_SPEED := 3.4
const CURSOR_INTENT_OUT_OF_RANGE_FADE_SPEED := 6.5
const CURSOR_INTENT_RESOURCE_FADE_SPEED := 8.0
const CURSOR_INTENT_FIRE_KICK_PER_SWORD := 0.18
const CURSOR_INTENT_FIRE_KICK_MIN := 0.28
const CURSOR_INTENT_FIRE_KICK_MAX := 1.0
const CURSOR_INTENT_FIRE_KICK_DECAY_SPEED := 7.4
const CURSOR_INTENT_FIRE_PHASE_STEP := 1.43
const FOCUS_STATUS_DURATION := 0.46
const FOCUS_STATUS_Y_OFFSET := 58.0
const DEFLECT_BULLET_SPEED_MULTIPLIER := 8.0
const RING_GUARD_BULLET_CLEAR_RADIUS := 34.0
const RING_GUARD_PLAYER_CLEAR_RADIUS := 58.0

const DAMAGE_SOURCE_NONE := ""
const DAMAGE_SOURCE_MELEE := "melee"
const DAMAGE_SOURCE_FLYING_SWORD := "flying_sword"
const DAMAGE_SOURCE_FLYING_SWORD_CLONE := "flying_sword_clone"
const DAMAGE_SOURCE_ARRAY_SWORD := "array_sword"
const DAMAGE_SOURCE_SYSTEM := "system"

const WAVE_BASE_ENEMIES := 3
const BOSS_WAVE_INTERVAL := 10
const FIRST_CHAPTER_SCRIPTED_WAVE_MAX := 9
const UNLOCK_WAVE_FLYING_SWORD := 2
const UNLOCK_WAVE_ARRAY_RING := 3
const UNLOCK_WAVE_ARRAY_FAN := 4
const UNLOCK_WAVE_ARRAY_PIERCE := 5
const SPAWN_MARGIN := 50.0
const SPAWN_INTERVAL := 0.35

const FLIGHT_STAGE_DURATION := 88.0
const FLIGHT_BASE_SCROLL_SPEED := 210.0
const FLIGHT_MIN_SCROLL_SPEED := 145.0
const FLIGHT_MAX_SCROLL_SPEED := 315.0
const FLIGHT_SCROLL_ACCEL := 4.8
const FLIGHT_FORWARD_SPEED_BONUS := 82.0
const FLIGHT_BACK_SPEED_BRAKE := 68.0
const FLIGHT_START_POS := Vector2(224.0, 318.0)
const FLIGHT_CANVAS_MIN := Vector2(PLAYER_RADIUS, PLAYER_RADIUS)
const FLIGHT_CANVAS_MAX := ARENA_SIZE - Vector2(PLAYER_RADIUS, PLAYER_RADIUS)
const FLIGHT_FREE_MOVE_SPEED := 340.0
const FLIGHT_HORIZONTAL_SPEED := 330.0
const FLIGHT_VERTICAL_SPEED := 330.0
const FLIGHT_JET_THRUST_ACCEL := 720.0
const FLIGHT_JET_AFTERBURNER_ACCEL := 1180.0
const FLIGHT_JET_GLIDE_DAMPING := 0.72
const FLIGHT_JET_BRAKE_DAMPING := 5.8
const FLIGHT_JET_TURN_RATE := 3.65
const FLIGHT_JET_HIGH_SPEED_TURN_RATE := 2.25
const FLIGHT_JET_BRAKE_TURN_BONUS := 1.45
const FLIGHT_JET_MAX_SPEED := 430.0
const FLIGHT_JET_AFTERBURNER_MAX_SPEED := 640.0
const FLIGHT_JET_ROLL_SPEED := 620.0
const FLIGHT_JET_ROLL_DURATION := 0.22
const FLIGHT_JET_ROLL_COOLDOWN := 0.48
const FLIGHT_JET_ROLL_EXIT_SPEED_KEEP := 0.86
const FLIGHT_JET_BOUND_BOUNCE := 0.18
const FLIGHT_JET_ANCHOR_RETURN_STRENGTH := 0.82
const FLIGHT_PROTOTYPE_SKELETON_BASE_SCALE := 1.16
const FLIGHT_PROTOTYPE_SKELETON_POSE_OFFSET := Vector2(0.0, -6.0)
const FLIGHT_VISUAL_HEADING_TURN_RATE := 8.8
const FLIGHT_VISUAL_HEADING_HARD_TURN_RATE := 12.0
const FLIGHT_VISUAL_HEADING_HOVER_TURN_RATE := 13.5
const FLIGHT_VISUAL_TURN_HALF_LIFE := 0.06
const FLIGHT_VISUAL_BOOST_HALF_LIFE := 0.09
const FLIGHT_VISUAL_CARVE_HALF_LIFE := 0.045
const FLIGHT_VISUAL_THROTTLE_HALF_LIFE := 0.08
const FLIGHT_VISUAL_CARVE_DURATION := 0.24
const FLIGHT_EIGHT_WAY_SWITCH_HYSTERESIS := 0.10
const FLIGHT_EIGHT_WAY_VECTORS := [
	Vector2(1.0, 0.0),
	Vector2(0.7071, -0.7071),
	Vector2(0.0, -1.0),
	Vector2(-0.7071, -0.7071),
	Vector2(-1.0, 0.0),
	Vector2(-0.7071, 0.7071),
	Vector2(0.0, 1.0),
	Vector2(0.7071, 0.7071),
]
const LEGACY_FLIGHT_CRUISE_SPEED := 430.0
const LEGACY_FLIGHT_BOOST_SPEED := 640.0
const LEGACY_FLIGHT_ACCELERATION := 1680.0
const LEGACY_FLIGHT_BOOST_ACCELERATION := 2450.0
const LEGACY_FLIGHT_GLIDE_DAMPING := 0.62
const LEGACY_FLIGHT_IDLE_BRAKE := 820.0
const LEGACY_FLIGHT_TURN_RATE := 8.8
const LEGACY_FLIGHT_HIGH_SPEED_TURN_RATE := 5.4
const FLIGHT_ANCHOR_POS := Vector2(224.0, 318.0)
const FLIGHT_ANCHOR_LANE_MIN := Vector2(24.0, 46.0)
const FLIGHT_ANCHOR_LANE_MAX := Vector2(632.0, 554.0)
const FLIGHT_ANCHOR_FORWARD_CONTROL_SPEED := 265.0
const FLIGHT_ANCHOR_BACK_CONTROL_SPEED := 220.0
const FLIGHT_ANCHOR_RETURN_STRENGTH := 3.8
const FLIGHT_ANCHOR_SOFT_RETURN_STRENGTH := 1.2
const FLIGHT_PASSIVE_ENERGY_REGEN := 22.0
const FLIGHT_OFFSCREEN_LEFT := -130.0
const FLIGHT_OFFSCREEN_RIGHT := 910.0

const SHOOTER := "shooter"
const TANK := "tank"
const CASTER := "caster"
const HEAVY := "heavy"
const RING_LEECH := "ring_leech"
const DRAPE_PRIEST := "drape_priest"
const MIRROR_NEEDLER := "mirror_needler"
const PUPPET := "puppet"
const FORMATION_EYE := "formation_eye"
const FORMATION_CORE := "formation_core"

const SWORD_SPIRIT_HIGH_VALUE_ENEMY_TYPES := [
	MIRROR_NEEDLER,
	CASTER,
	DRAPE_PRIEST,
]
const SWORD_SPIRIT_INTENT_MIN_FORWARD := 36.0
const SWORD_SPIRIT_INTENT_DEPTH := 560.0
const SWORD_SPIRIT_GUARD_RADIUS := 190.0
const SWORD_SPIRIT_GUARD_BULLET_RADIUS := 150.0
const SWORD_SPIRIT_GUARD_RECOMMEND_SCORE := 0.62
const SWORD_SPIRIT_GUARD_STEAL_MARGIN := 0.18
const SWORD_SPIRIT_SWEEP_MIN_DISTANCE := 88.0
const SWORD_SPIRIT_SWEEP_MAX_DISTANCE := 410.0
const SWORD_SPIRIT_SWEEP_MAX_ANGLE := 0.82
const SWORD_SPIRIT_SWEEP_HALF_WIDTH := 230.0
const SWORD_SPIRIT_SWEEP_SPREAD_TARGET := 180.0
const SWORD_SPIRIT_SWEEP_RECOMMEND_SCORE := 0.34
const SWORD_SPIRIT_PIERCE_MAX_ANGLE := 0.34
const SWORD_SPIRIT_PIERCE_CORRIDOR_HALF_WIDTH := 42.0
const SWORD_SPIRIT_CURSOR_LOCK_RADIUS := 62.0
const SWORD_SPIRIT_BOSS_CORE_CURSOR_LOCK_RADIUS := 92.0
const SWORD_SPIRIT_BOSS_CORE_CORRIDOR_HALF_WIDTH := 82.0
const SWORD_SPIRIT_PIERCE_RECOMMEND_SCORE := 0.34
const SWORD_SPIRIT_FOLLOWUP_RECOMMEND_SCORE := 0.38
const SWORD_SPIRIT_TAKEOVER_ENABLED := true
const SWORD_SPIRIT_TAKEOVER_PIERCE_OVERSHOOT := 240.0

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
	"formation_eye": Color("38d5ff"),
	"formation_core": Color("facc15"),
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

[b]鼠标移动 瞄准[/b]
角色、近战挥剑、御剑目标和剑阵方向都会参考鼠标位置。剑阵发射朝向也会跟随鼠标，方便你边走位边控线。

[b]Space 切换剑阵[/b]
在已解锁的环阵、扇阵、贯穿阵之间循环切换。环阵更适合近身护体和群组解压，扇阵更适合中距离扫面，贯穿阵更适合远端破线和窗口输出。

[b]左键点击 近战挥剑[/b]
立即朝鼠标方向斩击，适合处理贴脸敌人和弹开敌弹。命中敌人或成功弹反敌弹会回复剑意，是维持后续剑阵的主要来源。

[b]左键长按 剑阵压制[/b]
按住约 0.1 秒后持续发射飞剑。当前选中的剑阵会决定飞剑的发射方式。每把飞剑会消耗剑意，剑意不足或飞剑未回收时会中断。

[b]右键短按 御剑点刺[/b]
按下后快速松开，飞剑会刺向鼠标位置；飞剑离身期间会触发子弹时间，适合点杀远处目标、穿过弹幕空隙或打断一条直线上的威胁。

[b]右键长按 御剑连斩[/b]
按住超过短按阈值后进入连斩，拖动鼠标让飞剑追随并切割路径；松开右键后飞剑召回。适合持续切割移动中的目标或清理一片压力。

[b]死亡后左键 重新开始[/b]
力竭身亡后，在结算提示出现时点击左键即可重新开始本局。"""

const START_MENU_OPERATION_TEXT_DISTANCE := """[b]WASD 移动[/b]
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

const START_MENU_DEMO_TEXT := """[b]破庙夜袭[/b]
这是 Demo 第一关：只用左键挥剑 / 弹反，以及右键御剑。整关不会开放剑阵。

[b]左键点击 近战挥剑[/b]
贴身先活下来。敌弹飞到身前时挥剑，可以把针斩回去。

[b]右键短按 御剑点刺[/b]
快速出剑处理远处重敌，飞剑离手时会拖慢敌弹，让你夺回节奏。

[b]右键长按 御剑连斩[/b]
按住后拖动鼠标切割路径；看到丝线时，优先切线，不要追着傀身砍。

[b]恢复道具[/b]
精英敌人和段落末会留下回血光点，需要靠近拾取。

[b]失败与通关[/b]
Boss 前有检查点。击败织傀道人后会显示本次表现，并预告下一关的剑阵。"""

const START_MENU_FLIGHT_TEXT := """[b]御剑航行原型[/b]
这是横版相对前进测试：角色按机头、推力和惯性飞行，云海、敌阵和弹幕向后流动。

[b]A/D 转向，W 推进，S 空刹[/b]
松开推进后会保持滑翔；空刹可以压速度并提高回头能力。

[b]Shift 后燃器，Space 翻滚[/b]
后燃器用于抢航速和穿线，翻滚是短促避险，不改变鼠标瞄准。

[b]鼠标控距与瞄准[/b]
鼠标离角色越近越偏环阵，中距离是扇阵，远距离是贯穿阵。

[b]左键点击 / 长按[/b]
点击仍是近战挥剑；长按进入剑阵，专门验证环阵护身、扇阵清面、贯穿阵破线。

[b]右键御剑[/b]
短按点刺、长按连斩，保留当前御剑和子弹时间手感。"""

const START_MENU_FLIGHT_ANCHORED_TEXT := """[b]御剑航行：风压回中[/b]
这是同一条云海航道的对照版本：使用同一套推力飞行，但气流会轻微拉回左中航线。

[b]A/D 转向，W 推进，S 空刹[/b]
这版多一层风压回中，适合比较自由空战和横版航道哪种更稳。

[b]Shift 后燃器，Space 翻滚[/b]
后燃器用于突破弹线；翻滚提供短暂保命窗口。

[b]鼠标控距与瞄准[/b]
鼠标离角色越近越偏环阵，中距离是扇阵，远距离是贯穿阵。

[b]左键点击 / 长按[/b]
点击仍是近战挥剑；长按进入剑阵，专门验证环阵护身、扇阵清面、贯穿阵破线。

[b]右键御剑[/b]
短按点刺、长按连斩，保留当前御剑和子弹时间手感。"""

@export var sword_vfx_profile: SwordVfxProfile = DEFAULT_SWORD_VFX_PROFILE
@export var use_node_sword_flight_vfx := true
@export var large_arena_test_enabled := true
@export var use_flight_rider_sprite_fx := true
@export var use_flight_rider_body_rig_fx := false
@export var use_flight_prototype_skeleton_visual := true
@export_range(0.1, 1.2, 0.01) var flight_prototype_skeleton_scale := 0.3
@export_group("Hover Preset")
@export_enum("稳悬", "均衡", "灵动", "仙逸") var sword_hover_preset := 1
@export var sword_hover_preset_next_key: Key = KEY_NONE
@export var sword_hover_preset_previous_key: Key = KEY_NONE
@export_group("")
@export var lookdev_mode := false
@export var lookdev_auto_cycle := true
@export var lookdev_preview_mode: LookdevPreviewMode = LookdevPreviewMode.POINT
@export_range(0.25, 3.0, 0.05) var lookdev_playback_speed := 1.0
@export_group("Flight Rider Art")
@export_range(0.35, 2.4, 0.01) var flight_rider_visual_scale := 0.72
@export_range(0.2, 2.0, 0.01) var flight_rider_action_scale := 1.0
@export_range(18.0, 92.0, 1.0) var flight_full_energy_mandala_radius := 56.0
@export_range(0.0, 2.0, 0.01) var flight_full_energy_mandala_alpha := 1.0
@export_range(0.0, 4.0, 0.01) var flight_full_energy_mandala_spin := 1.0
@export_group("")

var player: Dictionary = {}
var sword: Dictionary = {}
var enemies: Array = []
var bullets: Array = []
var array_swords: Array = []
var particles: Array = []
var score_loot_pickups: Array = []
var sword_afterimages: Array = []
var sword_trail_points: Array = []
var sword_air_wakes: Array = []
var sword_return_catches: Array = []
var sword_hit_effects: Array = []
var fan_time_stop_clone_fx_nodes: Array = []
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
var large_arena_camera_center: Vector2 = BASE_ARENA_SIZE * 0.5
var large_arena_camera_zoom: float = 1.0
var large_arena_objective_ids: Dictionary = {}
var large_arena_objective_states: Dictionary = {}
var large_arena_completed: bool = false
var large_arena_pursuer_timer: float = 0.0
var large_arena_guard_timer: float = 0.0
var large_arena_interceptor_timer: float = 0.0
var large_arena_pressure_label: String = ""

var wave: int = 1
var enemies_to_spawn: int = WAVE_BASE_ENEMIES
var wave_spawn_queue: Array = []
var spawn_timer: float = 0.0
var score: int = 0
var is_game_over: bool = false
var screen_shake: float = 0.0
var elapsed_time: float = 0.0
var id_counter: int = 0
var current_melee_test_profile_index: int = 0
var status_message: String = ""
var status_message_timer: float = 0.0
var status_message_color: Color = Color.WHITE
var action_failure_cooldowns: Dictionary = {}
var energy_feedback_timer: float = 0.0
var energy_feedback_color: Color = Color.WHITE
var array_feedback_timer: float = 0.0
var array_feedback_color: Color = Color.WHITE
var score_feedback_timer: float = 0.0
var score_feedback_color: Color = Color.WHITE
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
var array_distance_guide_timer: float = 0.0
var energy_gain_feedback_timer: float = 0.0
var energy_gain_feedback_strength: float = 0.0
var energy_gain_feedback_color: Color = Color.WHITE
var sword_momentum_heat_display: float = 0.0
var sword_momentum_full_flash_timer: float = 0.0
var sword_momentum_was_full: bool = false
var hitstop_timer: float = 0.0
var hitstop_queue: Array = []
var hitstop_gap_timer: float = 0.0

var mouse_world: Vector2 = ARENA_SIZE * 0.5
var cursor_intent_previous_mouse_world: Vector2 = ARENA_SIZE * 0.5
var cursor_intent_mouse_speed: float = 0.0
var cursor_intent_fast_display: float = 0.0
var cursor_intent_last_mode: String = SwordArrayConfig.MODE_RING
var cursor_intent_mode_switch_timer: float = 0.0
var cursor_intent_pressure_score: float = 0.0
var cursor_intent_pressure_enter_timer: float = 0.0
var cursor_intent_pressure_active: bool = false
var cursor_intent_pressure_display: float = 0.0
var cursor_intent_out_of_range_display: float = 0.0
var cursor_intent_resource_display: float = 0.0
var cursor_intent_fire_kick: float = 0.0
var cursor_intent_fire_phase: float = 0.0
var sword_spirit_intent_debug: Dictionary = {}
var sword_spirit_takeover_plan: Array[String] = []
var sword_spirit_takeover_plan_index: int = 0
var sword_spirit_takeover_plan_signature: String = ""
var sword_spirit_takeover_last_mode: String = ""
var sword_spirit_takeover_last_reason: String = ""
var left_mouse_held: bool = false
var right_mouse_held: bool = false
var array_control_scheme: String = ARRAY_CONTROL_SCHEME_DISTANCE
var run_mode: String = RUN_MODE_LEGACY_WAVES
var demo_level_controller: DemoLevelController = DemoLevelController.new()
var demo_recovery_pickups: Array = []
var demo_victory_visible := false
var demo_victory_result: Dictionary = {}
var is_start_menu_active: bool = true
var start_menu: Control = null
var start_button: Button = null
var flight_start_button: Button = null
var flight_anchor_start_button: Button = null
var legacy_start_button: Button = null
var start_menu_scheme_button: Button = null
var start_menu_guide_label: RichTextLabel = null
var operation_scheme_button: Button = null
var flight_stage_timer: float = 0.0
var flight_scroll_speed: float = FLIGHT_BASE_SCROLL_SPEED
var flight_scroll_distance: float = 0.0
var flight_script_index: int = 0
var flight_stage_complete: bool = false
var flight_segment_index: int = 0
var flight_segment_label: String = "起飞校准"
var flight_heading: Vector2 = Vector2.RIGHT
var flight_visual_heading: Vector2 = Vector2.RIGHT
var flight_visual_turn_energy: float = 0.0
var flight_visual_boost_energy: float = 0.0
var flight_visual_carve_energy: float = 0.0
var flight_visual_throttle_energy: float = 0.0
var flight_visual_carve_timer: float = 0.0
var flight_visual_eight_way_index: int = 0
var legacy_flight_entry_active: bool = false
var flight_roll_timer: float = 0.0
var flight_roll_cooldown: float = 0.0
var flight_roll_direction: Vector2 = Vector2.RIGHT
var flight_skeleton_visual: Node2D = null
var rider_action_kind: String = ""
var rider_action_timer: float = 0.0
var rider_action_duration: float = 0.0
var rider_action_direction: Vector2 = Vector2.RIGHT
var rider_action_strength: float = 0.0
var rider_array_pose_active: bool = false
var rider_array_pose_mode: String = SwordArrayConfig.MODE_RING
var rider_array_visual_mode: String = SwordArrayConfig.MODE_RING
var rider_array_transition_pending_from_mode: String = SwordArrayConfig.MODE_RING
var rider_array_transition_pending_mode: String = ""
var rider_array_transition_pending_direction: Vector2 = Vector2.RIGHT
var rider_array_transition_confirm_timer: float = 0.0
var rider_array_release_visual_cooldown: float = 0.0
var lookdev_preview_time := 0.0
var lookdev_preview_loop_index := -1
var lookdev_preview_events: Dictionary = {}
var lookdev_control_panel: PanelContainer = null
var lookdev_slider_rows: Array = []
var lookdev_reset_button: Button = null
var lookdev_save_preview_button: Button = null
var lookdev_save_game_button: Button = null
var lookdev_source_sword_vfx_profile: SwordVfxProfile = null


func _is_large_arena_test_enabled() -> bool:
	return large_arena_test_enabled and _is_legacy_wave_mode() and not lookdev_mode


func _get_arena_size() -> Vector2:
	return LARGE_ARENA_SIZE if _is_large_arena_test_enabled() else BASE_ARENA_SIZE


func _get_initial_player_position() -> Vector2:
	return LARGE_ARENA_PLAYER_START if _is_large_arena_test_enabled() else BASE_ARENA_SIZE * 0.5


func _get_player_move_speed() -> float:
	if not _is_large_arena_test_enabled():
		return PLAYER_SPEED
	var speed := LARGE_ARENA_PLAYER_SPEED
	if not player.is_empty() and _is_large_arena_lower_wind_active_at(Vector2(player.get("pos", LARGE_ARENA_PLAYER_START))):
		speed *= LARGE_ARENA_WIND_SPEED_MULTIPLIER
	return speed


func _is_large_arena_lower_wind_active_at(world_pos: Vector2) -> bool:
	return (
		_is_large_arena_test_enabled()
		and _is_large_arena_objective_alive(LARGE_ARENA_LOWER_EYE_KEY)
		and LARGE_ARENA_LOWER_THREAT_RECT.has_point(world_pos)
	)


func _get_large_arena_screen_rect() -> Rect2:
	return get_viewport_rect()


func _get_large_arena_camera_half_extents() -> Vector2:
	return _get_large_arena_screen_rect().size * 0.5 / maxf(large_arena_camera_zoom, 0.001)


func _clamp_large_arena_camera_center(center: Vector2) -> Vector2:
	var arena_size := _get_arena_size()
	var half_extents := _get_large_arena_camera_half_extents()
	var min_center := half_extents
	var max_center := arena_size - half_extents
	if max_center.x < min_center.x:
		min_center.x = arena_size.x * 0.5
		max_center.x = min_center.x
	if max_center.y < min_center.y:
		min_center.y = arena_size.y * 0.5
		max_center.y = min_center.y
	return center.clamp(min_center, max_center)


func _get_large_arena_visible_world_rect() -> Rect2:
	var half_extents := _get_large_arena_camera_half_extents()
	return Rect2(large_arena_camera_center - half_extents, half_extents * 2.0)


func _get_screen_play_rect() -> Rect2:
	return _get_large_arena_screen_rect() if _is_large_arena_test_enabled() else ARENA_RECT


func get_sword_vfx_profile() -> SwordVfxProfile:
	if sword_vfx_profile == null:
		sword_vfx_profile = DEFAULT_SWORD_VFX_PROFILE
	return sword_vfx_profile


func _use_node_sword_flight_vfx() -> bool:
	return use_node_sword_flight_vfx and get_node_or_null("SwordFlightFx") != null


func _uses_legacy_flight_entry() -> bool:
	return legacy_flight_entry_active and _is_legacy_wave_mode() and not lookdev_mode


func _uses_flight_movement() -> bool:
	return _is_flight_prototype_mode() or _uses_legacy_flight_entry()


func _uses_flight_world_scroll() -> bool:
	return _is_flight_prototype_mode()


func _uses_flight_visuals() -> bool:
	return _uses_flight_movement() and not debug_calibration_mode


func _use_flight_prototype_skeleton_visual() -> bool:
	return use_flight_prototype_skeleton_visual and _uses_flight_visuals()


func _get_flight_scene_parallax_distance() -> float:
	if _uses_legacy_flight_entry() and _is_large_arena_test_enabled():
		return large_arena_camera_center.x * 0.72 + large_arena_camera_center.y * 0.08
	return flight_scroll_distance


func _use_flight_rider_sprite_fx() -> bool:
	if _use_flight_prototype_skeleton_visual():
		return false
	if _use_flight_rider_body_rig_fx():
		return false
	var rider_fx := get_node_or_null("FlightRiderSpriteFx")
	return use_flight_rider_sprite_fx and rider_fx != null and bool(rider_fx.get("enabled"))


func _use_flight_rider_body_rig_fx() -> bool:
	if _use_flight_prototype_skeleton_visual():
		return false
	var rig_fx := get_node_or_null("FlightRiderBodyRigFx")
	return use_flight_rider_body_rig_fx and rig_fx != null and bool(rig_fx.get("enabled"))


func _use_flight_rider_clean_vfx() -> bool:
	var rider_fx := get_node_or_null("FlightRiderSpriteFx")
	return (
		_uses_flight_visuals()
		and _use_flight_rider_sprite_fx()
		and rider_fx != null
		and rider_fx.has_method("uses_layered_sheets")
		and bool(rider_fx.call("uses_layered_sheets"))
	)


func _ensure_flight_skeleton_visual() -> Node2D:
	if flight_skeleton_visual != null and is_instance_valid(flight_skeleton_visual):
		return flight_skeleton_visual
	var existing := get_node_or_null("FlightPrototypeSkeletonVisual") as Node2D
	if existing != null:
		flight_skeleton_visual = existing
		return flight_skeleton_visual
	flight_skeleton_visual = HumanoidEightWaySkeletonVisual.new()
	flight_skeleton_visual.name = "FlightPrototypeSkeletonVisual"
	flight_skeleton_visual.z_as_relative = false
	flight_skeleton_visual.z_index = 18
	flight_skeleton_visual.visible = false
	add_child(flight_skeleton_visual)
	return flight_skeleton_visual


func _hide_flight_skeleton_visual() -> void:
	if flight_skeleton_visual == null:
		return
	if not is_instance_valid(flight_skeleton_visual):
		flight_skeleton_visual = null
		return
	flight_skeleton_visual.visible = false


func _reset_flight_visual_pose_state() -> void:
	var heading := flight_heading
	if heading.length_squared() <= 0.0001:
		heading = Vector2.RIGHT
	flight_visual_heading = heading.normalized()
	flight_visual_turn_energy = 0.0
	flight_visual_boost_energy = 0.0
	flight_visual_carve_energy = 0.0
	flight_visual_throttle_energy = 0.0
	flight_visual_carve_timer = 0.0
	flight_visual_eight_way_index = _get_flight_eight_way_index(flight_visual_heading)
	_hide_flight_skeleton_visual()


func _update_flight_skeleton_visual(delta: float) -> void:
	if (
		not _use_flight_prototype_skeleton_visual()
		or player.is_empty()
		or is_start_menu_active
		or is_game_over
		or demo_victory_visible
	):
		_hide_flight_skeleton_visual()
		return
	var skeleton := _ensure_flight_skeleton_visual()
	if skeleton == null:
		return
	var velocity := Vector2(player.get("vel", Vector2.ZERO))
	var target_heading := Vector2(player.get("flight_heading", flight_heading))
	if target_heading.length_squared() <= 0.0001:
		target_heading = velocity.normalized() if velocity.length_squared() > 1.0 else Vector2.RIGHT
	else:
		target_heading = target_heading.normalized()
	if flight_visual_heading.length_squared() <= 0.0001:
		flight_visual_heading = target_heading
	var visual_angle_delta := wrapf(target_heading.angle() - flight_visual_heading.angle(), -PI, PI)
	var turn_pressure := clampf(absf(visual_angle_delta) / PI, 0.0, 1.0)
	var turn_rate := lerpf(FLIGHT_VISUAL_HEADING_TURN_RATE, FLIGHT_VISUAL_HEADING_HARD_TURN_RATE, turn_pressure)
	var throttle_pressure := clampf(float(player.get("flight_afterburner", 0.0)), 0.0, 1.0)
	if velocity.length() < LEGACY_FLIGHT_CRUISE_SPEED * 0.35 or throttle_pressure <= 0.01:
		turn_rate = maxf(turn_rate, FLIGHT_VISUAL_HEADING_HOVER_TURN_RATE)
	var angle_step := clampf(visual_angle_delta, -turn_rate * delta, turn_rate * delta)
	flight_visual_heading = flight_visual_heading.rotated(angle_step).normalized()
	var speed_ratio := clampf(
		(velocity.length() - LEGACY_FLIGHT_CRUISE_SPEED) / maxf(LEGACY_FLIGHT_BOOST_SPEED - LEGACY_FLIGHT_CRUISE_SPEED, 1.0),
		0.0,
		1.0
	)
	var turn_target := clampf(absf(visual_angle_delta) / 1.35, 0.0, 1.0) * clampf(velocity.length() / LEGACY_FLIGHT_CRUISE_SPEED, 0.0, 1.0)
	if absf(visual_angle_delta) > 0.96 and velocity.length() > LEGACY_FLIGHT_CRUISE_SPEED * 0.72:
		flight_visual_carve_timer = FLIGHT_VISUAL_CARVE_DURATION
	else:
		flight_visual_carve_timer = maxf(flight_visual_carve_timer - delta, 0.0)
	var carve_target := clampf(flight_visual_carve_timer / FLIGHT_VISUAL_CARVE_DURATION, 0.0, 1.0)
	turn_target = maxf(turn_target, carve_target)
	var boost_target := maxf(speed_ratio, 0.55 if throttle_pressure > 0.01 else 0.0)
	flight_visual_boost_energy = _damp_float(flight_visual_boost_energy, boost_target, FLIGHT_VISUAL_BOOST_HALF_LIFE, delta)
	flight_visual_turn_energy = _damp_float(flight_visual_turn_energy, turn_target, FLIGHT_VISUAL_TURN_HALF_LIFE, delta)
	flight_visual_carve_energy = _damp_float(flight_visual_carve_energy, carve_target, FLIGHT_VISUAL_CARVE_HALF_LIFE, delta)
	flight_visual_throttle_energy = _damp_float(flight_visual_throttle_energy, throttle_pressure, FLIGHT_VISUAL_THROTTLE_HALF_LIFE, delta)
	flight_visual_eight_way_index = _get_flight_eight_way_index_with_hysteresis(flight_visual_heading)
	var skeleton_scale := (
		FLIGHT_PROTOTYPE_SKELETON_BASE_SCALE
		* clampf(flight_prototype_skeleton_scale, 0.1, 1.2)
		* (1.0 + 0.045 * flight_visual_boost_energy + 0.03 * flight_visual_carve_energy)
	)
	skeleton.global_position = _to_screen(Vector2(player["pos"])) + FLIGHT_PROTOTYPE_SKELETON_POSE_OFFSET + Vector2(0.0, -4.0 * flight_visual_boost_energy - 2.0 * flight_visual_carve_energy)
	skeleton.rotation = 0.0
	skeleton.scale = Vector2.ONE * skeleton_scale
	skeleton.visible = true
	if skeleton.has_method("set_flight_pose"):
		skeleton.call(
			"set_flight_pose",
			flight_visual_eight_way_index,
			flight_visual_heading,
			velocity,
			flight_visual_boost_energy,
			flight_visual_turn_energy,
			flight_visual_carve_energy,
			flight_visual_throttle_energy,
			delta
		)


func _get_flight_eight_way_index(heading: Vector2) -> int:
	var safe_heading := heading
	if safe_heading.length_squared() <= 0.0001:
		safe_heading = Vector2.RIGHT
	else:
		safe_heading = safe_heading.normalized()
	var best_index := 0
	var best_dot := -9999.0
	for index in range(FLIGHT_EIGHT_WAY_VECTORS.size()):
		var direction: Vector2 = FLIGHT_EIGHT_WAY_VECTORS[index]
		var dot_value := safe_heading.dot(direction.normalized())
		if dot_value > best_dot:
			best_dot = dot_value
			best_index = index
	return best_index


func _get_flight_eight_way_index_with_hysteresis(heading: Vector2) -> int:
	var nearest_index := _get_flight_eight_way_index(heading)
	if nearest_index == flight_visual_eight_way_index:
		return nearest_index
	if flight_visual_eight_way_index < 0 or flight_visual_eight_way_index >= FLIGHT_EIGHT_WAY_VECTORS.size():
		return nearest_index
	var safe_heading := heading
	if safe_heading.length_squared() <= 0.0001:
		safe_heading = Vector2.RIGHT
	else:
		safe_heading = safe_heading.normalized()
	var current_direction: Vector2 = FLIGHT_EIGHT_WAY_VECTORS[flight_visual_eight_way_index].normalized()
	var nearest_direction: Vector2 = FLIGHT_EIGHT_WAY_VECTORS[nearest_index].normalized()
	var current_error := absf(wrapf(safe_heading.angle() - current_direction.angle(), -PI, PI))
	var nearest_error := absf(wrapf(safe_heading.angle() - nearest_direction.angle(), -PI, PI))
	if current_error <= nearest_error + FLIGHT_EIGHT_WAY_SWITCH_HYSTERESIS:
		return flight_visual_eight_way_index
	return nearest_index


func _damp_float(current: float, target: float, half_life: float, delta: float) -> float:
	if half_life <= 0.0:
		return target
	var decay := pow(0.5, maxf(delta, 0.0) / half_life)
	return target + (current - target) * decay


func _get_sword_visual_position() -> Vector2:
	return (
		Vector2(sword.get("pos", Vector2.ZERO))
		+ Vector2(sword.get("impact_feedback_offset", Vector2.ZERO))
		+ Vector2(sword.get("hover_visual_offset", Vector2.ZERO))
	)


func _get_sword_visual_angle() -> float:
	return (
		float(sword.get("angle", 0.0))
		+ float(sword.get("impact_angle_offset", 0.0))
		+ float(sword.get("hover_visual_angle_offset", 0.0))
	)


func _get_sword_hover_blend() -> float:
	return float(sword.get("hover_idle_blend", 0.0))


func _is_held_melee_sword_active() -> bool:
	return (
		int(sword.get("state", SwordState.ORBITING)) == SwordState.ORBITING
		and int(player.get("mode", CombatMode.MELEE)) == CombatMode.MELEE
	)


func _is_melee_swing_visual_active() -> bool:
	return _is_held_melee_sword_active() and float(player.get("melee_swing_timer", 0.0)) > 0.0


func _get_melee_swing_progress() -> float:
	var swing_duration: float = maxf(float(player.get("melee_swing_duration", MELEE_SWORD_SWING_DURATION)), 0.001)
	return clampf(1.0 - float(player.get("melee_swing_timer", 0.0)) / swing_duration, 0.0, 1.0)


func _get_held_sword_aim_direction() -> Vector2:
	var aim_direction: Vector2 = mouse_world - player["pos"]
	if aim_direction.is_zero_approx():
		aim_direction = Vector2.RIGHT.rotated(float(sword.get("angle", 0.0)))
	if aim_direction.is_zero_approx():
		aim_direction = Vector2.RIGHT
	return aim_direction.normalized()


func _get_melee_sword_visual_angle() -> float:
	if _uses_flight_visuals() and _is_held_melee_sword_active():
		return float(_get_flight_held_sword_pose().get("angle", 0.0))
	var base_angle: float = _get_held_sword_aim_direction().angle()
	if not _is_melee_swing_visual_active():
		return base_angle - MELEE_SWORD_SWING_ARC * 0.5 * MELEE_SWORD_READY_SIDE
	base_angle = float(player.get("melee_swing_angle", base_angle))
	var swing_arc: float = maxf(float(player.get("melee_swing_arc", MELEE_SWORD_SWING_ARC)), 0.001)
	var swing_side: float = float(player.get("melee_swing_side", MELEE_SWORD_SWING_SIDE))
	if is_zero_approx(swing_side):
		swing_side = MELEE_SWORD_SWING_SIDE
	var swing_progress: float = _get_melee_swing_progress()
	var eased_progress: float = 1.0 - pow(1.0 - swing_progress, 3.0)
	return base_angle + lerpf(-swing_arc * 0.5, swing_arc * 0.5, eased_progress) * swing_side


func _get_held_melee_sword_position() -> Vector2:
	if _uses_flight_visuals():
		return Vector2(_get_flight_held_sword_pose().get("center", player["pos"]))
	var sword_angle: float = _get_melee_sword_visual_angle()
	var sword_forward: Vector2 = Vector2.RIGHT.rotated(sword_angle)
	if sword_forward.is_zero_approx():
		sword_forward = _get_held_sword_aim_direction()
	var swing_range: float = float(player.get("melee_swing_range", SWORD_MELEE_RANGE))
	var center_distance: float = maxf(swing_range - MELEE_SWORD_TIP_FORWARD_OFFSET, SWORD_RADIUS)
	return player["pos"] + sword_forward.normalized() * center_distance


func _flight_pose_ease(t: float) -> float:
	var clamped_t: float = clampf(t, 0.0, 1.0)
	return clamped_t * clamped_t * (3.0 - 2.0 * clamped_t)


func _get_flight_held_sword_pose() -> Dictionary:
	var visual_scale: float = clampf(flight_rider_visual_scale, 0.35, 2.4)
	var action_state: Dictionary = _get_rider_action_state()
	var action_kind: String = str(action_state.get("kind", ""))
	var action_progress: float = clampf(float(action_state.get("progress", 0.0)), 0.0, 1.0)
	var action_direction: Vector2 = Vector2(action_state.get("direction", _get_held_sword_aim_direction()))
	if action_direction.is_zero_approx():
		action_direction = _get_held_sword_aim_direction()
	if action_direction.is_zero_approx():
		action_direction = Vector2.RIGHT
	if _is_melee_swing_visual_active() and action_kind != "parry":
		action_kind = "parry"
		action_progress = _get_melee_swing_progress()
	var facing_sign: float = 1.0
	if absf(action_direction.x) > 0.28:
		facing_sign = -1.0 if action_direction.x < 0.0 else 1.0
	var flight_push: float = clampf(Vector2(player.get("vel", Vector2.ZERO)).x / maxf(FLIGHT_JET_MAX_SPEED, 1.0), -1.0, 1.0)
	if absf(action_direction.x) <= 0.28 and absf(flight_push) > 0.54:
		facing_sign = -1.0 if flight_push < 0.0 else 1.0
	var rider_fx := get_node_or_null("FlightRiderSpriteFx")
	if rider_fx != null and rider_fx.has_method("get_hand_hilt_pose"):
		var socket_pose: Dictionary = rider_fx.call("get_hand_hilt_pose", action_state)
		var local_hilt: Vector2 = Vector2(socket_pose.get("local_hilt", Vector2(36.0 * facing_sign, -24.0)))
		var sword_angle: float = float(socket_pose.get("angle", 0.0))
		var sword_forward: Vector2 = Vector2(socket_pose.get("forward", Vector2.RIGHT.rotated(sword_angle)))
		if sword_forward.is_zero_approx():
			sword_forward = Vector2.RIGHT.rotated(sword_angle)
		if sword_forward.is_zero_approx():
			sword_forward = Vector2.RIGHT
		var hilt_world: Vector2 = player["pos"] + local_hilt * visual_scale
		hilt_world += Vector2(flight_push * 2.0, sin(elapsed_time * 3.2) * 0.8)
		return {
			"center": hilt_world + sword_forward.normalized() * (18.0 * visual_scale),
			"hilt": hilt_world,
			"angle": sword_angle,
			"forward": sword_forward.normalized(),
			"facing_sign": float(socket_pose.get("facing_sign", facing_sign)),
			"frame": int(socket_pose.get("frame", 0)),
			"action": str(socket_pose.get("action", action_kind)),
		}
	var action_peak: float = sin(action_progress * PI)
	var hilt_local := Vector2(36.0 + 6.0 * absf(flight_push), -24.0 - 2.0 * absf(flight_push))
	var local_angle: float = deg_to_rad(-8.0)
	match action_kind:
		"parry":
			if action_progress < 0.48:
				var windup_t: float = _flight_pose_ease(action_progress / 0.48)
				hilt_local = Vector2(34.0, -42.0).lerp(Vector2(58.0, -16.0), windup_t)
				local_angle = lerpf(deg_to_rad(-64.0), deg_to_rad(-20.0), windup_t)
			else:
				var follow_t: float = _flight_pose_ease((action_progress - 0.48) / 0.52)
				hilt_local = Vector2(58.0, -16.0).lerp(Vector2(40.0, -7.0), follow_t)
				local_angle = lerpf(deg_to_rad(-20.0), deg_to_rad(16.0), follow_t)
		"idle_to_sword_control", "sword_control_to_idle":
			hilt_local = Vector2(36.0 + 18.0 * action_peak, -24.0 - 10.0 * action_peak)
			local_angle = lerpf(deg_to_rad(-8.0), deg_to_rad(4.0), action_peak)
		"array_release":
			hilt_local = Vector2(30.0 + 12.0 * action_peak, -25.0 - 13.0 * action_peak)
			local_angle = lerpf(deg_to_rad(-10.0), deg_to_rad(8.0), action_peak)
		"array_morph":
			hilt_local = Vector2(34.0 + 12.0 * action_peak, -25.0 - 16.0 * action_peak)
			local_angle = lerpf(deg_to_rad(-12.0), deg_to_rad(12.0), action_peak)
		_:
			if action_kind.begins_with("array_") and action_kind.ends_with("_release"):
				hilt_local = Vector2(30.0 + 12.0 * action_peak, -25.0 - 13.0 * action_peak)
				local_angle = lerpf(deg_to_rad(-10.0), deg_to_rad(8.0), action_peak)
			elif action_kind.begins_with("array_") and action_kind.find("_to_") >= 0:
				hilt_local = Vector2(34.0 + 12.0 * action_peak, -25.0 - 16.0 * action_peak)
				local_angle = lerpf(deg_to_rad(-12.0), deg_to_rad(12.0), action_peak)
	var sword_angle: float = local_angle if facing_sign > 0.0 else PI - local_angle
	var sword_forward: Vector2 = Vector2.RIGHT.rotated(sword_angle)
	var hilt_world: Vector2 = player["pos"] + Vector2(hilt_local.x * facing_sign, hilt_local.y) * visual_scale
	hilt_world += Vector2(flight_push * 3.0, sin(elapsed_time * 3.2) * 1.0)
	return {
		"center": hilt_world + sword_forward * (18.0 * visual_scale),
		"hilt": hilt_world,
		"angle": sword_angle,
		"forward": sword_forward,
		"facing_sign": facing_sign,
	}


func _trigger_rider_action(kind: String, direction: Vector2, duration: float, strength: float) -> bool:
	if not _uses_flight_visuals():
		return false
	if _use_flight_prototype_skeleton_visual():
		return false
	var normalized_direction: Vector2 = direction.normalized()
	if normalized_direction.is_zero_approx():
		normalized_direction = _get_held_sword_aim_direction()
	if normalized_direction.is_zero_approx():
		normalized_direction = Vector2.RIGHT
	if rider_action_timer > 0.0:
		var current_priority: int = _get_rider_action_priority(rider_action_kind)
		var next_priority: int = _get_rider_action_priority(kind)
		if rider_action_kind == kind:
			rider_action_direction = normalized_direction
			rider_action_strength = maxf(rider_action_strength, clampf(strength, 0.0, 2.0))
			if (
				_should_restart_repeated_rider_action(kind)
				and _get_rider_action_progress() >= RIDER_REPEATED_ACTION_RESTART_PROGRESS
			):
				rider_action_duration = maxf(duration, 0.001)
				rider_action_timer = rider_action_duration
			return true
		if (
			_is_rider_array_transition_action(rider_action_kind)
			and next_priority <= current_priority
			and _get_rider_action_progress() < RIDER_ARRAY_TRANSITION_PROTECTED_PROGRESS
		):
			return false
		if current_priority > next_priority and rider_action_timer > 0.05:
			return false
	rider_action_kind = kind
	rider_action_duration = maxf(duration, 0.001)
	rider_action_timer = rider_action_duration
	rider_action_direction = normalized_direction
	rider_action_strength = clampf(strength, 0.0, 2.0)
	return true


func _get_rider_action_priority(kind: String) -> int:
	match kind:
		"parry":
			return 50
		"idle_to_sword_control", "sword_control_to_idle":
			return 20
		_:
			if kind.begins_with("array_") and kind.find("_to_") >= 0:
				return 40
			if kind.begins_with("array_") and kind.ends_with("_release"):
				return 30
			return 0


func _should_restart_repeated_rider_action(kind: String) -> bool:
	return kind == "parry"


func _is_rider_array_transition_action(kind: String) -> bool:
	return kind.begins_with("array_") and kind.find("_to_") >= 0


func _get_rider_action_progress() -> float:
	var duration: float = maxf(rider_action_duration, 0.001)
	return 1.0 - clampf(rider_action_timer / duration, 0.0, 1.0)


func _normalize_rider_array_mode(mode: String) -> String:
	match mode:
		SwordArrayConfig.MODE_FAN:
			return SwordArrayConfig.MODE_FAN
		SwordArrayConfig.MODE_PIERCE:
			return SwordArrayConfig.MODE_PIERCE
		_:
			return SwordArrayConfig.MODE_RING


func _get_rider_array_release_action(mode: String) -> String:
	return "array_%s_release" % _normalize_rider_array_mode(mode)


func _get_rider_array_transition_action(from_mode: String, to_mode: String) -> String:
	var normalized_from: String = _normalize_rider_array_mode(from_mode)
	var normalized_to: String = _normalize_rider_array_mode(to_mode)
	if normalized_from == normalized_to:
		return ""
	return "array_%s_to_%s" % [normalized_from, normalized_to]


func _get_rider_array_enter_action(mode: String) -> String:
	return "idle_to_array_%s" % _normalize_rider_array_mode(mode)


func _get_rider_array_exit_action(mode: String) -> String:
	return "array_%s_to_idle" % _normalize_rider_array_mode(mode)


func _trigger_rider_array_release(mode: String, direction: Vector2) -> void:
	if rider_array_release_visual_cooldown > 0.0:
		return
	if _trigger_rider_action(_get_rider_array_release_action(mode), direction, RIDER_ARRAY_RELEASE_DURATION, 1.0):
		rider_array_release_visual_cooldown = RIDER_ARRAY_RELEASE_VISUAL_COOLDOWN


func _trigger_rider_array_mode_change(from_mode: String, to_mode: String, direction: Vector2) -> void:
	var normalized_to: String = _normalize_rider_array_mode(to_mode)
	var visual_from: String = _normalize_rider_array_mode(rider_array_visual_mode)
	if visual_from == normalized_to:
		rider_array_transition_pending_mode = ""
		rider_array_transition_confirm_timer = 0.0
		return
	rider_array_transition_pending_from_mode = visual_from if rider_array_pose_active else _normalize_rider_array_mode(from_mode)
	rider_array_transition_pending_mode = normalized_to
	rider_array_transition_pending_direction = direction
	rider_array_transition_confirm_timer = RIDER_ARRAY_TRANSITION_CONFIRM_DURATION


func _play_rider_array_mode_change(from_mode: String, to_mode: String, direction: Vector2) -> bool:
	var transition_action: String = _get_rider_array_transition_action(from_mode, to_mode)
	if transition_action == "":
		return true
	return _trigger_rider_action(transition_action, direction, RIDER_ARRAY_TRANSITION_DURATION, 0.72)


func _trigger_rider_sword_control_enter(direction: Vector2) -> void:
	_trigger_rider_action("idle_to_sword_control", direction, RIDER_SWORD_CONTROL_ENTER_DURATION, 1.0)


func _trigger_rider_sword_control_exit(direction: Vector2) -> void:
	_trigger_rider_action("sword_control_to_idle", direction, RIDER_SWORD_CONTROL_EXIT_DURATION, 0.85)


func _get_rider_body_array_mode() -> String:
	return _normalize_rider_array_mode(rider_array_visual_mode)


func _should_use_rider_array_idle_pose() -> bool:
	return (
		_uses_flight_visuals()
		and not _use_flight_prototype_skeleton_visual()
		and not _should_hide_sword_array_ui()
		and _is_any_array_unlocked()
	)


func _update_rider_array_pose_state() -> void:
	if not _uses_flight_visuals() or _use_flight_prototype_skeleton_visual():
		rider_array_pose_active = false
		rider_array_pose_mode = SwordArrayConfig.MODE_RING
		return
	var current_mode: String = _normalize_rider_array_mode(String(_get_sword_array_fire_state().get("dominant_mode", SwordArrayConfig.MODE_RING)))
	var is_engaged: bool = _should_use_rider_array_idle_pose()
	if is_engaged:
		if not rider_array_pose_active:
			rider_array_visual_mode = current_mode
			_trigger_rider_action(_get_rider_array_enter_action(current_mode), mouse_world - player["pos"], RIDER_ARRAY_ENTER_DURATION, 0.7)
		elif current_mode != rider_array_visual_mode and rider_array_transition_pending_mode != current_mode:
			_trigger_rider_array_mode_change(rider_array_visual_mode, current_mode, mouse_world - player["pos"])
		rider_array_pose_active = true
		rider_array_pose_mode = rider_array_visual_mode
		return
	if rider_array_pose_active:
		_trigger_rider_action(_get_rider_array_exit_action(rider_array_pose_mode), mouse_world - player["pos"], RIDER_ARRAY_EXIT_DURATION, 0.6)
	rider_array_pose_active = false
	rider_array_visual_mode = current_mode
	rider_array_pose_mode = current_mode


func _update_rider_action_state(delta: float) -> void:
	rider_array_release_visual_cooldown = maxf(rider_array_release_visual_cooldown - delta, 0.0)
	_update_rider_array_mode_change_request(delta)
	if rider_action_timer <= 0.0:
		rider_action_kind = ""
		rider_action_strength = 0.0
		return
	rider_action_timer = maxf(rider_action_timer - delta, 0.0)
	if rider_action_timer <= 0.0:
		rider_action_kind = ""
		rider_action_strength = 0.0


func _update_rider_array_mode_change_request(delta: float) -> void:
	if rider_array_transition_pending_mode == "":
		return
	rider_array_transition_confirm_timer = maxf(rider_array_transition_confirm_timer - delta, 0.0)
	if rider_array_transition_confirm_timer > 0.0:
		return
	var target_mode: String = _normalize_rider_array_mode(rider_array_transition_pending_mode)
	var from_mode: String = _normalize_rider_array_mode(rider_array_visual_mode)
	if from_mode != target_mode and not _play_rider_array_mode_change(from_mode, target_mode, rider_array_transition_pending_direction):
		return
	rider_array_visual_mode = target_mode
	rider_array_pose_mode = target_mode
	rider_array_transition_pending_from_mode = target_mode
	rider_array_transition_pending_mode = ""


func _get_rider_action_state() -> Dictionary:
	var duration: float = maxf(rider_action_duration, 0.001)
	var life_ratio: float = clampf(rider_action_timer / duration, 0.0, 1.0)
	var progress: float = 1.0 - life_ratio
	return {
		"kind": rider_action_kind,
		"timer": rider_action_timer,
		"duration": duration,
		"progress": progress,
		"life_ratio": life_ratio,
		"direction": rider_action_direction,
		"strength": rider_action_strength * life_ratio,
		"peak_strength": rider_action_strength * sin(progress * PI),
	}


func _get_sword_hover_preset_data() -> Dictionary:
	if SWORD_HOVER_PRESETS.is_empty():
		return {}
	var preset_index := clampi(sword_hover_preset, 0, SWORD_HOVER_PRESETS.size() - 1)
	return SWORD_HOVER_PRESETS[preset_index]


func _get_sword_hover_preset_name() -> String:
	var preset_data := _get_sword_hover_preset_data()
	return str(preset_data.get("name", "均衡"))


func _get_current_melee_test_profile_id() -> String:
	if MELEE_TEST_PROFILE_IDS.is_empty():
		return ""
	var profile_index: int = clampi(current_melee_test_profile_index, 0, MELEE_TEST_PROFILE_IDS.size() - 1)
	return str(MELEE_TEST_PROFILE_IDS[profile_index])


func _get_current_melee_test_profile_data() -> Dictionary:
	var profile_id: String = _get_current_melee_test_profile_id()
	return MELEE_TEST_PROFILES.get(profile_id, {})


func _get_current_melee_test_profile_name() -> String:
	return str(_get_current_melee_test_profile_data().get("name", "测试剑"))


func _get_current_melee_test_profile_traits_text() -> String:
	var profile_data: Dictionary = _get_current_melee_test_profile_data()
	var traits: Array = profile_data.get("traits", [])
	var trait_text := ""
	for index in range(traits.size()):
		if index > 0:
			trait_text += " / "
		trait_text += str(traits[index])
	return trait_text


func _get_current_melee_test_profile_hud_text() -> String:
	var trait_text: String = _get_current_melee_test_profile_traits_text()
	if trait_text == "":
		return _get_current_melee_test_profile_name()
	return "%s（%s）" % [_get_current_melee_test_profile_name(), trait_text]


func _get_melee_action_phase_text() -> String:
	match str(player.get("melee_action_phase", MELEE_ACTION_PHASE_IDLE)):
		"startup":
			return "前摇"
		"active":
			return "命中"
		"recovery":
			return "收招"
		_:
			return "待机"


func _get_current_melee_action_hud_text() -> String:
	if bool(player.get("melee_action_active", false)):
		var stage_data: Dictionary = player.get("melee_action_stage_data", {})
		var buffer_text: String = " | 已缓存" if bool(player.get("melee_input_buffered", false)) else ""
		if bool(stage_data.get("focused_action", false)) or bool(stage_data.get("focused_slash", false)):
			return "%s / %s%s" % [
				str(stage_data.get("name", "凝锋一刀")),
				_get_melee_action_phase_text(),
				buffer_text,
			]
		return "%d段 %s / %s%s" % [
			int(stage_data.get("stage", player.get("melee_combo_stage", 0))),
			str(stage_data.get("name", "普攻")),
			_get_melee_action_phase_text(),
			buffer_text,
		]
	if bool(player.get("melee_auto_combo_active", false)):
		return "凝锋一刀待发"
	return "待机"


func _cycle_melee_test_profile(direction: int) -> void:
	if MELEE_TEST_PROFILE_IDS.is_empty():
		return
	current_melee_test_profile_index = posmod(current_melee_test_profile_index + direction, MELEE_TEST_PROFILE_IDS.size())
	_clear_melee_auto_combo()
	_clear_melee_action()
	player["melee_combo_stage"] = 0
	player["melee_combo_timer"] = 0.0
	player["melee_input_buffered"] = false
	player["melee_input_buffer_timer"] = 0.0
	player["melee_shadow_strikes"] = []
	player["melee_shadow_flashes"] = []
	player["melee_flash_stage_data"] = {}
	var profile_data: Dictionary = _get_current_melee_test_profile_data()
	var profile_color: Color = profile_data.get("color", COLORS["melee_sword"])
	var message: String = "普攻测试：%s" % _get_current_melee_test_profile_hud_text()
	_show_status_message(message, profile_color, 1.2)
	_show_focus_status_message("普攻：%s" % _get_current_melee_test_profile_name(), profile_color, 0.58)
	_update_ui()
	queue_redraw()


func _matches_configured_key(event: InputEventKey, keycode: Key) -> bool:
	return keycode != KEY_NONE and event.keycode == keycode


func _get_keycode_label(keycode: Key) -> String:
	if keycode == KEY_NONE:
		return ""
	return OS.get_keycode_string(keycode)


func _get_sword_hover_preset_shortcut_hint() -> String:
	var key_parts: Array[String] = []
	var next_label := _get_keycode_label(sword_hover_preset_next_key)
	if next_label != "":
		key_parts.append(next_label)
	var previous_label := _get_keycode_label(sword_hover_preset_previous_key)
	if previous_label != "":
		key_parts.append(previous_label)
	if key_parts.is_empty():
		return "检查器设置浮空预设键"
	return "%s 切浮空预设" % " / ".join(key_parts)


func _cycle_sword_hover_preset(direction: int) -> void:
	if SWORD_HOVER_PRESETS.is_empty():
		return
	sword_hover_preset = int(posmod(sword_hover_preset + direction, SWORD_HOVER_PRESETS.size()))
	_show_status_message("浮空预设：%s" % _get_sword_hover_preset_name(), Color("88d8ff"), 1.2)


func _setup_sword_flight_vfx_environment() -> void:
	if not _use_node_sword_flight_vfx():
		return
	var viewport := get_viewport()
	if viewport != null:
		viewport.use_hdr_2d = true
	var glow_environment := get_node_or_null("SwordFlightGlowEnvironment") as WorldEnvironment
	if glow_environment == null:
		glow_environment = WorldEnvironment.new()
		glow_environment.name = "SwordFlightGlowEnvironment"
		add_child(glow_environment)
		move_child(glow_environment, 0)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CANVAS
	environment.background_canvas_max_layer = 0
	environment.glow_enabled = true
	environment.glow_normalized = true
	environment.glow_intensity = 0.72
	environment.glow_strength = 1.18
	environment.glow_bloom = 0.14
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	environment.glow_hdr_threshold = 0.72
	environment.glow_hdr_scale = 1.42
	environment.glow_map_strength = 0.0
	environment.set("glow_levels/1", 0.18)
	environment.set("glow_levels/2", 0.12)
	environment.set("glow_levels/3", 0.08)
	environment.set("glow_levels/4", 0.04)
	glow_environment.environment = environment
	_ensure_fan_time_stop_clone_flight_fx_nodes()


func _ensure_fan_time_stop_clone_flight_fx_nodes() -> void:
	fan_time_stop_clone_fx_nodes.clear()
	for side_sign in [-1.0, 1.0]:
		var node_name := "FanTimeStopSwordFlightFxLeft" if side_sign < 0.0 else "FanTimeStopSwordFlightFxRight"
		var clone_fx := get_node_or_null(node_name) as Node2D
		if clone_fx == null:
			clone_fx = SwordFlightFxScript.new()
			clone_fx.name = node_name
			clone_fx.visible = false
			clone_fx.set("source_side_sign", side_sign)
			add_child(clone_fx)
		else:
			clone_fx.set("source_side_sign", side_sign)
		_sync_fan_time_stop_clone_flight_fx_settings(clone_fx)
		fan_time_stop_clone_fx_nodes.append(clone_fx)


func _has_fan_time_stop_clone_flight_fx() -> bool:
	return _use_node_sword_flight_vfx() and not fan_time_stop_clone_fx_nodes.is_empty()


func _sync_fan_time_stop_clone_flight_fx_settings(clone_fx: Node) -> void:
	var source_fx := get_node_or_null("SwordFlightFx")
	if source_fx == null or clone_fx == null or source_fx == clone_fx:
		return
	for property_info in source_fx.get_property_list():
		var usage: int = int(property_info.get("usage", 0))
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0 or (usage & PROPERTY_USAGE_EDITOR) == 0:
			continue
		var property_name := StringName(property_info.get("name", ""))
		clone_fx.set(property_name, source_fx.get(property_name))


var debug_battle_mode: bool = false
var debug_flags: Dictionary = {}
var debug_calibration_mode: bool = false
var debug_dragging_player: bool = false
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
@onready var time_rift_fx: Node = get_node_or_null("TimeRiftFx")


func _ready() -> void:
	randomize()
	SwordArrayConfig.load_morph_distances_from_project()
	_setup_sword_flight_vfx_environment()
	_reset_game()
	_apply_demo_art_label_style()
	if lookdev_mode:
		_enter_lookdev_mode()
		return
	_build_operation_scheme_button()
	_build_start_menu()
	_update_array_control_scheme_ui()
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


func _build_operation_scheme_button() -> void:
	if operation_scheme_button != null:
		return
	operation_scheme_button = Button.new()
	operation_scheme_button.name = "OperationSchemeButton"
	operation_scheme_button.focus_mode = Control.FOCUS_NONE
	operation_scheme_button.mouse_filter = Control.MOUSE_FILTER_STOP
	operation_scheme_button.custom_minimum_size = Vector2(196.0, 34.0)
	operation_scheme_button.add_theme_font_size_override("font_size", 14)
	operation_scheme_button.add_theme_color_override("font_color", Color("d8e2ea"))
	operation_scheme_button.add_theme_color_override("font_hover_color", Color("f6fbff"))
	operation_scheme_button.add_theme_color_override("font_pressed_color", Color("f6fbff"))
	operation_scheme_button.add_theme_stylebox_override("normal", _make_start_menu_style(Color(0.06, 0.09, 0.13, 0.9), Color("7fa7c0"), 1, 6))
	operation_scheme_button.add_theme_stylebox_override("hover", _make_start_menu_style(Color(0.08, 0.13, 0.18, 0.96), Color("88d8ff"), 1, 6))
	operation_scheme_button.add_theme_stylebox_override("pressed", _make_start_menu_style(Color(0.11, 0.16, 0.13, 0.98), Color("f1e3bc"), 1, 6))
	operation_scheme_button.pressed.connect(_toggle_array_control_scheme)
	canvas_layer.add_child(operation_scheme_button)


func _process(delta: float) -> void:
	if lookdev_mode:
		_process_lookdev(delta)
		return
	if is_start_menu_active:
		_hide_flight_skeleton_visual()
		queue_redraw()
		return
	if is_game_over:
		_hide_flight_skeleton_visual()
		queue_redraw()
		return
	if demo_victory_visible:
		_hide_flight_skeleton_visual()
		if not score_loot_pickups.is_empty():
			score_loot_pickups.clear()
		_update_status_feedback(delta)
		_update_focus_status_feedback(delta)
		_update_ui()
		queue_redraw()
		return
	if _consume_hitstop(delta):
		queue_redraw()
		return

	elapsed_time += delta
	array_distance_guide_timer = maxf(array_distance_guide_timer - delta, 0.0)

	var is_flying_sword: bool = sword["state"] != SwordState.ORBITING
	if is_flying_sword:
		sword["time_slow_timer"] += delta
	else:
		sword["time_slow_timer"] = 0.0
	unsheath_flash_timer = max(unsheath_flash_timer - delta, 0.0)
	unsheath_flash_repeat_timer = max(unsheath_flash_repeat_timer - delta, 0.0)
	unsheath_press_flash_timer = max(unsheath_press_flash_timer - delta, 0.0)
	unsheath_press_flash_repeat_timer = max(unsheath_press_flash_repeat_timer - delta, 0.0)
	_update_rider_action_state(delta)

	var bullet_time_ratio: float = 1.0
	var player_time_ratio: float = 1.0
	if is_flying_sword:
		if _is_pierce_time_stop_drawing_active():
			bullet_time_ratio = PIERCE_TIME_STOP_DRAW_BULLET_TIME_MULTIPLIER
			player_time_ratio = PIERCE_TIME_STOP_DRAW_PLAYER_TIME_MULTIPLIER
		else:
			var time_slow_timer: float = float(sword["time_slow_timer"])
			bullet_time_ratio = _get_bullet_time_ratio(time_slow_timer)
			player_time_ratio = _get_player_bullet_time_ratio(time_slow_timer)

	var bullet_time_delta: float = delta * bullet_time_ratio
	var player_delta: float = delta * player_time_ratio

	if right_mouse_held:
		sword["press_timer"] += delta

	_update_array_morph_control(delta)
	_refresh_sword_array_live_state()
	SwordResonanceController.update(self, delta)
	_update_sword_momentum_state(delta)

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
	_update_rider_array_pose_state()

	_update_status_feedback(delta)
	_update_focus_status_feedback(delta)
	_update_action_feedback(delta)
	_update_array_energy_feedback_state(delta)
	_update_array_mode_confirm_feedback(delta)
	_update_player(delta, player_delta)
	_update_flight_skeleton_visual(delta)
	_update_flight_world_scroll(delta)
	_update_sword(delta)
	_trace_time_rift_sword()
	_update_boss(delta, bullet_time_delta)
	_update_enemies(bullet_time_delta, delta)
	_update_bullets(delta, bullet_time_delta)
	_update_time_rift_freeze_markers()
	_update_array_swords(delta)
	_update_particles(bullet_time_delta)
	_update_score_loot_pickups(delta)
	_update_sword_hit_effects(delta)
	if _is_large_arena_test_enabled():
		_update_large_arena_test(delta)
	elif _is_flight_prototype_mode():
		_update_flight_prototype(delta)
	elif _is_demo_level_active():
		demo_level_controller.update(self, delta)
	else:
		_update_wave(delta)
	_update_large_arena_camera(delta)
	_update_cursor_intent_indicator(delta)
	_update_sword_spirit_intent_debug()
	_apply_debug_runtime_overrides()

	if player["health"] <= 0.0:
		if not (_is_demo_level_active() and demo_level_controller.handle_player_death(self)):
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
			_update_mouse_world_from_motion(event)
			_wake_array_distance_guide()
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
				_start_game_from_menu()
		return
	if demo_victory_visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE:
				_show_start_menu()
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_start_menu()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if _handle_debug_key_input(event):
			return
		if event.keycode == KEY_SPACE:
			_toggle_selected_array_mode()
			return
	if event is InputEventMouseMotion:
		_update_mouse_world_from_motion(event)
		_wake_array_distance_guide()
		if debug_calibration_mode and debug_dragging_player:
			_set_debug_player_position(mouse_world)
	elif event is InputEventMouseButton:
		_update_mouse_world_from_button(event)
		_wake_array_distance_guide()
		if debug_calibration_mode and event.button_index == MOUSE_BUTTON_MIDDLE:
			debug_dragging_player = event.pressed
			if event.pressed:
				_set_debug_player_position(mouse_world)
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_game_over:
					_restart_current_run()
					_sync_desktop_mouse_visibility_to_game_state()
					return
				left_mouse_held = true
				if sword["state"] == SwordState.ORBITING:
					_perform_melee_attack()
			else:
				left_mouse_held = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_game_over:
				return
			if not _is_flying_sword_unlocked():
				if event.pressed:
					_show_locked_skill_feedback("flying_sword")
				right_mouse_held = false
				sword["press_timer"] = 0.0
				return
			if event.pressed:
				right_mouse_held = true
				sword["press_timer"] = 0.0
				sword["target_pos"] = mouse_world
				if sword["state"] == SwordState.ORBITING:
					_start_slicing()
			else:
				right_mouse_held = false
				if sword["state"] == SwordState.ORBITING:
					if sword["press_timer"] < SWORD_TAP_THRESHOLD:
						_start_point_strike()
				elif sword["state"] == SwordState.PIERCE_DRAWING:
					_release_pierce_time_stop_combo_sword()
				elif sword["state"] == SwordState.SLICING:
					if sword["press_timer"] < SWORD_TAP_THRESHOLD:
						_commit_quick_release_point_strike()
					else:
						sword["state"] = SwordState.RECALLING
						_trigger_time_rift_recover()


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
	panel.custom_minimum_size = Vector2(860.0, 700.0)
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
	subtitle_label.text = "破庙一夜，只凭手中剑与一口气。"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color("9cb0c2"))
	content.add_child(subtitle_label)

	start_menu_scheme_button = Button.new()
	start_menu_scheme_button.text = "操作方案"
	start_menu_scheme_button.custom_minimum_size = Vector2(0.0, 42.0)
	start_menu_scheme_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_menu_scheme_button.focus_mode = Control.FOCUS_NONE
	start_menu_scheme_button.add_theme_font_size_override("font_size", 18)
	start_menu_scheme_button.add_theme_color_override("font_color", Color("d8e2ea"))
	start_menu_scheme_button.add_theme_color_override("font_hover_color", Color("f6fbff"))
	start_menu_scheme_button.add_theme_color_override("font_pressed_color", Color("f6fbff"))
	start_menu_scheme_button.add_theme_stylebox_override("normal", _make_start_menu_style(Color(0.06, 0.09, 0.13, 0.9), Color("7fa7c0"), 1, 6))
	start_menu_scheme_button.add_theme_stylebox_override("hover", _make_start_menu_style(Color(0.08, 0.13, 0.18, 0.96), Color("88d8ff"), 1, 6))
	start_menu_scheme_button.add_theme_stylebox_override("pressed", _make_start_menu_style(Color(0.11, 0.16, 0.13, 0.98), Color("f1e3bc"), 1, 6))
	start_menu_scheme_button.pressed.connect(_toggle_array_control_scheme)
	content.add_child(start_menu_scheme_button)

	start_button = Button.new()
	start_button.text = "破庙夜袭"
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
	start_button.pressed.connect(_start_demo_level_from_menu)
	start_button.mouse_entered.connect(_show_demo_start_menu_guide)
	start_button.focus_entered.connect(_show_demo_start_menu_guide)
	content.add_child(start_button)

	flight_start_button = Button.new()
	flight_start_button.text = "御剑航行（自由）"
	flight_start_button.custom_minimum_size = Vector2(0.0, 48.0)
	flight_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flight_start_button.focus_mode = Control.FOCUS_NONE
	flight_start_button.add_theme_font_size_override("font_size", 21)
	flight_start_button.add_theme_color_override("font_color", Color("f1e3bc"))
	flight_start_button.add_theme_color_override("font_hover_color", Color("f6fbff"))
	flight_start_button.add_theme_color_override("font_pressed_color", Color("f6fbff"))
	flight_start_button.add_theme_stylebox_override("normal", _make_start_menu_style(Color(0.075, 0.115, 0.13, 0.94), Color("88d8ff"), 1, 6))
	flight_start_button.add_theme_stylebox_override("hover", _make_start_menu_style(Color(0.1, 0.16, 0.18, 0.98), Color("f1e3bc"), 1, 6))
	flight_start_button.add_theme_stylebox_override("pressed", _make_start_menu_style(Color(0.12, 0.16, 0.13, 0.98), Color("f1e3bc"), 1, 6))
	flight_start_button.pressed.connect(_start_flight_prototype_from_menu)
	flight_start_button.mouse_entered.connect(_show_flight_start_menu_guide)
	flight_start_button.focus_entered.connect(_show_flight_start_menu_guide)
	content.add_child(flight_start_button)

	flight_anchor_start_button = Button.new()
	flight_anchor_start_button.text = "御剑航行（风压回中）"
	flight_anchor_start_button.custom_minimum_size = Vector2(0.0, 44.0)
	flight_anchor_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flight_anchor_start_button.focus_mode = Control.FOCUS_NONE
	flight_anchor_start_button.add_theme_font_size_override("font_size", 19)
	flight_anchor_start_button.add_theme_color_override("font_color", Color("d8e2ea"))
	flight_anchor_start_button.add_theme_color_override("font_hover_color", Color("f6fbff"))
	flight_anchor_start_button.add_theme_color_override("font_pressed_color", Color("f6fbff"))
	flight_anchor_start_button.add_theme_stylebox_override("normal", _make_start_menu_style(Color(0.055, 0.1, 0.125, 0.94), Color("7fa7c0"), 1, 6))
	flight_anchor_start_button.add_theme_stylebox_override("hover", _make_start_menu_style(Color(0.085, 0.145, 0.17, 0.98), Color("88d8ff"), 1, 6))
	flight_anchor_start_button.add_theme_stylebox_override("pressed", _make_start_menu_style(Color(0.1, 0.15, 0.13, 0.98), Color("f1e3bc"), 1, 6))
	flight_anchor_start_button.pressed.connect(_start_flight_anchored_prototype_from_menu)
	flight_anchor_start_button.mouse_entered.connect(_show_flight_anchored_start_menu_guide)
	flight_anchor_start_button.focus_entered.connect(_show_flight_anchored_start_menu_guide)
	content.add_child(flight_anchor_start_button)

	legacy_start_button = Button.new()
	legacy_start_button.text = "旧波次入口"
	legacy_start_button.custom_minimum_size = Vector2(0.0, 42.0)
	legacy_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legacy_start_button.focus_mode = Control.FOCUS_NONE
	legacy_start_button.add_theme_font_size_override("font_size", 18)
	legacy_start_button.add_theme_color_override("font_color", Color("d8e2ea"))
	legacy_start_button.add_theme_color_override("font_hover_color", Color("f6fbff"))
	legacy_start_button.add_theme_color_override("font_pressed_color", Color("f6fbff"))
	legacy_start_button.add_theme_stylebox_override("normal", _make_start_menu_style(Color(0.06, 0.09, 0.13, 0.9), Color("7fa7c0"), 1, 6))
	legacy_start_button.add_theme_stylebox_override("hover", _make_start_menu_style(Color(0.08, 0.13, 0.18, 0.96), Color("88d8ff"), 1, 6))
	legacy_start_button.add_theme_stylebox_override("pressed", _make_start_menu_style(Color(0.11, 0.16, 0.13, 0.98), Color("f1e3bc"), 1, 6))
	legacy_start_button.pressed.connect(_start_legacy_waves_from_menu)
	legacy_start_button.mouse_entered.connect(_show_operation_start_menu_guide)
	legacy_start_button.focus_entered.connect(_show_operation_start_menu_guide)
	content.add_child(legacy_start_button)

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

	start_menu_guide_label = RichTextLabel.new()
	start_menu_guide_label.bbcode_enabled = true
	start_menu_guide_label.text = START_MENU_DEMO_TEXT
	start_menu_guide_label.custom_minimum_size = Vector2(0.0, 250.0)
	start_menu_guide_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_menu_guide_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	start_menu_guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_menu_guide_label.scroll_active = true
	start_menu_guide_label.selection_enabled = false
	start_menu_guide_label.add_theme_font_size_override("normal_font_size", 18)
	start_menu_guide_label.add_theme_font_size_override("bold_font_size", 18)
	start_menu_guide_label.add_theme_color_override("default_color", Color("d8e2ea"))
	content.add_child(start_menu_guide_label)


func _make_start_menu_style(background_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	return style


func _show_demo_start_menu_guide() -> void:
	if start_menu_guide_label != null:
		start_menu_guide_label.text = START_MENU_DEMO_TEXT


func _show_flight_start_menu_guide() -> void:
	if start_menu_guide_label != null:
		start_menu_guide_label.text = START_MENU_FLIGHT_TEXT


func _show_flight_anchored_start_menu_guide() -> void:
	if start_menu_guide_label != null:
		start_menu_guide_label.text = START_MENU_FLIGHT_ANCHORED_TEXT


func _show_operation_start_menu_guide() -> void:
	if start_menu_guide_label != null:
		start_menu_guide_label.text = START_MENU_OPERATION_TEXT if _get_array_control_scheme() == ARRAY_CONTROL_SCHEME_MANUAL else START_MENU_OPERATION_TEXT_DISTANCE


func _set_desktop_mouse_visible(visible: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED


func _sync_desktop_mouse_visibility_to_game_state() -> void:
	if is_start_menu_active or is_game_over or player.is_empty():
		_set_desktop_mouse_visible(true)
		return
	_set_desktop_mouse_visible(false)


func _set_player_combat_mode(mode: int) -> void:
	player["mode"] = mode


func _show_start_menu() -> void:
	is_start_menu_active = true
	legacy_flight_entry_active = false
	left_mouse_held = false
	right_mouse_held = false
	_hide_flight_skeleton_visual()
	_set_desktop_mouse_visible(true)
	_update_array_control_scheme_ui()
	if start_menu != null:
		start_menu.visible = true
		start_menu.move_to_front()
	if start_button != null:
		start_button.grab_focus()
	queue_redraw()


func _start_game_from_menu() -> void:
	_start_demo_level_from_menu()


func _start_demo_level_from_menu() -> void:
	_start_run_from_menu(RUN_MODE_DEMO_LEVEL)


func _start_flight_prototype_from_menu() -> void:
	_start_run_from_menu(RUN_MODE_FLIGHT_PROTOTYPE)


func _start_flight_anchored_prototype_from_menu() -> void:
	_start_run_from_menu(RUN_MODE_FLIGHT_ANCHORED_PROTOTYPE)


func _start_legacy_waves_from_menu() -> void:
	_start_run_from_menu(RUN_MODE_LEGACY_WAVES)


func _start_run_from_menu(mode: String) -> void:
	if not is_start_menu_active:
		return
	run_mode = mode
	legacy_flight_entry_active = mode == RUN_MODE_LEGACY_WAVES
	is_start_menu_active = false
	left_mouse_held = false
	right_mouse_held = false
	if start_menu != null:
		start_menu.visible = false
	_reset_game()
	if _is_demo_level_mode():
		demo_level_controller.start(self)
		_update_ui()
	elif _is_flight_prototype_mode():
		_start_flight_prototype()
		_update_ui()
	_sync_desktop_mouse_visibility_to_game_state()


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
	score_loot_pickups.clear()
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
	_trace_time_rift_sword()
	_update_time_rift_freeze_markers()
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
	_set_player_combat_mode(CombatMode.RANGED)
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
		_set_player_combat_mode(CombatMode.RANGED)
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
	_reset_large_arena_test_state()
	_reset_flight_visual_pose_state()
	if demo_level_controller != null:
		demo_level_controller.active = false
		demo_level_controller.completed = false
	demo_recovery_pickups.clear()
	demo_victory_visible = false
	demo_victory_result.clear()
	_reset_time_rift_fx()
	action_failure_cooldowns.clear()
	energy_feedback_timer = 0.0
	energy_feedback_color = Color.WHITE
	array_feedback_timer = 0.0
	array_feedback_color = Color.WHITE
	score_feedback_timer = 0.0
	score_feedback_color = Color.WHITE
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
	sword_momentum_heat_display = 0.0
	sword_momentum_full_flash_timer = 0.0
	sword_momentum_was_full = false
	array_distance_guide_timer = 0.0
	_reset_sword_spirit_takeover_state()
	_reset_cursor_intent_indicator()
	if _is_flight_prototype_mode():
		_reset_flight_prototype_state()
	elif _uses_legacy_flight_entry():
		_reset_legacy_flight_entry_state()
	elif not _is_demo_level_mode():
		_show_wave_unlock_feedback(wave)
	_sync_desktop_mouse_visibility_to_game_state()


func _restart_current_run() -> void:
	_reset_game()
	if _is_demo_level_mode():
		demo_level_controller.start(self)
		_update_ui()
	elif _is_flight_prototype_mode():
		_start_flight_prototype()
		_update_ui()
	elif _uses_legacy_flight_entry():
		_update_ui()


func _is_demo_level_mode() -> bool:
	return run_mode == RUN_MODE_DEMO_LEVEL


func _is_legacy_wave_mode() -> bool:
	return run_mode == RUN_MODE_LEGACY_WAVES


func _is_flight_free_prototype_mode() -> bool:
	return run_mode == RUN_MODE_FLIGHT_PROTOTYPE


func _is_flight_anchored_prototype_mode() -> bool:
	return run_mode == RUN_MODE_FLIGHT_ANCHORED_PROTOTYPE


func _is_flight_prototype_mode() -> bool:
	return _is_flight_free_prototype_mode() or _is_flight_anchored_prototype_mode()


func _is_demo_level_active() -> bool:
	return _is_demo_level_mode() and demo_level_controller != null and bool(demo_level_controller.active)


func _should_hide_sword_array_ui() -> bool:
	return _is_demo_level_mode() and not lookdev_mode and not debug_calibration_mode


func _reset_flight_prototype_state() -> void:
	flight_stage_timer = 0.0
	flight_scroll_speed = FLIGHT_BASE_SCROLL_SPEED
	flight_scroll_distance = 0.0
	flight_script_index = 0
	flight_stage_complete = false
	flight_segment_index = 0
	flight_segment_label = "起飞校准"
	flight_heading = Vector2.RIGHT
	_reset_flight_visual_pose_state()
	flight_roll_timer = 0.0
	flight_roll_cooldown = 0.0
	flight_roll_direction = Vector2.RIGHT
	rider_action_kind = ""
	rider_action_timer = 0.0
	rider_action_duration = 0.0
	rider_action_direction = Vector2.RIGHT
	rider_action_strength = 0.0
	rider_array_pose_active = false
	rider_array_pose_mode = SwordArrayConfig.MODE_RING
	rider_array_visual_mode = SwordArrayConfig.MODE_RING
	rider_array_transition_pending_from_mode = SwordArrayConfig.MODE_RING
	rider_array_transition_pending_mode = ""
	rider_array_transition_pending_direction = Vector2.RIGHT
	rider_array_transition_confirm_timer = 0.0
	rider_array_release_visual_cooldown = 0.0
	player["pos"] = FLIGHT_START_POS
	player["vel"] = Vector2.ZERO
	player["health"] = PLAYER_MAX_HEALTH
	player["energy"] = PLAYER_MAX_ENERGY
	player["array_selected_mode"] = SwordArrayConfig.MODE_RING
	player["array_mode"] = SwordArrayConfig.MODE_RING
	player["array_sticky_mode"] = SwordArrayConfig.MODE_RING
	mouse_world = player["pos"] + Vector2(360.0, -16.0)
	cursor_intent_previous_mouse_world = mouse_world
	sword["pos"] = player["pos"] + Vector2(34.0, -12.0)
	sword["prev_pos"] = sword["pos"]
	sword["target_pos"] = mouse_world
	sword["angle"] = 0.0
	_rebuild_array_sword_pool()
	_refresh_sword_array_live_state()


func _reset_legacy_flight_entry_state() -> void:
	flight_stage_timer = 0.0
	flight_scroll_speed = FLIGHT_BASE_SCROLL_SPEED
	flight_scroll_distance = 0.0
	flight_segment_index = 0
	flight_segment_label = "旧波次飞行"
	flight_heading = Vector2.RIGHT
	_reset_flight_visual_pose_state()
	flight_roll_timer = 0.0
	flight_roll_cooldown = 0.0
	flight_roll_direction = Vector2.RIGHT
	rider_action_kind = ""
	rider_action_timer = 0.0
	rider_action_duration = 0.0
	rider_action_direction = Vector2.RIGHT
	rider_action_strength = 0.0
	rider_array_pose_active = false
	rider_array_pose_mode = SwordArrayConfig.MODE_RING
	rider_array_visual_mode = SwordArrayConfig.MODE_RING
	rider_array_transition_pending_from_mode = SwordArrayConfig.MODE_RING
	rider_array_transition_pending_mode = ""
	rider_array_transition_pending_direction = Vector2.RIGHT
	rider_array_transition_confirm_timer = 0.0
	rider_array_release_visual_cooldown = 0.0
	player["flight_heading"] = flight_heading
	player["flight_afterburner"] = 0.0
	player["flight_brake"] = 0.0
	player["flight_roll_timer"] = 0.0
	cursor_intent_previous_mouse_world = mouse_world


func _start_flight_prototype() -> void:
	flight_segment_label = "起飞校准"
	var start_message: String = "风压回中测试开始" if _is_flight_anchored_prototype_mode() else "自由御剑测试开始"
	_show_status_message(start_message, COLORS["ranged_sword"], 1.2)
	_show_focus_status_message("云海航道", COLORS["ranged_sword"].lerp(Color.WHITE, 0.16), 0.72)


func _get_flight_lane_rect() -> Rect2:
	if _is_flight_anchored_prototype_mode():
		return Rect2(FLIGHT_ANCHOR_LANE_MIN, FLIGHT_ANCHOR_LANE_MAX - FLIGHT_ANCHOR_LANE_MIN)
	return Rect2(FLIGHT_CANVAS_MIN, FLIGHT_CANVAS_MAX - FLIGHT_CANVAS_MIN)


func _get_flight_anchor_world() -> Vector2:
	return FLIGHT_ANCHOR_POS


func _reset_large_arena_test_state() -> void:
	large_arena_camera_zoom = 1.0
	large_arena_camera_center = _get_initial_player_position()
	large_arena_objective_ids = {}
	large_arena_objective_states = {}
	large_arena_completed = false
	large_arena_pursuer_timer = 3.2
	large_arena_guard_timer = 0.5
	large_arena_interceptor_timer = 9999.0
	large_arena_pressure_label = ""
	if not _is_large_arena_test_enabled():
		return
	wave = 1
	enemies_to_spawn = 0
	wave_spawn_queue.clear()
	spawn_timer = 9999.0
	boss.clear()
	if not player.is_empty():
		player["pos"] = LARGE_ARENA_PLAYER_START
		player["vel"] = Vector2.ZERO
		player["health"] = PLAYER_MAX_HEALTH
		player["energy"] = PLAYER_MAX_ENERGY
	if not sword.is_empty():
		sword["pos"] = LARGE_ARENA_PLAYER_START
		sword["prev_pos"] = LARGE_ARENA_PLAYER_START
		sword["target_pos"] = LARGE_ARENA_PLAYER_START
		sword["vel"] = Vector2.ZERO
	mouse_world = (LARGE_ARENA_PLAYER_START + Vector2(360.0, -80.0)).clamp(Vector2.ZERO, LARGE_ARENA_SIZE)
	cursor_intent_previous_mouse_world = mouse_world
	large_arena_objective_states = {
		LARGE_ARENA_UPPER_EYE_KEY: LARGE_ARENA_STATE_VULNERABLE,
		LARGE_ARENA_LOWER_EYE_KEY: LARGE_ARENA_STATE_VULNERABLE,
		LARGE_ARENA_CORE_KEY: LARGE_ARENA_STATE_SEALED,
	}
	_spawn_large_arena_objective(FORMATION_EYE, LARGE_ARENA_UPPER_EYE_KEY, LARGE_ARENA_UPPER_EYE_POS)
	_spawn_large_arena_objective(FORMATION_EYE, LARGE_ARENA_LOWER_EYE_KEY, LARGE_ARENA_LOWER_EYE_POS)
	_spawn_large_arena_objective(FORMATION_CORE, LARGE_ARENA_CORE_KEY, LARGE_ARENA_CORE_POS)
	large_arena_camera_center = LARGE_ARENA_PLAYER_START
	game_over_label.text = "力竭身亡"
	_show_status_message("破云阵场：先破双阵眼，再斩阵心", COLORS["formation_core"], 1.8)


func _spawn_large_arena_objective(enemy_type: String, objective_key: String, position: Vector2) -> Dictionary:
	var objective: Dictionary = _spawn_enemy(enemy_type, position)
	objective["large_arena_role"] = "objective"
	objective["large_arena_objective_key"] = objective_key
	objective["large_arena_state"] = str(large_arena_objective_states.get(objective_key, LARGE_ARENA_STATE_VULNERABLE))
	objective["is_large_arena_objective"] = true
	large_arena_objective_ids[objective_key] = str(objective.get("id", ""))
	return objective


func _get_large_arena_objective(objective_key: String) -> Variant:
	var objective_id: String = str(large_arena_objective_ids.get(objective_key, ""))
	if objective_id == "":
		return null
	return _find_enemy_by_id(objective_id)


func _is_large_arena_objective_alive(objective_key: String) -> bool:
	var objective: Variant = _get_large_arena_objective(objective_key)
	return objective != null and not bool(objective.get("is_dying", false)) and float(objective.get("health", 0.0)) > 0.0


func _is_large_arena_objective_enemy(enemy: Dictionary) -> bool:
	return bool(enemy.get("is_large_arena_objective", false)) or str(enemy.get("type", "")) == FORMATION_EYE or str(enemy.get("type", "")) == FORMATION_CORE


func _get_large_arena_destroyed_eye_count() -> int:
	var destroyed := 0
	for key in [LARGE_ARENA_UPPER_EYE_KEY, LARGE_ARENA_LOWER_EYE_KEY]:
		if str(large_arena_objective_states.get(key, "")) == LARGE_ARENA_STATE_DESTROYED:
			destroyed += 1
	return destroyed


func _sync_large_arena_core_state() -> void:
	if not _is_large_arena_test_enabled() or large_arena_completed:
		return
	var core: Variant = _get_large_arena_objective(LARGE_ARENA_CORE_KEY)
	if core == null:
		return
	if _get_large_arena_destroyed_eye_count() >= 2 and str(large_arena_objective_states.get(LARGE_ARENA_CORE_KEY, "")) == LARGE_ARENA_STATE_SEALED:
		large_arena_objective_states[LARGE_ARENA_CORE_KEY] = LARGE_ARENA_STATE_VULNERABLE
		core["large_arena_state"] = LARGE_ARENA_STATE_VULNERABLE
		large_arena_interceptor_timer = 2.6
		_dismiss_large_arena_pressure_enemies("pursuer")
		_spawn_large_arena_boss()
		_show_status_message("双阵眼已破，阵心暴露", COLORS["formation_core"], 1.4)
		_create_particles(Vector2(core.get("pos", LARGE_ARENA_CORE_POS)), COLORS["formation_core"], 26)


func _spawn_large_arena_boss() -> void:
	if not _is_large_arena_test_enabled() or _has_boss():
		return
	_spawn_boss()
	if not _has_boss():
		return
	boss["large_arena_role"] = "boss"
	boss["pos"] = LARGE_ARENA_BOSS_SPAWN_POS
	boss["target_pos"] = LARGE_ARENA_BOSS_ANCHOR_POS
	boss["health"] = BOSS_MAX_HEALTH
	boss["max_health"] = BOSS_MAX_HEALTH
	boss["state_timer"] = 1.2
	_register_boss_hurtboxes()
	_create_particles(LARGE_ARENA_BOSS_ANCHOR_POS, COLORS["boss_body"], 34)
	_show_status_message("阵主现身", COLORS["boss_body"], 1.5)


func _handle_large_arena_objective_destroyed(enemy: Dictionary) -> void:
	if not _is_large_arena_test_enabled():
		return
	var objective_key: String = str(enemy.get("large_arena_objective_key", ""))
	if objective_key == "":
		return
	if str(large_arena_objective_states.get(objective_key, "")) == LARGE_ARENA_STATE_DESTROYED:
		return
	large_arena_objective_states[objective_key] = LARGE_ARENA_STATE_DESTROYED
	enemy["large_arena_state"] = LARGE_ARENA_STATE_DESTROYED
	match objective_key:
		LARGE_ARENA_UPPER_EYE_KEY:
			_dismiss_large_arena_pressure_enemies("eye_guard", objective_key)
			_show_status_message("上层阵眼破，中央炮线熄灭", COLORS["formation_eye"], 1.2)
		LARGE_ARENA_LOWER_EYE_KEY:
			_dismiss_large_arena_pressure_enemies("eye_guard", objective_key)
			_show_status_message("下层阵眼破，风场散去", COLORS["formation_eye"], 1.2)
		LARGE_ARENA_CORE_KEY:
			_complete_large_arena_test()
	_sync_large_arena_core_state()


func _complete_large_arena_test() -> void:
	if large_arena_completed:
		return
	large_arena_completed = true
	left_mouse_held = false
	right_mouse_held = false
	is_game_over = true
	game_over_label.text = "破阵功成"
	game_over_label.visible = true
	_set_desktop_mouse_visible(true)
	_show_status_message("阵心已破", COLORS["formation_core"], 2.0)


func _update_large_arena_test(delta: float) -> void:
	if not _is_large_arena_test_enabled() or large_arena_completed:
		return
	_sync_large_arena_core_state()
	_update_large_arena_pressure_fields(delta)
	_update_large_arena_spawns(delta)


func _update_large_arena_pressure_fields(delta: float) -> void:
	large_arena_pressure_label = ""
	var player_pos: Vector2 = Vector2(player.get("pos", Vector2.ZERO))
	if _is_large_arena_objective_alive(LARGE_ARENA_UPPER_EYE_KEY) and LARGE_ARENA_UPPER_THREAT_RECT.has_point(player_pos):
		large_arena_pressure_label = "中路炮线"
		if _apply_player_damage(LARGE_ARENA_THREAT_DAMAGE_PER_SECOND * delta, "large_arena_beam"):
			screen_shake = maxf(screen_shake, 1.5)
	if _is_large_arena_lower_wind_active_at(player_pos):
		large_arena_pressure_label = "下层风场"


func _update_large_arena_spawns(delta: float) -> void:
	large_arena_pursuer_timer -= delta
	large_arena_guard_timer -= delta
	large_arena_interceptor_timer -= delta
	if large_arena_pursuer_timer <= 0.0:
		large_arena_pursuer_timer = LARGE_ARENA_PURSUER_INTERVAL
		_spawn_large_arena_pursuer_if_needed()
	if large_arena_guard_timer <= 0.0:
		large_arena_guard_timer = LARGE_ARENA_GUARD_CHECK_INTERVAL
		_spawn_large_arena_guards_if_needed()
	if str(large_arena_objective_states.get(LARGE_ARENA_CORE_KEY, "")) == LARGE_ARENA_STATE_VULNERABLE and large_arena_interceptor_timer <= 0.0:
		large_arena_interceptor_timer = LARGE_ARENA_INTERCEPTOR_INTERVAL
		_spawn_large_arena_interceptor_if_needed()


func _count_large_arena_enemies(role: String, objective_key := "") -> int:
	var count := 0
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if bool(enemy.get("is_dying", false)) or float(enemy.get("health", 0.0)) <= 0.0:
			continue
		if str(enemy.get("large_arena_role", "")) != role:
			continue
		if objective_key != "" and str(enemy.get("large_arena_objective_key", "")) != objective_key:
			continue
		count += 1
	return count


func _dismiss_large_arena_pressure_enemies(role: String, objective_key := "") -> void:
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if bool(enemy.get("is_dying", false)) or float(enemy.get("health", 0.0)) <= 0.0:
			continue
		if str(enemy.get("large_arena_role", "")) != role:
			continue
		if objective_key != "" and str(enemy.get("large_arena_objective_key", "")) != objective_key:
			continue
		enemy["large_arena_dismissed"] = true
		enemy["score"] = 0
		_begin_enemy_death(enemy)


func _spawn_large_arena_pursuer_if_needed() -> void:
	if _count_large_arena_enemies("pursuer") >= LARGE_ARENA_MAX_PURSUERS:
		return
	var player_pos: Vector2 = Vector2(player.get("pos", LARGE_ARENA_PLAYER_START))
	var player_vel: Vector2 = Vector2(player.get("vel", Vector2.ZERO))
	var back_dir := -player_vel.normalized() if player_vel.length() > 20.0 else Vector2.LEFT
	var spawn_pos := (player_pos + back_dir * randf_range(330.0, 520.0) + Vector2(0.0, randf_range(-220.0, 220.0))).clamp(Vector2(40.0, 40.0), LARGE_ARENA_SIZE - Vector2(40.0, 40.0))
	var enemy: Dictionary = _spawn_enemy(RING_LEECH, spawn_pos)
	_apply_large_arena_enemy_tuning(enemy, "pursuer")
	enemy["score"] = 10


func _spawn_large_arena_guards_if_needed() -> void:
	for objective_key in [LARGE_ARENA_UPPER_EYE_KEY, LARGE_ARENA_LOWER_EYE_KEY]:
		if not _is_large_arena_objective_alive(objective_key):
			continue
		var target: Variant = _get_large_arena_objective(objective_key)
		if target == null:
			continue
		while _count_large_arena_enemies("eye_guard", objective_key) < LARGE_ARENA_GUARDS_PER_EYE:
			var angle := randf_range(-PI, PI)
			var radius := randf_range(120.0, 190.0)
			var spawn_pos := (Vector2(target.get("pos", Vector2.ZERO)) + Vector2.RIGHT.rotated(angle) * radius).clamp(Vector2(40.0, 40.0), LARGE_ARENA_SIZE - Vector2(40.0, 40.0))
			var guard: Dictionary = _spawn_enemy(SHOOTER, spawn_pos)
			_apply_large_arena_enemy_tuning(guard, "eye_guard", objective_key)
			guard["guard_angle"] = angle
			guard["guard_radius"] = radius
			guard["score"] = 12


func _spawn_large_arena_interceptor_if_needed() -> void:
	if _count_large_arena_enemies("interceptor") >= LARGE_ARENA_MAX_INTERCEPTORS:
		return
	var core_pos := LARGE_ARENA_CORE_POS
	var spawn_pos := (core_pos + Vector2(randf_range(-620.0, -360.0), randf_range(-260.0, 260.0))).clamp(Vector2(60.0, 60.0), LARGE_ARENA_SIZE - Vector2(60.0, 60.0))
	var enemy_type := HEAVY if randf() < 0.45 else SHOOTER
	var enemy: Dictionary = _spawn_enemy(enemy_type, spawn_pos)
	_apply_large_arena_enemy_tuning(enemy, "interceptor")
	enemy["score"] = 18


func _apply_large_arena_enemy_tuning(enemy: Dictionary, role: String, objective_key := "") -> void:
	enemy["large_arena_role"] = role
	if objective_key != "":
		enemy["large_arena_objective_key"] = objective_key
	match role:
		"pursuer":
			_set_enemy_max_health(enemy, LARGE_ARENA_PURSUER_HEALTH)
			enemy["move_speed_multiplier"] = LARGE_ARENA_PURSUER_SPEED_SCALE
			enemy["shoot_cooldown"] = minf(float(enemy.get("shoot_cooldown", RING_LEECH_COOLDOWN)), RING_LEECH_COOLDOWN * 0.65)
		"eye_guard":
			_set_enemy_max_health(enemy, LARGE_ARENA_GUARD_HEALTH)
			enemy["move_speed_multiplier"] = 1.0
			enemy["shoot_cooldown"] = minf(float(enemy.get("shoot_cooldown", SHOOTER_COOLDOWN)), SHOOTER_COOLDOWN * 0.75)
		"interceptor":
			if str(enemy.get("type", "")) == HEAVY:
				_set_enemy_max_health(enemy, LARGE_ARENA_INTERCEPTOR_HEAVY_HEALTH)
			else:
				_set_enemy_max_health(enemy, LARGE_ARENA_INTERCEPTOR_SHOOTER_HEALTH)
			enemy["move_speed_multiplier"] = LARGE_ARENA_INTERCEPTOR_SPEED_SCALE
			enemy["shoot_cooldown"] = minf(float(enemy.get("shoot_cooldown", SHOOTER_COOLDOWN)), SHOOTER_COOLDOWN * 0.85)
		"stray_guard":
			enemy["move_speed_multiplier"] = LARGE_ARENA_STRAY_GUARD_SPEED_SCALE


func _set_enemy_max_health(enemy: Dictionary, max_health: float) -> void:
	var resolved_health := maxf(max_health, 1.0)
	enemy["health"] = resolved_health
	enemy["max_health"] = resolved_health


func _get_enemy_move_speed_scale(enemy: Dictionary) -> float:
	return maxf(float(enemy.get("move_speed_multiplier", 1.0)), 0.0)


func _update_large_arena_enemy_role(enemy: Dictionary, delta: float) -> bool:
	var role: String = str(enemy.get("large_arena_role", ""))
	if role == "objective":
		enemy["vel"] = Vector2.ZERO
		return true
	if role != "eye_guard":
		return false
	var objective_key: String = str(enemy.get("large_arena_objective_key", ""))
	var target: Variant = _get_large_arena_objective(objective_key)
	if target == null or not _is_large_arena_objective_alive(objective_key):
		_apply_large_arena_enemy_tuning(enemy, "stray_guard")
		return false
	var angle: float = float(enemy.get("guard_angle", 0.0)) + delta * LARGE_ARENA_GUARD_ORBIT_ANGULAR_SPEED
	var radius: float = float(enemy.get("guard_radius", 150.0))
	enemy["guard_angle"] = wrapf(angle, -PI, PI)
	var target_pos: Vector2 = Vector2(target.get("pos", Vector2.ZERO))
	var player_pos: Vector2 = Vector2(player.get("pos", Vector2.ZERO))
	var desired_pos: Vector2 = target_pos + Vector2.RIGHT.rotated(angle) * radius
	if player_pos.distance_to(target_pos) <= LARGE_ARENA_GUARD_PLAYER_BIAS_RADIUS:
		desired_pos = desired_pos.lerp(player_pos, LARGE_ARENA_GUARD_PLAYER_BIAS)
	enemy["pos"] = Vector2(enemy.get("pos", Vector2.ZERO)).move_toward(desired_pos, LARGE_ARENA_GUARD_REPOSITION_SPEED * delta)
	var to_player: Vector2 = player_pos - Vector2(enemy.get("pos", Vector2.ZERO))
	enemy["shoot_cooldown"] = float(enemy.get("shoot_cooldown", 0.0)) - delta
	if enemy["shoot_cooldown"] <= 0.0 and not to_player.is_zero_approx():
		enemy["shoot_cooldown"] = SHOOTER_COOLDOWN * 0.82
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
	_clamp_enemy_to_arena(enemy)
	return true


func _update_large_arena_camera(_delta: float) -> void:
	if not _is_large_arena_test_enabled() or player.is_empty():
		large_arena_camera_center = BASE_ARENA_SIZE * 0.5
		return
	var previous_center := large_arena_camera_center
	var player_pos: Vector2 = Vector2(player.get("pos", LARGE_ARENA_PLAYER_START))
	large_arena_camera_center = player_pos
	_compensate_large_arena_virtual_cursor_for_camera(large_arena_camera_center - previous_center)


func _compensate_large_arena_virtual_cursor_for_camera(camera_delta: Vector2) -> void:
	if camera_delta.is_zero_approx() or not _should_use_virtual_mouse_motion():
		return
	mouse_world = (mouse_world + camera_delta).clamp(Vector2.ZERO, _get_arena_size())
	cursor_intent_previous_mouse_world = (cursor_intent_previous_mouse_world + camera_delta).clamp(Vector2.ZERO, _get_arena_size())


func _get_nearest_large_arena_live_objective(from_pos: Vector2) -> Variant:
	var best: Variant = null
	var best_distance := INF
	for objective_key in [LARGE_ARENA_UPPER_EYE_KEY, LARGE_ARENA_LOWER_EYE_KEY, LARGE_ARENA_CORE_KEY]:
		if str(large_arena_objective_states.get(objective_key, "")) == LARGE_ARENA_STATE_DESTROYED:
			continue
		var objective: Variant = _get_large_arena_objective(objective_key)
		if objective == null:
			continue
		var distance := from_pos.distance_to(Vector2(objective.get("pos", Vector2.ZERO)))
		if distance < best_distance:
			best_distance = distance
			best = objective
	return best


func _update_player(delta: float, player_delta: float) -> void:
	if debug_calibration_mode and debug_dragging_player:
		player["vel"] = Vector2.ZERO
		player["attack_cooldown"] = max(player["attack_cooldown"] - delta, 0.0)
		player["attack_flash_timer"] = max(player["attack_flash_timer"] - delta, 0.0)
		player["melee_swing_timer"] = maxf(float(player.get("melee_swing_timer", 0.0)) - delta, 0.0)
		_update_melee_combo_state(delta)
		return
	if _is_flight_prototype_mode():
		var move_input: Vector2 = _get_flight_control_input()
		_update_flight_jet_lancer_motion(delta, player_delta, move_input)
		_update_flight_scroll_speed(delta, move_input)
		player["attack_cooldown"] = max(player["attack_cooldown"] - delta, 0.0)
		player["attack_flash_timer"] = max(player["attack_flash_timer"] - delta, 0.0)
		player["melee_swing_timer"] = maxf(float(player.get("melee_swing_timer", 0.0)) - delta, 0.0)
		return
	if _uses_legacy_flight_entry():
		var move_input: Vector2 = _get_flight_control_input()
		_update_legacy_flight_motion(delta, player_delta, move_input)
		_update_legacy_flight_scroll_speed(delta)
		player["attack_cooldown"] = max(player["attack_cooldown"] - delta, 0.0)
		player["attack_flash_timer"] = max(player["attack_flash_timer"] - delta, 0.0)
		player["melee_swing_timer"] = maxf(float(player.get("melee_swing_timer", 0.0)) - delta, 0.0)
		_update_melee_combo_state(delta)
		return
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not move_input.is_zero_approx():
		player["vel"] = move_input.normalized() * _get_player_move_speed()
	else:
		player["vel"] = player["vel"].lerp(Vector2.ZERO, min(delta * 8.0, 1.0))
	player["pos"] += player["vel"] * player_delta
	player["pos"] = player["pos"].clamp(Vector2(PLAYER_RADIUS, PLAYER_RADIUS), _get_arena_size() - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))

	player["attack_cooldown"] = max(player["attack_cooldown"] - delta, 0.0)
	player["attack_flash_timer"] = max(player["attack_flash_timer"] - delta, 0.0)
	player["melee_swing_timer"] = maxf(float(player.get("melee_swing_timer", 0.0)) - delta, 0.0)
	_update_melee_combo_state(delta)


func _update_melee_combo_state(delta: float) -> void:
	var combo_timer: float = maxf(float(player.get("melee_combo_timer", 0.0)) - delta, 0.0)
	player["melee_combo_timer"] = combo_timer
	_update_melee_input_buffer(delta)
	_update_melee_action(delta)
	_update_melee_auto_combo(delta)
	_update_melee_shadow_strikes(delta)
	_update_melee_shadow_flashes(delta)
	if (
		is_zero_approx(combo_timer)
		and not bool(player.get("melee_auto_combo_active", false))
		and not bool(player.get("melee_action_active", false))
	):
		player["melee_combo_stage"] = 0


func _update_melee_input_buffer(delta: float) -> void:
	if not bool(player.get("melee_input_buffered", false)):
		return
	var buffer_timer: float = maxf(float(player.get("melee_input_buffer_timer", 0.0)) - delta, 0.0)
	player["melee_input_buffer_timer"] = buffer_timer
	if is_zero_approx(buffer_timer):
		player["melee_input_buffered"] = false


func _update_melee_action(delta: float) -> void:
	if not bool(player.get("melee_action_active", false)):
		return
	if not _is_held_melee_sword_active():
		_clear_melee_action()
		return
	var stage_data: Dictionary = player.get("melee_action_stage_data", {})
	var previous_elapsed: float = float(player.get("melee_action_elapsed", 0.0))
	var elapsed: float = previous_elapsed + delta
	player["melee_action_elapsed"] = elapsed
	player["melee_action_phase"] = _get_melee_action_phase_for_elapsed(stage_data, elapsed)
	var hit_time: float = maxf(float(stage_data.get("startup", 0.0)), 0.0)
	if not bool(player.get("melee_action_hit_done", false)) and previous_elapsed < hit_time and elapsed >= hit_time:
		player["melee_action_hit_done"] = true
		var attack_direction: Vector2 = Vector2(player.get("melee_action_direction", _get_melee_attack_direction()))
		_resolve_melee_action_hit(stage_data, attack_direction)
	var total_duration: float = maxf(float(stage_data.get("total_duration", player.get("melee_action_duration", 0.0))), 0.001)
	if elapsed >= total_duration:
		_finish_melee_action()


func _get_melee_action_phase_for_elapsed(stage_data: Dictionary, elapsed: float) -> String:
	var startup: float = maxf(float(stage_data.get("startup", 0.0)), 0.0)
	var active: float = maxf(float(stage_data.get("active", 0.0)), 0.0)
	if elapsed < startup:
		return MELEE_ACTION_PHASE_STARTUP
	if elapsed < startup + active:
		return MELEE_ACTION_PHASE_ACTIVE
	return MELEE_ACTION_PHASE_RECOVERY


func _resolve_melee_action_hit(stage_data: Dictionary, attack_direction: Vector2) -> void:
	player["attack_flash_duration"] = maxf(float(stage_data.get("flash_duration", MELEE_ATTACK_FLASH_DURATION)), 0.04)
	player["attack_flash_timer"] = player["attack_flash_duration"]
	player["melee_flash_color"] = stage_data.get("color", COLORS["melee_sword"])
	player["melee_flash_inner_color"] = stage_data.get("inner_color", COLORS["melee_sword"].lerp(Color.WHITE, 0.42))
	player["melee_flash_stage_data"] = stage_data
	_apply_melee_arc_attack(stage_data, attack_direction, false)
	if bool(stage_data.get("split_shadow", false)):
		_queue_melee_shadow_strike(stage_data, attack_direction)


func _finish_melee_action() -> void:
	var should_chain_buffer: bool = (
		bool(player.get("melee_input_buffered", false))
		and float(player.get("melee_input_buffer_timer", 0.0)) > 0.0
		and not bool(player.get("melee_auto_combo_active", false))
	)
	_clear_melee_action()
	if should_chain_buffer:
		player["melee_input_buffered"] = false
		player["melee_input_buffer_timer"] = 0.0
		var profile_data: Dictionary = _get_current_melee_test_profile_data()
		var next_stage: int = 1 if _is_melee_focus_profile(profile_data) else _get_next_melee_combo_stage()
		_start_melee_combo_stage(next_stage, _get_melee_attack_direction())


func _clear_melee_action() -> void:
	player["melee_action_active"] = false
	player["melee_action_phase"] = MELEE_ACTION_PHASE_IDLE
	player["melee_action_elapsed"] = 0.0
	player["melee_action_duration"] = 0.0
	player["melee_action_hit_done"] = false
	player["melee_action_stage_data"] = {}


func _update_melee_auto_combo(delta: float) -> void:
	if not bool(player.get("melee_auto_combo_active", false)):
		return
	if not _is_held_melee_sword_active():
		_clear_melee_auto_combo()
		return
	if bool(player.get("melee_action_active", false)):
		return
	var queue: Array = player.get("melee_auto_combo_queue", [])
	if queue.is_empty():
		_clear_melee_auto_combo()
		return
	var timer: float = float(player.get("melee_auto_combo_timer", 0.0)) - delta
	if timer > 0.0:
		player["melee_auto_combo_timer"] = timer
		return
	var stage_index: int = int(queue.pop_front())
	player["melee_auto_combo_queue"] = queue
	var attack_direction: Vector2 = Vector2(player.get("melee_auto_combo_direction", _get_melee_attack_direction()))
	if attack_direction.is_zero_approx():
		attack_direction = _get_melee_attack_direction()
	_start_melee_combo_stage(stage_index, attack_direction)
	player["melee_auto_combo_timer"] = MELEE_FOCUSED_CHAIN_GAP


func _clear_melee_auto_combo() -> void:
	player["melee_auto_combo_active"] = false
	player["melee_auto_combo_queue"] = []
	player["melee_auto_combo_timer"] = 0.0


func _update_melee_shadow_strikes(delta: float) -> void:
	var shadow_strikes: Array = player.get("melee_shadow_strikes", [])
	var index: int = shadow_strikes.size() - 1
	while index >= 0:
		var strike: Dictionary = shadow_strikes[index]
		strike["timer"] = float(strike.get("timer", 0.0)) - delta
		if float(strike.get("timer", 0.0)) <= 0.0:
			var stage_data: Dictionary = strike.get("stage_data", {})
			var strike_direction: Vector2 = Vector2(strike.get("direction", _get_melee_attack_direction()))
			if strike_direction.is_zero_approx():
				strike_direction = _get_melee_attack_direction()
			_apply_melee_arc_attack(stage_data, strike_direction, true)
			_push_melee_shadow_flash(stage_data, strike_direction)
			shadow_strikes.remove_at(index)
		else:
			shadow_strikes[index] = strike
		index -= 1
	player["melee_shadow_strikes"] = shadow_strikes


func _push_melee_shadow_flash(stage_data: Dictionary, attack_direction: Vector2) -> void:
	var shadow_flashes: Array = player.get("melee_shadow_flashes", [])
	var direction: Vector2 = attack_direction.normalized()
	if direction.is_zero_approx():
		direction = _get_melee_attack_direction()
	shadow_flashes.append({
		"timer": float(stage_data.get("flash_duration", MELEE_SHADOW_FLASH_DURATION)),
		"duration": float(stage_data.get("flash_duration", MELEE_SHADOW_FLASH_DURATION)),
		"angle": direction.angle() + float(stage_data.get("angle_offset", 0.0)),
		"range": float(stage_data.get("range", SWORD_MELEE_RANGE)),
		"arc": float(stage_data.get("arc", SWORD_MELEE_ARC)),
		"visual_range": float(stage_data.get("visual_range", stage_data.get("range", SWORD_MELEE_RANGE))),
		"damage_shape": str(stage_data.get("damage_shape", "broad_arc")),
		"vfx_shape": str(stage_data.get("vfx_shape", "broad_split")),
		"blade_shape": str(stage_data.get("blade_shape", "broad")),
		"spirit_shape": str(stage_data.get("spirit_shape", "split")),
		"deflect_range": float(stage_data.get("deflect_range", stage_data.get("range", SWORD_MELEE_RANGE))),
		"deflect_arc": float(stage_data.get("deflect_arc", stage_data.get("arc", SWORD_MELEE_ARC))),
		"draw_deflect_shape": false,
		"line_start_offset": float(stage_data.get("line_start_offset", 8.0)),
		"hit_width": float(stage_data.get("hit_width", MELEE_FOCUSED_SLASH_HIT_WIDTH)),
		"focused_phase": str(stage_data.get("focused_phase", "split")),
		"origin_offset": direction.orthogonal().normalized() * float(stage_data.get("origin_side_offset", 0.0)) + direction * float(stage_data.get("origin_forward_offset", 0.0)),
		"color": stage_data.get("color", Color("c084fc")),
		"inner_color": stage_data.get("inner_color", Color("e9d5ff")),
	})
	while shadow_flashes.size() > 6:
		shadow_flashes.remove_at(0)
	player["melee_shadow_flashes"] = shadow_flashes


func _update_melee_shadow_flashes(delta: float) -> void:
	var shadow_flashes: Array = player.get("melee_shadow_flashes", [])
	var index: int = shadow_flashes.size() - 1
	while index >= 0:
		var flash: Dictionary = shadow_flashes[index]
		flash["timer"] = float(flash.get("timer", 0.0)) - delta
		if float(flash.get("timer", 0.0)) <= 0.0:
			shadow_flashes.remove_at(index)
		else:
			shadow_flashes[index] = flash
		index -= 1
	player["melee_shadow_flashes"] = shadow_flashes


func _get_flight_control_input() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)


func _update_flight_jet_lancer_motion(delta: float, player_delta: float, move_input: Vector2) -> void:
	flight_roll_timer = maxf(flight_roll_timer - delta, 0.0)
	flight_roll_cooldown = maxf(flight_roll_cooldown - delta, 0.0)

	var velocity: Vector2 = Vector2(player.get("vel", Vector2.ZERO))
	if flight_heading.is_zero_approx():
		flight_heading = velocity.normalized() if velocity.length_squared() > 1.0 else Vector2.RIGHT

	var thrust_pressure: float = maxf(-move_input.y, 0.0)
	var brake_pressure: float = maxf(move_input.y, 0.0)
	var afterburner_pressure: float = 1.0 if _is_flight_afterburner_pressed() else 0.0
	var speed_ratio: float = clampf(velocity.length() / maxf(FLIGHT_JET_AFTERBURNER_MAX_SPEED, 1.0), 0.0, 1.0)
	var turn_rate: float = lerpf(FLIGHT_JET_TURN_RATE, FLIGHT_JET_HIGH_SPEED_TURN_RATE, speed_ratio)
	turn_rate += brake_pressure * FLIGHT_JET_BRAKE_TURN_BONUS
	if absf(move_input.x) > 0.01:
		flight_heading = flight_heading.rotated(move_input.x * turn_rate * delta).normalized()

	if Input.is_action_just_pressed("dash") and flight_roll_cooldown <= 0.0:
		_start_flight_roll(velocity)

	if flight_roll_timer > 0.0:
		velocity = flight_roll_direction * maxf(FLIGHT_JET_ROLL_SPEED, velocity.length() * FLIGHT_JET_ROLL_EXIT_SPEED_KEEP)
	else:
		var accel: float = thrust_pressure * FLIGHT_JET_THRUST_ACCEL + afterburner_pressure * FLIGHT_JET_AFTERBURNER_ACCEL
		if accel > 0.0:
			velocity += flight_heading * accel * delta

		var damping: float = FLIGHT_JET_GLIDE_DAMPING + brake_pressure * FLIGHT_JET_BRAKE_DAMPING
		if afterburner_pressure > 0.0:
			damping *= 0.42
		velocity = velocity.lerp(Vector2.ZERO, clampf(delta * damping, 0.0, 0.92))

		var max_speed: float = lerpf(FLIGHT_JET_MAX_SPEED, FLIGHT_JET_AFTERBURNER_MAX_SPEED, afterburner_pressure)
		if velocity.length() > max_speed:
			velocity = velocity.normalized() * max_speed

	if _is_flight_anchored_prototype_mode() and flight_roll_timer <= 0.0:
		velocity.x += (FLIGHT_ANCHOR_POS.x - float(player["pos"].x)) * FLIGHT_JET_ANCHOR_RETURN_STRENGTH * delta

	player["vel"] = velocity
	player["pos"] += velocity * player_delta
	_resolve_flight_lane_bounds()
	player["flight_heading"] = flight_heading
	player["flight_afterburner"] = afterburner_pressure
	player["flight_brake"] = brake_pressure
	player["flight_roll_timer"] = flight_roll_timer


func _update_legacy_flight_motion(delta: float, player_delta: float, move_input: Vector2) -> void:
	var velocity: Vector2 = Vector2(player.get("vel", Vector2.ZERO))
	if flight_heading.is_zero_approx():
		flight_heading = velocity.normalized() if velocity.length_squared() > 1.0 else Vector2.RIGHT
	var has_intent := not move_input.is_zero_approx()
	var boost_pressure := 1.0 if _is_legacy_flight_boost_pressed() else 0.0
	if has_intent:
		var desired_heading := move_input.normalized()
		var speed_ratio: float = clampf(velocity.length() / maxf(LEGACY_FLIGHT_BOOST_SPEED, 1.0), 0.0, 1.0)
		var turn_rate := lerpf(LEGACY_FLIGHT_TURN_RATE, LEGACY_FLIGHT_HIGH_SPEED_TURN_RATE, speed_ratio)
		var angle_delta := wrapf(desired_heading.angle() - flight_heading.angle(), -PI, PI)
		var angle_step := clampf(angle_delta, -turn_rate * delta, turn_rate * delta)
		flight_heading = flight_heading.rotated(angle_step).normalized()
	var target_speed := lerpf(LEGACY_FLIGHT_CRUISE_SPEED, LEGACY_FLIGHT_BOOST_SPEED, boost_pressure)
	if has_intent or boost_pressure > 0.0:
		var target_velocity := flight_heading * target_speed
		var accel := lerpf(LEGACY_FLIGHT_ACCELERATION, LEGACY_FLIGHT_BOOST_ACCELERATION, boost_pressure)
		velocity = velocity.move_toward(target_velocity, accel * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, clampf(delta * LEGACY_FLIGHT_GLIDE_DAMPING, 0.0, 0.9))
		if velocity.length() < 72.0:
			velocity = velocity.move_toward(Vector2.ZERO, LEGACY_FLIGHT_IDLE_BRAKE * delta)
	if velocity.length() > LEGACY_FLIGHT_BOOST_SPEED:
		velocity = velocity.normalized() * LEGACY_FLIGHT_BOOST_SPEED
	player["vel"] = velocity
	player["pos"] += velocity * player_delta
	_resolve_legacy_flight_bounds()
	player["flight_heading"] = flight_heading
	player["flight_afterburner"] = boost_pressure
	player["flight_brake"] = 0.0 if has_intent or boost_pressure > 0.0 else 1.0
	player["flight_roll_timer"] = 0.0


func _resolve_legacy_flight_bounds() -> void:
	var arena_size := _get_arena_size()
	var pos: Vector2 = Vector2(player["pos"])
	var velocity: Vector2 = Vector2(player["vel"])
	if pos.x < PLAYER_RADIUS:
		pos.x = PLAYER_RADIUS
		if velocity.x < 0.0:
			velocity.x = -velocity.x * FLIGHT_JET_BOUND_BOUNCE
	elif pos.x > arena_size.x - PLAYER_RADIUS:
		pos.x = arena_size.x - PLAYER_RADIUS
		if velocity.x > 0.0:
			velocity.x = -velocity.x * FLIGHT_JET_BOUND_BOUNCE
	if pos.y < PLAYER_RADIUS:
		pos.y = PLAYER_RADIUS
		if velocity.y < 0.0:
			velocity.y = -velocity.y * FLIGHT_JET_BOUND_BOUNCE
	elif pos.y > arena_size.y - PLAYER_RADIUS:
		pos.y = arena_size.y - PLAYER_RADIUS
		if velocity.y > 0.0:
			velocity.y = -velocity.y * FLIGHT_JET_BOUND_BOUNCE
	player["pos"] = pos
	player["vel"] = velocity


func _start_flight_roll(velocity: Vector2) -> void:
	var roll_direction: Vector2 = velocity.normalized()
	if roll_direction.is_zero_approx():
		roll_direction = flight_heading
	if roll_direction.is_zero_approx():
		roll_direction = Vector2.RIGHT
	flight_roll_direction = roll_direction
	flight_roll_timer = FLIGHT_JET_ROLL_DURATION
	flight_roll_cooldown = FLIGHT_JET_ROLL_COOLDOWN


func _resolve_flight_lane_bounds() -> void:
	var lane_min: Vector2 = FLIGHT_ANCHOR_LANE_MIN if _is_flight_anchored_prototype_mode() else FLIGHT_CANVAS_MIN
	var lane_max: Vector2 = FLIGHT_ANCHOR_LANE_MAX if _is_flight_anchored_prototype_mode() else FLIGHT_CANVAS_MAX
	var pos: Vector2 = Vector2(player["pos"])
	var velocity: Vector2 = Vector2(player["vel"])
	if pos.x < lane_min.x:
		pos.x = lane_min.x
		if velocity.x < 0.0:
			velocity.x = -velocity.x * FLIGHT_JET_BOUND_BOUNCE
	elif pos.x > lane_max.x:
		pos.x = lane_max.x
		if velocity.x > 0.0:
			velocity.x = -velocity.x * FLIGHT_JET_BOUND_BOUNCE
	if pos.y < lane_min.y:
		pos.y = lane_min.y
		if velocity.y < 0.0:
			velocity.y = -velocity.y * FLIGHT_JET_BOUND_BOUNCE
	elif pos.y > lane_max.y:
		pos.y = lane_max.y
		if velocity.y > 0.0:
			velocity.y = -velocity.y * FLIGHT_JET_BOUND_BOUNCE
	player["pos"] = pos
	player["vel"] = velocity


func _is_flight_afterburner_pressed() -> bool:
	return Input.is_key_pressed(KEY_SHIFT)


func _is_legacy_flight_boost_pressed() -> bool:
	return Input.is_action_pressed("dash") or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SPACE)


func _update_legacy_flight_scroll_speed(delta: float) -> void:
	var velocity: Vector2 = Vector2(player.get("vel", Vector2.ZERO))
	var speed_ratio: float = clampf(velocity.length() / maxf(LEGACY_FLIGHT_BOOST_SPEED, 1.0), 0.0, 1.0)
	var boost_pressure := 1.0 if _is_legacy_flight_boost_pressed() else 0.0
	var target_speed := FLIGHT_BASE_SCROLL_SPEED + speed_ratio * 82.0 + boost_pressure * 28.0
	target_speed = clampf(target_speed, FLIGHT_MIN_SCROLL_SPEED, FLIGHT_MAX_SCROLL_SPEED)
	flight_scroll_speed = lerpf(flight_scroll_speed, target_speed, minf(delta * FLIGHT_SCROLL_ACCEL, 1.0))


func _update_flight_scroll_speed(delta: float, move_input: Vector2) -> void:
	var flight_velocity: Vector2 = Vector2(player.get("vel", Vector2.ZERO))
	var forward_ratio: float = clampf(flight_velocity.x / maxf(FLIGHT_JET_MAX_SPEED, 1.0), -1.0, 1.0)
	var forward_pressure: float = maxf(forward_ratio, 0.0)
	var brake_pressure: float = maxf(-forward_ratio, maxf(move_input.y, 0.0))
	var afterburner_pressure: float = 1.0 if _is_flight_afterburner_pressed() else 0.0
	var anchor_offset_bonus := 0.0
	if _is_flight_anchored_prototype_mode():
		var anchor_offset_ratio: float = clampf((float(player["pos"].x) - FLIGHT_ANCHOR_POS.x) / 220.0, -1.0, 1.0)
		anchor_offset_bonus = anchor_offset_ratio * 28.0
	var target_speed: float = (
		FLIGHT_BASE_SCROLL_SPEED
		+ forward_pressure * FLIGHT_FORWARD_SPEED_BONUS
		- brake_pressure * FLIGHT_BACK_SPEED_BRAKE
		+ afterburner_pressure * 34.0
		+ anchor_offset_bonus
	)
	target_speed = clampf(target_speed, FLIGHT_MIN_SCROLL_SPEED, FLIGHT_MAX_SCROLL_SPEED)
	flight_scroll_speed = lerpf(flight_scroll_speed, target_speed, minf(delta * FLIGHT_SCROLL_ACCEL, 1.0))


func _update_flight_world_scroll(delta: float) -> void:
	if not _uses_flight_world_scroll():
		return
	var scroll_delta: float = flight_scroll_speed * delta
	flight_scroll_distance += scroll_delta
	var world_shift := Vector2(scroll_delta, 0.0)
	for enemy in enemies:
		enemy["pos"] = Vector2(enemy.get("pos", Vector2.ZERO)) - world_shift
		if enemy.has("package_desired_pos"):
			enemy["package_desired_pos"] = Vector2(enemy.get("package_desired_pos", enemy["pos"])) - world_shift
		if enemy.has("package_center"):
			enemy["package_center"] = Vector2(enemy.get("package_center", enemy["pos"])) - world_shift
	for bullet in bullets:
		if str(bullet.get("state", "normal")) == "deflected" or str(bullet.get("owner_id", "")) == "player":
			continue
		bullet["pos"] = Vector2(bullet.get("pos", Vector2.ZERO)) - world_shift
	for pickup in score_loot_pickups:
		pickup["pos"] = Vector2(pickup.get("pos", Vector2.ZERO)) - world_shift
	for particle in particles:
		particle["pos"] = Vector2(particle.get("pos", Vector2.ZERO)) - world_shift
	_cleanup_flight_offscreen_world()


func _cleanup_flight_offscreen_world() -> void:
	var enemy_index: int = enemies.size() - 1
	while enemy_index >= 0:
		var enemy: Dictionary = enemies[enemy_index]
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		if not bool(enemy.get("is_dying", false)) and enemy_pos.x < FLIGHT_OFFSCREEN_LEFT:
			_clear_target_runtime_state(str(enemy.get("id", "")))
			_clear_target_hurtboxes(str(enemy.get("id", "")))
			enemies.remove_at(enemy_index)
		enemy_index -= 1
	var pickup_index: int = score_loot_pickups.size() - 1
	while pickup_index >= 0:
		var pickup_pos: Vector2 = Vector2(score_loot_pickups[pickup_index].get("pos", Vector2.ZERO))
		if pickup_pos.x < FLIGHT_OFFSCREEN_LEFT:
			score_loot_pickups.remove_at(pickup_index)
		pickup_index -= 1


func _get_bullet_time_recovery_duration() -> float:
	return BULLET_TIME_RECOVERY_DURATION


func _get_bullet_time_recovery_progress(time_slow_timer: float) -> float:
	if time_slow_timer <= BULLET_TIME_ENTRY_HOLD_DURATION:
		return 0.0
	var recovery_duration: float = maxf(_get_bullet_time_recovery_duration() - BULLET_TIME_ENTRY_HOLD_DURATION, 0.001)
	return clampf((time_slow_timer - BULLET_TIME_ENTRY_HOLD_DURATION) / recovery_duration, 0.0, 1.0)


func _get_bullet_time_ratio(time_slow_timer: float) -> float:
	var recovery_progress: float = _get_bullet_time_recovery_progress(time_slow_timer)
	return lerpf(BULLET_TIME_START_MULTIPLIER, 1.0, recovery_progress)


func _get_player_bullet_time_ratio(time_slow_timer: float) -> float:
	var recovery_progress: float = _get_bullet_time_recovery_progress(time_slow_timer)
	return lerpf(PLAYER_BULLET_TIME_SPEED_MULTIPLIER, 1.0, recovery_progress)


func _trigger_time_rift_enter(direction: Vector2, anchor_world: Vector2) -> void:
	if time_rift_fx == null:
		return
	var rift_direction: Vector2 = direction.normalized()
	if rift_direction.is_zero_approx():
		rift_direction = Vector2.RIGHT
	time_rift_fx.enter_from_screen(
		_to_screen(anchor_world),
		rift_direction,
		_to_screen(player["pos"])
	)


func _trace_time_rift_sword() -> void:
	if time_rift_fx == null:
		return
	if not time_rift_fx.has_method("trace_to_screen"):
		return
	if int(sword.get("state", SwordState.ORBITING)) == SwordState.ORBITING:
		return
	time_rift_fx.trace_to_screen(_to_screen(_get_sword_visual_position()), _to_screen(player["pos"]))


func _get_fan_time_stop_clone_source(side_sign: float) -> Dictionary:
	if String(sword.get("combo_id", "")) != SwordResonanceController.COMBO_FAN_TIME_STOP:
		return {}
	var strength: float = _get_fan_time_stop_combo_strength()
	if strength <= 0.01:
		return {}
	var sword_state: int = int(sword.get("state", SwordState.ORBITING))
	if sword_state == SwordState.ORBITING:
		return {}
	var sword_angle: float = _get_sword_visual_angle()
	var forward: Vector2 = Vector2.RIGHT.rotated(sword_angle)
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var offset: Vector2 = _get_fan_time_stop_clone_offset(side_sign, strength, forward)
	var visual_pos: Vector2 = _get_sword_visual_position() + offset
	var clone_sword: Dictionary = sword.duplicate(true)
	clone_sword["state"] = sword_state
	clone_sword["pos"] = visual_pos
	clone_sword["prev_pos"] = Vector2(sword.get("prev_pos", sword.get("pos", visual_pos))) + offset
	clone_sword["target_pos"] = Vector2(sword.get("target_pos", visual_pos)) + offset
	clone_sword["vel"] = Vector2(sword.get("vel", Vector2.ZERO))
	clone_sword["angle"] = sword_angle
	return {
		"active": true,
		"sword": clone_sword,
		"visual_pos": visual_pos,
		"visual_angle": sword_angle,
		"player_mode": CombatMode.RANGED,
		"trail_points": _get_fan_time_stop_clone_trail_points(offset),
		"air_wakes": _get_fan_time_stop_clone_air_wakes(offset),
	}


func _get_fan_time_stop_combo_strength() -> float:
	var timer: float = maxf(float(sword.get("combo_timer", 0.0)), 0.0)
	var duration: float = maxf(float(sword.get("combo_duration", timer)), 0.001)
	if timer <= 0.0:
		return 0.0
	var elapsed: float = clampf(duration - timer, 0.0, duration)
	var split_progress: float = clampf(elapsed / maxf(FAN_TIME_STOP_SPLIT_DURATION, 0.001), 0.0, 1.0)
	var merge_progress: float = clampf(timer / maxf(FAN_TIME_STOP_MERGE_DURATION, 0.001), 0.0, 1.0)
	return minf(
		_get_fan_time_stop_transition_ease(split_progress),
		_get_fan_time_stop_transition_ease(merge_progress)
	)


func _get_fan_time_stop_transition_ease(progress: float) -> float:
	var value: float = clampf(progress, 0.0, 1.0)
	return value * value * (3.0 - 2.0 * value)


func _get_fan_time_stop_clone_offset(side_sign: float, strength: float, forward: Vector2) -> Vector2:
	var side: Vector2 = forward.orthogonal()
	var side_distance: float = (FAN_TIME_STOP_CLONE_SIDE_OFFSET_BASE + FAN_TIME_STOP_CLONE_SIDE_OFFSET_SCALE) * strength
	var forward_distance: float = FAN_TIME_STOP_CLONE_FORWARD_OFFSET * strength
	return side * side_sign * side_distance - forward * (forward_distance * side_sign)


func _trigger_fan_time_stop_clone_transition_effect(strength: float, particle_count: int, shake: float) -> void:
	var sword_angle: float = _get_sword_visual_angle()
	var forward: Vector2 = Vector2.RIGHT.rotated(sword_angle)
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var center: Vector2 = _get_sword_visual_position()
	var effect_color: Color = _get_resonance_color(SwordArrayConfig.MODE_FAN)
	_create_particles(center, effect_color, particle_count)
	for side_sign in [-1.0, 1.0]:
		var clone_pos: Vector2 = center + _get_fan_time_stop_clone_offset(side_sign, strength, forward)
		_create_particles(clone_pos, effect_color, particle_count)
	screen_shake = maxf(screen_shake, shake)


func _get_fan_time_stop_clone_trail_points(offset: Vector2) -> Array:
	var clone_trail_points: Array = []
	for point_variant in sword_trail_points:
		if not (point_variant is Dictionary):
			continue
		var trail_point: Dictionary = point_variant.duplicate(true)
		trail_point["pos"] = Vector2(trail_point.get("pos", Vector2.ZERO)) + offset
		clone_trail_points.append(trail_point)
	return clone_trail_points


func _get_fan_time_stop_clone_air_wakes(offset: Vector2) -> Array:
	var clone_air_wakes: Array = []
	for wake_variant in sword_air_wakes:
		if not (wake_variant is Dictionary):
			continue
		var wake: Dictionary = wake_variant.duplicate(true)
		wake["pos"] = Vector2(wake.get("pos", Vector2.ZERO)) + offset
		clone_air_wakes.append(wake)
	return clone_air_wakes


func _get_fan_time_stop_clone_attack_key(side_sign: float) -> String:
	return "left" if side_sign < 0.0 else "right"


func _get_fan_time_stop_clone_attack_instance_ids() -> Dictionary:
	var stored_ids: Variant = sword.get("fan_time_stop_clone_attack_instance_ids", {})
	if stored_ids is Dictionary:
		return stored_ids
	return {}


func _clear_fan_time_stop_clone_attack_instances() -> void:
	var clone_attack_instance_ids: Dictionary = _get_fan_time_stop_clone_attack_instance_ids()
	for attack_instance_id_variant in clone_attack_instance_ids.values():
		_clear_attack_instance(str(attack_instance_id_variant))
	sword["fan_time_stop_clone_attack_instance_ids"] = {}
	sword["fan_time_stop_clone_attack_profile_id"] = ""


func _ensure_fan_time_stop_clone_attack_instance(side_sign: float, profile_id: String) -> String:
	if String(sword.get("combo_id", "")) != SwordResonanceController.COMBO_FAN_TIME_STOP:
		return ""
	if profile_id == "":
		return ""
	var clone_attack_instance_ids: Dictionary = _get_fan_time_stop_clone_attack_instance_ids()
	var clone_key: String = _get_fan_time_stop_clone_attack_key(side_sign)
	var attack_instance_id: String = str(clone_attack_instance_ids.get(clone_key, ""))
	var attack_instances: Dictionary = combat_runtime.get("attack_instances", {})
	if attack_instance_id == "" or not attack_instances.has(attack_instance_id):
		var attack_instance: Dictionary = _build_attack_instance(profile_id, "player", "fan_time_stop_clone_%s" % clone_key)
		attack_instance_id = str(attack_instance.get("id", ""))
		clone_attack_instance_ids[clone_key] = attack_instance_id
	else:
		var attack_instance: Dictionary = attack_instances[attack_instance_id]
		attack_instance["profile_id"] = profile_id
		attack_instances[attack_instance_id] = attack_instance
		combat_runtime["attack_instances"] = attack_instances
	sword["fan_time_stop_clone_attack_instance_ids"] = clone_attack_instance_ids
	sword["fan_time_stop_clone_attack_profile_id"] = profile_id
	return attack_instance_id


func _trigger_time_rift_recover() -> void:
	if time_rift_fx == null:
		return
	time_rift_fx.begin_recover(_to_screen(player["pos"]))


func _reset_time_rift_fx() -> void:
	if time_rift_fx == null:
		return
	time_rift_fx.cancel_immediate()


func _update_time_rift_freeze_markers() -> void:
	if time_rift_fx == null:
		return
	if not time_rift_fx.has_method("set_freeze_markers"):
		return
	if time_rift_fx.has_method("is_active") and not time_rift_fx.is_active():
		time_rift_fx.set_freeze_markers([])
		return
	time_rift_fx.set_freeze_markers(_build_time_rift_freeze_markers())


func _build_time_rift_freeze_markers() -> Array:
	var markers: Array = []
	if _has_boss():
		markers.append({
			"position": _to_screen(Vector2(boss.get("pos", Vector2.ZERO)) + Vector2(boss.get("hit_reaction_offset", Vector2.ZERO))),
			"radius": BOSS_RADIUS,
			"color": COLORS["boss_body"],
			"threat": 1.35,
			"kind": "boss",
		})
	for enemy in enemies:
		if markers.size() >= TIME_RIFT_FREEZE_MARKER_LIMIT:
			break
		if float(enemy.get("health", 0.0)) <= 0.0:
			continue
		var enemy_type := str(enemy.get("type", SHOOTER))
		var enemy_color: Color = COLORS[enemy_type] if COLORS.has(enemy_type) else COLORS["health"]
		markers.append({
			"position": _to_screen(Vector2(enemy.get("pos", Vector2.ZERO)) + Vector2(enemy.get("hit_reaction_offset", Vector2.ZERO))),
			"radius": float(enemy.get("radius", SHOOTER_RADIUS)),
			"color": enemy_color,
			"threat": 1.05,
			"kind": "enemy",
		})
	for bullet in bullets:
		if markers.size() >= TIME_RIFT_FREEZE_MARKER_LIMIT:
			break
		if str(bullet.get("state", "normal")) != "normal":
			continue
		var bullet_color: Color = COLORS["bullet"]
		var raw_color = bullet.get("color", bullet_color)
		if raw_color is Color:
			bullet_color = raw_color
		if bool(bullet.get("reflectable", false)):
			bullet_color = bullet_color.lerp(COLORS["array_sword"], 0.42)
		else:
			bullet_color = bullet_color.lerp(COLORS["health"], 0.34)
		markers.append({
			"position": _to_screen(Vector2(bullet.get("pos", Vector2.ZERO))),
			"radius": maxf(float(bullet.get("radius", BULLET_RADIUS)) * 1.55, 10.0),
			"color": bullet_color,
			"threat": 0.72,
			"kind": "bullet",
		})
	return markers


func _get_unsheath_flash_progress() -> float:
	if UNSHEATH_FLASH_DURATION <= 0.0:
		return 0.0
	return clampf(unsheath_flash_timer / UNSHEATH_FLASH_DURATION, 0.0, 1.0)


func _get_unsheath_press_flash_progress() -> float:
	if UNSHEATH_PRESS_FLASH_DURATION <= 0.0:
		return 0.0
	return clampf(unsheath_press_flash_timer / UNSHEATH_PRESS_FLASH_DURATION, 0.0, 1.0)


func _get_resonance_mode() -> String:
	return SwordResonanceController.get_mode(player)


func _get_resonance_color(mode := "") -> Color:
	var resolved_mode: String = mode if mode != "" else _get_resonance_mode()
	return SwordResonanceController.get_color(resolved_mode)


func _get_resonance_display_name(mode := "") -> String:
	var resolved_mode: String = mode if mode != "" else _get_resonance_mode()
	return SwordResonanceController.get_display_name(resolved_mode)


func _get_resonance_strength() -> float:
	return SwordResonanceController.get_strength(player)


func _get_resonance_flash_strength() -> float:
	return SwordResonanceController.get_flash_strength(player)


func _get_resonance_progress() -> float:
	var mode: String = _get_resonance_mode()
	if mode == SwordResonanceController.MODE_NONE:
		return 0.0
	return clampf(
		float(player.get("resonance_timer", 0.0)) / maxf(float(player.get("resonance_duration", SwordResonanceController.RESONANCE_DURATION)), 0.001),
		0.0,
		1.0
	)


func _get_resonance_preview_strength() -> float:
	var mode: String = _get_resonance_mode()
	var base_strength: float = _get_resonance_strength()
	if mode == SwordResonanceController.MODE_NONE or base_strength <= 0.0:
		return 0.0
	var is_previewing: bool = false
	if mode == SwordArrayConfig.MODE_RING:
		is_previewing = (
			(left_mouse_held or bool(player.get("array_is_firing", false)) or float(player.get("array_hold_ratio", 0.0)) > 0.02)
			and _get_array_batch_mode() == SwordArrayConfig.MODE_PIERCE
		)
	elif mode == SwordArrayConfig.MODE_FAN or mode == SwordArrayConfig.MODE_PIERCE:
		is_previewing = right_mouse_held or int(sword.get("state", SwordState.ORBITING)) != SwordState.ORBITING
	if not is_previewing:
		return 0.0
	return base_strength * (0.74 + 0.26 * sin(elapsed_time * 12.0) * 0.5 + 0.13)


func _is_resonance_expiring() -> bool:
	return SwordResonanceController.is_expiring(player)


func _build_resonance_array_combo_state(combo_id: String, target_mode: String) -> Dictionary:
	if combo_id != SwordResonanceController.COMBO_RING_TO_PIERCE:
		return _get_sword_array_fire_state()
	var target_state: Dictionary = _build_locked_array_state(
		target_mode,
		float(player.get("array_control_distance", player["pos"].distance_to(mouse_world)))
	)
	target_state["dominant_mode"] = target_mode
	target_state["visual_from_mode"] = SwordArrayConfig.MODE_RING
	target_state["visual_to_mode"] = target_mode
	target_state["visual_blend"] = 0.86
	target_state["preset_from"] = SwordArrayConfig.get_default_preset_for_mode(SwordArrayConfig.MODE_RING)
	target_state["preset_to"] = SwordArrayConfig.get_default_preset_for_mode(target_mode)
	target_state["preset_blend"] = 0.86
	return SwordArrayConfig.complete_morph_state(target_state)


func _get_array_combo_fire_count(combo_id: String, mode: String, ready_count: int) -> int:
	if combo_id == SwordResonanceController.COMBO_RING_TO_PIERCE and mode == SwordArrayConfig.MODE_PIERCE:
		return ready_count
	return mini(_get_array_mode_batch_target(mode), ready_count)


func _start_sword_combo(combo_id: String, release_anchor: Vector2, target_pos: Vector2) -> void:
	_clear_sword_combo()
	if combo_id == SwordResonanceController.COMBO_NONE:
		return
	sword["combo_id"] = combo_id
	var duration: float = 1.05
	if combo_id == SwordResonanceController.COMBO_FAN_TIME_STOP:
		duration = FAN_TIME_STOP_COMBO_DURATION
	elif combo_id == SwordResonanceController.COMBO_PIERCE_TIME_STOP:
		duration = PIERCE_TIME_STOP_DRAW_DURATION
		sword["combo_phase"] = "drawing"
		sword["combo_release_anchor"] = release_anchor
		sword["combo_route_index"] = 1
		sword["combo_draw_distance"] = 0.0
	else:
		sword["combo_phase"] = "active"
	sword["combo_timer"] = duration
	sword["combo_duration"] = duration
	sword["combo_points"] = [release_anchor, target_pos]
	sword["combo_last_hit_pos"] = release_anchor
	var combo_color: Color = _get_resonance_color(SwordArrayConfig.MODE_FAN if combo_id == SwordResonanceController.COMBO_FAN_TIME_STOP else SwordArrayConfig.MODE_PIERCE)
	_create_particles(release_anchor, combo_color, 16)
	screen_shake = maxf(screen_shake, 3.0)
	if combo_id == SwordResonanceController.COMBO_FAN_TIME_STOP:
		_trigger_fan_time_stop_clone_transition_effect(0.0, FAN_TIME_STOP_TRANSITION_PARTICLE_COUNT, FAN_TIME_STOP_SPLIT_SHAKE)


func _clear_sword_combo() -> void:
	var combo_attack_instance_id: String = str(sword.get("combo_attack_instance_id", ""))
	if combo_attack_instance_id != "":
		_clear_attack_instance(combo_attack_instance_id)
	_clear_fan_time_stop_clone_attack_instances()
	sword["combo_id"] = SwordResonanceController.COMBO_NONE
	sword["combo_phase"] = ""
	sword["combo_timer"] = 0.0
	sword["combo_duration"] = 0.0
	sword["combo_points"] = []
	sword["combo_locked_points"] = []
	sword["combo_release_anchor"] = Vector2(sword.get("pos", player.get("pos", Vector2.ZERO)))
	sword["combo_route_index"] = 0
	sword["combo_draw_distance"] = 0.0
	sword["combo_last_hit_pos"] = Vector2(sword.get("pos", player.get("pos", Vector2.ZERO)))
	sword["combo_finish_profile_pending"] = false
	sword["combo_attack_instance_id"] = ""
	sword["combo_attack_profile_id"] = ""
	sword["fan_time_stop_clone_attack_instance_ids"] = {}
	sword["fan_time_stop_clone_attack_profile_id"] = ""


func _update_sword_combo_state(delta: float) -> void:
	var combo_id: String = String(sword.get("combo_id", SwordResonanceController.COMBO_NONE))
	if combo_id == SwordResonanceController.COMBO_NONE:
		return
	var previous_combo_timer: float = float(sword.get("combo_timer", 0.0))
	var combo_timer: float = maxf(previous_combo_timer - delta, 0.0)
	sword["combo_timer"] = combo_timer
	if (
		combo_id == SwordResonanceController.COMBO_FAN_TIME_STOP
		and previous_combo_timer > FAN_TIME_STOP_MERGE_DURATION
		and combo_timer <= FAN_TIME_STOP_MERGE_DURATION
	):
		_trigger_fan_time_stop_clone_transition_effect(1.0, FAN_TIME_STOP_TRANSITION_PARTICLE_COUNT, FAN_TIME_STOP_MERGE_SHAKE)
	if combo_id == SwordResonanceController.COMBO_PIERCE_TIME_STOP:
		var combo_phase: String = str(sword.get("combo_phase", ""))
		if combo_phase == "released" and bool(sword.get("combo_finish_profile_pending", false)) and int(sword.get("state", SwordState.ORBITING)) == SwordState.RECALLING:
			_set_sword_attack_profile(AttackProfiles.PROFILE_FLYING_SWORD_SLICE)
			sword["combo_finish_profile_pending"] = false
		if combo_phase == "drawing":
			_update_pierce_time_stop_combo_drawing()
			if combo_timer <= 0.0:
				_release_pierce_time_stop_combo_sword(true)
			return
		if combo_phase == "followthrough" and int(sword.get("state", SwordState.ORBITING)) == SwordState.POINT_STRIKE:
			return
		if combo_phase == "released" and combo_timer <= 0.0 and int(sword.get("state", SwordState.ORBITING)) != SwordState.ORBITING:
			return
	if combo_timer <= 0.0:
		_clear_sword_combo()


func _is_pierce_time_stop_drawing_active() -> bool:
	return (
		String(sword.get("combo_id", "")) == SwordResonanceController.COMBO_PIERCE_TIME_STOP
		and String(sword.get("combo_phase", "")) == "drawing"
		and int(sword.get("state", SwordState.ORBITING)) == SwordState.PIERCE_DRAWING
	)


func _is_right_mouse_intent_active() -> bool:
	return right_mouse_held or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)


func _update_pierce_time_stop_combo_drawing() -> void:
	if not _is_pierce_time_stop_drawing_active():
		return
	var anchor: Vector2 = Vector2(sword.get("combo_release_anchor", sword.get("pos", player.get("pos", Vector2.ZERO))))
	sword["pos"] = anchor
	sword["vel"] = Vector2.ZERO
	var draw_direction: Vector2 = mouse_world - anchor
	if draw_direction.is_zero_approx():
		draw_direction = mouse_world - player["pos"]
	if draw_direction.is_zero_approx():
		draw_direction = Vector2.RIGHT.rotated(float(sword.get("angle", 0.0)))
	if draw_direction.is_zero_approx():
		draw_direction = Vector2.RIGHT
	sword["angle"] = draw_direction.angle()
	sword["target_pos"] = mouse_world
	_append_pierce_time_stop_combo_point(mouse_world)
	var auto_release_draw_distance: float = PIERCE_TIME_STOP_COMBO_AUTO_RELEASE_DRAW_DISTANCE
	if auto_release_draw_distance > 0.0 and float(sword.get("combo_draw_distance", 0.0)) >= auto_release_draw_distance:
		_release_pierce_time_stop_combo_sword(true)


func _release_pierce_time_stop_combo_sword(auto_release := false) -> void:
	if String(sword.get("combo_id", "")) != SwordResonanceController.COMBO_PIERCE_TIME_STOP:
		return
	if String(sword.get("combo_phase", "")) != "drawing":
		return
	if auto_release:
		right_mouse_held = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	_append_pierce_time_stop_combo_point(mouse_world, true)
	var route_points: Array = _get_pierce_time_stop_combo_route_points()
	if route_points.size() < 2:
		var fallback_direction: Vector2 = mouse_world - player["pos"]
		if fallback_direction.is_zero_approx():
			fallback_direction = Vector2.RIGHT.rotated(float(sword.get("angle", 0.0)))
		if fallback_direction.is_zero_approx():
			fallback_direction = Vector2.RIGHT
		var fallback_anchor: Vector2 = Vector2(sword.get("combo_release_anchor", sword.get("pos", player["pos"])))
		route_points = [fallback_anchor, fallback_anchor + fallback_direction.normalized() * 160.0]
	sword["combo_phase"] = "released"
	sword["combo_points"] = route_points.duplicate()
	sword["combo_locked_points"] = route_points.duplicate()
	sword["combo_route_index"] = 1
	sword["combo_timer"] = PIERCE_TIME_STOP_RELEASE_COMBO_DURATION
	sword["combo_duration"] = PIERCE_TIME_STOP_RELEASE_COMBO_DURATION
	sword["pos"] = Vector2(route_points[0])
	sword["prev_pos"] = Vector2(route_points[0])
	sword["target_pos"] = Vector2(route_points[1])
	var launch_direction: Vector2 = Vector2(route_points[1]) - Vector2(route_points[0])
	if launch_direction.is_zero_approx():
		launch_direction = mouse_world - player["pos"]
	if launch_direction.is_zero_approx():
		launch_direction = Vector2.RIGHT
	sword["angle"] = launch_direction.angle()
	sword["vel"] = launch_direction.normalized() * SWORD_POINT_STRIKE_SPEED
	sword["state"] = SwordState.POINT_STRIKE
	sword["time_slow_timer"] = _get_bullet_time_recovery_duration()
	_set_player_combat_mode(CombatMode.RANGED)
	_start_sword_attack_instance(AttackProfiles.PROFILE_FLYING_SWORD_PIERCE_COMBO)
	var combo_color: Color = SwordResonanceController.get_color(SwordArrayConfig.MODE_PIERCE)
	_create_particles(Vector2(route_points[0]), combo_color, PIERCE_TIME_STOP_RELEASE_PARTICLE_COUNT)
	screen_shake = maxf(screen_shake, PIERCE_TIME_STOP_RELEASE_SHAKE)
	_trigger_time_rift_recover()


func _advance_pierce_time_stop_combo_route() -> bool:
	if String(sword.get("combo_id", "")) != SwordResonanceController.COMBO_PIERCE_TIME_STOP:
		return false
	if String(sword.get("combo_phase", "")) != "released":
		return false
	var route_points: Array = sword.get("combo_points", [])
	var route_index: int = int(sword.get("combo_route_index", 1)) + 1
	while route_index < route_points.size() and Vector2(route_points[route_index]).distance_to(sword["pos"]) <= PIERCE_TIME_STOP_ROUTE_REACHED_DISTANCE:
		route_index += 1
	if route_index >= route_points.size():
		return false
	sword["combo_route_index"] = route_index
	sword["target_pos"] = Vector2(route_points[route_index])
	return true


func _update_pierce_time_stop_combo_flight(delta: float) -> bool:
	if String(sword.get("combo_id", "")) != SwordResonanceController.COMBO_PIERCE_TIME_STOP:
		return false
	if String(sword.get("combo_phase", "")) != "released":
		return false
	var route_points: Array = sword.get("combo_points", [])
	if route_points.size() < 2:
		return false
	var route_index: int = clampi(int(sword.get("combo_route_index", 1)), 1, route_points.size() - 1)
	var current_pos: Vector2 = Vector2(sword["pos"])
	var previous_pos: Vector2 = current_pos
	var remaining_distance: float = SWORD_POINT_STRIKE_SPEED * PIERCE_TIME_STOP_COMBO_FLIGHT_SPEED_MULTIPLIER * delta
	while remaining_distance > 0.0 and route_index < route_points.size():
		var target_pos: Vector2 = Vector2(route_points[route_index])
		var to_target: Vector2 = target_pos - current_pos
		var target_distance: float = to_target.length()
		if target_distance <= PIERCE_TIME_STOP_ROUTE_REACHED_DISTANCE:
			current_pos = target_pos
			route_index += 1
			continue
		var travel_distance: float = minf(remaining_distance, target_distance)
		var travel_direction: Vector2 = to_target / target_distance
		current_pos += travel_direction * travel_distance
		remaining_distance -= travel_distance
		if target_distance - travel_distance <= PIERCE_TIME_STOP_ROUTE_REACHED_DISTANCE:
			current_pos = target_pos
			route_index += 1
			continue
		break
	sword["pos"] = current_pos
	var frame_velocity: Vector2 = (current_pos - previous_pos) / maxf(delta, 0.001)
	sword["vel"] = frame_velocity
	if frame_velocity.length_squared() > 1.0:
		sword["angle"] = frame_velocity.angle()
	if route_index >= route_points.size():
		_finish_pierce_time_stop_combo_flight()
	else:
		sword["combo_route_index"] = route_index
		sword["target_pos"] = Vector2(route_points[route_index])
	return true


func _finish_pierce_time_stop_combo_flight() -> void:
	var combo_color: Color = SwordResonanceController.get_color(SwordArrayConfig.MODE_PIERCE)
	if _is_right_mouse_intent_active():
		if sword["pos"].distance_to(mouse_world) <= 18.0:
			_hold_pierce_combo_sword_at_mouse(combo_color)
			return
		var follow_direction: Vector2 = mouse_world - sword["pos"]
		if follow_direction.is_zero_approx():
			follow_direction = Vector2.RIGHT.rotated(float(sword.get("angle", 0.0)))
		if follow_direction.is_zero_approx():
			follow_direction = Vector2.RIGHT
		sword["state"] = SwordState.POINT_STRIKE
		sword["target_pos"] = mouse_world
		sword["vel"] = follow_direction.normalized() * SWORD_POINT_STRIKE_SPEED
		sword["angle"] = follow_direction.angle()
		sword["combo_phase"] = "followthrough"
		sword["combo_timer"] = 0.18
		sword["combo_duration"] = 0.18
		sword["combo_finish_profile_pending"] = false
		_set_player_combat_mode(CombatMode.RANGED)
		_create_particles(sword["pos"], combo_color, 10)
		screen_shake = max(screen_shake, 3.5)
		return
	sword["state"] = SwordState.RECALLING
	sword["combo_finish_profile_pending"] = true
	_trigger_time_rift_recover()
	_create_particles(sword["pos"], combo_color, 18)
	screen_shake = max(screen_shake, 6.0)


func _hold_pierce_combo_sword_at_mouse(combo_color: Color) -> void:
	var hold_direction: Vector2 = mouse_world - sword["pos"]
	if hold_direction.is_zero_approx():
		hold_direction = Vector2.RIGHT.rotated(float(sword.get("angle", 0.0)))
	if hold_direction.is_zero_approx():
		hold_direction = Vector2.RIGHT
	sword["pos"] = mouse_world
	sword["prev_pos"] = mouse_world
	sword["target_pos"] = mouse_world
	sword["vel"] = Vector2.ZERO
	sword["angle"] = hold_direction.angle()
	sword["state"] = SwordState.SLICING
	sword["combo_phase"] = "held"
	sword["combo_timer"] = 0.16
	sword["combo_duration"] = 0.16
	sword["combo_finish_profile_pending"] = false
	_set_player_combat_mode(CombatMode.RANGED)
	_set_sword_attack_profile(AttackProfiles.PROFILE_FLYING_SWORD_SLICE)
	_create_particles(sword["pos"], combo_color, 8)
	screen_shake = max(screen_shake, 3.0)


func _get_pierce_time_stop_combo_route_points() -> Array:
	var raw_points: Array = sword.get("combo_points", [])
	var route_points: Array = []
	for point_variant in raw_points:
		var point: Vector2 = Vector2(point_variant)
		if route_points.is_empty() or Vector2(route_points[route_points.size() - 1]).distance_to(point) > PIERCE_TIME_STOP_COMBO_MIN_SWEEP_DISTANCE:
			route_points.append(point)
	return route_points


func _append_pierce_time_stop_combo_point(sample_pos: Vector2, force := false) -> void:
	var combo_points: Array = sword.get("combo_points", [])
	var spacing: float = PIERCE_TIME_STOP_COMBO_MIN_SWEEP_DISTANCE if force else PIERCE_TIME_STOP_COMBO_POINT_SPACING
	if combo_points.is_empty() or Vector2(combo_points[combo_points.size() - 1]).distance_to(sample_pos) > spacing:
		if String(sword.get("combo_phase", "")) == "drawing" and not combo_points.is_empty():
			sword["combo_draw_distance"] = float(sword.get("combo_draw_distance", 0.0)) + Vector2(combo_points[combo_points.size() - 1]).distance_to(sample_pos)
		combo_points.append(sample_pos)
	while combo_points.size() > PIERCE_TIME_STOP_COMBO_MAX_POINTS:
		if String(sword.get("combo_phase", "")) == "drawing" and combo_points.size() > 1:
			combo_points.remove_at(1)
		else:
			combo_points.remove_at(0)
	sword["combo_points"] = combo_points


func _can_use_array_attack() -> bool:
	if _should_hide_sword_array_ui():
		return false
	if not left_mouse_held:
		return false
	if float(player.get("array_hold_timer", 0.0)) < SwordArrayConfig.HOLD_THRESHOLD:
		return false
	if not _is_any_array_unlocked():
		_show_locked_skill_feedback(SwordArrayConfig.MODE_RING)
		return false
	var mode: String = _get_effective_array_batch_mode()
	if not _is_array_mode_unlocked(mode):
		_show_locked_skill_feedback(mode)
		return false
	return true


func _get_active_array_sword_count() -> int:
	return array_swords.size()


func _get_current_array_sword_capacity() -> int:
	if _should_hide_sword_array_ui():
		return 0
	return ARRAY_SWORD_COUNT


func _get_array_sortie_profile(mode: String) -> Dictionary:
	return SwordArrayConfig.get_profile(mode)


func _should_array_consume_energy() -> bool:
	if _is_flight_prototype_mode():
		return false
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
		"combo_id": "",
		"combo_timer": 0.0,
		"combo_duration": 0.0,
		"travel_mode": SwordArrayConfig.MODE_RING,
		"trail_timer": 0.0,
		"guidance_active": false,
		"guidance_elapsed": 0.0,
		"guidance_distance": 0.0,
		"guidance_fire_index": - 1,
		"guidance_volley_count": - 1,
		"guidance_burst_step": 0,
		"guidance_total_count": - 1,
		"guidance_state_source": {},
		"guidance_override_target_pos": Vector2.ZERO,
		"guidance_override_target_kind": "",
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
	array_sword["guidance_state_source"] = {}
	array_sword["guidance_override_target_pos"] = Vector2.ZERO
	array_sword["guidance_override_target_kind"] = ""
	array_sword["has_hit_target"] = false
	array_sword["remaining_penetration"] = _get_array_sword_penetration_targets(travel_mode)
	array_sword["hit_target_cooldowns"] = {}
	array_sword["combo_id"] = ""
	array_sword["combo_timer"] = 0.0
	array_sword["combo_duration"] = 0.0
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
	score_feedback_timer = maxf(score_feedback_timer - delta, 0.0)
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
	if _should_hide_sword_array_ui():
		array_energy_forecast_level = ArrayEnergyForecastLevel.NONE
		array_energy_warning_display = 0.0
		array_energy_break_timer = 0.0
		return
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
	if _should_hide_sword_array_ui():
		array_mode_confirm_timer = 0.0
		array_mode_confirm_cooldown = 0.0
		array_mode_confirm_mode = ""
		return
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


func _is_flying_sword_unlocked() -> bool:
	if _is_large_arena_test_enabled():
		return true
	if _is_demo_level_mode():
		return true
	if _is_flight_prototype_mode():
		return true
	return lookdev_mode or debug_calibration_mode or wave >= UNLOCK_WAVE_FLYING_SWORD


func _is_array_mode_unlocked(mode: String) -> bool:
	if _is_large_arena_test_enabled() or lookdev_mode or debug_calibration_mode:
		return true
	if _is_flight_prototype_mode():
		return true
	if _should_hide_sword_array_ui():
		return false
	match mode:
		SwordArrayConfig.MODE_PIERCE:
			return wave >= UNLOCK_WAVE_ARRAY_PIERCE
		SwordArrayConfig.MODE_FAN:
			return wave >= UNLOCK_WAVE_ARRAY_FAN
		SwordArrayConfig.MODE_RING:
			return wave >= UNLOCK_WAVE_ARRAY_RING
	return false


func _is_any_array_unlocked() -> bool:
	return _is_array_mode_unlocked(SwordArrayConfig.MODE_RING)


func _get_locked_skill_failure_message(skill_id: String) -> String:
	match skill_id:
		"flying_sword":
			return "御剑未解锁"
		SwordArrayConfig.MODE_RING:
			return "环阵未解锁"
		SwordArrayConfig.MODE_FAN:
			return "扇阵未解锁"
		SwordArrayConfig.MODE_PIERCE:
			return "贯穿阵未解锁"
		_:
			return "剑阵未解锁"


func _get_unlock_color(skill_id: String) -> Color:
	match skill_id:
		"melee":
			return COLORS["melee_sword"]
		"flying_sword":
			return COLORS["ranged_sword"]
		SwordArrayConfig.MODE_RING:
			return Color(SwordArrayConfig.get_profile(SwordArrayConfig.MODE_RING).get("accent_color", COLORS["array_sword"]))
		SwordArrayConfig.MODE_FAN:
			return Color(SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN).get("accent_color", COLORS["array_sword"]))
		SwordArrayConfig.MODE_PIERCE:
			return Color(SwordArrayConfig.get_profile(SwordArrayConfig.MODE_PIERCE).get("accent_color", COLORS["array_sword"]))
	return COLORS["array_sword"]


func _show_locked_skill_feedback(skill_id: String) -> void:
	var color: Color = _get_unlock_color(skill_id).lerp(COLORS["health"], 0.35)
	_show_action_failure(
		_get_locked_skill_failure_message(skill_id),
		"skill_locked_%s" % skill_id,
		color,
		"array" if skill_id != "flying_sword" else "",
		0.78
	)


func _show_wave_unlock_feedback(wave_index: int) -> void:
	var unlock_message := ""
	var unlock_color := Color.WHITE
	match wave_index:
		1:
			unlock_message = "近战已解锁"
			unlock_color = _get_unlock_color("melee")
		UNLOCK_WAVE_FLYING_SWORD:
			unlock_message = "御剑已解锁"
			unlock_color = _get_unlock_color("flying_sword")
		UNLOCK_WAVE_ARRAY_RING:
			unlock_message = "环阵已解锁"
			unlock_color = _get_unlock_color(SwordArrayConfig.MODE_RING)
		UNLOCK_WAVE_ARRAY_FAN:
			unlock_message = "扇阵已解锁"
			unlock_color = _get_unlock_color(SwordArrayConfig.MODE_FAN)
		UNLOCK_WAVE_ARRAY_PIERCE:
			unlock_message = "贯穿阵已解锁"
			unlock_color = _get_unlock_color(SwordArrayConfig.MODE_PIERCE)
	if unlock_message == "":
		return
	_show_status_message(unlock_message, unlock_color, 1.0)
	_show_focus_status_message(unlock_message, unlock_color, minf(FOCUS_STATUS_DURATION, 0.6))


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
	var mode: String = _get_effective_array_batch_mode()
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


func _wake_array_distance_guide() -> void:
	if not ARRAY_DISTANCE_GUIDE_ENABLED:
		return
	if _should_hide_sword_array_ui():
		return
	if _get_array_control_scheme() != ARRAY_CONTROL_SCHEME_DISTANCE:
		return
	array_distance_guide_timer = maxf(array_distance_guide_timer, ARRAY_DISTANCE_GUIDE_MOUSE_FADE_DURATION)


func _get_array_distance_guide_strength() -> float:
	if not ARRAY_DISTANCE_GUIDE_ENABLED:
		return 0.0
	if lookdev_mode or debug_calibration_mode or is_start_menu_active or _should_hide_sword_array_ui():
		return 0.0
	if _get_array_control_scheme() != ARRAY_CONTROL_SCHEME_DISTANCE:
		return 0.0
	var intro_strength: float = 0.0
	if ARRAY_DISTANCE_GUIDE_INTRO_DURATION > 0.0:
		intro_strength = clampf(1.0 - elapsed_time / ARRAY_DISTANCE_GUIDE_INTRO_DURATION, 0.0, 1.0)
	var mouse_strength: float = 0.0
	if ARRAY_DISTANCE_GUIDE_MOUSE_FADE_DURATION > 0.0:
		mouse_strength = clampf(array_distance_guide_timer / ARRAY_DISTANCE_GUIDE_MOUSE_FADE_DURATION, 0.0, 1.0)
	var hold_strength: float = ARRAY_DISTANCE_GUIDE_HOLD_STRENGTH if left_mouse_held else 0.0
	return clampf(maxf(intro_strength * 0.72, maxf(mouse_strength * 0.62, hold_strength)), 0.0, 1.0)


func _reset_cursor_intent_indicator() -> void:
	cursor_intent_previous_mouse_world = mouse_world
	cursor_intent_mouse_speed = 0.0
	cursor_intent_fast_display = 0.0
	cursor_intent_last_mode = str(player.get("array_mode", SwordArrayConfig.MODE_RING))
	cursor_intent_mode_switch_timer = 0.0
	cursor_intent_pressure_score = 0.0
	cursor_intent_pressure_enter_timer = 0.0
	cursor_intent_pressure_active = false
	cursor_intent_pressure_display = 0.0
	cursor_intent_out_of_range_display = 0.0
	cursor_intent_resource_display = 0.0
	cursor_intent_fire_kick = 0.0
	cursor_intent_fire_phase = 0.0


func _update_cursor_intent_indicator(delta: float) -> void:
	if player.is_empty():
		return
	if _should_hide_sword_array_ui():
		cursor_intent_pressure_display = 0.0
		cursor_intent_out_of_range_display = 0.0
		cursor_intent_resource_display = 0.0
		cursor_intent_fire_kick = move_toward(cursor_intent_fire_kick, 0.0, delta * CURSOR_INTENT_FIRE_KICK_DECAY_SPEED)
		cursor_intent_previous_mouse_world = mouse_world
		return
	var safe_delta: float = maxf(delta, 0.0001)
	var mouse_delta: Vector2 = mouse_world - cursor_intent_previous_mouse_world
	cursor_intent_mouse_speed = mouse_delta.length() / safe_delta
	var target_fast_display: float = _cursor_intent_smoothstep(inverse_lerp(CURSOR_INTENT_FAST_SPEED, CURSOR_INTENT_MAX_SPEED, cursor_intent_mouse_speed))
	var fast_speed: float = 11.0 if target_fast_display > cursor_intent_fast_display else 5.5
	cursor_intent_fast_display = move_toward(cursor_intent_fast_display, target_fast_display, delta * fast_speed)
	cursor_intent_previous_mouse_world = mouse_world

	var morph_state: Dictionary = _get_sword_array_morph_state()
	var current_mode: String = str(morph_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	if current_mode != cursor_intent_last_mode:
		cursor_intent_last_mode = current_mode
		cursor_intent_mode_switch_timer = CURSOR_INTENT_MODE_SWITCH_DURATION
	else:
		cursor_intent_mode_switch_timer = maxf(cursor_intent_mode_switch_timer - delta, 0.0)

	_update_cursor_intent_pressure(delta, morph_state)
	var out_of_range_target: float = _calculate_cursor_intent_out_of_range_strength()
	cursor_intent_out_of_range_display = move_toward(
		cursor_intent_out_of_range_display,
		out_of_range_target,
		delta * CURSOR_INTENT_OUT_OF_RANGE_FADE_SPEED
	)
	var resource_target: float = _calculate_cursor_intent_resource_strength()
	cursor_intent_resource_display = move_toward(
		cursor_intent_resource_display,
		resource_target,
		delta * CURSOR_INTENT_RESOURCE_FADE_SPEED
	)
	cursor_intent_fire_kick = move_toward(
		cursor_intent_fire_kick,
		0.0,
		delta * CURSOR_INTENT_FIRE_KICK_DECAY_SPEED
	)


func _pulse_cursor_intent_fire(fire_count: int) -> void:
	var count_strength: float = CURSOR_INTENT_FIRE_KICK_MIN + CURSOR_INTENT_FIRE_KICK_PER_SWORD * float(maxi(fire_count, 1))
	cursor_intent_fire_kick = maxf(cursor_intent_fire_kick, clampf(count_strength, 0.0, CURSOR_INTENT_FIRE_KICK_MAX))
	cursor_intent_fire_phase = fmod(cursor_intent_fire_phase + CURSOR_INTENT_FIRE_PHASE_STEP + float(maxi(fire_count, 1)) * 0.31, TAU)


func _update_cursor_intent_pressure(delta: float, morph_state: Dictionary) -> void:
	cursor_intent_pressure_score = _calculate_cursor_intent_pressure_score(morph_state)
	if cursor_intent_pressure_active:
		if cursor_intent_pressure_score <= CURSOR_INTENT_PRESSURE_EXIT_SCORE:
			cursor_intent_pressure_active = false
	else:
		if cursor_intent_pressure_score >= CURSOR_INTENT_PRESSURE_ENTER_SCORE:
			cursor_intent_pressure_enter_timer += delta
			if cursor_intent_pressure_enter_timer >= CURSOR_INTENT_PRESSURE_ENTER_HOLD:
				cursor_intent_pressure_active = true
		else:
			cursor_intent_pressure_enter_timer = 0.0
	var target_display: float = cursor_intent_pressure_score if cursor_intent_pressure_active else 0.0
	var fade_speed: float = CURSOR_INTENT_PRESSURE_FADE_IN_SPEED if target_display > cursor_intent_pressure_display else CURSOR_INTENT_PRESSURE_FADE_OUT_SPEED
	cursor_intent_pressure_display = move_toward(cursor_intent_pressure_display, target_display, delta * fade_speed)


func _calculate_cursor_intent_out_of_range_strength() -> float:
	var aim_distance: float = player["pos"].distance_to(mouse_world)
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var pierce_end: float = float(distances.get("fan_to_pierce_end", SwordArrayConfig.FAN_TO_PIERCE_END))
	var range_start: float = maxf(ARRAY_SWORD_MAX_TRAVEL_DISTANCE - 45.0, pierce_end + 70.0)
	var range_full: float = range_start + 120.0
	return _cursor_intent_smoothstep(inverse_lerp(range_start, range_full, aim_distance))


func _calculate_cursor_intent_resource_strength() -> float:
	var warning_strength: float = _get_array_energy_warning_strength()
	var break_strength: float = _get_array_energy_break_strength()
	var resource_strength: float = warning_strength * 0.72
	if array_energy_forecast_level >= ArrayEnergyForecastLevel.CRITICAL:
		resource_strength = maxf(resource_strength, warning_strength)
	return clampf(maxf(resource_strength, break_strength), 0.0, 1.0)


func _calculate_cursor_intent_pressure_score(morph_state: Dictionary) -> float:
	if enemies.is_empty() or player.is_empty():
		return 0.0
	var player_pos: Vector2 = Vector2(player.get("pos", Vector2.ZERO))
	var aim_vector: Vector2 = mouse_world - player_pos
	var mode: String = str(morph_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	var best_score: float = 0.0
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if _should_ignore_cursor_pressure_enemy(enemy):
			continue
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		var enemy_radius: float = float(enemy.get("radius", SHOOTER_RADIUS))
		var edge_distance: float = player_pos.distance_to(enemy_pos) - enemy_radius - PLAYER_RADIUS
		var proximity: float = 1.0 - _cursor_intent_smoothstep(inverse_lerp(0.0, CURSOR_INTENT_PRESSURE_RADIUS, maxf(edge_distance, 0.0)))
		if proximity <= 0.0:
			continue
		var threat_intent: float = _get_cursor_pressure_enemy_threat_intent(enemy, player_pos, enemy_pos)
		var uncovered: float = _get_cursor_pressure_uncovered_weight(enemy_pos, enemy_radius, aim_vector, mode)
		var score: float = clampf(proximity * threat_intent * uncovered, 0.0, 1.0)
		best_score = maxf(best_score, score)
	return best_score


func _should_ignore_cursor_pressure_enemy(enemy: Dictionary) -> bool:
	if bool(enemy.get("is_dying", false)):
		return true
	if float(enemy.get("health", 0.0)) <= 0.0:
		return true
	if float(enemy.get("stagger_timer", 0.0)) > 0.0:
		return true
	return false


func _get_cursor_pressure_enemy_threat_intent(enemy: Dictionary, player_pos: Vector2, enemy_pos: Vector2) -> float:
	var enemy_type: String = str(enemy.get("type", SHOOTER))
	var distance: float = player_pos.distance_to(enemy_pos)
	var intent: float = 0.35
	match enemy_type:
		TANK, HEAVY:
			intent = 1.0
		PUPPET:
			intent = 1.0 if float(enemy.get("melee_timer", 0.0)) > 0.0 or distance <= PUPPET_MELEE_RANGE + 24.0 else 0.72
		RING_LEECH:
			intent = 0.9 if distance <= RING_LEECH_FIRE_DISTANCE else 0.62
		MIRROR_NEEDLER:
			intent = 0.88 if float(enemy.get("charge_timer", 0.0)) > 0.0 else 0.42
		CASTER, DRAPE_PRIEST:
			intent = 0.55 if float(enemy.get("shoot_cooldown", 999.0)) <= 0.35 else 0.38
		_:
			intent = 0.5 if float(enemy.get("shoot_cooldown", 999.0)) <= 0.35 else 0.34
	var to_player: Vector2 = player_pos - enemy_pos
	var enemy_velocity: Vector2 = Vector2(enemy.get("vel", Vector2.ZERO))
	if not to_player.is_zero_approx() and not enemy_velocity.is_zero_approx():
		var approach_speed: float = enemy_velocity.dot(to_player.normalized())
		if approach_speed > 20.0:
			intent = maxf(intent, clampf(approach_speed / 180.0, 0.45, 1.0))
	if distance <= PLAYER_RADIUS + float(enemy.get("radius", SHOOTER_RADIUS)) + 24.0:
		intent = maxf(intent, 1.0)
	return clampf(intent, 0.0, 1.0)


func _get_cursor_pressure_uncovered_weight(enemy_pos: Vector2, enemy_radius: float, aim_vector: Vector2, mode: String) -> float:
	var player_pos: Vector2 = Vector2(player.get("pos", Vector2.ZERO))
	var to_enemy: Vector2 = enemy_pos - player_pos
	if to_enemy.is_zero_approx():
		return 1.0
	var coverage: float = 0.0
	if not aim_vector.is_zero_approx():
		var aim_dir: Vector2 = aim_vector.normalized()
		var angle: float = absf(aim_dir.angle_to(to_enemy.normalized()))
		var directional_coverage: float = 1.0 - _cursor_intent_smoothstep(inverse_lerp(0.38, 1.12, angle))
		coverage = maxf(coverage, directional_coverage)
	var cursor_distance_to_enemy: float = mouse_world.distance_to(enemy_pos)
	var target_coverage: float = 1.0 - _cursor_intent_smoothstep(inverse_lerp(enemy_radius + 24.0, enemy_radius + 92.0, cursor_distance_to_enemy))
	coverage = maxf(coverage, target_coverage)
	var ring_is_committed: bool = (left_mouse_held or bool(player.get("array_is_firing", false))) and mode == SwordArrayConfig.MODE_RING
	if ring_is_committed and to_enemy.length() <= SwordArrayConfig.RING_ACTIVE_RADIUS + enemy_radius + 34.0:
		coverage = maxf(coverage, 0.86)
	return clampf(1.0 - coverage, 0.0, 1.0)


func _get_cursor_intent_mode_switch_strength() -> float:
	if CURSOR_INTENT_MODE_SWITCH_DURATION <= 0.0:
		return 0.0
	return clampf(cursor_intent_mode_switch_timer / CURSOR_INTENT_MODE_SWITCH_DURATION, 0.0, 1.0)


func _cursor_intent_smoothstep(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _update_sword_spirit_intent_debug() -> void:
	sword_spirit_intent_debug = _build_sword_spirit_intent_debug()


func _build_sword_spirit_intent_debug() -> Dictionary:
	if player.is_empty():
		return {
			"guard_score": 0.0,
			"sweep_score": 0.0,
			"pierce_score": 0.0,
			"recommendation": "静默",
			"plan": "-",
			"reason": "等待玩家状态",
			"target_pos": Vector2.ZERO,
			"target_kind": "",
		}
	var player_pos: Vector2 = Vector2(player.get("pos", Vector2.ZERO))
	var aim_dir: Vector2 = _get_sword_spirit_aim_direction(player_pos)
	var guard_data: Dictionary = _calculate_sword_spirit_guard_intent(player_pos)
	var sweep_data: Dictionary = _calculate_sword_spirit_sweep_intent(player_pos, aim_dir)
	var pierce_data: Dictionary = _calculate_sword_spirit_pierce_intent(player_pos, aim_dir)
	var recommendation_data: Dictionary = _build_sword_spirit_recommendation(guard_data, sweep_data, pierce_data)
	var ignored_invulnerable_count: int = _count_sword_spirit_ignored_invulnerable_enemies()
	var active_silk_count: int = _count_sword_spirit_active_silks()
	var reason: String = str(recommendation_data.get("reason", ""))
	if active_silk_count > 0 and not _is_boss_core_open():
		if reason == "未见强压力":
			reason = "丝线%d需御剑切断" % active_silk_count
		else:
			reason = "%s；丝线%d需御剑" % [reason, active_silk_count]
	if ignored_invulnerable_count > 0:
		if reason == "未见强压力":
			reason = "忽略无效傀儡%d；优先切丝/等破绽" % ignored_invulnerable_count
		else:
			reason = "%s；忽略无效傀儡%d" % [reason, ignored_invulnerable_count]
	return {
		"guard_score": float(guard_data.get("score", 0.0)),
		"sweep_score": float(sweep_data.get("score", 0.0)),
		"pierce_score": float(pierce_data.get("score", 0.0)),
		"recommendation": str(recommendation_data.get("recommendation", "")),
		"plan": str(recommendation_data.get("plan", "")),
		"plan_modes": recommendation_data.get("plan_modes", []),
		"reason": reason,
		"target_pos": recommendation_data.get("target_pos", Vector2.ZERO),
		"target_kind": str(recommendation_data.get("target_kind", "")),
		"guard_reason": str(guard_data.get("reason", "")),
		"sweep_reason": str(sweep_data.get("reason", "")),
		"pierce_reason": str(pierce_data.get("reason", "")),
		"ignored_invulnerable_count": ignored_invulnerable_count,
		"active_silk_count": active_silk_count,
	}


func _get_sword_spirit_aim_direction(player_pos: Vector2) -> Vector2:
	var aim_vector: Vector2 = mouse_world - player_pos
	if not aim_vector.is_zero_approx():
		return aim_vector.normalized()
	var sword_vector: Vector2 = Vector2(sword.get("pos", player_pos)) - player_pos
	if not sword_vector.is_zero_approx():
		return sword_vector.normalized()
	return Vector2.RIGHT


func _should_ignore_sword_spirit_formation_enemy(enemy: Dictionary) -> bool:
	if _should_ignore_cursor_pressure_enemy(enemy):
		return true
	return _is_sword_spirit_invulnerable_formation_enemy(enemy)


func _is_sword_spirit_invulnerable_formation_enemy(enemy: Dictionary) -> bool:
	var enemy_type: String = str(enemy.get("type", ""))
	if enemy_type != PUPPET:
		return false
	# Boss 牵丝傀儡本体不吃剑阵伤害；剑灵编阵不应把它当成可解决目标。
	return _has_boss()


func _count_sword_spirit_ignored_invulnerable_enemies() -> int:
	var ignored_count: int = 0
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if _should_ignore_cursor_pressure_enemy(enemy):
			continue
		if _is_sword_spirit_invulnerable_formation_enemy(enemy):
			ignored_count += 1
	return ignored_count


func _count_sword_spirit_active_silks() -> int:
	if not _has_boss():
		return 0
	var active_count: int = 0
	for silk_variant in boss.get("silks", []):
		var silk: Dictionary = silk_variant
		if bool(silk.get("is_active", false)) and float(silk.get("health", 0.0)) > 0.0:
			active_count += 1
	return active_count


func _calculate_sword_spirit_guard_intent(player_pos: Vector2) -> Dictionary:
	var best_score: float = 0.0
	var best_reason: String = "近身安全"
	var nearby_count: int = 0
	var health_ratio: float = clampf(float(player.get("health", PLAYER_MAX_HEALTH)) / PLAYER_MAX_HEALTH, 0.0, 1.0)
	var low_health_pressure: float = 1.0 - health_ratio
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if _should_ignore_sword_spirit_formation_enemy(enemy):
			continue
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		var enemy_radius: float = float(enemy.get("radius", SHOOTER_RADIUS))
		var edge_distance: float = player_pos.distance_to(enemy_pos) - enemy_radius - PLAYER_RADIUS
		if edge_distance > SWORD_SPIRIT_GUARD_RADIUS:
			continue
		nearby_count += 1
		var proximity: float = 1.0 - _cursor_intent_smoothstep(inverse_lerp(0.0, SWORD_SPIRIT_GUARD_RADIUS, maxf(edge_distance, 0.0)))
		var enemy_type: String = str(enemy.get("type", SHOOTER))
		var type_weight: float = _get_sword_spirit_guard_type_weight(enemy_type)
		var approach_strength: float = _get_sword_spirit_approach_strength(enemy, player_pos, enemy_pos)
		var contact_bonus: float = 0.18 if edge_distance <= 10.0 else 0.0
		var score: float = clampf(
			proximity * (0.50 + type_weight * 0.30 + approach_strength * 0.26)
			+ low_health_pressure * proximity * 0.24
			+ contact_bonus,
			0.0,
			1.0
		)
		if score > best_score:
			best_score = score
			best_reason = "近身%s %.0f" % [_get_sword_spirit_enemy_label(enemy_type), maxf(edge_distance, 0.0)]
	var crowd_bonus: float = minf(float(maxi(nearby_count - 1, 0)) * 0.07, 0.21)
	if best_score > 0.0:
		best_score = clampf(best_score + crowd_bonus, 0.0, 1.0)
		if nearby_count >= 2:
			best_reason = "%s +%d" % [best_reason, nearby_count - 1]
	var bullet_data: Dictionary = _calculate_sword_spirit_guard_bullet_intent(player_pos)
	var bullet_score: float = float(bullet_data.get("score", 0.0))
	if bullet_score > best_score:
		best_score = bullet_score
		best_reason = str(bullet_data.get("reason", best_reason))
	elif bullet_score > 0.0 and best_score > 0.0:
		best_score = clampf(best_score + bullet_score * 0.18, 0.0, 1.0)
	return {
		"score": best_score,
		"reason": best_reason,
	}


func _calculate_sword_spirit_guard_bullet_intent(player_pos: Vector2) -> Dictionary:
	var best_score: float = 0.0
	var pressure_count: int = 0
	for bullet_variant in bullets:
		var bullet: Dictionary = bullet_variant
		if str(bullet.get("state", "")) != "normal":
			continue
		var bullet_pos: Vector2 = Vector2(bullet.get("pos", Vector2.ZERO))
		var bullet_radius: float = float(bullet.get("radius", BULLET_RADIUS))
		var edge_distance: float = player_pos.distance_to(bullet_pos) - bullet_radius - PLAYER_RADIUS
		if edge_distance > SWORD_SPIRIT_GUARD_BULLET_RADIUS:
			continue
		pressure_count += 1
		var proximity: float = 1.0 - _cursor_intent_smoothstep(inverse_lerp(0.0, SWORD_SPIRIT_GUARD_BULLET_RADIUS, maxf(edge_distance, 0.0)))
		var to_player: Vector2 = player_pos - bullet_pos
		var bullet_velocity: Vector2 = Vector2(bullet.get("vel", Vector2.ZERO))
		var approach_strength: float = 0.0
		if not to_player.is_zero_approx() and not bullet_velocity.is_zero_approx():
			var approach_speed: float = bullet_velocity.dot(to_player.normalized())
			approach_strength = _cursor_intent_smoothstep(inverse_lerp(20.0, 260.0, approach_speed))
		var type_weight: float = 1.0 if str(bullet.get("type", "")) == "large" else 0.78
		var score: float = clampf(proximity * (0.42 + approach_strength * 0.46 + type_weight * 0.16), 0.0, 1.0)
		best_score = maxf(best_score, score)
	if pressure_count >= 2:
		best_score = clampf(best_score + minf(float(pressure_count - 1) * 0.07, 0.21), 0.0, 1.0)
	return {
		"score": best_score,
		"reason": "近身弹幕%d" % pressure_count if pressure_count > 0 else "近身弹幕安全",
	}


func _get_sword_spirit_guard_type_weight(enemy_type: String) -> float:
	match enemy_type:
		TANK, HEAVY, PUPPET:
			return 1.0
		RING_LEECH:
			return 0.86
		MIRROR_NEEDLER:
			return 0.62
		CASTER, DRAPE_PRIEST:
			return 0.54
		_:
			return 0.48


func _get_sword_spirit_approach_strength(enemy: Dictionary, player_pos: Vector2, enemy_pos: Vector2) -> float:
	var to_player: Vector2 = player_pos - enemy_pos
	var enemy_velocity: Vector2 = Vector2(enemy.get("vel", Vector2.ZERO))
	if to_player.is_zero_approx() or enemy_velocity.is_zero_approx():
		return 0.0
	var approach_speed: float = enemy_velocity.dot(to_player.normalized())
	return _cursor_intent_smoothstep(inverse_lerp(20.0, 170.0, approach_speed))


func _calculate_sword_spirit_sweep_intent(player_pos: Vector2, aim_dir: Vector2) -> Dictionary:
	var lane_count: int = 0
	var mid_count: int = 0
	var min_lateral: float = 0.0
	var max_lateral: float = 0.0
	var has_lateral_sample: bool = false
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if _should_ignore_sword_spirit_formation_enemy(enemy):
			continue
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		var to_enemy: Vector2 = enemy_pos - player_pos
		if to_enemy.is_zero_approx():
			continue
		var forward_distance: float = to_enemy.dot(aim_dir)
		if forward_distance < SWORD_SPIRIT_INTENT_MIN_FORWARD or forward_distance > SWORD_SPIRIT_INTENT_DEPTH:
			continue
		var angle: float = absf(aim_dir.angle_to(to_enemy.normalized()))
		if angle > SWORD_SPIRIT_SWEEP_MAX_ANGLE:
			continue
		var signed_lateral: float = aim_dir.cross(to_enemy)
		if absf(signed_lateral) > SWORD_SPIRIT_SWEEP_HALF_WIDTH:
			continue
		lane_count += 1
		if forward_distance >= SWORD_SPIRIT_SWEEP_MIN_DISTANCE and forward_distance <= SWORD_SPIRIT_SWEEP_MAX_DISTANCE:
			mid_count += 1
		if not has_lateral_sample:
			min_lateral = signed_lateral
			max_lateral = signed_lateral
			has_lateral_sample = true
		else:
			min_lateral = minf(min_lateral, signed_lateral)
			max_lateral = maxf(max_lateral, signed_lateral)
	if lane_count <= 0:
		return {
			"score": 0.0,
			"reason": "主方向无面压力",
		}
	var lateral_spread: float = max_lateral - min_lateral
	var count_score: float = _cursor_intent_smoothstep(inverse_lerp(1.0, 5.0, float(lane_count)))
	var mid_score: float = _cursor_intent_smoothstep(inverse_lerp(1.0, 4.0, float(mid_count)))
	var spread_score: float = _cursor_intent_smoothstep(inverse_lerp(35.0, SWORD_SPIRIT_SWEEP_SPREAD_TARGET, lateral_spread))
	var score: float = clampf(count_score * 0.42 + mid_score * 0.28 + spread_score * 0.30, 0.0, 1.0)
	if lane_count == 1:
		score *= 0.45
	return {
		"score": score,
		"reason": "主向%d敌 横展%.0f" % [lane_count, lateral_spread],
	}


func _calculate_sword_spirit_pierce_intent(player_pos: Vector2, aim_dir: Vector2) -> Dictionary:
	var cursor_lock_score: float = 0.0
	var cursor_lock_reason: String = "准星未锁关键"
	var corridor_count: int = 0
	var high_value_count: int = 0
	var min_forward: float = 0.0
	var max_forward: float = 0.0
	var has_forward_sample: bool = false
	var boss_core_score: float = 0.0
	var boss_core_reason: String = ""
	var target_pos: Vector2 = Vector2.ZERO
	var target_kind: String = ""
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if _should_ignore_sword_spirit_formation_enemy(enemy):
			continue
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		var enemy_radius: float = float(enemy.get("radius", SHOOTER_RADIUS))
		var enemy_type: String = str(enemy.get("type", SHOOTER))
		var to_enemy: Vector2 = enemy_pos - player_pos
		var cursor_distance: float = mouse_world.distance_to(enemy_pos)
		var cursor_lock: float = 1.0 - _cursor_intent_smoothstep(
			inverse_lerp(enemy_radius + 10.0, enemy_radius + SWORD_SPIRIT_CURSOR_LOCK_RADIUS, cursor_distance)
		)
		if cursor_lock > 0.0:
			var lock_score: float = cursor_lock * _get_sword_spirit_pierce_value_weight(enemy)
			if lock_score > cursor_lock_score:
				cursor_lock_score = lock_score
				cursor_lock_reason = "准星%s" % _get_sword_spirit_enemy_label(enemy_type)
				target_pos = enemy_pos
				target_kind = "enemy"
		if to_enemy.is_zero_approx():
			continue
		var forward_distance: float = to_enemy.dot(aim_dir)
		if forward_distance < SWORD_SPIRIT_INTENT_MIN_FORWARD or forward_distance > SWORD_SPIRIT_INTENT_DEPTH:
			continue
		var angle: float = absf(aim_dir.angle_to(to_enemy.normalized()))
		var lateral_distance: float = absf(aim_dir.cross(to_enemy))
		var corridor_width: float = enemy_radius + SWORD_SPIRIT_PIERCE_CORRIDOR_HALF_WIDTH
		if angle > SWORD_SPIRIT_PIERCE_MAX_ANGLE or lateral_distance > corridor_width:
			continue
		corridor_count += 1
		if _is_sword_spirit_high_value_enemy(enemy):
			high_value_count += 1
		if not has_forward_sample:
			min_forward = forward_distance
			max_forward = forward_distance
			has_forward_sample = true
		else:
			min_forward = minf(min_forward, forward_distance)
			max_forward = maxf(max_forward, forward_distance)
	var line_score: float = 0.0
	var forward_spread: float = 0.0
	if corridor_count >= 2:
		forward_spread = max_forward - min_forward
		var line_count_score: float = _cursor_intent_smoothstep(inverse_lerp(1.0, 4.0, float(corridor_count)))
		var line_depth_score: float = _cursor_intent_smoothstep(inverse_lerp(90.0, 360.0, forward_spread))
		line_score = clampf(line_count_score * 0.46 + line_depth_score * 0.28, 0.0, 0.74)
	var high_value_score: float = minf(float(high_value_count) * 0.24, 0.42)
	var boss_core_data: Dictionary = _calculate_sword_spirit_boss_core_pierce_intent(player_pos, aim_dir)
	boss_core_score = float(boss_core_data.get("score", 0.0))
	boss_core_reason = str(boss_core_data.get("reason", ""))
	var primary_score: float = maxf(maxf(cursor_lock_score, line_score), boss_core_score)
	var score: float = clampf(primary_score + high_value_score, 0.0, 1.0)
	var reason: String = cursor_lock_reason
	if boss_core_score >= maxf(cursor_lock_score, line_score) and boss_core_score > 0.0:
		reason = boss_core_reason
		target_pos = Vector2(boss_core_data.get("target_pos", Vector2.ZERO))
		target_kind = str(boss_core_data.get("target_kind", ""))
	elif line_score > cursor_lock_score:
		reason = "成线%d敌 纵深%.0f" % [corridor_count, forward_spread]
		target_kind = ""
		target_pos = Vector2.ZERO
	if high_value_count > 0 and score > 0.0:
		reason = "%s +关键%d" % [reason, high_value_count]
	return {
		"score": score,
		"reason": reason,
		"target_pos": target_pos,
		"target_kind": target_kind if score > 0.0 else "",
	}


func _calculate_sword_spirit_boss_core_pierce_intent(player_pos: Vector2, aim_dir: Vector2) -> Dictionary:
	if not _is_boss_core_open():
		return {
			"score": 0.0,
			"reason": "Boss未开窗",
			"target_pos": Vector2.ZERO,
			"target_kind": "",
		}
	var boss_pos: Vector2 = Vector2(boss.get("pos", Vector2.ZERO))
	var boss_radius: float = float(boss.get("radius", BOSS_RADIUS))
	var cursor_distance: float = mouse_world.distance_to(boss_pos)
	var cursor_lock: float = 1.0 - _cursor_intent_smoothstep(
		inverse_lerp(boss_radius + 12.0, boss_radius + SWORD_SPIRIT_BOSS_CORE_CURSOR_LOCK_RADIUS, cursor_distance)
	)
	var to_boss: Vector2 = boss_pos - player_pos
	var corridor_score: float = 0.0
	if not to_boss.is_zero_approx():
		var forward_distance: float = to_boss.dot(aim_dir)
		var lateral_distance: float = absf(aim_dir.cross(to_boss))
		var angle: float = absf(aim_dir.angle_to(to_boss.normalized()))
		var is_in_corridor: bool = (
			forward_distance >= SWORD_SPIRIT_INTENT_MIN_FORWARD
			and forward_distance <= SWORD_SPIRIT_INTENT_DEPTH
			and lateral_distance <= boss_radius + SWORD_SPIRIT_BOSS_CORE_CORRIDOR_HALF_WIDTH
			and angle <= SWORD_SPIRIT_SWEEP_MAX_ANGLE
		)
		if is_in_corridor:
			var lateral_score: float = 1.0 - _cursor_intent_smoothstep(
				inverse_lerp(boss_radius * 0.45, boss_radius + SWORD_SPIRIT_BOSS_CORE_CORRIDOR_HALF_WIDTH, lateral_distance)
			)
			corridor_score = clampf(0.56 + lateral_score * 0.24, 0.0, 0.84)
	var score: float = clampf(maxf(cursor_lock * 0.96, corridor_score), 0.0, 1.0)
	return {
		"score": score,
		"reason": "Boss破绽" if score > 0.0 else "Boss破绽未入剑意",
		"target_pos": boss_pos if score > 0.0 else Vector2.ZERO,
		"target_kind": "boss_core" if score > 0.0 else "",
	}


func _build_sword_spirit_recommendation(guard_data: Dictionary, sweep_data: Dictionary, pierce_data: Dictionary) -> Dictionary:
	var guard_score: float = float(guard_data.get("score", 0.0))
	var sweep_score: float = float(sweep_data.get("score", 0.0))
	var pierce_score: float = float(pierce_data.get("score", 0.0))
	var strongest_non_guard: float = maxf(sweep_score, pierce_score)
	if guard_score >= SWORD_SPIRIT_GUARD_RECOMMEND_SCORE and guard_score >= strongest_non_guard - SWORD_SPIRIT_GUARD_STEAL_MARGIN:
		if pierce_score >= SWORD_SPIRIT_FOLLOWUP_RECOMMEND_SCORE and pierce_score >= sweep_score:
			return {
				"recommendation": "环阵护主后贯穿",
				"plan": "环 -> 贯",
				"plan_modes": [SwordArrayConfig.MODE_RING, SwordArrayConfig.MODE_PIERCE],
				"reason": "%s；%s" % [str(guard_data.get("reason", "")), str(pierce_data.get("reason", ""))],
				"target_pos": pierce_data.get("target_pos", Vector2.ZERO),
				"target_kind": str(pierce_data.get("target_kind", "")),
			}
		if sweep_score >= SWORD_SPIRIT_FOLLOWUP_RECOMMEND_SCORE:
			return {
				"recommendation": "环阵护主后扫面",
				"plan": "环 -> 扇",
				"plan_modes": [SwordArrayConfig.MODE_RING, SwordArrayConfig.MODE_FAN],
				"reason": "%s；%s" % [str(guard_data.get("reason", "")), str(sweep_data.get("reason", ""))],
			}
		return {
			"recommendation": "环阵护主",
			"plan": "环",
			"plan_modes": [SwordArrayConfig.MODE_RING],
			"reason": str(guard_data.get("reason", "")),
		}
	if pierce_score >= SWORD_SPIRIT_PIERCE_RECOMMEND_SCORE and pierce_score >= sweep_score:
		return {
			"recommendation": "贯穿破线",
			"plan": "贯",
			"plan_modes": [SwordArrayConfig.MODE_PIERCE],
			"reason": str(pierce_data.get("reason", "")),
			"target_pos": pierce_data.get("target_pos", Vector2.ZERO),
			"target_kind": str(pierce_data.get("target_kind", "")),
		}
	if sweep_score >= SWORD_SPIRIT_SWEEP_RECOMMEND_SCORE:
		return {
			"recommendation": "扇阵扫面",
			"plan": "扇",
			"plan_modes": [SwordArrayConfig.MODE_FAN],
			"reason": str(sweep_data.get("reason", "")),
		}
	var current_mode: String = str(player.get("array_mode", SwordArrayConfig.MODE_RING))
	return {
		"recommendation": "保持当前剑阵",
		"plan": _get_sword_spirit_mode_short_name(current_mode),
		"plan_modes": [current_mode],
		"reason": "未见强压力",
	}


func _is_sword_spirit_takeover_enabled() -> bool:
	return SWORD_SPIRIT_TAKEOVER_ENABLED and _is_any_array_unlocked()


func _reset_sword_spirit_takeover_state() -> void:
	sword_spirit_takeover_plan.clear()
	sword_spirit_takeover_plan_index = 0
	sword_spirit_takeover_plan_signature = ""
	sword_spirit_takeover_last_mode = ""
	sword_spirit_takeover_last_reason = ""
	if not player.is_empty():
		player["array_effective_fire_mode"] = str(player.get("array_mode", SwordArrayConfig.MODE_RING))


func _prepare_sword_spirit_takeover_plan(force := false) -> void:
	if not _is_sword_spirit_takeover_enabled():
		_reset_sword_spirit_takeover_state()
		return
	if not force and sword_spirit_takeover_plan_index < sword_spirit_takeover_plan.size():
		return
	if force or sword_spirit_intent_debug.is_empty():
		_update_sword_spirit_intent_debug()
	var plan_modes: Array[String] = _get_sword_spirit_debug_plan_modes()
	if plan_modes.is_empty():
		var fallback_mode: String = _get_unlocked_sword_spirit_takeover_mode(_get_array_batch_mode())
		if fallback_mode != "":
			plan_modes.append(fallback_mode)
	var signature: String = _build_sword_spirit_takeover_signature(plan_modes)
	if not force and signature == sword_spirit_takeover_plan_signature and not sword_spirit_takeover_plan.is_empty():
		sword_spirit_takeover_plan_index = 0
		sword_spirit_takeover_last_reason = str(sword_spirit_intent_debug.get("reason", ""))
		return
	sword_spirit_takeover_plan = plan_modes
	sword_spirit_takeover_plan_index = 0
	sword_spirit_takeover_plan_signature = signature
	sword_spirit_takeover_last_reason = str(sword_spirit_intent_debug.get("reason", ""))


func _get_sword_spirit_debug_plan_modes() -> Array[String]:
	var resolved_modes: Array[String] = []
	var raw_modes: Variant = sword_spirit_intent_debug.get("plan_modes", [])
	if typeof(raw_modes) != TYPE_ARRAY:
		return resolved_modes
	for mode_variant in raw_modes:
		var mode: String = _get_unlocked_sword_spirit_takeover_mode(str(mode_variant))
		if mode == "":
			continue
		if not resolved_modes.is_empty() and resolved_modes[resolved_modes.size() - 1] == mode:
			continue
		resolved_modes.append(mode)
	return resolved_modes


func _get_unlocked_sword_spirit_takeover_mode(mode: String) -> String:
	if _is_array_mode_unlocked(mode):
		return mode
	if mode == SwordArrayConfig.MODE_PIERCE and _is_array_mode_unlocked(SwordArrayConfig.MODE_FAN):
		return SwordArrayConfig.MODE_FAN
	if _is_array_mode_unlocked(SwordArrayConfig.MODE_RING):
		return SwordArrayConfig.MODE_RING
	return ""


func _build_sword_spirit_takeover_signature(plan_modes: Array[String]) -> String:
	if plan_modes.is_empty():
		return ""
	var parts: Array[String] = []
	for mode in plan_modes:
		parts.append(mode)
	return " > ".join(parts)


func _peek_sword_spirit_takeover_mode() -> String:
	if not _is_sword_spirit_takeover_enabled():
		return ""
	_prepare_sword_spirit_takeover_plan(false)
	if sword_spirit_takeover_plan_index < 0 or sword_spirit_takeover_plan_index >= sword_spirit_takeover_plan.size():
		return ""
	return sword_spirit_takeover_plan[sword_spirit_takeover_plan_index]


func _advance_sword_spirit_takeover_plan(fired_mode: String) -> void:
	if not _is_sword_spirit_takeover_enabled():
		return
	sword_spirit_takeover_last_mode = fired_mode
	if sword_spirit_takeover_plan_index < sword_spirit_takeover_plan.size():
		sword_spirit_takeover_plan_index += 1


func _get_effective_array_batch_mode() -> String:
	var takeover_mode: String = _peek_sword_spirit_takeover_mode()
	if takeover_mode != "":
		return takeover_mode
	return _get_array_batch_mode()


func _get_effective_array_fire_state() -> Dictionary:
	var takeover_mode: String = _peek_sword_spirit_takeover_mode()
	if takeover_mode != "":
		return SwordArrayConfig.get_mode_state(takeover_mode)
	return _get_sword_array_fire_state()


func _get_array_fire_override_target_pos_for_mode(mode: String):
	if mode != SwordArrayConfig.MODE_PIERCE:
		return null
	return mouse_world


func _get_array_fire_override_target_kind_for_mode(mode: String) -> String:
	var target_pos_variant: Variant = _get_array_fire_override_target_pos_for_mode(mode)
	if typeof(target_pos_variant) != TYPE_VECTOR2:
		return ""
	return "cursor"


func _resolve_array_sword_override_fire_target(launch_origin: Vector2, target_pos: Vector2, target_kind: String, travel_mode: String):
	if travel_mode != SwordArrayConfig.MODE_PIERCE:
		return null
	if target_kind != "cursor":
		return null
	return _build_sword_spirit_pierce_target_point(launch_origin, target_pos)


func _build_sword_spirit_pierce_target_point(launch_origin: Vector2, target_pos: Vector2) -> Vector2:
	var pierce_direction: Vector2 = target_pos - launch_origin
	if pierce_direction.is_zero_approx() and not player.is_empty():
		pierce_direction = target_pos - Vector2(player.get("pos", target_pos))
	if pierce_direction.is_zero_approx() and not player.is_empty():
		pierce_direction = _get_sword_spirit_aim_direction(Vector2(player.get("pos", Vector2.ZERO)))
	if pierce_direction.is_zero_approx():
		pierce_direction = Vector2.RIGHT
	return target_pos + pierce_direction.normalized() * SWORD_SPIRIT_TAKEOVER_PIERCE_OVERSHOOT


func _get_array_sword_guidance_override_target_point(array_sword: Dictionary):
	var target_kind: String = str(array_sword.get("guidance_override_target_kind", ""))
	if target_kind == "":
		return null
	var raw_target_pos: Variant = array_sword.get("guidance_override_target_pos", Vector2.ZERO)
	if typeof(raw_target_pos) != TYPE_VECTOR2:
		return null
	return _resolve_array_sword_override_fire_target(
		Vector2(array_sword.get("pos", Vector2.ZERO)),
		Vector2(raw_target_pos),
		target_kind,
		str(array_sword.get("travel_mode", SwordArrayConfig.MODE_RING))
	)


func _format_sword_spirit_intent_debug() -> String:
	if sword_spirit_intent_debug.is_empty():
		return "剑灵P0：等待判断"
	var takeover_suffix: String = ""
	if _is_sword_spirit_takeover_enabled():
		var queued_mode: String = ""
		if sword_spirit_takeover_plan_index >= 0 and sword_spirit_takeover_plan_index < sword_spirit_takeover_plan.size():
			queued_mode = sword_spirit_takeover_plan[sword_spirit_takeover_plan_index]
		elif sword_spirit_takeover_last_mode != "":
			queued_mode = sword_spirit_takeover_last_mode
		if queued_mode != "":
			takeover_suffix = " | 接管%s" % _get_sword_spirit_mode_short_name(queued_mode)
	return "剑灵P0：护 %.2f | 扫 %.2f | 破 %.2f | %s%s | %s" % [
		float(sword_spirit_intent_debug.get("guard_score", 0.0)),
		float(sword_spirit_intent_debug.get("sweep_score", 0.0)),
		float(sword_spirit_intent_debug.get("pierce_score", 0.0)),
		str(sword_spirit_intent_debug.get("plan", "")),
		takeover_suffix,
		str(sword_spirit_intent_debug.get("reason", "")),
	]


func _is_sword_spirit_high_value_enemy(enemy: Dictionary) -> bool:
	return SWORD_SPIRIT_HIGH_VALUE_ENEMY_TYPES.has(str(enemy.get("type", "")))


func _get_sword_spirit_pierce_value_weight(enemy: Dictionary) -> float:
	var enemy_type: String = str(enemy.get("type", SHOOTER))
	match enemy_type:
		MIRROR_NEEDLER:
			if float(enemy.get("charge_timer", 0.0)) > 0.0 or float(enemy.get("mirror_vulnerable_timer", 0.0)) > 0.0:
				return 1.0
			return 0.88
		CASTER:
			return 0.82
		DRAPE_PRIEST:
			return 0.86
		_:
			return 0.46


func _get_sword_spirit_enemy_label(enemy_type: String) -> String:
	match enemy_type:
		SHOOTER:
			return "射手"
		TANK:
			return "盾敌"
		CASTER:
			return "法师"
		HEAVY:
			return "重敌"
		RING_LEECH:
			return "环蚀"
		DRAPE_PRIEST:
			return "织幕"
		MIRROR_NEEDLER:
			return "镜针"
		PUPPET:
			return "傀儡"
		_:
			return enemy_type


func _get_sword_spirit_mode_short_name(mode: String) -> String:
	match mode:
		SwordArrayConfig.MODE_RING:
			return "环"
		SwordArrayConfig.MODE_FAN:
			return "扇"
		SwordArrayConfig.MODE_PIERCE:
			return "贯"
		_:
			return "现"


func _get_array_stable_mode_from_state(state: Dictionary) -> String:
	var completed_state: Dictionary = SwordArrayConfig.complete_morph_state(state)
	var visual_from_mode: String = str(completed_state.get("visual_from_mode", ""))
	var visual_to_mode: String = str(completed_state.get("visual_to_mode", visual_from_mode))
	if visual_from_mode != "" and visual_from_mode == visual_to_mode:
		return str(completed_state.get("dominant_mode", visual_from_mode))
	return str(completed_state.get("dominant_mode", ""))


func _get_array_mode_confirm_strength() -> float:
	if ARRAY_MODE_CONFIRM_DURATION <= 0.0:
		return 0.0
	return clampf(array_mode_confirm_timer / ARRAY_MODE_CONFIRM_DURATION, 0.0, 1.0)


func _get_array_control_scheme() -> String:
	return ARRAY_CONTROL_SCHEME_MANUAL if array_control_scheme == ARRAY_CONTROL_SCHEME_MANUAL else ARRAY_CONTROL_SCHEME_DISTANCE


func _get_array_control_scheme_display_name(scheme := "") -> String:
	var resolved_scheme: String = _get_array_control_scheme() if scheme == "" else scheme
	return "Space切阵" if resolved_scheme == ARRAY_CONTROL_SCHEME_MANUAL else "距离控阵"


func _get_array_control_scheme_color(scheme := "") -> Color:
	var resolved_scheme: String = _get_array_control_scheme() if scheme == "" else scheme
	if resolved_scheme == ARRAY_CONTROL_SCHEME_MANUAL:
		return Color(SwordArrayConfig.get_profile(SwordArrayConfig.MODE_PIERCE).get("accent_color", Color("88d8ff")))
	return Color("d7bb79")


func _get_sword_momentum_ratio() -> float:
	if player.is_empty():
		return 0.0
	return clampf(float(player.get("energy", 0.0)) / maxf(PLAYER_MAX_ENERGY, 0.001), 0.0, 1.0)


func _get_sword_momentum_heat_strength() -> float:
	return clampf(sword_momentum_heat_display, 0.0, 1.0)


func _get_sword_momentum_full_flash_strength() -> float:
	if SWORD_MOMENTUM_FULL_FLASH_DURATION <= 0.0:
		return 0.0
	return clampf(sword_momentum_full_flash_timer / SWORD_MOMENTUM_FULL_FLASH_DURATION, 0.0, 1.0)


func _update_sword_momentum_state(delta: float) -> void:
	sword_momentum_full_flash_timer = maxf(sword_momentum_full_flash_timer - delta, 0.0)
	if player.is_empty():
		sword_momentum_heat_display = move_toward(sword_momentum_heat_display, 0.0, delta * SWORD_MOMENTUM_HEAT_FADE_SPEED)
		sword_momentum_was_full = false
		return
	var ratio: float = _get_sword_momentum_ratio()
	var is_full: bool = ratio >= 1.0 - SWORD_MOMENTUM_FULL_EPSILON
	if is_full and not sword_momentum_was_full:
		sword_momentum_full_flash_timer = SWORD_MOMENTUM_FULL_FLASH_DURATION
		_show_status_message("剑意充盈", COLORS["energy"].lerp(Color("ff7a3d"), 0.28), 0.62)
		_show_focus_status_message("剑意充盈", COLORS["energy"].lerp(Color.WHITE, 0.12), 0.54)
		_emit_sword_momentum_full_effect()
	sword_momentum_was_full = is_full
	var heat_target: float = clampf(inverse_lerp(SWORD_MOMENTUM_HEAT_START_RATIO, 1.0, ratio), 0.0, 1.0)
	sword_momentum_heat_display = move_toward(
		sword_momentum_heat_display,
		heat_target,
		delta * SWORD_MOMENTUM_HEAT_FADE_SPEED
	)


func _emit_sword_momentum_full_effect() -> void:
	var player_pos: Vector2 = Vector2(player.get("pos", ARENA_SIZE * 0.5))
	_create_particles(player_pos, COLORS["energy"].lerp(Color.WHITE, 0.12), 16)
	_emit_sword_return_catch(player_pos, mouse_world - player_pos)
	var ready_effect_count: int = 0
	for array_sword in array_swords:
		if String(array_sword.get("state", "")) != "ready":
			continue
		if ready_effect_count < 12:
			_create_particles(Vector2(array_sword.get("pos", player_pos)), COLORS["array_sword_return"], 2)
			ready_effect_count += 1
	screen_shake = max(screen_shake, 3.2)


func _get_current_operation_guide_text() -> String:
	if is_start_menu_active:
		return START_MENU_DEMO_TEXT
	return START_MENU_OPERATION_TEXT if _get_array_control_scheme() == ARRAY_CONTROL_SCHEME_MANUAL else START_MENU_OPERATION_TEXT_DISTANCE


func _get_progression_hint_text() -> String:
	if _is_large_arena_test_enabled():
		return "%s | WASD 移动 | 左键/右键 御剑 | 长按左键 剑阵环/扇/贯 | F7 战斗调试" % _get_large_arena_goal_text()
	if _is_demo_level_mode():
		var demo_hint := "WASD 移动 | 左键 挥剑/弹反 | 右键 御剑"
		if _is_demo_level_active():
			var objective: String = demo_level_controller.get_objective_text()
			if objective != "":
				demo_hint += " | %s" % objective
		demo_hint += " | F7 战斗调试"
		return demo_hint
	if _is_flight_anchored_prototype_mode():
		return "WASD 调整航线/控速 | 松开左右回中 | 鼠标控距 | 左键 挥剑/长按剑阵 | 右键 御剑 | F7 航道调试"
	if _is_flight_prototype_mode():
		return "WASD 自由飞行/控速 | 鼠标控距 | 左键 挥剑/长按剑阵 | 右键 御剑 | F7 边界调试"
	var hint_parts: Array[String] = [
		"WASD 移动",
		"左键 挥剑",
	]
	if _is_flying_sword_unlocked():
		hint_parts.append("右键 御剑")
	if _is_array_mode_unlocked(SwordArrayConfig.MODE_RING):
		if _is_array_mode_unlocked(SwordArrayConfig.MODE_PIERCE):
			hint_parts.append("长按左键 剑阵环/扇/贯")
		elif _is_array_mode_unlocked(SwordArrayConfig.MODE_FAN):
			hint_parts.append("长按左键 剑阵环/扇")
		else:
			hint_parts.append("长按左键 环阵")
	hint_parts.append("点击右上切操作方案")
	hint_parts.append(_get_sword_hover_preset_shortcut_hint())
	hint_parts.append("F7 战斗调试")
	hint_parts.append("F6 校准调试")
	return " | ".join(hint_parts)


func _update_array_control_scheme_ui() -> void:
	var scheme_name: String = _get_array_control_scheme_display_name()
	if start_menu_scheme_button != null:
		start_menu_scheme_button.text = "操作方案：%s" % scheme_name
	if start_menu_guide_label != null:
		start_menu_guide_label.text = _get_current_operation_guide_text()
	if operation_scheme_button != null:
		operation_scheme_button.text = "操作：%s" % scheme_name
		operation_scheme_button.visible = not lookdev_mode and not is_start_menu_active and not debug_calibration_mode and not _should_hide_sword_array_ui()
		var viewport_size: Vector2 = get_viewport_rect().size
		operation_scheme_button.position = Vector2(viewport_size.x - 208.0, 92.0)
		operation_scheme_button.size = Vector2(196.0, 34.0)


func _can_toggle_array_control_scheme() -> bool:
	if lookdev_mode or debug_calibration_mode:
		return false
	if is_start_menu_active:
		return true
	return not left_mouse_held and not bool(player.get("array_is_firing", false))


func _set_array_control_scheme(scheme: String) -> void:
	array_control_scheme = ARRAY_CONTROL_SCHEME_MANUAL if scheme == ARRAY_CONTROL_SCHEME_MANUAL else ARRAY_CONTROL_SCHEME_DISTANCE
	if array_control_scheme == ARRAY_CONTROL_SCHEME_MANUAL:
		var current_mode: String = str(player.get("array_mode", SwordArrayConfig.MODE_RING))
		if ARRAY_TOGGLE_MODES.has(current_mode):
			player["array_selected_mode"] = current_mode
		else:
			player["array_selected_mode"] = _normalize_array_selected_mode(str(player.get("array_selected_mode", SwordArrayConfig.MODE_RING)))
		player["array_sticky_mode"] = _get_selected_array_mode()
	else:
		player["array_sticky_mode"] = str(player.get("array_mode", SwordArrayConfig.MODE_RING))
		_wake_array_distance_guide()
	_refresh_sword_array_live_state()
	_update_array_control_scheme_ui()
	_update_ui()


func _toggle_array_control_scheme() -> void:
	if not _can_toggle_array_control_scheme():
		_show_focus_status_message(
			"松开剑阵后再切换操作方案",
			Color("f1b46b"),
			minf(FOCUS_STATUS_DURATION, 0.55)
		)
		return
	var next_scheme: String = ARRAY_CONTROL_SCHEME_MANUAL
	if _get_array_control_scheme() == ARRAY_CONTROL_SCHEME_MANUAL:
		next_scheme = ARRAY_CONTROL_SCHEME_DISTANCE
	_set_array_control_scheme(next_scheme)
	if not is_start_menu_active:
		var scheme_name: String = _get_array_control_scheme_display_name(next_scheme)
		var scheme_color: Color = _get_array_control_scheme_color(next_scheme)
		_show_status_message("操作方案已切换：%s" % scheme_name, scheme_color, 0.8)
		_show_focus_status_message(scheme_name, scheme_color, minf(FOCUS_STATUS_DURATION, 0.55))


func _uses_manual_array_mode_toggle() -> bool:
	return _get_array_control_scheme() == ARRAY_CONTROL_SCHEME_MANUAL and not debug_calibration_mode and not _should_hide_sword_array_ui()


func _normalize_array_selected_mode(mode: String) -> String:
	match mode:
		SwordArrayConfig.MODE_FAN:
			return SwordArrayConfig.MODE_FAN
		SwordArrayConfig.MODE_PIERCE:
			return SwordArrayConfig.MODE_PIERCE
		_:
			return SwordArrayConfig.MODE_RING


func _get_selected_array_mode() -> String:
	return _normalize_array_selected_mode(
		str(player.get("array_selected_mode", player.get("array_mode", SwordArrayConfig.MODE_RING)))
	)


func _get_unlocked_array_toggle_modes() -> Array[String]:
	var unlocked_modes: Array[String] = []
	for mode_variant in ARRAY_TOGGLE_MODES:
		var mode: String = str(mode_variant)
		if _is_array_mode_unlocked(mode):
			unlocked_modes.append(mode)
	return unlocked_modes


func _get_next_locked_array_toggle_mode() -> String:
	for mode_variant in ARRAY_TOGGLE_MODES:
		var mode: String = str(mode_variant)
		if not _is_array_mode_unlocked(mode):
			return mode
	return ""


func _build_locked_array_state(mode: String, _aim_distance: float) -> Dictionary:
	var locked_mode: String = _normalize_array_selected_mode(mode)
	var state: Dictionary = SwordArrayConfig.get_mode_state(locked_mode)
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var max_distance: float = maxf(float(distances.get("fan_to_pierce_end", SwordArrayConfig.FAN_TO_PIERCE_END)), 1.0)
	var canonical_distance: float = 0.0
	match locked_mode:
		SwordArrayConfig.MODE_PIERCE:
			canonical_distance = float(distances.get("fan_to_pierce_end", SwordArrayConfig.FAN_TO_PIERCE_END))
		SwordArrayConfig.MODE_FAN:
			canonical_distance = float(distances.get("fan_stable_end", SwordArrayConfig.FAN_STABLE_END))
		_:
			canonical_distance = float(distances.get("ring_stable_end", SwordArrayConfig.RING_STABLE_END))
	state["distance_ratio"] = clampf(canonical_distance / max_distance, 0.0, 1.0)
	return state


func _get_array_mode_display_name(mode: String) -> String:
	match mode:
		SwordArrayConfig.MODE_PIERCE:
			return "贯穿阵"
		SwordArrayConfig.MODE_FAN:
			return "扇阵"
		_:
			return "环阵"


func _toggle_selected_array_mode() -> void:
	if is_game_over or lookdev_mode or is_start_menu_active or not _uses_manual_array_mode_toggle():
		return
	var unlocked_modes: Array[String] = _get_unlocked_array_toggle_modes()
	if unlocked_modes.is_empty():
		_show_locked_skill_feedback(SwordArrayConfig.MODE_RING)
		return
	var current_mode: String = _get_selected_array_mode()
	var next_mode: String = ""
	if unlocked_modes.size() == 1:
		next_mode = unlocked_modes[0]
		if current_mode == next_mode:
			var next_locked_mode: String = _get_next_locked_array_toggle_mode()
			if next_locked_mode != "":
				_show_locked_skill_feedback(next_locked_mode)
			return
	else:
		var current_index: int = unlocked_modes.find(current_mode)
		next_mode = unlocked_modes[0] if current_index < 0 else unlocked_modes[(current_index + 1) % unlocked_modes.size()]
	var ready_source_snapshot: Array = []
	if current_mode == SwordArrayConfig.MODE_PIERCE and next_mode == SwordArrayConfig.MODE_RING:
		ready_source_snapshot = _build_array_sword_source_snapshot()
	player["array_selected_mode"] = next_mode
	player["array_sticky_mode"] = next_mode
	player["array_confirm_observed_stable_mode"] = next_mode
	_refresh_sword_array_live_state()
	if current_mode == SwordArrayConfig.MODE_PIERCE and next_mode == SwordArrayConfig.MODE_RING:
		_trigger_ring_switch_strike(current_mode, ready_source_snapshot)
	_trigger_rider_array_mode_change(current_mode, next_mode, mouse_world - player["pos"])
	_trigger_array_mode_confirm(next_mode)
	_show_focus_status_message(
		_get_array_mode_display_name(next_mode),
		Color(SwordArrayConfig.get_profile(next_mode).get("accent_color", Color.WHITE)),
		minf(FOCUS_STATUS_DURATION, 0.55)
	)


func _build_array_mode_switch_strike_state(from_mode: String, to_mode: String) -> Dictionary:
	var normalized_from_mode: String = _normalize_array_selected_mode(from_mode)
	var normalized_to_mode: String = _normalize_array_selected_mode(to_mode)
	var target_state: Dictionary = _build_locked_array_state(
		normalized_to_mode,
		float(player.get("array_control_distance", player["pos"].distance_to(mouse_world)))
	)
	target_state["dominant_mode"] = normalized_to_mode
	target_state["visual_from_mode"] = normalized_from_mode
	target_state["visual_to_mode"] = normalized_to_mode
	target_state["visual_blend"] = ARRAY_RING_SWITCH_STRIKE_VISUAL_BLEND
	target_state["preset_from"] = SwordArrayConfig.get_default_preset_for_mode(normalized_from_mode)
	target_state["preset_to"] = SwordArrayConfig.get_default_preset_for_mode(normalized_to_mode)
	target_state["preset_blend"] = ARRAY_RING_SWITCH_STRIKE_VISUAL_BLEND
	return SwordArrayConfig.complete_morph_state(target_state)


func _trigger_ring_switch_strike(previous_mode: String, source_snapshot: Array) -> void:
	if not bool(player.get("array_is_firing", false)) or source_snapshot.is_empty():
		return
	var ring_switch_state: Dictionary = _build_array_mode_switch_strike_state(previous_mode, SwordArrayConfig.MODE_RING)
	var slot_count: int = _get_current_array_sword_capacity()
	var fired_count: int = 0
	for source_variant in source_snapshot:
		var source: Dictionary = source_variant
		var sword_id: String = str(source.get("id", ""))
		var array_sword: Dictionary = _get_array_sword_by_id(sword_id)
		if array_sword.is_empty() or String(array_sword.get("state", "")) != "ready":
			continue
		var slot_index: int = int(array_sword.get("slot_index", 0))
		var ring_anchor: Vector2 = _get_array_sword_slot_position(slot_index, 1.0)
		_fire_single_array_sword(
			sword_id,
			slot_index,
			slot_count,
			0,
			slot_count,
			"",
			SwordArrayConfig.MODE_RING,
			Vector2(source.get("pos", array_sword["pos"])),
			ring_anchor,
			ring_switch_state
		)
		fired_count += 1
	if fired_count > 0:
		_emit_sword_array_fire_effect(ring_switch_state, fired_count)


func _get_sword_array_formation_ratio() -> float:
	if bool(player.get("array_is_firing", false)):
		return 1.0
	return clampf(float(player.get("array_hold_ratio", 0.0)), 0.0, 1.0)


func _should_draw_sword_array_preview() -> bool:
	if _should_hide_sword_array_ui():
		return false
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


func _clamp_array_state_to_unlocks(state: Dictionary) -> Dictionary:
	var completed_state: Dictionary = SwordArrayConfig.complete_morph_state(state)
	if _is_array_mode_unlocked(SwordArrayConfig.MODE_PIERCE):
		return completed_state
	if _is_array_mode_unlocked(SwordArrayConfig.MODE_FAN):
		var visual_from_mode: String = str(completed_state.get("visual_from_mode", ""))
		var visual_to_mode: String = str(completed_state.get("visual_to_mode", ""))
		var dominant_mode: String = str(completed_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
		if visual_from_mode == SwordArrayConfig.MODE_PIERCE or visual_to_mode == SwordArrayConfig.MODE_PIERCE or dominant_mode == SwordArrayConfig.MODE_PIERCE:
			return SwordArrayConfig.get_mode_state(SwordArrayConfig.MODE_FAN)
		return completed_state
	return SwordArrayConfig.get_mode_state(SwordArrayConfig.MODE_RING)


func _refresh_sword_array_live_state() -> void:
	var raw_distance: float = float(player.get("array_raw_aim_distance", player["pos"].distance_to(mouse_world)))
	var control_distance: float = float(player.get("array_control_distance", raw_distance))
	var visual_state: Dictionary = {}
	var fire_state: Dictionary = {}
	var previous_mode: String = str(player.get("array_sticky_mode", player.get("array_mode", SwordArrayConfig.MODE_RING)))
	if _uses_manual_array_mode_toggle():
		var selected_mode: String = _get_selected_array_mode()
		if not _is_array_mode_unlocked(selected_mode):
			selected_mode = SwordArrayConfig.MODE_RING
		player["array_selected_mode"] = selected_mode
		visual_state = _build_locked_array_state(selected_mode, raw_distance)
		fire_state = _build_locked_array_state(selected_mode, control_distance)
		visual_state = _clamp_array_state_to_unlocks(visual_state)
		fire_state = _clamp_array_state_to_unlocks(fire_state)
		player["array_sticky_mode"] = selected_mode
	else:
		visual_state = SwordArrayConfig.get_morph_state_for_distance(raw_distance)
		fire_state = SwordArrayConfig.get_control_morph_state_for_distance(control_distance)
		visual_state = SwordArrayConfig.apply_dominant_mode_hysteresis(visual_state, previous_mode)
		fire_state = SwordArrayConfig.apply_dominant_mode_hysteresis(fire_state, previous_mode)
		visual_state = _clamp_array_state_to_unlocks(visual_state)
		fire_state = _clamp_array_state_to_unlocks(fire_state)
		player["array_sticky_mode"] = str(fire_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	player["array_morph_state"] = visual_state
	player["array_fire_morph_state"] = fire_state
	player["array_mode"] = fire_state["dominant_mode"]
	var new_mode: String = str(fire_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	if not _uses_manual_array_mode_toggle() and previous_mode != new_mode:
		_trigger_rider_array_mode_change(previous_mode, new_mode, mouse_world - player["pos"])


func _begin_sword_array_firing() -> void:
	if not _can_use_array_attack():
		return
	_refresh_sword_array_live_state()
	_prepare_sword_spirit_takeover_plan(true)
	var mode: String = _get_effective_array_batch_mode()
	if not _can_fire_array_batch(mode, _get_ready_array_sword_count()):
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return
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
	var morph_state: Dictionary = _get_effective_array_fire_state()
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
		morph_state = _get_effective_array_fire_state()
		mode = String(morph_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
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
		morph_state = _get_effective_array_fire_state()
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
	_reset_sword_spirit_takeover_state()
	_refresh_sword_array_live_state()


func _update_sword(delta: float) -> void:
	sword["prev_pos"] = sword["pos"]
	_update_sword_combo_state(delta)
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
		if _is_held_melee_sword_active():
			sword["angle"] = _get_melee_sword_visual_angle()
			sword["pos"] = _get_held_melee_sword_position()
		else:
			var orbit_direction: Vector2 = mouse_world - player["pos"]
			if orbit_direction.is_zero_approx():
				orbit_direction = Vector2.RIGHT.rotated(sword["angle"])
			else:
				orbit_direction = orbit_direction.normalized()
			sword["angle"] = orbit_direction.angle()
			var target: Vector2 = player["pos"] + orbit_direction * SWORD_ORBIT_DISTANCE
			sword["pos"] = sword["pos"].lerp(target, min(delta * 18.0, 1.0))
		var held_frame_velocity: Vector2 = (sword["pos"] - sword["prev_pos"]) / maxf(delta, 0.001)
		sword["vel"] = held_frame_velocity
		_update_sword_hover(delta, Vector2.ZERO)
		_update_sword_trail(delta, held_frame_velocity)
		_update_sword_air_wakes(delta, held_frame_velocity)
		_update_sword_afterimages(delta, held_frame_velocity)
		return

	if sword["state"] == SwordState.PIERCE_DRAWING:
		sword["vel"] = Vector2.ZERO
	elif sword["state"] == SwordState.SLICING:
		sword["pos"] = sword["pos"].lerp(mouse_world, min(delta * SWORD_SLICE_FOLLOW_SPEED, 1.0))
		sword["vel"] = (sword["pos"] - sword["prev_pos"]) / maxf(delta, 0.001)
	elif sword["state"] == SwordState.POINT_STRIKE:
		if not _update_pierce_time_stop_combo_flight(delta):
			var to_target: Vector2 = sword["target_pos"] - sword["pos"]
			var move_distance: float = SWORD_POINT_STRIKE_SPEED * delta
			if to_target.length() > move_distance and to_target.length() > 10.0:
				sword["vel"] = to_target.normalized() * SWORD_POINT_STRIKE_SPEED
				sword["pos"] += sword["vel"] * delta
			else:
				sword["pos"] = sword["target_pos"]
				sword["vel"] = Vector2.ZERO
				if (
					String(sword.get("combo_id", "")) == SwordResonanceController.COMBO_PIERCE_TIME_STOP
					and String(sword.get("combo_phase", "")) == "followthrough"
					and _is_right_mouse_intent_active()
				):
					_hold_pierce_combo_sword_at_mouse(SwordResonanceController.get_color(SwordArrayConfig.MODE_PIERCE))
					return
				sword["state"] = SwordState.RECALLING
				_trigger_time_rift_recover()
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
			_trigger_time_rift_recover()
			sword["vel"] = Vector2.ZERO
			sword["state"] = SwordState.ORBITING
			_set_player_combat_mode(CombatMode.MELEE)
			sword["angle"] = _get_melee_sword_visual_angle()
			sword["pos"] = _get_held_melee_sword_position()
			var buffered_press_timer: float = float(sword.get("press_timer", 0.0))
			if not _is_right_mouse_intent_active():
				sword["press_timer"] = 0.0
			_end_sword_attack_instance()
			_clear_sword_combo()
			if _is_right_mouse_intent_active():
				sword["press_timer"] = buffered_press_timer
				sword["target_pos"] = mouse_world
				_start_slicing()
				sword["prev_pos"] = sword["pos"]
				return
			_trigger_rider_sword_control_exit(recall_direction)
			return

	if sword["vel"].length_squared() > 1.0:
		sword["angle"] = sword["vel"].angle()
	var frame_velocity: Vector2 = (sword["pos"] - sword["prev_pos"]) / maxf(delta, 0.001)
	if frame_velocity.length_squared() > 1.0:
		sword["angle"] = frame_velocity.angle()
	_update_sword_hover(delta, frame_velocity)
	_update_sword_trail(delta, frame_velocity)
	_update_sword_air_wakes(delta, frame_velocity)
	_update_sword_afterimages(delta, frame_velocity)

	_damage_enemies_with_sword(delta)


func _update_sword_hover(delta: float, frame_velocity: Vector2) -> void:
	var hover_preset := _get_sword_hover_preset_data()
	if hover_preset.is_empty():
		sword["hover_idle_candidate_time"] = 0.0
		sword["hover_idle_active"] = false
		sword["hover_idle_blend"] = 0.0
		sword["hover_visual_offset"] = Vector2.ZERO
		sword["hover_visual_angle_offset"] = 0.0
		return

	var can_hover: bool = sword["state"] == SwordState.SLICING and right_mouse_held
	var hover_candidate_time: float = float(sword.get("hover_idle_candidate_time", 0.0))
	var hover_idle_active: bool = bool(sword.get("hover_idle_active", false))
	var hover_elapsed_time: float = float(sword.get("hover_elapsed_time", 0.0)) + delta
	var speed: float = frame_velocity.length()

	if can_hover:
		if hover_idle_active:
			if speed >= float(hover_preset.get("exit_speed", 180.0)):
				hover_idle_active = false
				hover_candidate_time = 0.0
		else:
			if speed <= float(hover_preset.get("enter_speed", 84.0)):
				hover_candidate_time += delta
				if hover_candidate_time >= float(hover_preset.get("enter_delay", 0.06)):
					hover_idle_active = true
			else:
				hover_candidate_time = 0.0
	else:
		hover_idle_active = false
		hover_candidate_time = 0.0

	var hover_blend := move_toward(
		float(sword.get("hover_idle_blend", 0.0)),
		1.0 if hover_idle_active else 0.0,
		delta / maxf(
			float(hover_preset.get("blend_in_duration", 0.14)) if hover_idle_active else float(hover_preset.get("blend_out_duration", 0.08)),
			0.001
		)
	)

	sword["hover_idle_candidate_time"] = hover_candidate_time
	sword["hover_idle_active"] = hover_idle_active
	sword["hover_idle_blend"] = hover_blend
	sword["hover_elapsed_time"] = hover_elapsed_time

	if hover_blend <= 0.001:
		sword["hover_visual_offset"] = Vector2.ZERO
		sword["hover_visual_angle_offset"] = 0.0
		return

	var forward: Vector2 = frame_velocity.normalized()
	if forward.is_zero_approx():
		forward = Vector2.RIGHT.rotated(float(sword.get("angle", 0.0)))
	if forward.is_zero_approx():
		forward = Vector2(sword.get("last_motion_forward", Vector2.RIGHT))
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()

	var side: Vector2 = forward.orthogonal()
	var phase: float = float(sword.get("hover_phase", 0.0))
	var float_phase: float = hover_elapsed_time * TAU * float(hover_preset.get("float_frequency", 1.55)) + phase
	var drift_phase: float = hover_elapsed_time * TAU * float(hover_preset.get("drift_frequency", 0.95)) + phase * 1.37
	var hover_offset: Vector2 = side * sin(float_phase) * float(hover_preset.get("float_amplitude", 6.0))
	hover_offset += forward * cos(drift_phase) * float(hover_preset.get("drift_amplitude", 1.3))
	sword["hover_visual_offset"] = hover_offset * hover_blend
	sword["hover_visual_angle_offset"] = sin(drift_phase + 0.4) * float(hover_preset.get("angle_amplitude", 0.055)) * hover_blend


func _damage_enemies_with_sword(delta: float) -> void:
	if sword["state"] == SwordState.PIERCE_DRAWING:
		return
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

	_damage_fan_time_stop_clone_swords(delta)
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


func _damage_fan_time_stop_clone_swords(delta: float) -> void:
	if String(sword.get("combo_id", "")) != SwordResonanceController.COMBO_FAN_TIME_STOP:
		return
	var attack_profile_id: String = str(sword.get("attack_profile_id", ""))
	if attack_profile_id == "":
		return
	for side_sign in [-1.0, 1.0]:
		var source: Dictionary = _get_fan_time_stop_clone_source(side_sign)
		if not bool(source.get("active", false)):
			continue
		var clone_sword: Dictionary = source.get("sword", {})
		var clone_state: int = int(clone_sword.get("state", SwordState.ORBITING))
		if clone_state == SwordState.PIERCE_DRAWING or clone_state == SwordState.ORBITING:
			continue
		var clone_prev_pos: Vector2 = Vector2(clone_sword.get("prev_pos", clone_sword.get("pos", Vector2.ZERO)))
		var clone_pos: Vector2 = Vector2(clone_sword.get("pos", Vector2.ZERO))
		var clone_swing_direction: Vector2 = clone_pos - clone_prev_pos
		var can_clone_hit := true
		if clone_state == SwordState.SLICING:
			var clone_swing_speed: float = clone_swing_direction.length() / maxf(delta, 0.001)
			can_clone_hit = clone_swing_speed >= SWORD_SLICE_MIN_HIT_SPEED
		if not can_clone_hit:
			continue
		var clone_attack_instance_id: String = _ensure_fan_time_stop_clone_attack_instance(side_sign, attack_profile_id)
		if clone_attack_instance_id == "":
			continue
		var detection_result: Dictionary = hit_detection.collect_segment_sweep_targets(
			self ,
			clone_prev_pos,
			clone_pos,
			float(clone_sword.get("radius", SWORD_RADIUS)),
			attack_profile_id,
			DAMAGE_SOURCE_FLYING_SWORD_CLONE,
			delta,
			{
				"exclude_enemy_types": [PUPPET],
			}
		)
		for contact_variant in detection_result.get("contacts", []):
			var contact: Dictionary = contact_variant
			var contact_point: Vector2 = contact.get("contact_point", clone_pos)
			var attack_result: Dictionary = _apply_attack_instance_hit_to_target(
				clone_attack_instance_id,
				attack_profile_id,
				contact_point,
				str(contact.get("target_id", "")),
				str(contact.get("hurtbox_id", "")),
				str(contact.get("target_profile_id", "")),
				DAMAGE_SOURCE_FLYING_SWORD_CLONE,
				float(contact.get("contact_time", delta)),
				str(contact.get("target_state", "")),
				bool(contact.get("is_currently_overlapping", true)),
				{
					"channel_scalar": FAN_TIME_STOP_CLONE_DAMAGE_SCALAR,
				}
			)
			if not bool(attack_result.get("allowed", false)):
				continue
			var enemy: Variant = contact.get("entity", null)
			if enemy == null:
				continue
			var effect_color: Color = COLORS["ranged_sword"].lerp(COLORS[str(enemy.get("type", SHOOTER))], 0.16)
			_emit_sword_hit_effect(
				contact_point,
				clone_swing_direction,
				effect_color,
				FAN_TIME_STOP_CLONE_HIT_EFFECT_INTENSITY
			)
		if _has_boss():
			var boss_contact: Dictionary = detection_result.get("boss_contact", {})
			if not boss_contact.is_empty():
				var boss_contact_point: Vector2 = boss_contact.get("contact_point", clone_pos)
				var boss_hit_result: Dictionary = _apply_boss_attack_instance_hit(
					clone_attack_instance_id,
					attack_profile_id,
					boss_contact_point,
					DAMAGE_SOURCE_FLYING_SWORD_CLONE,
					float(boss_contact.get("contact_time", delta)),
					bool(boss_contact.get("is_currently_overlapping", true)),
					{
						"channel_scalar": FAN_TIME_STOP_CLONE_DAMAGE_SCALAR,
					}
				)
				if bool(boss_hit_result.get("allowed", false)):
					_emit_sword_hit_effect(
						boss_contact_point,
						clone_swing_direction,
						COLORS["ranged_sword"].lerp(COLORS["boss_body"], 0.2),
						FAN_TIME_STOP_CLONE_HIT_EFFECT_INTENSITY
					)


func _damage_enemy(enemy: Dictionary, damage: float, damage_source: String) -> void:
	if damage <= 0.0:
		return
	if bool(enemy.get("is_dying", false)):
		return
	if _is_large_arena_test_enabled() and str(enemy.get("type", "")) == FORMATION_CORE and str(large_arena_objective_states.get(LARGE_ARENA_CORE_KEY, LARGE_ARENA_STATE_SEALED)) != LARGE_ARENA_STATE_VULNERABLE:
		enemy["hit_flash_timer"] = maxf(float(enemy.get("hit_flash_timer", 0.0)), ENEMY_HIT_FLASH_DURATION)
		enemy["hit_flash_color"] = COLORS["formation_core"]
		_show_action_failure("阵心封印未破", "large_arena_core_sealed", COLORS["formation_core"], "large_arena")
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
	if _is_demo_level_active():
		demo_level_controller.on_enemy_death(self, enemy)
	enemy["is_dying"] = true
	enemy["death_feedback_timer"] = ENEMY_DEATH_FEEDBACK_DURATION
	enemy["death_feedback_color"] = Color.WHITE
	enemy["stagger_timer"] = 0.0
	enemy["vel"] = Vector2.ZERO
	if _is_large_arena_objective_enemy(enemy):
		_handle_large_arena_objective_destroyed(enemy)
	if enemy.has("melee_timer"):
		enemy["melee_timer"] = 0.0
	_clear_target_runtime_state(str(enemy.get("id", "")))
	_clear_target_hurtboxes(str(enemy.get("id", "")))
	if enemy["type"] != PUPPET:
		_spawn_score_loot_for_enemy(enemy)
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
	var clamp_max: Vector2 = _get_arena_size() - clamp_min
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
	var max_step: float = RING_LEECH_SPEED * _get_enemy_move_speed_scale(enemy) * float(enemy.get("package_speed_multiplier", 1.0)) * step_scale * delta
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
		enemy["pos"] += move_direction.normalized() * RING_LEECH_SPEED * _get_enemy_move_speed_scale(enemy) * delta
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


func _update_enemies(delta: float, feedback_delta := -1.0) -> void:
	var visual_feedback_delta: float = delta if feedback_delta < 0.0 else feedback_delta
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
			_update_enemy_visual_feedback(enemy, visual_feedback_delta)
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
		_update_enemy_visual_feedback(enemy, visual_feedback_delta)
		if float(enemy.get("stagger_timer", 0.0)) > 0.0:
			enemy["vel"] = Vector2.ZERO
			index -= 1
			continue
		if _is_large_arena_test_enabled() and _update_large_arena_enemy_role(enemy, delta):
			if enemy["health"] <= 0.0:
				_begin_enemy_death(enemy)
			index -= 1
			continue
		if _is_flight_prototype_mode() and _update_flight_enemy(enemy, delta):
			if enemy["health"] <= 0.0:
				_begin_enemy_death(enemy)
			index -= 1
			continue
		var to_player: Vector2 = player["pos"] - enemy["pos"]
		var distance: float = max(to_player.length(), 0.001)
		var enemy_move_speed_scale := _get_enemy_move_speed_scale(enemy)
		match enemy["type"]:
			SHOOTER:
				var shooter_speed := SHOOTER_SPEED * enemy_move_speed_scale
				if distance > 200.0:
					enemy["pos"] += to_player.normalized() * shooter_speed * delta
				elif distance < 150.0:
					enemy["pos"] -= to_player.normalized() * shooter_speed * delta
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
				enemy["pos"] += to_player.normalized() * TANK_SPEED * enemy_move_speed_scale * delta
				if distance < enemy["radius"] + PLAYER_RADIUS:
					if _apply_player_damage(30.0 * delta, TANK):
						screen_shake = max(screen_shake, 2.0)
			CASTER:
				enemy["move_timer"] -= delta
				if enemy["move_timer"] <= 0.0:
					enemy["move_timer"] = randf_range(1.0, 2.0)
					enemy["vel"] = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * CASTER_SPEED * enemy_move_speed_scale
				enemy["pos"] += enemy["vel"] * delta
				enemy["pos"] = enemy["pos"].clamp(Vector2(enemy["radius"], enemy["radius"]), _get_arena_size() - Vector2(enemy["radius"], enemy["radius"]))
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
				enemy["pos"] += to_player.normalized() * HEAVY_SPEED * enemy_move_speed_scale * delta
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
		if String(array_sword.get("combo_id", "")) != "":
			array_sword["combo_timer"] = maxf(float(array_sword.get("combo_timer", 0.0)) - delta, 0.0)
			if float(array_sword.get("combo_timer", 0.0)) <= 0.0:
				array_sword["combo_id"] = ""
				array_sword["combo_duration"] = 0.0
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
		var apply_result: Dictionary = attack_result.get("apply_result", {})
		if bool(apply_result.get("killed", false)):
			SwordResonanceController.record_array_kill(self, travel_mode)
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
	if not bool(player.get("array_is_firing", false)):
		return false
	if str(player.get("array_effective_fire_mode", _get_array_batch_mode())) == SwordArrayConfig.MODE_RING:
		return true
	for array_sword in array_swords:
		if String(array_sword.get("state", "")) == "outbound" and String(array_sword.get("travel_mode", "")) == SwordArrayConfig.MODE_RING:
			return true
	return false


func _begin_array_sword_return(array_sword: Dictionary) -> void:
	_clear_array_sword_attack_instance(array_sword)
	array_sword["state"] = "returning"
	array_sword["guidance_active"] = false
	array_sword["guidance_override_target_pos"] = Vector2.ZERO
	array_sword["guidance_override_target_kind"] = ""
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
	var guidance_state_source = _get_sword_array_fire_state()
	var locked_guidance_state: Variant = array_sword.get("guidance_state_source", {})
	if typeof(locked_guidance_state) == TYPE_DICTIONARY and not (locked_guidance_state as Dictionary).is_empty():
		guidance_state_source = locked_guidance_state
	var override_target_point: Variant = _get_array_sword_guidance_override_target_point(array_sword)
	var target_point: Vector2
	if typeof(override_target_point) == TYPE_VECTOR2:
		target_point = override_target_point
	else:
		target_point = SwordArrayController.get_fire_target(
			self ,
			guidance_state_source,
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
	if typeof(override_target_point) == TYPE_VECTOR2 and travel_mode == SwordArrayConfig.MODE_PIERCE:
		guidance_tangent_bias = 0.0
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
	if _is_demo_level_mode():
		return
	if debug_calibration_mode:
		return
	if _has_boss() and boss["health"] <= 0.0:
		_create_particles(boss["pos"], COLORS["boss_body"], 40)
		_clear_target_runtime_state("boss")
		_clear_target_hurtboxes("boss")
		boss.clear()
		score += 5000
		wave += 1
		_show_wave_unlock_feedback(wave)
		enemies_to_spawn = _get_wave_enemy_count(wave)
		_prepare_wave_spawn_queue()
		spawn_timer = 0.5
		return

	if enemies_to_spawn <= 0 and enemies.is_empty():
		wave += 1
		_show_wave_unlock_feedback(wave)
		if _should_spawn_boss_wave(wave):
			wave_spawn_queue.clear()
			_spawn_boss()
			spawn_timer = 0.6
			return
		enemies_to_spawn = _get_wave_enemy_count(wave)
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
	spawn_timer = _get_spawn_entry_delay(next_spawn_entry, spawned_enemy_count)
	enemies_to_spawn = max(enemies_to_spawn - spawned_enemy_count, 0)


func _perform_melee_attack() -> void:
	if bool(player.get("melee_auto_combo_active", false)):
		return
	var profile_data: Dictionary = _get_current_melee_test_profile_data()
	var attack_direction: Vector2 = _get_melee_attack_direction()
	if bool(player.get("melee_action_active", false)):
		_buffer_melee_attack_input()
		return
	if _is_melee_focus_profile(profile_data):
		_clear_melee_auto_combo()
		player["melee_combo_stage"] = 0
		player["melee_combo_timer"] = 0.0
		_start_melee_combo_stage(1, attack_direction)
		return
	_start_melee_combo_stage(_get_next_melee_combo_stage(), attack_direction)


func _buffer_melee_attack_input() -> void:
	player["melee_input_buffered"] = true
	player["melee_input_buffer_timer"] = MELEE_INPUT_BUFFER_WINDOW


func _get_melee_attack_direction() -> Vector2:
	var attack_direction: Vector2 = mouse_world - player["pos"]
	if attack_direction.is_zero_approx():
		attack_direction = _get_held_sword_aim_direction()
	if attack_direction.is_zero_approx():
		attack_direction = Vector2.RIGHT
	return attack_direction.normalized()


func _get_next_melee_combo_stage() -> int:
	if float(player.get("melee_combo_timer", 0.0)) <= 0.0:
		return 1
	var next_stage: int = int(player.get("melee_combo_stage", 0)) + 1
	if next_stage > MELEE_COMBO_STAGE_COUNT:
		next_stage = 1
	return next_stage


func _is_melee_focus_profile(profile_data: Dictionary) -> bool:
	return bool(profile_data.get("focused", false)) or str(profile_data.get("spirit_shape", "")) == "focus"


func _apply_melee_trait_profile_to_stage(stage_data: Dictionary, profile_data: Dictionary, stage_index: int) -> void:
	var tempo_shape: String = str(profile_data.get("tempo_shape", "light"))
	var blade_shape: String = str(profile_data.get("blade_shape", "broad"))
	var spirit_shape: String = str(profile_data.get("spirit_shape", "split"))
	stage_data["tempo_shape"] = tempo_shape
	stage_data["blade_shape"] = blade_shape
	stage_data["spirit_shape"] = spirit_shape
	stage_data["deflect_shape"] = "guard_arc"
	stage_data["damage_shape"] = "broad_arc"
	stage_data["vfx_shape"] = "broad_split" if spirit_shape == "split" else "broad_focus"
	stage_data["deflect_range"] = maxf(float(stage_data.get("range", SWORD_MELEE_RANGE)) + 18.0, SWORD_MELEE_RANGE + 20.0)
	stage_data["deflect_arc"] = maxf(float(stage_data.get("arc", SWORD_MELEE_ARC)), PI * 1.08)
	stage_data["deflect_bullet_range_bonus"] = 10.0
	stage_data["draw_deflect_shape"] = false
	stage_data["focused_phase"] = "focus" if spirit_shape == "focus" else "split"
	if tempo_shape == "light":
		stage_data["startup"] = maxf(float(stage_data.get("startup", 0.0)) - 0.018, 0.035)
		stage_data["active"] = maxf(float(stage_data.get("active", 0.0)) - 0.006, 0.035)
		stage_data["recovery"] = maxf(float(stage_data.get("recovery", 0.0)) - 0.032, 0.075)
		stage_data["swing_arc"] = float(stage_data.get("swing_arc", MELEE_SWORD_SWING_ARC)) + PI * 8.0 / 180.0
	else:
		stage_data["startup"] = float(stage_data.get("startup", 0.0)) + 0.028 + 0.008 * float(stage_index - 1)
		stage_data["active"] = float(stage_data.get("active", 0.0)) + 0.008
		stage_data["recovery"] = float(stage_data.get("recovery", 0.0)) + 0.038
		stage_data["shake"] = float(stage_data.get("shake", 0.0)) + 1.0 + 0.35 * float(stage_index - 1)
		stage_data["hitstop"] = float(stage_data.get("hitstop", 0.0)) + 0.004 + 0.002 * float(stage_index - 1)
		stage_data["poise_scalar"] = float(stage_data.get("poise_scalar", 1.0)) + 0.08
	if blade_shape == "long":
		var is_third_stage := 1.0 if stage_index == 3 else 0.0
		var is_second_stage := 1.0 if stage_index == 2 else 0.0
		var is_heavy_tempo := 1.0 if tempo_shape == "heavy" else 0.0
		stage_data["damage_shape"] = "long_line"
		stage_data["vfx_shape"] = "long_split" if spirit_shape == "split" else "long_focus"
		stage_data["range"] = float(stage_data.get("range", SWORD_MELEE_RANGE)) + 34.0 + 8.0 * is_third_stage
		stage_data["visual_range"] = float(stage_data.get("range", SWORD_MELEE_RANGE)) + 8.0
		stage_data["arc"] = PI * (28.0 + 4.0 * is_second_stage) / 180.0
		stage_data["hit_width"] = 11.0 + 1.5 * is_heavy_tempo
		stage_data["line_start_offset"] = 10.0
		stage_data["swing_arc"] = PI * (44.0 + 6.0 * is_third_stage) / 180.0
		stage_data["close_damage_range"] = 74.0 + 8.0 * is_heavy_tempo
		stage_data["close_damage_arc"] = PI * (0.82 + 0.06 * is_heavy_tempo)
		stage_data["deflect_range"] = maxf(float(stage_data.get("range", SWORD_MELEE_RANGE)) - 18.0, SWORD_MELEE_RANGE + 24.0)
		stage_data["deflect_arc"] = PI * (1.08 + 0.04 * is_heavy_tempo)
		stage_data["deflect_bullet_range_bonus"] = 18.0
		stage_data["draw_deflect_shape"] = true
		stage_data["angle_offset"] = float(stage_data.get("angle_offset", 0.0)) * 0.45
	else:
		var broad_arc: float = PI * 142.0 / 180.0
		var broad_range: float = 106.0
		match stage_index:
			2:
				broad_arc = PI * 178.0 / 180.0
				broad_range = 96.0
			3:
				broad_arc = PI * 154.0 / 180.0
				broad_range = 112.0
		stage_data["range"] = broad_range
		stage_data["visual_range"] = broad_range + 8.0
		stage_data["arc"] = broad_arc
		stage_data["swing_arc"] = maxf(float(stage_data.get("swing_arc", MELEE_SWORD_SWING_ARC)), broad_arc + PI * 24.0 / 180.0)
		stage_data["deflect_range"] = maxf(broad_range + 20.0, SWORD_MELEE_RANGE + 18.0)
		stage_data["deflect_arc"] = maxf(broad_arc, PI * 1.16)
		stage_data["deflect_bullet_range_bonus"] = 12.0
	if spirit_shape == "focus":
		stage_data["split_shadow"] = false
		stage_data["damage_scalar"] = float(stage_data.get("damage_scalar", 1.0)) * 1.05
		stage_data["hitstop"] = float(stage_data.get("hitstop", 0.0)) + (0.004 if tempo_shape == "light" else 0.008)
		stage_data["shake"] = float(stage_data.get("shake", 0.0)) + (0.45 if tempo_shape == "light" else 0.9)
		stage_data["inner_color"] = Color("ffffff")
	else:
		stage_data["split_shadow"] = true
		stage_data["damage_scalar"] = float(stage_data.get("damage_scalar", 1.0)) * 0.94
		stage_data["active"] = float(stage_data.get("active", 0.0)) + 0.006
		stage_data["shadow_delay"] = float(profile_data.get("shadow_delay", MELEE_SHADOW_STRIKE_DELAY))
		stage_data["shadow_damage_scalar"] = float(profile_data.get("shadow_damage_scalar", MELEE_SHADOW_DAMAGE_SCALAR))


func _start_melee_combo_stage(stage_index: int, attack_direction: Vector2, is_shadow := false) -> void:
	var stage_data: Dictionary = _get_melee_combo_stage_data(stage_index, is_shadow)
	var swing_direction: Vector2 = attack_direction.normalized()
	if swing_direction.is_zero_approx():
		swing_direction = _get_melee_attack_direction()
	if is_shadow:
		_apply_melee_arc_attack(stage_data, swing_direction, true)
		_push_melee_shadow_flash(stage_data, swing_direction)
		return
	if not is_shadow:
		player["melee_combo_stage"] = clampi(stage_index, 1, MELEE_COMBO_STAGE_COUNT)
		player["melee_combo_timer"] = MELEE_COMBO_RESET_WINDOW
	player["attack_cooldown"] = maxf(float(player.get("attack_cooldown", 0.0)), float(stage_data.get("total_duration", SWORD_MELEE_COOLDOWN)))
	player["melee_action_active"] = true
	player["melee_action_phase"] = MELEE_ACTION_PHASE_STARTUP
	player["melee_action_elapsed"] = 0.0
	player["melee_action_duration"] = float(stage_data.get("total_duration", MELEE_SWORD_SWING_DURATION))
	player["melee_action_hit_done"] = false
	player["melee_action_stage_data"] = stage_data
	player["melee_action_direction"] = swing_direction
	_start_melee_swing_visual(swing_direction, stage_data)


func _get_melee_combo_stage_data(stage_index: int, is_shadow := false) -> Dictionary:
	var normalized_stage: int = clampi(stage_index, 1, MELEE_COMBO_STAGE_COUNT)
	var profile_data: Dictionary = _get_current_melee_test_profile_data()
	if _is_melee_focus_profile(profile_data):
		return _get_focused_melee_stage_data(profile_data, is_shadow)
	var stage_data: Dictionary = {}
	match normalized_stage:
		1:
			stage_data = {
				"stage": 1,
				"name": "起手外斩",
				"damage_scalar": 0.38,
				"range": 120.0,
				"arc": PI * 65.0 / 180.0,
				"startup": 0.10,
				"active": 0.065,
				"recovery": 0.15,
				"swing_arc": PI * 132.0 / 180.0,
				"swing_side": MELEE_SWORD_SWING_SIDE,
				"angle_offset": -0.16,
				"shake": 4.4,
				"hitstop": MELEE_HITSTOP_BASE_DURATION * 1.05,
				"poise_scalar": 1.0,
				"bullet_range_bonus": 22.0,
				"color": Color("93c5fd"),
				"inner_color": Color("fef3c7"),
				"spark_count": 3,
			}
		2:
			stage_data = {
				"stage": 2,
				"name": "中段反扫",
				"damage_scalar": 0.28,
				"range": 88.0,
				"arc": PI * 145.0 / 180.0,
				"startup": 0.08,
				"active": 0.08,
				"recovery": 0.16,
				"swing_arc": PI * 172.0 / 180.0,
				"swing_side": -MELEE_SWORD_SWING_SIDE,
				"angle_offset": 0.0,
				"shake": 3.8,
				"hitstop": MELEE_HITSTOP_BASE_DURATION * 0.88,
				"poise_scalar": 1.0,
				"bullet_range_bonus": 16.0,
				"color": Color("67e8f9"),
				"inner_color": Color("ecfeff"),
				"spark_count": 3,
			}
		_:
			stage_data = {
				"stage": 3,
				"name": "收鞘回斩",
				"damage_scalar": 0.46,
				"range": 112.0,
				"arc": PI * 90.0 / 180.0,
				"startup": 0.14,
				"active": 0.08,
				"recovery": 0.23,
				"swing_arc": PI * 138.0 / 180.0,
				"swing_side": MELEE_SWORD_READY_SIDE,
				"angle_offset": 0.18,
				"shake": 5.2,
				"hitstop": MELEE_HITSTOP_BASE_DURATION * 1.55,
				"poise_scalar": 1.0,
				"bullet_range_bonus": 18.0,
				"color": Color("facc15"),
				"inner_color": Color("fff7ed"),
				"spark_count": 4,
			}
	var profile_color: Color = profile_data.get("color", COLORS["melee_sword"])
	_apply_melee_trait_profile_to_stage(stage_data, profile_data, normalized_stage)
	var time_scalar: float = maxf(float(profile_data.get("time_scalar", 1.0)), 0.05)
	stage_data["startup"] = maxf(float(stage_data.get("startup", 0.0)) * time_scalar, 0.025)
	stage_data["active"] = maxf(float(stage_data.get("active", 0.0)) * time_scalar, 0.035)
	stage_data["recovery"] = maxf(float(stage_data.get("recovery", 0.0)) * time_scalar, 0.045)
	stage_data["hitstop"] = maxf(float(stage_data.get("hitstop", 0.0)) * float(profile_data.get("hitstop_scalar", 1.0)), 0.0)
	stage_data["shake"] = maxf(float(stage_data.get("shake", 0.0)) * float(profile_data.get("shake_scalar", 1.0)), 0.0)
	stage_data["poise_scalar"] = maxf(float(stage_data.get("poise_scalar", 1.0)) * float(profile_data.get("poise_scalar", 1.0)), 0.0)
	stage_data["color"] = (stage_data.get("color", COLORS["melee_sword"]) as Color).lerp(profile_color, 0.28)
	if bool(profile_data.get("opening", false)) and normalized_stage == 1:
		stage_data["damage_scalar"] = float(stage_data.get("damage_scalar", 1.0)) * 1.35
		stage_data["range"] = float(stage_data.get("range", SWORD_MELEE_RANGE)) + 18.0
		stage_data["arc"] = float(stage_data.get("arc", SWORD_MELEE_ARC)) + PI * 14.0 / 180.0
		stage_data["swing_arc"] = float(stage_data.get("swing_arc", MELEE_SWORD_SWING_ARC)) + PI * 16.0 / 180.0
		stage_data["startup"] = maxf(float(stage_data.get("startup", 0.0)) - 0.015, 0.025)
		stage_data["shake"] = float(stage_data.get("shake", 0.0)) + 0.7
		stage_data["color"] = Color("60a5fa").lerp(profile_color, 0.2)
		stage_data["inner_color"] = Color("fef08a")
	if bool(profile_data.get("returning", false)) and normalized_stage == 3:
		stage_data["damage_scalar"] = float(stage_data.get("damage_scalar", 1.0)) * 1.35
		stage_data["range"] = float(stage_data.get("range", SWORD_MELEE_RANGE)) + 14.0
		stage_data["arc"] = float(stage_data.get("arc", SWORD_MELEE_ARC)) + PI * 8.0 / 180.0
		stage_data["swing_arc"] = float(stage_data.get("swing_arc", MELEE_SWORD_SWING_ARC)) + PI * 18.0 / 180.0
		stage_data["startup"] = float(stage_data.get("startup", 0.0)) + 0.025
		stage_data["shake"] = float(stage_data.get("shake", 0.0)) + 0.9
		stage_data["hitstop"] = float(stage_data.get("hitstop", 0.0)) + 0.006
		stage_data["color"] = Color("f59e0b").lerp(profile_color, 0.16)
		stage_data["inner_color"] = Color("fff7ed")
	var total_duration: float = (
		float(stage_data.get("startup", 0.0))
		+ float(stage_data.get("active", 0.0))
		+ float(stage_data.get("recovery", 0.0))
	)
	stage_data["total_duration"] = maxf(total_duration, 0.05)
	stage_data["swing_duration"] = stage_data["total_duration"]
	stage_data["cooldown"] = stage_data["total_duration"]
	stage_data["split_shadow"] = bool(stage_data.get("split_shadow", bool(profile_data.get("split", false)))) and not is_shadow
	stage_data["deflect_bullets"] = not is_shadow
	stage_data["grant_energy"] = not is_shadow
	stage_data["flash_duration"] = minf(maxf(float(stage_data.get("active", MELEE_ATTACK_FLASH_DURATION)) + 0.08, 0.08), MELEE_ATTACK_FLASH_DURATION * 1.65)
	stage_data["profile_name"] = str(profile_data.get("name", "测试剑"))
	if is_shadow:
		stage_data["damage_scalar"] = float(stage_data.get("damage_scalar", 1.0)) * float(stage_data.get("shadow_damage_scalar", MELEE_SHADOW_DAMAGE_SCALAR))
		if str(stage_data.get("damage_shape", "broad_arc")) == "long_line":
			stage_data["range"] = float(stage_data.get("range", SWORD_MELEE_RANGE)) + 18.0
			stage_data["visual_range"] = float(stage_data.get("visual_range", stage_data.get("range", SWORD_MELEE_RANGE))) + 12.0
			stage_data["hit_width"] = float(stage_data.get("hit_width", MELEE_FOCUSED_SLASH_HIT_WIDTH)) + 1.0
		else:
			stage_data["range"] = float(stage_data.get("range", SWORD_MELEE_RANGE)) + 8.0
			stage_data["visual_range"] = float(stage_data.get("visual_range", stage_data.get("range", SWORD_MELEE_RANGE))) + 6.0
			stage_data["arc"] = float(stage_data.get("arc", SWORD_MELEE_ARC)) + PI * 18.0 / 180.0
			stage_data["swing_arc"] = float(stage_data.get("swing_arc", MELEE_SWORD_SWING_ARC)) + PI * 18.0 / 180.0
		stage_data["shadow_direction_offset"] = 0.14 * float(stage_data.get("swing_side", MELEE_SWORD_SWING_SIDE))
		stage_data["origin_side_offset"] = 16.0 * float(stage_data.get("swing_side", MELEE_SWORD_SWING_SIDE))
		stage_data["origin_forward_offset"] = -5.0
		stage_data["hitstop"] = 0.0
		stage_data["shake"] = float(stage_data.get("shake", 0.0)) * 0.34
		stage_data["poise_scalar"] = float(stage_data.get("poise_scalar", 1.0)) * 0.35
		stage_data["bullet_range_bonus"] = 0.0
		stage_data["deflect_bullets"] = false
		stage_data["grant_energy"] = false
		stage_data["color"] = Color("c084fc")
		stage_data["inner_color"] = Color("e9d5ff")
		stage_data["flash_duration"] = MELEE_SHADOW_FLASH_DURATION
		stage_data["spark_count"] = 1
	return stage_data


func _get_focused_melee_stage_data(profile_data: Dictionary, is_shadow := false) -> Dictionary:
	var profile_color: Color = profile_data.get("color", COLORS["melee_sword"])
	var tempo_shape: String = str(profile_data.get("tempo_shape", "light"))
	var blade_shape: String = str(profile_data.get("blade_shape", "long"))
	var is_heavy: bool = tempo_shape == "heavy"
	var is_long: bool = blade_shape == "long"
	var focused_time_scalar: float = lerpf(1.0, maxf(float(profile_data.get("time_scalar", 1.0)), 0.05), 0.45)
	var stage_data := {
		"stage": 1,
		"name": "凝锋一刀",
		"damage_scalar": MELEE_FOCUSED_SLASH_DAMAGE_SCALAR,
		"range": SWORD_MELEE_RANGE,
		"visual_range": SWORD_MELEE_RANGE,
		"arc": SWORD_MELEE_ARC,
		"startup": 0.128 if is_heavy else 0.052,
		"active": 0.058 if is_heavy else 0.034,
		"recovery": 0.22 if is_heavy else 0.108,
		"swing_arc": PI * 34.0 / 180.0,
		"swing_side": MELEE_SWORD_SWING_SIDE,
		"angle_offset": 0.0,
		"shake": 7.8 if is_heavy else 5.2,
		"hitstop": MELEE_HITSTOP_BASE_DURATION * (2.25 if is_heavy else 1.45),
		"poise_scalar": 1.38 if is_heavy else 1.16,
		"bullet_range_bonus": 0.0,
		"color": Color("dbeafe").lerp(profile_color, 0.34),
		"inner_color": Color("ffffff"),
		"spark_count": 7 if is_heavy else 5,
		"tempo_shape": tempo_shape,
		"blade_shape": blade_shape,
		"spirit_shape": "focus",
		"deflect_shape": "guard_arc",
		"damage_shape": "long_line" if is_long else "broad_arc",
		"vfx_shape": "long_focus" if is_long else "broad_focus",
		"focus_style": "iaido_line" if is_long else "heavy_cleave",
		"focused_action": true,
		"focused_slash": is_long,
		"focused_phase": "focus",
	}
	if is_long:
		stage_data["name"] = "合刃拔刀线"
		stage_data["damage_scalar"] = 1.02 if is_heavy else 0.9
		stage_data["range"] = 178.0 if is_heavy else 166.0
		stage_data["visual_range"] = 178.0 if is_heavy else 164.0
		stage_data["arc"] = PI * 22.0 / 180.0
		stage_data["hit_width"] = 15.0 if is_heavy else 12.5
		stage_data["line_start_offset"] = 8.0
		stage_data["close_damage_range"] = 86.0 if is_heavy else 78.0
		stage_data["close_damage_arc"] = PI * (0.94 if is_heavy else 0.86)
		stage_data["swing_arc"] = PI * (26.0 if is_heavy else 18.0) / 180.0
		stage_data["deflect_range"] = maxf(float(stage_data["range"]) - 22.0, SWORD_MELEE_RANGE + 24.0)
		stage_data["deflect_arc"] = PI * (1.14 if is_heavy else 1.1)
		stage_data["deflect_bullet_range_bonus"] = 18.0
		stage_data["draw_deflect_shape"] = true
		stage_data["startup"] = 0.086 if is_heavy else 0.042
		stage_data["active"] = 0.038 if is_heavy else 0.024
		stage_data["recovery"] = 0.176 if is_heavy else 0.092
		stage_data["flash_duration"] = 0.12 if is_heavy else 0.086
		stage_data["cut_mark_size"] = 18.0 if is_heavy else 13.0
	else:
		stage_data["name"] = "合刃横断"
		stage_data["damage_scalar"] = 1.16 if is_heavy else 0.98
		stage_data["range"] = 128.0 if is_heavy else 116.0
		stage_data["visual_range"] = 144.0 if is_heavy else 128.0
		stage_data["arc"] = PI * (176.0 if is_heavy else 158.0) / 180.0
		stage_data["swing_arc"] = float(stage_data["arc"]) + PI * (34.0 if is_heavy else 24.0) / 180.0
		stage_data["deflect_range"] = float(stage_data["range"]) + 22.0
		stage_data["deflect_arc"] = maxf(float(stage_data["arc"]), PI * 1.18)
		stage_data["deflect_bullet_range_bonus"] = 12.0
		stage_data["draw_deflect_shape"] = false
		stage_data["startup"] = 0.176 if is_heavy else 0.078
		stage_data["active"] = 0.066 if is_heavy else 0.04
		stage_data["recovery"] = 0.245 if is_heavy else 0.13
		stage_data["flash_duration"] = 0.24 if is_heavy else 0.15
		stage_data["cleave_band_width"] = 28.0 if is_heavy else 20.0
	stage_data["startup"] = maxf(float(stage_data.get("startup", 0.0)) * focused_time_scalar, 0.035)
	stage_data["active"] = maxf(float(stage_data.get("active", 0.0)) * focused_time_scalar, 0.026)
	stage_data["recovery"] = maxf(float(stage_data.get("recovery", 0.0)) * focused_time_scalar, 0.07)
	stage_data["hitstop"] = maxf(float(stage_data.get("hitstop", 0.0)) * float(profile_data.get("hitstop_scalar", 1.0)), 0.0)
	stage_data["shake"] = maxf(float(stage_data.get("shake", 0.0)) * float(profile_data.get("shake_scalar", 1.0)), 0.0)
	stage_data["poise_scalar"] = maxf(float(stage_data.get("poise_scalar", 1.0)) * float(profile_data.get("poise_scalar", 1.0)), 0.0)
	var total_duration: float = (
		float(stage_data.get("startup", 0.0))
		+ float(stage_data.get("active", 0.0))
		+ float(stage_data.get("recovery", 0.0))
	)
	stage_data["total_duration"] = maxf(total_duration, 0.05)
	stage_data["swing_duration"] = stage_data["total_duration"]
	stage_data["cooldown"] = stage_data["total_duration"]
	stage_data["split_shadow"] = false
	stage_data["deflect_bullets"] = not is_shadow
	stage_data["grant_energy"] = not is_shadow
	stage_data["flash_duration"] = float(stage_data.get("flash_duration", 0.19 if is_heavy else 0.13))
	stage_data["profile_name"] = str(profile_data.get("name", "测试剑"))
	if is_shadow:
		stage_data["damage_scalar"] = float(stage_data.get("damage_scalar", 1.0)) * MELEE_SHADOW_DAMAGE_SCALAR
		stage_data["hitstop"] = 0.0
		stage_data["shake"] = float(stage_data.get("shake", 0.0)) * 0.34
		stage_data["poise_scalar"] = float(stage_data.get("poise_scalar", 1.0)) * 0.35
		stage_data["deflect_bullets"] = false
		stage_data["grant_energy"] = false
		stage_data["color"] = Color("c084fc")
		stage_data["inner_color"] = Color("e9d5ff")
		stage_data["flash_duration"] = MELEE_SHADOW_FLASH_DURATION
	return stage_data


func _apply_melee_arc_attack(stage_data: Dictionary, attack_direction: Vector2, is_shadow := false) -> void:
	var swing_direction: Vector2 = attack_direction.normalized()
	if swing_direction.is_zero_approx():
		swing_direction = _get_melee_attack_direction()
	var attack_origin: Vector2 = player["pos"]
	var lateral_direction: Vector2 = swing_direction.orthogonal().normalized()
	if lateral_direction.is_zero_approx():
		lateral_direction = Vector2.UP
	attack_origin += lateral_direction * float(stage_data.get("origin_side_offset", 0.0))
	attack_origin += swing_direction * float(stage_data.get("origin_forward_offset", 0.0))
	var melee_attack_instance: Dictionary = _build_attack_instance(
		AttackProfiles.PROFILE_MELEE_SLASH,
		"player",
		"melee_shadow" if is_shadow else "melee"
	)
	var melee_attack_instance_id: String = str(melee_attack_instance.get("id", ""))
	var melee_attack_profile_id: String = str(melee_attack_instance.get("profile_id", AttackProfiles.PROFILE_MELEE_SLASH))
	var detection_result: Dictionary
	var damage_shape: String = str(stage_data.get("damage_shape", "long_line" if bool(stage_data.get("focused_slash", false)) else "broad_arc"))
	if damage_shape == "long_line":
		var line_start: Vector2 = attack_origin + swing_direction * float(stage_data.get("line_start_offset", 8.0))
		var line_end: Vector2 = attack_origin + swing_direction * float(stage_data.get("range", SWORD_MELEE_RANGE))
		detection_result = hit_detection.collect_segment_sweep_targets(
			self ,
			line_start,
			line_end,
			float(stage_data.get("hit_width", MELEE_FOCUSED_SLASH_HIT_WIDTH)),
			melee_attack_profile_id,
			DAMAGE_SOURCE_MELEE,
			0.0,
			{
				"exclude_enemy_types": [PUPPET],
			}
		)
		if float(stage_data.get("close_damage_range", 0.0)) > 0.0:
			var close_damage_result: Dictionary = hit_detection.collect_melee_arc_targets(
				self ,
				attack_origin,
				swing_direction,
				float(stage_data.get("close_damage_range", 0.0)),
				float(stage_data.get("close_damage_arc", stage_data.get("arc", SWORD_MELEE_ARC))),
				melee_attack_profile_id,
				DAMAGE_SOURCE_MELEE,
				{
					"exclude_enemy_types": [PUPPET],
					"bullet_range_bonus": 0.0,
				}
			)
			var merged_contacts: Array = detection_result.get("contacts", [])
			var existing_target_ids := {}
			for contact_variant in merged_contacts:
				var contact: Dictionary = contact_variant
				existing_target_ids[str(contact.get("target_id", ""))] = true
			for close_contact_variant in close_damage_result.get("contacts", []):
				var close_contact: Dictionary = close_contact_variant
				var close_target_id: String = str(close_contact.get("target_id", ""))
				if existing_target_ids.has(close_target_id):
					continue
				merged_contacts.append(close_contact)
				existing_target_ids[close_target_id] = true
			detection_result["contacts"] = merged_contacts
			var existing_boss_contact: Dictionary = detection_result.get("boss_contact", {})
			if existing_boss_contact.is_empty():
				detection_result["boss_contact"] = close_damage_result.get("boss_contact", {})
	else:
		detection_result = hit_detection.collect_melee_arc_targets(
			self ,
			attack_origin,
			swing_direction,
			float(stage_data.get("range", SWORD_MELEE_RANGE)),
			float(stage_data.get("arc", SWORD_MELEE_ARC)),
			melee_attack_profile_id,
			DAMAGE_SOURCE_MELEE,
			{
				"exclude_enemy_types": [PUPPET],
				"bullet_range_bonus": float(stage_data.get("bullet_range_bonus", 20.0)),
			}
		)
	if bool(stage_data.get("deflect_bullets", true)):
		var deflect_detection_result: Dictionary = hit_detection.collect_melee_arc_targets(
			self ,
			attack_origin,
			swing_direction,
			float(stage_data.get("deflect_range", stage_data.get("range", SWORD_MELEE_RANGE))),
			float(stage_data.get("deflect_arc", stage_data.get("arc", SWORD_MELEE_ARC))),
			melee_attack_profile_id,
			DAMAGE_SOURCE_MELEE,
			{
				"exclude_enemy_types": [PUPPET],
				"bullet_range_bonus": float(stage_data.get("deflect_bullet_range_bonus", stage_data.get("bullet_range_bonus", 12.0))),
			}
		)
		detection_result["bullet_contacts"] = deflect_detection_result.get("bullet_contacts", [])
	else:
		detection_result["bullet_contacts"] = []
	var slash_color: Color = stage_data.get("color", COLORS["melee_sword"])
	var hit_any_target := false
	if bool(stage_data.get("deflect_bullets", true)):
		for bullet_contact_variant in detection_result.get("bullet_contacts", []):
			var bullet_contact: Dictionary = bullet_contact_variant
			var bullet: Variant = bullet_contact.get("bullet", null)
			if bullet == null:
				continue
			var bullet_color: Color = bullet.get("color", COLORS["bullet"])
			_deflect_enemy_bullet(bullet, swing_direction)
			_emit_sword_hit_effect(
				bullet_contact.get("contact_point", bullet["pos"]),
				swing_direction,
				slash_color.lerp(bullet_color, 0.18),
				1.0,
				"deflect",
				{
					"spark_count": 4,
				}
			)
			_add_player_energy(ENERGY_GAIN_MELEE_DEFLECT * (1.5 if bullet["type"] == "large" else 1.0))
			screen_shake = max(screen_shake, maxf(float(stage_data.get("shake", 3.0)) * 0.66, 2.0))
	var hit_overrides := {
		"channel_scalar": maxf(float(stage_data.get("damage_scalar", 1.0)), 0.0),
		"channel_scalar_overrides": {
			AttackProfiles.CHANNEL_POISE: maxf(float(stage_data.get("poise_scalar", 1.0)), 0.0),
		},
	}
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
			bool(contact.get("is_currently_overlapping", true)),
			hit_overrides
		)
		if not bool(attack_result.get("allowed", false)):
			continue
		hit_any_target = true
		if bool(stage_data.get("grant_energy", true)):
			_add_player_energy(ENERGY_GAIN_MELEE_HIT)
		_emit_sword_hit_effect(
			contact.get("contact_point", enemy["pos"]),
			swing_direction,
			slash_color.lerp(COLORS[str(enemy.get("type", SHOOTER))], 0.24),
			0.76 if is_shadow else 1.06,
			"melee",
			{
				"spark_count": int(stage_data.get("spark_count", 3)),
			}
		)
		_create_particles(enemy["pos"], slash_color, 2 if is_shadow else 5)
		screen_shake = max(screen_shake, float(stage_data.get("shake", 4.0)))
	if _has_boss():
		var boss_contact: Dictionary = detection_result.get("boss_contact", {})
		if not boss_contact.is_empty():
			var boss_hit_result: Dictionary = _apply_boss_attack_instance_hit(
				melee_attack_instance_id,
				melee_attack_profile_id,
				boss_contact.get("contact_point", boss["pos"]),
				DAMAGE_SOURCE_MELEE,
				float(boss_contact.get("contact_time", 0.0)),
				bool(boss_contact.get("is_currently_overlapping", true)),
				hit_overrides
			)
			if bool(boss_hit_result.get("allowed", false)):
				hit_any_target = true
				if bool(stage_data.get("grant_energy", true)):
					_add_player_energy(ENERGY_GAIN_MELEE_HIT)
				_emit_sword_hit_effect(
					boss_contact.get("contact_point", boss["pos"]),
					swing_direction,
					slash_color.lerp(COLORS["boss_body"], 0.28),
					0.82 if is_shadow else 1.12,
					"melee",
					{
						"spark_count": int(stage_data.get("spark_count", 4)),
					}
				)
				_create_particles(boss["pos"], slash_color, 4 if is_shadow else 8)
				screen_shake = max(screen_shake, float(stage_data.get("shake", 5.0)) + 0.8)
	if hit_any_target and float(stage_data.get("hitstop", 0.0)) > 0.0:
		_request_hitstop(float(stage_data.get("hitstop", 0.0)))
	_clear_attack_instance(melee_attack_instance_id)


func _queue_melee_shadow_strike(stage_data: Dictionary, attack_direction: Vector2) -> void:
	var shadow_strikes: Array = player.get("melee_shadow_strikes", [])
	var shadow_stage_data: Dictionary = _get_melee_combo_stage_data(int(stage_data.get("stage", 1)), true)
	var shadow_direction: Vector2 = attack_direction.normalized().rotated(float(shadow_stage_data.get("shadow_direction_offset", 0.0)))
	shadow_strikes.append({
		"timer": float(stage_data.get("shadow_delay", MELEE_SHADOW_STRIKE_DELAY)),
		"direction": shadow_direction.normalized(),
		"stage_data": shadow_stage_data,
	})
	while shadow_strikes.size() > 6:
		shadow_strikes.remove_at(0)
	player["melee_shadow_strikes"] = shadow_strikes


func _start_melee_swing_visual(attack_direction: Vector2, stage_data: Dictionary) -> void:
	var swing_direction: Vector2 = attack_direction.normalized()
	if swing_direction.is_zero_approx():
		swing_direction = _get_held_sword_aim_direction()
	var swing_duration: float = maxf(float(stage_data.get("swing_duration", MELEE_SWORD_SWING_DURATION)), 0.04)
	player["attack_flash_duration"] = maxf(float(stage_data.get("flash_duration", MELEE_ATTACK_FLASH_DURATION)), 0.04)
	player["attack_flash_timer"] = 0.0
	player["melee_swing_timer"] = swing_duration
	player["melee_swing_duration"] = swing_duration
	player["melee_swing_angle"] = swing_direction.angle() + float(stage_data.get("angle_offset", 0.0))
	player["melee_swing_side"] = float(stage_data.get("swing_side", MELEE_SWORD_SWING_SIDE))
	player["melee_swing_range"] = float(stage_data.get("visual_range", stage_data.get("range", SWORD_MELEE_RANGE)))
	player["melee_swing_arc"] = float(stage_data.get("swing_arc", MELEE_SWORD_SWING_ARC))
	player["melee_attack_range"] = float(stage_data.get("range", SWORD_MELEE_RANGE))
	player["melee_attack_arc"] = float(stage_data.get("arc", SWORD_MELEE_ARC))
	player["melee_flash_color"] = stage_data.get("color", COLORS["melee_sword"])
	player["melee_flash_inner_color"] = stage_data.get("inner_color", COLORS["melee_sword"].lerp(Color.WHITE, 0.42))
	sword["afterimage_burst_timer"] = maxf(float(sword.get("afterimage_burst_timer", 0.0)), SWORD_AFTERIMAGE_BURST_DURATION)
	sword["afterimage_emit_timer"] = 0.0
	_trigger_rider_action("parry", swing_direction, RIDER_MELEE_BODY_DURATION, 1.15)


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
	if _is_demo_level_active():
		demo_level_controller.on_deflect(self)
	_create_particles(bullet["pos"], COLORS["melee_sword"], 4)


func _start_point_strike() -> void:
	var unsheath_direction: Vector2 = mouse_world - player["pos"]
	var release_anchor: Vector2 = _get_unsheath_flash_release_anchor(unsheath_direction, SwordState.POINT_STRIKE)
	var combo_id: String = SwordResonanceController.consume_time_stop_combo(player)
	_trigger_rider_sword_control_enter(unsheath_direction)
	_trigger_unsheath_flash(
		unsheath_direction,
		release_anchor
	)
	_trigger_time_rift_enter(unsheath_direction, release_anchor)
	_start_sword_attack_instance(AttackProfiles.PROFILE_FLYING_SWORD_POINT)
	sword["state"] = SwordState.POINT_STRIKE
	sword["target_pos"] = mouse_world
	_set_player_combat_mode(CombatMode.RANGED)
	_start_sword_combo(combo_id, release_anchor, mouse_world)
	if combo_id == SwordResonanceController.COMBO_FAN_TIME_STOP:
		_show_focus_status_message("分光御剑", SwordResonanceController.get_color(SwordArrayConfig.MODE_FAN), 0.58)
	elif combo_id == SwordResonanceController.COMBO_PIERCE_TIME_STOP:
		_show_focus_status_message("剑虹贯日", SwordResonanceController.get_color(SwordArrayConfig.MODE_PIERCE), 0.58)


func _start_slicing() -> void:
	var unsheath_direction: Vector2 = mouse_world - player["pos"]
	var release_anchor: Vector2 = _get_unsheath_flash_release_anchor(unsheath_direction, SwordState.SLICING)
	var combo_id: String = SwordResonanceController.consume_time_stop_combo(player)
	_trigger_rider_sword_control_enter(unsheath_direction)
	_trigger_unsheath_flash(
		unsheath_direction,
		release_anchor
	)
	_trigger_time_rift_enter(unsheath_direction, release_anchor)
	if combo_id == SwordResonanceController.COMBO_PIERCE_TIME_STOP:
		sword["state"] = SwordState.PIERCE_DRAWING
		sword["pos"] = release_anchor
		sword["prev_pos"] = release_anchor
		sword["vel"] = Vector2.ZERO
		_set_player_combat_mode(CombatMode.RANGED)
		_start_sword_combo(combo_id, release_anchor, mouse_world)
		_show_focus_status_message("剑虹贯日", SwordResonanceController.get_color(SwordArrayConfig.MODE_PIERCE), 0.58)
		return
	_start_sword_attack_instance(AttackProfiles.PROFILE_FLYING_SWORD_SLICE)
	sword["state"] = SwordState.SLICING
	_set_player_combat_mode(CombatMode.RANGED)
	_start_sword_combo(combo_id, release_anchor, mouse_world)
	if combo_id == SwordResonanceController.COMBO_FAN_TIME_STOP:
		_show_focus_status_message("分光御剑", SwordResonanceController.get_color(SwordArrayConfig.MODE_FAN), 0.58)
	elif combo_id == SwordResonanceController.COMBO_PIERCE_TIME_STOP:
		_show_focus_status_message("剑虹贯日", SwordResonanceController.get_color(SwordArrayConfig.MODE_PIERCE), 0.58)


func _commit_quick_release_point_strike() -> void:
	_trigger_rider_sword_control_enter(mouse_world - player["pos"])
	_set_sword_attack_profile(AttackProfiles.PROFILE_FLYING_SWORD_POINT)
	sword["state"] = SwordState.POINT_STRIKE
	sword["target_pos"] = mouse_world
	_set_player_combat_mode(CombatMode.RANGED)


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
	var release_origin: Vector2 = player["pos"]
	if _is_flight_prototype_mode():
		release_origin = Vector2(_get_flight_held_sword_pose().get("center", player["pos"]))
	var target_distance: float = release_origin.distance_to(mouse_world)
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
	return release_origin + flash_direction * (clamped_distance + UNSHEATH_FLASH_SWORD_FORWARD_OFFSET)


func _get_unsheath_flash_release_distance(target_distance: float, desired_distance: float) -> float:
	var max_distance: float = minf(
		maxf(target_distance - 10.0, SWORD_ORBIT_DISTANCE + 12.0),
		UNSHEATH_FLASH_RELEASE_MAX_DISTANCE
	)
	var min_distance: float = minf(UNSHEATH_FLASH_RELEASE_MIN_DISTANCE, max_distance)
	return clampf(desired_distance, min_distance, max_distance)


func _get_unsheath_press_flash_anchor(flash_direction: Vector2, anchor_lerp: float) -> Vector2:
	if _is_flight_prototype_mode():
		return Vector2(_get_flight_held_sword_pose().get("hilt", player["pos"])) - flash_direction * UNSHEATH_FLASH_ROOT_BACK_OFFSET
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

	var melee_swinging: bool = _is_melee_swing_visual_active()
	if sword["state"] != SwordState.POINT_STRIKE and sword["state"] != SwordState.SLICING and sword["state"] != SwordState.RECALLING and not melee_swinging:
		sword["trail_emit_timer"] = 0.0
		return

	var emit_timer: float = max(float(sword.get("trail_emit_timer", 0.0)) - delta, 0.0)
	var min_speed: float = float(vfx.trail_min_speed) * (0.7 if melee_swinging else (0.82 if sword["state"] == SwordState.RECALLING else 1.0))
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
	var is_slice: bool = sword["state"] == SwordState.SLICING or _is_melee_swing_visual_active()
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

	var melee_swinging: bool = _is_melee_swing_visual_active()
	if sword["state"] == SwordState.ORBITING and not melee_swinging:
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

	var melee_swinging: bool = _is_melee_swing_visual_active()
	if (sword["state"] == SwordState.ORBITING and not melee_swinging) or sword["state"] == SwordState.RECALLING:
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
		"angle": float(sword.get("angle", direction.angle())) if _is_melee_swing_visual_active() else direction.angle(),
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
		AttackProfiles.PROFILE_FLYING_SWORD_PIERCE_COMBO:
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
		AttackProfiles.PROFILE_FLYING_SWORD_PIERCE_COMBO:
			offset_distance = 8.8
			angle_offset = 0.22 * side_sign
			screen_shake_strength = 5.2
			local_hit_intensity = 0.92
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
	var morph_state: Dictionary = _get_effective_array_fire_state()
	var mode: String = String(morph_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	if not _can_fire_array_batch(mode, ready_count):
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return false
	var pending_combo_id: String = SwordResonanceController.peek_array_combo(player, mode)
	var fire_count: int = _get_array_combo_fire_count(pending_combo_id, mode, ready_count)
	var energy_fire_count: int = fire_count
	var energy_cost: float = _get_array_sword_energy_cost(energy_fire_count, mode)
	if energy_cost > 0.0 and not _try_consume_energy(energy_cost):
		_show_action_failure("剑意不足", "array_energy", _get_energy_failure_color(), "energy")
		return false
	player["array_packet_remainder"] = 0.0
	var source_snapshot: Array = _build_array_sword_source_snapshot()
	fire_count = mini(fire_count, source_snapshot.size())
	if fire_count <= 0:
		_show_action_failure("飞剑未回收", "array_ready", _get_array_failure_color(), "array")
		return false
	var combo_id: String = SwordResonanceController.consume_array_combo(player, mode) if pending_combo_id != SwordResonanceController.COMBO_NONE else SwordResonanceController.COMBO_NONE
	var fire_state_source: Dictionary = _build_resonance_array_combo_state(combo_id, mode) if combo_id != SwordResonanceController.COMBO_NONE else morph_state
	var batch_id: String = _next_id("array_batch") if mode == SwordArrayConfig.MODE_FAN else ""
	var fire_override_target_pos: Variant = _get_array_fire_override_target_pos_for_mode(mode)
	var fire_override_target_kind: String = _get_array_fire_override_target_kind_for_mode(mode)
	_trigger_rider_array_release(mode, mouse_world - player["pos"])
	var burst_step: int = 0
	var fired_count: int = 0
	while fired_count < fire_count:
		var snapshot_positions: Array = []
		for source in source_snapshot:
			snapshot_positions.append(source["pos"])
		var source_snapshot_index: int = SwordArrayController.get_fire_source_snapshot_index(
			self ,
			fire_state_source,
			snapshot_positions,
			fired_count,
			fire_count,
			burst_step,
			ready_count
		)
		if source_snapshot_index < 0 or source_snapshot_index >= source_snapshot.size():
			source_snapshot_index = 0
		var sword_id: String = str(source_snapshot[source_snapshot_index]["id"])
		_fire_single_array_sword(sword_id, fired_count, fire_count, burst_step, ready_count, batch_id, mode, null, null, fire_state_source, combo_id, fire_override_target_pos, fire_override_target_kind)
		source_snapshot.remove_at(source_snapshot_index)
		fired_count += 1
	_emit_sword_array_fire_effect(fire_state_source, fire_count)
	player["array_effective_fire_mode"] = mode
	_advance_sword_spirit_takeover_plan(mode)
	if combo_id == SwordResonanceController.COMBO_RING_TO_PIERCE:
		_show_focus_status_message("圆势归一", SwordResonanceController.get_color(SwordArrayConfig.MODE_RING), 0.58)
		screen_shake = maxf(screen_shake, 5.2)
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


func _fire_single_array_sword(
	sword_id: String,
	volley_fire_index: int,
	volley_fire_count: int,
	burst_step: int,
	total_count_before_fire: int,
	batch_id := "",
	override_mode := "",
	override_launch_origin = null,
	override_target_anchor = null,
	override_state_source = null,
	combo_id := "",
	override_fire_target_pos = null,
	override_fire_target_kind := ""
) -> void:
	if sword_id == "":
		return
	var array_sword: Dictionary = _get_array_sword_by_id(sword_id)
	if array_sword.is_empty() or String(array_sword.get("state", "")) != "ready":
		return
	var travel_mode: String = str(override_mode)
	if travel_mode == "":
		travel_mode = _get_array_batch_mode()
	var fire_state_source = _get_sword_array_fire_state()
	if typeof(override_state_source) == TYPE_DICTIONARY:
		var override_state: Dictionary = override_state_source
		if not override_state.is_empty():
			fire_state_source = override_state
	var launch_origin: Vector2 = array_sword["pos"]
	if typeof(override_launch_origin) == TYPE_VECTOR2:
		launch_origin = override_launch_origin
	else:
		launch_origin = SwordArrayController.get_fire_launch_origin(
			self ,
			fire_state_source,
			volley_fire_index,
			array_sword["pos"],
			volley_fire_count,
			burst_step,
			total_count_before_fire
		)
	var target_anchor: Vector2 = launch_origin
	if typeof(override_target_anchor) == TYPE_VECTOR2:
		target_anchor = override_target_anchor
	var override_target_point: Variant = null
	if typeof(override_fire_target_pos) == TYPE_VECTOR2:
		override_target_point = _resolve_array_sword_override_fire_target(
			launch_origin,
			Vector2(override_fire_target_pos),
			str(override_fire_target_kind),
			travel_mode
		)
	var target_point: Vector2
	if typeof(override_target_point) == TYPE_VECTOR2:
		target_point = override_target_point
	else:
		target_point = SwordArrayController.get_fire_target(
			self ,
			fire_state_source,
			volley_fire_index,
			target_anchor,
			volley_fire_count,
			burst_step,
			total_count_before_fire
		)
	var direction: Vector2 = target_point - launch_origin
	if direction.is_zero_approx():
		direction = mouse_world - player["pos"]
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	array_sword["pos"] = launch_origin
	array_sword["state"] = "outbound"
	array_sword["travel_mode"] = travel_mode
	_reset_array_sword_sortie_state(array_sword)
	array_sword["combo_id"] = combo_id
	array_sword["combo_timer"] = 0.72 if combo_id != "" else 0.0
	array_sword["combo_duration"] = array_sword["combo_timer"]
	_start_array_sword_attack_instance(array_sword)
	array_sword["batch_id"] = String(batch_id)
	array_sword["guidance_active"] = true
	array_sword["guidance_fire_index"] = volley_fire_index
	array_sword["guidance_volley_count"] = volley_fire_count
	array_sword["guidance_burst_step"] = burst_step
	array_sword["guidance_total_count"] = total_count_before_fire
	if typeof(override_state_source) == TYPE_DICTIONARY:
		array_sword["guidance_state_source"] = fire_state_source.duplicate(true)
	else:
		array_sword["guidance_state_source"] = {}
	if typeof(override_target_point) == TYPE_VECTOR2 and typeof(override_fire_target_pos) == TYPE_VECTOR2 and str(override_fire_target_kind) != "":
		array_sword["guidance_override_target_pos"] = Vector2(override_fire_target_pos)
		array_sword["guidance_override_target_kind"] = str(override_fire_target_kind)
	else:
		array_sword["guidance_override_target_pos"] = Vector2.ZERO
		array_sword["guidance_override_target_kind"] = ""
	var base_direction: Vector2 = direction.normalized()
	var flow_side: float = _resolve_array_sword_flow_side(array_sword, launch_origin, base_direction)
	array_sword["flow_side"] = flow_side
	var launch_tangent_bias: float = _get_array_sword_launch_tangent_bias(travel_mode) * _get_array_sword_flow_slot_weight(array_sword, travel_mode)
	if typeof(override_target_point) == TYPE_VECTOR2 and travel_mode == SwordArrayConfig.MODE_PIERCE:
		launch_tangent_bias = 0.0
	var launch_velocity_direction: Vector2 = _blend_array_sword_direction_with_tangent(
		base_direction,
		_get_array_sword_launch_tangent_direction(travel_mode, launch_origin, base_direction, flow_side),
		launch_tangent_bias
	)
	array_sword["vel"] = launch_velocity_direction * _get_current_array_sword_speed(travel_mode)
	player["array_fire_index"] += 1
	_create_particles(array_sword["pos"], COLORS["array_sword"], 5)
	screen_shake = max(screen_shake, 2.0)


func _emit_sword_array_fire_effect(state_source, fire_count: int) -> void:
	var effect: Dictionary = SwordArrayController.get_fire_effect(self , state_source, fire_count)
	_create_particles(effect["position"], effect["color"], effect["particles"])
	screen_shake = max(screen_shake, effect["shake"])
	_pulse_cursor_intent_fire(fire_count)


func _spawn_enemy(enemy_type: String, spawn_position_override = null) -> Dictionary:
	var has_spawn_override: bool = typeof(spawn_position_override) == TYPE_VECTOR2
	var spawn_pos: Vector2 = spawn_position_override if has_spawn_override else _roll_spawn_position()
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
		FORMATION_EYE:
			enemy["radius"] = LARGE_ARENA_EYE_RADIUS
			enemy["health"] = LARGE_ARENA_EYE_HEALTH
			enemy["max_health"] = LARGE_ARENA_EYE_HEALTH
			enemy["score"] = 150
			enemy["shoot_cooldown"] = 9999.0
			enemy["large_arena_role"] = "objective"
		FORMATION_CORE:
			enemy["radius"] = LARGE_ARENA_CORE_RADIUS
			enemy["health"] = LARGE_ARENA_CORE_HEALTH
			enemy["max_health"] = LARGE_ARENA_CORE_HEALTH
			enemy["score"] = 500
			enemy["shoot_cooldown"] = 9999.0
			enemy["large_arena_role"] = "objective"
		_:
			enemy["shoot_cooldown"] = randf_range(0.4, SHOOTER_COOLDOWN)
	if has_spawn_override:
		var enemy_radius: float = float(enemy.get("radius", SHOOTER_RADIUS))
		enemy["pos"] = Vector2(spawn_position_override).clamp(
			Vector2(enemy_radius, enemy_radius),
			_get_arena_size() - Vector2(enemy_radius, enemy_radius)
		)
		enemy["package_desired_pos"] = enemy["pos"]
		enemy["package_center"] = enemy["pos"]
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


func _spawn_score_loot_for_enemy(enemy: Dictionary) -> void:
	var value: int = int(enemy.get("score", 0))
	if value <= 0:
		return
	var drop_pos: Vector2 = Vector2(enemy.get("pos", player["pos"])) + Vector2(enemy.get("hit_reaction_offset", Vector2.ZERO))
	drop_pos = drop_pos.clamp(Vector2(SCORE_LOOT_RADIUS, SCORE_LOOT_RADIUS), ARENA_SIZE - Vector2(SCORE_LOOT_RADIUS, SCORE_LOOT_RADIUS))
	score_loot_pickups.append({
		"id": _next_id("score_loot"),
		"pos": drop_pos,
		"value": value,
		"life": SCORE_LOOT_LIFE_DURATION,
		"max_life": SCORE_LOOT_LIFE_DURATION,
		"radius": SCORE_LOOT_RADIUS,
		"pulse": randf() * TAU,
		"pickup_delay": SCORE_LOOT_PICKUP_ARM_DELAY,
		"source_enemy_type": str(enemy.get("type", "")),
	})


func _update_score_loot_pickups(delta: float) -> void:
	var index: int = score_loot_pickups.size() - 1
	while index >= 0:
		var pickup: Dictionary = score_loot_pickups[index]
		pickup["pulse"] = float(pickup.get("pulse", 0.0)) + delta
		pickup["pickup_delay"] = maxf(float(pickup.get("pickup_delay", 0.0)) - delta, 0.0)
		pickup["life"] = maxf(float(pickup.get("life", 0.0)) - delta, 0.0)
		var pickup_pos: Vector2 = Vector2(pickup.get("pos", Vector2.ZERO))
		var can_pick_up: bool = float(pickup.get("pickup_delay", 0.0)) <= 0.0
		can_pick_up = can_pick_up and pickup_pos.distance_to(Vector2(player.get("pos", Vector2.ZERO))) <= SCORE_LOOT_PICKUP_DISTANCE
		if can_pick_up:
			_collect_score_loot_pickup(pickup)
			score_loot_pickups.remove_at(index)
		elif float(pickup.get("life", 0.0)) <= 0.0:
			score_loot_pickups.remove_at(index)
		else:
			score_loot_pickups[index] = pickup
		index -= 1


func _collect_score_loot_pickup(pickup: Dictionary) -> void:
	var value: int = int(pickup.get("value", 0))
	if value <= 0:
		return
	var pickup_pos: Vector2 = Vector2(pickup.get("pos", player["pos"]))
	score += value
	var loot_color: Color = COLORS["energy"].lerp(Color.WHITE, 0.16)
	_create_particles(pickup_pos, loot_color, 12)
	score_feedback_timer = maxf(score_feedback_timer, SCORE_LOOT_FEEDBACK_DURATION)
	score_feedback_color = loot_color


func _update_flight_prototype(delta: float) -> void:
	if flight_stage_complete:
		_add_player_energy(FLIGHT_PASSIVE_ENERGY_REGEN * delta, false)
		return
	flight_stage_timer += delta
	_add_player_energy(FLIGHT_PASSIVE_ENERGY_REGEN * delta, false)
	_update_flight_scripted_events()
	if flight_stage_timer >= FLIGHT_STAGE_DURATION:
		flight_stage_complete = true
		flight_segment_label = "航道测试完成"
		_show_status_message("航道测试完成", COLORS["energy"], 1.6)
		_show_focus_status_message("测试完成", COLORS["energy"].lerp(Color.WHITE, 0.18), 0.8)


func _get_flight_scripted_events() -> Array:
	return [
		{"time": 1.0, "kind": "intro_shooters", "label": "起飞校准"},
		{"time": 9.0, "kind": "fan_wall", "label": "扇阵清面"},
		{"time": 19.0, "kind": "ring_pressure", "label": "环阵护身"},
		{"time": 30.0, "kind": "pierce_eye", "label": "贯穿破线"},
		{"time": 42.0, "kind": "vertical_clamp", "label": "上下夹击"},
		{"time": 55.0, "kind": "rear_chase", "label": "后侧追袭"},
		{"time": 68.0, "kind": "mixed_wave", "label": "综合敌阵"},
		{"time": 81.0, "kind": "final_eye", "label": "小型阵眼"},
	]


func _update_flight_scripted_events() -> void:
	var events: Array = _get_flight_scripted_events()
	while flight_script_index < events.size():
		var event: Dictionary = events[flight_script_index]
		if flight_stage_timer < float(event.get("time", 0.0)):
			return
		flight_segment_index = flight_script_index + 1
		flight_segment_label = str(event.get("label", "航道段落"))
		_spawn_flight_event(str(event.get("kind", "")))
		_show_status_message(flight_segment_label, COLORS["ranged_sword"], 1.0)
		flight_script_index += 1


func _spawn_flight_event(kind: String) -> void:
	if _has_debug_flag("no_spawn"):
		return
	match kind:
		"intro_shooters":
			_spawn_flight_enemy(SHOOTER, Vector2(820.0, 240.0), "drift_shooter")
			_spawn_flight_enemy(SHOOTER, Vector2(875.0, 420.0), "drift_shooter")
		"fan_wall":
			for lane_index in range(5):
				var y: float = 150.0 + float(lane_index) * 84.0
				_spawn_flight_enemy(SHOOTER, Vector2(830.0 + float(lane_index % 2) * 54.0, y), "fan_cluster")
		"ring_pressure":
			_spawn_flight_enemy(RING_LEECH, Vector2(340.0, 38.0), "ring_pursuer")
			_spawn_flight_enemy(RING_LEECH, Vector2(420.0, 586.0), "ring_pursuer")
			_spawn_flight_enemy(TANK, Vector2(850.0, 322.0), "drift_shooter")
		"pierce_eye":
			_spawn_flight_enemy(MIRROR_NEEDLER, Vector2(870.0, 318.0), "array_eye")
			_spawn_flight_enemy(SHOOTER, Vector2(805.0, 224.0), "drift_shooter")
			_spawn_flight_enemy(SHOOTER, Vector2(805.0, 414.0), "drift_shooter")
		"vertical_clamp":
			_spawn_flight_enemy(CASTER, Vector2(845.0, 118.0), "caster_lane")
			_spawn_flight_enemy(CASTER, Vector2(890.0, 514.0), "caster_lane")
			_spawn_flight_enemy(HEAVY, Vector2(910.0, 318.0), "heavy_gate")
		"rear_chase":
			_spawn_flight_enemy(RING_LEECH, Vector2(74.0, 172.0), "ring_pursuer")
			_spawn_flight_enemy(RING_LEECH, Vector2(54.0, 454.0), "ring_pursuer")
			_spawn_flight_enemy(SHOOTER, Vector2(865.0, 318.0), "fan_cluster")
		"mixed_wave":
			_spawn_flight_enemy(DRAPE_PRIEST, Vector2(850.0, 190.0), "drift_shooter")
			_spawn_flight_enemy(SHOOTER, Vector2(885.0, 288.0), "fan_cluster")
			_spawn_flight_enemy(SHOOTER, Vector2(885.0, 382.0), "fan_cluster")
			_spawn_flight_enemy(HEAVY, Vector2(930.0, 470.0), "heavy_gate")
		"final_eye":
			_spawn_flight_enemy(MIRROR_NEEDLER, Vector2(900.0, 318.0), "array_eye")
			for lane_index in range(4):
				var side_y: float = 162.0 + float(lane_index) * 104.0
				_spawn_flight_enemy(SHOOTER, Vector2(830.0 + float(lane_index) * 42.0, side_y), "fan_cluster")


func _spawn_flight_enemy(enemy_type: String, spawn_pos: Vector2, behavior: String) -> Dictionary:
	var enemy: Dictionary = _spawn_enemy(enemy_type, spawn_pos.clamp(Vector2.ZERO, ARENA_SIZE))
	enemy["pos"] = spawn_pos
	enemy["package_desired_pos"] = spawn_pos
	enemy["package_center"] = spawn_pos
	enemy["flight_behavior"] = behavior
	enemy["flight_spawn_time"] = flight_stage_timer
	enemy["flight_base_y"] = spawn_pos.y
	enemy["flight_phase"] = randf() * TAU
	enemy["shoot_cooldown"] = randf_range(0.45, 1.1)
	if behavior == "array_eye":
		enemy["health"] = maxf(float(enemy.get("health", 0.0)), 72.0)
		enemy["max_health"] = enemy["health"]
		enemy["mirror_vulnerable_timer"] = 999.0
		enemy["charge_timer"] = 0.0
	elif behavior == "heavy_gate":
		enemy["shoot_cooldown"] = randf_range(0.7, 1.2)
	return enemy


func _update_flight_enemy(enemy: Dictionary, delta: float) -> bool:
	var behavior: String = str(enemy.get("flight_behavior", ""))
	if behavior == "":
		return false
	var life: float = maxf(flight_stage_timer - float(enemy.get("flight_spawn_time", flight_stage_timer)), 0.0)
	var phase: float = float(enemy.get("flight_phase", 0.0))
	match behavior:
		"ring_pursuer":
			var to_player: Vector2 = player["pos"] - enemy["pos"]
			if not to_player.is_zero_approx():
				enemy["pos"] += to_player.normalized() * RING_LEECH_SPEED * 0.92 * delta
			if to_player.length() < PLAYER_RADIUS + float(enemy.get("radius", RING_LEECH_RADIUS)) + 10.0:
				if _apply_player_damage(18.0 * delta, RING_LEECH):
					screen_shake = max(screen_shake, 2.0)
		"array_eye":
			var eye_pos: Vector2 = Vector2(enemy["pos"])
			eye_pos.x += flight_scroll_speed * 0.58 * delta
			eye_pos.y = lerpf(eye_pos.y, ARENA_SIZE.y * 0.5 + sin(life * 1.4 + phase) * 28.0, minf(delta * 1.7, 1.0))
			enemy["pos"] = eye_pos
			enemy["charge_timer"] = maxf(float(enemy.get("charge_timer", 0.0)) - delta, 0.0)
			if _tick_flight_enemy_cooldown(enemy, delta, 1.35):
				enemy["charge_timer"] = MIRROR_NEEDLER_CHARGE_DURATION
				_spawn_flight_aimed_bullet(enemy, MIRROR_NEEDLER_BULLET_SPEED * 1.08, "large", COLORS["bullet"], {
					"family": BULLET_FAMILY_CORE,
					"radius": MIRROR_NEEDLER_BULLET_RADIUS,
					"damage": MIRROR_NEEDLER_BULLET_DAMAGE,
					"source_enemy_type": MIRROR_NEEDLER,
				})
		"caster_lane":
			var caster_pos: Vector2 = Vector2(enemy["pos"])
			caster_pos.y = lerpf(caster_pos.y, float(enemy.get("flight_base_y", caster_pos.y)) + sin(life * 1.8 + phase) * 34.0, minf(delta * 1.5, 1.0))
			enemy["pos"] = caster_pos
			if _tick_flight_enemy_cooldown(enemy, delta, 2.1):
				for spoke in range(6):
					var angle: float = PI + (TAU / 6.0) * float(spoke) + 0.22
					_spawn_bullet(enemy["pos"], Vector2.RIGHT.rotated(angle) * BULLET_SPEED * 0.72, "small", enemy["id"], COLORS["bullet"], {
						"family": BULLET_FAMILY_WEAVE,
						"source_enemy_type": CASTER,
					})
		"heavy_gate":
			var heavy_pos: Vector2 = Vector2(enemy["pos"])
			heavy_pos.x += flight_scroll_speed * 0.36 * delta
			heavy_pos.y = lerpf(heavy_pos.y, float(enemy.get("flight_base_y", heavy_pos.y)) + sin(life * 1.1 + phase) * 18.0, minf(delta, 1.0))
			enemy["pos"] = heavy_pos
			if _tick_flight_enemy_cooldown(enemy, delta, 1.65):
				_spawn_flight_aimed_bullet(enemy, BULLET_LARGE_SPEED * 1.2, "large", COLORS["bullet"], {
					"family": BULLET_FAMILY_CORE,
					"source_enemy_type": HEAVY,
				})
		"fan_cluster":
			var fan_pos: Vector2 = Vector2(enemy["pos"])
			fan_pos.y = lerpf(fan_pos.y, float(enemy.get("flight_base_y", fan_pos.y)) + sin(life * 2.0 + phase) * 22.0, minf(delta * 2.0, 1.0))
			enemy["pos"] = fan_pos
			if _tick_flight_enemy_cooldown(enemy, delta, 1.8):
				_spawn_flight_aimed_bullet(enemy, BULLET_SPEED * 0.85, "small", COLORS["bullet"], {
					"family": BULLET_FAMILY_NEEDLE,
					"source_enemy_type": SHOOTER,
				})
		_:
			var drift_pos: Vector2 = Vector2(enemy["pos"])
			drift_pos.y = lerpf(drift_pos.y, float(enemy.get("flight_base_y", drift_pos.y)) + sin(life * 1.6 + phase) * 18.0, minf(delta * 1.6, 1.0))
			enemy["pos"] = drift_pos
			if _tick_flight_enemy_cooldown(enemy, delta, 2.0):
				_spawn_flight_aimed_bullet(enemy, BULLET_SPEED * 0.8, "small", COLORS["bullet"], {
					"family": BULLET_FAMILY_NEEDLE,
					"source_enemy_type": str(enemy.get("type", SHOOTER)),
				})
	return true


func _tick_flight_enemy_cooldown(enemy: Dictionary, delta: float, reset_time: float) -> bool:
	enemy["shoot_cooldown"] = float(enemy.get("shoot_cooldown", reset_time)) - delta
	if float(enemy.get("shoot_cooldown", 0.0)) > 0.0:
		return false
	enemy["shoot_cooldown"] = reset_time
	return true


func _spawn_flight_aimed_bullet(enemy: Dictionary, speed: float, bullet_type: String, color: Color, extra := {}) -> void:
	var to_player: Vector2 = player["pos"] - enemy["pos"]
	var direction: Vector2 = to_player.normalized()
	if direction.is_zero_approx():
		direction = Vector2.LEFT
	_spawn_bullet(enemy["pos"], direction * speed, bullet_type, enemy["id"], color, extra)


func _remove_bullet(index: int) -> void:
	if index < 0 or index >= bullets.size():
		return
	_clear_attack_instance(str(bullets[index].get("attack_instance_id", "")))
	bullets.remove_at(index)


func _set_game_over() -> void:
	is_game_over = true
	left_mouse_held = false
	right_mouse_held = false
	_set_desktop_mouse_visible(true)
	game_over_label.text = "力竭身亡"
	game_over_label.visible = true


func _get_large_arena_progress_text() -> String:
	if large_arena_completed:
		return "阵心已破"
	var core_state: String = str(large_arena_objective_states.get(LARGE_ARENA_CORE_KEY, LARGE_ARENA_STATE_SEALED))
	if core_state == LARGE_ARENA_STATE_VULNERABLE:
		return "任务：斩阵心"
	return "任务：破阵眼 %d/2" % _get_large_arena_destroyed_eye_count()


func _get_large_arena_goal_text() -> String:
	if large_arena_completed:
		return "目标完成：阵心已破"
	var core_state: String = str(large_arena_objective_states.get(LARGE_ARENA_CORE_KEY, LARGE_ARENA_STATE_SEALED))
	if core_state == LARGE_ARENA_STATE_VULNERABLE:
		return "目标：斩阵心，阵主已现身"
	return "目标：先破上下两个阵眼，再斩阵心"


func _get_large_arena_objective_status_text() -> String:
	var upper_text := _get_large_arena_state_label(LARGE_ARENA_UPPER_EYE_KEY)
	var lower_text := _get_large_arena_state_label(LARGE_ARENA_LOWER_EYE_KEY)
	var core_text := _get_large_arena_state_label(LARGE_ARENA_CORE_KEY)
	var pressure_text := ""
	if large_arena_pressure_label != "":
		pressure_text = " | 压力：%s" % large_arena_pressure_label
	return "%s\n上阵眼 %s | 下阵眼 %s | 阵心 %s%s" % [_get_large_arena_goal_text(), upper_text, lower_text, core_text, pressure_text]


func _get_large_arena_state_label(objective_key: String) -> String:
	var state: String = str(large_arena_objective_states.get(objective_key, LARGE_ARENA_STATE_SEALED))
	match state:
		LARGE_ARENA_STATE_DESTROYED:
			return "已破"
		LARGE_ARENA_STATE_VULNERABLE:
			return "可击破"
		_:
			return "封印"


func _update_ui() -> void:
	_update_array_control_scheme_ui()
	if lookdev_mode:
		health_label.visible = true
		energy_label.visible = true
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
	health_label.visible = true
	energy_label.visible = not _should_hide_sword_array_ui()
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
	elif _is_demo_level_mode():
		var demo_stats: Dictionary = demo_victory_result if demo_victory_visible else demo_level_controller.stats
		wave_label.text = demo_level_controller.get_objective_text() if _is_demo_level_active() or demo_victory_visible else "破庙夜袭"
		score_label.text = "受伤 %.0f | 弹反 %d | 御剑击杀 %d | 切丝 %d | 恢复 %d" % [
			float(demo_stats.get("damage_taken", 0.0)),
			int(demo_stats.get("deflects", 0)),
			int(demo_stats.get("flying_sword_kills", 0)),
			int(demo_stats.get("silks_cut", 0)),
			int(demo_stats.get("pickups", 0))
		]
	elif _is_flight_prototype_mode():
		var event_count: int = _get_flight_scripted_events().size()
		var array_mode_name: String = _get_array_mode_display_name(String(_get_sword_array_fire_state().get("dominant_mode", SwordArrayConfig.MODE_RING)))
		var complete_text: String = " | 完成" if flight_stage_complete else ""
		var flight_mode_name: String = "风压回中" if _is_flight_anchored_prototype_mode() else "自由"
		var flight_body_speed: float = Vector2(player.get("vel", Vector2.ZERO)).length()
		var afterburner_text: String = " | 后燃" if _is_flight_afterburner_pressed() else ""
		var roll_text: String = " | 翻滚" if flight_roll_timer > 0.0 else ""
		wave_label.text = "御剑航行 %s | 段落 %d / %d %s%s" % [
			flight_mode_name,
			flight_segment_index,
			event_count,
			flight_segment_label,
			complete_text
		]
		score_label.text = "航速 %.0f | 机速 %.0f%s%s | 航程 %.1f | %s | 飞剑 %d / %d%s" % [
			flight_scroll_speed,
			flight_body_speed,
			afterburner_text,
			roll_text,
			flight_scroll_distance / 100.0,
			array_mode_name,
			_get_ready_array_sword_count(),
			_get_current_array_sword_capacity(),
			_get_debug_status_suffix()
		]
	else:
		if _is_large_arena_test_enabled():
			wave_label.text = _get_large_arena_progress_text()
			score_label.text = "%s\n飞剑 %d / %d%s" % [
				_get_large_arena_objective_status_text(),
				_get_ready_array_sword_count(),
				_get_current_array_sword_capacity(),
				_get_debug_status_suffix()
			]
		else:
			wave_label.text = "波次 %d%s" % [wave, " | 战斗调试" if debug_battle_mode else ""]
			score_label.text = "得分 %d | 飞剑 %d / %d%s\n普攻 F：%s\n动作：%s" % [
				score,
				_get_ready_array_sword_count(),
				_get_current_array_sword_capacity(),
				_get_debug_status_suffix(),
				_get_current_melee_test_profile_hud_text(),
				_get_current_melee_action_hud_text()
			]
			if debug_battle_mode:
				score_label.text = "%s\n%s" % [score_label.text, _format_sword_spirit_intent_debug()]
	var sword_mode_text: String = "剑阵" if bool(player.get("array_is_firing", false)) else ("近战" if sword["state"] == SwordState.ORBITING else "御剑")
	var bullet_time_text: String = " | 子弹时间" if sword["state"] != SwordState.ORBITING else ""
	var debug_mode_text: String = " | DEBUG" if debug_battle_mode else ""
	mode_label.text = "%s%s%s" % [sword_mode_text, bullet_time_text, debug_mode_text]
	energy_label.modulate = Color.WHITE
	var momentum_heat: float = _get_sword_momentum_heat_strength()
	if momentum_heat > 0.01:
		var heat_pulse: float = 0.42 + 0.58 * absf(sin(elapsed_time * 10.0))
		var heat_color: Color = COLORS["energy"].lerp(Color("ff6a2a"), 0.44 + 0.28 * heat_pulse)
		energy_label.modulate = energy_label.modulate.lerp(heat_color, 0.18 + 0.62 * momentum_heat)
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
	if score_feedback_timer > 0.0:
		var score_feedback_strength: float = clampf(score_feedback_timer / SCORE_LOOT_FEEDBACK_DURATION, 0.0, 1.0)
		score_label.modulate = score_label.modulate.lerp(
			score_feedback_color,
			(0.5 + 0.34 * absf(sin(elapsed_time * 18.0))) * score_feedback_strength
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
		hint_label.text = "战斗调试 | 1 无限生命 | 2 无限剑意 | 3 一击击杀 | 4 停刷怪 | 5 清敌弹 | %s | F7 退出 | F6 校准" % _get_sword_hover_preset_shortcut_hint()
	else:
		hint_label.text = _get_progression_hint_text()
	if _is_demo_level_mode():
		game_over_label.text = "夜色吞身\n破庙夜袭未竟\n左键重新开始"
	elif _is_flight_prototype_mode():
		game_over_label.text = "坠出航道\n御剑航行测试中断\n左键重新开始"
	else:
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
	return _get_array_batch_mode()


func _get_sword_array_direction(fire_index: int, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	return SwordArrayController.get_fire_direction(self , _get_sword_array_fire_state(), fire_index, volley_count, burst_step, total_count)


func _get_sword_array_target(fire_index: int, bullet_pos: Vector2, volley_count := -1, burst_step := 0, total_count := -1) -> Vector2:
	return SwordArrayController.get_fire_target(self , _get_sword_array_fire_state(), fire_index, bullet_pos, volley_count, burst_step, total_count)


func _update_boss(delta: float, bullet_time_delta: float) -> void:
	if _is_demo_level_active():
		demo_level_controller.update_boss(self, delta, bullet_time_delta)
		return
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


func _get_boss_spawn_position() -> Vector2:
	if _is_large_arena_test_enabled():
		return LARGE_ARENA_BOSS_SPAWN_POS
	return Vector2(ARENA_SIZE.x * 0.5, -150.0)


func _get_boss_anchor_position() -> Vector2:
	if _is_large_arena_test_enabled():
		return LARGE_ARENA_BOSS_ANCHOR_POS
	return Vector2(ARENA_SIZE.x * 0.5, 150.0)


func _get_boss_top_position() -> Vector2:
	if _is_large_arena_test_enabled():
		return LARGE_ARENA_BOSS_ANCHOR_POS
	return Vector2(ARENA_SIZE.x * 0.5, 100.0)


func _get_boss_center_position() -> Vector2:
	if _is_large_arena_test_enabled():
		return LARGE_ARENA_BOSS_CENTER_POS
	return ARENA_SIZE * 0.5


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
	if _is_large_arena_test_enabled():
		var screen_rect := _get_large_arena_screen_rect()
		return screen_rect.position + screen_rect.size * 0.5 + (world_pos - large_arena_camera_center) * large_arena_camera_zoom
	return ARENA_ORIGIN + world_pos


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	if _is_large_arena_test_enabled():
		var screen_rect := _get_large_arena_screen_rect()
		var world_pos: Vector2 = large_arena_camera_center + (screen_pos - screen_rect.position - screen_rect.size * 0.5) / maxf(large_arena_camera_zoom, 0.001)
		return world_pos.clamp(Vector2.ZERO, _get_arena_size())
	return (screen_pos - ARENA_ORIGIN).clamp(Vector2.ZERO, ARENA_SIZE)


func _update_mouse_world_from_motion(event: InputEventMouseMotion) -> void:
	if _should_use_virtual_mouse_motion():
		var relative_world: Vector2 = event.relative / (maxf(large_arena_camera_zoom, 0.001) if _is_large_arena_test_enabled() else 1.0)
		mouse_world = (mouse_world + relative_world).clamp(Vector2.ZERO, _get_arena_size())
		return
	mouse_world = _screen_to_world(event.position)


func _update_mouse_world_from_button(event: InputEventMouseButton) -> void:
	if _should_use_virtual_mouse_motion():
		return
	mouse_world = _screen_to_world(event.position)


func _should_use_virtual_mouse_motion() -> bool:
	return not lookdev_mode and not is_start_menu_active and not is_game_over


func _roll_spawn_position() -> Vector2:
	var arena_size := _get_arena_size()
	var roll: float = randf()
	if roll < 0.5:
		return Vector2(randf_range(0.0, arena_size.x), -SPAWN_MARGIN)
	if roll < 0.75:
		return Vector2(arena_size.x + SPAWN_MARGIN, randf_range(0.0, arena_size.y))
	return Vector2(-SPAWN_MARGIN, randf_range(0.0, arena_size.y))


func _should_spawn_boss_wave(wave_index: int) -> bool:
	return wave_index > 0 and wave_index % BOSS_WAVE_INTERVAL == 0


func _get_default_wave_enemy_count(wave_index: int) -> int:
	return WAVE_BASE_ENEMIES + wave_index * 2


func _get_wave_enemy_count(wave_index: int) -> int:
	var scripted_queue: Array = _build_scripted_wave_spawn_queue(wave_index)
	if not scripted_queue.is_empty():
		return _get_spawn_queue_cost(scripted_queue)
	return _get_default_wave_enemy_count(wave_index)


func _make_enemy_spawn_entries(enemy_type: String, count: int) -> Array:
	var entries: Array = []
	var entry_index := 0
	while entry_index < count:
		entries.append(_make_enemy_spawn_entry(enemy_type))
		entry_index += 1
	return entries


func _get_spawn_queue_cost(queue: Array) -> int:
	var total_cost := 0
	for entry_variant in queue:
		total_cost += _get_spawn_entry_cost(entry_variant)
	return total_cost


func _append_enemy_spawn_drill(queue: Array, enemy_type: String, offsets: Array, delay_between := 0.08, delay_after := 0.76) -> void:
	var entry_index := 0
	while entry_index < offsets.size():
		var delay: float = delay_after if entry_index == offsets.size() - 1 else delay_between
		queue.append(_make_enemy_spawn_entry_near(enemy_type, Vector2(offsets[entry_index]), delay))
		entry_index += 1


func _build_scripted_wave_spawn_queue(wave_index: int) -> Array:
	var queue: Array = []
	if wave_index > FIRST_CHAPTER_SCRIPTED_WAVE_MAX:
		return queue
	match wave_index:
		1:
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-82.0, -172.0),
				Vector2(0.0, -186.0),
				Vector2(82.0, -172.0),
			], 0.08, 0.72)
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-98.0, -136.0),
				Vector2(98.0, -136.0),
				Vector2(0.0, -158.0),
			], 0.10, 0.82)
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-150.0, -116.0),
				Vector2(150.0, -116.0),
				Vector2(-54.0, -172.0),
				Vector2(54.0, -172.0),
			], 0.10, 0.88)
		2:
			_append_enemy_spawn_drill(queue, HEAVY, [
				Vector2(0.0, -260.0),
				Vector2(-116.0, -250.0),
			], 0.16, 0.88)
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-94.0, -176.0),
				Vector2(94.0, -176.0),
				Vector2(0.0, -206.0),
			], 0.10, 0.76)
			_append_enemy_spawn_drill(queue, HEAVY, [
				Vector2(118.0, -264.0),
				Vector2(-24.0, -292.0),
			], 0.18, 0.86)
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-150.0, -156.0),
				Vector2(0.0, -178.0),
				Vector2(150.0, -156.0),
			], 0.10, 0.72)
		3:
			queue.append(_make_enemy_spawn_entry_near(TANK, Vector2(0.0, -128.0), 0.58))
			queue.append(_make_ring_leech_package_entry(RING_LEECH_PACKAGE_MIN_COUNT, 1.08))
			_append_enemy_spawn_drill(queue, TANK, [
				Vector2(-82.0, -134.0),
				Vector2(82.0, -134.0),
			], 0.18, 0.82)
			queue.append(_make_ring_leech_package_entry(RING_LEECH_PACKAGE_MIN_COUNT, 0.92))
		4:
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-220.0, -130.0),
				Vector2(-112.0, -186.0),
				Vector2(0.0, -210.0),
				Vector2(112.0, -186.0),
				Vector2(220.0, -130.0),
			], 0.06, 0.78)
			queue.append(_make_enemy_spawn_entry_near(CASTER, Vector2(0.0, -252.0), 0.68))
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-246.0, -168.0),
				Vector2(-124.0, -220.0),
				Vector2(0.0, -236.0),
				Vector2(124.0, -220.0),
				Vector2(246.0, -168.0),
			], 0.06, 0.78)
			queue.append(_make_enemy_spawn_entry_near(CASTER, Vector2(0.0, -286.0), 0.72))
		5:
			_append_enemy_spawn_drill(queue, MIRROR_NEEDLER, [
				Vector2(0.0, -312.0),
				Vector2(0.0, -250.0),
			], 0.12, 0.78)
			_append_enemy_spawn_drill(queue, HEAVY, [
				Vector2(-76.0, -268.0),
				Vector2(-38.0, -210.0),
				Vector2(0.0, -152.0),
			], 0.12, 0.82)
			_append_enemy_spawn_drill(queue, HEAVY, [
				Vector2(108.0, -286.0),
				Vector2(78.0, -226.0),
				Vector2(48.0, -166.0),
			], 0.12, 0.82)
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-132.0, -176.0),
				Vector2(132.0, -176.0),
			], 0.10, 0.72)
		6:
			_append_enemy_spawn_drill(queue, TANK, [
				Vector2(0.0, -132.0),
				Vector2(-96.0, -142.0),
			], 0.16, 0.74)
			queue.append(_make_enemy_spawn_entry_near(DRAPE_PRIEST, Vector2(0.0, -272.0), 0.68))
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-136.0, -178.0),
				Vector2(136.0, -178.0),
				Vector2(0.0, -198.0),
			], 0.10, 0.72)
			queue.append(_make_enemy_spawn_entry_near(DRAPE_PRIEST, Vector2(112.0, -276.0), 0.62))
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-192.0, -154.0),
				Vector2(192.0, -154.0),
				Vector2(76.0, -206.0),
			], 0.10, 0.66)
		7:
			_append_enemy_spawn_drill(queue, TANK, [
				Vector2(-64.0, -118.0),
				Vector2(64.0, -118.0),
				Vector2(0.0, -138.0),
			], 0.12, 0.74)
			queue.append(_make_enemy_spawn_entry_near(CASTER, Vector2(0.0, -240.0), 0.34))
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-178.0, -174.0),
				Vector2(178.0, -174.0),
				Vector2(-92.0, -216.0),
				Vector2(92.0, -216.0),
			], 0.08, 0.74)
			queue.append(_make_enemy_spawn_entry_near(CASTER, Vector2(146.0, -252.0), 0.44))
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(-220.0, -146.0),
				Vector2(0.0, -198.0),
				Vector2(220.0, -146.0),
			], 0.08, 0.66)
		8:
			_append_enemy_spawn_drill(queue, MIRROR_NEEDLER, [
				Vector2(0.0, -286.0),
				Vector2(126.0, -304.0),
			], 0.14, 0.54)
			queue.append(_make_enemy_spawn_entry_near(DRAPE_PRIEST, Vector2(-96.0, -238.0), 0.16))
			_append_enemy_spawn_drill(queue, TANK, [
				Vector2(-28.0, -148.0),
				Vector2(-110.0, -154.0),
			], 0.14, 0.66)
			queue.append(_make_enemy_spawn_entry_near(CASTER, Vector2(126.0, -214.0), 0.22))
			queue.append(_make_enemy_spawn_entry_near(DRAPE_PRIEST, Vector2(88.0, -254.0), 0.28))
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(198.0, -150.0),
				Vector2(-202.0, -158.0),
				Vector2(34.0, -198.0),
				Vector2(248.0, -190.0),
			], 0.08, 0.68)
		9:
			queue.append(_make_ring_leech_package_entry(RING_LEECH_PACKAGE_MAX_COUNT, 0.86))
			queue.append(_make_enemy_spawn_entry_near(DRAPE_PRIEST, Vector2(-138.0, -240.0), 0.16))
			_append_enemy_spawn_drill(queue, TANK, [
				Vector2(-56.0, -134.0),
				Vector2(78.0, -138.0),
			], 0.14, 0.54)
			_append_enemy_spawn_drill(queue, MIRROR_NEEDLER, [
				Vector2(92.0, -284.0),
				Vector2(-116.0, -304.0),
			], 0.16, 0.42)
			queue.append(_make_enemy_spawn_entry_near(CASTER, Vector2(190.0, -198.0), 0.24))
			queue.append(_make_enemy_spawn_entry_near(DRAPE_PRIEST, Vector2(16.0, -264.0), 0.18))
			_append_enemy_spawn_drill(queue, SHOOTER, [
				Vector2(0.0, -184.0),
				Vector2(-210.0, -152.0),
				Vector2(210.0, -152.0),
				Vector2(132.0, -214.0),
			], 0.08, 0.58)
	return queue


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


func _make_enemy_spawn_entry(enemy_type: String, extra := {}) -> Dictionary:
	var entry := {
		"kind": SPAWN_ENTRY_ENEMY,
		"enemy_type": enemy_type,
		"cost": 1,
	}
	for key_variant in extra.keys():
		entry[key_variant] = extra[key_variant]
	return entry


func _make_enemy_spawn_entry_near(enemy_type: String, offset: Vector2, delay_after := -1.0) -> Dictionary:
	var extra := {
		"spawn_offset": offset,
	}
	if delay_after >= 0.0:
		extra["delay_after"] = delay_after
	return _make_enemy_spawn_entry(enemy_type, extra)


func _make_package_spawn_entry(package_type: String, cost: int, extra := {}) -> Dictionary:
	var entry := {
		"kind": SPAWN_ENTRY_PACKAGE,
		"package_type": package_type,
		"cost": max(cost, 1),
	}
	for key_variant in extra.keys():
		entry[key_variant] = extra[key_variant]
	return entry


func _make_ring_leech_package_entry(member_count := RING_LEECH_PACKAGE_DEFAULT_COUNT, delay_after := -1.0) -> Dictionary:
	var resolved_count: int = clampi(member_count, RING_LEECH_PACKAGE_MIN_COUNT, RING_LEECH_PACKAGE_MAX_COUNT)
	var extra := {
		"member_count": resolved_count,
	}
	if delay_after >= 0.0:
		extra["delay_after"] = delay_after
	return _make_package_spawn_entry(
		ENEMY_PACKAGE_RING_LEECH_CLOSE,
		resolved_count,
		extra
	)


func _get_spawn_entry_cost(entry_variant: Variant) -> int:
	if typeof(entry_variant) == TYPE_DICTIONARY:
		return max(int((entry_variant as Dictionary).get("cost", 1)), 1)
	return 1


func _get_spawn_entry_delay(entry_variant: Variant, spawned_count: int) -> float:
	if typeof(entry_variant) == TYPE_DICTIONARY:
		var entry: Dictionary = entry_variant
		if entry.has("delay_after"):
			return maxf(float(entry.get("delay_after", SPAWN_INTERVAL)), 0.0)
	return SPAWN_INTERVAL * (1.0 + 0.12 * float(spawned_count - 1))


func _resolve_spawn_entry_position(entry: Dictionary) -> Variant:
	if entry.has("spawn_pos") and typeof(entry.get("spawn_pos")) == TYPE_VECTOR2:
		return entry.get("spawn_pos")
	if entry.has("spawn_offset") and typeof(entry.get("spawn_offset")) == TYPE_VECTOR2:
		var anchor: Vector2 = Vector2(player.get("pos", ARENA_SIZE * 0.5))
		return anchor + Vector2(entry.get("spawn_offset"))
	return null


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
	_spawn_enemy(str(entry.get("enemy_type", SHOOTER)), _resolve_spawn_entry_position(entry))
	return 1


func _prepare_wave_spawn_queue() -> void:
	var scripted_queue: Array = _build_scripted_wave_spawn_queue(wave)
	if not scripted_queue.is_empty():
		wave_spawn_queue = scripted_queue
		enemies_to_spawn = _get_spawn_queue_cost(wave_spawn_queue)
		return
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
	var arena_size := _get_arena_size()
	return position.x >= -SPAWN_MARGIN and position.x <= arena_size.x + SPAWN_MARGIN and position.y >= -SPAWN_MARGIN and position.y <= arena_size.y + SPAWN_MARGIN


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
	return _has_boss() and bool(boss.get("is_vulnerable", false))


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
		AttackProfiles.PROFILE_FLYING_SWORD_PIERCE_COMBO:
			reaction_distance = 10.5
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
	if damage_source == DAMAGE_SOURCE_FLYING_SWORD_CLONE:
		reaction_distance *= 0.72
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
	if _is_demo_level_active():
		demo_level_controller.on_attack_result(self, damage_source, result["apply_result"])
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
	if event.keycode == KEY_F:
		_cycle_melee_test_profile(1)
		return true
	if _matches_configured_key(event, sword_hover_preset_next_key):
		_cycle_sword_hover_preset(1)
		return true
	if _matches_configured_key(event, sword_hover_preset_previous_key):
		_cycle_sword_hover_preset(-1)
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
	if _is_flight_prototype_mode() and flight_roll_timer > 0.0:
		return false
	if _has_debug_flag("infinite_health"):
		player["health"] = PLAYER_MAX_HEALTH
		return false
	player["health"] = max(player["health"] - amount, 0.0)
	if _is_demo_level_active():
		demo_level_controller.on_player_damage(self, amount)
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
	score_loot_pickups.clear()
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
