extends Node2D

const MODEL_VISUAL_SCRIPT := preload("res://scripts/prototypes/yujian_model_to_2d_flight_visual.gd")
const DEFAULT_POSE_SAVE_PATH := "res://resources/flight/yujian_3d_model_pose_overrides.json"
const DEFAULT_MODEL_PATH := "res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX"
const POSE_NAMES := ["yujian_low", "yujian_boost", "yujian_turn_left", "yujian_turn_right"]
const POSE_LABELS := ["低速站剑", "高速前压", "左转回切", "右转回切"]
const BASE_POSE_T_POSE := "calibrated_t_pose"
const BASE_POSE_IMPORTED := "imported_pose"
const PREVIEW_MODE_EDIT := "edit_base"
const PREVIEW_MODE_FLIGHT := "flight_state"
const JOINT_PICK_RADIUS := 18.0
const JOINT_LINE_PAIRS := [
	["head", "neck"],
	["neck", "chest"],
	["chest", "pelvis"],
	["chest", "left_shoulder"],
	["left_shoulder", "left_elbow"],
	["left_elbow", "left_wrist"],
	["chest", "right_shoulder"],
	["right_shoulder", "right_elbow"],
	["right_elbow", "right_wrist"],
	["pelvis", "left_hip"],
	["left_hip", "left_knee"],
	["left_knee", "left_ankle"],
	["pelvis", "right_hip"],
	["right_hip", "right_knee"],
	["right_knee", "right_ankle"],
]
const DRAG_HANDLE_CONFIG := {
	"head": {
		"joint": "head",
		"label": "头",
		"bones": ["Bip001 Neck", "Bip001 Spine1", "Bip001 Spine"],
	},
	"chest": {
		"joint": "chest",
		"label": "胸",
		"bones": ["Bip001 Spine1", "Bip001 Spine", "Bip001 Pelvis"],
	},
	"left_elbow": {
		"joint": "left_elbow",
		"label": "左肘",
		"bones": ["Bip001 L UpperArm", "Bip001 L Clavicle"],
	},
	"left_wrist": {
		"joint": "left_wrist",
		"label": "左腕",
		"bones": ["Bip001 L Forearm", "Bip001 L UpperArm", "Bip001 L Clavicle"],
	},
	"right_elbow": {
		"joint": "right_elbow",
		"label": "右肘",
		"bones": ["Bip001 R UpperArm", "Bip001 R Clavicle"],
	},
	"right_wrist": {
		"joint": "right_wrist",
		"label": "右腕",
		"bones": ["Bip001 R Forearm", "Bip001 R UpperArm", "Bip001 R Clavicle"],
	},
	"left_knee": {
		"joint": "left_knee",
		"label": "左膝",
		"bones": ["Bip001 L Thigh"],
	},
	"left_ankle": {
		"joint": "left_ankle",
		"label": "左踝",
		"bones": ["Bip001 L Calf", "Bip001 L Thigh"],
	},
	"right_knee": {
		"joint": "right_knee",
		"label": "右膝",
		"bones": ["Bip001 R Thigh"],
	},
	"right_ankle": {
		"joint": "right_ankle",
		"label": "右踝",
		"bones": ["Bip001 R Calf", "Bip001 R Thigh"],
	},
}
const CORE_BONE_KEYWORDS := [
	"pelvis",
	"spine",
	"neck",
	"head",
	"clavicle",
	"upperarm",
	"forearm",
	"hand",
	"thigh",
	"calf",
	"foot",
]
const SECONDARY_BONE_KEYWORDS := ["bone_hair", "bone_xiuzi", "bone_piaodai", "bone_weibo", "bone_shengzi", "bone_qunbai"]

@export_file("*.json") var pose_save_path := DEFAULT_POSE_SAVE_PATH
@export_file("*.tscn", "*.scn", "*.glb", "*.gltf", "*.fbx") var model_path := DEFAULT_MODEL_PATH
@export_range(0.2, 2.0, 0.01) var preview_root_scale := 1.0

