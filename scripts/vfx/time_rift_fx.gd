extends Node2D
class_name TimeRiftFx

const DEFAULT_PROFILE = preload("res://resources/vfx/time_rift_profile_default.tres")
const DOMAIN_ART_SCENE = preload("res://scenes/vfx/TimeStopDomainArt.tscn")
const BRUSH_SWEEP_TEXTURES := [
	preload("res://resources/vfx/ink/brush/brush_sweep_01.png"),
	preload("res://resources/vfx/ink/brush/brush_sweep_02.png"),
]
const PAPER_GRAY_TEXTURE = preload("res://resources/vfx/ink/paper/paper_gray_01.png")
const PAPER_FIBER_TEXTURE = preload("res://resources/vfx/ink/paper/paper_fiber_01.png")
const MIST_TEXTURE = preload("res://resources/vfx/ink/mist/ink_mist_01.png")
const BLOT_TEXTURES := [
	preload("res://resources/vfx/ink/blot/ink_blot_01.png"),
	preload("res://resources/vfx/ink/blot/ink_blot_02.png"),
	preload("res://resources/vfx/ink/blot/ink_blot_03.png"),
]
const CRACK_DARK_TEXTURE = preload("res://resources/vfx/ink/crack/ink_crack_01.png")
const CRACK_LIGHT_TEXTURE = preload("res://resources/vfx/ink/crack/ink_crack_02.png")
const DROPLET_TEXTURE = preload("res://resources/vfx/ink/droplet/ink_droplets_01.png")
const SWORD_STREAK_TEXTURE = preload("res://resources/vfx/ink/sword/sword_streak_ink_01.png")
const DOMAIN_MARKER_POOL_SIZE := 22
const DOMAIN_RAY_POOL_SIZE := 7

enum Phase {
	IDLE,
	ENTERING,
	SUSTAINING,
	RECOVERING,
}

@export_group("夜界控制")
@export var 启用 := true
@export var 背景层绘制 := true
@export var 夜界配置: Resource = DEFAULT_PROFILE
@export_range(-16, 16, 1) var 画布层级 := 0
@export_range(0.0, 4.0, 0.01) var 背景氛围强度 := 1.15
@export_range(0.0, 4.0, 0.01) var 背景暗场强度 := 1.34
@export_range(0.0, 4.0, 0.01) var 背景纸纹强度 := 0.42
@export_range(0.0, 4.0, 0.01) var 入场墨爆强度 := 1.0
@export_range(0.0, 4.0, 0.01) var 冻结标记强度 := 0.72
@export_range(0.0, 4.0, 0.01) var 剑光放射强度 := 0.72
@export_group("夜界构图")
@export var 泼墨跟随出鞘方向 := true
@export_range(-180.0, 180.0, 1.0) var 泼墨固定角度 := -18.0
@export_range(0.1, 4.0, 0.01) var 泼墨轴向长度倍率 := 1.0
@export_range(0.1, 2.0, 0.01) var 泼墨中心前推倍率 := 1.0
@export var 背景笔触固定构图 := true
@export_range(-180.0, 180.0, 1.0) var 背景笔触固定角度 := -12.0
@export_range(0.0, 4.0, 0.01) var 背景笔触偏移倍率 := 1.0
@export_group("夜界暗场")
@export var 暗场颜色 := Color(0.0, 0.002, 0.008, 1.0)
@export_range(0.0, 1.0, 0.01) var 暗场持续透明度 := 0.68
@export_range(0.0, 1.0, 0.01) var 暗场入场透明度 := 0.34
@export_range(0.0, 0.5, 0.01) var 暗场呼吸透明度 := 0.045
@export_range(0.0, 8.0, 0.01) var 暗场呼吸速度 := 0.55
@export var 冷雾颜色 := Color(0.018, 0.060, 0.095, 1.0)
@export_range(0.0, 1.0, 0.01) var 冷雾透明度 := 0.075
@export var 入场冷光颜色 := Color(0.50, 0.72, 0.92, 1.0)
@export_range(0.0, 1.0, 0.01) var 入场冷光透明度 := 0.045
@export var 暗角启用 := true
@export_range(0.0, 4.0, 0.01) var 暗角透明倍率 := 1.45
@export_range(0.1, 4.0, 0.01) var 暗角厚度倍率 := 1.15
@export_range(1, 12, 1) var 暗角层数 := 5
@export_group("夜界纸纹素材")
@export var 纸纹暗面贴图: Texture2D = PAPER_GRAY_TEXTURE
@export var 纸纹纤维贴图: Texture2D = PAPER_FIBER_TEXTURE
@export var 纸纹暗面颜色 := Color(0.010, 0.015, 0.020, 1.0)
@export var 纸纹纤维颜色 := Color(0.28, 0.42, 0.52, 1.0)
@export_range(0.0, 1.0, 0.01) var 纸纹暗面透明度 := 0.16
@export_range(0.0, 1.0, 0.01) var 纸纹纤维透明度 := 0.075
@export_range(0.25, 3.0, 0.01) var 纸纹宽度倍率 := 1.0
@export_range(0.25, 3.0, 0.01) var 纸纹高度倍率 := 1.0
@export_group("夜界笔触素材")
@export var 笔触贴图一: Texture2D = preload("res://resources/vfx/ink/brush/brush_sweep_01.png")
@export var 笔触贴图二: Texture2D = preload("res://resources/vfx/ink/brush/brush_sweep_02.png")
@export var 雾纹贴图: Texture2D = MIST_TEXTURE
@export var 背景笔触主色 := Color(0.045, 0.090, 0.130, 1.0)
@export var 背景笔触副色 := Color(0.035, 0.072, 0.105, 1.0)
@export var 雾纹颜色 := Color(0.18, 0.34, 0.46, 1.0)
@export_range(0.1, 3.0, 0.01) var 背景笔触宽度倍率 := 1.0
@export_range(0.1, 3.0, 0.01) var 背景笔触高度倍率 := 1.0
@export_range(0.0, 3.0, 0.01) var 背景笔触持续透明倍率 := 1.0
@export_range(0.0, 3.0, 0.01) var 背景笔触入场透明倍率 := 1.0
@export_range(0.1, 3.0, 0.01) var 雾纹宽度倍率 := 1.0
@export_range(0.1, 3.0, 0.01) var 雾纹高度倍率 := 1.0
@export_range(0.0, 3.0, 0.01) var 雾纹透明倍率 := 1.0
@export_group("夜界泼墨素材")
@export var 墨斑贴图一: Texture2D = preload("res://resources/vfx/ink/blot/ink_blot_01.png")
@export var 墨斑贴图二: Texture2D = preload("res://resources/vfx/ink/blot/ink_blot_02.png")
@export var 墨斑贴图三: Texture2D = preload("res://resources/vfx/ink/blot/ink_blot_03.png")
@export var 裂痕暗纹贴图: Texture2D = CRACK_DARK_TEXTURE
@export var 裂痕亮纹贴图: Texture2D = CRACK_LIGHT_TEXTURE
@export var 墨滴贴图: Texture2D = DROPLET_TEXTURE
@export var 墨滴贴图二: Texture2D = preload("res://resources/vfx/ink/droplet/ink_droplets_02.png")
@export var 入场墨斑暗色 := Color(0.0, 0.010, 0.020, 1.0)
@export var 入场墨斑冷色 := Color(0.030, 0.070, 0.095, 1.0)
@export var 裂痕暗纹颜色 := Color(0.012, 0.034, 0.052, 1.0)
@export var 裂痕亮纹颜色 := Color(0.58, 0.84, 1.0, 1.0)
@export var 墨滴暗色 := Color(0.02, 0.045, 0.065, 1.0)
@export_range(0.12, 2.0, 0.01) var 入场泼墨持续时间 := 0.78
@export_range(0.0, 1.0, 0.01) var 入场泼墨残留倍率 := 0.10
@export_range(0.1, 4.0, 0.01) var 入场墨斑大小倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 入场墨斑透明倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 裂痕长度倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 裂痕宽度倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 裂痕暗纹透明倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 裂痕亮纹透明倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 墨滴大小倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 墨滴透明倍率 := 1.0
@export_group("夜界剑光")
@export var 剑光贴图: Texture2D = SWORD_STREAK_TEXTURE
@export var 剑光主色 := Color(0.48, 0.80, 1.0, 1.0)
@export var 剑光核心色 := Color(0.76, 0.93, 1.0, 1.0)
@export_range(0.1, 4.0, 0.01) var 剑光长度倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 剑光宽度倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 剑光持续透明倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 剑光入场透明倍率 := 1.0
@export_range(0, 24, 1) var 剑光游丝数量 := 7
@export_range(0.0, 4.0, 0.01) var 剑光游丝漂移幅度倍率 := 1.0
@export_range(0.0, 6.0, 0.01) var 剑光游丝漂移速度 := 0.6
@export_group("夜界冻结标记")
@export_range(0, 64, 1) var 冻结标记最大数量 := 22
@export var 冻结墨色 := Color(0.0, 0.006, 0.014, 1.0)
@export var 冻结环颜色 := Color(0.48, 0.86, 1.0, 1.0)
@export var 冻结环亮色 := Color(0.78, 0.94, 1.0, 1.0)
@export_range(0.1, 4.0, 0.01) var 冻结墨斑大小倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 冻结墨斑透明倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 冻结亮斑大小倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 冻结亮斑透明倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 冻结环半径倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 冻结环透明倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 冻结环线宽倍率 := 1.0
@export_range(0.0, 2.0, 0.01) var 冻结环旋转速度 := 0.12
@export_range(0.0, 6.0, 0.01) var 冻结标记呼吸速度 := 1.4
@export var 弹丸冻结刻痕启用 := true
@export_group("夜界时场线")
@export var 时场圆弧启用 := true
@export var 时场圆弧颜色 := Color(0.42, 0.74, 0.96, 1.0)
@export var 时场暗弧颜色 := Color(0.16, 0.34, 0.48, 1.0)
@export_range(0, 12, 1) var 时场圆弧数量 := 3
@export_range(0.0, 4.0, 0.01) var 时场圆弧透明倍率 := 0.55
@export_range(0.1, 3.0, 0.01) var 时场圆弧半径倍率 := 1.08
@export_range(0.1, 4.0, 0.01) var 时场圆弧线宽倍率 := 1.25
@export_range(0.0, 8.0, 0.01) var 时场圆弧呼吸速度 := 1.35
@export var 时场刻度颜色 := Color(0.54, 0.84, 1.0, 1.0)
@export_range(0, 64, 1) var 时场刻度数量 := 0
@export_range(0.0, 4.0, 0.01) var 时场刻度透明倍率 := 0.0
@export_range(0.1, 4.0, 0.01) var 时场刻度长度倍率 := 1.0
@export_range(-2.0, 2.0, 0.01) var 时场刻度旋转速度 := 0.0
@export_group("")

