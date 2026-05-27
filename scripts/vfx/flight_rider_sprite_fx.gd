extends Node2D
class_name FlightRiderSpriteFx

const DEFAULT_BODY_SHEET: Texture2D = preload("res://resources/flight/rider/flight_rider_body_v13_1_sheet.png")
const DEFAULT_BODY_TRANSITION_SHEET: Texture2D = preload("res://resources/flight/rider/flight_rider_body_v13_1_transitions.png")
const DEFAULT_WEAPON_SHEET: Texture2D = preload("res://resources/flight/rider/flight_rider_weapon_v3_sheet.png")
const DEFAULT_MOUNT_SHEET: Texture2D = preload("res://resources/flight/rider/flight_rider_mount_v3_sheet.png")
const DEFAULT_LEGACY_RIDER_SHEET: Texture2D = preload("res://resources/flight/rider/flight_rider_ink_sheet.png")
const DEFAULT_FRAME_SIZE := Vector2i(256, 256)
const DEFAULT_FRAME_COUNT := 16
const BODY_ACTION_ROWS := {
	"idle": 0,
	"forward": 1,
	"back": 2,
	"parry": 3,
	"sword_control_idle": 4,
	"array_ring_idle": 5,
	"array_fan_idle": 6,
	"array_pierce_idle": 7,
	"array_ring_release": 8,
	"array_fan_release": 9,
	"array_pierce_release": 10,
}
const BODY_TRANSITION_ROWS := {
	"idle_to_sword_control": 0,
	"sword_control_to_idle": 1,
	"idle_to_array_ring": 2,
	"array_ring_to_idle": 3,
	"idle_to_array_fan": 4,
	"array_fan_to_idle": 5,
	"idle_to_array_pierce": 6,
	"array_pierce_to_idle": 7,
	"array_ring_to_fan": 8,
	"array_fan_to_ring": 9,
	"array_fan_to_pierce": 10,
	"array_pierce_to_fan": 11,
	"array_pierce_to_ring": 12,
	"array_ring_to_pierce": 13,
}
const LEGACY_LAYER_ACTION_ROWS := {
	"idle": 0,
	"forward": 1,
	"back": 2,
	"parry": 3,
	"sword_control_idle": 4,
	"array_ring_idle": 6,
	"array_fan_idle": 6,
	"array_pierce_idle": 6,
	"array_ring_release": 5,
	"array_fan_release": 5,
	"array_pierce_release": 5,
}
const HAND_HILT_SOCKETS := {
	"idle": [Vector2(34.0, -23.0), Vector2(35.0, -24.0), Vector2(36.0, -23.0), Vector2(35.0, -22.0), Vector2(34.0, -23.0), Vector2(33.0, -24.0), Vector2(34.0, -23.0), Vector2(35.0, -22.0)],
	"forward": [Vector2(42.0, -21.0), Vector2(45.0, -21.0), Vector2(47.0, -20.0), Vector2(46.0, -19.0), Vector2(43.0, -18.0), Vector2(41.0, -19.0), Vector2(42.0, -21.0), Vector2(44.0, -22.0)],
	"back": [Vector2(28.0, -27.0), Vector2(26.0, -28.0), Vector2(24.0, -27.0), Vector2(23.0, -25.0), Vector2(24.0, -24.0), Vector2(26.0, -24.0), Vector2(28.0, -25.0), Vector2(29.0, -26.0)],
	"parry": [Vector2(24.0, -44.0), Vector2(31.0, -40.0), Vector2(42.0, -32.0), Vector2(55.0, -20.0), Vector2(58.0, -14.0), Vector2(51.0, -10.0), Vector2(40.0, -8.0), Vector2(32.0, -10.0)],
	"sword_control_idle": [Vector2(66.0, -29.0), Vector2(62.0, -25.0), Vector2(55.0, -21.0), Vector2(45.0, -20.0), Vector2(55.0, -21.0), Vector2(62.0, -25.0), Vector2(66.0, -29.0), Vector2(62.0, -25.0)],
	"array_ring_idle": [Vector2(34.0, -26.0), Vector2(34.0, -26.0), Vector2(34.0, -26.0), Vector2(36.0, -24.0), Vector2(34.0, -26.0), Vector2(34.0, -26.0), Vector2(34.0, -26.0), Vector2(36.0, -24.0)],
	"array_fan_idle": [Vector2(50.0, -42.0), Vector2(50.0, -42.0), Vector2(50.0, -42.0), Vector2(50.0, -42.0), Vector2(50.0, -42.0), Vector2(50.0, -42.0), Vector2(50.0, -42.0), Vector2(50.0, -42.0)],
	"array_pierce_idle": [Vector2(45.0, -48.0), Vector2(45.0, -48.0), Vector2(45.0, -48.0), Vector2(45.0, -48.0), Vector2(45.0, -48.0), Vector2(45.0, -48.0), Vector2(45.0, -48.0), Vector2(45.0, -48.0)],
	"array_release": [Vector2(30.0, -24.0), Vector2(34.0, -32.0), Vector2(40.0, -42.0), Vector2(44.0, -48.0), Vector2(42.0, -48.0), Vector2(37.0, -44.0), Vector2(34.0, -36.0), Vector2(32.0, -28.0)],
}
const HAND_HILT_ANGLES_DEG := {
	"idle": [-10.0, -9.0, -7.0, -8.0, -10.0, -11.0, -10.0, -8.0],
	"forward": [-13.0, -10.0, -7.0, -4.0, -5.0, -8.0, -12.0, -14.0],
	"back": [-24.0, -22.0, -18.0, -14.0, -11.0, -14.0, -18.0, -22.0],
	"parry": [-62.0, -54.0, -42.0, -24.0, -10.0, 4.0, 16.0, 22.0],
	"sword_control_idle": [5.0, 6.0, 3.0, -2.0, 3.0, 6.0, 5.0, 6.0],
	"array_ring_idle": [-14.0, -14.0, -14.0, -14.0, -14.0, -14.0, -14.0, -14.0],
	"array_fan_idle": [12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0],
	"array_pierce_idle": [24.0, 24.0, 24.0, 24.0, 24.0, 24.0, 24.0, 24.0],
	"array_release": [-10.0, -4.0, 2.0, 8.0, 12.0, 8.0, 2.0, -6.0],
}
const SUSTAINED_FRAME_SEQUENCES := {
	"sword_control_idle": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
	"array_ring_idle": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
	"array_fan_idle": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
	"array_pierce_idle": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
}

