extends Node2D

const VIEW_SIZE := Vector2(1280.0, 720.0)
const BASE_PLAY_ORIGIN := Vector2(92.0, 86.0)
const BASE_PLAY_SIZE := Vector2(1096.0, 548.0)
const FLIGHT_TEST_HORIZONTAL_SCALE := 5.0
const FLIGHT_TEST_VERTICAL_SCALE := 3.0
const PLAY_SIZE := Vector2(BASE_PLAY_SIZE.x * FLIGHT_TEST_HORIZONTAL_SCALE, BASE_PLAY_SIZE.y * FLIGHT_TEST_VERTICAL_SCALE)
const PLAY_RECT := Rect2(BASE_PLAY_ORIGIN, PLAY_SIZE)
const FLIGHT_START_POS := BASE_PLAY_ORIGIN + Vector2(PLAY_SIZE.x * 0.16, PLAY_SIZE.y * 0.52)
const CAMERA_LOOK_AHEAD_TIME := 0.24
const CAMERA_MAX_LOOK_AHEAD := Vector2(260.0, 120.0)
const CAMERA_HALF_LIFE := 0.08
const WORLD_GRID_STEP := 360.0
const CYAN := Color(0.42, 0.96, 1.0, 1.0)

const FRAME_COLUMNS := 7
const CELL_SIZE := Vector2(512.0, 512.0)
const SPRITE_SCALE := 0.47
const SHEET_FACE_SIGN := 1.0
const POSE_OFFSET := Vector2(-10.0, -6.0)
const USE_GEMINI_8WAY_CRUISE := true
const EIGHT_WAY_SET_V1 := 0
const EIGHT_WAY_SET_V2 := 1
const EIGHT_WAY_SET_V3_FACE := 2
const GEMINI_EIGHT_WAY_SCALE := 0.34
const GEMINI_POSE_OFFSET := Vector2(0.0, -18.0)
const GEMINI_EIGHT_WAY_SET_LABELS := [
	"V1 prototype",
	"V2 accepted",
	"V3 face",
]
const GEMINI_EIGHT_WAY_BASE_PATHS := [
	"res://resources/flight/yujian_8way_cruise_generated_v1/prototype",
	"res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v2",
	"res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face",
]
const EIGHT_WAY_RUNTIME_ADJUSTMENTS_PATH := "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_runtime_adjustments.json"
const GEMINI_EIGHT_WAY_NAMES := [
	"01_right",
	"02_up_right",
	"03_up",
	"04_up_left",
	"05_left",
	"06_down_left",
	"07_down",
	"08_down_right",
]
const GEMINI_EIGHT_WAY_VECTORS := [
	Vector2(1.0, 0.0),
	Vector2(0.7071, -0.7071),
	Vector2(0.0, -1.0),
	Vector2(-0.7071, -0.7071),
	Vector2(-1.0, 0.0),
	Vector2(-0.7071, 0.7071),
	Vector2(0.0, 1.0),
	Vector2(0.7071, 0.7071),
]

@export_enum("V1 prototype", "V2 accepted", "V3 face") var eight_way_character_set := EIGHT_WAY_SET_V3_FACE

const CRUISE_SPEED := 390.0
const BOOST_SPEED := 650.0
const ACCELERATION := 1320.0
const BOOST_ACCELERATION := 1920.0
const HOVER_BRAKE := 5200.0
const SLIP_BRAKE := 4200.0
const SLIP_DURATION := 0.12
const HOVER_STOP_SPEED := 16.0
const INPUT_HEADING_TURN_RATE := 4.8
const HEADING_TURN_RATE := 5.6
const HOVER_HEADING_TURN_RATE := 8.4
const HARD_HEADING_TURN_RATE := 9.0
const HARD_TURN_MIN_ANGLE := 2.06
const HARD_TURN_MIN_SPEED := 420.0
const CARVE_DURATION := 0.24
const CARVE_SIDE_FORCE := 720.0
const CARVE_SPEED_KEEP := 0.86
const BOUNDARY_SOFT_MARGIN := 280.0
const BOUNDARY_HEADING_PULL := 2.2
const BOUNDARY_RETURN_ACCEL := 1550.0
const CAMERA_MIN_ZOOM := 1.0
const CAMERA_MAX_ZOOM := 1.18
const CAMERA_ZOOM_HALF_LIFE := 0.16
const BOOST_ENTER_SPEED := 520.0
const BOOST_EXIT_SPEED := 455.0
const BOOST_IDLE_HARD_TURN_ENTRY_FRAME := 4

const KEY_MODE_NONE := 0
const KEY_MODE_GREEN := 2

const CLIP_CRUISE_IDLE := 0
const CLIP_CRUISE_TURN := 1
const CLIP_BOOST_ENTER := 2
const CLIP_BOOST_IDLE := 3
const CLIP_BOOST_EXIT := 4
const CLIP_HARD_TURN_CORE := 5
const CLIP_HARD_TURN_TO_BOOST := 6
const CLIP_HARD_TURN_TO_CRUISE := 7
const SPEED_MODE_CRUISE := 0
const SPEED_MODE_BOOST := 1

const CLIPS := [
	{
		"name": "cruise_idle",
		"path": "res://resources/flight/generated/yujian_v2_cruise_idle.png",
		"frames": 49,
		"fps": 20.0,
		"loop": true,
		"kind": "cruise",
		"trail_anchor": Vector2(-42.0, 90.0),
		"trail_weight": 0.86,
		"smear_weight": 0.12,
	},
	{
		"name": "cruise_turn",
		"path": "res://resources/flight/generated/yujian_v2_cruise_turn.png",
		"frames": 49,
		"fps": 64.0,
		"loop": false,
		"kind": "cruise_turn",
		"self_turn": true,
		"trail_anchor": Vector2(-54.0, 92.0),
		"trail_weight": 1.05,
		"smear_weight": 0.28,
	},
	{
		"name": "boost_enter",
		"path": "res://resources/flight/generated/yujian_v2_boost_enter.png",
		"frames": 9,
		"fps": 30.0,
		"loop": false,
		"kind": "boost_enter",
		"trail_anchor": Vector2(-62.0, 91.0),
		"trail_weight": 1.35,
		"smear_weight": 0.36,
	},
	{
		"name": "boost_idle",
		"path": "res://resources/flight/generated/yujian_v2_boost_idle.png",
		"frames": 49,
		"fps": 26.0,
		"loop": true,
		"kind": "boost",
		"trail_anchor": Vector2(-68.0, 92.0),
		"trail_weight": 1.5,
		"smear_weight": 0.42,
	},
	{
		"name": "boost_exit",
		"path": "res://resources/flight/generated/yujian_v2_boost_exit.png",
		"frames": 12,
		"fps": 30.0,
		"loop": false,
		"kind": "boost_exit",
		"trail_anchor": Vector2(-56.0, 92.0),
		"trail_weight": 1.12,
		"smear_weight": 0.24,
	},
	{
		"name": "hard_turn_core",
		"path": "res://resources/flight/generated/yujian_v2_hard_turn_core.png",
		"frames": 16,
		"fps": 30.0,
		"loop": false,
		"kind": "hard_turn",
		"self_turn": true,
		"trail_anchor": Vector2(-70.0, 92.0),
		"trail_weight": 1.72,
		"smear_weight": 0.9,
	},
	{
		"name": "hard_turn_to_boost",
		"path": "res://resources/flight/generated/yujian_v2_hard_turn_to_boost.png",
		"frames": 21,
		"fps": 48.0,
		"loop": false,
		"kind": "hard_follow_boost",
		"self_turn": true,
		"trail_anchor": Vector2(-74.0, 92.0),
		"trail_weight": 1.62,
		"smear_weight": 0.62,
	},
	{
		"name": "hard_turn_to_cruise",
		"path": "res://resources/flight/generated/yujian_v2_hard_turn_to_cruise.png",
		"frames": 33,
		"fps": 32.0,
		"loop": false,
		"kind": "hard_follow_cruise",
		"self_turn": true,
		"trail_anchor": Vector2(-64.0, 92.0),
		"trail_weight": 1.28,
		"smear_weight": 0.38,
	},
]

var sprite_root: Node2D
var character_sprite: Sprite2D
var key_shader: Shader
var trail_halo: Line2D
var trail_ribbon: Line2D
var trail_core: Line2D

var texture_cache: Dictionary = {}
var eight_way_textures: Array = []
var eight_way_index := 0
var sheet_texture: Texture2D
var clip_index := CLIP_CRUISE_IDLE
var frame_index := 0
var frame_timer := 0.0
var render_sign := 1.0
var facing_sign := 1.0
var turn_from_sign := 1.0
var turn_to_sign := 1.0
var speed_mode := SPEED_MODE_CRUISE

