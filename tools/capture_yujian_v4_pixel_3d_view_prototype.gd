extends SceneTree

const SCENE_PATH := "res://scenes/prototypes/YujianV4Pixel3DViewPrototype.tscn"
const OUTPUT_PATH := "res://artifacts/yujian_v4_pixel_3d_view_capture.png"
const SUBVIEWPORT_PATH := "res://artifacts/yujian_v4_pixel_3d_view_subviewport.png"
const STATE_CAPTURE_DIR := "res://artifacts/yujian_v4_pixel_3d_view_states"
const MIN_SAMPLE_VARIANCE := 0.0008


func _initialize() -> void:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		push_error("Failed to load scene: %s" % SCENE_PATH)
		quit(1)
		return

	var root := scene.instantiate()
	root.auto_demo = true
	root.show_legacy_2d_speed_overlays = true
	get_root().add_child(root)
	await process_frame
	for i in range(90):
		await process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var subviewport: SubViewport = root.pixel_world_viewport
	if subviewport == null:
		push_error("Prototype did not create pixel_world_viewport.")
		quit(1)
		return
	var sub_image := subviewport.get_texture().get_image()
	if sub_image == null:
		push_error("Failed to read pixel 3D subviewport image.")
		quit(1)
		return
	var variance := _sample_luma_variance(sub_image)
	var sub_save := sub_image.save_png(SUBVIEWPORT_PATH)
	if sub_save != OK:
		push_error("Failed to save subviewport capture: %s error=%d" % [SUBVIEWPORT_PATH, sub_save])
		quit(1)
		return
	print("subviewport_capture=%s variance=%.5f" % [SUBVIEWPORT_PATH, variance])
	if variance < MIN_SAMPLE_VARIANCE:
		push_error("Pixel 3D subviewport looks too flat or blank. variance=%.5f expected>=%.5f" % [variance, MIN_SAMPLE_VARIANCE])
		quit(1)
		return
	await _capture_fixed_direction_states(root)
	var root_texture := get_root().get_texture()
	if root_texture != null:
		var root_image := root_texture.get_image()
		if root_image != null:
			var root_save := root_image.save_png(OUTPUT_PATH)
			if root_save == OK:
				print("capture=%s" % OUTPUT_PATH)
	quit()


func _capture_fixed_direction_states(root: Node) -> void:
	root.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STATE_CAPTURE_DIR))
	var states := [
		{"name": "01_right", "dir": Vector2.RIGHT},
		{"name": "02_up_right", "dir": Vector2(1.0, -1.0).normalized()},
		{"name": "03_up", "dir": Vector2.UP},
		{"name": "04_up_left", "dir": Vector2(-1.0, -1.0).normalized()},
		{"name": "05_left", "dir": Vector2.LEFT},
		{"name": "06_down_left", "dir": Vector2(-1.0, 1.0).normalized()},
		{"name": "07_down", "dir": Vector2.DOWN},
		{"name": "08_down_right", "dir": Vector2(1.0, 1.0).normalized()},
	]
	for state in states:
		var dir: Vector2 = state["dir"]
		root.flight_pos = root.FLIGHT_START_POS
		root.visual_pos = root.flight_pos
		root.camera_center = root.flight_pos
		root.camera_look_ahead = Vector2.ZERO
		root.velocity = dir * root.BOOST_SPEED * 0.78
		root.target_heading = dir
		root.body_heading = dir
		root.visual_heading = dir
		root.heading_angle_delta = 0.0
		root.throttle_pressed = true
		root.boost_energy = 0.72
		root.turn_energy = 0.0
		root.carve_energy = 0.0
		root.throttle_energy = 1.0
		root.call("_update_camera", 0.0)
		root.call("_update_pixel_3d_world", 0.0)
		await process_frame
		await process_frame
		var subviewport: SubViewport = root.pixel_world_viewport
		if subviewport == null:
			continue
		var image := subviewport.get_texture().get_image()
		if image == null:
			continue
		var path := "%s/%s.png" % [STATE_CAPTURE_DIR, String(state["name"])]
		var save_result := image.save_png(path)
		if save_result != OK:
			push_error("Failed to save direction capture: %s error=%d" % [path, save_result])
			return
		print("direction_capture=%s" % path)


func _sample_luma_variance(image: Image) -> float:
	var sum := 0.0
	var sum_sq := 0.0
	var count := 0
	var step_x := maxi(1, image.get_width() / 48)
	var step_y := maxi(1, image.get_height() / 32)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			var color := image.get_pixel(x, y)
			var luma := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			sum += luma
			sum_sq += luma * luma
			count += 1
	if count <= 0:
		return 0.0
	var mean := sum / float(count)
	return maxf(sum_sq / float(count) - mean * mean, 0.0)
