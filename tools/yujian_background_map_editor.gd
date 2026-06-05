extends Control

const RENDERER_SCRIPT := preload("res://scripts/background/yujian_level_background_renderer.gd")
const PROFILE_PATH := "res://resources/flight/background/level_01_immortal_sea_background.json"

const VIEW_SIZE := Vector2(1280.0, 720.0)
const BASE_PLAY_ORIGIN := Vector2(92.0, 86.0)
const BASE_PLAY_SIZE := Vector2(1096.0, 548.0)
const BATTLEFIELD_SIZE_MULTIPLIER := 8.0
const FLIGHT_TEST_HORIZONTAL_SCALE := 10.0 * BATTLEFIELD_SIZE_MULTIPLIER
const FLIGHT_TEST_VERTICAL_SCALE := 6.0 * BATTLEFIELD_SIZE_MULTIPLIER
const PLAY_SIZE := Vector2(BASE_PLAY_SIZE.x * FLIGHT_TEST_HORIZONTAL_SCALE, BASE_PLAY_SIZE.y * FLIGHT_TEST_VERTICAL_SCALE)
const PLAY_RECT := Rect2(BASE_PLAY_ORIGIN, PLAY_SIZE)
const FLIGHT_START_POS := BASE_PLAY_ORIGIN + Vector2(PLAY_SIZE.x * 0.16, PLAY_SIZE.y * 0.52)
const CAMERA_MIN_ZOOM := 1.12

const PREVIEW_MIN_SIZE := Vector2(760.0, 480.0)
const SIDE_PANEL_MIN_WIDTH := 500.0
const CANVAS_MIN_ZOOM := 0.25
const CANVAS_MAX_ZOOM := 4.0
const CANVAS_ZOOM_STEP := 1.10
const PAN_REFERENCE_X_PARALLAX := 0.35
const SNAP_GRID_WORLD := 100.0
const MAX_UNDO_STEPS := 80
const HIT_RADIUS := 96.0

const LAYER_VALUES := ["far", "mid", "near"]
const LAYER_LABELS := ["远景 far", "中景 mid", "近景 near"]
const BAND_VALUES := ["horizon", "mid_sea", "near_sea"]
const BAND_LABELS := ["海平线带 horizon", "中景海面 mid_sea", "近景海面 near_sea"]
const FLOAT_KEYS := ["x", "y", "depth", "width", "length", "height"]
const INT_KEYS := ["kind", "landmark"]


class PreviewCanvas:
	extends Control

	var editor: Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_ALL

	func _draw() -> void:
		if editor != null:
			editor._draw_canvas(self)

	func _gui_input(event: InputEvent) -> void:
		if editor != null:
			editor._on_canvas_gui_input(event)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED and editor != null:
			editor._on_canvas_resized()


var profile: Dictionary = {}
var scenic_islands: Array = []
var active_index := -1
var selected_indices: Array = []

var flight_pos := FLIGHT_START_POS
var camera_center := FLIGHT_START_POS
var elapsed_time := 0.0
var canvas_zoom := 1.0
var canvas_pan := Vector2.ZERO
var canvas_auto_fit := true

var show_grid := false
var snap_enabled := false
var show_numbers := false
var show_warnings := true
var show_screen_bounds := false
var dirty := false

var undo_stack: Array = []
var redo_stack: Array = []

var renderer: Node2D
var viewport: SubViewport
var preview_canvas: PreviewCanvas
var island_list: ItemList
var status_label: Label
var warnings_label: Label
var selected_label: Label
var zoom_label: Label
var dirty_label: Label
var flight_x_spin: SpinBox
var flight_y_spin: SpinBox
var layer_option: OptionButton
var band_option: OptionButton
var grid_button: Button
var snap_button: Button
var number_button: Button
var warning_button: Button
var screen_bounds_button: Button
var property_spins: Dictionary = {}
var help_dialog: AcceptDialog

var ui_syncing := false
var dragging_islands := false
var panning_canvas := false
var marquee_selecting := false
var drag_last_canvas_pos := Vector2.ZERO
var marquee_start_canvas_pos := Vector2.ZERO
var marquee_current_canvas_pos := Vector2.ZERO


func _ready() -> void:
	_build_ui()
	_load_profile()
	_set_flight_position(FLIGHT_START_POS, true)
	call_deferred("_fit_canvas_to_view")
	_refresh_all()


