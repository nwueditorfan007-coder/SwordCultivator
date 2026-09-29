extends SceneTree


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/main/Main.tscn")
	if packed_scene == null:
		_fail("Failed to load main scene.")
		return

	var main: Node = packed_scene.instantiate()
	if main == null:
		_fail("Failed to instantiate main scene.")
		return

	get_root().add_child(main)
	await process_frame

	# 大战场现在通过菜单选择进入，默认启动模式是飞行原型；
	# 测试显式切换到旧波次入口，避免把默认菜单模式误判成大战场配置错误。
	main.run_mode = main.RUN_MODE_LEGACY_WAVES
	main.is_start_menu_active = false
	main._reset_game()
	await process_frame

	if not main._is_large_arena_test_enabled():
		_fail("Large arena test should be enabled in legacy waves mode.")
		return
	var active_arena_size: Vector2 = main._get_arena_size()
	if active_arena_size.x < main.LARGE_ARENA_SIZE.x or active_arena_size.y < main.LARGE_ARENA_SIZE.y:
		_fail("Active battlefield is smaller than the large-arena objective space: %s" % [active_arena_size])
		return
	if main._get_screen_play_rect() != main.get_viewport_rect():
		_fail("Large arena should use the actual viewport as the play rect.")
		return
	var expected_player_start: Vector2 = main._get_initial_player_position()
	if Vector2(main.player.get("pos", Vector2.ZERO)).distance_to(expected_player_start) > 0.1:
		_fail("Unexpected player start: %s (expected %s)" % [main.player.get("pos", Vector2.ZERO), expected_player_start])
		return
	if not main._is_flying_sword_unlocked():
		_fail("Large arena should unlock flying sword from the start.")
		return
	if not main._is_array_mode_unlocked("ring") or not main._is_array_mode_unlocked("fan") or not main._is_array_mode_unlocked("pierce"):
		_fail("Large arena should unlock every sword array mode from the start.")
		return
	if main.LARGE_ARENA_MAX_PURSUERS > 2:
		_fail("Large arena should keep pursuer pressure light in the objective test.")
		return
	if main.LARGE_ARENA_GUARDS_PER_EYE > 1:
		_fail("Large arena should keep each formation eye guarded by a small escort.")
		return

	main.is_start_menu_active = false
	main.player["pos"] = Vector2(main.player.get("pos", Vector2.ZERO)) + Vector2(160.0, -70.0)
	if main._uses_flight_prototype_battlefield():
		main.camera_center = main.player["pos"]
		var flight_screen_center: Vector2 = main.VIEW_SIZE * 0.5
		if main._to_screen(main.player["pos"]).distance_to(flight_screen_center) > 0.5:
			_fail("Shared flight camera should keep player centered.")
			return
	else:
		var cursor_screen_before: Vector2 = main._to_screen(main.mouse_world)
		main._update_large_arena_camera(0.016)
		var arena_screen_center: Vector2 = main._get_screen_play_rect().get_center()
		if main._to_screen(main.player["pos"]).distance_to(arena_screen_center) > 0.5:
			_fail("Large arena camera should keep player centered.")
			return
		var cursor_screen_after: Vector2 = main._to_screen(main.mouse_world)
		if cursor_screen_after.distance_to(cursor_screen_before) > 0.5:
			_fail("Large arena virtual cursor drifted after camera movement.")
			return

	main._spawn_large_arena_pursuer_if_needed()
	var pursuer_found := false
	for enemy_variant in main.enemies:
		var enemy: Dictionary = enemy_variant
		if str(enemy.get("large_arena_role", "")) == "pursuer":
			pursuer_found = true
			if float(enemy.get("max_health", 0.0)) < main.LARGE_ARENA_PURSUER_HEALTH:
				_fail("Large arena pursuer health tuning was not applied.")
				return
			if float(enemy.get("move_speed_multiplier", 1.0)) <= 1.0:
				_fail("Large arena pursuer speed tuning was not applied.")
				return
	if not pursuer_found:
		_fail("Large arena pursuer was not spawned.")
		return
	main._spawn_large_arena_guards_if_needed()
	if main._count_large_arena_enemies("eye_guard", main.LARGE_ARENA_UPPER_EYE_KEY) != main.LARGE_ARENA_GUARDS_PER_EYE:
		_fail("Upper formation eye guard count did not match the tuned objective-test pressure.")
		return
	if main._count_large_arena_enemies("eye_guard", main.LARGE_ARENA_LOWER_EYE_KEY) != main.LARGE_ARENA_GUARDS_PER_EYE:
		_fail("Lower formation eye guard count did not match the tuned objective-test pressure.")
		return

	var upper_eye: Variant = main._get_large_arena_objective(main.LARGE_ARENA_UPPER_EYE_KEY)
	var lower_eye: Variant = main._get_large_arena_objective(main.LARGE_ARENA_LOWER_EYE_KEY)
	var core: Variant = main._get_large_arena_objective(main.LARGE_ARENA_CORE_KEY)
	if upper_eye == null or lower_eye == null or core == null:
		_fail("Large arena objectives were not spawned.")
		return

	var core_health: float = float(core.get("health", 0.0))
	main._damage_enemy(core, 9999.0, main.DAMAGE_SOURCE_SYSTEM)
	if not is_equal_approx(float(core.get("health", 0.0)), core_health):
		_fail("Sealed core took damage.")
		return

	main._damage_enemy(upper_eye, 9999.0, main.DAMAGE_SOURCE_SYSTEM)
	if str(main.large_arena_objective_states.get(main.LARGE_ARENA_UPPER_EYE_KEY, "")) != main.LARGE_ARENA_STATE_DESTROYED:
		_fail("Upper formation eye did not enter destroyed state.")
		return
	if main._count_large_arena_enemies("eye_guard", main.LARGE_ARENA_UPPER_EYE_KEY) != 0:
		_fail("Upper formation eye guards should disperse when their eye is destroyed.")
		return
	if str(main.large_arena_objective_states.get(main.LARGE_ARENA_CORE_KEY, "")) != main.LARGE_ARENA_STATE_SEALED:
		_fail("Core opened before both eyes were destroyed.")
		return
	if main._has_boss():
		_fail("Boss should not spawn before both formation eyes are destroyed.")
		return

	main._damage_enemy(lower_eye, 9999.0, main.DAMAGE_SOURCE_SYSTEM)
	if str(main.large_arena_objective_states.get(main.LARGE_ARENA_LOWER_EYE_KEY, "")) != main.LARGE_ARENA_STATE_DESTROYED:
		_fail("Lower formation eye did not enter destroyed state.")
		return
	if str(main.large_arena_objective_states.get(main.LARGE_ARENA_CORE_KEY, "")) != main.LARGE_ARENA_STATE_VULNERABLE:
		_fail("Core did not become vulnerable after both eyes were destroyed.")
		return
	if main._count_large_arena_enemies("pursuer") != 0:
		_fail("Pursuers should clear when the boss phase opens.")
		return
	if not main._has_boss():
		_fail("Boss should spawn after both formation eyes are destroyed.")
		return
	if str(main.boss.get("large_arena_role", "")) != "boss":
		_fail("Large arena boss role was not tagged.")
		return
	if Vector2(main.boss.get("pos", Vector2.ZERO)).distance_to(main.LARGE_ARENA_BOSS_SPAWN_POS) > 0.1:
		_fail("Large arena boss spawned at an unexpected position: %s" % [main.boss.get("pos", Vector2.ZERO)])
		return

	main._damage_enemy(core, 9999.0, main.DAMAGE_SOURCE_SYSTEM)
	if not main.large_arena_completed or not main.is_game_over:
		_fail("Core destruction did not complete the large arena test.")
		return

	main.queue_free()
	await process_frame

	var legacy_main: Node = packed_scene.instantiate()
	if legacy_main == null:
		_fail("Failed to instantiate legacy main scene.")
		return
	legacy_main.large_arena_test_enabled = false
	get_root().add_child(legacy_main)
	await process_frame

	if legacy_main._is_large_arena_test_enabled():
		_fail("Legacy arena mode should be active when large arena test is disabled.")
		return
	if legacy_main._get_arena_size() != legacy_main.PLAY_SIZE:
		_fail("Unexpected shared flight battlefield size: %s" % [legacy_main._get_arena_size()])
		return
	if legacy_main._get_screen_play_rect() != legacy_main.ARENA_RECT and legacy_main._get_screen_play_rect() != legacy_main.get_viewport_rect():
		_fail("Legacy fallback should expose a valid play rect.")
		return
	var expected_legacy_start: Vector2 = legacy_main._get_initial_player_position()
	if Vector2(legacy_main.player.get("pos", Vector2.ZERO)).distance_to(expected_legacy_start) > 0.1:
		_fail("Unexpected legacy player start: %s" % [legacy_main.player.get("pos", Vector2.ZERO)])
		return
	if int(legacy_main.enemies_to_spawn) != int(legacy_main.WAVE_BASE_ENEMIES):
		_fail("Legacy wave spawn count was not initialized.")
		return

	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
