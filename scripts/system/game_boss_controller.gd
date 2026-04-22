extends RefCounted
class_name GameBossController

const TargetDescriptorRegistry = preload("res://scripts/combat/target_descriptor_registry.gd")
const TargetProfiles = preload("res://scripts/combat/target_profiles.gd")


static func update_boss(main: Node, delta: float, bullet_time_delta: float) -> void:
	if not has_boss(main):
		return
	main.boss["hit_flash_timer"] = maxf(float(main.boss.get("hit_flash_timer", 0.0)) - bullet_time_delta, 0.0)
	main.boss["hit_reaction_timer"] = maxf(float(main.boss.get("hit_reaction_timer", 0.0)) - bullet_time_delta, 0.0)
	main.boss["hit_reaction_offset"] = main._resolve_hit_reaction_offset(
		Vector2(main.boss.get("hit_reaction_vector", Vector2.ZERO)),
		float(main.boss.get("hit_reaction_timer", 0.0)),
		main.BOSS_HIT_REACTION_DURATION,
		main.BOSS_HIT_REACTION_SHAKE_CYCLES
	)
	if float(main.boss.get("hit_reaction_timer", 0.0)) <= 0.0:
		main.boss["hit_reaction_vector"] = Vector2.ZERO

	var to_target: Vector2 = main.boss["target_pos"] - main.boss["pos"]
	if to_target.length() > 5.0:
		main.boss["pos"] += to_target.normalized() * main.BOSS_SPEED * delta

	main.boss["state_timer"] -= bullet_time_delta
	if main.boss["is_vulnerable"]:
		main.boss["vulnerable_timer"] -= bullet_time_delta
		if main.boss["vulnerable_timer"] <= 0.0:
			main.boss["is_vulnerable"] = false

	_update_boss_silks(main, bullet_time_delta)

	if main.boss["phase"] == 1 and main.boss["health"] < main.boss["max_health"] * 0.7:
		main.boss["phase"] = 2
	if main.boss["phase"] == 2 and main.boss["health"] < main.boss["max_health"] * 0.3:
		main.boss["phase"] = 3

	if main.boss["state_timer"] <= 0.0:
		_choose_next_boss_state(main)

	match main.boss["state"]:
		main.BOSS_THOUSAND_SILKS:
			if int(floor(main.boss["state_timer"] * 10.0)) % 5 == 0:
				var fan_index: int = -3
				while fan_index <= 3:
					var angle: float = PI * 0.5 + float(fan_index) * 0.25
					main._spawn_bullet(main.boss["pos"], Vector2(cos(angle), sin(angle)) * 240.0, "small", main.boss["id"], main.COLORS["silk"])
					fan_index += 1
		main.BOSS_NEEDLE_RETURN:
			if int(floor(main.boss["state_timer"] * 20.0)) % 4 == 0:
				var ring_angle: float = randf_range(0.0, TAU)
				var spawn_pos: Vector2 = main.player["pos"] + Vector2.RIGHT.rotated(ring_angle) * 400.0
				var shot_dir: Vector2 = (main.player["pos"] - spawn_pos).normalized()
				main._spawn_bullet(spawn_pos, shot_dir * 360.0, "small", main.boss["id"], main.COLORS["silk"])
		main.BOSS_SILK_CAGE:
			if int(floor(main.boss["state_timer"] * 5.0)) % 5 == 0 and count_active_silks(main) < 3:
				spawn_puppets(main, 1)
		_:
			pass

	if main.boss["state"] == main.BOSS_PUPPET_AMBUSH and count_active_silks(main) == 0:
		main._open_boss_vulnerability_window(2.0)


static func draw_boss(main: Node2D) -> void:
	draw_boss_world(main)
	draw_boss_hud(main)


