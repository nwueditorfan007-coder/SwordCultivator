extends Node2D
class_name FlightRiderBodyRigFx

# V14/V15 分层 Rig：从 rig_manifest.json + pose_library.json
# 构建一个由 21 个 Sprite2D 组成的角色，按主场景状态在 5 个 pose 间插值切换，
# 并对头发/披帛施加速度滞后二级运动。
#
# 编辑模式（F2 切换）：
#   - 左键点击：拾取部件（按 z 序前到后），按下后立即进入拖拽
#   - 左键拖拽：移动选中部件
#   - 滚轮 / Q / E：旋转选中部件
#   - 方向键：微调位置（1 像素步进）
#   - Shift+方向键：粗调位置（10 像素步进）
#   - PageUp / PageDown：调整选中 z_index
#   - Tab：循环切换正在编辑的 pose
#   - F3 / Ctrl+S：把当前 pose 写回 JSON
#   - Esc：取消选择

const V14_MANIFEST_PATH := "res://resources/flight/rider/body_v14_rig/body_v14_rig_manifest.json"
const V14_POSE_LIBRARY_PATH := "res://resources/flight/rider/body_v14_rig/body_v14_pose_library.json"
const V14_PARTS_ROOT := "res://resources/flight/rider/body_v14_rig/"
const V15_MANIFEST_PATH := "res://resources/flight/rider/body_v15_ink_rig/body_v15_ink_rig_manifest.json"
const V15_POSE_LIBRARY_PATH := "res://resources/flight/rider/body_v15_ink_rig/body_v15_ink_pose_library.json"
const V15_PARTS_ROOT := "res://resources/flight/rider/body_v15_ink_rig/"

const LAG_FACTORS := {
	"hair_back": 0.6,
	"hair_tail": 1.0,
	"sash_back_root": 0.4,
	"sash_back_mid": 0.8,
	"sash_back_tip": 1.2,
	"sash_front_root": 0.4,
	"sash_front_mid": 0.8,
	"sash_front_tip": 1.2,
}

const EDIT_POSE_CYCLE := [
	"idle",
	"move_forward",
	"move_back",
	"high_speed_crouch",
	"turn_lean_left",
	"turn_lean_right",
	"sword_control_idle",
	"sword_control_commit",
	"sword_return_catch",
	"array_ring_idle",
	"array_fan_idle",
	"array_pierce_idle",
	"array_hold",
]

@export var enabled := true
@export_enum("v14", "v15_ink", "custom") var rig_asset_preset := "v14"
@export var custom_manifest_path := ""
@export var custom_pose_library_path := ""
@export var custom_parts_root := ""
@export_range(0.5, 30.0, 0.1) var pose_blend_speed := 8.0
@export_range(1.0, 60.0, 0.1) var lag_response := 18.0
@export_range(0.0, 2.0, 0.01) var lag_strength := 0.55
@export var use_pixel_filter := false
@export_range(-200.0, 200.0, 0.5) var character_y_anchor := 91.0
@export var enable_edit_hotkey := true

var main: Node2D = null
var assembly: Node2D
var sprites: Dictionary = {}
var manifest: Dictionary = {}
var pose_library: Dictionary = {}
var current_pose: Dictionary = {}
var target_pose_name: String = "idle"
var current_facing_sign: float = 1.0
var lag_offsets: Dictionary = {}
var active_manifest_path: String = ""
var active_pose_library_path: String = ""
var active_parts_root: String = ""

# 编辑模式状态
var edit_active: bool = false
var edit_pose_name: String = "idle"
var edit_pose_data: Dictionary = {}
var selected_part: String = ""
var drag_active: bool = false
var drag_start_mouse_pose: Vector2 = Vector2.ZERO
var drag_start_part_pos: Vector2 = Vector2.ZERO
var part_images: Dictionary = {}
var hud_layer: CanvasLayer = null
var hud_label: Label = null
var status_message: String = ""
var status_message_timer: float = 0.0


func _ready() -> void:
	main = get_parent() as Node2D
	z_as_relative = false
	z_index = 5
	if not _load_resources():
		push_warning("FlightRiderBodyRigFx: 资源加载失败，禁用节点")
		enabled = false
		return
	_build_assembly()
	_cache_part_images()
	_build_hud()
	set_process(true)
	set_process_input(true)


