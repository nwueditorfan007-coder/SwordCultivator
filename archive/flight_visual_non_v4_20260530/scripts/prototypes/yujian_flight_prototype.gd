extends Node2D

const VIEW_SIZE := Vector2(1280.0, 720.0)
const BASE_PLAY_ORIGIN := Vector2(88.0, 76.0)
const BASE_PLAY_SIZE := Vector2(1104.0, 568.0)
const FLIGHT_TEST_HORIZONTAL_SCALE := 5.0
const FLIGHT_TEST_VERTICAL_SCALE := 3.0
const PLAY_SIZE := Vector2(BASE_PLAY_SIZE.x * FLIGHT_TEST_HORIZONTAL_SCALE, BASE_PLAY_SIZE.y * FLIGHT_TEST_VERTICAL_SCALE)
const PLAY_RECT := Rect2(BASE_PLAY_ORIGIN, PLAY_SIZE)
const FLIGHT_START_POS := BASE_PLAY_ORIGIN + Vector2(PLAY_SIZE.x * 0.16, PLAY_SIZE.y * 0.50)
const CAMERA_LOOK_AHEAD_TIME := 0.24
const CAMERA_MAX_LOOK_AHEAD := Vector2(260.0, 120.0)
const CAMERA_HALF_LIFE := 0.08
const WORLD_GRID_STEP := 360.0
const MAX_SPEED := 720.0
const CRUISE_SPEED := 420.0
const ACCELERATION := 1120.0
const DASH_ACCELERATION := 1680.0
const DAMPING := 1.55
const BRAKE_DAMPING := 7.0
const TRAIL_LIFE := 0.85
const TRAIL_MIN_DISTANCE := 6.0
const CYAN := Color(0.48, 1.0, 0.96, 1.0)
const CORE := Color(0.96, 1.0, 0.98, 1.0)
const INK := Color(0.02, 0.025, 0.03, 1.0)
const INK_SOFT := Color(0.03, 0.038, 0.045, 0.88)

@export var auto_demo := true
@export_range(0.5, 1.6, 0.05) var demo_speed := 1.0
@export_range(0.7, 1.5, 0.05) var visual_scale := 1.18
@export_range(0.2, 1.4, 0.05) var sword_glow_strength := 0.9

var flight_pos := FLIGHT_START_POS
var velocity := Vector2(420.0, 0.0)
var previous_velocity := Vector2.ZERO
var acceleration := Vector2.ZERO
var facing := Vector2.RIGHT
var camera_center := FLIGHT_START_POS
var time := 0.0
var turn_energy := 0.0
var burst_energy := 0.0
var brake_energy := 0.0
var demo_phase_time := 0.0
var trail_points: Array = []
var secondary_chains: Array = []


func _ready() -> void:
	_reset_prototype()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var step: float = minf(delta, 1.0 / 30.0)
	time += step
	_update_flight(step)
	_update_camera(step)
	_update_secondary_motion(step)
	_update_trail(step)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_reset_prototype()
			KEY_T:
				auto_demo = not auto_demo


func _reset_prototype() -> void:
	flight_pos = FLIGHT_START_POS
	camera_center = FLIGHT_START_POS
	velocity = Vector2(360.0, -20.0)
	previous_velocity = velocity
	acceleration = Vector2.ZERO
	facing = Vector2.RIGHT
	time = 0.0
	turn_energy = 0.0
	burst_energy = 0.0
	brake_energy = 0.0
	demo_phase_time = 0.0
	trail_points.clear()
	_rebuild_secondary_chains()


func _rebuild_secondary_chains() -> void:
	secondary_chains.clear()
	_add_chain("hair_tail", Vector2(-13.0, -64.0), 6, 15.0, 0.972, 2.5, Color(0.0, 0.006, 0.008, 0.9), 0.95)
	_add_chain("sash_high", Vector2(-22.0, -25.0), 7, 18.0, 0.984, 3.1, Color(0.0, 0.008, 0.01, 0.82), 1.15)
	_add_chain("sash_low", Vector2(-18.0, 0.0), 6, 16.0, 0.982, 2.4, Color(0.0, 0.008, 0.01, 0.76), 1.0)


