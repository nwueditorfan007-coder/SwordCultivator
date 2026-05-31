extends Node2D

const MODEL_FALLBACK_PATHS := [
	"res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX",
	"res://resources/modle/000_男主角/000_Nanzhujue_LOD_Horse.FBX",
]
const DEFAULT_VIEWPORT_SIZE := Vector2i(768, 768)
const DEFAULT_POSE_OVERRIDE_PATH := "res://resources/flight/yujian_3d_model_pose_overrides.json"
const TARGET_MODEL_HEIGHT := 2.45
const FLIGHT_SPEED_POSE_REFERENCE := 1950.0
const CAMERA_FOCUS_HEIGHT := 0.55
const EDITOR_JOINT_BONE_KEYS := {
	"head": "head",
	"neck": "neck",
	"chest": "chest",
	"pelvis": "pelvis",
	"left_shoulder": "left_upper_arm",
	"left_elbow": "left_forearm",
	"left_wrist": "left_hand",
	"right_shoulder": "right_upper_arm",
	"right_elbow": "right_forearm",
	"right_wrist": "right_hand",
	"left_hip": "left_thigh",
	"left_knee": "left_calf",
	"left_ankle": "left_foot",
	"right_hip": "right_thigh",
	"right_knee": "right_calf",
	"right_ankle": "right_foot",
}

@export_file("*.tscn", "*.scn", "*.glb", "*.gltf", "*.fbx") var model_path := "res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX"
@export_file("*.json") var pose_override_path := DEFAULT_POSE_OVERRIDE_PATH
@export_range(0.5, 4.0, 0.05) var model_scale := 1.0
@export_range(0.15, 1.2, 0.01) var sprite_texture_scale := 0.74
@export_range(1.2, 8.0, 0.05) var camera_size := 6.2
@export_range(1.05, 2.8, 0.01) var camera_padding := 2.2
@export_range(3.0, 12.0, 0.1) var camera_distance := 7.0
@export_range(-180.0, 180.0, 1.0) var model_yaw_offset_degrees := -135.0
@export_range(-60.0, 60.0, 1.0) var model_pitch_offset_degrees := -2.0
@export_range(-60.0, 60.0, 1.0) var model_roll_offset_degrees := 0.0
@export var viewport_size := DEFAULT_VIEWPORT_SIZE
@export var use_preview_materials := true
@export var force_silhouette_material := false
@export var enable_bone_pose := true
@export var use_pose_override_file := true
@export var show_floor_sword := true

var pose_time := 0.0
var last_heading := Vector2.RIGHT
var last_velocity := Vector2.ZERO
var last_boost_energy := 0.0
var last_turn_energy := 0.0
var last_carve_energy := 0.0
var last_throttle_energy := 0.0
var context_turn_lean := 0.0
var context_carve_direction := 0.0
var context_switch_direction := 0.0
var context_switch_energy := 0.0
var last_speed_ratio := 0.0
var last_fast_pose := 0.0
var last_wind_pose := 0.0
var neutral_preview_enabled := false
var neutral_preview_fit_rotation_degrees := Vector3(90.0, 0.0, 0.0)
var neutral_preview_t_pose_enabled := false
var manual_pose_enabled := false
var manual_bone_pose_degrees := {}
var pose_override_base_pose := ""
var pose_override_poses := {}
var pose_override_load_status := "not_loaded"
var active_model_path := ""
var last_model_bounds := {}
var last_world_bounds := {}

var subviewport: SubViewport
var world_root: Node3D
var sword_pivot: Node3D
var model_pivot: Node3D
var model_fit_root: Node3D
var model_instance: Node3D
var floor_sword: MeshInstance3D
var camera: Camera3D
var character_sprite: Sprite2D
var preview_silhouette_material: StandardMaterial3D
var sword_material: StandardMaterial3D
var skeleton: Skeleton3D
var bone_indices: Dictionary = {}
var secondary_bone_groups: Dictionary = {}
var base_bone_pose_rotations: Array[Quaternion] = []


func _ready() -> void:
	_build_viewport()
	_load_pose_override_file()
	_create_or_reload_model()
	set_process(true)


func _process(delta: float) -> void:
	_update_model_pose(delta)


func set_flight_pose(
	_eight_way_index: int,
	visual_heading: Vector2,
	velocity: Vector2,
	boost_energy: float,
	turn_energy: float,
	carve_energy: float,
	throttle_energy: float,
	delta: float
) -> void:
	pose_time += maxf(delta, 0.0)
	if visual_heading.length_squared() > 0.0001:
		last_heading = visual_heading.normalized()
	last_velocity = velocity
	last_boost_energy = clampf(boost_energy, 0.0, 1.0)
	last_turn_energy = clampf(turn_energy, 0.0, 1.0)
	last_carve_energy = clampf(carve_energy, 0.0, 1.0)
	last_throttle_energy = clampf(throttle_energy, 0.0, 1.0)
	_update_model_pose(delta)


func get_active_model_path() -> String:
	return active_model_path


func set_flight_context(
	turn_lean: float,
	carve_direction: float,
	switch_direction: float,
	switch_energy: float
) -> void:
	context_turn_lean = clampf(turn_lean, -1.0, 1.0)
	context_carve_direction = signf(carve_direction)
	context_switch_direction = signf(switch_direction)
	context_switch_energy = clampf(switch_energy, 0.0, 1.0)


func set_manual_pose_enabled(enabled: bool) -> void:
	manual_pose_enabled = enabled
	_update_model_pose(0.0)


func set_neutral_preview_enabled(enabled: bool) -> void:
	neutral_preview_enabled = enabled
	_update_model_pose(0.0)


func set_neutral_preview_fit_rotation_degrees(rotation_degrees: Vector3) -> void:
	neutral_preview_fit_rotation_degrees = rotation_degrees
	_update_model_pose(0.0)


