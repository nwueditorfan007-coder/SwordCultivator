extends Node2D

const GameRenderer = preload("res://scripts/system/game_renderer.gd")
const MainScript = preload("res://scripts/system/main.gd")
const SwordVfxProfile = preload("res://scripts/vfx/sword_vfx_profile.gd")
const DEFAULT_SWORD_VFX_PROFILE = preload("res://resources/vfx/sword_vfx_profile_default.tres")
const DEFAULT_LOOKDEV_SWORD_VFX_PROFILE = preload("res://resources/vfx/sword_vfx_profile_lookdev.tres")

enum PreviewMode {
	POINT,
	SLICE,
	RECALL,
}

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

const ARENA_SIZE := Vector2(900.0, 520.0)
const ARENA_ORIGIN := Vector2(160.0, 92.0)
const ARENA_RECT := Rect2(ARENA_ORIGIN, ARENA_SIZE)

const PLAYER_RADIUS := MainScript.PLAYER_RADIUS
const SWORD_RADIUS := MainScript.SWORD_RADIUS
const SWORD_POINT_STRIKE_SPEED := MainScript.SWORD_POINT_STRIKE_SPEED
const SWORD_RECALL_SPEED := MainScript.SWORD_RECALL_SPEED
const SWORD_TRAIL_BASE_HALF_WIDTH := MainScript.SWORD_TRAIL_BASE_HALF_WIDTH
const SWORD_AIR_WAKE_BASE_LENGTH := MainScript.SWORD_AIR_WAKE_BASE_LENGTH
const SWORD_AIR_WAKE_BASE_WIDTH := MainScript.SWORD_AIR_WAKE_BASE_WIDTH
const SWORD_RETURN_CATCH_BASE_RADIUS := MainScript.SWORD_RETURN_CATCH_BASE_RADIUS
const SWORD_HIT_EFFECT_DURATION := MainScript.SWORD_HIT_EFFECT_DURATION
const SWORD_HIT_EFFECT_MAX_COUNT := MainScript.SWORD_HIT_EFFECT_MAX_COUNT
const SWORD_HIT_EFFECT_BASE_LENGTH := MainScript.SWORD_HIT_EFFECT_BASE_LENGTH
const SWORD_HIT_EFFECT_BASE_WIDTH := MainScript.SWORD_HIT_EFFECT_BASE_WIDTH
const SWORD_HIT_EFFECT_POINT_LENGTH_SCALE := MainScript.SWORD_HIT_EFFECT_POINT_LENGTH_SCALE
const SWORD_HIT_EFFECT_POINT_WIDTH_SCALE := MainScript.SWORD_HIT_EFFECT_POINT_WIDTH_SCALE
const SWORD_HIT_EFFECT_SLICE_LENGTH_SCALE := MainScript.SWORD_HIT_EFFECT_SLICE_LENGTH_SCALE
const SWORD_HIT_EFFECT_SLICE_WIDTH_SCALE := MainScript.SWORD_HIT_EFFECT_SLICE_WIDTH_SCALE
const SWORD_HIT_EFFECT_SPARK_COUNT := MainScript.SWORD_HIT_EFFECT_SPARK_COUNT
const COLORS := MainScript.COLORS
const LOOKDEV_CORE_COLOR := Color("fff6e5")
const LOOKDEV_WARM_COLOR := Color("ffd39b")
const PANEL_WIDTH := 360.0
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

@export var sword_vfx_profile: SwordVfxProfile = DEFAULT_SWORD_VFX_PROFILE
@export var preview_mode: PreviewMode = PreviewMode.POINT
@export var auto_cycle := false
@export_range(0.25, 3.0, 0.05) var playback_speed := 1.0
@export_range(1.5, 8.0, 0.1) var point_preview_duration := 2.8
@export_range(1.5, 8.0, 0.1) var slice_preview_duration := 3.4
@export_range(1.5, 8.0, 0.1) var recall_preview_duration := 2.4

var elapsed_time := 0.0
var preview_time := 0.0
var preview_paused := false
var preview_loop_index := -1
var preview_events: Dictionary = {}