var phase: Phase = Phase.IDLE
var phase_timer := 0.0
var effect_time := 0.0
var active_strength := 0.0
var recover_start_strength := 0.0
var enter_progress := 0.0
var recover_progress := 0.0
var player_screen := Vector2.ZERO
var anchor_screen := Vector2.ZERO
var focus_screen := Vector2.ZERO
var domain_axis := Vector2.RIGHT
var splash_player_screen := Vector2.ZERO
var splash_anchor_screen := Vector2.ZERO
var splash_focus_screen := Vector2.ZERO
var splash_center_screen := Vector2.ZERO
var splash_axis := Vector2.RIGHT
var splash_length := 760.0
var freeze_markers: Array = []

var fx_layer: CanvasLayer
var domain_art: Control
var domain_anim: AnimationPlayer
var domain_wash: ColorRect
var domain_wash_material: ShaderMaterial
var domain_nodes: Dictionary = {}
var domain_marker_dark_pool: Array[Sprite2D] = []
var domain_marker_light_pool: Array[Sprite2D] = []
var domain_ray_pool: Array[Sprite2D] = []
var domain_additive_material: CanvasItemMaterial


func _ready() -> void:
	_ensure_nodes()
	_apply_visibility(false)
	set_process(true)


func enter_from_screen(entry_screen: Vector2, direction: Vector2, player_screen_pos: Vector2) -> void:
	if not 启用:
		return
	_ensure_nodes()
	var slash_direction := direction.normalized()
	if slash_direction.is_zero_approx():
		slash_direction = Vector2.RIGHT
	player_screen = player_screen_pos
	anchor_screen = entry_screen
	focus_screen = entry_screen
	domain_axis = slash_direction
	_capture_splash_layout(entry_screen, slash_direction, player_screen_pos)
	phase = Phase.ENTERING
	phase_timer = 0.0
	effect_time = 0.0
	active_strength = 0.0
	recover_start_strength = _profile_float("进入强度", 0.92)
	enter_progress = 0.0
	recover_progress = 0.0
	_apply_visibility(true)
	_play_domain_animation("enter")
	_restart_domain_entry_particles()
	_update_domain_art()


func trace_to_screen(sword_screen_pos: Vector2, player_screen_pos: Vector2 = Vector2.INF) -> void:
	if phase == Phase.IDLE or phase == Phase.RECOVERING:
		return
	if player_screen_pos.x != INF and player_screen_pos.y != INF:
		player_screen = player_screen_pos
	focus_screen = sword_screen_pos
	_update_domain_art()


func begin_recover(player_screen_pos: Vector2 = Vector2.INF) -> void:
	if phase == Phase.IDLE:
		return
	if player_screen_pos.x != INF and player_screen_pos.y != INF:
		player_screen = player_screen_pos
	phase = Phase.RECOVERING
	phase_timer = 0.0
	recover_start_strength = maxf(active_strength, _profile_float("进入强度", 0.92) * 0.42)
	recover_progress = 0.0
	_apply_visibility(true)
	_play_domain_animation("recover")
	_update_domain_art()


func cancel_immediate() -> void:
	phase = Phase.IDLE
	phase_timer = 0.0
	effect_time = 0.0
	active_strength = 0.0
	enter_progress = 0.0
	recover_progress = 0.0
	freeze_markers.clear()
	_apply_visibility(false)
	_hide_domain_runtime_pools()
	_update_domain_material_parameters(_get_safe_viewport_size())


func set_player_screen(player_screen_pos: Vector2) -> void:
	player_screen = player_screen_pos
	if phase != Phase.IDLE:
		_update_domain_art()


func set_freeze_markers(markers: Array) -> void:
	freeze_markers.clear()
	for marker in markers:
		if marker is Dictionary:
			freeze_markers.append(marker.duplicate())


func is_active() -> bool:
	return phase != Phase.IDLE