var flight_pos := FLIGHT_START_POS
var visual_pos := flight_pos
var velocity := Vector2.ZERO
var camera_center := FLIGHT_START_POS
var camera_zoom := CAMERA_MIN_ZOOM
var target_heading := Vector2.RIGHT
var body_heading := Vector2.RIGHT
var heading_input := Vector2.RIGHT
var heading_input_active := false
var throttle_pressed := false
var slip_timer := 0.0
var throttle_energy := 0.0
var slip_energy := 0.0
var carve_energy := 0.0
var carve_direction := 0.0
var carve_timer := 0.0
var hard_turn_request_timer := 0.0
var heading_angle_delta := 0.0
var heading_turn_rate := 0.0
var boundary_energy := 0.0
var boost_energy := 0.0
var turn_energy := 0.0
var time := 0.0
var background_key_enabled := true
var auto_demo := false
var eight_way_adjustments: Dictionary = {}
var adjustment_selected_direction := 0
var adjustment_follow_current := true
var adjustment_updating_controls := false

var adjustment_layer: CanvasLayer
var adjustment_panel: PanelContainer
var adjustment_set_option: OptionButton
var adjustment_direction_option: OptionButton
var adjustment_follow_checkbox: CheckBox
var adjustment_global_scale_slider: HSlider
var adjustment_global_scale_spin: SpinBox
var adjustment_direction_scale_slider: HSlider
var adjustment_direction_scale_spin: SpinBox
var adjustment_offset_x_spin: SpinBox
var adjustment_offset_y_spin: SpinBox
var adjustment_status_label: Label

var trail_points: Array = []
var afterimages: Array = []


func _ready() -> void:
	_create_nodes()
	if USE_GEMINI_8WAY_CRUISE:
		_load_eight_way_adjustments()
		_load_eight_way_textures()
		_create_adjustment_panel()
	_start_clip(CLIP_CRUISE_IDLE, facing_sign)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var step := minf(delta, 1.0 / 30.0)
	time += step
	var axis := _get_move_axis()
	var boosting := _is_boost_pressed()
	_update_motion(axis, boosting, step)
	_update_speed_mode()
	_update_clip_requests(axis, boosting)
	_advance_clip(step, axis, boosting)
	_update_camera(step)
	_update_visual_state(step)
	_update_adjustment_panel_follow_state()
	_update_afterimages(step)
	_update_trail(step)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_start_clip(CLIP_CRUISE_IDLE, facing_sign)
			KEY_2:
				_start_cruise_turn(facing_sign, -facing_sign)
			KEY_3:
				_start_clip(CLIP_BOOST_ENTER, facing_sign)
			KEY_4:
				_start_clip(CLIP_BOOST_IDLE, facing_sign)
			KEY_5:
				_start_hard_turn(facing_sign, -facing_sign)
			KEY_K:
				background_key_enabled = not background_key_enabled
				_update_key_material()
			KEY_T:
				auto_demo = not auto_demo
			KEY_V:
				_set_eight_way_character_set((eight_way_character_set + 1) % GEMINI_EIGHT_WAY_BASE_PATHS.size())
			KEY_F2:
				_toggle_adjustment_panel()
			KEY_R:
				_start_clip(clip_index, render_sign)


func _create_nodes() -> void:
	key_shader = Shader.new()
	key_shader.code = """
shader_type canvas_item;

uniform float key_strength : hint_range(0.0, 1.0) = 1.0;
uniform int key_mode = 2;
uniform vec3 green_key = vec3(0.03, 0.67, 0.02);
uniform float green_distance_floor : hint_range(0.0, 0.5) = 0.13;
uniform float green_distance_ceiling : hint_range(0.0, 0.6) = 0.33;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float green_distance = distance(tex.rgb, green_key);
	float green_dominance = tex.g - max(tex.r, tex.b);
	float green_mask = (1.0 - smoothstep(green_distance_floor, green_distance_ceiling, green_distance)) * smoothstep(0.06, 0.22, green_dominance);
	if (key_mode == 2) {
		tex.a *= 1.0 - green_mask * key_strength;
	}
	COLOR = tex * COLOR;
}
"""

	trail_halo = _create_trail_line("TrailHalo", 0)
	trail_ribbon = _create_trail_line("TrailRibbon", 1)
	trail_core = _create_trail_line("TrailCore", 2)

	sprite_root = Node2D.new()
	sprite_root.name = "SequenceCharacterRoot"
	sprite_root.z_index = 5
	add_child(sprite_root)

	character_sprite = Sprite2D.new()
	character_sprite.name = "SequenceCharacter"
	character_sprite.centered = true
	character_sprite.region_enabled = not USE_GEMINI_8WAY_CRUISE
	character_sprite.material = _make_key_material()
	character_sprite.position = POSE_OFFSET
	sprite_root.add_child(character_sprite)


func _create_adjustment_panel() -> void:
	adjustment_layer = CanvasLayer.new()
	adjustment_layer.name = "EightWayAdjustmentLayer"
	adjustment_layer.layer = 80
	add_child(adjustment_layer)

	adjustment_panel = PanelContainer.new()
	adjustment_panel.name = "EightWayAdjustmentPanel"
	adjustment_panel.position = Vector2(930.0, 78.0)
	adjustment_panel.custom_minimum_size = Vector2(320.0, 0.0)
	adjustment_layer.add_child(adjustment_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	adjustment_panel.add_child(root)

	var title := Label.new()
	title.text = "八向人物调参  F2"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	adjustment_set_option = OptionButton.new()
	for index in range(GEMINI_EIGHT_WAY_SET_LABELS.size()):
		adjustment_set_option.add_item(String(GEMINI_EIGHT_WAY_SET_LABELS[index]), index)
	adjustment_set_option.select(clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_SET_LABELS.size() - 1))
	adjustment_set_option.item_selected.connect(Callable(self, "_on_adjustment_set_selected"))
	root.add_child(_make_adjustment_row("资源集", adjustment_set_option))

	adjustment_direction_option = OptionButton.new()
	for index in range(GEMINI_EIGHT_WAY_NAMES.size()):
		adjustment_direction_option.add_item(String(GEMINI_EIGHT_WAY_NAMES[index]), index)
	adjustment_direction_option.select(adjustment_selected_direction)
	adjustment_direction_option.item_selected.connect(Callable(self, "_on_adjustment_direction_selected"))
	root.add_child(_make_adjustment_row("方向", adjustment_direction_option))

	adjustment_follow_checkbox = CheckBox.new()
	adjustment_follow_checkbox.text = "跟随当前方向"
	adjustment_follow_checkbox.button_pressed = adjustment_follow_current
	adjustment_follow_checkbox.toggled.connect(Callable(self, "_on_adjustment_follow_toggled"))
	root.add_child(adjustment_follow_checkbox)

	adjustment_global_scale_slider = _make_adjustment_slider(0.6, 1.4, 0.005)
	adjustment_global_scale_spin = _make_adjustment_spin(0.4, 1.8, 0.01)
	adjustment_global_scale_slider.value_changed.connect(Callable(self, "_on_adjustment_global_scale_changed"))
	adjustment_global_scale_spin.value_changed.connect(Callable(self, "_on_adjustment_global_scale_changed"))
	root.add_child(_make_adjustment_slider_row("全局缩放", adjustment_global_scale_slider, adjustment_global_scale_spin))

	adjustment_direction_scale_slider = _make_adjustment_slider(0.6, 1.4, 0.005)
	adjustment_direction_scale_spin = _make_adjustment_spin(0.4, 1.8, 0.01)
	adjustment_direction_scale_slider.value_changed.connect(Callable(self, "_on_adjustment_direction_scale_changed"))
	adjustment_direction_scale_spin.value_changed.connect(Callable(self, "_on_adjustment_direction_scale_changed"))
	root.add_child(_make_adjustment_slider_row("方向缩放", adjustment_direction_scale_slider, adjustment_direction_scale_spin))

	adjustment_offset_x_spin = _make_adjustment_spin(-256.0, 256.0, 1.0)
	adjustment_offset_x_spin.value_changed.connect(Callable(self, "_on_adjustment_offset_x_changed"))
	root.add_child(_make_adjustment_row("X 偏移", adjustment_offset_x_spin))

	adjustment_offset_y_spin = _make_adjustment_spin(-256.0, 256.0, 1.0)
	adjustment_offset_y_spin.value_changed.connect(Callable(self, "_on_adjustment_offset_y_changed"))
	root.add_child(_make_adjustment_row("Y 偏移", adjustment_offset_y_spin))

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	root.add_child(button_row)
	var reset_direction_button := Button.new()
	reset_direction_button.text = "重置方向"
	reset_direction_button.pressed.connect(Callable(self, "_on_adjustment_reset_direction_pressed"))
	button_row.add_child(reset_direction_button)
	var reset_set_button := Button.new()
	reset_set_button.text = "重置资源集"
	reset_set_button.pressed.connect(Callable(self, "_on_adjustment_reset_set_pressed"))
	button_row.add_child(reset_set_button)
	var save_button := Button.new()
	save_button.text = "保存 JSON"
	save_button.pressed.connect(Callable(self, "_on_adjustment_save_pressed"))
	root.add_child(save_button)

	adjustment_status_label = Label.new()
	adjustment_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	adjustment_status_label.add_theme_font_size_override("font_size", 12)
	root.add_child(adjustment_status_label)

	_refresh_adjustment_controls()


