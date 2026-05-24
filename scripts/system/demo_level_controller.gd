extends RefCounted
class_name DemoLevelController


const PHASE_NORMAL := "normal"
const PHASE_SEGMENT_CLEAR := "segment_clear"
const PHASE_BOSS := "boss"
const PHASE_COMPLETE := "complete"

const BOSS_PHASE_INTRO := "intro"
const BOSS_PHASE_SILK := "silk"
const BOSS_PHASE_VULNERABLE := "vulnerable"

const SEGMENT_COUNT := 6
const SMALL_RECOVERY_AMOUNT := 25.0
const BOSS_RECOVERY_AMOUNT := 40.0
const RECOVERY_RADIUS := 18.0
const RECOVERY_PICKUP_DISTANCE := 32.0
const DEMO_BOSS_HEALTH := 1500.0
const BOSS_WINDOW_DURATION := 3.45
const BOSS_INTRO_DURATION := 3.0
const BOSS_SILK_DURATION := 9.0
const BOSS_RETRY_MIN_HEALTH := 70.0

var active := false
var completed := false
var phase := PHASE_NORMAL
var stage_index := -1
var segment_title := ""
var segment_hint := ""
var spawn_queue: Array = []
var spawn_timer := 0.0
var segment_clear_timer := 0.0
var stage_elite_drop_used := false
var boss_checkpoint_ready := false
var boss_checkpoint_health := 100.0
var boss_cycle := 0
var boss_phase := BOSS_PHASE_INTRO
var boss_phase_timer := 0.0
var boss_shot_timer := 0.0
var victory_data: Dictionary = {}
var stats: Dictionary = {}


func start(main: Node) -> void:
	active = true
	completed = false
	phase = PHASE_NORMAL
	stage_index = -1
	spawn_queue.clear()
	main.demo_recovery_pickups.clear()
	main.demo_victory_result.clear()
	main.demo_victory_visible = false
	main.array_swords.clear()
	main.player["energy"] = 0.0
	main.player["pos"] = main.ARENA_SIZE * Vector2(0.5, 0.62)
	main.sword["pos"] = main.player["pos"]
	main.sword["prev_pos"] = main.player["pos"]
	_reset_stats(main)
	_start_next_segment(main)


func update(main: Node, delta: float) -> void:
	if not active or completed:
		return
	_update_recovery_pickups(main, delta)
	match phase:
		PHASE_NORMAL:
			_update_normal_segment(main, delta)
		PHASE_SEGMENT_CLEAR:
			_update_segment_clear(main, delta)
		PHASE_BOSS:
			if not main._has_boss():
				_start_boss(main, false)
		_:
			pass


func update_boss(main: Node, delta: float, bullet_time_delta: float) -> void:
	if phase != PHASE_BOSS or completed:
		return
	if not main._has_boss():
		_start_boss(main, false)
		return

	main.boss["hit_flash_timer"] = maxf(float(main.boss.get("hit_flash_timer", 0.0)) - delta, 0.0)
	main.boss["hit_reaction_timer"] = maxf(float(main.boss.get("hit_reaction_timer", 0.0)) - delta, 0.0)
	main.boss["hit_reaction_offset"] = main._resolve_hit_reaction_offset(
		Vector2(main.boss.get("hit_reaction_vector", Vector2.ZERO)),
		float(main.boss.get("hit_reaction_timer", 0.0)),
		main.BOSS_HIT_REACTION_DURATION,
		main.BOSS_HIT_REACTION_SHAKE_CYCLES
	)
	if float(main.boss.get("hit_reaction_timer", 0.0)) <= 0.0:
		main.boss["hit_reaction_vector"] = Vector2.ZERO

	var to_target: Vector2 = Vector2(main.boss.get("target_pos", main.boss["pos"])) - main.boss["pos"]
	if to_target.length() > 4.0:
		main.boss["pos"] += to_target.normalized() * main.BOSS_SPEED * delta
	main._update_boss_silks(bullet_time_delta)

	if float(main.boss.get("health", 0.0)) <= 0.0:
		_complete_level(main)
		return

	boss_phase_timer = maxf(boss_phase_timer - bullet_time_delta, 0.0)
	boss_shot_timer = maxf(boss_shot_timer - bullet_time_delta, 0.0)
	match boss_phase:
		BOSS_PHASE_INTRO:
			_update_boss_intro(main)
		BOSS_PHASE_SILK:
			_update_boss_silk(main)
		BOSS_PHASE_VULNERABLE:
			_update_boss_vulnerable(main)


func handle_player_death(main: Node) -> bool:
	if phase == PHASE_BOSS and boss_checkpoint_ready:
		_restore_boss_checkpoint(main)
		return true
	return false


