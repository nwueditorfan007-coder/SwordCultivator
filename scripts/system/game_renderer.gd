extends RefCounted
class_name GameRenderer

const SwordArrayConfig = preload("res://scripts/system/sword_array_config.gd")
const SwordArrayController = preload("res://scripts/system/sword_array_controller.gd")
const SwordArrayBandRenderer = preload("res://scripts/system/sword_array_band_renderer.gd")
const SwordResonanceController = preload("res://scripts/system/sword_resonance_controller.gd")

const ARRAY_CHANNEL_CORE_COLOR := Color("f8fafc")
const ARRAY_CHANNEL_EDGE_COLOR := Color("22d3ee")
const ARRAY_CHANNEL_FLARE_COLOR := Color("fb7185")
const UNSHEATH_FLASH_CORE_COLOR := Color(1.0, 0.99, 0.96, 1.0)
const UNSHEATH_FLASH_EDGE_COLOR := Color(0.72, 0.9, 1.0, 1.0)
const UNSHEATH_FLASH_WARM_COLOR := Color(1.0, 0.9, 0.72, 1.0)
const ARRAY_MODE_CONFIRM_COLOR := Color(0.96, 0.99, 1.0, 1.0)
# 出鞘闪光主轴相对“御剑方向法线”的偏转角，方便直接手调。
const UNSHEATH_FLASH_AXIS_OFFSET_DEGREES := 90
const UNSHEATH_FLASH_HOTSPOT_OFFSET := 6.0
const UNSHEATH_FLASH_DIRECTIONAL_FRONT_SCALE := 0.3
const UNSHEATH_FLASH_DIRECTIONAL_BACK_SCALE := 0.12
const UNSHEATH_FLASH_TIP_LENGTH_SCALE := 0.18
const UNSHEATH_FLASH_TIP_WIDTH_SCALE := 0.07
const BULLET_EDGE_SHADE := 0.24
const BULLET_CORE_HIGHLIGHT := 0.28
const BULLET_SPECULAR_HIGHLIGHT := 0.52
const BULLET_RENDER_SCALE := 1.24
const ART_BG_DEEP := Color("010409")
const ART_BG := Color("05101a")
const ART_ARENA := Color("07101a")
const ART_ARENA_CORE := Color("0a1622")
const ART_GRID := Color(0.42, 0.72, 0.9, 0.038)
const ART_GOLD := Color("d7bb79")
const ART_BLUE := Color("88d8ff")
const ART_BLUE_CORE := Color("f6fbff")
const ART_RED := Color("df5b66")


static func draw_game(main: Node2D) -> void:
	_draw_art_background(main)

	var shake_offset: Vector2 = Vector2.ZERO
	if main.screen_shake > 0.1:
		shake_offset = Vector2(randf_range(-main.screen_shake, main.screen_shake), randf_range(-main.screen_shake, main.screen_shake))
	main.draw_set_transform(shake_offset, 0.0, Vector2.ONE)
	_draw_art_tactical_grid(main)
	if main.time_rift_fx != null and main.time_rift_fx.has_method("draw_background_effect"):
		main.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		main.time_rift_fx.draw_background_effect(main)
		main.draw_set_transform(shake_offset, 0.0, Vector2.ONE)

	for particle in main.particles:
		var particle_color: Color = particle["color"]
		particle_color.a = particle["life"] / particle["max_life"]
		main.draw_circle(main._to_screen(particle["pos"]), particle["size"], particle_color)

	if main._has_boss():
		main._draw_boss_world()

	for bullet in main.bullets:
		var bullet_pos: Vector2 = main._to_screen(bullet["pos"])
		var bullet_color: Color = bullet["color"]
		var bullet_radius: float = bullet["radius"] * BULLET_RENDER_SCALE
		var bullet_family: String = str(bullet.get("family", main.BULLET_FAMILY_NEEDLE))
		if bullet["state"] == "deflected":
			bullet_color = main.COLORS["melee_sword"]
			bullet_radius *= 1.15
		_draw_bullet_shape(
			main,
			bullet_pos,
			Vector2(bullet.get("vel", Vector2.RIGHT)),
			bullet_radius,
			bullet_color,
			bullet_family,
			bullet["state"] == "deflected"
		)

	for enemy in main.enemies:
		if str(enemy.get("type", "")) != main.DRAPE_PRIEST:
			continue
		var target_id: String = str(enemy.get("support_target_id", ""))
		if target_id == "":
			continue
		var target: Variant = main._find_enemy_by_id(target_id)
		if target == null or bool(target.get("is_dying", false)):
			continue
		var link_pulse: float = 0.72 + 0.28 * absf(sin(main.elapsed_time * 6.0))
		var link_color: Color = _with_alpha(main.COLORS["silk"].lerp(main.COLORS["drape_priest"], 0.18), 0.28 + 0.2 * link_pulse)
		var link_from: Vector2 = main._to_screen(Vector2(enemy.get("pos", Vector2.ZERO)) + Vector2(enemy.get("hit_reaction_offset", Vector2.ZERO)))
		var link_to: Vector2 = main._to_screen(Vector2(target.get("pos", Vector2.ZERO)) + Vector2(target.get("hit_reaction_offset", Vector2.ZERO)))
		main.draw_line(link_from, link_to, link_color, 3.6)

	for enemy in main.enemies:
		var color_key: String = enemy["type"]
		var enemy_flash_ratio: float = clampf(float(enemy.get("hit_flash_timer", 0.0)) / maxf(main.ENEMY_HIT_FLASH_DURATION, 0.001), 0.0, 1.0)
		var is_enemy_dying: bool = bool(enemy.get("is_dying", false))
		var enemy_death_ratio: float = clampf(float(enemy.get("death_feedback_timer", 0.0)) / maxf(main.ENEMY_DEATH_FEEDBACK_DURATION, 0.001), 0.0, 1.0)
		var enemy_death_progress: float = 1.0 - enemy_death_ratio
		var enemy_world_pos: Vector2 = enemy["pos"] + Vector2(enemy.get("hit_reaction_offset", Vector2.ZERO))
		var enemy_screen_pos: Vector2 = main._to_screen(enemy_world_pos)
		var enemy_color: Color = main.COLORS[color_key]
		var enemy_radius: float = float(enemy["radius"])
		var enemy_alpha: float = 1.0
		if is_enemy_dying:
			enemy_radius *= lerpf(1.08, 0.62, enemy_death_progress)
			enemy_alpha = 1.0 - pow(enemy_death_progress, 1.35)
			enemy_flash_ratio = maxf(enemy_flash_ratio, 0.42 + 0.58 * enemy_death_ratio)
		if enemy_flash_ratio > 0.0:
			var enemy_flash_color: Color = Color(enemy.get("hit_flash_color", Color.WHITE))
			enemy_color = enemy_color.lerp(enemy_flash_color, 0.4 + 0.46 * enemy_flash_ratio)
		if is_enemy_dying:
			var death_feedback_color: Color = Color(enemy.get("death_feedback_color", enemy.get("hit_flash_color", Color.WHITE)))
			enemy_color = enemy_color.lerp(death_feedback_color, 0.3 + 0.52 * enemy_death_ratio)
		enemy_color.a *= enemy_alpha
		_draw_enemy_sigil(
			main,
			enemy_screen_pos,
			enemy_radius,
			enemy_color,
			color_key,
			enemy_alpha,
			is_enemy_dying
		)
		if not is_enemy_dying and str(enemy.get("support_source_id", "")) != "":
			var support_pulse: float = 0.72 + 0.28 * absf(sin(main.elapsed_time * 8.0))
			var support_color: Color = _with_alpha(main.COLORS["silk"].lerp(main.COLORS["drape_priest"], 0.18), (0.24 + 0.18 * support_pulse) * enemy_alpha)
			main.draw_arc(
				enemy_screen_pos,
				enemy_radius + 5.8,
				0.0,
				TAU,
				22,
				support_color,
				2.2
			)
		if color_key == main.RING_LEECH:
			var leech_to_player: Vector2 = Vector2(main.player.get("pos", Vector2.ZERO)) - Vector2(enemy.get("pos", Vector2.ZERO))
			if leech_to_player.length() <= main.RING_LEECH_FIRE_DISTANCE + 12.0:
				var leech_dir: Vector2 = leech_to_player.normalized()
				if leech_dir.is_zero_approx():
					leech_dir = Vector2.RIGHT
				var fang_color: Color = _with_alpha(main.COLORS["ring_leech"], 0.28 * enemy_alpha)
				var fang_left: Vector2 = enemy_screen_pos + leech_dir.rotated(0.55) * (enemy_radius + 1.0)
				var fang_right: Vector2 = enemy_screen_pos + leech_dir.rotated(-0.55) * (enemy_radius + 1.0)
				var fang_tip: Vector2 = enemy_screen_pos + leech_dir * (enemy_radius + 8.0)
				main.draw_line(fang_left, fang_tip, fang_color, 1.8)
				main.draw_line(fang_right, fang_tip, fang_color, 1.8)
		if color_key == main.MIRROR_NEEDLER:
			var vulnerable_ratio: float = clampf(float(enemy.get("mirror_vulnerable_timer", 0.0)) / maxf(main.MIRROR_NEEDLER_VULNERABLE_DURATION, 0.001), 0.0, 1.0)
			var charge_timer: float = float(enemy.get("charge_timer", 0.0))
			var charge_progress: float = 1.0 - clampf(charge_timer / maxf(main.MIRROR_NEEDLER_CHARGE_DURATION, 0.001), 0.0, 1.0)
			if vulnerable_ratio > 0.0:
				var break_color: Color = _with_alpha(main.COLORS["melee_sword"], (0.18 + 0.18 * vulnerable_ratio) * enemy_alpha)
				main.draw_arc(
					enemy_screen_pos,
					enemy_radius + 5.2 + 1.6 * vulnerable_ratio,
					0.0,
					TAU,
					24,
					break_color,
					2.0
				)
			else:
				var shell_color: Color = _with_alpha(Color.WHITE, 0.3 * enemy_alpha)
				main.draw_arc(
					enemy_screen_pos,
					enemy_radius + 4.8,
					0.0,
					TAU,
					24,
					shell_color,
					2.0
				)
			if charge_timer > 0.0:
				var charge_color: Color = _with_alpha(main.COLORS["melee_sword"], (0.22 + 0.3 * charge_progress) * enemy_alpha)
				var charge_angle: float = PI * (0.4 + 0.45 * charge_progress)
				main.draw_arc(
					enemy_screen_pos,
					enemy_radius + 8.5 - 2.0 * charge_progress,
					- charge_angle,
					charge_angle,
					18,
					charge_color,
					2.1
				)
		if enemy_flash_ratio > 0.0:
			main.draw_circle(
				enemy_screen_pos,
				enemy_radius + 1.5 + 2.0 * enemy_flash_ratio,
				_with_alpha(Color.WHITE, (0.08 + 0.16 * enemy_flash_ratio) * enemy_alpha)
			)
		if enemy_flash_ratio > 0.0:
			var enemy_ring_color: Color = Color(enemy.get("hit_flash_color", Color.WHITE))
			enemy_ring_color.a = (0.2 + 0.26 * enemy_flash_ratio) * enemy_alpha
			main.draw_arc(
				enemy_screen_pos,
				enemy_radius + 6.0 + 7.0 * enemy_flash_ratio,
				0.0,
				TAU,
				24,
				enemy_ring_color,
				1.4 + 1.8 * enemy_flash_ratio
			)
		if is_enemy_dying:
			var death_ring_color: Color = Color(enemy.get("death_feedback_color", enemy.get("hit_flash_color", Color.WHITE)))
			death_ring_color.a = (0.14 + 0.22 * enemy_death_ratio) * enemy_alpha
			main.draw_arc(
				enemy_screen_pos,
				enemy_radius + 8.0 + 12.0 * enemy_death_progress,
				0.0,
				TAU,
				24,
				death_ring_color,
				1.6 + 1.8 * enemy_death_ratio
			)
		if not is_enemy_dying and enemy["type"] != main.PUPPET:
			var health_ratio: float = max(enemy["health"], 0.0) / enemy["max_health"]
			var bar_pos: Vector2 = enemy_screen_pos + Vector2(-enemy_radius, -enemy_radius - 10.0)
			main.draw_rect(Rect2(bar_pos, Vector2(enemy_radius * 2.0, 4.0)), Color("2f2f2f"), true)
			main.draw_rect(
				Rect2(bar_pos, Vector2(enemy_radius * 2.0 * health_ratio, 4.0)),
				main.COLORS["health"],
				true
			)
		elif not is_enemy_dying and enemy.get("melee_timer", 0.0) > 0.0:
			_draw_puppet_attack_telegraph(main, enemy, enemy_screen_pos)

	var player_pos: Vector2 = main._to_screen(main.player["pos"])
	var distance_guide_strength: float = main._get_array_distance_guide_strength()
	if distance_guide_strength > 0.01:
		_draw_array_distance_guides(main, player_pos, distance_guide_strength)
	main.draw_circle(player_pos, main.PLAYER_RADIUS, main.COLORS["player"])
	var aura_color: Color = main.COLORS["melee_sword"] if main.player["mode"] == main.CombatMode.MELEE else main.COLORS["ranged_sword"]
	var array_channeling: bool = bool(main.player.get("array_is_firing", false))
	var array_hold_ratio: float = clampf(float(main.player.get("array_hold_ratio", 0.0)), 0.0, 1.0)
	var array_priming: bool = not array_channeling and array_hold_ratio > 0.02
	var array_warning_strength: float = main._get_array_energy_warning_strength()
	var array_break_strength: float = main._get_array_energy_break_strength()
	var array_warning_level: int = int(main.array_energy_forecast_level)
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
	_draw_resonance_player_mark(main, player_pos)
	if array_warning_strength > 0.01:
		var warning_pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 11.0)
		var warning_color: Color = main.COLORS["energy"]
		if array_warning_level >= 2 or array_break_strength > 0.0:
			warning_color = main.COLORS["health"].lerp(main.COLORS["energy"], 0.18)
		var warning_radius: float = main.PLAYER_RADIUS + 14.0 + warning_pulse * 4.0
		main.draw_arc(
			player_pos,
			warning_radius,
			0.0,
			TAU,
			36,
			_with_alpha(warning_color, (0.18 + 0.34 * warning_pulse) * array_warning_strength),
			2.0 + 1.3 * array_warning_strength
		)
	if array_break_strength > 0.0:
		var break_radius: float = main.PLAYER_RADIUS + 12.0 + (1.0 - array_break_strength) * 18.0
		var break_color: Color = main.COLORS["health"].lerp(ARRAY_CHANNEL_CORE_COLOR, 0.2)
		main.draw_arc(
			player_pos,
			break_radius,
			0.0,
			TAU,
			32,
			_with_alpha(break_color, 0.2 + 0.45 * array_break_strength),
			2.4 + 1.6 * array_break_strength
		)
		main.draw_circle(
			player_pos,
			main.PLAYER_RADIUS + 3.0 + array_break_strength * 5.0,
			_with_alpha(break_color, 0.05 + 0.08 * array_break_strength)
		)
	_draw_energy_gain_pulse(main, player_pos)
	_draw_sword_recall_gate(main, player_pos)
	_draw_sword_return_catches(main)

	_draw_array_mode_confirm(main, player_pos)
	var mode_hint_strength: float = array_hold_ratio * 0.58
	if array_channeling:
		mode_hint_strength = maxf(mode_hint_strength, 0.48)
	if mode_hint_strength > 0.01:
		_draw_current_array_mode_hint(main, player_pos, mode_hint_strength)

	if not array_channeling:
		_draw_ambient_array_presence(main, player_pos, array_hold_ratio)

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
			if array_channeling:
				ghost_color.a = 0.18
				main.draw_circle(empty_slot_pos, 3.0, ghost_color)
				main.draw_arc(empty_slot_pos, 7.0, 0.0, TAU, 18, ghost_color, 1.2)
			elif array_priming:
				var priming_ghost_alpha: float = 0.06 + 0.12 * array_hold_ratio
				main.draw_circle(empty_slot_pos, 2.2, _with_alpha(ghost_color, priming_ghost_alpha))
				main.draw_arc(empty_slot_pos, 5.0 + 1.5 * array_hold_ratio, 0.0, TAU, 16, _with_alpha(ghost_color, priming_ghost_alpha * 1.25), 1.0)
			else:
				main.draw_circle(empty_slot_pos, 1.6, _with_alpha(ghost_color, 0.08))
		slot_index += 1

	var resonance_mode: String = main._get_resonance_mode()
	var resonance_strength: float = main._get_resonance_strength()
	var resonance_preview_strength: float = main._get_resonance_preview_strength()
	var resonance_color: Color = main._get_resonance_color(resonance_mode)
	var resonance_sword_mark_strength: float = clampf(resonance_strength * 0.42 + resonance_preview_strength * 0.76, 0.0, 1.0)
	_draw_resonance_array_field(main, player_pos, resonance_mode, resonance_color, resonance_strength, resonance_preview_strength)
	for array_sword in main.array_swords:
		var array_sword_pos: Vector2 = main._to_screen(array_sword["pos"])
		var array_sword_color: Color = SwordArrayController.get_accent_color(main._get_sword_array_morph_state())
		if array_sword["state"] == "returning":
			array_sword_color = main.COLORS["array_sword_return"]
		elif array_sword["state"] == "outbound":
			array_sword_color = main.COLORS["array_sword"]
		if array_channeling:
			array_sword_color = _get_channeled_array_sword_color(main, array_sword_color)
		if resonance_sword_mark_strength > 0.01:
			array_sword_color = array_sword_color.lerp(resonance_color, clampf(resonance_sword_mark_strength * 0.55, 0.0, 0.68))
		var array_combo_id: String = String(array_sword.get("combo_id", ""))
		var array_combo_strength: float = _get_combo_strength(array_sword)
		if array_combo_id == SwordResonanceController.COMBO_RING_TO_PIERCE and array_combo_strength > 0.01:
			array_sword_color = array_sword_color.lerp(SwordResonanceController.get_color(SwordArrayConfig.MODE_RING), 0.34 * array_combo_strength)
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
		var array_sword_state: String = String(array_sword.get("state", "ready"))
		if array_channeling or array_sword_state == "returning":
			_draw_channeled_array_sword_trail(main, array_sword, array_sword_pos, forward, side, array_sword_color)
		if array_sword_state == "ready" and not array_channeling:
			if array_priming:
				_draw_ready_array_sword_primed(main, array_sword_pos, tip_pos, left_pos, right_pos, array_sword_color, array_hold_ratio)
			else:
				_draw_ready_array_sword_idle(main, array_sword_pos, tip_pos, left_pos, right_pos, array_sword_color)
			if resonance_sword_mark_strength > 0.01:
				_draw_resonance_sword_mark(main, array_sword_pos, forward, side, resonance_mode, resonance_color, resonance_sword_mark_strength * 0.78)
			continue
		var array_sword_focus_strength: float = 0.16 if array_channeling else 0.03
		var sword_scale: float = 0.94 if array_channeling else 0.88
		var array_local_glow_strength: float = 0.0
		var array_glow_style: String = "idle"
		var sword_vfx = _get_sword_vfx(main)
		if array_sword_state == "returning":
			array_sword_focus_strength = maxf(array_sword_focus_strength, 0.12)
			sword_scale = 1.02
			array_local_glow_strength = float(sword_vfx.local_glow_array_recall)
			array_glow_style = "recall"
		elif array_sword_state == "outbound":
			array_local_glow_strength = float(sword_vfx.local_glow_array_outbound)
			array_glow_style = "point"
		elif array_channeling:
			array_local_glow_strength = float(sword_vfx.local_glow_array_channel_base) + float(sword_vfx.local_glow_array_channel_hold_scale) * array_hold_ratio
			array_glow_style = "slice"
		_draw_sword_body(main, array_sword_pos, forward, array_sword_color, sword_scale, array_sword_focus_strength, array_local_glow_strength, array_glow_style)
		if array_combo_id == SwordResonanceController.COMBO_RING_TO_PIERCE and array_combo_strength > 0.01:
			_draw_ring_to_pierce_array_combo(main, array_sword_pos, forward, array_combo_strength)
		if resonance_sword_mark_strength > 0.01:
			_draw_resonance_sword_mark(main, array_sword_pos, forward, side, resonance_mode, resonance_color, resonance_sword_mark_strength)

	if main.debug_calibration_mode:
		_draw_debug_calibration_overlay(main, player_pos)

	_draw_sword_air_wakes(main)
	_draw_sword_trail(main)
	_draw_sword_afterimages(main)
	_draw_sword_hit_effects(main)
	var use_node_main_sword_vfx: bool = _use_node_sword_flight_vfx(main)
	var sword_impact_ratio: float = clampf(
		float(main.sword.get("impact_feedback_timer", 0.0)) / maxf(main.SWORD_IMPACT_FEEDBACK_DURATION, 0.001),
		0.0,
		1.0
	)
	var sword_base_pos: Vector2 = main._to_screen(main.sword["pos"])
	var sword_visual_pos: Vector2 = main._get_sword_visual_position()
	var sword_pos: Vector2 = main._to_screen(sword_visual_pos)
	var sword_color: Color = main.COLORS["melee_sword"] if main.player["mode"] == main.CombatMode.MELEE else main.COLORS["ranged_sword"]
	var sword_angle: float = main._get_sword_visual_angle()
	var sword_forward: Vector2 = Vector2.RIGHT.rotated(sword_angle)
	var sword_focus_strength: float = 0.06 if main.player["mode"] == main.CombatMode.MELEE else 0.26
	sword_focus_strength += sword_impact_ratio * (0.42 if main.player["mode"] == main.CombatMode.MELEE else 0.56)
	var sword_state: int = int(main.sword.get("state", main.SwordState.ORBITING))
	var sword_vfx = _get_sword_vfx(main)
	var sword_hover_blend: float = main._get_sword_hover_blend()
	var sword_local_glow_strength: float = float(sword_vfx.local_glow_ranged_idle) if main.player["mode"] == main.CombatMode.RANGED else 0.0
	var sword_glow_style: String = "idle"
	if sword_state == main.SwordState.POINT_STRIKE:
		var point_speed_ratio: float = clampf(Vector2(main.sword.get("vel", Vector2.ZERO)).length() / maxf(main.SWORD_POINT_STRIKE_SPEED, 0.001), 0.0, 1.0)
		sword_local_glow_strength = float(sword_vfx.local_glow_point_base) + float(sword_vfx.local_glow_point_speed_scale) * point_speed_ratio
		sword_glow_style = "point"
	elif sword_state == main.SwordState.PIERCE_DRAWING:
		sword_local_glow_strength = maxf(float(sword_vfx.local_glow_point_base), 0.28)
		sword_focus_strength += 0.16
		sword_glow_style = "point"
	elif sword_state == main.SwordState.SLICING:
		var slice_speed_ratio: float = clampf(Vector2(main.sword.get("vel", Vector2.ZERO)).length() / maxf(main.SWORD_POINT_STRIKE_SPEED, 0.001), 0.0, 1.0)
		sword_local_glow_strength = float(sword_vfx.local_glow_slice_base) + float(sword_vfx.local_glow_slice_speed_scale) * slice_speed_ratio
		sword_glow_style = "slice"
	elif sword_state == main.SwordState.RECALLING:
		var recall_speed_ratio: float = clampf(Vector2(main.sword.get("vel", Vector2.ZERO)).length() / maxf(main.SWORD_RECALL_SPEED, 0.001), 0.0, 1.0)
		sword_local_glow_strength = float(sword_vfx.local_glow_recall_base) + float(sword_vfx.local_glow_recall_speed_scale) * recall_speed_ratio
		sword_glow_style = "recall"
	if sword_state == main.SwordState.SLICING and sword_hover_blend > 0.0:
		sword_local_glow_strength = lerpf(
			sword_local_glow_strength,
			maxf(float(sword_vfx.local_glow_ranged_idle), 0.18),
			sword_hover_blend
		)
		sword_focus_strength += 0.08 * sword_hover_blend
		sword_glow_style = "idle"
	sword_local_glow_strength = clampf(
		sword_local_glow_strength
		+ sword_impact_ratio * float(sword_vfx.local_glow_impact_bonus_scale),
		0.0,
		1.0
	)
	_draw_sword_motion_front(main, sword_pos, sword_forward, sword_color)
	if sword_impact_ratio > 0.0 and not use_node_main_sword_vfx:
		_draw_sword_impact_smear(main, sword_base_pos, sword_pos, sword_forward, sword_color, sword_impact_ratio)
		main.draw_circle(
			sword_pos - sword_forward * (4.0 + 2.0 * sword_impact_ratio),
			3.6 + 3.2 * sword_impact_ratio,
			_with_alpha(sword_color.lerp(UNSHEATH_FLASH_CORE_COLOR, 0.22), 0.12 + 0.16 * sword_impact_ratio)
		)
	if not use_node_main_sword_vfx:
		_draw_sword_body(main, sword_pos, sword_forward, sword_color, 1.6, sword_focus_strength, sword_local_glow_strength, sword_glow_style)
	if resonance_sword_mark_strength > 0.01 and sword_state != main.SwordState.ORBITING:
		_draw_resonance_main_sword_mark(
			main,
			sword_pos,
			sword_forward,
			resonance_mode,
			resonance_color,
			clampf(resonance_strength * 0.12 + resonance_preview_strength * 0.82, 0.0, 1.0)
		)
	var sword_combo_id: String = String(main.sword.get("combo_id", ""))
	var sword_combo_strength: float = _get_combo_strength(main.sword)
	if sword_combo_id == SwordResonanceController.COMBO_FAN_TIME_STOP and sword_combo_strength > 0.01:
		_draw_fan_time_stop_combo(main, sword_pos, sword_forward, sword_combo_strength)
	elif sword_combo_id == SwordResonanceController.COMBO_PIERCE_TIME_STOP and sword_combo_strength > 0.01:
		_draw_pierce_time_stop_combo(main, sword_pos, sword_forward, sword_combo_strength)

	if main.player["attack_flash_timer"] > 0.0:
		var attack_angle: float = (main.mouse_world - main.player["pos"]).angle()
		var attack_flash_ratio: float = clampf(
			float(main.player.get("attack_flash_timer", 0.0)) / maxf(main.MELEE_ATTACK_FLASH_DURATION, 0.001),
			0.0,
			1.0
		)
		var flash_strength: float = pow(attack_flash_ratio, 0.72)
		var outer_color: Color = _with_alpha(main.COLORS["melee_sword"].lerp(UNSHEATH_FLASH_WARM_COLOR, 0.28), 0.16 + 0.18 * flash_strength)
		var inner_color: Color = _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.24 + 0.24 * flash_strength)
		main.draw_arc(
			player_pos,
			main.SWORD_MELEE_RANGE,
			attack_angle - main.SWORD_MELEE_ARC * 0.5,
			attack_angle + main.SWORD_MELEE_ARC * 0.5,
			36,
			outer_color,
			4.0 + 0.8 * flash_strength
		)
		main.draw_arc(
			player_pos,
			main.SWORD_MELEE_RANGE - (8.0 + 4.0 * (1.0 - flash_strength)),
			attack_angle - main.SWORD_MELEE_ARC * 0.42,
			attack_angle + main.SWORD_MELEE_ARC * 0.42,
			24,
			inner_color,
			1.6 + 1.0 * flash_strength
		)

	_draw_unsheath_press_flash(main)
	_draw_unsheath_flash(main)
	main.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_arena_margin_mask(main)
	_draw_art_arena_frame(main)
	if main._has_boss():
		main._draw_boss_hud()
	draw_hud_bars(main)