func _make_adjustment_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(76.0, 0.0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _make_adjustment_slider_row(label_text: String, slider: HSlider, spin: SpinBox) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(76.0, 0.0)
	row.add_child(label)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	spin.custom_minimum_size = Vector2(74.0, 0.0)
	row.add_child(spin)
	return row


func _make_adjustment_slider(min_value: float, max_value: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.allow_greater = true
	slider.allow_lesser = true
	return slider


func _make_adjustment_spin(min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.allow_greater = true
	spin.allow_lesser = true
	return spin


func _create_trail_line(line_name: String, z: int) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.z_index = z
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.antialiased = true
	add_child(line)
	return line


func _make_key_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = key_shader
	_apply_key_params(material)
	return material


func _apply_key_params(material: ShaderMaterial) -> void:
	material.set_shader_parameter("key_mode", KEY_MODE_GREEN if background_key_enabled else KEY_MODE_NONE)
	material.set_shader_parameter("key_strength", 1.0 if background_key_enabled else 0.0)


func _update_key_material() -> void:
	if character_sprite != null and character_sprite.material is ShaderMaterial:
		_apply_key_params(character_sprite.material as ShaderMaterial)


func _load_sequence_texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	var image := Image.new()
	var global_path := ProjectSettings.globalize_path(path)
	if image.load(global_path) == OK:
		var image_texture := ImageTexture.create_from_image(image)
		texture_cache[path] = image_texture
		return image_texture
	var texture := load(path) as Texture2D
	if texture != null:
		texture_cache[path] = texture
	return texture


func _load_eight_way_adjustments() -> void:
	eight_way_adjustments = {"sets": {}}
	var global_path := ProjectSettings.globalize_path(EIGHT_WAY_RUNTIME_ADJUSTMENTS_PATH)
	if FileAccess.file_exists(global_path):
		var file := FileAccess.open(global_path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				eight_way_adjustments = parsed
	_ensure_all_eight_way_adjustments()


func _save_eight_way_adjustments() -> bool:
	_ensure_all_eight_way_adjustments()
	var global_path := ProjectSettings.globalize_path(EIGHT_WAY_RUNTIME_ADJUSTMENTS_PATH)
	var file := FileAccess.open(global_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(eight_way_adjustments, "\t"))
	return true


func _ensure_all_eight_way_adjustments() -> void:
	if typeof(eight_way_adjustments) != TYPE_DICTIONARY:
		eight_way_adjustments = {}
	if not eight_way_adjustments.has("sets") or typeof(eight_way_adjustments["sets"]) != TYPE_DICTIONARY:
		eight_way_adjustments["sets"] = {}
	for index in range(GEMINI_EIGHT_WAY_BASE_PATHS.size()):
		_ensure_eight_way_adjustment_set(index)


func _ensure_eight_way_adjustment_set(set_index: int) -> void:
	var sets: Dictionary = eight_way_adjustments["sets"]
	var set_key := _get_eight_way_set_key(set_index)
	if not sets.has(set_key) or typeof(sets[set_key]) != TYPE_DICTIONARY:
		sets[set_key] = {
			"global_scale": 1.0,
			"directions": {},
		}
	var set_data: Dictionary = sets[set_key]
	if not set_data.has("global_scale"):
		set_data["global_scale"] = 1.0
	if not set_data.has("directions") or typeof(set_data["directions"]) != TYPE_DICTIONARY:
		set_data["directions"] = {}
	var directions: Dictionary = set_data["directions"]
	for name_variant in GEMINI_EIGHT_WAY_NAMES:
		var name := String(name_variant)
		if not directions.has(name) or typeof(directions[name]) != TYPE_DICTIONARY:
			directions[name] = {
				"scale": 1.0,
				"offset": [0.0, 0.0],
			}
		var direction_data: Dictionary = directions[name]
		if not direction_data.has("scale"):
			direction_data["scale"] = 1.0
		if not direction_data.has("offset") or typeof(direction_data["offset"]) != TYPE_ARRAY:
			direction_data["offset"] = [0.0, 0.0]


func _get_eight_way_set_key(set_index: int) -> String:
	var safe_index := clampi(set_index, 0, GEMINI_EIGHT_WAY_BASE_PATHS.size() - 1)
	return String(GEMINI_EIGHT_WAY_BASE_PATHS[safe_index])


func _get_eight_way_set_adjustment(set_index: int) -> Dictionary:
	if not eight_way_adjustments.has("sets") or typeof(eight_way_adjustments["sets"]) != TYPE_DICTIONARY:
		_ensure_all_eight_way_adjustments()
	_ensure_eight_way_adjustment_set(set_index)
	var sets: Dictionary = eight_way_adjustments["sets"]
	return sets[_get_eight_way_set_key(set_index)]


func _get_eight_way_direction_adjustment(set_index: int, direction_index: int) -> Dictionary:
	var set_data := _get_eight_way_set_adjustment(set_index)
	var directions: Dictionary = set_data["directions"]
	var direction_name := String(GEMINI_EIGHT_WAY_NAMES[clampi(direction_index, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)])
	return directions[direction_name]


func _get_eight_way_global_scale(set_index: int) -> float:
	var set_data := _get_eight_way_set_adjustment(set_index)
	return float(set_data.get("global_scale", 1.0))


func _get_eight_way_direction_scale(set_index: int, direction_index: int) -> float:
	var direction_data := _get_eight_way_direction_adjustment(set_index, direction_index)
	return float(direction_data.get("scale", 1.0))


func _get_eight_way_direction_offset(set_index: int, direction_index: int) -> Vector2:
	var direction_data := _get_eight_way_direction_adjustment(set_index, direction_index)
	var raw_offset: Array = direction_data.get("offset", [0.0, 0.0])
	if raw_offset.size() < 2:
		return Vector2.ZERO
	return Vector2(float(raw_offset[0]), float(raw_offset[1]))


func _load_eight_way_textures() -> void:
	eight_way_textures.clear()
	for index in range(GEMINI_EIGHT_WAY_NAMES.size()):
		var path := _get_eight_way_path(index)
		var texture := _load_sequence_texture(path)
		if texture == null:
			push_warning("Missing Gemini 8-way yujian sprite (%s): %s" % [_current_eight_way_set_label(), path])
		eight_way_textures.append(texture)


func _set_eight_way_character_set(next_set: int) -> void:
	eight_way_character_set = clampi(next_set, 0, GEMINI_EIGHT_WAY_BASE_PATHS.size() - 1)
	if not USE_GEMINI_8WAY_CRUISE:
		return
	_load_eight_way_textures()
	_apply_eight_way_texture(body_heading)
	_refresh_adjustment_controls()
	queue_redraw()


func _get_eight_way_path(index: int) -> String:
	var set_index := clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_BASE_PATHS.size() - 1)
	var name_index := clampi(index, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)
	return "%s/%s.png" % [
		String(GEMINI_EIGHT_WAY_BASE_PATHS[set_index]),
		String(GEMINI_EIGHT_WAY_NAMES[name_index]),
	]


func _toggle_adjustment_panel() -> void:
	if adjustment_panel == null:
		return
	adjustment_panel.visible = not adjustment_panel.visible


func _update_adjustment_panel_follow_state() -> void:
	if adjustment_panel == null or not adjustment_panel.visible:
		return
	var needs_refresh := false
	if adjustment_set_option != null and adjustment_set_option.selected != eight_way_character_set:
		adjustment_set_option.select(clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_SET_LABELS.size() - 1))
		needs_refresh = true
	if adjustment_follow_current and adjustment_selected_direction != eight_way_index:
		adjustment_selected_direction = eight_way_index
		if adjustment_direction_option != null:
			adjustment_direction_option.select(adjustment_selected_direction)
		needs_refresh = true
	if needs_refresh:
		_refresh_adjustment_controls()


func _refresh_adjustment_controls() -> void:
	if adjustment_panel == null:
		return
	var set_index := clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_BASE_PATHS.size() - 1)
	var direction_index := clampi(adjustment_selected_direction, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)
	var global_scale := _get_eight_way_global_scale(set_index)
	var direction_scale := _get_eight_way_direction_scale(set_index, direction_index)
	var offset := _get_eight_way_direction_offset(set_index, direction_index)

	adjustment_updating_controls = true
	adjustment_set_option.select(set_index)
	adjustment_direction_option.select(direction_index)
	adjustment_follow_checkbox.button_pressed = adjustment_follow_current
	adjustment_global_scale_slider.value = global_scale
	adjustment_global_scale_spin.value = global_scale
	adjustment_direction_scale_slider.value = direction_scale
	adjustment_direction_scale_spin.value = direction_scale
	adjustment_offset_x_spin.value = offset.x
	adjustment_offset_y_spin.value = offset.y
	adjustment_updating_controls = false
	_update_adjustment_status()


func _update_adjustment_status(extra_message := "") -> void:
	if adjustment_status_label == null:
		return
	var set_label := _current_eight_way_set_label()
	var direction_name := String(GEMINI_EIGHT_WAY_NAMES[clampi(adjustment_selected_direction, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)])
	var global_scale := _get_eight_way_global_scale(eight_way_character_set)
	var direction_scale := _get_eight_way_direction_scale(eight_way_character_set, adjustment_selected_direction)
	var offset := _get_eight_way_direction_offset(eight_way_character_set, adjustment_selected_direction)
	adjustment_status_label.text = "%s / %s\n全局 %.3f  方向 %.3f  偏移 %.0f, %.0f" % [
		set_label,
		direction_name,
		global_scale,
		direction_scale,
		offset.x,
		offset.y,
	]
	if extra_message != "":
		adjustment_status_label.text += "\n%s" % extra_message


func _on_adjustment_set_selected(index: int) -> void:
	if adjustment_updating_controls:
		return
	_set_eight_way_character_set(index)


func _on_adjustment_direction_selected(index: int) -> void:
	if adjustment_updating_controls:
		return
	adjustment_selected_direction = clampi(index, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)
	adjustment_follow_current = false
	_refresh_adjustment_controls()


func _on_adjustment_follow_toggled(pressed: bool) -> void:
	if adjustment_updating_controls:
		return
	adjustment_follow_current = pressed
	if adjustment_follow_current:
		adjustment_selected_direction = eight_way_index
	_refresh_adjustment_controls()


func _on_adjustment_global_scale_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	var set_data := _get_eight_way_set_adjustment(eight_way_character_set)
	set_data["global_scale"] = value
	adjustment_updating_controls = true
	adjustment_global_scale_slider.value = value
	adjustment_global_scale_spin.value = value
	adjustment_updating_controls = false
	_apply_sprite_transform()
	_update_adjustment_status()


func _on_adjustment_direction_scale_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	var direction_data := _get_eight_way_direction_adjustment(eight_way_character_set, adjustment_selected_direction)
	direction_data["scale"] = value
	adjustment_updating_controls = true
	adjustment_direction_scale_slider.value = value
	adjustment_direction_scale_spin.value = value
	adjustment_updating_controls = false
	_apply_sprite_transform()
	_update_adjustment_status()


func _on_adjustment_offset_x_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	var offset := _get_eight_way_direction_offset(eight_way_character_set, adjustment_selected_direction)
	_set_eight_way_direction_offset(adjustment_selected_direction, Vector2(value, offset.y))


func _on_adjustment_offset_y_changed(value: float) -> void:
	if adjustment_updating_controls:
		return
	var offset := _get_eight_way_direction_offset(eight_way_character_set, adjustment_selected_direction)
	_set_eight_way_direction_offset(adjustment_selected_direction, Vector2(offset.x, value))


func _set_eight_way_direction_offset(direction_index: int, offset: Vector2) -> void:
	var direction_data := _get_eight_way_direction_adjustment(eight_way_character_set, direction_index)
	direction_data["offset"] = [offset.x, offset.y]
	adjustment_updating_controls = true
	adjustment_offset_x_spin.value = offset.x
	adjustment_offset_y_spin.value = offset.y
	adjustment_updating_controls = false
	_apply_sprite_transform()
	_update_adjustment_status()


func _on_adjustment_reset_direction_pressed() -> void:
	var direction_data := _get_eight_way_direction_adjustment(eight_way_character_set, adjustment_selected_direction)
	direction_data["scale"] = 1.0
	direction_data["offset"] = [0.0, 0.0]
	_apply_sprite_transform()
	_refresh_adjustment_controls()


func _on_adjustment_reset_set_pressed() -> void:
	var set_data := _get_eight_way_set_adjustment(eight_way_character_set)
	set_data["global_scale"] = 1.0
	var directions: Dictionary = set_data["directions"]
	for name_variant in GEMINI_EIGHT_WAY_NAMES:
		var name := String(name_variant)
		directions[name] = {
			"scale": 1.0,
			"offset": [0.0, 0.0],
		}
	_apply_sprite_transform()
	_refresh_adjustment_controls()


func _on_adjustment_save_pressed() -> void:
	if _save_eight_way_adjustments():
		_update_adjustment_status("已保存到 prototype_runtime_adjustments.json")
	else:
		_update_adjustment_status("保存失败：无法写入 JSON")


func _start_clip(next_clip: int, fixed_render_sign := 0.0, entry_frame := 0) -> void:
	clip_index = clampi(next_clip, 0, CLIPS.size() - 1)
	frame_timer = 0.0
	if fixed_render_sign != 0.0:
		_set_render_sign(fixed_render_sign, false)
	else:
		_set_render_sign(facing_sign, false)

	var clip := _current_clip()
	frame_index = clampi(entry_frame, 0, int(clip["frames"]) - 1)
	sheet_texture = _load_sequence_texture(String(clip["path"]))
	if sheet_texture == null:
		push_warning("Missing yujian v2 sheet: %s" % String(clip["path"]))
		return
	character_sprite.texture = sheet_texture
	_apply_frame()
	_apply_sprite_transform()


func _set_render_sign(next_sign: float, reset_directional_vfx := true) -> void:
	if next_sign == 0.0:
		return
	var next := signf(next_sign)
	if reset_directional_vfx and next != render_sign:
		_reset_directional_vfx()
	render_sign = next


func _reset_directional_vfx() -> void:
	trail_points.clear()
	afterimages.clear()


func _start_cruise_turn(from_sign: float, to_sign: float, entry_phase := 0.0) -> void:
	turn_from_sign = signf(from_sign)
	turn_to_sign = signf(to_sign)
	var entry_frame := int(round(clampf(entry_phase, 0.0, 1.0) * float(int(CLIPS[CLIP_CRUISE_TURN]["frames"]) - 1)))
	_start_clip(CLIP_CRUISE_TURN, turn_from_sign, entry_frame)
	_capture_afterimage(flight_pos - Vector2(turn_from_sign * 24.0, 0.0), 0.72)


func _start_hard_turn(from_sign: float, to_sign: float) -> void:
	turn_from_sign = signf(from_sign)
	turn_to_sign = signf(to_sign)
	_start_clip(CLIP_HARD_TURN_CORE, turn_from_sign)
	_capture_afterimage(flight_pos - Vector2(turn_from_sign * 36.0, 0.0), 1.0)
	_capture_afterimage(flight_pos - Vector2(turn_from_sign * 72.0, -8.0), 0.72)


func _start_hard_follow(next_clip: int) -> void:
	_start_clip(next_clip, turn_from_sign)


func _advance_clip(delta: float, axis: Vector2, boosting: bool) -> void:
	if sheet_texture == null:
		return
	var clip := _current_clip()
	frame_timer += delta
	var frame_duration := 1.0 / maxf(float(clip["fps"]), 1.0)
	while frame_timer >= frame_duration:
		frame_timer -= frame_duration
		frame_index += 1
		if frame_index >= int(clip["frames"]):
			if bool(clip["loop"]):
				frame_index = 0
			else:
				frame_index = int(clip["frames"]) - 1
				_apply_frame()
				_finish_clip(axis, boosting)
				return
		_apply_frame()


func _finish_clip(_axis: Vector2, _boosting: bool) -> void:
	match clip_index:
		CLIP_CRUISE_TURN:
			facing_sign = turn_to_sign
			_set_render_sign(facing_sign)
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_ENTER, facing_sign)
			else:
				_start_clip(CLIP_CRUISE_IDLE, facing_sign)
		CLIP_BOOST_ENTER:
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_IDLE, facing_sign)
			else:
				_start_clip(CLIP_BOOST_EXIT, facing_sign)
		CLIP_BOOST_EXIT:
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_ENTER, facing_sign)
			else:
				_start_clip(CLIP_CRUISE_IDLE, facing_sign)
		CLIP_HARD_TURN_CORE:
			facing_sign = turn_to_sign
			_set_render_sign(facing_sign)
			if speed_mode == SPEED_MODE_BOOST:
				_start_hard_follow(CLIP_HARD_TURN_TO_BOOST)
			else:
				_start_hard_follow(CLIP_HARD_TURN_TO_CRUISE)
		CLIP_HARD_TURN_TO_BOOST:
			facing_sign = turn_to_sign
			_set_render_sign(facing_sign)
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_IDLE, facing_sign, BOOST_IDLE_HARD_TURN_ENTRY_FRAME)
			else:
				_start_clip(CLIP_BOOST_EXIT, facing_sign)
		CLIP_HARD_TURN_TO_CRUISE:
			facing_sign = turn_to_sign
			_set_render_sign(facing_sign)
			if speed_mode == SPEED_MODE_BOOST:
				_start_clip(CLIP_BOOST_ENTER, facing_sign)
			else:
				_start_clip(CLIP_CRUISE_IDLE, facing_sign)
		_:
			_start_clip(CLIP_CRUISE_IDLE, facing_sign)


