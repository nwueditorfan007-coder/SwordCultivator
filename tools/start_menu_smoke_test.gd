extends SceneTree


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/main/Main.tscn")
	if packed_scene == null:
		_fail("Failed to load main scene.")
		return
	var main: Node = packed_scene.instantiate()
	if main == null:
		_fail("Failed to instantiate main scene.")
		return
	get_root().add_child(main)
	await process_frame

	if not bool(main.get("is_start_menu_active")):
		_fail("Start menu was not active after scene startup.")
		return
	var start_menu: Variant = main.get("start_menu")
	if not (start_menu is Control) or not bool(start_menu.visible):
		_fail("Start menu node was missing or hidden after scene startup.")
		return
	var legacy_button: Variant = main.get("legacy_start_button")
	if not (legacy_button is Button) or not bool(legacy_button.visible):
		_fail("Legacy waves entry was missing or hidden.")
		return

	main.queue_free()
	await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
