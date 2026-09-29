extends SceneTree

var main: Node
var frame_count := 0


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/main/Main.tscn")
	main = packed_scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main._start_legacy_waves_from_menu()
	print("MODE_AFTER_START=", main.run_mode, " LARGE=", main._is_large_arena_test_enabled(), " START_MENU=", main.is_start_menu_active)
	print("PLAYER=", main.player.get("pos"), " TIMER=", main.large_arena_pursuer_timer, " ENEMIES=", main.enemies.size())


func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count % 30 == 0:
		print("FRAME=", frame_count, " MODE=", main.run_mode, " LARGE=", main._is_large_arena_test_enabled(), " TIMER=", main.large_arena_pursuer_timer, " ENEMIES=", main.enemies.size(), " PLAYER=", main.player.get("pos"))
		for enemy_variant in main.enemies:
			var enemy: Dictionary = enemy_variant
			print(" ENEMY role=", enemy.get("large_arena_role", ""), " type=", enemy.get("type", ""), " pos=", enemy.get("pos", Vector2.ZERO), " dying=", enemy.get("is_dying", false))
	if frame_count >= 600:
		quit(0)
	return false
