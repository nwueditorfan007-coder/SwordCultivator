extends RefCounted
class_name SwordArrayBandRenderer

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayController = preload("res://scripts/system/sword_array_controller.gd")


static func draw_preview(
	main: Node2D,
	player_pos: Vector2,
	geometry: Dictionary,
	state_source,
	preview_alpha: float,
	formation_ratio: float
) -> void:
	match String(geometry.get("preview_type", SwordArrayConfig.MODE_RING)):
		SwordArrayConfig.MODE_RING:
			_draw_ring_preview(main, player_pos, geometry, 1.0, preview_alpha, formation_ratio)
		SwordArrayConfig.MODE_FAN:
			_draw_fan_preview(main, player_pos, geometry, 1.0, preview_alpha, formation_ratio)
		SwordArrayConfig.MODE_PIERCE:
			_draw_pierce_preview(main, geometry, 1.0, preview_alpha, formation_ratio)
		"crescent":
			_draw_crescent_preview(main, geometry, state_source, preview_alpha, formation_ratio)


static func _draw_ring_preview(main: Node2D, player_pos: Vector2, geometry: Dictionary, weight: float, preview_alpha: float, formation_ratio: float) -> void:
	var ring_color: Color = SwordArrayController.get_accent_color(SwordArrayConfig.MODE_RING)
	ring_color.a = preview_alpha * weight
	var ring_outline := Color(ring_color.r, ring_color.g, ring_color.b, preview_alpha * weight * 0.88)
	main.draw_arc(player_pos, float(geometry.get("radius", 0.0)), 0.0, TAU, 40, ring_outline, 3.0)
	var ring_soft_color: Color = SwordArrayController.get_soft_accent_color(SwordArrayConfig.MODE_RING)
	ring_soft_color.a = (0.14 + formation_ratio * 0.1) * weight
	main.draw_arc(player_pos, float(geometry.get("outer_radius", 0.0)), 0.0, TAU, 40, ring_soft_color, 1.5)
	var spoke_count: int = maxi(main._get_current_array_sword_capacity(), 1)
	var spoke_index: int = 0
	while spoke_index < spoke_count:
		var spoke_angle: float = (TAU / float(spoke_count)) * float(spoke_index)
		main.draw_line(
			player_pos + Vector2.RIGHT.rotated(spoke_angle) * max(float(geometry.get("radius", 0.0)) - 10.0, 8.0),
			player_pos + Vector2.RIGHT.rotated(spoke_angle) * float(geometry.get("outer_radius", 0.0)),
			ring_color,
			1.2
		)
		spoke_index += 1


static func _draw_fan_preview(main: Node2D, player_pos: Vector2, geometry: Dictionary, weight: float, preview_alpha: float, formation_ratio: float) -> void:
	var fan_color_source = geometry.get("preview_state", SwordArrayConfig.MODE_FAN)
	var fan_color: Color = SwordArrayController.get_accent_color(fan_color_source)
	fan_color.a = (preview_alpha + 0.08) * weight
	var fan_edge_color := Color(fan_color.r, fan_color.g, fan_color.b, 0.24 * weight)
	var fan_soft_color: Color = SwordArrayController.get_soft_accent_color(fan_color_source)
	fan_soft_color.a = (0.16 + formation_ratio * 0.14) * weight
	if _draw_section_profile_preview(main, geometry, weight, formation_ratio, fan_color, fan_edge_color, fan_soft_color):
		return
	_draw_arc_band_preview(main, geometry, weight, formation_ratio, fan_color, fan_edge_color, fan_soft_color)