var player := {
	"pos": ARENA_SIZE * 0.5,
	"mode": CombatMode.RANGED,
}
var sword := {
	"pos": ARENA_SIZE * 0.5,
	"prev_pos": ARENA_SIZE * 0.5,
	"vel": Vector2.ZERO,
	"angle": 0.0,
	"radius": SWORD_RADIUS,
	"state": SwordState.ORBITING,
	"trail_emit_timer": 0.0,
	"air_wake_emit_timer": 0.0,
	"last_motion_forward": Vector2.RIGHT,
}
var sword_trail_points: Array = []
var sword_air_wakes: Array = []
var sword_return_catches: Array = []
var sword_hit_effects: Array = []

var overlay_layer: CanvasLayer
var mode_label: Label
var hint_label: Label
var control_panel: PanelContainer
var slider_rows: Array = []
var reset_button: Button
var source_sword_vfx_profile: SwordVfxProfile


func _ready() -> void:
	source_sword_vfx_profile = DEFAULT_LOOKDEV_SWORD_VFX_PROFILE
	sword_vfx_profile = source_sword_vfx_profile.duplicate(true)
	_create_overlay()
	_reset_preview()
	set_process(true)
	queue_redraw()


func get_sword_vfx_profile() -> SwordVfxProfile:
	if sword_vfx_profile == null:
		sword_vfx_profile = DEFAULT_SWORD_VFX_PROFILE
	return sword_vfx_profile


func _process(delta: float) -> void:
	if not preview_paused:
		var scaled_delta: float = delta * playback_speed
		elapsed_time += scaled_delta
		preview_time += scaled_delta
		_update_preview(scaled_delta)
	_update_overlay()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_set_preview_mode(PreviewMode.POINT)
			KEY_2:
				_set_preview_mode(PreviewMode.SLICE)
			KEY_3:
				_set_preview_mode(PreviewMode.RECALL)
			KEY_SPACE:
				preview_paused = not preview_paused
			KEY_R:
				_reset_preview()


func _draw() -> void:
	GameRenderer._draw_art_background(self)
	GameRenderer._draw_art_tactical_grid(self)
	_draw_preview_guides()
	GameRenderer._draw_sword_recall_gate(self, _to_screen(player["pos"]))
	GameRenderer._draw_sword_return_catches(self)
	GameRenderer._draw_sword_air_wakes(self)
	GameRenderer._draw_sword_trail(self)
	GameRenderer._draw_sword_hit_effects(self)

	var sword_pos: Vector2 = _to_screen(sword["pos"])
	var sword_forward: Vector2 = Vector2.RIGHT.rotated(float(sword["angle"]))
	var sword_local_glow_strength: float = _get_preview_glow_strength()
	var sword_glow_style: String = _get_preview_glow_style()
	GameRenderer._draw_sword_motion_front(self, sword_pos, sword_forward, COLORS["ranged_sword"])
	GameRenderer._draw_sword_body(
		self,
		sword_pos,
		sword_forward,
		COLORS["ranged_sword"],
		1.6,
		0.26,
		sword_local_glow_strength,
		sword_glow_style
	)

	var player_pos: Vector2 = _to_screen(player["pos"])
	_draw_player_presence(player_pos)
	GameRenderer._draw_art_arena_frame(self)


func _get_time_stop_visual_strength() -> float:
	return 0.0


func _get_time_stop_world_color(color: Color) -> Color:
	return color


func _to_screen(world_pos: Vector2) -> Vector2:
	return ARENA_ORIGIN + world_pos


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return screen_pos - ARENA_ORIGIN


func _set_preview_mode(next_mode: PreviewMode) -> void:
	if preview_mode == next_mode:
		_reset_preview()
		return
	preview_mode = next_mode
	_reset_preview()


