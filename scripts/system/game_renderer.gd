extends RefCounted
class_name GameRenderer

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayController = preload("res://scripts/system/sword_array_controller.gd")
const SwordArrayBandRenderer = preload("res://scripts/system/sword_array_band_renderer.gd")


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

	for pickup in main.pickups:
		var pickup_pos: Vector2 = main._to_screen(pickup["pos"])
		var pickup_color: Color = main.COLORS["sword_resource"]
		var pulse_radius: float = 10.0 + absf(sin(main.elapsed_time * 6.0 + pickup_pos.x * 0.01)) * 3.0
		main.draw_circle(pickup_pos, 8.0, Color(pickup_color.r, pickup_color.g, pickup_color.b, 0.18))
		main.draw_arc(pickup_pos, pulse_radius, 0.0, TAU, 24, pickup_color, 2.0)
		main.draw_line(pickup_pos + Vector2(0.0, -pulse_radius - 3.0), pickup_pos + Vector2(0.0, -pulse_radius + 4.0), pickup_color, 1.4)
		main.draw_circle(pickup_pos, 4.5, pickup_color)

	for bullet in main.bullets:
		var bullet_pos: Vector2 = main._to_screen(bullet["pos"])
		var bullet_color: Color = bullet["color"]
		var bullet_radius: float = bullet["radius"]
		if bullet["state"] == "deflected":
			bullet_color = main.COLORS["melee_sword"]
			bullet_radius *= 1.15
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
	if main._is_array_empowered():
		aura_color = aura_color.lerp(main.COLORS["sword_resource"], 0.45)
	main.draw_arc(player_pos, main.PLAYER_RADIUS + 5.0, 0.0, TAU, 28, aura_color, 2.0)
	if main._is_array_empowered():
		var pulse_radius: float = main.PLAYER_RADIUS + 11.0 + sin(main.elapsed_time * 8.0) * 2.0
		main.draw_arc(
			player_pos,
			pulse_radius,
			0.0,
			TAU,
			32,
			Color(main.COLORS["sword_resource"].r, main.COLORS["sword_resource"].g, main.COLORS["sword_resource"].b, 0.55),
			2.2
		)

	if main._should_draw_sword_array_preview():
		_draw_sword_array_preview(main, player_pos)

	var ready_slot_lookup: Dictionary = {}
	for array_sword in main.array_swords:
		if array_sword["state"] == "ready":
			ready_slot_lookup[int(array_sword.get("slot_index", -1))] = true
	var slot_index: int = 0
	while slot_index < main._get_current_array_sword_capacity():
		if not ready_slot_lookup.has(slot_index):
			var empty_slot_pos: Vector2 = main._to_screen(main._get_array_sword_slot_position(slot_index))
			var ghost_color: Color = SwordArrayController.get_soft_accent_color(main._get_sword_array_morph_state())
			ghost_color.a = 0.18
			main.draw_circle(empty_slot_pos, 3.0, ghost_color)
			main.draw_arc(empty_slot_pos, 7.0, 0.0, TAU, 18, ghost_color, 1.2)
		slot_index += 1

	for array_sword in main.array_swords:
		var array_sword_pos: Vector2 = main._to_screen(array_sword["pos"])
		var array_sword_color: Color = SwordArrayController.get_accent_color(main._get_sword_array_morph_state())
		if array_sword["state"] == "returning":
			array_sword_color = main.COLORS["array_sword_return"]
		elif array_sword["state"] == "outbound":
			array_sword_color = main.COLORS["array_sword"]
		if main._is_array_empowered():
			array_sword_color = array_sword_color.lerp(main.COLORS["sword_resource"], 0.28)
		var forward: Vector2 = Vector2.RIGHT
		if array_sword["vel"].length_squared() > 1.0:
			forward = array_sword["vel"].normalized()
		elif array_sword["state"] == "ready":
			forward = (array_sword["pos"] - main.player["pos"]).normalized()
			if forward.is_zero_approx():
				forward = Vector2.RIGHT
		var side: Vector2 = forward.rotated(PI * 0.5)
		var tip_pos: Vector2 = array_sword_pos + forward * 10.0
		var left_pos: Vector2 = array_sword_pos - forward * 6.0 + side * 4.0
		var right_pos: Vector2 = array_sword_pos - forward * 6.0 - side * 4.0
		if main._is_array_empowered():
			main.draw_circle(array_sword_pos, 8.0, Color(array_sword_color.r, array_sword_color.g, array_sword_color.b, 0.12))
		_try_draw_colored_polygon(main, PackedVector2Array([tip_pos, left_pos, right_pos]), array_sword_color)
		main.draw_circle(array_sword_pos, 2.2, Color.WHITE)

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
	var energy_fill_color: Color = main.COLORS["energy"]
	if main._is_array_empowered():
		energy_fill_color = energy_fill_color.lerp(main.COLORS["sword_resource"], 0.35)
		main.draw_rect(
			Rect2(energy_bar_rect.position - Vector2(2.0, 2.0), energy_bar_rect.size + Vector2(4.0, 4.0)),
			Color(
				main.COLORS["sword_resource"].r,
				main.COLORS["sword_resource"].g,
				main.COLORS["sword_resource"].b,
				0.18
			),
			false,
			2.0
		)
		_draw_empower_flames(main, energy_bar_rect)
	main.draw_rect(Rect2(energy_bar_rect.position, Vector2(energy_bar_rect.size.x * (main.player["energy"] / main.PLAYER_MAX_ENERGY), energy_bar_rect.size.y)), energy_fill_color, true)
	if main._is_array_empowered():
		var empower_ratio: float = clampf(float(main.player.get("array_empower_timer", 0.0)) / main.ARRAY_SWORD_EMPOWER_DURATION, 0.0, 1.0)
		var empower_bar_rect: Rect2 = Rect2(energy_bar_rect.position + Vector2(0.0, 17.0), Vector2(energy_bar_rect.size.x, 5.0))
		var empower_color: Color = main.COLORS["sword_resource"]
		if float(main.player.get("array_empower_timer", 0.0)) <= 1.2:
			empower_color = empower_color.lerp(main.COLORS["health"], 0.45 + 0.25 * absf(sin(main.elapsed_time * 16.0)))
		main.draw_rect(empower_bar_rect, Color("2b171a"), true)
		main.draw_rect(Rect2(empower_bar_rect.position, Vector2(empower_bar_rect.size.x * empower_ratio, empower_bar_rect.size.y)), empower_color, true)
	var shard_index: int = 0
	while shard_index < int(main.player.get("sword_resource_max", main.SWORD_RESOURCE_MAX)):
		var icon_center: Vector2 = Vector2(health_bar_rect.position.x + 12.0 + shard_index * 18.0, energy_bar_rect.position.y + 30.0)
		var icon_color: Color = main.COLORS["sword_resource"] if shard_index < int(main.player.get("sword_resource", 0)) else Color("4b5563")
		var diamond := PackedVector2Array([
			icon_center + Vector2(0.0, -6.0),
			icon_center + Vector2(6.0, 0.0),
			icon_center + Vector2(0.0, 6.0),
			icon_center + Vector2(-6.0, 0.0),
		])
		_try_draw_colored_polygon(main, diamond, icon_color)
		shard_index += 1