static func _draw_art_background(main: Node2D) -> void:
	var viewport_rect: Rect2 = main.get_viewport_rect()
	var arena_rect: Rect2 = main.ARENA_RECT
	var arena_center: Vector2 = arena_rect.get_center()
	main.draw_rect(Rect2(Vector2.ZERO, viewport_rect.size), ART_BG_DEEP, true)
	main.draw_rect(Rect2(Vector2.ZERO, viewport_rect.size), _with_alpha(ART_BG, 0.82), true)
	_draw_art_depth_wash(main, viewport_rect, arena_rect)
	main.draw_rect(arena_rect.grow(34.0), _with_alpha(ART_BLUE, 0.018), true)
	main.draw_rect(arena_rect.grow(14.0), _with_alpha(ART_BG_DEEP, 0.62), true)
	main.draw_rect(arena_rect, ART_ARENA, true)
	main.draw_rect(
		Rect2(arena_rect.position + arena_rect.size * 0.08, arena_rect.size * 0.84),
		_with_alpha(ART_ARENA_CORE, 0.54),
		true
	)
	_draw_art_star_field(main, arena_rect)
	_draw_art_orbit_field(main, arena_center)
	_draw_art_mist_lines(main, arena_rect)


static func _draw_art_depth_wash(main: Node2D, viewport_rect: Rect2, arena_rect: Rect2) -> void:
	var center := arena_rect.get_center()
	var slash_axis := Vector2(0.96, -0.28).normalized()
	var counter_axis := Vector2(0.72, 0.48).normalized()
	_draw_soft_diagonal_band(main, center + Vector2(-90.0, -34.0), slash_axis, arena_rect.size.x * 0.74, 96.0, ART_BLUE, 0.028)
	_draw_soft_diagonal_band(main, center + Vector2(82.0, 72.0), slash_axis, arena_rect.size.x * 0.56, 58.0, ART_GOLD, 0.016)
	_draw_soft_diagonal_band(main, center + Vector2(140.0, -150.0), counter_axis, arena_rect.size.x * 0.48, 72.0, ART_BLUE_CORE, 0.014)
	main.draw_rect(
		Rect2(Vector2.ZERO, Vector2(viewport_rect.size.x, 110.0)),
		_with_alpha(ART_BG_DEEP, 0.18),
		true
	)
	main.draw_rect(
		Rect2(Vector2(0.0, viewport_rect.size.y - 135.0), Vector2(viewport_rect.size.x, 135.0)),
		_with_alpha(ART_BG_DEEP, 0.24),
		true
	)


static func _draw_soft_diagonal_band(
	main: Node2D,
	center: Vector2,
	axis: Vector2,
	half_length: float,
	half_width: float,
	color: Color,
	alpha: float
) -> void:
	var normal := Vector2(-axis.y, axis.x)
	var points := PackedVector2Array([
		center - axis * half_length - normal * half_width * 0.46,
		center - axis * half_length * 0.32 + normal * half_width,
		center + axis * half_length + normal * half_width * 0.52,
		center + axis * half_length * 0.34 - normal * half_width,
	])
	_try_draw_colored_polygon(main, points, _with_alpha(color, alpha))


static func _draw_art_star_field(main: Node2D, arena_rect: Rect2) -> void:
	var star_count: int = 36
	var star_index: int = 0
	while star_index < star_count:
		var x_ratio: float = fmod(float(star_index) * 0.6180339 + 0.13, 1.0)
		var y_ratio: float = fmod(float(star_index * star_index) * 0.071 + float(star_index) * 0.173, 1.0)
		var star_pos: Vector2 = arena_rect.position + Vector2(x_ratio * arena_rect.size.x, y_ratio * arena_rect.size.y)
		var shimmer: float = 0.58 + 0.42 * sin(main.elapsed_time * (0.22 + float(star_index % 5) * 0.035) + float(star_index) * 1.71)
		var star_color: Color = ART_GOLD.lerp(ART_BLUE_CORE, fmod(float(star_index) * 0.37, 1.0))
		var star_alpha: float = (0.032 + 0.074 * shimmer) * (0.72 if star_index % 7 == 0 else 1.0)
		var star_radius: float = 0.75 + fmod(float(star_index) * 1.9, 1.8)
		main.draw_circle(star_pos, star_radius, _with_alpha(star_color, star_alpha))
		if star_index % 11 == 0:
			main.draw_circle(star_pos, star_radius + 4.5, _with_alpha(star_color, star_alpha * 0.12))
		star_index += 1


static func _draw_art_orbit_field(main: Node2D, arena_center: Vector2) -> void:
	var arena_rect: Rect2 = main.ARENA_RECT
	var node_positions: Array[Vector2] = []
	var node_count := 27
	var node_index := 0
	while node_index < node_count:
		var x_ratio: float = fmod(float(node_index) * 0.381966 + 0.19, 1.0)
		var y_ratio: float = fmod(float(node_index * node_index) * 0.041 + float(node_index) * 0.137 + 0.07, 1.0)
		var drift := Vector2(
			sin(main.elapsed_time * 0.07 + float(node_index) * 1.9),
			cos(main.elapsed_time * 0.06 + float(node_index) * 1.3)
		) * 4.0
		node_positions.append(arena_rect.position + Vector2(x_ratio * arena_rect.size.x, y_ratio * arena_rect.size.y) + drift)
		node_index += 1

	node_index = 1
	while node_index < node_positions.size():
		var pos: Vector2 = node_positions[node_index]
		var linked_index := maxi(node_index - 1 - (node_index % 3), 0)
		var linked_pos: Vector2 = node_positions[linked_index]
		if pos.distance_to(linked_pos) < 260.0 and node_index % 4 != 0:
			var link_alpha := 0.030 + 0.014 * sin(main.elapsed_time * 0.18 + float(node_index))
			main.draw_line(linked_pos, pos, _with_alpha(ART_BLUE, link_alpha), 1.0)
		node_index += 1

	var pulse := 0.5 + 0.5 * sin(main.elapsed_time * 0.38)
	node_index = 0
	while node_index < node_positions.size():
		var pos: Vector2 = node_positions[node_index]
		var node_color := ART_GOLD.lerp(ART_BLUE_CORE, fmod(float(node_index) * 0.29, 1.0))
		var node_alpha := 0.064 + 0.038 * pulse
		var node_radius := 1.2 + fmod(float(node_index) * 0.73, 1.6)
		main.draw_circle(pos, node_radius + 3.2, _with_alpha(node_color, node_alpha * 0.13))
		main.draw_circle(pos, node_radius, _with_alpha(node_color, node_alpha))
		node_index += 1

	_draw_art_drift_strokes(main, arena_rect, arena_center)


static func _draw_art_drift_strokes(main: Node2D, arena_rect: Rect2, arena_center: Vector2) -> void:
	var axis := Vector2(0.94, -0.34).normalized()
	var normal := Vector2(-axis.y, axis.x)
	var stroke_index := 0
	while stroke_index < 5:
		var t := float(stroke_index) / 4.0
		var anchor := arena_rect.position + Vector2(
			arena_rect.size.x * lerpf(0.12, 0.78, t),
			arena_rect.size.y * (0.22 + 0.42 * fmod(t * 1.7 + 0.18, 1.0))
		)
		var breathe := sin(main.elapsed_time * 0.13 + float(stroke_index) * 1.8)
		var half_length := 46.0 + 34.0 * float(stroke_index % 3)
		var offset := normal * (breathe * 7.0 + float(stroke_index - 2) * 10.0)
		var color := ART_BLUE.lerp(ART_GOLD, 0.24 + 0.12 * float(stroke_index % 2))
		main.draw_line(anchor - axis * half_length + offset, anchor + axis * half_length + offset, _with_alpha(color, 0.034), 1.0)
		stroke_index += 1

	main.draw_line(
		arena_center - axis * 235.0 - normal * 96.0,
		arena_center + axis * 250.0 - normal * 116.0,
		_with_alpha(ART_BLUE_CORE, 0.022),
		1.0
	)


static func _draw_art_mist_lines(main: Node2D, arena_rect: Rect2) -> void:
	var line_index: int = 0
	while line_index < 7:
		var y_ratio: float = 0.14 + float(line_index) * 0.12
		var y: float = arena_rect.position.y + arena_rect.size.y * y_ratio + sin(main.elapsed_time * 0.18 + float(line_index)) * 5.0
		var start_x: float = arena_rect.position.x + 42.0 + fmod(float(line_index) * 139.0, arena_rect.size.x * 0.38)
		var length: float = 120.0 + fmod(float(line_index) * 71.0, 190.0)
		var color: Color = ART_BLUE.lerp(ART_GOLD, 0.35 + 0.08 * float(line_index % 3))
		main.draw_line(
			Vector2(start_x, y),
			Vector2(minf(start_x + length, arena_rect.end.x - 38.0), y + sin(float(line_index) * 1.7) * 9.0),
			_with_alpha(color, 0.032),
			1.0
		)
		line_index += 1


static func _draw_art_tactical_grid(main: Node2D) -> void:
	var x: int = 0
	while x <= int(main.ARENA_SIZE.x):
		var alpha_scale: float = 1.0 if x % 200 == 0 else 0.38
		var from: Vector2 = main.ARENA_ORIGIN + Vector2(float(x), 0.0)
		var to: Vector2 = main.ARENA_ORIGIN + Vector2(float(x), main.ARENA_SIZE.y)
		main.draw_line(from, to, _with_alpha(ART_GRID, ART_GRID.a * alpha_scale), 1.0)
		x += 100

	var y: int = 0
	while y <= int(main.ARENA_SIZE.y):
		var alpha_scale: float = 1.0 if y % 200 == 0 else 0.38
		var from_y: Vector2 = main.ARENA_ORIGIN + Vector2(0.0, float(y))
		var to_y: Vector2 = main.ARENA_ORIGIN + Vector2(main.ARENA_SIZE.x, float(y))
		main.draw_line(from_y, to_y, _with_alpha(ART_GRID, ART_GRID.a * alpha_scale), 1.0)
		y += 100


static func _draw_art_arena_frame(main: Node2D) -> void:
	var arena_rect: Rect2 = main.ARENA_RECT
	var frame_color: Color = _with_alpha(ART_GOLD, 0.34)
	var soft_color: Color = _with_alpha(ART_GOLD, 0.16)
	main.draw_rect(arena_rect, _with_alpha(ART_GOLD, 0.16), false, 1.2)
	main.draw_rect(arena_rect.grow(6.0), _with_alpha(ART_BLUE, 0.045), false, 1.0)
	var corner_len: float = 56.0
	var corners := [
		arena_rect.position,
		Vector2(arena_rect.end.x, arena_rect.position.y),
		arena_rect.end,
		Vector2(arena_rect.position.x, arena_rect.end.y),
	]
	for corner_index in range(corners.size()):
		var corner: Vector2 = corners[corner_index]
		var h_dir: float = 1.0 if corner_index == 0 or corner_index == 3 else -1.0
		var v_dir: float = 1.0 if corner_index == 0 or corner_index == 1 else -1.0
		main.draw_line(corner, corner + Vector2(corner_len * h_dir, 0.0), frame_color, 2.0)
		main.draw_line(corner, corner + Vector2(0.0, corner_len * v_dir), frame_color, 2.0)
		main.draw_circle(corner + Vector2(14.0 * h_dir, 14.0 * v_dir), 2.0, soft_color)
	main.draw_line(
		Vector2(arena_rect.position.x + arena_rect.size.x * 0.5 - 160.0, arena_rect.position.y - 16.0),
		Vector2(arena_rect.position.x + arena_rect.size.x * 0.5 + 160.0, arena_rect.position.y - 16.0),
		soft_color,
		1.0
	)
	main.draw_line(
		Vector2(arena_rect.position.x + arena_rect.size.x * 0.5 - 230.0, arena_rect.end.y + 16.0),
		Vector2(arena_rect.position.x + arena_rect.size.x * 0.5 + 230.0, arena_rect.end.y + 16.0),
		soft_color,
		1.0
	)


