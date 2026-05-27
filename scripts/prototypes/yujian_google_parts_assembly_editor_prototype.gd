extends Node2D
class_name YujianGooglePartsAssemblyEditorPrototype

const GOOGLE_PARTS_VISUAL := preload("res://scripts/prototypes/google_parts_skeleton_visual.gd")

const ADJUSTMENT_PATH := "res://resources/flight/rider/google_parts_assembly_adjustments.json"
const VIEW_SCALE := 2.15
const HANDLE_SIZE := 12.0

const PART_SET_ROOTS := [
	"res://resources/flight/rider/google_parts_v1",
	"res://resources/flight/rider/google_parts_v2",
]
const PART_SET_LABELS := [
	"Google v1",
	"Google v2",
]

const POSES := [
	{"key": "low", "label": "低速"},
	{"key": "fast", "label": "高速"},
]

const DIRECTIONS := [
	{"key": "right", "label": "右 / 身正 / 头右", "heading": Vector2.RIGHT, "index": 0, "pos": Vector2(178.0, 330.0)},
	{"key": "up", "label": "上 / 身侧右 / 头背", "heading": Vector2.UP, "index": 2, "pos": Vector2(428.0, 330.0)},
	{"key": "left", "label": "左 / 身背 / 头左", "heading": Vector2.LEFT, "index": 4, "pos": Vector2(678.0, 330.0)},
	{"key": "down", "label": "下 / 身侧左 / 头正", "heading": Vector2.DOWN, "index": 6, "pos": Vector2(928.0, 330.0)},
]

const SLOT_DEFS := [
	{"key": "head", "label": "头"},
	{"key": "torso", "label": "躯干"},
	{"key": "upper_arm_far", "label": "远侧大臂"},
	{"key": "forearm_far", "label": "远侧小臂"},
	{"key": "hand_far", "label": "远侧手"},
	{"key": "upper_arm_near", "label": "近侧大臂"},
	{"key": "forearm_near", "label": "近侧小臂"},
	{"key": "hand_near", "label": "近侧手"},
	{"key": "thigh_far", "label": "远侧大腿"},
	{"key": "calf_far", "label": "远侧小腿"},
	{"key": "thigh_near", "label": "近侧大腿"},
	{"key": "calf_near", "label": "近侧小腿"},
]

const MATERIAL_KEYS := [
	"head_front",
	"head_side",
	"head_back",
	"torso_front",
	"torso_side",
	"torso_back",
	"upper_arm_front",
	"upper_arm_side",
	"upper_arm_back",
	"forearm_front",
	"forearm_side",
	"forearm_back",
	"hand_front",
	"hand_side",
	"hand_back",
	"thigh_front",
	"thigh_side",
	"thigh_back",
	"calf_front",
	"calf_side",
	"calf_back",
]

var visuals: Array = []
var direction_labels: Array = []
var adjustments := {}
var selected_pose := "fast"
var selected_direction := "right"
var selected_slot := "head"
var selected_part_set_index := 1
var controls_updating := false
var drag_mode := ""
var drag_handle := ""
var drag_start_mouse := Vector2.ZERO
var drag_start_offset := Vector2.ZERO
var drag_start_scale := Vector2.ONE
var drag_start_rect := Rect2()

var editor_panel: PanelContainer
var selection_border: Line2D
var resize_handles := {}
var part_set_option: OptionButton
var pose_option: OptionButton
var direction_option: OptionButton
var slot_option: OptionButton
var material_option: OptionButton
var scale_x_slider: HSlider
var scale_x_spin: SpinBox
var scale_y_slider: HSlider
var scale_y_spin: SpinBox
var offset_x_spin: SpinBox
var offset_y_spin: SpinBox
var rotation_spin: SpinBox
var flip_x_checkbox: CheckBox
var flip_y_checkbox: CheckBox
var status_label: Label


func _ready() -> void:
	_create_preview_stage()
	_create_selection_overlay()
	_load_adjustments()
	_create_editor_panel()
	_apply_visual_state()
	_refresh_controls()
	set_process(true)


