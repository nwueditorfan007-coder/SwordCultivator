extends SceneTree

const SCENE_PATH := "res://scenes/prototypes/YujianSpriteSequence3DModelPrototype.tscn"
const OUTPUT_PATH := "res://artifacts/yujian_3d_model_prototype_capture.png"
const STATE_CAPTURE_DIR := "res://artifacts/yujian_3d_model_states"
const MIN_SUBVIEWPORT_ALPHA_MARGIN := 48
const ALPHA_BBOX_THRESHOLD := 0.03


func _initialize() -> void:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		push_error("Failed to load scene: %s" % SCENE_PATH)
		quit(1)
		return
	var root := scene.instantiate()
	root.auto_demo = true
	root.eight_way_character_set = root.EIGHT_WAY_SET_V4_SKELETON
	root.skeleton_size_scale = 0.3
	root.model_visual_root_scale = 0.82
	root.model_visual_texture_scale = 0.74
	root.model_visual_camera_size = 6.2
	root.model_visual_model_scale = 1.0
	get_root().add_child(root)
	await process_frame
	for i in range(90):
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var image := get_root().get_texture().get_image()
	if image == null:
		push_error("Failed to read root viewport image.")
		quit(1)
		return
	var save_result := image.save_png(OUTPUT_PATH)
	if save_result != OK:
		push_error("Failed to save capture: %s error=%d" % [OUTPUT_PATH, save_result])
		quit(1)
		return
	print("capture=%s" % OUTPUT_PATH)
	if root.model_flight_visual != null:
		print("model_visual=%s" % root.model_flight_visual.get_path())
		var subviewport: SubViewport = root.model_flight_visual.subviewport
		if subviewport != null:
			var sub_result := _save_subviewport(subviewport, "res://artifacts/yujian_3d_model_subviewport.png")
			if sub_result != OK:
				quit(1)
				return
			await _capture_fixed_pose_states(root)
		if root.model_flight_visual.has_method("get_debug_snapshot"):
			print(JSON.stringify(root.model_flight_visual.call("get_debug_snapshot")))
	quit()


func _capture_fixed_pose_states(root: Node) -> void:
	if root.model_flight_visual == null:
		return
	root.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STATE_CAPTURE_DIR))
	var visual: Node = root.model_flight_visual
	var states := [
		{
			"name": "01_cruise_right",
			"heading": Vector2.RIGHT,
			"velocity": Vector2(760.0, 0.0),
			"boost": 0.0,
			"turn": 0.0,
			"carve": 0.0,
			"throttle": 0.15,
			"turn_lean": 0.0,
			"carve_dir": 0.0,
			"switch_dir": 0.0,
			"switch": 0.0,
		},
		{
			"name": "02_boost_right",
			"heading": Vector2.RIGHT,
			"velocity": Vector2(2080.0, 0.0),
			"boost": 1.0,
			"turn": 0.0,
			"carve": 0.0,
			"throttle": 1.0,
			"turn_lean": 0.0,
			"carve_dir": 0.0,
			"switch_dir": 0.0,
			"switch": 0.0,
		},
		{
			"name": "03_boost_up_right_carve",
			"heading": Vector2(0.72, -0.69).normalized(),
			"velocity": Vector2(1500.0, -1420.0),
			"boost": 0.82,
			"turn": 0.68,
			"carve": 0.74,
			"throttle": 1.0,
			"turn_lean": -0.72,
			"carve_dir": -1.0,
			"switch_dir": -1.0,
			"switch": 0.62,
		},
	]
	for state in states:
		if visual.has_method("set_flight_context"):
			visual.call(
				"set_flight_context",
				float(state["turn_lean"]),
				float(state["carve_dir"]),
				float(state["switch_dir"]),
				float(state["switch"])
			)
		if visual.has_method("set_flight_pose"):
			visual.call(
				"set_flight_pose",
				0,
				state["heading"],
				state["velocity"],
				float(state["boost"]),
				float(state["turn"]),
				float(state["carve"]),
				float(state["throttle"]),
				1.0 / 60.0
			)
		await process_frame
		await process_frame
		var subviewport: SubViewport = visual.get("subviewport")
		if subviewport == null:
			continue
		var path := "%s/%s.png" % [STATE_CAPTURE_DIR, String(state["name"])]
		var result := _save_subviewport(subviewport, path)
		if result != OK:
			return


func _save_subviewport(subviewport: SubViewport, path: String) -> int:
	var sub_image := subviewport.get_texture().get_image()
	if sub_image == null:
		push_error("Failed to read model subviewport image.")
		return FAILED
	var margin_info := _calculate_alpha_margin(sub_image)
	var save_result := sub_image.save_png(path)
	if save_result != OK:
		push_error("Failed to save subviewport capture: %s error=%d" % [path, save_result])
		return save_result
	if not bool(margin_info.get("valid", false)):
		push_error("No visible model pixels found in subviewport capture: %s" % path)
		return FAILED
	var min_margin := int(margin_info.get("min_margin", 0))
	print("subviewport_capture=%s alpha_margin=%s" % [path, JSON.stringify(margin_info)])
	if min_margin < MIN_SUBVIEWPORT_ALPHA_MARGIN:
		push_error(
			"Subviewport capture is too close to the edge: %s min_margin=%d expected>=%d"
			% [path, min_margin, MIN_SUBVIEWPORT_ALPHA_MARGIN]
		)
		return FAILED
	return OK


func _calculate_alpha_margin(image: Image) -> Dictionary:
	var width := image.get_width()
	var height := image.get_height()
	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1
	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a <= ALPHA_BBOX_THRESHOLD:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < 0 or max_y < 0:
		return {"valid": false}
	var left := min_x
	var top := min_y
	var right := width - 1 - max_x
	var bottom := height - 1 - max_y
	return {
		"valid": true,
		"bbox": [min_x, min_y, max_x, max_y],
		"margin": [left, top, right, bottom],
		"min_margin": mini(mini(left, top), mini(right, bottom)),
	}