static func _get_channeled_array_sword_color(main: Node2D, base_color: Color) -> Color:
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 12.0)
	var energy_ratio: float = clampf(float(main.player.get("energy", 0.0)) / main.PLAYER_MAX_ENERGY, 0.0, 1.0)
	var warning_strength: float = main._get_array_energy_warning_strength()
	var break_strength: float = main._get_array_energy_break_strength()
	var warning_level: int = int(main.array_energy_forecast_level)
	var color: Color = base_color.lerp(ARRAY_CHANNEL_EDGE_COLOR, 0.62)
	color = color.lerp(ARRAY_CHANNEL_FLARE_COLOR, 0.22 + pulse * 0.16)
	if warning_strength > 0.001:
		var warning_color: Color = main.COLORS["energy"]
		if warning_level >= 2 or break_strength > 0.0:
			warning_color = main.COLORS["health"].lerp(main.COLORS["energy"], 0.16)
		color = color.lerp(warning_color, (0.16 + 0.26 * pulse) * warning_strength)
	elif energy_ratio <= 0.18:
		color = color.lerp(main.COLORS["health"], 0.22 + 0.18 * pulse)
	return color


static func _draw_resonance_array_field(
	main: Node2D,
	player_pos: Vector2,
	mode: String,
	color: Color,
	strength: float,
	preview_strength: float
) -> void:
	if mode == "" or strength <= 0.01:
		return
	var flash: float = main._get_resonance_flash_strength()
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 7.4)
	var field_strength: float = clampf(strength * (0.66 + 0.24 * pulse) + preview_strength * 0.32 + flash * 0.36, 0.0, 1.0)
	var aim_dir: Vector2 = main._to_screen(main.mouse_world) - player_pos
	if aim_dir.is_zero_approx():
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	var side: Vector2 = aim_dir.orthogonal()
	var core_color: Color = color.lerp(ART_BLUE_CORE, 0.26)
	match mode:
		SwordArrayConfig.MODE_RING:
			var ring_radius: float = main.PLAYER_RADIUS + 46.0 + 8.0 * pulse + 8.0 * flash
			main.draw_circle(player_pos, ring_radius + 16.0, _with_alpha(color, 0.025 + 0.045 * field_strength))
			main.draw_arc(player_pos, ring_radius, 0.0, TAU, 72, _with_alpha(color, 0.24 + 0.22 * field_strength), 2.0 + 1.6 * field_strength)
			main.draw_arc(player_pos, ring_radius + 13.0, -main.elapsed_time * 1.5, -main.elapsed_time * 1.5 + TAU * 0.72, 56, _with_alpha(core_color, 0.18 + 0.18 * field_strength), 1.4 + field_strength)
			main.draw_arc(player_pos, ring_radius - 12.0, main.elapsed_time * 1.1, main.elapsed_time * 1.1 + TAU * 0.46, 40, _with_alpha(ART_BLUE_CORE, 0.08 + 0.12 * field_strength), 1.0)
		SwordArrayConfig.MODE_FAN:
			var fan_radius: float = 92.0 + 28.0 * field_strength + 9.0 * flash
			var arc_width: float = 0.72 + 0.18 * field_strength
			main.draw_arc(player_pos, fan_radius, aim_dir.angle() - arc_width, aim_dir.angle() + arc_width, 48, _with_alpha(color, 0.22 + 0.22 * field_strength), 2.2 + 1.4 * field_strength)
			main.draw_arc(player_pos, fan_radius + 18.0, aim_dir.angle() - arc_width * 0.86, aim_dir.angle() + arc_width * 0.86, 42, _with_alpha(core_color, 0.12 + 0.16 * field_strength), 1.2 + 0.8 * field_strength)
			for offset in [-0.62, -0.31, 0.0, 0.31, 0.62]:
				var ray: Vector2 = aim_dir.rotated(offset)
				main.draw_line(
					player_pos + ray * (main.PLAYER_RADIUS + 18.0),
					player_pos + ray * (fan_radius + 8.0),
					_with_alpha(color.lerp(ART_BLUE_CORE, 0.2), 0.08 + 0.12 * field_strength),
					1.2 + 0.8 * field_strength
				)
		SwordArrayConfig.MODE_PIERCE:
			var start_pos: Vector2 = player_pos + aim_dir * (main.PLAYER_RADIUS + 16.0)
			var end_pos: Vector2 = player_pos + aim_dir * (148.0 + 42.0 * field_strength + 14.0 * flash)
			for side_offset in [-10.0, 0.0, 10.0]:
				var offset_pos: Vector2 = side * side_offset * (0.72 + 0.28 * field_strength)
				var alpha: float = 0.08 + 0.18 * field_strength if absf(side_offset) < 0.1 else 0.04 + 0.1 * field_strength
				main.draw_line(start_pos + offset_pos, end_pos + offset_pos, _with_alpha(color.lerp(ART_BLUE_CORE, 0.2), alpha), 1.0 + 1.4 * field_strength)
			main.draw_circle(end_pos, 4.2 + 2.8 * field_strength, _with_alpha(core_color, 0.22 + 0.24 * field_strength))


static func _draw_enemy_sigil(
	main: Node2D,
	center: Vector2,
	radius: float,
	enemy_color: Color,
	enemy_type: String,
	enemy_alpha: float,
	is_dying: bool
) -> void:
	var pulse: float = 0.78 + 0.22 * sin(main.elapsed_time * 3.2 + center.x * 0.013 + center.y * 0.007)
	var core_color: Color = enemy_color.lerp(ART_RED, 0.22)
	var ring_color: Color = _with_alpha(core_color, (0.42 + 0.18 * pulse) * enemy_alpha)
	var fill_color: Color = _with_alpha(core_color, (0.18 + 0.08 * pulse) * enemy_alpha)
	if is_dying:
		fill_color.a *= 0.7
		ring_color.a *= 0.85
	main.draw_circle(center, radius * 0.94, fill_color)
	main.draw_arc(center, radius + 1.2, 0.0, TAU, 28, ring_color, 1.7)
	main.draw_arc(center, radius * 0.56, 0.0, TAU, 20, _with_alpha(ART_BLUE_CORE, 0.08 * enemy_alpha), 1.0)
	match enemy_type:
		main.TANK:
			_draw_enemy_diamond(main, center, radius * 0.82, _with_alpha(core_color, 0.66 * enemy_alpha), 2.0)
			main.draw_line(center - Vector2(radius * 0.54, 0.0), center + Vector2(radius * 0.54, 0.0), _with_alpha(ART_BLUE_CORE, 0.18 * enemy_alpha), 1.2)
		main.CASTER:
			_draw_enemy_diamond(main, center, radius * 0.76, _with_alpha(core_color, 0.58 * enemy_alpha), 1.6)
			main.draw_arc(center, radius * 0.62, -PI * 0.15, PI * 1.15, 24, _with_alpha(ART_GOLD, 0.24 * enemy_alpha), 1.2)
		main.HEAVY:
			_draw_enemy_diamond(main, center, radius * 0.9, _with_alpha(core_color, 0.72 * enemy_alpha), 2.2)
			main.draw_arc(center, radius * 0.72, 0.0, TAU, 6, _with_alpha(core_color.lerp(Color.BLACK, 0.15), 0.55 * enemy_alpha), 1.4)
		main.RING_LEECH:
			main.draw_arc(center, radius * 0.72, 0.0, TAU, 18, _with_alpha(core_color, 0.62 * enemy_alpha), 1.5)
			main.draw_circle(center, radius * 0.16, _with_alpha(ART_BLUE_CORE, 0.62 * enemy_alpha))
		main.DRAPE_PRIEST:
			_draw_enemy_diamond(main, center, radius * 0.78, _with_alpha(ART_BLUE, 0.48 * enemy_alpha), 1.6)
			main.draw_line(center + Vector2(0.0, -radius * 0.7), center + Vector2(0.0, radius * 0.7), _with_alpha(ART_BLUE_CORE, 0.46 * enemy_alpha), 1.2)
		main.MIRROR_NEEDLER:
			_draw_enemy_diamond(main, center, radius * 0.78, _with_alpha(ART_BLUE_CORE, 0.52 * enemy_alpha), 1.5)
			main.draw_line(center - Vector2(radius * 0.48, radius * 0.48), center + Vector2(radius * 0.48, radius * 0.48), _with_alpha(core_color, 0.46 * enemy_alpha), 1.2)
			main.draw_line(center - Vector2(radius * 0.48, -radius * 0.48), center + Vector2(radius * 0.48, -radius * 0.48), _with_alpha(core_color, 0.46 * enemy_alpha), 1.2)
		main.PUPPET:
			_draw_enemy_diamond(main, center, radius * 0.86, _with_alpha(enemy_color.lerp(ART_GOLD, 0.18), 0.58 * enemy_alpha), 1.8)
			main.draw_arc(center, radius * 0.58, PI * 0.12, PI * 1.88, 24, _with_alpha(ART_GOLD, 0.24 * enemy_alpha), 1.2)
		_:
			_draw_enemy_diamond(main, center, radius * 0.7, _with_alpha(core_color, 0.56 * enemy_alpha), 1.6)
			main.draw_circle(center, radius * 0.14, _with_alpha(ART_BLUE_CORE, 0.58 * enemy_alpha))


static func _draw_enemy_diamond(main: Node2D, center: Vector2, radius: float, color: Color, width: float) -> void:
	var top: Vector2 = center + Vector2(0.0, -radius)
	var right: Vector2 = center + Vector2(radius, 0.0)
	var bottom: Vector2 = center + Vector2(0.0, radius)
	var left: Vector2 = center + Vector2(-radius, 0.0)
	main.draw_line(top, right, color, width)
	main.draw_line(right, bottom, color, width)
	main.draw_line(bottom, left, color, width)
	main.draw_line(left, top, color, width)


static func _draw_bullet_shape(
	main: Node2D,
	bullet_pos: Vector2,
	velocity: Vector2,
	bullet_radius: float,
	bullet_color: Color,
	bullet_family: String,
	is_deflected: bool
) -> void:
	var forward: Vector2 = velocity.normalized()
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	var side: Vector2 = forward.rotated(PI * 0.5)
	if is_deflected:
		_draw_deflected_bullet(main, bullet_pos, forward, side, bullet_radius, bullet_color)
		return
	match bullet_family:
		main.BULLET_FAMILY_WEAVE:
			_draw_weave_bullet(main, bullet_pos, forward, side, bullet_radius, bullet_color)
		main.BULLET_FAMILY_FANG:
			_draw_fang_bullet(main, bullet_pos, forward, side, bullet_radius, bullet_color)
		main.BULLET_FAMILY_CORE:
			_draw_core_bullet(main, bullet_pos, forward, side, bullet_radius, bullet_color)
		_:
			_draw_needle_bullet(main, bullet_pos, forward, side, bullet_radius, bullet_color)


static func _draw_needle_bullet(
	main: Node2D,
	center: Vector2,
	forward: Vector2,
	side: Vector2,
	radius: float,
	bullet_color: Color
) -> void:
	var body := PackedVector2Array([
		center + forward * radius * 1.8,
		center + side * radius * 0.55,
		center - forward * radius * 1.15,
		center - side * radius * 0.55,
	])
	_try_draw_colored_polygon(main, body, bullet_color)
	main.draw_line(
		center - forward * radius * 1.45,
		center - forward * radius * 0.4,
		_with_alpha(bullet_color.lerp(Color.BLACK, BULLET_EDGE_SHADE), 0.44),
		maxf(radius * 0.18, 1.0)
	)
	main.draw_line(
		center - forward * radius * 0.82,
		center + forward * radius * 1.1,
		_with_alpha(bullet_color.lerp(Color.WHITE, BULLET_SPECULAR_HIGHLIGHT), 0.78),
		maxf(radius * 0.16, 1.0)
	)


static func _draw_weave_bullet(
	main: Node2D,
	center: Vector2,
	forward: Vector2,
	side: Vector2,
	radius: float,
	bullet_color: Color
) -> void:
	var body := PackedVector2Array([
		center + forward * radius * 1.05,
		center + forward * radius * 0.28 + side * radius * 0.82,
		center - forward * radius * 0.95,
		center + forward * radius * 0.28 - side * radius * 0.82,
	])
	_try_draw_colored_polygon(main, body, _with_alpha(bullet_color, 0.96))
	main.draw_arc(
		center,
		radius * 0.96,
		0.0,
		TAU,
		14,
		_with_alpha(bullet_color.lerp(Color.BLACK, BULLET_EDGE_SHADE), 0.4),
		maxf(radius * 0.12, 1.0)
	)
	main.draw_line(
		center - side * radius * 0.92,
		center + side * radius * 0.92,
		_with_alpha(bullet_color.lerp(Color.WHITE, BULLET_CORE_HIGHLIGHT), 0.62),
		maxf(radius * 0.12, 1.0)
	)
	main.draw_line(
		center - forward * radius * 0.78,
		center + forward * radius * 0.78,
		_with_alpha(bullet_color.lerp(Color.WHITE, BULLET_SPECULAR_HIGHLIGHT), 0.44),
		maxf(radius * 0.1, 1.0)
	)


static func _draw_fang_bullet(
	main: Node2D,
	center: Vector2,
	forward: Vector2,
	side: Vector2,
	radius: float,
	bullet_color: Color
) -> void:
	var body := PackedVector2Array([
		center + forward * radius * 1.5,
		center - forward * radius * 0.22 + side * radius * 0.96,
		center - forward * radius * 0.78,
		center - forward * radius * 0.22 - side * radius * 0.96,
	])
	_try_draw_colored_polygon(main, body, bullet_color)
	main.draw_line(
		center - forward * radius * 0.42 + side * radius * 0.54,
		center - forward * radius * 1.2 + side * radius * 0.16,
		_with_alpha(bullet_color.lerp(Color.BLACK, BULLET_EDGE_SHADE), 0.42),
		maxf(radius * 0.14, 1.0)
	)
	main.draw_line(
		center - forward * radius * 0.42 - side * radius * 0.54,
		center - forward * radius * 1.2 - side * radius * 0.16,
		_with_alpha(bullet_color.lerp(Color.BLACK, BULLET_EDGE_SHADE), 0.42),
		maxf(radius * 0.14, 1.0)
	)
	main.draw_line(
		center - forward * radius * 0.35,
		center + forward * radius * 0.98,
		_with_alpha(bullet_color.lerp(Color.WHITE, BULLET_SPECULAR_HIGHLIGHT), 0.66),
		maxf(radius * 0.14, 1.0)
	)


static func _draw_core_bullet(
	main: Node2D,
	center: Vector2,
	forward: Vector2,
	side: Vector2,
	radius: float,
	bullet_color: Color
) -> void:
	var shell := PackedVector2Array([
		center + forward * radius * 1.04,
		center + forward * radius * 0.32 + side * radius * 0.96,
		center - forward * radius * 0.76 + side * radius * 0.7,
		center - forward * radius * 0.96,
		center - forward * radius * 0.76 - side * radius * 0.7,
		center + forward * radius * 0.32 - side * radius * 0.96,
	])
	_try_draw_colored_polygon(main, shell, bullet_color)
	main.draw_circle(
		center,
		radius * 0.42,
		_with_alpha(bullet_color.lerp(Color.WHITE, BULLET_CORE_HIGHLIGHT), 0.92)
	)
	main.draw_arc(
		center,
		radius * 0.9,
		0.0,
		TAU,
		18,
		_with_alpha(bullet_color.lerp(Color.BLACK, BULLET_EDGE_SHADE), 0.46),
		maxf(radius * 0.12, 1.2)
	)
	main.draw_line(
		center - forward * radius * 0.22,
		center + forward * radius * 0.78,
		_with_alpha(bullet_color.lerp(Color.WHITE, BULLET_SPECULAR_HIGHLIGHT), 0.74),
		maxf(radius * 0.15, 1.2)
	)


static func _draw_deflected_bullet(
	main: Node2D,
	center: Vector2,
	forward: Vector2,
	side: Vector2,
	radius: float,
	bullet_color: Color
) -> void:
	var blade := PackedVector2Array([
		center + forward * radius * 1.45,
		center - forward * radius * 0.12 + side * radius * 0.58,
		center - forward * radius * 1.15,
		center - forward * radius * 0.12 - side * radius * 0.58,
	])
	_try_draw_colored_polygon(main, blade, bullet_color)
	main.draw_line(
		center - forward * radius * 1.28,
		center + forward * radius * 1.08,
		_with_alpha(bullet_color.lerp(Color.WHITE, 0.42), 0.82),
		maxf(radius * 0.14, 1.0)
	)
	main.draw_circle(
		center - forward * radius * 0.18,
		radius * 0.24,
		_with_alpha(bullet_color.lerp(Color.WHITE, 0.18), 0.72)
	)


static func _draw_array_distance_guides(main: Node2D, player_pos: Vector2, strength: float) -> void:
	var guide_strength: float = clampf(strength, 0.0, 1.0)
	if guide_strength <= 0.01:
		return
	var distances: Dictionary = SwordArrayConfig.get_morph_distances()
	var mode_state: Dictionary = main._get_sword_array_fire_state()
	var active_mode: String = str(mode_state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	var ring_color: Color = SwordArrayController.get_accent_color(SwordArrayConfig.MODE_RING)
	var fan_color: Color = SwordArrayController.get_accent_color(SwordArrayConfig.MODE_FAN)
	var pierce_color: Color = SwordArrayController.get_accent_color(SwordArrayConfig.MODE_PIERCE)
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 3.2)
	var cursor_pos: Vector2 = main._to_screen(main.mouse_world)
	var aim_axis: Vector2 = cursor_pos - player_pos
	if aim_axis.is_zero_approx():
		aim_axis = Vector2.RIGHT
	var aim_dir: Vector2 = aim_axis.normalized()
	var aim_angle: float = aim_dir.angle()
	_draw_distance_guide_arc(
		main,
		player_pos,
		float(distances.get("ring_stable_end", SwordArrayConfig.RING_STABLE_END)),
		ring_color,
		guide_strength,
		active_mode == SwordArrayConfig.MODE_RING,
		aim_dir,
		aim_angle,
		pulse
	)
	_draw_distance_guide_arc(
		main,
		player_pos,
		float(distances.get("fan_stable_end", SwordArrayConfig.FAN_STABLE_END)),
		fan_color,
		guide_strength,
		active_mode == SwordArrayConfig.MODE_FAN,
		aim_dir,
		aim_angle,
		pulse
	)
	_draw_distance_guide_arc(
		main,
		player_pos,
		float(distances.get("fan_to_pierce_end", SwordArrayConfig.FAN_TO_PIERCE_END)),
		pierce_color,
		guide_strength,
		active_mode == SwordArrayConfig.MODE_PIERCE,
		aim_dir,
		aim_angle,
		pulse
	)
	var transition_color: Color = fan_color.lerp(pierce_color, 0.42)
	_draw_distance_guide_tick(
		main,
		player_pos,
		float(distances.get("ring_to_fan_end", SwordArrayConfig.RING_TO_FAN_END)),
		transition_color,
		guide_strength * 0.55,
		aim_dir
	)

	var active_color: Color = SwordArrayController.get_accent_color(active_mode)
	main.draw_line(
		player_pos + aim_dir * (main.PLAYER_RADIUS + 16.0),
		cursor_pos,
		_with_alpha(active_color, 0.055 + 0.11 * guide_strength),
		1.0 + guide_strength * 0.45
	)
	var active_radius: float = float(distances.get("ring_stable_end", SwordArrayConfig.RING_STABLE_END))
	match active_mode:
		SwordArrayConfig.MODE_FAN:
			active_radius = float(distances.get("fan_stable_end", SwordArrayConfig.FAN_STABLE_END))
		SwordArrayConfig.MODE_PIERCE:
			active_radius = float(distances.get("fan_to_pierce_end", SwordArrayConfig.FAN_TO_PIERCE_END))
	var active_arc: float = deg_to_rad(64.0)
	main.draw_arc(
		player_pos,
		active_radius,
		aim_angle - active_arc * 0.5,
		aim_angle + active_arc * 0.5,
		20,
		_with_alpha(active_color.lerp(Color.WHITE, 0.18), 0.2 * guide_strength + 0.12 * pulse * guide_strength),
		2.0 + guide_strength
	)
	main.draw_circle(cursor_pos, 3.0 + 1.6 * guide_strength, _with_alpha(active_color.lerp(Color.WHITE, 0.24), 0.2 + 0.32 * guide_strength))
	main.draw_arc(cursor_pos, 7.0 + 2.0 * pulse, 0.0, TAU, 18, _with_alpha(active_color, 0.14 + 0.18 * guide_strength), 1.0)


