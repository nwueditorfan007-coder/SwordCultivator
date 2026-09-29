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

	main.run_mode = main.RUN_MODE_LEGACY_WAVES
	main.is_start_menu_active = false
	main._reset_game()
	await process_frame
	if not main._is_large_arena_test_enabled():
		_fail("Legacy waves mode did not enable the large-arena engagement layer.")
		return

	var player_pos: Vector2 = Vector2(main.player.get("pos", Vector2.ZERO))
	main.large_arena_camera_center = player_pos
	main._spawn_large_arena_pursuer_if_needed()
	var pursuer: Dictionary = {}
	for enemy_variant in main.enemies:
		var candidate: Dictionary = enemy_variant
		if str(candidate.get("large_arena_role", "")) == "pursuer":
			pursuer = candidate
			break
	if pursuer.is_empty():
		_fail("Pursuer was not spawned.")
		return
	if Vector2(pursuer.get("large_arena_entry_direction", Vector2.ZERO)).is_zero_approx():
		_fail("Pursuer did not receive an entry direction.")
		return

	var start_pos: Vector2 = Vector2(pursuer.get("pos", Vector2.ZERO))
	var saw_override := false
	var frame := 0
	while frame < 30:
		if main._update_large_arena_engagement(pursuer, 0.016):
			saw_override = saw_override or bool(pursuer.get("large_arena_movement_overridden", false))
		frame += 1
	if not saw_override:
		_fail("Pursuer movement was not handed to the engagement trajectory.")
		return
	if Vector2(pursuer.get("pos", start_pos)).distance_to(start_pos) <= 0.5:
		_fail("Pursuer engagement trajectory did not move the enemy.")
		return

	# 交战安全区只允许真实可见区域内攻击，屏外接近不得开火。
	pursuer["large_arena_trajectory_active"] = false
	pursuer["pos"] = player_pos
	main._update_large_arena_engagement(pursuer, 0.016)
	if not bool(pursuer.get("large_arena_attack_enabled", false)):
		_fail("Visible pursuer was incorrectly prevented from attacking.")
		return
	var visible_rect: Rect2 = main._get_large_arena_visible_world_rect()
	pursuer["pos"] = visible_rect.position - Vector2(180.0, 0.0)
	main._update_large_arena_engagement(pursuer, 0.016)
	if bool(pursuer.get("large_arena_attack_enabled", false)):
		_fail("Off-screen pursuer was allowed to attack.")
		return

	main.queue_free()
	await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
