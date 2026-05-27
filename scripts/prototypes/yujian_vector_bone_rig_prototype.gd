extends Node2D

const VIEW_SIZE := Vector2(1280.0, 720.0)
const BG := Color(1.0, 1.0, 1.0, 1.0)
const GRID := Color(0.12, 0.16, 0.17, 0.07)
const PANEL := Color(0.92, 0.96, 0.96, 0.46)
const PANEL_LINE := Color(0.12, 0.18, 0.18, 0.18)
const AXIS := Color(0.58, 1.0, 0.92, 0.56)
const INK_BACK := Color(0.022, 0.028, 0.031, 0.95)
const INK_BODY := Color(0.035, 0.043, 0.047, 0.98)
const INK_FRONT := Color(0.065, 0.077, 0.080, 0.98)
const EDGE := Color(0.72, 0.82, 0.82, 0.48)
const FOLD := Color(0.58, 0.66, 0.65, 0.34)
const BONE := Color(0.36, 0.90, 1.0, 0.78)
const JOINT := Color(1.0, 0.84, 0.25, 0.96)
const LABEL := Color(0.10, 0.15, 0.15, 0.70)
const COSTUME_DARK := Color(0.010, 0.015, 0.018, 0.88)
const COSTUME_MID := Color(0.022, 0.032, 0.036, 0.74)
const COSTUME_EDGE := Color(0.72, 0.90, 0.90, 0.38)
const QI_COLD := Color(0.72, 0.98, 1.00, 0.58)
const QI_GOLD := Color(0.86, 0.72, 0.38, 0.34)

const PART_ORDER := [
	"head",
	"torso",
	"upper_arm_back",
	"forearm_back",
	"hand_back",
	"upper_arm_front",
	"forearm_front",
	"hand_front",
	"thigh_back",
	"calf_back",
	"thigh_front",
	"calf_front",
]

@export_range(0.45, 0.95, 0.01) var showcase_scale := 0.62
@export_range(0.4, 1.8, 0.05) var demo_speed := 1.0
@export var auto_demo := true
@export var show_bones := true
@export var show_part_labels := false
@export var show_v3_reference := true
@export var show_costume_layers := true
@export var show_speed_fx := true
@export_range(0.4, 1.8, 0.01) var costume_wind_strength := 1.0
@export_range(0.4, 1.8, 0.01) var speed_fx_intensity := 1.0

var time := 0.0
var rig_instances: Array = []


func _ready() -> void:
	_build_direction_showcase()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var step := minf(delta, 1.0 / 30.0)
	time += step * demo_speed
	_update_all_poses(step)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				time = 0.0
			KEY_T:
				auto_demo = not auto_demo
			KEY_B:
				show_bones = not show_bones
			KEY_L:
				show_part_labels = not show_part_labels
			KEY_G:
				show_v3_reference = not show_v3_reference
			KEY_C:
				show_costume_layers = not show_costume_layers
			KEY_V:
				show_speed_fx = not show_speed_fx


func _build_direction_showcase() -> void:
	for config in _get_direction_configs():
		rig_instances.append(_build_rig_instance(config))
	_update_all_poses(0.0)


func _get_direction_configs() -> Array:
	return [
		{
			"id": "04 UP_LEFT",
			"label": "04 左上",
			"profile": "up_left",
			"reference": "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/04_up_left.png",
			"axis": Vector2(-1.0, -1.0),
			"position": Vector2(350.0, 190.0),
			"view": "3/4 背侧",
			"depth_scale": Vector2(0.94, 0.90),
		},
		{
			"id": "03 UP",
			"label": "03 上",
			"profile": "up",
			"reference": "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/03_up.png",
			"axis": Vector2(0.0, -1.0),
			"position": Vector2(640.0, 174.0),
			"view": "背向压缩",
			"depth_scale": Vector2(0.70, 0.78),
		},
		{
			"id": "02 UP_RIGHT",
			"label": "02 右上",
			"profile": "up_right",
			"reference": "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/02_up_right.png",
			"axis": Vector2(1.0, -1.0),
			"position": Vector2(930.0, 190.0),
			"view": "3/4 背侧",
			"depth_scale": Vector2(0.94, 0.90),
		},
		{
			"id": "05 LEFT",
			"label": "05 左",
			"profile": "left",
			"reference": "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/05_left.png",
			"axis": Vector2(-1.0, 0.0),
			"position": Vector2(350.0, 368.0),
			"view": "侧向左",
			"depth_scale": Vector2(1.08, 0.76),
		},
		{
			"id": "01 RIGHT",
			"label": "01 右",
			"profile": "right",
			"reference": "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/01_right.png",
			"axis": Vector2(1.0, 0.0),
			"position": Vector2(930.0, 368.0),
			"view": "侧向右",
			"depth_scale": Vector2(1.08, 0.76),
		},
		{
			"id": "06 DOWN_LEFT",
			"label": "06 左下",
			"profile": "down_left",
			"reference": "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/06_down_left.png",
			"axis": Vector2(-1.0, 1.0),
			"position": Vector2(350.0, 552.0),
			"view": "3/4 正侧",
			"depth_scale": Vector2(0.88, 0.98),
		},
		{
			"id": "07 DOWN",
			"label": "07 下",
			"profile": "down",
			"reference": "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/07_down.png",
			"axis": Vector2(0.0, 1.0),
			"position": Vector2(640.0, 560.0),
			"view": "正面压缩",
			"depth_scale": Vector2(0.76, 1.02),
		},
		{
			"id": "08 DOWN_RIGHT",
			"label": "08 右下",
			"profile": "down_right",
			"reference": "res://resources/flight/yujian_8way_cruise_generated_v1/prototype_v3_face/08_down_right.png",
			"axis": Vector2(1.0, 1.0),
			"position": Vector2(930.0, 552.0),
			"view": "3/4 正侧",
			"depth_scale": Vector2(0.88, 0.98),
		},
	]


