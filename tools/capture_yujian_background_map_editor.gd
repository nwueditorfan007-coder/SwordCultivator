extends SceneTree

const SCENE_PATH := "res://scenes/tools/YujianBackgroundMapEditor.tscn"
const OUTPUT_PATH := "res://artifacts/yujian_background_map_editor.png"


func _initialize() -> void:
	get_root().size = Vector2i(1680, 820)
	var scene := load(SCENE_PATH)
	if scene == null:
		push_error("Failed to load scene: %s" % SCENE_PATH)
		quit(1)
		return
	var root := (scene as PackedScene).instantiate()
	get_root().add_child(root)
	for i in range(10):
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var image := get_root().get_texture().get_image()
	if image == null:
		push_error("Failed to read viewport image.")
		quit(1)
		return
	var result := image.save_png(OUTPUT_PATH)
	if result != OK:
		push_error("Failed to save capture: %s error=%d" % [OUTPUT_PATH, result])
		quit(1)
		return
	print("capture=%s" % OUTPUT_PATH)
	quit()
