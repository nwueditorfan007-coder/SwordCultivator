extends SceneTree

const MODEL_VISUAL_SCRIPT := preload("res://scripts/prototypes/yujian_model_to_2d_flight_visual.gd")
const OUTPUT_PATH := "res://artifacts/yujian_model_pose_editor_manual_offset.png"


func _initialize() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	var visual := MODEL_VISUAL_SCRIPT.new()
	visual.position = Vector2(480.0, 420.0)
	visual.set("sprite_texture_scale", 0.84)
	visual.set("camera_size", 5.8)
	root.add_child(visual)
	await process_frame
	if visual.has_method("set_neutral_preview_enabled"):
		visual.call("set_neutral_preview_enabled", true)
	if visual.has_method("set_neutral_preview_t_pose_enabled"):
		visual.call("set_neutral_preview_t_pose_enabled", true)
	if visual.has_method("set_manual_pose_enabled"):
		visual.call("set_manual_pose_enabled", true)
	if visual.has_method("set_manual_bone_pose_degrees"):
		visual.call("set_manual_bone_pose_degrees", {
			"Bip001 L Forearm": [0.0, 0.0, -32.0],
			"Bip001 R Forearm": [0.0, 0.0, 32.0],
		})
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
	quit()
