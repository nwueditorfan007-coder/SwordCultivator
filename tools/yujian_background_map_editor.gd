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
const PREVIEW_MIN_SIZE := Vector2(920.0, 540.0)
const SIDE_PANEL_MIN_WIDTH := 340.0

const LAYERS := ["far", "mid", "near"]
const BANDS := ["horizon", "mid_sea", "near_sea"]
const FLOAT_KEYS := ["x", "y", "depth", "width", "length", "height"]
const INT_KEYS := ["kind", "landmark"]

class PreviewGuideOverlay:
	extends Node2D

	var editor: Control

	func _draw() -> void:
		if editor != null:
			editor._draw_preview_guides(self)


var profile: Dictionary = {}
var scenic_islands: Array = []
var selected_index := -1
var flight_pos := FLIGHT_START_POS
var camera_center := FLIGHT_START_POS
var elapsed_time := 0.0

var renderer: Node2D
var overlay: PreviewGuideOverlay
var viewport: SubViewport
var preview_container: SubViewportContainer
var island_list: ItemList
var status_label: Label
var warnings_label: Label
var selected_label: Label
var flight_x_spin: SpinBox
var flight_y_spin: SpinBox
var layer_option: OptionButton
var band_option: OptionButton
var property_spins: Dictionary = {}

var ui_syncing := false
var dragging := false
var last_drag_pos := Vector2.ZERO


func _ready() -> void:
	_build_ui()
	_load_profile()
	_set_flight_position(FLIGHT_START_POS, true)
	_refresh_all()


func _process(delta: float) -> void:
	elapsed_time += delta
	if renderer != null:
		_sync_renderer()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	preview_container = SubViewportContainer.new()
	preview_container.custom_minimum_size = PREVIEW_MIN_SIZE
	preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_container.stretch = true
	preview_container.gui_input.connect(_on_preview_gui_input)
	root.add_child(preview_container)

	viewport = SubViewport.new()
	viewport.size = Vector2i(int(VIEW_SIZE.x), int(VIEW_SIZE.y))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_container.add_child(viewport)

	renderer = RENDERER_SCRIPT.new()
	renderer.name = "YujianLevelBackgroundRenderer"
	viewport.add_child(renderer)
	renderer.configure_world(VIEW_SIZE, PLAY_RECT, FLIGHT_START_POS, CAMERA_MIN_ZOOM)

	overlay = PreviewGuideOverlay.new()
	overlay.name = "PreviewGuideOverlay"
	overlay.editor = self
	overlay.z_index = 200
	viewport.add_child(overlay)

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
	title.text = "御剑背景摆放编辑器"
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)

	var path_label := Label.new()
	path_label.text = PROFILE_PATH
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(path_label)

	var file_buttons := HBoxContainer.new()
	column.add_child(file_buttons)
	file_buttons.add_child(_make_button("Reload", _on_reload_pressed))
	file_buttons.add_child(_make_button("Save", _on_save_pressed))

	column.add_child(_make_separator())
	column.add_child(_make_section_label("预览位置"))

	var preset_row := GridContainer.new()
	preset_row.columns = 3
	column.add_child(preset_row)
	preset_row.add_child(_make_button("Start", func() -> void: _set_flight_position(FLIGHT_START_POS, true)))
	preset_row.add_child(_make_button("Up", func() -> void: _set_flight_position(FLIGHT_START_POS + Vector2(0.0, -4200.0), true)))
	preset_row.add_child(_make_button("High", func() -> void: _set_flight_position(FLIGHT_START_POS + Vector2(0.0, -8400.0), true)))
	preset_row.add_child(_make_button("Top", func() -> void: _set_flight_position(Vector2(flight_pos.x, PLAY_RECT.position.y), true)))
	preset_row.add_child(_make_button("Bottom", func() -> void: _set_flight_position(Vector2(flight_pos.x, PLAY_RECT.end.y), true)))

	flight_x_spin = _make_spin(PLAY_RECT.position.x, PLAY_RECT.end.x, 100.0)
	column.add_child(_make_spin_row("Flight X", flight_x_spin))
	flight_x_spin.value_changed.connect(func(value: float) -> void:
		if ui_syncing:
			return
		_set_flight_position(Vector2(value, flight_pos.y), true)
	)

	flight_y_spin = _make_spin(PLAY_RECT.position.y, PLAY_RECT.end.y, 100.0)
	column.add_child(_make_spin_row("Flight Y", flight_y_spin))
	flight_y_spin.value_changed.connect(func(value: float) -> void:
		if ui_syncing:
			return
		_set_flight_position(Vector2(flight_pos.x, value), true)
	)

	column.add_child(_make_separator())
	column.add_child(_make_section_label("岛屿列表"))

	var island_buttons := HBoxContainer.new()
	column.add_child(island_buttons)
	island_buttons.add_child(_make_button("Add", _on_add_pressed))
	island_buttons.add_child(_make_button("Duplicate", _on_duplicate_pressed))
	island_buttons.add_child(_make_button("Delete", _on_delete_pressed))

	island_list = ItemList.new()
	island_list.custom_minimum_size = Vector2(340.0, 210.0)
	island_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	island_list.item_selected.connect(_on_island_item_selected)
	column.add_child(island_list)

	column.add_child(_make_separator())
	selected_label = _make_section_label("未选择岛屿")
	column.add_child(selected_label)

	layer_option = _make_option(LAYERS)
	column.add_child(_make_option_row("Layer", layer_option))
	layer_option.item_selected.connect(func(index: int) -> void:
		_on_selected_option_changed("layer", LAYERS[index])
	)

	band_option = _make_option(BANDS)
	column.add_child(_make_option_row("Band", band_option))
	band_option.item_selected.connect(func(index: int) -> void:
		_on_selected_option_changed("band", BANDS[index])
	)

	for key in FLOAT_KEYS:
		var spin := _make_property_spin(key)
		property_spins[key] = spin
		column.add_child(_make_spin_row(key.capitalize(), spin))
		spin.value_changed.connect(_on_property_spin_value_changed.bind(key))

	for key in INT_KEYS:
		var spin := _make_int_property_spin(key)
		property_spins[key] = spin
		column.add_child(_make_spin_row(key.capitalize(), spin))
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


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button


