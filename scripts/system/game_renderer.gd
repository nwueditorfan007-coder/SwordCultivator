extends RefCounted
class_name GameRenderer

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayController = preload("res://scripts/system/sword_array_controller.gd")


static func draw_game(main: Node2D) -> void:
	main.draw_rect(Rect2(Vector2.ZERO, main.get_viewport_rect().size), main.COLORS["background"], true)
	main.draw_rect(main.ARENA_RECT, Color("111111"), true)
	main.draw_rect(main.ARENA_RECT, Color("2e2e2e"), false, 3.0)

	var shake_offset: Vector2 = Vector2.ZERO
	if main.screen_shake > 0.1:
		shake_offset = Vector2(randf_range(-main.screen_shake, main.screen_shake), randf_range(-main.screen_shake, main.screen_shake))
	main.draw_set_transform(shake_offset, 0.0, Vector2.ONE)

	var x: int = 0
	while x <= int(main.ARENA_SIZE.x):
		var from: Vector2 = main.ARENA_ORIGIN + Vector2(float(x), 0.0)
		var to: Vector2 = main.ARENA_ORIGIN + Vector2(float(x), main.ARENA_SIZE.y)
		main.draw_line(from, to, main.COLORS["grid"], 1.0)
		x += 50

	var y: int = 0
	while y <= int(main.ARENA_SIZE.y):
		var from_y: Vector2 = main.ARENA_ORIGIN + Vector2(0.0, float(y))
		var to_y: Vector2 = main.ARENA_ORIGIN + Vector2(main.ARENA_SIZE.x, float(y))
		main.draw_line(from_y, to_y, main.COLORS["grid"], 1.0)
		y += 50

	for particle in main.particles:
		var particle_color: Color = particle["color"]
		particle_color.a = particle["life"] / particle["max_life"]
		main.draw_circle(main._to_screen(particle["pos"]), particle["size"], particle_color)

	if main._has_boss():
		main._draw_boss()

	for bullet in main.bullets:
		var bullet_pos: Vector2 = main._to_screen(bullet["pos"])
		var bullet_color: Color = bullet["color"]
		var bullet_radius: float = bullet["radius"]
		if bullet["state"] == "freezing" or bullet["state"] == "frozen" or bullet["state"] == "fired":
			bullet_color = main.COLORS["frozen"]
			bullet_radius *= 1.1 if bullet["state"] != "fired" else 1.0
		if main.player["absorbed_ids"].has(bullet["id"]):
			var morph_state: Dictionary = main._get_sword_array_morph_state()
			var hold_ratio: float = main._get_sword_array_formation_ratio()
			bullet_radius *= lerpf(1.0, 1.28, hold_ratio)
			bullet_color = SwordArrayController.get_accent_color(morph_state)
		main.draw_circle(bullet_pos, bullet_radius, bullet_color)

	for enemy in main.enemies:
		var color_key: String = enemy["type"]
		var enemy_screen_pos: Vector2 = main._to_screen(enemy["pos"])
		main.draw_circle(enemy_screen_pos, enemy["radius"], main.COLORS[color_key])
		if enemy["type"] != main.PUPPET:
			var health_ratio: float = max(enemy["health"], 0.0) / enemy["max_health"]
			var bar_pos: Vector2 = enemy_screen_pos + Vector2(-enemy["radius"], -enemy["radius"] - 10.0)
			main.draw_rect(Rect2(bar_pos, Vector2(enemy["radius"] * 2.0, 4.0)), Color("2f2f2f"), true)
			main.draw_rect(Rect2(bar_pos, Vector2(enemy["radius"] * 2.0 * health_ratio, 4.0)), main.COLORS["health"], true)
		elif enemy.get("melee_timer", 0.0) > 0.0:
			_draw_puppet_attack_telegraph(main, enemy, enemy_screen_pos)

	var player_pos: Vector2 = main._to_screen(main.player["pos"])
	main.draw_circle(player_pos, main.PLAYER_RADIUS, main.COLORS["player"])
	var aura_color: Color = main.COLORS["melee_sword"] if main.player["mode"] == main.CombatMode.MELEE else main.COLORS["ranged_sword"]
	main.draw_arc(player_pos, main.PLAYER_RADIUS + 5.0, 0.0, TAU, 28, aura_color, 2.0)

	if main.player["is_charging"]:
		main.draw_arc(player_pos, SwordArrayConfig.ABSORB_RANGE, 0.0, TAU, 48, main.COLORS["frozen"], 1.0)

	if main.player["absorbed_ids"].size() > 0:
		_draw_sword_array_preview(main, player_pos)

	if main.debug_calibration_mode:
		_draw_debug_calibration_overlay(main, player_pos)

	var sword_pos: Vector2 = main._to_screen(main.sword["pos"])
	var sword_color: Color = main.COLORS["melee_sword"] if main.player["mode"] == main.CombatMode.MELEE else main.COLORS["ranged_sword"]
	var sword_angle: float = main.sword["angle"]
	var tip: Vector2 = sword_pos + Vector2.RIGHT.rotated(sword_angle) * (main.SWORD_RADIUS * 1.2)
	var left: Vector2 = sword_pos + Vector2.LEFT.rotated(sword_angle) + Vector2.UP.rotated(sword_angle) * 8.0
	var right: Vector2 = sword_pos + Vector2.LEFT.rotated(sword_angle) + Vector2.DOWN.rotated(sword_angle) * 8.0
	_try_draw_colored_polygon(main, PackedVector2Array([tip, left, right]), sword_color)

	if main.player["attack_flash_timer"] > 0.0:
		var attack_angle: float = (main.mouse_world - main.player["pos"]).angle()
		main.draw_arc(player_pos, main.SWORD_MELEE_RANGE, attack_angle - main.SWORD_MELEE_ARC * 0.5, attack_angle + main.SWORD_MELEE_ARC * 0.5, 36, main.COLORS["melee_sword"], 4.0)

	main.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_hud_bars(main)


