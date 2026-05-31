extends SceneTree

const GOOGLE_PARTS_VISUAL := preload("res://scripts/prototypes/google_parts_skeleton_visual.gd")
const DEFAULT_PART_ROOT := "res://resources/flight/rider/google_parts_v1"
const DEFAULT_OUTPUT_PATH := "res://artifacts/google_parts_skeleton_preview.png"
const PREVIEW_SIZE := Vector2i(1400, 920)

const PREVIEW_POSES := [
	{"name": "right / body front / head right", "index": 0, "heading": Vector2.RIGHT},
	{"name": "up / body side right / head back", "index": 2, "heading": Vector2.UP},
	{"name": "left / body back / head left", "index": 4, "heading": Vector2.LEFT},
	{"name": "down / body side left / head front", "index": 6, "heading": Vector2.DOWN},
]


func _initialize() -> void:
	var part_root := OS.get_environment("GOOGLE_PARTS_ROOT")
	if part_root == "":
		part_root = DEFAULT_PART_ROOT
	var output_path := OS.get_environment("GOOGLE_PARTS_PREVIEW_OUTPUT")
	if output_path == "":
		output_path = DEFAULT_OUTPUT_PATH

	get_root().size = PREVIEW_SIZE
	var viewport := SubViewport.new()
	viewport.size = PREVIEW_SIZE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)

	var background := ColorRect.new()
	background.color = Color(0.045, 0.050, 0.055, 1.0)
	background.size = Vector2(PREVIEW_SIZE)
	viewport.add_child(background)

	var positions := [
		Vector2(190.0, 250.0),
		Vector2(520.0, 250.0),
		Vector2(850.0, 250.0),
		Vector2(1180.0, 250.0),
	]
	for row in range(2):
		var is_fast := row == 1
		for i in range(PREVIEW_POSES.size()):
			var pose: Dictionary = PREVIEW_POSES[i]
			var heading: Vector2 = pose["heading"]
			var visual := GOOGLE_PARTS_VISUAL.new()
			visual.set_part_set_root(part_root)
			visual.set_show_sword(false)
			visual.position = positions[i] + Vector2(0.0, row * 430.0)
			visual.scale = Vector2.ONE * 2.45
			viewport.add_child(visual)
			var velocity := heading * (1650.0 if is_fast else 60.0)
			visual.set_flight_pose(int(pose["index"]), heading, velocity, 0.42 if is_fast else 0.0, 0.0, 0.0, 0.85 if is_fast else 0.0, 0.016)

			var label := Label.new()
			label.text = "%s / %s" % ["fast" if is_fast else "low", String(pose["name"])]
			label.position = visual.position + Vector2(-118.0, 190.0)
			label.add_theme_font_size_override("font_size", 16)
			viewport.add_child(label)

	for i in range(18):
		await process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var image: Image = viewport.get_texture().get_image()
	if image == null:
		push_error("Failed to read Google parts preview viewport.")
		quit(1)
		return
	var save_result := image.save_png(output_path)
	if save_result != OK:
		push_error("Failed to save capture: %s error=%d" % [output_path, save_result])
		quit(1)
		return
	print("capture=%s" % output_path)
	quit()
