extends RefCounted
class_name GameRenderer

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayController = preload("res://scripts/system/sword_array_controller.gd")
const SwordArrayBandRenderer = preload("res://scripts/system/sword_array_band_renderer.gd")

const ARRAY_CHANNEL_CORE_COLOR := Color("f8fafc")
const ARRAY_CHANNEL_EDGE_COLOR := Color("22d3ee")
const ARRAY_CHANNEL_FLARE_COLOR := Color("fb7185")
const TIME_STOP_WASH_COLOR := Color(0.82, 0.9, 1.0, 1.0)
const TIME_STOP_FRAME_COLOR := Color(0.7, 0.9, 1.0, 1.0)
const TIME_STOP_FRAME_CORE_COLOR := Color(0.95, 0.99, 1.0, 1.0)
const UNSHEATH_FLASH_CORE_COLOR := Color(1.0, 0.99, 0.96, 1.0)
const UNSHEATH_FLASH_EDGE_COLOR := Color(0.72, 0.9, 1.0, 1.0)
const UNSHEATH_FLASH_WARM_COLOR := Color(1.0, 0.9, 0.72, 1.0)
# 出鞘闪光主轴相对“御剑方向法线”的偏转角，方便直接手调。
const UNSHEATH_FLASH_AXIS_OFFSET_DEGREES := 90
const UNSHEATH_FLASH_HOTSPOT_OFFSET := 6.0
const UNSHEATH_FLASH_DIRECTIONAL_FRONT_SCALE := 0.3
const UNSHEATH_FLASH_DIRECTIONAL_BACK_SCALE := 0.12
const UNSHEATH_FLASH_TIP_LENGTH_SCALE := 0.18
const UNSHEATH_FLASH_TIP_WIDTH_SCALE := 0.07