func on_enemy_death(main: Node, enemy: Dictionary) -> void:
	if not active or completed:
		return
	if phase != PHASE_NORMAL:
		return
	var enemy_type := str(enemy.get("type", ""))
	if stage_elite_drop_used:
		return
	if enemy_type == main.HEAVY or enemy_type == main.MIRROR_NEEDLER or enemy_type == main.DRAPE_PRIEST:
		stage_elite_drop_used = true
		_spawn_recovery_pickup(main, Vector2(enemy.get("pos", main.player["pos"])), SMALL_RECOVERY_AMOUNT, false)


func on_player_damage(_main: Node, amount: float) -> void:
	if amount <= 0.0:
		return
	stats["damage_taken"] = float(stats.get("damage_taken", 0.0)) + amount


func on_deflect(_main: Node) -> void:
	stats["deflects"] = int(stats.get("deflects", 0)) + 1


func on_attack_result(_main: Node, damage_source: String, apply_result: Dictionary) -> void:
	if damage_source == "flying_sword" and bool(apply_result.get("applied", false)):
		stats["flying_sword_hits"] = int(stats.get("flying_sword_hits", 0)) + 1
		if bool(apply_result.get("killed", false)) and str(apply_result.get("target_kind", "")) == "enemy":
			stats["flying_sword_kills"] = int(stats.get("flying_sword_kills", 0)) + 1
	if str(apply_result.get("target_kind", "")) == "silk" and bool(apply_result.get("killed", false)):
		stats["silks_cut"] = int(stats.get("silks_cut", 0)) + 1


func get_objective_text() -> String:
	if completed:
		return "破晓将至"
	if phase == PHASE_BOSS:
		match boss_phase:
			BOSS_PHASE_INTRO:
				return "织傀道人：先读他的针雨"
			BOSS_PHASE_SILK:
				return "织傀道人：御剑切断傀线"
			BOSS_PHASE_VULNERABLE:
				return "织傀道人：破绽已开，逼近输出"
	return "%d / %d  %s" % [stage_index + 1, SEGMENT_COUNT, segment_title]


func get_hint_text() -> String:
	if completed:
		return "天光压住邪丝。下一关，再学剑阵。"
	return segment_hint


func _reset_stats(main: Node) -> void:
	stats = {
		"start_time": main.elapsed_time,
		"damage_taken": 0.0,
		"deflects": 0,
		"flying_sword_hits": 0,
		"flying_sword_kills": 0,
		"silks_cut": 0,
		"pickups": 0,
		"boss_retries": 0,
	}
	victory_data.clear()


func _update_normal_segment(main: Node, delta: float) -> void:
	if not spawn_queue.is_empty():
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			var entry: Dictionary = spawn_queue.pop_front()
			var spawned_count: int = max(main._spawn_wave_entry(entry), 1)
			main.enemies_to_spawn = maxi(main.enemies_to_spawn - spawned_count, 0)
			spawn_timer = main._get_spawn_entry_delay(entry, spawned_count)
		return
	if main.enemies.is_empty():
		_finish_segment(main)


func _update_segment_clear(main: Node, delta: float) -> void:
	segment_clear_timer -= delta
	if segment_clear_timer > 0.0:
		return
	if stage_index >= SEGMENT_COUNT - 1:
		_begin_boss_checkpoint(main)
	else:
		_start_next_segment(main)


func _start_next_segment(main: Node) -> void:
	stage_index += 1
	if stage_index >= SEGMENT_COUNT:
		_begin_boss_checkpoint(main)
		return
	phase = PHASE_NORMAL
	stage_elite_drop_used = false
	main.wave = stage_index + 1
	spawn_queue = _build_segment_queue(main, stage_index)
	main.enemies_to_spawn = main._get_spawn_queue_cost(spawn_queue)
	spawn_timer = 0.45
	segment_title = _get_segment_title(stage_index)
	segment_hint = _get_segment_hint(stage_index)
	main._show_status_message(segment_title, Color("f1e3bc"), 1.25)
	main._show_focus_status_message(segment_hint, Color("88d8ff"), 1.15)


func _finish_segment(main: Node) -> void:
	phase = PHASE_SEGMENT_CLEAR
	segment_clear_timer = 2.0
	main.enemies_to_spawn = 0
	if stage_index == 1 or stage_index == 3:
		_spawn_recovery_pickup(main, _safe_pickup_pos(main, main.player["pos"] + Vector2(58.0, -26.0)), SMALL_RECOVERY_AMOUNT, false)
	if stage_index == SEGMENT_COUNT - 1:
		_spawn_recovery_pickup(main, _safe_pickup_pos(main, main.player["pos"] + Vector2(0.0, -52.0)), BOSS_RECOVERY_AMOUNT, true)
		segment_clear_timer = 2.8
	main._show_status_message("这一息，够我换口气。", Color("d7bb79"), 1.15)