func _load_resources() -> bool:
	active_manifest_path = _resolve_manifest_path()
	active_pose_library_path = _resolve_pose_library_path()
	active_parts_root = _normalize_root_path(_resolve_parts_root())
	var manifest_text := _read_text(active_manifest_path)
	var pose_text := _read_text(active_pose_library_path)
	if manifest_text.is_empty() or pose_text.is_empty():
		return false
	manifest = JSON.parse_string(manifest_text)
	pose_library = JSON.parse_string(pose_text)
	return manifest is Dictionary and pose_library is Dictionary


func _resolve_manifest_path() -> String:
	match rig_asset_preset:
		"v15_ink":
			return V15_MANIFEST_PATH
		"custom":
			return custom_manifest_path if not custom_manifest_path.is_empty() else V14_MANIFEST_PATH
		_:
			return V14_MANIFEST_PATH


func _resolve_pose_library_path() -> String:
	match rig_asset_preset:
		"v15_ink":
			return V15_POSE_LIBRARY_PATH
		"custom":
			return custom_pose_library_path if not custom_pose_library_path.is_empty() else V14_POSE_LIBRARY_PATH
		_:
			return V14_POSE_LIBRARY_PATH


func _resolve_parts_root() -> String:
	match rig_asset_preset:
		"v15_ink":
			return V15_PARTS_ROOT
		"custom":
			return custom_parts_root if not custom_parts_root.is_empty() else V14_PARTS_ROOT
		_:
			return V14_PARTS_ROOT


func _normalize_root_path(path: String) -> String:
	if path.ends_with("/"):
		return path
	return path + "/"


func _join_resource_path(root: String, relative_path: String) -> String:
	if relative_path.begins_with("res://") or relative_path.begins_with("user://"):
		return relative_path
	return root + relative_path


func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var s := f.get_as_text()
	f.close()
	return s


func _build_assembly() -> void:
	assembly = Node2D.new()
	assembly.name = "Assembly"
	var s_val: float = float(pose_library.get("assembly_scale", 0.18))
	assembly.scale = Vector2.ONE * s_val
	assembly.position = Vector2(0.0, character_y_anchor)
	add_child(assembly)

	var parts: Dictionary = manifest.get("parts", {})
	for part_name in parts.keys():
		var part_def: Dictionary = parts[part_name]
		var sprite := Sprite2D.new()
		sprite.name = String(part_name)
		var tex: Texture2D = load(_join_resource_path(active_parts_root, str(part_def["file"]))) as Texture2D
		sprite.texture = tex
		sprite.centered = false
		var pivot: Array = part_def.get("pivot", [0.0, 0.0])
		sprite.offset = Vector2(-float(pivot[0]), -float(pivot[1]))
		sprite.texture_filter = _get_texture_filter()
		assembly.add_child(sprite)
		sprites[part_name] = sprite

	current_pose = _clone_pose(_get_pose_data("idle"))
	_apply_pose_to_sprites()


func _cache_part_images() -> void:
	for part_name in sprites.keys():
		var sprite: Sprite2D = sprites[part_name]
		if sprite.texture == null:
			continue
		var img: Image = sprite.texture.get_image()
		if img != null:
			part_images[part_name] = img


func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "RigEditHud"
	hud_layer.layer = 50
	hud_layer.visible = false
	add_child(hud_layer)
	hud_label = Label.new()
	hud_label.name = "EditInfo"
	hud_label.position = Vector2(16, 16)
	hud_label.add_theme_font_size_override("font_size", 14)
	hud_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	hud_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	hud_label.add_theme_constant_override("outline_size", 4)
	hud_layer.add_child(hud_label)