func _build_rig_instance(config: Dictionary) -> Dictionary:
	var root := Node2D.new()
	root.name = String(config["id"]).replace(" ", "_")
	root.position = Vector2(config["position"])
	root.scale = _direction_scale(config)
	add_child(root)

	var reference_sprite := Sprite2D.new()
	reference_sprite.name = "V3ReferenceGhost"
	reference_sprite.texture = load(String(config["reference"])) as Texture2D
	reference_sprite.centered = true
	reference_sprite.scale = Vector2.ONE * 0.30
	reference_sprite.modulate = Color(1.0, 1.0, 1.0, 0.18)
	reference_sprite.z_index = -50
	root.add_child(reference_sprite)

	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	root.add_child(skeleton)

	var instance := {
		"root": root,
		"reference_sprite": reference_sprite,
		"skeleton": skeleton,
		"config": config,
		"bones": {},
		"bone_lengths": {},
		"bone_links": [],
		"part_centers": {},
		"costume": {},
	}

	var hip := _make_bone(instance, "hip", skeleton, Vector2.ZERO, 42.0)
	var torso := _make_bone(instance, "torso", hip, Vector2(0.0, -56.0), 86.0)
	var neck := _make_bone(instance, "neck", torso, Vector2(0.0, -58.0), 18.0)
	var head := _make_bone(instance, "head", neck, Vector2(0.0, -34.0), 46.0)

	var upper_arm_back := _make_bone(instance, "upper_arm_back", torso, Vector2(-30.0, -42.0), 60.0)
	var forearm_back := _make_bone(instance, "forearm_back", upper_arm_back, Vector2(60.0, 0.0), 54.0)
	var hand_back := _make_bone(instance, "hand_back", forearm_back, Vector2(54.0, 0.0), 18.0)

	var upper_arm_front := _make_bone(instance, "upper_arm_front", torso, Vector2(34.0, -40.0), 62.0)
	var forearm_front := _make_bone(instance, "forearm_front", upper_arm_front, Vector2(62.0, 0.0), 58.0)
	var hand_front := _make_bone(instance, "hand_front", forearm_front, Vector2(58.0, 0.0), 19.0)

	var thigh_back := _make_bone(instance, "thigh_back", hip, Vector2(-18.0, 4.0), 66.0)
	var calf_back := _make_bone(instance, "calf_back", thigh_back, Vector2(66.0, 0.0), 62.0)
	var thigh_front := _make_bone(instance, "thigh_front", hip, Vector2(22.0, 2.0), 70.0)
	var calf_front := _make_bone(instance, "calf_front", thigh_front, Vector2(70.0, 0.0), 66.0)

	instance["bone_links"] = [
		["hip", "torso"],
		["torso", "neck"],
		["neck", "head"],
		["torso", "upper_arm_back"],
		["upper_arm_back", "forearm_back"],
		["forearm_back", "hand_back"],
		["torso", "upper_arm_front"],
		["upper_arm_front", "forearm_front"],
		["forearm_front", "hand_front"],
		["hip", "thigh_back"],
		["thigh_back", "calf_back"],
		["hip", "thigh_front"],
		["thigh_front", "calf_front"],
	]

	_build_body_parts(instance, head, torso)
	_build_arm_parts(instance, upper_arm_back, forearm_back, hand_back, upper_arm_front, forearm_front, hand_front)
	_build_leg_parts(instance, thigh_back, calf_back, thigh_front, calf_front)
	_build_costume_layers(instance)
	return instance


func _direction_scale(config: Dictionary) -> Vector2:
	var depth := Vector2(config["depth_scale"])
	return depth * showcase_scale


func _make_bone(instance: Dictionary, bone_name: String, parent: Node, pos: Vector2, length: float) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = pos
	bone.set_autocalculate_length_and_angle(false)
	bone.set_length(length)
	bone.set_bone_angle(0.0)
	bone.rest = Transform2D(0.0, pos)
	parent.add_child(bone)
	instance["bones"][bone_name] = bone
	instance["bone_lengths"][bone_name] = length
	return bone


func _build_body_parts(instance: Dictionary, head: Bone2D, torso: Bone2D) -> void:
	_make_poly(instance, torso, "part_torso", [
		Vector2(-40.0, -50.0),
		Vector2(-20.0, -70.0),
		Vector2(28.0, -68.0),
		Vector2(52.0, -36.0),
		Vector2(48.0, 22.0),
		Vector2(22.0, 70.0),
		Vector2(-24.0, 68.0),
		Vector2(-52.0, 18.0),
	], INK_BODY, 1, "torso")
	_make_line(torso, "torso_edge_left", [Vector2(-27.0, -55.0), Vector2(-38.0, -9.0), Vector2(-26.0, 48.0)], EDGE, 1.3, 3)
	_make_line(torso, "torso_center_fold", [Vector2(8.0, -61.0), Vector2(11.0, -8.0), Vector2(27.0, 51.0)], FOLD, 1.1, 3)
	_make_line(torso, "torso_belt", [Vector2(-42.0, 20.0), Vector2(-4.0, 33.0), Vector2(43.0, 19.0)], EDGE, 1.4, 4)

	_make_poly(instance, head, "part_head", _ellipse_points(34.0, 40.0, 34), Color(0.006, 0.008, 0.009, 1.0), 9, "head")
	_make_poly(instance, head, "part_head_bun", _ellipse_points(13.0, 11.0, 18, Vector2(-3.0, -41.0)), Color(0.003, 0.005, 0.006, 1.0), 10, "head")
	_make_line(head, "head_edge", [Vector2(-21.0, -28.0), Vector2(-33.0, -3.0), Vector2(-21.0, 27.0)], EDGE, 1.3, 11)
	_make_line(head, "head_plane_hint", [Vector2(10.0, -22.0), Vector2(23.0, 2.0), Vector2(15.0, 26.0)], FOLD, 1.0, 11)