func _process(_delta: float) -> void:
	_update_selection_overlay()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _create_preview_stage() -> void:
	var background := ColorRect.new()
	background.color = Color(0.045, 0.049, 0.052, 1.0)
	background.size = Vector2(1280.0, 720.0)
	add_child(background)

	for direction_data in DIRECTIONS:
		var guide := ColorRect.new()
		guide.color = Color(0.09, 0.16, 0.17, 0.32)
		guide.position = Vector2(direction_data["pos"]) + Vector2(-86.0, -126.0)
		guide.size = Vector2(172.0, 252.0)
		add_child(guide)

		var visual := GOOGLE_PARTS_VISUAL.new()
		visual.set_part_set_root(_current_part_set_root())
		visual.set_show_sword(false)
		visual.position = Vector2(direction_data["pos"])
		visual.scale = Vector2.ONE * VIEW_SCALE
		add_child(visual)
		visuals.append(visual)

		var label := Label.new()
		label.text = String(direction_data["label"])
		label.position = Vector2(direction_data["pos"]) + Vector2(-58.0, 190.0)
		label.add_theme_font_size_override("font_size", 18)
		add_child(label)
		direction_labels.append(label)


func _create_selection_overlay() -> void:
	selection_border = Line2D.new()
	selection_border.width = 2.0
	selection_border.default_color = Color(0.80, 1.0, 0.94, 0.95)
	selection_border.z_index = 120
	add_child(selection_border)

	for handle_key in ["tl", "tr", "bl", "br"]:
		var handle := ColorRect.new()
		handle.color = Color(0.80, 1.0, 0.94, 0.95)
		handle.size = Vector2(HANDLE_SIZE, HANDLE_SIZE)
		handle.z_index = 130
		add_child(handle)
		resize_handles[handle_key] = handle


func _create_editor_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	editor_panel = PanelContainer.new()
	editor_panel.position = Vector2(1018.0, 18.0)
	editor_panel.custom_minimum_size = Vector2(244.0, 684.0)
	layer.add_child(editor_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	editor_panel.add_child(root)

	var title := Label.new()
	title.text = "四向拼接"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	part_set_option = OptionButton.new()
	for i in range(PART_SET_LABELS.size()):
		part_set_option.add_item(String(PART_SET_LABELS[i]), i)
	part_set_option.item_selected.connect(Callable(self, "_on_part_set_selected"))
	root.add_child(_make_row("素材集", part_set_option))

	pose_option = OptionButton.new()
	for i in range(POSES.size()):
		pose_option.add_item(String(POSES[i]["label"]), i)
	pose_option.item_selected.connect(Callable(self, "_on_pose_selected"))
	root.add_child(_make_row("状态", pose_option))

	direction_option = OptionButton.new()
	for i in range(DIRECTIONS.size()):
		direction_option.add_item(String(DIRECTIONS[i]["label"]), i)
	direction_option.item_selected.connect(Callable(self, "_on_direction_selected"))
	root.add_child(_make_row("方向", direction_option))

	slot_option = OptionButton.new()
	for i in range(SLOT_DEFS.size()):
		slot_option.add_item(String(SLOT_DEFS[i]["label"]), i)
	slot_option.item_selected.connect(Callable(self, "_on_slot_selected"))
	root.add_child(_make_row("部位", slot_option))

	material_option = OptionButton.new()
	material_option.add_item("默认", 0)
	for i in range(MATERIAL_KEYS.size()):
		material_option.add_item(String(MATERIAL_KEYS[i]), i + 1)
	material_option.item_selected.connect(Callable(self, "_on_material_selected"))
	root.add_child(_make_row("素材", material_option))

	scale_x_slider = _make_slider(0.10, 3.00, 0.01)
	scale_x_spin = _make_spin(0.10, 3.00, 0.01)
	scale_x_slider.value_changed.connect(Callable(self, "_on_scale_x_changed"))
	scale_x_spin.value_changed.connect(Callable(self, "_on_scale_x_changed"))
	root.add_child(_make_slider_row("宽", scale_x_slider, scale_x_spin))

	scale_y_slider = _make_slider(0.10, 3.00, 0.01)
	scale_y_spin = _make_spin(0.10, 3.00, 0.01)
	scale_y_slider.value_changed.connect(Callable(self, "_on_scale_y_changed"))
	scale_y_spin.value_changed.connect(Callable(self, "_on_scale_y_changed"))
	root.add_child(_make_slider_row("高", scale_y_slider, scale_y_spin))

	offset_x_spin = _make_spin(-220.0, 220.0, 1.0)
	offset_y_spin = _make_spin(-220.0, 220.0, 1.0)
	offset_x_spin.value_changed.connect(Callable(self, "_on_offset_x_changed"))
	offset_y_spin.value_changed.connect(Callable(self, "_on_offset_y_changed"))
	root.add_child(_make_row("X", offset_x_spin))
	root.add_child(_make_row("Y", offset_y_spin))

	rotation_spin = _make_spin(-180.0, 180.0, 1.0)
	rotation_spin.value_changed.connect(Callable(self, "_on_rotation_changed"))
	root.add_child(_make_row("旋转", rotation_spin))

	flip_x_checkbox = CheckBox.new()
	flip_x_checkbox.text = "X"
	flip_x_checkbox.toggled.connect(Callable(self, "_on_flip_x_toggled"))
	flip_y_checkbox = CheckBox.new()
	flip_y_checkbox.text = "Y"
	flip_y_checkbox.toggled.connect(Callable(self, "_on_flip_y_toggled"))
	var flip_row := HBoxContainer.new()
	var flip_label := Label.new()
	flip_label.text = "翻转"
	flip_label.custom_minimum_size = Vector2(60.0, 0.0)
	flip_row.add_child(flip_label)
	flip_row.add_child(flip_x_checkbox)
	flip_row.add_child(flip_y_checkbox)
	root.add_child(flip_row)

	var button_row := HBoxContainer.new()
	var reset_slot_button := Button.new()
	reset_slot_button.text = "重置部位"
	reset_slot_button.pressed.connect(Callable(self, "_on_reset_slot_pressed"))
	button_row.add_child(reset_slot_button)
	var reset_direction_button := Button.new()
	reset_direction_button.text = "重置方向"
	reset_direction_button.pressed.connect(Callable(self, "_on_reset_direction_pressed"))
	button_row.add_child(reset_direction_button)
	root.add_child(button_row)

	var save_row := HBoxContainer.new()
	var save_button := Button.new()
	save_button.text = "保存"
	save_button.pressed.connect(Callable(self, "_on_save_pressed"))
	save_row.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "加载"
	load_button.pressed.connect(Callable(self, "_on_load_pressed"))
	save_row.add_child(load_button)
	root.add_child(save_row)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 12)
	root.add_child(status_label)