func set_neutral_preview_t_pose_enabled(enabled: bool) -> void:
	neutral_preview_t_pose_enabled = enabled
	_update_model_pose(0.0)


func set_manual_bone_pose_degrees(pose_degrees: Dictionary) -> void:
	manual_bone_pose_degrees.clear()
	for key_variant in pose_degrees.keys():
		var bone_name := String(key_variant)
		var rotation := _coerce_rotation_degrees(pose_degrees[key_variant])
		manual_bone_pose_degrees[bone_name] = [rotation.x, rotation.y, rotation.z]
	_update_model_pose(0.0)


func get_manual_bone_pose_degrees() -> Dictionary:
	return manual_bone_pose_degrees.duplicate(true)


func reload_pose_override_file() -> void:
	_load_pose_override_file()
	_update_model_pose(0.0)


func capture_current_bone_pose_as_manual_base() -> void:
	_capture_base_bone_pose()


func get_skeleton_bone_names() -> Array[String]:
	var result: Array[String] = []
	if skeleton == null:
		return result
	for bone_index in range(skeleton.get_bone_count()):
		result.append(skeleton.get_bone_name(bone_index))
	return result


func get_editor_joint_points() -> Dictionary:
	var result := {}
	if skeleton == null or camera == null or character_sprite == null:
		return result
	for joint_key_variant in EDITOR_JOINT_BONE_KEYS.keys():
		var joint_key := String(joint_key_variant)
		var bone_key := String(EDITOR_JOINT_BONE_KEYS[joint_key_variant])
		var bone_index := int(bone_indices.get(bone_key, -1))
		if bone_index < 0:
			continue
		var bone_pose: Transform3D = skeleton.get_bone_global_pose(bone_index)
		var world_position := skeleton.global_transform * bone_pose.origin
		if camera.is_position_behind(world_position):
			continue
		var viewport_position := camera.unproject_position(world_position)
		var centered_position := viewport_position - Vector2(subviewport.size) * 0.5
		result[joint_key] = {
			"position": character_sprite.to_global(centered_position),
			"bone_name": skeleton.get_bone_name(bone_index),
			"bone_key": bone_key,
		}
	return result


func get_debug_snapshot() -> Dictionary:
	return {
		"active_model_path": active_model_path,
		"model_bounds": last_model_bounds,
		"world_bounds": last_world_bounds,
		"camera_size": camera_size,
		"camera_padding": camera_padding,
		"sprite_texture_scale": sprite_texture_scale,
		"model_scale": model_scale,
		"speed_ratio": last_speed_ratio,
		"fast_pose": last_fast_pose,
		"wind_pose": last_wind_pose,
		"neutral_preview_enabled": neutral_preview_enabled,
		"neutral_preview_fit_rotation_degrees": neutral_preview_fit_rotation_degrees,
		"neutral_preview_t_pose_enabled": neutral_preview_t_pose_enabled,
		"manual_pose_enabled": manual_pose_enabled,
		"manual_bone_count": manual_bone_pose_degrees.size(),
		"pose_override_path": pose_override_path,
		"pose_override_status": pose_override_load_status,
		"pose_override_base_pose": pose_override_base_pose,
		"pose_override_pose_count": pose_override_poses.size(),
		"viewport_size": viewport_size,
		"bone_count": skeleton.get_bone_count() if skeleton != null else 0,
		"bone_indices": bone_indices,
		"secondary_bone_counts": _get_secondary_bone_counts(),
	}


func _build_viewport() -> void:
	preview_silhouette_material = StandardMaterial3D.new()
	preview_silhouette_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview_silhouette_material.albedo_color = Color(0.006, 0.008, 0.010, 1.0)

	sword_material = StandardMaterial3D.new()
	sword_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sword_material.albedo_color = Color(0.64, 0.96, 1.0, 0.94)
	sword_material.emission_enabled = true
	sword_material.emission = Color(0.46, 0.92, 1.0, 1.0)
	sword_material.emission_energy_multiplier = 1.18

	subviewport = SubViewport.new()
	subviewport.name = "ModelTo2DViewport"
	subviewport.size = viewport_size
	subviewport.transparent_bg = true
	subviewport.own_world_3d = true
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(subviewport)

	world_root = Node3D.new()
	world_root.name = "WorldRoot"
	subviewport.add_child(world_root)

	sword_pivot = Node3D.new()
	sword_pivot.name = "SwordHeadingPivot"
	world_root.add_child(sword_pivot)

	model_pivot = Node3D.new()
	model_pivot.name = "ModelPosePivot"
	world_root.add_child(model_pivot)

	model_fit_root = Node3D.new()
	model_fit_root.name = "ModelFitRoot"
	model_pivot.add_child(model_fit_root)

	_create_floor_sword()
	_create_lighting()

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = camera_size
	camera.look_at_from_position(Vector3(camera_distance, 0.0, CAMERA_FOCUS_HEIGHT), Vector3(0.0, 0.0, CAMERA_FOCUS_HEIGHT), Vector3(0.0, 0.0, 1.0))
	camera.current = true
	world_root.add_child(camera)

	character_sprite = Sprite2D.new()
	character_sprite.name = "ModelTo2DSprite"
	character_sprite.centered = true
	character_sprite.texture = subviewport.get_texture()
	character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	character_sprite.scale = Vector2.ONE * sprite_texture_scale
	add_child(character_sprite)


func _create_lighting() -> void:
	var key_light := DirectionalLight3D.new()
	key_light.name = "ModelKeyLight"
	key_light.light_energy = 1.35
	key_light.rotation_degrees = Vector3(-16.0, -70.0, 0.0)
	world_root.add_child(key_light)

	var rim_light := OmniLight3D.new()
	rim_light.name = "ModelRimLight"
	rim_light.light_energy = 1.05
	rim_light.omni_range = 4.8
	rim_light.position = Vector3(2.8, -2.2, 1.55)
	world_root.add_child(rim_light)


