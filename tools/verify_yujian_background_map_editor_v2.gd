extends SceneTree

const SCENE_PATH := "res://scenes/tools/YujianBackgroundMapEditor.tscn"


func _initialize() -> void:
	get_root().size = Vector2i(1680, 820)
	var scene := load(SCENE_PATH)
	if scene == null:
		_fail("Failed to load scene: %s" % SCENE_PATH)
		return
	var editor := (scene as PackedScene).instantiate()
	get_root().add_child(editor)
	for i in range(10):
		await process_frame

	_assert(editor.scenic_islands.size() > 0, "profile should load scenic islands")
	_assert(editor.show_grid == false, "grid overlay should be off by default")
	_assert(editor.snap_enabled == false, "snap should be off by default")
	_assert(editor.show_numbers == false, "numbers should be off by default")
	_assert(editor.show_warnings == true, "warnings should be on by default")

	var zoom_cursor := Vector2(420.0, 300.0)
	var viewport_before: Vector2 = editor._canvas_to_viewport(zoom_cursor)
	editor._zoom_canvas_at(zoom_cursor, editor.canvas_zoom * 1.25)
	var viewport_after: Vector2 = editor._canvas_to_viewport(zoom_cursor)
	_assert(viewport_before.distance_to(viewport_after) < 0.01, "wheel zoom should keep cursor anchored")

	var flight_before: Vector2 = editor.flight_pos
	editor._pan_preview_by_canvas_delta(Vector2(120.0, -80.0))
	_assert(editor.flight_pos.x < flight_before.x, "right drag to the right should move preview anchor left")
	_assert(editor.flight_pos.y > flight_before.y, "right drag upward should move preview anchor downward")

	editor.active_index = 0
	editor.selected_indices = [0]
	var island_before: Dictionary = editor._island_at(0).duplicate(true)
	editor._push_undo("test move")
	editor._drag_selected_islands(Vector2(40.0, 30.0))
	var island_moved: Dictionary = editor._island_at(0)
	_assert(not is_equal_approx(float(island_moved.get("x", 0.0)), float(island_before.get("x", 0.0))), "drag should change island x")
	_assert(not is_equal_approx(float(island_moved.get("y", 0.0)), float(island_before.get("y", 0.0))), "drag should change island y")
	editor._undo()
	var island_undo: Dictionary = editor._island_at(0)
	_assert(is_equal_approx(float(island_undo.get("x", 0.0)), float(island_before.get("x", 0.0))), "undo should restore island x")
	_assert(is_equal_approx(float(island_undo.get("y", 0.0)), float(island_before.get("y", 0.0))), "undo should restore island y")
	editor._redo()
	var island_redo: Dictionary = editor._island_at(0)
	_assert(is_equal_approx(float(island_redo.get("x", 0.0)), float(island_moved.get("x", 0.0))), "redo should restore moved island x")
	_assert(is_equal_approx(float(island_redo.get("y", 0.0)), float(island_moved.get("y", 0.0))), "redo should restore moved island y")
	editor._undo()

	var center: Vector2 = editor._viewport_to_canvas(editor._project_island_center(editor._island_at(0)))
	editor.selected_indices = []
	editor.active_index = -1
	editor.marquee_start_canvas_pos = center - Vector2(80.0, 80.0)
	editor.marquee_current_canvas_pos = center + Vector2(80.0, 80.0)
	editor._select_by_marquee(false)
	_assert(editor.selected_indices.has(0), "marquee should select island under rectangle")

	editor._toggle_selection(1)
	_assert(editor.selected_indices.has(0) and editor.selected_indices.has(1), "shift-style toggle should allow multi-select")

	var count_before: int = editor.scenic_islands.size()
	editor._on_duplicate_pressed()
	_assert(editor.scenic_islands.size() == count_before + 2, "duplicate should copy selected islands")
	editor._undo()
	_assert(editor.scenic_islands.size() == count_before, "undo duplicate should restore island count")

	editor.selected_indices = [0, 1]
	editor.active_index = 0
	editor._on_delete_pressed()
	_assert(editor.scenic_islands.size() == count_before - 2, "delete should remove selected islands")
	editor._undo()
	_assert(editor.scenic_islands.size() == count_before, "undo delete should restore island count")

	print("Yujian background map editor V2 verification passed.")
	quit()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