func _process(delta: float) -> void:
	if main == null or not is_instance_valid(main):
		main = get_parent() as Node2D
	if not _is_active():
		visible = false
		if hud_layer:
			hud_layer.visible = false
		return
	visible = true
	var player_pos: Vector2 = Vector2(main.player.get("pos", Vector2.ZERO))
	global_position = main._to_screen(player_pos)
	var visual_scale: float = clampf(float(main.get("flight_rider_visual_scale")), 0.35, 2.4)
	scale = Vector2.ONE * visual_scale
	if assembly != null:
		assembly.position.y = character_y_anchor

	if edit_active:
		# 编辑模式：固定使用 edit_pose_data，禁止 facing flip / lag / blend
		current_pose = edit_pose_data
		current_facing_sign = 1.0
		lag_offsets.clear()
	else:
		_update_target()
		_blend_pose(delta)
		_update_lag(delta)
	_apply_pose_to_sprites()

	if status_message_timer > 0.0:
		status_message_timer = maxf(status_message_timer - delta, 0.0)
		if status_message_timer <= 0.0:
			status_message = ""
	_update_hud()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _is_active():
		return
	# F2 切编辑模式（始终响应）
	if enable_edit_hotkey and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			_toggle_edit_mode()
			get_viewport().set_input_as_handled()
			return
	if not edit_active:
		return
	# ---- 编辑模式下接管这些输入 ----
	if event is InputEventKey and event.pressed and not event.echo:
		var handled := _handle_edit_key(event)
		if handled:
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_edit_mouse_down()
			else:
				drag_active = false
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_rotate_selected(-2.0)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_rotate_selected(2.0)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and drag_active:
		_handle_edit_drag()
		get_viewport().set_input_as_handled()


func _toggle_edit_mode() -> void:
	edit_active = not edit_active
	if edit_active:
		edit_pose_name = "idle"
		edit_pose_data = _clone_pose(_get_pose_data(edit_pose_name))
		selected_part = ""
		drag_active = false
		hud_layer.visible = true
		# 把鼠标释放，否则点击拖拽都没法用
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_set_status("已进入编辑模式：" + edit_pose_name + "（鼠标已释放）")
	else:
		selected_part = ""
		drag_active = false
		hud_layer.visible = false
		current_pose = _clone_pose(_get_pose_data(target_pose_name))
		# 恢复鼠标捕获，让 main 重新接管
		if main != null and main.has_method("_sync_desktop_mouse_visibility_to_game_state"):
			main.call("_sync_desktop_mouse_visibility_to_game_state")
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _handle_edit_key(event: InputEventKey) -> bool:
	var step: float = 10.0 if event.shift_pressed else 1.0
	match event.keycode:
		KEY_TAB:
			_cycle_edit_pose(1 if not event.shift_pressed else -1)
			return true
		KEY_F3:
			_save_pose_library()
			return true
		KEY_S:
			if event.ctrl_pressed or event.meta_pressed:
				_save_pose_library()
				return true
			return false
		KEY_ESCAPE:
			selected_part = ""
			drag_active = false
			return true
		KEY_Q:
			_rotate_selected(-2.0)
			return true
		KEY_E:
			_rotate_selected(2.0)
			return true
		KEY_LEFT:
			_nudge_selected(Vector2(-step, 0.0))
			return true
		KEY_RIGHT:
			_nudge_selected(Vector2(step, 0.0))
			return true
		KEY_UP:
			_nudge_selected(Vector2(0.0, -step))
			return true
		KEY_DOWN:
			_nudge_selected(Vector2(0.0, step))
			return true
		KEY_PAGEUP:
			_bump_selected_z(1)
			return true
		KEY_PAGEDOWN:
			_bump_selected_z(-1)
			return true
		KEY_H:
			# 隐藏选中（设置 scale 为 0 表示该 pose 该件不显示）—— 暂用 z=-99 标记
			# 这里仅作切换：恢复用 PageUp 提升 z
			return false
	return false


func _handle_edit_mouse_down() -> void:
	if assembly == null:
		return
	var pose_mouse: Vector2 = assembly.get_local_mouse_position()
	var hit := _hit_test(pose_mouse)
	if hit == "":
		selected_part = ""
		drag_active = false
		_set_status("未选中（点击空白）")
		return
	selected_part = hit
	drag_active = true
	drag_start_mouse_pose = pose_mouse
	var data: Dictionary = edit_pose_data.get(hit, {})
	var pos = data.get("position", [0, 0])
	drag_start_part_pos = Vector2(float(pos[0]), float(pos[1]))
	_set_status("选中：" + hit)


func _handle_edit_drag() -> void:
	if selected_part == "" or assembly == null:
		return
	var pose_mouse: Vector2 = assembly.get_local_mouse_position()
	var delta := pose_mouse - drag_start_mouse_pose
	var new_pos: Vector2 = drag_start_part_pos + delta
	var data: Dictionary = edit_pose_data.get(selected_part, {})
	data["position"] = [new_pos.x, new_pos.y]
	edit_pose_data[selected_part] = data