func _process(delta: float) -> void:
	elapsed_time += delta
	_sync_renderer()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.ctrl_pressed and key_event.keycode == KEY_S:
		_on_save_pressed()
		get_viewport().set_input_as_handled()
	elif key_event.ctrl_pressed and key_event.keycode == KEY_Z:
		_undo()
		get_viewport().set_input_as_handled()
	elif key_event.ctrl_pressed and key_event.keycode == KEY_Y:
		_redo()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_DELETE:
		_on_delete_pressed()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_F:
		_fit_canvas_to_view()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_1:
		_set_canvas_zoom_100()
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_G:
		_set_grid_visible(not show_grid)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_H:
		_show_help()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	viewport = SubViewport.new()
	viewport.size = Vector2i(int(VIEW_SIZE.x), int(VIEW_SIZE.y))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	renderer = RENDERER_SCRIPT.new()
	renderer.name = "YujianLevelBackgroundRenderer"
	viewport.add_child(renderer)
	renderer.configure_world(VIEW_SIZE, PLAY_RECT, FLIGHT_START_POS, CAMERA_MIN_ZOOM)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var canvas_column := VBoxContainer.new()
	canvas_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(canvas_column)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	canvas_column.add_child(toolbar)

	toolbar.add_child(_make_button("适配视图(F)", _fit_canvas_to_view))
	toolbar.add_child(_make_button("1:1", _set_canvas_zoom_100))
	grid_button = _make_toggle_button("网格(G)", show_grid, func(value: bool) -> void: _set_grid_visible(value))
	toolbar.add_child(grid_button)
	snap_button = _make_toggle_button("吸附", snap_enabled, func(value: bool) -> void: _set_snap_enabled(value))
	toolbar.add_child(snap_button)
	number_button = _make_toggle_button("编号", show_numbers, func(value: bool) -> void: _set_numbers_visible(value))
	toolbar.add_child(number_button)
	warning_button = _make_toggle_button("警告", show_warnings, func(value: bool) -> void: _set_warnings_visible(value))
	toolbar.add_child(warning_button)
	screen_bounds_button = _make_toggle_button("屏幕边界", show_screen_bounds, func(value: bool) -> void: _set_screen_bounds_visible(value))
	toolbar.add_child(screen_bounds_button)
	toolbar.add_child(_make_button("帮助(H)", _show_help))

	zoom_label = Label.new()
	zoom_label.text = "100%"
	zoom_label.custom_minimum_size = Vector2(72.0, 0.0)
	toolbar.add_child(zoom_label)

	dirty_label = Label.new()
	dirty_label.text = "已保存"
	dirty_label.custom_minimum_size = Vector2(88.0, 0.0)
	toolbar.add_child(dirty_label)

	preview_canvas = PreviewCanvas.new()
	preview_canvas.editor = self
	preview_canvas.custom_minimum_size = PREVIEW_MIN_SIZE
	preview_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_column.add_child(preview_canvas)

	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(SIDE_PANEL_MIN_WIDTH, 720.0)
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(side_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.add_child(scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)

	var title := Label.new()
	title.text = "御剑背景画布编辑器 V2"
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)

	column.add_child(_make_section_label("文件"))
	var path_label := Label.new()
	path_label.text = PROFILE_PATH
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(path_label)

	var file_buttons := HBoxContainer.new()
	file_buttons.add_child(_make_button("重新载入", _on_reload_pressed))
	file_buttons.add_child(_make_button("保存(Ctrl+S)", _on_save_pressed))
	file_buttons.add_child(_make_button("撤销(Ctrl+Z)", _undo))
	file_buttons.add_child(_make_button("重做(Ctrl+Y)", _redo))
	column.add_child(file_buttons)

	column.add_child(_make_separator())
	column.add_child(_make_section_label("画布"))
	column.add_child(_make_hint_label("左键选中/拖岛，Shift+左键多选，空白左拖框选；右键拖动画布，滚轮缩放。"))
	column.add_child(_make_hint_label("网格吸附默认关闭，开启后岛屿 X/Y 吸附到 100 世界单位。"))

	column.add_child(_make_separator())
	column.add_child(_make_section_label("预览位置"))
	var preset_row := GridContainer.new()
	preset_row.columns = 3
	preset_row.add_child(_make_button("起点", func() -> void: _set_flight_position(FLIGHT_START_POS, true)))
	preset_row.add_child(_make_button("上升", func() -> void: _set_flight_position(FLIGHT_START_POS + Vector2(0.0, -4200.0), true)))
	preset_row.add_child(_make_button("高空", func() -> void: _set_flight_position(FLIGHT_START_POS + Vector2(0.0, -8400.0), true)))
	preset_row.add_child(_make_button("顶部", func() -> void: _set_flight_position(Vector2(flight_pos.x, PLAY_RECT.position.y), true)))
	preset_row.add_child(_make_button("底部", func() -> void: _set_flight_position(Vector2(flight_pos.x, PLAY_RECT.end.y), true)))
	column.add_child(preset_row)

	flight_x_spin = _make_spin(PLAY_RECT.position.x, PLAY_RECT.end.x, 100.0)
	column.add_child(_make_spin_row("预览 X", flight_x_spin))
	flight_x_spin.value_changed.connect(func(value: float) -> void:
		if ui_syncing:
			return
		_set_flight_position(Vector2(value, flight_pos.y), true)
	)

	flight_y_spin = _make_spin(PLAY_RECT.position.y, PLAY_RECT.end.y, 100.0)
	column.add_child(_make_spin_row("预览 Y", flight_y_spin))
	flight_y_spin.value_changed.connect(func(value: float) -> void:
		if ui_syncing:
			return
		_set_flight_position(Vector2(flight_pos.x, value), true)
	)

	column.add_child(_make_separator())
	column.add_child(_make_section_label("岛屿列表"))
	var island_buttons := HBoxContainer.new()
	island_buttons.add_child(_make_button("新增", _on_add_pressed))
	island_buttons.add_child(_make_button("复制", _on_duplicate_pressed))
	island_buttons.add_child(_make_button("删除(Delete)", _on_delete_pressed))
	column.add_child(island_buttons)

	island_list = ItemList.new()
	island_list.custom_minimum_size = Vector2(460.0, 210.0)
	island_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	island_list.select_mode = ItemList.SELECT_MULTI
	island_list.item_selected.connect(_on_island_item_selected)
	column.add_child(island_list)

	column.add_child(_make_separator())
	selected_label = _make_section_label("未选择岛屿")
	column.add_child(selected_label)

	layer_option = _make_option(LAYER_LABELS)
	column.add_child(_make_option_row("层级", layer_option))
	layer_option.item_selected.connect(func(index: int) -> void:
		_on_selected_option_changed("layer", LAYER_VALUES[index])
	)

	band_option = _make_option(BAND_LABELS)
	column.add_child(_make_option_row("海面带", band_option))
	band_option.item_selected.connect(func(index: int) -> void:
		_on_selected_option_changed("band", BAND_VALUES[index])
	)

	var labels := {
		"x": "X 坐标",
		"y": "Y 坐标",
		"depth": "深度",
		"width": "宽度",
		"length": "纵深",
		"height": "高度",
		"kind": "形体",
		"landmark": "地标",
	}
	for key in FLOAT_KEYS:
		var spin := _make_property_spin(key)
		property_spins[key] = spin
		column.add_child(_make_spin_row(String(labels[key]), spin))
		spin.value_changed.connect(_on_property_spin_value_changed.bind(key))
	for key in INT_KEYS:
		var spin := _make_int_property_spin(key)
		property_spins[key] = spin
		column.add_child(_make_spin_row(String(labels[key]), spin))
		spin.value_changed.connect(_on_property_spin_value_changed.bind(key))

	column.add_child(_make_separator())
	column.add_child(_make_section_label("校验"))
	warnings_label = Label.new()
	warnings_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warnings_label.text = ""
	column.add_child(warnings_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = ""
	column.add_child(status_label)

	help_dialog = AcceptDialog.new()
	help_dialog.title = "画布操作"
	help_dialog.dialog_text = "左键：选择/拖动岛屿\nShift+左键：增减选择\n空白左拖：框选\n右键拖动：平移画布并移动预览位置\n滚轮：围绕鼠标缩放画布\nCtrl+S：保存\nCtrl+Z/Y：撤销/重做\nDelete：删除选中岛屿\nF：适配视图\n1：100% 缩放\nG：显示/隐藏网格\nH：显示本帮助"
	add_child(help_dialog)


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button


func _make_toggle_button(text: String, initial_value: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_pressed = initial_value
	button.toggled.connect(callback)
	return button


func _make_separator() -> HSeparator:
	return HSeparator.new()


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	return label


func _make_hint_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.74, 0.78, 0.82, 1.0))
	return label