const ART_BLUE := Color("88d8ff")
const ART_BLUE_CORE := Color("f6fbff")
const ART_GOLD := Color("d7bb79")

@export_group("FrameRonin Layers")
@export var body_sheet: Texture2D = DEFAULT_BODY_SHEET
@export var body_transition_sheet: Texture2D = DEFAULT_BODY_TRANSITION_SHEET
@export var weapon_sheet: Texture2D = DEFAULT_WEAPON_SHEET
@export var mount_sheet: Texture2D = DEFAULT_MOUNT_SHEET
@export var frame_size := DEFAULT_FRAME_SIZE
@export_range(1, 32, 1) var frame_count := DEFAULT_FRAME_COUNT
@export var use_pixel_filter := false
@export_group("Legacy Fallback")
@export var rider_sheet: Texture2D = null
@export_group("")
@export var enabled := true
@export_range(0.0, 2.0, 0.01) var body_alpha := 1.0
@export_range(0.0, 2.0, 0.01) var weapon_alpha := 0.0
@export_range(0.0, 2.0, 0.01) var mount_alpha := 0.0
@export_range(1.0, 24.0, 0.1) var idle_animation_fps := 9.0
@export_range(1.0, 30.0, 0.1) var motion_animation_fps := 16.0
@export_range(1.0, 30.0, 0.1) var action_animation_fps := 22.0
@export_range(1.0, 12.0, 0.1) var sword_control_idle_animation_fps := 3.2
@export_range(1.0, 12.0, 0.1) var array_idle_animation_fps := 2.4
@export_range(0.0, 1.0, 0.01) var mount_wake_alpha := 0.32
@export_range(0.0, 1.0, 0.01) var resonance_alpha := 0.28

