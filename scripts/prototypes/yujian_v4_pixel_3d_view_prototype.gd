extends "res://scripts/prototypes/yujian_sprite_sequence_prototype.gd"

const DEFAULT_PIXEL_VIEWPORT_SIZE := Vector2i(640, 360)
const WORLD_TO_3D := 0.018
const TARGET_MODEL_HEIGHT := 1.24
const CAMERA_SIZE_SCALE := 0.86
const CAMERA_HEIGHT := 13.5
const CAMERA_BACK := 15.5
const CAMERA_RIGHT_DRIFT := 0.0
const DECOR_GRID_STEP := 620.0
const TREE_COUNT := 34
const PATCH_COUNT := 48
const STONE_COUNT := 26
const ENEMY_OFFSETS := [
	Vector2(560.0, -250.0),
	Vector2(880.0, 170.0),
	Vector2(-420.0, 320.0),
]

@export_file("*.tscn", "*.scn", "*.glb", "*.gltf", "*.fbx") var rider_model_path := ""
@export var pixel_viewport_size := DEFAULT_PIXEL_VIEWPORT_SIZE
@export var show_legacy_2d_speed_overlays := true
@export var show_3d_rider := true
@export var show_v4_sprite_rider_debug := false
@export var show_3d_array_readability := false
@export_range(0.65, 1.35, 0.01) var pixel_camera_size_scale := CAMERA_SIZE_SCALE
@export_range(0.6, 1.6, 0.01) var player_visual_scale := 1.0
@export_range(0.6, 1.6, 0.01) var rider_model_scale := 1.0
@export_range(-180.0, 180.0, 1.0) var rider_model_yaw_offset_degrees := 180.0

var pixel_world_viewport: SubViewport
var pixel_world_sprite: Sprite2D
var pixel_world_root: Node3D
var pixel_world_camera: Camera3D
var decor_root: Node3D
var player_root_3d: Node3D
var player_yaw_root: Node3D
var player_body_root: Node3D
var model_pose_root: Node3D
var model_fit_root: Node3D
var model_instance: Node3D
var drawn_rider_root: Node3D
var drawn_rider_parts := {}
var sword_root_3d: Node3D
var array_root_3d: Node3D
var ring_mesh_instance: MeshInstance3D
var fan_mesh_instance: MeshInstance3D
var pierce_mesh_instance: MeshInstance3D
var enemy_roots: Array = []
var tree_roots: Array = []
var patch_roots: Array = []
var stone_roots: Array = []

var ground_material: StandardMaterial3D
var ground_patch_materials: Array = []
var trunk_material: StandardMaterial3D
var foliage_materials: Array = []
var stone_material: StandardMaterial3D
var robe_material: StandardMaterial3D
var dark_robe_material: StandardMaterial3D
var hair_material: StandardMaterial3D
var skin_material: StandardMaterial3D
var sword_material_3d: StandardMaterial3D
var sword_core_material: StandardMaterial3D
var enemy_material: StandardMaterial3D
var enemy_edge_material: StandardMaterial3D
var ring_material: StandardMaterial3D
var fan_material: StandardMaterial3D
var pierce_material: StandardMaterial3D
var active_model_path := ""


func _create_nodes() -> void:
	super._create_nodes()
	eight_way_character_set = EIGHT_WAY_SET_V4_SKELETON
	if sprite_root != null:
		sprite_root.visible = show_v4_sprite_rider_debug
		sprite_root.z_index = 24
	if reference_vfx_sprite != null:
		reference_vfx_sprite.visible = false
	_create_pixel_3d_world()


func _process(delta: float) -> void:
	super._process(delta)
	_update_pixel_3d_world(minf(delta, 1.0 / 30.0))


func _update_reference_vfx(_delta: float) -> void:
	pass


func _create_adjustment_panel() -> void:
	super._create_adjustment_panel()
	if adjustment_panel != null:
		adjustment_panel.visible = false


func _draw_background() -> void:
	pass


func _draw_scene_speed_streaks() -> void:
	if show_legacy_2d_speed_overlays:
		super._draw_scene_speed_streaks()