func draw_background_effect(draw_target: CanvasItem) -> void:
	if draw_target == null or not 背景层绘制 or phase == Phase.IDLE:
		return
	var state_strength := clampf(active_strength, 0.0, 1.0) * (1.0 - recover_progress * 0.86)
	var fade := clampf(state_strength * 背景氛围强度, 0.0, 1.0)
	if fade <= 0.004 and state_strength <= 0.004:
		return
	var viewport_size := _get_safe_viewport_size()
	var axis := _get_splash_axis()
	var normal := Vector2(-axis.y, axis.x)
	var angle := axis.angle()
	var line_distance := maxf(splash_length * 泼墨轴向长度倍率, 320.0)
	var center := splash_center_screen
	var brush_axis := _get_background_brush_axis()
	var brush_normal := Vector2(-brush_axis.y, brush_axis.x)
	var brush_angle := brush_axis.angle()
	var brush_offset := 背景笔触偏移倍率
	var splash_stamp := _get_splash_stamp_strength()
	var ink_stamp := clampf(splash_stamp * 入场墨爆强度, 0.0, 1.0)
	var splash_residue := fade * 入场泼墨残留倍率
	_draw_background_state_wash(draw_target, viewport_size, state_strength, fade, ink_stamp)
	_draw_background_time_field(draw_target, center, viewport_size, fade)
	var brush_hold_alpha := fade * 背景笔触持续透明倍率
	var brush_entry_alpha := ink_stamp * 背景笔触入场透明倍率
	_draw_background_sprite(draw_target, _get_brush_texture(0), viewport_size * Vector2(0.52, 0.24) + brush_normal * 24.0 * brush_offset, brush_angle - 0.08, Vector2(viewport_size.x / 620.0 * 背景笔触宽度倍率, viewport_size.y / 1320.0 * 背景笔触高度倍率), _color_with_alpha(背景笔触主色, 0.050 * brush_hold_alpha + 0.090 * brush_entry_alpha))
	_draw_background_sprite(draw_target, _get_brush_texture(1), viewport_size * Vector2(0.61, 0.48) - brush_normal * 36.0 * brush_offset, brush_angle + 0.10, Vector2(viewport_size.x / 560.0 * 背景笔触宽度倍率, viewport_size.y / 1180.0 * 背景笔触高度倍率), _color_with_alpha(背景笔触副色, 0.054 * brush_hold_alpha + 0.10 * brush_entry_alpha))
	_draw_background_sprite(draw_target, _get_brush_texture(0), viewport_size * Vector2(0.34, 0.67) + brush_normal * 18.0 * brush_offset, brush_angle - 0.34, Vector2(viewport_size.x / 760.0 * 背景笔触宽度倍率, viewport_size.y / 1550.0 * 背景笔触高度倍率), _color_with_alpha(背景笔触主色, 0.040 * brush_hold_alpha + 0.062 * brush_entry_alpha))
	_draw_background_sprite(draw_target, _get_brush_texture(1), viewport_size * Vector2(0.78, 0.30) - brush_normal * 12.0 * brush_offset, brush_angle + 0.46, Vector2(viewport_size.x / 910.0 * 背景笔触宽度倍率, viewport_size.y / 1800.0 * 背景笔触高度倍率), _color_with_alpha(背景笔触副色, 0.038 * brush_hold_alpha + 0.052 * brush_entry_alpha))
	_draw_background_sprite_sized(draw_target, 雾纹贴图, center - brush_axis * line_distance * 0.06 + brush_normal * 18.0 * brush_offset, brush_angle - 0.12, line_distance * 1.18 * 雾纹宽度倍率, 300.0 * 雾纹高度倍率, _color_with_alpha(雾纹颜色, (0.060 * fade + 0.052 * ink_stamp) * 雾纹透明倍率))
	_draw_background_sprite_sized(draw_target, _get_blot_texture(0), center - axis * line_distance * 0.08 + normal * 34.0, angle - 0.34, 310.0 * 入场墨斑大小倍率, 220.0 * 入场墨斑大小倍率, _color_with_alpha(入场墨斑暗色, 0.15 * ink_stamp * 入场墨斑透明倍率))
	_draw_background_sprite_sized(draw_target, _get_blot_texture(1), center + axis * line_distance * 0.12 - normal * 48.0, angle + 0.26, 230.0 * 入场墨斑大小倍率, 165.0 * 入场墨斑大小倍率, _color_with_alpha(入场墨斑冷色, 0.11 * ink_stamp * 入场墨斑透明倍率))
	_draw_background_sprite_sized(draw_target, 裂痕暗纹贴图, center + normal * 8.0, angle, line_distance * 1.32 * 裂痕长度倍率, 210.0 * 裂痕宽度倍率, _color_with_alpha(裂痕暗纹颜色, (0.060 * splash_residue + 0.30 * ink_stamp) * 裂痕暗纹透明倍率))
	_draw_background_sprite_sized(draw_target, 裂痕暗纹贴图, center, angle, line_distance * 1.12 * 裂痕长度倍率, 168.0 * 裂痕宽度倍率, _color_with_alpha(裂痕暗纹颜色, (0.064 * splash_residue + 0.34 * ink_stamp) * 裂痕暗纹透明倍率))
	_draw_background_sprite_sized(draw_target, 裂痕亮纹贴图, center + normal * 3.0, angle + 0.018, line_distance * 0.95 * 裂痕长度倍率, 88.0 * 裂痕宽度倍率, _color_with_alpha(裂痕亮纹颜色, (0.055 * splash_residue + 0.18 * ink_stamp) * 剑光放射强度 * 裂痕亮纹透明倍率))
	_draw_background_sprite_sized(draw_target, 剑光贴图, center + axis * 20.0, angle, line_distance * 1.32 * 剑光长度倍率, 40.0 * 剑光宽度倍率, _color_with_alpha(剑光主色, (0.12 * fade * 剑光持续透明倍率 + 0.20 * ink_stamp * 剑光入场透明倍率) * 剑光放射强度))
	_draw_background_sprite_sized(draw_target, 剑光贴图, center - axis * 36.0 - normal * 9.0, angle - 0.012, line_distance * 0.72 * 剑光长度倍率, 20.0 * 剑光宽度倍率, _color_with_alpha(剑光核心色, (0.092 * fade * 剑光持续透明倍率 + 0.12 * ink_stamp * 剑光入场透明倍率) * 剑光放射强度))
	_draw_background_sprite_sized(draw_target, 墨滴贴图, center - axis * line_distance * 0.14 + normal * 66.0, angle - 0.42, 210.0 * 墨滴大小倍率, 150.0 * 墨滴大小倍率, _color_with_alpha(墨滴暗色, (0.034 * splash_residue + 0.12 * ink_stamp) * 墨滴透明倍率))
	_draw_background_sprite_sized(draw_target, 墨滴贴图二, center + axis * line_distance * 0.18 - normal * 76.0, angle + 0.34, 185.0 * 墨滴大小倍率, 135.0 * 墨滴大小倍率, _color_with_alpha(裂痕亮纹颜色, 0.060 * ink_stamp * 墨滴透明倍率 * 剑光放射强度))
	_draw_background_freeze_markers(draw_target, fade)
	_draw_background_rays(draw_target, fade)
	draw_target.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _process(delta: float) -> void:
	if phase == Phase.IDLE:
		return
	effect_time += delta
	phase_timer += delta
	match phase:
		Phase.ENTERING:
			enter_progress = clampf(phase_timer / maxf(_profile_float("进入时长", 0.18), 0.001), 0.0, 1.0)
			active_strength = _profile_float("进入强度", 0.92) * _smooth01(enter_progress)
			if enter_progress >= 1.0:
				phase = Phase.SUSTAINING
				phase_timer = 0.0
				active_strength = _profile_float("进入强度", 0.92)
				_play_domain_animation("hold")
		Phase.SUSTAINING:
			enter_progress = 1.0
			recover_progress = 0.0
			active_strength = move_toward(active_strength, _profile_float("进入强度", 0.92), delta * 3.5)
		Phase.RECOVERING:
			enter_progress = 1.0
			recover_progress = clampf(phase_timer / maxf(_profile_float("愈合时长", 0.68), 0.001), 0.0, 1.0)
			active_strength = recover_start_strength * (1.0 - pow(recover_progress, 1.55))
			if recover_progress >= 1.0:
				cancel_immediate()
				return
	_update_domain_art()


func _ensure_nodes() -> void:
	if 夜界配置 == null:
		夜界配置 = DEFAULT_PROFILE
	if 背景层绘制:
		if domain_art != null:
			domain_art.visible = false
			_hide_domain_runtime_pools()
		return
	if fx_layer != null:
		fx_layer.layer = 画布层级
		_ensure_domain_art()
		return
	fx_layer = CanvasLayer.new()
	fx_layer.name = "TimeStopDomainLayer"
	fx_layer.layer = 画布层级
	add_child(fx_layer)
	_ensure_domain_art()