func _add_chain(id: String, anchor_local: Vector2, point_count: int, segment_length: float, damping: float, width: float, color: Color, wind_scale: float) -> void:
	var points: Array = []
	var prev_points: Array = []
	var root := _to_rider_world(anchor_local)
	for i in range(point_count):
		var point := root - facing * segment_length * float(i)
		points.append(point)
		prev_points.append(point)
	secondary_chains.append({
		"id": id,
		"anchor": anchor_local,
		"points": points,
		"prev_points": prev_points,
		"segment": segment_length,
		"damping": damping,
		"width": width,
		"color": color,
		"wind_scale": wind_scale,
	})


func _update_flight(delta: float) -> void:
	previous_velocity = velocity
	var manual_axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if manual_axis.length_squared() > 0.01:
		auto_demo = false
	if auto_demo:
		_update_demo_flight(delta)
	else:
		_update_manual_flight(delta, manual_axis)

	flight_pos += velocity * delta
	_constrain_to_play_rect()
	acceleration = (velocity - previous_velocity) / maxf(delta, 0.001)

	if velocity.length() > 18.0:
		var target_facing := velocity.normalized()
		var turn_amount := clampf(facing.angle_to(target_facing) / 1.2, -1.0, 1.0)
		turn_energy = lerpf(turn_energy, absf(turn_amount), minf(delta * 8.0, 1.0))
		facing = facing.slerp(target_facing, minf(delta * 6.5, 1.0)).normalized()
	else:
		turn_energy = lerpf(turn_energy, 0.0, minf(delta * 4.0, 1.0))
	burst_energy = lerpf(burst_energy, 0.0, minf(delta * 2.8, 1.0))
	brake_energy = lerpf(brake_energy, 0.0, minf(delta * 4.5, 1.0))


func _update_manual_flight(delta: float, manual_axis: Vector2) -> void:
	var desired_accel := Vector2.ZERO
	if manual_axis.length_squared() > 0.01:
		desired_accel = manual_axis.normalized() * ACCELERATION
		if Input.is_action_pressed("dash"):
			desired_accel += manual_axis.normalized() * DASH_ACCELERATION
			burst_energy = maxf(burst_energy, 1.0)
	else:
		desired_accel = -velocity * DAMPING
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		desired_accel += -velocity * BRAKE_DAMPING
		brake_energy = maxf(brake_energy, 1.0)
	velocity += desired_accel * delta
	velocity = velocity.limit_length(MAX_SPEED)


func _update_demo_flight(delta: float) -> void:
	demo_phase_time += delta * demo_speed
	var t := fmod(demo_phase_time, 10.0)
	var target_position := Vector2.ZERO
	var max_phase_speed := 430.0
	var responsiveness := ACCELERATION
	if t < 1.8:
		target_position = _field_point(0.58, 0.45)
	elif t < 3.2:
		target_position = _field_point(0.76, 0.78)
		max_phase_speed = 540.0
		burst_energy = maxf(burst_energy, 0.85)
	elif t < 4.45:
		target_position = _field_point(0.31, 0.27)
		max_phase_speed = 650.0
		responsiveness = DASH_ACCELERATION
		burst_energy = maxf(burst_energy, 1.0)
	elif t < 5.55:
		target_position = _field_point(0.32, 0.45)
		max_phase_speed = 360.0
		responsiveness = DASH_ACCELERATION
		brake_energy = maxf(brake_energy, 1.0)
	elif t < 7.15:
		target_position = _field_point(0.74, 0.31)
		max_phase_speed = 540.0
		burst_energy = maxf(burst_energy, 0.65)
	elif t < 8.2:
		target_position = _field_point(0.69, 0.47)
		max_phase_speed = 310.0
		brake_energy = maxf(brake_energy, 0.9)
	else:
		target_position = _field_point(0.16, 0.50)
		max_phase_speed = 500.0
	var target_velocity := (target_position - flight_pos) * 1.65
	target_velocity = target_velocity.limit_length(max_phase_speed)
	velocity = velocity.move_toward(target_velocity, responsiveness * delta)
	velocity = velocity.limit_length(MAX_SPEED)


