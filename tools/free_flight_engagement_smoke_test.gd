extends SceneTree


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/main/Main.tscn")
	if packed_scene == null:
		_fail("Failed to load main scene.")
		return
	var main: Node = packed_scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.run_mode = main.RUN_MODE_FLIGHT_PROTOTYPE
	main.is_start_menu_active = false
	main._reset_game()
	# 入场导演先在远处派出待机敌群，玩家飞近后整组激活。
	main._update_flight_prototype(1.0)
	if main.enemies.size() < 2:
		_fail("Free flight director did not spawn its first enemy group.")
		return
	for enemy_variant in main.enemies:
		if not bool(Dictionary(enemy_variant).get("flight_dormant", false)):
			_fail("New director groups should wait dormant until the player approaches.")
			return
	var group_center: Vector2 = Vector2(main.flight_encounter_director.groups[0]["center"])
	var approach_pos := group_center - Vector2(700.0, 0.0)
	main.flight_pos = approach_pos
	main.player["pos"] = approach_pos
	main.camera_center = approach_pos
	main.flight_encounter_director.update(main, 0.016)
	for enemy_variant in main.enemies:
		if bool(Dictionary(enemy_variant).get("flight_dormant", false)):
			_fail("Director did not activate the group once it entered the screen.")
			return

	var tracked: Dictionary = {}
	for enemy_variant in main.enemies:
		var enemy: Dictionary = enemy_variant
		if bool(enemy.get("engagement_ai_active", false)):
			tracked[str(enemy.get("id", ""))] = Vector2(enemy.get("pos", Vector2.ZERO))
	if tracked.is_empty():
		_fail("Free flight scripted enemies were not assigned engagement AI.")
		return

	var had_bullet := false
	for _step in range(150):
		main._update_enemies(0.016, 0.016)
		main._update_flight_world_scroll(0.016)
		if not main.bullets.is_empty():
			had_bullet = true
	if not had_bullet:
		_fail("Free flight engagement enemies never produced an attack bullet.")
		return

	var moved := false
	for enemy_variant in main.enemies:
		var enemy: Dictionary = enemy_variant
		var enemy_id := str(enemy.get("id", ""))
		if not tracked.has(enemy_id):
			continue
		if Vector2(enemy.get("pos", Vector2.ZERO)).distance_to(Vector2(tracked[enemy_id])) > 1.0:
			moved = true
			break
	if not moved:
		_fail("Free flight engagement enemy did not move on its交会轨迹.")
		return

	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