func _make_spin(min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.allow_greater = true
	spin.allow_lesser = true
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin


func _make_property_spin(key: String) -> SpinBox:
	match key:
		"x":
			return _make_spin(-200000.0, 200000.0, 20.0)
		"y":
			return _make_spin(-40000.0, 40000.0, 20.0)
		"depth":
			return _make_spin(0.04, 0.98, 0.01)
		"width":
			return _make_spin(20.0, 3000.0, 10.0)
		"length":
			return _make_spin(0.02, 0.40, 0.005)
		"height":
			return _make_spin(0.0, 400.0, 2.0)
		_:
			return _make_spin(-10000.0, 10000.0, 1.0)


func _make_int_property_spin(_key: String) -> SpinBox:
	return _make_spin(-1.0, 32.0, 1.0)


func _make_spin_row(label_text: String, spin: SpinBox) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(92.0, 0.0)
	row.add_child(label)
	row.add_child(spin)
	return row


func _make_option(values: Array) -> OptionButton:
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value in values:
		option.add_item(String(value))
	return option


func _make_option_row(label_text: String, option: OptionButton) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(92.0, 0.0)
	row.add_child(label)
	row.add_child(option)
	return row


func _load_profile() -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		_set_status("读取失败: %s" % PROFILE_PATH, true)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_set_status("JSON 格式无效: %s" % PROFILE_PATH, true)
		return
	profile = parsed
	var islands: Variant = profile.get("scenic_islands", [])
	if typeof(islands) != TYPE_ARRAY:
		islands = []
	scenic_islands = islands
	profile["scenic_islands"] = scenic_islands
	active_index = -1 if scenic_islands.is_empty() else 0
	selected_indices = [] if active_index < 0 else [active_index]
	undo_stack.clear()
	redo_stack.clear()
	dirty = false
	_set_status("已载入 %d 个实体岛" % scenic_islands.size())


func _apply_profile_to_renderer() -> void:
	if renderer == null or profile.is_empty():
		return
	var settings: Variant = profile.get("settings", {})
	if typeof(settings) == TYPE_DICTIONARY:
		renderer.call("_apply_profile_settings", settings)
	renderer.set("profile", profile)
	renderer.set("far_island_bands", _profile_array("far_island_bands"))
	renderer.set("scenic_islands", scenic_islands)
	_sync_renderer()


func _profile_array(key: String) -> Array:
	var value: Variant = profile.get(key, [])
	return value if typeof(value) == TYPE_ARRAY else []


func _sync_renderer() -> void:
	if renderer == null:
		return
	renderer.set_world_state(
		elapsed_time,
		flight_pos,
		camera_center,
		CAMERA_MIN_ZOOM,
		Vector2.ZERO,
		0.0,
		0.0,
		0.0,
		false
	)
	if preview_canvas != null:
		preview_canvas.queue_redraw()


func _refresh_all() -> void:
	_apply_profile_to_renderer()
	_refresh_island_list()
	_refresh_selected_controls()
	_refresh_warnings()
	_refresh_dirty_label()
	_refresh_toolbar()


func _refresh_island_list() -> void:
	if island_list == null:
		return
	ui_syncing = true
	island_list.clear()
	for i in range(scenic_islands.size()):
		var island := _island_at(i)
		var label := "%02d  %s/%s  x %.0f  y %.0f" % [
			i,
			String(island.get("layer", "mid")),
			String(island.get("band", "mid_sea")),
			float(island.get("x", 0.0)),
			float(island.get("y", 0.0)),
		]
		island_list.add_item(label)
		if selected_indices.has(i):
			island_list.select(i, false)
	ui_syncing = false


func _refresh_selected_controls() -> void:
	if flight_x_spin == null:
		return
	ui_syncing = true
	flight_x_spin.value = flight_pos.x
	flight_y_spin.value = flight_pos.y
	if active_index < 0 or active_index >= scenic_islands.size():
		selected_label.text = "未选择岛屿"
		ui_syncing = false
		return
	var island := _selected_island()
	selected_label.text = "编辑岛屿 %02d    已选 %d 个" % [active_index, selected_indices.size()]
	_select_option_value(layer_option, LAYER_VALUES, String(island.get("layer", "mid")))
	_select_option_value(band_option, BAND_VALUES, String(island.get("band", "mid_sea")))
	for key in FLOAT_KEYS:
		if property_spins.has(key):
			(property_spins[key] as SpinBox).value = float(island.get(key, _default_island_value(key)))
	for key in INT_KEYS:
		if property_spins.has(key):
			(property_spins[key] as SpinBox).value = float(int(island.get(key, int(_default_island_value(key)))))
	ui_syncing = false


func _refresh_warnings() -> void:
	if warnings_label == null or renderer == null:
		return
	var lines := []
	var horizon := float(renderer.call("get_horizon_y"))
	var visible_count := 0
	var sky_count := 0
	for i in range(scenic_islands.size()):
		var island := _island_at(i)
		var alpha := float(renderer.call("get_scenic_island_visibility_alpha", island))
		if alpha <= 0.02:
			continue
		visible_count += 1
		var center := _project_island_center(island)
		var bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", island)
		if center.y < horizon or bounds.end.y < horizon:
			sky_count += 1
			if show_warnings:
				lines.append("警告: %02d 已进入海平线上方  center %.1f  horizon %.1f" % [i, center.y, horizon])
	if active_index >= 0 and active_index < scenic_islands.size():
		var selected := _selected_island()
		var selected_center := _project_island_center(selected)
		var selected_bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", selected)
		lines.append("选中: center_y-horizon %.1f, bounds %.0f..%.0f" % [
			selected_center.y - horizon,
			selected_bounds.position.y,
			selected_bounds.end.y,
		])
	lines.append("可见实体岛: %d，海平线上方: %d" % [visible_count, sky_count])
	warnings_label.text = "\n".join(lines)


func _refresh_dirty_label() -> void:
	if dirty_label == null:
		return
	dirty_label.text = "未保存" if dirty else "已保存"
	dirty_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28, 1.0) if dirty else Color(0.72, 0.95, 0.78, 1.0))