static func _draw_distance_guide_arc(
	main: Node2D,
	player_pos: Vector2,
	radius: float,
	color: Color,
	strength: float,
	active: bool,
	aim_dir: Vector2,
	aim_angle: float,
	pulse: float
) -> void:
	if radius <= 0.0:
		return
	var arc_span: float = deg_to_rad(34.0)
	var alpha: float = (0.035 + 0.035 * strength) * strength
	var width: float = 1.0 + 0.25 * strength
	if active:
		arc_span = deg_to_rad(72.0)
		alpha = 0.13 * strength + 0.07 * pulse * strength
		width = 1.6 + 0.9 * strength
	main.draw_arc(player_pos, radius, aim_angle - arc_span * 0.5, aim_angle + arc_span * 0.5, 20, _with_alpha(color, alpha), width)
	main.draw_arc(player_pos, radius + 4.0, aim_angle - arc_span * 0.28, aim_angle + arc_span * 0.28, 14, _with_alpha(color.lerp(Color.WHITE, 0.16), alpha * 0.32), 0.8)
	_draw_distance_guide_tick(main, player_pos, radius, color, strength if active else strength * 0.48, aim_dir)


static func _draw_distance_guide_tick(
	main: Node2D,
	player_pos: Vector2,
	radius: float,
	color: Color,
	strength: float,
	aim_dir: Vector2
) -> void:
	var tick_strength: float = clampf(strength, 0.0, 1.0)
	if radius <= 0.0 or tick_strength <= 0.01:
		return
	var side: Vector2 = aim_dir.rotated(PI * 0.5)
	var center: Vector2 = player_pos + aim_dir * radius
	var tick_half_width: float = 5.0 + tick_strength * 5.0
	var tick_depth: float = 3.0 + tick_strength * 2.0
	main.draw_line(
		center - side * tick_half_width - aim_dir * tick_depth,
		center + side * tick_half_width - aim_dir * tick_depth,
		_with_alpha(color.lerp(Color.WHITE, 0.12), 0.08 + 0.2 * tick_strength),
		1.0 + 0.8 * tick_strength
	)
	main.draw_circle(center, 1.4 + tick_strength * 1.6, _with_alpha(color, 0.08 + 0.2 * tick_strength))


static func _draw_current_array_mode_hint(main: Node2D, player_pos: Vector2, strength: float) -> void:
	var hint_strength: float = clampf(strength, 0.0, 1.0)
	var state: Dictionary = main._get_sword_array_fire_state()
	var mode: String = str(state.get("dominant_mode", SwordArrayConfig.MODE_RING))
	var aim_vector: Vector2 = main.mouse_world - main.player["pos"]
	if aim_vector.is_zero_approx():
		aim_vector = Vector2.RIGHT
	var forward: Vector2 = aim_vector.normalized()
	var side: Vector2 = forward.rotated(PI * 0.5)
	var angle: float = forward.angle()
	var color: Color = SwordArrayController.get_accent_color(mode)
	var soft_color: Color = SwordArrayController.get_soft_accent_color(mode)
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 5.0)
	match mode:
		SwordArrayConfig.MODE_RING:
			var guard_radius: float = main.PLAYER_RADIUS + 19.0 + pulse * 2.4
			main.draw_arc(player_pos, guard_radius, 0.0, TAU, 42, _with_alpha(color, 0.16 * hint_strength), 1.8)
			main.draw_arc(player_pos, guard_radius + 7.0, 0.0, TAU, 42, _with_alpha(soft_color, 0.08 * hint_strength), 1.1)
			for spoke_index in range(4):
				var spoke_angle: float = angle + float(spoke_index) * PI * 0.5
				var spoke_dir: Vector2 = Vector2.RIGHT.rotated(spoke_angle)
				main.draw_line(
					player_pos + spoke_dir * (main.PLAYER_RADIUS + 6.0),
					player_pos + spoke_dir * (main.PLAYER_RADIUS + 16.0 + pulse * 2.0),
					_with_alpha(color.lerp(Color.WHITE, 0.18), 0.12 * hint_strength),
					1.2
				)
		SwordArrayConfig.MODE_FAN:
			var fan_arc: float = float(SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN).get("arc", deg_to_rad(60.0))) * 1.38
			var fan_radius: float = main.PLAYER_RADIUS + 46.0 + pulse * 4.0
			main.draw_arc(
				player_pos,
				fan_radius,
				angle - fan_arc * 0.5,
				angle + fan_arc * 0.5,
				30,
				_with_alpha(color, 0.18 * hint_strength),
				2.0
			)
			main.draw_arc(
				player_pos,
				fan_radius - 16.0,
				angle - fan_arc * 0.34,
				angle + fan_arc * 0.34,
				20,
				_with_alpha(soft_color, 0.11 * hint_strength),
				1.2
			)
			main.draw_line(
				player_pos + forward * (main.PLAYER_RADIUS + 12.0),
				player_pos + forward * (fan_radius + 5.0),
				_with_alpha(color.lerp(Color.WHITE, 0.1), 0.08 * hint_strength),
				1.0
			)
		SwordArrayConfig.MODE_PIERCE:
			var start: Vector2 = player_pos + forward * (main.PLAYER_RADIUS + 18.0)
			var tip: Vector2 = player_pos + forward * (main.PLAYER_RADIUS + 92.0 + pulse * 12.0)
			var tail: Vector2 = player_pos + forward * (main.PLAYER_RADIUS + 54.0)
			main.draw_line(start, tip, _with_alpha(color.lerp(Color.WHITE, 0.18), 0.2 * hint_strength), 2.0)
			main.draw_line(start + side * 5.0, tail + side * 1.6, _with_alpha(soft_color, 0.08 * hint_strength), 1.0)
			main.draw_line(start - side * 5.0, tail - side * 1.6, _with_alpha(soft_color, 0.08 * hint_strength), 1.0)
			var head := PackedVector2Array([
				tip,
				tip - forward * 13.0 + side * 5.2,
				tip - forward * 13.0 - side * 5.2,
			])
			_try_draw_colored_polygon(main, head, _with_alpha(color.lerp(Color.WHITE, 0.2), 0.11 * hint_strength))
		_:
			main.draw_arc(player_pos, main.PLAYER_RADIUS + 18.0, 0.0, TAU, 32, _with_alpha(color, 0.1 * hint_strength), 1.4)


static func _draw_ambient_array_presence(main: Node2D, player_pos: Vector2, hold_ratio: float) -> void:
	var ambient_ratio: float = 0.18 + hold_ratio * 0.42
	var ambient_alpha: float = 0.065 + hold_ratio * 0.09
	var morph_state: Dictionary = main._get_sword_array_morph_state()
	var geometry: Dictionary = SwordArrayController.get_geometry_result(main, morph_state, ambient_ratio)
	_draw_preview_family(main, player_pos, geometry, morph_state, ambient_alpha, ambient_ratio)
	var accent_color: Color = SwordArrayController.get_soft_accent_color(morph_state)
	var field_radius: float = main.PLAYER_RADIUS + 8.0 + 2.0 * sin(main.elapsed_time * 2.6)
	main.draw_arc(
		player_pos,
		field_radius,
		0.0,
		TAU,
		24,
		_with_alpha(accent_color, 0.08 + hold_ratio * 0.06),
		1.2
	)


static func _draw_array_mode_confirm(main: Node2D, player_pos: Vector2) -> void:
	var strength: float = main._get_array_mode_confirm_strength()
	if strength <= 0.0:
		return
	var mode: String = str(main.array_mode_confirm_mode)
	if mode == "":
		return
	var progress: float = 1.0 - strength
	var mode_color: Color = SwordArrayController.get_accent_color(mode)
	var pulse_alpha: float = 0.16 + 0.56 * strength
	var pulse_color: Color = _with_alpha(mode_color.lerp(ARRAY_MODE_CONFIRM_COLOR, 0.45), pulse_alpha)
	var soft_pulse_color: Color = _with_alpha(SwordArrayController.get_soft_accent_color(mode), 0.08 + 0.18 * strength)
	match mode:
		SwordArrayConfig.MODE_RING:
			var ring_radius: float = main.PLAYER_RADIUS + 12.0 + progress * 12.0
			main.draw_arc(player_pos, ring_radius, 0.0, TAU, 36, pulse_color, 1.8 + 1.2 * strength)
			main.draw_arc(player_pos, ring_radius + 8.0, 0.0, TAU, 36, soft_pulse_color, 1.0 + 0.8 * strength)
		SwordArrayConfig.MODE_FAN:
			var fan_arc: float = float(SwordArrayConfig.get_profile(SwordArrayConfig.MODE_FAN).get("arc", deg_to_rad(60.0))) * 1.12
			var fan_radius: float = main.PLAYER_RADIUS + 18.0 + progress * 16.0
			main.draw_arc(
				player_pos,
				fan_radius,
				main.array_mode_confirm_angle - fan_arc * 0.5,
				main.array_mode_confirm_angle + fan_arc * 0.5,
				22,
				pulse_color,
				1.8 + 1.0 * strength
			)
			main.draw_arc(
				player_pos,
				fan_radius + 10.0,
				main.array_mode_confirm_angle - fan_arc * 0.58,
				main.array_mode_confirm_angle + fan_arc * 0.58,
				22,
				soft_pulse_color,
				1.0 + 0.6 * strength
			)
		SwordArrayConfig.MODE_PIERCE:
			var direction: Vector2 = Vector2.RIGHT.rotated(main.array_mode_confirm_angle)
			var start: Vector2 = player_pos + direction * (main.PLAYER_RADIUS + 10.0)
			var tip: Vector2 = player_pos + direction * (main.PLAYER_RADIUS + 26.0 + progress * 18.0)
			main.draw_line(start, tip, pulse_color, 1.8 + 1.0 * strength)
			main.draw_line(start - direction.rotated(PI * 0.5) * 4.0, tip - direction.rotated(PI * 0.5) * 1.2, soft_pulse_color, 1.0)
			main.draw_line(start + direction.rotated(PI * 0.5) * 4.0, tip + direction.rotated(PI * 0.5) * 1.2, soft_pulse_color, 1.0)
			main.draw_circle(tip, 1.6 + 1.4 * strength, pulse_color)


static func _draw_ready_array_sword_idle(
	main: Node2D,
	array_sword_pos: Vector2,
	tip_pos: Vector2,
	left_pos: Vector2,
	right_pos: Vector2,
	base_color: Color
) -> void:
	var tip: Vector2 = array_sword_pos + (tip_pos - array_sword_pos) * 0.72
	var left: Vector2 = array_sword_pos + (left_pos - array_sword_pos) * 0.66
	var right: Vector2 = array_sword_pos + (right_pos - array_sword_pos) * 0.66
	var tail_center: Vector2 = (left + right) * 0.5
	var idle_outline: Color = _with_alpha(base_color, 0.24)
	var idle_core: Color = _with_alpha(ARRAY_CHANNEL_CORE_COLOR, 0.38)
	main.draw_line(left, tip, idle_outline, 1.1)
	main.draw_line(tip, right, idle_outline, 1.1)
	main.draw_line(right, left, _with_alpha(base_color, 0.14), 0.9)
	main.draw_line(tail_center, tip, idle_core, 0.9)
	main.draw_circle(array_sword_pos, 2.0, _with_alpha(Color.WHITE, 0.58))
	main.draw_arc(array_sword_pos, 5.2, 0.0, TAU, 12, _with_alpha(base_color, 0.12), 1.0)


static func _draw_ready_array_sword_primed(
	main: Node2D,
	array_sword_pos: Vector2,
	tip_pos: Vector2,
	left_pos: Vector2,
	right_pos: Vector2,
	base_color: Color,
	hold_ratio: float
) -> void:
	var outline_alpha: float = 0.22 + 0.34 * hold_ratio
	var core_alpha: float = 0.35 + 0.4 * hold_ratio
	var outline_color: Color = _with_alpha(base_color, outline_alpha)
	main.draw_line(left_pos, tip_pos, outline_color, 1.2 + 0.6 * hold_ratio)
	main.draw_line(tip_pos, right_pos, outline_color, 1.2 + 0.6 * hold_ratio)
	main.draw_line(right_pos, left_pos, _with_alpha(base_color, outline_alpha * 0.72), 1.0)
	main.draw_line(array_sword_pos - (tip_pos - array_sword_pos) * 0.45, tip_pos, _with_alpha(ARRAY_CHANNEL_CORE_COLOR, core_alpha), 1.0 + 0.3 * hold_ratio)
	main.draw_circle(array_sword_pos, 2.0 + 0.6 * hold_ratio, _with_alpha(Color.WHITE, 0.5 + 0.2 * hold_ratio))
	main.draw_arc(array_sword_pos, 5.0 + 1.5 * hold_ratio, 0.0, TAU, 14, _with_alpha(base_color, 0.12 + 0.18 * hold_ratio), 1.0)


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
	var streak_start: Vector2 = array_sword_pos - forward * trail_length
	var streak_end: Vector2 = array_sword_pos + forward * 7.0
	var outer_color: Color = array_sword_color.lerp(ART_BLUE, 0.14)
	var ribbon_color: Color = array_sword_color.lerp(ART_BLUE_CORE, 0.22)
	var core_color: Color = ART_BLUE_CORE.lerp(Color.WHITE, 0.46)
	var warm_color: Color = ART_GOLD
	if state == "returning":
		outer_color = array_sword_color.lerp(main.COLORS["ranged_sword"], 0.28)
		ribbon_color = array_sword_color.lerp(ART_BLUE_CORE, 0.1)
		core_color = UNSHEATH_FLASH_CORE_COLOR.lerp(Color.WHITE, 0.3)
		warm_color = ART_GOLD
	_draw_luminous_sword_streak(
		main,
		streak_start,
		streak_end,
		2.6 + pulse * 0.4,
		outer_color,
		ribbon_color,
		core_color,
		0.1 + pulse * 0.04,
		0.18 + pulse * 0.08,
		0.28 + pulse * 0.06,
		0.04 + pulse * 0.04,
		warm_color
	)
	main.draw_line(
		streak_start + side * 1.3,
		streak_end + side * 0.4,
		_with_alpha(ART_BLUE, 0.08 + pulse * 0.04),
		0.7
	)


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


static func _draw_luminous_sword_streak(
	main: Node2D,
	start: Vector2,
	end: Vector2,
	half_width: float,
	outer_color: Color,
	ribbon_color: Color,
	core_color: Color,
	outer_alpha: float,
	ribbon_alpha: float,
	core_alpha: float,
	warm_alpha := 0.0,
	warm_color := ART_GOLD
) -> void:
	var axis: Vector2 = end - start
	if axis.length_squared() <= 0.001 or half_width <= 0.0:
		return
	var forward: Vector2 = axis.normalized()
	var side: Vector2 = forward.rotated(PI * 0.5)
	var tip_extension: float = minf(axis.length() * 0.08, 8.0)
	var outer_poly := PackedVector2Array([
		start + side * half_width * 1.2,
		start - side * half_width * 1.12,
		end - side * half_width * 0.44 + forward * tip_extension,
		end + side * half_width * 0.56 + forward * tip_extension,
	])
	var ribbon_poly := PackedVector2Array([
		start + side * half_width * 0.52,
		start - side * half_width * 0.46,
		end - side * half_width * 0.16 + forward * tip_extension * 0.42,
		end + side * half_width * 0.2 + forward * tip_extension * 0.42,
	])
	_try_draw_colored_polygon(main, outer_poly, _with_alpha(outer_color, outer_alpha))
	_try_draw_colored_polygon(main, ribbon_poly, _with_alpha(ribbon_color, ribbon_alpha))
	main.draw_line(
		start - forward * 0.8,
		end + forward * tip_extension * 0.74,
		_with_alpha(core_color, core_alpha),
		maxf(half_width * 0.24, 0.9)
	)
	main.draw_circle(
		end - forward * minf(axis.length() * 0.04, 2.0),
		maxf(half_width * 0.14, 0.72),
		_with_alpha(core_color.lerp(Color.WHITE, 0.16), core_alpha * 0.54)
	)
	if warm_alpha > 0.001:
		main.draw_line(
			start + side * half_width * 0.18,
			end + side * half_width * 0.06,
			_with_alpha(warm_color, warm_alpha),
			maxf(half_width * 0.08, 0.55)
		)
		main.draw_circle(
			start + forward * minf(axis.length() * 0.12, 8.0),
			maxf(half_width * 0.22, 0.9),
			_with_alpha(warm_color.lerp(Color.WHITE, 0.24), warm_alpha * 0.82)
		)


static func _quadratic_bezier_point(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	var omt: float = 1.0 - t
	return omt * omt * start + 2.0 * omt * t * control + t * t * end


static func _draw_quadratic_trace(
	main: Node2D,
	start: Vector2,
	control: Vector2,
	end: Vector2,
	outer_color: Color,
	core_color: Color,
	outer_alpha: float,
	core_alpha: float,
	outer_width: float,
	core_width: float
) -> void:
	var prev: Vector2 = start
	var steps: int = 8
	for step in range(1, steps + 1):
		var t: float = float(step) / float(steps)
		var point: Vector2 = _quadratic_bezier_point(start, control, end, t)
		var fade: float = 1.0 - pow(t, 1.15) * 0.78
		main.draw_line(prev, point, _with_alpha(outer_color, outer_alpha * fade), maxf(outer_width * fade, 0.45))
		main.draw_line(prev, point, _with_alpha(core_color, core_alpha * fade), maxf(core_width * fade, 0.4))
		prev = point


static func _draw_sword_motion_front(main: Node2D, sword_pos: Vector2, forward: Vector2, base_color: Color) -> void:
	if _use_node_sword_flight_vfx(main):
		return
	var sword_vfx = _get_sword_vfx(main)
	var sword_state: int = int(main.sword.get("state", main.SwordState.ORBITING))
	if sword_state != main.SwordState.POINT_STRIKE and sword_state != main.SwordState.RECALLING:
		return
	var sword_velocity: Vector2 = Vector2(main.sword.get("vel", Vector2.ZERO))
	var speed: float = sword_velocity.length()
	var speed_reference: float = main.SWORD_RECALL_SPEED if sword_state == main.SwordState.RECALLING else main.SWORD_POINT_STRIKE_SPEED
	var speed_ratio: float = clampf(
		(speed / maxf(speed_reference, 0.001) - float(sword_vfx.front_speed_start)) / maxf(float(sword_vfx.front_speed_span), 0.001),
		0.0,
		1.0
	)
	if speed_ratio <= 0.0:
		return
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var side: Vector2 = forward.rotated(PI * 0.5)
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * (16.0 if sword_state == main.SwordState.POINT_STRIKE else 12.0))
	var front_origin: Vector2 = sword_pos + forward * (8.0 + 4.0 * speed_ratio)
	var front_length: float = lerpf(float(sword_vfx.front_length_min), float(sword_vfx.front_length_max), speed_ratio) * (float(sword_vfx.front_recall_length_scale) if sword_state == main.SwordState.RECALLING else 1.0)
	var front_width: float = lerpf(float(sword_vfx.front_width_min), float(sword_vfx.front_width_max), speed_ratio) * (float(sword_vfx.front_recall_width_scale) if sword_state == main.SwordState.RECALLING else 1.0)
	var pulse_strength: float = float(sword_vfx.front_point_pulse) if sword_state == main.SwordState.POINT_STRIKE else float(sword_vfx.front_recall_pulse)
	var tip: Vector2 = front_origin + forward * (front_length + pulse * pulse_strength)
	var halo_tip: Vector2 = tip + forward * (6.0 + 8.0 * speed_ratio)
	var outer_color: Color = base_color.lerp(ART_BLUE, 0.18)
	var ribbon_color: Color = base_color.lerp(ART_BLUE_CORE, 0.24)
	var core_color: Color = ART_BLUE_CORE.lerp(Color.WHITE, 0.36)
	var accent_color: Color = UNSHEATH_FLASH_WARM_COLOR
	if sword_state == main.SwordState.RECALLING:
		outer_color = main.COLORS["array_sword_return"].lerp(main.COLORS["ranged_sword"], 0.46)
		ribbon_color = main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.18)
		accent_color = ART_GOLD
		core_color = UNSHEATH_FLASH_CORE_COLOR.lerp(Color.WHITE, 0.28)
	var beam_start: Vector2 = sword_pos - forward * (1.2 + 1.8 * speed_ratio)
	var beam_end: Vector2 = halo_tip + forward * (front_length * (0.32 if sword_state == main.SwordState.RECALLING else 0.46))
	var beam_half_width: float = front_width * (0.42 if sword_state == main.SwordState.POINT_STRIKE else 0.34)
	_draw_luminous_sword_streak(
		main,
		beam_start,
		beam_end,
		beam_half_width,
		outer_color,
		ribbon_color,
		core_color,
		0.08 + 0.12 * speed_ratio,
		0.14 + 0.2 * speed_ratio,
		0.24 + 0.26 * speed_ratio,
		0.05 + 0.06 * speed_ratio,
		accent_color
	)
	main.draw_line(
		beam_start + side * beam_half_width * 0.58,
		beam_end + side * beam_half_width * 0.18,
		_with_alpha(ART_BLUE, 0.05 + 0.08 * speed_ratio),
		0.8 + 0.5 * speed_ratio
	)
	main.draw_line(
		front_origin - side * beam_half_width * 0.24,
		tip - side * beam_half_width * 0.08,
		_with_alpha(accent_color, 0.04 + 0.05 * speed_ratio),
		0.66 + 0.34 * speed_ratio
	)


