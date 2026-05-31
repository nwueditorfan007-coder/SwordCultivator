extends Node2D

const VIEW_SIZE := Vector2(1280.0, 720.0)
const PLAY_RECT := Rect2(Vector2(120.0, 96.0), Vector2(3280.0, 1280.0))
const START_POS := Vector2(460.0, 760.0)
const CAMERA_LOOK_AHEAD_TIME := 0.32
const CAMERA_MAX_LOOK_AHEAD := Vector2(380.0, 160.0)
const CAMERA_HALF_LIFE := 0.10
const WORLD_GRID_STEP := 320.0

const FRAME_COLUMNS := 7
const CELL_SIZE := Vector2(512.0, 512.0)
const POSE_OFFSET := Vector2(-10.0, -6.0)
const SHEET_FACE_SIGN := 1.0

const CLIP_CRUISE := 0
const CLIP_CRUISE_TURN := 1
const CLIP_BOOST := 2
const CLIP_HARD_TURN_CORE := 3
const CLIP_HARD_TURN_TO_BOOST := 4
const SIDE_LIMIT := deg_to_rad(90.0)
const TURN_ARM_ANGLE := deg_to_rad(82.0)
const CRUISE_TURN_EXIT_ANGLE := deg_to_rad(64.0)
const HARD_TURN_EXIT_ANGLE := deg_to_rad(74.0)
const CRUISE_TURN_FLIP_PHASE := 0.50
const HARD_TURN_FLIP_PHASE := 0.52

const CRUISE_SPEED := 420.0
const BOOST_SPEED := 610.0
const HIGH_SPEED_TURN_MIN_SPEED := 520.0
const BOOST_VISUAL_ENTER_SPEED := 520.0
const BOOST_VISUAL_EXIT_SPEED := 455.0
const ACCELERATION := 980.0
const BOOST_ACCELERATION := 1320.0
const TURN_RATE := deg_to_rad(132.0)
const HARD_TURN_SPEED_GAIN := 86.0
const TRAIL_LIFE := 0.78
const AFTERIMAGE_LIFE := 0.32

const CYAN := Color(0.42, 0.96, 1.0, 1.0)
const CORE := Color(0.96, 1.0, 0.98, 1.0)
const INK := Color(0.012, 0.016, 0.018, 1.0)

const CLIPS := [
	{
		"name": "cruise",
		"path": "res://resources/flight/generated/yujian_v2_cruise_idle.png",
		"frames": 49,
		"fps": 20.0,
		"loop": true,
	},
	{
		"name": "cruise_turn",
		"path": "res://resources/flight/generated/yujian_v2_cruise_turn.png",
		"frames": 49,
		"fps": 64.0,
		"loop": false,
	},
	{
		"name": "boost",
		"path": "res://resources/flight/generated/yujian_v2_boost_idle.png",
		"frames": 49,
		"fps": 26.0,
		"loop": true,
	},
	{
		"name": "hard_turn_core",
		"path": "res://resources/flight/generated/yujian_v2_hard_turn_core.png",
		"frames": 16,
		"fps": 30.0,
		"loop": false,
	},
	{
		"name": "hard_turn_to_boost",
		"path": "res://resources/flight/generated/yujian_v2_hard_turn_to_boost.png",
		"frames": 21,
		"fps": 48.0,
		"loop": false,
	},
]

@export var auto_demo := true
@export_range(0.25, 2.0, 0.05) var demo_speed := 0.85
@export_range(0.25, 0.8, 0.01) var sprite_scale := 0.46
@export_range(0.8, 1.35, 0.05) var camera_zoom := 1.04
@export var background_key_enabled := true

var sprite_root: Node2D
var character_sprite: Sprite2D
var key_shader: Shader
var texture_cache: Dictionary = {}
var sheet_texture: Texture2D

var flight_pos := START_POS
var velocity := Vector2(CRUISE_SPEED, 0.0)
var camera_center := START_POS
var target_heading := Vector2.RIGHT
var render_sign := 1.0
var side_angle := 0.0
var target_side_angle := 0.0
var turn_pole := 1.0
var turn_from_sign := 1.0
var turn_to_sign := -1.0
var turn_flipped := false
var demo_angle := 0.0
var time := 0.0
var clip_index := CLIP_CRUISE
var frame_index := 0
var frame_timer := 0.0
var trail_points: Array = []
var afterimages: Array = []