static func draw_boss_world(main: Node2D) -> void:
	var boss_visual_offset: Vector2 = Vector2(main.boss.get("hit_reaction_offset", Vector2.ZERO))
	var silk_index: int = 0
	while silk_index < main.boss["silks"].size():
		var silk: Dictionary = main.boss["silks"][silk_index]
		var puppet: Variant = find_enemy_by_id(main, str(silk.get("id", "")))
		var puppet_visual_offset: Vector2 = Vector2.ZERO
		if puppet != null:
			puppet_visual_offset = Vector2(puppet.get("hit_reaction_offset", Vector2.ZERO))
		if silk["is_active"]:
			var from_world: Vector2 = silk["from"] + boss_visual_offset
			var to_world: Vector2 = silk["to"] + puppet_visual_offset
			var from_pos: Vector2 = main._to_screen(from_world)
			var to_pos: Vector2 = main._to_screen(to_world)
			var silk_color: Color = main.COLORS["silk_main"] if silk["is_main"] else main.COLORS["silk"]
			main.draw_line(from_pos, to_pos, main._get_time_stop_world_color(silk_color), 3.0 if silk["is_main"] else 1.0)
			var contact_feedback_timer: float = float(silk.get("contact_feedback_timer", 0.0))
			if contact_feedback_timer > 0.0:
				var contact_strength: float = clampf(contact_feedback_timer / maxf(main.SILK_CONTACT_FEEDBACK_DURATION, 0.001), 0.0, 1.0)
				var contact_pos: Vector2 = main._to_screen(silk.get("contact_feedback_pos", silk["to"]))
				var contact_color: Color = Color(silk.get("contact_feedback_color", Color.WHITE))
				var contact_axis: Vector2 = (to_world - from_world).normalized()
				if contact_axis.is_zero_approx():
					contact_axis = Vector2.RIGHT
				var contact_half_length: float = 14.0 + 10.0 * contact_strength + (8.0 if bool(silk.get("contact_feedback_is_point", false)) else 0.0)
				main.draw_line(
					contact_pos - contact_axis * contact_half_length,
					contact_pos + contact_axis * contact_half_length,
					main._get_time_stop_world_color(contact_color),
					1.4 + 1.8 * contact_strength
				)
				main.draw_circle(
					contact_pos,
					2.6 + 2.8 * contact_strength,
					main._get_time_stop_world_color(Color.WHITE)
				)
		var cut_feedback_timer: float = float(silk.get("cut_feedback_timer", 0.0))
		if cut_feedback_timer > 0.0:
			var cut_strength: float = clampf(cut_feedback_timer / maxf(main.SILK_SEVER_FEEDBACK_DURATION, 0.001), 0.0, 1.0)
			var cut_from_world: Vector2 = Vector2(silk.get("cut_feedback_from", silk.get("from", Vector2.ZERO))) + boss_visual_offset
			var cut_to_world: Vector2 = Vector2(silk.get("cut_feedback_to", silk.get("to", Vector2.ZERO))) + puppet_visual_offset
			var cut_center_world: Vector2 = Vector2(silk.get("cut_feedback_center", cut_from_world.lerp(cut_to_world, 0.5)))
			var cut_axis: Vector2 = cut_to_world - cut_from_world
			if cut_axis.is_zero_approx():
				cut_axis = Vector2.RIGHT
			else:
				cut_axis = cut_axis.normalized()
			var retract_axis: Vector2 = cut_axis.rotated(PI * 0.5)
			var retract_distance: float = (1.0 - cut_strength) * (20.0 if bool(silk.get("cut_feedback_is_main", false)) else 12.0)
			var gap_size: float = 10.0 + 14.0 * cut_strength
			var cut_color: Color = Color.WHITE
			var from_screen: Vector2 = main._to_screen(cut_from_world)
			var to_screen: Vector2 = main._to_screen(cut_to_world)
			var center_screen: Vector2 = main._to_screen(cut_center_world)
			main.draw_line(
				from_screen,
				main._to_screen(cut_center_world - cut_axis * gap_size - retract_axis * retract_distance),
				main._get_time_stop_world_color(cut_color),
				1.6 + 2.2 * cut_strength
			)
			main.draw_line(
				main._to_screen(cut_center_world + cut_axis * gap_size + retract_axis * retract_distance),
				to_screen,
				main._get_time_stop_world_color(cut_color),
				1.6 + 2.2 * cut_strength
			)
			main.draw_circle(
				center_screen,
				4.0 + 4.0 * cut_strength,
				main._get_time_stop_world_color(Color(1.0, 1.0, 1.0, 0.12 + 0.12 * cut_strength))
			)
		silk_index += 1

	var boss_color: Color = main.COLORS["boss_vulnerable"] if main.boss["is_vulnerable"] else main.COLORS["boss_body"]
	var boss_hit_flash_ratio: float = clampf(float(main.boss.get("hit_flash_timer", 0.0)) / maxf(main.BOSS_HIT_FLASH_DURATION, 0.001), 0.0, 1.0)
	if boss_hit_flash_ratio > 0.0:
		var boss_flash_color: Color = Color(main.boss.get("hit_flash_color", Color.WHITE))
		boss_color = boss_color.lerp(boss_flash_color, 0.42 + 0.34 * boss_hit_flash_ratio)
	var boss_pos: Vector2 = main._to_screen(main.boss["pos"] + boss_visual_offset)
	main.draw_circle(boss_pos, main.boss["radius"], main._get_time_stop_world_color(boss_color))
	if boss_hit_flash_ratio > 0.0:
		main.draw_circle(
			boss_pos,
			main.boss["radius"] + 2.0 + 3.5 * boss_hit_flash_ratio,
			main._get_time_stop_world_color(Color(1.0, 1.0, 1.0, 0.06 + 0.12 * boss_hit_flash_ratio))
		)
	main.draw_arc(boss_pos, main.boss["radius"] + 8.0, 0.0, TAU, 32, main._get_time_stop_world_color(Color.WHITE), 2.0)
	if boss_hit_flash_ratio > 0.0:
		var boss_ring_color: Color = Color(main.boss.get("hit_flash_color", Color.WHITE))
		boss_ring_color.a = 0.24 + 0.24 * boss_hit_flash_ratio
		main.draw_arc(
			boss_pos,
			main.boss["radius"] + 12.0 + 8.0 * boss_hit_flash_ratio,
			0.0,
			TAU,
			32,
			main._get_time_stop_world_color(boss_ring_color),
			1.8 + 2.0 * boss_hit_flash_ratio
		)


