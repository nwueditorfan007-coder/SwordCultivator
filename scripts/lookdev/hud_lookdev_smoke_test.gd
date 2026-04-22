extends SceneTree


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/lookdev/HudLookdev.tscn")
	if packed_scene == null:
		push_error("Failed to load HUD lookdev scene.")
		quit(1)
		return

	var instance: Node = packed_scene.instantiate()
	if instance == null:
		push_error("Failed to instantiate HUD lookdev scene.")
		quit(1)
		return

	get_root().add_child(instance)
	quit()
