extends MainLoop

var main: Node2D
var frame := 0

func _process(delta: float) -> bool:
	frame += 1
	if frame == 1:
		print("=== Smoke Test Starting ===")
		var packed := load("res://scenes/main/Main.tscn") as PackedScene
		main = packed.instantiate() as Node2D
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null:
			tree.root.add_child(main)
		print("Scene instantiated successfully.")

	if frame >= 30:
		print("=== Smoke Test Completed Successfully! ===")
		return true

	return false