func _make_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(60.0, 0.0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _make_slider_row(label_text: String, slider: HSlider, spin: SpinBox) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(60.0, 0.0)
	row.add_child(label)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	spin.custom_minimum_size = Vector2(66.0, 0.0)
	row.add_child(spin)
	return row


func _make_slider(min_value: float, max_value: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	return slider


func _make_spin(min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(82.0, 0.0)
	return spin


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if _is_pointer_over_panel(event.position):
			return
		var handle_key := _resize_handle_at(event.position)
		if handle_key != "":
			_begin_resize(handle_key, event.position)
			get_viewport().set_input_as_handled()
			return
		var hit := _hit_test_slot(event.position)
		if not hit.is_empty():
			selected_direction = String(hit["direction"])
			selected_slot = String(hit["slot"])
			_refresh_controls()
			_begin_drag(event.position)
			get_viewport().set_input_as_handled()
	else:
		drag_mode = ""
		drag_handle = ""


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if drag_mode == "move":
		_apply_drag_move(event.position)
		get_viewport().set_input_as_handled()
	elif drag_mode == "resize":
		_apply_drag_resize(event.position)
		get_viewport().set_input_as_handled()


func _begin_drag(mouse_position: Vector2) -> void:
	drag_mode = "move"
	drag_start_mouse = mouse_position
	drag_start_offset = _offset_from_data(_current_slot_adjustment())


func _begin_resize(handle_key: String, mouse_position: Vector2) -> void:
	drag_mode = "resize"
	drag_handle = handle_key
	drag_start_mouse = mouse_position
	drag_start_rect = _selected_slot_rect()
	var data := _current_slot_adjustment()
	drag_start_scale = Vector2(float(data.get("scale_x", 1.0)), float(data.get("scale_y", 1.0)))


func _apply_drag_move(mouse_position: Vector2) -> void:
	var visual := _selected_visual()
	var visual_scale := maxf(absf(visual.scale.x), 0.001) if visual != null else VIEW_SCALE
	var delta := (mouse_position - drag_start_mouse) / visual_scale
	var data := _current_slot_adjustment()
	var offset := drag_start_offset + delta
	data["offset"] = [offset.x, offset.y]
	_apply_visual_state()
	_refresh_controls()


func _apply_drag_resize(mouse_position: Vector2) -> void:
	if drag_start_rect.size.x <= 0.001 or drag_start_rect.size.y <= 0.001:
		return
	var delta := mouse_position - drag_start_mouse
	var x_sign := -1.0 if drag_handle in ["tl", "bl"] else 1.0
	var y_sign := -1.0 if drag_handle in ["tl", "tr"] else 1.0
	var next_x := drag_start_scale.x * (1.0 + x_sign * delta.x / drag_start_rect.size.x)
	var next_y := drag_start_scale.y * (1.0 + y_sign * delta.y / drag_start_rect.size.y)
	var data := _current_slot_adjustment()
	data["scale_x"] = clampf(next_x, 0.10, 3.00)
	data["scale_y"] = clampf(next_y, 0.10, 3.00)
	_apply_visual_state()
	_refresh_controls()


func _is_pointer_over_panel(position: Vector2) -> bool:
	return editor_panel != null and editor_panel.get_global_rect().has_point(position)


func _resize_handle_at(position: Vector2) -> String:
	for handle_key in resize_handles.keys():
		var handle := resize_handles[handle_key] as ColorRect
		if handle.visible and handle.get_global_rect().has_point(position):
			return String(handle_key)
	return ""


func _hit_test_slot(position: Vector2) -> Dictionary:
	for direction_data in DIRECTIONS:
		var direction_key := String(direction_data["key"])
		var visual := visuals[_direction_index_for_key(direction_key)] as Node2D
		for i in range(SLOT_DEFS.size() - 1, -1, -1):
			var slot_key := String(SLOT_DEFS[i]["key"])
			var rect: Rect2 = visual.call("get_slot_global_rect", slot_key)
			if rect.size.x > 0.0 and rect.size.y > 0.0 and rect.has_point(position):
				return {
					"direction": direction_key,
					"slot": slot_key,
				}
	return {}


func _selected_slot_rect() -> Rect2:
	var visual := _selected_visual()
	if visual == null or not visual.has_method("get_slot_global_rect"):
		return Rect2()
	return visual.call("get_slot_global_rect", selected_slot)


func _selected_visual() -> Node2D:
	var index := _selected_direction_index()
	if index < 0 or index >= visuals.size():
		return null
	return visuals[index] as Node2D


func _update_selection_overlay() -> void:
	if selection_border == null:
		return
	var rect := _selected_slot_rect()
	var visible := rect.size.x > 1.0 and rect.size.y > 1.0
	selection_border.visible = visible
	for handle in resize_handles.values():
		(handle as ColorRect).visible = visible
	if not visible:
		return
	var p0 := rect.position
	var p1 := rect.position + Vector2(rect.size.x, 0.0)
	var p2 := rect.position + rect.size
	var p3 := rect.position + Vector2(0.0, rect.size.y)
	selection_border.points = PackedVector2Array([p0, p1, p2, p3, p0])
	_position_handle("tl", p0)
	_position_handle("tr", p1)
	_position_handle("br", p2)
	_position_handle("bl", p3)


func _position_handle(handle_key: String, center: Vector2) -> void:
	var handle := resize_handles[handle_key] as ColorRect
	handle.position = center - Vector2(HANDLE_SIZE, HANDLE_SIZE) * 0.5


func _load_adjustments() -> void:
	adjustments = {}
	var global_path := ProjectSettings.globalize_path(ADJUSTMENT_PATH)
	if FileAccess.file_exists(global_path):
		var file := FileAccess.open(global_path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				if parsed.has("part_set_root"):
					selected_part_set_index = _part_set_index_for_root(String(parsed["part_set_root"]))
				if parsed.has("poses") and typeof(parsed["poses"]) == TYPE_DICTIONARY:
					adjustments = parsed["poses"]
				elif parsed.has("directions") and typeof(parsed["directions"]) == TYPE_DICTIONARY:
					var old_directions: Dictionary = parsed["directions"]
					adjustments = {
						"low": old_directions.duplicate(true),
						"fast": old_directions.duplicate(true),
					}
				else:
					adjustments = _migrate_flat_adjustments(parsed)
	_ensure_adjustments()


func _migrate_flat_adjustments(source: Dictionary) -> Dictionary:
	for direction_data in DIRECTIONS:
		if source.has(String(direction_data["key"])):
			return {
				"low": source.duplicate(true),
				"fast": source.duplicate(true),
			}
	return {}


func _save_adjustments() -> bool:
	_ensure_adjustments()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources/flight/rider"))
	var file := FileAccess.open(ProjectSettings.globalize_path(ADJUSTMENT_PATH), FileAccess.WRITE)
	if file == null:
		return false
	var payload := {
		"part_set_root": _current_part_set_root(),
		"poses": adjustments,
	}
	file.store_string(JSON.stringify(payload, "\t"))
	return true


func _ensure_adjustments() -> void:
	if typeof(adjustments) != TYPE_DICTIONARY:
		adjustments = {}
	for pose_data in POSES:
		var pose_key := String(pose_data["key"])
		if not adjustments.has(pose_key) or typeof(adjustments[pose_key]) != TYPE_DICTIONARY:
			adjustments[pose_key] = {}
		var pose_adjustments: Dictionary = adjustments[pose_key]
		for direction_data in DIRECTIONS:
			var direction_key := String(direction_data["key"])
			if not pose_adjustments.has(direction_key) or typeof(pose_adjustments[direction_key]) != TYPE_DICTIONARY:
				pose_adjustments[direction_key] = {}
			var direction_adjustments: Dictionary = pose_adjustments[direction_key]
			for slot_data in SLOT_DEFS:
				var slot_key := String(slot_data["key"])
				if not direction_adjustments.has(slot_key) or typeof(direction_adjustments[slot_key]) != TYPE_DICTIONARY:
					direction_adjustments[slot_key] = _default_slot_adjustment()
				else:
					_normalize_slot_adjustment(direction_adjustments[slot_key])


func _normalize_slot_adjustment(data: Dictionary) -> void:
	if not data.has("texture_key"):
		data["texture_key"] = ""
	var legacy_scale := float(data.get("scale", 1.0))
	if not data.has("scale"):
		data["scale"] = 1.0
	if not data.has("scale_x"):
		data["scale_x"] = legacy_scale
	if not data.has("scale_y"):
		data["scale_y"] = legacy_scale
	if not data.has("offset"):
		data["offset"] = [0.0, 0.0]
	if not data.has("rotation_deg"):
		data["rotation_deg"] = 0.0
	if not data.has("flip_x"):
		data["flip_x"] = false
	if not data.has("flip_y"):
		data["flip_y"] = false


func _default_slot_adjustment() -> Dictionary:
	return {
		"texture_key": "",
		"scale": 1.0,
		"scale_x": 1.0,
		"scale_y": 1.0,
		"offset": [0.0, 0.0],
		"rotation_deg": 0.0,
		"flip_x": false,
		"flip_y": false,
	}


func _current_slot_adjustment() -> Dictionary:
	_ensure_adjustments()
	return adjustments[selected_pose][selected_direction][selected_slot]


func _current_part_set_root() -> String:
	return String(PART_SET_ROOTS[clampi(selected_part_set_index, 0, PART_SET_ROOTS.size() - 1)])


func _part_set_index_for_root(root_path: String) -> int:
	for i in range(PART_SET_ROOTS.size()):
		if String(PART_SET_ROOTS[i]) == root_path:
			return i
	return 0


func _selected_pose_index() -> int:
	for i in range(POSES.size()):
		if String(POSES[i]["key"]) == selected_pose:
			return i
	return 0


func _selected_direction_index() -> int:
	return _direction_index_for_key(selected_direction)


func _direction_index_for_key(direction_key: String) -> int:
	for i in range(DIRECTIONS.size()):
		if String(DIRECTIONS[i]["key"]) == direction_key:
			return i
	return 0


func _selected_slot_index() -> int:
	for i in range(SLOT_DEFS.size()):
		if String(SLOT_DEFS[i]["key"]) == selected_slot:
			return i
	return 0


func _selected_material_index(texture_key: String) -> int:
	if texture_key == "":
		return 0
	var found := MATERIAL_KEYS.find(texture_key)
	return found + 1 if found >= 0 else 0


func _apply_visual_state() -> void:
	_ensure_adjustments()
	for i in range(visuals.size()):
		var visual := visuals[i] as Node2D
		var direction_data: Dictionary = DIRECTIONS[i]
		var heading: Vector2 = direction_data["heading"]
		if visual.has_method("set_part_set_root"):
			visual.call("set_part_set_root", _current_part_set_root())
		if visual.has_method("set_slot_adjustments"):
			visual.call("set_slot_adjustments", adjustments)
		var pose_params := _pose_params_for_heading(heading)
		visual.call(
			"set_flight_pose",
			int(direction_data["index"]),
			heading,
			pose_params["velocity"],
			pose_params["boost"],
			0.0,
			0.0,
			pose_params["throttle"],
			0.016
		)
	for i in range(direction_labels.size()):
		var label := direction_labels[i] as Label
		var direction_key := String(DIRECTIONS[i]["key"])
		label.modulate = Color(0.78, 1.0, 0.96, 1.0) if direction_key == selected_direction else Color(0.72, 0.78, 0.78, 0.78)
	_update_selection_overlay()


func _pose_params_for_heading(heading: Vector2) -> Dictionary:
	if selected_pose == "low":
		return {
			"velocity": heading * 60.0,
			"boost": 0.0,
			"throttle": 0.0,
		}
	return {
		"velocity": heading * 1650.0,
		"boost": 0.42,
		"throttle": 0.85,
	}


func _refresh_controls(extra_message := "") -> void:
	if part_set_option == null:
		return
	var data := _current_slot_adjustment()
	controls_updating = true
	part_set_option.select(clampi(selected_part_set_index, 0, PART_SET_ROOTS.size() - 1))
	pose_option.select(_selected_pose_index())
	direction_option.select(_selected_direction_index())
	slot_option.select(_selected_slot_index())
	material_option.select(_selected_material_index(String(data.get("texture_key", ""))))
	var scale_x_value := clampf(float(data.get("scale_x", 1.0)), 0.10, 3.00)
	var scale_y_value := clampf(float(data.get("scale_y", 1.0)), 0.10, 3.00)
	scale_x_slider.value = scale_x_value
	scale_x_spin.value = scale_x_value
	scale_y_slider.value = scale_y_value
	scale_y_spin.value = scale_y_value
	var offset := _offset_from_data(data)
	offset_x_spin.value = offset.x
	offset_y_spin.value = offset.y
	rotation_spin.value = float(data.get("rotation_deg", 0.0))
	flip_x_checkbox.button_pressed = bool(data.get("flip_x", false))
	flip_y_checkbox.button_pressed = bool(data.get("flip_y", false))
	controls_updating = false
	_update_status(extra_message)
	_update_selection_overlay()


func _offset_from_data(data: Dictionary) -> Vector2:
	var raw_offset: Variant = data.get("offset", [0.0, 0.0])
	if typeof(raw_offset) == TYPE_ARRAY and raw_offset.size() >= 2:
		return Vector2(float(raw_offset[0]), float(raw_offset[1]))
	if typeof(raw_offset) == TYPE_VECTOR2:
		return raw_offset
	return Vector2.ZERO


func _update_status(extra_message := "") -> void:
	if status_label == null:
		return
	var data := _current_slot_adjustment()
	var offset := _offset_from_data(data)
	status_label.text = "%s / %s / %s\n素材 %s\n缩放 %.2f, %.2f  偏移 %.0f, %.0f  旋转 %.0f" % [
		String(POSES[_selected_pose_index()]["label"]),
		String(DIRECTIONS[_selected_direction_index()]["label"]),
		String(SLOT_DEFS[_selected_slot_index()]["label"]),
		String(data.get("texture_key", "默认")) if String(data.get("texture_key", "")) != "" else "默认",
		float(data.get("scale_x", 1.0)),
		float(data.get("scale_y", 1.0)),
		offset.x,
		offset.y,
		float(data.get("rotation_deg", 0.0)),
	]
	if extra_message != "":
		status_label.text += "\n%s" % extra_message


func _set_texture_key(texture_key: String) -> void:
	var data := _current_slot_adjustment()
	data["texture_key"] = texture_key
	_apply_visual_state()
	_update_status()


func _set_scale_x(value: float) -> void:
	var data := _current_slot_adjustment()
	data["scale_x"] = clampf(value, 0.10, 3.00)
	_apply_visual_state()
	_update_status()


func _set_scale_y(value: float) -> void:
	var data := _current_slot_adjustment()
	data["scale_y"] = clampf(value, 0.10, 3.00)
	_apply_visual_state()
	_update_status()


func _on_part_set_selected(index: int) -> void:
	if controls_updating:
		return
	selected_part_set_index = clampi(index, 0, PART_SET_ROOTS.size() - 1)
	_apply_visual_state()
	_refresh_controls()


func _on_pose_selected(index: int) -> void:
	if controls_updating:
		return
	selected_pose = String(POSES[clampi(index, 0, POSES.size() - 1)]["key"])
	_apply_visual_state()
	_refresh_controls()


func _on_direction_selected(index: int) -> void:
	if controls_updating:
		return
	selected_direction = String(DIRECTIONS[clampi(index, 0, DIRECTIONS.size() - 1)]["key"])
	_apply_visual_state()
	_refresh_controls()


func _on_slot_selected(index: int) -> void:
	if controls_updating:
		return
	selected_slot = String(SLOT_DEFS[clampi(index, 0, SLOT_DEFS.size() - 1)]["key"])
	_refresh_controls()


func _on_material_selected(index: int) -> void:
	if controls_updating:
		return
	var texture_key := ""
	if index > 0:
		texture_key = String(MATERIAL_KEYS[clampi(index - 1, 0, MATERIAL_KEYS.size() - 1)])
	_set_texture_key(texture_key)
	_refresh_controls()


func _on_scale_x_changed(value: float) -> void:
	if controls_updating:
		return
	_set_scale_x(value)
	_refresh_controls()


func _on_scale_y_changed(value: float) -> void:
	if controls_updating:
		return
	_set_scale_y(value)
	_refresh_controls()


func _on_offset_x_changed(value: float) -> void:
	if controls_updating:
		return
	var data := _current_slot_adjustment()
	var offset := _offset_from_data(data)
	data["offset"] = [value, offset.y]
	_apply_visual_state()
	_update_status()


func _on_offset_y_changed(value: float) -> void:
	if controls_updating:
		return
	var data := _current_slot_adjustment()
	var offset := _offset_from_data(data)
	data["offset"] = [offset.x, value]
	_apply_visual_state()
	_update_status()


func _on_rotation_changed(value: float) -> void:
	if controls_updating:
		return
	var data := _current_slot_adjustment()
	data["rotation_deg"] = value
	_apply_visual_state()
	_update_status()


func _on_flip_x_toggled(pressed: bool) -> void:
	if controls_updating:
		return
	var data := _current_slot_adjustment()
	data["flip_x"] = pressed
	_apply_visual_state()
	_update_status()


func _on_flip_y_toggled(pressed: bool) -> void:
	if controls_updating:
		return
	var data := _current_slot_adjustment()
	data["flip_y"] = pressed
	_apply_visual_state()
	_update_status()


func _on_reset_slot_pressed() -> void:
	adjustments[selected_pose][selected_direction][selected_slot] = _default_slot_adjustment()
	_apply_visual_state()
	_refresh_controls("已重置当前部位")


func _on_reset_direction_pressed() -> void:
	adjustments[selected_pose][selected_direction] = {}
	for slot_data in SLOT_DEFS:
		adjustments[selected_pose][selected_direction][String(slot_data["key"])] = _default_slot_adjustment()
	_apply_visual_state()
	_refresh_controls("已重置当前状态的当前方向")


func _on_save_pressed() -> void:
	if _save_adjustments():
		_refresh_controls("已保存")
	else:
		_refresh_controls("保存失败")


func _on_load_pressed() -> void:
	_load_adjustments()
	_apply_visual_state()
	_refresh_controls("已加载")