static func draw_game(main: Node2D) -> void:
	main.draw_rect(Rect2(Vector2.ZERO, main.get_viewport_rect().size), main._get_time_stop_world_color(main.COLORS["background"]), true)
	main.draw_rect(main.ARENA_RECT, main._get_time_stop_world_color(Color("111111")), true)
	main.draw_rect(main.ARENA_RECT, main._get_time_stop_world_color(Color("2e2e2e")), false, 3.0)

	var shake_offset: Vector2 = Vector2.ZERO
	if main.screen_shake > 0.1:
		shake_offset = Vector2(randf_range(-main.screen_shake, main.screen_shake), randf_range(-main.screen_shake, main.screen_shake))
	main.draw_set_transform(shake_offset, 0.0, Vector2.ONE)
	var time_stop_strength: float = main._get_time_stop_visual_strength()

	var x: int = 0
	while x <= int(main.ARENA_SIZE.x):
		var from: Vector2 = main.ARENA_ORIGIN + Vector2(float(x), 0.0)
		var to: Vector2 = main.ARENA_ORIGIN + Vector2(float(x), main.ARENA_SIZE.y)
		main.draw_line(from, to, main._get_time_stop_world_color(main.COLORS["grid"]), 1.0)
		x += 50

	var y: int = 0
	while y <= int(main.ARENA_SIZE.y):
		var from_y: Vector2 = main.ARENA_ORIGIN + Vector2(0.0, float(y))
		var to_y: Vector2 = main.ARENA_ORIGIN + Vector2(main.ARENA_SIZE.x, float(y))
		main.draw_line(from_y, to_y, main._get_time_stop_world_color(main.COLORS["grid"]), 1.0)
		y += 50

	for particle in main.particles:
		var particle_color: Color = particle["color"]
		if not _is_player_owned_effect_color(main, particle_color):
			particle_color = main._get_time_stop_world_color(particle_color)
		particle_color.a = particle["life"] / particle["max_life"]
		main.draw_circle(main._to_screen(particle["pos"]), particle["size"], particle_color)

	if main._has_boss():
		main._draw_boss()

	for bullet in main.bullets:
		var bullet_pos: Vector2 = main._to_screen(bullet["pos"])
		var bullet_color: Color = bullet["color"]
		var bullet_radius: float = bullet["radius"]
		if bullet["state"] == "deflected":
			bullet_color = main.COLORS["melee_sword"]
			bullet_radius *= 1.15
		else:
			bullet_color = main._get_time_stop_world_color(bullet_color)
			if time_stop_strength > 0.001:
				main.draw_circle(
					bullet_pos,
					bullet_radius + 2.6 + 2.0 * time_stop_strength,
					_with_alpha(TIME_STOP_FRAME_COLOR, 0.05 + 0.12 * time_stop_strength)
				)
		main.draw_circle(bullet_pos, bullet_radius, bullet_color)

	for enemy in main.enemies:
		var color_key: String = enemy["type"]
		var enemy_screen_pos: Vector2 = main._to_screen(enemy["pos"])
		main.draw_circle(enemy_screen_pos, enemy["radius"], main._get_time_stop_world_color(main.COLORS[color_key]))
		if time_stop_strength > 0.001:
			main.draw_arc(
				enemy_screen_pos,
				enemy["radius"] + 3.0 + 1.5 * time_stop_strength,
				0.0,
				TAU,
				24,
				_with_alpha(TIME_STOP_FRAME_COLOR, 0.06 + 0.14 * time_stop_strength),
				1.2 + 1.0 * time_stop_strength
			)
		if enemy["type"] != main.PUPPET:
			var health_ratio: float = max(enemy["health"], 0.0) / enemy["max_health"]
			var bar_pos: Vector2 = enemy_screen_pos + Vector2(-enemy["radius"], -enemy["radius"] - 10.0)
			main.draw_rect(Rect2(bar_pos, Vector2(enemy["radius"] * 2.0, 4.0)), main._get_time_stop_world_color(Color("2f2f2f")), true)
			main.draw_rect(
				Rect2(bar_pos, Vector2(enemy["radius"] * 2.0 * health_ratio, 4.0)),
				main._get_time_stop_world_color(main.COLORS["health"]),
				true
			)
		elif enemy.get("melee_timer", 0.0) > 0.0:
			_draw_puppet_attack_telegraph(main, enemy, enemy_screen_pos)

	_draw_time_stop_wash(main)

	var player_pos: Vector2 = main._to_screen(main.player["pos"])
	main.draw_circle(player_pos, main.PLAYER_RADIUS, main.COLORS["player"])
	var aura_color: Color = main.COLORS["melee_sword"] if main.player["mode"] == main.CombatMode.MELEE else main.COLORS["ranged_sword"]
	var array_channeling: bool = bool(main.player.get("array_is_firing", false))
	if array_channeling:
		aura_color = aura_color.lerp(ARRAY_CHANNEL_EDGE_COLOR, 0.45)
	main.draw_arc(player_pos, main.PLAYER_RADIUS + 5.0, 0.0, TAU, 28, aura_color, 2.0)
	if array_channeling:
		var pulse_radius: float = main.PLAYER_RADIUS + 11.0 + sin(main.elapsed_time * 8.0) * 2.0
		main.draw_arc(
			player_pos,
			pulse_radius,
			0.0,
			TAU,
			32,
			_with_alpha(ARRAY_CHANNEL_EDGE_COLOR, 0.55),
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
		if array_channeling:
			array_sword_color = _get_channeled_array_sword_color(main, array_sword_color)
		var forward: Vector2 = Vector2.RIGHT
		if array_sword["vel"].length_squared() > 1.0:
			forward = array_sword["vel"].normalized()
		elif array_sword["state"] == "ready":
			forward = (array_sword["pos"] - main.player["pos"]).normalized()
			if forward.is_zero_approx():
				forward = Vector2.RIGHT
		var side: Vector2 = forward.rotated(PI * 0.5)
		var sword_length: float = 14.0 if array_channeling else 10.0
		var sword_tail_length: float = 8.0 if array_channeling else 6.0
		var sword_half_width: float = 5.0 if array_channeling else 4.0
		var tip_pos: Vector2 = array_sword_pos + forward * sword_length
		var left_pos: Vector2 = array_sword_pos - forward * sword_tail_length + side * sword_half_width
		var right_pos: Vector2 = array_sword_pos - forward * sword_tail_length - side * sword_half_width
		if array_channeling:
			_draw_channeled_array_sword_trail(main, array_sword, array_sword_pos, forward, side, array_sword_color)
		_try_draw_colored_polygon(main, PackedVector2Array([tip_pos, left_pos, right_pos]), array_sword_color)
		if array_channeling:
			main.draw_line(array_sword_pos - forward * 5.0, tip_pos, _with_alpha(ARRAY_CHANNEL_CORE_COLOR, 0.95), 2.0)
			main.draw_circle(array_sword_pos, 3.0, ARRAY_CHANNEL_CORE_COLOR)
		else:
			main.draw_circle(array_sword_pos, 2.2, Color.WHITE)

	if main.debug_calibration_mode:
		_draw_debug_calibration_overlay(main, player_pos)

	_draw_sword_trail(main)
	_draw_sword_afterimages(main)
	_draw_sword_hit_effects(main)
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

	_draw_unsheath_press_flash(main)
	_draw_unsheath_flash(main)
	main.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_hud_bars(main)


static func _get_channeled_array_sword_color(main: Node2D, base_color: Color) -> Color:
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 12.0)
	var energy_ratio: float = clampf(float(main.player.get("energy", 0.0)) / main.PLAYER_MAX_ENERGY, 0.0, 1.0)
	var color: Color = base_color.lerp(ARRAY_CHANNEL_EDGE_COLOR, 0.62)
	color = color.lerp(ARRAY_CHANNEL_FLARE_COLOR, 0.22 + pulse * 0.16)
	if energy_ratio <= 0.18:
		color = color.lerp(main.COLORS["health"], 0.22 + 0.18 * pulse)
	return color


