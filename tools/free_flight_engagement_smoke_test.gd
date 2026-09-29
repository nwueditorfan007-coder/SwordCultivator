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
	main.flight_stage_timer = 0.99
	main._update_flight_prototype(0.02)
	if main.enemies.size() < 2:
		_fail("Free flight did not spawn its first scripted enemies.")
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