func _draw_debug() -> void:
	var speed_label := "boost" if speed_mode == SPEED_MODE_BOOST else "cruise"
	var control_label := "direct intent" if control_mode == CONTROL_MODE_DIRECT_INTENT else "steer throttle"
	draw_string(
		ThemeDB.fallback_font,
		Vector2(24.0, 32.0),
		"Yujian V4 pixel 3D  |  normal 8-way action view  |  WASD Space F3 F2 T",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		16.0,
		Color(0.91, 0.96, 0.95, 0.88)
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(24.0, 56.0),
		"view: %dx%d nearest  control: %s  speed: %s %.1f  zoom %.2f  pos %.0f,%.0f  visual %.0fdeg  action-dir:%s  rider:%s" % [
			pixel_viewport_size.x,
			pixel_viewport_size.y,
			control_label,
			speed_label,
			velocity.length(),
			camera_zoom,
			flight_pos.x,
			flight_pos.y,
			rad_to_deg(visual_heading.angle()),
			_current_3d_direction_label(),
			active_model_path.get_file() if active_model_path != "" else "drawn-pixel",
		],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		13.0,
		Color(0.76, 0.90, 0.90, 0.78)
	)


func _create_pixel_3d_world() -> void:
	_create_materials()

	pixel_world_viewport = SubViewport.new()
	pixel_world_viewport.name = "Pixel3DWorldViewport"
	pixel_world_viewport.size = pixel_viewport_size
	pixel_world_viewport.own_world_3d = true
	pixel_world_viewport.transparent_bg = false
	pixel_world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(pixel_world_viewport)

	pixel_world_sprite = Sprite2D.new()
	pixel_world_sprite.name = "Pixel3DWorldComposite"
	pixel_world_sprite.centered = false
	pixel_world_sprite.texture = pixel_world_viewport.get_texture()
	pixel_world_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pixel_world_sprite.z_as_relative = false
	pixel_world_sprite.z_index = -200
	pixel_world_sprite.scale = Vector2(VIEW_SIZE.x / float(pixel_viewport_size.x), VIEW_SIZE.y / float(pixel_viewport_size.y))
	add_child(pixel_world_sprite)
	move_child(pixel_world_sprite, 0)

	pixel_world_root = Node3D.new()
	pixel_world_root.name = "Pixel3DWorldRoot"
	pixel_world_viewport.add_child(pixel_world_root)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.34, 0.45, 0.50, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.64, 0.72, 0.78, 1.0)
	environment.ambient_light_energy = 0.72
	var world_environment := WorldEnvironment.new()
	world_environment.name = "PixelWorldEnvironment"
	world_environment.environment = environment
	pixel_world_root.add_child(world_environment)

	pixel_world_camera = Camera3D.new()
	pixel_world_camera.name = "V4OrthographicPixelCamera"
	pixel_world_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	pixel_world_camera.current = true
	pixel_world_root.add_child(pixel_world_camera)

	var sun := DirectionalLight3D.new()
	sun.name = "SoftTopLight"
	sun.light_energy = 1.4
	sun.rotation_degrees = Vector3(-56.0, -32.0, 0.0)
	pixel_world_root.add_child(sun)

	decor_root = Node3D.new()
	decor_root.name = "StreamingDecor"
	pixel_world_root.add_child(decor_root)

	_create_ground()
	_create_decor_pool()
	_create_player_3d()
	_create_array_visuals()
	_create_enemy_pool()
	_update_pixel_3d_world(0.0)