static func _draw_channeled_array_sword_trail(
	main: Node2D,
	array_sword: Dictionary,
	array_sword_pos: Vector2,
	forward: Vector2,
	side: Vector2,
	array_sword_color: Color
) -> void:
	var state: String = String(array_sword.get("state", "ready"))
	var speed: float = array_sword["vel"].length()
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 16.0 + float(array_sword.get("slot_index", 0)) * 0.8)
	var trail_length: float = 24.0
	if state != "ready":
		trail_length = 42.0 + minf(speed * 0.018, 30.0)
	var tail_end: Vector2 = array_sword_pos - forward * trail_length
	var inner_tail: Vector2 = array_sword_pos - forward * trail_length * 0.58
	var flare_color: Color = ARRAY_CHANNEL_FLARE_COLOR.lerp(array_sword_color, 0.35 + pulse * 0.2)
	var edge_color: Color = ARRAY_CHANNEL_EDGE_COLOR.lerp(array_sword_color, 0.3)

	main.draw_line(tail_end, array_sword_pos - forward * 5.0, _with_alpha(flare_color, 0.18 + pulse * 0.08), 8.0)
	main.draw_line(inner_tail, array_sword_pos - forward * 2.0, _with_alpha(edge_color, 0.42 + pulse * 0.14), 4.0)
	main.draw_line(
		array_sword_pos - forward * trail_length * 0.34 + side * 3.2,
		array_sword_pos + forward * 6.0,
		_with_alpha(ARRAY_CHANNEL_CORE_COLOR, 0.45),
		1.2
	)
	main.draw_line(
		array_sword_pos - forward * trail_length * 0.34 - side * 3.2,
		array_sword_pos + forward * 6.0,
		_with_alpha(ARRAY_CHANNEL_CORE_COLOR, 0.3),
		1.2
	)
	main.draw_circle(array_sword_pos, 10.0 + pulse * 2.0, _with_alpha(edge_color, 0.14))
	var flare_angle: float = forward.angle()
	main.draw_arc(array_sword_pos, 13.0 + pulse * 3.0, flare_angle - 0.8, flare_angle + 0.8, 12, _with_alpha(flare_color, 0.48), 1.6)


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
			main._get_time_stop_world_color(Color(1.0, 0.0, 0.0, 0.55)),
			2.0
		)
		main.draw_arc(
			enemy_screen_pos,
			main.PUPPET_MELEE_RANGE * prep_ratio,
			attack_angle - 0.5,
			attack_angle + 0.5,
			28,
			main._get_time_stop_world_color(Color(1.0, 0.4, 0.4, 0.9)),
			3.0
		)
	elif attack_progress < main.PUPPET_MELEE_PREP_TIME + 0.16:
		main.draw_arc(
			enemy_screen_pos,
			main.PUPPET_MELEE_RANGE,
			attack_angle - 0.8,
			attack_angle + 0.8,
			28,
			main._get_time_stop_world_color(Color(1.0, 0.0, 0.0, 1.0)),
			5.0
		)


static func _draw_time_stop_wash(main: Node2D) -> void:
	var wash_alpha: float = main._get_time_stop_world_wash_alpha()
	var strength: float = main._get_time_stop_visual_strength()
	if wash_alpha <= 0.001 and strength <= 0.001:
		return
	if wash_alpha > 0.001:
		main.draw_rect(
			Rect2(Vector2.ZERO, main.get_viewport_rect().size),
			_with_alpha(TIME_STOP_WASH_COLOR, wash_alpha * 0.36),
			true
		)
	if wash_alpha > 0.001:
		main.draw_rect(main.ARENA_RECT, _with_alpha(TIME_STOP_WASH_COLOR, wash_alpha), true)
	if strength <= 0.001:
		return
	var frame_rect: Rect2 = main.ARENA_RECT.grow(2.0)
	main.draw_rect(
		frame_rect,
		_with_alpha(TIME_STOP_FRAME_COLOR, 0.07 + 0.11 * strength),
		false,
		2.2 + 2.0 * strength
	)
	var inner_rect: Rect2 = main.ARENA_RECT.grow(-(8.0 + 8.0 * strength))
	if inner_rect.size.x > 0.0 and inner_rect.size.y > 0.0:
		main.draw_rect(
			inner_rect,
			_with_alpha(TIME_STOP_FRAME_CORE_COLOR, 0.03 + 0.07 * strength),
			false,
			1.0 + 0.9 * strength
		)
	_draw_time_stop_frame_corners(main, frame_rect, strength)
	_draw_time_stop_focus_field(main, strength)


static func _draw_time_stop_frame_corners(main: Node2D, frame_rect: Rect2, strength: float) -> void:
	var corner_length: float = 20.0 + 24.0 * strength
	var inset: float = 6.0
	var thickness: float = 1.8 + 1.4 * strength
	var left: float = frame_rect.position.x + inset
	var right: float = frame_rect.end.x - inset
	var top: float = frame_rect.position.y + inset
	var bottom: float = frame_rect.end.y - inset
	var corner_color: Color = _with_alpha(TIME_STOP_FRAME_CORE_COLOR, 0.12 + 0.18 * strength)
	main.draw_line(Vector2(left, top), Vector2(left + corner_length, top), corner_color, thickness)
	main.draw_line(Vector2(left, top), Vector2(left, top + corner_length), corner_color, thickness)
	main.draw_line(Vector2(right, top), Vector2(right - corner_length, top), corner_color, thickness)
	main.draw_line(Vector2(right, top), Vector2(right, top + corner_length), corner_color, thickness)
	main.draw_line(Vector2(left, bottom), Vector2(left + corner_length, bottom), corner_color, thickness)
	main.draw_line(Vector2(left, bottom), Vector2(left, bottom - corner_length), corner_color, thickness)
	main.draw_line(Vector2(right, bottom), Vector2(right - corner_length, bottom), corner_color, thickness)
	main.draw_line(Vector2(right, bottom), Vector2(right, bottom - corner_length), corner_color, thickness)