var main: Node2D = null
var mount_sprite: Sprite2D
var echo_sprite: Sprite2D
var body_sprite: Sprite2D
var weapon_sprite: Sprite2D
var local_time := 0.0
var current_action := "idle"
var current_frame := 0
var current_facing_sign := 1.0
var current_uses_transition_sheet := false


func _ready() -> void:
	main = get_parent() as Node2D
	z_as_relative = false
	z_index = 5
	_build_sprites()
	set_process(true)


func uses_layered_sheets() -> bool:
	return true


func draws_mount_sheet() -> bool:
	return _get_mount_sheet() != null and mount_alpha > 0.001


func draws_weapon_sheet() -> bool:
	return _get_weapon_sheet() != null and weapon_alpha > 0.001


func _build_sprites() -> void:
	mount_sprite = _create_sprite(_get_mount_sheet(), -2)
	echo_sprite = _create_sprite(_get_body_sheet(), -1)
	echo_sprite.modulate = Color(0.46, 0.85, 1.0, 0.14)
	echo_sprite.position = Vector2(-4.0, 3.0)
	body_sprite = _create_sprite(_get_body_sheet(), 0)
	weapon_sprite = _create_sprite(_get_weapon_sheet(), 1)


func _create_sprite(texture: Texture2D, z_index_value: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, Vector2(_get_frame_size()))
	sprite.z_index = z_index_value
	sprite.texture_filter = _get_texture_filter()
	add_child(sprite)
	return sprite


func _process(delta: float) -> void:
	local_time += delta
	if main == null or not is_instance_valid(main):
		main = get_parent() as Node2D
	if not _is_active():
		visible = false
		return
	visible = true
	var player_pos: Vector2 = Vector2(main.player.get("pos", Vector2.ZERO))
	global_position = main._to_screen(player_pos)
	var visual_scale: float = clampf(float(main.get("flight_rider_visual_scale")), 0.35, 2.4)
	scale = Vector2.ONE * visual_scale
	_update_action_frame()
	_update_sprite_region()
	queue_redraw()


func _draw() -> void:
	if not visible or main == null:
		return
	_draw_procedural_mount()
	_draw_mount_wake()
	_draw_local_resonance()


func _is_active() -> bool:
	if not enabled or main == null:
		return false
	if main.has_method("_uses_flight_visuals"):
		if not bool(main.call("_uses_flight_visuals")):
			return false
	elif not main.has_method("_is_flight_prototype_mode") or not main._is_flight_prototype_mode():
		return false
	if bool(main.get("is_start_menu_active")):
		return false
	if main.has_method("_use_flight_rider_sprite_fx") and not bool(main.call("_use_flight_rider_sprite_fx")):
		return false
	return true


func _update_action_frame() -> void:
	var pose_state := _resolve_pose_state()
	current_action = str(pose_state.get("action", "idle"))
	current_frame = int(pose_state.get("frame", 0))
	current_facing_sign = float(pose_state.get("facing_sign", 1.0))
	current_uses_transition_sheet = bool(pose_state.get("uses_transition_sheet", false))


