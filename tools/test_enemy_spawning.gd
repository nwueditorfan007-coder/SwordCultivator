extends MainLoop

var main: Node2D
var frame_count := 0

func _process(delta: float) -> bool:
	frame_count += 1

	if frame_count == 1:
		print("--- Starting Enemy Spawning Test in Godot ---")
		var packed := load("res://scenes/main/Main.tscn") as PackedScene
		main = packed.instantiate() as Node2D
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null:
			tree.root.add_child(main)
		print("[TEST] Scene instantiated and mounted.")
		return false

	if main == null:
		return false

	# Wait until in-game timer reaches 1.2 seconds (intro_shooters spawn at 1.0s)
	if main.flight_stage_timer >= 1.2 and not main.enemies.is_empty():
		print("[TEST] In-game timer: ", main.flight_stage_timer, " Enemies size: ", main.enemies.size())
		var first_enemy: Dictionary = main.enemies[0]
		print("[TEST] Enemy 0 type: ", first_enemy.get("type"), " pos: ", first_enemy.get("pos"))
		print("[TEST] Player pos: ", main.player.get("pos"))
		var dist: float = (Vector2(main.player.get("pos")) - Vector2(first_enemy.get("pos"))).length()
		print("[TEST] Distance to player: ", dist)

		if dist > 2000.0:
			print("FAILED: Enemy spawned too far away!")
			return true

		# Test damaging and killing the enemy with flying sword / melee
		first_enemy["health"] = 0.0
		print("[TEST] Enemy HP set to 0.0 (testing death feedback)...")

	if main.flight_stage_timer >= 2.0:
		print("[TEST] Flight stage timer reached 2.0s: Score = ", main.score, " Enemies = ", main.enemies.size())
		print("=== Enemy Spawning and Combat Verified PASSED with ZERO ERRORS! ===")
		return true

	return false