func _ready() -> void:
	_create_nodes()
	_reset_prototype()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var step := minf(delta, 1.0 / 30.0)
	time += step
	_update_input_and_turn(step)
	_update_motion(step)
	_refresh_loop_clip()
	_update_camera(step)
	_update_clip(step)
	_update_trail(step)
	_update_afterimages(step)
	_apply_sprite_transform()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_reset_prototype()
			KEY_T:
				auto_demo = not auto_demo
			KEY_K:
				background_key_enabled = not background_key_enabled
				character_sprite.material = _make_key_material()


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

	sprite_root = Node2D.new()
	sprite_root.name = "SideViewSequenceRoot"
	sprite_root.z_index = 10
	add_child(sprite_root)

	character_sprite = Sprite2D.new()
	character_sprite.name = "SideViewSequenceCharacter"
	character_sprite.centered = true
	character_sprite.region_enabled = true
	character_sprite.position = POSE_OFFSET
	character_sprite.material = _make_key_material()
	sprite_root.add_child(character_sprite)


func _make_key_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = key_shader
	material.set_shader_parameter("key_strength", 1.0)
	material.set_shader_parameter("key_mode", 2 if background_key_enabled else 0)
	return material


func _reset_prototype() -> void:
	flight_pos = START_POS
	velocity = Vector2(CRUISE_SPEED, 0.0)
	camera_center = START_POS + Vector2(130.0, -20.0)
	target_heading = Vector2.RIGHT
	render_sign = 1.0
	side_angle = 0.0
	target_side_angle = 0.0
	turn_pole = 1.0
	turn_from_sign = 1.0
	turn_to_sign = -1.0
	turn_flipped = false
	demo_angle = 0.0
	trail_points.clear()
	afterimages.clear()
	_start_clip(CLIP_CRUISE)
	_apply_sprite_transform()


func _update_input_and_turn(delta: float) -> void:
	var axis := _get_move_axis(delta)
	if axis.length_squared() > 0.01:
		target_heading = axis.normalized()

	if _is_turning():
		_update_turn_pose()
		return

	target_side_angle = _local_angle_for_sign(target_heading, render_sign)
	if absf(target_side_angle) > SIDE_LIMIT:
		var pole := _resolve_turn_pole(target_side_angle, target_heading)
		if absf(side_angle) >= TURN_ARM_ANGLE and signf(side_angle) == pole:
			if _should_use_high_speed_turn():
				_start_high_speed_turn(pole)
			else:
				_start_cruise_turn(pole)
			return
		target_side_angle = pole * SIDE_LIMIT

	var max_step := TURN_RATE * delta
	side_angle = move_toward(side_angle, clampf(target_side_angle, -SIDE_LIMIT, SIDE_LIMIT), max_step)


func _get_move_axis(delta: float) -> Vector2:
	var manual_axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var arrow_axis := Vector2(
		float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	)
	manual_axis += arrow_axis
	if manual_axis.length_squared() > 1.0:
		manual_axis = manual_axis.normalized()
	if manual_axis.length_squared() > 0.01:
		auto_demo = false
		return manual_axis
	if auto_demo:
		demo_angle = wrapf(demo_angle + delta * demo_speed, -PI, PI)
		return Vector2(cos(demo_angle), -sin(demo_angle))
	return _heading_from_sign_angle(render_sign, side_angle)


func _resolve_turn_pole(local_angle: float, heading: Vector2) -> float:
	if absf(absf(local_angle) - PI) < deg_to_rad(8.0):
		if absf(side_angle) > deg_to_rad(12.0):
			return signf(side_angle)
		if absf(heading.y) > 0.05:
			return -signf(heading.y)
	return signf(local_angle) if local_angle != 0.0 else 1.0


func _start_cruise_turn(pole: float) -> void:
	_prepare_turn(pole)
	_capture_afterimage(0.36)
	_start_clip(CLIP_CRUISE_TURN)