static func _draw_sword_body(
	main: Node2D,
	sword_pos: Vector2,
	forward: Vector2,
	base_color: Color,
	scale := 1.0,
	focus_strength := 0.0,
	local_glow_strength := 0.0,
	glow_style := "idle"
) -> void:
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var sword_vfx = _get_sword_vfx(main)
	var side: Vector2 = forward.rotated(PI * 0.5)
	var blade_tip: Vector2 = sword_pos + forward * (24.4 * scale)
	var shoulder_center: Vector2 = sword_pos + forward * (0.25 * scale)
	var blade_root: Vector2 = sword_pos - forward * (8.6 * scale)
	var guard_center: Vector2 = blade_root - forward * (0.08 * scale)
	var handle_front: Vector2 = guard_center - forward * (0.56 * scale)
	var handle_back: Vector2 = sword_pos - forward * (17.2 * scale)
	var shoulder_half_width: float = 2.78 * scale
	var root_half_width: float = 0.82 * scale
	var handle_half_width: float = 0.58 * scale
	var pommel_radius: float = 0.96 * scale
	var guard_half_span: float = 3.05 * scale
	var guard_half_thickness: float = 0.58 * scale
	var blade_color: Color = base_color.lerp(ART_BLUE_CORE, 0.16 + 0.08 * focus_strength)
	var blade_edge_color: Color = base_color.lerp(ART_BLUE_CORE, 0.24 + 0.08 * focus_strength)
	var blade_core_color: Color = ART_BLUE_CORE.lerp(Color.WHITE, 0.42 + 0.12 * focus_strength)
	var handle_color: Color = Color(0.12, 0.15, 0.2, 1.0).lerp(base_color, 0.16)
	if focus_strength > 0.001:
		var glow_tail: Vector2 = handle_back - forward * 0.6
		var glow_root: Vector2 = blade_root + forward * 0.4
		var glow_shoulder: Vector2 = shoulder_center + forward * 1.0
		var glow_tip: Vector2 = blade_tip + forward * (1.4 + 1.8 * focus_strength)
		var glow_root_half: float = 1.36 * scale + 0.72 * focus_strength * scale
		var glow_shoulder_half: float = 2.36 * scale + 0.84 * focus_strength * scale
		var outer_glow_root_half: float = glow_root_half * 1.55
		var outer_glow_shoulder_half: float = glow_shoulder_half * 1.46
		var sword_outer_glow := PackedVector2Array([
			glow_tail - forward * 1.8,
			glow_root + side * outer_glow_root_half,
			glow_shoulder + side * outer_glow_shoulder_half,
			glow_tip + forward * 1.4,
			glow_shoulder - side * outer_glow_shoulder_half,
			glow_root - side * outer_glow_root_half,
		])
		var sword_glow := PackedVector2Array([
			glow_tail,
			glow_root + side * glow_root_half,
			glow_shoulder + side * glow_shoulder_half,
			glow_tip,
			glow_shoulder - side * glow_shoulder_half,
			glow_root - side * glow_root_half,
		])
		_try_draw_colored_polygon(main, sword_outer_glow, _with_alpha(base_color.lerp(ART_BLUE_CORE, 0.18), 0.04 + 0.07 * focus_strength))
		_try_draw_colored_polygon(main, sword_glow, _with_alpha(base_color.lerp(ART_BLUE_CORE, 0.16), 0.08 + 0.12 * focus_strength))
	if local_glow_strength > 0.001:
		var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * (15.0 if glow_style == "point" else 11.0))
		var local_accent_color: Color = base_color.lerp(UNSHEATH_FLASH_CORE_COLOR, 0.32)
		var guard_accent_color: Color = base_color.lerp(ART_BLUE_CORE, 0.14)
		var tip_bias: float = 0.0
		match glow_style:
			"point":
				local_accent_color = UNSHEATH_FLASH_CORE_COLOR.lerp(base_color, 0.34)
				guard_accent_color = local_accent_color.lerp(UNSHEATH_FLASH_EDGE_COLOR, 0.28)
				tip_bias = 0.12
			"slice":
				local_accent_color = base_color.lerp(UNSHEATH_FLASH_WARM_COLOR, 0.16)
				guard_accent_color = local_accent_color.lerp(ART_BLUE_CORE, 0.16)
			"recall":
				local_accent_color = main.COLORS["array_sword_return"].lerp(ART_GOLD, 0.24)
				guard_accent_color = local_accent_color.lerp(UNSHEATH_FLASH_CORE_COLOR, 0.24)
				tip_bias = -0.08
		var tip_glow_center: Vector2 = blade_tip - forward * (2.0 - 1.2 * tip_bias)
		var tip_glow_radius: float = (
			float(sword_vfx.local_glow_tip_radius_min)
			+ float(sword_vfx.local_glow_tip_radius_scale) * local_glow_strength
			+ pulse * float(sword_vfx.local_glow_tip_radius_pulse)
		) * scale
		var guard_glow_radius: float = (
			float(sword_vfx.local_glow_guard_radius_min)
			+ float(sword_vfx.local_glow_guard_radius_scale) * local_glow_strength
		) * scale
		var spine_width: float = (
			float(sword_vfx.local_glow_spine_width_min)
			+ float(sword_vfx.local_glow_spine_width_scale) * local_glow_strength
		) * scale
		var spine_tail: Vector2 = blade_root + forward * (1.0 + 0.8 * local_glow_strength)
		var spine_mid: Vector2 = shoulder_center + forward * 4.2
		var spine_tip: Vector2 = blade_tip - forward * 2.4
		var spine_poly := PackedVector2Array([
			spine_tail + side * spine_width * 0.44,
			spine_mid + side * spine_width * 0.82,
			spine_tip + side * spine_width * 0.18,
			spine_tip - side * spine_width * 0.18,
			spine_mid - side * spine_width * 0.82,
			spine_tail - side * spine_width * 0.44,
		])
		_try_draw_colored_polygon(
			main,
			spine_poly,
			_with_alpha(local_accent_color, float(sword_vfx.local_glow_spine_alpha_base) + float(sword_vfx.local_glow_spine_alpha_scale) * local_glow_strength)
		)
		var tip_alpha: float = float(sword_vfx.local_glow_tip_alpha_base) + float(sword_vfx.local_glow_tip_alpha_scale) * local_glow_strength
		var guard_alpha: float = float(sword_vfx.local_glow_guard_alpha_base) + float(sword_vfx.local_glow_guard_alpha_scale) * local_glow_strength
		main.draw_arc(
			tip_glow_center,
			tip_glow_radius,
			0.0,
			TAU,
			24,
			_with_alpha(local_accent_color, tip_alpha * 0.82),
			0.9 + 0.8 * local_glow_strength
		)
		main.draw_circle(
			tip_glow_center,
			tip_glow_radius * 0.32,
			_with_alpha(local_accent_color.lerp(Color.WHITE, 0.12), tip_alpha * 0.42)
		)
		main.draw_arc(
			guard_center,
			guard_glow_radius,
			0.0,
			TAU,
			22,
			_with_alpha(guard_accent_color, guard_alpha * 0.74),
			0.8 + 0.7 * local_glow_strength
		)
		main.draw_circle(
			guard_center,
			guard_glow_radius * 0.24,
			_with_alpha(guard_accent_color.lerp(Color.WHITE, 0.08), guard_alpha * 0.28)
		)
		main.draw_line(
			spine_tail,
			blade_tip - forward * 1.4,
			_with_alpha(local_accent_color.lerp(Color.WHITE, 0.18), float(sword_vfx.local_glow_spine_line_alpha_base) + float(sword_vfx.local_glow_spine_line_alpha_scale) * local_glow_strength),
			float(sword_vfx.local_glow_spine_line_width_base) + float(sword_vfx.local_glow_spine_line_width_scale) * local_glow_strength
		)
	var blade_polygon := PackedVector2Array([
		blade_tip,
		shoulder_center + side * shoulder_half_width,
		blade_root + side * root_half_width,
		blade_root - side * root_half_width,
		shoulder_center - side * shoulder_half_width,
	])
	var blade_core := PackedVector2Array([
		sword_pos + forward * (20.8 * scale),
		shoulder_center + side * shoulder_half_width * 0.16,
		blade_root + side * root_half_width * 0.18,
		blade_root - side * root_half_width * 0.18,
		shoulder_center - side * shoulder_half_width * 0.16,
	])
	var handle_polygon := PackedVector2Array([
		handle_front + side * handle_half_width,
		handle_front - side * handle_half_width,
		handle_back - side * handle_half_width * 0.88,
		handle_back + side * handle_half_width * 0.88,
	])
	var guard_polygon := PackedVector2Array([
		guard_center + side * guard_half_span,
		guard_center + forward * guard_half_thickness + side * guard_half_span * 0.1,
		guard_center + forward * guard_half_thickness * 0.92,
		guard_center - side * guard_half_span,
		guard_center - forward * guard_half_thickness - side * guard_half_span * 0.1,
		guard_center - forward * guard_half_thickness * 0.92,
	])
	var body_flow_color: Color = base_color.lerp(ART_BLUE_CORE, 0.34)
	var body_flow_tip_color: Color = ART_GOLD.lerp(ART_BLUE_CORE, 0.22)
	var body_flow_presence := 0.0
	if sword_vfx != null:
		body_flow_presence = clampf(
			float(sword_vfx.body_flow_idle_strength) * 0.78
			+ local_glow_strength * (0.72 + 0.34 * float(sword_vfx.body_flow_speed_strength))
			+ focus_strength * 0.42,
			0.0,
			1.0
		)
		match glow_style:
			"point":
				body_flow_presence = clampf(body_flow_presence + 0.14, 0.0, 1.0)
			"slice":
				body_flow_color = body_flow_color.lerp(UNSHEATH_FLASH_WARM_COLOR, 0.14)
				body_flow_tip_color = body_flow_tip_color.lerp(ART_GOLD, 0.28)
			"recall":
				body_flow_color = main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.22)
				body_flow_tip_color = ART_GOLD.lerp(main.COLORS["array_sword_return"], 0.22)
	if body_flow_presence > 0.001:
		var shell_width_scale: float = float(sword_vfx.body_flow_shell_width_scale) if sword_vfx != null else 1.0
		var core_width_scale: float = float(sword_vfx.body_flow_core_width_scale) if sword_vfx != null else 1.0
		var shell_tip: Vector2 = blade_tip + forward * (2.8 + 4.6 * body_flow_presence)
		var shell_poly := PackedVector2Array([
			blade_root + side * root_half_width * (1.9 + 0.4 * shell_width_scale),
			shoulder_center + side * shoulder_half_width * (1.42 + 0.22 * shell_width_scale),
			shell_tip,
			shoulder_center - side * shoulder_half_width * (1.42 + 0.22 * shell_width_scale),
			blade_root - side * root_half_width * (1.9 + 0.4 * shell_width_scale),
		])
		var shell_alpha: float = 0.08 + 0.16 * body_flow_presence
		_try_draw_colored_polygon(main, shell_poly, _with_alpha(body_flow_color, shell_alpha))

		var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * (4.2 + 0.6 * float(sword_vfx.body_flow_scroll_speed)))
		var band_density: float = maxf(float(sword_vfx.body_flow_band_density), 0.1) if sword_vfx != null else 4.0
		var band_phase: float = fmod(main.elapsed_time * (0.18 + 0.035 * float(sword_vfx.body_flow_scroll_speed)), 1.0) if sword_vfx != null else 0.0
		var band_center_ratio: float = lerpf(0.24, 0.86, band_phase)
		var band_center: Vector2 = blade_root.lerp(blade_tip, band_center_ratio)
		var band_half_length: float = (2.8 + 1.2 * pulse + 0.06 * (12.0 - minf(band_density, 12.0))) * scale
		var band_half_width: float = (0.82 + 0.56 * body_flow_presence + 0.42 * core_width_scale) * scale
		var band_poly := PackedVector2Array([
			band_center - forward * band_half_length - side * band_half_width * 1.12,
			band_center - forward * band_half_length * 0.22 + side * band_half_width * 1.36,
			band_center + forward * band_half_length + side * band_half_width * 0.78,
			band_center + forward * band_half_length * 0.18 - side * band_half_width * 1.28,
		])
		_try_draw_colored_polygon(
			main,
			band_poly,
			_with_alpha(body_flow_tip_color.lerp(Color.WHITE, 0.1), 0.12 + 0.22 * body_flow_presence)
		)
	_try_draw_colored_polygon(main, blade_polygon, blade_color)
	if body_flow_presence > 0.001:
		var rail_alpha: float = 0.18 + 0.22 * body_flow_presence
		var upper_edge_color: Color = body_flow_color.lerp(Color.WHITE, 0.24)
		var lower_edge_color: Color = body_flow_color.lerp(body_flow_tip_color, 0.18)
		main.draw_line(
			shoulder_center + side * shoulder_half_width * 1.04,
			blade_tip,
			_with_alpha(upper_edge_color, rail_alpha),
			1.0 + 0.7 * body_flow_presence
		)
		main.draw_line(
			shoulder_center - side * shoulder_half_width * 1.02,
			blade_tip,
			_with_alpha(lower_edge_color, rail_alpha * 0.82),
			0.92 + 0.64 * body_flow_presence
		)
	_try_draw_colored_polygon(main, blade_core, _with_alpha(blade_core_color, 0.72 + 0.12 * focus_strength))
	_try_draw_colored_polygon(main, handle_polygon, handle_color)
	_try_draw_colored_polygon(main, guard_polygon, blade_edge_color.lerp(Color.WHITE, 0.12))
	main.draw_circle(handle_back, pommel_radius, blade_edge_color.lerp(Color.WHITE, 0.28))
	var guard_glint_pos: Vector2 = guard_center + forward * 1.7
	var guard_glint_alpha: float = 0.06 + 0.08 * local_glow_strength + 0.05 * focus_strength
	main.draw_circle(
		guard_glint_pos,
		0.85 * scale + 0.55 * local_glow_strength,
		_with_alpha(ART_GOLD.lerp(Color.WHITE, 0.18), guard_glint_alpha)
	)
	main.draw_line(
		guard_glint_pos - forward * 0.3,
		guard_glint_pos + forward * (4.4 + 1.6 * local_glow_strength) * scale,
		_with_alpha(ART_GOLD, guard_glint_alpha * 0.78),
		0.68 * scale
	)
	main.draw_line(
		handle_front - forward * 0.78,
		blade_tip - forward * 1.6,
		_with_alpha(blade_core_color.lerp(Color.WHITE, 0.22), 0.72 + 0.14 * focus_strength),
		0.78 + 0.48 * scale
	)
	main.draw_line(
		shoulder_center + side * shoulder_half_width * 0.84,
		blade_tip,
		_with_alpha(blade_edge_color, 0.18 + 0.12 * local_glow_strength + 0.08 * focus_strength),
		0.74 + 0.18 * scale
	)
	main.draw_line(
		shoulder_center - side * shoulder_half_width * 0.84,
		blade_tip,
		_with_alpha(blade_edge_color, 0.14 + 0.1 * local_glow_strength + 0.06 * focus_strength),
		0.7 + 0.16 * scale
	)


static func _draw_sword_impact_smear(
	main: Node2D,
	base_pos: Vector2,
	sword_pos: Vector2,
	forward: Vector2,
	base_color: Color,
	impact_ratio: float
) -> void:
	if impact_ratio <= 0.0:
		return
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var side: Vector2 = forward.rotated(PI * 0.5)
	var recoil: Vector2 = sword_pos - base_pos
	if recoil.is_zero_approx():
		recoil = -forward * (6.0 + 10.0 * impact_ratio)
	var recoil_dir: Vector2 = recoil.normalized()
	var smear_back: Vector2 = base_pos - recoil_dir * (8.0 + 16.0 * impact_ratio)
	var smear_tip: Vector2 = sword_pos + forward * (10.0 + 8.0 * impact_ratio)
	var outer_half_width: float = 4.6 + 5.6 * impact_ratio
	var inner_half_width: float = 1.8 + 2.4 * impact_ratio
	var outer_poly := PackedVector2Array([
		smear_back + side * outer_half_width,
		sword_pos + side * outer_half_width * 0.56,
		smear_tip,
		sword_pos - side * outer_half_width * 0.56,
		smear_back - side * outer_half_width,
	])
	var inner_poly := PackedVector2Array([
		base_pos + side * inner_half_width,
		sword_pos + side * inner_half_width * 0.72,
		smear_tip,
		sword_pos - side * inner_half_width * 0.72,
		base_pos - side * inner_half_width,
	])
	_try_draw_colored_polygon(main, outer_poly, _with_alpha(base_color.lerp(UNSHEATH_FLASH_WARM_COLOR, 0.26), 0.12 + 0.16 * impact_ratio))
	_try_draw_colored_polygon(main, inner_poly, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.16 + 0.2 * impact_ratio))
	main.draw_line(
		smear_back,
		smear_tip,
		_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.12 + 0.22 * impact_ratio),
		1.2 + 1.6 * impact_ratio
	)


static func _draw_sword_afterimages(main: Node2D) -> void:
	var trail_presence_scale: float = 0.62 if main.sword_trail_points.size() >= 3 else 1.0
	var focus_boost: float = 1.0
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
		var ghost_alpha: float = minf((0.05 + 0.2 * life_ratio) * main.SWORD_AFTERIMAGE_ALPHA_SCALE * trail_presence_scale * focus_boost, 1.0)
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