func _create_materials() -> void:
	ground_material = _make_material(Color(0.24, 0.37, 0.47, 1.0), false)
	ground_patch_materials = [
		_make_material(Color(0.67, 0.83, 0.86, 0.42), true, true),
		_make_material(Color(0.55, 0.74, 0.80, 0.32), true, true),
		_make_material(Color(0.76, 0.90, 0.88, 0.28), true, true),
	]
	trunk_material = _make_material(Color(0.12, 0.22, 0.30, 0.82), true, true)
	foliage_materials = [
		_make_material(Color(0.10, 0.25, 0.33, 0.70), true, true),
		_make_material(Color(0.16, 0.34, 0.42, 0.54), true, true),
		_make_material(Color(0.07, 0.18, 0.27, 0.62), true, true),
	]
	stone_material = _make_material(Color(0.70, 0.84, 0.88, 0.40), true, true)
	robe_material = _make_material(Color(0.78, 0.82, 0.80, 1.0), false)
	dark_robe_material = _make_material(Color(0.08, 0.10, 0.12, 1.0), false)
	hair_material = _make_material(Color(0.025, 0.030, 0.038, 1.0), true)
	skin_material = _make_material(Color(0.80, 0.68, 0.58, 1.0), false)
	sword_material_3d = _make_material(Color(0.60, 0.88, 1.0, 1.0), true)
	sword_core_material = _make_material(Color(0.93, 1.0, 0.98, 1.0), true)
	enemy_material = _make_material(Color(0.14, 0.06, 0.10, 1.0), false)
	enemy_edge_material = _make_material(Color(0.64, 0.10, 0.18, 1.0), true)
	ring_material = _make_material(Color(0.62, 1.0, 0.94, 0.34), true, true)
	fan_material = _make_material(Color(0.76, 0.90, 1.0, 0.22), true, true)
	pierce_material = _make_material(Color(0.92, 1.0, 0.96, 0.42), true, true)


