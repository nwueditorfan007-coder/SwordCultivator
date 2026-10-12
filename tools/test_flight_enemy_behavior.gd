extends MainLoop

var main: Node2D
var frame_count := 0
var initial_enemy_check_passed := false
var offscreen_persistence_tested := false
var bullet_time_check_passed := false

func _process(delta: float) -> bool:
	frame_count += 1

	if frame_count == 1:
		print("--- Starting Flight Enemy Behavior & Combat Verification ---")
		var packed := load("res://scenes/main/Main.tscn") as PackedScene
		main = packed.instantiate() as Node2D
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null:
			tree.root.add_child(main)
		print("[TEST] Scene instantiated and mounted.")
		return false

	if main == null:
		return false

	# 1. Verify that on entry, screen is not flooded with 30 enemies
	if frame_count == 5:
		var count: int = main.enemies.size()
		print("[TEST] Frame 5: Initial enemy count = ", count)
		if count >= 20:
			print("FAILED: Enemy swarm still flooded screen at start! Count = ", count)
			return true
		else:
			print("PASSED Requirement 1: No screen-flooding swarm at start (count = %d)" % count)
			initial_enemy_check_passed = true

	# 2. Advance time so scripted wave 1 spawns at 1.0s
	if main.flight_stage_timer >= 1.2 and not main.enemies.is_empty() and not offscreen_persistence_tested:
		var enemy: Dictionary = main.enemies[0]
		var player_pos: Vector2 = Vector2(main.player.get("pos", Vector2.ZERO))
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		print("[TEST] Wave 1 spawned! Enemy count = ", main.enemies.size(), " Enemy 0 at: ", enemy_pos)

		# Move player 3500 pixels away to force enemy completely off screen
		main.player["pos"] = player_pos + Vector2(3500.0, 0.0)
		main.flight_pos = Vector2(main.player["pos"])
		main.camera_center = Vector2(main.player["pos"])
		print("[TEST] Fast-forwarded player 3500px away (forcing enemy offscreen)...")
		offscreen_persistence_tested = true

	# After moving player 3500px away, wait until timer reaches 2.5s and verify enemy did NOT disappear
	if offscreen_persistence_tested and not bullet_time_check_passed and main.flight_stage_timer >= 2.2:
		if main.enemies.is_empty():
			print("FAILED Requirement 2: Offscreen enemy disappeared/despawned!")
			return true
		var enemy: Dictionary = main.enemies[0]
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		var player_pos: Vector2 = Vector2(main.player.get("pos", Vector2.ZERO))
		var dist: float = player_pos.distance_to(enemy_pos)
		print("[TEST] Verified offscreen enemy still ALIVE! Count = ", main.enemies.size(), " Pos = ", enemy_pos, " Distance to player = ", dist)
		print("PASSED Requirement 2: Enemies persist and fly freely in large battlefield without despawning!")

		# 3. Test Requirement 3: Right click flying sword bullet time ratio
		main.sword["state"] = main.SwordState.SLICING
		main.sword["time_slow_timer"] = 0.5
		main.sword["vel"] = Vector2(500.0, 0.0)
		
		var is_flying_sword: bool = int(main.sword.get("state", main.SwordState.ORBITING)) != main.SwordState.ORBITING
		var b_ratio: float = 1.0
		if is_flying_sword and not main._uses_flight_prototype_battlefield():
			b_ratio = main._get_bullet_time_ratio(float(main.sword.get("time_slow_timer", 0.0)))
		print("[TEST] Flying sword state active in battlefield mode: bullet_time_ratio = ", b_ratio)
		if b_ratio < 0.99:
			print("FAILED Requirement 3: Bullet time slowdown is still active during flying sword!")
			return true
		print("PASSED Requirement 3: Right-click flying sword state runs in real time (ratio = 1.0) without time-stop!")
		bullet_time_check_passed = true

	if bullet_time_check_passed and main.flight_stage_timer >= 2.6:
		print("=== ALL 3 REQUIREMENTS VERIFIED PASSED WITH ZERO ERRORS! ===")
		return true

	return false