static func _draw_debug_calibration_overlay(main: Node2D, player_pos: Vector2) -> void:
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var boundary_colors := [
		Color(0.34, 1.0, 0.92, 0.28),
		Color(0.65, 0.96, 1.0, 0.24),
		Color(0.95, 0.9, 0.55, 0.22),
		Color(1.0, 1.0, 1.0, 0.18),
	]
	var boundary_values := [
		distances["ring_stable_end"],
		distances["ring_to_fan_end"],
		distances["fan_stable_end"],
		distances["fan_to_pierce_end"],
	]
	var boundary_index: int = 0
	while boundary_index < boundary_values.size():
		main.draw_arc(player_pos, boundary_values[boundary_index], 0.0, TAU, 72, boundary_colors[boundary_index], 1.3)
		boundary_index += 1

	var mouse_pos: Vector2 = main._to_screen(main.mouse_world)
	main.draw_line(player_pos, mouse_pos, Color(1.0, 1.0, 1.0, 0.35), 1.4)
	main.draw_circle(mouse_pos, 4.0, Color(1.0, 1.0, 1.0, 0.55))


static func _draw_puppet_attack_telegraph(main: Node2D, enemy: Dictionary, enemy_screen_pos: Vector2) -> void:
	var to_player: Vector2 = main.player["pos"] - enemy["pos"]
	if to_player.is_zero_approx():
		to_player = Vector2.RIGHT
	var attack_angle: float = to_player.angle()
	var attack_progress: float = main.PUPPET_MELEE_COOLDOWN - enemy["melee_timer"]

	if attack_progress < main.PUPPET_MELEE_PREP_TIME:
		var prep_ratio: float = attack_progress / main.PUPPET_MELEE_PREP_TIME
		main.draw_arc(
			enemy_screen_pos,
			main.PUPPET_MELEE_RANGE,
			attack_angle - 0.5,
			attack_angle + 0.5,
			28,
			Color(1.0, 0.0, 0.0, 0.55),
			2.0
		)
		main.draw_arc(
			enemy_screen_pos,
			main.PUPPET_MELEE_RANGE * prep_ratio,
			attack_angle - 0.5,
			attack_angle + 0.5,
			28,
			Color(1.0, 0.4, 0.4, 0.9),
			3.0
		)
	elif attack_progress < main.PUPPET_MELEE_PREP_TIME + 0.16:
		main.draw_arc(
			enemy_screen_pos,
			main.PUPPET_MELEE_RANGE,
			attack_angle - 0.8,
			attack_angle + 0.8,
			28,
			Color(1.0, 0.0, 0.0, 1.0),
			5.0
		)