func _begin_boss_checkpoint(main: Node) -> void:
	phase = PHASE_BOSS
	main.wave = SEGMENT_COUNT + 1
	main.enemies_to_spawn = 0
	main.wave_spawn_queue.clear()
	main.bullets.clear()
	main.enemy_packages.clear()
	main.player["pos"] = main.ARENA_SIZE * Vector2(0.5, 0.66)
	main.sword["pos"] = main.player["pos"]
	main.sword["prev_pos"] = main.sword["pos"]
	boss_checkpoint_ready = true
	boss_checkpoint_health = maxf(float(main.player.get("health", main.PLAYER_MAX_HEALTH)), BOSS_RETRY_MIN_HEALTH)
	_start_boss(main, false)


func _start_boss(main: Node, from_retry: bool) -> void:
	main.enemies.clear()
	main.bullets.clear()
	main.enemy_packages.clear()
	main._clear_target_runtime_state("boss")
	main._clear_target_hurtboxes("boss")
	main.boss.clear()
	main._spawn_boss()
	main.boss["health"] = DEMO_BOSS_HEALTH
	main.boss["max_health"] = DEMO_BOSS_HEALTH
	main.boss["state"] = "demo_weaver"
	main.boss["target_pos"] = Vector2(main.ARENA_SIZE.x * 0.5, 118.0)
	main.boss["is_vulnerable"] = false
	main.boss["vulnerable_timer"] = 0.0
	boss_cycle = 0
	boss_phase = BOSS_PHASE_INTRO
	boss_phase_timer = BOSS_INTRO_DURATION
	boss_shot_timer = 0.65
	segment_title = "织傀道人"
	segment_hint = "别砍傀身。线才是命。"
	var color := Color("f1e3bc") if not from_retry else Color("facc15")
	main._show_status_message("织傀道人", color, 1.3)
	main._show_focus_status_message("线才是命门。", Color("88d8ff"), 1.1)


func _restore_boss_checkpoint(main: Node) -> void:
	stats["boss_retries"] = int(stats.get("boss_retries", 0)) + 1
	main.player["health"] = maxf(boss_checkpoint_health, BOSS_RETRY_MIN_HEALTH)
	main.left_mouse_held = false
	main.right_mouse_held = false
	main._end_sword_attack_instance()
	main.sword["state"] = main.SwordState.ORBITING
	main._set_player_combat_mode(main.CombatMode.MELEE)
	main._reset_time_rift_fx()
	_start_boss(main, true)


func _update_boss_intro(main: Node) -> void:
	if boss_shot_timer <= 0.0:
		_fire_boss_fan(main, 5, 0.24, 210.0)
		boss_shot_timer = 0.95
	if boss_phase_timer <= 0.0:
		_begin_boss_silk_phase(main)


func _begin_boss_silk_phase(main: Node) -> void:
	boss_cycle += 1
	boss_phase = BOSS_PHASE_SILK
	boss_phase_timer = BOSS_SILK_DURATION
	boss_shot_timer = 0.6
	main.boss["is_vulnerable"] = false
	main.boss["vulnerable_timer"] = 0.0
	main.boss["target_pos"] = Vector2(main.ARENA_SIZE.x * 0.5, 118.0 + minf(float(boss_cycle), 3.0) * 14.0)
	main._spawn_puppets(2 if boss_cycle == 1 else (3 if boss_cycle == 2 else 4))
	main._show_focus_status_message("别追傀身，切线。", Color("88d8ff"), 1.0)


func _update_boss_silk(main: Node) -> void:
	if boss_shot_timer <= 0.0:
		var spoke_count := 5 if boss_cycle < 3 else 7
		_fire_boss_fan(main, spoke_count, 0.2, 230.0 + 18.0 * float(boss_cycle))
		boss_shot_timer = 0.95 if boss_cycle < 3 else 0.72
	if main._count_active_silks() <= 0:
		_begin_boss_vulnerable_phase(main)
	elif boss_phase_timer <= 0.0:
		boss_phase_timer = 2.4
		boss_shot_timer = minf(boss_shot_timer, 0.18)
		main._show_focus_status_message("线不断，破绽不开。", Color("f87171"), 0.9)