func _refresh_toolbar() -> void:
	if zoom_label != null:
		zoom_label.text = "%d%%" % int(round(canvas_zoom * 100.0))
	if grid_button != null:
		grid_button.button_pressed = show_grid
	if snap_button != null:
		snap_button.button_pressed = snap_enabled
	if number_button != null:
		number_button.button_pressed = show_numbers
	if warning_button != null:
		warning_button.button_pressed = show_warnings
	if screen_bounds_button != null:
		screen_bounds_button.button_pressed = show_screen_bounds
	if preview_canvas != null:
		preview_canvas.queue_redraw()


func _select_option_value(option: OptionButton, values: Array, value: String) -> void:
	var index := values.find(value)
	option.select(maxi(index, 0))


func _on_reload_pressed() -> void:
	_load_profile()
	_set_flight_position(flight_pos, true)
	_refresh_all()


func _on_save_pressed() -> void:
	profile["scenic_islands"] = scenic_islands
	var global_path := ProjectSettings.globalize_path(PROFILE_PATH)
	var file := FileAccess.open(global_path, FileAccess.WRITE)
	if file == null:
		_set_status("保存失败: %s" % global_path, true)
		return
	file.store_string(JSON.stringify(profile, "\t") + "\n")
	dirty = false
	_refresh_dirty_label()
	_set_status("已保存: %s" % global_path)


func _on_add_pressed() -> void:
	_push_undo("新增岛屿")
	var island := _default_island()
	var anchor := _profile_anchor_from_canvas(preview_canvas.size * 0.52, island)
	island["x"] = anchor.x
	island["y"] = anchor.y
	scenic_islands.append(island)
	active_index = scenic_islands.size() - 1
	selected_indices = [active_index]
	_mark_dirty("已新增岛屿")
	_refresh_all()


func _on_duplicate_pressed() -> void:
	if selected_indices.is_empty():
		return
	_push_undo("复制岛屿")
	var sorted := _sorted_selected_indices()
	var new_selection := []
	var insert_offset := 0
	for index in sorted:
		var source_index := int(index)
		var copy: Dictionary = _island_at(source_index).duplicate(true)
		copy["x"] = float(copy.get("x", 0.0)) + SNAP_GRID_WORLD
		copy["y"] = float(copy.get("y", 0.0)) + SNAP_GRID_WORLD
		var insert_index: int = source_index + 1 + insert_offset
		scenic_islands.insert(insert_index, copy)
		new_selection.append(insert_index)
		insert_offset += 1
	selected_indices = new_selection
	active_index = int(selected_indices[0])
	_mark_dirty("已复制岛屿")
	_refresh_all()