static func _draw_sword_air_wakes(main: Node2D) -> void:
	if _use_node_sword_flight_vfx(main):
		return
	if main.sword_air_wakes.is_empty():
		return
	for wake in main.sword_air_wakes:
		var life_ratio: float = clampf(float(wake.get("life", 0.0)) / maxf(float(wake.get("max_life", 1.0)), 0.001), 0.0, 1.0)
		if life_ratio <= 0.0:
			continue
		var center: Vector2 = main._to_screen(wake["pos"])
		var forward: Vector2 = Vector2(wake.get("forward", Vector2.RIGHT))
		if forward.is_zero_approx():
			forward = Vector2.RIGHT
		forward = forward.normalized()
		var outward: Vector2 = Vector2(wake.get("outward", forward.rotated(PI * 0.5)))
		if outward.is_zero_approx():
			outward = forward.rotated(PI * 0.5)
		outward = outward.normalized()
		var turn_strength: float = clampf(float(wake.get("turn_strength", 0.0)), 0.0, 1.0)
		var speed_ratio: float = clampf(float(wake.get("speed_ratio", 0.0)), 0.0, 1.0)
		var style: String = str(wake.get("style", "point"))
		var length: float = float(wake.get("length", main.SWORD_AIR_WAKE_BASE_LENGTH)) * (0.46 + 0.54 * life_ratio)
		var width: float = float(wake.get("width", main.SWORD_AIR_WAKE_BASE_WIDTH)) * (0.5 + 0.5 * life_ratio)
		var haze_color: Color = main.COLORS["ranged_sword"].lerp(UNSHEATH_FLASH_EDGE_COLOR, 0.22)
		var streak_color: Color = ART_BLUE_CORE.lerp(Color.WHITE, 0.22)
		if style == "recall":
			haze_color = main.COLORS["array_sword_return"].lerp(main.COLORS["ranged_sword"], 0.5)
			streak_color = main.COLORS["array_sword_return"].lerp(UNSHEATH_FLASH_CORE_COLOR, 0.44)
		var trace_start: Vector2 = center - forward * length * 0.62
		var trace_end: Vector2 = center + forward * length * (0.32 + 0.08 * turn_strength) + outward * width * (0.42 + 0.14 * speed_ratio)
		var trace_control: Vector2 = center + outward * width * (1.08 + 0.56 * turn_strength) - forward * length * 0.08
		_draw_quadratic_trace(
			main,
			trace_start,
			trace_control,
			trace_end,
			haze_color,
			streak_color,
			0.05 + 0.08 * life_ratio,
			0.08 + 0.12 * life_ratio,
			1.7 + 0.9 * speed_ratio,
			0.7 + 0.28 * turn_strength
		)


static func _draw_sword_trail(main: Node2D) -> void:
	if _use_node_sword_flight_vfx(main):
		return
	if main.sword_trail_points.size() < 2:
		return
	var segment_index: int = 1
	while segment_index < main.sword_trail_points.size():
		var older: Dictionary = main.sword_trail_points[segment_index - 1]
		var newer: Dictionary = main.sword_trail_points[segment_index]
		var older_ratio: float = clampf(float(older.get("life", 0.0)) / maxf(float(older.get("max_life", 1.0)), 0.001), 0.0, 1.0)
		var newer_ratio: float = clampf(float(newer.get("life", 0.0)) / maxf(float(newer.get("max_life", 1.0)), 0.001), 0.0, 1.0)
		if older_ratio <= 0.0 and newer_ratio <= 0.0:
			segment_index += 1
			continue
		var alpha_scale: float = 0.5 * (float(older.get("alpha_scale", 1.0)) + float(newer.get("alpha_scale", 1.0)))
		var from_pos: Vector2 = main._to_screen(older["pos"])
		var to_pos: Vector2 = main._to_screen(newer["pos"])
		var segment: Vector2 = to_pos - from_pos
		if segment.length_squared() <= 0.001:
			segment_index += 1
			continue
		var style: String = str(newer.get("style", older.get("style", "slice")))
		var trail_forward: Vector2 = Vector2(newer.get("forward", segment.normalized()))
		if trail_forward.is_zero_approx():
			trail_forward = segment.normalized()
		else:
			trail_forward = trail_forward.normalized()
		var side: Vector2 = segment.normalized().rotated(PI * 0.5)
		var from_half_width: float = float(older.get("half_width", main.SWORD_TRAIL_BASE_HALF_WIDTH)) * older_ratio
		var to_half_width: float = float(newer.get("half_width", main.SWORD_TRAIL_BASE_HALF_WIDTH)) * newer_ratio
		var segment_ratio: float = 0.5 * (older_ratio + newer_ratio)
		var turn_strength: float = maxf(float(older.get("turn_strength", 0.0)), float(newer.get("turn_strength", 0.0)))
		var haze_color: Color = main.COLORS["ranged_sword"].lerp(UNSHEATH_FLASH_EDGE_COLOR, 0.28)
		var ribbon_color: Color = main.COLORS["ranged_sword"].lerp(ART_BLUE_CORE, 0.12)
		var accent_color: Color = UNSHEATH_FLASH_WARM_COLOR
		if style == "recall":
			haze_color = main.COLORS["array_sword_return"].lerp(main.COLORS["ranged_sword"], 0.42)
			ribbon_color = main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.16)
			accent_color = ART_GOLD
		elif style == "slice":
			ribbon_color = ribbon_color.lerp(UNSHEATH_FLASH_WARM_COLOR, 0.08)
		if style == "point":
			var point_start: Vector2 = from_pos - trail_forward * (1.4 + 1.0 * segment_ratio)
			var point_end: Vector2 = to_pos + trail_forward * (8.0 + 12.0 * segment_ratio + 4.0 * turn_strength)
			var point_half_width: float = maxf(0.95, lerpf(from_half_width, to_half_width, 0.5) * (0.28 + 0.08 * turn_strength))
			_draw_luminous_sword_streak(
				main,
				point_start,
				point_end,
				point_half_width,
				haze_color.lerp(ART_BLUE, 0.12),
				ribbon_color.lerp(ART_BLUE_CORE, 0.18),
				ART_BLUE_CORE.lerp(Color.WHITE, 0.46),
				(0.08 + 0.14 * segment_ratio + 0.08 * turn_strength) * alpha_scale,
				(0.16 + 0.18 * segment_ratio) * alpha_scale,
				(0.24 + 0.28 * segment_ratio) * alpha_scale,
				(0.06 + 0.08 * segment_ratio) * alpha_scale,
				accent_color
			)
		elif style == "recall":
			var recall_start: Vector2 = from_pos - trail_forward * 0.6
			var recall_end: Vector2 = to_pos + trail_forward * (4.4 + 5.4 * segment_ratio)
			var recall_half_width: float = maxf(0.9, lerpf(from_half_width, to_half_width, 0.5) * 0.24)
			_draw_luminous_sword_streak(
				main,
				recall_start,
				recall_end,
				recall_half_width,
				haze_color,
				ribbon_color,
				UNSHEATH_FLASH_CORE_COLOR.lerp(Color.WHITE, 0.2),
				(0.08 + 0.12 * segment_ratio) * alpha_scale,
				(0.12 + 0.14 * segment_ratio) * alpha_scale,
				(0.16 + 0.18 * segment_ratio) * alpha_scale,
				(0.04 + 0.05 * segment_ratio) * alpha_scale,
				accent_color
			)
			main.draw_line(
				recall_start + side * recall_half_width * 0.56,
				recall_end + side * recall_half_width * 0.1,
				_with_alpha(ART_BLUE, (0.04 + 0.06 * segment_ratio) * alpha_scale),
				0.7 + 0.36 * segment_ratio
			)
			main.draw_line(
				recall_start - side * recall_half_width * 0.1,
				recall_end,
				_with_alpha(accent_color, (0.04 + 0.06 * segment_ratio) * alpha_scale),
				0.62 + 0.28 * segment_ratio
			)
		else:
			var slice_start: Vector2 = from_pos - trail_forward * (1.2 + 1.4 * turn_strength)
			var slice_end: Vector2 = to_pos + trail_forward * (6.0 + 7.0 * segment_ratio)
			var slice_half_width: float = maxf(1.0, lerpf(from_half_width, to_half_width, 0.5) * (0.34 + 0.06 * turn_strength))
			_draw_luminous_sword_streak(
				main,
				slice_start,
				slice_end,
				slice_half_width,
				haze_color.lerp(ART_BLUE, 0.08),
				ribbon_color,
				UNSHEATH_FLASH_CORE_COLOR.lerp(Color.WHITE, 0.2),
				(0.08 + 0.14 * segment_ratio + 0.06 * turn_strength) * alpha_scale,
				(0.12 + 0.16 * segment_ratio) * alpha_scale,
				(0.16 + 0.18 * segment_ratio) * alpha_scale,
				(0.04 + 0.06 * segment_ratio) * alpha_scale,
				accent_color
			)
		segment_index += 1
	var head_point: Dictionary = main.sword_trail_points[main.sword_trail_points.size() - 1]
	var head_ratio: float = clampf(float(head_point.get("life", 0.0)) / maxf(float(head_point.get("max_life", 1.0)), 0.001), 0.0, 1.0)
	if head_ratio > 0.0:
		var head_pos: Vector2 = main._to_screen(head_point["pos"])
		var head_forward: Vector2 = Vector2(head_point.get("forward", Vector2.RIGHT))
		if head_forward.is_zero_approx():
			head_forward = Vector2.RIGHT
		head_forward = head_forward.normalized()
		var head_side: Vector2 = head_forward.rotated(PI * 0.5)
		var head_half_width: float = float(head_point.get("half_width", main.SWORD_TRAIL_BASE_HALF_WIDTH))
		var head_style: String = str(head_point.get("style", "slice"))
		if head_style == "point":
			var spear_tip := PackedVector2Array([
				head_pos + head_forward * (9.0 + 8.0 * head_ratio),
				head_pos - head_forward * 1.6 + head_side * head_half_width * 0.18,
				head_pos - head_forward * 1.6 - head_side * head_half_width * 0.18,
			])
			_try_draw_colored_polygon(main, spear_tip, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.24 + 0.2 * head_ratio))
			main.draw_line(
				head_pos - head_forward * 0.5,
				head_pos + head_forward * (8.0 + 9.0 * head_ratio),
				_with_alpha(UNSHEATH_FLASH_WARM_COLOR, 0.08 + 0.1 * head_ratio),
				0.9 + 0.4 * head_ratio
			)
		elif head_style == "recall":
			var comet_tip := PackedVector2Array([
				head_pos + head_forward * (7.0 + 6.0 * head_ratio),
				head_pos - head_forward * 2.2 + head_side * head_half_width * 0.12,
				head_pos - head_forward * 2.2 - head_side * head_half_width * 0.12,
			])
			_try_draw_colored_polygon(main, comet_tip, _with_alpha(main.COLORS["array_sword_return"].lerp(UNSHEATH_FLASH_CORE_COLOR, 0.34), 0.18 + 0.18 * head_ratio))
			main.draw_circle(
				head_pos,
				2.0 + 2.0 * head_ratio,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.1 + 0.12 * head_ratio)
			)
		else:
			var blade_tip := PackedVector2Array([
				head_pos + head_forward * (6.0 + 6.0 * head_ratio) + head_side * head_half_width * 0.14,
				head_pos - head_forward * 2.0 + head_side * head_half_width * 0.3,
				head_pos - head_forward * 3.0 - head_side * head_half_width * 0.22,
				head_pos + head_forward * 3.0 - head_side * head_half_width * 0.12,
			])
			_try_draw_colored_polygon(main, blade_tip, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.14 + 0.16 * head_ratio))


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
		_draw_hit_contact_glyph(main, center, forward, effect_color, style, intensity)
		if style == "sever":
			var sever_from: Vector2 = main._to_screen(hit_effect.get("from", hit_effect["pos"]))
			var sever_to: Vector2 = main._to_screen(hit_effect.get("to", hit_effect["pos"]))
			var sever_axis: Vector2 = sever_to - sever_from
			if sever_axis.is_zero_approx():
				sever_axis = forward
			else:
				sever_axis = sever_axis.normalized()
			var retract_axis: Vector2 = sever_axis.rotated(PI * 0.5)
			var is_main_sever: bool = bool(hit_effect.get("is_main", false))
			var retract_distance: float = (1.0 - life_ratio) * (22.0 if is_main_sever else 10.0)
			var gap_size: float = 8.0 + 10.0 * intensity
			var left_end: Vector2 = center - sever_axis * gap_size - retract_axis * retract_distance
			var right_start: Vector2 = center + sever_axis * gap_size + retract_axis * retract_distance
			main.draw_line(
				sever_from,
				left_end,
				_with_alpha(effect_color, 0.18 + 0.24 * intensity),
				1.4 + 1.4 * intensity
			)
			main.draw_line(
				right_start,
				sever_to,
				_with_alpha(effect_color, 0.18 + 0.24 * intensity),
				1.4 + 1.4 * intensity
			)
			main.draw_line(
				center - cut_normal * cut_width * 0.92,
				center + cut_normal * cut_width * 0.92,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.24 + 0.28 * intensity),
				1.2 + 0.8 * intensity
			)
			main.draw_circle(
				center,
				3.0 + 3.0 * intensity,
				_with_alpha(effect_color.lerp(UNSHEATH_FLASH_CORE_COLOR, 0.26), 0.08 + 0.1 * intensity)
			)
		elif style == "point":
			var pierce_tip := PackedVector2Array([
				center + forward * cut_half_length * 1.12,
				center + forward * cut_half_length * 0.34 + cut_normal * cut_width * 0.22,
				center + forward * cut_half_length * 0.34 - cut_normal * cut_width * 0.22,
			])
			_try_draw_colored_polygon(main, pierce_tip, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.22 + 0.24 * intensity))
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
			main.draw_arc(
				center + forward * cut_half_length * 0.18,
				2.6 + cut_width * 0.72,
				0.0,
				TAU,
				18,
				_with_alpha(effect_color, 0.08 + 0.12 * intensity),
				1.0
			)
		elif style == "deflect":
			main.draw_line(
				center - forward * cut_half_length * 0.42,
				center + forward * cut_half_length * 0.72,
				_with_alpha(effect_color.lerp(UNSHEATH_FLASH_CORE_COLOR, 0.24), 0.16 + 0.24 * intensity),
				maxf(cut_width * 0.44, 1.0)
			)
			main.draw_line(
				center - cut_normal * cut_width * 1.08,
				center + cut_normal * cut_width * 1.08,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.2 + 0.22 * intensity),
				1.0 + 0.7 * intensity
			)
			main.draw_arc(
				center,
				3.0 + cut_width * 0.82,
				0.0,
				TAU,
				18,
				_with_alpha(effect_color, 0.08 + 0.14 * intensity),
				1.0 + 0.4 * intensity
			)
			main.draw_line(
				center - forward * cut_half_length * 0.52 - cut_normal * cut_width * 0.92,
				center + forward * cut_half_length * 0.36 + cut_normal * cut_width * 0.82,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.1 + 0.16 * intensity),
				0.9 + 0.5 * intensity
			)
			main.draw_line(
				center - forward * cut_half_length * 0.52 + cut_normal * cut_width * 0.92,
				center + forward * cut_half_length * 0.36 - cut_normal * cut_width * 0.82,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.1 + 0.16 * intensity),
				0.9 + 0.5 * intensity
			)
		elif style == "melee":
			var slash_axis: Vector2 = forward.rotated(-0.16)
			var melee_body := PackedVector2Array([
				center - slash_axis * cut_half_length * 0.92 + cut_normal * cut_width * 0.42,
				center - slash_axis * cut_half_length * 0.76 - cut_normal * cut_width * 0.28,
				center + slash_axis * cut_half_length * 0.98 - cut_normal * cut_width * 0.2,
				center + slash_axis * cut_half_length * 0.84 + cut_normal * cut_width * 0.32,
			])
			_try_draw_colored_polygon(main, melee_body, _with_alpha(effect_color.lerp(UNSHEATH_FLASH_WARM_COLOR, 0.34), 0.16 + 0.22 * intensity))
			main.draw_line(
				center - slash_axis * cut_half_length * 0.66,
				center + slash_axis * cut_half_length * 0.74,
				_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.26 + 0.28 * intensity),
				maxf(cut_width * 0.24, 1.0)
			)
			main.draw_line(
				center - cut_normal * cut_width * 0.38,
				center + cut_normal * cut_width * 0.52,
				_with_alpha(UNSHEATH_FLASH_WARM_COLOR, 0.08 + 0.12 * intensity),
				0.8 + 0.5 * intensity
			)
			main.draw_arc(
				center + slash_axis * cut_half_length * 0.08,
				5.0 + cut_width * 0.68,
				slash_axis.angle() - 0.6,
				slash_axis.angle() + 0.72,
				18,
				_with_alpha(effect_color, 0.08 + 0.12 * intensity),
				1.0 + 0.4 * intensity
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
			main.draw_line(
				center - slash_axis * cut_half_length * 0.18 - cut_normal * cut_width * 0.42,
				center + slash_axis * cut_half_length * 0.78 - cut_normal * cut_width * 0.16,
				_with_alpha(effect_color, 0.08 + 0.12 * intensity),
				0.9 + 0.4 * intensity
			)
		var spark_index: int = 0
		while spark_index < spark_count:
			var spark_ratio: float = 0.5 if spark_count <= 1 else float(spark_index) / float(spark_count - 1)
			var spread: float = lerpf(-0.22, 0.22, spark_ratio) + sin(seed + float(spark_index) * 1.9) * 0.05
			var spark_dir: Vector2 = forward.rotated(spread)
			var spark_start: Vector2 = center
			if style == "slice" or style == "melee":
				spark_dir = forward.rotated(lerpf(-0.16, 0.14, spark_ratio) + sin(seed + float(spark_index) * 1.3) * 0.04)
				spark_start = center + forward * lerpf(-cut_half_length * 0.24, cut_half_length * 0.24, spark_ratio) + cut_normal * sin(seed + float(spark_index) * 2.1) * cut_width * 0.08
			elif style == "sever":
				spark_dir = cut_normal.rotated(lerpf(-0.38, 0.38, spark_ratio) + sin(seed + float(spark_index) * 1.6) * 0.08)
				spark_start = center + forward * sin(seed + float(spark_index) * 2.2) * cut_half_length * 0.18
			elif style == "deflect":
				spark_dir = cut_normal.rotated(lerpf(-0.26, 0.26, spark_ratio) + sin(seed + float(spark_index) * 1.4) * 0.06)
				spark_start = center
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


static func _draw_hit_contact_glyph(
	main: Node2D,
	center: Vector2,
	forward: Vector2,
	effect_color: Color,
	style: String,
	intensity: float
) -> void:
	var side: Vector2 = forward.rotated(PI * 0.5)
	var radius: float = 5.0 + 9.0 * intensity
	var glyph_color: Color = effect_color.lerp(UNSHEATH_FLASH_CORE_COLOR, 0.42)
	var ring_alpha: float = 0.08 + 0.16 * intensity
	main.draw_arc(center, radius, 0.0, TAU, 20, _with_alpha(glyph_color, ring_alpha), 1.0 + 0.7 * intensity)
	if style == "point":
		main.draw_line(center - forward * radius * 0.8, center + forward * radius * 1.35, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.18 + 0.22 * intensity), 1.0)
		main.draw_line(center - side * radius * 0.36, center + side * radius * 0.36, _with_alpha(glyph_color, 0.1 + 0.14 * intensity), 0.9)
		var pierce_head := PackedVector2Array([
			center + forward * radius * 1.2,
			center + forward * radius * 0.34 + side * radius * 0.16,
			center + forward * radius * 0.34 - side * radius * 0.16,
		])
		_try_draw_colored_polygon(main, pierce_head, _with_alpha(glyph_color.lerp(UNSHEATH_FLASH_CORE_COLOR, 0.24), 0.12 + 0.16 * intensity))
	elif style == "deflect":
		main.draw_line(center - side * radius, center + side * radius, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.2 + 0.2 * intensity), 1.2)
		main.draw_arc(center, radius * 0.78, -PI * 0.2, PI * 1.2, 18, _with_alpha(glyph_color, 0.12 + 0.14 * intensity), 1.0)
		main.draw_line(center - forward * radius * 0.86, center + forward * radius * 0.86, _with_alpha(glyph_color, 0.1 + 0.14 * intensity), 1.0)
		main.draw_line(center - forward * radius * 0.62 - side * radius * 0.62, center + forward * radius * 0.62 + side * radius * 0.62, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.08 + 0.12 * intensity), 0.9)
		main.draw_line(center - forward * radius * 0.62 + side * radius * 0.62, center + forward * radius * 0.62 - side * radius * 0.62, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.08 + 0.12 * intensity), 0.9)
	elif style == "sever":
		main.draw_arc(center, radius * 0.78, -PI * 0.42, PI * 0.42, 14, _with_alpha(glyph_color, 0.12 + 0.16 * intensity), 1.0)
		main.draw_arc(center, radius * 0.78, PI * 0.58, PI * 1.42, 14, _with_alpha(glyph_color, 0.12 + 0.16 * intensity), 1.0)
		main.draw_line(center - side * radius * 0.86, center + side * radius * 0.86, _with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.14 + 0.16 * intensity), 1.0)
	else:
		var diamond := PackedVector2Array([
			center + forward * radius,
			center + side * radius * 0.62,
			center - forward * radius * 0.72,
			center - side * radius * 0.62,
		])
		_try_draw_polyline_closed(main, diamond, _with_alpha(glyph_color, 0.1 + 0.16 * intensity), 1.0 + 0.6 * intensity)


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


