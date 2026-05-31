extends Node2D

const VIEW_SIZE := Vector2(1280.0, 720.0)
const MODEL_FALLBACK_PATHS := [
	"res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX",
	"res://resources/modle/000_男主角/000_Nanzhujue_LOD_Horse.FBX",
]
const REFERENCE_POS := Vector2(335.0, 420.0)
const STACK_POS := Vector2(850.0, 420.0)
const VIEWPORT_SIZE := Vector2i(768, 768)
const MODEL_SLICE_TOP := 58.0
const MODEL_SLICE_BOTTOM := 708.0
const MODEL_SLICE_CENTER := Vector2(384.0, 384.0)
const STACK_LAYER_COUNT := 32
const STACK_VERTICAL_GAP := -7.0
const STACK_SIDE_SHIFT := 22.0
const STACK_DEPTH_SHIFT := 2.0
const STACK_PITCH_SHIFT := 8.0
const TRAIL_LIFE := 0.72
const CYAN := Color(0.44, 0.95, 0.93, 1.0)
const CORE := Color(0.96, 1.0, 0.98, 1.0)

@export_file("*.tscn", "*.scn", "*.glb", "*.gltf", "*.fbx") var model_path := "res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX"
@export_range(0.6, 4.0, 0.05) var reference_camera_size := 3.0
@export_range(0.25, 1.2, 0.01) var stack_scale := 0.56
@export var show_model_reference := true
@export var auto_demo := true

var time := 0.0
var yaw := 0.0
var pitch := 0.0
var manual_yaw := 0.0
var manual_pitch := 0.0
var speed_energy := 0.0
var turn_energy := 0.0
var layer_specs: Array = []
var layer_sprites: Array = []
var trail_points: Array = []

var stack_root: Node2D
var subviewport: SubViewport
var world_root: Node3D
var model_pivot: Node3D
var model_fit_root: Node3D
var model_instance: Node3D
var camera: Camera3D
var reference_sprite: Sprite2D
var active_model_path := ""


func _ready() -> void:
	_build_reference_viewport()
	_build_stacked_character()
	_reset_pose()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var step := minf(delta, 1.0 / 30.0)
	time += step
	_update_pose(step)
	_update_stacked_layers(step)
	_update_reference_model()
	_update_trail(step)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_T:
				auto_demo = not auto_demo
			KEY_M:
				show_model_reference = not show_model_reference
				if reference_sprite != null:
					reference_sprite.visible = show_model_reference
			KEY_R:
				_create_or_reload_model()
				_rebuild_stacked_character()
				_reset_pose()


func _reset_pose() -> void:
	yaw = 0.0
	pitch = 0.0
	manual_yaw = 0.0
	manual_pitch = 0.0
	speed_energy = 0.0
	turn_energy = 0.0
	trail_points.clear()


func _build_reference_viewport() -> void:
	subviewport = SubViewport.new()
	subviewport.name = "CurrentCharacterReferenceViewport"
	subviewport.size = VIEWPORT_SIZE
	subviewport.transparent_bg = true
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(subviewport)

	world_root = Node3D.new()
	world_root.name = "WorldRoot"
	subviewport.add_child(world_root)

	model_pivot = Node3D.new()
	model_pivot.name = "ModelPivot"
	world_root.add_child(model_pivot)

	model_fit_root = Node3D.new()
	model_fit_root.name = "ModelFitRoot"
	model_pivot.add_child(model_fit_root)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = reference_camera_size
	camera.look_at_from_position(Vector3(7.0, 0.0, 1.18), Vector3(0.0, 0.0, 1.18), Vector3(0.0, 0.0, 1.0))
	camera.current = true
	world_root.add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.name = "SoftDirectionLight"
	key_light.light_energy = 1.45
	key_light.rotation_degrees = Vector3(-12.0, -76.0, 0.0)
	world_root.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "CameraFillLight"
	fill_light.light_energy = 1.1
	fill_light.omni_range = 5.0
	fill_light.position = Vector3(3.2, 0.0, 1.35)
	world_root.add_child(fill_light)

	reference_sprite = Sprite2D.new()
	reference_sprite.name = "CurrentCharacterReference"
	reference_sprite.centered = true
	reference_sprite.texture = subviewport.get_texture()
	reference_sprite.position = REFERENCE_POS
	reference_sprite.scale = Vector2.ONE * 0.54
	reference_sprite.visible = show_model_reference
	add_child(reference_sprite)

	_create_or_reload_model()