func _apply_visibility(is_visible: bool) -> void:
	_ensure_nodes()
	if domain_art != null:
		domain_art.visible = is_visible and not 背景层绘制
	if not is_visible:
		_hide_domain_runtime_pools()


func _ensure_domain_art() -> void:
	if domain_art != null or fx_layer == null:
		return
	domain_art = DOMAIN_ART_SCENE.instantiate() as Control
	if domain_art == null:
		return
	domain_art.name = "TimeStopDomainArtRuntime"
	domain_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	domain_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	domain_art.offset_left = 0.0
	domain_art.offset_top = 0.0
	domain_art.offset_right = 0.0
	domain_art.offset_bottom = 0.0
	domain_art.visible = false
	fx_layer.add_child(domain_art)

	domain_anim = domain_art.get_node_or_null("AnimationPlayer") as AnimationPlayer
	domain_wash = domain_art.get_node_or_null("Wash") as ColorRect
	if domain_wash != null:
		domain_wash_material = domain_wash.material as ShaderMaterial
	domain_additive_material = CanvasItemMaterial.new()
	domain_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_cache_domain_nodes()
	_hide_static_domain_targets()
	_build_domain_marker_pool()
	_build_domain_ray_pool()
	_hide_domain_runtime_pools()


func _cache_domain_nodes() -> void:
	domain_nodes.clear()
	var paths: Dictionary = {
		"paper": "Paper",
		"fiber": "Fiber",
		"brush_a": "SpriteLayer/BackgroundBrush/BrushA",
		"brush_b": "SpriteLayer/BackgroundBrush/BrushB",
		"brush_c": "SpriteLayer/BackgroundBrush/BrushC",
		"brush_d": "SpriteLayer/BackgroundBrush/BrushD",
		"mist_near": "SpriteLayer/MistLayer/MistNear",
		"mist_far": "SpriteLayer/MistLayer/MistFar",
		"target_layer": "SpriteLayer/TargetLayer",
		"entry_layer": "SpriteLayer/EntryLayer",
		"crack_shadow": "SpriteLayer/EntryLayer/CrackShadow",
		"crack_dark": "SpriteLayer/EntryLayer/CrackDark",
		"crack_light": "SpriteLayer/EntryLayer/CrackLight",
		"droplet_a": "SpriteLayer/EntryLayer/DropletDecalA",
		"droplet_b": "SpriteLayer/EntryLayer/DropletDecalB",
		"streak_main": "SpriteLayer/EntryLayer/StreakMain",
		"streak_core": "SpriteLayer/EntryLayer/StreakCore",
		"droplet_particles": "SpriteLayer/EntryLayer/DropletParticles",
		"sustain_layer": "SpriteLayer/SustainLayer",
		"halo_player": "SpriteLayer/SustainLayer/FreezeHaloPlayer",
		"halo_focus": "SpriteLayer/SustainLayer/FreezeHaloFocus",
		"recover_flow_main": "SpriteLayer/SustainLayer/RecoverFlowMain",
		"recover_flow_core": "SpriteLayer/SustainLayer/RecoverFlowCore",
		"slow_ink_drift": "SpriteLayer/SustainLayer/SlowInkDrift",
	}
	for key in paths.keys():
		domain_nodes[key] = domain_art.get_node_or_null(NodePath(paths[key]))


func _hide_static_domain_targets() -> void:
	var target_layer := domain_nodes.get("target_layer") as Node
	if target_layer == null:
		return
	for child in target_layer.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false


func _build_domain_marker_pool() -> void:
	if not domain_marker_dark_pool.is_empty():
		return
	var target_layer := domain_nodes.get("target_layer") as Node2D
	if target_layer == null:
		return
	for index in range(DOMAIN_MARKER_POOL_SIZE):
		var texture: Texture2D = _get_blot_texture(index)
		var dark := Sprite2D.new()
		dark.name = "RuntimeFreezeMarkerDark%d" % index
		dark.texture = texture
		dark.z_index = 10 + index
		dark.visible = false
		target_layer.add_child(dark)
		domain_marker_dark_pool.append(dark)

		var light := Sprite2D.new()
		light.name = "RuntimeFreezeMarkerLight%d" % index
		light.texture = texture
		light.material = domain_additive_material
		light.z_index = 34 + index
		light.visible = false
		target_layer.add_child(light)
		domain_marker_light_pool.append(light)


func _build_domain_ray_pool() -> void:
	if not domain_ray_pool.is_empty():
		return
	var sustain_layer := domain_nodes.get("sustain_layer") as Node2D
	if sustain_layer == null:
		return
	for index in range(DOMAIN_RAY_POOL_SIZE):
		var ray := Sprite2D.new()
		ray.name = "RuntimeSwordRay%d" % index
		ray.texture = 剑光贴图
		ray.material = domain_additive_material
		ray.z_index = 24 + index
		ray.visible = false
		sustain_layer.add_child(ray)
		domain_ray_pool.append(ray)


func _hide_domain_runtime_pools() -> void:
	for marker in domain_marker_dark_pool:
		marker.visible = false
	for marker in domain_marker_light_pool:
		marker.visible = false
	for ray in domain_ray_pool:
		ray.visible = false
	var droplet_particles := domain_nodes.get("droplet_particles") as GPUParticles2D
	if droplet_particles != null:
		droplet_particles.emitting = false
	var slow_drift := domain_nodes.get("slow_ink_drift") as GPUParticles2D
	if slow_drift != null:
		slow_drift.emitting = false


func _play_domain_animation(animation_name: StringName) -> void:
	if domain_anim == null or not domain_anim.has_animation(animation_name):
		return
	domain_anim.play(animation_name)


func _restart_domain_entry_particles() -> void:
	var particles := domain_nodes.get("droplet_particles") as GPUParticles2D
	if particles == null:
		return
	particles.global_position = splash_anchor_screen if splash_anchor_screen != Vector2.ZERO else focus_screen
	particles.global_rotation = _get_splash_axis().angle()
	var material := particles.process_material as ParticleProcessMaterial
	if material != null:
		var axis := _get_splash_axis()
		material.direction = Vector3(axis.x, axis.y, 0.0)
	particles.emitting = false
	particles.restart()
	particles.emitting = true


func _capture_splash_layout(entry_screen: Vector2, direction: Vector2, player_screen_pos: Vector2) -> void:
	var viewport_size := _get_safe_viewport_size()
	var axis := direction.normalized()
	if axis.is_zero_approx():
		axis = entry_screen - player_screen_pos
	if axis.is_zero_approx():
		axis = Vector2.RIGHT
	axis = axis.normalized()
	splash_axis = axis
	domain_axis = axis
	splash_player_screen = player_screen_pos
	splash_anchor_screen = entry_screen
	var base_length := maxf(viewport_size.x * 0.76, viewport_size.y * 1.05)
	var max_length := maxf(620.0, maxf(viewport_size.x, viewport_size.y) * 0.92)
	splash_length = clampf(base_length, 620.0, max_length)
	var entry_forward := maxf((entry_screen - player_screen_pos).dot(axis), 0.0)
	var center_forward := clampf(maxf(entry_forward, splash_length * 0.34), 220.0, splash_length * 0.43) * 泼墨中心前推倍率
	var focus_forward := clampf(maxf(entry_forward, splash_length * 0.58), splash_length * 0.46, splash_length * 0.78) * 泼墨中心前推倍率
	splash_center_screen = _clamp_screen_with_bleed(player_screen_pos + axis * center_forward, viewport_size, 180.0)
	splash_focus_screen = _clamp_screen_with_bleed(player_screen_pos + axis * focus_forward, viewport_size, 220.0)


func _update_domain_art() -> void:
	if domain_art == null:
		return
	if phase == Phase.IDLE or 背景层绘制:
		domain_art.visible = false
		_hide_domain_runtime_pools()
		return
	domain_art.visible = true
	var viewport_size := _get_safe_viewport_size()
	_update_domain_material_parameters(viewport_size)
	_update_domain_background(viewport_size)
	_update_domain_entry_layer()
	_update_domain_marker_pool()
	_update_domain_rays()