func _create_floor_sword() -> void:
	var sword_mesh := BoxMesh.new()
	sword_mesh.size = Vector3(0.055, 2.05, 0.045)
	floor_sword = MeshInstance3D.new()
	floor_sword.name = "ReadableFlightSword"
	floor_sword.mesh = sword_mesh
	floor_sword.material_override = sword_material
	floor_sword.position = Vector3(0.0, 0.0, 0.035)
	floor_sword.rotation_degrees = Vector3(0.0, 0.0, -1.2)
	if sword_pivot != null:
		sword_pivot.add_child(floor_sword)
	else:
		world_root.add_child(floor_sword)


func _create_or_reload_model() -> void:
	if model_fit_root == null:
		return
	for child in model_fit_root.get_children():
		child.queue_free()
	model_instance = null
	skeleton = null
	bone_indices.clear()
	active_model_path = _resolve_model_path(model_path)
	if active_model_path != "":
		var resource := load(active_model_path)
		if resource is PackedScene:
			model_instance = resource.instantiate()
		elif resource is Mesh:
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.mesh = resource
			model_instance = mesh_instance
	if model_instance == null:
		model_instance = _create_placeholder_character()
	model_fit_root.add_child(model_instance)
	if force_silhouette_material:
		_apply_silhouette_material(model_instance)
	elif use_preview_materials:
		_apply_preview_material(model_instance)
	_fit_model_to_view()
	skeleton = _find_first_skeleton(model_instance)
	_cache_bone_indices()
	_capture_base_bone_pose()
	_update_model_pose(0.0)


func _resolve_model_path(preferred_path: String) -> String:
	var candidates: Array[String] = []
	if preferred_path.strip_edges() != "":
		candidates.append(preferred_path)
	for fallback_path in MODEL_FALLBACK_PATHS:
		if not candidates.has(fallback_path):
			candidates.append(fallback_path)
	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func _create_placeholder_character() -> Node3D:
	var root := Node3D.new()
	root.name = "PlaceholderCultivator"
	var body := CapsuleMesh.new()
	body.radius = 0.24
	body.height = 1.18
	root.add_child(_make_mesh(body, Vector3(0.0, 0.0, 1.08), Vector3(0.72, 0.58, 1.0)))
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.19
	head_mesh.height = 0.32
	root.add_child(_make_mesh(head_mesh, Vector3(0.0, 0.0, 1.88), Vector3.ONE))
	var sleeve_mesh := BoxMesh.new()
	sleeve_mesh.size = Vector3(0.92, 0.18, 0.22)
	root.add_child(_make_mesh(sleeve_mesh, Vector3(0.34, 0.0, 1.30), Vector3.ONE, Vector3(0.0, 0.0, -13.0)))
	root.add_child(_make_mesh(sleeve_mesh, Vector3(-0.34, 0.0, 1.20), Vector3.ONE, Vector3(0.0, 0.0, 16.0)))
	return root