func _build_stacked_character() -> void:
	stack_root = Node2D.new()
	stack_root.name = "StackedSpriteCharacterRoot"
	stack_root.position = STACK_POS
	add_child(stack_root)
	_rebuild_stacked_character()


func _rebuild_stacked_character() -> void:
	if stack_root == null:
		return
	for child in stack_root.get_children():
		child.queue_free()
	layer_specs.clear()
	layer_sprites.clear()
	var slice_height := (MODEL_SLICE_BOTTOM - MODEL_SLICE_TOP) / float(STACK_LAYER_COUNT)
	for index in range(STACK_LAYER_COUNT):
		var z := float(index) / float(STACK_LAYER_COUNT - 1)
		var slice_y := MODEL_SLICE_TOP + float(index) * slice_height
		var sprite := Sprite2D.new()
		sprite.name = "Slice_%02d" % index
		sprite.centered = false
		sprite.texture = subviewport.get_texture()
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0.0, slice_y, float(VIEWPORT_SIZE.x), slice_height + 1.0)
		sprite.z_index = index
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		stack_root.add_child(sprite)
		layer_specs.append({
			"z": z,
			"slice_y": slice_y,
			"slice_height": slice_height,
			"sway": lerpf(0.4, 2.4, z),
			"local_offset": _slice_local_offset(z),
		})
		layer_sprites.append(sprite)


func _slice_local_offset(z: float) -> Vector2:
	var shoulder_swing := sin(z * PI * 2.0) * 0.8
	var head_lift := -1.6 * smoothstep(0.78, 1.0, z)
	return Vector2(shoulder_swing, head_lift)


func _update_pose(delta: float) -> void:
	if auto_demo:
		yaw = sin(time * 0.72) * 0.82
		pitch = sin(time * 1.08) * 0.38
		speed_energy = 0.46 + 0.34 * (0.5 + 0.5 * sin(time * 1.3))
		turn_energy = absf(cos(time * 0.72)) * 0.42
		return

	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	manual_yaw += axis.x * delta * 1.75
	manual_pitch = clampf(manual_pitch + axis.y * delta * 1.2, -0.72, 0.72)
	yaw = lerp_angle(yaw, manual_yaw, 1.0 - pow(0.5, delta / 0.09))
	pitch = _damp_float(pitch, manual_pitch, 0.08, delta)
	speed_energy = _damp_float(speed_energy, 1.0 if Input.is_action_pressed("dash") else 0.18, 0.12, delta)
	turn_energy = _damp_float(turn_energy, clampf(absf(axis.x) * 0.8 + absf(axis.y) * 0.25, 0.0, 1.0), 0.10, delta)


func _update_stacked_layers(_delta: float) -> void:
	if stack_root == null:
		return
	var bob := Vector2(0.0, sin(time * 2.2) * (2.0 + speed_energy * 2.0))
	stack_root.position = STACK_POS + bob
	stack_root.scale = Vector2.ONE * stack_scale
	stack_root.rotation = sin(yaw) * 0.035 + pitch * 0.025

	var side := sin(yaw)
	var depth := cos(yaw)
	var stack_axis := Vector2(
		side * STACK_SIDE_SHIFT,
		-STACK_VERTICAL_GAP + depth * STACK_DEPTH_SHIFT + pitch * STACK_PITCH_SHIFT
	)
	var pose_squash := 1.0 - absf(pitch) * 0.075 - speed_energy * 0.035
	var pose_stretch := 1.0 + speed_energy * 0.055 + turn_energy * 0.045

	for index in range(layer_sprites.size()):
		var sprite := layer_sprites[index] as Sprite2D
		var spec := layer_specs[index] as Dictionary
		var z := float(spec["z"])
		var slice_y := float(spec["slice_y"])
		var local_offset: Vector2 = spec["local_offset"]
		var sway := sin(time * 2.1 + z * PI * 2.0) * float(spec["sway"]) * (0.08 + speed_energy * 0.10)
		var turn_pull := Vector2(side * turn_energy * z * 5.0, -turn_energy * z * 1.2)
		var slice_origin := Vector2(-MODEL_SLICE_CENTER.x, slice_y - MODEL_SLICE_CENTER.y)
		sprite.position = slice_origin + local_offset + stack_axis * z + Vector2(side * sway, 0.0) + turn_pull
		sprite.rotation = side * z * 0.045 - pitch * (1.0 - z) * 0.030
		sprite.scale = Vector2(pose_stretch + z * 0.012, pose_squash)
		var shade := clampf(0.88 + z * 0.10 + speed_energy * 0.03, 0.0, 1.08)
		var rim := clampf(absf(side) * 0.035 + speed_energy * 0.025, 0.0, 0.08)
		sprite.modulate = Color(shade + rim, shade + rim * 1.25, shade + rim * 1.22, 1.0)