func _make_separator() -> HSeparator:
	return HSeparator.new()


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
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
		_set_status("Load failed: %s" % PROFILE_PATH, true)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_set_status("Invalid JSON: %s" % PROFILE_PATH, true)
		return
	profile = parsed
	var islands: Variant = profile.get("scenic_islands", [])
	if typeof(islands) != TYPE_ARRAY:
		islands = []
	scenic_islands = islands
	profile["scenic_islands"] = scenic_islands
	selected_index = -1 if scenic_islands.is_empty() else 0
	_set_status("Loaded %d scenic islands" % scenic_islands.size())


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
	if overlay != null:
		overlay.queue_redraw()


func _refresh_all() -> void:
	_apply_profile_to_renderer()
	_refresh_island_list()
	_refresh_selected_controls()
	_refresh_warnings()


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
	if selected_index >= 0 and selected_index < scenic_islands.size():
		island_list.select(selected_index)
	ui_syncing = false


func _refresh_selected_controls() -> void:
	ui_syncing = true
	flight_x_spin.value = flight_pos.x
	flight_y_spin.value = flight_pos.y
	if selected_index < 0 or selected_index >= scenic_islands.size():
		selected_label.text = "未选择岛屿"
		ui_syncing = false
		return
	var island := _selected_island()
	selected_label.text = "编辑岛屿 %02d" % selected_index
	_select_option_value(layer_option, LAYERS, String(island.get("layer", "mid")))
	_select_option_value(band_option, BANDS, String(island.get("band", "mid_sea")))
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
			lines.append("警告: %02d visible above horizon  center %.1f  horizon %.1f" % [i, center.y, horizon])
	if selected_index >= 0 and selected_index < scenic_islands.size():
		var selected := _selected_island()
		var selected_center := _project_island_center(selected)
		var selected_bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", selected)
		lines.append("选中: center_y-horizon %.1f, bounds %.0f..%.0f" % [
			selected_center.y - horizon,
			selected_bounds.position.y,
			selected_bounds.end.y,
		])
	lines.append("Visible scenic islands: %d, above horizon: %d" % [visible_count, sky_count])
	warnings_label.text = "\n".join(lines)


func _select_option_value(option: OptionButton, values: Array, value: String) -> void:
	var index := values.find(value)
	option.select(maxi(index, 0))