static func _draw_time_stop_focus_field(main: Node2D, strength: float) -> void:
	var center: Vector2 = main._to_screen(main.player["pos"])
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 9.0)
	var inner_radius: float = main.PLAYER_RADIUS + 18.0 + 6.0 * pulse + 10.0 * strength
	var outer_radius: float = main.PLAYER_RADIUS + 34.0 + 14.0 * strength
	main.draw_arc(
		center,
		inner_radius,
		0.0,
		TAU,
		36,
		_with_alpha(TIME_STOP_FRAME_CORE_COLOR, 0.05 + 0.1 * strength),
		1.0 + 0.8 * strength
	)
	main.draw_arc(
		center,
		outer_radius,
		0.0,
		TAU,
		40,
		_with_alpha(TIME_STOP_FRAME_COLOR, 0.04 + 0.08 * strength),
		0.9 + 0.7 * strength
	)
	var ray_gap: float = main.PLAYER_RADIUS + 10.0
	var ray_length: float = 14.0 + 18.0 * strength
	var ray_color: Color = _with_alpha(TIME_STOP_FRAME_COLOR, 0.04 + 0.08 * strength)
	main.draw_line(center + Vector2.RIGHT * ray_gap, center + Vector2.RIGHT * (ray_gap + ray_length), ray_color, 1.0 + 0.6 * strength)
	main.draw_line(center + Vector2.LEFT * ray_gap, center + Vector2.LEFT * (ray_gap + ray_length), ray_color, 1.0 + 0.6 * strength)
	main.draw_line(center + Vector2.UP * ray_gap, center + Vector2.UP * (ray_gap + ray_length), ray_color, 1.0 + 0.6 * strength)
	main.draw_line(center + Vector2.DOWN * ray_gap, center + Vector2.DOWN * (ray_gap + ray_length), ray_color, 1.0 + 0.6 * strength)


static func _draw_sword_afterimages(main: Node2D) -> void:
	var trail_presence_scale: float = 0.62 if main.sword_trail_points.size() >= 3 else 1.0
	for afterimage in main.sword_afterimages:
		var life_ratio: float = clampf(float(afterimage.get("life", 0.0)) / maxf(float(afterimage.get("max_life", 1.0)), 0.001), 0.0, 1.0)
		if life_ratio <= 0.0:
			continue
		var sword_pos: Vector2 = main._to_screen(afterimage["pos"])
		var forward: Vector2 = Vector2.RIGHT.rotated(float(afterimage.get("angle", 0.0)))
		var side: Vector2 = forward.rotated(PI * 0.5)
		var stretch: float = float(afterimage.get("stretch", 1.0))
		var width_scale: float = float(afterimage.get("width_scale", 1.0))
		var ghost_color: Color = Color(afterimage.get("color", main.COLORS["ranged_sword"]))
		var ghost_alpha: float = minf((0.04 + 0.16 * life_ratio) * main.SWORD_AFTERIMAGE_ALPHA_SCALE * trail_presence_scale, 1.0)
		var tip: Vector2 = sword_pos + forward * (main.SWORD_RADIUS * 1.08 * stretch)
		var left: Vector2 = sword_pos - forward * (8.5 * stretch) + side * (7.2 * width_scale)
		var right: Vector2 = sword_pos - forward * (8.5 * stretch) - side * (7.2 * width_scale)
		_try_draw_colored_polygon(main, PackedVector2Array([tip, left, right]), _with_alpha(ghost_color, ghost_alpha))
		main.draw_line(
			sword_pos - forward * (3.0 + 1.5 * stretch),
			tip,
			_with_alpha(Color.WHITE, 0.05 + 0.12 * life_ratio),
			1.0 + 1.2 * life_ratio
		)