func _begin_boss_vulnerable_phase(main: Node) -> void:
	boss_phase = BOSS_PHASE_VULNERABLE
	boss_phase_timer = BOSS_WINDOW_DURATION
	boss_shot_timer = 1.2
	main._open_boss_vulnerability_window(BOSS_WINDOW_DURATION, true)
	main._show_focus_status_message("破绽开了。近身斩，御剑追。", Color("facc15"), 1.0)


func _update_boss_vulnerable(main: Node) -> void:
	if boss_phase_timer > 0.0:
		return
	main.boss["is_vulnerable"] = false
	main.boss["vulnerable_timer"] = 0.0
	if boss_cycle >= 3:
		boss_cycle = 2
	_begin_boss_silk_phase(main)


func _fire_boss_fan(main: Node, spoke_count: int, angle_step: float, speed: float) -> void:
	if not main._has_boss():
		return
	var to_player: Vector2 = Vector2(main.player.get("pos", main.ARENA_SIZE * 0.5)) - Vector2(main.boss.get("pos", Vector2.ZERO))
	if to_player.is_zero_approx():
		to_player = Vector2.DOWN
	var base_angle := to_player.angle()
	var center_index := float(spoke_count - 1) * 0.5
	for shot_index in range(spoke_count):
		var angle := base_angle + (float(shot_index) - center_index) * angle_step
		main._spawn_bullet(
			main.boss["pos"],
			Vector2.RIGHT.rotated(angle) * speed,
			"small",
			str(main.boss.get("id", "demo_boss")),
			main.COLORS["bullet"],
			{
				"family": main.BULLET_FAMILY_WEAVE,
				"source_enemy_type": "demo_boss",
			}
		)


func _complete_level(main: Node) -> void:
	completed = true
	active = false
	phase = PHASE_COMPLETE
	main._create_particles(main.boss.get("pos", main.ARENA_SIZE * 0.5), main.COLORS["boss_body"], 42)
	main._clear_target_runtime_state("boss")
	main._clear_target_hurtboxes("boss")
	main.boss.clear()
	main.enemies.clear()
	main.bullets.clear()
	victory_data = stats.duplicate(true)
	victory_data["clear_time"] = maxf(main.elapsed_time - float(stats.get("start_time", main.elapsed_time)), 0.0)
	main.demo_victory_result = victory_data.duplicate(true)
	main.demo_victory_visible = true
	main._show_status_message("破晓", Color("f1e3bc"), 3.0)


func _update_recovery_pickups(main: Node, delta: float) -> void:
	var index: int = main.demo_recovery_pickups.size() - 1
	while index >= 0:
		var pickup: Dictionary = main.demo_recovery_pickups[index]
		pickup["pulse"] = float(pickup.get("pulse", 0.0)) + delta
		if Vector2(pickup.get("pos", Vector2.ZERO)).distance_to(Vector2(main.player.get("pos", Vector2.ZERO))) <= RECOVERY_PICKUP_DISTANCE:
			var amount := float(pickup.get("amount", SMALL_RECOVERY_AMOUNT))
			var before_health := float(main.player.get("health", main.PLAYER_MAX_HEALTH))
			main.player["health"] = minf(before_health + amount, main.PLAYER_MAX_HEALTH)
			stats["pickups"] = int(stats.get("pickups", 0)) + 1
			main._create_particles(Vector2(pickup.get("pos", main.player["pos"])), main.COLORS["health"], 12)
			main.demo_recovery_pickups.remove_at(index)
		else:
			main.demo_recovery_pickups[index] = pickup
		index -= 1


func _spawn_recovery_pickup(main: Node, position: Vector2, amount: float, is_major: bool) -> void:
	main.demo_recovery_pickups.append({
		"id": main._next_id("recovery"),
		"pos": _safe_pickup_pos(main, position),
		"amount": amount,
		"radius": RECOVERY_RADIUS + (5.0 if is_major else 0.0),
		"is_major": is_major,
		"pulse": randf() * TAU,
	})


func _safe_pickup_pos(main: Node, position: Vector2) -> Vector2:
	return position.clamp(Vector2(42.0, 42.0), main.ARENA_SIZE - Vector2(42.0, 42.0))


