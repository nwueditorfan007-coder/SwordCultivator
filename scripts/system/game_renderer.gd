extends RefCounted
class_name GameRenderer

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
		main.draw_arc(player_pos, main.MARBLE_ABSORB_RANGE, 0.0, TAU, 48, main.COLORS["frozen"], 1.0)

	if main.player["absorbed_ids"].size() > 0:
		_draw_sword_array_preview(main, player_pos)

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
	var mode: String = main.player["array_mode"]
	var preview: Dictionary = SwordArrayController.get_preview_data(main, mode)
	var preview_color := Color(0.0, 1.0, 1.0, 0.3)

	match preview["type"]:
		main.SWORD_ARRAY_RING:
			main.draw_arc(player_pos, preview["radius"], 0.0, TAU, 40, preview_color, 3.0)
			main.draw_arc(player_pos, preview["outer_radius"], 0.0, TAU, 40, Color(0.0, 1.0, 1.0, 0.12), 1.0)
		main.SWORD_ARRAY_FAN:
			main.draw_arc(player_pos, preview["radius"], preview["angle"] - preview["arc"] * 0.5, preview["angle"] + preview["arc"] * 0.5, 32, preview_color, 3.0)
			main.draw_line(player_pos, player_pos + Vector2.RIGHT.rotated(preview["angle"] - preview["arc"] * 0.5) * preview["radius"], Color(0.0, 1.0, 1.0, 0.18), 1.0)
			main.draw_line(player_pos, player_pos + Vector2.RIGHT.rotated(preview["angle"] + preview["arc"] * 0.5) * preview["radius"], Color(0.0, 1.0, 1.0, 0.18), 1.0)
		_:
			var start_pos: Vector2 = main._to_screen(preview["start"])
			var end_pos: Vector2 = main._to_screen(preview["end"])
			var line_dir: Vector2 = (end_pos - start_pos).normalized()
			var side_offset: Vector2 = line_dir.rotated(PI * 0.5) * preview["half_width"]
			main.draw_line(start_pos, end_pos, preview_color, 4.0)
			main.draw_line(start_pos + side_offset, end_pos + side_offset, Color(0.0, 1.0, 1.0, 0.15), 1.0)
			main.draw_line(start_pos - side_offset, end_pos - side_offset, Color(0.0, 1.0, 1.0, 0.15), 1.0)