func _on_delete_pressed() -> void:
	if selected_indices.is_empty():
		return
	_push_undo("删除岛屿")
	var sorted := _sorted_selected_indices()
	sorted.reverse()
	for index in sorted:
		var remove_index := int(index)
		if remove_index >= 0 and remove_index < scenic_islands.size():
			scenic_islands.remove_at(remove_index)
	var fallback_index := -1
	if not sorted.is_empty():
		fallback_index = int(sorted[sorted.size() - 1])
	active_index = mini(fallback_index, scenic_islands.size() - 1)
	selected_indices = [] if active_index < 0 else [active_index]
	_mark_dirty("已删除岛屿")
	_refresh_all()


func _on_island_item_selected(index: int) -> void:
	if ui_syncing:
		return
	active_index = index
	selected_indices = _packed_ints_to_array(island_list.get_selected_items())
	if selected_indices.is_empty():
		selected_indices = [index]
	_refresh_selected_controls()
	_refresh_warnings()
	if preview_canvas != null:
		preview_canvas.queue_redraw()


func _on_selected_spin_changed(key: String, value: float) -> void:
	if ui_syncing or active_index < 0 or active_index >= scenic_islands.size():
		return
	_push_undo("修改属性")
	var island := _selected_island()
	if INT_KEYS.has(key):
		island[key] = int(round(value))
	else:
		island[key] = _snap_value(value) if snap_enabled and (key == "x" or key == "y") else value
	_on_island_data_changed("已修改属性")


func _on_property_spin_value_changed(value: float, key: String) -> void:
	_on_selected_spin_changed(key, value)


func _on_selected_option_changed(key: String, value: String) -> void:
	if ui_syncing or active_index < 0 or active_index >= scenic_islands.size():
		return
	_push_undo("修改层级")
	_selected_island()[key] = value
	_on_island_data_changed("已修改层级")


func _on_island_data_changed(message: String) -> void:
	profile["scenic_islands"] = scenic_islands
	_mark_dirty(message)
	_refresh_island_list()
	_apply_profile_to_renderer()
	_refresh_warnings()
	_refresh_selected_controls()


func _on_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var canvas_pos := mouse_event.position
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				preview_canvas.grab_focus()
				_handle_left_press(canvas_pos, mouse_event.shift_pressed)
			else:
				_handle_left_release(canvas_pos, mouse_event.shift_pressed)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				preview_canvas.grab_focus()
				panning_canvas = true
				drag_last_canvas_pos = canvas_pos
			else:
				panning_canvas = false
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_zoom_canvas_at(canvas_pos, canvas_zoom * CANVAS_ZOOM_STEP)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_zoom_canvas_at(canvas_pos, canvas_zoom / CANVAS_ZOOM_STEP)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if dragging_islands:
			_drag_selected_islands(motion.relative / canvas_zoom)
		elif panning_canvas:
			_pan_preview_by_canvas_delta(motion.relative / canvas_zoom)
		elif marquee_selecting:
			marquee_current_canvas_pos = motion.position
			preview_canvas.queue_redraw()


func _handle_left_press(canvas_pos: Vector2, shift_pressed: bool) -> void:
	var hit_index := _find_island_at_canvas_pos(canvas_pos)
	drag_last_canvas_pos = canvas_pos
	if hit_index >= 0:
		if shift_pressed:
			_toggle_selection(hit_index)
			return
		if not selected_indices.has(hit_index):
			active_index = hit_index
			selected_indices = [hit_index]
			_refresh_island_list()
			_refresh_selected_controls()
		_push_undo("移动岛屿")
		dragging_islands = true
	else:
		marquee_selecting = true
		marquee_start_canvas_pos = canvas_pos
		marquee_current_canvas_pos = canvas_pos
		if not shift_pressed:
			active_index = -1
			selected_indices = []
			_refresh_island_list()
			_refresh_selected_controls()


func _handle_left_release(_canvas_pos: Vector2, shift_pressed: bool) -> void:
	if dragging_islands:
		dragging_islands = false
		_refresh_all()
	if marquee_selecting:
		marquee_selecting = false
		_select_by_marquee(shift_pressed)
		preview_canvas.queue_redraw()


func _toggle_selection(index: int) -> void:
	if selected_indices.has(index):
		selected_indices.erase(index)
		if active_index == index:
			active_index = -1 if selected_indices.is_empty() else int(selected_indices[selected_indices.size() - 1])
	else:
		selected_indices.append(index)
		active_index = index
	_refresh_island_list()
	_refresh_selected_controls()
	_refresh_warnings()
	preview_canvas.queue_redraw()


func _select_by_marquee(shift_pressed: bool) -> void:
	var rect := _normalized_rect(marquee_start_canvas_pos, marquee_current_canvas_pos)
	if rect.size.length() < 4.0:
		return
	var new_selection := [] if not shift_pressed else selected_indices.duplicate()
	for i in range(scenic_islands.size()):
		var bounds := _island_canvas_bounds(_island_at(i))
		var center := _viewport_to_canvas(_project_island_center(_island_at(i)))
		if rect.intersects(bounds) or rect.has_point(center):
			if not new_selection.has(i):
				new_selection.append(i)
	selected_indices = new_selection
	active_index = -1 if selected_indices.is_empty() else int(selected_indices[selected_indices.size() - 1])
	_refresh_island_list()
	_refresh_selected_controls()
	_refresh_warnings()