func _update_clip_requests(_axis: Vector2, _boosting: bool) -> void:
	var desired_sign := _heading_render_sign(body_heading, render_sign)
	var can_interrupt_turn := not _is_turn_clip() or _clip_phase() >= 0.22

	if hard_turn_request_timer > 0.0 and can_interrupt_turn:
		hard_turn_request_timer = 0.0
		var hard_target_sign := _heading_render_sign(target_heading, desired_sign)
		_start_hard_turn(render_sign, hard_target_sign)
		return

	if not _is_clip_looping():
		if _clip_phase() >= 0.18 and absf(body_heading.x) > 0.34 and desired_sign != facing_sign:
			if _should_use_hard_turn():
				_start_hard_turn(render_sign, desired_sign)
			else:
				_start_cruise_turn(render_sign, desired_sign, 0.32)
			return
		if clip_index == CLIP_BOOST_ENTER and not throttle_pressed:
			_start_clip(CLIP_BOOST_EXIT, facing_sign)
			return
		if clip_index == CLIP_BOOST_EXIT and throttle_pressed:
			_start_clip(CLIP_BOOST_ENTER, facing_sign)
			return
		if absf(body_heading.x) > 0.34:
			facing_sign = desired_sign
		return

	var sign_changed := absf(body_heading.x) > 0.34 and desired_sign != facing_sign
	if sign_changed:
		if _should_use_hard_turn():
			_start_hard_turn(facing_sign, desired_sign)
		else:
			_start_cruise_turn(facing_sign, desired_sign)
		return

	if absf(body_heading.x) > 0.34:
		facing_sign = desired_sign
		_set_render_sign(desired_sign)

	if speed_mode == SPEED_MODE_BOOST:
		if clip_index == CLIP_CRUISE_IDLE or clip_index == CLIP_BOOST_EXIT:
			_start_clip(CLIP_BOOST_ENTER, facing_sign)
	else:
		if clip_index == CLIP_BOOST_IDLE or clip_index == CLIP_BOOST_ENTER:
			_start_clip(CLIP_BOOST_EXIT, facing_sign)