func _reset_preview() -> void:
	preview_time = 0.0
	preview_loop_index = -1
	preview_events.clear()
	sword_trail_points.clear()
	sword_air_wakes.clear()
	sword_return_catches.clear()
	sword_hit_effects.clear()
	player["pos"] = Vector2(ARENA_SIZE.x * 0.26, ARENA_SIZE.y * 0.58)
	sword["pos"] = player["pos"] + Vector2(34.0, -18.0)
	sword["prev_pos"] = sword["pos"]
	sword["vel"] = Vector2.ZERO
	sword["angle"] = 0.0
	sword["state"] = SwordState.ORBITING
	sword["trail_emit_timer"] = 0.0
	sword["air_wake_emit_timer"] = 0.0
	sword["last_motion_forward"] = Vector2.RIGHT
	_update_overlay()


func _update_preview(delta: float) -> void:
	_update_sword_hit_effects(delta)
	_update_sword_return_catches(delta)
	var duration: float = _get_current_preview_duration()
	var loop_index: int = int(floor(preview_time / maxf(duration, 0.001)))
	if loop_index != preview_loop_index:
		preview_loop_index = loop_index
		preview_events.clear()
	if auto_cycle and preview_time >= duration * 3.0:
		_set_preview_mode((int(preview_mode) + 1) % PreviewMode.size())
		return
	var local_time: float = fmod(preview_time, duration)
	var previous_pos: Vector2 = sword["pos"]
	match preview_mode:
		PreviewMode.POINT:
			_update_point_preview(local_time)
		PreviewMode.SLICE:
			_update_slice_preview(local_time)
		PreviewMode.RECALL:
			_update_recall_preview(local_time)
	var frame_velocity: Vector2 = (sword["pos"] - previous_pos) / maxf(delta, 0.001)
	sword["prev_pos"] = previous_pos
	sword["vel"] = frame_velocity
	if frame_velocity.length_squared() > 1.0:
		sword["angle"] = frame_velocity.angle()
	_update_preview_trail(delta, frame_velocity)
	_update_preview_air_wakes(delta, frame_velocity)


func _update_point_preview(local_time: float) -> void:
	var duration: float = point_preview_duration
	var prep_duration: float = duration * 0.18
	var strike_duration: float = duration * 0.42
	var recall_duration: float = duration * 0.26
	var idle_duration: float = duration - prep_duration - strike_duration - recall_duration
	var player_pos: Vector2 = Vector2(player["pos"])
	var launch_pos: Vector2 = player_pos + Vector2(38.0, -24.0)
	var target_pos: Vector2 = Vector2(ARENA_SIZE.x * 0.74, ARENA_SIZE.y * 0.3)
	if local_time < prep_duration:
		sword["state"] = SwordState.ORBITING
		var prep_ratio: float = local_time / maxf(prep_duration, 0.001)
		sword["pos"] = player_pos.lerp(launch_pos, prep_ratio)
	elif local_time < prep_duration + strike_duration:
		sword["state"] = SwordState.POINT_STRIKE
		var strike_ratio: float = (local_time - prep_duration) / maxf(strike_duration, 0.001)
		var eased_ratio: float = 1.0 - pow(1.0 - strike_ratio, 3.0)
		sword["pos"] = launch_pos.lerp(target_pos, eased_ratio)
		if strike_ratio >= 0.88 and _consume_preview_event("point_hit"):
			_emit_preview_hit_effect(target_pos, target_pos - launch_pos, COLORS["ranged_sword"].lerp(LOOKDEV_WARM_COLOR, 0.2), "point")
	elif local_time < prep_duration + strike_duration + recall_duration:
		sword["state"] = SwordState.RECALLING
		var recall_ratio: float = (local_time - prep_duration - strike_duration) / maxf(recall_duration, 0.001)
		var eased_recall: float = pow(recall_ratio, 0.82)
		var return_pos: Vector2 = player_pos + Vector2(8.0, -10.0)
		sword["pos"] = target_pos.lerp(return_pos, eased_recall)
		if recall_ratio >= 0.96 and _consume_preview_event("point_return"):
			_emit_sword_return_catch(return_pos, return_pos - target_pos)
	else:
		sword["state"] = SwordState.ORBITING
		var idle_ratio: float = (local_time - prep_duration - strike_duration - recall_duration) / maxf(idle_duration, 0.001)
		sword["pos"] = player_pos.lerp(launch_pos, 1.0 - idle_ratio)