static func _draw_sword_trail(main: Node2D) -> void:
	if main.sword_trail_points.size() < 2:
		return
	var outer_color: Color = main.COLORS["ranged_sword"].lerp(UNSHEATH_FLASH_EDGE_COLOR, 0.34)
	var segment_index: int = 1
	while segment_index < main.sword_trail_points.size():
		var older: Dictionary = main.sword_trail_points[segment_index - 1]
		var newer: Dictionary = main.sword_trail_points[segment_index]
		var older_ratio: float = clampf(float(older.get("life", 0.0)) / maxf(float(older.get("max_life", 1.0)), 0.001), 0.0, 1.0)
		var newer_ratio: float = clampf(float(newer.get("life", 0.0)) / maxf(float(newer.get("max_life", 1.0)), 0.001), 0.0, 1.0)
		var alpha_scale: float = 0.5 * (float(older.get("alpha_scale", 1.0)) + float(newer.get("alpha_scale", 1.0)))
		if older_ratio <= 0.0 and newer_ratio <= 0.0:
			segment_index += 1
			continue
		var from_pos: Vector2 = main._to_screen(older["pos"])
		var to_pos: Vector2 = main._to_screen(newer["pos"])
		var segment: Vector2 = to_pos - from_pos
		if segment.length_squared() <= 0.001:
			segment_index += 1
			continue
		var style: String = str(newer.get("style", older.get("style", "slice")))
		var trail_forward: Vector2 = newer.get("forward", segment.normalized())
		if trail_forward.is_zero_approx():
			trail_forward = segment.normalized()
		else:
			trail_forward = trail_forward.normalized()
		var side: Vector2 = segment.normalized().rotated(PI * 0.5)
		var from_half_width: float = float(older.get("half_width", main.SWORD_TRAIL_BASE_HALF_WIDTH)) * older_ratio
		var to_half_width: float = float(newer.get("half_width", main.SWORD_TRAIL_BASE_HALF_WIDTH)) * newer_ratio
		var segment_ratio: float = 0.5 * (older_ratio + newer_ratio)
		if style == "point":
			var point_outer_quad := PackedVector2Array([
				from_pos + side * from_half_width * 0.56,
				from_pos - side * from_half_width * 0.56,
				to_pos - side * to_half_width * 0.46,
				to_pos + side * to_half_width * 0.46,
			])
			var point_core_quad := PackedVector2Array([
				from_pos + side * from_half_width * 0.16,
				from_pos - side * from_half_width * 0.16,
				to_pos - side * to_half_width * 0.14,
				to_pos + side * to_half_width * 0.14,
			])
			_try_draw_colored_polygon(main, point_outer_quad, _with_alpha(outer_color, (0.16 + 0.2 * segment_ratio) * alpha_scale))
			_try_draw_colored_polygon(main, point_core_quad, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, (0.28 + 0.3 * segment_ratio) * alpha_scale))
			main.draw_line(
				from_pos - trail_forward * 1.6,
				to_pos + trail_forward * (6.0 + 8.5 * segment_ratio),
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, (0.22 + 0.28 * segment_ratio) * alpha_scale),
				1.2 + 1.0 * segment_ratio
			)
			main.draw_line(
				from_pos + trail_forward * 2.0,
				to_pos + trail_forward * (2.8 + 4.8 * segment_ratio),
				_with_alpha(UNSHEATH_FLASH_WARM_COLOR, (0.08 + 0.12 * segment_ratio) * alpha_scale),
				0.8 + 0.5 * segment_ratio
			)
		else:
			var blade_bias_from: Vector2 = trail_forward * from_half_width * 0.18
			var blade_bias_to: Vector2 = trail_forward * to_half_width * 0.22
			var slice_outer_quad := PackedVector2Array([
				from_pos + side * from_half_width * 0.68 + blade_bias_from * 0.16,
				from_pos - side * from_half_width * 0.58 - blade_bias_from * 0.34,
				to_pos - side * to_half_width * 0.54 - blade_bias_to * 0.42,
				to_pos + side * to_half_width * 0.64 + blade_bias_to * 0.18,
			])
			var slice_core_quad := PackedVector2Array([
				from_pos + side * from_half_width * 0.18,
				from_pos - side * from_half_width * 0.14 - blade_bias_from * 0.1,
				to_pos - side * to_half_width * 0.14 - blade_bias_to * 0.12,
				to_pos + side * to_half_width * 0.18,
			])
			_try_draw_colored_polygon(main, slice_outer_quad, _with_alpha(outer_color, (0.1 + 0.18 * segment_ratio) * alpha_scale))
			_try_draw_colored_polygon(main, slice_core_quad, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, (0.14 + 0.18 * segment_ratio) * alpha_scale))
			main.draw_line(
				from_pos - side * from_half_width * 0.1,
				to_pos + side * to_half_width * 0.1,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, (0.08 + 0.14 * segment_ratio) * alpha_scale),
				0.9 + 1.0 * segment_ratio
			)
			main.draw_line(
				from_pos + side * from_half_width * 0.34,
				to_pos + side * to_half_width * 0.4 + trail_forward * 3.2,
				_with_alpha(UNSHEATH_FLASH_WARM_COLOR, (0.05 + 0.08 * segment_ratio) * alpha_scale),
				0.8 + 0.7 * segment_ratio
			)
		segment_index += 1
	var head_point: Dictionary = main.sword_trail_points[main.sword_trail_points.size() - 1]
	var head_ratio: float = clampf(float(head_point.get("life", 0.0)) / maxf(float(head_point.get("max_life", 1.0)), 0.001), 0.0, 1.0)
	if head_ratio > 0.0:
		var head_pos: Vector2 = main._to_screen(head_point["pos"])
		var head_forward: Vector2 = head_point.get("forward", Vector2.RIGHT)
		if head_forward.is_zero_approx():
			head_forward = Vector2.RIGHT
		head_forward = head_forward.normalized()
		var head_side: Vector2 = head_forward.rotated(PI * 0.5)
		var head_half_width: float = float(head_point.get("half_width", main.SWORD_TRAIL_BASE_HALF_WIDTH))
		if str(head_point.get("style", "slice")) == "point":
			var spear_tip := PackedVector2Array([
				head_pos + head_forward * (9.0 + 8.0 * head_ratio),
				head_pos - head_forward * 1.6 + head_side * head_half_width * 0.18,
				head_pos - head_forward * 1.6 - head_side * head_half_width * 0.18,
			])
			_try_draw_colored_polygon(main, spear_tip, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.2 + 0.2 * head_ratio))
			main.draw_line(
				head_pos - head_forward * 0.5,
				head_pos + head_forward * (7.0 + 8.0 * head_ratio),
				_with_alpha(UNSHEATH_FLASH_WARM_COLOR, 0.08 + 0.1 * head_ratio),
				0.9 + 0.4 * head_ratio
			)
		else:
			var blade_tip := PackedVector2Array([
				head_pos + head_forward * (6.0 + 6.0 * head_ratio) + head_side * head_half_width * 0.14,
				head_pos - head_forward * 2.0 + head_side * head_half_width * 0.3,
				head_pos - head_forward * 3.0 - head_side * head_half_width * 0.22,
				head_pos + head_forward * 3.0 - head_side * head_half_width * 0.12,
			])
			_try_draw_colored_polygon(main, blade_tip, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.12 + 0.15 * head_ratio))


