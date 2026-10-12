extends SceneTree

func _init() -> void:
	print("Checking game_renderer.gd compilation...")
	var script := load("res://scripts/system/game_renderer.gd") as GDScript
	if script == null:
		print("FAILED to load game_renderer.gd")
		quit(1)
		return
	print("game_renderer.gd loaded successfully!")
	quit(0)
