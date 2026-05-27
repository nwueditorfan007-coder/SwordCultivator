extends HumanoidEightWaySkeletonVisual
class_name GooglePartsSkeletonVisual

const SHOW_GOOGLE_BONE_GUIDES := false
const ADJUSTMENT_PATH := "res://resources/flight/rider/google_parts_assembly_adjustments.json"

const DEFAULT_PART_SET_ROOT := "res://resources/flight/rider/google_parts_v1"
const PART_KEYS := [
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

const PART_BOUNDS := {
	"calf_back": Rect2(190.0, 58.0, 142.0, 368.0),
	"calf_front": Rect2(184.0, 46.0, 148.0, 394.0),
	"calf_side": Rect2(114.0, 47.0, 229.0, 403.0),
	"forearm_back": Rect2(179.0, 45.0, 151.0, 386.0),
	"forearm_front": Rect2(175.0, 44.0, 151.0, 387.0),
	"forearm_side": Rect2(185.0, 43.0, 156.0, 389.0),
	"hand_back": Rect2(179.0, 91.0, 141.0, 304.0),
	"hand_front": Rect2(194.0, 91.0, 143.0, 304.0),
	"hand_side": Rect2(210.0, 90.0, 110.0, 308.0),
	"head_back": Rect2(140.0, 49.0, 234.0, 351.0),
	"head_front": Rect2(145.0, 46.0, 222.0, 374.0),
	"head_side": Rect2(109.0, 54.0, 269.0, 367.0),
	"thigh_back": Rect2(174.0, 47.0, 171.0, 391.0),
	"thigh_front": Rect2(169.0, 40.0, 169.0, 397.0),
	"thigh_side": Rect2(175.0, 53.0, 170.0, 384.0),
	"torso_back": Rect2(82.0, 29.0, 347.0, 410.0),
	"torso_front": Rect2(83.0, 35.0, 344.0, 405.0),
	"torso_side": Rect2(139.0, 19.0, 226.0, 421.0),
	"upper_arm_back": Rect2(156.0, 49.0, 222.0, 378.0),
	"upper_arm_front": Rect2(132.0, 47.0, 224.0, 379.0),
	"upper_arm_side": Rect2(151.0, 42.0, 196.0, 392.0),
}

const SIDE_SOURCE_FACING := {
	"head": -1.0,
	"torso": -1.0,
	"upper_arm": 1.0,
	"forearm": 1.0,
	"hand": 1.0,
	"thigh": 1.0,
	"calf": 1.0,
}

const DIRECTION_VIEW_SUFFIX := {
	"right": "front",
	"up": "side",
	"left": "back",
	"down": "side",
}

const DIRECTION_SIDE_FRONT_SIGN := {
	"right": 1.0,
	"up": 1.0,
	"left": -1.0,
	"down": -1.0,
}

const HEAD_DIRECTION_VIEW_SUFFIX := {
	"right": "side",
	"up": "back",
	"left": "side",
	"down": "front",
}

const PART_RENDER_WIDTHS := {
	"upper_arm": {
		"front": 22.0,
		"side": 20.0,
		"back": 22.0,
	},
	"forearm": {
		"front": 19.0,
		"side": 18.0,
		"back": 18.0,
	},
	"thigh": {
		"front": 30.0,
		"side": 25.0,
		"back": 28.0,
	},
	"calf": {
		"front": 17.0,
		"side": 17.0,
		"back": 16.0,
	},
}

var _part_textures := {}
var _part_bounds_cache := {}
var _slot_adjustments := {}
var _slot_local_rects := {}
var _part_set_root := DEFAULT_PART_SET_ROOT
var _current_adjustment_pose := "fast"
var _show_sword := true


func _ready() -> void:
	_load_pose_overrides()
	_load_part_textures()
	if _slot_adjustments.is_empty():
		_load_saved_slot_adjustments()


func set_part_set_root(root_path: String) -> void:
	if root_path == "" or root_path == _part_set_root:
		return
	_part_set_root = root_path.trim_suffix("/")
	if is_inside_tree():
		_load_part_textures()
		queue_redraw()


func set_show_sword(enabled: bool) -> void:
	_show_sword = enabled
	queue_redraw()


func set_slot_adjustments(adjustments: Dictionary) -> void:
	_slot_adjustments = adjustments.duplicate(true)
	queue_redraw()


func get_slot_global_rect(slot_key: String) -> Rect2:
	if not _slot_local_rects.has(slot_key):
		return Rect2()
	var local_rect: Rect2 = _slot_local_rects[slot_key]
	var corners := [
		local_rect.position,
		local_rect.position + Vector2(local_rect.size.x, 0.0),
		local_rect.position + local_rect.size,
		local_rect.position + Vector2(0.0, local_rect.size.y),
	]
	var out := Rect2(to_global(corners[0]), Vector2.ZERO)
	for i in range(1, corners.size()):
		out = out.expand(to_global(corners[i]))
	return out


func _load_part_textures() -> void:
	_part_textures.clear()
	_part_bounds_cache.clear()
	for key_variant in PART_KEYS:
		var key := String(key_variant)
		var path := "%s/%s.png" % [_part_set_root, key]
		var image := Image.new()
		var global_path := ProjectSettings.globalize_path(path)
		if image.load(global_path) == OK:
			_part_bounds_cache[key] = _scan_image_bounds(image)
			_part_textures[key] = ImageTexture.create_from_image(image)
			continue
		var texture := load(path) as Texture2D
		if texture != null:
			_part_textures[key] = texture
		else:
			push_warning("Missing Google part texture: %s" % path)


func _load_saved_slot_adjustments() -> void:
	var global_path := ProjectSettings.globalize_path(ADJUSTMENT_PATH)
	if not FileAccess.file_exists(global_path):
		return
	var file := FileAccess.open(global_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if parsed.has("poses") and typeof(parsed["poses"]) == TYPE_DICTIONARY:
		_slot_adjustments = parsed["poses"]
	elif parsed.has("directions") and typeof(parsed["directions"]) == TYPE_DICTIONARY:
		_slot_adjustments = {
			"low": parsed["directions"],
			"fast": parsed["directions"],
		}


func _scan_image_bounds(image: Image) -> Rect2:
	var size := image.get_size()
	var min_x := size.x
	var min_y := size.y
	var max_x := -1
	var max_y := -1
	for y in range(size.y):
		for x in range(size.x):
			if image.get_pixel(x, y).a <= 0.08:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2(Vector2.ZERO, Vector2(size))
	return Rect2(
		Vector2(float(min_x), float(min_y)),
		Vector2(float(max_x - min_x + 1), float(max_y - min_y + 1))
	)


func _draw() -> void:
	var pose := _build_google_parts_pose()
	_slot_local_rects.clear()
	_current_adjustment_pose = "fast" if float(pose.get("fast_pose", 0.0)) >= 0.5 else "low"
	var h: Vector2 = pose["heading"]
	var speed_ratio: float = pose["speed_ratio"]
	if _show_sword:
		_draw_sword(h, speed_ratio)
	_draw_google_parts(pose)
	if SHOW_GOOGLE_BONE_GUIDES:
		_draw_joints(pose)


func _build_google_parts_pose() -> Dictionary:
	var current_pose := _build_flight_pose()
	var h: Vector2 = current_pose["heading"]
	if _direction_key_for_heading(h) == "right":
		return current_pose
	var right_pose := _build_direction_flight_pose(
		0,
		float(current_pose.get("fast_pose", 0.0)),
		float(current_pose.get("speed_ratio", 0.0)),
		float(current_pose.get("wind", 0.0)),
		true
	)
	var pose := right_pose.duplicate(true)
	for key in [
		"heading",
		"side",
		"near",
		"far",
		"near_side_sign",
		"speed_ratio",
		"fast_pose",
		"wind",
		"draw_order",
	]:
		if current_pose.has(key):
			pose[key] = current_pose[key]
	return pose


func _draw_google_parts(pose: Dictionary) -> void:
	var view_pose := _google_view_pose(pose)
	var draw_order := _front_side_adjusted_draw_order(view_pose.get("draw_order", EDIT_DRAW_LAYER_KEYS), view_pose)
	for layer_key_variant in draw_order:
		var layer_key := String(layer_key_variant)
		match layer_key:
			"far_arm":
				_draw_google_arm(view_pose, "far", _layer_alpha(layer_key, view_pose))
			"far_leg":
				_draw_google_leg(view_pose, "far", _layer_alpha(layer_key, view_pose))
			"torso":
				_draw_google_torso(view_pose)
			"head":
				_draw_google_head(view_pose)
			"near_leg":
				_draw_google_leg(view_pose, "near", _layer_alpha(layer_key, view_pose))
			"near_arm":
				_draw_google_arm(view_pose, "near", _layer_alpha(layer_key, view_pose))


func _draw_google_head(pose: Dictionary) -> void:
	var h: Vector2 = pose["heading"]
	var view := _head_view_suffix_for_heading(h)
	var head_center: Vector2 = pose["head_center"]
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var lean := _torso_rotation(pose) * 0.32
	var target_height := 33.0
	var scale_value := _part_scale_for_height("head", view, target_height)
	var head_pos := head_center + (head_center - shoulder_center).normalized() * 1.5
	_draw_part_texture("head", "head", view, head_pos, lean, Vector2.ONE * scale_value, 1.0, true, 0.0)


func _draw_google_torso(pose: Dictionary) -> void:
	var h: Vector2 = pose["heading"]
	var view := _view_suffix_for_heading(h)
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var hip_center: Vector2 = pose["hip_center"]
	var fast: float = clampf(float(pose.get("fast_pose", 0.0)), 0.0, 1.0)
	var front_profile := smoothstep(0.50, 0.94, absf(h.x))
	var target_height := shoulder_center.distance_to(hip_center) + lerpf(30.0, 40.0, front_profile) + fast * 6.0
	var target_width := lerpf(22.0, maxf(42.0, float(pose.get("torso_width", 12.0)) * 2.8), front_profile)
	if view == "side":
		target_width = maxf(target_width * 0.72, 22.0)
	var scale_value := _part_scale_for_size("torso", view, Vector2(target_width, target_height))
	var torso_pos := shoulder_center.lerp(hip_center, 0.53) + h * lerpf(0.0, 5.0, fast)
	_draw_part_texture("torso", "torso", view, torso_pos, _torso_rotation(pose), scale_value, 1.0, true, 0.0)


func _draw_google_arm(pose: Dictionary, side_key: String, alpha: float) -> void:
	var h: Vector2 = pose["heading"]
	var view := _view_suffix_for_heading(h)
	var shoulder: Vector2 = pose["shoulder_%s" % side_key]
	var elbow: Vector2 = pose["elbow_%s" % side_key]
	var wrist: Vector2 = pose["wrist_%s" % side_key]
	var center_x := float(pose["shoulder_center"].x)
	_draw_segment_part("upper_arm_%s" % side_key, "upper_arm", view, shoulder, elbow, center_x, alpha, 8.0, 0.74, 1.02)
	_draw_segment_part("forearm_%s" % side_key, "forearm", view, elbow, wrist, center_x, alpha, 7.0, 0.70, 1.04)
	_draw_hand_part("hand_%s" % side_key, view, elbow, wrist, center_x, alpha)


func _draw_google_leg(pose: Dictionary, side_key: String, alpha: float) -> void:
	var h: Vector2 = pose["heading"]
	var view := _view_suffix_for_heading(h)
	var hip: Vector2 = pose["hip_%s" % side_key]
	var knee: Vector2 = pose["knee_%s" % side_key]
	var ankle: Vector2 = pose["ankle_%s" % side_key]
	var center_x := float(pose["hip_center"].x)
	_draw_segment_part("thigh_%s" % side_key, "thigh", view, hip, knee, center_x, alpha, 10.0, 0.78, 1.02)
	_draw_segment_part("calf_%s" % side_key, "calf", view, knee, ankle, center_x, alpha, 8.0, 0.72, 1.05)


func _draw_segment_part(
		slot_key: String,
		part_name: String,
		view: String,
		a: Vector2,
		b: Vector2,
		center_x: float,
		alpha: float,
		length_pad: float,
		x_multiplier: float,
		y_multiplier: float
) -> void:
	var segment := b - a
	if segment.length_squared() <= 0.001:
		return
	var bounds := _part_bounds(part_name, view)
	var target_length := segment.length() + length_pad
	var scale_y := target_length / maxf(bounds.size.y, 1.0) * y_multiplier
	var target_width := _part_render_width(part_name, view) * x_multiplier
	var scale_x := target_width / maxf(bounds.size.x, 1.0)
	var midpoint := a.lerp(b, 0.5)
	var side_sign := _side_sign_for_point(midpoint, center_x)
	var mirror := _should_mirror_part(part_name, view, _current_direction_key(), side_sign, true)
	if mirror:
		scale_x = -scale_x
	_draw_part_texture(slot_key, part_name, view, midpoint, segment.angle() - PI * 0.5, Vector2(scale_x, scale_y), alpha, false, 0.0)


func _draw_hand_part(slot_key: String, view: String, elbow: Vector2, wrist: Vector2, center_x: float, alpha: float) -> void:
	var segment := wrist - elbow
	if segment.length_squared() <= 0.001:
		return
	var direction := segment.normalized()
	var bounds := _part_bounds("hand", view)
	var target_height := 17.0
	var scale_value := target_height / maxf(bounds.size.y, 1.0)
	var side_sign := _side_sign_for_point(wrist, center_x)
	var mirror := _should_mirror_part("hand", view, _current_direction_key(), side_sign, true)
	var scale_x := -scale_value if mirror else scale_value
	_draw_part_texture(slot_key, "hand", view, wrist + direction * 5.2, segment.angle() - PI * 0.5, Vector2(scale_x, scale_value), alpha, false, 0.0)


func _draw_part_texture(
		slot_key: String,
		part_name: String,
		view: String,
		position: Vector2,
		rotation: float,
		part_scale: Vector2,
		alpha: float,
		allow_side_mirror: bool,
		side_sign: float
) -> void:
	var texture_key := _slot_texture_key(slot_key, part_name, view)
	var texture := _part_textures.get(texture_key, null) as Texture2D
	if texture == null:
		return
	var bounds := _part_bounds_by_key(texture_key)
	var texture_size := Vector2(texture.get_size())
	var pivot := bounds.position + bounds.size * 0.5
	var draw_scale := part_scale
	if allow_side_mirror and _should_mirror_part(part_name, view, _current_direction_key(), side_sign, view == "side"):
		draw_scale.x = -draw_scale.x
	var adjustment := _slot_adjustment(_current_direction_key(), slot_key)
	var uniform_scale := clampf(float(adjustment.get("scale", 1.0)), 0.05, 6.0)
	draw_scale *= uniform_scale
	draw_scale.x *= clampf(float(adjustment.get("scale_x", 1.0)), 0.05, 6.0)
	draw_scale.y *= clampf(float(adjustment.get("scale_y", 1.0)), 0.05, 6.0)
	if bool(adjustment.get("flip_x", false)):
		draw_scale.x = -draw_scale.x
	if bool(adjustment.get("flip_y", false)):
		draw_scale.y = -draw_scale.y
	var offset := _slot_offset(adjustment)
	var draw_rotation := rotation + deg_to_rad(float(adjustment.get("rotation_deg", 0.0)))
	_record_slot_rect(slot_key, position + offset, draw_rotation, draw_scale, pivot, texture_size)
	draw_set_transform(position + offset, draw_rotation, draw_scale)
	draw_texture_rect(texture, Rect2(-pivot, texture_size), false, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _view_suffix_for_heading(h: Vector2) -> String:
	return String(DIRECTION_VIEW_SUFFIX.get(_direction_key_for_heading(h), "front"))


func _head_view_suffix_for_heading(h: Vector2) -> String:
	return String(HEAD_DIRECTION_VIEW_SUFFIX.get(_direction_key_for_heading(h), "front"))


func _current_direction_key() -> String:
	return _direction_key_for_heading(_heading_for_side())


func _direction_key_for_heading(h: Vector2) -> String:
	var safe_heading := h
	if safe_heading.length_squared() <= 0.0001:
		safe_heading = Vector2.RIGHT
	else:
		safe_heading = safe_heading.normalized()
	if absf(safe_heading.x) > absf(safe_heading.y) * 0.82:
		return "right" if safe_heading.x >= 0.0 else "left"
	return "down" if safe_heading.y >= 0.0 else "up"


func _slot_texture_key(slot_key: String, part_name: String, view: String) -> String:
	var adjustment := _slot_adjustment(_current_direction_key(), slot_key)
	var texture_key := String(adjustment.get("texture_key", ""))
	if texture_key != "":
		return texture_key
	return "%s_%s" % [part_name, view]


func _slot_adjustment(direction_key: String, slot_key: String) -> Dictionary:
	if _slot_adjustments.has(_current_adjustment_pose) and typeof(_slot_adjustments[_current_adjustment_pose]) == TYPE_DICTIONARY:
		var pose_data: Dictionary = _slot_adjustments[_current_adjustment_pose]
		if pose_data.has(direction_key) and typeof(pose_data[direction_key]) == TYPE_DICTIONARY:
			var pose_direction_data: Dictionary = pose_data[direction_key]
			if pose_direction_data.has(slot_key) and typeof(pose_direction_data[slot_key]) == TYPE_DICTIONARY:
				return pose_direction_data[slot_key]
	if not _slot_adjustments.has(direction_key) or typeof(_slot_adjustments[direction_key]) != TYPE_DICTIONARY:
		return {}
	var direction_data: Dictionary = _slot_adjustments[direction_key]
	if not direction_data.has(slot_key) or typeof(direction_data[slot_key]) != TYPE_DICTIONARY:
		return {}
	return direction_data[slot_key]


func _record_slot_rect(slot_key: String, position: Vector2, rotation: float, scale: Vector2, pivot: Vector2, texture_size: Vector2) -> void:
	var corners := [
		-pivot,
		-pivot + Vector2(texture_size.x, 0.0),
		-pivot + texture_size,
		-pivot + Vector2(0.0, texture_size.y),
	]
	var rect := Rect2(position + (corners[0] * scale).rotated(rotation), Vector2.ZERO)
	for i in range(1, corners.size()):
		rect = rect.expand(position + (corners[i] * scale).rotated(rotation))
	_slot_local_rects[slot_key] = rect


func _slot_offset(adjustment: Dictionary) -> Vector2:
	var raw_offset: Variant = adjustment.get("offset", [0.0, 0.0])
	if typeof(raw_offset) == TYPE_VECTOR2:
		return raw_offset
	if typeof(raw_offset) == TYPE_ARRAY and raw_offset.size() >= 2:
		return Vector2(float(raw_offset[0]), float(raw_offset[1]))
	return Vector2.ZERO


func _part_bounds_by_key(texture_key: String) -> Rect2:
	if _part_bounds_cache.has(texture_key):
		return _part_bounds_cache[texture_key]
	return PART_BOUNDS.get(texture_key, Rect2(0.0, 0.0, 512.0, 512.0))


func _part_bounds(part_name: String, view: String) -> Rect2:
	var texture_key := "%s_%s" % [part_name, view]
	return _part_bounds_by_key(texture_key)


func _part_scale_for_height(part_name: String, view: String, target_height: float) -> float:
	var bounds := _part_bounds(part_name, view)
	return target_height / maxf(bounds.size.y, 1.0)


func _part_scale_for_size(part_name: String, view: String, target_size: Vector2) -> Vector2:
	var bounds := _part_bounds(part_name, view)
	return Vector2(
		target_size.x / maxf(bounds.size.x, 1.0),
		target_size.y / maxf(bounds.size.y, 1.0)
	)


func _part_render_width(part_name: String, view: String) -> float:
	if not PART_RENDER_WIDTHS.has(part_name):
		return 12.0
	var part_widths: Dictionary = PART_RENDER_WIDTHS[part_name]
	return float(part_widths.get(view, part_widths.get("front", 12.0)))


func _torso_rotation(pose: Dictionary) -> float:
	var shoulder_center: Vector2 = pose["shoulder_center"]
	var hip_center: Vector2 = pose["hip_center"]
	var axis := hip_center - shoulder_center
	if axis.length_squared() <= 0.001:
		return 0.0
	return axis.angle() - PI * 0.5


func _layer_alpha(layer_key: String, pose: Dictionary) -> float:
	var h: Vector2 = pose["heading"]
	if _view_suffix_for_heading(h) != "side":
		return 0.96
	return 0.96 if _is_front_body_layer(layer_key, pose) else 0.58


func _side_sign_for_point(point: Vector2, center_x: float) -> float:
	var sign_value := signf(point.x - center_x)
	return sign_value if sign_value != 0.0 else 1.0


func _heading_for_side() -> Vector2:
	return _heading.normalized() if _heading.length_squared() > 0.0001 else _direction_vector(_direction_index)


func _google_view_pose(pose: Dictionary) -> Dictionary:
	var view_pose := pose.duplicate()
	var h: Vector2 = view_pose["heading"]
	var direction_key := _direction_key_for_heading(h)
	view_pose["front_side_sign"] = _side_front_sign_for_direction(direction_key)
	match String(DIRECTION_VIEW_SUFFIX.get(direction_key, "front")):
		"front":
			view_pose["frontness"] = 1.0
		"back":
			view_pose["frontness"] = -1.0
		_:
			view_pose["frontness"] = 0.0
	return view_pose


func _side_front_sign_for_direction(direction_key: String) -> float:
	return float(DIRECTION_SIDE_FRONT_SIGN.get(direction_key, 1.0))


func _should_mirror_part(part_name: String, view: String, direction_key: String, side_sign: float, mirrorable: bool) -> bool:
	if not mirrorable:
		return false
	if view == "side":
		var target_sign := _side_front_sign_for_direction(direction_key)
		var source_sign := float(SIDE_SOURCE_FACING.get(part_name, 1.0))
		return not is_equal_approx(source_sign, target_sign)
	return side_sign < 0.0
