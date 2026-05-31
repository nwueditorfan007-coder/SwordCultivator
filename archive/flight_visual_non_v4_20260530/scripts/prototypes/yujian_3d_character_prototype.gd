extends Node2D

const VIEW_SIZE := Vector2(1280.0, 720.0)
const PLAY_RECT := Rect2(Vector2(88.0, 76.0), Vector2(1104.0, 568.0))
const CYAN := Color(0.48, 1.0, 0.96, 1.0)
const CORE := Color(0.96, 1.0, 0.98, 1.0)
const MODEL_FALLBACK_PATHS := [
	"res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX",
	"res://resources/modle/000_男主角/000_Nanzhujue_LOD_Horse.FBX",
]

@export_file("*.tscn", "*.scn", "*.glb", "*.gltf", "*.fbx") var model_path := "res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX"
@export_range(0.25, 4.0, 0.05) var model_scale := 1.0
@export_range(-180.0, 180.0, 1.0) var model_yaw_degrees := 0.0
@export_range(-90.0, 90.0, 1.0) var model_pitch_degrees := 0.0
@export_range(-90.0, 90.0, 1.0) var model_roll_degrees := 0.0
@export_range(0.8, 6.0, 0.05) var camera_size := 3.0
@export_range(0.2, 2.0, 0.05) var sprite_scale := 0.72
@export var force_silhouette_material := false
@export var use_preview_materials := true
@export var auto_demo := true

var flight_pos := Vector2(300.0, 360.0)
var velocity := Vector2(420.0, 0.0)
var facing_sign := 1.0
var time := 0.0
var trail_points: Array = []

var subviewport: SubViewport
var world_root: Node3D
var model_pivot: Node3D
var model_fit_root: Node3D
var model_instance: Node3D
var camera: Camera3D
var character_sprite: Sprite2D
var silhouette_material: StandardMaterial3D
var active_model_path := ""


func _ready() -> void:
	_build_viewport()
	_create_or_reload_model()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var step := minf(delta, 1.0 / 30.0)
	time += step
	_update_flight(step)
	_update_model_pose(step)
	_update_trail(step)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_create_or_reload_model()
			KEY_T:
				auto_demo = not auto_demo
			KEY_C:
				force_silhouette_material = not force_silhouette_material
				_create_or_reload_model()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_POST_SAVE:
		if is_inside_tree():
			_create_or_reload_model()