func _constrain_to_play_rect() -> void:
	if flight_pos.x < PLAY_RECT.position.x:
		flight_pos.x = PLAY_RECT.position.x
		velocity.x = absf(velocity.x) * 0.42
	if flight_pos.x > PLAY_RECT.end.x:
		flight_pos.x = PLAY_RECT.end.x
		velocity.x = -absf(velocity.x) * 0.42
	if flight_pos.y < PLAY_RECT.position.y:
		flight_pos.y = PLAY_RECT.position.y
		velocity.y = absf(velocity.y) * 0.42
	if flight_pos.y > PLAY_RECT.end.y:
		flight_pos.y = PLAY_RECT.end.y
		velocity.y = -absf(velocity.y) * 0.42


func _field_point(x_ratio: float, y_ratio: float) -> Vector2:
	return PLAY_RECT.position + Vector2(PLAY_RECT.size.x * x_ratio, PLAY_RECT.size.y * y_ratio)


func _update_camera(delta: float) -> void:
	var look_ahead := velocity * CAMERA_LOOK_AHEAD_TIME
	look_ahead.x = clampf(look_ahead.x, -CAMERA_MAX_LOOK_AHEAD.x, CAMERA_MAX_LOOK_AHEAD.x)
	look_ahead.y = clampf(look_ahead.y, -CAMERA_MAX_LOOK_AHEAD.y, CAMERA_MAX_LOOK_AHEAD.y)
	var target_center := _clamp_camera_center(flight_pos + look_ahead)
	if delta <= 0.0:
		camera_center = target_center
	else:
		camera_center = _damp_vector2(camera_center, target_center, CAMERA_HALF_LIFE, delta)


func _clamp_camera_center(center: Vector2) -> Vector2:
	var half_view := VIEW_SIZE * 0.5
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
	return camera_center - VIEW_SIZE * 0.5


func _get_visible_world_rect() -> Rect2:
	return Rect2(_camera_origin(), VIEW_SIZE).intersection(PLAY_RECT)


func _damp_vector2(current: Vector2, target: Vector2, half_life: float, delta: float) -> Vector2:
	if half_life <= 0.0:
		return target
	var decay := pow(0.5, delta / half_life)
	return target + (current - target) * decay


func _update_secondary_motion(delta: float) -> void:
	var wind := -velocity * 0.018 - acceleration * 0.003
	wind.y += 46.0
	if brake_energy > 0.08:
		wind += facing * 760.0 * brake_energy
	for chain in secondary_chains:
		var points: Array = chain["points"]
		var prev_points: Array = chain["prev_points"]
		var root := _to_rider_world(chain["anchor"])
		points[0] = root
		prev_points[0] = root
		for i in range(1, points.size()):
			var current: Vector2 = points[i]
			var previous: Vector2 = prev_points[i]
			var velocity_part := (current - previous) * float(chain["damping"])
			prev_points[i] = current
			points[i] = current + velocity_part + wind * float(chain["wind_scale"]) * delta * delta
		for iteration in range(5):
			points[0] = root
			for i in range(1, points.size()):
				var parent: Vector2 = points[i - 1]
				var child: Vector2 = points[i]
				var offset := child - parent
				var distance := maxf(offset.length(), 0.001)
				points[i] = parent + offset / distance * float(chain["segment"])


func _update_trail(delta: float) -> void:
	for point in trail_points:
		point["age"] = float(point["age"]) + delta
	trail_points = trail_points.filter(func(point: Dictionary) -> bool: return float(point["age"]) <= TRAIL_LIFE)
	var sword_center := _get_sword_center()
	if trail_points.is_empty() or Vector2(trail_points[-1]["pos"]).distance_to(sword_center) >= TRAIL_MIN_DISTANCE:
		trail_points.append({
			"pos": sword_center,
			"age": 0.0,
			"speed": velocity.length(),
			"burst": maxf(burst_energy, turn_energy),
		})