func _resolve_pose_state(action_state: Dictionary = {}) -> Dictionary:
	if main == null or not is_instance_valid(main):
		main = get_parent() as Node2D
	if main == null:
		return {
			"action": "idle",
			"frame": 0,
			"facing_sign": current_facing_sign,
			"uses_transition_sheet": false,
		}
	var flight_push: float = _get_flight_push()
	if action_state.is_empty():
		action_state = main._get_rider_action_state() if main.has_method("_get_rider_action_state") else {}
	var action_kind: String = str(action_state.get("kind", ""))
	var action_progress: float = clampf(float(action_state.get("progress", 0.0)), 0.0, 1.0)
	if main.has_method("_is_melee_swing_visual_active") and main._is_melee_swing_visual_active():
		action_kind = "parry"
		if main.has_method("_get_melee_swing_progress"):
			action_progress = clampf(main._get_melee_swing_progress(), 0.0, 1.0)

	var facing_sign: float = _resolve_facing_sign(action_state, flight_push)
	var has_melee_parry: bool = action_kind == "parry" and main.has_method("_is_melee_swing_visual_active") and main._is_melee_swing_visual_active()
	var has_timed_body_action: bool = BODY_ACTION_ROWS.has(action_kind) and (float(action_state.get("timer", 0.0)) > 0.0 or has_melee_parry)
	var has_timed_transition: bool = BODY_TRANSITION_ROWS.has(action_kind) and float(action_state.get("timer", 0.0)) > 0.0
	var resolved_action := "idle"
	var resolved_frame := 0
	var resolved_frame_count := _get_frame_count()
	var uses_transition_sheet := false
	if has_timed_body_action:
		resolved_action = action_kind
		resolved_frame = _sample_timed_frame(resolved_action, action_progress, resolved_frame_count)
	elif has_timed_transition:
		resolved_action = action_kind
		resolved_frame = _sample_timed_frame(resolved_action, action_progress, resolved_frame_count)
		uses_transition_sheet = true
	else:
		var sustained_action: String = _resolve_sustained_action()
		if sustained_action != "":
			resolved_action = sustained_action
			resolved_frame = _sample_sustained_frame(sustained_action, resolved_frame_count)
		else:
			var relative_push: float = flight_push * facing_sign
			if relative_push > 0.18:
				resolved_action = "forward"
			elif relative_push < -0.18:
				resolved_action = "back"
			else:
				resolved_action = "idle"
			var speed_ratio: float = clampf(absf(relative_push), 0.0, 1.0)
			var fps: float = lerpf(idle_animation_fps, motion_animation_fps, speed_ratio)
			resolved_frame = int(floor(local_time * fps)) % resolved_frame_count

	return {
		"action": resolved_action,
		"frame": resolved_frame,
		"facing_sign": facing_sign,
		"uses_transition_sheet": uses_transition_sheet,
	}


func _resolve_sustained_action() -> String:
	if main == null or not is_instance_valid(main):
		return ""
	if bool(main.get("right_mouse_held")):
		return "sword_control_idle"
	if main.sword != null and int(main.sword.get("state", main.SwordState.ORBITING)) != main.SwordState.ORBITING:
		return "sword_control_idle"
	if main.has_method("_should_use_rider_array_idle_pose") and bool(main.call("_should_use_rider_array_idle_pose")):
		return _get_array_idle_action(_get_current_array_mode())
	if bool(main.player.get("array_is_firing", false)) or float(main.player.get("array_hold_ratio", 0.0)) > 0.08:
		return _get_array_idle_action(_get_current_array_mode())
	return ""


func _get_current_array_mode() -> String:
	if main == null or not is_instance_valid(main):
		return "ring"
	var mode := "ring"
	if main.has_method("_get_rider_body_array_mode"):
		mode = str(main.call("_get_rider_body_array_mode"))
	elif main.has_method("_get_sword_array_fire_state"):
		var fire_state: Dictionary = main._get_sword_array_fire_state()
		mode = str(fire_state.get("dominant_mode", mode))
	else:
		mode = str(main.player.get("array_mode", mode))
	return _normalize_array_mode(mode)


func _normalize_array_mode(mode: String) -> String:
	match mode:
		"fan":
			return "fan"
		"pierce":
			return "pierce"
		_:
			return "ring"


func _get_array_idle_action(mode: String) -> String:
	return "array_%s_idle" % _normalize_array_mode(mode)


func _get_sustained_animation_fps(action: String) -> float:
	if action == "sword_control_idle":
		return sword_control_idle_animation_fps
	if action.begins_with("array_") and action.ends_with("_idle"):
		return array_idle_animation_fps
	return action_animation_fps


func _sample_sustained_frame(action: String, frame_count: int) -> int:
	var sequence: Array = SUSTAINED_FRAME_SEQUENCES.get(action, [])
	var sequence_size := sequence.size()
	if sequence_size > 0:
		var sequence_index: int = int(floor(local_time * _get_sustained_animation_fps(action))) % sequence_size
		return clampi(int(sequence[sequence_index]), 0, frame_count - 1)
	return int(floor(local_time * _get_sustained_animation_fps(action))) % frame_count