func _make_mesh(mesh: Mesh, position: Vector3, scale_value: Vector3, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.scale = scale_value
	mesh_instance.rotation_degrees = rotation_value
	return mesh_instance


func _apply_preview_material(root: Node) -> void:
	if root is MeshInstance3D:
		_apply_preview_to_mesh(root as MeshInstance3D)
	for child in root.get_children():
		_apply_preview_material(child)


func _apply_preview_to_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return
	mesh_instance.material_override = null
	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		var material: Material = null
		var active_material := mesh_instance.get_active_material(surface_index)
		if active_material != null:
			material = active_material.duplicate(true)
		elif mesh_instance.mesh.surface_get_material(surface_index) != null:
			material = mesh_instance.mesh.surface_get_material(surface_index).duplicate(true)
		if material is StandardMaterial3D:
			var standard := material as StandardMaterial3D
			standard.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			standard.disable_receive_shadows = true
			standard.albedo_color = standard.albedo_color.lerp(Color(0.88, 0.96, 0.95, standard.albedo_color.a), 0.22)
			mesh_instance.set_surface_override_material(surface_index, standard)


func _apply_silhouette_material(root: Node) -> void:
	if root is MeshInstance3D:
		_apply_silhouette_to_mesh(root as MeshInstance3D)
	for child in root.get_children():
		_apply_silhouette_material(child)


func _apply_silhouette_to_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return
	mesh_instance.material_override = null
	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		var material: Material = null
		var active_material := mesh_instance.get_active_material(surface_index)
		if active_material != null:
			material = active_material.duplicate(true)
		elif mesh_instance.mesh.surface_get_material(surface_index) != null:
			material = mesh_instance.mesh.surface_get_material(surface_index).duplicate(true)
		if material is StandardMaterial3D:
			var standard := material as StandardMaterial3D
			var material_name := standard.resource_name.to_lower()
			var source_transparency := standard.transparency
			standard.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			standard.albedo_color = Color(0.006, 0.008, 0.010, 1.0)
			standard.disable_receive_shadows = true
			var should_keep_alpha := material_name.contains("hair") or source_transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
			if standard.albedo_texture != null and should_keep_alpha:
				standard.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				standard.alpha_scissor_threshold = 0.18
			else:
				standard.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			mesh_instance.set_surface_override_material(surface_index, standard)
		else:
			mesh_instance.set_surface_override_material(surface_index, preview_silhouette_material)


func _fit_model_to_view() -> void:
	if model_instance == null:
		return
	var bounds := _collect_model_bounds(model_instance)
	last_model_bounds = bounds
	if not bool(bounds.get("valid", false)):
		return
	var min_point: Vector3 = bounds["min"]
	var max_point: Vector3 = bounds["max"]
	var center := (min_point + max_point) * 0.5
	var size := max_point - min_point
	var height := maxf(size.z, 0.001)
	var fit_scale := TARGET_MODEL_HEIGHT / height
	model_fit_root.scale = Vector3.ONE * model_scale * fit_scale
	model_fit_root.position = Vector3(
		-center.x * model_fit_root.scale.x,
		-center.y * model_fit_root.scale.y,
		-center.z * model_fit_root.scale.z + TARGET_MODEL_HEIGHT * 0.5
	)


func _collect_model_bounds(root: Node) -> Dictionary:
	var result := {
		"valid": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_collect_model_bounds_recursive(root, result)
	return result


func _collect_model_bounds_recursive(node: Node, result: Dictionary) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var mesh_instance := node as MeshInstance3D
		var aabb: AABB = mesh_instance.get_aabb()
		for x in [aabb.position.x, aabb.end.x]:
			for y in [aabb.position.y, aabb.end.y]:
				for z in [aabb.position.z, aabb.end.z]:
					var point: Vector3 = model_fit_root.global_transform.affine_inverse() * (mesh_instance.global_transform * Vector3(x, y, z))
					if not bool(result["valid"]):
						result["valid"] = true
						result["min"] = point
						result["max"] = point
					else:
						result["min"] = Vector3(
							minf(Vector3(result["min"]).x, point.x),
							minf(Vector3(result["min"]).y, point.y),
							minf(Vector3(result["min"]).z, point.z)
						)
						result["max"] = Vector3(
							maxf(Vector3(result["max"]).x, point.x),
							maxf(Vector3(result["max"]).y, point.y),
							maxf(Vector3(result["max"]).z, point.z)
						)
	for child in node.get_children():
		_collect_model_bounds_recursive(child, result)


func _find_first_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_first_skeleton(child)
		if found != null:
			return found
	return null


func _cache_bone_indices() -> void:
	if skeleton == null:
		return
	bone_indices = {
		"pelvis": _find_bone(["pelvis", "hips"]),
		"spine": _find_bone(["spine"]),
		"chest": _find_bone(["spine1", "chest"]),
		"neck": _find_bone(["neck"]),
		"head": _find_bone(["head"]),
		"left_clavicle": _find_bone([" l clavicle", "clavicle_l", "leftclavicle", "_l_clavicle"]),
		"right_clavicle": _find_bone([" r clavicle", "clavicle_r", "rightclavicle", "_r_clavicle"]),
		"left_upper_arm": _find_bone([" l upperarm", "upperarm_l", "arm_l", "leftarm", "_l_arm"]),
		"right_upper_arm": _find_bone([" r upperarm", "upperarm_r", "arm_r", "rightarm", "_r_arm"]),
		"left_forearm": _find_bone([" l forearm", "forearm_l", "leftforearm", "_l_forearm"]),
		"right_forearm": _find_bone([" r forearm", "forearm_r", "rightforearm", "_r_forearm"]),
		"left_hand": _find_bone([" l hand", "hand_l", "lefthand", "_l_hand"]),
		"right_hand": _find_bone([" r hand", "hand_r", "righthand", "_r_hand"]),
		"left_thigh": _find_bone([" l thigh", "thigh_l", "leftthigh", "_l_thigh"]),
		"right_thigh": _find_bone([" r thigh", "thigh_r", "rightthigh", "_r_thigh"]),
		"left_calf": _find_bone([" l calf", "calf_l", "leftcalf", "_l_calf"]),
		"right_calf": _find_bone([" r calf", "calf_r", "rightcalf", "_r_calf"]),
		"left_foot": _find_bone([" l foot", "foot_l", "leftfoot", "_l_foot"]),
		"right_foot": _find_bone([" r foot", "foot_r", "rightfoot", "_r_foot"]),
	}
	secondary_bone_groups = {
		"hair": _find_bones_containing(["bone_hair"]),
		"sleeve": _find_bones_containing(["bone_xiuzi"]),
		"ribbon": _find_bones_containing(["bone_piaodai", "bone_weibo", "bone_shengzi"]),
		"robe": _find_bones_containing(["bone_qunbai"]),
	}


func _get_secondary_bone_counts() -> Dictionary:
	var counts := {}
	for key in secondary_bone_groups.keys():
		counts[key] = (secondary_bone_groups[key] as Array).size()
	return counts


func _find_bone(keywords: Array[String]) -> int:
	if skeleton == null:
		return -1
	for bone_index in range(skeleton.get_bone_count()):
		var bone_name := " " + skeleton.get_bone_name(bone_index).to_lower().replace("bip001", "").replace(".", "_").replace("-", "_") + " "
		for keyword in keywords:
			if bone_name.contains(keyword.to_lower()):
				return bone_index
	return -1


func _find_bones_containing(keywords: Array[String]) -> Array[int]:
	var result: Array[int] = []
	if skeleton == null:
		return result
	for bone_index in range(skeleton.get_bone_count()):
		var bone_name := skeleton.get_bone_name(bone_index).to_lower()
		for keyword in keywords:
			if bone_name.contains(keyword.to_lower()):
				result.append(bone_index)
				break
	return result


func _load_pose_override_file() -> void:
	pose_override_base_pose = ""
	pose_override_poses.clear()
	pose_override_load_status = "disabled"
	if not use_pose_override_file:
		return
	pose_override_load_status = "missing"
	if pose_override_path.strip_edges() == "" or not FileAccess.file_exists(pose_override_path):
		return
	var text := FileAccess.get_file_as_string(pose_override_path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		pose_override_load_status = "invalid_json"
		return
	var data: Dictionary = parsed
	var poses: Variant = data.get("poses", {})
	if not (poses is Dictionary):
		pose_override_load_status = "missing_poses"
		return
	pose_override_base_pose = String(data.get("editor_base_pose", ""))
	for pose_name_variant in Dictionary(poses).keys():
		var pose_name := String(pose_name_variant)
		var pose_entry: Variant = Dictionary(poses)[pose_name_variant]
		if not (pose_entry is Dictionary):
			continue
		var source_bones: Variant = Dictionary(pose_entry).get("bones", {})
		if not (source_bones is Dictionary):
			continue
		var bones := {}
		for bone_name_variant in Dictionary(source_bones).keys():
			var bone_name := String(bone_name_variant)
			var rotation := _coerce_rotation_degrees(Dictionary(source_bones)[bone_name_variant])
			if rotation.length() > 0.001:
				bones[bone_name] = [rotation.x, rotation.y, rotation.z]
		pose_override_poses[pose_name] = {"bones": bones}
	pose_override_load_status = "loaded"


func _update_model_pose(delta: float) -> void:
	if model_pivot == null:
		return
	if neutral_preview_enabled:
		_update_neutral_preview_pose(delta)
		return
	var safe_heading := last_heading.normalized() if last_heading.length_squared() > 0.0001 else Vector2.RIGHT
	var pose_weights := _calculate_v4_pose_weights()
	last_speed_ratio = float(pose_weights["speed_ratio"])
	last_fast_pose = float(pose_weights["fast_pose"])
	last_wind_pose = float(pose_weights["wind"])
	var fast_pose := last_fast_pose
	var wind_pose := last_wind_pose
	var boost := maxf(last_boost_energy, fast_pose * 0.86)
	var turn_pressure := clampf(maxf(absf(context_turn_lean), last_turn_energy) + last_carve_energy * 0.55 + context_switch_energy * 0.30, 0.0, 1.0)
	var turn_direction := _resolve_turn_direction(safe_heading)
	var climb := clampf(-safe_heading.y, -1.0, 1.0)
	var idle_pose := 1.0 - fast_pose
	var heading_yaw_degrees := -rad_to_deg(safe_heading.angle())
	var model_yaw_degrees := heading_yaw_degrees + model_yaw_offset_degrees
	var screen_lean_degrees := lerpf(0.0, -10.0, fast_pose) + climb * lerpf(1.0, 4.0, fast_pose)
	var model_bank_degrees := turn_direction * turn_pressure * lerpf(1.5, 5.5, fast_pose) + last_carve_energy * turn_direction * 3.5
	model_pivot.rotation_degrees = Vector3(
		model_pitch_offset_degrees + screen_lean_degrees,
		model_roll_offset_degrees,
		model_yaw_degrees
	)
	model_pivot.position = Vector3(0.0, 0.0, 0.015 * idle_pose - 0.018 * fast_pose + sin(pose_time * 6.0) * 0.010 * idle_pose)
	model_fit_root.rotation_degrees = Vector3(
		0.0,
		turn_direction * turn_pressure * lerpf(1.5, 4.0, fast_pose),
		model_bank_degrees
	)

	if floor_sword != null:
		floor_sword.visible = show_floor_sword
		if sword_pivot != null:
			sword_pivot.rotation_degrees = Vector3(0.0, 0.0, heading_yaw_degrees)
			sword_pivot.position = Vector3(0.0, 0.0, -0.01 * fast_pose)
		floor_sword.position = Vector3(0.0, -0.55, 0.03)
		floor_sword.scale = Vector3(1.0, 1.0 + wind_pose * 0.10 + last_carve_energy * 0.08, 1.0)
		floor_sword.rotation_degrees = Vector3(0.0, 0.0, -1.2 + turn_direction * turn_pressure * 6.5)
	if character_sprite != null:
		var squash := 1.0 - fast_pose * 0.035 - last_carve_energy * 0.025
		var stretch := 1.0 + fast_pose * 0.055 + turn_pressure * 0.025
		character_sprite.scale = Vector2(sprite_texture_scale * stretch, sprite_texture_scale * squash)
		character_sprite.position = Vector2(0.0, -7.0 * fast_pose - 3.0 * last_carve_energy)
		character_sprite.rotation = turn_direction * turn_pressure * 0.052 - climb * 0.026
	_apply_bone_pose(delta, boost, turn_pressure, turn_direction, climb)
	if camera != null:
		_update_camera_framing(boost)


func _update_neutral_preview_pose(_delta: float) -> void:
	last_speed_ratio = 0.0
	last_fast_pose = 0.0
	last_wind_pose = 0.0
	model_pivot.rotation_degrees = Vector3(model_pitch_offset_degrees, model_roll_offset_degrees, model_yaw_offset_degrees)
	model_pivot.position = Vector3.ZERO
	model_fit_root.rotation_degrees = neutral_preview_fit_rotation_degrees
	if sword_pivot != null:
		sword_pivot.rotation_degrees = Vector3.ZERO
		sword_pivot.position = Vector3.ZERO
	if floor_sword != null:
		floor_sword.visible = show_floor_sword
		floor_sword.position = Vector3(0.0, -0.55, 0.03)
		floor_sword.scale = Vector3.ONE
		floor_sword.rotation_degrees = Vector3(0.0, 0.0, -1.2)
	if character_sprite != null:
		character_sprite.scale = Vector2.ONE * sprite_texture_scale
		character_sprite.position = Vector2.ZERO
		character_sprite.rotation = 0.0
	if enable_bone_pose and skeleton != null:
		_restore_base_bone_pose()
		if neutral_preview_t_pose_enabled:
			_apply_editable_t_pose_base()
		if manual_pose_enabled:
			_apply_manual_bone_pose(manual_bone_pose_degrees)
		if skeleton.has_method("force_update_all_bone_transforms"):
			skeleton.call("force_update_all_bone_transforms")
	if camera != null:
		_update_camera_framing(0.0)


func _calculate_v4_pose_weights() -> Dictionary:
	var speed_ratio := clampf(last_velocity.length() / FLIGHT_SPEED_POSE_REFERENCE, 0.0, 1.0)
	var pose_driver := maxf(speed_ratio, last_boost_energy * 0.92 + last_throttle_energy * 0.18)
	var fast_pose := smoothstep(0.28, 0.82, pose_driver)
	if fast_pose > 0.975:
		fast_pose = 1.0
	var wind := clampf(speed_ratio + last_boost_energy * 0.65 + last_carve_energy * 0.5, 0.0, 1.6)
	return {
		"speed_ratio": speed_ratio,
		"fast_pose": fast_pose,
		"wind": wind,
	}


func _resolve_turn_direction(safe_heading: Vector2) -> float:
	if context_carve_direction != 0.0 and last_carve_energy > 0.02:
		return context_carve_direction
	if context_switch_direction != 0.0 and context_switch_energy > 0.02:
		return context_switch_direction
	if absf(context_turn_lean) > 0.04:
		return signf(context_turn_lean)
	if last_velocity.length_squared() > 0.0001:
		return signf(safe_heading.cross(last_velocity.normalized()))
	return 0.0


func _update_camera_framing(boost: float) -> void:
	if camera == null or model_pivot == null:
		return
	last_world_bounds = _collect_world_bounds(model_pivot)
	camera.size = camera_size * (1.0 + boost * 0.025)
	camera.look_at_from_position(
		Vector3(camera_distance, 0.0, CAMERA_FOCUS_HEIGHT),
		Vector3(0.0, 0.0, CAMERA_FOCUS_HEIGHT),
		Vector3(0.0, 0.0, 1.0)
	)


func _collect_world_bounds(root: Node) -> Dictionary:
	var result := {
		"valid": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_collect_world_bounds_recursive(root, result)
	return result


func _collect_world_bounds_recursive(node: Node, result: Dictionary) -> void:
	if node is MeshInstance3D and node.mesh != null and node.visible:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == floor_sword:
			return
		var aabb: AABB = mesh_instance.get_aabb()
		for x in [aabb.position.x, aabb.end.x]:
			for y in [aabb.position.y, aabb.end.y]:
				for z in [aabb.position.z, aabb.end.z]:
					var point: Vector3 = mesh_instance.global_transform * Vector3(x, y, z)
					if not bool(result["valid"]):
						result["valid"] = true
						result["min"] = point
						result["max"] = point
					else:
						result["min"] = Vector3(
							minf(Vector3(result["min"]).x, point.x),
							minf(Vector3(result["min"]).y, point.y),
							minf(Vector3(result["min"]).z, point.z)
						)
						result["max"] = Vector3(
							maxf(Vector3(result["max"]).x, point.x),
							maxf(Vector3(result["max"]).y, point.y),
							maxf(Vector3(result["max"]).z, point.z)
						)
	for child in node.get_children():
		_collect_world_bounds_recursive(child, result)


func _apply_bone_pose(_delta: float, boost: float, turn_pressure: float, turn_direction: float, climb: float) -> void:
	if not enable_bone_pose or skeleton == null:
		return
	var reset_bones := {}
	for value in bone_indices.values():
		var bone_index := int(value)
		if bone_index >= 0:
			reset_bones[bone_index] = true
	for group in secondary_bone_groups.values():
		for value in group:
			var bone_index := int(value)
			if bone_index >= 0:
				reset_bones[bone_index] = true
	if skeleton.has_method("reset_bone_pose"):
		for bone_index in reset_bones.keys():
			skeleton.call("reset_bone_pose", int(bone_index))
	var safe_heading := last_heading.normalized() if last_heading.length_squared() > 0.0001 else Vector2.RIGHT
	var heading_side := signf(safe_heading.x)
	if heading_side == 0.0:
		heading_side = 1.0
	var fast := clampf(last_fast_pose, 0.0, 1.0)
	var wind := clampf(last_wind_pose, 0.0, 1.6)
	var idle := 1.0 - fast
	var front_profile := absf(safe_heading.y)
	var turn := turn_direction * turn_pressure
	var breath := sin(pose_time * 4.8) * 0.026 * idle
	var stride := sin(pose_time * lerpf(3.6, 7.4, fast) + heading_side * 0.7) * (0.02 + 0.08 * fast)
	var attack := fast * (0.82 + last_boost_energy * 0.22)

	_set_bone_rotation("pelvis", Quaternion(Vector3.RIGHT, -0.08 * attack + breath) * Quaternion(Vector3.FORWARD, turn * 0.18))
	_set_bone_rotation("spine", Quaternion(Vector3.RIGHT, -0.30 * attack + climb * 0.08 * fast + breath) * Quaternion(Vector3.FORWARD, turn * 0.22))
	_set_bone_rotation("chest", Quaternion(Vector3.RIGHT, -0.42 * attack + climb * 0.11 * fast) * Quaternion(Vector3.FORWARD, turn * 0.28) * Quaternion(Vector3.UP, -heading_side * front_profile * fast * 0.08))
	_set_bone_rotation("neck", Quaternion(Vector3.RIGHT, 0.12 * attack - climb * 0.05 * fast) * Quaternion(Vector3.FORWARD, -turn * 0.06))
	_set_bone_rotation("head", Quaternion(Vector3.RIGHT, 0.10 * attack - climb * 0.04 * fast) * Quaternion(Vector3.FORWARD, -turn * 0.05))

	_set_bone_rotation("left_clavicle", Quaternion(Vector3.FORWARD, -fast * 0.12 + turn * 0.05))
	_set_bone_rotation("right_clavicle", Quaternion(Vector3.FORWARD, fast * 0.12 + turn * 0.05))
	_set_bone_rotation("left_upper_arm", Quaternion(Vector3.FORWARD, -fast * 0.52 + turn * 0.10) * Quaternion(Vector3.RIGHT, -0.20 * fast + stride) * Quaternion(Vector3.UP, heading_side * fast * 0.10))
	_set_bone_rotation("right_upper_arm", Quaternion(Vector3.FORWARD, fast * 0.50 + turn * 0.10) * Quaternion(Vector3.RIGHT, -0.18 * fast - stride) * Quaternion(Vector3.UP, heading_side * fast * 0.10))
	_set_bone_rotation("left_forearm", Quaternion(Vector3.FORWARD, -fast * 0.22 + stride * 0.35) * Quaternion(Vector3.RIGHT, -0.10 * wind * fast))
	_set_bone_rotation("right_forearm", Quaternion(Vector3.FORWARD, fast * 0.22 - stride * 0.35) * Quaternion(Vector3.RIGHT, -0.10 * wind * fast))
	_set_bone_rotation("left_hand", Quaternion(Vector3.FORWARD, -fast * 0.08))
	_set_bone_rotation("right_hand", Quaternion(Vector3.FORWARD, fast * 0.08))

	var side_leg_bias := heading_side * 0.18 * fast
	_set_bone_rotation("left_thigh", Quaternion(Vector3.RIGHT, 0.40 * fast + stride * 0.45) * Quaternion(Vector3.FORWARD, -side_leg_bias + turn * 0.06))
	_set_bone_rotation("right_thigh", Quaternion(Vector3.RIGHT, -0.34 * fast - stride * 0.35) * Quaternion(Vector3.FORWARD, -side_leg_bias + turn * 0.06))
	_set_bone_rotation("left_calf", Quaternion(Vector3.RIGHT, -0.32 * fast - stride * 0.35))
	_set_bone_rotation("right_calf", Quaternion(Vector3.RIGHT, 0.26 * fast + stride * 0.28))
	_set_bone_rotation("left_foot", Quaternion(Vector3.RIGHT, 0.10 * fast) * Quaternion(Vector3.FORWARD, -turn * 0.04))
	_set_bone_rotation("right_foot", Quaternion(Vector3.RIGHT, -0.08 * fast) * Quaternion(Vector3.FORWARD, -turn * 0.04))
	_apply_secondary_bone_motion(boost, turn_pressure, turn_direction, climb)
	if manual_pose_enabled:
		_apply_manual_bone_pose(manual_bone_pose_degrees)
	else:
		var runtime_override_bones := _runtime_pose_override_bones(turn_pressure, turn_direction)
		if not runtime_override_bones.is_empty():
			_apply_manual_bone_pose(runtime_override_bones)
	if skeleton.has_method("force_update_all_bone_transforms"):
		skeleton.call("force_update_all_bone_transforms")


func _apply_secondary_bone_motion(boost: float, turn_pressure: float, turn_direction: float, climb: float) -> void:
	var wind := clampf(maxf(boost, last_wind_pose * 0.78), 0.0, 1.25)
	_apply_bone_group_motion("hair", wind, turn_pressure, turn_direction, climb, 0.32, 0.16)
	_apply_bone_group_motion("sleeve", wind, turn_pressure, turn_direction, climb, 0.24, 0.12)
	_apply_bone_group_motion("ribbon", wind, turn_pressure, turn_direction, climb, 0.44, 0.22)
	_apply_bone_group_motion("robe", wind, turn_pressure, turn_direction, climb, 0.28, 0.14)


func _apply_bone_group_motion(
	group_key: String,
	wind: float,
	turn_pressure: float,
	turn_direction: float,
	climb: float,
	base_amplitude: float,
	wave_amplitude: float
) -> void:
	if skeleton == null:
		return
	var group: Array = secondary_bone_groups.get(group_key, [])
	if group.is_empty():
		return
	for index in range(group.size()):
		var bone_index := int(group[index])
		if bone_index < 0:
			continue
		var ratio := float(index + 1) / float(group.size())
		var wave := sin(pose_time * (4.2 + ratio * 1.7) + ratio * TAU)
		var wind_bend := -(base_amplitude + wave_amplitude * ratio) * wind
		var side_bend := turn_direction * turn_pressure * (0.05 + 0.09 * ratio)
		var climb_bend := climb * 0.035 * ratio
		var rotation := Quaternion(Vector3.RIGHT, wind_bend + climb_bend + wave * 0.018 * wind)
		rotation *= Quaternion(Vector3.FORWARD, side_bend)
		_offset_bone_rotation_by_index(bone_index, rotation)


func _runtime_pose_override_bones(turn_pressure: float, turn_direction: float) -> Dictionary:
	if pose_override_load_status != "loaded":
		return {}
	var pose_name := _runtime_pose_override_name(turn_pressure, turn_direction)
	var pose_entry: Variant = pose_override_poses.get(pose_name, {})
	if not (pose_entry is Dictionary):
		return {}
	var bones: Variant = Dictionary(pose_entry).get("bones", {})
	if bones is Dictionary:
		return bones
	return {}


func _runtime_pose_override_name(turn_pressure: float, turn_direction: float) -> String:
	if turn_pressure > 0.22 and absf(turn_direction) > 0.01:
		return "yujian_turn_left" if turn_direction < 0.0 else "yujian_turn_right"
	if last_fast_pose > 0.45 or last_boost_energy > 0.45:
		return "yujian_boost"
	return "yujian_low"


func _reset_all_bone_poses() -> void:
	if skeleton == null or not skeleton.has_method("reset_bone_pose"):
		return
	for bone_index in range(skeleton.get_bone_count()):
		skeleton.call("reset_bone_pose", bone_index)


func _capture_base_bone_pose() -> void:
	base_bone_pose_rotations.clear()
	if skeleton == null:
		return
	for bone_index in range(skeleton.get_bone_count()):
		base_bone_pose_rotations.append(skeleton.get_bone_pose_rotation(bone_index))


func _restore_base_bone_pose() -> void:
	if skeleton == null:
		return
	if base_bone_pose_rotations.size() != skeleton.get_bone_count():
		_capture_base_bone_pose()
	for bone_index in range(mini(base_bone_pose_rotations.size(), skeleton.get_bone_count())):
		_set_bone_rotation_by_index(bone_index, base_bone_pose_rotations[bone_index])


func _apply_editable_t_pose_base() -> void:
	if skeleton == null:
		return
	_align_bone_child_direction("left_upper_arm", "left_forearm", Vector3.RIGHT)
	_align_bone_child_direction("left_forearm", "left_hand", Vector3.RIGHT)
	_align_bone_child_direction("right_upper_arm", "right_forearm", Vector3.LEFT)
	_align_bone_child_direction("right_forearm", "right_hand", Vector3.LEFT)


func _align_bone_child_direction(
	bone_key: String,
	child_key: String,
	target_direction: Vector3,
	weight := 1.0
) -> void:
	if skeleton == null:
		return
	var bone_index := int(bone_indices.get(bone_key, -1))
	var child_index := int(bone_indices.get(child_key, -1))
	if bone_index < 0 or child_index < 0 or target_direction.length_squared() <= 0.00001:
		return
	if skeleton.has_method("force_update_all_bone_transforms"):
		skeleton.call("force_update_all_bone_transforms")
	var bone_global: Transform3D = skeleton.get_bone_global_pose(bone_index)
	var child_global: Transform3D = skeleton.get_bone_global_pose(child_index)
	var current_direction := child_global.origin - bone_global.origin
	if current_direction.length_squared() <= 0.00001:
		return
	var parent_index := skeleton.get_bone_parent(bone_index)
	var parent_basis := Basis.IDENTITY
	if parent_index >= 0:
		parent_basis = skeleton.get_bone_global_pose(parent_index).basis.orthonormalized()
	var current_parent_direction := parent_basis.inverse() * current_direction.normalized()
	var target_parent_direction := parent_basis.inverse() * target_direction.normalized()
	if current_parent_direction.length_squared() <= 0.00001 or target_parent_direction.length_squared() <= 0.00001:
		return
	var delta := _quaternion_from_to(current_parent_direction.normalized(), target_parent_direction.normalized())
	var clamped_weight := clampf(weight, 0.0, 1.0)
	if clamped_weight < 0.999:
		delta = Quaternion.IDENTITY.slerp(delta, clamped_weight)
	var rest_basis := skeleton.get_bone_rest(bone_index).basis.orthonormalized()
	var pose_basis := Basis(skeleton.get_bone_pose_rotation(bone_index)).orthonormalized()
	var new_pose_basis := rest_basis.inverse() * Basis(delta).orthonormalized() * rest_basis * pose_basis
	_set_bone_rotation_by_index(bone_index, new_pose_basis.orthonormalized().get_rotation_quaternion().normalized())


func _quaternion_from_to(from_direction: Vector3, to_direction: Vector3) -> Quaternion:
	var from := from_direction.normalized()
	var to := to_direction.normalized()
	var dot := clampf(from.dot(to), -1.0, 1.0)
	if dot > 0.9999:
		return Quaternion.IDENTITY
	var axis := from.cross(to)
	if axis.length_squared() <= 0.000001:
		axis = from.cross(Vector3.UP)
		if axis.length_squared() <= 0.000001:
			axis = from.cross(Vector3.RIGHT)
	return Quaternion(axis.normalized(), acos(dot))


func _apply_manual_bone_pose(pose_degrees: Dictionary) -> void:
	if skeleton == null:
		return
	for key_variant in pose_degrees.keys():
		var bone_name := String(key_variant)
		var bone_index := _find_bone_by_name(bone_name)
		if bone_index < 0:
			continue
		var rotation_degrees := _coerce_rotation_degrees(pose_degrees[key_variant])
		var base_rotation := skeleton.get_bone_pose_rotation(bone_index)
		var offset_rotation := _rotation_degrees_to_quaternion(rotation_degrees)
		_set_bone_rotation_by_index(bone_index, (base_rotation * offset_rotation).normalized())


func _find_bone_by_name(bone_name: String) -> int:
	if skeleton == null:
		return -1
	for bone_index in range(skeleton.get_bone_count()):
		if skeleton.get_bone_name(bone_index) == bone_name:
			return bone_index
	return -1


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


func _rotation_degrees_to_quaternion(rotation_degrees: Vector3) -> Quaternion:
	var euler := Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z)
	)
	return Basis.from_euler(euler).get_rotation_quaternion()


func _set_bone_rotation(bone_key: String, rotation: Quaternion) -> void:
	if skeleton == null:
		return
	var bone_index := int(bone_indices.get(bone_key, -1))
	if bone_index < 0:
		return
	_offset_bone_rotation_by_index(bone_index, rotation)


func _set_bone_rotation_by_index(bone_index: int, rotation: Quaternion) -> void:
	if skeleton == null or bone_index < 0:
		return
	if skeleton.has_method("set_bone_pose_rotation"):
		skeleton.call("set_bone_pose_rotation", bone_index, rotation)


func _offset_bone_rotation_by_index(bone_index: int, offset_rotation: Quaternion) -> void:
	if skeleton == null or bone_index < 0:
		return
	var base_rotation := _base_bone_pose_rotation(bone_index)
	_set_bone_rotation_by_index(bone_index, (base_rotation * offset_rotation).normalized())


func _base_bone_pose_rotation(bone_index: int) -> Quaternion:
	if bone_index < 0:
		return Quaternion.IDENTITY
	if base_bone_pose_rotations.size() != skeleton.get_bone_count():
		_capture_base_bone_pose()
	if bone_index < base_bone_pose_rotations.size():
		return base_bone_pose_rotations[bone_index]
	return skeleton.get_bone_pose_rotation(bone_index)
