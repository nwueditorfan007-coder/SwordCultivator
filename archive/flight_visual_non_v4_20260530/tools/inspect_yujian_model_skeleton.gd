extends SceneTree

const MODEL_PATH := "res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX"
const BONE_KEYWORDS := [
	"Pelvis",
	"Spine",
	"Spine1",
	"Neck",
	"Head",
	"L Clavicle",
	"L UpperArm",
	"L Forearm",
	"L Hand",
	"R Clavicle",
	"R UpperArm",
	"R Forearm",
	"R Hand",
	"L Thigh",
	"L Calf",
	"L Foot",
	"R Thigh",
	"R Calf",
	"R Foot",
]


func _initialize() -> void:
	var scene := load(MODEL_PATH) as PackedScene
	if scene == null:
		push_error("Failed to load %s" % MODEL_PATH)
		quit(1)
		return
	var model := scene.instantiate()
	get_root().add_child(model)
	await process_frame
	var skeleton := _find_skeleton(model)
	if skeleton == null:
		push_error("No Skeleton3D found.")
		quit(1)
		return
	print("skeleton=%s bones=%d" % [skeleton.name, skeleton.get_bone_count()])
	for bone_index in range(skeleton.get_bone_count()):
		var bone_name := skeleton.get_bone_name(bone_index)
		if not _should_print_bone(bone_name):
			continue
		var parent := skeleton.get_bone_parent(bone_index)
		var parent_name := "-" if parent < 0 else skeleton.get_bone_name(parent)
		var rest: Transform3D = skeleton.get_bone_rest(bone_index)
		var global_rest: Transform3D = skeleton.get_bone_global_rest(bone_index)
		var global_pose: Transform3D = skeleton.get_bone_global_pose(bone_index)
		var pose_rotation: Quaternion = skeleton.get_bone_pose_rotation(bone_index)
		print(
			"%03d %-24s parent=%-24s rest_origin=%s global_rest=%s global_pose=%s pose=%s"
			% [bone_index, bone_name, parent_name, _v(rest.origin), _v(global_rest.origin), _v(global_pose.origin), _q(pose_rotation)]
		)
	if skeleton.has_method("reset_bone_pose"):
		for bone_index in range(skeleton.get_bone_count()):
			skeleton.call("reset_bone_pose", bone_index)
	if skeleton.has_method("force_update_all_bone_transforms"):
		skeleton.call("force_update_all_bone_transforms")
	print("-- after reset_bone_pose --")
	for bone_index in range(skeleton.get_bone_count()):
		var bone_name := skeleton.get_bone_name(bone_index)
		if not _should_print_bone(bone_name):
			continue
		var global_pose: Transform3D = skeleton.get_bone_global_pose(bone_index)
		var pose_rotation: Quaternion = skeleton.get_bone_pose_rotation(bone_index)
		print("%03d %-24s global_pose=%s pose=%s" % [bone_index, bone_name, _v(global_pose.origin), _q(pose_rotation)])
	quit()


func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _should_print_bone(bone_name: String) -> bool:
	for keyword in BONE_KEYWORDS:
		if bone_name.contains(String(keyword)):
			return true
	return false


func _v(value: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [value.x, value.y, value.z]


func _q(value: Quaternion) -> String:
	return "(%.3f, %.3f, %.3f, %.3f)" % [value.x, value.y, value.z, value.w]