func _update_domain_material_parameters(viewport_size: Vector2) -> void:
	if domain_wash_material == null:
		return
	var safe_size := viewport_size
	if safe_size.x <= 0.0 or safe_size.y <= 0.0:
		safe_size = Vector2(1280.0, 720.0)
	var splash_focus := splash_focus_screen if splash_focus_screen != Vector2.ZERO else focus_screen
	var splash_player := splash_player_screen if splash_player_screen != Vector2.ZERO else player_screen
	var focus_uv := Vector2(
		clampf(splash_focus.x / safe_size.x, 0.0, 1.0),
		clampf(splash_focus.y / safe_size.y, 0.0, 1.0)
	)
	var player_uv := Vector2(
		clampf(splash_player.x / safe_size.x, 0.0, 1.0),
		clampf(splash_player.y / safe_size.y, 0.0, 1.0)
	)
	var entry_pulse := 0.0
	if phase == Phase.ENTERING:
		entry_pulse = clampf(1.0 - enter_progress, 0.0, 1.0)
	domain_wash_material.set_shader_parameter("strength", clampf(active_strength, 0.0, 1.0))
	domain_wash_material.set_shader_parameter("entry_pulse", entry_pulse)
	domain_wash_material.set_shader_parameter("recover_progress", clampf(recover_progress, 0.0, 1.0))
	domain_wash_material.set_shader_parameter("center_uv", focus_uv)
	domain_wash_material.set_shader_parameter("player_uv", player_uv)
	domain_wash_material.set_shader_parameter("axis_dir", _get_splash_axis())


func _update_domain_background(viewport_size: Vector2) -> void:
	var fade := clampf(active_strength, 0.0, 1.0) * (1.0 - recover_progress * 0.82)
	_set_domain_texture("paper", 纸纹暗面贴图)
	_set_domain_texture("fiber", 纸纹纤维贴图)
	_set_domain_texture("brush_a", _get_brush_texture(0))
	_set_domain_texture("brush_b", _get_brush_texture(1))
	_set_domain_texture("brush_c", _get_brush_texture(0))
	_set_domain_texture("brush_d", _get_brush_texture(1))
	_set_domain_texture("mist_near", 雾纹贴图)
	_set_domain_texture("mist_far", 雾纹贴图)
	_set_canvas_modulate("paper", _color_with_alpha(纸纹暗面颜色, 纸纹暗面透明度 * fade * 背景纸纹强度))
	_set_canvas_modulate("fiber", _color_with_alpha(纸纹纤维颜色, 纸纹纤维透明度 * fade * 背景纸纹强度))
	var axis := _get_background_brush_axis()
	var normal := Vector2(-axis.y, axis.x)
	var angle := axis.angle()
	var brush_offset := 背景笔触偏移倍率
	_set_domain_sprite("brush_a", viewport_size * Vector2(0.52, 0.24) + normal * 24.0 * brush_offset, angle - 0.08, Vector2(viewport_size.x / 620.0 * 背景笔触宽度倍率, viewport_size.y / 1320.0 * 背景笔触高度倍率), _color_with_alpha(背景笔触主色, 0.16 * fade * 背景笔触持续透明倍率))
	_set_domain_sprite("brush_b", viewport_size * Vector2(0.61, 0.48) - normal * 36.0 * brush_offset, angle + 0.10, Vector2(viewport_size.x / 560.0 * 背景笔触宽度倍率, viewport_size.y / 1180.0 * 背景笔触高度倍率), _color_with_alpha(背景笔触副色, 0.18 * fade * 背景笔触持续透明倍率))
	_set_domain_sprite("brush_c", viewport_size * Vector2(0.34, 0.67) + normal * 18.0 * brush_offset, angle - 0.34, Vector2(viewport_size.x / 760.0 * 背景笔触宽度倍率, viewport_size.y / 1550.0 * 背景笔触高度倍率), _color_with_alpha(背景笔触主色, 0.12 * fade * 背景笔触持续透明倍率))
	_set_domain_sprite("brush_d", viewport_size * Vector2(0.78, 0.30) - normal * 12.0 * brush_offset, angle + 0.46, Vector2(viewport_size.x / 910.0 * 背景笔触宽度倍率, viewport_size.y / 1800.0 * 背景笔触高度倍率), _color_with_alpha(背景笔触副色, 0.12 * fade * 背景笔触持续透明倍率))
	_set_domain_sprite("mist_near", splash_focus_screen.lerp(splash_player_screen, 0.26) + normal * 56.0 * brush_offset, angle - 0.18, Vector2(viewport_size.x / 520.0 * 雾纹宽度倍率, viewport_size.y / 680.0 * 雾纹高度倍率), _color_with_alpha(雾纹颜色, 0.12 * fade * 雾纹透明倍率))
	_set_domain_sprite("mist_far", splash_focus_screen.lerp(splash_player_screen, 0.56) - normal * 74.0 * brush_offset, angle + 0.24, Vector2(viewport_size.x / 690.0 * 雾纹宽度倍率, viewport_size.y / 820.0 * 雾纹高度倍率), _color_with_alpha(雾纹颜色, 0.08 * fade * 雾纹透明倍率))
	var slow_drift := domain_nodes.get("slow_ink_drift") as GPUParticles2D
	if slow_drift != null:
		slow_drift.global_position = splash_center_screen
		slow_drift.global_rotation = angle
		slow_drift.modulate = _color_with_alpha(背景笔触副色, 0.18 * fade * 背景笔触持续透明倍率)
		slow_drift.emitting = phase != Phase.RECOVERING or recover_progress < 0.72