func _update_trail(delta: float) -> void:
	for point in trail_points:
		point["age"] = float(point["age"]) + delta
	trail_points = trail_points.filter(func(point: Dictionary) -> bool: return float(point["age"]) <= TRAIL_LIFE)
	var tail := STACK_POS + Vector2(-88.0 - 30.0 * speed_energy, 88.0 + pitch * 18.0)
	if trail_points.is_empty() or Vector2(trail_points[-1]["pos"]).distance_to(tail) > 10.0:
		trail_points.append({"pos": tail, "age": 0.0, "speed": speed_energy})


func _draw() -> void:
	_draw_background()
	_draw_trail()
	_draw_ground_marks()
	_draw_debug_text()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.69, 0.74, 0.74, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.045, 0.060, 0.064, 0.12))
	_draw_mountain_band(0.30, 0.58, Color(0.14, 0.17, 0.17, 0.18), 0.0)
	_draw_mountain_band(0.56, 0.86, Color(0.04, 0.055, 0.056, 0.28), 1.8)
	for i in range(9):
		var y := 124.0 + float(i) * 62.0 + sin(time * 0.13 + float(i)) * 8.0
		var x := fmod(time * (11.0 + float(i % 3) * 2.0) + float(i) * 188.0, VIEW_SIZE.x + 320.0) - 160.0
		_draw_cloud_wisp(Vector2(x, y), 150.0 + float(i % 3) * 38.0, Color(0.94, 0.98, 0.98, 0.13))


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


func _draw_trail() -> void:
	for i in range(1, trail_points.size()):
		var prev: Dictionary = trail_points[i - 1]
		var current: Dictionary = trail_points[i]
		var age := (float(prev["age"]) + float(current["age"])) * 0.5
		var life := clampf(1.0 - age / TRAIL_LIFE, 0.0, 1.0)
		var width := (9.0 + float(current["speed"]) * 22.0) * life
		var halo := CYAN
		halo.a = 0.10 * life
		draw_line(prev["pos"], current["pos"], halo, width * 2.5, true)
		var core := CORE
		core.a = 0.26 * life
		draw_line(prev["pos"], current["pos"], core, maxf(width * 0.24, 2.0), true)


func _draw_ground_marks() -> void:
	draw_circle(REFERENCE_POS + Vector2(0.0, 126.0), 82.0, Color(0.01, 0.02, 0.022, 0.10))
	draw_circle(STACK_POS + Vector2(4.0, 126.0), 78.0, Color(0.01, 0.02, 0.022, 0.13))
	draw_line(Vector2(640.0, 98.0), Vector2(640.0, 638.0), Color(0.78, 0.95, 0.95, 0.12), 1.0)


func _draw_debug_text() -> void:
	var reference_label := active_model_path if active_model_path != "" else "placeholder"
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 32.0), "堆叠精灵人物原型  |  T自动/手动  WASD调姿态  Space速度  M参考模型  R重建", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16.0, Color(0.90, 0.96, 0.94, 0.84))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 56.0), "reference: %s  |  yaw %.0fdeg  pitch %.0fdeg  speed %.2f  turn %.2f  layers %d" % [reference_label, rad_to_deg(yaw), rad_to_deg(pitch), speed_energy, turn_energy, STACK_LAYER_COUNT], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.70, 0.84, 0.84, 0.75))
	draw_string(ThemeDB.fallback_font, REFERENCE_POS + Vector2(-114.0, 170.0), "当前男主模型参考", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14.0, Color(0.22, 0.32, 0.32, 0.72))
	draw_string(ThemeDB.fallback_font, STACK_POS + Vector2(-130.0, 170.0), "当前模型切片堆叠人物", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14.0, Color(0.22, 0.32, 0.32, 0.72))