func _build_arm_parts(
	instance: Dictionary,
	upper_arm_back: Bone2D,
	forearm_back: Bone2D,
	hand_back: Bone2D,
	upper_arm_front: Bone2D,
	forearm_front: Bone2D,
	hand_front: Bone2D
) -> void:
	_make_poly(instance, upper_arm_back, "part_upper_arm_back", _segment_points(60.0, 12.0, 15.0), INK_BACK, 0, "upper_arm_back")
	_make_line(upper_arm_back, "upper_arm_back_edge", [Vector2(5.0, -8.0), Vector2(36.0, -10.0), Vector2(58.0, -4.0)], EDGE, 1.0, 1)
	_make_poly(instance, forearm_back, "part_forearm_back", _segment_points(54.0, 10.0, 12.5), Color(0.026, 0.032, 0.035, 0.95), 1, "forearm_back")
	_make_poly(instance, hand_back, "part_hand_back", _ellipse_points(12.0, 9.0, 18, Vector2(8.0, 0.0)), Color(0.018, 0.022, 0.025, 0.98), 2, "hand_back")

	_make_poly(instance, upper_arm_front, "part_upper_arm_front", _segment_points(62.0, 14.0, 17.0), INK_FRONT, 6, "upper_arm_front")
	_make_line(upper_arm_front, "upper_arm_front_edge", [Vector2(6.0, -9.0), Vector2(37.0, -12.0), Vector2(60.0, -5.0)], EDGE, 1.1, 7)
	_make_poly(instance, forearm_front, "part_forearm_front", _segment_points(58.0, 11.0, 14.0), Color(0.045, 0.055, 0.058, 0.98), 7, "forearm_front")
	_make_line(forearm_front, "forearm_front_edge", [Vector2(4.0, -8.0), Vector2(35.0, -8.5), Vector2(56.0, -2.0)], EDGE, 1.0, 8)
	_make_poly(instance, hand_front, "part_hand_front", _ellipse_points(13.0, 9.0, 18, Vector2(8.0, 0.0)), Color(0.025, 0.030, 0.033, 1.0), 9, "hand_front")


func _build_leg_parts(instance: Dictionary, thigh_back: Bone2D, calf_back: Bone2D, thigh_front: Bone2D, calf_front: Bone2D) -> void:
	_make_poly(instance, thigh_back, "part_thigh_back", _segment_points(66.0, 15.0, 18.0), Color(0.022, 0.028, 0.031, 0.95), 0, "thigh_back")
	_make_line(thigh_back, "thigh_back_edge", [Vector2(7.0, -10.0), Vector2(38.0, -13.0), Vector2(63.0, -4.0)], EDGE, 1.0, 1)
	_make_poly(instance, calf_back, "part_calf_back", _segment_points(62.0, 12.0, 15.0), Color(0.018, 0.023, 0.026, 0.97), 1, "calf_back")
	_make_line(calf_back, "calf_back_edge", [Vector2(6.0, -8.0), Vector2(35.0, -9.5), Vector2(59.0, -3.0)], EDGE, 1.0, 2)

	_make_poly(instance, thigh_front, "part_thigh_front", _segment_points(70.0, 17.0, 20.0), Color(0.030, 0.037, 0.041, 0.98), 4, "thigh_front")
	_make_line(thigh_front, "thigh_front_edge", [Vector2(7.0, -12.0), Vector2(41.0, -15.0), Vector2(67.0, -5.0)], EDGE, 1.1, 5)
	_make_poly(instance, calf_front, "part_calf_front", _segment_points(66.0, 13.0, 16.0), Color(0.020, 0.026, 0.030, 0.98), 5, "calf_front")
	_make_line(calf_front, "calf_front_edge", [Vector2(6.0, -9.0), Vector2(38.0, -10.0), Vector2(63.0, -3.0)], EDGE, 1.1, 6)


func _build_costume_layers(instance: Dictionary) -> void:
	var root: Node2D = instance["root"]
	var costume := {}
	costume["robe_back"] = _make_costume_poly(root, "RobeBack", -6)
	costume["robe_front"] = _make_costume_poly(root, "RobeFront", 5)
	costume["sleeve_back"] = _make_costume_poly(root, "SleeveBack", 2)
	costume["sleeve_front"] = _make_costume_poly(root, "SleeveFront", 9)
	costume["sash_back"] = _make_costume_line(root, "SashBack", COSTUME_DARK, 8.5, -3)
	costume["sash_back_edge"] = _make_costume_line(root, "SashBackEdge", COSTUME_EDGE, 1.3, -2)
	costume["sash_front"] = _make_costume_line(root, "SashFront", Color(0.016, 0.024, 0.028, 0.90), 7.2, 10)
	costume["sash_front_edge"] = _make_costume_line(root, "SashFrontEdge", COSTUME_EDGE, 1.25, 11)
	costume["hair_tail"] = _make_costume_line(root, "HairTail", Color(0.002, 0.004, 0.005, 0.94), 7.5, 8)
	costume["hair_edge"] = _make_costume_line(root, "HairTailEdge", Color(0.50, 0.72, 0.78, 0.32), 1.25, 12)
	costume["hand_qi_front"] = _make_costume_line(root, "HandQiFront", QI_COLD, 1.25, 13, false)
	costume["hand_qi_back"] = _make_costume_line(root, "HandQiBack", QI_COLD, 1.05, 3, false)
	costume["belt_glint"] = _make_costume_line(root, "BeltGlint", QI_GOLD, 1.1, 12, false)
	instance["costume"] = costume


