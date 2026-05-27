extends Node2D
class_name FlightAtmosphereFx

const ART_BLUE := Color("88d8ff")
const ART_BLUE_CORE := Color("f6fbff")
const ART_GOLD := Color("d7bb79")

@export_group("Cloud Sea")
@export_enum("Performance", "Balanced", "Cinematic") var quality_preset := 2
@export_range(0.0, 3.0, 0.01) var cloud_density := 0.62
@export_range(0.0, 3.0, 0.01) var cloud_alpha := 0.56
@export_range(0.1, 4.0, 0.01) var cloud_speed_scale := 0.82
@export_range(0.0, 2.0, 0.01) var cloud_turbulence := 0.16
@export_group("Wind Veil")
@export_range(0.0, 3.0, 0.01) var wind_density := 0.52
@export_range(0.0, 3.0, 0.01) var wind_alpha := 0.48
@export_range(0.1, 4.0, 0.01) var wind_speed_scale := 1.0
@export_range(0.0, 2.0, 0.01) var wind_turbulence := 0.22
@export_range(0.1, 4.0, 0.01) var wind_trail_lifetime := 0.78
@export_range(6, 40, 1) var wind_trail_sections := 16
@export_range(1, 4, 1) var wind_trail_subdivisions := 1
@export_range(0.2, 4.0, 0.01) var wind_width_scale := 1.72
@export_group("")

var main: Node2D = null
var cloud_floor_particles: GPUParticles2D
var cloud_mid_particles: GPUParticles2D
var wind_veil_particles: GPUParticles2D
var wind_strand_particles: GPUParticles2D
var cloud_floor_material: ParticleProcessMaterial
var cloud_mid_material: ParticleProcessMaterial
var wind_veil_material: ParticleProcessMaterial
var wind_strand_material: ParticleProcessMaterial


func _ready() -> void:
	main = get_parent() as Node2D
	z_as_relative = false
	z_index = -18
	_build_layers()
	set_process(true)


func _process(_delta: float) -> void:
	if main == null or not is_instance_valid(main):
		main = get_parent() as Node2D
	if not _is_active():
		_set_emitting(false)
		visible = false
		return
	visible = true
	_set_emitting(true)
	_update_layers()


func _is_active() -> bool:
	if main == null:
		return false
	if main.has_method("_uses_flight_visuals"):
		if not bool(main.call("_uses_flight_visuals")):
			return false
	elif not main.has_method("_is_flight_prototype_mode") or not main._is_flight_prototype_mode():
		return false
	if bool(main.get("is_start_menu_active")):
		return false
	return true


func _build_layers() -> void:
	cloud_floor_material = ParticleProcessMaterial.new()
	cloud_mid_material = ParticleProcessMaterial.new()
	wind_veil_material = ParticleProcessMaterial.new()
	wind_strand_material = ParticleProcessMaterial.new()

	cloud_floor_particles = _create_particles(_make_soft_texture(164, 60, 2.4), cloud_floor_material, 64, 5.2, -20, false)
	cloud_mid_particles = _create_particles(_make_soft_texture(132, 48, 2.0), cloud_mid_material, 24, 5.8, -19, false)
	wind_veil_particles = _create_particles(_make_soft_texture(148, 22, 3.4), wind_veil_material, 11, 2.8, -16, true)
	wind_strand_particles = _create_particles(_make_soft_texture(82, 9, 4.0), wind_strand_material, 3, 2.1, -15, true)

	cloud_floor_particles.name = "CloudFloorParticles"
	cloud_mid_particles.name = "CloudMidParticles"
	wind_veil_particles.name = "WindVeilParticles"
	wind_strand_particles.name = "WindStrandParticles"


func _create_particles(
	texture: Texture2D,
	process_material: ParticleProcessMaterial,
	amount: int,
	lifetime: float,
	z_index_value: int,
	use_additive: bool
) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.texture = texture
	particles.process_material = process_material
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.one_shot = false
	particles.local_coords = false
	particles.emitting = false
	particles.randomness = 0.18
	particles.draw_order = GPUParticles2D.DRAW_ORDER_LIFETIME
	particles.trail_enabled = false
	particles.z_as_relative = false
	particles.z_index = z_index_value
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if use_additive else CanvasItemMaterial.BLEND_MODE_MIX
	particles.material = material
	add_child(particles)
	return particles


func _set_emitting(should_emit: bool) -> void:
	if cloud_floor_particles != null:
		cloud_floor_particles.emitting = should_emit
	if cloud_mid_particles != null:
		cloud_mid_particles.emitting = should_emit
	if wind_veil_particles != null:
		wind_veil_particles.emitting = should_emit
	if wind_strand_particles != null:
		wind_strand_particles.emitting = should_emit