func _create_or_reload_model() -> void:
	if model_fit_root == null:
		return
	for child in model_fit_root.get_children():
		child.queue_free()
	model_instance = null
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
	_apply_preview_material(model_instance)
	_fit_model_to_view()
	_update_reference_model()


func _resolve_model_path(preferred_path: String) -> String:
	var candidates := []
	if preferred_path.strip_edges() != "":
		candidates.append(preferred_path)
	for fallback_path in MODEL_FALLBACK_PATHS:
		if not candidates.has(fallback_path):
			candidates.append(fallback_path)
	for candidate: String in candidates:
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func _create_placeholder_character() -> Node3D:
	var root := Node3D.new()
	root.name = "PlaceholderCultivator"
	root.add_child(_make_mesh(CapsuleMesh.new(), Vector3(0.0, 1.08, 0.0), Vector3(0.58, 0.92, 0.40)))
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.34
	root.add_child(_make_mesh(head_mesh, Vector3(0.0, 1.92, 0.0), Vector3.ONE))
	var sleeve_mesh := BoxMesh.new()
	root.add_child(_make_mesh(sleeve_mesh, Vector3(0.46, 1.22, 0.0), Vector3(0.86, 0.18, 0.22), Vector3(0.0, 0.0, -12.0)))
	root.add_child(_make_mesh(sleeve_mesh, Vector3(-0.45, 1.14, 0.0), Vector3(0.82, 0.16, 0.2), Vector3(0.0, 0.0, 16.0)))
	var sword_mesh := BoxMesh.new()
	root.add_child(_make_mesh(sword_mesh, Vector3(0.78, 0.66, 0.0), Vector3(1.9, 0.045, 0.045), Vector3(0.0, 0.0, -6.0)))
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
		var source_material := mesh_instance.get_active_material(surface_index)
		var material: Material = null
		if source_material != null:
			material = source_material.duplicate(true)
		elif mesh_instance.mesh.surface_get_material(surface_index) != null:
			material = mesh_instance.mesh.surface_get_material(surface_index).duplicate(true)
		if material is StandardMaterial3D:
			var standard := material as StandardMaterial3D
			standard.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			standard.disable_receive_shadows = true
			standard.albedo_color = standard.albedo_color.lerp(Color(1.0, 1.0, 1.0, standard.albedo_color.a), 0.18)
			mesh_instance.set_surface_override_material(surface_index, standard)


func _fit_model_to_view() -> void:
	if model_instance == null:
		return
	var bounds := _collect_model_bounds(model_instance)
	if not bool(bounds.get("valid", false)):
		return
	var min_point: Vector3 = bounds["min"]
	var max_point: Vector3 = bounds["max"]
	var center := (min_point + max_point) * 0.5
	var size := max_point - min_point
	var height := maxf(size.z, 0.001)
	var target_height := 2.45
	var fit_scale := target_height / height
	model_fit_root.scale = Vector3.ONE * fit_scale
	model_fit_root.position = Vector3(
		-center.x * model_fit_root.scale.x,
		-center.y * model_fit_root.scale.y,
		-center.z * model_fit_root.scale.z + target_height * 0.5
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


func _update_reference_model() -> void:
	if reference_sprite != null:
		reference_sprite.visible = show_model_reference
	if camera != null:
		camera.size = reference_camera_size
	if model_pivot == null:
		return
	model_pivot.rotation_degrees = Vector3(
		-4.0 + rad_to_deg(pitch) * 0.18,
		rad_to_deg(yaw) * 0.55,
		pitch * 11.0 - speed_energy * 6.0
	)


func _damp_float(current: float, target: float, half_life: float, delta: float) -> float:
	if half_life <= 0.0:
		return target
	var decay := pow(0.5, delta / half_life)
	return target + (current - target) * decay