static func _draw_sword_hit_effects(main: Node2D) -> void:
	for hit_effect in main.sword_hit_effects:
		var life_ratio: float = clampf(float(hit_effect.get("life", 0.0)) / maxf(float(hit_effect.get("max_life", 1.0)), 0.001), 0.0, 1.0)
		if life_ratio <= 0.0:
			continue
		var intensity: float = pow(life_ratio, 1.25)
		var center: Vector2 = main._to_screen(hit_effect["pos"])
		var forward: Vector2 = hit_effect.get("direction", Vector2.RIGHT)
		if forward.is_zero_approx():
			forward = Vector2.RIGHT
		forward = forward.normalized()
		var cut_normal: Vector2 = forward.rotated(PI * 0.5)
		var effect_color: Color = Color(hit_effect.get("color", main.COLORS["ranged_sword"]))
		var style: String = str(hit_effect.get("style", "slice"))
		var cut_half_length: float = float(hit_effect.get("length", main.SWORD_HIT_EFFECT_BASE_LENGTH)) * (0.38 + 0.18 * intensity)
		var cut_width: float = float(hit_effect.get("width", main.SWORD_HIT_EFFECT_BASE_WIDTH)) * (0.62 + 0.34 * intensity)
		var spark_count: int = int(hit_effect.get("spark_count", main.SWORD_HIT_EFFECT_SPARK_COUNT))
		var seed: float = float(hit_effect.get("seed", 0.0))
		if style == "point":
			main.draw_line(
				center - forward * cut_half_length * 0.16,
				center + forward * cut_half_length * 0.9,
				_with_alpha(effect_color.lerp(UNSHEATH_FLASH_WARM_COLOR, 0.18), 0.12 + 0.18 * intensity),
				maxf(cut_width * 0.72, 1.0)
			)
			main.draw_line(
				center - forward * cut_half_length * 0.06,
				center + forward * cut_half_length * 0.62,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.24 + 0.28 * intensity),
				1.0 + cut_width * 0.12
			)
			main.draw_line(
				center - cut_normal * cut_width * 0.72,
				center + cut_normal * cut_width * 0.72,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.12 + 0.16 * intensity),
				0.9 + 0.45 * intensity
			)
		else:
			var slash_axis: Vector2 = forward
			var slash_body := PackedVector2Array([
				center - slash_axis * cut_half_length * 0.82 + cut_normal * cut_width * 0.34,
				center - slash_axis * cut_half_length * 0.82 - cut_normal * cut_width * 0.22,
				center + slash_axis * cut_half_length * 0.96 - cut_normal * cut_width * 0.18,
				center + slash_axis * cut_half_length * 0.96 + cut_normal * cut_width * 0.26,
			])
			_try_draw_colored_polygon(main, slash_body, _with_alpha(effect_color.lerp(UNSHEATH_FLASH_WARM_COLOR, 0.3), 0.14 + 0.2 * intensity))
			main.draw_line(
				center - slash_axis * cut_half_length * 0.72,
				center + slash_axis * cut_half_length * 0.82,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.24 + 0.28 * intensity),
				maxf(cut_width * 0.22, 1.0)
			)
			main.draw_line(
				center - slash_axis * cut_half_length * 0.48 + cut_normal * cut_width * 0.22,
				center + slash_axis * cut_half_length * 0.62 + cut_normal * cut_width * 0.14,
				_with_alpha(UNSHEATH_FLASH_WARM_COLOR, 0.1 + 0.14 * intensity),
				maxf(cut_width * 0.1, 0.8)
			)
		var spark_index: int = 0
		while spark_index < spark_count:
			var spark_ratio: float = 0.5 if spark_count <= 1 else float(spark_index) / float(spark_count - 1)
			var spread: float = lerpf(-0.22, 0.22, spark_ratio) + sin(seed + float(spark_index) * 1.9) * 0.05
			var spark_dir: Vector2 = forward.rotated(spread)
			var spark_start: Vector2 = center
			if style == "slice":
				spark_dir = forward.rotated(lerpf(-0.16, 0.14, spark_ratio) + sin(seed + float(spark_index) * 1.3) * 0.04)
				spark_start = center + forward * lerpf(-cut_half_length * 0.24, cut_half_length * 0.24, spark_ratio) + cut_normal * sin(seed + float(spark_index) * 2.1) * cut_width * 0.08
			else:
				spark_start = center + forward * lerpf(cut_half_length * 0.08, cut_half_length * 0.42, spark_ratio)
			var spark_length: float = cut_half_length * (0.54 + 0.18 * spark_ratio) * (0.66 + 0.24 * intensity)
			main.draw_line(
				spark_start,
				spark_start + spark_dir * spark_length,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.1 + 0.18 * intensity),
				0.9 + 0.7 * intensity
			)
			spark_index += 1