func _update_layers() -> void:
	var arena_rect: Rect2 = main.ARENA_RECT
	var speed_ratio: float = clampf(float(main.flight_scroll_speed) / maxf(float(main.FLIGHT_BASE_SCROLL_SPEED), 1.0), 0.65, 1.5)
	var visibility := arena_rect.grow(520.0)

	_configure_cloud_layer(
		cloud_floor_particles,
		cloud_floor_material,
		Vector2(arena_rect.get_center().x + 40.0, arena_rect.position.y + arena_rect.size.y * 0.82),
		Vector3(arena_rect.size.x * 0.60, 66.0, 0.0),
		48,
		5.2,
		54.0 * cloud_speed_scale,
		126.0 * cloud_speed_scale,
		0.62,
		Color("d8e2ea").lerp(ART_BLUE, 0.42),
		0.090 * cloud_alpha,
		cloud_turbulence,
		visibility
	)
	_configure_cloud_layer(
		cloud_mid_particles,
		cloud_mid_material,
		Vector2(arena_rect.get_center().x + 120.0, arena_rect.position.y + arena_rect.size.y * 0.50),
		Vector3(arena_rect.size.x * 0.52, 108.0, 0.0),
		12,
		5.8,
		34.0 * cloud_speed_scale,
		86.0 * cloud_speed_scale,
		0.42,
		ART_BLUE_CORE.lerp(ART_GOLD, 0.12),
		0.040 * cloud_alpha,
		cloud_turbulence * 0.78,
		visibility
	)
	_configure_wind_layer(
		wind_veil_particles,
		wind_veil_material,
		Vector2(arena_rect.get_center().x + 110.0, arena_rect.get_center().y + 8.0),
		Vector3(arena_rect.size.x * 0.62, arena_rect.size.y * 0.38, 0.0),
		4,
		2.8,
		180.0 * speed_ratio * wind_speed_scale,
		340.0 * speed_ratio * wind_speed_scale,
		0.48,
		ART_BLUE_CORE.lerp(ART_GOLD, 0.10),
		0.16 * wind_alpha,
		wind_turbulence,
		visibility,
		1.0
	)
	_configure_wind_layer(
		wind_strand_particles,
		wind_strand_material,
		Vector2(arena_rect.get_center().x + 160.0, arena_rect.get_center().y - 18.0),
		Vector3(arena_rect.size.x * 0.58, arena_rect.size.y * 0.32, 0.0),
		2,
		2.1,
		260.0 * speed_ratio * wind_speed_scale,
		460.0 * speed_ratio * wind_speed_scale,
		0.64,
		ART_BLUE_CORE,
		0.18 * wind_alpha,
		wind_turbulence * 1.12,
		visibility,
		0.55
	)


func _configure_cloud_layer(
	particles: GPUParticles2D,
	material: ParticleProcessMaterial,
	position: Vector2,
	extents: Vector3,
	base_amount: int,
	lifetime_value: float,
	speed_min: float,
	speed_max: float,
	spread: float,
	color: Color,
	opacity: float,
	turbulence: float,
	visibility: Rect2
) -> void:
	particles.global_position = position
	particles.amount = maxi(1, int(round(float(base_amount) * cloud_density * _particle_quality_scale())))
	particles.lifetime = lifetime_value
	particles.preprocess = lifetime_value
	particles.visibility_rect = visibility
	particles.trail_enabled = false
	material.direction = Vector3(-1.0, 0.01, 0.0).normalized()
	material.spread = 18.0 + spread * 28.0
	material.gravity = Vector3(0.0, -1.5, 0.0)
	material.initial_velocity_min = speed_min
	material.initial_velocity_max = speed_max
	material.damping_min = 16.0
	material.damping_max = 46.0
	material.scale_min = 0.64
	material.scale_max = 1.76
	material.angle_min = -9.0
	material.angle_max = 9.0
	material.angular_velocity_min = -4.0
	material.angular_velocity_max = 4.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = extents
	_apply_turbulence(material, turbulence, 0.55)
	var gradient_key: String = "cloud:%s:%.3f" % [color.to_html(true), opacity]
	if _should_update_material_key(material, "flight_gradient_key", gradient_key):
		material.color_ramp = _make_gradient_texture([
			{"offset": 0.0, "color": _color_with_alpha(color, 0.0)},
			{"offset": 0.12, "color": _color_with_alpha(color, opacity * 0.52)},
			{"offset": 0.48, "color": _color_with_alpha(color.lerp(Color.WHITE, 0.12), opacity)},
			{"offset": 0.82, "color": _color_with_alpha(color.lerp(Color("07131b"), 0.22), opacity * 0.42)},
			{"offset": 1.0, "color": _color_with_alpha(color, 0.0)},
		])
		material.set_meta("flight_gradient_key", gradient_key)
	var curve_key := "cloud_curve_v2"
	if _should_update_material_key(material, "flight_curve_key", curve_key):
		material.scale_curve = _make_curve_texture([
			Vector2(0.0, 0.14),
			Vector2(0.18, 0.92),
			Vector2(0.68, 1.0),
			Vector2(1.0, 0.0),
		])
		material.set_meta("flight_curve_key", curve_key)


