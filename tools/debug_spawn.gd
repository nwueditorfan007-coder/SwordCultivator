extends SceneTree

func _init() -> void:
	print("Debugging step by step...")
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	var main: Node2D = packed.instantiate() as Node2D
	root.add_child(main)

	print("Initial main.is_start_menu_active: ", main.get("is_start_menu_active"))
	print("Initial main.run_mode: ", main.get("run_mode"))
	print("Initial main.flight_stage_timer: ", main.get("flight_stage_timer"))

	var dt: float = 1.0 / 60.0
	for i in range(120): # 2 seconds
		main._process(dt)
		if i % 30 == 0:
			print("Frame ", i, " timer: ", main.get("flight_stage_timer"), " script_index: ", main.get("flight_script_index"), " enemies: ", main.enemies.size())

	print("Final enemies size: ", main.enemies.size())
	quit(0)