func _update_domain_entry_layer() -> void:
	var fade := clampf(active_strength, 0.0, 1.0) * (1.0 - recover_progress * 0.94)
	var axis := _get_splash_axis()
	var normal := Vector2(-axis.y, axis.x)
	var angle := axis.angle()
	var line_distance := maxf(splash_length * 泼墨轴向长度倍率, 320.0)
	var center := splash_center_screen
	var splash_stamp := _get_splash_stamp_strength()
	var ink_stamp := clampf(splash_stamp * 入场墨爆强度, 0.0, 1.0)
	var splash_residue := fade * 入场泼墨残留倍率
	var open := _smooth01(enter_progress)
	var burst_width := 0.82 + 0.18 * open
	_set_domain_texture("crack_shadow", 裂痕暗纹贴图)
	_set_domain_texture("crack_dark", 裂痕暗纹贴图)
	_set_domain_texture("crack_light", 裂痕亮纹贴图)
	_set_domain_texture("streak_main", 剑光贴图)
	_set_domain_texture("streak_core", 剑光贴图)
	_set_domain_texture("droplet_a", 墨滴贴图)
	_set_domain_texture("droplet_b", 墨滴贴图二)
	_set_domain_texture("halo_player", _get_blot_texture(0))
	_set_domain_texture("halo_focus", _get_blot_texture(0))
	_set_domain_sprite_sized("crack_shadow", center + normal * 9.0, angle, line_distance * 1.46 * 裂痕长度倍率, 250.0 * burst_width * 裂痕宽度倍率, _color_with_alpha(裂痕暗纹颜色, (0.18 * splash_residue + 0.56 * ink_stamp) * 裂痕暗纹透明倍率))
	_set_domain_sprite_sized("crack_dark", center, angle, line_distance * 1.26 * 裂痕长度倍率, 208.0 * burst_width * 裂痕宽度倍率, _color_with_alpha(裂痕暗纹颜色, (0.20 * splash_residue + 0.70 * ink_stamp) * 裂痕暗纹透明倍率))
	_set_domain_sprite_sized("crack_light", center + normal * 3.0, angle + 0.018, line_distance * 1.04 * 裂痕长度倍率, 108.0 * burst_width * 裂痕宽度倍率, _color_with_alpha(裂痕亮纹颜色, (0.08 * splash_residue + 0.28 * ink_stamp) * 剑光放射强度 * 裂痕亮纹透明倍率))
	_set_domain_sprite_sized("streak_main", center + axis * 18.0, angle, line_distance * 1.54 * 剑光长度倍率, 66.0 * 剑光宽度倍率, _color_with_alpha(剑光主色, (0.16 * fade * 剑光持续透明倍率 + 0.26 * ink_stamp * 剑光入场透明倍率) * 剑光放射强度))
	_set_domain_sprite_sized("streak_core", center + axis * 42.0 - normal * 5.0, angle, line_distance * 0.86 * 剑光长度倍率, 34.0 * 剑光宽度倍率, _color_with_alpha(剑光核心色, (0.16 * fade * 剑光持续透明倍率 + 0.28 * ink_stamp * 剑光入场透明倍率) * 剑光放射强度))
	_set_domain_sprite_sized("droplet_a", center - axis * line_distance * 0.12 + normal * 68.0, angle - 0.42, 260.0 * 墨滴大小倍率, 190.0 * 墨滴大小倍率, _color_with_alpha(墨滴暗色, (0.04 * splash_residue + 0.18 * ink_stamp) * 墨滴透明倍率))
	_set_domain_sprite_sized("droplet_b", center + axis * line_distance * 0.16 - normal * 76.0, angle + 0.34, 220.0 * 墨滴大小倍率, 160.0 * 墨滴大小倍率, _color_with_alpha(裂痕亮纹颜色, 0.08 * ink_stamp * 剑光放射强度 * 墨滴透明倍率))
	_set_domain_sprite_sized("halo_player", splash_player_screen, effect_time * 0.22, 150.0 * 冻结墨斑大小倍率, 150.0 * 冻结墨斑大小倍率, _color_with_alpha(冻结墨色, 0.30 * fade * 冻结墨斑透明倍率))
	_set_domain_sprite_sized("halo_focus", splash_focus_screen, -effect_time * 0.16, (220.0 + 90.0 * open) * 冻结亮斑大小倍率, (220.0 + 90.0 * open) * 冻结亮斑大小倍率, _color_with_alpha(冻结环颜色, 0.20 * fade * 剑光放射强度 * 冻结亮斑透明倍率))
	var recover_alpha := clampf(recover_progress * (1.0 - recover_progress) * 4.0, 0.0, 1.0)
	_set_domain_sprite_sized("recover_flow_main", splash_player_screen.lerp(splash_focus_screen, 0.38), angle + 0.04, line_distance * 1.06 * 剑光长度倍率, 54.0 * 剑光宽度倍率, _color_with_alpha(剑光主色, 0.22 * recover_alpha))
	_set_domain_sprite_sized("recover_flow_core", splash_player_screen.lerp(splash_focus_screen, 0.34), angle, line_distance * 0.74 * 剑光长度倍率, 28.0 * 剑光宽度倍率, _color_with_alpha(剑光核心色, 0.24 * recover_alpha))


func _update_domain_marker_pool() -> void:
	var marker_strength := clampf(active_strength * 冻结标记强度, 0.0, 1.0) * (1.0 - recover_progress * 0.7)
	var visible_count := mini(mini(freeze_markers.size(), 冻结标记最大数量), domain_marker_dark_pool.size())
	for index in range(domain_marker_dark_pool.size()):
		var dark := domain_marker_dark_pool[index]
		var light := domain_marker_light_pool[index]
		if index >= visible_count or marker_strength <= 0.01:
			dark.visible = false
			light.visible = false
			continue
		var marker: Dictionary = freeze_markers[index]
		var position: Vector2 = Vector2(marker.get("position", Vector2.ZERO))
		var radius := float(marker.get("radius", 20.0))
		var threat := clampf(float(marker.get("threat", 1.0)), 0.0, 1.5)
		var marker_color := Color(0.95, 0.22, 0.22, 1.0)
		var raw_color = marker.get("color", marker_color)
		if raw_color is Color:
			marker_color = raw_color
		dark.texture = _get_blot_texture(index)
		light.texture = _get_blot_texture(index)
		var size := maxf(radius * (3.8 + threat * 0.75), 42.0) * 冻结墨斑大小倍率
		var pulse := 0.88 + 0.12 * sin(effect_time * 冻结标记呼吸速度 + float(index) * 0.71)
		dark.visible = true
		dark.global_position = position
		dark.global_rotation = effect_time * (0.06 + float(index % 3) * 0.015)
		dark.scale = _domain_sprite_scale_for_size(dark, size * pulse, size * pulse)
		dark.modulate = _color_with_alpha(冻结墨色, marker_strength * (0.34 + threat * 0.08) * 冻结墨斑透明倍率)
		var light_color := marker_color.lerp(Color.WHITE, 0.28)
		light_color.a = marker_strength * (0.10 + threat * 0.045) * 冻结亮斑透明倍率
		light.visible = true
		light.global_position = position + Vector2(2.0, -2.0)
		light.global_rotation = -dark.global_rotation * 0.72
		light.scale = _domain_sprite_scale_for_size(light, size * 0.62 * 冻结亮斑大小倍率, size * 0.62 * 冻结亮斑大小倍率)
		light.modulate = light_color


func _update_domain_rays() -> void:
	var ray_strength := clampf(active_strength * 剑光放射强度, 0.0, 1.0) * (1.0 - recover_progress * 0.35)
	var axis := _get_splash_axis()
	var normal := Vector2(-axis.y, axis.x)
	var line_distance := maxf(splash_length * 泼墨轴向长度倍率 * 0.9, 220.0)
	var ray_start := splash_player_screen - axis * (line_distance * 0.12)
	var ray_end := splash_focus_screen + axis * (line_distance * 0.20)
	for index in range(domain_ray_pool.size()):
		var ray := domain_ray_pool[index]
		if index >= 剑光游丝数量 or ray_strength <= 0.01:
			ray.visible = false
			continue
		ray.texture = 剑光贴图
		var ray_count := mini(maxi(剑光游丝数量, 1), domain_ray_pool.size())
		var t := (float(index) + 0.75) / (float(ray_count) + 1.2)
		var side := -1.0 if index % 2 == 0 else 1.0
		var arc := sin(t * PI) * (34.0 + float(index % 3) * 18.0)
		var drift := sin(effect_time * (剑光游丝漂移速度 + t) + float(index) * 1.7) * 10.0 * 剑光游丝漂移幅度倍率
		var pos := ray_start.lerp(ray_end, t) + normal * side * (arc + drift) - axis * (18.0 * float(index % 2))
		var length := clampf(line_distance * (0.18 + 0.07 * float(index % 4)), 90.0, 360.0)
		var height := 18.0 + 5.0 * float(index % 3)
		ray.visible = true
		ray.global_position = pos
		ray.global_rotation = axis.angle() + side * (0.08 + 0.02 * sin(effect_time + float(index)))
		ray.scale = _domain_sprite_scale_for_size(ray, length * 剑光长度倍率, height * 剑光宽度倍率)
		ray.modulate = _color_with_alpha(剑光主色, ray_strength * (0.11 + 0.035 * float(index % 3)) * 剑光持续透明倍率)