func _sample_timed_frame(action: String, progress: float, frame_count: int) -> int:
	var readable_progress: float = clampf(progress, 0.0, 0.999)
	if _should_hold_timed_action_endpoints(action):
		readable_progress = _apply_endpoint_hold(readable_progress, 0.08, 0.10)
	return clampi(int(floor(readable_progress * float(frame_count))), 0, frame_count - 1)


func _should_hold_timed_action_endpoints(action: String) -> bool:
	return (
		action == "parry"
		or BODY_TRANSITION_ROWS.has(action)
		or (action.begins_with("array_") and action.ends_with("_release"))
	)


func _apply_endpoint_hold(progress: float, start_hold: float, end_hold: float) -> float:
	if progress <= start_hold:
		return 0.0
	if progress >= 1.0 - end_hold:
		return 0.999
	var span: float = maxf(1.0 - start_hold - end_hold, 0.001)
	return clampf((progress - start_hold) / span, 0.0, 0.999)


func get_hand_hilt_pose(action_state: Dictionary = {}) -> Dictionary:
	var pose_state := _resolve_pose_state(action_state)
	var action: String = str(pose_state.get("action", "idle"))
	var frame: int = clampi(int(pose_state.get("frame", 0)), 0, _get_frame_count() - 1)
	var facing_sign: float = float(pose_state.get("facing_sign", 1.0))
	var hilt_action: String = _resolve_hilt_action(action)
	var sockets: Array = HAND_HILT_SOCKETS.get(hilt_action, HAND_HILT_SOCKETS["idle"])
	var angles: Array = HAND_HILT_ANGLES_DEG.get(hilt_action, HAND_HILT_ANGLES_DEG["idle"])
	var local_hilt: Vector2 = Vector2(_sample_frame_value(sockets, frame, Vector2.ZERO))
	var local_angle: float = deg_to_rad(float(_sample_frame_value(angles, frame, 0.0)))
	if facing_sign < 0.0:
		local_hilt.x = -local_hilt.x
		local_angle = PI - local_angle
	return {
		"action": action,
		"frame": frame,
		"local_hilt": local_hilt,
		"angle": local_angle,
		"forward": Vector2.RIGHT.rotated(local_angle),
		"facing_sign": facing_sign,
	}


func _resolve_hilt_action(action: String) -> String:
	if HAND_HILT_SOCKETS.has(action):
		return action
	if action.begins_with("array_") and action.ends_with("_release"):
		return "array_release"
	if action.find("sword_control") >= 0:
		return "sword_control_idle"
	if action.begins_with("array_"):
		var parts := action.split("_")
		if parts.size() >= 3:
			return _get_array_idle_action(str(parts[1]))
	return "idle"


func _update_sprite_region() -> void:
	var row: int = int(BODY_TRANSITION_ROWS.get(current_action, 0)) if current_uses_transition_sheet else int(BODY_ACTION_ROWS.get(current_action, 0))
	var size := _get_frame_size()
	var region := Rect2(
		Vector2(float(current_frame * size.x), float(row * size.y)),
		Vector2(size)
	)
	var body_texture: Texture2D = _get_current_body_sheet()
	var legacy_region := _get_legacy_layer_region()
	_apply_sprite_region(mount_sprite, _get_mount_sheet(), legacy_region, mount_alpha)
	_apply_sprite_region(echo_sprite, body_texture, region, 0.14)
	_apply_sprite_region(body_sprite, body_texture, region, body_alpha)
	_apply_sprite_region(weapon_sprite, _get_weapon_sheet(), legacy_region, weapon_alpha)
	echo_sprite.visible = current_action != "idle" and body_sprite.visible