func _draw() -> void:
	_draw_background()
	draw_set_transform(-_camera_origin(), 0.0, Vector2.ONE)
	_draw_world_guides()
	_draw_trail()
	_draw_wind_lines()
	_draw_secondary_chains(["hair_tail", "sash_high", "sash_low"])
	_draw_sword()
	_draw_rider()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_debug_overlay()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.73, 0.76, 0.76, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.08, 0.1, 0.12, 0.16))
	_draw_mountain_band(0.28, 0.48, Color(0.23, 0.26, 0.27, 0.18), 0.0)
	_draw_mountain_band(0.43, 0.62, Color(0.12, 0.15, 0.16, 0.28), 73.0)
	_draw_mountain_band(0.58, 0.78, Color(0.04, 0.055, 0.06, 0.36), 132.0)
	for i in range(9):
		var y := 120.0 + float(i) * 58.0 + sin(time * 0.16 + float(i)) * 7.0
		var x := fmod(time * (6.0 + float(i % 3) * 2.0) + float(i) * 173.0, VIEW_SIZE.x + 280.0) - 180.0
		_draw_cloud_wisp(Vector2(x, y), 130.0 + float(i % 4) * 32.0, Color(0.92, 0.94, 0.92, 0.15))


func _draw_world_guides() -> void:
	var visible_rect := _get_visible_world_rect()
	if not visible_rect.has_area():
		return
	var start_x: float = floorf(visible_rect.position.x / WORLD_GRID_STEP) * WORLD_GRID_STEP
	var x: float = start_x
	while x <= visible_rect.end.x + WORLD_GRID_STEP:
		var alpha := 0.13 if int(round(x / WORLD_GRID_STEP)) % 5 == 0 else 0.052
		draw_line(Vector2(x, visible_rect.position.y), Vector2(x, visible_rect.end.y), Color(0.64, 0.9, 0.92, alpha), 1.0)
		x += WORLD_GRID_STEP

	var start_y: float = floorf(visible_rect.position.y / WORLD_GRID_STEP) * WORLD_GRID_STEP
	var y: float = start_y
	while y <= visible_rect.end.y + WORLD_GRID_STEP:
		var alpha := 0.11 if int(round(y / WORLD_GRID_STEP)) % 3 == 0 else 0.048
		draw_line(Vector2(visible_rect.position.x, y), Vector2(visible_rect.end.x, y), Color(0.64, 0.9, 0.92, alpha), 1.0)
		y += WORLD_GRID_STEP

	draw_rect(PLAY_RECT, Color(1.0, 1.0, 1.0, 0.10), false, 1.4)


func _draw_mountain_band(top_ratio: float, bottom_ratio: float, color: Color, offset: float) -> void:
	var top := VIEW_SIZE.y * top_ratio
	var bottom := VIEW_SIZE.y * bottom_ratio
	var points := PackedVector2Array()
	points.append(Vector2(0.0, bottom))
	var count := 9
	for i in range(count + 1):
		var x := VIEW_SIZE.x * float(i) / float(count)
		var height := 86.0 + 96.0 * absf(sin(float(i) * 1.37 + offset * 0.01))
		var ridge := top + height * (0.45 + 0.55 * absf(sin(float(i) * 0.91 + offset)))
		ridge = clampf(ridge, top, bottom - 18.0)
		points.append(Vector2(x, ridge))
	points.append(Vector2(VIEW_SIZE.x, bottom))
	draw_colored_polygon(points, color)


func _draw_cloud_wisp(origin: Vector2, length: float, color: Color) -> void:
	var points := PackedVector2Array()
	var count := 12
	for i in range(count):
		var f := float(i) / float(count - 1)
		points.append(origin + Vector2(length * (f - 0.5), sin(f * TAU + time * 0.2) * 9.0))
	draw_polyline(points, color, 5.0, true)