func _update_motion(axis: Vector2, boosting: bool, delta: float) -> void:
	_update_target_heading_from_input(axis, delta)

	var boundary_steer := _get_boundary_steer()
	boundary_energy = clampf(boundary_steer.length(), 0.0, 1.0)
	if boundary_energy > 0.0:
		target_heading = (target_heading + boundary_steer.normalized() * boundary_energy * BOUNDARY_HEADING_PULL).normalized()

	var previous_throttle := throttle_pressed
	throttle_pressed = boosting
	if previous_throttle and not throttle_pressed and velocity.length() > HOVER_STOP_SPEED:
		slip_timer = SLIP_DURATION

	if carve_timer > 0.0:
		carve_timer = maxf(carve_timer - delta, 0.0)
	if hard_turn_request_timer > 0.0:
		hard_turn_request_timer = maxf(hard_turn_request_timer - delta, 0.0)

	var turn_delta := _signed_angle_between(body_heading, target_heading)
	var speed_ratio := clampf(velocity.length() / BOOST_SPEED, 0.0, 1.0)
	var turn_pressure := clampf(absf(turn_delta) / PI, 0.0, 1.0)
	var turn_rate := lerpf(HEADING_TURN_RATE, HARD_HEADING_TURN_RATE, turn_pressure)
	if not throttle_pressed:
		turn_rate = maxf(turn_rate, HOVER_HEADING_TURN_RATE)
	var angle_step := clampf(turn_delta, -turn_rate * delta, turn_rate * delta)
	body_heading = body_heading.rotated(angle_step).normalized()
	heading_turn_rate = absf(angle_step) / maxf(delta, 0.001)
	heading_angle_delta = _signed_angle_between(body_heading, target_heading)

	if throttle_pressed and absf(turn_delta) >= HARD_TURN_MIN_ANGLE and velocity.length() >= HARD_TURN_MIN_SPEED and carve_timer <= 0.0:
		_begin_carve(signf(turn_delta))

	if throttle_pressed:
		var carve_ratio := clampf(carve_timer / CARVE_DURATION, 0.0, 1.0)
		var target_speed := BOOST_SPEED * lerpf(1.0, CARVE_SPEED_KEEP, carve_ratio)
		var target_velocity := body_heading * target_speed
		var acceleration := lerpf(ACCELERATION, BOOST_ACCELERATION, clampf(0.35 + speed_ratio, 0.0, 1.0))
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		if carve_ratio > 0.0 and carve_direction != 0.0:
			var carve_side := body_heading.rotated(carve_direction * PI * 0.5)
			velocity += carve_side * CARVE_SIDE_FORCE * carve_ratio * delta
	else:
		if slip_timer > 0.0:
			slip_timer = maxf(slip_timer - delta, 0.0)
			velocity = velocity.move_toward(Vector2.ZERO, SLIP_BRAKE * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, HOVER_BRAKE * delta)
			if velocity.length() <= HOVER_STOP_SPEED:
				velocity = Vector2.ZERO

	if boundary_energy > 0.0:
		var inward := boundary_steer.normalized()
		var return_speed := maxf(velocity.length(), CRUISE_SPEED * 0.45)
		velocity = velocity.move_toward(inward * return_speed, BOUNDARY_RETURN_ACCEL * boundary_energy * delta)

	flight_pos += velocity * delta
	_apply_boundary_failsafe()


func _update_target_heading_from_input(axis: Vector2, delta: float) -> void:
	heading_input_active = axis.length_squared() > 0.01
	if not heading_input_active:
		return
	heading_input = axis.normalized()
	var input_strength := clampf(axis.length(), 0.0, 1.0)
	var turn_delta := _signed_angle_between(target_heading, heading_input)
	var angle_step := clampf(turn_delta, -INPUT_HEADING_TURN_RATE * input_strength * delta, INPUT_HEADING_TURN_RATE * input_strength * delta)
	target_heading = target_heading.rotated(angle_step).normalized()


func _update_speed_mode() -> void:
	var speed := velocity.length()
	if speed_mode == SPEED_MODE_CRUISE and speed >= BOOST_ENTER_SPEED:
		speed_mode = SPEED_MODE_BOOST
	elif speed_mode == SPEED_MODE_BOOST and speed <= BOOST_EXIT_SPEED:
		speed_mode = SPEED_MODE_CRUISE


func _update_visual_state(delta: float) -> void:
	visual_pos = flight_pos
	var speed_ratio := clampf((velocity.length() - CRUISE_SPEED) / maxf(BOOST_SPEED - CRUISE_SPEED, 1.0), 0.0, 1.0)
	var boost_target := maxf(speed_ratio, 0.55 if throttle_pressed else 0.0)
	var turn_target := clampf(absf(heading_angle_delta) / 1.35, 0.0, 1.0) * clampf(velocity.length() / CRUISE_SPEED, 0.0, 1.0)
	if _is_turn_clip():
		turn_target = maxf(turn_target, 0.72)
	var carve_target := clampf(carve_timer / CARVE_DURATION, 0.0, 1.0)
	turn_target = maxf(turn_target, carve_target)
	boost_energy = _damp_float(boost_energy, boost_target, 0.09, delta)
	turn_energy = _damp_float(turn_energy, turn_target, 0.06, delta)
	throttle_energy = _damp_float(throttle_energy, 1.0 if throttle_pressed else 0.0, 0.08, delta)
	slip_energy = _damp_float(slip_energy, clampf(slip_timer / SLIP_DURATION, 0.0, 1.0), 0.05, delta)
	carve_energy = _damp_float(carve_energy, carve_target, 0.045, delta)
	_apply_sprite_transform()