static func draw_boss_hud(main: Node2D) -> void:
	var bar_width: float = 400.0
	var bar_rect: Rect2 = Rect2(Vector2((main.ARENA_SIZE.x - bar_width) * 0.5 + main.ARENA_ORIGIN.x, 40.0), Vector2(bar_width, 10.0))
	main.draw_rect(bar_rect, main._get_time_stop_world_color(Color(0.0, 0.0, 0.0, 0.5)), true)
	main.draw_rect(
		Rect2(bar_rect.position, Vector2(bar_width * (main.boss["health"] / main.boss["max_health"]), bar_rect.size.y)),
		main._get_time_stop_world_color(main.COLORS["boss_body"]),
		true
	)
	main.draw_rect(bar_rect, main._get_time_stop_world_color(Color.WHITE), false, 1.0)


static func update_silk_damage(main: Node, delta: float) -> void:
	var silk_index: int = 0
	while silk_index < main.boss["silks"].size():
		var silk: Dictionary = main.boss["silks"][silk_index]
		var hurtbox: Dictionary = main._get_target_primary_hurtbox(str(silk.get("id", "")))
		var hurtbox_id: String = str(hurtbox.get("hurtbox_id", ""))
		var target_profile_id: String = str(hurtbox.get("target_profile_id", TargetProfiles.PROFILE_SILK_SEGMENT))
		var is_sword_attack_active: bool = main.sword["state"] == main.SwordState.SLICING or main.sword["state"] == main.SwordState.POINT_STRIKE
		var is_contacting_silk: bool = false
		if silk["is_active"] and is_sword_attack_active:
			is_contacting_silk = dist_to_segment(main.sword["pos"], silk["from"], silk["to"]) < main.sword["radius"] + 5.0
			if is_contacting_silk and hurtbox_id != "":
				var attack_result: Dictionary = main._apply_sword_hit_to_target(
					str(silk.get("id", "")),
					hurtbox_id,
					target_profile_id,
					main.DAMAGE_SOURCE_FLYING_SWORD,
					delta
				)
				var apply_result: Dictionary = attack_result.get("apply_result", {})
				if bool(apply_result.get("killed", false)):
					main._create_particles(main.sword["pos"], main.COLORS["silk"], 20)
		if hurtbox_id != "":
			main._set_sword_hit_overlap(str(silk.get("id", "")), hurtbox_id, is_contacting_silk)
		silk_index += 1