func _draw_trail() -> void:
	if trail_points.size() < 2:
		return
	for i in range(1, trail_points.size()):
		var prev: Dictionary = trail_points[i - 1]
		var current: Dictionary = trail_points[i]
		var age := (float(prev["age"]) + float(current["age"])) * 0.5
		var life := clampf(1.0 - age / TRAIL_LIFE, 0.0, 1.0)
		var speed_factor := clampf(float(current["speed"]) / MAX_SPEED, 0.0, 1.0)
		var burst := float(current["burst"])
		var width := (10.0 + speed_factor * 34.0 + burst * 42.0) * life * visual_scale
		var glow_color := CYAN
		glow_color.a = (0.08 + burst * 0.12 + speed_factor * 0.1) * life * sword_glow_strength
		draw_line(prev["pos"], current["pos"], glow_color, width * 2.2, true)
		var core_color := CORE
		core_color.a = (0.12 + burst * 0.28) * life * sword_glow_strength
		draw_line(prev["pos"], current["pos"], core_color, maxf(width * 0.42, 2.0), true)
		var ink_color := Color(0.0, 0.012, 0.014, 0.22 * life)
		draw_line(prev["pos"] + Vector2(0.0, 6.0), current["pos"] + Vector2(0.0, 6.0), ink_color, width * 0.52, true)


func _draw_wind_lines() -> void:
	var speed_factor := clampf(velocity.length() / MAX_SPEED, 0.0, 1.0)
	if speed_factor < 0.18:
		return
	var right := Vector2(-facing.y, facing.x)
	for i in range(8):
		var lateral := (float(i) - 3.5) * 18.0
		var origin := flight_pos - facing * (90.0 + float(i % 3) * 24.0) + right * lateral
		var end := origin - facing * (54.0 + 82.0 * speed_factor)
		var color := Color(0.76, 1.0, 0.98, 0.045 * speed_factor)
		draw_line(origin, end, color, 1.0 + speed_factor * 2.0, true)


func _draw_secondary_chains(ids: Array) -> void:
	for chain in secondary_chains:
		if not ids.has(String(chain["id"])):
			continue
		var points: Array = chain["points"]
		var color: Color = chain["color"]
		var base_width := float(chain["width"]) * visual_scale
		for i in range(1, points.size()):
			var f := float(i) / float(points.size() - 1)
			var width := lerpf(base_width, maxf(base_width * 0.18, 0.8), f)
			var segment_color := color
			segment_color.a *= lerpf(1.0, 0.56, f)
			draw_line(points[i - 1], points[i], segment_color, width, true)


func _draw_sword() -> void:
	var center := _get_sword_center()
	var forward := facing
	var right := Vector2(-forward.y, forward.x)
	var length := 154.0 * visual_scale + burst_energy * 34.0
	var half_width := 6.0 * visual_scale
	var tip := center + forward * length * 0.55
	var tail := center - forward * length * 0.45
	var glow := CYAN
	glow.a = (0.14 + burst_energy * 0.24 + turn_energy * 0.12) * sword_glow_strength
	draw_line(tail - forward * 20.0, tip + forward * 22.0, glow, 28.0 * visual_scale + burst_energy * 18.0, true)
	var core := CORE
	core.a = 0.94
	draw_line(tail, tip, core, 5.5 * visual_scale, true)
	var blade := PackedVector2Array([
		tip,
		center + right * half_width,
		tail + right * half_width * 0.45,
		tail - right * half_width * 0.45,
		center - right * half_width,
	])
	draw_colored_polygon(blade, Color(0.82, 1.0, 0.98, 0.86))
	var dark_edge := Color(0.0, 0.06, 0.07, 0.38)
	draw_polyline(blade, dark_edge, 1.4, true)