func _drag_selected_islands(viewport_delta: Vector2) -> void:
	if selected_indices.is_empty():
		return
	var moved := false
	for index in selected_indices:
		var island_index := int(index)
		if island_index < 0 or island_index >= scenic_islands.size():
			continue
		var island := _island_at(island_index)
		var profile_delta := _screen_delta_to_profile_delta(viewport_delta, island)
		var new_x := float(island.get("x", 0.0)) + profile_delta.x
		var new_y := float(island.get("y", 0.0)) + profile_delta.y
		if snap_enabled:
			new_x = _snap_value(new_x)
			new_y = _snap_value(new_y)
		island["x"] = new_x
		island["y"] = new_y
		moved = true
	if moved:
		_mark_dirty("已移动岛屿")
		_apply_profile_to_renderer()
		_refresh_selected_controls()
		_refresh_warnings()


func _pan_preview_by_canvas_delta(viewport_delta: Vector2) -> void:
	var y_rate := maxf(_settings_float("horizon_y_response", 0.016) + _editor_scenic_anchor_parallax_y("mid", 0.5) / CAMERA_MIN_ZOOM, 0.001)
	var world_delta := Vector2(
		-viewport_delta.x * CAMERA_MIN_ZOOM / PAN_REFERENCE_X_PARALLAX,
		-viewport_delta.y / y_rate
	)
	_set_flight_position(flight_pos + world_delta, true)


func _set_flight_position(new_pos: Vector2, clamp_to_play: bool) -> void:
	flight_pos = new_pos
	if clamp_to_play:
		flight_pos.x = clampf(flight_pos.x, PLAY_RECT.position.x, PLAY_RECT.end.x)
		flight_pos.y = clampf(flight_pos.y, PLAY_RECT.position.y, PLAY_RECT.end.y)
	camera_center = _clamp_camera_center(flight_pos)
	_sync_renderer()
	_refresh_selected_controls()
	_refresh_warnings()


func _clamp_camera_center(center: Vector2) -> Vector2:
	var half_view := VIEW_SIZE * 0.5 * CAMERA_MIN_ZOOM
	var min_center := PLAY_RECT.position + half_view
	var max_center := PLAY_RECT.end - half_view
	if min_center.x > max_center.x:
		min_center.x = PLAY_RECT.get_center().x
		max_center.x = min_center.x
	if min_center.y > max_center.y:
		min_center.y = PLAY_RECT.get_center().y
		max_center.y = min_center.y
	return Vector2(
		clampf(center.x, min_center.x, max_center.x),
		clampf(center.y, min_center.y, max_center.y)
	)


func _fit_canvas_to_view() -> void:
	if preview_canvas == null:
		return
	var available := preview_canvas.size
	if available.x <= 1.0 or available.y <= 1.0:
		available = PREVIEW_MIN_SIZE
	canvas_zoom = minf(available.x / VIEW_SIZE.x, available.y / VIEW_SIZE.y)
	canvas_pan = (available - VIEW_SIZE * canvas_zoom) * 0.5
	canvas_auto_fit = true
	_refresh_toolbar()


func _set_canvas_zoom_100() -> void:
	if preview_canvas == null:
		return
	canvas_zoom = 1.0
	canvas_pan = (preview_canvas.size - VIEW_SIZE) * 0.5
	canvas_auto_fit = false
	_refresh_toolbar()


func _zoom_canvas_at(canvas_pos: Vector2, new_zoom: float) -> void:
	var old_zoom := canvas_zoom
	new_zoom = clampf(new_zoom, CANVAS_MIN_ZOOM, CANVAS_MAX_ZOOM)
	if is_equal_approx(old_zoom, new_zoom):
		return
	var viewport_point := _canvas_to_viewport(canvas_pos)
	canvas_zoom = new_zoom
	canvas_pan = canvas_pos - viewport_point * canvas_zoom
	canvas_auto_fit = false
	_refresh_toolbar()


func _on_canvas_resized() -> void:
	if canvas_auto_fit:
		_fit_canvas_to_view()


func _set_grid_visible(value: bool) -> void:
	show_grid = value
	_refresh_toolbar()


func _set_snap_enabled(value: bool) -> void:
	snap_enabled = value
	_refresh_toolbar()


func _set_numbers_visible(value: bool) -> void:
	show_numbers = value
	_refresh_toolbar()


func _set_warnings_visible(value: bool) -> void:
	show_warnings = value
	_refresh_toolbar()
	_refresh_warnings()


func _set_screen_bounds_visible(value: bool) -> void:
	show_screen_bounds = value
	_refresh_toolbar()


func _show_help() -> void:
	if help_dialog != null:
		help_dialog.popup_centered()


func _canvas_to_viewport(canvas_pos: Vector2) -> Vector2:
	return (canvas_pos - canvas_pan) / maxf(canvas_zoom, 0.001)


func _viewport_to_canvas(viewport_pos: Vector2) -> Vector2:
	return canvas_pan + viewport_pos * canvas_zoom