static func spawn_boss(main: Node) -> void:
	main._clear_target_hurtboxes("boss")
	main.boss = {
		"id": main._next_id("boss"),
		"descriptor_provider_id": TargetDescriptorRegistry.PROVIDER_BOSS,
		"pos": Vector2(main.ARENA_SIZE.x * 0.5, -150.0),
		"radius": main.BOSS_RADIUS,
		"target_profile_id": TargetProfiles.PROFILE_BOSS_BODY,
		"health": main.BOSS_MAX_HEALTH,
		"max_health": main.BOSS_MAX_HEALTH,
		"state": main.BOSS_IDLE,
		"state_timer": 3.0,
		"phase": 1,
		"silks": [],
		"is_vulnerable": false,
		"vulnerable_timer": 0.0,
		"target_pos": Vector2(main.ARENA_SIZE.x * 0.5, 150.0),
		"hit_flash_timer": 0.0,
		"hit_flash_color": Color.WHITE,
		"hit_reaction_timer": 0.0,
		"hit_reaction_offset": Vector2.ZERO,
		"hit_reaction_vector": Vector2.ZERO,
	}
	main._register_boss_hurtboxes()


static func spawn_puppets(main: Node, count: int) -> void:
	if not has_boss(main):
		return
	var puppet_count: int = 0
	while puppet_count < count:
		var angle: float = randf_range(0.0, TAU)
		var distance: float = randf_range(200.0, 300.0)
		var puppet_pos: Vector2 = Vector2(main.ARENA_SIZE.x * 0.5, main.ARENA_SIZE.y * 0.5) + Vector2.RIGHT.rotated(angle) * distance
		var puppet_id: String = main._next_id("puppet")
		var puppet: Dictionary = main._spawn_enemy(main.PUPPET)
		var previous_puppet_id: String = str(puppet.get("id", ""))
		puppet["id"] = puppet_id
		puppet["pos"] = puppet_pos.clamp(Vector2(main.PUPPET_RADIUS, main.PUPPET_RADIUS), main.ARENA_SIZE - Vector2(main.PUPPET_RADIUS, main.PUPPET_RADIUS))
		puppet["melee_timer"] = 0.0
		main._clear_target_hurtboxes(previous_puppet_id)
		main._register_enemy_hurtboxes(puppet)
		main.enemies[main.enemies.size() - 1] = puppet
		var silk := {
			"id": puppet_id,
			"descriptor_provider_id": TargetDescriptorRegistry.PROVIDER_SILK_SEGMENT,
			"target_profile_id": TargetProfiles.PROFILE_SILK_SEGMENT,
			"from": main.boss["pos"],
			"to": puppet["pos"],
			"is_main": false,
			"health": main.SILK_MAX_HEALTH,
			"max_health": main.SILK_MAX_HEALTH,
			"is_active": true,
			"contact_feedback_timer": 0.0,
			"contact_feedback_pos": puppet["pos"],
			"contact_feedback_color": Color.WHITE,
			"contact_feedback_is_point": false,
			"cut_feedback_timer": 0.0,
			"cut_feedback_from": main.boss["pos"],
			"cut_feedback_to": puppet["pos"],
			"cut_feedback_center": puppet["pos"].lerp(main.boss["pos"], 0.5),
			"cut_feedback_is_main": false,
		}
		main.boss["silks"].append(silk)
		main._register_silk_hurtbox(silk)
		puppet_count += 1