func _hit_test(pose_mouse: Vector2) -> String:
	# 按 z_index 从高到低，命中非透明像素的第一个
	var keys: Array = edit_pose_data.keys()
	keys.sort_custom(func(a, b): return int(edit_pose_data[a].get("z_index", 0)) > int(edit_pose_data[b].get("z_index", 0)))
	for part_name in keys:
		var sprite: Sprite2D = sprites.get(part_name)
		if sprite == null or sprite.texture == null:
			continue
		var sprite_local: Vector2 = sprite.to_local(assembly.to_global(pose_mouse))
		var px := int(round(sprite_local.x - sprite.offset.x))
		var py := int(round(sprite_local.y - sprite.offset.y))
		var img: Image = part_images.get(part_name)
		if img == null:
			continue
		if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
			continue
		if img.get_pixel(px, py).a > 0.2:
			return part_name
	return ""


func _rotate_selected(deg: float) -> void:
	if selected_part == "":
		return
	var data: Dictionary = edit_pose_data.get(selected_part, {})
	var cur := float(data.get("rotation_degrees", 0.0))
	data["rotation_degrees"] = fposmod(cur + deg + 180.0, 360.0) - 180.0
	edit_pose_data[selected_part] = data


func _nudge_selected(delta: Vector2) -> void:
	if selected_part == "":
		return
	var data: Dictionary = edit_pose_data.get(selected_part, {})
	var pos = data.get("position", [0, 0])
	var p := Vector2(float(pos[0]) + delta.x, float(pos[1]) + delta.y)
	data["position"] = [p.x, p.y]
	edit_pose_data[selected_part] = data


func _bump_selected_z(delta: int) -> void:
	if selected_part == "":
		return
	var data: Dictionary = edit_pose_data.get(selected_part, {})
	data["z_index"] = int(data.get("z_index", 0)) + delta
	edit_pose_data[selected_part] = data


func _cycle_edit_pose(direction: int) -> void:
	var idx: int = EDIT_POSE_CYCLE.find(edit_pose_name)
	if idx < 0:
		idx = 0
	idx = (idx + direction + EDIT_POSE_CYCLE.size()) % EDIT_POSE_CYCLE.size()
	edit_pose_name = EDIT_POSE_CYCLE[idx]
	edit_pose_data = _clone_pose(_get_pose_data(edit_pose_name))
	selected_part = ""
	drag_active = false
	_set_status("切到 pose：" + edit_pose_name)


func _save_pose_library() -> bool:
	if not pose_library.has("poses"):
		pose_library["poses"] = {}
	pose_library["poses"][edit_pose_name] = edit_pose_data
	var json_str := JSON.stringify(pose_library, "  ")
	var f := FileAccess.open(active_pose_library_path, FileAccess.WRITE)
	if f == null:
		_set_status("❌ 写文件失败 " + active_pose_library_path)
		return false
	f.store_string(json_str)
	f.close()
	_set_status("✓ 已保存 " + edit_pose_name + " 到 JSON")
	return true


func _set_status(msg: String) -> void:
	status_message = msg
	status_message_timer = 3.0


func _update_hud() -> void:
	if hud_label == null:
		return
	if not edit_active:
		hud_label.text = ""
		return
	var lines: Array[String] = []
	lines.append("[编辑模式] pose = " + edit_pose_name)
	lines.append("选中: " + (selected_part if selected_part != "" else "无"))
	if selected_part != "" and edit_pose_data.has(selected_part):
		var d: Dictionary = edit_pose_data[selected_part]
		var pos = d.get("position", [0, 0])
		lines.append("  pos = (%.1f, %.1f)  rot = %.1f°  z = %d" % [float(pos[0]), float(pos[1]), float(d.get("rotation_degrees", 0)), int(d.get("z_index", 0))])
	lines.append("")
	lines.append("F2 切编辑模式 | Tab 切 pose | F3/Ctrl+S 保存")
	lines.append("左键点选+拖拽 | 滚轮/Q/E 旋转 | 方向键微调（Shift 粗调）")
	lines.append("PageUp/Down 改 z_index | Esc 取消选择")
	if status_message != "":
		lines.append("")
		lines.append(">> " + status_message)
	hud_label.text = "\n".join(lines)