var model_visual: Node2D
var editor_layer: CanvasLayer
var editor_panel: PanelContainer
var pose_option: OptionButton
var preview_mode_option: OptionButton
var base_pose_option: OptionButton
var bone_option: OptionButton
var rotation_sliders: Array[HSlider] = []
var rotation_spins: Array[SpinBox] = []
var selected_bone_label: Label
var status_label: Label

var pose_data := {}
var current_pose_name := "yujian_low"
var bone_names: Array[String] = []
var current_bone_name := ""
var syncing_controls := false
var preview_flight_state := false
var use_t_pose_base := true
var active_drag_handle := ""
var active_drag_target := Vector2.ZERO
var solving_drag := false


func _ready() -> void:
	_initialize_empty_pose_data()
	_create_visual()
	_create_editor_panel()
	call_deferred("_finish_setup")
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.58, 0.68, 0.68, 1.0))
	draw_line(Vector2(0.0, 430.0), Vector2(viewport_size.x, 430.0), Color(0.77, 0.88, 0.88, 0.22), 2.0)
	draw_line(Vector2(420.0, 0.0), Vector2(420.0, viewport_size.y), Color(0.77, 0.88, 0.88, 0.18), 1.0)
	_draw_joint_overlay()


func _finish_setup() -> void:
	_load_pose_file()
	_refresh_bone_list()
	_apply_current_pose_preview()
	_sync_rotation_controls_from_selected_bone()


func _create_visual() -> void:
	model_visual = MODEL_VISUAL_SCRIPT.new()
	model_visual.name = "EditableModelTo2DFlightVisual"
	model_visual.set("model_path", model_path)
	model_visual.set("sprite_texture_scale", 0.74)
	model_visual.set("camera_size", 6.2)
	model_visual.set("enable_bone_pose", true)
	model_visual.position = Vector2(420.0, 430.0)
	model_visual.scale = Vector2.ONE * preview_root_scale
	add_child(model_visual)
	if model_visual.has_method("set_neutral_preview_enabled"):
		model_visual.call("set_neutral_preview_enabled", true)
	if model_visual.has_method("set_neutral_preview_t_pose_enabled"):
		model_visual.call("set_neutral_preview_t_pose_enabled", use_t_pose_base)
	if model_visual.has_method("set_manual_pose_enabled"):
		model_visual.call("set_manual_pose_enabled", true)