func _apply_sprite_transform() -> void:
	if sprite_root == null or character_sprite == null:
		return
	if USE_GEMINI_8WAY_CRUISE:
		_apply_eight_way_texture(body_heading)
		sprite_root.position = _world_to_screen(visual_pos)
		sprite_root.rotation = 0.0
		sprite_root.scale = Vector2.ONE / maxf(camera_zoom, 0.001)
		var turn_lean := clampf(heading_angle_delta / 1.4, -1.0, 1.0)
		var adjustment_scale := _get_eight_way_global_scale(eight_way_character_set) * _get_eight_way_direction_scale(eight_way_character_set, eight_way_index)
		var adjustment_offset := _get_eight_way_direction_offset(eight_way_character_set, eight_way_index)
		var sprite_scale := GEMINI_EIGHT_WAY_SCALE * adjustment_scale * (1.0 + 0.035 * boost_energy + 0.035 * carve_energy)
		character_sprite.position = GEMINI_POSE_OFFSET + adjustment_offset + Vector2(0.0, -3.0 * boost_energy - 2.0 * carve_energy)
		character_sprite.rotation = -turn_lean * 0.035 + carve_direction * carve_energy * 0.045
		character_sprite.scale = Vector2(sprite_scale, sprite_scale)
		return
	sprite_root.position = _world_to_screen(visual_pos)
	sprite_root.rotation = _visual_root_rotation()
	sprite_root.scale = Vector2.ONE / maxf(camera_zoom, 0.001)
	var climb_lean := clampf(-body_heading.y, -1.0, 1.0)
	var turn_lean := clampf(heading_angle_delta / 1.4, -1.0, 1.0)
	var scale_x := SPRITE_SCALE * (1.0 + 0.04 * boost_energy + 0.055 * carve_energy)
	var scale_y := SPRITE_SCALE * (1.0 - 0.025 * boost_energy - 0.035 * carve_energy)
	character_sprite.position = POSE_OFFSET + Vector2(-8.0 * boost_energy - 5.0 * carve_energy, -5.0 * climb_lean)
	character_sprite.rotation = climb_lean * 0.08 - turn_lean * 0.10 + carve_direction * carve_energy * 0.08
	character_sprite.scale = Vector2(render_sign * SHEET_FACE_SIGN * scale_x, scale_y)


func _apply_eight_way_texture(heading: Vector2) -> void:
	if eight_way_textures.is_empty():
		return
	var next_index := _get_eight_way_index(heading)
	eight_way_index = next_index
	var texture := eight_way_textures[next_index] as Texture2D
	if texture == null:
		return
	if character_sprite.texture == texture and not character_sprite.region_enabled:
		return
	character_sprite.texture = texture
	character_sprite.region_enabled = false
	character_sprite.region_rect = Rect2(Vector2.ZERO, texture.get_size())


func _get_eight_way_index(heading: Vector2) -> int:
	var safe_heading := heading
	if safe_heading.length_squared() <= 0.0001:
		safe_heading = Vector2.RIGHT
	else:
		safe_heading = safe_heading.normalized()
	var best_index := 0
	var best_dot := -9999.0
	for index in range(GEMINI_EIGHT_WAY_VECTORS.size()):
		var direction: Vector2 = GEMINI_EIGHT_WAY_VECTORS[index]
		var dot_value := safe_heading.dot(direction.normalized())
		if dot_value > best_dot:
			best_dot = dot_value
			best_index = index
	return best_index


func _current_eight_way_name() -> String:
	if GEMINI_EIGHT_WAY_NAMES.is_empty():
		return "none"
	return String(GEMINI_EIGHT_WAY_NAMES[clampi(eight_way_index, 0, GEMINI_EIGHT_WAY_NAMES.size() - 1)])


func _current_eight_way_set_label() -> String:
	if GEMINI_EIGHT_WAY_SET_LABELS.is_empty():
		return "unknown"
	return String(GEMINI_EIGHT_WAY_SET_LABELS[clampi(eight_way_character_set, 0, GEMINI_EIGHT_WAY_SET_LABELS.size() - 1)])


func _apply_frame() -> void:
	if character_sprite == null:
		return
	if USE_GEMINI_8WAY_CRUISE:
		return
	character_sprite.region_rect = _get_frame_rect(frame_index)


func _get_frame_rect(index: int) -> Rect2:
	var column := index % FRAME_COLUMNS
	var row := int(floor(float(index) / float(FRAME_COLUMNS)))
	return Rect2(Vector2(column, row) * CELL_SIZE, CELL_SIZE)


func _get_move_axis() -> Vector2:
	var manual_axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var arrow_axis := Vector2(
		float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	)
	if arrow_axis.length_squared() > 1.0:
		arrow_axis = arrow_axis.normalized()
	manual_axis += arrow_axis
	if manual_axis.length_squared() > 1.0:
		manual_axis = manual_axis.normalized()
	if auto_demo and (manual_axis.length_squared() > 0.01 or Input.is_action_pressed("dash")):
		auto_demo = false
	if auto_demo:
		var x := cos(time * 0.72)
		var y := sin(time * 1.08) * 0.64
		return Vector2(x, y).normalized()
	return manual_axis.normalized() if manual_axis.length_squared() > 1.0 else manual_axis


func _is_boost_pressed() -> bool:
	return auto_demo or Input.is_action_pressed("dash")


func _clip_phase() -> float:
	var clip := _current_clip()
	var frame_count := maxi(int(clip["frames"]) - 1, 1)
	return clampf(float(frame_index) / float(frame_count), 0.0, 1.0)


func _should_use_hard_turn() -> bool:
	return speed_mode == SPEED_MODE_BOOST or _is_hard_turn_clip()


func _begin_carve(direction: float) -> void:
	carve_direction = signf(direction)
	if carve_direction == 0.0:
		carve_direction = 1.0
	carve_timer = CARVE_DURATION
	hard_turn_request_timer = 0.12
	_capture_afterimage(flight_pos - _safe_velocity_dir() * 36.0, 0.92)
	_capture_afterimage(flight_pos - _safe_velocity_dir() * 72.0 + body_heading.rotated(carve_direction * PI * 0.5) * 10.0, 0.64)


func _signed_angle_between(from_dir: Vector2, to_dir: Vector2) -> float:
	if from_dir.length_squared() <= 0.0001 or to_dir.length_squared() <= 0.0001:
		return 0.0
	return wrapf(to_dir.angle() - from_dir.angle(), -PI, PI)


func _heading_render_sign(heading: Vector2, fallback_sign: float) -> float:
	if absf(heading.x) > 0.18:
		return signf(heading.x)
	return signf(fallback_sign) if fallback_sign != 0.0 else 1.0


func _render_rotation() -> float:
	var base_angle := body_heading.angle()
	if render_sign < 0.0:
		return wrapf(base_angle - PI, -PI, PI)
	return base_angle


func _visual_root_rotation() -> float:
	if bool(_current_clip().get("self_turn", false)):
		return 0.0
	return _render_rotation()


func _get_boundary_steer() -> Vector2:
	var steer := Vector2.ZERO
	var left_distance := flight_pos.x - PLAY_RECT.position.x
	var right_distance := PLAY_RECT.end.x - flight_pos.x
	var top_distance := flight_pos.y - PLAY_RECT.position.y
	var bottom_distance := PLAY_RECT.end.y - flight_pos.y
	if left_distance < BOUNDARY_SOFT_MARGIN:
		steer.x += 1.0 - clampf(left_distance / BOUNDARY_SOFT_MARGIN, 0.0, 1.0)
	if right_distance < BOUNDARY_SOFT_MARGIN:
		steer.x -= 1.0 - clampf(right_distance / BOUNDARY_SOFT_MARGIN, 0.0, 1.0)
	if top_distance < BOUNDARY_SOFT_MARGIN:
		steer.y += 1.0 - clampf(top_distance / BOUNDARY_SOFT_MARGIN, 0.0, 1.0)
	if bottom_distance < BOUNDARY_SOFT_MARGIN:
		steer.y -= 1.0 - clampf(bottom_distance / BOUNDARY_SOFT_MARGIN, 0.0, 1.0)
	return steer.limit_length(1.0)


