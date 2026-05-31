extends Node2D

const HUMANOID_8WAY_SKELETON_VISUAL := preload("res://scripts/prototypes/humanoid_8way_skeleton_visual.gd")
const WIND_RIBBON_EFFECT_SCRIPT := preload("res://third_party/ffttasd/wind_ribbon/scripts/wind_ribbon_effect.gd")
const FOG_CARD_3D_SCRIPT := preload("res://third_party/ffttasd/godot_fog_card/scripts/fog_card_3d.gd")
const FOG_CARD_SHADER := preload("res://third_party/ffttasd/godot_fog_card/reference_fog/shaders/fog-card.gdshader")
const CLOUDSEA_FAR_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/cloudsea_far_band_01.png"
const CLOUDSEA_MID_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/cloudsea_mid_band_01.png"
const MOUNTAIN_FAR_INK_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/mountain_far_ink_01.png"
const MOUNTAIN_MID_INK_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/mountain_mid_ink_01.png"
const SEA_HORIZON_WASH_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/sea_horizon_wash_01.png"
const FAR_ISLAND_CHAIN_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/far_island_chain_01.png"
const SEA_MIST_FOOT_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/sea_mist_foot_01.png"
const SEA_SHIMMER_LINES_ATLAS_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/sea_shimmer_lines_atlas_01.png"
const BOUNDARY_CLOUD_WALL_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/boundary_cloud_wall_01.png"
const BOUNDARY_RUNE_STRIP_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/boundary_rune_strip_01.png"
const NEAR_CLOUD_WISPS_ATLAS_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/near_cloud_wisps_atlas_01.png"
const LANDMARK_SILHOUETTES_ATLAS_TEXTURE_PATH := "res://resources/flight/background/yujian_cloudsea_v1/landmark_silhouettes_atlas_01.png"

const VIEW_SIZE := Vector2(1280.0, 720.0)
const BASE_PLAY_ORIGIN := Vector2(92.0, 86.0)
const BASE_PLAY_SIZE := Vector2(1096.0, 548.0)
const BATTLEFIELD_SIZE_MULTIPLIER := 8.0
const FLIGHT_SPEED_MULTIPLIER := 3.0
const FLIGHT_TEST_HORIZONTAL_SCALE := 10.0 * BATTLEFIELD_SIZE_MULTIPLIER
const FLIGHT_TEST_VERTICAL_SCALE := 6.0 * BATTLEFIELD_SIZE_MULTIPLIER
const PLAY_SIZE := Vector2(BASE_PLAY_SIZE.x * FLIGHT_TEST_HORIZONTAL_SCALE, BASE_PLAY_SIZE.y * FLIGHT_TEST_VERTICAL_SCALE)
const PLAY_RECT := Rect2(BASE_PLAY_ORIGIN, PLAY_SIZE)
const FLIGHT_START_POS := BASE_PLAY_ORIGIN + Vector2(PLAY_SIZE.x * 0.16, PLAY_SIZE.y * 0.52)
const CAMERA_LOOK_AHEAD_TIME := 0.10
const CAMERA_MAX_LOOK_AHEAD := Vector2(360.0, 110.0)
const CAMERA_LOOK_AHEAD_HALF_LIFE := 0.075
const CAMERA_HARD_TURN_LOOK_AHEAD_SCALE := 0.58
const WORLD_GRID_STEP := 360.0
const CYAN := Color(0.42, 0.96, 1.0, 1.0)
const SCENE_FAR_MOUNTAIN_PARALLAX := 0.075
const SCENE_MID_MOUNTAIN_PARALLAX := 0.18
const SCENE_FAR_FOG_PARALLAX := 0.10
const SCENE_MID_FOG_PARALLAX := 0.28
const SCENE_NEAR_FOG_PARALLAX := 0.72
const SCENE_FAR_MOUNTAIN_TILE := 760.0
const SCENE_MID_MOUNTAIN_TILE := 620.0
const SCENE_WIND_MIN_SPEED := 0.68
const SCENE_BACKGROUND_SPEED_MIN := 0.36
const SCENE_BACKGROUND_BOUNDARY_SCREEN_RANGE := 260.0
const SCENE_BACKGROUND_BOUNDARY_ALPHA := 0.30
const SCENE_BACKGROUND_RUNE_ALPHA := 0.18
const REFERENCE_VFX_VIEWPORT_SIZE := Vector2i(1280, 720)
const REFERENCE_FOG_CARD_COUNT := 14
const REFERENCE_WIND_SEGMENT_COUNT := 6
const REFERENCE_WIND_TURN_SUPPRESS_PRESSURE := 0.18
const REFERENCE_WIND_STABLE_ANGLE := 0.10
const REFERENCE_WIND_HEADING_SETTLE_ANGLE := 0.08
const REFERENCE_WIND_VELOCITY_ALIGN_ANGLE := 0.18
const REFERENCE_WIND_HEADING_RATE_LIMIT := 0.75
const REFERENCE_WIND_REAPPEAR_STABLE_TIME := 0.18
const REFERENCE_WIND_STRAND_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const REFERENCE_WIND_VEIL_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const REFERENCE_WIND_STRAND_OPACITY := 0.20
const REFERENCE_WIND_VEIL_OPACITY := 0.016
const REFERENCE_WIND_START_PREPROCESS := 0.04
const REFERENCE_WIND_ACTIVE_HALF_LIFE := 0.18
const REFERENCE_WIND_RELEASE_HALF_LIFE := 0.055
const REFERENCE_WIND_RELEASE_HIDE_THRESHOLD := 0.08
const REFERENCE_WIND_RELEASE_MIN_SCALE := 0.28
const REFERENCE_WIND_STRAND_TRAIL_LIFETIME := 0.42
const REFERENCE_WIND_VEIL_TRAIL_LIFETIME := 0.48
const SCENE_SPEED_STREAK_MAX_COUNT := 34
const SCENE_SPEED_STREAK_MIN_ENERGY := 0.12
const SCENE_SPEED_STREAK_SPAWN_RATE := 36.0
const SCENE_SPEED_STREAK_LIFE := 0.38
const SCENE_SPEED_STREAK_MIN_LENGTH := 82.0
const SCENE_SPEED_STREAK_MAX_LENGTH := 220.0

const FRAME_COLUMNS := 7
const CELL_SIZE := Vector2(512.0, 512.0)
const SPRITE_SCALE := 0.235
const SHEET_FACE_SIGN := 1.0
const POSE_OFFSET := Vector2(-10.0, -6.0)
const USE_GEMINI_8WAY_CRUISE := true
const EIGHT_WAY_SET_V1 := -1
const EIGHT_WAY_SET_V2 := -2
const EIGHT_WAY_SET_V3_FACE := -3
const EIGHT_WAY_SET_V4_SKELETON := 0
const EIGHT_WAY_SET_V5_INK_PARTS := -4
const EIGHT_WAY_SET_V6_GOOGLE_PARTS := -5
const EIGHT_WAY_SET_V7_GOOGLE_PARTS_V2 := -6
const GEMINI_EIGHT_WAY_SCALE := 0.17
const INK_PART_EIGHT_WAY_SCALE := 1.22
const GOOGLE_PARTS_EIGHT_WAY_SCALE := 1.12
const GEMINI_POSE_OFFSET := Vector2(0.0, -18.0)
const SKELETON_EIGHT_WAY_SCALE := 1.16
const SKELETON_POSE_OFFSET := Vector2(0.0, -6.0)
const VISUAL_HEADING_TURN_RATE := 8.8
const VISUAL_HEADING_HARD_TURN_RATE := 12.0
const VISUAL_HEADING_HOVER_TURN_RATE := 13.5
const EIGHT_WAY_SWITCH_HYSTERESIS := 0.14
const EIGHT_WAY_LOCAL_ROTATION_LIMIT := 0.66
const V3_TWO_WAY_LOCAL_ROTATION_LIMIT := PI * 0.5
const V3_TWO_WAY_VERTICAL_X_THRESHOLD := 0.32
const V3_TWO_WAY_VERTICAL_Y_THRESHOLD := 0.58
const EIGHT_WAY_ADJUSTMENT_HALF_LIFE := 0.045
const EIGHT_WAY_SWITCH_GHOST_LIFE := 0.12
const DIRECTION_SWITCH_FX_LIFE := 0.24
const DIRECTION_SWITCH_FX_HARD_LIFE := 0.34
const DIRECTION_SWITCH_ENERGY_HALF_LIFE := 0.075
const DIRECTION_SWITCH_ARC_RADIUS := 92.0
const DIRECTION_SWITCH_ARC_HARD_RADIUS := 150.0
const DIRECTION_SWITCH_MAX_ARCS := 8
const CONTROL_MODE_DIRECT_INTENT := 0
const CONTROL_MODE_STEER_THROTTLE := 1
const GEMINI_EIGHT_WAY_SET_LABELS := [
	"V4 skeleton rig",
]
const GEMINI_EIGHT_WAY_BASE_PATHS := [
	"res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v4_skeleton",
]
const EIGHT_WAY_RUNTIME_ADJUSTMENTS_PATH := "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_runtime_adjustments.json"
const GEMINI_EIGHT_WAY_NAMES := [
	"01_right",
	"03_up",
	"05_left",
	"07_down",
]
const GEMINI_EIGHT_WAY_VECTORS := [
	Vector2(1.0, 0.0),
	Vector2(0.0, -1.0),
	Vector2(-1.0, 0.0),
	Vector2(0.0, 1.0),
]
const SKELETON_CARDINAL_DIRECTION_INDICES := [0, 2, 4, 6]
const BACKGROUND_ISLAND_GROUPS := [
	{"x": -12600.0, "depth": 0.34, "scale": 0.56, "sea_offset": -22.0, "alpha": 0.68, "landmark": 0, "landmark_scale": 0.42, "mountain": "far"},
	{"x": -9000.0, "depth": 0.42, "scale": 0.72, "sea_offset": 8.0, "alpha": 0.86, "landmark": 3, "landmark_scale": 0.48, "mirror": true},
	{"x": -5200.0, "depth": 0.52, "scale": 0.84, "sea_offset": 34.0, "alpha": 0.94, "landmark": 4, "landmark_scale": 0.58},
	{"x": -1200.0, "depth": 0.38, "scale": 0.64, "sea_offset": -8.0, "alpha": 0.76, "landmark": 1, "landmark_scale": 0.44, "mountain": "far", "mirror": true},
	{"x": 2900.0, "depth": 0.50, "scale": 0.82, "sea_offset": 24.0, "alpha": 0.92, "landmark": 5, "landmark_scale": 0.54},
	{"x": 7200.0, "depth": 0.44, "scale": 0.70, "sea_offset": 2.0, "alpha": 0.82, "landmark": 2, "landmark_scale": 0.46, "mirror": true},
	{"x": 11800.0, "depth": 0.56, "scale": 0.92, "sea_offset": 44.0, "alpha": 0.98, "landmark": 0, "landmark_scale": 0.60},
	{"x": 16600.0, "depth": 0.40, "scale": 0.66, "sea_offset": -12.0, "alpha": 0.78, "landmark": 4, "landmark_scale": 0.44, "mountain": "far"},
	{"x": 21300.0, "depth": 0.53, "scale": 0.86, "sea_offset": 28.0, "alpha": 0.95, "landmark": 3, "landmark_scale": 0.56, "mirror": true},
	{"x": 26200.0, "depth": 0.46, "scale": 0.74, "sea_offset": 10.0, "alpha": 0.86, "landmark": 1, "landmark_scale": 0.48},
	{"x": 31300.0, "depth": 0.58, "scale": 0.94, "sea_offset": 48.0, "alpha": 1.0, "landmark": 5, "landmark_scale": 0.62, "mirror": true},
	{"x": 36500.0, "depth": 0.39, "scale": 0.62, "sea_offset": -18.0, "alpha": 0.74, "landmark": 2, "landmark_scale": 0.42, "mountain": "far"},
	{"x": 41700.0, "depth": 0.51, "scale": 0.84, "sea_offset": 30.0, "alpha": 0.94, "landmark": 4, "landmark_scale": 0.56},
	{"x": 46900.0, "depth": 0.45, "scale": 0.72, "sea_offset": 4.0, "alpha": 0.84, "landmark": 0, "landmark_scale": 0.48, "mirror": true},
	{"x": 52100.0, "depth": 0.57, "scale": 0.92, "sea_offset": 42.0, "alpha": 0.98, "landmark": 3, "landmark_scale": 0.60},
	{"x": 57300.0, "depth": 0.41, "scale": 0.68, "sea_offset": -4.0, "alpha": 0.80, "landmark": 1, "landmark_scale": 0.46, "mountain": "far", "mirror": true},
	{"x": 62500.0, "depth": 0.52, "scale": 0.86, "sea_offset": 26.0, "alpha": 0.94, "landmark": 5, "landmark_scale": 0.56},
	{"x": 67800.0, "depth": 0.47, "scale": 0.76, "sea_offset": 12.0, "alpha": 0.86, "landmark": 2, "landmark_scale": 0.50, "mirror": true},
	{"x": 73100.0, "depth": 0.55, "scale": 0.90, "sea_offset": 38.0, "alpha": 0.96, "landmark": 4, "landmark_scale": 0.58},
]

@export_enum("V4 skeleton rig") var eight_way_character_set := EIGHT_WAY_SET_V4_SKELETON
@export_enum("Direct intent", "Steer throttle") var control_mode := CONTROL_MODE_DIRECT_INTENT
@export_range(0.25, 1.25, 0.01) var skeleton_size_scale := 0.3

@export_category("大战场背景")
@export_group("整体响应")
@export_range(0.10, 1.0, 0.01) var 急转背景保留比例 := 0.72
@export_range(0.10, 1.0, 0.01) var 海岛高速保留比例 := 0.70
@export_range(0.10, 1.0, 0.01) var 海面高速保留比例 := 0.82
@export_range(0.10, 1.0, 0.01) var 水纹高速保留比例 := 0.30
@export_range(0.0, 1.0, 0.005) var 岛群整体透明度 := 0.88
@export_range(0.20, 1.40, 0.01) var 岛群世界移动倍率 := 1.0
@export_range(-120.0, 160.0, 1.0) var 岛群贴海偏移 := 12.0

@export_group("天空")
@export var 天空顶部颜色 := Color(0.68, 0.78, 0.84, 1.0)
@export var 天空中部颜色 := Color(0.84, 0.91, 0.92, 1.0)
@export var 天空底部颜色 := Color(0.96, 0.98, 0.95, 1.0)
@export_range(0.0, 0.30, 0.005) var 天空中部雾光强度 := 0.08
@export_range(0.0, 0.30, 0.005) var 天空低处青雾强度 := 0.025

@export_group("海平面")
@export_range(0.35, 0.72, 0.001) var 海平线高度比例 := 0.515
@export var 海面基础颜色 := Color(0.01, 0.28, 0.78, 1.0)
@export_range(0.0, 0.90, 0.005) var 海面基础透明度 := 0.72
@export var 海平线柔光颜色 := Color(0.36, 0.76, 1.0, 1.0)
@export_range(0.0, 0.30, 0.005) var 海平线柔光强度 := 0.10
@export_range(8.0, 180.0, 1.0) var 海平线柔光宽度 := 56.0
@export_range(0.40, 0.78, 0.001) var 海面水洗高度比例 := 0.58
@export_range(0.0, 1.0, 0.005) var 海面水洗透明度 := 0.28
@export var 海面水洗染色 := Color(0.12, 0.58, 1.0, 1.0)

@export_group("山与岛屿")
@export_range(0.0, 1.0, 0.005) var 远山透明度 := 0.10
@export_range(0.0, 1.0, 0.005) var 中景山透明度 := 0.12
@export_range(0.35, 0.72, 0.001) var 远岛高度比例 := 0.525
@export_range(0.0, 1.0, 0.005) var 远岛透明度 := 0.46
@export var 远岛染色 := Color(0.55, 0.69, 0.67, 1.0)
@export_range(0.35, 0.76, 0.001) var 山脚海雾高度比例 := 0.55
@export_range(0.0, 1.0, 0.005) var 山脚海雾透明度 := 0.055
@export_range(0.0, 1.0, 0.005) var 岛群山体透明度 := 0.34
@export_range(0.0, 1.0, 0.005) var 岛群山脚雾透明度 := 0.18
@export_range(0.0, 1.0, 0.005) var 地标建筑透明度 := 0.26

@export_group("云海与水纹")
@export_range(0.40, 0.82, 0.001) var 远云高度比例 := 0.61
@export_range(0.0, 1.0, 0.005) var 远云透明度 := 0.13
@export_range(0.48, 0.90, 0.001) var 中景云高度比例 := 0.69
@export_range(0.0, 1.0, 0.005) var 中景云透明度 := 0.13
@export_range(0.48, 0.92, 0.001) var 水纹高度比例 := 0.72
@export_range(0.0, 0.50, 0.005) var 水纹透明度 := 0.045

const CRUISE_SPEED := 390.0 * FLIGHT_SPEED_MULTIPLIER
const BOOST_SPEED := 760.0 * FLIGHT_SPEED_MULTIPLIER
const ACCELERATION := 1320.0 * FLIGHT_SPEED_MULTIPLIER
const BOOST_ACCELERATION := 2300.0 * FLIGHT_SPEED_MULTIPLIER
const DIRECT_CRUISE_ACCELERATION := 1850.0 * FLIGHT_SPEED_MULTIPLIER
const DIRECT_BOOST_ACCELERATION := 3000.0 * FLIGHT_SPEED_MULTIPLIER
const DIRECT_BODY_TURN_RATE := 10.6
const DIRECT_HARD_BODY_TURN_RATE := 14.0
const HOVER_BRAKE := 5200.0 * FLIGHT_SPEED_MULTIPLIER
const SLIP_BRAKE := 4200.0 * FLIGHT_SPEED_MULTIPLIER
const SLIP_DURATION := 0.12
const HOVER_STOP_SPEED := 16.0
const INPUT_HEADING_TURN_RATE := 4.8
const HEADING_TURN_RATE := 5.6
const HOVER_HEADING_TURN_RATE := 8.4
const HARD_HEADING_TURN_RATE := 9.0
const HARD_TURN_MIN_ANGLE := 2.06
const HARD_TURN_MIN_SPEED := 420.0 * FLIGHT_SPEED_MULTIPLIER
const CARVE_DURATION := 0.24
const CARVE_SIDE_FORCE := 720.0 * FLIGHT_SPEED_MULTIPLIER
const CARVE_SPEED_KEEP := 0.86
const BOUNDARY_SOFT_MARGIN := 280.0 * FLIGHT_SPEED_MULTIPLIER
const BOUNDARY_HEADING_PULL := 2.2
const BOUNDARY_RETURN_ACCEL := 1550.0 * FLIGHT_SPEED_MULTIPLIER
const CAMERA_MIN_ZOOM := 1.12
const CAMERA_MAX_ZOOM := 1.30
const CAMERA_ZOOM_HALF_LIFE := 0.18
const BOOST_ENTER_SPEED := 520.0 * FLIGHT_SPEED_MULTIPLIER
const BOOST_EXIT_SPEED := 455.0 * FLIGHT_SPEED_MULTIPLIER
const BOOST_IDLE_HARD_TURN_ENTRY_FRAME := 4
const BOOST_BURST_DURATION := 0.11
const BOOST_BURST_EXTRA_DISTANCE := 168.0
const BOOST_SHOCKWAVE_LIFE := 0.30
const BOOST_SHOCKWAVE_FRONT_OFFSET := 132.0
const BOOST_SHOCKWAVE_MAX_COUNT := 5
const BOOST_SHOCKWAVE_FRONT_FOLLOW_POWER := 2.25
const BOOST_SHOCKWAVE_DRIFT_FACTOR := 0.08
const BOOST_SHOCKWAVE_RING_TEXTURE_PATH := "res://resources/vfx/yujian_boost/boost_shockwave_video_ring.png"
const BOOST_SHOCKWAVE_MIST_TEXTURE_PATH := "res://resources/vfx/yujian_boost/boost_shockwave_video_mist.png"
const BOOST_SHOCKWAVE_NEEDLE_TEXTURE_PATH := "res://resources/vfx/yujian_boost/boost_shockwave_video_sketch_lines.png"
const BOOST_SHOCKWAVE_SHARD_TEXTURE_PATH := "res://resources/vfx/yujian_boost/boost_shockwave_video_smear.png"
const BOOST_SHOCKWAVE_PARTICLE_ROOT_PATH := "BoostShockwaveVfxRoot"
const BOOST_SHOCKWAVE_PARTICLE_VISIBILITY_RECT := Rect2(Vector2(-820.0, -520.0), Vector2(1640.0, 1040.0))
const AIRWAKE_PARTICLE_VISIBILITY_RECT := Rect2(Vector2(-620.0, -360.0), Vector2(1240.0, 720.0))

@export_category("加速冲击波")
@export_group("前冲")
@export_range(0.04, 0.30, 0.005) var 前冲时长 := BOOST_BURST_DURATION
@export_range(0.0, 280.0, 1.0) var 前冲距离 := BOOST_BURST_EXTRA_DISTANCE
@export_group("位置")
@export_range(40.0, 260.0, 1.0) var 前置距离 := BOOST_SHOCKWAVE_FRONT_OFFSET
@export_range(0.08, 0.70, 0.01) var 冲击波寿命 := BOOST_SHOCKWAVE_LIFE
@export_range(1, 8, 1) var 最大残留数量 := BOOST_SHOCKWAVE_MAX_COUNT
@export_range(0.2, 4.0, 0.05) var 前方跟随力度 := BOOST_SHOCKWAVE_FRONT_FOLLOW_POWER
@export_range(0.0, 120.0, 1.0) var 向前漂移距离 := 42.0
@export_range(0.0, 0.20, 0.005) var 速度拖拽系数 := BOOST_SHOCKWAVE_DRIFT_FACTOR
@export_group("椭圆环")
@export var 椭圆环颜色 := Color(1.0, 1.0, 0.96, 1.0)
@export_range(0.0, 2.0, 0.01) var 椭圆环透明度 := 1.24
@export_range(0.10, 1.20, 0.01) var 椭圆环起始缩放 := 0.46
@export_range(0.10, 1.60, 0.01) var 椭圆环结束缩放 := 0.72
@export_range(4.0, 80.0, 1.0) var 前后半径起始 := 10.0
@export_range(8.0, 120.0, 1.0) var 前后半径结束 := 36.0
@export_range(20.0, 260.0, 1.0) var 上下半径起始 := 46.0
@export_range(40.0, 360.0, 1.0) var 上下半径结束 := 152.0
@export_range(0.2, 2.0, 0.01) var 整体形状缩放 := 1.0
@export_group("手绘线")
@export var 外圈颜色 := Color(0.96, 0.96, 0.90, 1.0)
@export var 线带颜色 := Color(0.98, 0.98, 0.94, 1.0)
@export var 核心线颜色 := Color(1.0, 1.0, 0.96, 1.0)
@export var 速度线颜色 := Color(0.96, 0.96, 0.90, 1.0)
@export var 暗速度线颜色 := Color(0.86, 0.86, 0.80, 1.0)
@export_range(0.0, 2.5, 0.01) var 线条透明度 := 1.0
@export_range(0.0, 2.5, 0.01) var 速度线透明度 := 1.0
@export_group("粒子")
@export_range(1, 64, 1) var 雾粒子数量 := 14
@export_range(1, 48, 1) var 线稿粒子数量 := 10
@export_range(1, 32, 1) var 拖影粒子数量 := 4
@export_range(0.05, 0.80, 0.01) var 雾粒子寿命 := 0.34
@export_range(0.05, 0.60, 0.01) var 线稿粒子寿命 := 0.20
@export_range(0.05, 0.60, 0.01) var 拖影粒子寿命 := 0.24
@export var 雾粒子颜色 := Color(0.98, 0.98, 0.92, 1.0)
@export var 线稿粒子颜色 := Color(0.98, 0.98, 0.92, 1.0)
@export var 拖影粒子颜色 := Color(0.90, 0.90, 0.84, 1.0)
@export_range(0.0, 2.5, 0.01) var 粒子透明度 := 1.0
@export_range(0.2, 2.0, 0.01) var 粒子速度 := 1.0

@export_category("破空尾流")
@export_group("整体")
@export_range(0.0, 2.0, 0.01) var 破空尾流强度 := 1.30
@export_range(0.45, 1.8, 0.01) var 破空尾流长度 := 1.18

@export_group("可读主线")
@export_range(0.0, 2.0, 0.01) var 主线长度倍率 := 1.0
@export_range(0.0, 2.5, 0.01) var 主线核心透明度 := 1.0
@export_range(0.0, 2.5, 0.01) var 主线光晕透明度 := 1.0
@export_range(0.25, 3.0, 0.01) var 主线核心宽度 := 1.0
@export_range(0.25, 3.0, 0.01) var 主线光晕宽度 := 1.0

@export_group("历史尾迹辅助")
@export_range(0.0, 2.0, 0.01) var 辅助尾迹透明度 := 1.0
@export_range(0.25, 2.5, 0.01) var 辅助尾迹宽度 := 1.0

@export_group("剑轨粒子")
@export_range(0.0, 2.0, 0.01) var 剑轨亮度 := 1.08
@export_range(1, 96, 1) var 剑轨粒子数量 := 30
@export_range(0.06, 0.80, 0.01) var 剑轨粒子寿命 := 0.32
@export_range(0.2, 2.5, 0.01) var 剑轨粒子速度 := 1.0
@export_range(0.0, 2.5, 0.01) var 剑轨粒子透明度 := 1.0

@export_group("云气开缝")
@export_range(0.0, 2.0, 0.01) var 云气开缝强度 := 0.38
@export_range(1, 96, 1) var 云气粒子数量 := 24
@export_range(0.06, 0.80, 0.01) var 云气粒子寿命 := 0.26
@export_range(0.2, 2.5, 0.01) var 云气粒子速度 := 1.0
@export_range(0.0, 2.5, 0.01) var 云气粒子透明度 := 1.0

@export_group("风切针线")
@export_range(0.0, 2.0, 0.01) var 风切粒子强度 := 0.92
@export_range(1, 128, 1) var 风切粒子数量 := 32
@export_range(0.06, 0.80, 0.01) var 风切粒子寿命 := 0.26
@export_range(0.2, 2.5, 0.01) var 风切粒子速度 := 1.0
@export_range(0.0, 2.5, 0.01) var 风切粒子透明度 := 1.0

@export_group("冷凝散点")
@export_range(1, 64, 1) var 冷凝粒子数量 := 10
@export_range(0.06, 0.80, 0.01) var 冷凝粒子寿命 := 0.22
@export_range(0.2, 2.5, 0.01) var 冷凝粒子速度 := 1.0
@export_range(0.0, 2.5, 0.01) var 冷凝粒子透明度 := 1.0

@export_group("压缩尾迹")
@export_range(0.0, 2.0, 0.01) var 压缩尾迹强度 := 0.18
@export_range(1, 48, 1) var 压缩粒子数量 := 5
@export_range(0.06, 0.80, 0.01) var 压缩粒子寿命 := 0.15
@export_range(0.2, 2.5, 0.01) var 压缩粒子速度 := 1.0
@export_range(0.0, 2.5, 0.01) var 压缩粒子透明度 := 1.0

const KEY_MODE_NONE := 0
const KEY_MODE_GREEN := 2

const CLIP_CRUISE_IDLE := 0
const CLIP_CRUISE_TURN := 1
const CLIP_BOOST_ENTER := 2
const CLIP_BOOST_IDLE := 3
const CLIP_BOOST_EXIT := 4
const CLIP_HARD_TURN_CORE := 5
const CLIP_HARD_TURN_TO_BOOST := 6
const CLIP_HARD_TURN_TO_CRUISE := 7
const CLIP_V3_TOP_TURN := 8
const SPEED_MODE_CRUISE := 0
const SPEED_MODE_BOOST := 1