func _on_reload_pressed() -> void:
	_load_profile()
	_refresh_all()


func _on_save_pressed() -> void:
	profile["scenic_islands"] = scenic_islands
	var global_path := ProjectSettings.globalize_path(PROFILE_PATH)
	var file := FileAccess.open(global_path, FileAccess.WRITE)
	if file == null:
		_set_status("Save failed: %s" % global_path, true)
		return
	file.store_string(JSON.stringify(profile, "\t") + "\n")
	_set_status("Saved: %s" % global_path)


func _on_add_pressed() -> void:
	var island := _default_island()
	var anchor := _profile_anchor_from_screen(Vector2(VIEW_SIZE.x * 0.68, VIEW_SIZE.y * 0.60), island)
	island["x"] = anchor.x
	island["y"] = anchor.y
	scenic_islands.append(island)
	selected_index = scenic_islands.size() - 1
	_refresh_all()


func _on_duplicate_pressed() -> void:
	if selected_index < 0 or selected_index >= scenic_islands.size():
		return
	var copy: Dictionary = _selected_island().duplicate(true)
	copy["x"] = float(copy.get("x", 0.0)) + 900.0
	copy["y"] = float(copy.get("y", 0.0)) + 300.0
	scenic_islands.insert(selected_index + 1, copy)
	selected_index += 1
	_refresh_all()


func _on_delete_pressed() -> void:
	if selected_index < 0 or selected_index >= scenic_islands.size():
		return
	scenic_islands.remove_at(selected_index)
	selected_index = mini(selected_index, scenic_islands.size() - 1)
	_refresh_all()


func _on_island_item_selected(index: int) -> void:
	if ui_syncing:
		return
	selected_index = index
	_refresh_selected_controls()
	_refresh_warnings()
	if overlay != null:
		overlay.queue_redraw()


func _on_selected_spin_changed(key: String, value: float) -> void:
	if ui_syncing or selected_index < 0 or selected_index >= scenic_islands.size():
		return
	var island := _selected_island()
	if INT_KEYS.has(key):
		island[key] = int(round(value))
	else:
		island[key] = value
	_on_island_data_changed()


func _on_property_spin_value_changed(value: float, key: String) -> void:
	_on_selected_spin_changed(key, value)


func _on_selected_option_changed(key: String, value: String) -> void:
	if ui_syncing or selected_index < 0 or selected_index >= scenic_islands.size():
		return
	_selected_island()[key] = value
	_on_island_data_changed()


func _on_island_data_changed() -> void:
	profile["scenic_islands"] = scenic_islands
	_refresh_island_list()
	_apply_profile_to_renderer()
	_refresh_warnings()
	_refresh_selected_controls()


func _on_preview_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var pos := _preview_to_viewport_pos(mouse_event.position)
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_select_island_at(pos)
				dragging = selected_index >= 0
				last_drag_pos = pos
			else:
				dragging = false
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_set_flight_position(flight_pos + Vector2(0.0, -250.0), true)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_set_flight_position(flight_pos + Vector2(0.0, 250.0), true)
	elif event is InputEventMouseMotion and dragging and selected_index >= 0:
		var motion := event as InputEventMouseMotion
		var pos := _preview_to_viewport_pos(motion.position)
		var delta := pos - last_drag_pos
		last_drag_pos = pos
		_drag_selected_island(delta)


func _preview_to_viewport_pos(pos: Vector2) -> Vector2:
	var display_size := preview_container.size
	if display_size.x <= 0.0 or display_size.y <= 0.0:
		return pos
	return Vector2(pos.x * VIEW_SIZE.x / display_size.x, pos.y * VIEW_SIZE.y / display_size.y)


func _select_island_at(pos: Vector2) -> void:
	var best_index := -1
	var best_distance := INF
	for i in range(scenic_islands.size()):
		var island := _island_at(i)
		var bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", island)
		var center := _project_island_center(island)
		var distance := center.distance_to(pos)
		if bounds.has_point(pos):
			distance *= 0.25
		if distance < best_distance and distance < 96.0:
			best_distance = distance
			best_index = i
	if best_index >= 0:
		selected_index = best_index
		_refresh_island_list()
		_refresh_selected_controls()
		_refresh_warnings()