func _update_slice_preview(local_time: float) -> void:
	var duration: float = slice_preview_duration
	var prep_duration: float = duration * 0.16
	var slice_duration: float = duration * 0.62
	var recall_duration: float = duration * 0.18
	var player_pos: Vector2 = Vector2(player["pos"])
	var launch_pos: Vector2 = player_pos + Vector2(46.0, -26.0)
	var curve_center: Vector2 = Vector2(ARENA_SIZE.x * 0.58, ARENA_SIZE.y * 0.46)
	var radius_x: float = 180.0
	var radius_y: float = 104.0
	if local_time < prep_duration:
		sword["state"] = SwordState.ORBITING
		var prep_ratio: float = local_time / maxf(prep_duration, 0.001)
		sword["pos"] = player_pos.lerp(launch_pos, prep_ratio)
	elif local_time < prep_duration + slice_duration:
		sword["state"] = SwordState.SLICING
		var slice_ratio: float = (local_time - prep_duration) / maxf(slice_duration, 0.001)
		var angle: float = lerpf(-1.2, 2.55, slice_ratio) + sin(slice_ratio * TAU * 2.0) * 0.14
		sword["pos"] = curve_center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
		if slice_ratio >= 0.28 and _consume_preview_event("slice_hit_1"):
			_emit_preview_hit_effect(sword["pos"], Vector2.RIGHT.rotated(angle + 0.42), COLORS["ranged_sword"].lerp(LOOKDEV_WARM_COLOR, 0.18), "slice")
		if slice_ratio >= 0.58 and _consume_preview_event("slice_hit_2"):
			_emit_preview_hit_effect(sword["pos"], Vector2.RIGHT.rotated(angle - 0.34), COLORS["ranged_sword"].lerp(LOOKDEV_WARM_COLOR, 0.12), "slice")
	elif local_time < prep_duration + slice_duration + recall_duration:
		sword["state"] = SwordState.RECALLING
		var recall_ratio: float = (local_time - prep_duration - slice_duration) / maxf(recall_duration, 0.001)
		var return_pos: Vector2 = player_pos + Vector2(12.0, -12.0)
		var recall_start: Vector2 = curve_center + Vector2(cos(2.55) * radius_x, sin(2.55) * radius_y)
		sword["pos"] = recall_start.lerp(return_pos, pow(recall_ratio, 0.82))
		if recall_ratio >= 0.96 and _consume_preview_event("slice_return"):
			_emit_sword_return_catch(return_pos, return_pos - recall_start)
	else:
		sword["state"] = SwordState.ORBITING
		sword["pos"] = launch_pos


func _update_recall_preview(local_time: float) -> void:
	var duration: float = recall_preview_duration
	var player_pos: Vector2 = Vector2(player["pos"])
	var start_pos: Vector2 = Vector2(ARENA_SIZE.x * 0.78, ARENA_SIZE.y * 0.28)
	var end_pos: Vector2 = player_pos + Vector2(10.0, -10.0)
	sword["state"] = SwordState.RECALLING
	var recall_ratio: float = clampf(local_time / maxf(duration, 0.001), 0.0, 1.0)
	var eased_ratio: float = 1.0 - pow(1.0 - recall_ratio, 2.4)
	sword["pos"] = start_pos.lerp(end_pos, eased_ratio)
	if recall_ratio >= 0.94 and _consume_preview_event("recall_return"):
		_emit_sword_return_catch(end_pos, end_pos - start_pos)
	if recall_ratio >= 0.32 and _consume_preview_event("recall_hit"):
		_emit_preview_hit_effect(start_pos.lerp(end_pos, 0.42), end_pos - start_pos, COLORS["array_sword_return"].lerp(LOOKDEV_CORE_COLOR, 0.24), "deflect")