const CLIPS := [
	{
		"name": "cruise_idle",
		"path": "res://resources/flight/generated/yujian_v2_cruise_idle.png",
		"frames": 49,
		"fps": 20.0,
		"loop": true,
		"kind": "cruise",
		"trail_anchor": Vector2(-42.0, 90.0),
		"trail_weight": 0.86,
		"smear_weight": 0.12,
	},
	{
		"name": "cruise_turn",
		"path": "res://resources/flight/generated/yujian_v2_cruise_turn.png",
		"frames": 49,
		"fps": 64.0,
		"loop": false,
		"kind": "cruise_turn",
		"self_turn": true,
		"trail_anchor": Vector2(-54.0, 92.0),
		"trail_weight": 1.05,
		"smear_weight": 0.28,
	},
	{
		"name": "boost_enter",
		"path": "res://resources/flight/generated/yujian_v2_boost_enter.png",
		"frames": 9,
		"fps": 30.0,
		"loop": false,
		"kind": "boost_enter",
		"trail_anchor": Vector2(-62.0, 91.0),
		"trail_weight": 1.35,
		"smear_weight": 0.36,
	},
	{
		"name": "boost_idle",
		"path": "res://resources/flight/generated/yujian_v2_boost_idle.png",
		"frames": 49,
		"fps": 26.0,
		"loop": true,
		"kind": "boost",
		"trail_anchor": Vector2(-68.0, 92.0),
		"trail_weight": 1.5,
		"smear_weight": 0.42,
	},
	{
		"name": "boost_exit",
		"path": "res://resources/flight/generated/yujian_v2_boost_exit.png",
		"frames": 12,
		"fps": 30.0,
		"loop": false,
		"kind": "boost_exit",
		"trail_anchor": Vector2(-56.0, 92.0),
		"trail_weight": 1.12,
		"smear_weight": 0.24,
	},
	{
		"name": "hard_turn_core",
		"path": "res://resources/flight/generated/yujian_v2_hard_turn_core.png",
		"frames": 16,
		"fps": 30.0,
		"loop": false,
		"kind": "hard_turn",
		"self_turn": true,
		"trail_anchor": Vector2(-70.0, 92.0),
		"trail_weight": 1.72,
		"smear_weight": 0.9,
	},
	{
		"name": "hard_turn_to_boost",
		"path": "res://resources/flight/generated/yujian_v2_hard_turn_to_boost.png",
		"frames": 21,
		"fps": 48.0,
		"loop": false,
		"kind": "hard_follow_boost",
		"self_turn": true,
		"trail_anchor": Vector2(-74.0, 92.0),
		"trail_weight": 1.62,
		"smear_weight": 0.62,
	},
	{
		"name": "hard_turn_to_cruise",
		"path": "res://resources/flight/generated/yujian_v2_hard_turn_to_cruise.png",
		"frames": 33,
		"fps": 32.0,
		"loop": false,
		"kind": "hard_follow_cruise",
		"self_turn": true,
		"trail_anchor": Vector2(-64.0, 92.0),
		"trail_weight": 1.28,
		"smear_weight": 0.38,
	},
	{
		"name": "v3_top_turn_1378",
		"path": "res://archive/flight_visual_non_v4_20260530/resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/top_turn_1378_4f_512_strip.png",
		"frames": 6,
		"columns": 4,
		"source_frames": [0, 1, 1, 2, 2, 3],
		"fps": 9.0,
		"loop": false,
		"kind": "v3_top_turn",
		"self_turn": true,
		"trail_anchor": Vector2(-58.0, 92.0),
		"trail_weight": 1.18,
		"smear_weight": 0.42,
	},
]

var sprite_root: Node2D
var character_sprite: Sprite2D
var skeleton_character: Node2D
var ink_part_character: Node2D
var google_part_character: Node2D
var reference_vfx_viewport: SubViewport
var reference_vfx_sprite: Sprite2D
var reference_vfx_camera: Camera3D
var reference_wind_ribbon: Node3D
var reference_wind_emitting := false
var reference_wind_direction := Vector3.LEFT
var reference_wind_rotation := 0.0
var reference_wind_ribbons: Array[Node3D] = []
var reference_wind_segment_energy: Array[float] = []
var reference_wind_segment_rotations: Array[float] = []
var reference_wind_segment_emitting: Array[bool] = []
var reference_wind_current_index := 0
var reference_wind_target_rotation := 0.0
var reference_wind_stable_time := 0.0
var reference_wind_initialized := false
var reference_fog_cards: Array[MeshInstance3D] = []
var key_shader: Shader
var trail_halo: Line2D
var trail_ribbon: Line2D
var trail_core: Line2D
var airwake_root: Node2D
var qi_rail_particles: GPUParticles2D
var cloud_split_particles: GPUParticles2D
var wind_cut_particles: GPUParticles2D
var condensation_particles: GPUParticles2D
var compression_particles: GPUParticles2D
var airwake_halo_line: Line2D
var airwake_core_line: Line2D
var airwake_cloud_lines: Array[Line2D] = []
var airwake_wind_lines: Array[Line2D] = []
var airwake_mote_lines: Array[Line2D] = []
var airwake_compression_line: Line2D
var airwake_particle_layers: Array[GPUParticles2D] = []
var cloudsea_far_texture: Texture2D
var cloudsea_mid_texture: Texture2D
var mountain_far_ink_texture: Texture2D
var mountain_mid_ink_texture: Texture2D
var sea_horizon_wash_texture: Texture2D
var far_island_chain_texture: Texture2D
var sea_mist_foot_texture: Texture2D
var sea_shimmer_lines_atlas_texture: Texture2D
var boundary_cloud_wall_texture: Texture2D
var boundary_rune_strip_texture: Texture2D
var near_cloud_wisps_atlas_texture: Texture2D
var landmark_silhouettes_atlas_texture: Texture2D

var texture_cache: Dictionary = {}
var eight_way_textures: Array = []
var eight_way_index := 0
var sheet_texture: Texture2D
var clip_index := CLIP_CRUISE_IDLE
var frame_index := 0
var frame_timer := 0.0
var render_sign := 1.0
var facing_sign := 1.0
var turn_from_sign := 1.0
var turn_to_sign := 1.0
var v3_top_turn_reverse := false
var v3_top_turn_is_bottom := false
var v3_top_turn_target_sign := 0.0
var speed_mode := SPEED_MODE_CRUISE

var flight_pos := FLIGHT_START_POS
var visual_pos := flight_pos
var velocity := Vector2.ZERO
var camera_center := FLIGHT_START_POS
var camera_look_ahead := Vector2.ZERO
var camera_look_ahead_time := CAMERA_LOOK_AHEAD_TIME
var camera_max_look_ahead := CAMERA_MAX_LOOK_AHEAD
var camera_look_ahead_half_life := CAMERA_LOOK_AHEAD_HALF_LIFE
var camera_hard_turn_look_ahead_scale := CAMERA_HARD_TURN_LOOK_AHEAD_SCALE
var camera_zoom := CAMERA_MIN_ZOOM
var target_heading := Vector2.RIGHT
var body_heading := Vector2.RIGHT
var visual_heading := Vector2.RIGHT
var heading_input := Vector2.RIGHT
var heading_input_active := false
var throttle_pressed := false
var slip_timer := 0.0
var throttle_energy := 0.0
var slip_energy := 0.0
var carve_energy := 0.0
var carve_direction := 0.0
var carve_timer := 0.0
var hard_turn_request_timer := 0.0
var heading_angle_delta := 0.0
var heading_turn_rate := 0.0
var boundary_energy := 0.0
var boost_energy := 0.0
var boost_burst_timer := 0.0
var boost_burst_direction := Vector2.RIGHT
var turn_energy := 0.0
var direction_switch_energy := 0.0
var direction_switch_direction := 0.0
var eight_way_local_rotation := 0.0
var eight_way_visual_offset := Vector2.ZERO
var eight_way_visual_direction_scale := 1.0
var eight_way_visual_adjustments_initialized := false
var eight_way_texture_initialized := false
var time := 0.0
var background_key_enabled := true
var auto_demo := false
var show_debug_guides := false
var eight_way_adjustments: Dictionary = {}
var adjustment_selected_direction := 0
var adjustment_follow_current := true
var adjustment_updating_controls := false

var adjustment_layer: CanvasLayer
var adjustment_panel: PanelContainer
var adjustment_set_option: OptionButton
var adjustment_direction_option: OptionButton
var adjustment_follow_checkbox: CheckBox
var adjustment_global_scale_slider: HSlider
var adjustment_global_scale_spin: SpinBox
var adjustment_direction_scale_slider: HSlider
var adjustment_direction_scale_spin: SpinBox
var adjustment_offset_x_spin: SpinBox
var adjustment_offset_y_spin: SpinBox
var camera_look_ahead_time_slider: HSlider
var camera_look_ahead_time_spin: SpinBox
var camera_max_look_ahead_x_slider: HSlider
var camera_max_look_ahead_x_spin: SpinBox
var camera_max_look_ahead_y_slider: HSlider
var camera_max_look_ahead_y_spin: SpinBox
var camera_look_ahead_half_life_slider: HSlider
var camera_look_ahead_half_life_spin: SpinBox
var camera_hard_turn_look_ahead_scale_slider: HSlider
var camera_hard_turn_look_ahead_scale_spin: SpinBox
var adjustment_status_label: Label

var trail_points: Array = []
var afterimages: Array = []
var direction_switch_fx: Array = []
var boost_shockwaves: Array = []
var boost_shockwave_seed := 0
var boost_shockwave_vfx_root: Node2D
var boost_shockwave_ring_sprite: Sprite2D
var boost_shockwave_particle_layers: Array[GPUParticles2D] = []
var boost_shockwave_textures: Dictionary = {}
var scene_speed_streaks: Array = []
var scene_speed_streak_spawn_accumulator := 0.0
var scene_speed_streak_seed := 0
var hair_fx_panel_hotkey_down := false


func _ready() -> void:
	_load_background_textures()
	_create_nodes()
	if USE_GEMINI_8WAY_CRUISE:
		_load_eight_way_adjustments()
		_load_eight_way_textures()
		_create_adjustment_panel()
	_start_clip(CLIP_CRUISE_IDLE, facing_sign)
	set_process(true)
	set_process_input(true)
	queue_redraw()


func _load_background_textures() -> void:
	cloudsea_far_texture = _load_png_texture(CLOUDSEA_FAR_TEXTURE_PATH)
	cloudsea_mid_texture = _load_png_texture(CLOUDSEA_MID_TEXTURE_PATH)
	mountain_far_ink_texture = _load_png_texture(MOUNTAIN_FAR_INK_TEXTURE_PATH)
	mountain_mid_ink_texture = _load_png_texture(MOUNTAIN_MID_INK_TEXTURE_PATH)
	sea_horizon_wash_texture = _load_png_texture(SEA_HORIZON_WASH_TEXTURE_PATH)
	far_island_chain_texture = _load_png_texture(FAR_ISLAND_CHAIN_TEXTURE_PATH)
	sea_mist_foot_texture = _load_png_texture(SEA_MIST_FOOT_TEXTURE_PATH)
	sea_shimmer_lines_atlas_texture = _load_png_texture(SEA_SHIMMER_LINES_ATLAS_TEXTURE_PATH)
	boundary_cloud_wall_texture = _load_png_texture(BOUNDARY_CLOUD_WALL_TEXTURE_PATH)
	boundary_rune_strip_texture = _load_png_texture(BOUNDARY_RUNE_STRIP_TEXTURE_PATH)
	near_cloud_wisps_atlas_texture = _load_png_texture(NEAR_CLOUD_WISPS_ATLAS_TEXTURE_PATH)
	landmark_silhouettes_atlas_texture = _load_png_texture(LANDMARK_SILHOUETTES_ATLAS_TEXTURE_PATH)


func _process(delta: float) -> void:
	var step := minf(delta, 1.0 / 30.0)
	time += step
	_update_hair_fx_panel_hotkey()
	var axis := _get_move_axis()
	var boosting := _is_boost_pressed()
	_update_motion(axis, boosting, step)
	_update_speed_mode()
	_update_clip_requests(axis, boosting)
	_advance_clip(step, axis, boosting)
	_update_camera(step)
	_update_visual_state(step)
	_update_reference_vfx(step)
	_update_scene_speed_streaks(step)
	_update_adjustment_panel_follow_state()
	_update_direction_switch_fx(step)
	_update_boost_shockwaves(step)
	_update_boost_shockwave_particle_root()
	_update_afterimages(step)
	_update_trail(step)
	_update_airwake_particles(step)
	queue_redraw()


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and _is_hair_fx_panel_hotkey(event):
		hair_fx_panel_hotkey_down = key_event.pressed
		if key_event.pressed and not key_event.echo:
			_toggle_skeleton_hair_fx_panel()
			get_viewport().set_input_as_handled()


