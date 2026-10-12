extends SceneTree

# 验证飞行大战场「交锋参考系 + 出剑凝滞」：
# 玩家以巡航速度飞行时，交锋敌人相对玩家的运动应稳定；出剑凝滞期间应接近定格；
# 光标不动时连斩飞剑不应因巡航位移而产生切割命中。
# 运行：godot --headless --fixed-fps 60 --path . --script tools/flight_slice_frame_test.gd

const FRAME_DELTA := 1.0 / 60.0
const MAX_DILATED_RELATIVE_SPEED := 150.0

var main: Node


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/main/Main.tscn")
	if packed_scene == null:
		_fail("Failed to load main scene.")
		return
	main = packed_scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.run_mode = main.RUN_MODE_FLIGHT_PROTOTYPE
	main.is_start_menu_active = false
	main._reset_game()
	Input.action_press("move_right")
	for _i in range(60):
		await process_frame
	var cruise_speed: float = Vector2(main.player.get("vel", Vector2.ZERO)).length()

	main._update_flight_prototype(1.0)
	if main.enemies.size() < 2:
		_fail("Free flight director did not spawn its first enemy group.")
		return
	# 把玩家放到敌群前方，模拟「飞近敌群」，由导演自然激活。
	var group_center: Vector2 = Vector2(main.flight_encounter_director.groups[0]["center"])
	var approach_pos := group_center - Vector2(700.0, 0.0)
	main.flight_pos = approach_pos
	main.player["pos"] = approach_pos
	main.camera_center = approach_pos
	for _i in range(20):
		await process_frame

	var cruise_stats := await _measure_relative_motion(90)

	# 敌弹：巡航中弹道应以固定相对速度在屏幕上直线推进。
	var shooter_id := ""
	for enemy_variant in main.enemies:
		if not bool(Dictionary(enemy_variant).get("is_dying", false)):
			shooter_id = str(Dictionary(enemy_variant).get("id", ""))
			break
	var bullet_origin: Vector2 = Vector2(main.player["pos"]) + Vector2(0.0, -600.0)
	main._spawn_bullet(bullet_origin, Vector2(0.0, 150.0), "small", shooter_id, Color.WHITE)
	var bullet: Dictionary = main.bullets[main.bullets.size() - 1]
	var bullet_rel_start: Vector2 = Vector2(bullet["pos"]) - Vector2(main.player["pos"])
	for _i in range(20):
		await process_frame
	var bullet_rel_speed: float = (Vector2(bullet["pos"]) - Vector2(main.player["pos"]) - bullet_rel_start).length() / (20.0 * FRAME_DELTA)
	print("[FLIGHT-FRAME] enemy bullet relative speed while cruising: %.0f px/s" % bullet_rel_speed)
	if absf(bullet_rel_speed - main.FLIGHT_BULLET_RELATIVE_SPEED) > 80.0:
		_fail("Enemy bullet relative speed is unstable while cruising (%.0f px/s)." % bullet_rel_speed)
		return

	var health_before := _total_enemy_health()
	main._start_sword_attack_instance(main.AttackProfiles.PROFILE_FLYING_SWORD_SLICE)
	main.sword["state"] = main.SwordState.SLICING
	main.sword["time_slow_timer"] = 0.0
	var dilated_stats := await _measure_relative_motion(15)
	var dilation_ratio: float = main.flight_combat_time_ratio
	var health_after := _total_enemy_health()

	# 势：同一刀斩 3 个 -> 10 + 14 + 18 = 42，进入「起势」；收刀结算后开启斩后爆速。
	for _k in range(3):
		main._register_flight_momentum_kill({})
	var momentum_value: float = main.flight_momentum.value
	var momentum_tier: int = main.flight_momentum.get_tier()
	main.sword["state"] = main.SwordState.RECALLING
	await process_frame
	var bursting: bool = main.flight_momentum.is_bursting()
	var peak_speed := 0.0
	for _i in range(30):
		await process_frame
		peak_speed = maxf(peak_speed, Vector2(main.player.get("vel", Vector2.ZERO)).length())
	Input.action_release("move_right")
	print("[FLIGHT-FRAME] momentum after 3-kill strike: %.0f (tier %d), burst=%s, peak speed %.0f px/s" % [momentum_value, momentum_tier, str(bursting), peak_speed])
	if momentum_tier != 1 or not bursting:
		_fail("Momentum did not rise to tier 1 and burst after a 3-kill strike.")
		return
	if peak_speed <= cruise_speed * 1.2:
		_fail("Post-strike burst did not raise flight speed (peak %.0f)." % peak_speed)
		return

	print("[FLIGHT-FRAME] player cruise speed: %.0f px/s" % cruise_speed)
	print("[FLIGHT-FRAME] cruise   relative speed mean %.0f / max %.0f px/s (samples %d)" % [cruise_stats.mean, cruise_stats.max, cruise_stats.samples])
	print("[FLIGHT-FRAME] dilated  relative speed mean %.0f / max %.0f px/s (samples %d)" % [dilated_stats.mean, dilated_stats.max, dilated_stats.samples])
	print("[FLIGHT-FRAME] dilation ratio after 15 frames: %.2f" % dilation_ratio)
	print("[FLIGHT-FRAME] enemy health lost with idle cursor: %.1f" % (health_before - health_after))

	if cruise_stats.samples == 0 or dilated_stats.samples == 0:
		_fail("No engagement enemy samples were collected.")
		return
	if dilation_ratio >= 0.5:
		_fail("Flight slice dilation is not active (ratio %.2f)." % dilation_ratio)
		return
	if dilated_stats.mean > MAX_DILATED_RELATIVE_SPEED:
		_fail("Engagement enemies move too fast on screen during dilation (%.0f px/s)." % dilated_stats.mean)
		return
	if health_before - health_after > 0.01:
		_fail("Idle cursor slicing damaged enemies while cruising.")
		return
	print("[FLIGHT-FRAME] PASSED")
	quit(0)


func _measure_relative_motion(frames: int) -> Dictionary:
	var previous := _collect_relative_positions()
	var total := 0.0
	var peak := 0.0
	var samples := 0
	for _i in range(frames):
		await process_frame
		var current := _collect_relative_positions()
		for enemy_id in current.keys():
			if not previous.has(enemy_id):
				continue
			var speed: float = (Vector2(current[enemy_id]) - Vector2(previous[enemy_id])).length() / FRAME_DELTA
			total += speed
			peak = maxf(peak, speed)
			samples += 1
		previous = current
	return {"mean": total / maxf(float(samples), 1.0), "max": peak, "samples": samples}


func _collect_relative_positions() -> Dictionary:
	var result := {}
	var player_pos: Vector2 = Vector2(main.player.get("pos", Vector2.ZERO))
	for enemy_variant in main.enemies:
		var enemy: Dictionary = enemy_variant
		if bool(enemy.get("is_dying", false)) or not bool(enemy.get("engagement_ai_active", false)):
			continue
		if not bool(enemy.get("large_arena_trajectory_active", false)):
			continue
		result[str(enemy.get("id", ""))] = Vector2(enemy.get("pos", Vector2.ZERO)) - player_pos
	return result


func _total_enemy_health() -> float:
	var total := 0.0
	for enemy_variant in main.enemies:
		var enemy: Dictionary = enemy_variant
		total += float(enemy.get("health", 0.0))
	return total


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