static func _draw_empower_flames(main: Node2D, energy_bar_rect: Rect2) -> void:
	var flame_count: int = 8
	var flame_index: int = 0
	while flame_index < flame_count:
		var x_ratio: float = float(flame_index) / float(maxi(flame_count - 1, 1))
		var base_x: float = energy_bar_rect.position.x + x_ratio * energy_bar_rect.size.x
		var sway: float = sin(main.elapsed_time * 8.0 + float(flame_index) * 0.9) * 3.0
		var flame_height: float = 7.0 + absf(sin(main.elapsed_time * 10.5 + float(flame_index) * 1.2)) * 7.0
		var flame_color: Color = main.COLORS["sword_resource"].lerp(main.COLORS["energy"], 0.35)
		flame_color.a = 0.42
		var flame := PackedVector2Array([
			Vector2(base_x - 5.0, energy_bar_rect.position.y + 1.0),
			Vector2(base_x + sway, energy_bar_rect.position.y - flame_height),
			Vector2(base_x + 5.0, energy_bar_rect.position.y + 1.0),
		])
		_try_draw_colored_polygon(main, flame, flame_color)
		flame_index += 1


static func _draw_sword_array_preview(main: Node2D, player_pos: Vector2) -> void:
	var morph_state: Dictionary = main._get_sword_array_morph_state()
	var formation_ratio: float = main._get_sword_array_formation_ratio()
	var geometry: Dictionary = SwordArrayController.get_geometry_result(main, morph_state, formation_ratio)
	var hold_ratio: float = main.player.get("array_hold_ratio", 0.0)
	var preview_alpha: float = 0.18 + formation_ratio * 0.28 + hold_ratio * 0.18
	_draw_preview_family(main, player_pos, geometry, morph_state, preview_alpha, formation_ratio)


static func _draw_preview_family(
	main: Node2D,
	player_pos: Vector2,
	geometry: Dictionary,
	state_source,
	preview_alpha: float,
	formation_ratio: float
) -> void:
	match String(geometry.get("family", "")):
		SwordArrayConfig.FORMATION_FAMILY_BAND:
			_draw_band_family_preview(main, player_pos, geometry, state_source, preview_alpha, formation_ratio)
		_:
			_draw_legacy_preview_family(main, player_pos, geometry, state_source, preview_alpha, formation_ratio)


static func _draw_band_family_preview(
	main: Node2D,
	player_pos: Vector2,
	geometry: Dictionary,
	state_source,
	preview_alpha: float,
	formation_ratio: float
) -> void:
	SwordArrayBandRenderer.draw_preview(main, player_pos, geometry, state_source, preview_alpha, formation_ratio)


static func _draw_legacy_preview_family(
	main: Node2D,
	player_pos: Vector2,
	geometry: Dictionary,
	state_source,
	preview_alpha: float,
	formation_ratio: float
) -> void:
	SwordArrayBandRenderer.draw_preview(main, player_pos, geometry, state_source, preview_alpha, formation_ratio)


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