func _start_high_speed_turn(pole: float) -> void:
	_prepare_turn(pole)
	velocity += _heading_from_sign_angle(render_sign, side_angle) * HARD_TURN_SPEED_GAIN
	_capture_afterimage(0.9)
	_capture_afterimage(0.54)
	_start_clip(CLIP_HARD_TURN_CORE)


func _prepare_turn(pole: float) -> void:
	turn_pole = signf(pole) if pole != 0.0 else 1.0
	turn_from_sign = render_sign
	turn_to_sign = -render_sign
	turn_flipped = false
	side_angle = turn_pole * SIDE_LIMIT


func _update_turn_pose() -> void:
	var phase := _clip_phase()
	match clip_index:
		CLIP_CRUISE_TURN:
			_update_flipped_turn_pose(phase, CRUISE_TURN_FLIP_PHASE, CRUISE_TURN_EXIT_ANGLE)
		CLIP_HARD_TURN_CORE:
			if not turn_flipped and phase >= HARD_TURN_FLIP_PHASE:
				_flip_turn(0.72)
			side_angle = turn_pole * SIDE_LIMIT
		CLIP_HARD_TURN_TO_BOOST:
			if not turn_flipped:
				_flip_turn(0.54)
			side_angle = turn_pole * lerpf(SIDE_LIMIT, HARD_TURN_EXIT_ANGLE, phase)


func _update_flipped_turn_pose(phase: float, flip_phase: float, exit_angle: float) -> void:
	if not turn_flipped and phase >= flip_phase:
		_flip_turn(0.48)
	if turn_flipped:
		var out_phase := inverse_lerp(flip_phase, 1.0, phase)
		side_angle = turn_pole * lerpf(SIDE_LIMIT, exit_angle, clampf(out_phase, 0.0, 1.0))
	else:
		side_angle = turn_pole * SIDE_LIMIT


func _flip_turn(afterimage_intensity: float) -> void:
	render_sign = turn_to_sign
	turn_flipped = true
	_capture_afterimage(afterimage_intensity)


func _finish_cruise_turn() -> void:
	render_sign = turn_to_sign
	turn_flipped = false
	side_angle = turn_pole * CRUISE_TURN_EXIT_ANGLE
	target_heading = _heading_from_sign_angle(render_sign, side_angle)
	_start_clip(CLIP_CRUISE)


func _finish_high_speed_turn() -> void:
	render_sign = turn_to_sign
	turn_flipped = false
	side_angle = turn_pole * HARD_TURN_EXIT_ANGLE
	target_heading = _heading_from_sign_angle(render_sign, side_angle)
	_start_clip(CLIP_BOOST if _should_show_boost_loop() else CLIP_CRUISE)


func _update_motion(delta: float) -> void:
	var boost_pressed := Input.is_action_pressed("dash")
	var speed := BOOST_SPEED if boost_pressed else CRUISE_SPEED
	var accel := BOOST_ACCELERATION if boost_pressed else ACCELERATION
	var heading := _heading_from_sign_angle(render_sign, side_angle)
	if _is_turning():
		heading = _turn_heading()
	if _is_hard_turning():
		speed += 54.0
		accel *= 1.18
	elif clip_index == CLIP_CRUISE_TURN:
		speed *= 0.94
		accel *= 1.05
	velocity = velocity.move_toward(heading * speed, accel * delta)
	flight_pos += velocity * delta
	_apply_bounds()


func _turn_heading() -> Vector2:
	var sign_to_use := turn_to_sign if turn_flipped else turn_from_sign
	return _heading_from_sign_angle(sign_to_use, side_angle)


func _refresh_loop_clip() -> void:
	if _is_turning():
		return
	var next_loop := CLIP_BOOST if _should_show_boost_loop() else CLIP_CRUISE
	if clip_index != next_loop:
		_start_clip(next_loop)


func _should_show_boost_loop() -> bool:
	if Input.is_action_pressed("dash"):
		return true
	if clip_index == CLIP_BOOST:
		return velocity.length() >= BOOST_VISUAL_EXIT_SPEED
	return velocity.length() >= BOOST_VISUAL_ENTER_SPEED