func _screen_delta_to_profile_delta(screen_delta: Vector2, island: Dictionary) -> Vector2:
	var depth := clampf(float(island.get("depth", 0.5)), 0.0, 1.0)
	var layer := String(island.get("layer", "mid")).to_lower()
	var x_parallax := maxf(_editor_scenic_layer_parallax_x(layer, depth), 0.001)
	var y_parallax := maxf(_editor_scenic_anchor_parallax_y(layer, depth), 0.001)
	return Vector2(
		screen_delta.x * CAMERA_MIN_ZOOM / x_parallax,
		screen_delta.y * CAMERA_MIN_ZOOM / y_parallax
	)


func _profile_anchor_from_canvas(canvas_pos: Vector2, island: Dictionary) -> Vector2:
	return _profile_anchor_from_screen(_canvas_to_viewport(canvas_pos), island)


func _profile_anchor_from_screen(screen_pos: Vector2, island: Dictionary) -> Vector2:
	var depth := clampf(float(island.get("depth", 0.5)), 0.0, 1.0)
	var layer := String(island.get("layer", "mid")).to_lower()
	var band := String(island.get("band", "mid_sea")).to_lower()
	var x_parallax := maxf(_editor_scenic_layer_parallax_x(layer, depth), 0.001)
	var y_parallax := maxf(_editor_scenic_anchor_parallax_y(layer, depth), 0.001)
	var horizon := float(renderer.call("get_horizon_y"))
	var profile_x := camera_center.x + (screen_pos.x - VIEW_SIZE.x * 0.5) * CAMERA_MIN_ZOOM / x_parallax
	var profile_y := flight_pos.y - FLIGHT_START_POS.y + (screen_pos.y - horizon - _editor_scenic_band_offset(band, depth)) * CAMERA_MIN_ZOOM / y_parallax
	return Vector2(profile_x, profile_y)


func _editor_scenic_layer_parallax_x(layer: String, depth: float) -> float:
	match layer:
		"far":
			return lerpf(0.055, 0.12, clampf(depth, 0.0, 1.0))
		"near":
			return lerpf(0.46, 0.66, clampf(depth, 0.0, 1.0))
		_:
			return lerpf(0.22, 0.38, clampf(depth, 0.0, 1.0))


func _editor_scenic_anchor_parallax_y(layer: String, _depth: float) -> float:
	var base := 0.060 * _settings_float("vertical_exit_strength", 1.0)
	match layer.to_lower():
		"far":
			return base * _settings_float("far_scenic_y_parallax", 0.48)
		"near":
			return base * _settings_float("near_scenic_y_parallax", 1.12)
		_:
			return base * _settings_float("mid_scenic_y_parallax", 0.78)


func _editor_scenic_band_offset(band: String, depth: float) -> float:
	match band:
		"horizon":
			return 66.0 + depth * 22.0
		"near_sea", "foreground_bottom":
			return 252.0 + depth * 50.0
		"foreground":
			return 284.0 + depth * 58.0
		_:
			return 132.0 + depth * 44.0


func _settings_float(key: String, fallback: float) -> float:
	var settings: Variant = profile.get("settings", {})
	if typeof(settings) != TYPE_DICTIONARY:
		return fallback
	return float(settings.get(key, fallback))


func _find_island_at_canvas_pos(canvas_pos: Vector2) -> int:
	var best_index := -1
	var best_distance := INF
	for i in range(scenic_islands.size()):
		var island := _island_at(i)
		var bounds := _island_canvas_bounds(island)
		var center := _viewport_to_canvas(_project_island_center(island))
		var distance := center.distance_to(canvas_pos)
		if bounds.has_point(canvas_pos):
			distance *= 0.25
		if distance < best_distance and distance < HIT_RADIUS * canvas_zoom:
			best_distance = distance
			best_index = i
	return best_index


func _island_canvas_bounds(island: Dictionary) -> Rect2:
	var bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", island)
	return Rect2(_viewport_to_canvas(bounds.position), bounds.size * canvas_zoom)


func _project_island_center(island: Dictionary) -> Vector2:
	return renderer.call(
		"project_scenic_point",
		float(island.get("x", FLIGHT_START_POS.x)),
		FLIGHT_START_POS.y + float(island.get("y", 0.0)),
		float(island.get("depth", 0.5)),
		String(island.get("layer", "mid")),
		String(island.get("band", "mid_sea"))
	)


func _draw_canvas(canvas: Control) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0.075, 0.080, 0.090, 1.0))
	var texture: Texture2D = null
	if viewport != null:
		texture = viewport.get_texture()
	var image_rect := Rect2(canvas_pan, VIEW_SIZE * canvas_zoom)
	if texture != null:
		canvas.draw_texture_rect(texture, image_rect, false)
	canvas.draw_rect(image_rect, Color(1.0, 1.0, 1.0, 0.28), false, 1.0)
	if show_grid:
		_draw_canvas_grid(canvas, image_rect)
	if show_screen_bounds:
		canvas.draw_rect(image_rect, Color(0.42, 0.72, 1.0, 0.80), false, 2.0)
	_draw_canvas_guides(canvas)
	if marquee_selecting:
		var rect := _normalized_rect(marquee_start_canvas_pos, marquee_current_canvas_pos)
		canvas.draw_rect(rect, Color(0.25, 0.58, 1.0, 0.18), true)
		canvas.draw_rect(rect, Color(0.32, 0.72, 1.0, 0.95), false, 1.0)