func _make_costume_poly(parent: Node2D, node_name: String, z: int) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = node_name
	poly.antialiased = true
	poly.z_index = z
	parent.add_child(poly)
	return poly


func _make_costume_line(
	parent: Node2D,
	node_name: String,
	color: Color,
	width: float,
	z: int,
	tapered := true
) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.default_color = color
	line.width = width
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.z_index = z
	if tapered:
		line.width_curve = _make_costume_width_curve()
	parent.add_child(line)
	return line


func _make_costume_width_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.78))
	curve.add_point(Vector2(0.22, 1.0))
	curve.add_point(Vector2(0.72, 0.68))
	curve.add_point(Vector2(1.0, 0.0))
	return curve


func _segment_points(length: float, root_half_width: float, end_half_width: float) -> Array:
	return [
		Vector2(-7.0, -root_half_width * 0.55),
		Vector2(8.0, -root_half_width),
		Vector2(length * 0.58, -end_half_width),
		Vector2(length + 6.0, -end_half_width * 0.55),
		Vector2(length + 7.0, end_half_width * 0.52),
		Vector2(length * 0.56, end_half_width),
		Vector2(8.0, root_half_width),
		Vector2(-8.0, root_half_width * 0.54),
	]


func _ellipse_points(rx: float, ry: float, segments: int, offset := Vector2.ZERO) -> Array:
	var points: Array = []
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(offset + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


func _make_poly(instance: Dictionary, parent: Node2D, node_name: String, points: Array, color: Color, z: int, part_name: String) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = node_name
	poly.polygon = PackedVector2Array(points)
	poly.color = color
	poly.antialiased = true
	poly.z_index = z
	poly.set_meta("bind_part", part_name)
	parent.add_child(poly)
	if not instance["part_centers"].has(part_name):
		instance["part_centers"][part_name] = _points_center(points)
	return poly


func _make_line(parent: Node2D, node_name: String, points: Array, color: Color, width: float, z: int) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = PackedVector2Array(points)
	line.default_color = color
	line.width = width
	line.antialiased = true
	line.z_index = z
	parent.add_child(line)
	return line


func _points_center(points: Array) -> Vector2:
	var center := Vector2.ZERO
	for point in points:
		center += Vector2(point)
	return center / maxf(float(points.size()), 1.0)


func _update_costume_layers(instance: Dictionary, phase: float) -> void:
	var costume: Dictionary = instance.get("costume", {})
	if costume.is_empty():
		return
	_set_costume_visible(costume, show_costume_layers)
	if not show_costume_layers:
		return

	var axis_dir := _costume_axis_local(instance)
	var back_dir := -axis_dir
	var side_dir := axis_dir.rotated(PI * 0.5)
	var wind := clampf(costume_wind_strength, 0.2, 2.2)
	var profile := String(Dictionary(instance["config"]).get("profile", "right"))
	var is_vertical := profile == "up" or profile == "down"
	var is_diagonal := profile.find("_") >= 0
	var flutter := sin(phase * 3.2)
	var slow_flutter := sin(phase * 1.7 + 0.6)
	var long_factor := 1.0 + (0.16 if is_diagonal else 0.0) - (0.10 if is_vertical else 0.0)

	var waist_left := _bone_point_local(instance, "torso", Vector2(-42.0, 20.0))
	var waist_right := _bone_point_local(instance, "torso", Vector2(42.0, 20.0))
	var waist_center := _bone_point_local(instance, "torso", Vector2(0.0, 24.0))
	var hip_center := _bone_point_local(instance, "hip", Vector2(0.0, 12.0))
	var hang := Vector2(0.0, 52.0)
	var robe_drag := back_dir * (17.0 + 14.0 * wind) * long_factor + side_dir * flutter * 3.0
	var robe_back_points := [
		waist_left + side_dir * 6.0,
		waist_right - side_dir * 6.0,
		hip_center + side_dir * 32.0 + hang * 0.88 + robe_drag * 0.42,
		hip_center + hang * 1.22 + robe_drag * 0.95,
		hip_center - side_dir * 34.0 + hang * 0.92 + robe_drag * 0.56,
	]
	var robe_front_points := [
		waist_left.lerp(waist_center, 0.20),
		waist_right.lerp(waist_center, 0.12),
		hip_center + side_dir * 24.0 + hang * 0.72 + robe_drag * 0.28,
		hip_center + hang * 1.00 + robe_drag * 0.50 + side_dir * slow_flutter * 3.0,
		hip_center - side_dir * 24.0 + hang * 0.72 + robe_drag * 0.20,
	]
	_set_poly_points(costume["robe_back"], robe_back_points, COSTUME_DARK)
	_set_poly_points(costume["robe_front"], robe_front_points, COSTUME_MID)

	var forearm_back_start := _bone_point_local(instance, "forearm_back", Vector2(4.0, 0.0))
	var forearm_back_end := _bone_point_local(instance, "forearm_back", Vector2(54.0, 0.0))
	var forearm_front_start := _bone_point_local(instance, "forearm_front", Vector2(4.0, 0.0))
	var forearm_front_end := _bone_point_local(instance, "forearm_front", Vector2(58.0, 0.0))
	_set_poly_points(
		costume["sleeve_back"],
		_sleeve_points(forearm_back_start, forearm_back_end, back_dir, 11.0, 19.0, 7.0 + wind * 5.0),
		Color(0.012, 0.018, 0.021, 0.76)
	)
	_set_poly_points(
		costume["sleeve_front"],
		_sleeve_points(forearm_front_start, forearm_front_end, back_dir, 12.0, 21.0, 8.0 + wind * 5.0),
		Color(0.030, 0.043, 0.047, 0.78)
	)

	var sash_back_anchor := _bone_point_local(instance, "torso", Vector2(-30.0, 24.0))
	var sash_front_anchor := _bone_point_local(instance, "torso", Vector2(31.0, 25.0))
	var sash_back_points := _ribbon_points(sash_back_anchor, back_dir, side_dir, 64.0 * wind * long_factor, -10.0 + flutter * 4.0, phase)
	var sash_front_points := _ribbon_points(sash_front_anchor, back_dir, side_dir, 54.0 * wind * long_factor, 11.0 + slow_flutter * 4.0, phase + 0.85)
	_set_line_points(costume["sash_back"], sash_back_points, Color(0.004, 0.008, 0.010, 0.92))
	_set_line_points(costume["sash_back_edge"], sash_back_points, Color(0.60, 0.84, 0.88, 0.34))
	_set_line_points(costume["sash_front"], sash_front_points, Color(0.014, 0.023, 0.027, 0.90))
	_set_line_points(costume["sash_front_edge"], sash_front_points, Color(0.74, 0.94, 0.92, 0.38))

	var head_anchor := _bone_point_local(instance, "head", Vector2(-4.0, 13.0))
	var hair_points := _ribbon_points(head_anchor, back_dir, side_dir, 42.0 * wind * long_factor, -6.0 + flutter * 2.4, phase + 0.34)
	_set_line_points(costume["hair_tail"], hair_points, Color(0.001, 0.003, 0.004, 0.96))
	_set_line_points(costume["hair_edge"], hair_points, Color(0.48, 0.70, 0.76, 0.30))

	var hand_front := _bone_point_local(instance, "hand_front", Vector2(14.0, 0.0))
	var hand_back := _bone_point_local(instance, "hand_back", Vector2(13.0, 0.0))
	_set_line_points(costume["hand_qi_front"], [
		hand_front - side_dir * 4.0,
		hand_front + axis_dir * (18.0 + 5.0 * wind) + side_dir * flutter * 2.5,
	], QI_COLD)
	_set_line_points(costume["hand_qi_back"], [
		hand_back + side_dir * 3.0,
		hand_back + axis_dir * (15.0 + 4.0 * wind) - side_dir * slow_flutter * 2.0,
	], Color(0.68, 0.95, 1.0, 0.36))
	_set_line_points(costume["belt_glint"], [
		waist_left.lerp(waist_center, 0.18),
		waist_center + back_dir * 3.0,
		waist_right.lerp(waist_center, 0.18),
	], QI_GOLD)


func _set_costume_visible(costume: Dictionary, visible_value: bool) -> void:
	for node in costume.values():
		if node is CanvasItem:
			(node as CanvasItem).visible = visible_value


func _set_poly_points(poly: Polygon2D, points: Array, color: Color) -> void:
	if poly == null:
		return
	poly.polygon = PackedVector2Array(points)
	poly.color = color


func _set_line_points(line: Line2D, points: Array, color: Color) -> void:
	if line == null:
		return
	line.points = PackedVector2Array(points)
	line.default_color = color


func _ribbon_points(anchor: Vector2, back_dir: Vector2, side_dir: Vector2, length: float, side_bias: float, phase: float) -> Array:
	var wave_a := sin(phase * 2.6) * 5.0
	var wave_b := sin(phase * 3.7 + 1.2) * 4.0
	return [
		anchor,
		anchor + back_dir * length * 0.32 + side_dir * (side_bias * 0.44 + wave_a),
		anchor + back_dir * length * 0.68 + side_dir * (side_bias * 0.94 + wave_b),
		anchor + back_dir * length + side_dir * (side_bias * 0.72 + wave_a * 0.52 - wave_b * 0.22),
	]


func _sleeve_points(start: Vector2, end: Vector2, wind_dir: Vector2, root_half_width: float, tip_half_width: float, drag: float) -> Array:
	var forward := end - start
	if forward.length_squared() <= 0.001:
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var normal := forward.rotated(PI * 0.5)
	return [
		start + normal * root_half_width,
		end + normal * tip_half_width + wind_dir * drag,
		end - normal * tip_half_width * 0.86 + wind_dir * drag * 0.62,
		start - normal * root_half_width * 0.72,
	]


func _costume_axis_local(instance: Dictionary) -> Vector2:
	var root: Node2D = instance["root"]
	var axis := Vector2(Dictionary(instance["config"]).get("axis", Vector2.RIGHT))
	if axis.is_zero_approx():
		axis = Vector2.RIGHT
	axis = axis.normalized()
	var local_axis := root.to_local(root.global_position + axis) - root.to_local(root.global_position)
	return local_axis.normalized() if not local_axis.is_zero_approx() else axis


func _bone_point_local(instance: Dictionary, bone_name: String, offset := Vector2.ZERO) -> Vector2:
	var bones: Dictionary = instance["bones"]
	var bone: Bone2D = bones.get(bone_name, null)
	if bone == null:
		return Vector2.ZERO
	var root: Node2D = instance["root"]
	return root.to_local(bone.to_global(offset))


func _update_all_poses(_delta: float) -> void:
	for index in range(rig_instances.size()):
		var instance: Dictionary = rig_instances[index]
		var config: Dictionary = instance["config"]
		var root: Node2D = instance["root"]
		var reference_sprite: Sprite2D = instance["reference_sprite"]
		root.scale = _direction_scale(config)
		reference_sprite.visible = show_v3_reference
		var phase := time + float(index) * 0.37
		var float_offset := Vector2(0.0, sin(phase * 1.7) * 3.0)
		root.position = Vector2(config["position"]) + float_offset
		_apply_profile(instance, String(config["profile"]), phase)
		_update_costume_layers(instance, phase)


func _apply_profile(instance: Dictionary, profile: String, phase: float) -> void:
	match profile:
		"right":
			_apply_side_pose(instance, 1.0, phase)
		"left":
			_apply_side_pose(instance, -1.0, phase)
		"up":
			_apply_vertical_pose(instance, -1.0, phase)
		"down":
			_apply_vertical_pose(instance, 1.0, phase)
		"up_right":
			_apply_diagonal_pose(instance, 1.0, -1.0, phase)
		"up_left":
			_apply_diagonal_pose(instance, -1.0, -1.0, phase)
		"down_right":
			_apply_diagonal_pose(instance, 1.0, 1.0, phase)
		"down_left":
			_apply_diagonal_pose(instance, -1.0, 1.0, phase)


func _apply_side_pose(instance: Dictionary, side: float, phase: float) -> void:
	var pulse := sin(phase * 2.0)
	_set_bone(instance, "hip", Vector2.ZERO, side * 5.0)
	_set_bone(instance, "torso", Vector2(side * 24.0, -47.0), side * 34.0, Vector2(1.0, 0.84))
	_set_bone(instance, "neck", Vector2(side * 7.0, -58.0), side * -12.0)
	_set_bone(instance, "head", Vector2(side * 8.0, -32.0), side * -8.0 + pulse * 1.2, Vector2(0.92, 0.88))

	_set_bone(instance, "upper_arm_front", Vector2(side * 48.0, -35.0), _mirror_angle(8.0, side), Vector2(1.08, 1.0))
	_set_bone(instance, "forearm_front", Vector2(62.0, 0.0), -12.0, Vector2(1.08, 1.0))
	_set_bone(instance, "hand_front", Vector2(58.0, 0.0), 2.0)
	_set_bone(instance, "upper_arm_back", Vector2(side * -54.0, -34.0), _mirror_angle(166.0, side), Vector2(1.04, 1.0))
	_set_bone(instance, "forearm_back", Vector2(60.0, 0.0), 18.0, Vector2(1.02, 1.0))
	_set_bone(instance, "hand_back", Vector2(54.0, 0.0), -4.0)

	_set_bone(instance, "thigh_front", Vector2(side * 34.0, 7.0), _mirror_angle(48.0, side), Vector2(1.05, 1.0))
	_set_bone(instance, "calf_front", Vector2(70.0, 0.0), 25.0 + pulse * 2.0, Vector2(1.04, 1.0))
	_set_bone(instance, "thigh_back", Vector2(side * -42.0, 7.0), _mirror_angle(126.0, side), Vector2(1.0, 1.0))
	_set_bone(instance, "calf_back", Vector2(66.0, 0.0), -18.0, Vector2(1.02, 1.0))


func _apply_vertical_pose(instance: Dictionary, front: float, phase: float) -> void:
	var toward_camera := front > 0.0
	var pulse := sin(phase * 2.0)
	var arm_spread := 36.0 if toward_camera else 27.0
	var leg_spread := 31.0 if toward_camera else 20.0
	var chest_lift := 8.0 if toward_camera else -8.0
	var head_scale := Vector2(1.02, 0.90) if toward_camera else Vector2(0.86, 0.66)
	var torso_scale := Vector2(0.94, 0.96) if toward_camera else Vector2(0.82, 0.78)

	_set_bone(instance, "hip", Vector2.ZERO, 0.0)
	_set_bone(instance, "torso", Vector2(0.0, -50.0 + chest_lift), 0.0, torso_scale)
	_set_bone(instance, "neck", Vector2(0.0, -53.0), 0.0)
	_set_bone(instance, "head", Vector2(0.0, -31.0), pulse * 1.0, head_scale)

	_set_bone(instance, "upper_arm_front", Vector2(arm_spread, -35.0), 54.0 + front * 8.0, Vector2(0.92 if not toward_camera else 1.0, 1.0))
	_set_bone(instance, "forearm_front", Vector2(58.0, 0.0), 14.0 + front * 6.0)
	_set_bone(instance, "hand_front", Vector2(54.0, 0.0), 0.0)
	_set_bone(instance, "upper_arm_back", Vector2(-arm_spread, -36.0), 126.0 - front * 8.0, Vector2(0.90 if not toward_camera else 1.0, 1.0))
	_set_bone(instance, "forearm_back", Vector2(56.0, 0.0), -14.0 - front * 6.0)
	_set_bone(instance, "hand_back", Vector2(50.0, 0.0), 0.0)

	_set_bone(instance, "thigh_front", Vector2(leg_spread, 2.0), 78.0, Vector2(0.72 if not toward_camera else 0.86, 1.0))
	_set_bone(instance, "calf_front", Vector2(70.0, 0.0), 23.0, Vector2(0.72 if not toward_camera else 0.86, 1.0))
	_set_bone(instance, "thigh_back", Vector2(-leg_spread, 3.0), 102.0, Vector2(0.68 if not toward_camera else 0.82, 1.0))
	_set_bone(instance, "calf_back", Vector2(66.0, 0.0), -22.0, Vector2(0.68 if not toward_camera else 0.82, 1.0))


func _apply_diagonal_pose(instance: Dictionary, side: float, front: float, phase: float) -> void:
	var toward_camera := front > 0.0
	var pulse := sin(phase * 2.0)
	var compact := 0.82 if not toward_camera else 0.94
	var lean := side * (30.0 if toward_camera else 26.0)
	var arm_open := 42.0 if toward_camera else 36.0
	var leg_open := 34.0 if toward_camera else 27.0
	var torso_scale := Vector2(0.90, 0.88) if toward_camera else Vector2(0.84, 0.78)

	_set_bone(instance, "hip", Vector2(side * 4.0, 0.0), side * 5.0)
	_set_bone(instance, "torso", Vector2(side * 15.0, -50.0), lean, torso_scale)
	_set_bone(instance, "neck", Vector2(side * 3.0, -54.0), -side * 4.0)
	_set_bone(instance, "head", Vector2(side * 5.0, -32.0), -side * 3.0 + pulse * 1.0, Vector2(0.94, 0.78 if not toward_camera else 0.86))

	_set_bone(instance, "upper_arm_front", Vector2(side * arm_open, -36.0), _mirror_angle(18.0 if toward_camera else 28.0, side), Vector2(compact, 1.0))
	_set_bone(instance, "forearm_front", Vector2(62.0, 0.0), -10.0 + front * 8.0, Vector2(compact, 1.0))
	_set_bone(instance, "hand_front", Vector2(58.0, 0.0), 0.0)
	_set_bone(instance, "upper_arm_back", Vector2(side * -arm_open, -38.0), _mirror_angle(154.0 if toward_camera else 164.0, side), Vector2(compact, 1.0))
	_set_bone(instance, "forearm_back", Vector2(60.0, 0.0), 14.0 - front * 6.0, Vector2(compact, 1.0))
	_set_bone(instance, "hand_back", Vector2(54.0, 0.0), 0.0)

	_set_bone(instance, "thigh_front", Vector2(side * leg_open, 3.0), _mirror_angle(58.0 if toward_camera else 74.0, side), Vector2(compact, 1.0))
	_set_bone(instance, "calf_front", Vector2(70.0, 0.0), 20.0 + front * 5.0, Vector2(compact, 1.0))
	_set_bone(instance, "thigh_back", Vector2(side * -leg_open, 5.0), _mirror_angle(118.0 if toward_camera else 108.0, side), Vector2(compact * 0.96, 1.0))
	_set_bone(instance, "calf_back", Vector2(66.0, 0.0), -18.0 - front * 5.0, Vector2(compact * 0.96, 1.0))


func _mirror_angle(angle: float, side: float) -> float:
	return angle if side > 0.0 else 180.0 - angle


func _set_bone(instance: Dictionary, bone_name: String, pos: Vector2, angle_degrees: float, scale_value := Vector2.ONE) -> void:
	var bones: Dictionary = instance["bones"]
	var bone: Bone2D = bones.get(bone_name, null)
	if bone == null:
		return
	bone.position = pos
	bone.rotation = deg_to_rad(angle_degrees)
	bone.scale = scale_value


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), BG, true)
	_draw_grid()
	_draw_direction_panels()
	if show_speed_fx:
		_draw_speed_fx()
	if show_bones:
		_draw_bone_overlay()
	if show_part_labels:
		_draw_part_labels()
	_draw_hud()


