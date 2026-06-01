extends SceneTree

const SCENE_PATH := "res://scenes/prototypes/YujianSpriteSequencePrototype.tscn"
const STATIC_OUTPUT_PATH := "res://artifacts/yujian_sprite_sequence_first_level_static.png"
const Y_UP_OUTPUT_PATH := "res://artifacts/yujian_sprite_sequence_first_level_y_up.png"
const Y_HIGH_OUTPUT_PATH := "res://artifacts/yujian_sprite_sequence_first_level_y_high.png"
const BOOST_OUTPUT_PATH := "res://artifacts/yujian_sprite_sequence_first_level_boost.png"


func _initialize() -> void:
	get_root().size = Vector2i(1280, 720)
	var scene := load(SCENE_PATH)
	if scene == null:
		push_error("Failed to load scene: %s" % SCENE_PATH)
		quit(1)
		return
	var root := (scene as PackedScene).instantiate()
	root.set("显示调试文本", false)
	get_root().add_child(root)

	for i in range(8):
		await process_frame
	var start_pos: Vector2 = root.get("flight_pos")
	if not _save_root_capture(STATIC_OUTPUT_PATH):
		quit(1)
		return

	var y_up_pos := start_pos + Vector2(0.0, -4200.0)
	root.set("flight_pos", y_up_pos)
	root.set("visual_pos", y_up_pos)
	root.set("camera_center", y_up_pos)
	root.set("camera_look_ahead", Vector2.ZERO)
	root.set("velocity", Vector2.ZERO)
	root.set("throttle_energy", 0.0)
	root.set("boost_energy", 0.0)
	root.set("visual_heading", Vector2.UP)
	_clear_runtime_traces(root)
	root.queue_redraw()
	for i in range(8):
		await process_frame
	if not _save_root_capture(Y_UP_OUTPUT_PATH):
		quit(1)
		return

	var y_high_pos := start_pos + Vector2(0.0, -8400.0)
	root.set("flight_pos", y_high_pos)
	root.set("visual_pos", y_high_pos)
	root.set("camera_center", y_high_pos)
	root.set("camera_look_ahead", Vector2.ZERO)
	root.set("velocity", Vector2.ZERO)
	root.set("throttle_energy", 0.0)
	root.set("boost_energy", 0.0)
	root.set("visual_heading", Vector2.UP)
	_clear_runtime_traces(root)
	root.queue_redraw()
	for i in range(8):
		await process_frame
	if not _save_root_capture(Y_HIGH_OUTPUT_PATH):
		quit(1)
		return

	root.set("flight_pos", start_pos)
	root.set("visual_pos", start_pos)
	root.set("camera_center", start_pos)
	root.set("camera_look_ahead", Vector2.ZERO)
	_clear_runtime_traces(root)
	root.set("velocity", Vector2(2100.0, 0.0))
	root.set("throttle_energy", 1.0)
	root.set("boost_energy", 1.0)
	root.set("visual_heading", Vector2.RIGHT)
	root.queue_redraw()
	for i in range(8):
		await process_frame
	if not _save_root_capture(BOOST_OUTPUT_PATH):
		quit(1)
		return

	quit()


func _clear_runtime_traces(root: Node) -> void:
	root.set("trail_points", [])
	root.set("afterimages", [])
	root.set("scene_speed_streaks", [])
	root.set("boost_shockwaves", [])


func _save_root_capture(path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var image: Image = get_root().get_texture().get_image()
	if image == null:
		push_error("Failed to read viewport image.")
		return false
	var save_result := image.save_png(path)
	if save_result != OK:
		push_error("Failed to save capture: %s error=%d" % [path, save_result])
		return false
	print("capture=%s" % path)
	return true
