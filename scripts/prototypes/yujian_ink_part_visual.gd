extends Node2D
class_name YujianInkPartVisual

const SPEED_REFERENCE := 2280.0
const CRUISE_REFERENCE := 1170.0
const OUTLINE := Color(0.004, 0.005, 0.006, 0.96)
const INK_CORE := Color(0.018, 0.020, 0.023, 0.98)
const INK_MID := Color(0.070, 0.074, 0.074, 0.92)
const INK_WASH := Color(0.34, 0.35, 0.33, 0.30)
const INK_LIGHT := Color(0.74, 0.76, 0.70, 0.58)
const INK_RIM := Color(0.88, 0.90, 0.84, 0.48)
const HAIR_CORE := Color(0.002, 0.003, 0.004, 0.98)
const HAIR_RIM := Color(0.80, 0.82, 0.78, 0.36)
const SWORD_GLOW := Color(0.58, 0.96, 1.00, 0.38)
const SWORD_CORE := Color(0.94, 1.00, 0.98, 0.92)
const QI_LINE := Color(0.74, 0.98, 0.94, 0.36)
const SASH_CORE := Color(0.012, 0.014, 0.016, 0.92)
const SASH_RIM := Color(0.82, 0.83, 0.78, 0.36)

var _direction_index := 0
var _heading := Vector2.RIGHT
var _velocity := Vector2.ZERO
var _boost := 0.0
var _turn := 0.0
var _carve := 0.0
var _throttle := 0.0
var _time := 0.0
var _wind_follow := 0.0
var _turn_follow := 0.0
var _carve_follow := 0.0
var _facing_sign := 1.0