func _is_hair_fx_panel_hotkey(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	if key_event == null:
		return false
	return key_event.keycode == KEY_F5


func _update_hair_fx_panel_hotkey() -> void:
	var pressed := Input.is_key_pressed(KEY_F5)
	if pressed and not hair_fx_panel_hotkey_down:
		hair_fx_panel_hotkey_down = true
		_toggle_skeleton_hair_fx_panel()
	elif not pressed and hair_fx_panel_hotkey_down:
		hair_fx_panel_hotkey_down = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_start_clip(CLIP_CRUISE_IDLE, facing_sign)
			KEY_2:
				_start_cruise_turn(facing_sign, -facing_sign)
			KEY_3:
				_start_clip(CLIP_BOOST_ENTER, facing_sign)
			KEY_4:
				_start_clip(CLIP_BOOST_IDLE, facing_sign)
			KEY_5:
				_start_hard_turn(facing_sign, -facing_sign)
			KEY_K:
				background_key_enabled = not background_key_enabled
				_update_key_material()
			KEY_T:
				auto_demo = not auto_demo
			KEY_F2:
				_toggle_adjustment_panel()
			KEY_F3:
				_toggle_control_mode()
			KEY_F6:
				_cycle_skeleton_sword_style()
			KEY_F9:
				show_debug_guides = not show_debug_guides
			KEY_R:
				_start_clip(clip_index, render_sign)


func _toggle_control_mode() -> void:
	if control_mode == CONTROL_MODE_DIRECT_INTENT:
		control_mode = CONTROL_MODE_STEER_THROTTLE
	else:
		control_mode = CONTROL_MODE_DIRECT_INTENT
	if velocity.length_squared() > 0.001:
		target_heading = velocity.normalized()
	else:
		target_heading = body_heading.normalized()
	slip_timer = 0.0
	hard_turn_request_timer = 0.0


func _create_nodes() -> void:
	key_shader = Shader.new()
	key_shader.code = """
shader_type canvas_item;

uniform float key_strength : hint_range(0.0, 1.0) = 1.0;
uniform int key_mode = 2;
uniform vec3 green_key = vec3(0.03, 0.67, 0.02);
uniform float green_distance_floor : hint_range(0.0, 0.5) = 0.13;
uniform float green_distance_ceiling : hint_range(0.0, 0.6) = 0.33;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float green_distance = distance(tex.rgb, green_key);
	float green_dominance = tex.g - max(tex.r, tex.b);
	float green_mask = (1.0 - smoothstep(green_distance_floor, green_distance_ceiling, green_distance)) * smoothstep(0.06, 0.22, green_dominance);
	if (key_mode == 2) {
		tex.a *= 1.0 - green_mask * key_strength;
	}
	COLOR = tex * COLOR;
}
"""

	trail_halo = _create_trail_line("TrailHalo", 0)
	trail_ribbon = _create_trail_line("TrailRibbon", 1)
	trail_core = _create_trail_line("TrailCore", 2)
	_setup_airwake_particles()
	_create_reference_vfx_viewport()

	sprite_root = Node2D.new()
	sprite_root.name = "SequenceCharacterRoot"
	sprite_root.z_index = 5
	add_child(sprite_root)

	character_sprite = Sprite2D.new()
	character_sprite.name = "SequenceCharacter"
	character_sprite.centered = true
	character_sprite.region_enabled = not USE_GEMINI_8WAY_CRUISE
	character_sprite.material = _make_key_material()
	character_sprite.position = POSE_OFFSET
	character_sprite.visible = not _uses_procedural_eight_way()
	sprite_root.add_child(character_sprite)

	skeleton_character = HUMANOID_8WAY_SKELETON_VISUAL.new()
	skeleton_character.name = "SkeletonEightWayCharacter"
	if skeleton_character.has_method("set_external_hair_fx_hotkey_owner"):
		skeleton_character.call("set_external_hair_fx_hotkey_owner", true)
	skeleton_character.visible = _uses_skeleton_eight_way()
	sprite_root.add_child(skeleton_character)
	_setup_boost_shockwave_particles()


func _create_adjustment_panel() -> void:
	adjustment_layer = CanvasLayer.new()
	adjustment_layer.name = "EightWayAdjustmentLayer"
	adjustment_layer.layer = 80
	add_child(adjustment_layer)

	adjustment_panel = PanelContainer.new()
	adjustment_panel.name = "EightWayAdjustmentPanel"
	adjustment_panel.position = Vector2(930.0, 78.0)
	adjustment_panel.custom_minimum_size = Vector2(320.0, 0.0)
	adjustment_layer.add_child(adjustment_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	adjustment_panel.add_child(root)

	var title := Label.new()
	title.text = "四向人物调参  F2"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	adjustment_set_option = OptionButton.new()
	for index in range(GEMINI_EIGHT_WAY_SET_LABELS.size()):
		adjustment_set_option.add_item(String(GEMINI_EIGHT_WAY_SET_LABELS[index]), index)
	adjustment_set_option.select(clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_SET_LABELS.size() - 1))
	adjustment_set_option.item_selected.connect(Callable(self, "_on_adjustment_set_selected"))
	root.add_child(_make_adjustment_row("资源集", adjustment_set_option))

	adjustment_direction_option = OptionButton.new()
	for index in range(GEMINI_EIGHT_WAY_NAMES.size()):
		adjustment_direction_option.add_item(String(GEMINI_EIGHT_WAY_NAMES[index]), index)
	adjustment_direction_option.select(adjustment_selected_direction)
	adjustment_direction_option.item_selected.connect(Callable(self, "_on_adjustment_direction_selected"))
	root.add_child(_make_adjustment_row("方向", adjustment_direction_option))

	adjustment_follow_checkbox = CheckBox.new()
	adjustment_follow_checkbox.text = "跟随当前方向"
	adjustment_follow_checkbox.button_pressed = adjustment_follow_current
	adjustment_follow_checkbox.toggled.connect(Callable(self, "_on_adjustment_follow_toggled"))
	root.add_child(adjustment_follow_checkbox)

	adjustment_global_scale_slider = _make_adjustment_slider(0.6, 1.4, 0.005)
	adjustment_global_scale_spin = _make_adjustment_spin(0.4, 1.8, 0.01)
	adjustment_global_scale_slider.value_changed.connect(Callable(self, "_on_adjustment_global_scale_changed"))
	adjustment_global_scale_spin.value_changed.connect(Callable(self, "_on_adjustment_global_scale_changed"))
	root.add_child(_make_adjustment_slider_row("全局缩放", adjustment_global_scale_slider, adjustment_global_scale_spin))

	adjustment_direction_scale_slider = _make_adjustment_slider(0.6, 1.4, 0.005)
	adjustment_direction_scale_spin = _make_adjustment_spin(0.4, 1.8, 0.01)
	adjustment_direction_scale_slider.value_changed.connect(Callable(self, "_on_adjustment_direction_scale_changed"))
	adjustment_direction_scale_spin.value_changed.connect(Callable(self, "_on_adjustment_direction_scale_changed"))
	root.add_child(_make_adjustment_slider_row("方向缩放", adjustment_direction_scale_slider, adjustment_direction_scale_spin))

	adjustment_offset_x_spin = _make_adjustment_spin(-256.0, 256.0, 1.0)
	adjustment_offset_x_spin.value_changed.connect(Callable(self, "_on_adjustment_offset_x_changed"))
	root.add_child(_make_adjustment_row("X 偏移", adjustment_offset_x_spin))

	adjustment_offset_y_spin = _make_adjustment_spin(-256.0, 256.0, 1.0)
	adjustment_offset_y_spin.value_changed.connect(Callable(self, "_on_adjustment_offset_y_changed"))
	root.add_child(_make_adjustment_row("Y 偏移", adjustment_offset_y_spin))

	var camera_title := Label.new()
	camera_title.text = "镜头"
	camera_title.add_theme_font_size_override("font_size", 14)
	root.add_child(camera_title)

	camera_look_ahead_time_slider = _make_adjustment_slider(0.0, 0.22, 0.005)
	camera_look_ahead_time_spin = _make_adjustment_spin(0.0, 0.35, 0.005)
	camera_look_ahead_time_slider.value_changed.connect(Callable(self, "_on_camera_look_ahead_time_changed"))
	camera_look_ahead_time_spin.value_changed.connect(Callable(self, "_on_camera_look_ahead_time_changed"))
	root.add_child(_make_adjustment_slider_row("预判时间", camera_look_ahead_time_slider, camera_look_ahead_time_spin))

	camera_max_look_ahead_x_slider = _make_adjustment_slider(0.0, 720.0, 5.0)
	camera_max_look_ahead_x_spin = _make_adjustment_spin(0.0, 1200.0, 5.0)
	camera_max_look_ahead_x_slider.value_changed.connect(Callable(self, "_on_camera_max_look_ahead_x_changed"))
	camera_max_look_ahead_x_spin.value_changed.connect(Callable(self, "_on_camera_max_look_ahead_x_changed"))
	root.add_child(_make_adjustment_slider_row("预判X", camera_max_look_ahead_x_slider, camera_max_look_ahead_x_spin))

	camera_max_look_ahead_y_slider = _make_adjustment_slider(0.0, 320.0, 5.0)
	camera_max_look_ahead_y_spin = _make_adjustment_spin(0.0, 800.0, 5.0)
	camera_max_look_ahead_y_slider.value_changed.connect(Callable(self, "_on_camera_max_look_ahead_y_changed"))
	camera_max_look_ahead_y_spin.value_changed.connect(Callable(self, "_on_camera_max_look_ahead_y_changed"))
	root.add_child(_make_adjustment_slider_row("预判Y", camera_max_look_ahead_y_slider, camera_max_look_ahead_y_spin))

	camera_look_ahead_half_life_slider = _make_adjustment_slider(0.01, 0.18, 0.005)
	camera_look_ahead_half_life_spin = _make_adjustment_spin(0.01, 0.30, 0.005)
	camera_look_ahead_half_life_slider.value_changed.connect(Callable(self, "_on_camera_look_ahead_half_life_changed"))
	camera_look_ahead_half_life_spin.value_changed.connect(Callable(self, "_on_camera_look_ahead_half_life_changed"))
	root.add_child(_make_adjustment_slider_row("预判平滑", camera_look_ahead_half_life_slider, camera_look_ahead_half_life_spin))

	camera_hard_turn_look_ahead_scale_slider = _make_adjustment_slider(0.10, 1.0, 0.01)
	camera_hard_turn_look_ahead_scale_spin = _make_adjustment_spin(0.05, 1.0, 0.01)
	camera_hard_turn_look_ahead_scale_slider.value_changed.connect(Callable(self, "_on_camera_hard_turn_look_ahead_scale_changed"))
	camera_hard_turn_look_ahead_scale_spin.value_changed.connect(Callable(self, "_on_camera_hard_turn_look_ahead_scale_changed"))
	root.add_child(_make_adjustment_slider_row("急转预判", camera_hard_turn_look_ahead_scale_slider, camera_hard_turn_look_ahead_scale_spin))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	root.add_child(button_row)
	var reset_direction_button := Button.new()
	reset_direction_button.text = "重置方向"
	reset_direction_button.pressed.connect(Callable(self, "_on_adjustment_reset_direction_pressed"))
	button_row.add_child(reset_direction_button)
	var reset_set_button := Button.new()
	reset_set_button.text = "重置资源集"
	reset_set_button.pressed.connect(Callable(self, "_on_adjustment_reset_set_pressed"))
	button_row.add_child(reset_set_button)
	var reset_camera_button := Button.new()
	reset_camera_button.text = "重置镜头"
	reset_camera_button.pressed.connect(Callable(self, "_on_camera_reset_pressed"))
	button_row.add_child(reset_camera_button)
	var save_button := Button.new()
	save_button.text = "保存调参 JSON"
	save_button.pressed.connect(Callable(self, "_on_adjustment_save_pressed"))
	root.add_child(save_button)

	adjustment_status_label = Label.new()
	adjustment_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	adjustment_status_label.add_theme_font_size_override("font_size", 12)
	root.add_child(adjustment_status_label)

	_refresh_adjustment_controls()


func _make_adjustment_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(76.0, 0.0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _make_adjustment_slider_row(label_text: String, slider: HSlider, spin: SpinBox) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(76.0, 0.0)
	row.add_child(label)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	spin.custom_minimum_size = Vector2(74.0, 0.0)
	row.add_child(spin)
	return row


func _make_adjustment_slider(min_value: float, max_value: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.allow_greater = true
	slider.allow_lesser = true
	return slider


func _make_adjustment_spin(min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.allow_greater = true
	spin.allow_lesser = true
	return spin


func _create_trail_line(line_name: String, z: int) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.z_index = z
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.antialiased = true
	add_child(line)
	return line


func _setup_airwake_particles() -> void:
	airwake_root = Node2D.new()
	airwake_root.name = "YujianAirwakeParticles"
	airwake_root.z_index = 4
	add_child(airwake_root)

	var additive_material := _make_airwake_canvas_material(CanvasItemMaterial.BLEND_MODE_ADD)
	var soft_material := _make_airwake_canvas_material(CanvasItemMaterial.BLEND_MODE_MIX)
	airwake_halo_line = _create_airwake_local_line("AirwakeReadableHalo", 0, additive_material)
	airwake_core_line = _create_airwake_local_line("AirwakeReadableCore", 3, additive_material)
	airwake_cloud_lines = [
		_create_airwake_local_line("AirwakeCloudSplitUpper", 1, soft_material),
		_create_airwake_local_line("AirwakeCloudSplitLower", 1, soft_material),
	]
	airwake_wind_lines.clear()
	for index in range(5):
		airwake_wind_lines.append(_create_airwake_local_line("AirwakeWindCutLine%02d" % index, 4, additive_material))
	airwake_mote_lines.clear()
	for index in range(8):
		airwake_mote_lines.append(_create_airwake_local_line("AirwakeCondensationMote%02d" % index, 2, soft_material))
	airwake_compression_line = _create_airwake_local_line("AirwakeCompressionBand", 0, soft_material)
	qi_rail_particles = _create_airwake_layer(
		"QiRailCoreParticles",
		_make_airwake_needle_texture(120, 12, 0.72),
		_make_airwake_process_material(Vector3(-1.0, 0.0, 0.0), 8.0, Vector3(2.0, 6.0, 1.0), 150.0, 330.0, 8.0, 26.0, 0.060, 0.16, Color(0.88, 1.0, 1.0, 0.36)),
		additive_material,
		剑轨粒子数量,
		剑轨粒子寿命,
		2,
		false,
		0.0
	)
	cloud_split_particles = _create_airwake_layer(
		"CloudSplitMistParticles",
		_make_airwake_soft_texture(22, 5.8, 2.85),
		_make_airwake_process_material(Vector3(-1.0, 0.0, 0.0), 48.0, Vector3(3.0, 40.0, 1.0), 120.0, 280.0, 2.0, 12.0, 0.055, 0.17, Color(0.58, 0.95, 1.0, 0.050), true),
		soft_material,
		云气粒子数量,
		云气粒子寿命,
		1,
		false,
		0.0
	)
	wind_cut_particles = _create_airwake_layer(
		"WindCutNeedlesParticles",
		_make_airwake_needle_texture(112, 5, 0.90),
		_make_airwake_process_material(Vector3(-1.0, 0.0, 0.0), 14.0, Vector3(2.0, 44.0, 1.0), 220.0, 540.0, 5.0, 20.0, 0.065, 0.16, Color(0.94, 1.0, 1.0, 0.25)),
		additive_material,
		风切粒子数量,
		风切粒子寿命,
		3,
		false,
		0.0
	)
	condensation_particles = _create_airwake_layer(
		"WakeDissolveMotes",
		_make_airwake_soft_texture(12, 1.4, 2.9),
		_make_airwake_process_material(Vector3(-1.0, 0.0, 0.0), 66.0, Vector3(3.0, 34.0, 1.0), 76.0, 180.0, 4.0, 15.0, 0.040, 0.12, Color(0.78, 0.98, 1.0, 0.048), true),
		soft_material,
		冷凝粒子数量,
		冷凝粒子寿命,
		1,
		false,
		0.0
	)
	compression_particles = _create_airwake_layer(
		"CompressionConeParticles",
		_make_airwake_cone_texture(104, 34),
		_make_airwake_process_material(Vector3(-1.0, 0.0, 0.0), 9.0, Vector3(3.0, 10.0, 1.0), 92.0, 210.0, 10.0, 32.0, 0.14, 0.34, Color(0.72, 0.98, 1.0, 0.040)),
		soft_material,
		压缩粒子数量,
		压缩粒子寿命,
		0,
		false,
		0.0
	)


func _make_airwake_canvas_material(blend_mode: CanvasItemMaterial.BlendMode) -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = blend_mode
	return material


func _create_airwake_local_line(line_name: String, z: int, canvas_material: CanvasItemMaterial) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.z_index = z
	line.material = canvas_material
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.antialiased = true
	line.visible = false
	airwake_root.add_child(line)
	return line


func _create_airwake_layer(
	layer_name: String,
	texture: Texture2D,
	process_material: ParticleProcessMaterial,
	canvas_material: CanvasItemMaterial,
	amount: int,
	lifetime: float,
	z: int,
	use_trail: bool,
	trail_lifetime: float
) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = layer_name
	particles.z_index = z
	particles.material = canvas_material
	particles.texture = texture
	particles.process_material = process_material
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = false
	particles.preprocess = lifetime * 0.65
	particles.randomness = 0.46
	particles.fixed_fps = 60
	particles.local_coords = false
	particles.draw_order = GPUParticles2D.DRAW_ORDER_LIFETIME
	particles.visibility_rect = AIRWAKE_PARTICLE_VISIBILITY_RECT
	particles.trail_enabled = use_trail
	if use_trail:
		particles.trail_lifetime = trail_lifetime
		particles.trail_sections = 6
		particles.trail_section_subdivisions = 3
	particles.amount_ratio = 0.0
	particles.emitting = false
	airwake_root.add_child(particles)
	airwake_particle_layers.append(particles)
	return particles


func _make_airwake_process_material(
	direction: Vector3,
	spread: float,
	box_extents: Vector3,
	velocity_min: float,
	velocity_max: float,
	damping_min: float,
	damping_max: float,
	scale_min: float,
	scale_max: float,
	color: Color,
	use_turbulence := false
) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = box_extents
	material.direction = direction
	material.spread = spread
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = velocity_min
	material.initial_velocity_max = velocity_max
	material.damping_min = damping_min
	material.damping_max = damping_max
	material.scale_min = scale_min
	material.scale_max = scale_max
	material.color = color
	material.angle_min = -5.0
	material.angle_max = 5.0
	material.angular_velocity_min = -18.0
	material.angular_velocity_max = 18.0
	if use_turbulence:
		material.turbulence_enabled = true
		material.turbulence_noise_strength = 0.16
		material.turbulence_noise_scale = 8.0
		material.turbulence_influence_min = 0.02
		material.turbulence_influence_max = 0.12
	return material


func _make_airwake_soft_texture(size: int, stretch: float, falloff: float) -> ImageTexture:
	var width: int = maxi(int(round(float(size) * stretch)), 4)
	var height: int = maxi(size, 4)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center := Vector2((float(width) - 1.0) * 0.5, (float(height) - 1.0) * 0.5)
	var inv_width := 1.0 / maxf(center.x, 1.0)
	var inv_height := 1.0 / maxf(center.y, 1.0)
	for y in range(height):
		for x in range(width):
			var offset := Vector2((float(x) - center.x) * inv_width, (float(y) - center.y) * inv_height)
			var alpha := pow(maxf(1.0 - offset.length(), 0.0), falloff)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _make_airwake_needle_texture(width: int, height: int, head_bias: float) -> ImageTexture:
	var image := Image.create(maxi(width, 4), maxi(height, 4), false, Image.FORMAT_RGBA8)
	var center_y := (float(height) - 1.0) * 0.5
	var inv_y := 1.0 / maxf(center_y, 1.0)
	for y in range(height):
		for x in range(width):
			var nx := float(x) / maxf(float(width - 1), 1.0)
			var ny := absf((float(y) - center_y) * inv_y)
			var body := pow(maxf(1.0 - ny, 0.0), 3.8)
			var tail_fade := smoothstep(0.0, 0.22, nx)
			var head_fade := 1.0 - smoothstep(head_bias, 1.0, nx)
			var alpha := body * tail_fade * head_fade
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _make_airwake_cone_texture(width: int, height: int) -> ImageTexture:
	var image := Image.create(maxi(width, 4), maxi(height, 4), false, Image.FORMAT_RGBA8)
	var center_y := (float(height) - 1.0) * 0.5
	for y in range(height):
		for x in range(width):
			var nx := float(x) / maxf(float(width - 1), 1.0)
			var local_half_height := lerpf(0.12, 1.0, 1.0 - nx) * center_y
			var y_pressure := 1.0 - clampf(absf(float(y) - center_y) / maxf(local_half_height, 1.0), 0.0, 1.0)
			var length_fade := smoothstep(0.04, 0.24, nx) * (1.0 - smoothstep(0.76, 1.0, nx))
			var alpha := pow(maxf(y_pressure, 0.0), 2.0) * length_fade * 0.72
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _create_reference_vfx_viewport() -> void:
	reference_vfx_viewport = SubViewport.new()
	reference_vfx_viewport.name = "ReferenceVfxViewport"
	reference_vfx_viewport.size = REFERENCE_VFX_VIEWPORT_SIZE
	reference_vfx_viewport.transparent_bg = true
	reference_vfx_viewport.own_world_3d = true
	reference_vfx_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(reference_vfx_viewport)

	reference_vfx_sprite = Sprite2D.new()
	reference_vfx_sprite.name = "ReferenceVfxComposite"
	reference_vfx_sprite.centered = false
	reference_vfx_sprite.texture = reference_vfx_viewport.get_texture()
	reference_vfx_sprite.z_index = 3
	add_child(reference_vfx_sprite)

	var reference_root := Node3D.new()
	reference_root.name = "ReferenceVfxRoot"
	reference_vfx_viewport.add_child(reference_root)

	reference_vfx_camera = Camera3D.new()
	reference_vfx_camera.name = "ReferenceVfxCamera"
	reference_vfx_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	reference_vfx_camera.size = 6.6
	reference_vfx_camera.position = Vector3(0.0, 0.0, 8.0)
	reference_vfx_camera.current = true
	reference_root.add_child(reference_vfx_camera)

	_create_reference_fog_cards(reference_root)
	_create_reference_wind_ribbon(reference_root)


func _create_reference_wind_ribbon(parent: Node3D) -> void:
	reference_wind_ribbons.clear()
	reference_wind_segment_energy.clear()
	reference_wind_segment_rotations.clear()
	reference_wind_segment_emitting.clear()
	for i in range(REFERENCE_WIND_SEGMENT_COUNT):
		var ribbon := _create_reference_wind_ribbon_node("ReferenceWindRibbon%02d" % i)
		parent.add_child(ribbon)
		reference_wind_ribbons.append(ribbon)
		reference_wind_segment_energy.append(0.0)
		reference_wind_segment_rotations.append(0.0)
		reference_wind_segment_emitting.append(false)
	reference_wind_ribbon = reference_wind_ribbons[0] if not reference_wind_ribbons.is_empty() else null


func _create_reference_wind_ribbon_node(ribbon_name: String) -> Node3D:
	var ribbon := Node3D.new()
	ribbon.name = ribbon_name
	ribbon.set_script(WIND_RIBBON_EFFECT_SCRIPT)
	var strand_particles := GPUParticles3D.new()
	strand_particles.name = "StrandParticles"
	ribbon.add_child(strand_particles)

	var veil_particles := GPUParticles3D.new()
	veil_particles.name = "VeilParticles"
	ribbon.add_child(veil_particles)

	var spawn_preview := MeshInstance3D.new()
	spawn_preview.name = "SpawnPreview"
	spawn_preview.visible = false
	ribbon.add_child(spawn_preview)

	ribbon.set("show_spawn_preview", false)
	ribbon.set("preview_in_game", false)
	ribbon.set("emitting", false)
	ribbon.set("world_space_wind", false)
	ribbon.set("use_tube_trails", true)
	ribbon.set("camera_facing", false)
	ribbon.set("cross_section", true)
	ribbon.set("spawn_extents", Vector3(4.9, 2.45, 0.55))
	ribbon.set("wind_direction", reference_wind_direction)
	ribbon.set("strand_amount", 32)
	ribbon.set("strand_lifetime", 1.85)
	ribbon.set("strand_trail_lifetime", REFERENCE_WIND_STRAND_TRAIL_LIFETIME)
	ribbon.set("strand_width", 0.045)
	ribbon.set("strand_speed_min", 3.8)
	ribbon.set("strand_speed_max", 6.4)
	ribbon.set("strand_opacity", REFERENCE_WIND_STRAND_OPACITY)
	ribbon.set("strand_color", REFERENCE_WIND_STRAND_COLOR)
	ribbon.set("veil_amount", 7)
	ribbon.set("veil_lifetime", 2.1)
	ribbon.set("veil_trail_lifetime", REFERENCE_WIND_VEIL_TRAIL_LIFETIME)
	ribbon.set("veil_width", 0.075)
	ribbon.set("veil_speed_min", 1.8)
	ribbon.set("veil_speed_max", 3.1)
	ribbon.set("veil_opacity", REFERENCE_WIND_VEIL_OPACITY)
	ribbon.set("veil_color", REFERENCE_WIND_VEIL_COLOR)
	ribbon.set("spread", 2.4)
	ribbon.set("lift", 0.02)
	ribbon.set("turbulence", 0.12)
	ribbon.visible = false
	return ribbon


func _create_reference_fog_cards(parent: Node3D) -> void:
	reference_fog_cards.clear()
	for i in range(REFERENCE_FOG_CARD_COUNT):
		var card := MeshInstance3D.new()
		card.name = "ReferenceFogCard%02d" % i
		var mesh := QuadMesh.new()
		mesh.size = Vector2(2.27, 1.5)
		card.mesh = mesh
		card.material_override = _make_reference_fog_material(i)
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		card.set_script(FOG_CARD_3D_SCRIPT)
		card.set("plane_size", Vector2(2.27, 1.5))
		card.set("card_scale_factor", lerpf(1.55, 2.65, _hash01(float(i) + 0.4)))
		card.set("phase", 0.45)
		card.set("random_offset", Vector2(_hash01(float(i) + 1.2), _hash01(float(i) + 2.8)))
		card.set("billboard", true)
		card.set("fog_tint", Color(0.88, 0.92, 0.88, 1.0))
		card.set("fog_opacity", lerpf(0.42, 0.68, _hash01(float(i) + 3.5)))
		card.set("noise_scale", 9.25)
		card.set("noise_speed", Vector2(0.035 + 0.02 * _hash01(float(i) + 4.3), 0.0))
		card.set("softness", 3.0)
		card.set("fade_in", 0.1)
		card.set("fade_out", 0.9)
		card.set("near_fade", 0.1)
		card.set("far_fade", 80.0)
		parent.add_child(card)
		reference_fog_cards.append(card)


func _make_reference_fog_material(index: int) -> ShaderMaterial:
	var noise := FastNoiseLite.new()
	noise.seed = 9100 + index * 37
	noise.frequency = 0.003

	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	ramp.colors = PackedColorArray([Color.BLACK, Color(0.82, 0.82, 0.82, 1.0), Color.WHITE])

	var noise_texture := NoiseTexture2D.new()
	noise_texture.width = 256
	noise_texture.height = 256
	noise_texture.noise = noise
	noise_texture.color_ramp = ramp
	noise_texture.seamless = true
	noise_texture.seamless_blend_skirt = 1.0

	var material := ShaderMaterial.new()
	material.resource_local_to_scene = true
	material.shader = FOG_CARD_SHADER
	material.set_shader_parameter("color", Color(0.88, 0.92, 0.88, 0.58))
	material.set_shader_parameter("noise_texture", noise_texture)
	material.set_shader_parameter("noise_scale", 9.25)
	material.set_shader_parameter("noise_speed", Vector2(0.05, 0.0))
	material.set_shader_parameter("softness", 3.0)
	material.set_shader_parameter("fade_in", 0.1)
	material.set_shader_parameter("fade_out", 0.9)
	material.set_shader_parameter("near_fade", 0.1)
	material.set_shader_parameter("far_fade", 80.0)
	material.set_shader_parameter("phase", 0.45)
	material.set_shader_parameter("scale_factor", 1.0)
	material.set_shader_parameter("random_offset", Vector2(_hash01(float(index) + 1.2), _hash01(float(index) + 2.8)))
	material.set_shader_parameter("billboard", true)
	return material


func _make_key_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = key_shader
	_apply_key_params(material)
	return material


func _apply_key_params(material: ShaderMaterial) -> void:
	material.set_shader_parameter("key_mode", KEY_MODE_GREEN if background_key_enabled else KEY_MODE_NONE)
	material.set_shader_parameter("key_strength", 1.0 if background_key_enabled else 0.0)


func _update_key_material() -> void:
	if character_sprite != null and character_sprite.material is ShaderMaterial:
		_apply_key_params(character_sprite.material as ShaderMaterial)


func _load_sequence_texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	var image := Image.new()
	var global_path := ProjectSettings.globalize_path(path)
	if image.load(global_path) == OK:
		var image_texture := ImageTexture.create_from_image(image)
		texture_cache[path] = image_texture
		return image_texture
	var texture := load(path) as Texture2D
	if texture != null:
		texture_cache[path] = texture
	return texture


func _load_eight_way_adjustments() -> void:
	eight_way_adjustments = {"sets": {}}
	var global_path := ProjectSettings.globalize_path(EIGHT_WAY_RUNTIME_ADJUSTMENTS_PATH)
	if FileAccess.file_exists(global_path):
		var file := FileAccess.open(global_path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				eight_way_adjustments = parsed
	_ensure_all_eight_way_adjustments()
	_apply_camera_adjustments_from_data()


func _save_eight_way_adjustments() -> bool:
	_ensure_all_eight_way_adjustments()
	_write_camera_adjustments_to_data()
	var global_path := ProjectSettings.globalize_path(EIGHT_WAY_RUNTIME_ADJUSTMENTS_PATH)
	var file := FileAccess.open(global_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(eight_way_adjustments, "\t"))
	return true


func _ensure_all_eight_way_adjustments() -> void:
	if typeof(eight_way_adjustments) != TYPE_DICTIONARY:
		eight_way_adjustments = {}
	if not eight_way_adjustments.has("sets") or typeof(eight_way_adjustments["sets"]) != TYPE_DICTIONARY:
		eight_way_adjustments["sets"] = {}
	for index in range(GEMINI_EIGHT_WAY_BASE_PATHS.size()):
		_ensure_eight_way_adjustment_set(index)
	_ensure_camera_adjustments()


func _ensure_camera_adjustments() -> void:
	if not eight_way_adjustments.has("camera") or typeof(eight_way_adjustments["camera"]) != TYPE_DICTIONARY:
		eight_way_adjustments["camera"] = {}
	var camera_data: Dictionary = eight_way_adjustments["camera"]
	if not camera_data.has("look_ahead_time"):
		camera_data["look_ahead_time"] = CAMERA_LOOK_AHEAD_TIME
	if not camera_data.has("max_look_ahead") or typeof(camera_data["max_look_ahead"]) != TYPE_ARRAY:
		camera_data["max_look_ahead"] = [CAMERA_MAX_LOOK_AHEAD.x, CAMERA_MAX_LOOK_AHEAD.y]
	if not camera_data.has("look_ahead_half_life"):
		camera_data["look_ahead_half_life"] = CAMERA_LOOK_AHEAD_HALF_LIFE
	if not camera_data.has("hard_turn_look_ahead_scale"):
		camera_data["hard_turn_look_ahead_scale"] = CAMERA_HARD_TURN_LOOK_AHEAD_SCALE


func _apply_camera_adjustments_from_data() -> void:
	_ensure_camera_adjustments()
	var camera_data: Dictionary = eight_way_adjustments["camera"]
	camera_look_ahead_time = clampf(float(camera_data.get("look_ahead_time", CAMERA_LOOK_AHEAD_TIME)), 0.0, 0.35)
	var raw_max: Array = camera_data.get("max_look_ahead", [CAMERA_MAX_LOOK_AHEAD.x, CAMERA_MAX_LOOK_AHEAD.y])
	if raw_max.size() < 2:
		raw_max = [CAMERA_MAX_LOOK_AHEAD.x, CAMERA_MAX_LOOK_AHEAD.y]
	camera_max_look_ahead = Vector2(
		clampf(float(raw_max[0]), 0.0, 1200.0),
		clampf(float(raw_max[1]), 0.0, 800.0)
	)
	camera_look_ahead_half_life = clampf(float(camera_data.get("look_ahead_half_life", CAMERA_LOOK_AHEAD_HALF_LIFE)), 0.01, 0.30)
	camera_hard_turn_look_ahead_scale = clampf(float(camera_data.get("hard_turn_look_ahead_scale", CAMERA_HARD_TURN_LOOK_AHEAD_SCALE)), 0.05, 1.0)


func _write_camera_adjustments_to_data() -> void:
	_ensure_camera_adjustments()
	var camera_data: Dictionary = eight_way_adjustments["camera"]
	camera_data["look_ahead_time"] = camera_look_ahead_time
	camera_data["max_look_ahead"] = [camera_max_look_ahead.x, camera_max_look_ahead.y]
	camera_data["look_ahead_half_life"] = camera_look_ahead_half_life
	camera_data["hard_turn_look_ahead_scale"] = camera_hard_turn_look_ahead_scale


func _ensure_eight_way_adjustment_set(set_index: int) -> void:
	var sets: Dictionary = eight_way_adjustments["sets"]
	var set_key := _get_eight_way_set_key(set_index)
	if not sets.has(set_key) or typeof(sets[set_key]) != TYPE_DICTIONARY:
		sets[set_key] = {
			"global_scale": 1.0,
			"directions": {},
		}
	var set_data: Dictionary = sets[set_key]
	if not set_data.has("global_scale"):
		set_data["global_scale"] = 1.0
	if not set_data.has("directions") or typeof(set_data["directions"]) != TYPE_DICTIONARY:
		set_data["directions"] = {}
	var directions: Dictionary = set_data["directions"]
	for name_variant in GEMINI_EIGHT_WAY_NAMES:
		var name := String(name_variant)
		if not directions.has(name) or typeof(directions[name]) != TYPE_DICTIONARY:
			directions[name] = {
				"scale": 1.0,
				"offset": [0.0, 0.0],
			}
		var direction_data: Dictionary = directions[name]
		if not direction_data.has("scale"):
			direction_data["scale"] = 1.0
		if not direction_data.has("offset") or typeof(direction_data["offset"]) != TYPE_ARRAY:
			direction_data["offset"] = [0.0, 0.0]


func _get_eight_way_set_key(set_index: int) -> String:
	var safe_index := clampi(set_index, 0, GEMINI_EIGHT_WAY_BASE_PATHS.size() - 1)
	return String(GEMINI_EIGHT_WAY_BASE_PATHS[safe_index])


func _get_eight_way_set_adjustment(set_index: int) -> Dictionary:
	if not eight_way_adjustments.has("sets") or typeof(eight_way_adjustments["sets"]) != TYPE_DICTIONARY:
		_ensure_all_eight_way_adjustments()
	_ensure_eight_way_adjustment_set(set_index)
	var sets: Dictionary = eight_way_adjustments["sets"]
	return sets[_get_eight_way_set_key(set_index)]


func _get_eight_way_direction_adjustment(set_index: int, direction_index: int) -> Dictionary:
	var set_data := _get_eight_way_set_adjustment(set_index)
	var directions: Dictionary = set_data["directions"]
	var direction_name := String(GEMINI_EIGHT_WAY_NAMES[clampi(direction_index, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)])
	return directions[direction_name]


func _get_eight_way_global_scale(set_index: int) -> float:
	var set_data := _get_eight_way_set_adjustment(set_index)
	return float(set_data.get("global_scale", 1.0))


func _get_eight_way_direction_scale(set_index: int, direction_index: int) -> float:
	var direction_data := _get_eight_way_direction_adjustment(set_index, direction_index)
	return float(direction_data.get("scale", 1.0))


func _get_eight_way_direction_offset(set_index: int, direction_index: int) -> Vector2:
	var direction_data := _get_eight_way_direction_adjustment(set_index, direction_index)
	var raw_offset: Array = direction_data.get("offset", [0.0, 0.0])
	if raw_offset.size() < 2:
		return Vector2.ZERO
	return Vector2(float(raw_offset[0]), float(raw_offset[1]))


func _load_eight_way_textures() -> void:
	eight_way_textures.clear()
	if _uses_procedural_eight_way():
		return
	for index in range(GEMINI_EIGHT_WAY_NAMES.size()):
		if _uses_v3_face_eight_way() and not _is_v3_two_way_direction_index(index):
			eight_way_textures.append(null)
			continue
		var path := _get_eight_way_path(index)
		var texture := _load_sequence_texture(path)
		if texture == null:
			push_warning("Missing Gemini 8-way yujian sprite (%s): %s" % [_current_eight_way_set_label(), path])
		eight_way_textures.append(texture)


func _set_eight_way_character_set(_next_set: int) -> void:
	eight_way_character_set = EIGHT_WAY_SET_V4_SKELETON
	if not USE_GEMINI_8WAY_CRUISE:
		return
	eight_way_texture_initialized = false
	eight_way_visual_adjustments_initialized = false
	if character_sprite != null:
		character_sprite.visible = not _uses_procedural_eight_way()
	if skeleton_character != null:
		skeleton_character.visible = _uses_skeleton_eight_way()
	_load_eight_way_textures()
	if _use_v1_sequence_visual():
		if sheet_texture == null:
			_start_clip(CLIP_CRUISE_IDLE, facing_sign)
		else:
			_apply_v1_hybrid_texture(visual_heading)
			_apply_sprite_transform()
	else:
		_apply_eight_way_texture(visual_heading)
	_refresh_adjustment_controls()
	queue_redraw()


func _eight_way_set_count() -> int:
	return GEMINI_EIGHT_WAY_SET_LABELS.size()


func _uses_skeleton_eight_way() -> bool:
	return eight_way_character_set == EIGHT_WAY_SET_V4_SKELETON


func _uses_v3_face_eight_way() -> bool:
	return false


func _uses_ink_part_eight_way() -> bool:
	return false


func _uses_google_part_eight_way() -> bool:
	return false


func _google_part_root_path() -> String:
	return ""


func _uses_procedural_eight_way() -> bool:
	return _uses_skeleton_eight_way()


func _get_eight_way_path(index: int) -> String:
	var set_index := clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_BASE_PATHS.size() - 1)
	var name_index := clampi(index, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)
	return "%s/%s.png" % [
		String(GEMINI_EIGHT_WAY_BASE_PATHS[set_index]),
		String(GEMINI_EIGHT_WAY_NAMES[name_index]),
	]


func _toggle_adjustment_panel() -> void:
	if adjustment_panel == null:
		return
	adjustment_panel.visible = not adjustment_panel.visible


func _toggle_skeleton_hair_fx_panel() -> void:
	if skeleton_character == null or not skeleton_character.has_method("toggle_hair_fx_panel"):
		return
	skeleton_character.call("toggle_hair_fx_panel")


func _cycle_skeleton_sword_style() -> void:
	if skeleton_character == null or not skeleton_character.has_method("cycle_sword_style"):
		return
	skeleton_character.call("cycle_sword_style")


func _current_skeleton_sword_style_label() -> String:
	if skeleton_character == null or not skeleton_character.has_method("get_sword_style_label"):
		return "-"
	return String(skeleton_character.call("get_sword_style_label"))


func _update_adjustment_panel_follow_state() -> void:
	if adjustment_panel == null or not adjustment_panel.visible:
		return
	var needs_refresh := false
	if adjustment_set_option != null and adjustment_set_option.selected != eight_way_character_set:
		adjustment_set_option.select(clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_SET_LABELS.size() - 1))
		needs_refresh = true
	if adjustment_follow_current and adjustment_selected_direction != eight_way_index:
		adjustment_selected_direction = eight_way_index
		if adjustment_direction_option != null:
			adjustment_direction_option.select(adjustment_selected_direction)
		needs_refresh = true
	if needs_refresh:
		_refresh_adjustment_controls()


func _refresh_adjustment_controls() -> void:
	if adjustment_panel == null:
		return
	var set_index := clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_BASE_PATHS.size() - 1)
	var direction_index := clampi(adjustment_selected_direction, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)
	var global_scale := _get_eight_way_global_scale(set_index)
	var direction_scale := _get_eight_way_direction_scale(set_index, direction_index)
	var offset := _get_eight_way_direction_offset(set_index, direction_index)

	adjustment_updating_controls = true
	adjustment_set_option.select(set_index)
	adjustment_direction_option.select(direction_index)
	adjustment_follow_checkbox.button_pressed = adjustment_follow_current
	adjustment_global_scale_slider.value = global_scale
	adjustment_global_scale_spin.value = global_scale
	adjustment_direction_scale_slider.value = direction_scale
	adjustment_direction_scale_spin.value = direction_scale
	adjustment_offset_x_spin.value = offset.x
	adjustment_offset_y_spin.value = offset.y
	camera_look_ahead_time_slider.value = camera_look_ahead_time
	camera_look_ahead_time_spin.value = camera_look_ahead_time
	camera_max_look_ahead_x_slider.value = camera_max_look_ahead.x
	camera_max_look_ahead_x_spin.value = camera_max_look_ahead.x
	camera_max_look_ahead_y_slider.value = camera_max_look_ahead.y
	camera_max_look_ahead_y_spin.value = camera_max_look_ahead.y
	camera_look_ahead_half_life_slider.value = camera_look_ahead_half_life
	camera_look_ahead_half_life_spin.value = camera_look_ahead_half_life
	camera_hard_turn_look_ahead_scale_slider.value = camera_hard_turn_look_ahead_scale
	camera_hard_turn_look_ahead_scale_spin.value = camera_hard_turn_look_ahead_scale
	adjustment_updating_controls = false
	_update_adjustment_status()


func _update_adjustment_status(extra_message := "") -> void:
	if adjustment_status_label == null:
		return
	var set_label := _current_eight_way_set_label()
	var direction_name := String(GEMINI_EIGHT_WAY_NAMES[clampi(adjustment_selected_direction, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)])
	var global_scale := _get_eight_way_global_scale(eight_way_character_set)
	var direction_scale := _get_eight_way_direction_scale(eight_way_character_set, adjustment_selected_direction)
	var offset := _get_eight_way_direction_offset(eight_way_character_set, adjustment_selected_direction)
	adjustment_status_label.text = "%s / %s\n全局 %.3f  方向 %.3f  偏移 %.0f, %.0f" % [
		set_label,
		direction_name,
		global_scale,
		direction_scale,
		offset.x,
		offset.y,
	]
	adjustment_status_label.text += "\n镜头 预判 %.3f  X%.0f Y%.0f  平滑 %.3f  急转 %.2f" % [
		camera_look_ahead_time,
		camera_max_look_ahead.x,
		camera_max_look_ahead.y,
		camera_look_ahead_half_life,
		camera_hard_turn_look_ahead_scale,
	]
	if extra_message != "":
		adjustment_status_label.text += "\n%s" % extra_message


func _on_adjustment_set_selected(index: int) -> void:
	if adjustment_updating_controls:
		return
	_set_eight_way_character_set(index)


func _on_adjustment_direction_selected(index: int) -> void:
	if adjustment_updating_controls:
		return
	adjustment_selected_direction = clampi(index, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)
	adjustment_follow_current = false
	_refresh_adjustment_controls()


func _on_adjustment_follow_toggled(pressed: bool) -> void:
	if adjustment_updating_controls:
		return
	adjustment_follow_current = pressed
	if adjustment_follow_current:
		adjustment_selected_direction = eight_way_index
	_refresh_adjustment_controls()


func _on_adjustment_global_scale_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	var set_data := _get_eight_way_set_adjustment(eight_way_character_set)
	set_data["global_scale"] = value
	adjustment_updating_controls = true
	adjustment_global_scale_slider.value = value
	adjustment_global_scale_spin.value = value
	adjustment_updating_controls = false
	_apply_sprite_transform()
	_update_adjustment_status()


func _on_adjustment_direction_scale_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	var direction_data := _get_eight_way_direction_adjustment(eight_way_character_set, adjustment_selected_direction)
	direction_data["scale"] = value
	adjustment_updating_controls = true
	adjustment_direction_scale_slider.value = value
	adjustment_direction_scale_spin.value = value
	adjustment_updating_controls = false
	_apply_sprite_transform()
	_update_adjustment_status()


func _on_adjustment_offset_x_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	var offset := _get_eight_way_direction_offset(eight_way_character_set, adjustment_selected_direction)
	_set_eight_way_direction_offset(adjustment_selected_direction, Vector2(value, offset.y))


func _on_adjustment_offset_y_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	var offset := _get_eight_way_direction_offset(eight_way_character_set, adjustment_selected_direction)
	_set_eight_way_direction_offset(adjustment_selected_direction, Vector2(offset.x, value))


func _set_eight_way_direction_offset(direction_index: int, offset: Vector2) -> void:
	var direction_data := _get_eight_way_direction_adjustment(eight_way_character_set, direction_index)
	direction_data["offset"] = [offset.x, offset.y]
	adjustment_updating_controls = true
	adjustment_offset_x_spin.value = offset.x
	adjustment_offset_y_spin.value = offset.y
	adjustment_updating_controls = false
	_apply_sprite_transform()
	_update_adjustment_status()


func _sync_camera_control_pair(slider: HSlider, spin: SpinBox, value: float) -> void:
	adjustment_updating_controls = true
	slider.value = value
	spin.value = value
	adjustment_updating_controls = false


func _on_camera_look_ahead_time_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	camera_look_ahead_time = clampf(value, 0.0, 0.35)
	_sync_camera_control_pair(camera_look_ahead_time_slider, camera_look_ahead_time_spin, camera_look_ahead_time)
	_write_camera_adjustments_to_data()
	_update_adjustment_status()


func _on_camera_max_look_ahead_x_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	camera_max_look_ahead.x = clampf(value, 0.0, 1200.0)
	_sync_camera_control_pair(camera_max_look_ahead_x_slider, camera_max_look_ahead_x_spin, camera_max_look_ahead.x)
	_write_camera_adjustments_to_data()
	_update_adjustment_status()


func _on_camera_max_look_ahead_y_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	camera_max_look_ahead.y = clampf(value, 0.0, 800.0)
	_sync_camera_control_pair(camera_max_look_ahead_y_slider, camera_max_look_ahead_y_spin, camera_max_look_ahead.y)
	_write_camera_adjustments_to_data()
	_update_adjustment_status()


func _on_camera_look_ahead_half_life_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	camera_look_ahead_half_life = clampf(value, 0.01, 0.30)
	_sync_camera_control_pair(camera_look_ahead_half_life_slider, camera_look_ahead_half_life_spin, camera_look_ahead_half_life)
	_write_camera_adjustments_to_data()
	_update_adjustment_status()


func _on_camera_hard_turn_look_ahead_scale_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	camera_hard_turn_look_ahead_scale = clampf(value, 0.05, 1.0)
	_sync_camera_control_pair(camera_hard_turn_look_ahead_scale_slider, camera_hard_turn_look_ahead_scale_spin, camera_hard_turn_look_ahead_scale)
	_write_camera_adjustments_to_data()
	_update_adjustment_status()


func _on_camera_reset_pressed() -> void:
	camera_look_ahead_time = CAMERA_LOOK_AHEAD_TIME
	camera_max_look_ahead = CAMERA_MAX_LOOK_AHEAD
	camera_look_ahead_half_life = CAMERA_LOOK_AHEAD_HALF_LIFE
	camera_hard_turn_look_ahead_scale = CAMERA_HARD_TURN_LOOK_AHEAD_SCALE
	camera_look_ahead = Vector2.ZERO
	_write_camera_adjustments_to_data()
	_refresh_adjustment_controls()


func _on_adjustment_reset_direction_pressed() -> void:
	var direction_data := _get_eight_way_direction_adjustment(eight_way_character_set, adjustment_selected_direction)
	direction_data["scale"] = 1.0
	direction_data["offset"] = [0.0, 0.0]
	_apply_sprite_transform()
	_refresh_adjustment_controls()


func _on_adjustment_reset_set_pressed() -> void:
	var set_data := _get_eight_way_set_adjustment(eight_way_character_set)
	set_data["global_scale"] = 1.0
	var directions: Dictionary = set_data["directions"]
	for name_variant in GEMINI_EIGHT_WAY_NAMES:
		var name := String(name_variant)
		directions[name] = {
			"scale": 1.0,
			"offset": [0.0, 0.0],
		}
	_apply_sprite_transform()
	_refresh_adjustment_controls()


func _on_adjustment_save_pressed() -> void:
	if _save_eight_way_adjustments():
		_update_adjustment_status("已保存到 prototype_runtime_adjustments.json")
	else:
		_update_adjustment_status("保存失败：无法写入 JSON")


func _start_clip(next_clip: int, fixed_render_sign := 0.0, entry_frame := 0) -> void:
	clip_index = clampi(next_clip, 0, CLIPS.size() - 1)
	frame_timer = 0.0
	if fixed_render_sign != 0.0:
		_set_render_sign(fixed_render_sign, false)
	else:
		_set_render_sign(facing_sign, false)

	var clip := _current_clip()
	frame_index = clampi(entry_frame, 0, int(clip["frames"]) - 1)
	sheet_texture = _load_sequence_texture(String(clip["path"]))
	if sheet_texture == null:
		push_warning("Missing yujian v2 sheet: %s" % String(clip["path"]))
		return
	character_sprite.texture = sheet_texture
	_apply_frame()
	_apply_sprite_transform()


func _set_render_sign(next_sign: float, reset_directional_vfx := true) -> void:
	if next_sign == 0.0:
		return
	var next := signf(next_sign)
	if reset_directional_vfx and next != render_sign:
		_reset_directional_vfx()
	render_sign = next


func _reset_directional_vfx() -> void:
	trail_points.clear()
	afterimages.clear()


func _start_cruise_turn(from_sign: float, to_sign: float, entry_phase := 0.0) -> void:
	if _use_v1_sequence_visual():
		facing_sign = signf(to_sign)
		_set_render_sign(facing_sign)
		return
	turn_from_sign = signf(from_sign)
	turn_to_sign = signf(to_sign)
	var entry_frame := int(round(clampf(entry_phase, 0.0, 1.0) * float(int(CLIPS[CLIP_CRUISE_TURN]["frames"]) - 1)))
	_start_clip(CLIP_CRUISE_TURN, turn_from_sign, entry_frame)
	_capture_afterimage(flight_pos - Vector2(turn_from_sign * 24.0, 0.0), 0.72)


func _start_hard_turn(from_sign: float, to_sign: float) -> void:
	if _use_v1_sequence_visual():
		hard_turn_request_timer = 0.0
		facing_sign = signf(to_sign)
		_set_render_sign(facing_sign)
		return
	turn_from_sign = signf(from_sign)
	turn_to_sign = signf(to_sign)
	_start_clip(CLIP_HARD_TURN_CORE, turn_from_sign)
	_capture_afterimage(flight_pos - Vector2(turn_from_sign * 36.0, 0.0), 1.0)
	_capture_afterimage(flight_pos - Vector2(turn_from_sign * 72.0, -8.0), 0.72)


func _start_v3_top_turn(from_sign: float, to_sign: float, is_bottom_turn := false) -> void:
	if not _uses_v3_face_eight_way():
		return
	turn_from_sign = signf(from_sign) if from_sign != 0.0 else facing_sign
	turn_to_sign = signf(to_sign) if to_sign != 0.0 else -turn_from_sign
	if turn_to_sign == turn_from_sign:
		return
	v3_top_turn_is_bottom = is_bottom_turn
	v3_top_turn_reverse = (turn_from_sign < 0.0 and turn_to_sign > 0.0) != v3_top_turn_is_bottom
	v3_top_turn_target_sign = turn_to_sign
	eight_way_index = _v3_two_way_index_from_sign(turn_from_sign)
	eight_way_local_rotation = _get_eight_way_local_rotation(visual_heading, eight_way_index)
	_start_clip(CLIP_V3_TOP_TURN, turn_from_sign)
	_capture_afterimage(flight_pos - Vector2(turn_from_sign * 32.0, -12.0), 0.82)


func _start_hard_follow(next_clip: int) -> void:
	_start_clip(next_clip, turn_from_sign)


func _advance_clip(delta: float, axis: Vector2, boosting: bool) -> void:
	if sheet_texture == null:
		return
	var clip := _current_clip()
	frame_timer += delta
	var frame_duration := 1.0 / maxf(float(clip["fps"]), 1.0)
	while frame_timer >= frame_duration:
		frame_timer -= frame_duration
		frame_index += 1
		if frame_index >= int(clip["frames"]):
			if bool(clip["loop"]):
				frame_index = 0
			else:
				frame_index = int(clip["frames"]) - 1
				_apply_frame()
				_finish_clip(axis, boosting)
				return
		_apply_frame()


func _finish_clip(_axis: Vector2, _boosting: bool) -> void:
	match clip_index:
		CLIP_V3_TOP_TURN:
			facing_sign = turn_to_sign
			_set_render_sign(facing_sign)
			eight_way_index = 0 if facing_sign > 0.0 else 2
			eight_way_local_rotation = 0.0
			eight_way_texture_initialized = true
			v3_top_turn_is_bottom = false
			v3_top_turn_target_sign = 0.0
			_start_clip(CLIP_CRUISE_IDLE, facing_sign)
		CLIP_CRUISE_TURN:
			facing_sign = turn_to_sign
			_set_render_sign(facing_sign)
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_ENTER, facing_sign)
			else:
				_start_clip(CLIP_CRUISE_IDLE, facing_sign)
		CLIP_BOOST_ENTER:
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_IDLE, facing_sign)
			else:
				_start_clip(CLIP_BOOST_EXIT, facing_sign)
		CLIP_BOOST_EXIT:
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_ENTER, facing_sign)
			else:
				_start_clip(CLIP_CRUISE_IDLE, facing_sign)
		CLIP_HARD_TURN_CORE:
			facing_sign = turn_to_sign
			_set_render_sign(facing_sign)
			if speed_mode == SPEED_MODE_BOOST:
				_start_hard_follow(CLIP_HARD_TURN_TO_BOOST)
			else:
				_start_hard_follow(CLIP_HARD_TURN_TO_CRUISE)
		CLIP_HARD_TURN_TO_BOOST:
			facing_sign = turn_to_sign
			_set_render_sign(facing_sign)
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_IDLE, facing_sign, BOOST_IDLE_HARD_TURN_ENTRY_FRAME)
			else:
				_start_clip(CLIP_BOOST_EXIT, facing_sign)
		CLIP_HARD_TURN_TO_CRUISE:
			facing_sign = turn_to_sign
			_set_render_sign(facing_sign)
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_ENTER, facing_sign)
			else:
				_start_clip(CLIP_CRUISE_IDLE, facing_sign)
		_:
			_start_clip(CLIP_CRUISE_IDLE, facing_sign)