func _draw_background_state_wash(draw_target: CanvasItem, viewport_size: Vector2, state_strength: float, fade: float, ink_stamp: float) -> void:
	var viewport_rect := Rect2(Vector2.ZERO, viewport_size)
	var dark_breathe := 1.0 + sin(effect_time * TAU * 暗场呼吸速度) * 暗场呼吸透明度
	var dark_alpha := (暗场持续透明度 * state_strength + 暗场入场透明度 * ink_stamp) * 背景暗场强度 * dark_breathe
	draw_target.draw_rect(viewport_rect, _color_with_alpha(暗场颜色, dark_alpha), true)
	draw_target.draw_rect(viewport_rect, _color_with_alpha(冷雾颜色, 冷雾透明度 * fade), true)
	var paper_rect := Rect2(
		(viewport_size - viewport_size * Vector2(纸纹宽度倍率, 纸纹高度倍率)) * 0.5,
		viewport_size * Vector2(纸纹宽度倍率, 纸纹高度倍率)
	)
	if 纸纹暗面贴图 != null:
		draw_target.draw_texture_rect(纸纹暗面贴图, paper_rect, false, _color_with_alpha(纸纹暗面颜色, 纸纹暗面透明度 * state_strength * 背景纸纹强度))
	if 纸纹纤维贴图 != null:
		draw_target.draw_texture_rect(纸纹纤维贴图, paper_rect, false, _color_with_alpha(纸纹纤维颜色, 纸纹纤维透明度 * fade * 背景纸纹强度))
	if ink_stamp > 0.01:
		draw_target.draw_rect(viewport_rect, _color_with_alpha(入场冷光颜色, 入场冷光透明度 * ink_stamp), true)
	_draw_background_edge_vignette(draw_target, viewport_size, state_strength * 背景暗场强度)


func _draw_background_edge_vignette(draw_target: CanvasItem, viewport_size: Vector2, strength: float) -> void:
	if not 暗角启用 or strength <= 0.004:
		return
	var band_count := maxi(暗角层数, 1)
	for index in range(band_count):
		var t := float(index) / float(maxi(band_count - 1, 1))
		var thickness := lerpf(20.0, 118.0, t) * 暗角厚度倍率
		var alpha := strength * lerpf(0.034, 0.012, t) * 暗角透明倍率
		var color := _color_with_alpha(暗场颜色, alpha)
		draw_target.draw_rect(Rect2(Vector2.ZERO, Vector2(viewport_size.x, thickness)), color, true)
		draw_target.draw_rect(Rect2(Vector2(0.0, viewport_size.y - thickness), Vector2(viewport_size.x, thickness)), color, true)
		draw_target.draw_rect(Rect2(Vector2.ZERO, Vector2(thickness, viewport_size.y)), color, true)
		draw_target.draw_rect(Rect2(Vector2(viewport_size.x - thickness, 0.0), Vector2(thickness, viewport_size.y)), color, true)


func _draw_background_time_field(draw_target: CanvasItem, center: Vector2, viewport_size: Vector2, fade: float) -> void:
	if not 时场圆弧启用 or fade <= 0.004:
		return
	var pulse := 0.72 + 0.28 * sin(effect_time * 时场圆弧呼吸速度)
	var max_radius := maxf(viewport_size.x, viewport_size.y) * 0.58 * 时场圆弧半径倍率
	var arc_count := maxi(时场圆弧数量, 0)
	for index in range(arc_count):
		var t := float(index) / float(maxi(arc_count - 1, 1))
		var radius := lerpf(170.0, max_radius, t)
		var start_angle := -0.82 + float(index) * 0.44 + sin(effect_time * 0.08 + float(index)) * 0.035
		var arc_span := PI * lerpf(0.18, 0.34, 1.0 - t)
		var alpha := fade * lerpf(0.040, 0.014, t) * pulse * 时场圆弧透明倍率
		draw_target.draw_arc(center, radius, start_angle, start_angle + arc_span, 34, _color_with_alpha(时场圆弧颜色, alpha), 1.0 * 时场圆弧线宽倍率)
		draw_target.draw_arc(center, radius * 0.985, start_angle + PI * 0.92, start_angle + PI * 0.92 + arc_span * 0.42, 24, _color_with_alpha(时场暗弧颜色, alpha * 0.52), 1.0 * 时场圆弧线宽倍率)
	var tick_alpha := fade * 0.050 * (0.82 + 0.18 * pulse) * 时场刻度透明倍率
	var tick_count := maxi(时场刻度数量, 0)
	if tick_alpha <= 0.001 or tick_count <= 0:
		return
	for index in range(tick_count):
		var angle := float(index) / float(tick_count) * TAU + 0.09 + effect_time * 时场刻度旋转速度
		var radius := max_radius * (0.42 + 0.18 * _stable_noise(index, 4.7))
		var length := (7.0 + 6.0 * _stable_noise(index, 8.9)) * 时场刻度长度倍率
		var direction := Vector2.RIGHT.rotated(angle)
		var tick_center := center + direction * radius
		draw_target.draw_line(tick_center - direction * length, tick_center + direction * length, _color_with_alpha(时场刻度颜色, tick_alpha), 1.0 * 时场圆弧线宽倍率)


func _draw_background_freeze_markers(draw_target: CanvasItem, fade: float) -> void:
	var marker_strength := clampf(active_strength * 冻结标记强度, 0.0, 1.0) * (1.0 - recover_progress * 0.78)
	if marker_strength <= 0.004:
		return
	var visible_count := mini(freeze_markers.size(), 冻结标记最大数量)
	for index in range(visible_count):
		var marker: Dictionary = freeze_markers[index]
		var position: Vector2 = Vector2(marker.get("position", Vector2.ZERO))
		var radius := float(marker.get("radius", 20.0))
		var threat := clampf(float(marker.get("threat", 1.0)), 0.0, 1.5)
		var marker_color := Color(0.95, 0.22, 0.22, 1.0)
		var raw_color = marker.get("color", marker_color)
		if raw_color is Color:
			marker_color = raw_color
		var texture: Texture2D = _get_blot_texture(index)
		var size := maxf(radius * (3.0 + threat * 0.52), 36.0) * 冻结墨斑大小倍率
		var pulse := 0.92 + 0.08 * sin(effect_time * 冻结标记呼吸速度 + float(index) * 0.71)
		var ring_radius := maxf(radius * (1.65 + threat * 0.16), 19.0) * 冻结环半径倍率
		var ring_alpha := marker_strength * (0.11 + threat * 0.035) * fade * 冻结环透明倍率
		var ring_angle := effect_time * 冻结环旋转速度 + float(index) * 0.19
		draw_target.draw_arc(position, ring_radius, ring_angle - PI * 0.72, ring_angle + PI * 0.42, 32, _color_with_alpha(冻结环颜色, ring_alpha), 1.25 * 冻结环线宽倍率)
		draw_target.draw_arc(position, ring_radius * 0.68, ring_angle + PI * 0.36, ring_angle + PI * 1.08, 24, _color_with_alpha(冻结环亮色, ring_alpha * 0.58), 1.0 * 冻结环线宽倍率)
		if 弹丸冻结刻痕启用 and radius <= 14.0:
			var tick_dir := Vector2.RIGHT.rotated(ring_angle + PI * 0.5)
			draw_target.draw_line(position - tick_dir * (ring_radius + 3.0), position - tick_dir * (ring_radius - 4.0), _color_with_alpha(冻结环亮色, ring_alpha * 0.8), 1.0 * 冻结环线宽倍率)
			draw_target.draw_line(position + tick_dir * (ring_radius - 4.0), position + tick_dir * (ring_radius + 3.0), _color_with_alpha(冻结环亮色, ring_alpha * 0.8), 1.0 * 冻结环线宽倍率)
		_draw_background_sprite_sized(
			draw_target,
			texture,
			position,
			effect_time * (0.035 + float(index % 3) * 0.01),
			size * pulse,
			size * pulse,
			_color_with_alpha(冻结墨色, marker_strength * (0.16 + threat * 0.050) * fade * 冻结墨斑透明倍率)
		)
		var light_color := marker_color.lerp(Color.WHITE, 0.18)
		light_color.a = marker_strength * (0.082 + threat * 0.026) * fade * 冻结亮斑透明倍率
		_draw_background_sprite_sized(
			draw_target,
			texture,
			position + Vector2(2.0, -2.0),
			-effect_time * 0.035,
			size * 0.48 * 冻结亮斑大小倍率,
			size * 0.48 * 冻结亮斑大小倍率,
			light_color
		)