static func _draw_classic_fan_preview(
	main: Node2D,
	player_pos: Vector2,
	geometry: Dictionary,
	weight: float,
	formation_ratio: float,
	fan_color: Color,
	fan_edge_color: Color,
	fan_soft_color: Color
) -> void:
	var fan_mid_radius: float = lerpf(float(geometry.get("inner_radius", 0.0)), float(geometry.get("outer_radius", 0.0)), 0.56)
	var fan_mid_arc: float = float(geometry.get("arc", 0.0)) * 0.78
	var fan_fill: PackedVector2Array = _build_fan_band_polygon(
		player_pos,
		float(geometry.get("angle", 0.0)),
		float(geometry.get("arc", 0.0)),
		float(geometry.get("inner_radius", 0.0)),
		float(geometry.get("outer_radius", 0.0)),
		16
	)
	_try_draw_colored_polygon(
		main,
		fan_fill,
		Color(fan_soft_color.r, fan_soft_color.g, fan_soft_color.b, (0.08 + formation_ratio * 0.08) * weight)
	)
	main.draw_arc(player_pos, float(geometry.get("outer_radius", 0.0)), float(geometry.get("angle", 0.0)) - float(geometry.get("arc", 0.0)) * 0.5, float(geometry.get("angle", 0.0)) + float(geometry.get("arc", 0.0)) * 0.5, 32, fan_color, 3.0)
	main.draw_arc(player_pos, fan_mid_radius, float(geometry.get("angle", 0.0)) - fan_mid_arc * 0.5, float(geometry.get("angle", 0.0)) + fan_mid_arc * 0.5, 24, fan_soft_color, 1.6)
	main.draw_arc(player_pos, float(geometry.get("inner_radius", 0.0)), float(geometry.get("angle", 0.0)) - fan_mid_arc * 0.32, float(geometry.get("angle", 0.0)) + fan_mid_arc * 0.32, 18, fan_edge_color, 1.1)
	main.draw_line(
		player_pos + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) - float(geometry.get("arc", 0.0)) * 0.5) * float(geometry.get("inner_radius", 0.0)),
		player_pos + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) - float(geometry.get("arc", 0.0)) * 0.5) * float(geometry.get("outer_radius", 0.0)),
		fan_edge_color,
		1.2
	)
	main.draw_line(
		player_pos + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) + float(geometry.get("arc", 0.0)) * 0.5) * float(geometry.get("inner_radius", 0.0)),
		player_pos + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) + float(geometry.get("arc", 0.0)) * 0.5) * float(geometry.get("outer_radius", 0.0)),
		fan_edge_color,
		1.2
	)
	main.draw_line(
		player_pos + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0))) * float(geometry.get("inner_radius", 0.0)),
		player_pos + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0))) * float(geometry.get("outer_radius", 0.0)),
		fan_soft_color,
		1.0
	)


static func _draw_pierce_preview(main: Node2D, geometry: Dictionary, weight: float, preview_alpha: float, formation_ratio: float) -> void:
	var start_pos: Vector2 = main._to_screen(geometry.get("start", Vector2.ZERO))
	var end_pos: Vector2 = main._to_screen(geometry.get("end", Vector2.ZERO))
	var tip_pos: Vector2 = main._to_screen(geometry.get("tip", Vector2.ZERO))
	var line_dir: Vector2 = (end_pos - start_pos).normalized()
	var side_offset: Vector2 = line_dir.rotated(PI * 0.5) * float(geometry.get("half_width", 0.0))
	var pierce_color: Color = SwordArrayController.get_accent_color(SwordArrayConfig.MODE_PIERCE)
	pierce_color.a = (preview_alpha + 0.1) * weight
	var pierce_soft_color: Color = SwordArrayController.get_soft_accent_color(SwordArrayConfig.MODE_PIERCE)
	pierce_soft_color.a = (0.18 + formation_ratio * 0.08) * weight
	var wedge_back: Vector2 = start_pos + line_dir * float(geometry.get("wedge_length", 0.0))
	var wedge_side: Vector2 = line_dir.rotated(PI * 0.5) * float(geometry.get("wedge_width", 0.0))
	_try_draw_colored_polygon(
		main,
		PackedVector2Array([start_pos + wedge_side, start_pos - wedge_side, wedge_back]),
		Color(pierce_soft_color.r, pierce_soft_color.g, pierce_soft_color.b, (0.12 + formation_ratio * 0.1) * weight)
	)
	main.draw_line(start_pos, end_pos, pierce_color, 3.2 + formation_ratio * 1.4)
	main.draw_line(start_pos + side_offset, end_pos + side_offset * 0.35, pierce_soft_color, 1.0)
	main.draw_line(start_pos - side_offset, end_pos - side_offset * 0.35, pierce_soft_color, 1.0)
	main.draw_line(end_pos, tip_pos, Color(1.0, 1.0, 1.0, (0.34 + formation_ratio * 0.18) * weight), 2.2)
	main.draw_circle(tip_pos, float(geometry.get("tip_radius", 0.0)), Color(1.0, 1.0, 1.0, (0.28 + formation_ratio * 0.22) * weight))


static func _draw_crescent_preview(main: Node2D, geometry: Dictionary, state_source, preview_alpha: float, formation_ratio: float) -> void:
	var accent_color: Color = SwordArrayController.get_accent_color(state_source)
	accent_color.a = preview_alpha + 0.06
	var soft_color: Color = SwordArrayController.get_soft_accent_color(state_source)
	soft_color.a = 0.14 + formation_ratio * 0.12
	var edge_color := Color(accent_color.r, accent_color.g, accent_color.b, 0.22)
	if _draw_section_profile_preview(main, geometry, 1.0, formation_ratio, accent_color, edge_color, soft_color):
		return
	_draw_arc_band_preview(main, geometry, 1.0, formation_ratio, accent_color, edge_color, soft_color)


