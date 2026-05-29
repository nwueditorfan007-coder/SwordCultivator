extends SceneTree

const VISUAL_SCRIPT := preload("res://scripts/prototypes/humanoid_8way_skeleton_visual.gd")
const OUTPUT_PATH := "res://artifacts/v4_plus_right_fast_capture.png"


func _initialize() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var visual := VISUAL_SCRIPT.new()
	visual.position = Vector2(520.0, 360.0)
	visual.scale = Vector2.ONE * 0.95
	root.add_child(visual)
	visual.set_flight_pose(0, Vector2.RIGHT, Vector2(2200.0, 0.0), 1.0, 0.0, 0.0, 1.0, 1.0 / 60.0)

	for i in range(8):
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