func _apply_boundary_failsafe() -> void:
	var min_pos := PLAY_RECT.position
	var max_pos := PLAY_RECT.end
	if flight_pos.x < min_pos.x:
		flight_pos.x = min_pos.x
		velocity.x = absf(velocity.x) * 0.36
	elif flight_pos.x > max_pos.x:
		flight_pos.x = max_pos.x
		velocity.x = -absf(velocity.x) * 0.36
	if flight_pos.y < min_pos.y:
		flight_pos.y = min_pos.y
		velocity.y = absf(velocity.y) * 0.36
	elif flight_pos.y > max_pos.y:
		flight_pos.y = max_pos.y
		velocity.y = -absf(velocity.y) * 0.36


func _is_clip_looping() -> bool:
	return bool(_current_clip()["loop"])


func _is_turn_clip() -> bool:
	return clip_index == CLIP_CRUISE_TURN or _is_hard_turn_clip()


func _is_hard_turn_clip() -> bool:
	return clip_index == CLIP_HARD_TURN_CORE or clip_index == CLIP_HARD_TURN_TO_BOOST or clip_index == CLIP_HARD_TURN_TO_CRUISE


func _current_clip() -> Dictionary:
	return CLIPS[clip_index]


func _update_camera(delta: float) -> void:
	var zoom_target := lerpf(CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM, clampf((velocity.length() - CRUISE_SPEED * 0.55) / maxf(BOOST_SPEED - CRUISE_SPEED * 0.55, 1.0), 0.0, 1.0))
	camera_zoom = _damp_float(camera_zoom, zoom_target, CAMERA_ZOOM_HALF_LIFE, delta)
	var look_ahead := velocity * CAMERA_LOOK_AHEAD_TIME
	look_ahead.x = clampf(look_ahead.x, -CAMERA_MAX_LOOK_AHEAD.x, CAMERA_MAX_LOOK_AHEAD.x)
	look_ahead.y = clampf(look_ahead.y, -CAMERA_MAX_LOOK_AHEAD.y, CAMERA_MAX_LOOK_AHEAD.y)
	var target_center := _clamp_camera_center(flight_pos + look_ahead)
	if delta <= 0.0:
		camera_center = target_center
	else:
		camera_center = _damp_vector2(camera_center, target_center, CAMERA_HALF_LIFE, delta)


func _clamp_camera_center(center: Vector2) -> Vector2:
	var half_view := VIEW_SIZE * 0.5 * camera_zoom
	var min_center := PLAY_RECT.position + half_view
	var max_center := PLAY_RECT.end - half_view
	if max_center.x < min_center.x:
		min_center.x = PLAY_RECT.get_center().x
		max_center.x = min_center.x
	if max_center.y < min_center.y:
		min_center.y = PLAY_RECT.get_center().y
		max_center.y = min_center.y
	return center.clamp(min_center, max_center)


func _camera_origin() -> Vector2:
	return camera_center - VIEW_SIZE * 0.5 * camera_zoom


func _world_to_screen(world_pos: Vector2) -> Vector2:
	return (world_pos - camera_center) / maxf(camera_zoom, 0.001) + VIEW_SIZE * 0.5


func _get_visible_world_rect() -> Rect2:
	return Rect2(_camera_origin(), VIEW_SIZE * camera_zoom).intersection(PLAY_RECT)


func _update_afterimages(delta: float) -> void:
	for image in afterimages:
		image["age"] = float(image["age"]) + delta
	afterimages = afterimages.filter(func(image: Dictionary) -> bool: return float(image["age"]) <= float(image.get("life", 0.28)))

	var clip := _current_clip()
	var fast_enough := velocity.length() > 440.0 or _is_hard_turn_clip() or clip_index == CLIP_BOOST_IDLE
	if not fast_enough:
		return
	var min_distance := lerpf(54.0, 30.0, clampf(boost_energy + turn_energy + carve_energy, 0.0, 1.0))
	if afterimages.is_empty() or Vector2(afterimages[-1]["pos"]).distance_to(flight_pos) > min_distance:
		_capture_afterimage(flight_pos - _safe_velocity_dir() * 24.0, float(clip.get("smear_weight", 0.3)))


func _capture_afterimage(pos: Vector2, intensity: float) -> void:
	if USE_GEMINI_8WAY_CRUISE and character_sprite != null and character_sprite.texture != null:
		var texture := character_sprite.texture
		afterimages.append({
			"texture": texture,
			"source": Rect2(Vector2.ZERO, texture.get_size()),
			"pos": pos,
			"scale": character_sprite.scale.abs(),
			"facing": 1.0,
			"rotation": character_sprite.rotation,
			"age": 0.0,
			"life": 0.20 + 0.16 * clampf(intensity, 0.0, 1.0),
			"intensity": clampf(intensity, 0.0, 1.0),
			"velocity": velocity,
		})
		return
	if sheet_texture == null:
		return
	afterimages.append({
		"texture": sheet_texture,
		"source": _get_frame_rect(frame_index),
		"pos": pos,
		"scale": character_sprite.scale.abs(),
		"facing": render_sign * SHEET_FACE_SIGN,
		"rotation": _visual_root_rotation(),
		"age": 0.0,
		"life": 0.20 + 0.16 * clampf(intensity, 0.0, 1.0),
		"intensity": clampf(intensity, 0.0, 1.0),
		"velocity": velocity,
	})


func _update_trail(delta: float) -> void:
	for point in trail_points:
		point["age"] = float(point["age"]) + delta
	var max_life := 0.70 + 0.16 * clampf(boost_energy + turn_energy, 0.0, 1.0)
	trail_points = trail_points.filter(func(point: Dictionary) -> bool: return float(point["age"]) <= max_life)

	var anchor := _get_trail_anchor()
	var distance_threshold := lerpf(15.0, 8.0, clampf(boost_energy + turn_energy, 0.0, 1.0))
	if trail_points.is_empty() or Vector2(trail_points[-1]["pos"]).distance_to(anchor) > distance_threshold:
		var clip := _current_clip()
		trail_points.append({
			"pos": anchor,
			"age": 0.0,
			"life": max_life,
			"speed": velocity.length(),
			"weight": float(clip.get("trail_weight", 1.0)),
			"boost": boost_energy,
			"turn": turn_energy,
		})
	_update_trail_lines()


func _get_trail_anchor() -> Vector2:
	var clip := _current_clip()
	var offset: Vector2 = clip.get("trail_anchor", Vector2(-42.0, 90.0))
	var tail_dir := _safe_velocity_dir()
	var carve_side := Vector2.ZERO
	if carve_direction != 0.0:
		carve_side = tail_dir.rotated(carve_direction * PI * 0.5) * 14.0 * carve_energy
	var back_distance := absf(offset.x) + 10.0 + 16.0 * boost_energy + 12.0 * turn_energy + 10.0 * carve_energy
	var vertical_drop := offset.y * lerpf(0.55, 0.35, boost_energy)
	return visual_pos - tail_dir * back_distance + Vector2(0.0, vertical_drop) + carve_side


