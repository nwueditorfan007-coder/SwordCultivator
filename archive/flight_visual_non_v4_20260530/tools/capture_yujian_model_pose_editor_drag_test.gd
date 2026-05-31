extends SceneTree

const SCENE_PATH := "res://scenes/prototypes/YujianModelPoseEditorPrototype.tscn"
const OUTPUT_PATH := "res://artifacts/yujian_model_pose_editor_drag_test.png"


func _initialize() -> void:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		push_error("Failed to load scene: %s" % SCENE_PATH)
		quit(1)
		return
	var root := scene.instantiate()
	get_root().add_child(root)
	for i in range(12):
		await process_frame
	if not root.has_method("_editor_joint_points") or not root.has_method("_solve_drag_handle"):
		push_error("Pose editor drag API is unavailable.")
		quit(1)
		return
	var initial_points: Dictionary = root.call("_editor_joint_points")
	if not initial_points.has("left_wrist"):
		push_error("left_wrist joint was not projected.")
		quit(1)
		return
	var start_position := _joint_position(initial_points["left_wrist"])
	var target_position := start_position + Vector2(-96.0, -58.0)
	root.call("_solve_drag_handle", "left_wrist", target_position)
	for i in range(8):
		await process_frame
	var dragged_points: Dictionary = root.call("_editor_joint_points")
	if not dragged_points.has("left_wrist"):
		push_error("left_wrist joint disappeared after drag solve.")
		quit(1)
		return
	var end_position := _joint_position(dragged_points["left_wrist"])
	var start_distance := start_position.distance_to(target_position)
	var end_distance := end_position.distance_to(target_position)
	var current_bones: Dictionary = root.call("_current_pose_bones")
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
	print("drag_start_distance=%.2f" % start_distance)
	print("drag_end_distance=%.2f" % end_distance)
	print("drag_bone_offsets=%d" % current_bones.size())
	print("capture=%s" % OUTPUT_PATH)
	quit()


func _joint_position(value: Variant) -> Vector2:
	if value is Dictionary:
		var dict_value: Dictionary = value
		var position: Variant = dict_value.get("position", Vector2.ZERO)
		if position is Vector2:
			return position
	return Vector2.ZERO