func _draw_canvas_grid(canvas: Control, image_rect: Rect2) -> void:
	var step := SNAP_GRID_WORLD * canvas_zoom
	if step < 12.0:
		step *= ceilf(12.0 / step)
	var start_x := image_rect.position.x + fposmod(-image_rect.position.x, step)
	var x := start_x
	while x <= image_rect.end.x:
		canvas.draw_line(Vector2(x, image_rect.position.y), Vector2(x, image_rect.end.y), Color(1.0, 1.0, 1.0, 0.11), 1.0)
		x += step
	var start_y := image_rect.position.y + fposmod(-image_rect.position.y, step)
	var y := start_y
	while y <= image_rect.end.y:
		canvas.draw_line(Vector2(image_rect.position.x, y), Vector2(image_rect.end.x, y), Color(1.0, 1.0, 1.0, 0.11), 1.0)
		y += step


func _draw_canvas_guides(canvas: Control) -> void:
	if renderer == null:
		return
	var horizon := float(renderer.call("get_horizon_y"))
	var horizon_y := _viewport_to_canvas(Vector2(0.0, horizon)).y
	canvas.draw_line(
		_viewport_to_canvas(Vector2(0.0, horizon)),
		_viewport_to_canvas(Vector2(VIEW_SIZE.x, horizon)),
		Color(1.0, 0.92, 0.32, 0.95),
		2.0
	)
	var player_screen := (flight_pos - camera_center) / CAMERA_MIN_ZOOM + VIEW_SIZE * 0.5
	var player_canvas := _viewport_to_canvas(player_screen)
	canvas.draw_circle(player_canvas, 7.0 * canvas_zoom, Color(0.05, 0.05, 0.05, 0.85))
	canvas.draw_circle(player_canvas, 4.0 * canvas_zoom, Color(0.95, 1.0, 1.0, 0.95))

	for i in range(scenic_islands.size()):
		var island := _island_at(i)
		var alpha := float(renderer.call("get_scenic_island_visibility_alpha", island))
		if alpha <= 0.01:
			continue
		var bounds := _island_canvas_bounds(island)
		var center := _viewport_to_canvas(_project_island_center(island))
		var viewport_bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", island)
		var color := Color(0.20, 0.95, 0.45, 0.88)
		if show_warnings and (viewport_bounds.end.y < horizon or _canvas_to_viewport(center).y < horizon):
			color = Color(1.0, 0.24, 0.18, 0.96)
		if selected_indices.has(i):
			color = Color(1.0, 0.84, 0.18, 1.0)
		canvas.draw_rect(bounds, color, false, 2.0)
		canvas.draw_circle(center, maxf(3.0, 4.0 * canvas_zoom), color)
		if show_numbers or selected_indices.has(i):
			canvas.draw_string(ThemeDB.fallback_font, center + Vector2(8.0, -8.0), "%02d" % i, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14.0, color)


func _push_undo(_label: String) -> void:
	undo_stack.append({
		"islands": _clone_islands(),
		"selected": selected_indices.duplicate(),
		"active": active_index,
	})
	if undo_stack.size() > MAX_UNDO_STEPS:
		undo_stack.pop_front()
	redo_stack.clear()


func _undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append({
		"islands": _clone_islands(),
		"selected": selected_indices.duplicate(),
		"active": active_index,
	})
	_restore_snapshot(undo_stack.pop_back())
	_mark_dirty("已撤销")
	_refresh_all()


func _redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append({
		"islands": _clone_islands(),
		"selected": selected_indices.duplicate(),
		"active": active_index,
	})
	_restore_snapshot(redo_stack.pop_back())
	_mark_dirty("已重做")
	_refresh_all()


func _restore_snapshot(snapshot: Dictionary) -> void:
	scenic_islands = snapshot.get("islands", []).duplicate(true)
	profile["scenic_islands"] = scenic_islands
	selected_indices = snapshot.get("selected", []).duplicate()
	active_index = int(snapshot.get("active", -1))


func _clone_islands() -> Array:
	return scenic_islands.duplicate(true)


func _mark_dirty(message: String) -> void:
	dirty = true
	_refresh_dirty_label()
	_set_status(message)


func _sorted_selected_indices() -> Array:
	var sorted := selected_indices.duplicate()
	sorted.sort()
	return sorted


func _packed_ints_to_array(values: PackedInt32Array) -> Array:
	var result := []
	for value in values:
		result.append(int(value))
	return result


func _normalized_rect(a: Vector2, b: Vector2) -> Rect2:
	var position := Vector2(minf(a.x, b.x), minf(a.y, b.y))
	var end := Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
	return Rect2(position, end - position)


func _snap_value(value: float) -> float:
	return round(value / SNAP_GRID_WORLD) * SNAP_GRID_WORLD


func _island_at(index: int) -> Dictionary:
	if index < 0 or index >= scenic_islands.size():
		return {}
	var value: Variant = scenic_islands[index]
	return value if typeof(value) == TYPE_DICTIONARY else {}


func _selected_island() -> Dictionary:
	return _island_at(active_index)


func _default_island() -> Dictionary:
	return {
		"x": FLIGHT_START_POS.x + 2400.0,
		"y": 4200.0,
		"layer": "mid",
		"band": "mid_sea",
		"depth": 0.42,
		"width": 320.0,
		"length": 0.110,
		"height": 32.0,
		"kind": 0,
		"landmark": -1,
	}


func _default_island_value(key: String) -> float:
	return float(_default_island().get(key, 0.0))


func _set_status(text: String, is_error := false) -> void:
	if status_label != null:
		status_label.text = text
		status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.28, 1.0) if is_error else Color(0.72, 0.95, 0.78, 1.0))
	if is_error:
		push_warning(text)
	else:
		print(text)