func _draw() -> void:
	if not edit_active or selected_part == "" or assembly == null:
		return
	var sprite: Sprite2D = sprites.get(selected_part)
	if sprite == null or sprite.texture == null:
		return
	# 在 sprite 的 4 个角画一圈高亮（在 rig fx 节点坐标系下画）
	var tex_size: Vector2 = sprite.texture.get_size()
	var corners_local := [
		sprite.offset,
		sprite.offset + Vector2(tex_size.x, 0),
		sprite.offset + tex_size,
		sprite.offset + Vector2(0, tex_size.y),
	]
	var corners_in_self := []
	for c in corners_local:
		# sprite local -> global -> 本节点 local
		var global_p: Vector2 = sprite.to_global(c)
		var self_p: Vector2 = to_local(global_p)
		corners_in_self.append(self_p)
	var hi := Color(1.0, 0.85, 0.25, 0.9)
	for i in range(corners_in_self.size()):
		var a: Vector2 = corners_in_self[i]
		var b: Vector2 = corners_in_self[(i + 1) % corners_in_self.size()]
		draw_line(a, b, hi, 1.5 / max(scale.x, 0.001))
	# 画 pivot 点
	var pivot_global: Vector2 = sprite.to_global(Vector2.ZERO)
	var pivot_self: Vector2 = to_local(pivot_global)
	draw_circle(pivot_self, 3.0 / max(scale.x, 0.001), Color(1.0, 0.4, 0.4, 0.95))


func _is_active() -> bool:
	if not enabled or main == null:
		return false
	if not main.has_method("_is_flight_prototype_mode") or not main._is_flight_prototype_mode():
		return false
	if bool(main.get("is_start_menu_active")):
		return false
	if main.has_method("_use_flight_rider_body_rig_fx"):
		return bool(main.call("_use_flight_rider_body_rig_fx"))
	return true


func _update_target() -> void:
	var action_state: Dictionary = main._get_rider_action_state() if main.has_method("_get_rider_action_state") else {}
	current_facing_sign = _resolve_facing_sign(action_state)
	var sustained := _resolve_sustained_action()
	var motion := _resolve_motion_pose()
	target_pose_name = sustained if sustained != "" else motion


func _resolve_sustained_action() -> String:
	if main == null:
		return ""
	if bool(main.get("right_mouse_held")):
		return "sword_control_idle"
	if main.sword != null and int(main.sword.get("state", main.SwordState.ORBITING)) != main.SwordState.ORBITING:
		return "sword_control_idle"
	if main.has_method("_should_use_rider_array_idle_pose") and bool(main.call("_should_use_rider_array_idle_pose")):
		return _array_idle_action(_get_array_mode())
	if bool(main.player.get("array_is_firing", false)) or float(main.player.get("array_hold_ratio", 0.0)) > 0.08:
		return _array_idle_action(_get_array_mode())
	return ""


func _resolve_motion_pose() -> String:
	if main == null:
		return "idle"
	var velocity := Vector2(main.player.get("vel", Vector2.ZERO))
	var speed: float = velocity.length()
	if speed <= 40.0:
		return "idle"
	var max_speed: float = maxf(float(main.FLIGHT_HORIZONTAL_SPEED), 1.0)
	var speed_ratio: float = speed / max_speed
	if speed_ratio >= 0.82 and _pose_exists("high_speed_crouch"):
		return "high_speed_crouch"
	if absf(velocity.y) > 180.0 and absf(velocity.y) > absf(velocity.x) * 0.75:
		var lean_pose := "turn_lean_left" if velocity.y < 0.0 else "turn_lean_right"
		if _pose_exists(lean_pose):
			return lean_pose
	var forward_speed: float = velocity.x * current_facing_sign
	if forward_speed > 120.0 and _pose_exists("move_forward"):
		return "move_forward"
	if forward_speed < -120.0 and _pose_exists("move_back"):
		return "move_back"
	return "idle"


func _pose_exists(name: String) -> bool:
	var poses: Dictionary = pose_library.get("poses", {})
	return poses.has(name)


func _get_array_mode() -> String:
	var raw := "ring"
	if main.has_method("_get_rider_body_array_mode"):
		raw = str(main.call("_get_rider_body_array_mode"))
	else:
		raw = str(main.player.get("array_mode", "ring"))
	if raw == "fan":
		return "fan"
	if raw == "pierce":
		return "pierce"
	return "ring"


func _array_idle_action(mode: String) -> String:
	return "array_%s_idle" % mode