func _update_preview_trail(delta: float, frame_velocity: Vector2) -> void:
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

	if int(sword.get("state", SwordState.ORBITING)) != SwordState.POINT_STRIKE and int(sword.get("state", SwordState.ORBITING)) != SwordState.SLICING and int(sword.get("state", SwordState.ORBITING)) != SwordState.RECALLING:
		sword["trail_emit_timer"] = 0.0
		return
	var emit_timer: float = max(float(sword.get("trail_emit_timer", 0.0)) - delta, 0.0)
	var min_speed: float = float(vfx.trail_min_speed) * (0.82 if int(sword["state"]) == SwordState.RECALLING else 1.0)
	if frame_velocity.length() < min_speed:
		sword["trail_emit_timer"] = emit_timer
		return
	if emit_timer > 0.0:
		sword["trail_emit_timer"] = emit_timer
		return
	sword["trail_emit_timer"] = float(vfx.trail_sample_interval)
	_emit_preview_trail_point(frame_velocity)


func _emit_preview_trail_point(frame_velocity: Vector2) -> void:
	var vfx: SwordVfxProfile = get_sword_vfx_profile()
	var direction: Vector2 = frame_velocity.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT.rotated(float(sword["angle"]))
	var sword_state: int = int(sword["state"])
	var is_slice: bool = sword_state == SwordState.SLICING
	var is_recalling: bool = sword_state == SwordState.RECALLING
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
		previous_forward = Vector2(sword_trail_points[sword_trail_points.size() - 1].get("forward", direction))
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


func _update_preview_air_wakes(delta: float, frame_velocity: Vector2) -> void:
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
	if int(sword["state"]) == SwordState.ORBITING:
		sword["air_wake_emit_timer"] = 0.0
		sword["last_motion_forward"] = Vector2.RIGHT.rotated(float(sword["angle"]))
		return
	var current_forward: Vector2 = frame_velocity.normalized()
	if current_forward.is_zero_approx():
		current_forward = Vector2.RIGHT.rotated(float(sword["angle"]))
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
	if speed >= float(vfx.air_wake_min_speed) and turn_strength > 0.0 and emit_timer <= 0.0:
		_emit_preview_air_wake(current_forward, turn_delta, turn_strength, speed)
		sword["air_wake_emit_timer"] = lerpf(float(vfx.air_wake_emit_interval_max), float(vfx.air_wake_emit_interval_min), turn_strength)
	else:
		sword["air_wake_emit_timer"] = emit_timer
	sword["last_motion_forward"] = current_forward


func _emit_preview_air_wake(current_forward: Vector2, turn_delta: float, turn_strength: float, speed: float) -> void:
	var vfx: SwordVfxProfile = get_sword_vfx_profile()
	var turn_sign: float = 1.0 if turn_delta >= 0.0 else -1.0
	var outward: Vector2 = current_forward.rotated(turn_sign * PI * 0.5)
	var is_recalling: bool = int(sword["state"]) == SwordState.RECALLING
	var speed_reference: float = SWORD_RECALL_SPEED if is_recalling else SWORD_POINT_STRIKE_SPEED
	var speed_ratio: float = clampf(speed / maxf(speed_reference, 0.001), 0.0, 1.0)
	var center: Vector2 = sword["pos"] - current_forward * (8.0 + 6.0 * speed_ratio) + outward * (4.0 + 9.0 * turn_strength)
	var wake_width_scale: float = float(vfx.trail_recall_width_scale) * 1.16 if is_recalling else 1.0
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
		"style": "recall" if is_recalling else "point",
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
	var resolved_direction: Vector2 = direction.normalized()
	if resolved_direction.is_zero_approx():
		resolved_direction = Vector2.RIGHT
	sword_return_catches.append({
		"pos": catch_pos,
		"forward": resolved_direction,
		"life": float(vfx.return_catch_duration),
		"max_life": float(vfx.return_catch_duration),
		"radius": float(vfx.return_catch_base_radius),
	})
	if sword_return_catches.size() > int(vfx.return_catch_max_count):
		sword_return_catches.remove_at(0)


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