func _build_segment_queue(main: Node, index: int) -> Array:
	var queue: Array = []
	match index:
		0:
			_append_drill(main, queue, main.SHOOTER, [Vector2(-96.0, -178.0), Vector2(0.0, -194.0), Vector2(96.0, -178.0)], 0.08, 0.72)
			_append_drill(main, queue, main.SHOOTER, [Vector2(-152.0, -128.0), Vector2(152.0, -128.0), Vector2(-46.0, -184.0), Vector2(46.0, -184.0)], 0.08, 0.82)
		1:
			_append_drill(main, queue, main.HEAVY, [Vector2(-86.0, -254.0), Vector2(86.0, -254.0)], 0.16, 0.76)
			_append_drill(main, queue, main.SHOOTER, [Vector2(-150.0, -158.0), Vector2(0.0, -196.0), Vector2(150.0, -158.0)], 0.08, 0.74)
			_append_drill(main, queue, main.HEAVY, [Vector2(0.0, -286.0), Vector2(128.0, -236.0)], 0.18, 0.78)
		2:
			_append_drill(main, queue, main.TANK, [Vector2(-70.0, -124.0), Vector2(70.0, -124.0)], 0.14, 0.52)
			_append_drill(main, queue, main.RING_LEECH, [Vector2(-180.0, -86.0), Vector2(180.0, -86.0), Vector2(-116.0, 96.0), Vector2(116.0, 96.0)], 0.08, 0.78)
			_append_drill(main, queue, main.HEAVY, [Vector2(-110.0, -250.0), Vector2(110.0, -250.0)], 0.18, 0.76)
		3:
			queue.append(main._make_enemy_spawn_entry_near(main.DRAPE_PRIEST, Vector2(0.0, -266.0), 0.26))
			_append_drill(main, queue, main.TANK, [Vector2(-72.0, -140.0), Vector2(72.0, -140.0)], 0.12, 0.62)
			_append_drill(main, queue, main.SHOOTER, [Vector2(-184.0, -150.0), Vector2(184.0, -150.0), Vector2(0.0, -196.0)], 0.08, 0.72)
			queue.append(main._make_enemy_spawn_entry_near(main.DRAPE_PRIEST, Vector2(118.0, -278.0), 0.34))
			_append_drill(main, queue, main.HEAVY, [Vector2(-116.0, -244.0)], 0.12, 0.82)
		4:
			_append_drill(main, queue, main.MIRROR_NEEDLER, [Vector2(0.0, -302.0)], 0.1, 0.42)
			_append_drill(main, queue, main.HEAVY, [Vector2(-112.0, -238.0), Vector2(112.0, -238.0)], 0.14, 0.62)
			_append_drill(main, queue, main.SHOOTER, [Vector2(-198.0, -142.0), Vector2(198.0, -142.0), Vector2(0.0, -190.0)], 0.08, 0.56)
			_append_drill(main, queue, main.MIRROR_NEEDLER, [Vector2(-128.0, -304.0), Vector2(128.0, -304.0)], 0.14, 0.82)
		5:
			queue.append(main._make_ring_leech_package_entry(main.RING_LEECH_PACKAGE_MIN_COUNT, 0.78))
			queue.append(main._make_enemy_spawn_entry_near(main.DRAPE_PRIEST, Vector2(-132.0, -252.0), 0.16))
			_append_drill(main, queue, main.TANK, [Vector2(-72.0, -132.0), Vector2(72.0, -132.0)], 0.12, 0.48)
			queue.append(main._make_enemy_spawn_entry_near(main.MIRROR_NEEDLER, Vector2(118.0, -304.0), 0.28))
			queue.append(main._make_enemy_spawn_entry_near(main.MIRROR_NEEDLER, Vector2(-118.0, -304.0), 0.28))
			_append_drill(main, queue, main.SHOOTER, [Vector2(-220.0, -150.0), Vector2(0.0, -204.0), Vector2(220.0, -150.0)], 0.08, 0.66)
	return queue


func _append_drill(main: Node, queue: Array, enemy_type: String, offsets: Array, delay_between: float, delay_after: float) -> void:
	var entry_index := 0
	while entry_index < offsets.size():
		var delay := delay_after if entry_index == offsets.size() - 1 else delay_between
		queue.append(main._make_enemy_spawn_entry_near(enemy_type, Vector2(offsets[entry_index]), delay))
		entry_index += 1


func _get_segment_title(index: int) -> String:
	match index:
		0:
			return "庙门压入"
		1:
			return "廊下重针"
		2:
			return "烛影围逼"
		3:
			return "供桌丝线"
		4:
			return "重针审判"
		5:
			return "夜袭合围"
	return ""


func _get_segment_hint(index: int) -> String:
	match index:
		0:
			return "左键先活下来。飞来的针，可以斩回去。"
		1:
			return "远处那枚重针，右键御剑去断。"
		2:
			return "贴身别慌，先斩开身前，再召剑回手。"
		3:
			return "那根线不对。线断了，局面才会松。"
		4:
			return "大针能斩回去，镜壳破时再追。"
		5:
			return "先稳近身，再切线，最后处理远处。"
	return ""