func _create_editor_panel() -> void:
	editor_layer = CanvasLayer.new()
	editor_layer.name = "YujianModelPoseEditorLayer"
	editor_layer.layer = 94
	add_child(editor_layer)

	editor_panel = PanelContainer.new()
	editor_panel.name = "YujianModelPoseEditorPanel"
	editor_panel.anchor_left = 1.0
	editor_panel.anchor_top = 0.0
	editor_panel.anchor_right = 1.0
	editor_panel.anchor_bottom = 1.0
	editor_panel.offset_left = -430.0
	editor_panel.offset_right = -18.0
	editor_panel.offset_top = 24.0
	editor_panel.offset_bottom = -24.0
	editor_layer.add_child(editor_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	editor_panel.add_child(root)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	root.add_child(title_row)

	var title := Label.new()
	title.text = "御剑 3D 骨骼 Pose 编辑"
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var save_button := Button.new()
	save_button.text = "保存"
	save_button.pressed.connect(Callable(self, "_on_save_pressed"))
	title_row.add_child(save_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	pose_option = OptionButton.new()
	for index in range(POSE_NAMES.size()):
		pose_option.add_item(String(POSE_LABELS[index]), index)
	pose_option.item_selected.connect(Callable(self, "_on_pose_selected"))
	content.add_child(_make_row("姿态", pose_option))

	preview_mode_option = OptionButton.new()
	preview_mode_option.add_item("展开编辑", 0)
	preview_mode_option.add_item("飞行预览", 1)
	preview_mode_option.select(0)
	preview_mode_option.item_selected.connect(Callable(self, "_on_preview_mode_selected"))
	content.add_child(_make_row("预览", preview_mode_option))

	base_pose_option = OptionButton.new()
	base_pose_option.add_item("校准 T-Pose", 0)
	base_pose_option.add_item("导入姿态", 1)
	base_pose_option.select(0)
	base_pose_option.item_selected.connect(Callable(self, "_on_base_pose_selected"))
	content.add_child(_make_row("基准", base_pose_option))

	bone_option = OptionButton.new()
	bone_option.item_selected.connect(Callable(self, "_on_bone_selected"))
	content.add_child(_make_row("骨骼", bone_option))

	selected_bone_label = Label.new()
	selected_bone_label.text = "骨骼: -"
	selected_bone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_bone_label.add_theme_font_size_override("font_size", 12)
	content.add_child(selected_bone_label)

	for axis_index in range(3):
		var slider := _make_slider(-180.0, 180.0, 1.0)
		var spin := _make_spin(-180.0, 180.0, 1.0)
		rotation_sliders.append(slider)
		rotation_spins.append(spin)
		slider.value_changed.connect(Callable(self, "_on_rotation_axis_changed").bind(axis_index))
		spin.value_changed.connect(Callable(self, "_on_rotation_axis_changed").bind(axis_index))
		content.add_child(_make_slider_row(["X", "Y", "Z"][axis_index], slider, spin))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	content.add_child(button_row)

	var reset_bone_button := Button.new()
	reset_bone_button.text = "重置骨骼"
	reset_bone_button.pressed.connect(Callable(self, "_on_reset_bone_pressed"))
	button_row.add_child(reset_bone_button)

	var clear_pose_button := Button.new()
	clear_pose_button.text = "清空姿态"
	clear_pose_button.pressed.connect(Callable(self, "_on_clear_pose_pressed"))
	button_row.add_child(clear_pose_button)

	var reload_button := Button.new()
	reload_button.text = "重载"
	reload_button.pressed.connect(Callable(self, "_on_reload_pressed"))
	button_row.add_child(reload_button)

	var help := Label.new()
	help.text = "调法: 直接拖角色上的亮点摆大形；滑杆只做选中骨骼的细调。展开编辑负责摆骨，飞行预览负责检查速度/转向姿态。"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 12)
	content.add_child(help)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 12)
	content.add_child(status_label)