func _resolve_facing_sign(action_state: Dictionary) -> float:
	var direction := Vector2.ZERO
	if not action_state.is_empty() and str(action_state.get("kind", "")) != "":
		direction = Vector2(action_state.get("direction", Vector2.ZERO))
	if direction.length_squared() <= 0.001 and main != null:
		direction = Vector2(main.get("mouse_world")) - Vector2(main.player.get("pos", Vector2.ZERO))
	if direction.length_squared() > 0.001 and absf(direction.x) > 0.28:
		return -1.0 if direction.x < 0.0 else 1.0
	var velocity := Vector2(main.player.get("vel", Vector2.ZERO))
	if absf(velocity.x) > 180.0:
		return -1.0 if velocity.x < 0.0 else 1.0
	return current_facing_sign


func _get_pose_data(name: String) -> Dictionary:
	var poses: Dictionary = pose_library.get("poses", {})
	if poses.has(name):
		return poses[name]
	return poses.get("idle", {})


func _clone_pose(src: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in src.keys():
		var v: Dictionary = src[k]
		out[k] = {
			"position": [float(v["position"][0]), float(v["position"][1])],
			"rotation_degrees": float(v.get("rotation_degrees", 0.0)),
			"scale": [float(v.get("scale", [1.0, 1.0])[0]), float(v.get("scale", [1.0, 1.0])[1])],
			"z_index": int(v.get("z_index", 0)),
		}
	return out


func _blend_pose(delta: float) -> void:
	var target: Dictionary = _get_pose_data(target_pose_name)
	if target.is_empty():
		return
	var t: float = clampf(pose_blend_speed * delta, 0.0, 1.0)
	for part_name in current_pose.keys():
		if not target.has(part_name):
			continue
		var cur: Dictionary = current_pose[part_name]
		var tgt: Dictionary = target[part_name]
		var cur_pos := Vector2(float(cur["position"][0]), float(cur["position"][1]))
		var tgt_pos := Vector2(float(tgt["position"][0]), float(tgt["position"][1]))
		var new_pos: Vector2 = cur_pos.lerp(tgt_pos, t)
		var cur_rot: float = deg_to_rad(float(cur["rotation_degrees"]))
		var tgt_rot: float = deg_to_rad(float(tgt["rotation_degrees"]))
		var new_rot: float = lerp_angle(cur_rot, tgt_rot, t)
		current_pose[part_name] = {
			"position": [new_pos.x, new_pos.y],
			"rotation_degrees": rad_to_deg(new_rot),
			"scale": tgt.get("scale", [1.0, 1.0]),
			"z_index": int(tgt.get("z_index", 0)),
		}


func _update_lag(delta: float) -> void:
	if main == null:
		return
	var velocity := Vector2(main.player.get("vel", Vector2.ZERO))
	var max_speed: float = maxf(float(main.FLIGHT_HORIZONTAL_SPEED), 1.0)
	var v_norm: Vector2 = velocity / max_speed
	var base: Vector2 = -v_norm * 90.0 * lag_strength
	var response: float = clampf(lag_response * delta, 0.0, 1.0)
	for part_name in LAG_FACTORS.keys():
		var factor: float = float(LAG_FACTORS[part_name])
		var target_lag: Vector2 = base * factor
		var current: Vector2 = lag_offsets.get(part_name, Vector2.ZERO)
		lag_offsets[part_name] = current.lerp(target_lag, response)


func _apply_pose_to_sprites() -> void:
	var flip: bool = current_facing_sign < 0.0
	for part_name in current_pose.keys():
		var sprite: Sprite2D = sprites.get(part_name)
		if sprite == null:
			continue
		var data: Dictionary = current_pose[part_name]
		var pos := Vector2(float(data["position"][0]), float(data["position"][1]))
		if flip:
			pos.x = -pos.x
		if lag_offsets.has(part_name):
			pos += lag_offsets[part_name]
		sprite.position = pos
		var rot: float = deg_to_rad(float(data["rotation_degrees"]))
		if flip:
			rot = -rot
		sprite.rotation = rot
		sprite.flip_h = flip
		sprite.z_index = int(data["z_index"])


func _get_texture_filter() -> CanvasItem.TextureFilter:
	return CanvasItem.TEXTURE_FILTER_NEAREST if use_pixel_filter else CanvasItem.TEXTURE_FILTER_LINEAR
