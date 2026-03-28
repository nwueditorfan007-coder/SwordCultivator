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
	main.draw_colored_polygon(PackedVector2Array([tip, left, right]), sword_color)

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
		"spear":
			_draw_spear_preview(main, preview, morph_state, preview_alpha, formation_ratio)


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
	var fan_color: Color = SwordArrayController.get_accent_color(SwordArrayConfig.MODE_FAN)
	fan_color.a = (preview_alpha + 0.08) * weight
	var fan_edge_color := Color(fan_color.r, fan_color.g, fan_color.b, 0.24 * weight)
	var fan_soft_color: Color = SwordArrayController.get_soft_accent_color(SwordArrayConfig.MODE_FAN)
	fan_soft_color.a = (0.16 + formation_ratio * 0.14) * weight
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
	main.draw_colored_polygon(
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
	main.draw_colored_polygon(
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
	main.draw_colored_polygon(fill, Color(soft_color.r, soft_color.g, soft_color.b, 0.1 + formation_ratio * 0.08))
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


static func _draw_spear_preview(main: Node2D, preview: Dictionary, state_source, preview_alpha: float, formation_ratio: float) -> void:
	var left_outline: PackedVector2Array = _to_screen_outline(main, preview["left_outline"])
	var right_outline: PackedVector2Array = _to_screen_outline(main, preview["right_outline"])
	var outline := PackedVector2Array()
	for point in left_outline:
		outline.append(point)
	var right_index: int = right_outline.size() - 1
	while right_index >= 0:
		outline.append(right_outline[right_index])
		right_index -= 1
	var accent_color: Color = SwordArrayController.get_accent_color(state_source)
	accent_color.a = preview_alpha + 0.08
	var soft_color: Color = SwordArrayController.get_soft_accent_color(state_source)
	soft_color.a = 0.16 + formation_ratio * 0.12
	main.draw_colored_polygon(
		outline,
		Color(soft_color.r, soft_color.g, soft_color.b, 0.12 + formation_ratio * 0.08)
	)
	_draw_outline_path(main, left_outline, accent_color, 2.2)
	_draw_outline_path(main, right_outline, accent_color, 2.2)
	var sections: Array = preview["sections"]
	var section_index: int = 0
	while section_index < sections.size():
		var section: Dictionary = sections[section_index]
		var screen_left: Vector2 = main._to_screen(section["left"])
		var screen_right: Vector2 = main._to_screen(section["right"])
		if section_index > 0 and section_index < sections.size() - 1:
			main.draw_line(screen_left, screen_right, Color(soft_color.r, soft_color.g, soft_color.b, 0.22 + formation_ratio * 0.08), 1.0)
		section_index += 1
	var tail: Vector2 = main._to_screen(preview["tail"])
	var tip: Vector2 = main._to_screen(preview["tip"])
	main.draw_line(tail, tip, Color(1.0, 1.0, 1.0, 0.24 + formation_ratio * 0.16), 1.2)
	main.draw_circle(tip, preview["tip_radius"], Color(1.0, 1.0, 1.0, 0.24 + formation_ratio * 0.2))


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