func _draw_grid() -> void:
	for x in range(80, 1220, 80):
		draw_line(Vector2(x, 80), Vector2(x, 640), GRID, 1.0)
	for y in range(80, 680, 80):
		draw_line(Vector2(64, y), Vector2(1216, y), GRID, 1.0)


func _draw_direction_panels() -> void:
	for instance in rig_instances:
		var config: Dictionary = instance["config"]
		var root: Node2D = instance["root"]
		var center := root.position
		var panel := Rect2(center - Vector2(112.0, 86.0), Vector2(224.0, 172.0))
		draw_rect(panel, PANEL, true)
		draw_rect(panel, PANEL_LINE, false, 1.0)
		_draw_axis(center, Vector2(config["axis"]))
		draw_string(ThemeDB.fallback_font, panel.position + Vector2(10.0, 19.0), String(config["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.08, 0.12, 0.12, 0.86))
		draw_string(ThemeDB.fallback_font, panel.position + Vector2(10.0, 39.0), String(config["view"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11.0, Color(0.18, 0.28, 0.28, 0.76))


func _draw_axis(center: Vector2, axis: Vector2) -> void:
	var dir := axis.normalized()
	var start := center - dir * 78.0
	var end := center + dir * 84.0
	draw_line(start, end, Color(0.58, 1.0, 0.92, 0.20), 7.0)
	draw_line(start, end, AXIS, 1.8)
	var right := dir.rotated(PI * 0.5)
	var arrow := PackedVector2Array([
		end,
		end - dir * 13.0 + right * 5.0,
		end - dir * 13.0 - right * 5.0,
	])
	draw_colored_polygon(arrow, AXIS)


func _draw_speed_fx() -> void:
	for instance in rig_instances:
		var config: Dictionary = instance["config"]
		var axis := Vector2(config.get("axis", Vector2.RIGHT))
		if axis.is_zero_approx():
			continue
		axis = axis.normalized()
		_draw_afterimage(instance, axis)
		_draw_wind_streaks(instance, axis)


func _draw_afterimage(instance: Dictionary, axis: Vector2) -> void:
	var root: Node2D = instance["root"]
	var scale_factor := (absf(root.scale.x) + absf(root.scale.y)) * 0.5
	var back_dir := -axis
	for layer in range(2):
		var layer_index := float(layer + 1)
		var shift := back_dir * (18.0 + layer_index * 19.0) * speed_fx_intensity
		var alpha := (0.080 / layer_index) * speed_fx_intensity
		var head := _bone_point_screen(instance, "head", Vector2.ZERO) + shift
		var torso := _bone_point_screen(instance, "torso", Vector2(0.0, 0.0)) + shift
		var hip := _bone_point_screen(instance, "hip", Vector2.ZERO) + shift
		var ghost_color := Color(0.018, 0.030, 0.032, alpha)
		draw_line(torso, hip, ghost_color, 26.0 * scale_factor)
		draw_circle(head, 17.0 * scale_factor, ghost_color)
		draw_circle(torso.lerp(hip, 0.35), 20.0 * scale_factor, Color(0.020, 0.034, 0.036, alpha * 0.72))


func _draw_wind_streaks(instance: Dictionary, axis: Vector2) -> void:
	var root: Node2D = instance["root"]
	var center := root.position
	var side := axis.rotated(PI * 0.5)
	var back_dir := -axis
	var stroke_count := 5
	for streak_index in range(stroke_count):
		var lane := float(streak_index) - float(stroke_count - 1) * 0.5
		var jitter := sin(time * 2.2 + float(streak_index) * 1.37) * 5.5
		var side_offset := side * (lane * 22.0 + jitter)
		var near := center + back_dir * (18.0 + float(streak_index % 2) * 6.0) + side_offset
		var far := center + back_dir * (88.0 + float(streak_index) * 8.0) + side_offset - axis * 8.0
		var alpha := (0.12 + 0.035 * float(stroke_count - streak_index)) * speed_fx_intensity
		draw_line(far, near, Color(0.70, 0.96, 1.0, alpha), 1.1 + 0.25 * float(streak_index % 2))
		draw_line(far + side * 2.0, near + side * 1.2, Color(0.88, 0.76, 0.42, alpha * 0.22), 0.65)
	if absf(axis.x) > 0.15 and absf(axis.y) > 0.15:
		var arc_center := center + back_dir * 36.0
		var start_angle := axis.angle() + PI * 0.58
		var end_angle := axis.angle() + PI * 1.08
		draw_arc(arc_center, 42.0, start_angle, end_angle, 18, Color(0.74, 0.96, 1.0, 0.10 * speed_fx_intensity), 1.2)


func _bone_point_screen(instance: Dictionary, bone_name: String, offset := Vector2.ZERO) -> Vector2:
	var bones: Dictionary = instance["bones"]
	var bone: Bone2D = bones.get(bone_name, null)
	if bone == null:
		return Vector2.ZERO
	return to_local(bone.to_global(offset))


func _draw_bone_overlay() -> void:
	for instance in rig_instances:
		for link in Array(instance["bone_links"]):
			var bones: Dictionary = instance["bones"]
			var a: Bone2D = bones.get(String(link[0]), null)
			var b: Bone2D = bones.get(String(link[1]), null)
			if a == null or b == null:
				continue
			draw_line(to_local(a.global_position), to_local(b.global_position), BONE, 1.1)
		for bone_name in Dictionary(instance["bones"]).keys():
			var bone: Bone2D = instance["bones"][bone_name]
			var pos := to_local(bone.global_position)
			draw_circle(pos, 3.4, JOINT)
			if _is_terminal_bone(instance, String(bone_name)):
				var length := float(instance["bone_lengths"].get(bone_name, 28.0))
				var end_pos := to_local(bone.to_global(Vector2(length, 0.0)))
				draw_line(pos, end_pos, BONE, 0.9)
				draw_circle(end_pos, 2.1, Color(0.84, 1.0, 0.97, 0.76))


func _is_terminal_bone(instance: Dictionary, bone_name: String) -> bool:
	for link in Array(instance["bone_links"]):
		if String(link[0]) == bone_name:
			return false
	return true


func _draw_part_labels() -> void:
	for instance in rig_instances:
		var bones: Dictionary = instance["bones"]
		var part_centers: Dictionary = instance["part_centers"]
		for part_name in PART_ORDER:
			var bone: Bone2D = bones.get(String(part_name), null)
			if bone == null:
				continue
			var center := Vector2(part_centers.get(part_name, Vector2.ZERO))
			var pos := to_local(bone.to_global(center)) + Vector2(6.0, -5.0)
			draw_string(ThemeDB.fallback_font, pos, String(part_name), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8.5, LABEL)


func _draw_hud() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 34.0), "Yujian eight-way body major-parts rig", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18.0, Color(0.07, 0.10, 0.10, 0.90))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 58.0), "Rule: movement direction = invisible sword axis = body facing; each direction uses its own pose, not a rotated sprite.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.16, 0.24, 0.24, 0.80))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 82.0), "T demo  B bones  L labels  G V3 ghost  C costume  V speed  R reset", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.05, 0.38, 0.34, 0.78))
	var center_text := "八向要求\n上: 背向压缩\n下: 正面压缩\n左右: 侧向不倒立\n斜向: 3/4 背侧或正侧"
	draw_multiline_string(ThemeDB.fallback_font, Vector2(558.0, 310.0), center_text, HORIZONTAL_ALIGNMENT_CENTER, 170.0, 16.0, 4, Color(0.12, 0.18, 0.18, 0.78))