static func _draw_arc_band_preview(
	main: Node2D,
	geometry: Dictionary,
	weight: float,
	formation_ratio: float,
	line_color: Color,
	edge_color: Color,
	soft_color: Color
) -> void:
	var center: Vector2 = main._to_screen(geometry.get("center", Vector2.ZERO))
	var outer_arc: float = float(geometry.get("arc", 0.0))
	var inner_arc: float = float(geometry.get("inner_arc", outer_arc))
	var inner_radius: float = float(geometry.get("inner_radius", 0.0))
	var outer_radius: float = float(geometry.get("outer_radius", 0.0))
	var fill: PackedVector2Array = _build_crescent_polygon(
		center,
		float(geometry.get("angle", 0.0)),
		outer_arc,
		inner_arc,
		inner_radius,
		outer_radius,
		18
	)
	_try_draw_colored_polygon(main, fill, Color(soft_color.r, soft_color.g, soft_color.b, (0.08 + formation_ratio * 0.08) * weight))
	main.draw_arc(
		center,
		outer_radius,
		float(geometry.get("angle", 0.0)) - outer_arc * 0.5,
		float(geometry.get("angle", 0.0)) + outer_arc * 0.5,
		36,
		line_color,
		3.0
	)
	main.draw_arc(
		center,
		inner_radius,
		float(geometry.get("angle", 0.0)) - inner_arc * 0.5,
		float(geometry.get("angle", 0.0)) + inner_arc * 0.5,
		28,
		soft_color,
		1.8
	)
	var left_outer: Vector2 = center + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) - outer_arc * 0.5) * outer_radius
	var left_inner: Vector2 = center + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) - inner_arc * 0.5) * inner_radius
	var right_outer: Vector2 = center + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) + outer_arc * 0.5) * outer_radius
	var right_inner: Vector2 = center + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0)) + inner_arc * 0.5) * inner_radius
	main.draw_line(left_outer, left_inner, edge_color, 1.2)
	main.draw_line(right_outer, right_inner, edge_color, 1.2)
	main.draw_line(
		center + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0))) * inner_radius,
		center + Vector2.RIGHT.rotated(float(geometry.get("angle", 0.0))) * outer_radius,
		Color(1.0, 1.0, 1.0, 0.18 + formation_ratio * 0.1),
		1.0
	)


static func _draw_section_profile_preview(
	main: Node2D,
	geometry: Dictionary,
	weight: float,
	formation_ratio: float,
	line_color: Color,
	edge_color: Color,
	soft_color: Color
) -> bool:
	if not bool(geometry.get("has_profile_sections", false)):
		return false
	var curve_strength: float = float(geometry.get("edge_curve_strength", 1.0))
	var left_outline: PackedVector2Array = _smooth_open_outline(
		_to_screen_outline(main, geometry.get("left_outline", [])),
		_get_outline_smoothing_passes(curve_strength)
	)
	var right_outline: PackedVector2Array = _smooth_open_outline(
		_to_screen_outline(main, geometry.get("right_outline", [])),
		_get_outline_smoothing_passes(curve_strength)
	)
	if left_outline.size() < 2 or right_outline.size() < 2:
		return false
	var spine_focus: float = float(geometry.get("spine_focus", 0.0))
	var tip_focus: float = clampf(float(geometry.get("tip_focus", spine_focus)), 0.0, 1.0)
	var spine_points: PackedVector2Array = _to_screen_outline(main, geometry.get("spine_points", []))
	var fill_color := Color(soft_color.r, soft_color.g, soft_color.b, (0.09 + formation_ratio * 0.08) * weight)
	var outer_cap_control: Vector2 = main._to_screen(geometry.get("outer_cap_control", geometry.get("tip", Vector2.ZERO)))
	var inner_cap_control: Vector2 = main._to_screen(geometry.get("inner_cap_control", geometry.get("tail", Vector2.ZERO)))
	var outer_curve: PackedVector2Array = _build_quadratic_curve_points(
		left_outline[left_outline.size() - 1],
		outer_cap_control,
		right_outline[right_outline.size() - 1],
		_get_cap_curve_segments(curve_strength)
	)
	var inner_curve: PackedVector2Array = _build_quadratic_curve_points(
		right_outline[0],
		inner_cap_control,
		left_outline[0],
		_get_cap_curve_segments(curve_strength)
	)
	_draw_section_band_fill(
		main,
		left_outline,
		right_outline,
		outer_curve,
		inner_curve,
		outer_cap_control,
		inner_cap_control,
		fill_color
	)
	_draw_outline_path(main, left_outline, line_color, 2.6)
	_draw_outline_path(main, right_outline, line_color, 2.6)
	_draw_outline_path(main, outer_curve, line_color, 2.6)
	_draw_outline_path(main, inner_curve, edge_color, 1.4)
	if spine_focus > 0.0:
		var spine_color := Color(1.0, 1.0, 1.0, (0.08 + formation_ratio * 0.1) * spine_focus)
		if spine_points.size() >= 2:
			_draw_outline_path(main, spine_points, spine_color, 1.1)
		else:
			main.draw_line(
				main._to_screen(geometry.get("tail", Vector2.ZERO)),
				main._to_screen(geometry.get("tip", Vector2.ZERO)),
				spine_color,
				1.1
			)
	if float(geometry.get("tip_radius", 0.0)) > 0.05:
		main.draw_circle(
			main._to_screen(geometry.get("tip", Vector2.ZERO)),
			float(geometry.get("tip_radius", 0.0)),
			Color(1.0, 1.0, 1.0, (0.12 + formation_ratio * 0.12) * tip_focus)
		)
	return true