static func draw_hud_bars(main: Node2D) -> void:
	var health_bar_rect: Rect2 = Rect2(Vector2(28.0, 24.0), Vector2(260.0, 18.0))
	var energy_bar_rect: Rect2 = Rect2(Vector2(28.0, 52.0), Vector2(260.0, 12.0))
	main.draw_rect(health_bar_rect, Color("1d1d1d"), true)
	main.draw_rect(Rect2(health_bar_rect.position, Vector2(health_bar_rect.size.x * (main.player["health"] / main.PLAYER_MAX_HEALTH), health_bar_rect.size.y)), main.COLORS["health"], true)
	main.draw_rect(energy_bar_rect, Color("1d1d1d"), true)
	main.draw_rect(Rect2(energy_bar_rect.position, Vector2(energy_bar_rect.size.x * (main.player["energy"] / main.PLAYER_MAX_ENERGY), energy_bar_rect.size.y)), main.COLORS["energy"], true)


static func _draw_sword_array_preview(main: Node2D, player_pos: Vector2) -> void:
	var morph_state: Dictionary = main._get_sword_array_morph_state()
	var formation_ratio: float = main._get_sword_array_formation_ratio()
	var preview: Dictionary = SwordArrayController.get_preview_data(main, morph_state, formation_ratio)
	var hold_ratio: float = main.player.get("array_hold_ratio", 0.0)
	var preview_alpha: float = 0.18 + formation_ratio * 0.28 + hold_ratio * 0.18
	match preview["type"]:
		SwordArrayConfig.MODE_RING:
			_draw_ring_preview(main, player_pos, preview, 1.0, preview_alpha, formation_ratio)
		SwordArrayConfig.MODE_FAN:
			_draw_fan_preview(main, player_pos, preview, 1.0, preview_alpha, formation_ratio)
		SwordArrayConfig.MODE_PIERCE:
			_draw_pierce_preview(main, preview, 1.0, preview_alpha, formation_ratio)
		"crescent":
			_draw_crescent_preview(main, preview, morph_state, preview_alpha, formation_ratio)


static func _draw_ring_preview(main: Node2D, player_pos: Vector2, preview: Dictionary, weight: float, preview_alpha: float, formation_ratio: float) -> void:
	var ring_color: Color = SwordArrayController.get_accent_color(SwordArrayConfig.MODE_RING)
	ring_color.a = preview_alpha * weight
	var ring_outline := Color(ring_color.r, ring_color.g, ring_color.b, preview_alpha * weight * 0.88)
	main.draw_arc(player_pos, preview["radius"], 0.0, TAU, 40, ring_outline, 3.0)
	var ring_soft_color: Color = SwordArrayController.get_soft_accent_color(SwordArrayConfig.MODE_RING)
	ring_soft_color.a = (0.14 + formation_ratio * 0.1) * weight
	main.draw_arc(player_pos, preview["outer_radius"], 0.0, TAU, 40, ring_soft_color, 1.5)
	var spoke_count: int = maxi(main.player["absorbed_ids"].size(), 1)
	var spoke_index: int = 0
	while spoke_index < spoke_count:
		var spoke_angle: float = (TAU / float(spoke_count)) * float(spoke_index)
		main.draw_line(
			player_pos + Vector2.RIGHT.rotated(spoke_angle) * max(preview["radius"] - 10.0, 8.0),
			player_pos + Vector2.RIGHT.rotated(spoke_angle) * preview["outer_radius"],
			ring_color,
			1.2
		)
		spoke_index += 1


