extends SceneTree

const MODEL_VISUAL_SCRIPT := preload("res://scripts/prototypes/yujian_model_to_2d_flight_visual.gd")
const OUTPUT_PATH := "res://artifacts/yujian_model_pose_runtime_manual_offset.png"


func _initialize() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	var visual := MODEL_VISUAL_SCRIPT.new()
	visual.position = Vector2(520.0, 420.0)
	visual.set("sprite_texture_scale", 0.84)
	visual.set("camera_size", 5.8)
	root.add_child(visual)
	for i in range(8):
		await process_frame
	if visual.has_method("set_neutral_preview_enabled"):
		visual.call("set_neutral_preview_enabled", false)
	if visual.has_method("set_manual_pose_enabled"):
		visual.call("set_manual_pose_enabled", true)
	if visual.has_method("set_manual_bone_pose_degrees"):
		visual.call("set_manual_bone_pose_degrees", {
			"Bip001 L Forearm": [0.0, 0.0, -24.0],
			"Bip001 R Forearm": [0.0, 0.0, 24.0],
		})
	if visual.has_method("set_flight_context"):
		visual.call("set_flight_context", 0.0, 0.0, 0.0, 0.0)
	if visual.has_method("set_flight_pose"):
		visual.call("set_flight_pose", 0, Vector2.RIGHT, Vector2(2200.0, 0.0), 1.0, 0.0, 0.0, 1.0, 1.0 / 60.0)
	for i in range(10):
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var image: Image = get_root().get_texture().get_image()
	if image == null:
		push_error("Failed to read viewport image.")
		quit(1)
		return
	var save_result := image.save_png(OUTPUT_PATH)
	if save_result != OK:
		push_error("Failed to save capture: %s error=%d" % [OUTPUT_PATH, save_result])
		quit(1)
		return
	print("capture=%s" % OUTPUT_PATH)
	if visual.has_method("get_debug_snapshot"):
		print(JSON.stringify(visual.call("get_debug_snapshot"), "\t"))
	quit()