func _make_material(color: Color, unshaded: bool, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if transparent or color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _create_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "ActionGroundBackdrop"
	ground.mesh = _make_box(Vector3(PLAY_SIZE.x * WORLD_TO_3D, 0.04, PLAY_SIZE.y * WORLD_TO_3D))
	ground.material_override = ground_material
	ground.position = _world2_to_3d(PLAY_RECT.get_center()) + Vector3(0.0, -0.08, 0.0)
	pixel_world_root.add_child(ground)


func _create_decor_pool() -> void:
	for i in range(PATCH_COUNT):
		var patch := MeshInstance3D.new()
		patch.name = "CloudPatch%02d" % i
		patch.mesh = _make_box(Vector3(1.0, 0.04, 1.0))
		patch.material_override = ground_patch_materials[i % ground_patch_materials.size()]
		decor_root.add_child(patch)
		patch_roots.append(patch)

	for i in range(TREE_COUNT):
		var tree := Node3D.new()
		tree.name = "DistantMountainShard%02d" % i
		var body := _make_mesh_instance("RidgeBody", _make_box(Vector3(1.25, 0.62, 0.05)), trunk_material, tree)
		body.position.y = 0.31
		var cap := _make_mesh_instance("RidgeCap", _make_box(Vector3(0.82, 0.34, 0.05)), foliage_materials[i % foliage_materials.size()], tree)
		cap.position = Vector3(0.10, 0.76, -0.02)
		decor_root.add_child(tree)
		tree_roots.append(tree)

	for i in range(STONE_COUNT):
		var stone := MeshInstance3D.new()
		stone.name = "BrightAirMarker%02d" % i
		stone.mesh = _make_box(Vector3(0.48, 0.10, 0.22))
		stone.material_override = stone_material
		decor_root.add_child(stone)
		stone_roots.append(stone)


func _create_player_3d() -> void:
	player_root_3d = Node3D.new()
	player_root_3d.name = "V4SmallRider3D"
	player_root_3d.visible = show_3d_rider
	pixel_world_root.add_child(player_root_3d)

	player_yaw_root = Node3D.new()
	player_yaw_root.name = "HeadingRoot"
	player_root_3d.add_child(player_yaw_root)

	sword_root_3d = Node3D.new()
	sword_root_3d.name = "FlyingSword"
	player_yaw_root.add_child(sword_root_3d)
	var sword_body := _make_mesh_instance("SwordBody", _make_box(Vector3(1.42, 0.045, 0.085)), sword_material_3d, sword_root_3d)
	sword_body.position = Vector3(0.0, 0.075, -0.18)
	var sword_core := _make_mesh_instance("SwordCore", _make_box(Vector3(1.12, 0.055, 0.035)), sword_core_material, sword_root_3d)
	sword_core.position = Vector3(0.0, 0.11, -0.20)

	player_body_root = Node3D.new()
	player_body_root.name = "BodyLeanRoot"
	player_root_3d.add_child(player_body_root)

	model_pose_root = Node3D.new()
	model_pose_root.name = "ModelPoseRoot"
	player_body_root.add_child(model_pose_root)

	model_fit_root = Node3D.new()
	model_fit_root.name = "ModelFitRoot"
	model_pose_root.add_child(model_fit_root)
	_create_or_reload_rider_model()


func _create_array_visuals() -> void:
	array_root_3d = Node3D.new()
	array_root_3d.name = "SwordArrayReadability"
	array_root_3d.visible = show_3d_array_readability
	pixel_world_root.add_child(array_root_3d)

	ring_mesh_instance = MeshInstance3D.new()
	ring_mesh_instance.name = "RingRangeRead"
	ring_mesh_instance.mesh = _make_ring_mesh(0.76, 0.96, 56)
	ring_mesh_instance.material_override = ring_material
	array_root_3d.add_child(ring_mesh_instance)

	fan_mesh_instance = MeshInstance3D.new()
	fan_mesh_instance.name = "FanSweepRead"
	fan_mesh_instance.mesh = _make_fan_mesh(2.05, deg_to_rad(86.0), 28)
	fan_mesh_instance.material_override = fan_material
	array_root_3d.add_child(fan_mesh_instance)

	pierce_mesh_instance = MeshInstance3D.new()
	pierce_mesh_instance.name = "PierceLineRead"
	pierce_mesh_instance.mesh = _make_box(Vector3(3.1, 0.18, 0.028))
	pierce_mesh_instance.material_override = pierce_material
	pierce_mesh_instance.position = Vector3(1.66, 0.0, -0.01)
	array_root_3d.add_child(pierce_mesh_instance)


func _create_enemy_pool() -> void:
	for i in range(ENEMY_OFFSETS.size()):
		var enemy := Node3D.new()
		enemy.name = "ReadabilityEnemy%02d" % i
		var body := _make_mesh_instance("EnemyBody", _make_box(Vector3(0.34, 0.62, 0.28)), enemy_material, enemy)
		body.position.y = 0.44
		var shoulder := _make_mesh_instance("EnemyShoulderFlash", _make_box(Vector3(0.48, 0.12, 0.10)), enemy_edge_material, enemy)
		shoulder.position = Vector3(0.0, 0.76, -0.08)
		var weapon := _make_mesh_instance("EnemyWeapon", _make_box(Vector3(0.08, 0.06, 0.88)), enemy_edge_material, enemy)
		weapon.position = Vector3(0.22, 0.56, -0.34)
		weapon.rotation.z = deg_to_rad(16.0)
		pixel_world_root.add_child(enemy)
		enemy_roots.append(enemy)


func _update_pixel_3d_world(delta: float) -> void:
	if pixel_world_camera == null:
		return
	_update_pixel_camera()
	_update_streaming_decor()
	player_root_3d.visible = show_3d_rider
	if show_3d_rider:
		_update_player_3d(delta)
	if show_3d_array_readability:
		_update_array_visuals()
	_update_enemies()


func _update_pixel_camera() -> void:
	var target := _world2_to_3d(camera_center)
	var camera_offset := Vector3(CAMERA_RIGHT_DRIFT, CAMERA_HEIGHT, CAMERA_BACK)
	pixel_world_camera.position = target + camera_offset
	pixel_world_camera.look_at(target, Vector3.UP)
	pixel_world_camera.size = VIEW_SIZE.y * camera_zoom * WORLD_TO_3D * pixel_camera_size_scale


func _update_streaming_decor() -> void:
	var base_cell := Vector2(floorf(camera_center.x / DECOR_GRID_STEP), floorf(camera_center.y / DECOR_GRID_STEP))

	for i in range(patch_roots.size()):
		var patch := patch_roots[i] as MeshInstance3D
		var pos2 := _decor_position(base_cell, i, 7, 5, 0.0)
		var sx := lerpf(1.9, 5.2, _hash01(float(i) * 7.13 + base_cell.x))
		var sy := lerpf(0.35, 1.35, _hash01(float(i) * 5.31 + base_cell.y))
		patch.position = _world2_to_3d(pos2) + Vector3(0.0, -0.045, 0.0)
		patch.scale = Vector3(sx, 1.0, sy)
		patch.rotation.y = (_hash01(float(i) * 1.73 + base_cell.x * 2.0) - 0.5) * 0.28

	for i in range(tree_roots.size()):
		var tree := tree_roots[i] as Node3D
		var pos2 := _decor_position(base_cell, i, 8, 5, 120.0)
		if pos2.distance_to(flight_pos) < 360.0:
			pos2 += Vector2(260.0, -280.0)
		var scale_x := lerpf(1.6, 4.4, _hash01(float(i) * 3.21 + base_cell.y))
		var scale_y := lerpf(0.8, 2.4, _hash01(float(i) * 2.43 + base_cell.x))
		tree.position = _world2_to_3d(pos2)
		tree.scale = Vector3(scale_x, scale_y, 1.0)
		tree.rotation.y = (_hash01(float(i) * 4.41 + base_cell.x) - 0.5) * 0.22

	for i in range(stone_roots.size()):
		var stone := stone_roots[i] as MeshInstance3D
		var pos2 := _decor_position(base_cell, i, 6, 4, -190.0)
		var scale_value := lerpf(0.65, 1.45, _hash01(float(i) * 2.77 + base_cell.x - base_cell.y))
		stone.position = _world2_to_3d(pos2) + Vector3(0.0, 0.035, 0.0)
		stone.scale = Vector3(scale_value, 1.0, scale_value * 0.72)
		stone.rotation.y = _hash01(float(i) * 6.19 + base_cell.y) * TAU


func _decor_position(base_cell: Vector2, index: int, columns: int, rows: int, phase: float) -> Vector2:
	var col := index % columns - columns / 2
	var row := int(index / columns) % rows - rows / 2
	var cell := base_cell + Vector2(col, row)
	var seed := float(index) * 11.37 + cell.x * 23.19 + cell.y * 31.73 + phase
	var jitter := Vector2(
		(_hash01(seed) - 0.5) * DECOR_GRID_STEP * 0.76,
		(_hash01(seed + 8.1) - 0.5) * DECOR_GRID_STEP * 0.76
	)
	return cell * DECOR_GRID_STEP + jitter


func _update_player_3d(_delta: float) -> void:
	var bob := sin(time * 3.8) * 0.018
	player_root_3d.position = _world2_to_3d(visual_pos) + Vector3(0.0, 0.22 + bob, 0.0)
	player_root_3d.scale = Vector3.ONE * player_visual_scale

	player_yaw_root.rotation = Vector3.ZERO
	player_yaw_root.rotation.y = _heading_to_vertical_plane_angle(visual_heading)

	var turn_lean := clampf(heading_angle_delta / 1.35, -1.0, 1.0)
	var speed_ratio := clampf(velocity.length() / BOOST_SPEED, 0.0, 1.0)
	var climb := clampf(-visual_heading.y, -1.0, 1.0)
	player_body_root.rotation = Vector3.ZERO
	player_body_root.rotation.z = -turn_lean * 0.08 + carve_direction * carve_energy * 0.06
	player_body_root.position = Vector3(0.0, 0.02 * climb, lerpf(0.03, -0.10, boost_energy))
	if model_pose_root != null:
		model_pose_root.rotation_degrees = Vector3(-90.0, 0.0, rider_model_yaw_offset_degrees if active_model_path != "" else 0.0)
	if active_model_path == "":
		_update_drawn_pixel_rider_pose(speed_ratio)
	sword_root_3d.rotation.x = deg_to_rad(lerpf(2.0, -8.0, boost_energy)) + carve_direction * carve_energy * 0.05


func _update_array_visuals() -> void:
	array_root_3d.position = _world2_to_3d(visual_pos) + Vector3(0.0, 0.045, 0.0)
	array_root_3d.rotation = Vector3.ZERO
	array_root_3d.rotation.y = _heading_to_vertical_plane_angle(visual_heading)
	var pulse := 0.5 + 0.5 * sin(time * 2.6)
	ring_mesh_instance.scale = Vector3.ONE * (1.0 + pulse * 0.045 + turn_energy * 0.08)
	fan_mesh_instance.position = Vector3(0.32, 0.0, -0.015)
	fan_mesh_instance.scale = Vector3.ONE * (1.0 + throttle_energy * 0.08)
	pierce_mesh_instance.scale = Vector3(lerpf(0.82, 1.26, boost_energy), lerpf(0.74, 1.08, boost_energy), 1.0)


func _update_enemies() -> void:
	for i in range(enemy_roots.size()):
		var enemy := enemy_roots[i] as Node3D
		var orbit := Vector2(cos(time * 0.55 + float(i) * 1.8), sin(time * 0.43 + float(i) * 2.2)) * 64.0
		var pos2: Vector2 = flight_pos + ENEMY_OFFSETS[i] + orbit
		enemy.position = _world2_to_3d(pos2)
		enemy.position.y += 0.08 + sin(time * 3.0 + float(i)) * 0.035
		enemy.rotation = Vector3.ZERO
		enemy.rotation.y = _heading_to_vertical_plane_angle(flight_pos - pos2)


func _world2_to_3d(pos: Vector2) -> Vector3:
	var relative := pos - FLIGHT_START_POS
	return Vector3(relative.x * WORLD_TO_3D, 0.0, relative.y * WORLD_TO_3D)


func _dir2_to_3d(dir: Vector2) -> Vector3:
	if dir.length_squared() <= 0.0001:
		return Vector3.FORWARD
	var safe := dir.normalized()
	return Vector3(safe.x, 0.0, safe.y).normalized()


func _heading_to_vertical_plane_angle(dir: Vector2) -> float:
	if dir.length_squared() <= 0.0001:
		return 0.0
	var safe := dir.normalized()
	return atan2(-safe.y, safe.x)


func _current_3d_direction_label() -> String:
	if visual_heading.length_squared() <= 0.0001:
		return "right"
	var safe := visual_heading.normalized()
	var angle := wrapf(safe.angle(), -PI, PI)
	var sector := int(posmod(roundi(angle / (PI * 0.25)), 8))
	var labels := [
		"right",
		"down_right",
		"down",
		"down_left",
		"left",
		"up_left",
		"up",
		"up_right",
	]
	return labels[sector]


func _create_or_reload_rider_model() -> void:
	if model_fit_root == null:
		return
	for child in model_fit_root.get_children():
		child.queue_free()
	model_instance = null
	drawn_rider_root = null
	drawn_rider_parts.clear()
	active_model_path = _resolve_model_path(rider_model_path)
	if active_model_path != "":
		var resource := load(active_model_path)
		if resource is PackedScene:
			model_instance = resource.instantiate()
		elif resource is Mesh:
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.mesh = resource
			model_instance = mesh_instance
	if model_instance == null:
		model_instance = _create_placeholder_rider()
	model_fit_root.add_child(model_instance)
	_apply_preview_material(model_instance)
	if active_model_path == "":
		_update_drawn_pixel_rider_pose(clampf(velocity.length() / BOOST_SPEED, 0.0, 1.0))
	_fit_rider_model_to_view()


func _resolve_model_path(preferred_path: String) -> String:
	var candidate := preferred_path.strip_edges()
	if candidate != "" and ResourceLoader.exists(candidate):
		return candidate
	return ""


func _create_placeholder_rider() -> Node3D:
	var root := Node3D.new()
	root.name = "DrawnPixelRider"
	drawn_rider_root = root
	_make_drawn_rider_part("far_arm", "FarSleeve", robe_material, root)
	_make_drawn_rider_part("far_leg", "FarLeg", dark_robe_material, root)
	_make_drawn_rider_part("lower_robe", "LowerRobe", dark_robe_material, root)
	_make_drawn_rider_part("torso", "LightRobe", robe_material, root)
	_make_drawn_rider_part("head", "Head", skin_material, root)
	_make_drawn_rider_part("hair", "Hair", hair_material, root)
	_make_drawn_rider_part("hair_ribbon", "HairRibbon", hair_material, root)
	_make_drawn_rider_part("near_leg", "NearLeg", dark_robe_material, root)
	_make_drawn_rider_part("near_arm", "NearSleeve", robe_material, root)
	return root


func _make_drawn_rider_part(key: String, name: String, material: Material, parent: Node) -> MeshInstance3D:
	var part := _make_mesh_instance(name, _make_box(Vector3.ONE), material, parent)
	drawn_rider_parts[key] = part
	return part


func _update_drawn_pixel_rider_pose(speed_ratio: float) -> void:
	if drawn_rider_root == null or drawn_rider_parts.is_empty():
		return
	var h := _drawn_rider_pose_heading()
	var up := Vector2(0.0, 1.0)
	var near_sign := signf(h.x)
	if near_sign == 0.0:
		near_sign = 1.0
	var near := Vector2(near_sign, 0.0)
	var far := -near
	var front_profile := absf(h.y)
	var side_profile := absf(h.x)
	var pose_pressure := clampf(maxf(speed_ratio, maxf(boost_energy * 0.86, throttle_energy * 0.58)), 0.0, 1.0)
	var fast := smoothstep(0.16, 0.86, pose_pressure)
	var carve := clampf(carve_energy + turn_energy * 0.45, 0.0, 1.0)
	var turn_side := h.rotated(PI * 0.5) * carve_direction * carve * 0.07

	var foot_center := Vector2(0.0, 0.10)
	var hip_center := foot_center + up * lerpf(0.42, 0.35, fast) - h * lerpf(0.02, 0.16, fast) + turn_side * 0.28
	var shoulder_center := hip_center + up * lerpf(0.34, 0.25, fast) + h * lerpf(0.05, 0.37, fast) + turn_side * 0.72
	var head_center := shoulder_center + up * lerpf(0.18, 0.16, fast) + h * lerpf(0.02, 0.11, fast) + turn_side * 0.62
	var torso_width := lerpf(0.10, 0.25, front_profile) * lerpf(1.0, 0.86, fast)
	var hip_width := lerpf(0.075, 0.17, front_profile) * lerpf(1.0, 0.88, fast)
	if side_profile > 0.65:
		torso_width = maxf(torso_width, 0.115)
		hip_width = maxf(hip_width, 0.085)

	var shoulder_near := shoulder_center + near * torso_width
	var shoulder_far := shoulder_center + far * torso_width * 0.82
	var hip_near := hip_center + near * hip_width
	var hip_far := hip_center + far * hip_width * 0.86
	var foot_spacing := lerpf(0.085, 0.18, front_profile)
	var foot_stagger := lerpf(0.20, 0.075, front_profile)
	var ankle_near := foot_center + near * foot_spacing + h * foot_stagger
	var ankle_far := foot_center + far * foot_spacing - h * foot_stagger
	var knee_near := hip_near.lerp(ankle_near, 0.58) + near * 0.045 + h * 0.045
	var knee_far := hip_far.lerp(ankle_far, 0.58) + far * 0.038 + h * 0.025

	var arm_spread := lerpf(0.055, 0.145, front_profile)
	var wrist_near := shoulder_near - h * lerpf(0.08, 0.54, fast) + near * (arm_spread + 0.08) + up * lerpf(-0.26, -0.18, fast)
	var wrist_far := shoulder_far - h * lerpf(0.05, 0.48, fast) + far * (arm_spread * 0.76 + 0.05) + up * lerpf(-0.28, -0.20, fast)
	var elbow_near := shoulder_near.lerp(wrist_near, 0.48) + near * 0.035 + h * 0.035
	var elbow_far := shoulder_far.lerp(wrist_far, 0.48) + far * 0.028 + h * 0.020

	var near_depth := -0.045
	var far_depth := 0.040
	var body_depth := 0.0
	_pose_drawn_limb("far_arm", shoulder_far, elbow_far.lerp(wrist_far, 0.84), 0.085, far_depth)
	_pose_drawn_limb("far_leg", hip_far, knee_far.lerp(ankle_far, 0.90), 0.090, far_depth)
	_pose_drawn_limb("lower_robe", hip_center, foot_center + up * 0.025 - h * 0.035, hip_width * 2.35, body_depth)
	_pose_drawn_limb("torso", hip_center, shoulder_center, torso_width * 2.12, body_depth - 0.012)
	_pose_drawn_box("head", head_center, Vector2(lerpf(0.18, 0.24, front_profile), 0.20), body_depth - 0.030, 0.0)
	_pose_drawn_box("hair", head_center - h * 0.035 + up * 0.025, Vector2(lerpf(0.20, 0.27, front_profile), 0.16), body_depth - 0.055, 0.0)
	_pose_drawn_limb("hair_ribbon", head_center - h * 0.07 + up * -0.035, head_center - h * lerpf(0.30, 0.48, fast) + up * lerpf(-0.02, -0.10, fast), 0.040, body_depth - 0.065)
	_pose_drawn_limb("near_leg", hip_near, knee_near.lerp(ankle_near, 0.90), 0.095, near_depth)
	_pose_drawn_limb("near_arm", shoulder_near, elbow_near.lerp(wrist_near, 0.84), 0.090, near_depth)


func _drawn_rider_pose_heading() -> Vector2:
	var safe := visual_heading
	if safe.length_squared() <= 0.0001:
		safe = Vector2.RIGHT
	else:
		safe = safe.normalized()
	var directions := [
		Vector2.RIGHT,
		Vector2(0.70710678, -0.70710678),
		Vector2.UP,
		Vector2(-0.70710678, -0.70710678),
		Vector2.LEFT,
		Vector2(-0.70710678, 0.70710678),
		Vector2.DOWN,
		Vector2(0.70710678, 0.70710678),
	]
	var best := Vector2.RIGHT
	var best_dot := -9999.0
	for direction in directions:
		var dot_value := safe.dot(direction)
		if dot_value > best_dot:
			best_dot = dot_value
			best = direction
	var pose_heading := Vector2(best.x, -best.y)
	if pose_heading.length_squared() <= 0.0001:
		return Vector2.RIGHT
	return pose_heading.normalized()


func _pose_drawn_limb(key: String, from_point: Vector2, to_point: Vector2, width: float, depth: float) -> void:
	var delta := to_point - from_point
	var length := maxf(delta.length(), 0.001)
	var center := (from_point + to_point) * 0.5
	_pose_drawn_box(key, center, Vector2(width, length), depth, atan2(delta.x, delta.y))


func _pose_drawn_box(key: String, center: Vector2, size: Vector2, depth: float, angle_y: float) -> void:
	var part := drawn_rider_parts.get(key) as MeshInstance3D
	if part == null:
		return
	part.visible = true
	part.position = Vector3(center.x, depth, center.y)
	part.rotation = Vector3(0.0, angle_y, 0.0)
	part.scale = Vector3(maxf(size.x, 0.001), 0.050, maxf(size.y, 0.001))


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
			standard.albedo_color = standard.albedo_color.lerp(Color(0.88, 0.96, 0.95, standard.albedo_color.a), 0.18)
			mesh_instance.set_surface_override_material(surface_index, standard)


func _fit_rider_model_to_view() -> void:
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
	var fit_scale := TARGET_MODEL_HEIGHT / height
	model_fit_root.scale = Vector3.ONE * rider_model_scale * fit_scale
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


func _make_mesh_instance(name: String, mesh: Mesh, material: Material, parent: Node) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _make_box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


func _make_ring_mesh(inner_radius: float, outer_radius: float, segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in range(segments):
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var base := vertices.size()
		vertices.append(Vector3(cos(a0) * outer_radius, sin(a0) * outer_radius, 0.0))
		vertices.append(Vector3(cos(a0) * inner_radius, sin(a0) * inner_radius, 0.0))
		vertices.append(Vector3(cos(a1) * outer_radius, sin(a1) * outer_radius, 0.0))
		vertices.append(Vector3(cos(a1) * inner_radius, sin(a1) * inner_radius, 0.0))
		indices.append_array(PackedInt32Array([base, base + 2, base + 1, base + 1, base + 2, base + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _make_fan_mesh(radius: float, angle: float, segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3.ZERO)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var a := lerpf(-angle * 0.5, angle * 0.5, t)
		vertices.append(Vector3(cos(a) * radius, sin(a) * radius, 0.0))
	for i in range(segments):
		indices.append_array(PackedInt32Array([0, i + 1, i + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