func _update_clip_requests(_axis: Vector2, _boosting: bool) -> void:
	var desired_sign := _heading_render_sign(body_heading, render_sign)
	if _is_v3_top_turn_clip():
		return
	var v3_turn_request := _v3_vertical_turn_request_from_heading()
	if not v3_turn_request.is_empty():
		_start_v3_top_turn(facing_sign, float(v3_turn_request["target_sign"]), bool(v3_turn_request["bottom"]))
		return
	var using_v1_sequence := _use_v1_sequence_visual()
	if using_v1_sequence:
		hard_turn_request_timer = 0.0
		if _is_hard_turn_clip() or clip_index == CLIP_CRUISE_TURN:
			_start_clip(CLIP_BOOST_IDLE if speed_mode == SPEED_MODE_BOOST else CLIP_CRUISE_IDLE, facing_sign)
			return
		if absf(body_heading.x) > 0.34 and desired_sign != facing_sign:
			facing_sign = desired_sign
			_set_render_sign(desired_sign)
	var can_interrupt_turn := not _is_turn_clip() or _clip_phase() >= 0.22

	if hard_turn_request_timer > 0.0 and can_interrupt_turn:
		hard_turn_request_timer = 0.0
		var hard_target_sign := _heading_render_sign(target_heading, desired_sign)
		_start_hard_turn(render_sign, hard_target_sign)
		return

	if not _is_clip_looping():
		if _clip_phase() >= 0.18 and absf(body_heading.x) > 0.34 and desired_sign != facing_sign:
			if _should_use_hard_turn():
				_start_hard_turn(render_sign, desired_sign)
			else:
				_start_cruise_turn(render_sign, desired_sign, 0.32)
			return
		if clip_index == CLIP_BOOST_ENTER and not throttle_pressed:
			_start_clip(CLIP_BOOST_EXIT, facing_sign)
			return
		if clip_index == CLIP_BOOST_EXIT and throttle_pressed:
			_start_clip(CLIP_BOOST_ENTER, facing_sign)
			return
		if absf(body_heading.x) > 0.34:
			facing_sign = desired_sign
		return

	var sign_changed := absf(body_heading.x) > 0.34 and desired_sign != facing_sign
	if sign_changed:
		if _should_use_hard_turn():
			_start_hard_turn(facing_sign, desired_sign)
		else:
			_start_cruise_turn(facing_sign, desired_sign)
		return

	if absf(body_heading.x) > 0.34:
		facing_sign = desired_sign
		_set_render_sign(desired_sign)

	if speed_mode == SPEED_MODE_BOOST:
		if clip_index == CLIP_CRUISE_IDLE or clip_index == CLIP_BOOST_EXIT:
			_start_clip(CLIP_BOOST_ENTER, facing_sign)
	else:
		if clip_index == CLIP_BOOST_IDLE or clip_index == CLIP_BOOST_ENTER:
			_start_clip(CLIP_BOOST_EXIT, facing_sign)


func _v3_vertical_turn_request_from_heading() -> Dictionary:
	if not _uses_v3_face_eight_way():
		return {}
	if absf(body_heading.x) > V3_TWO_WAY_VERTICAL_X_THRESHOLD or absf(body_heading.y) < V3_TWO_WAY_VERTICAL_Y_THRESHOLD:
		return {}
	var target_sign := _heading_render_sign(target_heading, facing_sign)
	if target_sign == facing_sign:
		return {}
	return {
		"target_sign": target_sign,
		"bottom": body_heading.y > 0.0,
	}


func _update_motion(axis: Vector2, boosting: bool, delta: float) -> void:
	if control_mode == CONTROL_MODE_STEER_THROTTLE:
		_update_steer_throttle_motion(axis, boosting, delta)
	else:
		_update_direct_intent_motion(axis, boosting, delta)


func _update_steer_throttle_motion(axis: Vector2, boosting: bool, delta: float) -> void:
	_update_target_heading_from_input(axis, delta)

	var boundary_steer := _get_boundary_steer()
	boundary_energy = clampf(boundary_steer.length(), 0.0, 1.0)
	if boundary_energy > 0.0:
		target_heading = (target_heading + boundary_steer.normalized() * boundary_energy * BOUNDARY_HEADING_PULL).normalized()

	var previous_throttle := throttle_pressed
	throttle_pressed = boosting
	var boost_just_pressed := throttle_pressed and not previous_throttle
	if previous_throttle and not throttle_pressed and velocity.length() > HOVER_STOP_SPEED:
		slip_timer = SLIP_DURATION

	if carve_timer > 0.0:
		carve_timer = maxf(carve_timer - delta, 0.0)
	if hard_turn_request_timer > 0.0:
		hard_turn_request_timer = maxf(hard_turn_request_timer - delta, 0.0)

	var turn_delta := _signed_angle_between(body_heading, target_heading)
	var speed_ratio := clampf(velocity.length() / BOOST_SPEED, 0.0, 1.0)
	var turn_pressure := clampf(absf(turn_delta) / PI, 0.0, 1.0)
	var turn_rate := lerpf(HEADING_TURN_RATE, HARD_HEADING_TURN_RATE, turn_pressure)
	if not throttle_pressed:
		turn_rate = maxf(turn_rate, HOVER_HEADING_TURN_RATE)
	var angle_step := clampf(turn_delta, -turn_rate * delta, turn_rate * delta)
	body_heading = body_heading.rotated(angle_step).normalized()
	heading_turn_rate = absf(angle_step) / maxf(delta, 0.001)
	heading_angle_delta = _signed_angle_between(body_heading, target_heading)

	if boost_just_pressed:
		_start_boost_burst()

	if throttle_pressed and absf(turn_delta) >= HARD_TURN_MIN_ANGLE and velocity.length() >= HARD_TURN_MIN_SPEED and carve_timer <= 0.0:
		_begin_carve(signf(turn_delta))

	if throttle_pressed:
		var carve_ratio := clampf(carve_timer / CARVE_DURATION, 0.0, 1.0)
		var target_speed := BOOST_SPEED * lerpf(1.0, CARVE_SPEED_KEEP, carve_ratio)
		var target_velocity := body_heading * target_speed
		var acceleration := lerpf(ACCELERATION, BOOST_ACCELERATION, clampf(0.35 + speed_ratio, 0.0, 1.0))
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		if carve_ratio > 0.0 and carve_direction != 0.0:
			var carve_side := body_heading.rotated(carve_direction * PI * 0.5)
			velocity += carve_side * CARVE_SIDE_FORCE * carve_ratio * delta
	else:
		if slip_timer > 0.0:
			slip_timer = maxf(slip_timer - delta, 0.0)
			velocity = velocity.move_toward(Vector2.ZERO, SLIP_BRAKE * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, HOVER_BRAKE * delta)
			if velocity.length() <= HOVER_STOP_SPEED:
				velocity = Vector2.ZERO

	if boundary_energy > 0.0:
		var inward := boundary_steer.normalized()
		var return_speed := maxf(velocity.length(), CRUISE_SPEED * 0.45)
		velocity = velocity.move_toward(inward * return_speed, BOUNDARY_RETURN_ACCEL * boundary_energy * delta)

	flight_pos += velocity * delta
	_apply_boost_burst_delta(delta)
	_apply_boundary_failsafe()


func _update_direct_intent_motion(axis: Vector2, boosting: bool, delta: float) -> void:
	var previous_input_active := heading_input_active
	var input_active := axis.length_squared() > 0.01
	heading_input_active = input_active
	if input_active:
		heading_input = axis.normalized()

	var boundary_steer := _get_boundary_steer()
	boundary_energy = clampf(boundary_steer.length(), 0.0, 1.0)

	var previous_throttle := throttle_pressed
	throttle_pressed = boosting
	var boost_just_pressed := throttle_pressed and not previous_throttle
	if (previous_input_active and not input_active) or (previous_throttle and not throttle_pressed):
		if velocity.length() > HOVER_STOP_SPEED and not input_active and not throttle_pressed:
			slip_timer = SLIP_DURATION
	if input_active or throttle_pressed:
		slip_timer = 0.0

	if carve_timer > 0.0:
		carve_timer = maxf(carve_timer - delta, 0.0)
	if hard_turn_request_timer > 0.0:
		hard_turn_request_timer = maxf(hard_turn_request_timer - delta, 0.0)

	if input_active:
		var input_strength := clampf(axis.length(), 0.0, 1.0)
		_steer_target_heading_toward(heading_input, INPUT_HEADING_TURN_RATE, input_strength, delta)
	elif throttle_pressed:
		if velocity.length_squared() > 0.001:
			target_heading = velocity.normalized()
		else:
			target_heading = body_heading.normalized()
	elif velocity.length_squared() > 0.001:
		target_heading = velocity.normalized()

	if boundary_energy > 0.0:
		target_heading = (target_heading + boundary_steer.normalized() * boundary_energy * BOUNDARY_HEADING_PULL).normalized()

	var turn_delta := _signed_angle_between(body_heading, target_heading)
	var speed_ratio := clampf(velocity.length() / BOOST_SPEED, 0.0, 1.0)
	var turn_pressure := clampf(absf(turn_delta) / PI, 0.0, 1.0)
	var turn_rate := lerpf(DIRECT_BODY_TURN_RATE, DIRECT_HARD_BODY_TURN_RATE, turn_pressure)
	if not throttle_pressed or velocity.length() < CRUISE_SPEED * 0.35:
		turn_rate = maxf(turn_rate, HOVER_HEADING_TURN_RATE)
	var angle_step := clampf(turn_delta, -turn_rate * delta, turn_rate * delta)
	body_heading = body_heading.rotated(angle_step).normalized()
	heading_turn_rate = absf(angle_step) / maxf(delta, 0.001)
	heading_angle_delta = _signed_angle_between(body_heading, target_heading)

	if boost_just_pressed:
		_start_boost_burst()

	if input_active and velocity.length() >= HARD_TURN_MIN_SPEED and carve_timer <= 0.0:
		var velocity_turn_delta := _signed_angle_between(_safe_velocity_dir(), target_heading)
		if absf(velocity_turn_delta) >= HARD_TURN_MIN_ANGLE:
			_begin_carve(signf(velocity_turn_delta))

	if input_active or throttle_pressed:
		var carve_ratio := clampf(carve_timer / CARVE_DURATION, 0.0, 1.0)
		var target_speed := BOOST_SPEED if throttle_pressed else CRUISE_SPEED
		target_speed *= lerpf(1.0, CARVE_SPEED_KEEP, carve_ratio)
		var target_velocity := target_heading * target_speed
		var throttle_ratio := 1.0 if throttle_pressed else 0.0
		var acceleration := lerpf(DIRECT_CRUISE_ACCELERATION, DIRECT_BOOST_ACCELERATION, clampf(throttle_ratio + speed_ratio * 0.35, 0.0, 1.0))
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		if carve_ratio > 0.0 and carve_direction != 0.0:
			var carve_side := body_heading.rotated(carve_direction * PI * 0.5)
			velocity += carve_side * CARVE_SIDE_FORCE * carve_ratio * delta
	else:
		if slip_timer > 0.0:
			slip_timer = maxf(slip_timer - delta, 0.0)
			velocity = velocity.move_toward(Vector2.ZERO, SLIP_BRAKE * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, HOVER_BRAKE * delta)
			if velocity.length() <= HOVER_STOP_SPEED:
				velocity = Vector2.ZERO

	if boundary_energy > 0.0:
		var inward := boundary_steer.normalized()
		var return_speed := maxf(velocity.length(), CRUISE_SPEED * 0.45)
		velocity = velocity.move_toward(inward * return_speed, BOUNDARY_RETURN_ACCEL * boundary_energy * delta)

	flight_pos += velocity * delta
	_apply_boost_burst_delta(delta)
	_apply_boundary_failsafe()


func _start_boost_burst() -> void:
	var burst_dir := _get_boost_burst_direction()
	if burst_dir.length_squared() <= 0.0001:
		return
	boost_burst_direction = burst_dir.normalized()
	boost_burst_timer = maxf(前冲时长, 0.001)
	velocity = boost_burst_direction * maxf(velocity.length(), BOOST_SPEED)
	boost_energy = maxf(boost_energy, 0.95)
	throttle_energy = maxf(throttle_energy, 0.82)
	_spawn_boost_shockwave(boost_burst_direction)
	_spawn_boost_burst_streaks(boost_burst_direction)
	_capture_afterimage(flight_pos - boost_burst_direction * 34.0, 1.0)
	_capture_afterimage(flight_pos - boost_burst_direction * 84.0, 0.72)


func _get_boost_burst_direction() -> Vector2:
	if velocity.length() < CRUISE_SPEED * 0.25 and heading_input_active and heading_input.length_squared() > 0.0001:
		return heading_input.normalized()
	if body_heading.length_squared() > 0.0001:
		return body_heading.normalized()
	if target_heading.length_squared() > 0.0001:
		return target_heading.normalized()
	return _safe_velocity_dir()


func _apply_boost_burst_delta(delta: float) -> void:
	if boost_burst_timer <= 0.0 or boost_burst_direction.length_squared() <= 0.0001:
		return
	var previous_timer := boost_burst_timer
	boost_burst_timer = maxf(boost_burst_timer - delta, 0.0)
	var safe_duration := maxf(前冲时长, 0.001)
	var before := clampf(1.0 - previous_timer / safe_duration, 0.0, 1.0)
	var after := clampf(1.0 - boost_burst_timer / safe_duration, 0.0, 1.0)
	var distance_delta := 前冲距离 * (_ease_out_cubic(after) - _ease_out_cubic(before))
	flight_pos += boost_burst_direction.normalized() * distance_delta


func _update_target_heading_from_input(axis: Vector2, delta: float) -> void:
	heading_input_active = axis.length_squared() > 0.01
	if not heading_input_active:
		return
	heading_input = axis.normalized()
	var input_strength := clampf(axis.length(), 0.0, 1.0)
	_steer_target_heading_toward(heading_input, INPUT_HEADING_TURN_RATE, input_strength, delta)


func _steer_target_heading_toward(desired_heading: Vector2, turn_rate: float, strength: float, delta: float) -> void:
	if desired_heading.length_squared() <= 0.0001:
		return
	if target_heading.length_squared() <= 0.0001:
		target_heading = body_heading.normalized() if body_heading.length_squared() > 0.0001 else Vector2.RIGHT
	var safe_desired := desired_heading.normalized()
	var safe_strength := clampf(strength, 0.0, 1.0)
	var turn_delta := _signed_angle_between(target_heading, safe_desired)
	var angle_step := clampf(turn_delta, -turn_rate * safe_strength * delta, turn_rate * safe_strength * delta)
	target_heading = target_heading.rotated(angle_step).normalized()


func _update_speed_mode() -> void:
	var speed := velocity.length()
	if speed_mode == SPEED_MODE_CRUISE and speed >= BOOST_ENTER_SPEED:
		speed_mode = SPEED_MODE_BOOST
	elif speed_mode == SPEED_MODE_BOOST and speed <= BOOST_EXIT_SPEED:
		speed_mode = SPEED_MODE_CRUISE


func _update_visual_state(delta: float) -> void:
	visual_pos = flight_pos
	_update_visual_heading(delta)
	var speed_ratio := clampf((velocity.length() - CRUISE_SPEED) / maxf(BOOST_SPEED - CRUISE_SPEED, 1.0), 0.0, 1.0)
	var boost_target := maxf(speed_ratio, 0.55 if throttle_pressed else 0.0)
	var turn_target := clampf(absf(heading_angle_delta) / 1.35, 0.0, 1.0) * clampf(velocity.length() / CRUISE_SPEED, 0.0, 1.0)
	if _is_turn_clip():
		turn_target = maxf(turn_target, 0.72)
	var carve_target := clampf(carve_timer / CARVE_DURATION, 0.0, 1.0)
	turn_target = maxf(turn_target, carve_target)
	boost_energy = _damp_float(boost_energy, boost_target, 0.09, delta)
	turn_energy = _damp_float(turn_energy, turn_target, 0.06, delta)
	direction_switch_energy = _damp_float(direction_switch_energy, 0.0, DIRECTION_SWITCH_ENERGY_HALF_LIFE, delta)
	throttle_energy = _damp_float(throttle_energy, 1.0 if throttle_pressed else 0.0, 0.08, delta)
	slip_energy = _damp_float(slip_energy, clampf(slip_timer / SLIP_DURATION, 0.0, 1.0), 0.05, delta)
	carve_energy = _damp_float(carve_energy, carve_target, 0.045, delta)
	_apply_sprite_transform(delta)


func _update_visual_heading(delta: float) -> void:
	var target := body_heading
	if target.length_squared() <= 0.0001:
		target = Vector2.RIGHT
	else:
		target = target.normalized()
	if visual_heading.length_squared() <= 0.0001:
		visual_heading = target
		return
	var angle_delta := _signed_angle_between(visual_heading, target)
	var turn_pressure := clampf(absf(angle_delta) / PI, 0.0, 1.0)
	var turn_rate := lerpf(VISUAL_HEADING_TURN_RATE, VISUAL_HEADING_HARD_TURN_RATE, turn_pressure)
	if velocity.length() < CRUISE_SPEED * 0.35 or not throttle_pressed:
		turn_rate = maxf(turn_rate, VISUAL_HEADING_HOVER_TURN_RATE)
	var angle_step := clampf(angle_delta, -turn_rate * delta, turn_rate * delta)
	visual_heading = visual_heading.rotated(angle_step).normalized()


func _apply_sprite_transform(delta := 0.0) -> void:
	if sprite_root == null or character_sprite == null:
		return
	var use_static_direction_pose := false
	if USE_GEMINI_8WAY_CRUISE:
		if _is_v3_top_turn_clip():
			eight_way_index = _v3_two_way_index_from_sign(turn_from_sign)
			eight_way_local_rotation = _get_eight_way_local_rotation(visual_heading, eight_way_index)
			use_static_direction_pose = true
		elif _use_v1_sequence_visual():
			use_static_direction_pose = _apply_v1_hybrid_texture(visual_heading)
		else:
			_apply_eight_way_texture(visual_heading)
			use_static_direction_pose = true
	if use_static_direction_pose:
		sprite_root.position = _world_to_screen(visual_pos)
		sprite_root.rotation = 0.0
		sprite_root.scale = Vector2.ONE / maxf(camera_zoom, 0.001)
		var turn_lean := clampf(heading_angle_delta / 1.4, -1.0, 1.0)
		var target_direction_scale := _get_eight_way_direction_scale(eight_way_character_set, eight_way_index)
		var target_offset := _get_eight_way_direction_offset(eight_way_character_set, eight_way_index)
		_update_eight_way_visual_adjustments(target_offset, target_direction_scale, delta)
		if _uses_skeleton_eight_way():
			_apply_skeleton_eight_way_transform(delta, turn_lean)
			return
		if _uses_ink_part_eight_way():
			_apply_ink_part_eight_way_transform(delta, turn_lean)
			return
		if _uses_google_part_eight_way():
			_apply_google_part_eight_way_transform(delta, turn_lean)
			return
		if character_sprite != null:
			character_sprite.visible = true
		if skeleton_character != null:
			skeleton_character.visible = false
		if ink_part_character != null:
			ink_part_character.visible = false
		if google_part_character != null:
			google_part_character.visible = false
		var adjustment_scale := _get_eight_way_global_scale(eight_way_character_set) * eight_way_visual_direction_scale
		var switch_side := visual_heading.rotated(direction_switch_direction * PI * 0.5)
		var switch_offset := (-visual_heading * 5.0 + switch_side * 4.0) * direction_switch_energy
		var sprite_scale := GEMINI_EIGHT_WAY_SCALE * adjustment_scale * (1.0 + 0.035 * boost_energy + 0.035 * carve_energy)
		var scale_x := sprite_scale * (1.0 + 0.035 * direction_switch_energy)
		var scale_y := sprite_scale * (1.0 - 0.022 * direction_switch_energy)
		character_sprite.position = GEMINI_POSE_OFFSET + eight_way_visual_offset + Vector2(0.0, -3.0 * boost_energy - 2.0 * carve_energy) + switch_offset
		character_sprite.rotation = eight_way_local_rotation - turn_lean * 0.035 + carve_direction * carve_energy * 0.045 + direction_switch_direction * direction_switch_energy * 0.055
		character_sprite.scale = Vector2(scale_x, scale_y)
		return
	sprite_root.position = _world_to_screen(visual_pos)
	sprite_root.rotation = _visual_root_rotation()
	sprite_root.scale = Vector2.ONE / maxf(camera_zoom, 0.001)
	var climb_lean := clampf(-body_heading.y, -1.0, 1.0)
	var turn_lean := clampf(heading_angle_delta / 1.4, -1.0, 1.0)
	var scale_x := SPRITE_SCALE * (1.0 + 0.04 * boost_energy + 0.055 * carve_energy)
	var scale_y := SPRITE_SCALE * (1.0 - 0.025 * boost_energy - 0.035 * carve_energy)
	character_sprite.position = POSE_OFFSET + Vector2(-8.0 * boost_energy - 5.0 * carve_energy, -5.0 * climb_lean)
	character_sprite.rotation = climb_lean * 0.08 - turn_lean * 0.10 + carve_direction * carve_energy * 0.08
	character_sprite.scale = Vector2(render_sign * SHEET_FACE_SIGN * scale_x, scale_y)


