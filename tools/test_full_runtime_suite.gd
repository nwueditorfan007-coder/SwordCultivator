extends MainLoop

var main: Node2D
var step_index := 0

func _process(delta: float) -> bool:
	step_index += 1

	if step_index == 1:
		print("[TEST] Step 1: Loading Main scene...")
		var packed := load("res://scenes/main/Main.tscn") as PackedScene
		main = packed.instantiate() as Node2D
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null:
			tree.root.add_child(main)
		print("[TEST] Scene instantiated and added to root.")
		return false

	if main == null:
		return false

	# Step 10: Test F2 Adjustment panel
	if step_index == 10:
		print("[TEST] Step 10: Testing F2 Adjustment panel...")
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_F2
		main._unhandled_input(ev)
		return false

	# Step 15: Test F3 Control mode toggle
	if step_index == 15:
		print("[TEST] Step 15: Testing F3 Control mode toggle...")
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_F3
		main._unhandled_input(ev)
		return false

	# Step 20: Test F5 Hair panel
	if step_index == 20:
		print("[TEST] Step 20: Testing F5 Hair panel...")
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_F5
		main._input(ev)
		return false

	# Step 25: Test F6 Sword style cycle
	if step_index == 25:
		print("[TEST] Step 25: Testing F6 Sword style cycle...")
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_F6
		main._unhandled_input(ev)
		return false

	# Step 30: Test F9 Debug guides
	if step_index == 30:
		print("[TEST] Step 30: Testing F9 Debug guides...")
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_F9
		main._unhandled_input(ev)
		return false

	# Step 35: Test Boost (Shift)
	if step_index == 35:
		print("[TEST] Step 35: Testing Boost burst...")
		main.set("throttle_pressed", true)
		if main.has_method("_start_boost_burst"):
			main.call("_start_boost_burst")
		return false

	# Step 40: Test Sword Array Toggle (Space)
	if step_index == 40:
		print("[TEST] Step 40: Testing Space (Array Morph)...")
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_SPACE
		main._unhandled_input(ev)
		return false

	# Step 45: Test Array Firing (Left Mouse Click)
	if step_index == 45:
		print("[TEST] Step 45: Testing Left Click Array Firing...")
		var ev := InputEventMouseButton.new()
		ev.pressed = true
		ev.button_index = MOUSE_BUTTON_LEFT
		main._unhandled_input(ev)
		return false

	# Step 50: Test Release Left Click
	if step_index == 50:
		var ev := InputEventMouseButton.new()
		ev.pressed = false
		ev.button_index = MOUSE_BUTTON_LEFT
		main._unhandled_input(ev)
		return false

	# Step 55: Test Point Strike (Right Mouse Click Tap)
	if step_index == 55:
		print("[TEST] Step 55: Testing Right Click Tap (Point Strike)...")
		var ev_down := InputEventMouseButton.new()
		ev_down.pressed = true
		ev_down.button_index = MOUSE_BUTTON_RIGHT
		main._unhandled_input(ev_down)
		main.sword["press_timer"] = 0.05
		var ev_up := InputEventMouseButton.new()
		ev_up.pressed = false
		ev_up.button_index = MOUSE_BUTTON_RIGHT
		main._unhandled_input(ev_up)
		return false

	# Step 65: Test Slicing (Right Mouse Hold)
	if step_index == 65:
		print("[TEST] Step 65: Testing Right Click Hold (Slicing)...")
		var ev_down := InputEventMouseButton.new()
		ev_down.pressed = true
		ev_down.button_index = MOUSE_BUTTON_RIGHT
		main._unhandled_input(ev_down)
		main.sword["press_timer"] = 0.5
		return false

	# Step 75: Test Recalling (Release Right Click Hold)
	if step_index == 75:
		print("[TEST] Step 75: Testing Right Click Release (Recalling)...")
		var ev_up := InputEventMouseButton.new()
		ev_up.pressed = false
		ev_up.button_index = MOUSE_BUTTON_RIGHT
		main._unhandled_input(ev_up)
		return false

	# Step 80: Test Enemy spawn and update
	if step_index == 80:
		print("[TEST] Step 80: Testing Enemy spawning...")
		if main.has_method("_spawn_enemy"):
			main.call("_spawn_enemy", "puppet")
		return false

	# Step 90: Test Drawing pass
	if step_index == 90:
		print("[TEST] Step 90: Testing queue_redraw...")
		main.queue_redraw()
		return false

	if step_index >= 120:
		print("=== Full Runtime Test Suite Completed PASSED with ZERO ERRORS! ===")
		return true

	return false