func _make_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(64.0, 0.0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _make_slider_row(label_text: String, slider: HSlider, spin: SpinBox) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(64.0, 0.0)
	row.add_child(label)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	spin.custom_minimum_size = Vector2(82.0, 0.0)
	row.add_child(spin)
	return row


func _make_slider(min_value: float, max_value: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.allow_lesser = true
	slider.allow_greater = true
	return slider


func _make_spin(min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.allow_lesser = true
	spin.allow_greater = true
	return spin


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			if _is_point_inside_editor_panel(mouse_event.position):
				return
			var handle_key := _nearest_drag_handle(mouse_event.position)
			if handle_key == "":
				return
			active_drag_handle = handle_key
			active_drag_target = mouse_event.position
			_select_primary_bone_for_handle(handle_key)
			_solve_drag_handle(handle_key, active_drag_target)
			get_viewport().set_input_as_handled()
		elif active_drag_handle != "":
			active_drag_handle = ""
			get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and active_drag_handle != "":
		var motion_event := event as InputEventMouseMotion
		active_drag_target = motion_event.position
		_solve_drag_handle(active_drag_handle, active_drag_target)
		get_viewport().set_input_as_handled()


func _is_point_inside_editor_panel(point: Vector2) -> bool:
	return editor_panel != null and editor_panel.get_global_rect().has_point(point)


func _initialize_empty_pose_data() -> void:
	pose_data.clear()
	for pose_name in POSE_NAMES:
		pose_data[String(pose_name)] = {"bones": {}}


func _refresh_bone_list() -> void:
	bone_names.clear()
	if model_visual != null and model_visual.has_method("get_skeleton_bone_names"):
		var loaded_names: Array = model_visual.call("get_skeleton_bone_names")
		bone_names = _sorted_bone_names(loaded_names)
	bone_option.clear()
	for index in range(bone_names.size()):
		bone_option.add_item(_display_bone_name(bone_names[index]), index)
	if not bone_names.is_empty():
		current_bone_name = bone_names[0]
		bone_option.select(0)
	_update_selected_bone_label()


func _sorted_bone_names(source_names: Array) -> Array[String]:
	var core: Array[String] = []
	var secondary: Array[String] = []
	var other: Array[String] = []
	for name_variant in source_names:
		var bone_name := String(name_variant)
		if _matches_keywords(bone_name, CORE_BONE_KEYWORDS):
			core.append(bone_name)
		elif _matches_keywords(bone_name, SECONDARY_BONE_KEYWORDS):
			secondary.append(bone_name)
		else:
			other.append(bone_name)
	core.sort()
	secondary.sort()
	other.sort()
	return core + secondary + other


func _matches_keywords(text: String, keywords: Array) -> bool:
	var lower := text.to_lower()
	for keyword_variant in keywords:
		if lower.contains(String(keyword_variant).to_lower()):
			return true
	return false


func _display_bone_name(bone_name: String) -> String:
	return bone_name.replace("Bip001 ", "")


func _draw_joint_overlay() -> void:
	var joint_points := _editor_joint_points()
	if joint_points.is_empty():
		return
	for pair in JOINT_LINE_PAIRS:
		var start_key := String(pair[0])
		var end_key := String(pair[1])
		if not joint_points.has(start_key) or not joint_points.has(end_key):
			continue
		var start_position := _joint_position(joint_points[start_key])
		var end_position := _joint_position(joint_points[end_key])
		draw_line(start_position, end_position, Color(0.12, 0.18, 0.18, 0.78), 6.0)
		draw_line(start_position, end_position, Color(0.77, 1.0, 0.98, 0.72), 2.0)
	for joint_key_variant in joint_points.keys():
		var joint_key := String(joint_key_variant)
		var position := _joint_position(joint_points[joint_key_variant])
		var draggable := DRAG_HANDLE_CONFIG.has(joint_key)
		var radius := 8.5 if draggable else 5.0
		var fill := Color(1.0, 0.82, 0.36, 0.96) if draggable else Color(0.64, 0.92, 0.92, 0.72)
		var outline := Color(0.05, 0.08, 0.08, 0.9)
		if joint_key == active_drag_handle:
			radius = 10.5
			fill = Color(0.55, 1.0, 1.0, 1.0)
		draw_circle(position, radius + 2.0, outline)
		draw_circle(position, radius, fill)
		if draggable:
			var label := String(Dictionary(DRAG_HANDLE_CONFIG[joint_key]).get("label", joint_key))
			draw_string(ThemeDB.fallback_font, position + Vector2(9.0, -8.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11.0, Color(0.06, 0.09, 0.09, 0.88))
	if active_drag_handle != "":
		draw_circle(active_drag_target, 4.0, Color(0.18, 1.0, 1.0, 0.9))


func _editor_joint_points() -> Dictionary:
	if model_visual == null or not model_visual.has_method("get_editor_joint_points"):
		return {}
	var points: Variant = model_visual.call("get_editor_joint_points")
	return points if points is Dictionary else {}


func _joint_position(value: Variant) -> Vector2:
	if value is Dictionary:
		var dict_value: Dictionary = value
		var position: Variant = dict_value.get("position", Vector2.ZERO)
		if position is Vector2:
			return position
	return Vector2.ZERO


func _nearest_drag_handle(point: Vector2) -> String:
	var joint_points := _editor_joint_points()
	var best_key := ""
	var best_distance_sq := JOINT_PICK_RADIUS * JOINT_PICK_RADIUS
	for handle_key_variant in DRAG_HANDLE_CONFIG.keys():
		var handle_key := String(handle_key_variant)
		var config: Dictionary = DRAG_HANDLE_CONFIG[handle_key_variant]
		var joint_key := String(config.get("joint", handle_key))
		if not joint_points.has(joint_key):
			continue
		var distance_sq := _joint_position(joint_points[joint_key]).distance_squared_to(point)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_key = handle_key
	return best_key


func _on_pose_selected(index: int) -> void:
	var safe_index := clampi(index, 0, POSE_NAMES.size() - 1)
	current_pose_name = String(POSE_NAMES[safe_index])
	if pose_option != null:
		pose_option.select(safe_index)
	_apply_current_pose_preview()
	_sync_rotation_controls_from_selected_bone()


func _on_preview_mode_selected(index: int) -> void:
	preview_flight_state = index == 1
	_sync_preview_mode_option()
	_apply_current_pose_preview()
	_sync_rotation_controls_from_selected_bone()
	_set_status("预览模式: %s" % _current_preview_mode_label())


func _on_base_pose_selected(index: int) -> void:
	use_t_pose_base = index == 0
	_sync_base_pose_option()
	_apply_current_pose_preview()
	_sync_rotation_controls_from_selected_bone()
	_set_status("基准姿态: %s" % _current_base_pose_label())


func _on_bone_selected(index: int) -> void:
	if index < 0 or index >= bone_names.size():
		return
	current_bone_name = bone_names[index]
	_update_selected_bone_label()
	_sync_rotation_controls_from_selected_bone()


func _on_rotation_axis_changed(value: float, axis_index: int) -> void:
	if syncing_controls or current_bone_name == "":
		return
	var rotation := _selected_bone_rotation()
	rotation[axis_index] = value
	_set_selected_bone_rotation(rotation)
	_sync_rotation_controls_from_selected_bone()
	_apply_current_pose_preview()


func _on_reset_bone_pressed() -> void:
	if current_bone_name == "":
		return
	var bones := _current_pose_bones()
	bones.erase(current_bone_name)
	_sync_rotation_controls_from_selected_bone()
	_apply_current_pose_preview()
	_set_status("已重置骨骼: %s" % _display_bone_name(current_bone_name))


func _on_clear_pose_pressed() -> void:
	pose_data[current_pose_name] = {"bones": {}}
	_sync_rotation_controls_from_selected_bone()
	_apply_current_pose_preview()
	_set_status("已清空姿态: %s" % current_pose_name)


func _on_reload_pressed() -> void:
	_load_pose_file()
	_apply_current_pose_preview()
	_sync_rotation_controls_from_selected_bone()


func _on_save_pressed() -> void:
	_save_pose_file()


func _solve_drag_handle(handle_key: String, target_position: Vector2) -> void:
	if solving_drag or not DRAG_HANDLE_CONFIG.has(handle_key):
		return
	solving_drag = true
	var config: Dictionary = DRAG_HANDLE_CONFIG[handle_key]
	var joint_key := String(config.get("joint", handle_key))
	var chain: Array = config.get("bones", [])
	var best_distance := _joint_distance_squared(joint_key, target_position)
	for step in [16.0, 9.0, 5.0, 2.5, 1.0]:
		var improved := true
		var pass_count := 0
		while improved and pass_count < 2:
			improved = false
			pass_count += 1
			for bone_name_variant in chain:
				var bone_name := String(bone_name_variant)
				if not bone_names.has(bone_name):
					continue
				for axis_index in range(3):
					var current_rotation := _bone_rotation(bone_name)
					var best_rotation := current_rotation
					for sign in [-1.0, 1.0]:
						var candidate := current_rotation
						candidate[axis_index] = clampf(candidate[axis_index] + step * sign, -180.0, 180.0)
						_set_bone_rotation(bone_name, candidate)
						_apply_current_pose_preview()
						var candidate_distance := _joint_distance_squared(joint_key, target_position)
						if candidate_distance + 0.01 < best_distance:
							best_distance = candidate_distance
							best_rotation = candidate
							improved = true
					_set_bone_rotation(bone_name, best_rotation)
					_apply_current_pose_preview()
	_sync_rotation_controls_from_selected_bone()
	solving_drag = false
	queue_redraw()


func _joint_distance_squared(joint_key: String, target_position: Vector2) -> float:
	var joint_points := _editor_joint_points()
	if not joint_points.has(joint_key):
		return INF
	return _joint_position(joint_points[joint_key]).distance_squared_to(target_position)


func _bone_rotation(bone_name: String) -> Vector3:
	var bones := _current_pose_bones()
	return _coerce_rotation_degrees(bones.get(bone_name, [0.0, 0.0, 0.0]))


func _set_bone_rotation(bone_name: String, rotation: Vector3) -> void:
	var bones := _current_pose_bones()
	if rotation.length() <= 0.001:
		bones.erase(bone_name)
	else:
		bones[bone_name] = [snappedf(rotation.x, 0.001), snappedf(rotation.y, 0.001), snappedf(rotation.z, 0.001)]


func _select_primary_bone_for_handle(handle_key: String) -> void:
	if not DRAG_HANDLE_CONFIG.has(handle_key):
		return
	var config: Dictionary = DRAG_HANDLE_CONFIG[handle_key]
	var chain: Array = config.get("bones", [])
	for bone_name_variant in chain:
		var bone_name := String(bone_name_variant)
		var bone_index := bone_names.find(bone_name)
		if bone_index < 0:
			continue
		current_bone_name = bone_name
		if bone_option != null:
			bone_option.select(bone_index)
		_update_selected_bone_label()
		_sync_rotation_controls_from_selected_bone()
		return


func _selected_bone_rotation() -> Vector3:
	var bones := _current_pose_bones()
	return _coerce_rotation_degrees(bones.get(current_bone_name, [0.0, 0.0, 0.0]))


func _set_selected_bone_rotation(rotation: Vector3) -> void:
	var bones := _current_pose_bones()
	if rotation.length() <= 0.001:
		bones.erase(current_bone_name)
	else:
		bones[current_bone_name] = [snappedf(rotation.x, 0.001), snappedf(rotation.y, 0.001), snappedf(rotation.z, 0.001)]


func _current_pose_bones() -> Dictionary:
	if not pose_data.has(current_pose_name) or not (pose_data[current_pose_name] is Dictionary):
		pose_data[current_pose_name] = {"bones": {}}
	var pose_entry: Dictionary = pose_data[current_pose_name]
	if not pose_entry.has("bones") or not (pose_entry["bones"] is Dictionary):
		pose_entry["bones"] = {}
	return pose_entry["bones"]


func _sync_rotation_controls_from_selected_bone() -> void:
	syncing_controls = true
	var rotation := _selected_bone_rotation()
	for axis_index in range(3):
		rotation_sliders[axis_index].set_value_no_signal(rotation[axis_index])
		rotation_spins[axis_index].set_value_no_signal(rotation[axis_index])
	syncing_controls = false
	_update_selected_bone_label()


func _update_selected_bone_label() -> void:
	if selected_bone_label == null:
		return
	selected_bone_label.text = "骨骼: %s" % (current_bone_name if current_bone_name != "" else "-")


func _apply_current_pose_preview() -> void:
	if model_visual == null:
		return
	if model_visual.has_method("set_neutral_preview_t_pose_enabled"):
		model_visual.call("set_neutral_preview_t_pose_enabled", use_t_pose_base)
	if model_visual.has_method("set_manual_pose_enabled"):
		model_visual.call("set_manual_pose_enabled", true)
	if model_visual.has_method("set_manual_bone_pose_degrees"):
		model_visual.call("set_manual_bone_pose_degrees", _current_pose_bones())
	if model_visual.has_method("set_neutral_preview_enabled"):
		model_visual.call("set_neutral_preview_enabled", not preview_flight_state)
	if preview_flight_state:
		_apply_preview_state_to_visual(_preview_state_for_pose(current_pose_name))


func _apply_preview_state_to_visual(state: Dictionary) -> void:
	if model_visual.has_method("set_flight_context"):
		model_visual.call(
			"set_flight_context",
			float(state["turn_lean"]),
			float(state["carve_dir"]),
			float(state["switch_dir"]),
			float(state["switch"])
		)
	if model_visual.has_method("set_flight_pose"):
		model_visual.call(
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


func _preview_state_for_pose(pose_name: String) -> Dictionary:
	match pose_name:
		"yujian_boost":
			return {
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
			}
		"yujian_turn_left":
			return {
				"heading": Vector2(0.72, -0.69).normalized(),
				"velocity": Vector2(1500.0, -1420.0),
				"boost": 0.72,
				"turn": 0.75,
				"carve": 0.78,
				"throttle": 1.0,
				"turn_lean": -0.82,
				"carve_dir": -1.0,
				"switch_dir": -1.0,
				"switch": 0.65,
			}
		"yujian_turn_right":
			return {
				"heading": Vector2(0.72, 0.69).normalized(),
				"velocity": Vector2(1500.0, 1420.0),
				"boost": 0.72,
				"turn": 0.75,
				"carve": 0.78,
				"throttle": 1.0,
				"turn_lean": 0.82,
				"carve_dir": 1.0,
				"switch_dir": 1.0,
				"switch": 0.65,
			}
		_:
			return {
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
			}


func _load_pose_file() -> void:
	_initialize_empty_pose_data()
	if not FileAccess.file_exists(pose_save_path):
		_set_status("未找到姿态文件，当前为空: %s" % pose_save_path)
		return
	var text := FileAccess.get_file_as_string(pose_save_path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_set_status("姿态文件格式错误: %s" % pose_save_path)
		return
	var data: Dictionary = parsed
	preview_flight_state = String(data.get("editor_preview_mode", PREVIEW_MODE_EDIT)) == PREVIEW_MODE_FLIGHT
	_sync_preview_mode_option()
	use_t_pose_base = String(data.get("editor_base_pose", BASE_POSE_T_POSE)) != BASE_POSE_IMPORTED
	_sync_base_pose_option()
	var poses: Variant = data.get("poses", {})
	if not (poses is Dictionary):
		_set_status("姿态文件没有 poses: %s" % pose_save_path)
		return
	for pose_name_variant in POSE_NAMES:
		var pose_name := String(pose_name_variant)
		var source_entry: Variant = Dictionary(poses).get(pose_name, {})
		if not (source_entry is Dictionary):
			continue
		var source_dict: Dictionary = source_entry
		var source_bones: Variant = source_dict.get("bones", {})
		if not (source_bones is Dictionary):
			continue
		var bones := {}
		for bone_name_variant in Dictionary(source_bones).keys():
			var bone_name := String(bone_name_variant)
			var rotation := _coerce_rotation_degrees(Dictionary(source_bones)[bone_name_variant])
			if rotation.length() > 0.001:
				bones[bone_name] = [rotation.x, rotation.y, rotation.z]
		pose_data[pose_name] = {"bones": bones}
	_set_status("已载入 %s" % pose_save_path)


func _save_pose_file() -> void:
	var global_path := ProjectSettings.globalize_path(pose_save_path)
	var global_dir := ProjectSettings.globalize_path(pose_save_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(global_dir)
	var file := FileAccess.open(global_path, FileAccess.WRITE)
	if file == null:
		_set_status("保存失败: %s" % error_string(FileAccess.get_open_error()))
		return
	var data := {
		"format_version": 1,
		"model_path": model_path,
		"editor_preview_mode": _current_preview_mode_key(),
		"editor_base_pose": _current_base_pose_key(),
		"poses": pose_data,
	}
	file.store_string(JSON.stringify(data, "\t"))
	_set_status("已保存 %s" % pose_save_path)


func _coerce_rotation_degrees(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 3:
			return Vector3(float(array_value[0]), float(array_value[1]), float(array_value[2]))
	if value is Dictionary:
		var dict_value: Dictionary = value
		return Vector3(
			float(dict_value.get("x", 0.0)),
			float(dict_value.get("y", 0.0)),
			float(dict_value.get("z", 0.0))
		)
	return Vector3.ZERO


func _current_base_pose_key() -> String:
	return BASE_POSE_T_POSE if use_t_pose_base else BASE_POSE_IMPORTED


func _current_preview_mode_key() -> String:
	return PREVIEW_MODE_FLIGHT if preview_flight_state else PREVIEW_MODE_EDIT


func _current_preview_mode_label() -> String:
	return "飞行预览" if preview_flight_state else "展开编辑"


func _sync_preview_mode_option() -> void:
	if preview_mode_option == null:
		return
	preview_mode_option.select(1 if preview_flight_state else 0)


func _current_base_pose_label() -> String:
	return "校准 T-Pose" if use_t_pose_base else "导入姿态"


func _sync_base_pose_option() -> void:
	if base_pose_option == null:
		return
	base_pose_option.select(0 if use_t_pose_base else 1)


func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text
	print(text)