func _configure_wind_layer(
	particles: GPUParticles2D,
	material: ParticleProcessMaterial,
	position: Vector2,
	extents: Vector3,
	base_amount: int,
	lifetime_value: float,
	speed_min: float,
	speed_max: float,
	spread: float,
	color: Color,
	opacity: float,
	turbulence: float,
	visibility: Rect2,
	width_scale: float
) -> void:
	particles.global_position = position
	particles.amount = maxi(1, int(round(float(base_amount) * wind_density * _particle_quality_scale())))
	particles.lifetime = lifetime_value
	particles.preprocess = lifetime_value
	particles.visibility_rect = visibility
	particles.trail_enabled = true
	particles.trail_lifetime = clampf(wind_trail_lifetime, 0.1, 4.0)
	particles.trail_sections = maxi(4, int(round(float(wind_trail_sections) * _trail_quality_scale())))
	particles.trail_section_subdivisions = maxi(1, int(wind_trail_subdivisions))
	material.direction = Vector3(-1.0, 0.025, 0.0).normalized()
	material.spread = 5.0 + spread * 10.0
	material.gravity = Vector3(0.0, -0.4, 0.0)
	material.initial_velocity_min = speed_min
	material.initial_velocity_max = speed_max
	material.damping_min = 2.0
	material.damping_max = 14.0
	material.scale_min = 0.32 * wind_width_scale * width_scale
	material.scale_max = 0.92 * wind_width_scale * width_scale
	material.angle_min = -3.0
	material.angle_max = 3.0
	material.angular_velocity_min = -3.0
	material.angular_velocity_max = 3.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = extents
	_apply_turbulence(material, turbulence, 1.0)
	var gradient_key: String = "wind:%s:%.3f" % [color.to_html(true), opacity]
	if _should_update_material_key(material, "flight_gradient_key", gradient_key):
		material.color_ramp = _make_gradient_texture([
			{"offset": 0.0, "color": _color_with_alpha(color, 0.0)},
			{"offset": 0.10, "color": _color_with_alpha(color.lerp(Color.WHITE, 0.18), opacity * 0.62)},
			{"offset": 0.28, "color": _color_with_alpha(color, opacity)},
			{"offset": 0.52, "color": _color_with_alpha(color, opacity * 0.34)},
			{"offset": 0.82, "color": _color_with_alpha(color, 0.0)},
			{"offset": 1.0, "color": _color_with_alpha(color, 0.0)},
		])
		material.set_meta("flight_gradient_key", gradient_key)
	var curve_key := "wind_curve_v2"
	if _should_update_material_key(material, "flight_curve_key", curve_key):
		material.scale_curve = _make_curve_texture([
			Vector2(0.0, 0.0),
			Vector2(0.08, 0.58),
			Vector2(0.44, 1.0),
			Vector2(0.78, 0.36),
			Vector2(1.0, 0.0),
		])
		material.set_meta("flight_curve_key", curve_key)


func _apply_turbulence(material: ParticleProcessMaterial, amount: float, strength_scale: float) -> void:
	material.turbulence_enabled = amount > 0.001
	material.turbulence_noise_strength = amount * 0.52 * strength_scale
	material.turbulence_noise_scale = 0.92
	material.turbulence_noise_speed = Vector3(0.42 + amount * 0.32, 0.18 + amount * 0.2, 0.0)
	material.turbulence_influence_min = amount * 0.006 * strength_scale
	material.turbulence_influence_max = amount * 0.034 * strength_scale
	material.turbulence_initial_displacement_min = 0.0
	material.turbulence_initial_displacement_max = amount * 0.012 * strength_scale


func _particle_quality_scale() -> float:
	match int(quality_preset):
		0:
			return 0.58
		1:
			return 0.82
		_:
			return 1.0


func _trail_quality_scale() -> float:
	match int(quality_preset):
		0:
			return 0.54
		1:
			return 0.76
		_:
			return 1.0


func _should_update_material_key(material: ParticleProcessMaterial, meta_name: StringName, next_key: String) -> bool:
	if material == null:
		return false
	if not material.has_meta(meta_name):
		return true
	return str(material.get_meta(meta_name)) != next_key


func _make_gradient_texture(stops: Array) -> GradientTexture1D:
	var gradient := Gradient.new()
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for stop in stops:
		offsets.append(float(stop.get("offset", 0.0)))
		colors.append(Color(stop.get("color", Color.WHITE)))
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 128
	return texture


func _make_curve_texture(points: Array) -> CurveTexture:
	var curve := Curve.new()
	for point in points:
		curve.add_point(point)
	var texture := CurveTexture.new()
	texture.curve = curve
	texture.width = 128
	return texture


func _make_soft_texture(width: int, height: int, stretch: float) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(width - 1) * 0.5, float(height - 1) * 0.5)
	var radius := Vector2(maxf(float(width) * 0.5, 1.0), maxf(float(height) * 0.5, 1.0))
	for y in range(height):
		for x in range(width):
			var local := Vector2(float(x), float(y)) - center
			var uv := Vector2(local.x / radius.x, local.y / radius.y)
			var distance := sqrt(uv.x * uv.x + uv.y * uv.y * stretch)
			var alpha := pow(clampf(1.0 - distance, 0.0, 1.0), 1.8)
			var edge := pow(clampf(1.0 - absf(uv.x), 0.0, 1.0), 0.35)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * edge))
	return ImageTexture.create_from_image(image)


func _color_with_alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = alpha
	return result