func _should_use_high_speed_turn() -> bool:
	return Input.is_action_pressed("dash") or velocity.length() >= HIGH_SPEED_TURN_MIN_SPEED


func _apply_bounds() -> void:
	if flight_pos.x < PLAY_RECT.position.x:
		flight_pos.x = PLAY_RECT.position.x
		velocity.x = absf(velocity.x) * 0.44
	if flight_pos.x > PLAY_RECT.end.x:
		flight_pos.x = PLAY_RECT.end.x
		velocity.x = -absf(velocity.x) * 0.44
	if flight_pos.y < PLAY_RECT.position.y:
		flight_pos.y = PLAY_RECT.position.y
		velocity.y = absf(velocity.y) * 0.44
	if flight_pos.y > PLAY_RECT.end.y:
		flight_pos.y = PLAY_RECT.end.y
		velocity.y = -absf(velocity.y) * 0.44


func _update_camera(delta: float) -> void:
	var look_ahead := velocity * CAMERA_LOOK_AHEAD_TIME
	look_ahead.x = clampf(look_ahead.x, -CAMERA_MAX_LOOK_AHEAD.x, CAMERA_MAX_LOOK_AHEAD.x)
	look_ahead.y = clampf(look_ahead.y, -CAMERA_MAX_LOOK_AHEAD.y, CAMERA_MAX_LOOK_AHEAD.y)
	var target_center := _clamp_camera_center(flight_pos + look_ahead)
	camera_center = _damp_vector2(camera_center, target_center, CAMERA_HALF_LIFE, delta)


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


func _update_clip(delta: float) -> void:
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
				match clip_index:
					CLIP_CRUISE_TURN:
						_finish_cruise_turn()
					CLIP_HARD_TURN_CORE:
						if not turn_flipped:
							_flip_turn(0.54)
						_start_clip(CLIP_HARD_TURN_TO_BOOST)
					CLIP_HARD_TURN_TO_BOOST:
						_finish_high_speed_turn()
				return
		_apply_frame()


func _start_clip(next_clip: int) -> void:
	clip_index = clampi(next_clip, 0, CLIPS.size() - 1)
	frame_index = 0
	frame_timer = 0.0
	var clip := _current_clip()
	sheet_texture = _load_sequence_texture(String(clip["path"]))
	if sheet_texture == null:
		push_warning("Missing side-view yujian sheet: %s" % String(clip["path"]))
		return
	character_sprite.texture = sheet_texture
	_apply_frame()


func _load_sequence_texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	var texture := load(path) as Texture2D
	if texture != null:
		texture_cache[path] = texture
	return texture


func _apply_frame() -> void:
	if character_sprite == null:
		return
	character_sprite.region_rect = _get_frame_rect(frame_index)


func _get_frame_rect(index: int) -> Rect2:
	var column := index % FRAME_COLUMNS
	var row := int(floor(float(index) / float(FRAME_COLUMNS)))
	return Rect2(Vector2(column, row) * CELL_SIZE, CELL_SIZE)


func _apply_sprite_transform() -> void:
	if sprite_root == null or character_sprite == null:
		return
	sprite_root.position = _world_to_screen(flight_pos)
	sprite_root.rotation = _render_rotation()
	character_sprite.position = POSE_OFFSET + Vector2(0.0, -8.0 / maxf(camera_zoom, 0.001))
	var draw_scale := sprite_scale / maxf(camera_zoom, 0.001)
	character_sprite.scale = Vector2(render_sign * SHEET_FACE_SIGN * draw_scale, draw_scale)


func _update_trail(delta: float) -> void:
	for point in trail_points:
		point["age"] = float(point["age"]) + delta
	trail_points = trail_points.filter(func(point: Dictionary) -> bool: return float(point["age"]) <= TRAIL_LIFE)
	var anchor := flight_pos - _safe_velocity_dir() * 54.0 + Vector2(0.0, 36.0)
	if trail_points.is_empty() or Vector2(trail_points[-1]["pos"]).distance_to(anchor) > 12.0:
		trail_points.append({
			"pos": anchor,
			"age": 0.0,
			"speed": velocity.length(),
			"turn": absf(side_angle) / SIDE_LIMIT,
			"hard": 1.0 if _is_hard_turning() else 0.0,
			"cruise_turn": 1.0 if clip_index == CLIP_CRUISE_TURN else 0.0,
		})