func _apply_sprite_region(sprite: Sprite2D, texture: Texture2D, region: Rect2, alpha: float) -> void:
	if sprite == null:
		return
	sprite.texture = texture
	sprite.visible = texture != null and alpha > 0.001
	if not sprite.visible:
		return
	sprite.texture_filter = _get_texture_filter()
	sprite.region_rect = region
	sprite.flip_h = current_facing_sign < 0.0
	sprite.modulate = Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0))


func _resolve_facing_sign(action_state: Dictionary, flight_push: float) -> float:
	var direction := Vector2.ZERO
	if not action_state.is_empty() and (float(action_state.get("timer", 0.0)) > 0.0 or str(action_state.get("kind", "")) != ""):
		direction = Vector2(action_state.get("direction", Vector2.ZERO))
	if direction.length_squared() <= 0.001 and main != null:
		direction = Vector2(main.get("mouse_world")) - Vector2(main.player.get("pos", Vector2.ZERO))
	if direction.length_squared() > 0.001 and absf(direction.x) > 0.28:
		return -1.0 if direction.x < 0.0 else 1.0
	if absf(flight_push) > 0.54:
		return -1.0 if flight_push < 0.0 else 1.0
	return current_facing_sign


func _get_flight_push() -> float:
	if main == null:
		return 0.0
	var velocity := Vector2(main.player.get("vel", Vector2.ZERO))
	var max_speed: float = maxf(float(main.FLIGHT_HORIZONTAL_SPEED), 1.0)
	return clampf(velocity.x / max_speed, -1.0, 1.0)


func _get_current_body_sheet() -> Texture2D:
	if current_uses_transition_sheet and _get_body_transition_sheet() != null:
		return _get_body_transition_sheet()
	return _get_body_sheet()


func _get_legacy_layer_region() -> Rect2:
	var size := _get_frame_size()
	var legacy_action: String = _resolve_legacy_layer_action(current_action)
	var row: int = int(LEGACY_LAYER_ACTION_ROWS.get(legacy_action, 0))
	return Rect2(
		Vector2(float(current_frame * size.x), float(row * size.y)),
		Vector2(size)
	)


func _resolve_legacy_layer_action(action: String) -> String:
	if LEGACY_LAYER_ACTION_ROWS.has(action):
		return action
	if action.find("sword_control") >= 0:
		return "sword_control_idle"
	if action.begins_with("array_") and action.ends_with("_release"):
		var release_parts := action.split("_")
		if release_parts.size() >= 3:
			return "array_%s_release" % _normalize_array_mode(str(release_parts[1]))
	if action.begins_with("array_"):
		var parts := action.split("_")
		if parts.size() >= 3:
			return _get_array_idle_action(str(parts[1]))
	return "idle"


func _get_body_sheet() -> Texture2D:
	if body_sheet != null:
		return body_sheet
	if rider_sheet != null:
		return rider_sheet
	return DEFAULT_BODY_SHEET


func _get_body_transition_sheet() -> Texture2D:
	return body_transition_sheet if body_transition_sheet != null else DEFAULT_BODY_TRANSITION_SHEET


func _get_weapon_sheet() -> Texture2D:
	return weapon_sheet if weapon_sheet != null else DEFAULT_WEAPON_SHEET


func _get_mount_sheet() -> Texture2D:
	return mount_sheet if mount_sheet != null else DEFAULT_MOUNT_SHEET


func _get_frame_size() -> Vector2i:
	return Vector2i(maxi(1, frame_size.x), maxi(1, frame_size.y))


func _get_frame_count() -> int:
	return maxi(1, int(frame_count))


func _get_texture_filter() -> CanvasItem.TextureFilter:
	return CanvasItem.TEXTURE_FILTER_NEAREST if use_pixel_filter else CanvasItem.TEXTURE_FILTER_LINEAR


func _sample_frame_value(values: Array, frame: int, default_value):
	if values.is_empty():
		return default_value
	if values.size() == _get_frame_count():
		return values[clampi(frame, 0, values.size() - 1)]
	var max_frame := maxf(float(_get_frame_count() - 1), 1.0)
	var sample_ratio := float(frame) / max_frame
	var sample_index := clampi(int(round(sample_ratio * float(values.size() - 1))), 0, values.size() - 1)
	return values[sample_index]