static func _draw_fan_preview(main: Node2D, player_pos: Vector2, preview: Dictionary, weight: float, preview_alpha: float, formation_ratio: float) -> void:
	var fan_color_source = preview.get("preview_state", SwordArrayConfig.MODE_FAN)
	var fan_color: Color = SwordArrayController.get_accent_color(fan_color_source)
	fan_color.a = (preview_alpha + 0.08) * weight
	var fan_edge_color := Color(fan_color.r, fan_color.g, fan_color.b, 0.24 * weight)
	var fan_soft_color: Color = SwordArrayController.get_soft_accent_color(fan_color_source)
	fan_soft_color.a = (0.16 + formation_ratio * 0.14) * weight
	if preview.get("has_profile_sections", false):
		var curve_strength: float = clampf(float(preview.get("edge_curve_strength", 1.0)), 0.0, 1.0)
		var left_outline: PackedVector2Array = _smooth_open_outline(
			_to_screen_outline(main, preview["left_outline"]),
			_get_outline_smoothing_passes(curve_strength)
		)
		var right_outline: PackedVector2Array = _smooth_open_outline(
			_to_screen_outline(main, preview["right_outline"]),
			_get_outline_smoothing_passes(curve_strength)
		)
		if left_outline.size() >= 2 and right_outline.size() >= 2:
			var spine_focus: float = clampf(float(preview.get("spine_focus", 0.0)), 0.0, 1.0)
			var tip_focus: float = clampf(float(preview.get("tip_focus", spine_focus)), 0.0, 1.0)
			var fill_color := Color(fan_soft_color.r, fan_soft_color.g, fan_soft_color.b, (0.09 + formation_ratio * 0.08) * weight)
			var outer_curve: PackedVector2Array = _build_quadratic_curve_points(
				left_outline[left_outline.size() - 1],
				main._to_screen(preview.get("outer_cap_control", preview["tip"])),
				right_outline[right_outline.size() - 1],
				_get_cap_curve_segments(curve_strength)
			)
			var inner_curve: PackedVector2Array = _build_quadratic_curve_points(
				right_outline[0],
				main._to_screen(preview.get("inner_cap_control", preview["tail"])),
				left_outline[0],
				_get_cap_curve_segments(curve_strength)
			)
			_draw_section_band_fill(
				main,
				left_outline,
				right_outline,
				outer_curve,
				inner_curve,
				main._to_screen(preview.get("outer_cap_control", preview["tip"])),
				main._to_screen(preview.get("inner_cap_control", preview["tail"])),
				fill_color
			)
			_draw_outline_path(main, left_outline, fan_color, 2.6)
			_draw_outline_path(main, right_outline, fan_color, 2.6)
			_draw_outline_path(main, outer_curve, fan_color, 2.6)
			_draw_outline_path(main, inner_curve, fan_edge_color, 1.4)
			if spine_focus > 0.0:
				main.draw_line(
					main._to_screen(preview["tail"]),
					main._to_screen(preview["tip"]),
					Color(1.0, 1.0, 1.0, (0.08 + formation_ratio * 0.1) * spine_focus),
					1.1
				)
			if preview.get("tip_radius", 0.0) > 0.05:
				main.draw_circle(
					main._to_screen(preview["tip"]),
					preview["tip_radius"],
					Color(1.0, 1.0, 1.0, (0.12 + formation_ratio * 0.12) * tip_focus)
				)
			return
	var fan_mid_radius: float = lerpf(preview["inner_radius"], preview["outer_radius"], 0.56)
	var fan_mid_arc: float = preview["arc"] * 0.78
	var fan_fill: PackedVector2Array = _build_fan_band_polygon(
		player_pos,
		preview["angle"],
		preview["arc"],
		preview["inner_radius"],
		preview["outer_radius"],
		16
	)
	_try_draw_colored_polygon(
		main,
		fan_fill,
		Color(fan_soft_color.r, fan_soft_color.g, fan_soft_color.b, (0.08 + formation_ratio * 0.08) * weight)
	)
	main.draw_arc(player_pos, preview["outer_radius"], preview["angle"] - preview["arc"] * 0.5, preview["angle"] + preview["arc"] * 0.5, 32, fan_color, 3.0)
	main.draw_arc(player_pos, fan_mid_radius, preview["angle"] - fan_mid_arc * 0.5, preview["angle"] + fan_mid_arc * 0.5, 24, fan_soft_color, 1.6)
	main.draw_arc(player_pos, preview["inner_radius"], preview["angle"] - fan_mid_arc * 0.32, preview["angle"] + fan_mid_arc * 0.32, 18, fan_edge_color, 1.1)
	main.draw_line(
		player_pos + Vector2.RIGHT.rotated(preview["angle"] - preview["arc"] * 0.5) * preview["inner_radius"],
		player_pos + Vector2.RIGHT.rotated(preview["angle"] - preview["arc"] * 0.5) * preview["outer_radius"],
		fan_edge_color,
		1.2
	)
	main.draw_line(
		player_pos + Vector2.RIGHT.rotated(preview["angle"] + preview["arc"] * 0.5) * preview["inner_radius"],
		player_pos + Vector2.RIGHT.rotated(preview["angle"] + preview["arc"] * 0.5) * preview["outer_radius"],
		fan_edge_color,
		1.2
	)
	main.draw_line(
		player_pos + Vector2.RIGHT.rotated(preview["angle"]) * preview["inner_radius"],
		player_pos + Vector2.RIGHT.rotated(preview["angle"]) * preview["outer_radius"],
		fan_soft_color,
		1.0
	)