func _draw_rider() -> void:
	var speed_factor := clampf(velocity.length() / MAX_SPEED, 0.0, 1.0)
	var crouch := burst_energy * 0.35 + speed_factor * 0.12
	var lean := speed_factor * 0.2 + burst_energy * 0.18 - brake_energy * 0.12
	var back_cloak := _rider_polygon([
		Vector2(-23.0 - lean * 2.0, -31.0),
		Vector2(-65.0 - lean * 6.0, -18.0 + brake_energy * 4.0),
		Vector2(-43.0 - lean * 3.0, 9.0),
		Vector2(-9.0, 20.0 + crouch * 2.0),
		Vector2(7.0 + lean * 2.0, -1.0 + crouch * 2.0),
		Vector2(3.0 + lean * 2.0, -24.0),
	], Color(0.0, 0.006, 0.008, 0.78))
	var rear_leg := _rider_polygon([
		Vector2(-4.0, 4.0 + crouch * 2.0),
		Vector2(-31.0 - lean * 2.0, 23.0),
		Vector2(-18.0, 30.0),
		Vector2(6.0, 13.0 + crouch * 2.0),
	], Color(0.012, 0.017, 0.02, 0.86))
	var torso := _rider_polygon([
		Vector2(-14.0 + lean * 2.0, -43.0 + crouch * 2.0),
		Vector2(9.0 + lean * 4.0, -42.0 + crouch * 2.0),
		Vector2(22.0 + lean * 4.0, -20.0 + crouch * 3.0),
		Vector2(13.0 + lean * 2.0, 7.0 + crouch * 3.0),
		Vector2(-4.0, 18.0 + crouch * 3.0),
		Vector2(-20.0 - lean * 1.0, 1.0 + crouch * 2.0),
		Vector2(-23.0 - lean * 1.0, -24.0 + crouch * 2.0),
	], INK)
	var front_sleeve := _rider_polygon([
		Vector2(1.0 + lean * 3.0, -32.0 + crouch * 2.0),
		Vector2(34.0 + lean * 5.0, -26.0 + crouch * 2.0),
		Vector2(57.0 + lean * 4.0, -13.0 + crouch * 2.0),
		Vector2(45.0 + lean * 2.0, -3.0 + crouch * 3.0),
		Vector2(9.0, -13.0 + crouch * 2.0),
	], Color(0.018, 0.024, 0.028, 1.0))
	var front_leg := _rider_polygon([
		Vector2(6.0 + lean * 2.0, 6.0 + crouch * 2.0),
		Vector2(35.0 + lean * 4.0, 19.0 + crouch * 2.0),
		Vector2(61.0 + lean * 2.0, 17.0),
		Vector2(42.0 + lean * 2.0, 26.0),
		Vector2(5.0, 22.0 + crouch * 2.0),
	], INK)
	var robe_tail := _rider_polygon([
		Vector2(-3.0, 9.0 + crouch * 2.0),
		Vector2(15.0 + lean * 2.0, 33.0 + crouch * 2.0),
		Vector2(26.0 + lean * 2.0, 27.0),
		Vector2(14.0, 8.0 + crouch * 2.0),
	], Color(0.006, 0.011, 0.014, 0.92))
	var head_center := Vector2(-2.0 + lean * 4.0, -62.0 + crouch * 1.0)
	var head := _rider_polygon([
		head_center + Vector2(-11.0, -2.0),
		head_center + Vector2(-7.0, -12.0),
		head_center + Vector2(3.0, -15.0),
		head_center + Vector2(12.0, -8.0),
		head_center + Vector2(13.0, 4.0),
		head_center + Vector2(4.0, 12.0),
		head_center + Vector2(-8.0, 8.0),
	], INK)
	draw_circle(_to_rider_world(head_center + Vector2(-9.0, -14.0)), 4.2 * visual_scale, INK)
	_draw_rider_polyline([
		head_center + Vector2(-9.0, -11.0),
		head_center + Vector2(-24.0 - lean * 3.0, -13.0),
		head_center + Vector2(-36.0 - lean * 4.0, -8.0 + brake_energy * 3.0),
	], INK, 4.2, false)
	var hand := _to_rider_world(Vector2(45.0 + lean * 5.0, -9.0 + crouch * 4.0))
	var rider_forward := _get_rider_forward()
	var rider_right := Vector2(-rider_forward.y, rider_forward.x)
	var sword_tip := hand + rider_forward * (78.0 * visual_scale) + rider_right * (8.0 * visual_scale)
	draw_line(hand - rider_forward * 8.0 * visual_scale, sword_tip, Color(0.0, 0.004, 0.006, 0.96), 3.0 * visual_scale, true)
	var sword_edge := CYAN
	sword_edge.a = 0.22 + burst_energy * 0.18
	draw_line(hand + rider_forward * 18.0 * visual_scale, sword_tip, sword_edge, 1.15 * visual_scale, true)
	_draw_rider_polyline([
		Vector2(-20.0, -22.0 + crouch * 2.0),
		Vector2(0.0 + lean * 2.0, -17.0 + crouch * 3.0),
		Vector2(20.0 + lean * 2.0, -20.0 + crouch * 3.0),
	], Color(0.36, 1.0, 0.94, 0.13), 1.7, false)
	_draw_rider_rim([back_cloak, rear_leg, torso, front_sleeve, front_leg, robe_tail, head], speed_factor)