func _emit_preview_hit_effect(contact_pos: Vector2, swing_direction: Vector2, effect_color: Color, style_override: String) -> void:
	var direction: Vector2 = swing_direction.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var speed_reference: float = SWORD_POINT_STRIKE_SPEED if style_override != "recall" else SWORD_RECALL_SPEED
	var speed_ratio: float = clampf(Vector2(sword.get("vel", Vector2.ZERO)).length() / maxf(speed_reference, 0.001), 0.0, 1.0)
	var length_scale: float = SWORD_HIT_EFFECT_POINT_LENGTH_SCALE
	var width_scale: float = SWORD_HIT_EFFECT_POINT_WIDTH_SCALE
	var spark_count: int = SWORD_HIT_EFFECT_SPARK_COUNT
	match style_override:
		"slice":
			length_scale = SWORD_HIT_EFFECT_SLICE_LENGTH_SCALE
			width_scale = SWORD_HIT_EFFECT_SLICE_WIDTH_SCALE
			spark_count = 3
		"deflect":
			length_scale = 0.96
			width_scale = 0.72
			spark_count = 4
		"sever":
			length_scale = 1.28
			width_scale = 0.68
			spark_count = 5
	sword_hit_effects.append({
		"pos": contact_pos,
		"direction": direction,
		"life": SWORD_HIT_EFFECT_DURATION,
		"max_life": SWORD_HIT_EFFECT_DURATION,
		"length": (SWORD_HIT_EFFECT_BASE_LENGTH + 10.0 * speed_ratio) * length_scale,
		"width": (SWORD_HIT_EFFECT_BASE_WIDTH + 3.0 * speed_ratio) * width_scale,
		"spark_count": spark_count,
		"seed": randf() * TAU,
		"color": effect_color,
		"style": style_override,
	})
	if sword_hit_effects.size() > SWORD_HIT_EFFECT_MAX_COUNT:
		sword_hit_effects.remove_at(0)


func _consume_preview_event(event_key: String) -> bool:
	if preview_events.has(event_key):
		return false
	preview_events[event_key] = true
	return true


func _get_current_preview_duration() -> float:
	match preview_mode:
		PreviewMode.SLICE:
			return slice_preview_duration
		PreviewMode.RECALL:
			return recall_preview_duration
		_:
			return point_preview_duration


func _get_preview_glow_strength() -> float:
	var vfx: SwordVfxProfile = get_sword_vfx_profile()
	match int(sword.get("state", SwordState.ORBITING)):
		SwordState.POINT_STRIKE:
			var point_speed_ratio: float = clampf(Vector2(sword.get("vel", Vector2.ZERO)).length() / maxf(SWORD_POINT_STRIKE_SPEED, 0.001), 0.0, 1.0)
			return float(vfx.local_glow_point_base) + float(vfx.local_glow_point_speed_scale) * point_speed_ratio
		SwordState.SLICING:
			var slice_speed_ratio: float = clampf(Vector2(sword.get("vel", Vector2.ZERO)).length() / maxf(SWORD_POINT_STRIKE_SPEED, 0.001), 0.0, 1.0)
			return float(vfx.local_glow_slice_base) + float(vfx.local_glow_slice_speed_scale) * slice_speed_ratio
		SwordState.RECALLING:
			var recall_speed_ratio: float = clampf(Vector2(sword.get("vel", Vector2.ZERO)).length() / maxf(SWORD_RECALL_SPEED, 0.001), 0.0, 1.0)
			return float(vfx.local_glow_recall_base) + float(vfx.local_glow_recall_speed_scale) * recall_speed_ratio
		_:
			return float(vfx.local_glow_ranged_idle)


func _get_preview_glow_style() -> String:
	match int(sword.get("state", SwordState.ORBITING)):
		SwordState.POINT_STRIKE:
			return "point"
		SwordState.SLICING:
			return "slice"
		SwordState.RECALLING:
			return "recall"
		_:
			return "idle"