func _drag_selected_island(screen_delta: Vector2) -> void:
	var island := _selected_island()
	var profile_delta := _screen_delta_to_profile_delta(screen_delta, island)
	island["x"] = float(island.get("x", 0.0)) + profile_delta.x
	island["y"] = float(island.get("y", 0.0)) + profile_delta.y
	_on_island_data_changed()


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


func _screen_delta_to_profile_delta(screen_delta: Vector2, island: Dictionary) -> Vector2:
	var depth := clampf(float(island.get("depth", 0.5)), 0.0, 1.0)
	var layer := String(island.get("layer", "mid")).to_lower()
	var x_parallax := maxf(_editor_scenic_layer_parallax_x(layer, depth), 0.001)
	var y_parallax := maxf(_editor_scenic_anchor_parallax_y(), 0.001)
	return Vector2(
		screen_delta.x * CAMERA_MIN_ZOOM / x_parallax,
		screen_delta.y * CAMERA_MIN_ZOOM / y_parallax
	)


func _profile_anchor_from_screen(screen_pos: Vector2, island: Dictionary) -> Vector2:
	var depth := clampf(float(island.get("depth", 0.5)), 0.0, 1.0)
	var layer := String(island.get("layer", "mid")).to_lower()
	var band := String(island.get("band", "mid_sea")).to_lower()
	var x_parallax := maxf(_editor_scenic_layer_parallax_x(layer, depth), 0.001)
	var y_parallax := maxf(_editor_scenic_anchor_parallax_y(), 0.001)
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


func _editor_scenic_anchor_parallax_y() -> float:
	return 0.060 * _settings_float("vertical_exit_strength", 1.0)


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


func _project_island_center(island: Dictionary) -> Vector2:
	return renderer.call(
		"project_scenic_point",
		float(island.get("x", FLIGHT_START_POS.x)),
		FLIGHT_START_POS.y + float(island.get("y", 0.0)),
		float(island.get("depth", 0.5)),
		String(island.get("layer", "mid")),
		String(island.get("band", "mid_sea"))
	)


func _draw_preview_guides(canvas: Node2D) -> void:
	if renderer == null:
		return
	var horizon := float(renderer.call("get_horizon_y"))
	canvas.draw_line(Vector2(0.0, horizon), Vector2(VIEW_SIZE.x, horizon), Color(1.0, 0.92, 0.32, 0.88), 2.0)
	canvas.draw_line(Vector2(0.0, 0.0), Vector2(VIEW_SIZE.x, 0.0), Color(1.0, 1.0, 1.0, 0.22), 1.0)
	canvas.draw_line(Vector2(0.0, VIEW_SIZE.y), Vector2(VIEW_SIZE.x, VIEW_SIZE.y), Color(1.0, 1.0, 1.0, 0.22), 1.0)

	var player_screen := (flight_pos - camera_center) / CAMERA_MIN_ZOOM + VIEW_SIZE * 0.5
	canvas.draw_circle(player_screen, 7.0, Color(0.05, 0.05, 0.05, 0.85))
	canvas.draw_circle(player_screen, 4.0, Color(0.95, 1.0, 1.0, 0.95))

	for i in range(scenic_islands.size()):
		var island := _island_at(i)
		var bounds: Rect2 = renderer.call("get_scenic_island_projected_bounds", island)
		var alpha := float(renderer.call("get_scenic_island_visibility_alpha", island))
		if alpha <= 0.01:
			continue
		var center := _project_island_center(island)
		var color := Color(0.20, 0.95, 0.45, 0.85)
		if bounds.end.y < horizon or center.y < horizon:
			color = Color(1.0, 0.24, 0.18, 0.95)
		if i == selected_index:
			color = Color(1.0, 0.84, 0.18, 1.0)
		canvas.draw_rect(bounds, color, false, 2.0)
		canvas.draw_circle(center, 4.0, color)
		canvas.draw_string(ThemeDB.fallback_font, center + Vector2(8.0, -8.0), "%02d" % i, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14.0, color)


func _island_at(index: int) -> Dictionary:
	if index < 0 or index >= scenic_islands.size():
		return {}
	var value: Variant = scenic_islands[index]
	return value if typeof(value) == TYPE_DICTIONARY else {}


func _selected_island() -> Dictionary:
	return _island_at(selected_index)


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