func _draw_mount_wake() -> void:
	var flight_push: float = _get_flight_push()
	if absf(flight_push) <= 0.07 or mount_wake_alpha <= 0.001:
		return
	var wake_dir := Vector2(-signf(flight_push), 0.0)
	var center := Vector2(0.0 + flight_push * 3.0, 91.0 + sin(float(main.get("elapsed_time")) * 3.2) * 0.8)
	for index in range(2):
		var wake_offset := Vector2(-18.0 - float(index) * 18.0, 4.0 + float(index) * 3.5)
		var wake_len: float = 18.0 + absf(flight_push) * 22.0 - float(index) * 3.0
		draw_line(
			center + wake_offset,
			center + wake_offset + wake_dir * wake_len,
			_alpha(ART_BLUE_CORE, (0.026 + 0.030 * absf(flight_push)) * mount_wake_alpha),
			0.9 + float(index) * 0.25
		)


func _draw_procedural_mount() -> void:
	if draws_mount_sheet():
		return
	var flight_push: float = _get_flight_push()
	var time: float = float(main.get("elapsed_time"))
	var center := Vector2(flight_push * 6.0, 91.0 + sin(time * 3.2) * 1.2)
	var forward := Vector2.RIGHT
	var side := Vector2.DOWN
	var pressure: float = clampf(absf(flight_push), 0.0, 1.0)
	var blade_back := center - forward * (76.0 + 10.0 * pressure)
	var blade_tip := center + forward * (92.0 + 8.0 * pressure)
	var platform := PackedVector2Array([
		blade_back - side * 5.0,
		blade_tip - side * 2.0,
		blade_tip + forward * 11.0,
		blade_tip + side * 2.0,
		blade_back + side * 5.0,
	])
	draw_colored_polygon(platform, _alpha(ART_BLUE, 0.16 + 0.10 * pressure))
	draw_line(blade_back, blade_tip + forward * 10.0, _alpha(ART_BLUE_CORE, 0.42 + 0.18 * pressure), 1.6)
	draw_line(blade_back + side * 3.4, blade_tip - side * 1.2, _alpha(ART_GOLD, 0.20), 0.9)
	draw_line(blade_back - side * 3.6, blade_tip + side * 1.2, _alpha(ART_BLUE, 0.22), 0.9)
	if pressure > 0.06:
		var wake_dir := Vector2(-signf(flight_push), 0.0)
		draw_line(blade_back - forward * 20.0, blade_back + wake_dir * (30.0 + pressure * 34.0), _alpha(ART_BLUE_CORE, 0.08 + pressure * 0.08), 1.1)


func _draw_local_resonance() -> void:
	var energy_ratio: float = clampf(float(main.player.get("energy", 0.0)) / maxf(float(main.PLAYER_MAX_ENERGY), 1.0), 0.0, 1.0)
	var full_strength: float = smoothstep(0.985, 1.0, energy_ratio)
	var flash_strength: float = 0.0
	if main.has_method("_get_sword_momentum_full_flash_strength"):
		flash_strength = clampf(main._get_sword_momentum_full_flash_strength(), 0.0, 1.0)
	var strength: float = clampf((full_strength + flash_strength * 0.9) * resonance_alpha, 0.0, 1.0)
	if strength <= 0.01:
		return
	var time: float = float(main.elapsed_time)
	var radius: float = 29.0 + flash_strength * 5.0
	draw_circle(Vector2.ZERO, radius + 6.0, _alpha(ART_BLUE, 0.004 * strength))
	draw_arc(Vector2.ZERO, radius, time * 0.9, time * 0.9 + TAU * 0.30, 30, _alpha(ART_GOLD, 0.045 * strength), 0.65 + flash_strength * 0.45)
	draw_arc(Vector2.ZERO, radius + 5.0, -time * 1.1, -time * 1.1 + TAU * 0.22, 26, _alpha(ART_BLUE_CORE, 0.035 * strength), 0.58 + flash_strength * 0.35)


func _alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = clampf(alpha, 0.0, 1.0)
	return result
