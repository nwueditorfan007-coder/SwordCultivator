extends SceneTree

const SKELETON_VISUAL := preload("res://scripts/prototypes/humanoid_8way_skeleton_visual.gd")

const OUT_DIR := "res://resources/flight/yujian_hover_idle_right_v1"
const FRAMES_DIR := OUT_DIR + "/frames"
const SHEET_PATH := OUT_DIR + "/01_right_hover_idle_8f_512.png"
const PREVIEW_PATH := OUT_DIR + "/01_right_hover_idle_8f_preview.png"
const METADATA_PATH := OUT_DIR + "/01_right_hover_idle_8f_512.json"

const CELL_SIZE := 512
const PREVIEW_CELL_SIZE := 256
const FRAME_COUNT := 8
const RIGHT_DIRECTION_INDEX := 0
const LOOP_SECONDS := TAU / 2.20

var _viewport: SubViewport
var _visual: Node2D


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES_DIR))
	get_root().size = Vector2i(CELL_SIZE, CELL_SIZE)

	_viewport = SubViewport.new()
	_viewport.name = "RightHoverIdleExportViewport"
	_viewport.size = Vector2i(CELL_SIZE, CELL_SIZE)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_viewport)

	var holder := Node2D.new()
	holder.name = "SpriteExportRoot"
	_viewport.add_child(holder)

	_visual = SKELETON_VISUAL.new()
	_visual.name = "RightHoverIdleSkeleton"
	_visual.position = Vector2(256.0, 252.0)
	_visual.scale = Vector2.ONE * 1.54
	_visual.set("visual_style", 0)
	_visual.set("hair_fx_enabled", true)
	_visual.set("idle_pose_fx_enabled", true)
	_visual.set("idle_pose_breath_strength", 0.90)
	_visual.set("idle_pose_control_strength", 0.78)
	_visual.set("idle_pose_tension_strength", 0.58)
	holder.add_child(_visual)

	for i in range(10):
		_set_right_hover_pose(1.0 / 60.0)
		await process_frame

	var sheet := Image.create(CELL_SIZE * FRAME_COUNT, CELL_SIZE, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	var preview := _create_checker_preview()

	for frame_index in range(FRAME_COUNT):
		var phase := LOOP_SECONDS * float(frame_index) / float(FRAME_COUNT)
		_visual.set("_time", phase)
		_set_right_hover_pose(0.0)
		await process_frame
		await process_frame

		var frame := _viewport.get_texture().get_image()
		if frame == null:
			push_error("Failed to read viewport image for frame %d." % frame_index)
			quit(1)
			return
		frame.convert(Image.FORMAT_RGBA8)
		var frame_path := "%s/01_right_hover_idle_%02d.png" % [FRAMES_DIR, frame_index]
		var frame_result := frame.save_png(frame_path)
		if frame_result != OK:
			push_error("Failed to save frame: %s error=%d" % [frame_path, frame_result])
			quit(1)
			return
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, Vector2i(CELL_SIZE, CELL_SIZE)), Vector2i(frame_index * CELL_SIZE, 0))

		var preview_frame := frame.duplicate()
		preview_frame.resize(PREVIEW_CELL_SIZE, PREVIEW_CELL_SIZE, Image.INTERPOLATE_NEAREST)
		var preview_pos := Vector2i((frame_index % 4) * PREVIEW_CELL_SIZE, int(frame_index / 4) * PREVIEW_CELL_SIZE)
		preview.blend_rect(preview_frame, Rect2i(Vector2i.ZERO, Vector2i(PREVIEW_CELL_SIZE, PREVIEW_CELL_SIZE)), preview_pos)

	var sheet_result := sheet.save_png(SHEET_PATH)
	if sheet_result != OK:
		push_error("Failed to save sheet: %s error=%d" % [SHEET_PATH, sheet_result])
		quit(1)
		return
	var preview_result := preview.save_png(PREVIEW_PATH)
	if preview_result != OK:
		push_error("Failed to save preview: %s error=%d" % [PREVIEW_PATH, preview_result])
		quit(1)
		return
	_save_metadata()
	print("right_hover_idle_frames=%d" % FRAME_COUNT)
	print("right_hover_idle_sheet=%s" % SHEET_PATH)
	print("right_hover_idle_preview=%s" % PREVIEW_PATH)
	quit()


func _set_right_hover_pose(delta: float) -> void:
	_visual.call(
			"set_flight_pose",
			RIGHT_DIRECTION_INDEX,
			Vector2.RIGHT,
			Vector2.ZERO,
			0.0,
			0.0,
			0.0,
			0.0,
			delta
	)


func _create_checker_preview() -> Image:
	var size := Vector2i(PREVIEW_CELL_SIZE * 4, PREVIEW_CELL_SIZE * 2)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.18, 0.18, 0.18, 1.0))
	var tile := 16
	for y in range(0, size.y, tile):
		for x in range(0, size.x, tile):
			var odd := (int(x / tile) + int(y / tile)) % 2 == 1
			var color := Color(0.26, 0.26, 0.26, 1.0) if odd else Color(0.15, 0.15, 0.15, 1.0)
			image.fill_rect(Rect2i(Vector2i(x, y), Vector2i(tile, tile)), color)
	var border := Color(0.76, 0.83, 0.80, 1.0)
	for i in range(FRAME_COUNT):
		var pos := Vector2i((i % 4) * PREVIEW_CELL_SIZE, int(i / 4) * PREVIEW_CELL_SIZE)
		image.fill_rect(Rect2i(pos, Vector2i(PREVIEW_CELL_SIZE, 1)), border)
		image.fill_rect(Rect2i(pos + Vector2i(0, PREVIEW_CELL_SIZE - 1), Vector2i(PREVIEW_CELL_SIZE, 1)), border)
		image.fill_rect(Rect2i(pos, Vector2i(1, PREVIEW_CELL_SIZE)), border)
		image.fill_rect(Rect2i(pos + Vector2i(PREVIEW_CELL_SIZE - 1, 0), Vector2i(1, PREVIEW_CELL_SIZE)), border)
	return image


func _save_metadata() -> void:
	var metadata := {
		"asset": "01_right_hover_idle",
		"direction": "01_right",
		"direction_index": RIGHT_DIRECTION_INDEX,
		"frame_count": FRAME_COUNT,
		"cell_size": CELL_SIZE,
		"sheet": SHEET_PATH,
		"frames_dir": FRAMES_DIR,
		"preview": PREVIEW_PATH,
		"source": "HumanoidEightWaySkeletonVisual V4 runtime idle pose export",
		"notes": "Prototype right-facing hover idle. Transparent 512x512 frames; sword axis and body heading face screen right."
	}
	var file := FileAccess.open(METADATA_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write metadata: %s" % METADATA_PATH)
		return
	file.store_string(JSON.stringify(metadata, "\t"))
	file.close()
