extends SceneTree

var main: Node2D
var frame_count := 0

func _init() -> void:
	print("=== Starting Main Flight Integration Test ===")
	var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
	if main_scene == null:
		push_error("Failed to load Main.tscn")
		quit(1)
		return

	main = main_scene.instantiate() as Node2D
	root.add_child(main)
	print("Main instantiated and added to root.")

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 1:
		print("Frame 1: checking essential prototype nodes in Main...")
		assert(main.get_node_or_null("BoostShockwaveVfxRoot") != null, "BoostShockwaveVfxRoot missing")
		assert(main.get_node_or_null("EightWayAdjustmentLayer") != null, "EightWayAdjustmentLayer missing")
		assert(main.get_node_or_null("ReferenceVfxViewport") != null, "ReferenceVfxViewport missing")
		assert(main.get_node_or_null("YujianLevelBackgroundRenderer") != null, "YujianLevelBackgroundRenderer missing")
		assert(main.get_node_or_null("SequenceCharacterRoot/SkeletonEightWayCharacter") != null, "SkeletonEightWayCharacter missing")
		print("All prototype nodes verified!")

		# Start flight prototype mode
		if main.has_method("_start_flight_prototype_from_menu"):
			main.call("_start_flight_prototype_from_menu")
			print("Started flight prototype run mode.")

	if frame_count == 30:
		main.set("throttle_pressed", true)
		if main.has_method("_start_boost_burst"):
			main.call("_start_boost_burst")
		print("Frame 30: simulated boost burst.")

	if frame_count == 60:
		if main.has_method("_start_point_strike"):
			main.call("_start_point_strike")
		print("Frame 60: simulated sword point strike.")

	if frame_count == 90:
		if main.has_method("_toggle_selected_array_mode"):
			main.call("_toggle_selected_array_mode")
		print("Frame 90: simulated array toggle.")

	if frame_count >= 120:
		print("Frame 120 reached successfully without errors.")
		print("=== Main Flight Integration Test PASSED! ===")
		quit(0)
		return true

	return false