func _update_afterimages(delta: float) -> void:
	for image in afterimages:
		image["age"] = float(image["age"]) + delta
	afterimages = afterimages.filter(func(image: Dictionary) -> bool: return float(image["age"]) <= AFTERIMAGE_LIFE)
	if _is_turning() and (afterimages.is_empty() or float(afterimages[-1].get("age", 1.0)) > 0.06):
		_capture_afterimage(0.42 if _is_hard_turning() else 0.22)


func _capture_afterimage(intensity: float) -> void:
	if sheet_texture == null:
		return
	afterimages.append({
		"texture": sheet_texture,
		"source": _get_frame_rect(frame_index),
		"pos": flight_pos,
		"rotation": _render_rotation(),
		"facing": render_sign * SHEET_FACE_SIGN,
		"scale": sprite_scale,
		"age": 0.0,
		"intensity": intensity,
		"velocity": velocity,
	})


func _draw() -> void:
	_draw_background()
	_draw_world_guides()
	_draw_trail()
	_draw_afterimages()
	_draw_side_plane()
	_draw_debug_overlay()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.67, 0.73, 0.74, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.03, 0.045, 0.05, 0.14))
	_draw_mountain_band(0.27, 0.55, Color(0.18, 0.20, 0.20, 0.18), 0.0)
	_draw_mountain_band(0.52, 0.86, Color(0.04, 0.055, 0.055, 0.34), 1.25)
	for i in range(12):
		var y := 86.0 + float(i) * 48.0 + sin(time * 0.12 + float(i)) * 8.0
		var x := fmod(time * (12.0 + float(i % 3) * 2.5) + float(i) * 211.0, VIEW_SIZE.x + 260.0) - 130.0
		_draw_cloud_wisp(Vector2(x, y), 130.0 + float(i % 3) * 36.0, Color(0.95, 0.97, 0.96, 0.13))


func _draw_mountain_band(top_ratio: float, bottom_ratio: float, color: Color, phase_offset: float) -> void:
	var top := VIEW_SIZE.y * top_ratio
	var bottom := VIEW_SIZE.y * bottom_ratio
	var points := PackedVector2Array([Vector2(0.0, bottom)])
	for i in range(12):
		var f := float(i) / 11.0
		var ridge := top + 92.0 * absf(sin(float(i) * 0.94 + phase_offset))
		points.append(Vector2(VIEW_SIZE.x * f, clampf(ridge, top, bottom - 20.0)))
	points.append(Vector2(VIEW_SIZE.x, bottom))
	draw_colored_polygon(points, color)


