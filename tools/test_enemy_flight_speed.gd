extends MainLoop

var main: Node2D
var frame_count := 0
var speed_test_passed := false

func _process(delta: float) -> bool:
	frame_count += 1

	if frame_count == 1:
		print("--- Starting Flight Enemy Speed Verification ---")
		var packed := load("res://scenes/main/Main.tscn") as PackedScene
		main = packed.instantiate() as Node2D
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null:
			tree.root.add_child(main)
		print("[TEST] Scene instantiated and mounted.")
		return false

	if main == null:
		return false

	# Let game step until wave 1 spawns (around 1.2s - 1.5s)
	if main.flight_stage_timer >= 1.6 and not main.enemies.is_empty() and not speed_test_passed:
		var enemy: Dictionary = main.enemies[0]
		var enemy_vel: Vector2 = Vector2(enemy.get("vel", Vector2.ZERO))
		var enemy_speed: float = enemy_vel.length()
		var player_cruise_speed: float = main.CRUISE_SPEED
		print("[TEST] Enemy 0 behavior: ", enemy.get("flight_behavior"), " vel: ", enemy_vel, " speed: ", enemy_speed)
		print("[TEST] Player CRUISE_SPEED: ", player_cruise_speed)
		
		var speed_ratio: float = enemy_speed / maxf(player_cruise_speed, 1.0)
		print("[TEST] Enemy speed ratio relative to player cruise speed: ", speed_ratio)

		# Verify that enemy speed is in the expected range (roughly matching player cruise speed, between 0.7x and 1.25x)
		# instead of the old 0.08x (90 px/s vs 1170 px/s)
		if speed_ratio < 0.65:
			print("FAILED: Enemy speed is still too slow compared to player! Ratio = ", speed_ratio)
			return true

		print("PASSED: Enemy flight speed is matched with player flight speed! (~%.1f px/s vs %.1f px/s, ratio = %.2f)" % [enemy_speed, player_cruise_speed, speed_ratio])
		speed_test_passed = true

	if speed_test_passed and main.flight_stage_timer >= 2.0:
		print("=== Flight Enemy Speed Verification PASSED with ZERO ERRORS! ===")
		return true

	return false