func _draw_player_presence(player_pos: Vector2) -> void:
	var pulse: float = 0.5 + 0.5 * sin(elapsed_time * 2.4)
	var slow_pulse: float = 0.5 + 0.5 * sin(elapsed_time * 1.2 + 0.6)
	var core_color: Color = COLORS["player"].lerp(Color.WHITE, 0.22)
	var aura_color: Color = Color("7dd3fc")
	var ring_color: Color = Color("d7bb79")
	draw_circle(player_pos, PLAYER_RADIUS + 11.0 + 4.0 * pulse, Color(aura_color.r, aura_color.g, aura_color.b, 0.06))
	draw_circle(player_pos, PLAYER_RADIUS + 4.0 + 2.0 * slow_pulse, Color(core_color.r, core_color.g, core_color.b, 0.1))
	draw_circle(player_pos, PLAYER_RADIUS, COLORS["player"])
	draw_circle(player_pos, PLAYER_RADIUS - 4.0, Color(core_color.r, core_color.g, core_color.b, 0.44))
	draw_arc(player_pos, PLAYER_RADIUS + 8.0, 0.0, TAU, 28, Color(aura_color.r, aura_color.g, aura_color.b, 0.22), 1.4)
	draw_arc(player_pos, PLAYER_RADIUS + 15.0 + 2.0 * pulse, 0.0, TAU, 32, Color(ring_color.r, ring_color.g, ring_color.b, 0.12), 1.0)
	draw_arc(player_pos, PLAYER_RADIUS + 22.0 + 3.0 * slow_pulse, PI * 0.16, PI * 1.68, 26, Color(aura_color.r, aura_color.g, aura_color.b, 0.14), 1.0)
	var tick_radius: float = PLAYER_RADIUS + 18.0
	for tick_index in range(6):
		var angle: float = float(tick_index) / 6.0 * TAU + elapsed_time * 0.12
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var tick_center: Vector2 = player_pos + direction * tick_radius
		draw_line(
			tick_center - direction * 2.0,
			tick_center + direction * 4.0,
			Color(ring_color.r, ring_color.g, ring_color.b, 0.18),
			1.0
		)


func _draw_preview_guides() -> void:
	var player_pos: Vector2 = _to_screen(player["pos"])
	var accent_color: Color = Color(0.85, 0.74, 0.48, 0.14)
	draw_arc(player_pos, 68.0, 0.0, TAU, 36, accent_color, 1.0)
	match preview_mode:
		PreviewMode.POINT:
			var target: Vector2 = _to_screen(Vector2(ARENA_SIZE.x * 0.74, ARENA_SIZE.y * 0.3))
			draw_line(player_pos, target, Color(0.5, 0.8, 1.0, 0.08), 1.0)
			draw_arc(target, 18.0, 0.0, TAU, 24, Color(1.0, 0.92, 0.78, 0.16), 1.0)
		PreviewMode.SLICE:
			var center: Vector2 = _to_screen(Vector2(ARENA_SIZE.x * 0.58, ARENA_SIZE.y * 0.46))
			draw_arc(center, 180.0, 0.0, TAU, 48, Color(0.5, 0.8, 1.0, 0.06), 1.0)
			draw_arc(center, 104.0, 0.0, TAU, 48, Color(1.0, 0.9, 0.72, 0.04), 1.0)
		PreviewMode.RECALL:
			var start: Vector2 = _to_screen(Vector2(ARENA_SIZE.x * 0.78, ARENA_SIZE.y * 0.28))
			draw_line(start, player_pos, Color(1.0, 0.9, 0.72, 0.08), 1.0)
			draw_arc(start, 14.0, 0.0, TAU, 20, Color(0.6, 0.84, 1.0, 0.14), 1.0)