static func _draw_unsheath_press_flash(main: Node2D) -> void:
	var remaining: float = main._get_unsheath_press_flash_progress()
	if remaining <= 0.0:
		return
	var intensity: float = pow(remaining, 1.85)
	var strength_scale: float = main.UNSHEATH_PRESS_FLASH_STRENGTH * maxf(main.unsheath_press_flash_strength, 0.0)
	if strength_scale <= 0.001:
		return
	var center: Vector2 = main._to_screen(main.unsheath_press_flash_origin)
	var forward: Vector2 = main.unsheath_press_flash_direction
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var streak_axis: Vector2 = _get_unsheath_streak_axis(forward)
	var half_length: float = (12.0 + 18.0 * intensity) * strength_scale
	var forward_length: float = (5.0 + 10.0 * intensity) * strength_scale
	main.draw_line(
		center - streak_axis * half_length,
		center + streak_axis * half_length,
		_with_alpha(UNSHEATH_FLASH_WARM_COLOR, minf((0.12 + 0.18 * intensity) * strength_scale, 1.0)),
		(2.6 + 2.2 * intensity) * strength_scale
	)
	main.draw_line(
		center - forward * forward_length * 0.2,
		center + forward * forward_length,
		_with_alpha(UNSHEATH_FLASH_CORE_COLOR, minf((0.14 + 0.16 * intensity) * strength_scale, 1.0)),
		(1.0 + 1.0 * intensity) * strength_scale
	)
	main.draw_circle(
		center,
		(2.6 + 3.8 * intensity) * strength_scale,
		_with_alpha(UNSHEATH_FLASH_CORE_COLOR, minf((0.14 + 0.18 * intensity) * strength_scale, 1.0))
	)


static func _draw_unsheath_flash(main: Node2D) -> void:
	var remaining: float = main._get_unsheath_flash_progress()
	if remaining <= 0.0:
		return
	var strength_scale: float = maxf(main.unsheath_flash_strength, 0.0)
	if strength_scale <= 0.001:
		return
	var intensity: float = pow(remaining, 1.6)
	var length_scale: float = main.UNSHEATH_FLASH_LENGTH_SCALE * strength_scale
	var width_scale: float = main.UNSHEATH_FLASH_WIDTH_SCALE * (0.72 + 0.28 * strength_scale)
	var center: Vector2 = main._to_screen(main.unsheath_flash_origin)
	var forward: Vector2 = main.unsheath_flash_direction
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var major_axis: Vector2 = _get_unsheath_streak_axis(forward)
	var hotspot: Vector2 = center + forward * UNSHEATH_FLASH_HOTSPOT_OFFSET * width_scale
	var half_length: float = lerpf(96.0, 178.0, intensity) * length_scale
	var band_half_width: float = (5.2 + 7.8 * intensity) * width_scale
	var directional_front: float = half_length * UNSHEATH_FLASH_DIRECTIONAL_FRONT_SCALE
	var directional_back: float = half_length * UNSHEATH_FLASH_DIRECTIONAL_BACK_SCALE
	var tip_length: float = half_length * UNSHEATH_FLASH_TIP_LENGTH_SCALE
	var tip_half_width: float = half_length * UNSHEATH_FLASH_TIP_WIDTH_SCALE * width_scale
	var outer_band := PackedVector2Array([
		hotspot - major_axis * half_length - forward * band_half_width * 0.32,
		hotspot - major_axis * half_length * 0.18 + forward * band_half_width * 0.82,
		hotspot + major_axis * half_length + forward * band_half_width * 0.44,
		hotspot + major_axis * half_length * 0.24 - forward * band_half_width * 0.7,
	])
	_try_draw_colored_polygon(main, outer_band, _with_alpha(UNSHEATH_FLASH_WARM_COLOR, (0.1 + 0.16 * intensity) * strength_scale))
	var core_band := PackedVector2Array([
		hotspot - major_axis * half_length * 0.84 - forward * band_half_width * 0.12,
		hotspot - major_axis * half_length * 0.12 + forward * band_half_width * 0.34,
		hotspot + major_axis * half_length * 0.84 + forward * band_half_width * 0.22,
		hotspot + major_axis * half_length * 0.12 - forward * band_half_width * 0.28,
	])
	_try_draw_colored_polygon(main, core_band, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, (0.16 + 0.24 * intensity) * strength_scale))
	main.draw_line(
		hotspot - major_axis * half_length * 0.98 - forward * band_half_width * 0.08,
		hotspot + major_axis * half_length * 0.98 + forward * band_half_width * 0.12,
		_with_alpha(UNSHEATH_FLASH_WARM_COLOR, (0.16 + 0.22 * intensity) * strength_scale),
		(5.4 + 7.2 * intensity) * width_scale
	)
	main.draw_line(
		hotspot - major_axis * half_length * 0.86 - forward * band_half_width * 0.02,
		hotspot + major_axis * half_length * 0.88 + forward * band_half_width * 0.08,
		_with_alpha(UNSHEATH_FLASH_CORE_COLOR, (0.34 + 0.34 * intensity) * strength_scale),
		(1.8 + 2.4 * intensity) * width_scale
	)
	main.draw_line(
		hotspot - forward * directional_back,
		hotspot + forward * directional_front,
		_with_alpha(UNSHEATH_FLASH_EDGE_COLOR, (0.14 + 0.16 * intensity) * strength_scale),
		(1.0 + 1.2 * intensity) * width_scale
	)
	main.draw_line(
		hotspot - forward * directional_back * 0.45,
		hotspot + forward * directional_front * 0.74,
		_with_alpha(UNSHEATH_FLASH_CORE_COLOR, (0.12 + 0.14 * intensity) * strength_scale),
		(0.9 + 0.9 * intensity) * width_scale
	)
	var tip_base_center: Vector2 = hotspot + forward * directional_front * 0.56
	var tip_point: Vector2 = hotspot + forward * (directional_front + tip_length)
	var tip_triangle := PackedVector2Array([
		tip_base_center + major_axis * tip_half_width,
		tip_point,
		tip_base_center - major_axis * tip_half_width,
	])
	_try_draw_colored_polygon(main, tip_triangle, _with_alpha(UNSHEATH_FLASH_WARM_COLOR, (0.12 + 0.16 * intensity) * strength_scale))
	var tip_core := PackedVector2Array([
		tip_base_center + major_axis * tip_half_width * 0.48,
		hotspot + forward * (directional_front + tip_length * 0.72),
		tip_base_center - major_axis * tip_half_width * 0.48,
	])
	_try_draw_colored_polygon(main, tip_core, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, (0.16 + 0.18 * intensity) * strength_scale))
	main.draw_circle(
		hotspot,
		(4.2 + 5.4 * intensity) * width_scale,
		_with_alpha(UNSHEATH_FLASH_CORE_COLOR, (0.1 + 0.15 * intensity) * strength_scale)
	)