func _draw_rider_rim(polygons: Array, speed_factor: float) -> void:
	var rim := CYAN
	rim.a = (0.08 + speed_factor * 0.08 + burst_energy * 0.1) * sword_glow_strength
	for polygon in polygons:
		draw_polyline(polygon, rim, 0.9 * visual_scale, true)


func _rider_polygon(local_points: Array, color: Color) -> PackedVector2Array:
	var world_points := PackedVector2Array()
	for local_point in local_points:
		world_points.append(_to_rider_world(local_point))
	draw_colored_polygon(world_points, color)
	return world_points


func _draw_rider_polyline(local_points: Array, color: Color, width: float, closed: bool) -> void:
	var world_points := PackedVector2Array()
	for local_point in local_points:
		world_points.append(_to_rider_world(local_point))
	draw_polyline(world_points, color, width * visual_scale, closed)


func _local_polygon(local_points: Array, color: Color) -> PackedVector2Array:
	var world_points := PackedVector2Array()
	for local_point in local_points:
		world_points.append(_to_world(local_point))
	draw_colored_polygon(world_points, color)
	return world_points


func _draw_local_polyline(local_points: Array, color: Color, width: float, closed: bool) -> void:
	var world_points := PackedVector2Array()
	for local_point in local_points:
		world_points.append(_to_world(local_point))
	draw_polyline(world_points, color, width * visual_scale, closed)


func _draw_debug_overlay() -> void:
	var mode_text := "AUTO DEMO" if auto_demo else "MANUAL"
	var hint := "%s  |  field %.0fx%.0f  |  T切换演示  R重置  WASD飞行  Space冲刺  右键急停" % [mode_text, FLIGHT_TEST_HORIZONTAL_SCALE, FLIGHT_TEST_VERTICAL_SCALE]
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 32.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16.0, Color(0.9, 0.95, 0.94, 0.74))
	var speed := "speed %.0f  turn %.2f  brake %.2f  pos %.0f,%.0f" % [velocity.length(), turn_energy, brake_energy, flight_pos.x, flight_pos.y]
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 56.0), speed, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.7, 0.82, 0.82, 0.62))


func _get_sword_center() -> Vector2:
	var right := Vector2(-facing.y, facing.x)
	return flight_pos + right * (24.0 - burst_energy * 7.0)


func _get_rider_forward() -> Vector2:
	var sign_x := 1.0
	if velocity.x < -24.0:
		sign_x = -1.0
	elif velocity.x <= 24.0 and facing.x < 0.0:
		sign_x = -1.0
	var raw_angle := facing.angle()
	if sign_x < 0.0:
		var relative := wrapf(raw_angle - PI, -PI, PI)
		var clamped := clampf(relative, -0.55, 0.55)
		return Vector2(cos(PI + clamped), sin(PI + clamped)).normalized()
	var clamped_angle := clampf(raw_angle, -0.55, 0.55)
	return Vector2(cos(clamped_angle), sin(clamped_angle)).normalized()


func _to_rider_world(local_point: Vector2) -> Vector2:
	var rider_forward := _get_rider_forward()
	var rider_right := Vector2(-rider_forward.y, rider_forward.x)
	return flight_pos + rider_forward * local_point.x * visual_scale + rider_right * local_point.y * visual_scale


func _to_world(local_point: Vector2) -> Vector2:
	var right := Vector2(-facing.y, facing.x)
	return flight_pos + facing * local_point.x * visual_scale + right * local_point.y * visual_scale