func _apply_skeleton_eight_way_transform(delta: float, turn_lean: float) -> void:
	if skeleton_character == null:
		return
	if character_sprite != null:
		character_sprite.visible = false
	if ink_part_character != null:
		ink_part_character.visible = false
	if google_part_character != null:
		google_part_character.visible = false
	skeleton_character.visible = true
	var adjustment_scale := _get_eight_way_global_scale(eight_way_character_set) * eight_way_visual_direction_scale
	var skeleton_scale := SKELETON_EIGHT_WAY_SCALE * skeleton_size_scale * adjustment_scale * (1.0 + 0.045 * boost_energy + 0.03 * carve_energy)
	skeleton_character.position = SKELETON_POSE_OFFSET + eight_way_visual_offset + Vector2(0.0, -4.0 * boost_energy - 2.0 * carve_energy)
	skeleton_character.rotation = 0.0
	skeleton_character.scale = Vector2.ONE * skeleton_scale
	if skeleton_character.has_method("set_flight_pose"):
		skeleton_character.call(
			"set_flight_pose",
			_get_skeleton_direction_index(eight_way_index),
			visual_heading,
			velocity,
			boost_energy,
			turn_energy,
			carve_energy,
			throttle_energy,
			delta
		)


func _apply_ink_part_eight_way_transform(delta: float, turn_lean: float) -> void:
	if ink_part_character == null:
		return
	if character_sprite != null:
		character_sprite.visible = false
	if skeleton_character != null:
		skeleton_character.visible = false
	if google_part_character != null:
		google_part_character.visible = false
	ink_part_character.visible = true
	var adjustment_scale := _get_eight_way_global_scale(eight_way_character_set) * eight_way_visual_direction_scale
	var ink_scale := INK_PART_EIGHT_WAY_SCALE * skeleton_size_scale * adjustment_scale * (1.0 + 0.055 * boost_energy + 0.035 * carve_energy)
	var switch_side := visual_heading.rotated(direction_switch_direction * PI * 0.5)
	var switch_offset := (-visual_heading * 4.0 + switch_side * 5.0) * direction_switch_energy
	ink_part_character.position = SKELETON_POSE_OFFSET + eight_way_visual_offset + Vector2(0.0, -5.0 * boost_energy - 2.0 * carve_energy) + switch_offset
	ink_part_character.rotation = -turn_lean * 0.025 + carve_direction * carve_energy * 0.035 + direction_switch_direction * direction_switch_energy * 0.035
	ink_part_character.scale = Vector2.ONE * ink_scale
	if ink_part_character.has_method("set_flight_pose"):
		ink_part_character.call(
			"set_flight_pose",
			eight_way_index,
			visual_heading,
			velocity,
			boost_energy,
			turn_energy,
			carve_energy,
			throttle_energy,
			delta
		)


func _apply_google_part_eight_way_transform(delta: float, turn_lean: float) -> void:
	if google_part_character == null:
		return
	if character_sprite != null:
		character_sprite.visible = false
	if skeleton_character != null:
		skeleton_character.visible = false
	if ink_part_character != null:
		ink_part_character.visible = false
	if google_part_character.has_method("set_part_set_root"):
		google_part_character.call("set_part_set_root", _google_part_root_path())
	google_part_character.visible = true
	var adjustment_scale := _get_eight_way_global_scale(eight_way_character_set) * eight_way_visual_direction_scale
	var google_scale := GOOGLE_PARTS_EIGHT_WAY_SCALE * skeleton_size_scale * adjustment_scale * (1.0 + 0.035 * boost_energy + 0.025 * carve_energy)
	var switch_side := visual_heading.rotated(direction_switch_direction * PI * 0.5)
	var switch_offset := (-visual_heading * 4.0 + switch_side * 4.5) * direction_switch_energy
	google_part_character.position = SKELETON_POSE_OFFSET + eight_way_visual_offset + Vector2(0.0, -4.0 * boost_energy - 2.0 * carve_energy) + switch_offset
	google_part_character.rotation = -turn_lean * 0.018 + carve_direction * carve_energy * 0.030 + direction_switch_direction * direction_switch_energy * 0.030
	google_part_character.scale = Vector2.ONE * google_scale
	if google_part_character.has_method("set_flight_pose"):
		google_part_character.call(
			"set_flight_pose",
			eight_way_index,
			visual_heading,
			velocity,
			boost_energy,
			turn_energy,
			carve_energy,
			throttle_energy,
			delta
		)


func _is_skeleton_pose_editor_active() -> bool:
	return _uses_skeleton_eight_way() and skeleton_character != null and skeleton_character.has_method("is_pose_editor_active") and bool(skeleton_character.call("is_pose_editor_active"))


func _update_eight_way_visual_adjustments(target_offset: Vector2, target_direction_scale: float, delta: float) -> void:
	if not eight_way_visual_adjustments_initialized or delta <= 0.0:
		eight_way_visual_offset = target_offset
		eight_way_visual_direction_scale = target_direction_scale
		eight_way_visual_adjustments_initialized = true
		return
	eight_way_visual_offset = _damp_vector2(eight_way_visual_offset, target_offset, EIGHT_WAY_ADJUSTMENT_HALF_LIFE, delta)
	eight_way_visual_direction_scale = _damp_float(eight_way_visual_direction_scale, target_direction_scale, EIGHT_WAY_ADJUSTMENT_HALF_LIFE, delta)


func _apply_eight_way_texture(heading: Vector2) -> void:
	if _uses_procedural_eight_way():
		var procedural_next_index := _get_eight_way_index_with_hysteresis(heading)
		var direction_changed := eight_way_texture_initialized and procedural_next_index != eight_way_index
		if direction_changed and (_uses_ink_part_eight_way() or _uses_google_part_eight_way()):
			_trigger_eight_way_direction_switch(eight_way_index, procedural_next_index)
		eight_way_index = procedural_next_index
		eight_way_local_rotation = _get_eight_way_local_rotation(heading, procedural_next_index)
		eight_way_texture_initialized = true
		return
	if eight_way_textures.is_empty():
		return
	var next_index := _get_v3_two_way_index() if _uses_v3_face_eight_way() else _get_eight_way_index_with_hysteresis(heading)
	var direction_changed := eight_way_texture_initialized and next_index != eight_way_index
	if direction_changed:
		_trigger_eight_way_direction_switch(eight_way_index, next_index)
	eight_way_index = next_index
	eight_way_local_rotation = _get_eight_way_local_rotation(heading, next_index)
	var texture := eight_way_textures[next_index] as Texture2D
	if texture == null:
		return
	eight_way_texture_initialized = true
	if character_sprite.texture == texture and not character_sprite.region_enabled:
		return
	character_sprite.texture = texture
	character_sprite.region_enabled = false
	character_sprite.region_rect = Rect2(Vector2.ZERO, texture.get_size())


func _apply_v1_hybrid_texture(heading: Vector2) -> bool:
	var next_index := _get_eight_way_index_with_hysteresis(heading)
	var direction_changed := eight_way_texture_initialized and next_index != eight_way_index
	if direction_changed:
		_trigger_eight_way_direction_switch(eight_way_index, next_index)
	eight_way_index = next_index
	eight_way_local_rotation = _get_eight_way_local_rotation(heading, next_index)
	eight_way_texture_initialized = true
	if _is_v1_sequence_sheet_index(next_index):
		if sheet_texture != null:
			character_sprite.texture = sheet_texture
			character_sprite.region_enabled = true
			character_sprite.region_rect = _get_frame_rect(frame_index)
		return false
	if eight_way_textures.is_empty():
		return false
	var texture := eight_way_textures[next_index] as Texture2D
	if texture == null:
		return false
	character_sprite.texture = texture
	character_sprite.region_enabled = false
	character_sprite.region_rect = Rect2(Vector2.ZERO, texture.get_size())
	return true


func _trigger_eight_way_direction_switch(previous_index: int, next_index: int) -> void:
	var previous_direction: Vector2 = GEMINI_EIGHT_WAY_VECTORS[clampi(previous_index, 0, GEMINI_EIGHT_WAY_VECTORS.size() - 1)].normalized()
	var next_direction: Vector2 = GEMINI_EIGHT_WAY_VECTORS[clampi(next_index, 0, GEMINI_EIGHT_WAY_VECTORS.size() - 1)].normalized()
	var signed_switch_angle := _signed_angle_between(previous_direction, next_direction)
	var switch_direction := signf(signed_switch_angle)
	if switch_direction == 0.0:
		switch_direction = signf(direction_switch_direction) if direction_switch_direction != 0.0 else 1.0
	var angle_pressure := clampf(absf(signed_switch_angle) / (PI * 0.75), 0.0, 1.0)
	var intent_pressure := clampf(absf(heading_angle_delta) / PI, 0.0, 1.0)
	var speed_pressure := clampf((velocity.length() - CRUISE_SPEED * 0.35) / maxf(BOOST_SPEED - CRUISE_SPEED * 0.35, 1.0), 0.0, 1.0)
	var switch_strength := clampf(maxf(angle_pressure, intent_pressure) * lerpf(0.68, 1.0, speed_pressure) + carve_energy * 0.45, 0.34, 1.0)
	direction_switch_direction = switch_direction
	direction_switch_energy = maxf(direction_switch_energy, switch_strength)
	turn_energy = maxf(turn_energy, switch_strength * 0.45)
	_capture_eight_way_switch_ghost(switch_strength)
	_spawn_direction_switch_arc(previous_direction, next_direction, switch_direction, switch_strength)


func _spawn_direction_switch_arc(previous_direction: Vector2, next_direction: Vector2, switch_direction: float, switch_strength: float) -> void:
	var radius := lerpf(DIRECTION_SWITCH_ARC_RADIUS, DIRECTION_SWITCH_ARC_HARD_RADIUS, switch_strength)
	var life := lerpf(DIRECTION_SWITCH_FX_LIFE, DIRECTION_SWITCH_FX_HARD_LIFE, switch_strength)
	direction_switch_fx.append({
		"center": visual_pos,
		"old_dir": previous_direction,
		"new_dir": next_direction,
		"direction": switch_direction,
		"radius": radius,
		"age": 0.0,
		"life": life,
		"strength": switch_strength,
		"velocity": velocity,
	})
	while direction_switch_fx.size() > DIRECTION_SWITCH_MAX_ARCS:
		direction_switch_fx.pop_front()


func _capture_eight_way_switch_ghost(switch_strength := 0.5) -> void:
	if _uses_procedural_eight_way():
		return
	if character_sprite == null or character_sprite.texture == null:
		return
	var texture := character_sprite.texture
	var source := Rect2(Vector2.ZERO, texture.get_size())
	if character_sprite.region_enabled:
		source = character_sprite.region_rect
	var ghost_life := lerpf(EIGHT_WAY_SWITCH_GHOST_LIFE, DIRECTION_SWITCH_FX_HARD_LIFE * 0.58, switch_strength)
	afterimages.append({
		"texture": texture,
		"source": source,
		"pos": visual_pos,
		"screen_offset": character_sprite.position,
		"scale": character_sprite.scale.abs(),
		"facing": 1.0,
		"rotation": character_sprite.rotation,
		"age": 0.0,
		"life": ghost_life,
		"intensity": lerpf(0.78, 1.18, switch_strength),
		"alpha": lerpf(0.10, 0.18, switch_strength),
		"velocity": velocity * lerpf(0.26, 0.52, switch_strength),
	})


func _get_eight_way_index(heading: Vector2) -> int:
	var safe_heading := heading
	if safe_heading.length_squared() <= 0.0001:
		safe_heading = Vector2.RIGHT
	else:
		safe_heading = safe_heading.normalized()
	var best_index := 0
	var best_dot := -9999.0
	for index in range(GEMINI_EIGHT_WAY_VECTORS.size()):
		var direction: Vector2 = GEMINI_EIGHT_WAY_VECTORS[index]
		var dot_value := safe_heading.dot(direction.normalized())
		if dot_value > best_dot:
			best_dot = dot_value
			best_index = index
	return best_index


func _get_eight_way_index_with_hysteresis(heading: Vector2) -> int:
	var nearest_index := _get_eight_way_index(heading)
	if nearest_index == eight_way_index:
		return nearest_index
	if eight_way_index < 0 or eight_way_index >= GEMINI_EIGHT_WAY_VECTORS.size():
		return nearest_index
	var safe_heading := heading
	if safe_heading.length_squared() <= 0.0001:
		safe_heading = Vector2.RIGHT
	else:
		safe_heading = safe_heading.normalized()
	var current_direction: Vector2 = GEMINI_EIGHT_WAY_VECTORS[eight_way_index].normalized()
	var nearest_direction: Vector2 = GEMINI_EIGHT_WAY_VECTORS[nearest_index].normalized()
	var current_error := absf(_signed_angle_between(current_direction, safe_heading))
	var nearest_error := absf(_signed_angle_between(nearest_direction, safe_heading))
	if current_error <= nearest_error + EIGHT_WAY_SWITCH_HYSTERESIS:
		return eight_way_index
	return nearest_index


func _get_skeleton_direction_index(direction_index: int) -> int:
	if SKELETON_CARDINAL_DIRECTION_INDICES.is_empty():
		return direction_index
	var safe_index := clampi(direction_index, 0, SKELETON_CARDINAL_DIRECTION_INDICES.size() - 1)
	return int(SKELETON_CARDINAL_DIRECTION_INDICES[safe_index])


func _get_v3_two_way_index() -> int:
	return _v3_two_way_index_from_sign(facing_sign)


func _v3_two_way_index_from_sign(source_sign: float) -> int:
	return 0 if source_sign >= 0.0 else 2


func _get_eight_way_local_rotation(heading: Vector2, index: int) -> float:
	if index < 0 or index >= GEMINI_EIGHT_WAY_VECTORS.size():
		return 0.0
	var safe_heading := heading
	if safe_heading.length_squared() <= 0.0001:
		return 0.0
	safe_heading = safe_heading.normalized()
	var base_direction: Vector2 = GEMINI_EIGHT_WAY_VECTORS[index].normalized()
	var rotation_limit := V3_TWO_WAY_LOCAL_ROTATION_LIMIT if _uses_v3_face_eight_way() else EIGHT_WAY_LOCAL_ROTATION_LIMIT
	return clampf(_signed_angle_between(base_direction, safe_heading), -rotation_limit, rotation_limit)


func _current_eight_way_name() -> String:
	if GEMINI_EIGHT_WAY_NAMES.is_empty():
		return "none"
	return String(GEMINI_EIGHT_WAY_NAMES[clampi(eight_way_index, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)])


func _current_eight_way_set_label() -> String:
	if GEMINI_EIGHT_WAY_SET_LABELS.is_empty():
		return "unknown"
	return String(GEMINI_EIGHT_WAY_SET_LABELS[clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_SET_LABELS.size() - 1)])


func _use_v1_sequence_visual() -> bool:
	return USE_GEMINI_8WAY_CRUISE and eight_way_character_set == EIGHT_WAY_SET_V1


func _is_v1_sequence_sheet_index(index: int) -> bool:
	return index == 0 or index == 2


func _is_v3_two_way_direction_index(index: int) -> bool:
	return index == 0 or index == 2


func _use_v1_static_direction_visual() -> bool:
	return _use_v1_sequence_visual() and not _is_v1_sequence_sheet_index(eight_way_index)


func _apply_frame() -> void:
	if character_sprite == null:
		return
	if USE_GEMINI_8WAY_CRUISE and not _is_v3_top_turn_clip() and (not _use_v1_sequence_visual() or _use_v1_static_direction_visual()):
		return
	character_sprite.region_enabled = true
	character_sprite.region_rect = _get_current_frame_rect()


func _get_current_frame_rect() -> Rect2:
	var clip := _current_clip()
	var source_frame := frame_index
	var source_frames: Array = clip.get("source_frames", [])
	if not source_frames.is_empty():
		var order_index := clampi(frame_index, 0, source_frames.size() - 1)
		if _is_v3_top_turn_clip() and v3_top_turn_reverse:
			order_index = source_frames.size() - 1 - order_index
		source_frame = int(source_frames[order_index])
	elif _is_v3_top_turn_clip() and v3_top_turn_reverse:
		source_frame = int(clip["frames"]) - 1 - frame_index
	var columns := int(clip.get("columns", FRAME_COLUMNS))
	return _get_frame_rect(source_frame, columns)


func _get_frame_rect(index: int, columns: int = FRAME_COLUMNS) -> Rect2:
	var safe_columns := maxi(columns, 1)
	var column := index % safe_columns
	var row := int(floor(float(index) / float(safe_columns)))
	return Rect2(Vector2(column, row) * CELL_SIZE, CELL_SIZE)


func _get_move_axis() -> Vector2:
	if _is_skeleton_pose_editor_active():
		return Vector2.ZERO
	var manual_axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var arrow_axis := Vector2(
		float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	)
	if arrow_axis.length_squared() > 1.0:
		arrow_axis = arrow_axis.normalized()
	manual_axis += arrow_axis
	if manual_axis.length_squared() > 1.0:
		manual_axis = manual_axis.normalized()
	if auto_demo and (manual_axis.length_squared() > 0.01 or Input.is_action_pressed("dash")):
		auto_demo = false
	if auto_demo:
		var x := cos(time * 0.72)
		var y := sin(time * 1.08) * 0.64
		return Vector2(x, y).normalized()
	return manual_axis.normalized() if manual_axis.length_squared() > 1.0 else manual_axis


func _is_boost_pressed() -> bool:
	if _is_skeleton_pose_editor_active():
		return false
	return auto_demo or Input.is_action_pressed("dash")


func _clip_phase() -> float:
	var clip := _current_clip()
	var frame_count := maxi(int(clip["frames"]) - 1, 1)
	return clampf(float(frame_index) / float(frame_count), 0.0, 1.0)


func _should_use_hard_turn() -> bool:
	return speed_mode == SPEED_MODE_BOOST or _is_hard_turn_clip()


func _begin_carve(direction: float) -> void:
	carve_direction = signf(direction)
	if carve_direction == 0.0:
		carve_direction = 1.0
	carve_timer = CARVE_DURATION
	hard_turn_request_timer = 0.12
	_capture_afterimage(flight_pos - _safe_velocity_dir() * 36.0, 0.92)
	_capture_afterimage(flight_pos - _safe_velocity_dir() * 72.0 + body_heading.rotated(carve_direction * PI * 0.5) * 10.0, 0.64)


func _signed_angle_between(from_dir: Vector2, to_dir: Vector2) -> float:
	if from_dir.length_squared() <= 0.0001 or to_dir.length_squared() <= 0.0001:
		return 0.0
	return wrapf(to_dir.angle() - from_dir.angle(), -PI, PI)


func _heading_render_sign(heading: Vector2, fallback_sign: float) -> float:
	if absf(heading.x) > 0.18:
		return signf(heading.x)
	return signf(fallback_sign) if fallback_sign != 0.0 else 1.0


func _render_rotation() -> float:
	var base_angle := body_heading.angle()
	if render_sign < 0.0:
		return wrapf(base_angle - PI, -PI, PI)
	return base_angle


func _visual_root_rotation() -> float:
	if bool(_current_clip().get("self_turn", false)):
		return 0.0
	return _render_rotation()


func _get_boundary_steer() -> Vector2:
	var steer := Vector2.ZERO
	var left_distance := flight_pos.x - PLAY_RECT.position.x
	var right_distance := PLAY_RECT.end.x - flight_pos.x
	var top_distance := flight_pos.y - PLAY_RECT.position.y
	var bottom_distance := PLAY_RECT.end.y - flight_pos.y
	if left_distance < BOUNDARY_SOFT_MARGIN:
		steer.x += 1.0 - clampf(left_distance / BOUNDARY_SOFT_MARGIN, 0.0, 1.0)
	if right_distance < BOUNDARY_SOFT_MARGIN:
		steer.x -= 1.0 - clampf(right_distance / BOUNDARY_SOFT_MARGIN, 0.0, 1.0)
	if top_distance < BOUNDARY_SOFT_MARGIN:
		steer.y += 1.0 - clampf(top_distance / BOUNDARY_SOFT_MARGIN, 0.0, 1.0)
	if bottom_distance < BOUNDARY_SOFT_MARGIN:
		steer.y -= 1.0 - clampf(bottom_distance / BOUNDARY_SOFT_MARGIN, 0.0, 1.0)
	return steer.limit_length(1.0)


func _apply_boundary_failsafe() -> void:
	var min_pos := PLAY_RECT.position
	var max_pos := PLAY_RECT.end
	if flight_pos.x < min_pos.x:
		flight_pos.x = min_pos.x
		velocity.x = absf(velocity.x) * 0.36
	elif flight_pos.x > max_pos.x:
		flight_pos.x = max_pos.x
		velocity.x = -absf(velocity.x) * 0.36
	if flight_pos.y < min_pos.y:
		flight_pos.y = min_pos.y
		velocity.y = absf(velocity.y) * 0.36
	elif flight_pos.y > max_pos.y:
		flight_pos.y = max_pos.y
		velocity.y = -absf(velocity.y) * 0.36


func _is_clip_looping() -> bool:
	return bool(_current_clip()["loop"])


func _is_turn_clip() -> bool:
	return clip_index == CLIP_CRUISE_TURN or _is_v3_top_turn_clip() or _is_hard_turn_clip()


func _is_hard_turn_clip() -> bool:
	return clip_index == CLIP_HARD_TURN_CORE or clip_index == CLIP_HARD_TURN_TO_BOOST or clip_index == CLIP_HARD_TURN_TO_CRUISE


func _is_v3_top_turn_clip() -> bool:
	return clip_index == CLIP_V3_TOP_TURN and _uses_v3_face_eight_way()


func _current_clip() -> Dictionary:
	return CLIPS[clip_index]


func _update_camera(delta: float) -> void:
	var speed_zoom_pressure := clampf((velocity.length() - CRUISE_SPEED * 0.55) / maxf(BOOST_SPEED - CRUISE_SPEED * 0.55, 1.0), 0.0, 1.0)
	var boost_zoom_pressure := 0.55 if throttle_pressed else 0.0
	var zoom_target := lerpf(CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM, maxf(speed_zoom_pressure, boost_zoom_pressure))
	camera_zoom = _damp_float(camera_zoom, zoom_target, CAMERA_ZOOM_HALF_LIFE, delta)
	var turn_pressure := clampf(maxf(maxf(absf(heading_angle_delta) / PI, carve_energy), direction_switch_energy), 0.0, 1.0)
	var look_ahead_scale := lerpf(1.0, camera_hard_turn_look_ahead_scale, turn_pressure)
	var target_look_ahead := velocity * camera_look_ahead_time * look_ahead_scale
	target_look_ahead.x = clampf(target_look_ahead.x, -camera_max_look_ahead.x, camera_max_look_ahead.x)
	target_look_ahead.y = clampf(target_look_ahead.y, -camera_max_look_ahead.y, camera_max_look_ahead.y)
	if delta <= 0.0:
		camera_look_ahead = target_look_ahead
	else:
		camera_look_ahead = _damp_vector2(camera_look_ahead, target_look_ahead, camera_look_ahead_half_life, delta)
	camera_center = _clamp_camera_center(flight_pos + camera_look_ahead)


func _update_reference_vfx(delta: float) -> void:
	if reference_vfx_viewport == null:
		return
	var speed_pressure := clampf((velocity.length() - CRUISE_SPEED * SCENE_WIND_MIN_SPEED) / maxf(BOOST_SPEED - CRUISE_SPEED * SCENE_WIND_MIN_SPEED, 1.0), 0.0, 1.0)
	var turn_pressure := clampf(maxf(carve_energy, maxf(direction_switch_energy * 0.82, absf(heading_angle_delta) / PI * clampf(velocity.length() / BOOST_SPEED, 0.0, 1.0))), 0.0, 1.0)
	_update_reference_wind(speed_pressure, turn_pressure, delta)
	_update_reference_fog_cards(speed_pressure, delta)


func _update_reference_wind(speed_pressure: float, turn_pressure: float, delta: float) -> void:
	if reference_wind_ribbons.is_empty():
		return
	var wind_energy := clampf(maxf(speed_pressure, throttle_energy * 0.68), 0.0, 1.0)
	var travel_dir := _safe_velocity_dir()
	var desired_wind_2d := Vector2(-travel_dir.x, travel_dir.y).normalized()
	var target_rotation := wrapf(desired_wind_2d.angle() - PI, -PI, PI)
	if not reference_wind_initialized:
		reference_wind_initialized = true
		reference_wind_rotation = target_rotation
		reference_wind_target_rotation = target_rotation
		for i in range(reference_wind_ribbons.size()):
			reference_wind_segment_rotations[i] = target_rotation
			reference_wind_ribbons[i].rotation.z = target_rotation

	var should_emit := wind_energy > 0.06
	var frame_rotation_delta := absf(wrapf(target_rotation - reference_wind_target_rotation, -PI, PI))
	var active_course_delta := absf(wrapf(target_rotation - reference_wind_rotation, -PI, PI)) if reference_wind_emitting else 0.0
	reference_wind_target_rotation = target_rotation
	var body_dir := body_heading.normalized() if body_heading.length_squared() > 0.0001 else travel_dir
	var target_dir := target_heading.normalized() if target_heading.length_squared() > 0.0001 else body_dir
	var velocity_body_delta := absf(_signed_angle_between(travel_dir, body_dir))
	var velocity_target_delta := absf(_signed_angle_between(travel_dir, target_dir))
	var course_unstable := (
		absf(heading_angle_delta) > REFERENCE_WIND_HEADING_SETTLE_ANGLE
		or heading_turn_rate > REFERENCE_WIND_HEADING_RATE_LIMIT
		or velocity_body_delta > REFERENCE_WIND_VELOCITY_ALIGN_ANGLE
		or velocity_target_delta > REFERENCE_WIND_VELOCITY_ALIGN_ANGLE
	)
	var is_turning := (
		turn_pressure > REFERENCE_WIND_TURN_SUPPRESS_PRESSURE
		or frame_rotation_delta > REFERENCE_WIND_STABLE_ANGLE
		or active_course_delta > REFERENCE_WIND_STABLE_ANGLE
		or course_unstable
	)
	if not should_emit:
		_stop_reference_wind_emission()
		reference_wind_stable_time = 0.0
		_fade_reference_wind_segments(-1, 0.0, delta)
		return

	if is_turning:
		_stop_reference_wind_emission()
		reference_wind_stable_time = 0.0
		_fade_reference_wind_segments(-1, 0.0, delta)
		return

	reference_wind_stable_time += delta
	if reference_wind_stable_time < REFERENCE_WIND_REAPPEAR_STABLE_TIME:
		_stop_reference_wind_emission()
		_fade_reference_wind_segments(-1, 0.0, delta)
		return

	if not reference_wind_emitting:
		reference_wind_current_index = _find_reference_wind_reuse_index()
		reference_wind_segment_energy[reference_wind_current_index] = 0.0
		_activate_reference_wind_segment(reference_wind_current_index, target_rotation, true)
		reference_wind_emitting = true
	else:
		reference_wind_segment_rotations[reference_wind_current_index] = reference_wind_rotation

	_fade_reference_wind_segments(reference_wind_current_index, wind_energy, delta)


func _stop_reference_wind_emission() -> void:
	if not reference_wind_emitting:
		return
	for i in range(reference_wind_ribbons.size()):
		_set_reference_wind_segment_emitting(i, false)
	reference_wind_emitting = false


func _activate_reference_wind_segment(index: int, rotation: float, restart_particles: bool) -> void:
	if index < 0 or index >= reference_wind_ribbons.size():
		return
	reference_wind_rotation = rotation
	reference_wind_segment_rotations[index] = rotation
	var ribbon := reference_wind_ribbons[index]
	ribbon.rotation.z = rotation
	ribbon.visible = true
	_set_reference_wind_segment_emitting(index, true, restart_particles)


func _find_reference_wind_reuse_index() -> int:
	var best_index := (reference_wind_current_index + 1) % maxi(reference_wind_ribbons.size(), 1)
	var best_energy := 9999.0
	for i in range(reference_wind_ribbons.size()):
		if i == reference_wind_current_index:
			continue
		var energy := reference_wind_segment_energy[i]
		if energy < best_energy:
			best_energy = energy
			best_index = i
	return best_index


