extends SceneTree

const SCENE_PATH := "res://scenes/prototypes/YujianModelPoseEditorPrototype.tscn"
const OUTPUT_PATH := "res://artifacts/yujian_model_pose_editor_view_test.png"


func _initialize() -> void:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		push_error("Failed to load scene: %s" % SCENE_PATH)
		quit(1)
		return
	var root := scene.instantiate()
	get_root().add_child(root)
	for i in range(10):
		await process_frame
	if not root.has_method("_apply_view_preset"):
		push_error("Pose editor view preset API is unavailable.")
		quit(1)
		return
	root.call("_apply_view_preset", 1)
	for i in range(10):
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var image: Image = get_root().get_texture().get_image()
	if image == null:
		push_error("Failed to read editor viewport image.")
		quit(1)
		return
	var save_result := image.save_png(OUTPUT_PATH)
	if save_result != OK:
		push_error("Failed to save capture: %s error=%d" % [OUTPUT_PATH, save_result])
		quit(1)
		return
	print("capture=%s" % OUTPUT_PATH)
	quit()