func set_flight_pose(
		p_direction_index: int,
		p_heading: Vector2,
		p_velocity: Vector2,
		p_boost: float,
		p_turn: float,
		p_carve: float,
		p_throttle: float,
		p_delta: float
) -> void:
	_direction_index = p_direction_index
	_heading = p_heading.normalized() if p_heading.length_squared() > 0.0001 else Vector2.RIGHT
	_velocity = p_velocity
	_boost = clampf(p_boost, 0.0, 1.0)
	_turn = clampf(p_turn, 0.0, 1.0)
	_carve = clampf(p_carve, 0.0, 1.0)
	_throttle = clampf(p_throttle, 0.0, 1.0)
	var speed_ratio := clampf(_velocity.length() / SPEED_REFERENCE, 0.0, 1.35)
	var wind_target := clampf(speed_ratio + _boost * 0.58 + _carve * 0.34, 0.0, 1.55)
	_wind_follow = _damp_float(_wind_follow, wind_target, 0.12, p_delta)
	_turn_follow = _damp_float(_turn_follow, maxf(_turn, _carve * 0.76), 0.10, p_delta)
	_carve_follow = _damp_float(_carve_follow, _carve, 0.09, p_delta)
	if absf(_heading.x) > 0.18:
		_facing_sign = signf(_heading.x)
	_time += maxf(p_delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var h := _safe_heading()
	var fast := _fast_weight()
	var wind := _wind_follow
	var turn := _turn_follow
	var body := _build_body_points(h, fast, wind, turn)
	_draw_sword_and_contact(body, h, fast, wind, turn)
	_draw_back_hair(body, h, fast, wind, turn)
	_draw_back_robe(body, h, fast, wind, turn)
	_draw_far_sleeve(body, h, fast, wind)
	_draw_far_leg(body, h, fast)
	_draw_torso_and_front_robe(body, h, fast)
	_draw_near_leg(body, h, fast)
	_draw_near_sleeve(body, h, fast, wind)
	_draw_sash_streamers(body, h, fast, wind, turn)
	_draw_head_and_hair(body, h, fast, wind)
	_draw_front_qi_lines(body, h, fast, wind, turn)


func _safe_heading() -> Vector2:
	if _heading.length_squared() > 0.0001:
		return _heading.normalized()
	if _velocity.length_squared() > 0.0001:
		return _velocity.normalized()
	return Vector2.RIGHT


func _fast_weight() -> float:
	var speed_ratio := clampf(_velocity.length() / SPEED_REFERENCE, 0.0, 1.0)
	return smoothstep(0.18, 0.88, maxf(speed_ratio, _boost * 0.88 + _throttle * 0.20))


func _build_body_points(h: Vector2, fast: float, wind: float, turn: float) -> Dictionary:
	var flow := -h
	var side := Vector2(_facing_sign, 0.0)
	var opposite_side := -side
	var foot := Vector2(0.0, lerpf(72.0, 62.0, fast)) - h * lerpf(0.0, 9.0, fast)
	var hip := foot + Vector2(0.0, lerpf(-76.0, -64.0, fast)) - h * lerpf(8.0, 38.0, fast)
	var shoulder := hip + Vector2(0.0, lerpf(-50.0, -34.0, fast)) + h * lerpf(8.0, 58.0, fast)
	var head := shoulder + Vector2(0.0, lerpf(-28.0, -23.0, fast)) + h * lerpf(4.0, 24.0, fast)
	var chest := shoulder.lerp(hip, 0.34)
	var waist := shoulder.lerp(hip, 0.72)
	var shoulder_width := lerpf(13.0, 10.0, fast)
	var hip_width := lerpf(11.0, 8.5, fast)
	var sleeve_drop := Vector2(0.0, 34.0 + 5.0 * wind)
	var near_wrist := shoulder + h * lerpf(38.0, -86.0, fast) + side * lerpf(18.0, 26.0, fast) + sleeve_drop
	var far_wrist := shoulder + h * lerpf(14.0, -96.0, fast) + opposite_side * lerpf(10.0, 20.0, fast) + sleeve_drop * 0.92
	var near_ankle := foot + h * lerpf(19.0, 48.0, fast) + side * lerpf(8.0, 17.0, fast) + Vector2(0.0, lerpf(0.0, 12.0, fast))
	var far_ankle := foot - h * lerpf(18.0, 88.0, fast) + opposite_side * lerpf(7.0, 12.0, fast) + Vector2(0.0, lerpf(2.0, 9.0, fast))
	var turn_push := side * turn * 8.0 * signf(h.x if absf(h.x) > 0.08 else _facing_sign)
	return {
		"h": h,
		"flow": flow,
		"side": side,
		"opposite_side": opposite_side,
		"foot": foot,
		"hip": hip + turn_push * 0.18,
		"shoulder": shoulder + turn_push * 0.36,
		"head": head + turn_push * 0.45,
		"chest": chest,
		"waist": waist,
		"shoulder_near": shoulder + side * shoulder_width,
		"shoulder_far": shoulder + opposite_side * shoulder_width * 0.82,
		"hip_near": hip + side * hip_width,
		"hip_far": hip + opposite_side * hip_width * 0.82,
		"near_wrist": near_wrist,
		"far_wrist": far_wrist,
		"near_ankle": near_ankle,
		"far_ankle": far_ankle,
	}


func _draw_sword_and_contact(body: Dictionary, h: Vector2, fast: float, wind: float, turn: float) -> void:
	var foot: Vector2 = body["foot"]
	var sword_center := foot + Vector2(0.0, 14.0)
	var back := sword_center - h * (78.0 + 28.0 * fast)
	var front := sword_center + h * (84.0 + 36.0 * fast)
	var side := h.rotated(PI * 0.5)
	var glow_alpha := 0.14 + 0.17 * fast + 0.08 * _boost
	draw_line(back - h * (34.0 + wind * 16.0), front + h * 22.0, Color(SWORD_GLOW.r, SWORD_GLOW.g, SWORD_GLOW.b, glow_alpha * 0.45), 26.0 + 14.0 * fast, true)
	draw_line(back, front, Color(0.04, 0.12, 0.14, 0.88), 12.0, true)
	draw_line(back, front, SWORD_GLOW, 6.2 + 2.8 * fast, true)
	draw_line(back + h * 18.0, front + h * 18.0, SWORD_CORE, 2.4 + 2.0 * fast, true)
	var tip := PackedVector2Array([
		front + h * 24.0,
		front - h * 4.0 + side * (5.0 + fast * 3.0),
		front - h * 4.0 - side * (5.0 + fast * 3.0),
	])
	_draw_ink_polygon(tip, SWORD_CORE, Color(0.18, 0.36, 0.38, 0.86), 1.4)
	draw_arc(foot + Vector2(0.0, 8.0), 17.0 + fast * 8.0, 0.12, PI - 0.12, 18, Color(QI_LINE.r, QI_LINE.g, QI_LINE.b, 0.20 + 0.14 * fast), 2.1, true)
	draw_line(foot - h * (18.0 + wind * 16.0) + Vector2(0.0, 12.0), foot + h * 30.0 + Vector2(0.0, 12.0), Color(QI_LINE.r, QI_LINE.g, QI_LINE.b, 0.18 + 0.12 * turn), 1.4 + fast, true)


func _draw_back_hair(body: Dictionary, h: Vector2, fast: float, wind: float, turn: float) -> void:
	var head: Vector2 = body["head"]
	var flow: Vector2 = body["flow"]
	var side: Vector2 = body["side"]
	var base := head - h * 8.0 + Vector2(0.0, -2.0)
	var length := 58.0 + 72.0 * fast + 22.0 * wind
	for i in range(4):
		var t := float(i) / 3.0
		var side_offset := side * lerpf(-8.0, 13.0, t)
		var lift := Vector2(0.0, lerpf(-9.0, 12.0, t))
		var start := base + side_offset * 0.42 + lift * 0.2
		var control := start + flow * (length * lerpf(0.34, 0.50, t)) + side * sin(_time * 2.0 + t * 2.7) * (5.0 + turn * 5.0) + lift
		var end := start + flow * length * lerpf(0.72, 1.06, t) + lift * 2.0 + side * sin(_time * 2.6 + t * 4.0) * (7.0 + wind * 4.0)
		var points := _quadratic_points(start, control, end, 9)
		_draw_tapered_polyline(points, OUTLINE, 8.5 - t * 2.0, 2.0, true)
		_draw_tapered_polyline(points, HAIR_CORE, 5.6 - t * 1.3, 1.0, true)
		_draw_tapered_polyline(points, HAIR_RIM, 1.2, 0.3, true)


func _draw_back_robe(body: Dictionary, h: Vector2, fast: float, wind: float, turn: float) -> void:
	var flow: Vector2 = body["flow"]
	var side: Vector2 = body["side"]
	var shoulder: Vector2 = body["shoulder"]
	var hip: Vector2 = body["hip"]
	var waist: Vector2 = body["waist"]
	var tail_length := 76.0 + 82.0 * fast + 28.0 * wind
	var flare := 18.0 + 25.0 * fast + 12.0 * turn
	var tail_a := waist + flow * tail_length + Vector2(0.0, 38.0 + 12.0 * fast) + side * flare
	var tail_b := hip + flow * (tail_length * 1.16) + Vector2(0.0, 56.0 + 8.0 * wind) - side * (flare * 0.82)
	var tail_mid := hip + flow * (tail_length * 0.92) + Vector2(0.0, 44.0 + 7.0 * fast)
	var robe_front := PackedVector2Array([
		shoulder - h * 2.0 - side * 8.0,
		waist + side * 11.0,
		tail_a,
		tail_mid,
	])
	var robe_back := PackedVector2Array([
		shoulder - h * 2.0 - side * 10.0,
		tail_mid,
		tail_b,
		hip - side * 11.0,
	])
	_draw_ink_polygon(robe_back, Color(0.013, 0.015, 0.018, 0.96), OUTLINE, 4.0)
	_draw_ink_polygon(robe_front, INK_CORE, OUTLINE, 3.2)
	_draw_ink_wash(robe_front, Color(0.36, 0.37, 0.35, 0.22), 0.58)
	_draw_ink_wash(robe_back, Color(0.23, 0.24, 0.23, 0.18), 0.56)
	draw_line(shoulder - side * 9.0, tail_a, INK_RIM, 2.0, true)
	draw_line(waist - h * 2.0, tail_b.lerp(tail_a, 0.34), INK_WASH, 3.2, true)
	draw_line(hip + flow * 15.0, tail_b, Color(0.05, 0.055, 0.058, 0.62), 4.4, true)


func _draw_far_sleeve(body: Dictionary, h: Vector2, fast: float, wind: float) -> void:
	_draw_sleeve_panel(body["shoulder_far"], body["far_wrist"], h, float(body["opposite_side"].x), fast, wind, 0.62)


func _draw_near_sleeve(body: Dictionary, h: Vector2, fast: float, wind: float) -> void:
	_draw_sleeve_panel(body["shoulder_near"], body["near_wrist"], h, float(body["side"].x), fast, wind, 0.94)


func _draw_sleeve_panel(shoulder: Vector2, wrist: Vector2, h: Vector2, side_sign: float, fast: float, wind: float, alpha: float) -> void:
	var side := Vector2(side_sign, 0.0)
	var flow := -h
	var width := 14.0 + 13.0 * (1.0 - fast * 0.24)
	var drag := flow * (16.0 + 34.0 * fast + 10.0 * wind)
	var sleeve := PackedVector2Array([
		shoulder - side * 4.0,
		shoulder + side * (8.0 + width * 0.24),
		wrist + side * width + drag * 0.18 + Vector2(0.0, 4.0),
		wrist - side * (width * 0.76) + drag * 0.34 + Vector2(0.0, 9.0),
	])
	var fill := Color(INK_MID.r, INK_MID.g, INK_MID.b, INK_MID.a * alpha)
	_draw_ink_polygon(sleeve, fill, OUTLINE, 3.0)
	draw_line(shoulder + side * 2.0, wrist + drag * 0.18, Color(INK_RIM.r, INK_RIM.g, INK_RIM.b, INK_RIM.a * alpha), 1.8, true)
	draw_line(wrist - side * width * 0.45, wrist + side * width * 0.72, Color(INK_LIGHT.r, INK_LIGHT.g, INK_LIGHT.b, 0.30 * alpha), 2.3, true)


func _draw_far_leg(body: Dictionary, h: Vector2, fast: float) -> void:
	_draw_leg(body["hip_far"], body["far_ankle"], h, 0.54 + 0.14 * fast)


func _draw_near_leg(body: Dictionary, h: Vector2, fast: float) -> void:
	_draw_leg(body["hip_near"], body["near_ankle"], h, 0.88)


func _draw_leg(hip: Vector2, ankle: Vector2, h: Vector2, alpha: float) -> void:
	var knee := hip.lerp(ankle, 0.54) + Vector2(0.0, -4.0)
	draw_line(hip, knee, OUTLINE, 12.0, true)
	draw_line(knee, ankle, OUTLINE, 10.0, true)
	draw_line(hip, knee, Color(0.026, 0.028, 0.030, alpha), 7.0, true)
	draw_line(knee, ankle, Color(0.010, 0.011, 0.014, alpha), 6.2, true)
	var boot := PackedVector2Array([
		ankle + h * 9.0 + Vector2(0.0, 1.0),
		ankle - h * 5.0 + Vector2(0.0, -3.0),
		ankle - h * 7.0 + Vector2(0.0, 5.0),
	])
	_draw_ink_polygon(boot, Color(0.006, 0.007, 0.009, alpha), OUTLINE, 1.4)


func _draw_torso_and_front_robe(body: Dictionary, h: Vector2, fast: float) -> void:
	var side: Vector2 = body["side"]
	var shoulder: Vector2 = body["shoulder"]
	var hip: Vector2 = body["hip"]
	var waist: Vector2 = body["waist"]
	var torso := PackedVector2Array([
		body["shoulder_near"],
		body["shoulder_far"],
		body["hip_far"],
		body["hip_near"],
	])
	_draw_ink_polygon(torso, INK_CORE, OUTLINE, 3.2)
	var front_panel := PackedVector2Array([
		waist + side * 7.0,
		waist - side * 8.0,
		hip - side * 8.0 + Vector2(0.0, 35.0 + 8.0 * fast) - h * (6.0 + 12.0 * fast),
		hip + side * 10.0 + Vector2(0.0, 30.0 + 10.0 * fast) - h * (3.0 + 8.0 * fast),
	])
	_draw_ink_polygon(front_panel, Color(0.024, 0.027, 0.030, 0.92), OUTLINE, 2.4)
	draw_line(shoulder - side * 6.0, waist + side * 2.0, INK_LIGHT, 2.4, true)
	draw_line(shoulder + side * 6.0, waist - side * 1.0, Color(INK_RIM.r, INK_RIM.g, INK_RIM.b, 0.42), 1.7, true)
	draw_line(waist - side * 13.0, waist + side * 15.0, OUTLINE, 7.0, true)
	draw_line(waist - side * 12.0, waist + side * 14.0, SASH_CORE, 4.2, true)
	draw_circle(waist + h * 2.0, 3.8, OUTLINE)
	draw_circle(waist + h * 2.0, 2.2, Color(0.78, 0.96, 0.92, 0.70))


func _draw_sash_streamers(body: Dictionary, h: Vector2, fast: float, wind: float, turn: float) -> void:
	var waist: Vector2 = body["waist"]
	var flow := -h
	var side: Vector2 = body["side"]
	for i in range(2):
		var lane := -1.0 if i == 0 else 1.0
		var start := waist + side * lane * (6.0 + i * 3.0)
		var control := start + flow * (34.0 + 36.0 * fast) + side * lane * (10.0 + turn * 7.0) + Vector2(0.0, 8.0 + i * 6.0)
		var end := start + flow * (70.0 + 70.0 * fast + wind * 20.0) + side * lane * (14.0 + sin(_time * 2.4 + i) * 5.0) + Vector2(0.0, 18.0 + i * 9.0)
		var points := _quadratic_points(start, control, end, 8)
		_draw_tapered_polyline(points, OUTLINE, 6.0, 1.2, true)
		_draw_tapered_polyline(points, SASH_CORE, 3.8, 0.8, true)
		_draw_tapered_polyline(points, SASH_RIM, 1.2, 0.2, true)


func _draw_head_and_hair(body: Dictionary, h: Vector2, fast: float, wind: float) -> void:
	var head: Vector2 = body["head"]
	var side: Vector2 = body["side"]
	var radius := lerpf(15.0, 13.2, fast)
	draw_circle(head, radius + 2.6, OUTLINE)
	draw_circle(head, radius, Color(0.040, 0.042, 0.043, 0.98))
	draw_line(head - side * 7.0 - h * 1.5, head + side * 4.0 + h * 3.0, INK_RIM, 1.6, true)
	draw_circle(head + h * 8.0 + Vector2(0.0, 1.5), 1.8, Color(0.008, 0.009, 0.010, 0.92))
	var bun := head - h * 9.0 + Vector2(0.0, -11.0)
	draw_circle(bun, 7.0, OUTLINE)
	draw_circle(bun, 5.0, HAIR_CORE)
	var top_ribbon := _quadratic_points(bun + Vector2(0.0, -3.0), bun - h * (24.0 + 10.0 * fast) - side * 4.0 + Vector2(0.0, -7.0), bun - h * (46.0 + 28.0 * fast + wind * 7.0) + side * 7.0 + Vector2(0.0, -6.0), 7)
	_draw_tapered_polyline(top_ribbon, OUTLINE, 4.2, 0.8, true)
	_draw_tapered_polyline(top_ribbon, HAIR_RIM, 1.7, 0.3, true)


func _draw_front_qi_lines(body: Dictionary, h: Vector2, fast: float, wind: float, turn: float) -> void:
	if fast < 0.10 and turn < 0.10:
		return
	var foot: Vector2 = body["foot"]
	var flow := -h
	var side: Vector2 = body["side"]
	var amount := 2 + int(round(fast * 3.0 + turn * 2.0))
	for i in range(amount):
		var lane := float(i) - float(amount - 1) * 0.5
		var start := foot + flow * (24.0 + i * 9.0) + side * lane * 9.0 + Vector2(0.0, 26.0 + i * 2.0)
		var end := start + flow * (38.0 + wind * 26.0) + side * sin(_time * 3.1 + i) * 8.0
		draw_line(start, end, Color(QI_LINE.r, QI_LINE.g, QI_LINE.b, (0.12 + fast * 0.12 + turn * 0.08) * (1.0 - float(i) * 0.10)), 1.2 + fast * 1.2, true)


func _draw_ink_polygon(points: PackedVector2Array, fill: Color, rim: Color, outline_amount: float) -> void:
	_draw_triangle_fan(_expand_polygon(points, outline_amount), OUTLINE)
	_draw_triangle_fan(points, fill)
	var closed := PackedVector2Array(points)
	if points.size() > 0:
		closed.append(points[0])
		draw_polyline(closed, rim, 1.3, true)


func _draw_ink_wash(points: PackedVector2Array, color: Color, scale_amount: float) -> void:
	var center := _polygon_center(points)
	var wash := PackedVector2Array()
	for point in points:
		wash.append(center.lerp(point, scale_amount))
	_draw_triangle_fan(wash, color)


func _quadratic_points(a: Vector2, b: Vector2, c: Vector2, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_steps := maxi(steps, 2)
	for i in range(safe_steps + 1):
		var t := float(i) / float(safe_steps)
		var inv := 1.0 - t
		points.append(a * inv * inv + b * 2.0 * inv * t + c * t * t)
	return points


func _draw_tapered_polyline(points: PackedVector2Array, color: Color, start_width: float, end_width: float, antialiased := true) -> void:
	if points.size() < 2:
		return
	var segment_count := points.size() - 1
	for i in range(segment_count):
		var t := float(i) / maxf(float(segment_count - 1), 1.0)
		var width := lerpf(start_width, end_width, t)
		draw_line(points[i], points[i + 1], color, width, antialiased)


func _draw_triangle_fan(points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	var center := _polygon_center(points)
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		if absf((a - center).cross(b - center)) < 0.001:
			continue
		draw_colored_polygon(PackedVector2Array([center, a, b]), color)


func _expand_polygon(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var center := _polygon_center(points)
	var out := PackedVector2Array()
	for point in points:
		var dir := point - center
		out.append(point + dir.normalized() * amount if dir.length_squared() > 0.0001 else point)
	return out


func _polygon_center(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var center := Vector2.ZERO
	for point in points:
		center += point
	return center / float(points.size())


func _damp_float(current: float, target: float, half_life: float, delta: float) -> float:
	if delta <= 0.0 or half_life <= 0.0:
		return target
	var decay := pow(0.5, delta / half_life)
	return target + (current - target) * decay