func _draw_background_rays(draw_target: CanvasItem, fade: float) -> void:
	var ray_strength := clampf(active_strength * 剑光放射强度, 0.0, 1.0) * (1.0 - recover_progress * 0.45)
	if ray_strength <= 0.004:
		return
	var axis := _get_splash_axis()
	var normal := Vector2(-axis.y, axis.x)
	var line_distance := maxf(splash_length * 泼墨轴向长度倍率 * 0.86, 220.0)
	var ray_start := splash_player_screen - axis * (line_distance * 0.10)
	var ray_end := splash_focus_screen + axis * (line_distance * 0.16)
	var ray_count := maxi(剑光游丝数量, 0)
	for index in range(ray_count):
		var t := (float(index) + 0.75) / (float(ray_count) + 1.2)
		var side := -1.0 if index % 2 == 0 else 1.0
		var arc := sin(t * PI) * (28.0 + float(index % 3) * 13.0)
		var drift := sin(effect_time * (剑光游丝漂移速度 + t) + float(index) * 1.7) * 5.0 * 剑光游丝漂移幅度倍率
		var pos := ray_start.lerp(ray_end, t) + normal * side * (arc + drift) - axis * (12.0 * float(index % 2))
		var length := clampf(line_distance * (0.16 + 0.055 * float(index % 4)), 72.0, 260.0)
		var height := 10.0 + 3.0 * float(index % 3)
		_draw_background_sprite_sized(
			draw_target,
			剑光贴图,
			pos,
			axis.angle() + side * (0.08 + 0.02 * sin(effect_time + float(index))),
			length * 剑光长度倍率,
			height * 剑光宽度倍率,
			_color_with_alpha(剑光主色, ray_strength * (0.105 + 0.024 * float(index % 3)) * fade * 剑光持续透明倍率)
		)


func _get_brush_texture(index: int) -> Texture2D:
	if index % 2 == 0:
		return 笔触贴图一 if 笔触贴图一 != null else BRUSH_SWEEP_TEXTURES[0]
	return 笔触贴图二 if 笔触贴图二 != null else BRUSH_SWEEP_TEXTURES[1]


func _get_blot_texture(index: int) -> Texture2D:
	match index % 3:
		0:
			return 墨斑贴图一 if 墨斑贴图一 != null else BLOT_TEXTURES[0]
		1:
			return 墨斑贴图二 if 墨斑贴图二 != null else BLOT_TEXTURES[1]
		_:
			return 墨斑贴图三 if 墨斑贴图三 != null else BLOT_TEXTURES[2]


func _color_with_alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = clampf(alpha, 0.0, 1.0)
	return result


func _draw_background_sprite_sized(draw_target: CanvasItem, texture: Texture2D, position: Vector2, rotation: float, width: float, height: float, color: Color) -> void:
	if texture == null or color.a <= 0.001:
		return
	_draw_background_sprite(draw_target, texture, position, rotation, _texture_scale_for_size(texture, width, height), color)


func _draw_background_sprite(draw_target: CanvasItem, texture: Texture2D, position: Vector2, rotation: float, scale: Vector2, color: Color) -> void:
	if texture == null or color.a <= 0.001:
		return
	var texture_size := Vector2(texture.get_size())
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	draw_target.draw_set_transform(position, rotation, scale)
	draw_target.draw_texture(texture, -texture_size * 0.5, color)
	draw_target.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _texture_scale_for_size(texture: Texture2D, width: float, height: float) -> Vector2:
	if texture == null:
		return Vector2.ONE
	var size := Vector2(texture.get_size())
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	return Vector2(maxf(width, 1.0) / size.x, maxf(height, 1.0) / size.y)


func _set_domain_texture(key: String, texture: Texture2D) -> void:
	if texture == null:
		return
	var node := domain_nodes.get(key) as Node
	if node is Sprite2D:
		(node as Sprite2D).texture = texture
	elif node is TextureRect:
		(node as TextureRect).texture = texture


func _set_canvas_modulate(key: String, color: Color) -> void:
	var item := domain_nodes.get(key) as CanvasItem
	if item == null:
		return
	item.visible = color.a > 0.001
	item.modulate = color


func _set_domain_sprite(key: String, position: Vector2, rotation: float, scale: Vector2, color: Color) -> void:
	var sprite := domain_nodes.get(key) as Sprite2D
	if sprite == null:
		return
	sprite.visible = color.a > 0.001
	sprite.global_position = position
	sprite.global_rotation = rotation
	sprite.scale = scale
	sprite.modulate = color


func _set_domain_sprite_sized(key: String, position: Vector2, rotation: float, width: float, height: float, color: Color) -> void:
	var sprite := domain_nodes.get(key) as Sprite2D
	if sprite == null:
		return
	sprite.visible = color.a > 0.001
	sprite.global_position = position
	sprite.global_rotation = rotation
	sprite.scale = _domain_sprite_scale_for_size(sprite, width, height)
	sprite.modulate = color


func _domain_sprite_scale_for_size(sprite: Sprite2D, width: float, height: float) -> Vector2:
	if sprite == null or sprite.texture == null:
		return Vector2.ONE
	var size := sprite.texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	return Vector2(maxf(width, 1.0) / size.x, maxf(height, 1.0) / size.y)


func _get_splash_axis() -> Vector2:
	if not 泼墨跟随出鞘方向:
		return Vector2.RIGHT.rotated(deg_to_rad(泼墨固定角度)).normalized()
	var axis := splash_axis
	if axis.is_zero_approx():
		axis = domain_axis
	if axis.is_zero_approx():
		axis = Vector2.RIGHT
	return axis.normalized()


func _get_background_brush_axis() -> Vector2:
	if 背景笔触固定构图:
		return Vector2.RIGHT.rotated(deg_to_rad(背景笔触固定角度)).normalized()
	return _get_splash_axis()


func _get_splash_stamp_strength() -> float:
	var life := clampf(1.0 - effect_time / maxf(入场泼墨持续时间, 0.001), 0.0, 1.0)
	var stamp := pow(life, 0.72)
	if phase == Phase.ENTERING:
		stamp = maxf(stamp, 0.36 + 0.64 * (1.0 - _smooth01(enter_progress)))
	if phase == Phase.RECOVERING:
		stamp *= 1.0 - recover_progress
	return clampf(stamp, 0.0, 1.0)


func _get_domain_axis() -> Vector2:
	var axis := domain_axis
	if axis.is_zero_approx() and player_screen.distance_squared_to(focus_screen) > 0.001:
		axis = focus_screen - player_screen
	if axis.is_zero_approx():
		axis = Vector2.RIGHT
	return axis.normalized()


func _clamp_screen_with_bleed(point: Vector2, viewport_size: Vector2, bleed: float) -> Vector2:
	var safe_size := viewport_size
	if safe_size.x <= 0.0 or safe_size.y <= 0.0:
		safe_size = Vector2(1280.0, 720.0)
	return Vector2(
		clampf(point.x, -bleed, safe_size.x + bleed),
		clampf(point.y, -bleed, safe_size.y + bleed)
	)


func _get_safe_viewport_size() -> Vector2:
	if is_inside_tree():
		var viewport_size := get_viewport_rect().size
		if viewport_size.x > 0.0 and viewport_size.y > 0.0:
			return viewport_size
	return Vector2(1280.0, 720.0)


func _get_profile() -> Resource:
	if 夜界配置 == null:
		夜界配置 = DEFAULT_PROFILE
	return 夜界配置


func _profile_float(property_name: StringName, default_value: float) -> float:
	var safe_profile := _get_profile()
	if safe_profile == null:
		return default_value
	var value = safe_profile.get(property_name)
	return float(value) if value != null else default_value


func _smooth01(value: float) -> float:
	var x := clampf(value, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _stable_noise(index: int, salt: float) -> float:
	var value := sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
	return value - floor(value)