func _create_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	add_child(overlay_layer)

	mode_label = Label.new()
	mode_label.position = Vector2(24.0, 18.0)
	mode_label.size = Vector2(520.0, 32.0)
	mode_label.add_theme_font_size_override("font_size", 24)
	mode_label.add_theme_color_override("font_color", Color("f1e3bc"))
	mode_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.4))
	mode_label.add_theme_constant_override("shadow_offset_x", 0)
	mode_label.add_theme_constant_override("shadow_offset_y", 2)
	overlay_layer.add_child(mode_label)

	hint_label = Label.new()
	hint_label.position = Vector2(24.0, 52.0)
	hint_label.size = Vector2(860.0, 48.0)
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color("9cb0c2"))
	hint_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.35))
	hint_label.add_theme_constant_override("shadow_offset_x", 0)
	hint_label.add_theme_constant_override("shadow_offset_y", 2)
	overlay_layer.add_child(hint_label)

	control_panel = PanelContainer.new()
	control_panel.position = Vector2(ARENA_RECT.end.x + 20.0, 92.0)
	control_panel.size = Vector2(PANEL_WIDTH, 780.0)
	control_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.add_child(control_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 14)
	panel_margin.add_theme_constant_override("margin_top", 14)
	panel_margin.add_theme_constant_override("margin_right", 14)
	panel_margin.add_theme_constant_override("margin_bottom", 14)
	control_panel.add_child(panel_margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_margin.add_child(scroll)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(root_vbox)

	var title := Label.new()
	title.text = "御剑特效实时调参"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("f1e3bc"))
	root_vbox.add_child(title)

	var sub_title := Label.new()
	sub_title.text = "拖动滑杆立即影响当前预览"
	sub_title.add_theme_font_size_override("font_size", 14)
	sub_title.add_theme_color_override("font_color", Color("9cb0c2"))
	root_vbox.add_child(sub_title)

	reset_button = Button.new()
	reset_button.text = "恢复推荐值"
	reset_button.pressed.connect(_reset_vfx_profile)
	root_vbox.add_child(reset_button)

	for group_spec in LOOKDEV_CONTROLS:
		var group_label := Label.new()
		group_label.text = str(group_spec["title"])
		group_label.add_theme_font_size_override("font_size", 17)
		group_label.add_theme_color_override("font_color", Color("d7bb79"))
		root_vbox.add_child(group_label)
		for item in group_spec["items"]:
			var row := _create_slider_row(item)
			root_vbox.add_child(row["container"])
			slider_rows.append(row)

	_sync_slider_rows_from_profile()


func _update_overlay() -> void:
	if mode_label == null or hint_label == null:
		return
	var mode_text := "点刺"
	match preview_mode:
		PreviewMode.SLICE:
			mode_text = "连斩"
		PreviewMode.RECALL:
			mode_text = "回收"
	mode_label.text = "御剑特效预览 · %s%s" % [mode_text, " · 暂停" if preview_paused else ""]
	hint_label.text = "1 点刺  2 连斩  3 回收  |  Space 暂停/继续  |  R 重播  |  右侧直接拖中文滑杆"


func _create_slider_row(spec: Dictionary) -> Dictionary:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	container.add_child(title_row)

	var name_label := Label.new()
	name_label.text = str(spec["label"])
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color("e7dec3"))
	title_row.add_child(name_label)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(72.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", Color("88d8ff"))
	title_row.add_child(value_label)

	var slider := HSlider.new()
	slider.min_value = float(spec["min"])
	slider.max_value = float(spec["max"])
	slider.step = float(spec["step"])
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider_value_changed.bind(String(spec["prop"]), value_label))
	container.add_child(slider)

	return {
		"container": container,
		"slider": slider,
		"value_label": value_label,
		"prop": String(spec["prop"]),
		"step": float(spec["step"]),
	}


func _sync_slider_rows_from_profile() -> void:
	var profile: SwordVfxProfile = get_sword_vfx_profile()
	for row_variant in slider_rows:
		var row: Dictionary = row_variant
		var prop: String = row["prop"]
		var slider: HSlider = row["slider"]
		var value_label: Label = row["value_label"]
		var step: float = float(row["step"])
		var value: float = float(profile.get(prop))
		slider.set_block_signals(true)
		slider.value = value
		slider.set_block_signals(false)
		value_label.text = _format_slider_value(value, step)


func _on_slider_value_changed(value: float, prop: String, value_label: Label) -> void:
	var profile: SwordVfxProfile = get_sword_vfx_profile()
	profile.set(prop, value)
	var step := 0.01
	for row_variant in slider_rows:
		var row: Dictionary = row_variant
		if str(row["prop"]) == prop:
			step = float(row["step"])
			break
	value_label.text = _format_slider_value(value, step)


func _format_slider_value(value: float, step: float) -> String:
	if step >= 1.0:
		return str(int(round(value)))
	if step >= 0.1:
		return "%.1f" % value
	if step >= 0.01:
		return "%.2f" % value
	return "%.3f" % value


func _reset_vfx_profile() -> void:
	sword_vfx_profile = source_sword_vfx_profile.duplicate(true)
	_sync_slider_rows_from_profile()