func _draw_cloud_wisp(origin: Vector2, length: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(12):
		var f := float(i) / 11.0
		points.append(origin + Vector2(length * (f - 0.5), sin(f * TAU + time * 0.18) * 7.0))
	draw_polyline(points, color, 5.0, true)


func _draw_world_guides() -> void:
	var visible := _visible_world_rect()
	var start_x := floorf(visible.position.x / WORLD_GRID_STEP) * WORLD_GRID_STEP
	var x := start_x
	while x <= visible.end.x + WORLD_GRID_STEP:
		var alpha := 0.13 if int(round(x / WORLD_GRID_STEP)) % 4 == 0 else 0.052
		draw_line(_world_to_screen(Vector2(x, visible.position.y)), _world_to_screen(Vector2(x, visible.end.y)), Color(0.74, 0.96, 0.98, alpha), 1.0)
		x += WORLD_GRID_STEP
	var start_y := floorf(visible.position.y / WORLD_GRID_STEP) * WORLD_GRID_STEP
	var y := start_y
	while y <= visible.end.y + WORLD_GRID_STEP:
		var alpha := 0.12 if int(round(y / WORLD_GRID_STEP)) % 3 == 0 else 0.048
		draw_line(_world_to_screen(Vector2(visible.position.x, y)), _world_to_screen(Vector2(visible.end.x, y)), Color(0.74, 0.96, 0.98, alpha), 1.0)
		y += WORLD_GRID_STEP
	var rect_screen := Rect2(_world_to_screen(PLAY_RECT.position), PLAY_RECT.size / maxf(camera_zoom, 0.001))
	draw_rect(rect_screen, Color(0.22, 0.65, 0.72, 0.25), false, 1.4)


func _draw_trail() -> void:
	if trail_points.size() < 2:
		return
	for i in range(1, trail_points.size()):
		var prev: Dictionary = trail_points[i - 1]
		var current: Dictionary = trail_points[i]
		var age := (float(prev["age"]) + float(current["age"])) * 0.5
		var life := clampf(1.0 - age / TRAIL_LIFE, 0.0, 1.0)
		var speed_factor := clampf(float(current["speed"]) / BOOST_SPEED, 0.0, 1.0)
		var turn_factor := float(current["turn"])
		var hard_factor := float(current["hard"])
		var cruise_turn_factor := float(current.get("cruise_turn", 0.0))
		var width := (7.0 + speed_factor * 26.0 + turn_factor * 18.0 + cruise_turn_factor * 10.0 + hard_factor * 32.0) * life / maxf(camera_zoom, 0.001)
		var halo := CYAN
		halo.a = (0.06 + speed_factor * 0.08 + cruise_turn_factor * 0.05 + hard_factor * 0.12) * life
		var core := CORE
		core.a = (0.15 + turn_factor * 0.20 + hard_factor * 0.24) * life
		draw_line(_world_to_screen(Vector2(prev["pos"])), _world_to_screen(Vector2(current["pos"])), halo, width * 2.2, true)
		draw_line(_world_to_screen(Vector2(prev["pos"])), _world_to_screen(Vector2(current["pos"])), core, maxf(width * 0.34, 1.4), true)


func _draw_afterimages() -> void:
	for image in afterimages:
		var texture := image.get("texture") as Texture2D
		if texture == null:
			continue
		var age := float(image["age"])
		var life := clampf(1.0 - age / AFTERIMAGE_LIFE, 0.0, 1.0)
		var source: Rect2 = image.get("source", Rect2(Vector2.ZERO, CELL_SIZE))
		var draw_scale := float(image.get("scale", sprite_scale)) / maxf(camera_zoom, 0.001)
		var drift: Vector2 = Vector2(image.get("velocity", Vector2.ZERO)) * -0.055 * age
		var pos := _world_to_screen(Vector2(image["pos"]) + drift)
		var destination := Rect2(-source.size * draw_scale * 0.5, source.size * draw_scale)
		var color := Color(0.44, 1.0, 1.0, 0.09 * life * float(image.get("intensity", 1.0)))
		draw_set_transform(pos, float(image.get("rotation", 0.0)), Vector2(float(image.get("facing", 1.0)), 1.0))
		draw_texture_rect_region(texture, destination, source, color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_side_plane() -> void:
	var pos := _world_to_screen(flight_pos)
	var rotation := _render_rotation()
	var scale := 1.0 / maxf(camera_zoom, 0.001)
	var hard := 1.0 if _is_hard_turning() else 0.0
	var soft := 1.0 if clip_index == CLIP_CRUISE_TURN else 0.0
	draw_set_transform(pos, rotation, Vector2(scale, scale))
	var glow := CYAN
	glow.a = 0.20 + soft * 0.08 + hard * 0.18
	draw_line(Vector2(-112.0, 84.0), Vector2(130.0, 84.0), glow, 18.0 + soft * 8.0 + hard * 18.0, true)
	var blade := PackedVector2Array([
		Vector2(138.0, 84.0),
		Vector2(88.0, 72.0),
		Vector2(-112.0, 78.0),
		Vector2(-132.0, 86.0),
		Vector2(-92.0, 92.0),
		Vector2(88.0, 94.0),
	])
	draw_colored_polygon(blade, Color(0.80, 1.0, 0.98, 0.88))
	draw_polyline(blade, Color(0.0, 0.06, 0.07, 0.46), 1.4, true)
	var foot_line := Color(0.02, 0.035, 0.036, 0.72)
	draw_line(Vector2(-36.0, 64.0), Vector2(52.0, 64.0), foot_line, 4.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_debug_overlay() -> void:
	var clip := _current_clip()
	var display_degrees := _display_angle_degrees(_heading_from_sign_angle(render_sign, side_angle))
	var side_degrees := rad_to_deg(side_angle)
	var target_degrees := rad_to_deg(target_side_angle)
	var mode := _turn_mode_label()
	var hint := "Side-view yujian turn prototype | WASD/Arrow steer heading | Space speed | R reset | T demo | K key"
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 32.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16.0, Color(0.91, 0.96, 0.95, 0.84))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 56.0), "mode: %s  clip: %s %d/%d  facing: %s  side %.0fdeg target %.0fdeg display %.0fdeg  speed %.0f  demo %s" % [mode, String(clip["name"]), frame_index, int(clip["frames"]) - 1, "right" if render_sign > 0.0 else "left", side_degrees, target_degrees, display_degrees, velocity.length(), str(auto_demo)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.70, 0.84, 0.84, 0.76))
	var sign_text := "top" if side_angle >= 0.0 else "bottom"
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 78.0), "Low speed: cruise_turn. High speed/Space: hard_turn_core -> hard_turn_to_boost. Edge: %s" % sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.64, 0.76, 0.76, 0.62))