func _update_trail_lines() -> void:
	if trail_points.size() < 2:
		_apply_line(trail_halo, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		_apply_line(trail_ribbon, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		_apply_line(trail_core, PackedVector2Array(), 0.0, Color.TRANSPARENT)
		return

	var raw_points: Array = []
	var total_weight := 0.0
	var total_speed := 0.0
	var total_turn := 0.0
	var total_boost := 0.0
	for point in trail_points:
		raw_points.append(_world_to_screen(Vector2(point["pos"])))
		var life := clampf(1.0 - float(point["age"]) / maxf(float(point.get("life", 0.7)), 0.001), 0.0, 1.0)
		total_weight += float(point.get("weight", 1.0)) * life
		total_speed += float(point.get("speed", 0.0)) * life
		total_turn += float(point.get("turn", 0.0)) * life
		total_boost += float(point.get("boost", 0.0)) * life

	var count := maxf(float(trail_points.size()), 1.0)
	var avg_weight := total_weight / count
	var avg_speed := total_speed / count
	var avg_turn := total_turn / count
	var avg_boost := total_boost / count
	var speed_ratio := clampf(avg_speed / BOOST_SPEED, 0.0, 1.0)
	var width := (7.0 + speed_ratio * 22.0 + avg_boost * 10.0 + avg_turn * 18.0) * maxf(avg_weight, 0.35)
	width /= maxf(camera_zoom, 0.001)
	var alpha_scale := clampf(0.45 + speed_ratio * 0.36 + avg_boost * 0.24 + avg_turn * 0.22, 0.16, 1.0)
	var smooth_points := _build_smooth_points(raw_points)
	var halo := CYAN
	halo.a = 0.11 * alpha_scale
	var ribbon := Color(0.72, 1.0, 0.98, 0.22 * alpha_scale)
	var core := Color(0.96, 1.0, 0.98, 0.42 * alpha_scale)
	_apply_line(trail_halo, smooth_points, width * 2.8, halo)
	_apply_line(trail_ribbon, smooth_points, width * 0.72, ribbon)
	_apply_line(trail_core, smooth_points, maxf(width * 0.16, 2.0), core)


func _apply_line(line: Line2D, points: PackedVector2Array, width: float, color: Color) -> void:
	if line == null:
		return
	line.points = points
	line.width = width
	line.default_color = color


func _build_smooth_points(raw_points: Array) -> PackedVector2Array:
	var packed := PackedVector2Array()
	if raw_points.is_empty():
		return packed
	if raw_points.size() == 1:
		packed.append(raw_points[0])
		return packed
	for index in range(raw_points.size() - 1):
		var p0: Vector2 = raw_points[maxi(index - 1, 0)]
		var p1: Vector2 = raw_points[index]
		var p2: Vector2 = raw_points[index + 1]
		var p3: Vector2 = raw_points[mini(index + 2, raw_points.size() - 1)]
		for step in range(5):
			var t := float(step) / 5.0
			packed.append(_catmull_rom(p0, p1, p2, p3, t))
	packed.append(raw_points[raw_points.size() - 1])
	return packed


func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


func _draw() -> void:
	_draw_background()
	_draw_afterimages()
	_draw_debug()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.70, 0.75, 0.76, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.05, 0.065, 0.07, 0.10))
	_draw_mountain_band(0.25, 0.53, Color(0.13, 0.16, 0.16, 0.18), 0.0)
	_draw_mountain_band(0.52, 0.82, Color(0.04, 0.055, 0.056, 0.30), 1.7)
	_draw_world_guides()
	for i in range(18):
		var y_ratio := fmod(float(i) * 0.173 + 0.11, 1.0)
		var world_y := PLAY_RECT.position.y + PLAY_RECT.size.y * y_ratio + sin(time * 0.12 + float(i)) * 18.0
		var world_x := PLAY_RECT.position.x + fmod(time * (16.0 + float(i % 4) * 2.8) + float(i) * 431.0, PLAY_RECT.size.x + 420.0) - 210.0
		var screen_pos := _world_to_screen(Vector2(world_x, world_y))
		if Rect2(Vector2(-260.0, -80.0), VIEW_SIZE + Vector2(520.0, 160.0)).has_point(screen_pos):
			_draw_cloud_wisp(screen_pos, (145.0 + float(i % 3) * 48.0) / maxf(camera_zoom, 0.001), Color(0.94, 0.98, 0.98, 0.16))


func _draw_world_guides() -> void:
	var visible_rect := _get_visible_world_rect()
	if not visible_rect.has_area():
		return
	var start_x: float = floorf(visible_rect.position.x / WORLD_GRID_STEP) * WORLD_GRID_STEP
	var x: float = start_x
	while x <= visible_rect.end.x + WORLD_GRID_STEP:
		var alpha := 0.14 if int(round(x / WORLD_GRID_STEP)) % 5 == 0 else 0.055
		draw_line(
			_world_to_screen(Vector2(x, visible_rect.position.y)),
			_world_to_screen(Vector2(x, visible_rect.end.y)),
			Color(0.72, 0.92, 0.95, alpha),
			1.0
		)
		x += WORLD_GRID_STEP

	var start_y: float = floorf(visible_rect.position.y / WORLD_GRID_STEP) * WORLD_GRID_STEP
	var y: float = start_y
	while y <= visible_rect.end.y + WORLD_GRID_STEP:
		var alpha := 0.12 if int(round(y / WORLD_GRID_STEP)) % 3 == 0 else 0.05
		draw_line(
			_world_to_screen(Vector2(visible_rect.position.x, y)),
			_world_to_screen(Vector2(visible_rect.end.x, y)),
			Color(0.72, 0.92, 0.95, alpha),
			1.0
		)
		y += WORLD_GRID_STEP

	var rect_screen := Rect2(_world_to_screen(PLAY_RECT.position), PLAY_RECT.size / maxf(camera_zoom, 0.001))
	draw_rect(rect_screen, Color(0.22, 0.64, 0.72, 0.32), false, 2.0)


func _draw_mountain_band(top_ratio: float, bottom_ratio: float, color: Color, offset: float) -> void:
	var top := VIEW_SIZE.y * top_ratio
	var bottom := VIEW_SIZE.y * bottom_ratio
	var points := PackedVector2Array([Vector2(0.0, bottom)])
	for i in range(11):
		var x := VIEW_SIZE.x * float(i) / 10.0
		var ridge := top + 82.0 * absf(sin(float(i) * 1.13 + offset))
		points.append(Vector2(x, clampf(ridge, top, bottom - 20.0)))
	points.append(Vector2(VIEW_SIZE.x, bottom))
	draw_colored_polygon(points, color)


func _draw_cloud_wisp(origin: Vector2, length: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(12):
		var f := float(i) / 11.0
		points.append(origin + Vector2(length * (f - 0.5), sin(f * TAU + time * 0.18) * 7.0))
	draw_polyline(points, color, 5.0, true)


func _draw_afterimages() -> void:
	for image in afterimages:
		var texture := image.get("texture") as Texture2D
		if texture == null:
			continue
		var age := float(image["age"])
		var life := clampf(1.0 - age / maxf(float(image.get("life", 0.3)), 0.001), 0.0, 1.0)
		var frame_rect: Rect2 = image.get("source", Rect2())
		var draw_scale: Vector2 = image.get("scale", Vector2.ONE)
		var facing := float(image.get("facing", 1.0))
		var rotation := float(image.get("rotation", 0.0))
		var stored_velocity: Vector2 = image.get("velocity", Vector2.ZERO)
		var drift := stored_velocity.normalized() * -24.0 * age
		var pos := _world_to_screen(Vector2(image["pos"]) + drift)
		var stretch := 1.0 + age * (0.32 + float(image.get("intensity", 0.0)) * 0.18)
		var camera_scale := 1.0 / maxf(camera_zoom, 0.001)
		var source_size := frame_rect.size
		if source_size.x <= 0.0 or source_size.y <= 0.0:
			source_size = texture.get_size()
		var destination := Rect2(-source_size * draw_scale * stretch * camera_scale * 0.5, source_size * draw_scale * stretch * camera_scale)
		var color := Color(0.46, 1.0, 1.0, 0.06 * life * float(image.get("intensity", 1.0)))
		draw_set_transform(pos, rotation, Vector2(facing, 1.0))
		draw_texture_rect_region(texture, destination, frame_rect, color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_debug() -> void:
	var clip := _current_clip()
	var material_label := "green key" if background_key_enabled else "raw bg"
	var speed_label := "boost" if speed_mode == SPEED_MODE_BOOST else "cruise"
	var visual_label := "sheet"
	if USE_GEMINI_8WAY_CRUISE:
		visual_label = "Gemini 8way %s %s" % [_current_eight_way_set_label(), _current_eight_way_name()]
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 32.0), "Yujian flight v2  |  field %.0fx%.0f  |  WASD steering  Space throttle  K key  V set  F2 panel  T demo" % [FLIGHT_TEST_HORIZONTAL_SCALE, FLIGHT_TEST_VERTICAL_SCALE], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16.0, Color(0.91, 0.96, 0.95, 0.84))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 56.0), "clip: %s  frame: %d/%d  visual: %s  mode: %s  speed: %.1f  throttle %.2f slip %.2f carve %.2f turn %.0fdeg  body %.0fdeg target %.0fdeg  zoom %.2f  pos %.0f,%.0f  %s" % [String(clip["name"]), frame_index, int(clip["frames"]) - 1, visual_label, speed_label, velocity.length(), throttle_energy, slip_energy, carve_energy, rad_to_deg(heading_angle_delta), rad_to_deg(body_heading.angle()), rad_to_deg(target_heading.angle()), camera_zoom, flight_pos.x, flight_pos.y, material_label], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.72, 0.86, 0.86, 0.76))


func _safe_velocity_dir() -> Vector2:
	if velocity.length_squared() > 0.001:
		return velocity.normalized()
	return body_heading.normalized()


func _damp_float(current: float, target: float, half_life: float, delta: float) -> float:
	if half_life <= 0.0:
		return target
	var decay := pow(0.5, delta / half_life)
	return target + (current - target) * decay


func _damp_vector2(current: Vector2, target: Vector2, half_life: float, delta: float) -> Vector2:
	return Vector2(
		_damp_float(current.x, target.x, half_life, delta),
		_damp_float(current.y, target.y, half_life, delta)
	)