static func _build_fan_band_polygon(center: Vector2, angle: float, arc: float, inner_radius: float, outer_radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segment_count: int = maxi(segments, 3)
	var step: float = arc / float(segment_count)
	var segment_index: int = 0
	while segment_index <= segment_count:
		var sample_angle: float = angle - arc * 0.5 + step * float(segment_index)
		points.append(center + Vector2.RIGHT.rotated(sample_angle) * outer_radius)
		segment_index += 1
	segment_index = segment_count
	while segment_index >= 0:
		var inner_sample_angle: float = angle - arc * 0.5 + step * float(segment_index)
		points.append(center + Vector2.RIGHT.rotated(inner_sample_angle) * inner_radius)
		segment_index -= 1
	return points


static func _build_crescent_polygon(center: Vector2, angle: float, outer_arc: float, inner_arc: float, inner_radius: float, outer_radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segment_count: int = maxi(segments, 4)
	var outer_step: float = outer_arc / float(segment_count)
	var inner_step: float = inner_arc / float(segment_count)
	var segment_index: int = 0
	while segment_index <= segment_count:
		var sample_angle: float = angle - outer_arc * 0.5 + outer_step * float(segment_index)
		points.append(center + Vector2.RIGHT.rotated(sample_angle) * outer_radius)
		segment_index += 1
	segment_index = segment_count
	while segment_index >= 0:
		var inner_sample_angle: float = angle - inner_arc * 0.5 + inner_step * float(segment_index)
		points.append(center + Vector2.RIGHT.rotated(inner_sample_angle) * inner_radius)
		segment_index -= 1
	return points


static func _to_screen_outline(main: Node2D, world_points: Array) -> PackedVector2Array:
	var screen_points := PackedVector2Array()
	for world_point in world_points:
		screen_points.append(main._to_screen(world_point))
	return screen_points


static func _draw_outline_path(main: Node2D, points: PackedVector2Array, color: Color, width: float) -> void:
	var point_index: int = 0
	while point_index < points.size() - 1:
		main.draw_line(points[point_index], points[point_index + 1], color, width)
		point_index += 1


static func _draw_section_band_fill(
	main: Node2D,
	left_outline: PackedVector2Array,
	right_outline: PackedVector2Array,
	outer_curve: PackedVector2Array,
	inner_curve: PackedVector2Array,
	outer_cap_control: Vector2,
	inner_cap_control: Vector2,
	color: Color
) -> void:
	var strip_count: int = mini(left_outline.size(), right_outline.size()) - 1
	var strip_index: int = 0
	while strip_index < strip_count:
		var left_from: Vector2 = left_outline[strip_index]
		var left_to: Vector2 = left_outline[strip_index + 1]
		var right_from: Vector2 = right_outline[strip_index]
		var right_to: Vector2 = right_outline[strip_index + 1]
		_try_draw_colored_polygon(
			main,
			PackedVector2Array([left_from, left_to, right_from]),
			color
		)
		_try_draw_colored_polygon(
			main,
			PackedVector2Array([right_from, left_to, right_to]),
			color
		)
		strip_index += 1
	_draw_curve_fan_fill(main, outer_cap_control, outer_curve, color)
	_draw_curve_fan_fill(main, inner_cap_control, inner_curve, color)


static func _draw_curve_fan_fill(main: Node2D, anchor: Vector2, curve_points: PackedVector2Array, color: Color) -> void:
	if curve_points.size() < 2:
		return
	var point_index: int = 0
	while point_index < curve_points.size() - 1:
		_try_draw_colored_polygon(
			main,
			PackedVector2Array([anchor, curve_points[point_index], curve_points[point_index + 1]]),
			color
		)
		point_index += 1


static func _try_draw_colored_polygon(main: Node2D, points: PackedVector2Array, color: Color) -> void:
	if not _is_valid_fill_polygon(points):
		return
	main.draw_colored_polygon(points, color)


static func _is_valid_fill_polygon(points: PackedVector2Array) -> bool:
	if points.size() < 3:
		return false
	var edge_index: int = 0
	while edge_index < points.size():
		var next_index: int = (edge_index + 1) % points.size()
		if points[edge_index].distance_to(points[next_index]) < 0.2:
			return false
		edge_index += 1
	var area: float = 0.0
	var point_index: int = 0
	while point_index < points.size():
		var next_point_index: int = (point_index + 1) % points.size()
		area += points[point_index].x * points[next_point_index].y - points[next_point_index].x * points[point_index].y
		point_index += 1
	if absf(area) <= 1.0:
		return false
	var segment_index: int = 0
	while segment_index < points.size():
		var segment_next_index: int = (segment_index + 1) % points.size()
		var other_index: int = segment_index + 1
		while other_index < points.size():
			var other_next_index: int = (other_index + 1) % points.size()
			var shares_vertex: bool = (
				segment_index == other_index
				or segment_index == other_next_index
				or segment_next_index == other_index
				or segment_next_index == other_next_index
			)
			if not shares_vertex and _segments_intersect(
				points[segment_index],
				points[segment_next_index],
				points[other_index],
				points[other_next_index]
			):
				return false
			other_index += 1
		segment_index += 1
	return true


static func _segments_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	var a1_side: float = _signed_triangle_area(a1, a2, b1)
	var a2_side: float = _signed_triangle_area(a1, a2, b2)
	var b1_side: float = _signed_triangle_area(b1, b2, a1)
	var b2_side: float = _signed_triangle_area(b1, b2, a2)
	if is_zero_approx(a1_side) and _is_point_on_segment(b1, a1, a2):
		return true
	if is_zero_approx(a2_side) and _is_point_on_segment(b2, a1, a2):
		return true
	if is_zero_approx(b1_side) and _is_point_on_segment(a1, b1, b2):
		return true
	if is_zero_approx(b2_side) and _is_point_on_segment(a2, b1, b2):
		return true
	return a1_side * a2_side < 0.0 and b1_side * b2_side < 0.0


static func _signed_triangle_area(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)


static func _is_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> bool:
	return (
		point.x >= minf(segment_start.x, segment_end.x) - 0.2
		and point.x <= maxf(segment_start.x, segment_end.x) + 0.2
		and point.y >= minf(segment_start.y, segment_end.y) - 0.2
		and point.y <= maxf(segment_start.y, segment_end.y) + 0.2
	)


static func _get_outline_smoothing_passes(curve_strength: float) -> int:
	var clamped_strength: float = clampf(curve_strength, 0.0, 1.0)
	if clamped_strength >= 0.68:
		return 2
	if clamped_strength >= 0.16:
		return 1
	return 0


static func _smooth_open_outline(points: PackedVector2Array, passes: int) -> PackedVector2Array:
	if passes <= 0 or points.size() < 3:
		return points
	var result := PackedVector2Array()
	for point in points:
		result.append(point)
	var pass_index: int = 0
	while pass_index < passes and result.size() >= 3:
		var smoothed := PackedVector2Array()
		smoothed.append(result[0])
		var point_index: int = 0
		while point_index < result.size() - 1:
			var from_point: Vector2 = result[point_index]
			var to_point: Vector2 = result[point_index + 1]
			smoothed.append(from_point.lerp(to_point, 0.25))
			smoothed.append(from_point.lerp(to_point, 0.75))
			point_index += 1
		smoothed.append(result[result.size() - 1])
		result = smoothed
		pass_index += 1
	return result


static func _get_cap_curve_segments(curve_strength: float) -> int:
	return 8 + int(round(clampf(curve_strength, 0.0, 1.0) * 8.0))


static func _build_quadratic_curve_points(start: Vector2, control: Vector2, finish: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segment_count: int = maxi(segments, 4)
	var segment_index: int = 0
	while segment_index <= segment_count:
		var t: float = float(segment_index) / float(segment_count)
		var one_minus_t: float = 1.0 - t
		points.append(
			start * one_minus_t * one_minus_t
			+ control * 2.0 * one_minus_t * t
			+ finish * t * t
		)
		segment_index += 1
	return points