func _local_angle_for_sign(direction: Vector2, side_sign: float) -> float:
	if direction.length_squared() <= 0.0001:
		return side_angle
	var display_angle := atan2(-direction.y, direction.x)
	if side_sign >= 0.0:
		return wrapf(display_angle, -PI, PI)
	return wrapf(PI - display_angle, -PI, PI)


func _heading_from_sign_angle(side_sign: float, local_angle: float) -> Vector2:
	var display_angle := local_angle if side_sign >= 0.0 else PI - local_angle
	return Vector2(cos(display_angle), -sin(display_angle)).normalized()


func _render_rotation() -> float:
	var heading := _heading_from_sign_angle(render_sign, side_angle)
	var base_angle := heading.angle()
	if render_sign < 0.0:
		return wrapf(base_angle - PI, -PI, PI)
	return base_angle


func _display_angle_degrees(direction: Vector2) -> float:
	return rad_to_deg(wrapf(atan2(-direction.y, direction.x), -PI, PI))


func _is_turning() -> bool:
	return clip_index == CLIP_CRUISE_TURN or _is_hard_turning()


func _is_hard_turning() -> bool:
	return clip_index == CLIP_HARD_TURN_CORE or clip_index == CLIP_HARD_TURN_TO_BOOST


func _turn_mode_label() -> String:
	match clip_index:
		CLIP_CRUISE_TURN:
			return "cruise turn"
		CLIP_HARD_TURN_CORE:
			return "hard turn core"
		CLIP_HARD_TURN_TO_BOOST:
			return "hard turn to boost"
		CLIP_BOOST:
			return "boost"
		_:
			return "cruise"


func _clip_phase() -> float:
	var clip := _current_clip()
	var frame_count := maxi(int(clip["frames"]) - 1, 1)
	return clampf(float(frame_index) / float(frame_count), 0.0, 1.0)


func _current_clip() -> Dictionary:
	return CLIPS[clip_index]


func _safe_velocity_dir() -> Vector2:
	if velocity.length_squared() > 0.001:
		return velocity.normalized()
	return _heading_from_sign_angle(render_sign, side_angle)


func _visible_world_rect() -> Rect2:
	return Rect2(camera_center - VIEW_SIZE * 0.5 * camera_zoom, VIEW_SIZE * camera_zoom).intersection(PLAY_RECT)


func _world_to_screen(world_pos: Vector2) -> Vector2:
	return (world_pos - camera_center) / maxf(camera_zoom, 0.001) + VIEW_SIZE * 0.5


func _damp_float(current: float, target: float, half_life: float, delta: float) -> float:
	if half_life <= 0.0:
		return target
	var decay := pow(0.5, delta / half_life)
	return target + (current - target) * decay


func _damp_vector2(current: Vector2, target: Vector2, half_life: float, delta: float) -> Vector2:
	return Vector2(
		_damp_float(current.x, target.x, half_life, delta),
		_damp_float(current.y, target.y, half_life, delta)
	)