static func count_active_silks(main: Node) -> int:
	if not has_boss(main):
		return 0
	var active_count: int = 0
	var silk_index: int = 0
	while silk_index < main.boss["silks"].size():
		if main.boss["silks"][silk_index]["is_active"]:
			active_count += 1
		silk_index += 1
	return active_count


static func is_silk_active(main: Node, enemy_id: String) -> bool:
	if not has_boss(main):
		return false
	var silk_index: int = 0
	while silk_index < main.boss["silks"].size():
		var silk: Dictionary = main.boss["silks"][silk_index]
		if silk["id"] == enemy_id:
			return silk["is_active"]
		silk_index += 1
	return false


static func find_enemy_by_id(main: Node, enemy_id: String) -> Variant:
	for enemy in main.enemies:
		if enemy["id"] == enemy_id:
			return enemy
	return null


static func kill_enemy_by_id(main: Node, enemy_id: String) -> void:
	var index: int = main.enemies.size() - 1
	while index >= 0:
		if main.enemies[index]["id"] == enemy_id:
			main.enemies[index]["health"] = 0.0
			return
		index -= 1


static func find_silk_index(main: Node, silk_id: String) -> int:
	if not has_boss(main):
		return -1
	var silk_index: int = 0
	while silk_index < main.boss["silks"].size():
		if str(main.boss["silks"][silk_index].get("id", "")) == silk_id:
			return silk_index
		silk_index += 1
	return -1


static func resolve_silk_binding(main: Node, silk_id: String) -> Dictionary:
	var result := {
		"found": false,
		"index": -1,
		"id": silk_id,
		"is_active": false,
		"health": 0.0,
		"max_health": 0.0,
		"target_profile_id": TargetProfiles.PROFILE_SILK_SEGMENT,
		"from": Vector2.ZERO,
		"to": Vector2.ZERO,
	}
	if not has_boss(main):
		return result
	var silk_index: int = find_silk_index(main, silk_id)
	if silk_index < 0:
		return result
	var silk: Dictionary = main.boss["silks"][silk_index]
	result["found"] = true
	result["index"] = silk_index
	result["is_active"] = bool(silk.get("is_active", false))
	result["health"] = float(silk.get("health", 0.0))
	result["max_health"] = float(silk.get("max_health", 0.0))
	result["target_profile_id"] = str(silk.get("target_profile_id", TargetProfiles.PROFILE_SILK_SEGMENT))
	result["from"] = silk.get("from", Vector2.ZERO)
	result["to"] = silk.get("to", Vector2.ZERO)
	result["is_main"] = bool(silk.get("is_main", false))
	return result