static func _draw_resonance_player_mark(main: Node2D, player_pos: Vector2) -> void:
	var mode: String = main._get_resonance_mode()
	var strength: float = main._get_resonance_strength()
	if mode == "" or strength <= 0.01:
		return
	var color: Color = main._get_resonance_color(mode)
	var flash: float = main._get_resonance_flash_strength()
	var preview: float = main._get_resonance_preview_strength()
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * (10.0 if preview > 0.01 else 4.6))
	var alpha_scale: float = clampf(strength * (0.72 + 0.24 * pulse) + flash * 0.34 + preview * 0.28, 0.0, 1.0)
	var aim_dir: Vector2 = main.mouse_world - main.player["pos"]
	if aim_dir.is_zero_approx():
		aim_dir = Vector2.RIGHT
	aim_dir = aim_dir.normalized()
	match mode:
		SwordArrayConfig.MODE_RING:
			var ring_radius: float = main.PLAYER_RADIUS + 18.0 + flash * 12.0 + preview * 5.0
			main.draw_circle(player_pos, ring_radius + 5.0, _with_alpha(color, 0.025 * alpha_scale))
			main.draw_arc(player_pos, ring_radius, 0.0, TAU, 48, _with_alpha(color, 0.34 * alpha_scale), 2.0 + preview * 1.8)
			main.draw_arc(player_pos, ring_radius + 10.0, main.elapsed_time * 0.8, main.elapsed_time * 0.8 + TAU * 0.72, 42, _with_alpha(color.lerp(ART_BLUE_CORE, 0.24), 0.14 * alpha_scale), 1.4)
		SwordArrayConfig.MODE_FAN:
			var fan_radius: float = main.PLAYER_RADIUS + 54.0 + flash * 10.0
			var fan_angle: float = aim_dir.angle()
			var arc_width: float = 0.64 + preview * 0.24
			main.draw_arc(player_pos, fan_radius, fan_angle - arc_width, fan_angle + arc_width, 28, _with_alpha(color, 0.33 * alpha_scale), 2.4 + preview * 1.2)
			for offset in [-0.48, 0.0, 0.48]:
				var ray: Vector2 = Vector2.RIGHT.rotated(fan_angle + offset)
				main.draw_line(player_pos + ray * (main.PLAYER_RADIUS + 8.0), player_pos + ray * fan_radius, _with_alpha(color.lerp(ART_BLUE_CORE, 0.18), 0.16 * alpha_scale), 1.6)
		SwordArrayConfig.MODE_PIERCE:
			var line_len: float = 104.0 + flash * 28.0 + preview * 34.0
			var start_pos: Vector2 = player_pos + aim_dir * (main.PLAYER_RADIUS + 12.0)
			var end_pos: Vector2 = player_pos + aim_dir * line_len
			main.draw_line(start_pos, end_pos, _with_alpha(color, 0.36 * alpha_scale), 2.2 + preview * 1.8)
			main.draw_line(start_pos, end_pos, _with_alpha(ART_BLUE_CORE, 0.15 * alpha_scale), 0.9)
			main.draw_circle(end_pos, 3.6 + preview * 2.4, _with_alpha(color.lerp(ART_BLUE_CORE, 0.24), 0.34 * alpha_scale))


static func _get_combo_strength(holder: Dictionary) -> float:
	var combo_id: String = String(holder.get("combo_id", ""))
	if combo_id == "":
		return 0.0
	if String(holder.get("combo_phase", "")) == "drawing":
		return 1.0
	var timer: float = maxf(float(holder.get("combo_timer", 0.0)), 0.0)
	var duration: float = maxf(float(holder.get("combo_duration", timer)), 0.001)
	if timer <= 0.0:
		return 0.0
	return clampf(timer / duration, 0.0, 1.0)


static func _draw_ring_to_pierce_array_combo(main: Node2D, sword_pos: Vector2, forward: Vector2, strength: float) -> void:
	var color: Color = SwordResonanceController.get_color(SwordArrayConfig.MODE_RING)
	var pierce_color: Color = SwordResonanceController.get_color(SwordArrayConfig.MODE_PIERCE)
	var clamped_strength: float = clampf(strength, 0.0, 1.0)
	var resolved_forward: Vector2 = forward.normalized()
	if resolved_forward.is_zero_approx():
		resolved_forward = Vector2.RIGHT
	_draw_luminous_sword_streak(
		main,
		sword_pos - resolved_forward * (32.0 + 22.0 * clamped_strength),
		sword_pos + resolved_forward * (46.0 + 28.0 * clamped_strength),
		4.4 + 2.2 * clamped_strength,
		color.lerp(pierce_color, 0.32),
		pierce_color.lerp(ART_BLUE_CORE, 0.24),
		ART_BLUE_CORE,
		0.08 + 0.12 * clamped_strength,
		0.14 + 0.18 * clamped_strength,
		0.20 + 0.22 * clamped_strength,
		0.04 + 0.04 * clamped_strength,
		color
	)
	main.draw_arc(sword_pos, 11.0 + 9.0 * clamped_strength, 0.0, TAU, 24, _with_alpha(color, 0.16 + 0.2 * clamped_strength), 1.4 + 1.4 * clamped_strength)
	main.draw_line(sword_pos - resolved_forward * 18.0, sword_pos + resolved_forward * (42.0 + 30.0 * clamped_strength), _with_alpha(pierce_color.lerp(ART_BLUE_CORE, 0.24), 0.20 + 0.24 * clamped_strength), 2.2 + 1.6 * clamped_strength)


static func _draw_fan_time_stop_combo(main: Node2D, sword_pos: Vector2, forward: Vector2, strength: float) -> void:
	var color: Color = SwordResonanceController.get_color(SwordArrayConfig.MODE_FAN)
	var clamped_strength: float = clampf(strength, 0.0, 1.0)
	var resolved_forward: Vector2 = forward.normalized()
	if resolved_forward.is_zero_approx():
		resolved_forward = Vector2.RIGHT
	var side: Vector2 = resolved_forward.orthogonal()
	var uses_node_clones: bool = main.has_method("_has_fan_time_stop_clone_flight_fx") and bool(main.call("_has_fan_time_stop_clone_flight_fx"))
	if not uses_node_clones:
		for side_sign in [-1.0, 1.0]:
			var offset: Vector2 = side * side_sign * (main.FAN_TIME_STOP_CLONE_SIDE_OFFSET_BASE + main.FAN_TIME_STOP_CLONE_SIDE_OFFSET_SCALE * clamped_strength)
			var ghost_pos: Vector2 = sword_pos + offset - resolved_forward * (main.FAN_TIME_STOP_CLONE_FORWARD_OFFSET * side_sign)
			_draw_fan_time_stop_sword_clone(main, ghost_pos, resolved_forward, clamped_strength)
	var fan_radius: float = 54.0 + 20.0 * clamped_strength
	main.draw_arc(sword_pos, fan_radius, resolved_forward.angle() - 0.72, resolved_forward.angle() + 0.72, 32, _with_alpha(color, 0.14 + 0.16 * clamped_strength), 2.0)


static func _draw_fan_time_stop_sword_clone(main: Node2D, sword_pos: Vector2, forward: Vector2, strength: float) -> void:
	var vfx = _get_sword_vfx(main)
	var clamped_strength: float = clampf(strength, 0.0, 1.0)
	var speed_ratio: float = clampf(Vector2(main.sword.get("vel", Vector2.ZERO)).length() / maxf(main.SWORD_POINT_STRIKE_SPEED, 0.001), 0.45, 1.0)
	var clone_alpha: float = 0.5 + 0.42 * clamped_strength
	var base_color: Color = main.COLORS["ranged_sword"]
	var trail_half_width: float = maxf(float(vfx.trail_base_half_width) * float(vfx.trail_point_width_scale) * 0.52, 3.2)
	var trail_start: Vector2 = sword_pos - forward * (58.0 + 34.0 * speed_ratio)
	var trail_end: Vector2 = sword_pos - forward * (9.0 + 5.0 * speed_ratio)
	_draw_luminous_sword_streak(
		main,
		trail_start,
		trail_end,
		trail_half_width,
		base_color.lerp(ART_BLUE, 0.24),
		ART_BLUE.lerp(ART_BLUE_CORE, 0.24),
		ART_BLUE_CORE.lerp(Color.WHITE, 0.28),
		(0.12 + 0.12 * speed_ratio) * clone_alpha,
		(0.22 + 0.18 * speed_ratio) * clone_alpha,
		(0.36 + 0.18 * speed_ratio) * clone_alpha,
		(0.04 + 0.04 * speed_ratio) * clone_alpha,
		ART_GOLD
	)
	var front_length: float = lerpf(float(vfx.front_length_min), float(vfx.front_length_max), speed_ratio)
	var front_width: float = lerpf(float(vfx.front_width_min), float(vfx.front_width_max), speed_ratio) * 0.42
	_draw_luminous_sword_streak(
		main,
		sword_pos - forward * (1.0 + 1.6 * speed_ratio),
		sword_pos + forward * (front_length * 0.92 + 12.0 * clamped_strength),
		front_width,
		base_color.lerp(ART_BLUE, 0.18),
		base_color.lerp(ART_BLUE_CORE, 0.24),
		ART_BLUE_CORE.lerp(Color.WHITE, 0.36),
		(0.08 + 0.1 * speed_ratio) * clone_alpha,
		(0.14 + 0.16 * speed_ratio) * clone_alpha,
		(0.22 + 0.22 * speed_ratio) * clone_alpha,
		(0.04 + 0.05 * speed_ratio) * clone_alpha,
		UNSHEATH_FLASH_WARM_COLOR
	)
	_draw_sword_body(
		main,
		sword_pos,
		forward,
		_with_alpha(base_color.lerp(ART_BLUE_CORE, 0.12), clone_alpha),
		1.46,
		0.26 + 0.34 * clamped_strength,
		maxf(float(vfx.local_glow_point_base), 0.34) + 0.28 * clamped_strength,
		"point"
	)


static func _draw_pierce_time_stop_combo(main: Node2D, sword_pos: Vector2, forward: Vector2, strength: float) -> void:
	var color: Color = SwordResonanceController.get_color(SwordArrayConfig.MODE_PIERCE)
	var clamped_strength: float = clampf(strength, 0.0, 1.0)
	var is_drawing: bool = String(main.sword.get("combo_phase", "")) == "drawing"
	var resolved_forward: Vector2 = forward.normalized()
	if resolved_forward.is_zero_approx():
		resolved_forward = Vector2.RIGHT
	var raw_points: Array = main.sword.get("combo_points", [])
	var locked_points: Array = []
	if not is_drawing:
		locked_points = main.sword.get("combo_locked_points", [])
		if not locked_points.is_empty():
			raw_points = locked_points
	var line_strength: float = clamped_strength if is_drawing else clampf(0.38 + clamped_strength * 0.24, 0.0, 0.62)
	var line_alpha_strength: float = clamped_strength if is_drawing else clampf(0.24 + clamped_strength * 0.26, 0.0, 0.5)
	var previous_screen: Vector2 = Vector2.INF
	var point_index: int = 0
	for point_variant in raw_points:
		var point: Vector2 = main._to_screen(Vector2(point_variant))
		if previous_screen.x != INF:
			var line_alpha: float = 0.055 + 0.1 * line_alpha_strength
			var line_width: float = 1.15 + 0.55 * line_strength
			if is_drawing:
				var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 18.0 + float(point_index) * 0.8)
				line_alpha += 0.035 * pulse
				line_width += 0.3 * pulse
			main.draw_line(previous_screen, point, _with_alpha(color, line_alpha), line_width)
			main.draw_line(previous_screen, point, _with_alpha(ART_BLUE_CORE, 0.035 + 0.065 * line_alpha_strength), 0.7 + (0.15 if is_drawing else 0.0))
		if is_drawing and point_index % 3 == 0:
			main.draw_circle(point, 1.1 + 0.5 * clamped_strength, _with_alpha(color.lerp(ART_BLUE_CORE, 0.2), 0.08 + 0.06 * clamped_strength))
		previous_screen = point
		point_index += 1
	if raw_points.size() < 2:
		main.draw_line(sword_pos - resolved_forward * 28.0, sword_pos + resolved_forward * (72.0 + 28.0 * clamped_strength), _with_alpha(color, 0.08 + 0.1 * clamped_strength), 1.4)
	var head_pos: Vector2 = main._to_screen(main.mouse_world)
	if not is_drawing and not raw_points.is_empty():
		head_pos = main._to_screen(Vector2(raw_points[raw_points.size() - 1]))
	elif not is_drawing:
		head_pos = sword_pos + resolved_forward * (28.0 + 18.0 * clamped_strength)
	main.draw_circle(head_pos, 2.8 + 1.8 * line_strength + (0.7 if is_drawing else 0.0), _with_alpha(color.lerp(ART_BLUE_CORE, 0.32), 0.1 + 0.14 * line_alpha_strength))
	if is_drawing:
		main.draw_arc(head_pos, 8.5 + 2.0 * clamped_strength, main.elapsed_time * 1.8, main.elapsed_time * 1.8 + TAU * 0.74, 28, _with_alpha(color, 0.12), 0.9)


static func _draw_hud_resonance_mark(main: Node2D, center: Vector2) -> void:
	var mode: String = main._get_resonance_mode()
	var strength: float = main._get_resonance_strength()
	if mode == "" or strength <= 0.01:
		return
	var color: Color = main._get_resonance_color(mode)
	var progress: float = main._get_resonance_progress()
	var flash: float = main._get_resonance_flash_strength()
	var preview: float = main._get_resonance_preview_strength()
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 8.6)
	var radius: float = 27.0 + flash * 4.0 + preview * 2.0
	main.draw_circle(center, radius + 14.0, _with_alpha(color, 0.08 + 0.06 * preview + 0.04 * pulse))
	main.draw_circle(center, radius + 4.0, _with_alpha(color.lerp(ART_BLUE_CORE, 0.14), 0.07 + 0.08 * strength))
	main.draw_circle(center, radius, _with_alpha(ART_BG_DEEP, 0.7))
	main.draw_arc(center, radius, 0.0, TAU, 56, _with_alpha(color, 0.34), 1.8)
	main.draw_arc(center, radius + 7.0, -main.elapsed_time * 1.4, -main.elapsed_time * 1.4 + TAU * 0.68, 46, _with_alpha(color.lerp(ART_BLUE_CORE, 0.24), 0.22 + 0.12 * pulse), 1.6)
	if progress > 0.0:
		main.draw_arc(center, radius + 2.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 56, _with_alpha(color.lerp(ART_BLUE_CORE, 0.2), 0.76), 3.0)
	match mode:
		SwordArrayConfig.MODE_RING:
			main.draw_arc(center, 10.0, 0.0, TAU, 30, _with_alpha(color, 0.88), 2.6)
			main.draw_arc(center, 17.0, main.elapsed_time * 1.1, main.elapsed_time * 1.1 + TAU * 0.55, 24, _with_alpha(color.lerp(ART_BLUE_CORE, 0.28), 0.52), 1.7)
			main.draw_circle(center, 3.4, _with_alpha(ART_BLUE_CORE, 0.86))
		SwordArrayConfig.MODE_FAN:
			var base_angle: float = -PI * 0.32
			main.draw_arc(center, 16.0, base_angle, PI * 0.32, 24, _with_alpha(color, 0.88), 2.6)
			for offset in [-0.46, -0.23, 0.0, 0.23, 0.46]:
				main.draw_line(center + Vector2(-6.0, 8.0), center + Vector2.RIGHT.rotated(-PI * 0.5 + offset) * 17.0, _with_alpha(color.lerp(ART_BLUE_CORE, 0.16), 0.66), 1.6)
		SwordArrayConfig.MODE_PIERCE:
			main.draw_line(center + Vector2(-13.0, 11.0), center + Vector2(14.0, -12.0), _with_alpha(color, 0.92), 4.0)
			main.draw_line(center + Vector2(-6.0, 12.0), center + Vector2(18.0, -8.0), _with_alpha(ART_BLUE_CORE, 0.34), 1.5)
			main.draw_circle(center + Vector2(15.0, -13.0), 4.0, _with_alpha(ART_BLUE_CORE, 0.86))
	if main._is_resonance_expiring():
		var blink: float = 0.5 + 0.5 * sin(main.elapsed_time * 16.0)
		main.draw_arc(center, radius + 11.0, 0.0, TAU, 44, _with_alpha(color, 0.12 + 0.26 * blink), 2.0)


static func _draw_resonance_sword_mark(
	main: Node2D,
	sword_pos: Vector2,
	forward: Vector2,
	side: Vector2,
	mode: String,
	color: Color,
	strength: float
) -> void:
	if mode == "" or strength <= 0.01:
		return
	var clamped_strength: float = clampf(strength, 0.0, 1.0)
	var resolved_forward: Vector2 = forward.normalized()
	if resolved_forward.is_zero_approx():
		resolved_forward = Vector2.RIGHT
	var resolved_side: Vector2 = side.normalized()
	if resolved_side.is_zero_approx():
		resolved_side = resolved_forward.orthogonal()
	match mode:
		SwordArrayConfig.MODE_RING:
			main.draw_arc(sword_pos, 8.0 + 4.0 * clamped_strength, 0.0, TAU, 22, _with_alpha(color, 0.36 * clamped_strength), 1.6 + 1.4 * clamped_strength)
			main.draw_circle(sword_pos, 4.0 + 2.0 * clamped_strength, _with_alpha(color.lerp(ART_BLUE_CORE, 0.28), 0.08 + 0.14 * clamped_strength))
		SwordArrayConfig.MODE_FAN:
			var base_pos: Vector2 = sword_pos - resolved_forward * 5.0
			main.draw_line(base_pos, sword_pos + resolved_forward * 12.0 + resolved_side * 7.0, _with_alpha(color, 0.42 * clamped_strength), 1.7 + clamped_strength)
			main.draw_line(base_pos, sword_pos + resolved_forward * 12.0 - resolved_side * 7.0, _with_alpha(color, 0.42 * clamped_strength), 1.7 + clamped_strength)
			main.draw_arc(sword_pos + resolved_forward * 3.0, 9.0 + 3.0 * clamped_strength, resolved_forward.angle() - 0.56, resolved_forward.angle() + 0.56, 16, _with_alpha(color.lerp(ART_BLUE_CORE, 0.16), 0.18 * clamped_strength), 1.2)
		SwordArrayConfig.MODE_PIERCE:
			main.draw_line(sword_pos - resolved_forward * 10.0, sword_pos + resolved_forward * (18.0 + 9.0 * clamped_strength), _with_alpha(color, 0.48 * clamped_strength), 1.8 + 1.3 * clamped_strength)
			main.draw_line(sword_pos - resolved_forward * 5.0 + resolved_side * 3.0, sword_pos + resolved_forward * (16.0 + 8.0 * clamped_strength) + resolved_side * 3.0, _with_alpha(ART_BLUE_CORE, 0.18 * clamped_strength), 0.9 + 0.6 * clamped_strength)
			main.draw_circle(sword_pos + resolved_forward * (19.0 + 9.0 * clamped_strength), 2.8 + clamped_strength, _with_alpha(color.lerp(ART_BLUE_CORE, 0.22), 0.42 * clamped_strength))