func _set_reference_wind_segment_emitting(index: int, emitting: bool, restart_particles: bool = false) -> void:
	if index < 0 or index >= reference_wind_ribbons.size():
		return
	reference_wind_segment_emitting[index] = emitting
	var ribbon := reference_wind_ribbons[index]
	var strand_particles := ribbon.get_node_or_null("StrandParticles") as GPUParticles3D
	var veil_particles := ribbon.get_node_or_null("VeilParticles") as GPUParticles3D
	_set_reference_wind_particles_emitting(strand_particles, emitting, restart_particles)
	_set_reference_wind_particles_emitting(veil_particles, emitting, restart_particles)
	if emitting:
		ribbon.visible = true


func _set_reference_wind_particles_emitting(particles: GPUParticles3D, emitting: bool, restart_particles: bool) -> void:
	if particles == null:
		return
	particles.preprocess = REFERENCE_WIND_START_PREPROCESS
	particles.emitting = emitting
	if emitting and restart_particles:
		particles.restart()


func _set_reference_wind_segment_intensity(index: int, energy: float) -> void:
	if index < 0 or index >= reference_wind_ribbons.size():
		return
	var ribbon := reference_wind_ribbons[index]
	var ratio := clampf(energy, 0.0, 1.0)
	var strand_particles := ribbon.get_node_or_null("StrandParticles") as GPUParticles3D
	var veil_particles := ribbon.get_node_or_null("VeilParticles") as GPUParticles3D
	if strand_particles != null:
		strand_particles.amount_ratio = clampf(ratio, 0.0, 1.0)
		strand_particles.speed_scale = lerpf(0.82, 1.06, ratio)
	if veil_particles != null:
		veil_particles.amount_ratio = clampf(0.62 * ratio, 0.0, 0.7)
		veil_particles.speed_scale = lerpf(0.72, 0.96, ratio)


func _fade_reference_wind_segments(active_index: int, active_energy: float, delta: float) -> void:
	var offset := Vector3(
		clampf(camera_look_ahead.x / maxf(camera_max_look_ahead.x, 1.0), -1.0, 1.0) * -0.35,
		clampf(camera_look_ahead.y / maxf(camera_max_look_ahead.y, 1.0), -1.0, 1.0) * 0.20,
		0.0
	)
	for i in range(reference_wind_ribbons.size()):
		var ribbon := reference_wind_ribbons[i]
		var target_energy := active_energy if i == active_index else 0.0
		var half_life := REFERENCE_WIND_ACTIVE_HALF_LIFE if i == active_index else REFERENCE_WIND_RELEASE_HALF_LIFE
		reference_wind_segment_energy[i] = _damp_float(reference_wind_segment_energy[i], target_energy, half_life, delta)
		var energy := reference_wind_segment_energy[i]
		ribbon.position = offset
		ribbon.rotation.z = reference_wind_segment_rotations[i]
		var min_scale := 0.70 if i == active_index else REFERENCE_WIND_RELEASE_MIN_SCALE
		ribbon.scale = Vector3.ONE * lerpf(min_scale, 1.18, clampf(energy, 0.0, 1.0))
		_set_reference_wind_segment_intensity(i, energy)
		if i != active_index and energy < REFERENCE_WIND_RELEASE_HIDE_THRESHOLD:
			ribbon.visible = false
			_set_reference_wind_segment_emitting(i, false)


func _update_scene_speed_streaks(delta: float) -> void:
	for streak in scene_speed_streaks:
		streak["age"] = float(streak["age"]) + delta
		var drift_dir: Vector2 = streak.get("dir", Vector2.RIGHT)
		var flow_speed := float(streak.get("flow_speed", 0.0))
		streak["pos"] = Vector2(streak["pos"]) - drift_dir * flow_speed * delta
	scene_speed_streaks = scene_speed_streaks.filter(func(streak: Dictionary) -> bool: return float(streak["age"]) <= float(streak.get("life", SCENE_SPEED_STREAK_LIFE)))

	var speed_pressure := clampf((velocity.length() - CRUISE_SPEED * 0.52) / maxf(BOOST_SPEED - CRUISE_SPEED * 0.52, 1.0), 0.0, 1.0)
	var streak_energy := clampf(maxf(speed_pressure, maxf(throttle_energy * 0.54, carve_energy * 0.36)), 0.0, 1.0)
	if streak_energy < SCENE_SPEED_STREAK_MIN_ENERGY:
		scene_speed_streak_spawn_accumulator = 0.0
		return

	var spawn_rate := lerpf(6.0, SCENE_SPEED_STREAK_SPAWN_RATE, streak_energy)
	scene_speed_streak_spawn_accumulator += spawn_rate * delta
	while scene_speed_streak_spawn_accumulator >= 1.0:
		_spawn_scene_speed_streak(streak_energy)
		scene_speed_streak_spawn_accumulator -= 1.0


func _spawn_scene_speed_streak(streak_energy: float) -> void:
	var dir := _safe_velocity_dir()
	if dir.length_squared() <= 0.0001:
		return
	var side_dir := dir.rotated(PI * 0.5)
	var seed := float(scene_speed_streak_seed)
	scene_speed_streak_seed += 1
	var forward_span := VIEW_SIZE.x * camera_zoom * 0.82
	var side_span := VIEW_SIZE.y * camera_zoom * 0.76
	var forward_offset := lerpf(-0.58, 0.64, _hash01(seed + time * 0.37)) * forward_span
	var side_offset := lerpf(-0.62, 0.62, _hash01(seed + 17.3)) * side_span
	var pos := camera_center + dir * forward_offset + side_dir * side_offset
	var length := lerpf(SCENE_SPEED_STREAK_MIN_LENGTH, SCENE_SPEED_STREAK_MAX_LENGTH, streak_energy) * camera_zoom * lerpf(0.68, 1.22, _hash01(seed + 5.1))
	var life := SCENE_SPEED_STREAK_LIFE * lerpf(0.74, 1.18, _hash01(seed + 9.8))
	scene_speed_streaks.append({
		"pos": pos,
		"dir": dir,
		"age": 0.0,
		"life": life,
		"length": length,
		"width": lerpf(1.2, 3.4, streak_energy) * lerpf(0.72, 1.32, _hash01(seed + 2.4)),
		"alpha": lerpf(0.035, 0.16, streak_energy) * lerpf(0.62, 1.08, _hash01(seed + 6.7)),
		"flow_speed": velocity.length() * lerpf(0.10, 0.24, streak_energy),
	})
	while scene_speed_streaks.size() > SCENE_SPEED_STREAK_MAX_COUNT:
		scene_speed_streaks.pop_front()


func _update_reference_fog_cards(_speed_pressure: float, _delta: float) -> void:
	if reference_fog_cards.is_empty():
		return
	var camera_factor := camera_center - FLIGHT_START_POS
	for i in range(reference_fog_cards.size()):
		var card := reference_fog_cards[i]
		var layer := float(i % 3)
		var parallax_values: Array[float] = [SCENE_FAR_FOG_PARALLAX, SCENE_MID_FOG_PARALLAX, SCENE_NEAR_FOG_PARALLAX]
		var parallax: float = parallax_values[i % 3]
		var width: float = 13.8
		var spacing: float = width / maxf(float(REFERENCE_FOG_CARD_COUNT), 1.0)
		var drift: float = time * lerpf(0.10, 0.34, layer / 2.0)
		var x: float = fposmod(float(i) * spacing + _hash01(float(i) + 0.7) * 2.4 - camera_factor.x * parallax * 0.010 + drift, width) - width * 0.5
		var y_base: float = lerpf(-2.1, 1.45, _hash01(float(i) + 5.9))
		var y: float = y_base + camera_factor.y * parallax * 0.003 + sin(time * 0.18 + float(i) * 1.7) * 0.08
		card.position = Vector3(x, y, lerpf(-0.9, 0.8, layer / 2.0))
		card.rotation_degrees = Vector3(0.0, 0.0, lerpf(-4.0, 4.0, _hash01(float(i) + 8.2)))
		card.set("phase", 0.45)
		card.set("fog_opacity", lerpf(0.44, 0.72, _hash01(float(i) + 3.5)))


func _clamp_camera_center(center: Vector2) -> Vector2:
	var half_view := VIEW_SIZE * 0.5 * camera_zoom
	var min_center := PLAY_RECT.position + half_view
	var max_center := PLAY_RECT.end - half_view
	if max_center.x < min_center.x:
		min_center.x = PLAY_RECT.get_center().x
		max_center.x = min_center.x
	if max_center.y < min_center.y:
		min_center.y = PLAY_RECT.get_center().y
		max_center.y = min_center.y
	return center.clamp(min_center, max_center)


func _camera_origin() -> Vector2:
	return camera_center - VIEW_SIZE * 0.5 * camera_zoom


func _world_to_screen(world_pos: Vector2) -> Vector2:
	return (world_pos - camera_center) / maxf(camera_zoom, 0.001) + VIEW_SIZE * 0.5


func _get_visible_world_rect() -> Rect2:
	return Rect2(_camera_origin(), VIEW_SIZE * camera_zoom).intersection(PLAY_RECT)


func _update_afterimages(delta: float) -> void:
	for image in afterimages:
		image["age"] = float(image["age"]) + delta
	afterimages = afterimages.filter(func(image: Dictionary) -> bool: return float(image["age"]) <= float(image.get("life", 0.28)))

	var clip := _current_clip()
	var fast_enough := velocity.length() > 440.0 * FLIGHT_SPEED_MULTIPLIER or _is_hard_turn_clip() or clip_index == CLIP_BOOST_IDLE
	if not fast_enough:
		return
	var min_distance := lerpf(54.0, 30.0, clampf(boost_energy + turn_energy + carve_energy, 0.0, 1.0))
	if afterimages.is_empty() or Vector2(afterimages[-1]["pos"]).distance_to(flight_pos) > min_distance:
		_capture_afterimage(flight_pos - _safe_velocity_dir() * 24.0, float(clip.get("smear_weight", 0.3)))


func _update_direction_switch_fx(delta: float) -> void:
	for fx in direction_switch_fx:
		fx["age"] = float(fx["age"]) + delta
	direction_switch_fx = direction_switch_fx.filter(func(fx: Dictionary) -> bool: return float(fx["age"]) <= float(fx.get("life", DIRECTION_SWITCH_FX_LIFE)))


func _update_boost_shockwaves(delta: float) -> void:
	for fx in boost_shockwaves:
		fx["age"] = float(fx["age"]) + delta
	boost_shockwaves = boost_shockwaves.filter(func(fx: Dictionary) -> bool: return float(fx["age"]) <= float(fx.get("life", 冲击波寿命)))


func _setup_boost_shockwave_particles() -> void:
	boost_shockwave_vfx_root = get_node_or_null(BOOST_SHOCKWAVE_PARTICLE_ROOT_PATH) as Node2D
	boost_shockwave_particle_layers.clear()
	if boost_shockwave_vfx_root == null:
		return
	_load_boost_shockwave_textures()
	boost_shockwave_vfx_root.visible = true
	_setup_boost_shockwave_ring_sprite()
	for child in boost_shockwave_vfx_root.get_children():
		var particles := child as GPUParticles2D
		if particles == null:
			continue
		particles.emitting = false
		particles.one_shot = true
		particles.local_coords = true
		particles.visibility_rect = BOOST_SHOCKWAVE_PARTICLE_VISIBILITY_RECT
		_apply_boost_shockwave_particle_runtime_settings(particles)
		_apply_boost_shockwave_particle_texture(particles)
		boost_shockwave_particle_layers.append(particles)


func _load_boost_shockwave_textures() -> void:
	boost_shockwave_textures.clear()
	boost_shockwave_textures["ring"] = _load_png_texture(BOOST_SHOCKWAVE_RING_TEXTURE_PATH)
	boost_shockwave_textures["mist"] = _load_png_texture(BOOST_SHOCKWAVE_MIST_TEXTURE_PATH)
	boost_shockwave_textures["needle"] = _load_png_texture(BOOST_SHOCKWAVE_NEEDLE_TEXTURE_PATH)
	boost_shockwave_textures["shard"] = _load_png_texture(BOOST_SHOCKWAVE_SHARD_TEXTURE_PATH)


func _load_png_texture(path: String) -> Texture2D:
	var file_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if not file_bytes.is_empty():
		var image := Image.new()
		var error := image.load_png_from_buffer(file_bytes)
		if error == OK:
			return ImageTexture.create_from_image(image)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _setup_boost_shockwave_ring_sprite() -> void:
	if boost_shockwave_vfx_root == null:
		return
	boost_shockwave_ring_sprite = boost_shockwave_vfx_root.get_node_or_null("ShockwaveRingSprite") as Sprite2D
	if boost_shockwave_ring_sprite == null:
		boost_shockwave_ring_sprite = Sprite2D.new()
		boost_shockwave_ring_sprite.name = "ShockwaveRingSprite"
		boost_shockwave_vfx_root.add_child(boost_shockwave_ring_sprite)
	var texture := boost_shockwave_textures.get("ring", null) as Texture2D
	if texture != null:
		boost_shockwave_ring_sprite.texture = texture
	boost_shockwave_ring_sprite.centered = true
	boost_shockwave_ring_sprite.position = Vector2.ZERO
	boost_shockwave_ring_sprite.z_index = 2
	boost_shockwave_ring_sprite.visible = false
	boost_shockwave_ring_sprite.modulate = _color_with_scaled_alpha(椭圆环颜色, 0.0)


func _apply_boost_shockwave_particle_texture(particles: GPUParticles2D) -> void:
	var texture_key := ""
	match particles.name:
		"ShockwaveMistParticles":
			texture_key = "mist"
		"ShockwaveNeedleParticles":
			texture_key = "needle"
		"ShockwaveShardParticles":
			texture_key = "shard"
	if texture_key.is_empty():
		return
	var texture := boost_shockwave_textures.get(texture_key, null) as Texture2D
	if texture != null:
		particles.texture = texture


func _color_with_scaled_alpha(color: Color, alpha_scale: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(color.a * alpha_scale, 0.0, 1.0))


func _apply_boost_shockwave_particle_runtime_settings(particles: GPUParticles2D) -> void:
	match particles.name:
		"ShockwaveMistParticles":
			particles.amount = maxi(1, 雾粒子数量)
			particles.lifetime = maxf(雾粒子寿命, 0.01)
		"ShockwaveNeedleParticles":
			particles.amount = maxi(1, 线稿粒子数量)
			particles.lifetime = maxf(线稿粒子寿命, 0.01)
		"ShockwaveShardParticles":
			particles.amount = maxi(1, 拖影粒子数量)
			particles.lifetime = maxf(拖影粒子寿命, 0.01)


func _update_boost_shockwave_particle_root() -> void:
	if boost_shockwave_vfx_root == null:
		return
	if boost_shockwaves.is_empty():
		if boost_shockwave_ring_sprite != null:
			boost_shockwave_ring_sprite.visible = false
		return
	var fx: Dictionary = boost_shockwaves[-1]
	var dir: Vector2 = fx.get("dir", Vector2.RIGHT)
	if dir.length_squared() <= 0.0001:
		dir = Vector2.RIGHT
	else:
		dir = dir.normalized()
	var progress := _get_boost_shockwave_progress(fx)
	_place_boost_shockwave_particle_root(_get_boost_shockwave_center(fx, dir, progress), dir)
	_update_boost_shockwave_ring_sprite(fx, progress, clampf(float(fx.get("strength", 1.0)), 0.0, 1.0))


func _trigger_boost_shockwave_particles(center: Vector2, direction: Vector2, strength: float) -> void:
	if boost_shockwave_vfx_root == null or boost_shockwave_particle_layers.is_empty() or direction.length_squared() <= 0.0001:
		return
	var dir := direction.normalized()
	var clamped_strength := clampf(strength, 0.0, 1.0)
	_place_boost_shockwave_particle_root(center, dir)
	for particles in boost_shockwave_particle_layers:
		if particles == null:
			continue
		_apply_boost_shockwave_particle_runtime_settings(particles)
		match particles.name:
			"ShockwaveMistParticles":
				particles.speed_scale = lerpf(0.86, 1.0, clamped_strength) * 粒子速度
				particles.modulate = _color_with_scaled_alpha(雾粒子颜色, lerpf(0.52, 0.70, clamped_strength) * 粒子透明度)
			"ShockwaveNeedleParticles":
				particles.speed_scale = lerpf(0.92, 1.06, clamped_strength) * 粒子速度
				particles.modulate = _color_with_scaled_alpha(线稿粒子颜色, lerpf(0.50, 0.68, clamped_strength) * 粒子透明度)
			"ShockwaveShardParticles":
				particles.speed_scale = lerpf(0.88, 1.0, clamped_strength) * 粒子速度
				particles.modulate = _color_with_scaled_alpha(拖影粒子颜色, lerpf(0.30, 0.46, clamped_strength) * 粒子透明度)
		particles.restart()
		particles.emitting = true


func _place_boost_shockwave_particle_root(center: Vector2, direction: Vector2) -> void:
	if boost_shockwave_vfx_root == null:
		return
	var dir := direction.normalized()
	boost_shockwave_vfx_root.position = _world_to_screen(center)
	boost_shockwave_vfx_root.rotation = dir.angle()
	boost_shockwave_vfx_root.scale = Vector2.ONE / maxf(camera_zoom, 0.001)


func _update_boost_shockwave_ring_sprite(fx: Dictionary, progress: float, strength: float) -> void:
	if boost_shockwave_ring_sprite == null:
		return
	var fade := pow(1.0 - progress, 1.25)
	if fade <= 0.01:
		boost_shockwave_ring_sprite.visible = false
		return
	var seed := float(fx.get("seed", 0.0))
	var eased := _ease_out_cubic(progress)
	boost_shockwave_ring_sprite.visible = true
	boost_shockwave_ring_sprite.position = Vector2.ZERO
	boost_shockwave_ring_sprite.rotation = sin(seed * 1.9 + progress * 8.0) * 0.025
	var ring_scale := lerpf(椭圆环起始缩放, 椭圆环结束缩放, eased) * 整体形状缩放 * lerpf(0.92, 1.08, clampf(strength, 0.0, 1.0))
	boost_shockwave_ring_sprite.scale = Vector2.ONE * ring_scale
	boost_shockwave_ring_sprite.modulate = _color_with_scaled_alpha(椭圆环颜色, fade * 椭圆环透明度 * clampf(strength, 0.0, 1.0))


func _get_boost_shockwave_progress(fx: Dictionary) -> float:
	var age := float(fx.get("age", 0.0))
	var life := maxf(float(fx.get("life", 冲击波寿命)), 0.001)
	return clampf(age / life, 0.0, 1.0)


func _get_boost_shockwave_center(fx: Dictionary, direction: Vector2, progress: float) -> Vector2:
	var dir := direction.normalized()
	var age := float(fx.get("age", 0.0))
	var velocity_drift: Vector2 = fx.get("velocity", Vector2.ZERO)
	var center: Vector2 = fx.get("center", visual_pos)
	var current_front := visual_pos + dir * 前置距离
	var follow_weight := pow(1.0 - progress, 前方跟随力度)
	center = center.lerp(current_front, follow_weight)
	return center + dir * lerpf(0.0, 向前漂移距离, progress) + velocity_drift * age * 速度拖拽系数