func _build_viewport() -> void:
	silhouette_material = StandardMaterial3D.new()
	silhouette_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	silhouette_material.albedo_color = Color(0.005, 0.007, 0.008, 1.0)

	subviewport = SubViewport.new()
	subviewport.name = "Character3DViewport"
	subviewport.size = Vector2i(768, 768)
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
	camera.size = camera_size
	camera.look_at_from_position(Vector3(7.0, 0.0, 1.18), Vector3(0.0, 0.0, 1.18), Vector3(0.0, 0.0, 1.0))
	camera.current = true
	world_root.add_child(camera)

	var light := DirectionalLight3D.new()
	light.name = "SoftDirectionLight"
	light.light_energy = 1.45
	light.rotation_degrees = Vector3(-12.0, -76.0, 0.0)
	world_root.add_child(light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "CameraFillLight"
	fill_light.light_energy = 1.1
	fill_light.omni_range = 5.0
	fill_light.position = Vector3(3.2, 0.0, 1.35)
	world_root.add_child(fill_light)

	character_sprite = Sprite2D.new()
	character_sprite.name = "CharacterSprite"
	character_sprite.centered = true
	character_sprite.texture = subviewport.get_texture()
	character_sprite.position = flight_pos
	character_sprite.scale = Vector2.ONE * sprite_scale
	add_child(character_sprite)


func _create_or_reload_model() -> void:
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
	model_fit_root.scale = Vector3.ONE * model_scale
	if force_silhouette_material:
		_apply_silhouette_material(model_instance)
	elif use_preview_materials:
		_apply_preview_material(model_instance)
	_fit_model_to_view()
	_update_model_pose(0.0)


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
	var body := _make_mesh(CapsuleMesh.new(), Vector3(0.0, 1.1, 0.0), Vector3(0.62, 0.92, 0.42))
	root.add_child(body)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.34
	root.add_child(_make_mesh(head_mesh, Vector3(0.0, 1.95, 0.0), Vector3.ONE))
	var sleeve_mesh := BoxMesh.new()
	root.add_child(_make_mesh(sleeve_mesh, Vector3(0.48, 1.22, 0.0), Vector3(0.9, 0.18, 0.22), Vector3(0.0, 0.0, -12.0)))
	root.add_child(_make_mesh(sleeve_mesh, Vector3(-0.45, 1.14, 0.0), Vector3(0.82, 0.16, 0.2), Vector3(0.0, 0.0, 16.0)))
	var cloak := PlaneMesh.new()
	cloak.size = Vector2(1.35, 1.15)
	root.add_child(_make_mesh(cloak, Vector3(-0.4, 0.92, 0.12), Vector3.ONE, Vector3(0.0, 0.0, 18.0)))
	var sword_mesh := BoxMesh.new()
	root.add_child(_make_mesh(sword_mesh, Vector3(0.8, 0.72, 0.0), Vector3(1.9, 0.045, 0.045), Vector3(0.0, 0.0, -6.0)))
	return root


func _make_mesh(mesh: Mesh, position: Vector3, scale_value: Vector3, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.scale = scale_value
	mesh_instance.rotation_degrees = rotation_value
	return mesh_instance


func _apply_silhouette_material(root: Node) -> void:
	if root is MeshInstance3D:
		_apply_silhouette_to_mesh(root as MeshInstance3D)
	for child in root.get_children():
		_apply_silhouette_material(child)


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


func _apply_silhouette_to_mesh(mesh_instance: MeshInstance3D) -> void:
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
			var material_name := standard.resource_name.to_lower()
			var source_transparency := standard.transparency
			standard.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			standard.albedo_color = Color(0.005, 0.007, 0.008, 1.0)
			standard.disable_receive_shadows = true
			var should_keep_alpha := material_name.contains("hair") or source_transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
			if standard.albedo_texture != null and should_keep_alpha:
				standard.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				standard.alpha_scissor_threshold = 0.18
			else:
				standard.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			mesh_instance.set_surface_override_material(surface_index, standard)
		else:
			mesh_instance.set_surface_override_material(surface_index, silhouette_material)


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
	model_fit_root.scale = Vector3.ONE * model_scale * fit_scale
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


func _update_flight(delta: float) -> void:
	if auto_demo:
		var target := Vector2(650.0 + sin(time * 0.68) * 280.0, 350.0 + sin(time * 1.1) * 115.0)
		velocity = velocity.move_toward((target - flight_pos) * 1.55, 860.0 * delta)
	else:
		var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if axis.length_squared() > 0.01:
			velocity = velocity.move_toward(axis.normalized() * 520.0, 1200.0 * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 760.0 * delta)
	flight_pos += velocity * delta
	flight_pos = flight_pos.clamp(PLAY_RECT.position, PLAY_RECT.end)
	if absf(velocity.x) > 24.0:
		facing_sign = signf(velocity.x)
	character_sprite.position = flight_pos
	character_sprite.scale = Vector2(sprite_scale * facing_sign, sprite_scale)


func _update_model_pose(_delta: float) -> void:
	if model_pivot == null:
		return
	var speed_factor := clampf(velocity.length() / 620.0, 0.0, 1.0)
	var vertical_tilt := clampf(velocity.y / 620.0, -1.0, 1.0)
	model_pivot.rotation_degrees = Vector3(
		model_pitch_degrees,
		model_roll_degrees + vertical_tilt * 10.0 - speed_factor * 6.0,
		model_yaw_degrees
	)
	camera.size = camera_size


func _update_trail(delta: float) -> void:
	for point in trail_points:
		point["age"] = float(point["age"]) + delta
	trail_points = trail_points.filter(func(point: Dictionary) -> bool: return float(point["age"]) <= 0.75)
	if trail_points.is_empty() or Vector2(trail_points[-1]["pos"]).distance_to(flight_pos) > 10.0:
		trail_points.append({"pos": flight_pos, "age": 0.0, "speed": velocity.length()})


func _draw() -> void:
	_draw_background()
	_draw_sword_trail()
	_draw_debug_text()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.72, 0.75, 0.75, 1.0))
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.06, 0.075, 0.08, 0.12))
	_draw_mountain_band(0.28, 0.52, Color(0.22, 0.25, 0.26, 0.18), 0.0)
	_draw_mountain_band(0.52, 0.78, Color(0.08, 0.1, 0.105, 0.28), 61.0)
	for i in range(7):
		var y := 130.0 + float(i) * 70.0 + sin(time * 0.12 + float(i)) * 8.0
		var x := fmod(time * (7.0 + float(i % 3)) + float(i) * 190.0, VIEW_SIZE.x + 320.0) - 180.0
		_draw_cloud_wisp(Vector2(x, y), 150.0 + float(i % 3) * 44.0, Color(0.94, 0.96, 0.94, 0.14))


func _draw_mountain_band(top_ratio: float, bottom_ratio: float, color: Color, offset: float) -> void:
	var top := VIEW_SIZE.y * top_ratio
	var bottom := VIEW_SIZE.y * bottom_ratio
	var points := PackedVector2Array([Vector2(0.0, bottom)])
	for i in range(10):
		var x := VIEW_SIZE.x * float(i) / 9.0
		var ridge := top + 86.0 * absf(sin(float(i) * 1.21 + offset))
		points.append(Vector2(x, clampf(ridge, top, bottom - 18.0)))
	points.append(Vector2(VIEW_SIZE.x, bottom))
	draw_colored_polygon(points, color)


func _draw_cloud_wisp(origin: Vector2, length: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(12):
		var f := float(i) / 11.0
		points.append(origin + Vector2(length * (f - 0.5), sin(f * TAU + time * 0.18) * 8.0))
	draw_polyline(points, color, 5.0, true)


func _draw_sword_trail() -> void:
	for i in range(1, trail_points.size()):
		var prev: Dictionary = trail_points[i - 1]
		var current: Dictionary = trail_points[i]
		var age := (float(prev["age"]) + float(current["age"])) * 0.5
		var life := clampf(1.0 - age / 0.75, 0.0, 1.0)
		var width := (8.0 + clampf(float(current["speed"]) / 620.0, 0.0, 1.0) * 24.0) * life
		var glow := CYAN
		glow.a = 0.12 * life
		draw_line(prev["pos"], current["pos"], glow, width * 2.5, true)
		var core := CORE
		core.a = 0.26 * life
		draw_line(prev["pos"], current["pos"], core, maxf(width * 0.32, 2.0), true)


func _draw_debug_text() -> void:
	var model_label := active_model_path if active_model_path != "" else "placeholder"
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 32.0), "3D角色横版验证  |  T演示/手动  C预览/剪影  R重载模型  WASD移动", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16.0, Color(0.9, 0.95, 0.94, 0.78))
	var material_mode := "silhouette" if force_silhouette_material else "preview texture"
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 56.0), "model: %s  |  material: %s" % [model_label, material_mode], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.0, Color(0.72, 0.84, 0.84, 0.7))