static func _get_unsheath_streak_axis(forward: Vector2) -> Vector2:
	var streak_axis: Vector2 = forward.rotated(PI * 0.5 + deg_to_rad(UNSHEATH_FLASH_AXIS_OFFSET_DEGREES))
	if streak_axis.is_zero_approx():
		streak_axis = Vector2.RIGHT
	return streak_axis.normalized()


static func _is_player_owned_effect_color(main: Node2D, color: Color) -> bool:
	return (
		_color_matches(color, main.COLORS["player"])
		or _color_matches(color, main.COLORS["melee_sword"])
		or _color_matches(color, main.COLORS["ranged_sword"])
		or _color_matches(color, main.COLORS["array_sword"])
		or _color_matches(color, main.COLORS["array_sword_return"])
		or _color_matches(color, main.COLORS["energy"])
	)


static func draw_hud_bars(main: Node2D) -> void:
	var health_bar_rect: Rect2 = Rect2(Vector2(28.0, 24.0), Vector2(260.0, 18.0))
	var energy_bar_rect: Rect2 = Rect2(Vector2(28.0, 52.0), Vector2(260.0, 12.0))
	main.draw_rect(health_bar_rect, Color("1d1d1d"), true)
	main.draw_rect(Rect2(health_bar_rect.position, Vector2(health_bar_rect.size.x * (main.player["health"] / main.PLAYER_MAX_HEALTH), health_bar_rect.size.y)), main.COLORS["health"], true)
	main.draw_rect(energy_bar_rect, Color("1d1d1d"), true)
	var energy_fill_color: Color = main.COLORS["energy"]
	if bool(main.player.get("array_is_firing", false)):
		energy_fill_color = energy_fill_color.lerp(ARRAY_CHANNEL_EDGE_COLOR, 0.35)
		main.draw_rect(
			Rect2(energy_bar_rect.position - Vector2(2.0, 2.0), energy_bar_rect.size + Vector2(4.0, 4.0)),
			_with_alpha(ARRAY_CHANNEL_EDGE_COLOR, 0.18),
			false,
			2.0
		)
		_draw_array_channel_flames(main, energy_bar_rect)
	main.draw_rect(Rect2(energy_bar_rect.position, Vector2(energy_bar_rect.size.x * (main.player["energy"] / main.PLAYER_MAX_ENERGY), energy_bar_rect.size.y)), energy_fill_color, true)


static func _draw_array_channel_flames(main: Node2D, energy_bar_rect: Rect2) -> void:
	var flame_count: int = 8
	var flame_index: int = 0
	while flame_index < flame_count:
		var x_ratio: float = float(flame_index) / float(maxi(flame_count - 1, 1))
		var base_x: float = energy_bar_rect.position.x + x_ratio * energy_bar_rect.size.x
		var sway: float = sin(main.elapsed_time * 8.0 + float(flame_index) * 0.9) * 3.0
		var flame_height: float = 7.0 + absf(sin(main.elapsed_time * 10.5 + float(flame_index) * 1.2)) * 7.0
		var flame_color: Color = ARRAY_CHANNEL_EDGE_COLOR.lerp(main.COLORS["energy"], 0.35)
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


static func _with_alpha(color: Color, alpha: float) -> Color:
	var result: Color = color
	result.a = alpha
	return result


static func _color_matches(lhs: Color, rhs: Color) -> bool:
	return (
		absf(lhs.r - rhs.r) <= 0.002
		and absf(lhs.g - rhs.g) <= 0.002
		and absf(lhs.b - rhs.b) <= 0.002
		and absf(lhs.a - rhs.a) <= 0.002
	)


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