func _spawn_boost_shockwave(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	var dir := direction.normalized()
	var speed_pressure := clampf(velocity.length() / BOOST_SPEED, 0.0, 1.2)
	var strength := clampf(0.82 + speed_pressure * 0.18, 0.82, 1.0)
	var center := flight_pos + dir * 前置距离
	boost_shockwaves.append({
		"center": center,
		"dir": dir,
		"age": 0.0,
		"life": 冲击波寿命,
		"strength": strength,
		"velocity": dir * maxf(velocity.length(), BOOST_SPEED),
		"seed": float(boost_shockwave_seed),
	})
	_trigger_boost_shockwave_particles(center, dir, strength)
	_update_boost_shockwave_ring_sprite(boost_shockwaves[-1], 0.0, strength)
	boost_shockwave_seed += 1
	while boost_shockwaves.size() > 最大残留数量:
		boost_shockwaves.pop_front()


func _spawn_boost_burst_streaks(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	var dir := direction.normalized()
	var side_dir := dir.rotated(PI * 0.5)
	for i in range(9):
		var seed := float(scene_speed_streak_seed)
		scene_speed_streak_seed += 1
		var side_offset := lerpf(-168.0, 168.0, _hash01(seed + 3.1))
		var back_offset := lerpf(22.0, 210.0, _hash01(seed + 7.4))
		scene_speed_streaks.append({
			"pos": flight_pos - dir * back_offset + side_dir * side_offset,
			"dir": dir,
			"age": 0.0,
			"life": lerpf(0.18, 0.32, _hash01(seed + 9.6)),
			"length": lerpf(180.0, 420.0, _hash01(seed + 12.2)) * camera_zoom,
			"width": lerpf(2.2, 5.4, _hash01(seed + 2.4)),
			"alpha": lerpf(0.13, 0.26, _hash01(seed + 6.7)),
			"flow_speed": BOOST_SPEED * lerpf(0.22, 0.42, _hash01(seed + 8.8)),
		})
	while scene_speed_streaks.size() > SCENE_SPEED_STREAK_MAX_COUNT:
		scene_speed_streaks.pop_front()


func _capture_afterimage(pos: Vector2, intensity: float) -> void:
	if _uses_procedural_eight_way():
		return
	if USE_GEMINI_8WAY_CRUISE and (not _use_v1_sequence_visual() or _use_v1_static_direction_visual()) and character_sprite != null and character_sprite.texture != null:
		var texture := character_sprite.texture
		var source := Rect2(Vector2.ZERO, texture.get_size())
		if character_sprite.region_enabled:
			source = character_sprite.region_rect
		afterimages.append({
			"texture": texture,
			"source": source,
			"pos": pos,
			"screen_offset": character_sprite.position,
			"scale": character_sprite.scale.abs(),
			"facing": 1.0,
			"rotation": character_sprite.rotation,
			"age": 0.0,
			"life": 0.20 + 0.16 * clampf(intensity, 0.0, 1.0),
			"intensity": clampf(intensity, 0.0, 1.0),
			"velocity": velocity,
		})
		return
	if sheet_texture == null:
		return
	afterimages.append({
		"texture": sheet_texture,
		"source": _get_current_frame_rect(),
		"pos": pos,
		"screen_offset": character_sprite.position,
		"scale": character_sprite.scale.abs(),
		"facing": render_sign * SHEET_FACE_SIGN,
		"rotation": _visual_root_rotation(),
		"age": 0.0,
		"life": 0.20 + 0.16 * clampf(intensity, 0.0, 1.0),
		"intensity": clampf(intensity, 0.0, 1.0),
		"velocity": velocity,
	})


func _update_trail(delta: float) -> void:
	for point in trail_points:
		point["age"] = float(point["age"]) + delta
	var max_life := 0.70 + 0.16 * clampf(boost_energy + turn_energy, 0.0, 1.0)
	max_life = maxf(max_life, 0.54 + 0.31 * clampf(破空尾流长度, 0.45, 1.8))
	trail_points = trail_points.filter(func(point: Dictionary) -> bool: return float(point["age"]) <= max_life)

	var anchor := _get_trail_anchor()
	var distance_threshold := lerpf(15.0, 8.0, clampf(boost_energy + turn_energy, 0.0, 1.0))
	if trail_points.is_empty() or Vector2(trail_points[-1]["pos"]).distance_to(anchor) > distance_threshold:
		var clip := _current_clip()
		trail_points.append({
			"pos": anchor,
			"age": 0.0,
			"life": max_life,
			"speed": velocity.length(),
			"weight": float(clip.get("trail_weight", 1.0)),
			"boost": boost_energy,
			"turn": turn_energy,
		})
	_update_trail_lines()


func _update_airwake_particles(delta: float) -> void:
	if airwake_root == null:
		return
	var direction := _safe_velocity_dir()
	if direction.length_squared() <= 0.0001:
		_clear_airwake_particles()
		return

	var speed_ratio := clampf((velocity.length() - CRUISE_SPEED * 0.28) / maxf(BOOST_SPEED - CRUISE_SPEED * 0.28, 1.0), 0.0, 1.0)
	var boost_pressure := clampf(maxf(boost_energy, throttle_energy * 0.68), 0.0, 1.0)
	var carve_pressure := clampf(maxf(carve_energy, turn_energy * 0.82), 0.0, 1.0)
	var base_energy := clampf(maxf(speed_ratio, boost_pressure * 0.82) + carve_pressure * 0.18, 0.0, 1.0) * 破空尾流强度
	_sync_airwake_particle_budget()
	if base_energy <= 0.015:
		_clear_airwake_particles()
		return

	airwake_root.visible = true
	_update_airwake_transform(direction)

	var rail_ratio := clampf((0.20 + base_energy * 0.48 + boost_pressure * 0.12) * 剑轨亮度, 0.0, 0.88)
	var mist_ratio := clampf((0.08 + base_energy * 0.38 + carve_pressure * 0.14) * 云气开缝强度, 0.0, 0.36)
	var needle_ratio := clampf((0.10 + base_energy * 0.44 + boost_pressure * 0.36 + carve_pressure * 0.20) * 风切粒子强度, 0.0, 1.0)
	var mote_ratio := clampf((base_energy * 0.10 + carve_pressure * 0.12) * 云气开缝强度, 0.0, 0.18)
	var compression_ratio := clampf((boost_pressure * 0.34 + carve_pressure * 0.12) * 压缩尾迹强度, 0.0, 0.24)
	var length_scale := 破空尾流长度 * lerpf(0.82, 1.26, boost_pressure)

	_set_airwake_layer(qi_rail_particles, rail_ratio, lerpf(1.04, 1.52, speed_ratio) * length_scale * 剑轨粒子速度, Color(0.82, 1.0, 1.0, (0.30 + 0.12 * boost_pressure) * 剑轨粒子透明度), delta)
	_set_airwake_layer(cloud_split_particles, mist_ratio, lerpf(1.02, 1.42, speed_ratio) * length_scale * 云气粒子速度, Color(0.48, 0.92, 1.0, (0.045 + 0.020 * base_energy) * 云气粒子透明度), delta)
	_set_airwake_layer(wind_cut_particles, needle_ratio, lerpf(1.12, 1.78, speed_ratio) * length_scale * 风切粒子速度, Color(0.92, 1.0, 1.0, (0.18 + 0.10 * boost_pressure) * 风切粒子透明度), delta)
	_set_airwake_layer(condensation_particles, mote_ratio, lerpf(1.00, 1.28, speed_ratio) * 冷凝粒子速度, Color(0.70, 0.96, 1.0, (0.040 + 0.018 * carve_pressure) * 冷凝粒子透明度), delta)
	_set_airwake_layer(compression_particles, compression_ratio, lerpf(0.90, 1.24, boost_pressure) * length_scale * 压缩粒子速度, Color(0.60, 0.96, 1.0, (0.028 + 0.038 * boost_pressure) * 压缩粒子透明度), delta)
	_update_airwake_readable_lines(direction, rail_ratio, needle_ratio, speed_ratio, boost_pressure, length_scale)
	_update_airwake_support_lines(direction, mist_ratio, needle_ratio, mote_ratio, compression_ratio, speed_ratio, boost_pressure, length_scale)


func _get_airwake_anchor(direction: Vector2) -> Vector2:
	var clip := _current_clip()
	var offset: Vector2 = clip.get("trail_anchor", Vector2(-42.0, 90.0))
	var carve_side := Vector2.ZERO
	if carve_direction != 0.0:
		carve_side = direction.rotated(carve_direction * PI * 0.5) * 10.0 * carve_energy
	var back_distance := absf(offset.x) * 0.62 + 8.0 + 14.0 * boost_energy + 8.0 * turn_energy
	var vertical_drop := offset.y * lerpf(0.42, 0.30, boost_energy)
	return visual_pos - direction * back_distance + Vector2(0.0, vertical_drop) + carve_side


func _update_airwake_transform(direction: Vector2) -> void:
	airwake_root.position = Vector2.ZERO
	airwake_root.rotation = 0.0
	airwake_root.scale = Vector2.ONE

	var emitter_position := _world_to_screen(_get_airwake_anchor(direction))
	var emitter_scale := Vector2.ONE / maxf(camera_zoom, 0.001)
	for particles in airwake_particle_layers:
		if particles == null:
			continue
		particles.position = emitter_position
		particles.rotation = direction.angle()
		particles.scale = emitter_scale


func _set_airwake_layer(particles: GPUParticles2D, target_ratio: float, speed_scale: float, color: Color, delta: float) -> void:
	if particles == null:
		return
	var ratio := _damp_float(particles.amount_ratio, clampf(target_ratio, 0.0, 1.0), 0.055, delta)
	particles.amount_ratio = ratio
	particles.speed_scale = speed_scale
	particles.modulate = color
	particles.visible = ratio > 0.01
	particles.emitting = ratio > 0.015


func _update_airwake_readable_lines(direction: Vector2, rail_ratio: float, needle_ratio: float, speed_ratio: float, boost_pressure: float, length_scale: float) -> void:
	var visibility := clampf(maxf(rail_ratio, needle_ratio * 0.72), 0.0, 1.0)
	if visibility <= 0.015:
		_set_airwake_line(airwake_halo_line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		_set_airwake_line(airwake_core_line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var line_length := (72.0 + 88.0 * speed_ratio + 56.0 * boost_pressure) * length_scale * 主线长度倍率
	var core_points := _get_airwake_screen_path(direction, line_length)
	if core_points.size() < 2:
		_set_airwake_line(airwake_halo_line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		_set_airwake_line(airwake_core_line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var camera_scale := 1.0 / maxf(camera_zoom, 0.001)
	var halo_alpha := (0.050 + 0.038 * boost_pressure) * visibility * 主线光晕透明度
	var core_alpha := (0.30 + 0.12 * boost_pressure) * visibility * 主线核心透明度
	_set_airwake_line(airwake_halo_line, core_points, (4.8 + 1.8 * speed_ratio) * 主线光晕宽度 * camera_scale, Color(0.58, 0.96, 1.0, halo_alpha))
	_set_airwake_line(airwake_core_line, core_points, (1.35 + 0.85 * speed_ratio) * 主线核心宽度 * camera_scale, Color(0.93, 1.0, 1.0, core_alpha))


func _set_airwake_line(line: Line2D, points: PackedVector2Array, width: float, color: Color) -> void:
	if line == null:
		return
	line.points = points
	line.width = width
	line.default_color = color
	line.visible = points.size() >= 2 and color.a > 0.01


func _get_airwake_screen_path(direction: Vector2, target_length: float) -> PackedVector2Array:
	var world_points := _collect_airwake_world_path(direction, maxf(target_length, 8.0))
	var raw_points: Array = []
	for point in world_points:
		raw_points.append(_world_to_screen(Vector2(point)))
	return _build_smooth_points(raw_points)


func _collect_airwake_world_path(direction: Vector2, target_length: float) -> Array:
	var anchor := _get_airwake_anchor(direction)
	var reverse_points: Array = [anchor]
	var collected_length := 0.0
	var last := anchor
	for index in range(trail_points.size() - 1, -1, -1):
		var point := Vector2(trail_points[index]["pos"])
		var segment_length := last.distance_to(point)
		if segment_length <= 1.5:
			continue
		if collected_length + segment_length >= target_length:
			var remaining := maxf(target_length - collected_length, 0.0)
			reverse_points.append(last.lerp(point, remaining / segment_length))
			collected_length = target_length
			break
		reverse_points.append(point)
		collected_length += segment_length
		last = point

	if reverse_points.size() < 2:
		reverse_points.append(anchor - direction * target_length)
	reverse_points.reverse()
	return reverse_points


func _offset_airwake_path(points: PackedVector2Array, offset: float) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	if points.size() < 2:
		return shifted
	for index in range(points.size()):
		var previous: Vector2 = points[maxi(index - 1, 0)]
		var next: Vector2 = points[mini(index + 1, points.size() - 1)]
		var tangent := (next - previous).normalized()
		if tangent.length_squared() <= 0.0001:
			tangent = Vector2.RIGHT
		var normal := Vector2(-tangent.y, tangent.x)
		shifted.append(points[index] + normal * offset)
	return shifted


func _sample_airwake_path_from_end(points: PackedVector2Array, distance_from_end: float) -> Dictionary:
	if points.size() < 2:
		return {"pos": Vector2.ZERO, "tangent": Vector2.RIGHT}

	var remaining := maxf(distance_from_end, 0.0)
	for index in range(points.size() - 1, 0, -1):
		var segment_start: Vector2 = points[index - 1]
		var segment_end: Vector2 = points[index]
		var segment := segment_end - segment_start
		var segment_length := segment.length()
		if segment_length <= 0.001:
			continue
		if remaining <= segment_length:
			var ratio := remaining / segment_length
			return {
				"pos": segment_end.lerp(segment_start, ratio),
				"tangent": segment / segment_length,
			}
		remaining -= segment_length

	var first: Vector2 = points[0]
	var second: Vector2 = points[1]
	var fallback_tangent := (second - first).normalized()
	if fallback_tangent.length_squared() <= 0.0001:
		fallback_tangent = Vector2.RIGHT
	return {"pos": first, "tangent": fallback_tangent}


func _update_airwake_support_lines(
	direction: Vector2,
	mist_ratio: float,
	needle_ratio: float,
	mote_ratio: float,
	compression_ratio: float,
	speed_ratio: float,
	boost_pressure: float,
	length_scale: float
) -> void:
	_update_airwake_cloud_lines(direction, mist_ratio, speed_ratio, boost_pressure, length_scale)
	_update_airwake_wind_lines(direction, needle_ratio, speed_ratio, boost_pressure, length_scale)
	_update_airwake_mote_lines(direction, mote_ratio, speed_ratio, length_scale)
	_update_airwake_compression_line(direction, compression_ratio, speed_ratio, boost_pressure, length_scale)


func _update_airwake_cloud_lines(direction: Vector2, mist_ratio: float, speed_ratio: float, boost_pressure: float, length_scale: float) -> void:
	var visibility := clampf(mist_ratio * 云气粒子透明度, 0.0, 1.0)
	if visibility <= 0.015:
		for line in airwake_cloud_lines:
			_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var cloud_length := (76.0 + 88.0 * speed_ratio + 40.0 * boost_pressure) * length_scale * lerpf(0.82, 1.22, clampf(云气粒子速度 - 1.0, 0.0, 1.0))
	var cloud_gap := 11.0 + 18.0 * speed_ratio + 8.0 * boost_pressure
	var path_points := _get_airwake_screen_path(direction, cloud_length)
	if path_points.size() < 2:
		for line in airwake_cloud_lines:
			_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var camera_scale := 1.0 / maxf(camera_zoom, 0.001)
	for index in range(airwake_cloud_lines.size()):
		var side := -1.0 if index == 0 else 1.0
		var points := _offset_airwake_path(path_points, side * cloud_gap * camera_scale)
		var alpha := (0.070 + 0.038 * boost_pressure) * visibility
		var width := (5.0 + 7.0 * speed_ratio) * clampf(云气粒子透明度, 0.0, 2.5) * camera_scale
		_set_airwake_line(airwake_cloud_lines[index], points, width, Color(0.50, 0.92, 1.0, alpha))


func _update_airwake_wind_lines(direction: Vector2, needle_ratio: float, speed_ratio: float, boost_pressure: float, length_scale: float) -> void:
	var visibility := clampf(needle_ratio * 风切粒子透明度, 0.0, 1.0)
	var active_count := clampi(ceili(float(airwake_wind_lines.size()) * clampf(风切粒子数量 / 128.0, 0.0, 1.0)), 0, airwake_wind_lines.size())
	if visibility <= 0.015 or active_count <= 0:
		for line in airwake_wind_lines:
			_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var base_length := (42.0 + 92.0 * speed_ratio + 36.0 * boost_pressure) * length_scale * clampf(风切粒子速度, 0.2, 2.5)
	var path_points := _get_airwake_screen_path(direction, base_length + 116.0 * length_scale)
	if path_points.size() < 2:
		for line in airwake_wind_lines:
			_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var camera_scale := 1.0 / maxf(camera_zoom, 0.001)
	var base_length_screen := base_length * camera_scale
	for index in range(airwake_wind_lines.size()):
		var line := airwake_wind_lines[index]
		if index >= active_count:
			_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
			continue
		var phase := fposmod(time * 5.0 * clampf(风切粒子速度, 0.2, 2.5) + float(index) * 0.31, 1.0)
		var side := -1.0 if index % 2 == 0 else 1.0
		var lateral := side * lerpf(9.0, 44.0, _hash01(float(index) * 7.17 + 0.4)) * camera_scale
		var back_distance := lerpf(20.0, 96.0, phase) * length_scale * camera_scale
		var sample := _sample_airwake_path_from_end(path_points, back_distance)
		var tangent: Vector2 = sample["tangent"]
		var normal := Vector2(-tangent.y, tangent.x)
		var center: Vector2 = sample["pos"] + normal * lateral
		var length := base_length_screen * lerpf(0.48, 1.0, _hash01(float(index) * 5.43 + 0.8))
		var side_sway := side * lerpf(2.0, 9.0, speed_ratio) * camera_scale
		var points := PackedVector2Array([
			center + tangent * 4.0 * camera_scale,
			center - tangent * length + normal * side_sway,
		])
		var alpha := (0.11 + 0.11 * boost_pressure) * visibility * lerpf(0.62, 1.0, phase)
		var width := (0.85 + 1.45 * speed_ratio) * camera_scale
		_set_airwake_line(line, points, width, Color(0.92, 1.0, 1.0, alpha))


func _update_airwake_mote_lines(direction: Vector2, mote_ratio: float, speed_ratio: float, length_scale: float) -> void:
	var visibility := clampf(mote_ratio * 冷凝粒子透明度, 0.0, 1.0)
	var active_count := clampi(ceili(float(airwake_mote_lines.size()) * clampf(冷凝粒子数量 / 64.0, 0.0, 1.0)), 0, airwake_mote_lines.size())
	if visibility <= 0.01 or active_count <= 0:
		for line in airwake_mote_lines:
			_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var scatter_length := (52.0 + 86.0 * speed_ratio) * length_scale * clampf(冷凝粒子速度, 0.2, 2.5)
	var path_points := _get_airwake_screen_path(direction, scatter_length + 72.0 * length_scale)
	if path_points.size() < 2:
		for line in airwake_mote_lines:
			_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var camera_scale := 1.0 / maxf(camera_zoom, 0.001)
	for index in range(airwake_mote_lines.size()):
		var line := airwake_mote_lines[index]
		if index >= active_count:
			_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
			continue
		var seed := float(index) * 11.73
		var phase := fposmod(time * 2.6 * clampf(冷凝粒子速度, 0.2, 2.5) + _hash01(seed), 1.0)
		var back_distance := scatter_length * lerpf(0.16, 1.0, phase) * camera_scale
		var sample := _sample_airwake_path_from_end(path_points, back_distance)
		var tangent: Vector2 = sample["tangent"]
		var normal := Vector2(-tangent.y, tangent.x)
		var lateral := lerpf(-38.0, 38.0, _hash01(seed + 3.1)) * camera_scale
		var mote_size := lerpf(2.0, 5.0, _hash01(seed + 4.9)) * camera_scale
		var center: Vector2 = sample["pos"] + normal * lateral
		var points := PackedVector2Array([center, center - tangent * mote_size])
		var alpha := (0.10 + 0.08 * speed_ratio) * visibility * (1.0 - phase * 0.45)
		_set_airwake_line(line, points, mote_size, Color(0.72, 0.96, 1.0, alpha))


func _update_airwake_compression_line(direction: Vector2, compression_ratio: float, speed_ratio: float, boost_pressure: float, length_scale: float) -> void:
	var visibility := clampf(compression_ratio * 压缩粒子透明度, 0.0, 1.0)
	if visibility <= 0.015:
		_set_airwake_line(airwake_compression_line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var line_length := (54.0 + 88.0 * speed_ratio + 70.0 * boost_pressure) * length_scale * clampf(压缩粒子速度, 0.2, 2.5)
	var points := _get_airwake_screen_path(direction, line_length)
	if points.size() < 2:
		_set_airwake_line(airwake_compression_line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return
	var camera_scale := 1.0 / maxf(camera_zoom, 0.001)
	var alpha := (0.040 + 0.082 * boost_pressure) * visibility
	var width := (10.0 + 22.0 * boost_pressure + 6.0 * speed_ratio) * visibility * camera_scale
	_set_airwake_line(airwake_compression_line, points, width, Color(0.58, 0.94, 1.0, alpha))


func _sync_airwake_particle_budget() -> void:
	_set_airwake_particle_budget(qi_rail_particles, 剑轨粒子数量, 剑轨粒子寿命)
	_set_airwake_particle_budget(cloud_split_particles, 云气粒子数量, 云气粒子寿命)
	_set_airwake_particle_budget(wind_cut_particles, 风切粒子数量, 风切粒子寿命)
	_set_airwake_particle_budget(condensation_particles, 冷凝粒子数量, 冷凝粒子寿命)
	_set_airwake_particle_budget(compression_particles, 压缩粒子数量, 压缩粒子寿命)


func _set_airwake_particle_budget(particles: GPUParticles2D, amount: int, lifetime: float) -> void:
	if particles == null:
		return
	particles.amount = maxi(amount, 1)
	particles.lifetime = maxf(lifetime, 0.01)
	particles.preprocess = particles.lifetime * 0.65


func _clear_airwake_particles() -> void:
	if airwake_root != null:
		airwake_root.visible = false
	_set_airwake_line(airwake_halo_line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
	_set_airwake_line(airwake_core_line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
	for line in airwake_cloud_lines:
		_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
	for line in airwake_wind_lines:
		_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
	for line in airwake_mote_lines:
		_set_airwake_line(line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
	_set_airwake_line(airwake_compression_line, PackedVector2Array(), 0.0, Color.TRANSPARENT)
	for particles in airwake_particle_layers:
		if particles == null:
			continue
		particles.amount_ratio = _damp_float(particles.amount_ratio, 0.0, 0.045, 1.0 / 30.0)
		particles.emitting = particles.amount_ratio > 0.01
		particles.visible = particles.amount_ratio > 0.01


func _get_trail_anchor() -> Vector2:
	var clip := _current_clip()
	var offset: Vector2 = clip.get("trail_anchor", Vector2(-42.0, 90.0))
	var tail_dir := _safe_velocity_dir()
	var carve_side := Vector2.ZERO
	if carve_direction != 0.0:
		carve_side = tail_dir.rotated(carve_direction * PI * 0.5) * 14.0 * carve_energy
	var back_distance := absf(offset.x) + 10.0 + 16.0 * boost_energy + 12.0 * turn_energy + 10.0 * carve_energy
	var vertical_drop := offset.y * lerpf(0.55, 0.35, boost_energy)
	return visual_pos - tail_dir * back_distance + Vector2(0.0, vertical_drop) + carve_side


func _update_trail_lines() -> void:
	if trail_points.size() < 2:
		_apply_line(trail_halo, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		_apply_line(trail_ribbon, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		_apply_line(trail_core, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return

	var raw_points: Array = []
	var total_weight := 0.0
	var total_speed := 0.0
	var total_turn := 0.0
	var total_boost := 0.0
	for point in trail_points:
		raw_points.append(_world_to_screen(Vector2(point["pos"])))
		var life := clampf(1.0 - float(point["age"]) / maxf(float(point.get("life", 0.7)), 0.001), 0.0, 1.0)
		total_weight += float(point.get("weight", 1.0)) * life
		total_speed += float(point.get("speed", 0.0)) * life
		total_turn += float(point.get("turn", 0.0)) * life
		total_boost += float(point.get("boost", 0.0)) * life

	var count := maxf(float(trail_points.size()), 1.0)
	var avg_weight := total_weight / count
	var avg_speed := total_speed / count
	var avg_turn := total_turn / count
	var avg_boost := total_boost / count
	var speed_ratio := clampf(avg_speed / BOOST_SPEED, 0.0, 1.0)
	var width := (7.0 + speed_ratio * 22.0 + avg_boost * 10.0 + avg_turn * 18.0) * maxf(avg_weight, 0.35)
	width /= maxf(camera_zoom, 0.001)
	var alpha_scale := clampf(0.45 + speed_ratio * 0.36 + avg_boost * 0.24 + avg_turn * 0.22, 0.16, 1.0)
	var smooth_points := _build_smooth_points(raw_points)
	var halo := CYAN
	halo.a = 0.055 * alpha_scale * 辅助尾迹透明度
	var ribbon := Color(0.72, 1.0, 0.98, 0.115 * alpha_scale * 辅助尾迹透明度)
	var core := Color(0.96, 1.0, 0.98, 0.56 * alpha_scale * 辅助尾迹透明度)
	_apply_line(trail_halo, smooth_points, width * 0.92 * 辅助尾迹宽度, halo)
	_apply_line(trail_ribbon, smooth_points, width * 0.34 * 辅助尾迹宽度, ribbon)
	_apply_line(trail_core, smooth_points, maxf(width * 0.11 * 辅助尾迹宽度, 1.65), core)


func _apply_line(line: Line2D, points: PackedVector2Array, width: float, color: Color) -> void:
	if line == null:
		return
	line.points = points
	line.width = width
	line.default_color = color


func _build_smooth_points(raw_points: Array) -> PackedVector2Array:
	var packed := PackedVector2Array()
	if raw_points.is_empty():
		return packed
	if raw_points.size() == 1:
		packed.append(raw_points[0])
		return packed
	for index in range(raw_points.size() - 1):
		var p0: Vector2 = raw_points[maxi(index - 1, 0)]
		var p1: Vector2 = raw_points[index]
		var p2: Vector2 = raw_points[index + 1]
		var p3: Vector2 = raw_points[mini(index + 2, raw_points.size() - 1)]
		for step in range(5):
			var t := float(step) / 5.0
			packed.append(_catmull_rom(p0, p1, p2, p3, t))
	packed.append(raw_points[raw_points.size() - 1])
	return packed


func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


func _draw() -> void:
	_draw_background()
	_draw_scene_speed_streaks()
	_draw_boost_shockwaves()
	_draw_direction_switch_fx()
	_draw_afterimages()
	_draw_debug()


func _draw_background() -> void:
	_draw_sky_wash()
	var speed_pressure := _background_speed_pressure()
	var readability_fade := lerpf(1.0, 急转背景保留比例, clampf(maxf(carve_energy, direction_switch_energy), 0.0, 1.0))
	var grounded_plane_fade := readability_fade * lerpf(1.0, 海岛高速保留比例, speed_pressure)
	_draw_sea_plane_wash(speed_pressure, readability_fade)
	_draw_parallax_texture_layer(mountain_far_ink_texture, 0.34, Vector2(0.035, 0.010), 远山透明度 * readability_fade)
	_draw_parallax_texture_layer(sea_horizon_wash_texture, 海面水洗高度比例, Vector2(0.065, 0.014), 海面水洗透明度 * grounded_plane_fade, 1.0, 0.0, 海面水洗染色)
	_draw_parallax_texture_layer(cloudsea_far_texture, 远云高度比例, Vector2(0.090, 0.018), 远云透明度 * readability_fade)
	_draw_world_island_groups(speed_pressure, grounded_plane_fade)
	_draw_sea_shimmer_from_atlas(speed_pressure, grounded_plane_fade)
	_draw_near_cloud_wisps_from_atlas(speed_pressure)
	_draw_battlefield_boundary_layers()
	if show_debug_guides:
		_draw_world_guides()


func _draw_sky_wash() -> void:
	_draw_smooth_sky_gradient(天空顶部颜色, 天空中部颜色, 天空底部颜色)
	_draw_soft_sky_haze(0.47, 0.20, Color(0.96, 0.98, 0.94, 天空中部雾光强度))
	_draw_soft_sky_haze(0.72, 0.24, Color(0.74, 0.90, 0.94, 天空低处青雾强度))


func _draw_sea_plane_wash(speed_pressure: float, readability_fade: float) -> void:
	var horizon_y := _get_sea_horizon_y()
	var bottom_y := VIEW_SIZE.y + 2.0
	var height := maxf(bottom_y - horizon_y, 1.0)
	var alpha_scale := readability_fade * lerpf(1.0, 海面高速保留比例, speed_pressure)
	draw_rect(
		Rect2(Vector2(0.0, horizon_y), Vector2(VIEW_SIZE.x, height)),
		Color(
			海面基础颜色.r,
			海面基础颜色.g,
			海面基础颜色.b,
			海面基础透明度 * alpha_scale * 海面基础颜色.a
		)
	)
	_draw_soft_horizon_glow(horizon_y, alpha_scale)


func _get_sea_horizon_y() -> float:
	return VIEW_SIZE.y * 海平线高度比例 - (camera_center.y - FLIGHT_START_POS.y) * 0.012 / maxf(camera_zoom, 0.001)


func _draw_soft_horizon_glow(horizon_y: float, alpha_scale: float) -> void:
	var band_height := 海平线柔光宽度
	var top_y := horizon_y - band_height * 0.45
	var step_count := 72
	var previous_y := top_y
	for index in range(step_count):
		var t := (float(index) + 0.5) / float(step_count)
		var center_distance := absf(t * 2.0 - 1.0)
		var alpha := 海平线柔光强度 * alpha_scale * 海平线柔光颜色.a * pow(maxf(1.0 - center_distance, 0.0), 1.8)
		var next_y := top_y + band_height * float(index + 1) / float(step_count)
		draw_rect(
			Rect2(Vector2(0.0, previous_y), Vector2(VIEW_SIZE.x, next_y - previous_y)),
			Color(海平线柔光颜色.r, 海平线柔光颜色.g, 海平线柔光颜色.b, alpha)
		)
		previous_y = next_y


func _draw_smooth_sky_gradient(top_color: Color, middle_color: Color, bottom_color: Color) -> void:
	var step_count := 180
	var previous_y := 0.0
	for index in range(step_count):
		var t := (float(index) + 0.5) / float(step_count)
		var color := _sample_sky_gradient(top_color, middle_color, bottom_color, t)
		var next_y := VIEW_SIZE.y * float(index + 1) / float(step_count)
		draw_rect(Rect2(Vector2(0.0, previous_y), Vector2(VIEW_SIZE.x, next_y - previous_y + 0.5)), color)
		previous_y = next_y


func _sample_sky_gradient(top_color: Color, middle_color: Color, bottom_color: Color, t: float) -> Color:
	var smooth_t := t * t * (3.0 - 2.0 * t)
	if smooth_t < 0.58:
		return top_color.lerp(middle_color, smooth_t / 0.58)
	return middle_color.lerp(bottom_color, (smooth_t - 0.58) / 0.42)


func _draw_soft_sky_haze(center_ratio: float, half_height_ratio: float, color: Color) -> void:
	var half_height := VIEW_SIZE.y * half_height_ratio
	var center_y := VIEW_SIZE.y * center_ratio
	var top_y := center_y - half_height
	var step_count := 96
	var previous_y := top_y
	for index in range(step_count):
		var t := (float(index) + 0.5) / float(step_count)
		var distance_from_center := absf(t * 2.0 - 1.0)
		var alpha := color.a * pow(maxf(1.0 - distance_from_center, 0.0), 1.65)
		var next_y := top_y + half_height * 2.0 * float(index + 1) / float(step_count)
		draw_rect(
			Rect2(Vector2(0.0, previous_y), Vector2(VIEW_SIZE.x, next_y - previous_y + 0.5)),
			Color(color.r, color.g, color.b, alpha)
		)
		previous_y = next_y


func _background_speed_pressure() -> float:
	var min_speed := CRUISE_SPEED * SCENE_BACKGROUND_SPEED_MIN
	return clampf((velocity.length() - min_speed) / maxf(BOOST_SPEED - min_speed, 1.0), 0.0, 1.0)


func _draw_parallax_texture_layer(texture: Texture2D, y_ratio: float, parallax: Vector2, alpha: float, scale: float = 1.0, y_sway: float = 0.0, tint: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	if texture == null or alpha <= 0.001:
		return
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var draw_size: Vector2 = texture_size * scale
	var y_shift: float = -(camera_center.y - FLIGHT_START_POS.y) * parallax.y / maxf(camera_zoom, 0.001)
	var y: float = VIEW_SIZE.y * y_ratio - draw_size.y * 0.5 + y_shift + y_sway
	var color := Color(tint.r, tint.g, tint.b, clampf(alpha * tint.a, 0.0, 1.0))
	var phase := camera_center.x * parallax.x + time * 4.0 * parallax.x
	_draw_mirrored_texture_tile_x(texture, y, phase, color, scale)


func _draw_world_island_groups(speed_pressure: float, grounded_plane_fade: float) -> void:
	if 岛群整体透明度 <= 0.001 or grounded_plane_fade <= 0.001:
		return
	var horizon_y := _get_sea_horizon_y()
	var base_fade := 岛群整体透明度 * grounded_plane_fade * lerpf(1.0, 0.88, speed_pressure)
	for group in BACKGROUND_ISLAND_GROUPS:
		var depth := clampf(float(group.get("depth", 0.48)) * 岛群世界移动倍率, 0.08, 1.4)
		var screen_x := VIEW_SIZE.x * 0.5 + (float(group.get("x", FLIGHT_START_POS.x)) - camera_center.x) * depth / maxf(camera_zoom, 0.001)
		var unit_scale := float(group.get("scale", 0.76)) / maxf(camera_zoom, 0.001)
		var cull_width := 1120.0 * maxf(unit_scale, 0.3)
		if screen_x < -cull_width or screen_x > VIEW_SIZE.x + cull_width:
			continue
		var group_alpha := clampf(base_fade * float(group.get("alpha", 1.0)), 0.0, 1.0)
		if group_alpha <= 0.001:
			continue
		var sea_y := horizon_y + 岛群贴海偏移 + float(group.get("sea_offset", 0.0)) * unit_scale
		var flip_x := bool(group.get("mirror", false))
		var is_far_mountain := String(group.get("mountain", "mid")) == "far"
		var mountain_texture := mountain_far_ink_texture if is_far_mountain else mountain_mid_ink_texture
		var mountain_alpha := 岛群山体透明度 * (0.72 if is_far_mountain else 1.0) * group_alpha
		_draw_texture_anchored(
			sea_horizon_wash_texture,
			Vector2(screen_x, sea_y + 66.0 * unit_scale),
			Vector2(0.5, 0.56),
			0.40 * unit_scale,
			海面水洗透明度 * 0.62 * group_alpha,
			海面水洗染色,
			flip_x
		)
		_draw_texture_anchored(
			mountain_texture,
			Vector2(screen_x, sea_y - 12.0 * unit_scale),
			Vector2(0.5, 0.88),
			0.40 * unit_scale,
			mountain_alpha,
			Color(0.58, 0.70, 0.72, 1.0),
			flip_x
		)
		_draw_atlas_region_anchored(
			landmark_silhouettes_atlas_texture,
			int(group.get("landmark", 0)),
			Vector2(screen_x + 92.0 * unit_scale * (-1.0 if flip_x else 1.0), sea_y - 28.0 * unit_scale),
			float(group.get("landmark_scale", 0.50)) * unit_scale,
			地标建筑透明度 * group_alpha,
			Color(0.45, 0.58, 0.62, 1.0),
			flip_x
		)
		_draw_texture_anchored(
			far_island_chain_texture,
			Vector2(screen_x, sea_y + 18.0 * unit_scale),
			Vector2(0.5, 0.58),
			0.42 * unit_scale,
			远岛透明度 * group_alpha,
			远岛染色,
			flip_x
		)
		_draw_texture_anchored(
			sea_mist_foot_texture,
			Vector2(screen_x, sea_y + 30.0 * unit_scale),
			Vector2(0.5, 0.60),
			0.44 * unit_scale,
			岛群山脚雾透明度 * group_alpha,
			Color(0.88, 0.96, 1.0, 1.0),
			flip_x
		)
		_draw_texture_anchored(
			cloudsea_mid_texture,
			Vector2(screen_x, sea_y + 82.0 * unit_scale),
			Vector2(0.5, 0.52),
			0.40 * unit_scale,
			中景云透明度 * 0.74 * group_alpha,
			Color(0.86, 0.94, 0.98, 1.0),
			flip_x
		)


func _draw_texture_anchored(texture: Texture2D, anchor_pos: Vector2, anchor: Vector2, scale: float, alpha: float, tint: Color = Color(1.0, 1.0, 1.0, 1.0), flip_x: bool = false) -> void:
	if texture == null or alpha <= 0.001 or scale <= 0.001:
		return
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var draw_size := texture_size * scale
	var destination := Rect2(anchor_pos - Vector2(draw_size.x * anchor.x, draw_size.y * anchor.y), draw_size)
	var source := Rect2(Vector2.ZERO, texture_size)
	var color := Color(tint.r, tint.g, tint.b, clampf(alpha * tint.a, 0.0, 1.0))
	if flip_x:
		_draw_texture_rect_region_flipped_x(texture, destination, source, color)
	else:
		draw_texture_rect_region(texture, destination, source, color)


func _draw_atlas_region_anchored(texture: Texture2D, cell_index: int, anchor_pos: Vector2, scale: float, alpha: float, tint: Color = Color(1.0, 1.0, 1.0, 1.0), flip_x: bool = false) -> void:
	if texture == null or alpha <= 0.001 or scale <= 0.001:
		return
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var cell_size := Vector2(texture_size.x * 0.5, texture_size.y / 3.0)
	var safe_index := posmod(cell_index, 6)
	var row := floori(float(safe_index) / 2.0)
	var source := Rect2(Vector2(float(safe_index % 2) * cell_size.x, float(row) * cell_size.y), cell_size)
	var draw_size := cell_size * scale
	var destination := Rect2(anchor_pos - Vector2(draw_size.x * 0.5, draw_size.y * 0.86), draw_size)
	var color := Color(tint.r, tint.g, tint.b, clampf(alpha * tint.a, 0.0, 1.0))
	if flip_x:
		_draw_texture_rect_region_flipped_x(texture, destination, source, color)
	else:
		draw_texture_rect_region(texture, destination, source, color)


func _draw_sea_shimmer_from_atlas(speed_pressure: float, grounded_plane_fade: float) -> void:
	if sea_shimmer_lines_atlas_texture == null or grounded_plane_fade <= 0.001:
		return
	var texture_size: Vector2 = sea_shimmer_lines_atlas_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale := 1.0
	var y_shift: float = -(camera_center.y - FLIGHT_START_POS.y) * 0.034 / maxf(camera_zoom, 0.001)
	var y := VIEW_SIZE.y * 水纹高度比例 - texture_size.y * scale * 0.5 + y_shift + sin(time * 0.16) * 1.5
	var phase := camera_center.x * 0.30 + time * 1.8
	var alpha := 水纹透明度 * grounded_plane_fade * lerpf(1.0, 水纹高速保留比例, speed_pressure)
	_draw_mirrored_texture_tile_x(sea_shimmer_lines_atlas_texture, y, phase, Color(1.0, 1.0, 1.0, alpha), scale)


func _draw_far_landmarks_from_atlas(speed_pressure: float) -> void:
	var texture: Texture2D = landmark_silhouettes_atlas_texture
	if texture == null:
		return
	var texture_size: Vector2 = texture.get_size()
	var cell_size := Vector2(texture_size.x * 0.5, texture_size.y / 3.0)
	var spacing_world := 5200.0
	var visible_rect := _get_visible_world_rect()
	var start_index := int(floorf(visible_rect.position.x / spacing_world)) - 2
	var end_index := int(ceilf(visible_rect.end.x / spacing_world)) + 2
	var base_alpha := 0.045 * lerpf(1.0, 0.55, speed_pressure)
	for index in range(start_index, end_index + 1):
		var seed := float(index) * 17.37
		var world_x := float(index) * spacing_world + lerpf(-900.0, 900.0, _hash01(seed + 1.0))
		var screen_x := VIEW_SIZE.x * 0.5 + (world_x - camera_center.x) * 0.052 / maxf(camera_zoom, 0.001)
		if screen_x < -cell_size.x or screen_x > VIEW_SIZE.x + cell_size.x:
			continue
		var row := int(floorf(_hash01(seed + 2.0) * 3.0)) % 3
		var col := int(floorf(_hash01(seed + 3.0) * 2.0)) % 2
		var source := Rect2(Vector2(float(col) * cell_size.x, float(row) * cell_size.y), cell_size)
		var draw_scale := lerpf(0.35, 0.58, _hash01(seed + 4.0))
		var screen_y := VIEW_SIZE.y * lerpf(0.32, 0.50, _hash01(seed + 5.0))
		_draw_atlas_region(texture, source, Vector2(screen_x, screen_y), draw_scale, base_alpha)


func _draw_near_cloud_wisps_from_atlas(speed_pressure: float) -> void:
	var active_pressure := clampf(maxf(speed_pressure, throttle_energy * 0.32) - 0.05, 0.0, 1.0)
	if active_pressure <= 0.001:
		return
	var texture: Texture2D = near_cloud_wisps_atlas_texture
	if texture == null:
		return
	var texture_size: Vector2 = texture.get_size()
	var cell_size := Vector2(texture_size.x * 0.5, texture_size.y * 0.25)
	var visible_rect := _get_visible_world_rect()
	var spacing_world := 1250.0
	var start_index := int(floorf(visible_rect.position.x / spacing_world)) - 3
	var end_index := int(ceilf(visible_rect.end.x / spacing_world)) + 3
	for index in range(start_index, end_index + 1):
		var seed := float(index) * 31.11
		var world_x := float(index) * spacing_world + lerpf(-280.0, 280.0, _hash01(seed + 1.0))
		var world_y := visible_rect.position.y + visible_rect.size.y * lerpf(0.16, 0.84, _hash01(seed + 2.0))
		var screen_pos := Vector2(
			VIEW_SIZE.x * 0.5 + (world_x - camera_center.x) * 0.62 / maxf(camera_zoom, 0.001),
			VIEW_SIZE.y * 0.5 + (world_y - camera_center.y) * 0.40 / maxf(camera_zoom, 0.001)
		)
		if screen_pos.x < -cell_size.x or screen_pos.x > VIEW_SIZE.x + cell_size.x:
			continue
		if screen_pos.y < -cell_size.y or screen_pos.y > VIEW_SIZE.y + cell_size.y:
			continue
		var col := int(floorf(_hash01(seed + 3.0) * 2.0)) % 2
		var row := int(floorf(_hash01(seed + 4.0) * 4.0)) % 4
		var source := Rect2(Vector2(float(col) * cell_size.x, float(row) * cell_size.y), cell_size)
		var draw_scale := lerpf(0.42, 0.78, _hash01(seed + 5.0))
		var alpha := lerpf(0.018, 0.058, active_pressure) * lerpf(0.62, 1.0, _hash01(seed + 6.0))
		_draw_atlas_region(texture, source, screen_pos, draw_scale, alpha)


func _draw_atlas_region(texture: Texture2D, source: Rect2, center: Vector2, scale: float, alpha: float) -> void:
	if texture == null or alpha <= 0.001:
		return
	var destination_size := source.size * scale
	if destination_size.x <= 0.0 or destination_size.y <= 0.0:
		return
	var destination := Rect2(center - destination_size * 0.5, destination_size)
	draw_texture_rect_region(texture, destination, source, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))


func _draw_battlefield_boundary_layers() -> void:
	var top_y := _world_to_screen(Vector2(camera_center.x, PLAY_RECT.position.y)).y
	var bottom_y := _world_to_screen(Vector2(camera_center.x, PLAY_RECT.end.y)).y
	var left_x := _world_to_screen(Vector2(PLAY_RECT.position.x, camera_center.y)).x
	var right_x := _world_to_screen(Vector2(PLAY_RECT.end.x, camera_center.y)).x
	_draw_horizontal_boundary_layer(top_y, true, _boundary_screen_pressure(top_y, 0.0))
	_draw_horizontal_boundary_layer(bottom_y, false, _boundary_screen_pressure(bottom_y, VIEW_SIZE.y))
	_draw_vertical_boundary_layer(left_x, true, _boundary_screen_pressure(left_x, 0.0))
	_draw_vertical_boundary_layer(right_x, false, _boundary_screen_pressure(right_x, VIEW_SIZE.x))


func _boundary_screen_pressure(screen_value: float, edge_value: float) -> float:
	return clampf(1.0 - absf(screen_value - edge_value) / SCENE_BACKGROUND_BOUNDARY_SCREEN_RANGE, 0.0, 1.0)


func _draw_horizontal_boundary_layer(screen_y: float, is_top: bool, pressure: float) -> void:
	if pressure <= 0.001:
		return
	if boundary_cloud_wall_texture == null or boundary_rune_strip_texture == null:
		return
	var cloud_size: Vector2 = boundary_cloud_wall_texture.get_size()
	var cloud_y: float = screen_y - cloud_size.y * 0.24 if is_top else screen_y - cloud_size.y * 0.76
	var cloud_alpha := SCENE_BACKGROUND_BOUNDARY_ALPHA * pressure
	_draw_tiled_texture_x(boundary_cloud_wall_texture, cloud_y, 0.42, cloud_alpha)
	var rune_size: Vector2 = boundary_rune_strip_texture.get_size()
	var rune_y: float = screen_y + 58.0 if is_top else screen_y - rune_size.y - 58.0
	_draw_tiled_texture_x(boundary_rune_strip_texture, rune_y, 0.55, SCENE_BACKGROUND_RUNE_ALPHA * pressure)


func _draw_vertical_boundary_layer(screen_x: float, is_left: bool, pressure: float) -> void:
	if pressure <= 0.001:
		return
	if boundary_cloud_wall_texture == null or boundary_rune_strip_texture == null:
		return
	var cloud_width := 240.0
	var cloud_x := screen_x - cloud_width * 0.34 if is_left else screen_x - cloud_width * 0.66
	var cloud_rect := Rect2(Vector2(cloud_x, -20.0), Vector2(cloud_width, VIEW_SIZE.y + 40.0))
	var cloud_source := Rect2(Vector2.ZERO, boundary_cloud_wall_texture.get_size())
	draw_texture_rect_region(boundary_cloud_wall_texture, cloud_rect, cloud_source, Color(1.0, 1.0, 1.0, SCENE_BACKGROUND_BOUNDARY_ALPHA * 0.72 * pressure))
	var rune_width := 92.0
	var rune_x := screen_x + 52.0 if is_left else screen_x - rune_width - 52.0
	var rune_rect := Rect2(Vector2(rune_x, 0.0), Vector2(rune_width, VIEW_SIZE.y))
	var rune_source := Rect2(Vector2.ZERO, boundary_rune_strip_texture.get_size())
	draw_texture_rect_region(boundary_rune_strip_texture, rune_rect, rune_source, Color(1.0, 1.0, 1.0, SCENE_BACKGROUND_RUNE_ALPHA * 0.48 * pressure))


func _draw_tiled_texture_x(texture: Texture2D, y: float, parallax_x: float, alpha: float, scale: float = 1.0) -> void:
	if texture == null or alpha <= 0.001:
		return
	var texture_size: Vector2 = texture.get_size()
	var draw_size: Vector2 = texture_size * scale
	if draw_size.x <= 0.0 or draw_size.y <= 0.0:
		return
	var color := Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0))
	_draw_mirrored_texture_tile_x(texture, y, camera_center.x * parallax_x, color, scale)


func _draw_mirrored_texture_tile_x(texture: Texture2D, y: float, phase: float, color: Color, scale: float = 1.0) -> void:
	var texture_size: Vector2 = texture.get_size()
	var draw_size: Vector2 = texture_size * scale
	if draw_size.x <= 0.0 or draw_size.y <= 0.0:
		return
	var tile_width := draw_size.x * 2.0
	var x: float = -fposmod(phase, tile_width) - tile_width
	var source := Rect2(Vector2.ZERO, texture_size)
	while x < VIEW_SIZE.x + draw_size.x:
		draw_texture_rect_region(texture, Rect2(Vector2(x, y), draw_size), source, color)
		_draw_texture_rect_region_flipped_x(texture, Rect2(Vector2(x + draw_size.x, y), draw_size), source, color)
		x += tile_width


func _draw_texture_rect_region_flipped_x(texture: Texture2D, destination: Rect2, source: Rect2, color: Color) -> void:
	draw_set_transform(destination.position + Vector2(destination.size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(texture, Rect2(Vector2.ZERO, destination.size), source, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_world_guides() -> void:
	var visible_rect := _get_visible_world_rect()
	if not visible_rect.has_area():
		return
	var start_x: float = floorf(visible_rect.position.x / WORLD_GRID_STEP) * WORLD_GRID_STEP
	var x: float = start_x
	while x <= visible_rect.end.x + WORLD_GRID_STEP:
		var alpha := 0.14 if int(round(x / WORLD_GRID_STEP)) % 5 == 0 else 0.055
		draw_line(
			_world_to_screen(Vector2(x, visible_rect.position.y)),
			_world_to_screen(Vector2(x, visible_rect.end.y)),
			Color(0.72, 0.92, 0.95, alpha),
			1.0
		)
		x += WORLD_GRID_STEP

	var start_y: float = floorf(visible_rect.position.y / WORLD_GRID_STEP) * WORLD_GRID_STEP
	var y: float = start_y
	while y <= visible_rect.end.y + WORLD_GRID_STEP:
		var alpha := 0.12 if int(round(y / WORLD_GRID_STEP)) % 3 == 0 else 0.05
		draw_line(
			_world_to_screen(Vector2(visible_rect.position.x, y)),
			_world_to_screen(Vector2(visible_rect.end.x, y)),
			Color(0.72, 0.92, 0.95, alpha),
			1.0
		)
		y += WORLD_GRID_STEP

	var rect_screen := Rect2(_world_to_screen(PLAY_RECT.position), PLAY_RECT.size / maxf(camera_zoom, 0.001))
	draw_rect(rect_screen, Color(0.22, 0.64, 0.72, 0.32), false, 2.0)


func _draw_parallax_mountain_band(top_ratio: float, bottom_ratio: float, color: Color, offset: float, parallax: float, tile_width: float, ridge_height: float) -> void:
	var top := VIEW_SIZE.y * top_ratio
	var bottom := VIEW_SIZE.y * bottom_ratio
	var y_shift := -(camera_center.y - FLIGHT_START_POS.y) * parallax * 0.11 / maxf(camera_zoom, 0.001)
	var x := -fposmod(camera_center.x * parallax + offset * 113.0, tile_width) - tile_width
	while x < VIEW_SIZE.x + tile_width:
		var points := PackedVector2Array([Vector2(x, bottom + y_shift)])
		for i in range(9):
			var t := float(i) / 8.0
			var local_x := tile_width * t
			var noise := absf(sin((float(i) * 1.41 + offset) * 1.27)) * 0.72 + absf(sin(float(i) * 0.73 + offset * 2.1)) * 0.28
			var ridge := top + ridge_height * noise + y_shift
			points.append(Vector2(x + local_x, clampf(ridge, top + y_shift, bottom + y_shift - 18.0)))
		points.append(Vector2(x + tile_width, bottom + y_shift))
		draw_colored_polygon(points, color)
		x += tile_width


func _draw_cloud_wisp(origin: Vector2, length: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(12):
		var f := float(i) / 11.0
		points.append(origin + Vector2(length * (f - 0.5), sin(f * TAU + time * 0.18) * 7.0))
	draw_polyline(points, color, 5.0, true)


func _hash01(value: float) -> float:
	return fposmod(sin(value * 12.9898 + 78.233) * 43758.5453, 1.0)


func _draw_scene_speed_streaks() -> void:
	for streak in scene_speed_streaks:
		var age := float(streak.get("age", 0.0))
		var life := maxf(float(streak.get("life", SCENE_SPEED_STREAK_LIFE)), 0.001)
		var progress := clampf(age / life, 0.0, 1.0)
		var fade := sin(progress * PI) * pow(1.0 - progress, 0.22)
		if fade <= 0.01:
			continue
		var pos: Vector2 = streak.get("pos", camera_center)
		var dir: Vector2 = streak.get("dir", Vector2.RIGHT)
		if dir.length_squared() <= 0.0001:
			continue
		dir = dir.normalized()
		var length := float(streak.get("length", SCENE_SPEED_STREAK_MIN_LENGTH))
		var half := dir * length * 0.5
		var start := _world_to_screen(pos - half)
		var end := _world_to_screen(pos + half)
		var alpha := float(streak.get("alpha", 0.08)) * fade
		var width := float(streak.get("width", 1.5)) / maxf(camera_zoom, 0.001)
		draw_line(start, end, Color(1.0, 1.0, 1.0, alpha), width, true)


func _draw_boost_shockwaves() -> void:
	for fx in boost_shockwaves:
		var progress := _get_boost_shockwave_progress(fx)
		var fade := pow(1.0 - progress, 1.18)
		if fade <= 0.01:
			continue
		var dir: Vector2 = fx.get("dir", Vector2.RIGHT)
		if dir.length_squared() <= 0.0001:
			dir = Vector2.RIGHT
		else:
			dir = dir.normalized()
		var strength := clampf(float(fx.get("strength", 1.0)), 0.0, 1.0)
		var center := _get_boost_shockwave_center(fx, dir, progress)
		var eased := _ease_out_cubic(progress)
		var shape_pressure := 整体形状缩放 * lerpf(0.88, 1.08, strength)
		var forward_radius := lerpf(前后半径起始, 前后半径结束, eased) * shape_pressure
		var side_radius := lerpf(上下半径起始, 上下半径结束, eased) * shape_pressure
		var line_alpha := fade * strength * 线条透明度
		var halo := _color_with_scaled_alpha(外圈颜色, 0.06 * line_alpha)
		var ribbon := _color_with_scaled_alpha(线带颜色, 0.19 * line_alpha)
		var core := _color_with_scaled_alpha(核心线颜色, 0.30 * line_alpha)
		var halo_points := _build_boost_shockwave_arc_points(center, dir, forward_radius * 1.12, side_radius * 1.08, 0.0, TAU, 58, fx)
		var front_points := _build_boost_shockwave_arc_points(center, dir, forward_radius, side_radius, -1.18, 1.18, 24, fx)
		var rear_points := _build_boost_shockwave_arc_points(center, dir, forward_radius * 0.82, side_radius * 0.95, PI - 0.92, PI + 0.92, 18, fx)
		var inner_points := _build_boost_shockwave_arc_points(center - dir * 9.0, dir, forward_radius * 0.46, side_radius * 0.70, -1.38, 1.38, 22, fx)
		var camera_scale := 1.0 / maxf(camera_zoom, 0.001)
		draw_polyline(halo_points, halo, maxf(5.0 * fade * camera_scale, 0.8), true)
		draw_polyline(front_points, ribbon, maxf(2.4 * fade * camera_scale, 0.8), true)
		draw_polyline(front_points, core, maxf(0.9 * camera_scale, 0.55), true)
		draw_polyline(rear_points, _color_with_scaled_alpha(外圈颜色, 0.08 * fade * 线条透明度), maxf(1.2 * fade * camera_scale, 0.55), true)
		draw_polyline(inner_points, _color_with_scaled_alpha(线带颜色, 0.11 * fade * 线条透明度), maxf(0.8 * camera_scale, 0.45), true)
		_draw_boost_shockwave_fragments(center, dir, side_radius, progress, fade, fx)


func _build_boost_shockwave_arc_points(
	center: Vector2,
	dir: Vector2,
	forward_radius: float,
	side_radius: float,
	start_angle: float,
	end_angle: float,
	point_count: int,
	fx: Dictionary
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_count := maxi(point_count, 2)
	var side_dir := dir.rotated(PI * 0.5)
	var seed := float(fx.get("seed", 0.0))
	var age := float(fx.get("age", 0.0))
	for index in range(safe_count):
		var t := float(index) / float(safe_count - 1)
		var angle := lerpf(start_angle, end_angle, t)
		var hand_offset := sin(angle * 3.0 + seed * 1.7 + age * 18.0) * 2.6
		var world_point := center + dir * cos(angle) * forward_radius + side_dir * sin(angle) * (side_radius + hand_offset)
		points.append(_world_to_screen(world_point))
	return points


func _draw_boost_shockwave_fragments(center: Vector2, dir: Vector2, side_radius: float, progress: float, fade: float, fx: Dictionary) -> void:
	var side_dir := dir.rotated(PI * 0.5)
	var seed := float(fx.get("seed", 0.0)) * 19.31
	var camera_scale := 1.0 / maxf(camera_zoom, 0.001)
	for i in range(5):
		var lane := lerpf(-side_radius * 0.82, side_radius * 0.82, _hash01(seed + float(i) * 3.7))
		var back_offset := lerpf(12.0, 110.0, _hash01(seed + float(i) * 5.1))
		var length := lerpf(34.0, 118.0, _hash01(seed + float(i) * 7.3)) * lerpf(1.0, 0.42, progress)
		var side_sway := lerpf(-18.0, 18.0, _hash01(seed + float(i) * 11.2))
		var start := _world_to_screen(center - dir * back_offset + side_dir * lane)
		var end := _world_to_screen(center - dir * (back_offset + length) + side_dir * (lane + side_sway))
		var alpha := lerpf(0.025, 0.085, _hash01(seed + float(i) * 13.6)) * fade
		var width := lerpf(0.8, 2.2, _hash01(seed + float(i) * 17.4)) * camera_scale
		var color := _color_with_scaled_alpha(速度线颜色, alpha * 1.30 * 速度线透明度)
		if i % 3 == 0:
			color = _color_with_scaled_alpha(暗速度线颜色, alpha * 0.9 * 速度线透明度)
		draw_line(start, end, color, width, true)


func _draw_direction_switch_fx() -> void:
	for fx in direction_switch_fx:
		var age := float(fx.get("age", 0.0))
		var life := maxf(float(fx.get("life", DIRECTION_SWITCH_FX_LIFE)), 0.001)
		var progress := clampf(age / life, 0.0, 1.0)
		var fade := pow(1.0 - progress, 1.35)
		if fade <= 0.01:
			continue
		var strength := clampf(float(fx.get("strength", 0.5)), 0.0, 1.0)
		var points := _build_direction_switch_arc_points(fx, progress)
		if points.size() < 2:
			continue
		var width := lerpf(8.0, 24.0, strength) * fade / maxf(camera_zoom, 0.001)
		var halo := CYAN
		halo.a = 0.12 * fade * lerpf(0.65, 1.0, strength)
		var ribbon := Color(0.72, 1.0, 0.98, 0.26 * fade)
		var core := Color(0.98, 1.0, 0.94, 0.54 * fade)
		draw_polyline(points, halo, width * 2.4, true)
		draw_polyline(points, ribbon, width * 0.72, true)
		draw_polyline(points, core, maxf(width * 0.16, 1.5), true)
		if strength > 0.58:
			_draw_direction_switch_front_edge(fx, fade, strength)


func _build_direction_switch_arc_points(fx: Dictionary, progress: float) -> PackedVector2Array:
	var center: Vector2 = fx.get("center", visual_pos)
	var old_dir: Vector2 = fx.get("old_dir", Vector2.RIGHT)
	var new_dir: Vector2 = fx.get("new_dir", Vector2.RIGHT)
	if old_dir.length_squared() <= 0.0001:
		old_dir = Vector2.RIGHT
	else:
		old_dir = old_dir.normalized()
	if new_dir.length_squared() <= 0.0001:
		new_dir = Vector2.RIGHT
	else:
		new_dir = new_dir.normalized()
	var strength := clampf(float(fx.get("strength", 0.5)), 0.0, 1.0)
	var age := float(fx.get("age", 0.0))
	var radius := float(fx.get("radius", DIRECTION_SWITCH_ARC_RADIUS)) * (1.0 + progress * 0.12)
	var velocity_drift: Vector2 = fx.get("velocity", Vector2.ZERO)
	var center_drift := velocity_drift * age * 0.075
	var start_angle := (-old_dir).angle()
	var angle_delta := _signed_angle_between(-old_dir, -new_dir)
	var switch_direction := float(fx.get("direction", 1.0))
	var packed := PackedVector2Array()
	for index in range(11):
		var point_progress := float(index) / 10.0
		var eased := point_progress * point_progress * (3.0 - 2.0 * point_progress)
		var pulse := sin(point_progress * PI)
		var overshoot := switch_direction * 0.16 * strength * pulse * (1.0 - progress)
		var angle := start_angle + angle_delta * eased + overshoot
		var arc_radius := radius * (1.0 + 0.16 * pulse * strength)
		var world_point := center + center_drift + Vector2(cos(angle), sin(angle)) * arc_radius
		packed.append(_world_to_screen(world_point))
	return packed


func _draw_direction_switch_front_edge(fx: Dictionary, fade: float, strength: float) -> void:
	var center: Vector2 = fx.get("center", visual_pos)
	var new_dir: Vector2 = fx.get("new_dir", Vector2.RIGHT)
	if new_dir.length_squared() <= 0.0001:
		new_dir = Vector2.RIGHT
	else:
		new_dir = new_dir.normalized()
	var switch_direction := float(fx.get("direction", 1.0))
	var age := float(fx.get("age", 0.0))
	var velocity_drift: Vector2 = fx.get("velocity", Vector2.ZERO)
	var side_dir := new_dir.rotated(switch_direction * PI * 0.5)
	var base := center + velocity_drift * age * 0.055 + new_dir * lerpf(24.0, 52.0, strength)
	var start := _world_to_screen(base - new_dir * lerpf(20.0, 34.0, strength) - side_dir * 6.0)
	var end := _world_to_screen(base + new_dir * lerpf(22.0, 42.0, strength) + side_dir * 8.0)
	draw_line(start, end, Color(0.98, 1.0, 0.94, 0.36 * fade), lerpf(2.0, 4.0, strength) / maxf(camera_zoom, 0.001), true)


func _draw_afterimages() -> void:
	for image in afterimages:
		var texture := image.get("texture") as Texture2D
		if texture == null:
			continue
		var age := float(image["age"])
		var life := clampf(1.0 - age / maxf(float(image.get("life", 0.3)), 0.001), 0.0, 1.0)
		var frame_rect: Rect2 = image.get("source", Rect2())
		var draw_scale: Vector2 = image.get("scale", Vector2.ONE)
		var facing := float(image.get("facing", 1.0))
		var rotation := float(image.get("rotation", 0.0))
		var stored_velocity: Vector2 = image.get("velocity", Vector2.ZERO)
		var drift := stored_velocity.normalized() * -24.0 * age
		var camera_scale := 1.0 / maxf(camera_zoom, 0.001)
		var screen_offset: Vector2 = image.get("screen_offset", Vector2.ZERO)
		var pos := _world_to_screen(Vector2(image["pos"]) + drift) + screen_offset * camera_scale
		var stretch := 1.0 + age * (0.32 + float(image.get("intensity", 0.0)) * 0.18)
		var source_size := frame_rect.size
		if source_size.x <= 0.0 or source_size.y <= 0.0:
			source_size = texture.get_size()
		var destination := Rect2(-source_size * draw_scale * stretch * camera_scale * 0.5, source_size * draw_scale * stretch * camera_scale)
		var color := Color(0.46, 1.0, 1.0, float(image.get("alpha", 0.06)) * life * float(image.get("intensity", 1.0)))
		draw_set_transform(pos, rotation, Vector2(facing, 1.0))
		draw_texture_rect_region(texture, destination, frame_rect, color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_debug() -> void:
	var clip := _current_clip()
	var material_label := "green key" if background_key_enabled else "raw bg"
	var speed_label := "boost" if speed_mode == SPEED_MODE_BOOST else "cruise"
	var control_label := "direct intent" if control_mode == CONTROL_MODE_DIRECT_INTENT else "steer throttle"
	var sword_label := _current_skeleton_sword_style_label()
	var visual_label := "sheet"
	if USE_GEMINI_8WAY_CRUISE:
		if _uses_skeleton_eight_way():
			visual_label = "V4 skeleton %s sword:%s" % [_current_eight_way_name(), sword_label]
		elif _uses_ink_part_eight_way():
			visual_label = "V5 ink parts %s" % _current_eight_way_name()
		elif _uses_google_part_eight_way():
			visual_label = "%s %s" % [_current_eight_way_set_label(), _current_eight_way_name()]
		elif _use_v1_sequence_visual():
			if _use_v1_static_direction_visual():
				visual_label = "V1 static %s" % _current_eight_way_name()
			else:
				visual_label = "V1 sequence %s" % String(clip["name"])
		elif _uses_v3_face_eight_way():
			visual_label = "Gemini 2way %s %s" % [_current_eight_way_set_label(), _current_eight_way_name()]
		else:
			visual_label = "Gemini 4way %s %s" % [_current_eight_way_set_label(), _current_eight_way_name()]
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 32.0), "Yujian flight V4  |  field %.0fx%.0f  |  WASD intent  Space boost  F3 mode  K key  F2 panel  F4 pose  F5 hair  F6 sword:%s  F9 guides:%s  T demo" % [FLIGHT_TEST_HORIZONTAL_SCALE, FLIGHT_TEST_VERTICAL_SCALE, sword_label, "on" if show_debug_guides else "off"], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16.0, Color(0.91, 0.96, 0.95, 0.84))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 56.0), "control: %s  clip: %s  frame: %d/%d  visual: %s  mode: %s  speed: %.1f  throttle %.2f slip %.2f carve %.2f turn %.0fdeg  body %.0fdeg visual %.0fdeg local %.0fdeg target %.0fdeg  zoom %.2f  pos %.0f,%.0f  %s" % [control_label, String(clip["name"]), frame_index, int(clip["frames"]) - 1, visual_label, speed_label, velocity.length(), throttle_energy, slip_energy, carve_energy, rad_to_deg(heading_angle_delta), rad_to_deg(body_heading.angle()), rad_to_deg(visual_heading.angle()), rad_to_deg(eight_way_local_rotation), rad_to_deg(target_heading.angle()), camera_zoom, flight_pos.x, flight_pos.y, material_label], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.72, 0.86, 0.86, 0.76))


func _safe_velocity_dir() -> Vector2:
	if velocity.length_squared() > 0.001:
		return velocity.normalized()
	return body_heading.normalized()


func _damp_float(current: float, target: float, half_life: float, delta: float) -> float:
	if half_life <= 0.0:
		return target
	var decay := pow(0.5, delta / half_life)
	return target + (current - target) * decay


func _ease_out_cubic(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


func _damp_angle(current: float, target: float, half_life: float, delta: float) -> float:
	var delta_angle := wrapf(target - current, -PI, PI)
	return wrapf(_damp_float(0.0, delta_angle, half_life, delta) + current, -PI, PI)


func _damp_vector2(current: Vector2, target: Vector2, half_life: float, delta: float) -> Vector2:
	return Vector2(
		_damp_float(current.x, target.x, half_life, delta),
		_damp_float(current.y, target.y, half_life, delta)
	)