static func apply_silk_damage(main: Node, silk_id: String, damage: float, damage_source := "") -> Dictionary:
	var result := {
		"found": false,
		"applied": false,
		"amount": 0.0,
		"killed": false,
		"resource_before": 0.0,
		"resource_after": 0.0,
		"resource_max": 0.0,
	}
	var silk_binding: Dictionary = resolve_silk_binding(main, silk_id)
	if not bool(silk_binding.get("found", false)):
		return result
	var silk_index: int = int(silk_binding.get("index", -1))
	var silk: Dictionary = main.boss["silks"][silk_index]
	result["found"] = true
	result["resource_before"] = float(silk_binding.get("health", 0.0))
	result["resource_after"] = float(silk_binding.get("health", 0.0))
	result["resource_max"] = float(silk_binding.get("max_health", 0.0))
	if not bool(silk_binding.get("is_active", false)):
		return result
	if damage <= 0.0:
		return result
	var previous_health: float = float(silk_binding.get("health", 0.0))
	if main._has_debug_flag("one_hit_kill"):
		silk["health"] = 0.0
	elif damage > 0.0:
		silk["health"] = maxf(previous_health - damage, 0.0)
	result["resource_before"] = previous_health
	result["resource_after"] = float(silk.get("health", previous_health))
	result["amount"] = maxf(previous_health - float(result.get("resource_after", previous_health)), 0.0)
	result["applied"] = float(result.get("amount", 0.0)) > 0.0 or (main._has_debug_flag("one_hit_kill") and previous_health > 0.0)
	if damage_source != "" and damage_source != main.DAMAGE_SOURCE_NONE:
		var puppet: Variant = find_enemy_by_id(main, silk_id)
		if puppet != null:
			puppet["last_damage_source"] = damage_source
	result["resource_after"] = float(silk.get("health", result.get("resource_after", previous_health)))
	if float(result.get("resource_after", 0.0)) <= 0.0:
		silk["is_active"] = false
		main._clear_target_hurtboxes(silk_id)
		kill_enemy_by_id(main, silk_id)
		result["killed"] = true
	main.boss["silks"][silk_index] = silk
	return result


static func has_boss(main: Node) -> bool:
	return not main.boss.is_empty()


static func dist_to_segment(point: Vector2, segment_a: Vector2, segment_b: Vector2) -> float:
	var segment_length_sq: float = segment_a.distance_squared_to(segment_b)
	if segment_length_sq == 0.0:
		return point.distance_to(segment_a)
	var projection: float = clamp((point - segment_a).dot(segment_b - segment_a) / segment_length_sq, 0.0, 1.0)
	var closest: Vector2 = segment_a + (segment_b - segment_a) * projection
	return point.distance_to(closest)


static func _update_boss_silks(main: Node, delta: float) -> void:
	var silk_index: int = 0
	while silk_index < main.boss["silks"].size():
		var silk: Dictionary = main.boss["silks"][silk_index]
		silk["contact_feedback_timer"] = maxf(float(silk.get("contact_feedback_timer", 0.0)) - delta, 0.0)
		silk["cut_feedback_timer"] = maxf(float(silk.get("cut_feedback_timer", 0.0)) - delta, 0.0)
		silk["from"] = main.boss["pos"]
		var puppet: Variant = find_enemy_by_id(main, silk["id"])
		if puppet != null:
			silk["to"] = puppet["pos"]
		main.boss["silks"][silk_index] = silk
		silk_index += 1


static func _choose_next_boss_state(main: Node) -> void:
	var next_states: Array = [main.BOSS_THOUSAND_SILKS, main.BOSS_PUPPET_AMBUSH, main.BOSS_SILK_CAGE, main.BOSS_NEEDLE_RETURN]
	if main.boss["phase"] == 1:
		next_states = [main.BOSS_THOUSAND_SILKS, main.BOSS_PUPPET_AMBUSH]
	var next_state: String = next_states[randi() % next_states.size()]
	main.boss["state"] = next_state
	match next_state:
		main.BOSS_THOUSAND_SILKS:
			main.boss["state_timer"] = 4.0
			main.boss["target_pos"] = Vector2(main.ARENA_SIZE.x * 0.5, 100.0)
		main.BOSS_PUPPET_AMBUSH:
			main.boss["state_timer"] = 6.5
			main.boss["target_pos"] = Vector2(main.ARENA_SIZE.x * 0.5, 100.0)
			spawn_puppets(main, 2 if main.boss["phase"] == 1 else 4)
			main.boss["is_vulnerable"] = false
		main.BOSS_SILK_CAGE:
			main.boss["state_timer"] = 5.0
			main.boss["target_pos"] = Vector2(main.ARENA_SIZE.x * 0.5, main.ARENA_SIZE.y * 0.5)
		main.BOSS_NEEDLE_RETURN:
			main.boss["state_timer"] = 3.5
			main.boss["target_pos"] = Vector2(main.ARENA_SIZE.x * 0.5, 150.0)