static func _draw_pierce_preview(main: Node2D, preview: Dictionary, weight: float, preview_alpha: float, formation_ratio: float) -> void:
	var start_pos: Vector2 = main._to_screen(preview["start"])
	var end_pos: Vector2 = main._to_screen(preview["end"])
	var tip_pos: Vector2 = main._to_screen(preview["tip"])
	var line_dir: Vector2 = (end_pos - start_pos).normalized()
	var side_offset: Vector2 = line_dir.rotated(PI * 0.5) * preview["half_width"]
	var pierce_color: Color = SwordArrayController.get_accent_color(SwordArrayConfig.MODE_PIERCE)
	pierce_color.a = (preview_alpha + 0.1) * weight
	var pierce_soft_color: Color = SwordArrayController.get_soft_accent_color(SwordArrayConfig.MODE_PIERCE)
	pierce_soft_color.a = (0.18 + formation_ratio * 0.08) * weight
	var wedge_back: Vector2 = start_pos + line_dir * preview["wedge_length"]
	var wedge_side: Vector2 = line_dir.rotated(PI * 0.5) * preview["wedge_width"]
	_try_draw_colored_polygon(
		main,
		PackedVector2Array([start_pos + wedge_side, start_pos - wedge_side, wedge_back]),
		Color(pierce_soft_color.r, pierce_soft_color.g, pierce_soft_color.b, (0.12 + formation_ratio * 0.1) * weight)
	)
	main.draw_line(start_pos, end_pos, pierce_color, 3.2 + formation_ratio * 1.4)
	main.draw_line(start_pos + side_offset, end_pos + side_offset * 0.35, pierce_soft_color, 1.0)
	main.draw_line(start_pos - side_offset, end_pos - side_offset * 0.35, pierce_soft_color, 1.0)
	main.draw_line(end_pos, tip_pos, Color(1.0, 1.0, 1.0, (0.34 + formation_ratio * 0.18) * weight), 2.2)
	main.draw_circle(tip_pos, preview["tip_radius"], Color(1.0, 1.0, 1.0, (0.28 + formation_ratio * 0.22) * weight))


static func _draw_crescent_preview(main: Node2D, preview: Dictionary, state_source, preview_alpha: float, formation_ratio: float) -> void:
	var center: Vector2 = main._to_screen(preview["center"])
	var accent_color: Color = SwordArrayController.get_accent_color(state_source)
	accent_color.a = preview_alpha + 0.06
	var soft_color: Color = SwordArrayController.get_soft_accent_color(state_source)
	soft_color.a = 0.14 + formation_ratio * 0.12
	var fill: PackedVector2Array = _build_crescent_polygon(
		center,
		preview["angle"],
		preview["arc"],
		preview["inner_arc"],
		preview["inner_radius"],
		preview["outer_radius"],
		18
	)
	_try_draw_colored_polygon(main, fill, Color(soft_color.r, soft_color.g, soft_color.b, 0.1 + formation_ratio * 0.08))
	main.draw_arc(center, preview["outer_radius"], preview["angle"] - preview["arc"] * 0.5, preview["angle"] + preview["arc"] * 0.5, 36, accent_color, 3.0)
	main.draw_arc(center, preview["inner_radius"], preview["angle"] - preview["inner_arc"] * 0.5, preview["angle"] + preview["inner_arc"] * 0.5, 28, soft_color, 1.8)
	var left_outer: Vector2 = center + Vector2.RIGHT.rotated(preview["angle"] - preview["arc"] * 0.5) * preview["outer_radius"]
	var left_inner: Vector2 = center + Vector2.RIGHT.rotated(preview["angle"] - preview["inner_arc"] * 0.5) * preview["inner_radius"]
	var right_outer: Vector2 = center + Vector2.RIGHT.rotated(preview["angle"] + preview["arc"] * 0.5) * preview["outer_radius"]
	var right_inner: Vector2 = center + Vector2.RIGHT.rotated(preview["angle"] + preview["inner_arc"] * 0.5) * preview["inner_radius"]
	main.draw_line(left_outer, left_inner, soft_color, 1.2)
	main.draw_line(right_outer, right_inner, soft_color, 1.2)
	main.draw_line(
		center + Vector2.RIGHT.rotated(preview["angle"]) * preview["inner_radius"],
		center + Vector2.RIGHT.rotated(preview["angle"]) * preview["outer_radius"],
		Color(1.0, 1.0, 1.0, 0.22 + formation_ratio * 0.12),
		1.0
	)


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
			PackedVector2Array([
				left_from,
				left_to,
				right_from,
			]),
			color
		)
		_try_draw_colored_polygon(
			main,
			PackedVector2Array([
				right_from,
				left_to,
				right_to,
			]),
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
			PackedVector2Array([
				anchor,
				curve_points[point_index],
				curve_points[point_index + 1],
			]),
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