static func _draw_resonance_main_sword_mark(
	main: Node2D,
	sword_pos: Vector2,
	forward: Vector2,
	mode: String,
	color: Color,
	strength: float
) -> void:
	if mode == "" or strength <= 0.01:
		return
	var resolved_forward: Vector2 = forward.normalized()
	if resolved_forward.is_zero_approx():
		resolved_forward = Vector2.RIGHT
	var side: Vector2 = resolved_forward.orthogonal()
	var clamped_strength: float = clampf(strength, 0.0, 1.0)
	_draw_resonance_sword_mark(main, sword_pos, resolved_forward, side, mode, color, clamped_strength)
	if mode == SwordArrayConfig.MODE_FAN:
		for side_sign in [-1.0, 1.0]:
			var ghost_pos: Vector2 = sword_pos + side * side_sign * (12.0 + 7.0 * clamped_strength)
			main.draw_line(
				ghost_pos - resolved_forward * 16.0,
				ghost_pos + resolved_forward * 18.0,
				_with_alpha(color.lerp(ART_BLUE_CORE, 0.14), 0.14 + 0.22 * clamped_strength),
				2.0
			)
	elif mode == SwordArrayConfig.MODE_PIERCE:
		main.draw_line(
			sword_pos - resolved_forward * 24.0,
			sword_pos + resolved_forward * (52.0 + 22.0 * clamped_strength),
			_with_alpha(color, 0.18 + 0.24 * clamped_strength),
			2.4 + 1.6 * clamped_strength
		)


static func _draw_arena_margin_mask(main: Node2D) -> void:
	var viewport_rect: Rect2 = main.get_viewport_rect()
	var arena_rect: Rect2 = main.ARENA_RECT
	var mask_color: Color = ART_BG_DEEP.lerp(ART_BG, 0.22)
	var top_height: float = maxf(arena_rect.position.y - viewport_rect.position.y, 0.0)
	var bottom_height: float = maxf(viewport_rect.end.y - arena_rect.end.y, 0.0)
	var left_width: float = maxf(arena_rect.position.x - viewport_rect.position.x, 0.0)
	var right_width: float = maxf(viewport_rect.end.x - arena_rect.end.x, 0.0)
	if top_height > 0.0:
		main.draw_rect(Rect2(viewport_rect.position, Vector2(viewport_rect.size.x, top_height)), mask_color, true)
	if bottom_height > 0.0:
		main.draw_rect(Rect2(Vector2(viewport_rect.position.x, arena_rect.end.y), Vector2(viewport_rect.size.x, bottom_height)), mask_color, true)
	if left_width > 0.0:
		main.draw_rect(Rect2(Vector2(viewport_rect.position.x, arena_rect.position.y), Vector2(left_width, arena_rect.size.y)), mask_color, true)
	if right_width > 0.0:
		main.draw_rect(Rect2(Vector2(arena_rect.end.x, arena_rect.position.y), Vector2(right_width, arena_rect.size.y)), mask_color, true)


static func draw_hud_bars(main: Node2D) -> void:
	var viewport_size: Vector2 = main.get_viewport_rect().size
	var health_bar_rect: Rect2 = Rect2(Vector2(96.0, 44.0), Vector2(218.0, 8.0))
	var energy_bar_rect: Rect2 = Rect2(Vector2(96.0, 76.0), Vector2(204.0, 7.0))
	_draw_hud_top_banner(main, viewport_size)
	_draw_hud_mode_badge(main, Vector2(viewport_size.x - 62.0, 52.0), 35.0)
	_draw_hud_lotus(main, Vector2(54.0, 53.0), 25.0)
	_draw_hud_metric_bar(
		main,
		health_bar_rect,
		float(main.player["health"]) / maxf(main.PLAYER_MAX_HEALTH, 1.0),
		main.COLORS["health"].lerp(ART_BLUE_CORE, 0.12),
		main.COLORS["health"],
		0.95
	)
	var energy_fill_color: Color = main.COLORS["energy"]
	if bool(main.player.get("array_is_firing", false)):
		energy_fill_color = energy_fill_color.lerp(ARRAY_CHANNEL_EDGE_COLOR, 0.35)
		main.draw_rect(Rect2(energy_bar_rect.position - Vector2(2.0, 2.0), energy_bar_rect.size + Vector2(4.0, 4.0)), _with_alpha(ARRAY_CHANNEL_EDGE_COLOR, 0.18), false, 2.0)
		_draw_array_channel_flames(main, energy_bar_rect)
	_draw_hud_metric_bar(
		main,
		energy_bar_rect,
		float(main.player["energy"]) / maxf(main.PLAYER_MAX_ENERGY, 1.0),
		energy_fill_color.lerp(ART_BLUE_CORE, 0.08),
		energy_fill_color,
		0.88
	)
	if main.energy_gain_feedback_timer > 0.0 and main.energy_gain_feedback_strength > 0.0:
		var gain_ratio: float = clampf(
			float(main.energy_gain_feedback_timer) / maxf(main.ENERGY_GAIN_FEEDBACK_DURATION, 0.001),
			0.0,
			1.0
		)
		var gain_strength: float = clampf(float(main.energy_gain_feedback_strength), 0.0, 1.0) * gain_ratio
		var gain_color: Color = Color(main.energy_gain_feedback_color)
		main.draw_rect(
			Rect2(energy_bar_rect.position - Vector2(2.0, 2.0), energy_bar_rect.size + Vector2(4.0, 4.0)),
			_with_alpha(gain_color, 0.1 + 0.26 * gain_strength),
			false,
			2.0 + 0.8 * gain_strength
		)
		var sweep_width: float = energy_bar_rect.size.x * (0.1 + 0.12 * gain_strength)
		var sweep_progress: float = 1.0 - gain_ratio
		var sweep_x: float = energy_bar_rect.position.x - sweep_width + (energy_bar_rect.size.x + sweep_width) * sweep_progress
		main.draw_rect(
			Rect2(Vector2(sweep_x, energy_bar_rect.position.y), Vector2(sweep_width, energy_bar_rect.size.y)),
			_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.08 + 0.16 * gain_strength),
			true
		)
	_draw_hud_resonance_mark(main, Vector2(336.0, 62.0))
	_draw_hud_bottom_frame(main, viewport_size)


static func _draw_hud_top_banner(main: Node2D, viewport_size: Vector2) -> void:
	var center_x: float = viewport_size.x * 0.5
	var y: float = 38.0
	var width: float = 350.0
	var banner_rect := Rect2(Vector2(center_x - width * 0.5, 21.0), Vector2(width, 34.0))
	main.draw_rect(banner_rect.grow_individual(12.0, 2.0, 12.0, 2.0), _with_alpha(ART_BG_DEEP, 0.34), true)
	main.draw_rect(banner_rect, _with_alpha(ART_GOLD, 0.13), false, 1.2)
	main.draw_line(Vector2(center_x - width * 0.5 - 56.0, y), Vector2(center_x - width * 0.5 - 12.0, y), _with_alpha(ART_GOLD, 0.38), 1.1)
	main.draw_line(Vector2(center_x + width * 0.5 + 12.0, y), Vector2(center_x + width * 0.5 + 56.0, y), _with_alpha(ART_GOLD, 0.38), 1.1)
	main.draw_circle(Vector2(center_x - width * 0.5 - 20.0, y), 2.0, _with_alpha(ART_GOLD, 0.58))
	main.draw_circle(Vector2(center_x + width * 0.5 + 20.0, y), 2.0, _with_alpha(ART_GOLD, 0.58))


static func _draw_hud_mode_badge(main: Node2D, center: Vector2, radius: float) -> void:
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 1.4)
	main.draw_circle(center, radius + 10.0, _with_alpha(ART_BLUE, 0.055 + 0.025 * pulse))
	main.draw_arc(center, radius, 0.0, TAU, 40, _with_alpha(ART_GOLD, 0.56), 1.7)
	main.draw_arc(center, radius - 10.0, PI * 0.18, PI * 1.88, 30, _with_alpha(ART_BLUE, 0.22), 1.1)
	main.draw_line(center + Vector2(0.0, -radius - 8.0), center + Vector2(0.0, radius + 8.0), _with_alpha(ART_GOLD, 0.14), 1.0)


static func _draw_hud_lotus(main: Node2D, center: Vector2, radius: float) -> void:
	var pulse: float = 0.92 + 0.08 * sin(main.elapsed_time * 1.2)
	var petal_index: int = 0
	while petal_index < 5:
		var angle: float = -PI * 0.5 + (float(petal_index) - 2.0) * 0.34
		var tip: Vector2 = center + Vector2.RIGHT.rotated(angle) * radius * 0.95
		var left: Vector2 = center + Vector2.RIGHT.rotated(angle + 0.5) * radius * 0.56
		var right: Vector2 = center + Vector2.RIGHT.rotated(angle - 0.5) * radius * 0.56
		_try_draw_colored_polygon(main, PackedVector2Array([left, tip, right]), _with_alpha(ART_GOLD, 0.15 * pulse))
		main.draw_line(left, tip, _with_alpha(ART_GOLD, 0.45), 1.1)
		main.draw_line(tip, right, _with_alpha(ART_GOLD, 0.45), 1.1)
		petal_index += 1
	main.draw_arc(center, radius * 1.24, 0.0, TAU, 30, _with_alpha(ART_BLUE, 0.15), 1.1)
	main.draw_arc(center, radius * 1.58, PI * 0.18, PI * 0.82, 18, _with_alpha(ART_BLUE, 0.2), 1.0)


static func _draw_hud_metric_bar(
	main: Node2D,
	bar_rect: Rect2,
	fill_ratio: float,
	core_color: Color,
	accent_color: Color,
	alpha_scale: float
) -> void:
	var ratio: float = clampf(fill_ratio, 0.0, 1.0)
	main.draw_rect(bar_rect.grow_individual(0.0, 2.0, 32.0, 2.0), _with_alpha(ART_BG_DEEP, 0.54), true)
	main.draw_rect(bar_rect.grow_individual(0.0, 2.0, 32.0, 2.0), _with_alpha(ART_GOLD, 0.18 * alpha_scale), false, 1.0)
	var fill_rect := Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y))
	main.draw_rect(fill_rect, _with_alpha(accent_color, 0.22 * alpha_scale), true)
	main.draw_rect(Rect2(fill_rect.position, Vector2(fill_rect.size.x, maxf(fill_rect.size.y - 2.0, 1.0))), _with_alpha(core_color, 0.78 * alpha_scale), true)
	if fill_rect.size.x > 8.0:
		main.draw_rect(Rect2(fill_rect.end - Vector2(8.0, 0.0), Vector2(8.0, fill_rect.size.y)), _with_alpha(core_color.lerp(Color.WHITE, 0.32), 0.86 * alpha_scale), true)
	main.draw_line(bar_rect.position + Vector2(0.0, -8.0), bar_rect.position + Vector2(bar_rect.size.x + 48.0, -8.0), _with_alpha(ART_GOLD, 0.16 * alpha_scale), 1.0)


static func _draw_hud_bottom_frame(main: Node2D, viewport_size: Vector2) -> void:
	var y: float = viewport_size.y - 37.0
	main.draw_rect(Rect2(Vector2(0.0, y - 20.0), Vector2(viewport_size.x, 44.0)), _with_alpha(ART_BG_DEEP, 0.34), true)
	main.draw_line(Vector2(48.0, y - 14.0), Vector2(viewport_size.x - 48.0, y - 14.0), _with_alpha(ART_GOLD, 0.2), 1.0)
	main.draw_line(Vector2(260.0, y + 16.0), Vector2(viewport_size.x - 260.0, y + 16.0), _with_alpha(ART_BLUE, 0.08), 1.0)


static func _draw_energy_gain_pulse(main: Node2D, player_pos: Vector2) -> void:
	if main.energy_gain_feedback_timer <= 0.0 or main.energy_gain_feedback_strength <= 0.0:
		return
	var gain_ratio: float = clampf(
		float(main.energy_gain_feedback_timer) / maxf(main.ENERGY_GAIN_FEEDBACK_DURATION, 0.001),
		0.0,
		1.0
	)
	var gain_strength: float = clampf(float(main.energy_gain_feedback_strength), 0.0, 1.0) * gain_ratio
	var gain_pulse: float = 1.0 - gain_ratio
	var gain_color: Color = Color(main.energy_gain_feedback_color)
	var radius: float = main.PLAYER_RADIUS + 12.0 + gain_pulse * (18.0 + 12.0 * gain_strength)
	main.draw_arc(
		player_pos,
		radius,
		0.0,
		TAU,
		32,
		_with_alpha(gain_color, 0.18 + 0.26 * gain_strength),
		1.8 + 1.2 * gain_strength
	)
	main.draw_circle(
		player_pos,
		main.PLAYER_RADIUS + 4.0 + gain_strength * 5.0,
		_with_alpha(gain_color.lerp(UNSHEATH_FLASH_CORE_COLOR, 0.32), 0.03 + 0.06 * gain_strength)
	)


static func _draw_sword_recall_gate(main: Node2D, player_pos: Vector2) -> void:
	if int(main.sword.get("state", main.SwordState.ORBITING)) != main.SwordState.RECALLING:
		return
	var to_sword: Vector2 = Vector2(main.sword.get("pos", main.player["pos"])) - main.player["pos"]
	var distance: float = to_sword.length()
	if distance <= main.PLAYER_RADIUS + 10.0:
		return
	var direction: Vector2 = to_sword.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var gate_ratio: float = clampf((distance - (main.PLAYER_RADIUS + 10.0)) / 220.0, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * 10.0)
	var gate_color: Color = main.COLORS["array_sword_return"].lerp(main.COLORS["ranged_sword"], 0.46)
	var inner_radius: float = main.PLAYER_RADIUS + 13.0 + pulse * 1.6
	var outer_radius: float = main.PLAYER_RADIUS + 22.0 + gate_ratio * 6.0
	main.draw_arc(
		player_pos,
		inner_radius,
		0.0,
		TAU,
		32,
		_with_alpha(gate_color, 0.08 + 0.14 * gate_ratio),
		1.4 + 0.8 * gate_ratio
	)
	main.draw_arc(
		player_pos,
		outer_radius,
		direction.angle() - 0.62,
		direction.angle() + 0.62,
		20,
		_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.08 + 0.14 * gate_ratio),
		1.0 + 0.7 * gate_ratio
	)
	for offset in [-0.34, 0.0, 0.34]:
		var ray_dir: Vector2 = direction.rotated(float(offset))
		var ray_from: Vector2 = player_pos + ray_dir * outer_radius
		var ray_to: Vector2 = player_pos + ray_dir * (inner_radius - 4.0)
		main.draw_line(ray_from, ray_to, _with_alpha(gate_color, 0.08 + 0.12 * gate_ratio), 0.9 + 0.4 * gate_ratio)


static func _draw_sword_return_catches(main: Node2D) -> void:
	if main.sword_return_catches.is_empty():
		return
	for catch_effect in main.sword_return_catches:
		var life_ratio: float = clampf(float(catch_effect.get("life", 0.0)) / maxf(float(catch_effect.get("max_life", 1.0)), 0.001), 0.0, 1.0)
		if life_ratio <= 0.0:
			continue
		var progress: float = 1.0 - life_ratio
		var center: Vector2 = main._to_screen(catch_effect["pos"])
		var forward: Vector2 = Vector2(catch_effect.get("forward", Vector2.RIGHT))
		if forward.is_zero_approx():
			forward = Vector2.RIGHT
		forward = forward.normalized()
		var base_radius: float = float(catch_effect.get("radius", main.SWORD_RETURN_CATCH_BASE_RADIUS))
		var ring_radius: float = lerpf(main.PLAYER_RADIUS + 8.0, base_radius, progress)
		var ring_color: Color = main.COLORS["array_sword_return"].lerp(UNSHEATH_FLASH_CORE_COLOR, 0.32)
		main.draw_arc(
			center,
			ring_radius,
			0.0,
			TAU,
			30,
			_with_alpha(ring_color, 0.08 + 0.18 * life_ratio),
			1.2 + 0.9 * life_ratio
		)
		main.draw_line(
			center - forward * (3.0 + 3.0 * life_ratio),
			center + forward * (10.0 + 12.0 * life_ratio),
			_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.1 + 0.16 * life_ratio),
			1.0 + 0.7 * life_ratio
		)
		for offset in [-0.45, 0.45]:
			var spoke_dir: Vector2 = forward.rotated(float(offset))
			var spoke_end: Vector2 = center + spoke_dir * ring_radius
			var spoke_inner: Vector2 = center + spoke_dir * (ring_radius * 0.48)
			main.draw_line(spoke_end, spoke_inner, _with_alpha(ring_color, 0.06 + 0.12 * life_ratio), 0.9 + 0.4 * life_ratio)
		main.draw_circle(
			center,
			2.2 + 2.0 * life_ratio,
			_with_alpha(UNSHEATH_FLASH_CORE_COLOR, 0.06 + 0.1 * life_ratio)
		)


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


static func _try_draw_polyline_closed(main: Node2D, points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	var point_index: int = 0
	while point_index < points.size():
		var next_index: int = (point_index + 1) % points.size()
		main.draw_line(points[point_index], points[next_index], color, width)
		point_index += 1


static func _get_sword_vfx(main: Node) -> Resource:
	if main.has_method("get_sword_vfx_profile"):
		return main.call("get_sword_vfx_profile")
	return null


static func _use_node_sword_flight_vfx(main: Node) -> bool:
	return main.has_method("_use_node_sword_flight_vfx") and bool(main.call("_use_node_sword_flight_vfx"))


static func _with_alpha(color: Color, alpha: float) -> Color:
	var result: Color = color
	result.a = alpha
	return result


static func _stable_noise(index: int, salt: float) -> float:
	var value: float = sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
	return value - floor(value)


static func _draw_irregular_ink_poly(main: Node2D, center: Vector2, radius: float, seed: int, color: Color) -> void:
	if radius <= 0.0 or color.a <= 0.001:
		return
	var point_count: int = 9
	var points := PackedVector2Array()
	var point_index: int = 0
	while point_index < point_count:
		var angle: float = float(point_index) / float(point_count) * TAU
		var wobble: float = 0.62 + 0.48 * _stable_noise(seed * 19 + point_index, radius * 0.17)
		var tangent_pull: float = (_stable_noise(seed * 23 + point_index, radius * 0.31) - 0.5) * radius * 0.16
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var tangent: Vector2 = direction.rotated(PI * 0.5)
		points.append(center + direction * radius * wobble + tangent * tangent_pull)
		point_index += 1
	_try_draw_colored_polygon(main, points, color)


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
