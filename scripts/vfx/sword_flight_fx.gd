extends Node2D

const SWORD_DISTORTION_SHADER = preload("res://resources/vfx/sword_flight_distortion.gdshader")
const ART_BLUE := Color("88d8ff")
const ART_BLUE_CORE := Color("f6fbff")
const ART_GOLD := Color("d7bb79")
const UNSHEATH_FLASH_CORE_COLOR := Color(1.0, 0.99, 0.96, 1.0)
const UNSHEATH_FLASH_EDGE_COLOR := Color(0.72, 0.9, 1.0, 1.0)
const WAKE_POOL_SIZE := 16
const TRAIL_SUBDIVISIONS := 5
const WAKE_SEGMENTS := 6
const RING_SEGMENTS := 20
const TRAIL_WIDTH_BASE_SCALE := 1.08
const TRAIL_HALO_WIDTH_SCALE := 1.28
const TRAIL_RIBBON_WIDTH_SCALE := 0.62
const TRAIL_CORE_WIDTH_SCALE := 0.16
const TRAIL_WARM_WIDTH_SCALE := 0.08
const TRAIL_HEAD_CLEARANCE_POINT := 18.0
const TRAIL_HEAD_CLEARANCE_SLICE := 21.0
const TRAIL_HEAD_CLEARANCE_RECALL := 14.0
const BODY_HALO_WIDTH_BASE := 1.6
const BODY_HALO_WIDTH_SCALE := 1.4
const BODY_RIBBON_WIDTH_BASE := 0.52
const BODY_RIBBON_WIDTH_SCALE := 0.44
const BODY_CORE_WIDTH_BASE := 0.16
const BODY_CORE_WIDTH_SCALE := 0.18
const BODY_SIDE_PARTICLE_SEGMENT_COUNT := 3
const BODY_FLOW_SAMPLE_COUNT := 17
const BODY_SIDE_MIST_PLUME_COUNT := 3
const MAIN_SWORD_VISUAL_SCALE := 1.6
const PARTICLE_VISIBILITY_RECT := Rect2(-360.0, -360.0, 720.0, 720.0)
const BURST_POOL_SIZE := 4
const BURST_TRIGGER_COOLDOWN := 0.06
const TURN_BURST_THRESHOLD := 0.34

@export_group("热浪扭曲")
@export var 扭曲启用 := true
@export_range(1, 16, 1) var 扭曲渲染层级 := 5
@export var 扭曲调试可见 := false
@export_range(0.0, 1.0, 0.01) var 扭曲调试透明度 := 0.18
@export_range(0.0, 1.0, 0.01) var 扭曲速度阈值 := 0.12
@export_range(0.0, 1.0, 0.01) var 扭曲转向阈值 := 0.14
@export_range(0.0, 32.0, 0.5) var 扭曲前移基础 := 10.0
@export_range(0.0, 32.0, 0.5) var 扭曲前移速度系数 := 10.0
@export_range(0.1, 4.0, 0.01) var 扭曲横向尺寸基础 := 0.56
@export_range(0.0, 4.0, 0.01) var 扭曲横向尺寸速度系数 := 0.92
@export_range(0.0, 4.0, 0.01) var 扭曲横向尺寸转向系数 := 0.42
@export_range(0.05, 1.5, 0.01) var 扭曲纵向尺寸基础 := 0.18
@export_range(0.0, 1.5, 0.01) var 扭曲纵向尺寸辉光系数 := 0.10
@export_range(0.0, 1.5, 0.01) var 扭曲纵向尺寸转向系数 := 0.06
@export_range(0.0, 0.02, 0.0001) var 扭曲强度基础 := 0.0014
@export_range(0.0, 0.02, 0.0001) var 扭曲强度速度系数 := 0.0024
@export_range(0.0, 0.02, 0.0001) var 扭曲强度转向系数 := 0.0012
@export_range(0.0, 1.5, 0.01) var 扭曲透明度基础 := 0.78
@export_range(0.0, 1.5, 0.01) var 扭曲透明度速度系数 := 0.12
@export_range(0.0, 1.5, 0.01) var 扭曲透明度转向系数 := 0.10
@export_range(0.0, 8.0, 0.05) var 扭曲流动基础 := 2.4
@export_range(0.0, 8.0, 0.05) var 扭曲流动速度系数 := 1.4

@export_group("剑体流光调试")
@export var 剑体流光启用 := true
@export_range(0.0, 2.0, 0.01) var 剑体流光整体强度 := 1.0
@export_range(0.2, 3.0, 0.01) var 剑体流带摆幅倍率 := 1.0
@export_range(0.2, 3.0, 0.01) var 剑体流带宽度倍率 := 1.0
@export_range(0.2, 3.0, 0.01) var 剑体流动速度倍率 := 1.0
@export_range(0.2, 3.0, 0.01) var 剑体流纹密度倍率 := 1.0
@export_range(0.2, 2.0, 0.01) var 剑体翻绕强度倍率 := 1.0
@export_range(0.0, 24.0, 0.1) var 剑体流光向后延伸 := 6.0
@export_range(0.0, 16.0, 0.1) var 剑体流光向前延伸 := 2.0
@export_range(0.0, 2.0, 0.01) var 主流透明度倍率 := 1.0
@export_range(0.0, 2.0, 0.01) var 副流透明度倍率 := 1.0
@export_range(0.0, 2.0, 0.01) var 剑尖流光透明度倍率 := 1.0
@export_range(0.0, 2.0, 0.01) var 贴身底辉强度倍率 := 1.0
@export_range(0.2, 2.0, 0.01) var 贴身底辉宽度倍率 := 1.0

@export_group("剑气补层调试")
@export var 剑气补层启用 := true
@export_range(0.0, 4.0, 0.01) var 剑气补层整体强度 := 1.0
@export_range(0.1, 4.0, 0.01) var 剑气薄雾长度倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 剑气薄雾宽度倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 剑气上刃外散强度 := 1.0
@export_range(0.0, 4.0, 0.01) var 剑气下刃外散强度 := 1.0
@export_range(-64.0, 64.0, 0.1) var 剑气沿剑身前后偏移 := 0.0
@export_range(0.1, 4.0, 0.01) var 剑气后外散距离倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 剑气后外散角度倍率 := 1.0
@export_range(0.0, 2.5, 0.01) var 剑气贴刃距离倍率 := 0.24
@export_range(0.0, 16.0, 0.1) var 剑气起喷外移 := 0.6
@export_range(0.0, 4.0, 0.01) var 剑气薄雾透明度倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 剑气粒子数量倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 剑气粒子速度倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 剑气粒子尺寸倍率 := 1.0
@export_range(0.1, 4.0, 0.01) var 剑气粒子散射倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 剑气尾雾强度倍率 := 1.0
@export_range(0.0, 4.0, 0.01) var 剑气前雾强度倍率 := 1.0

var main: Node2D = null
var source_side_sign := 0.0
var source_cache: Dictionary = {}

var trail_halo: Line2D
var trail_ribbon: Line2D
var trail_core: Line2D
var trail_warm: Line2D

var wake_halo_lines: Array = []
var wake_core_lines: Array = []

var base_blade_fill: Polygon2D
var base_blade_core_fill: Polygon2D
var base_handle_fill: Polygon2D
var base_guard_fill: Polygon2D
var base_pommel_fill: Polygon2D
var base_spine_line: Line2D
var base_upper_edge_line: Line2D
var base_lower_edge_line: Line2D
var base_guard_glint_line: Line2D

var body_flow_primary: Line2D
var body_flow_secondary: Line2D
var body_flow_tip: Line2D
var body_halo: Line2D
var body_ribbon: Line2D
var body_core: Line2D

var front_halo: Line2D
var front_ribbon: Line2D
var front_core: Line2D

var guard_ring: Line2D
var body_haze: Sprite2D
var body_upper_side_haze_sprites: Array = []
var body_lower_side_haze_sprites: Array = []
var trail_haze: Sprite2D
var front_haze: Sprite2D
var turn_slice: Sprite2D
var distortion_backbuffer: BackBufferCopy
var distortion_sprite: Sprite2D
var distortion_debug_sprite: Sprite2D
var distortion_material: ShaderMaterial
var aura_particles: GPUParticles2D
var wake_particles: GPUParticles2D
var aura_particle_material: ParticleProcessMaterial
var wake_particle_material: ParticleProcessMaterial
var body_upper_side_particles: Array = []
var body_lower_side_particles: Array = []
var body_upper_side_particle_materials: Array = []
var body_lower_side_particle_materials: Array = []
var burst_emitters: Array = []
var spark_emitters: Array = []
var accel_emitters: Array = []
var burst_emitter_cursor := 0
var spark_emitter_cursor := 0
var accel_emitter_cursor := 0
var previous_sword_state := -1
var previous_turn_strength := 0.0
var previous_impact_timer := 0.0
var previous_speed_ratio := 0.0
var burst_trigger_cooldown := 0.0


func _ready() -> void:
	main = get_parent() as Node2D
	z_as_relative = false
	z_index = 6
	_build_layers()
	set_process(true)


func _process(_delta: float) -> void:
	source_cache = _resolve_source_cache()
	if not _is_active():
		_clear_all()
		visible = false
		return
	visible = true
	_update_body_base()
	_update_body_flow()
	_update_body_glow()
	_update_front_beam()
	_update_trail()
	_update_wakes()
	_update_particles()
	_update_haze()
	_update_distortion(_delta)
	_update_burst_events(_delta)


func _is_active() -> bool:
	if main == null or not is_instance_valid(main):
		main = get_parent() as Node2D
	if main == null:
		return false
	if not main.has_method("_use_node_sword_flight_vfx"):
		return false
	if not bool(main.call("_use_node_sword_flight_vfx")):
		return false
	if bool(main.get("is_start_menu_active")):
		return false
	if _uses_clone_source():
		return bool(source_cache.get("active", false))
	return true


func _uses_clone_source() -> bool:
	return absf(source_side_sign) > 0.001


func _resolve_source_cache() -> Dictionary:
	if not _uses_clone_source():
		return {}
	if main == null or not is_instance_valid(main):
		main = get_parent() as Node2D
	if main == null or not main.has_method("_get_fan_time_stop_clone_source"):
		return {}
	var source = main.call("_get_fan_time_stop_clone_source", source_side_sign)
	return source if source is Dictionary else {}


func _get_source_sword() -> Dictionary:
	if _uses_clone_source():
		return source_cache.get("sword", {})
	return main.sword


func _get_source_trail_points() -> Array:
	if _uses_clone_source():
		return source_cache.get("trail_points", [])
	return main.sword_trail_points


func _get_source_air_wakes() -> Array:
	if _uses_clone_source():
		return source_cache.get("air_wakes", [])
	return main.sword_air_wakes


func _get_source_visual_position() -> Vector2:
	if _uses_clone_source():
		return Vector2(source_cache.get("visual_pos", Vector2.ZERO))
	return main._get_sword_visual_position()


func _get_source_visual_angle() -> float:
	if _uses_clone_source():
		return float(source_cache.get("visual_angle", 0.0))
	return main._get_sword_visual_angle()


func _get_source_player_mode() -> int:
	if _uses_clone_source():
		return int(source_cache.get("player_mode", main.CombatMode.RANGED))
	return int(main.player["mode"])


func _get_source_sword_state() -> int:
	return int(_get_source_sword().get("state", main.SwordState.ORBITING))


func _get_source_velocity() -> Vector2:
	return Vector2(_get_source_sword().get("vel", Vector2.ZERO))


func _get_source_impact_ratio() -> float:
	return clampf(
		float(_get_source_sword().get("impact_feedback_timer", 0.0)) / maxf(main.SWORD_IMPACT_FEEDBACK_DURATION, 0.001),
		0.0,
		1.0
	)


func _build_layers() -> void:
	trail_halo = _create_line(_make_alpha_gradient([0.0, 0.14, 0.7, 0.9, 1.0], [0.0, 0.08, 0.44, 0.08, 0.0]), _make_curve([
		Vector2(0.0, 0.02),
		Vector2(0.16, 0.48),
		Vector2(0.62, 0.72),
		Vector2(0.84, 0.24),
		Vector2(1.0, 0.0),
	]))
	trail_ribbon = _create_line(_make_alpha_gradient([0.0, 0.16, 0.74, 0.92, 1.0], [0.0, 0.18, 0.82, 0.06, 0.0]), _make_curve([
		Vector2(0.0, 0.04),
		Vector2(0.22, 0.44),
		Vector2(0.7, 0.64),
		Vector2(0.88, 0.16),
		Vector2(1.0, 0.0),
	]))
	trail_core = _create_line(_make_alpha_gradient([0.0, 0.22, 0.78, 0.94, 1.0], [0.0, 0.08, 0.96, 0.02, 0.0]), _make_curve([
		Vector2(0.0, 0.0),
		Vector2(0.28, 0.28),
		Vector2(0.76, 0.46),
		Vector2(0.9, 0.08),
		Vector2(1.0, 0.0),
	]))
	trail_warm = _create_line(_make_alpha_gradient([0.0, 0.34, 0.82, 1.0], [0.0, 0.0, 0.3, 0.0]), _make_curve([
		Vector2(0.0, 0.0),
		Vector2(0.46, 0.18),
		Vector2(0.82, 0.3),
		Vector2(1.0, 0.0),
	]))

	for wake_index in range(WAKE_POOL_SIZE):
		var halo_line := _create_line(_make_alpha_gradient([0.0, 0.24, 0.68, 1.0], [0.0, 0.18, 0.52, 0.0]), _make_curve([
			Vector2(0.0, 0.0),
			Vector2(0.26, 0.84),
			Vector2(0.68, 0.8),
			Vector2(1.0, 0.0),
		]))
		var core_line := _create_line(_make_alpha_gradient([0.0, 0.24, 0.74, 1.0], [0.0, 0.1, 0.76, 0.0]), _make_curve([
			Vector2(0.0, 0.0),
			Vector2(0.3, 0.76),
			Vector2(0.72, 0.86),
			Vector2(1.0, 0.0),
		]))
		halo_line.name = "WakeHalo%d" % wake_index
		core_line.name = "WakeCore%d" % wake_index
		wake_halo_lines.append(halo_line)
		wake_core_lines.append(core_line)

	_build_body_base_layer()
	_build_body_flow_layer()

	body_halo = _create_line(_make_alpha_gradient([0.0, 0.14, 0.82, 1.0], [0.18, 0.42, 0.72, 0.24]), _make_curve([
		Vector2(0.0, 0.3),
		Vector2(0.18, 0.82),
		Vector2(0.82, 1.0),
		Vector2(1.0, 0.22),
	]))
	body_ribbon = _create_line(_make_alpha_gradient([0.0, 0.16, 0.84, 1.0], [0.16, 0.52, 0.96, 0.38]), _make_curve([
		Vector2(0.0, 0.24),
		Vector2(0.2, 0.8),
		Vector2(0.86, 1.0),
		Vector2(1.0, 0.24),
	]))
	body_core = _create_line(_make_alpha_gradient([0.0, 0.18, 0.88, 1.0], [0.12, 0.62, 1.0, 0.46]), _make_curve([
		Vector2(0.0, 0.18),
		Vector2(0.22, 0.76),
		Vector2(0.88, 1.0),
		Vector2(1.0, 0.28),
	]))

	front_halo = _create_line(_make_alpha_gradient([0.0, 0.1, 0.78, 1.0], [0.0, 0.1, 0.92, 0.0]), _make_curve([
		Vector2(0.0, 0.08),
		Vector2(0.14, 0.96),
		Vector2(0.82, 1.0),
		Vector2(1.0, 0.02),
	]))
	front_ribbon = _create_line(_make_alpha_gradient([0.0, 0.12, 0.82, 1.0], [0.0, 0.18, 0.98, 0.04]), _make_curve([
		Vector2(0.0, 0.1),
		Vector2(0.18, 0.92),
		Vector2(0.86, 1.0),
		Vector2(1.0, 0.06),
	]))
	front_core = _create_line(_make_alpha_gradient([0.0, 0.22, 0.9, 1.0], [0.0, 0.16, 1.0, 0.06]), _make_curve([
		Vector2(0.0, 0.0),
		Vector2(0.3, 0.74),
		Vector2(0.9, 1.0),
		Vector2(1.0, 0.0),
	]))

	guard_ring = _create_line(null, null)
	_build_haze_layers()
	_build_particle_layers()
	_build_burst_particle_layers()
	_build_distortion_layer()


func _create_line(gradient: Gradient, width_curve: Curve, closed := false) -> Line2D:
	var line := Line2D.new()
	line.antialiased = true
	line.closed = closed
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.default_color = Color.WHITE
	line.material = _make_additive_material()
	if gradient != null:
		line.gradient = gradient
	if width_curve != null:
		line.width_curve = width_curve
	add_child(line)
	return line


func _create_sprite(texture: Texture2D, z_index_value: int, material_override: Material = null) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.z_index = z_index_value
	sprite.material = material_override if material_override != null else _make_additive_material()
	add_child(sprite)
	return sprite


func _create_polygon(z_index_value: int, material_override: Material = null) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.color = Color.WHITE
	polygon.z_index = z_index_value
	if material_override != null:
		polygon.material = material_override
	add_child(polygon)
	return polygon


func _make_additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


func _build_body_base_layer() -> void:
	base_blade_fill = _create_polygon(-2)
	base_blade_fill.name = "BaseBladeFill"
	base_blade_core_fill = _create_polygon(-1)
	base_blade_core_fill.name = "BaseBladeCoreFill"
	base_handle_fill = _create_polygon(-2)
	base_handle_fill.name = "BaseHandleFill"
	base_guard_fill = _create_polygon(-1)
	base_guard_fill.name = "BaseGuardFill"
	base_pommel_fill = _create_polygon(0)
	base_pommel_fill.name = "BasePommelFill"

	base_spine_line = _create_line(null, null)
	base_spine_line.name = "BaseSpineLine"
	base_spine_line.material = null
	base_spine_line.z_index = 3

	base_upper_edge_line = _create_line(null, null)
	base_upper_edge_line.name = "BaseUpperEdgeLine"
	base_upper_edge_line.material = null
	base_upper_edge_line.z_index = 4

	base_lower_edge_line = _create_line(null, null)
	base_lower_edge_line.name = "BaseLowerEdgeLine"
	base_lower_edge_line.material = null
	base_lower_edge_line.z_index = 4

	base_guard_glint_line = _create_line(null, null)
	base_guard_glint_line.name = "BaseGuardGlintLine"
	base_guard_glint_line.material = null
	base_guard_glint_line.z_index = 5


func _build_body_flow_layer() -> void:
	body_flow_primary = _create_line(_make_alpha_gradient([0.0, 0.16, 0.72, 0.92, 1.0], [0.0, 0.18, 0.96, 0.56, 0.0]), _make_curve([
		Vector2(0.0, 0.0),
		Vector2(0.16, 0.72),
		Vector2(0.64, 1.0),
		Vector2(0.9, 0.62),
		Vector2(1.0, 0.0),
	]))
	body_flow_primary.name = "BodyFlowPrimary"
	body_flow_primary.z_index = 1

	body_flow_secondary = _create_line(_make_alpha_gradient([0.0, 0.18, 0.76, 0.94, 1.0], [0.0, 0.12, 0.84, 0.42, 0.0]), _make_curve([
		Vector2(0.0, 0.0),
		Vector2(0.18, 0.64),
		Vector2(0.68, 0.94),
		Vector2(0.92, 0.54),
		Vector2(1.0, 0.0),
	]))
	body_flow_secondary.name = "BodyFlowSecondary"
	body_flow_secondary.z_index = 2

	body_flow_tip = _create_line(_make_alpha_gradient([0.0, 0.18, 0.82, 1.0], [0.0, 0.06, 0.72, 0.0]), _make_curve([
		Vector2(0.0, 0.0),
		Vector2(0.24, 0.54),
		Vector2(0.74, 0.9),
		Vector2(1.0, 0.0),
	]))
	body_flow_tip.name = "BodyFlowTip"
	body_flow_tip.z_index = 3


func _build_particle_layers() -> void:
	aura_particle_material = _make_side_backscatter_particle_material()
	aura_particles = _create_particles_node(_make_soft_particle_texture(18, 1.0), aura_particle_material, 30, 0.22)
	aura_particles.name = "BodyUpperSideParticles0"
	aura_particles.z_index = -2
	aura_particles.preprocess = 0.12
	body_upper_side_particles.append(aura_particles)
	body_upper_side_particle_materials.append(aura_particle_material)

	wake_particle_material = _make_side_backscatter_particle_material()
	wake_particles = _create_particles_node(_make_soft_particle_texture(18, 1.0), wake_particle_material, 30, 0.22)
	wake_particles.name = "BodyLowerSideParticles0"
	wake_particles.z_index = -2
	wake_particles.preprocess = 0.12
	body_lower_side_particles.append(wake_particles)
	body_lower_side_particle_materials.append(wake_particle_material)

	for index in range(1, BODY_SIDE_PARTICLE_SEGMENT_COUNT):
		var upper_material := _make_side_backscatter_particle_material()
		var upper_particles := _create_particles_node(_make_soft_particle_texture(18, 1.0), upper_material, 30, 0.22)
		upper_particles.name = "BodyUpperSideParticles%d" % index
		upper_particles.z_index = -2
		upper_particles.preprocess = 0.08
		body_upper_side_particles.append(upper_particles)
		body_upper_side_particle_materials.append(upper_material)

		var lower_material := _make_side_backscatter_particle_material()
		var lower_particles := _create_particles_node(_make_soft_particle_texture(18, 1.0), lower_material, 30, 0.22)
		lower_particles.name = "BodyLowerSideParticles%d" % index
		lower_particles.z_index = -2
		lower_particles.preprocess = 0.08
		body_lower_side_particles.append(lower_particles)
		body_lower_side_particle_materials.append(lower_material)


func _build_haze_layers() -> void:
	body_haze = _create_sprite(_make_soft_particle_texture(132, 1.4), -4)
	body_haze.name = "BodyHaze"
	for index in range(BODY_SIDE_MIST_PLUME_COUNT):
		var upper_haze := _create_sprite(_make_soft_particle_texture(112 + index * 10, 3.4), -4)
		upper_haze.name = "BodyUpperSideHaze%d" % index
		body_upper_side_haze_sprites.append(upper_haze)
		var lower_haze := _create_sprite(_make_soft_particle_texture(112 + index * 10, 3.4), -4)
		lower_haze.name = "BodyLowerSideHaze%d" % index
		body_lower_side_haze_sprites.append(lower_haze)
	trail_haze = _create_sprite(_make_soft_particle_texture(124, 3.1), -5)
	trail_haze.name = "TrailHaze"
	front_haze = _create_sprite(_make_soft_particle_texture(108, 2.2), -3)
	front_haze.name = "FrontHaze"
	turn_slice = _create_sprite(_make_slice_texture(132, 22), -2)
	turn_slice.name = "TurnSlice"


func _build_distortion_layer() -> void:
	distortion_backbuffer = BackBufferCopy.new()
	distortion_backbuffer.name = "DistortionBackBuffer"
	distortion_backbuffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	distortion_backbuffer.z_as_relative = false
	distortion_backbuffer.z_index = 扭曲渲染层级
	add_child(distortion_backbuffer)

	distortion_material = ShaderMaterial.new()
	distortion_material.shader = SWORD_DISTORTION_SHADER
	distortion_sprite = _create_sprite(_make_soft_particle_texture(128, 2.6), 扭曲渲染层级, distortion_material)
	distortion_sprite.name = "Distortion"
	distortion_sprite.z_as_relative = false
	distortion_sprite.z_index = 扭曲渲染层级

	var debug_material := CanvasItemMaterial.new()
	debug_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	distortion_debug_sprite = _create_sprite(_make_soft_particle_texture(128, 2.6), 扭曲渲染层级 + 1, debug_material)
	distortion_debug_sprite.name = "DistortionDebug"
	distortion_debug_sprite.z_as_relative = false
	distortion_debug_sprite.z_index = 扭曲渲染层级 + 1
	distortion_debug_sprite.visible = false


func _build_burst_particle_layers() -> void:
	for index in range(BURST_POOL_SIZE):
		var burst := _create_one_shot_particles_node(_make_soft_particle_texture(30, 1.4), _make_burst_particle_material(), 20, 0.32, -2)
		burst.name = "BurstEmitter%d" % index
		burst_emitters.append(burst)
		var spark := _create_one_shot_particles_node(_make_soft_particle_texture(24, 3.2), _make_spark_particle_material(), 14, 0.24, -1)
		spark.name = "SparkEmitter%d" % index
		spark_emitters.append(spark)
		var accel := _create_one_shot_particles_node(_make_soft_particle_texture(20, 4.6), _make_accel_streak_particle_material(), 12, 0.18, -1)
		accel.name = "AccelEmitter%d" % index
		accel_emitters.append(accel)


func _create_particles_node(texture: Texture2D, process_material: ParticleProcessMaterial, amount: int, lifetime: float) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.texture = texture
	particles.process_material = process_material
	particles.material = _make_additive_material()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = false
	particles.local_coords = false
	particles.emitting = false
	particles.randomness = 0.28
	particles.visibility_rect = PARTICLE_VISIBILITY_RECT
	particles.draw_order = GPUParticles2D.DRAW_ORDER_LIFETIME
	add_child(particles)
	return particles


func _create_one_shot_particles_node(texture: Texture2D, process_material: ParticleProcessMaterial, amount: int, lifetime: float, z_index_value: int) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.texture = texture
	particles.process_material = process_material
	particles.material = _make_additive_material()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.local_coords = false
	particles.emitting = false
	particles.randomness = 0.38
	particles.visibility_rect = PARTICLE_VISIBILITY_RECT
	particles.draw_order = GPUParticles2D.DRAW_ORDER_LIFETIME
	particles.z_index = z_index_value
	add_child(particles)
	return particles


func _make_aura_particle_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 180.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = 8.0
	material.initial_velocity_max = 28.0
	material.damping_min = 18.0
	material.damping_max = 32.0
	material.scale_min = 0.32
	material.scale_max = 0.88
	material.angle_min = -180.0
	material.angle_max = 180.0
	material.angular_velocity_min = -24.0
	material.angular_velocity_max = 24.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(4.0, 2.0, 0.0)
	material.color_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(1.8, 2.1, 2.4, 0.0)},
		{"offset": 0.12, "color": Color(1.9, 2.3, 2.7, 0.72)},
		{"offset": 0.48, "color": Color(0.72, 1.15, 1.6, 0.26)},
		{"offset": 1.0, "color": Color(0.2, 0.3, 0.45, 0.0)},
	])
	material.color_initial_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(1.25, 0.96, 0.62, 1.0)},
		{"offset": 0.58, "color": Color(0.68, 1.08, 1.52, 1.0)},
		{"offset": 1.0, "color": Color(1.0, 1.0, 1.0, 1.0)},
	])
	material.scale_curve = _make_curve_texture([
		Vector2(0.0, 0.18),
		Vector2(0.18, 0.92),
		Vector2(0.72, 0.58),
		Vector2(1.0, 0.0),
	])
	return material


func _make_side_backscatter_particle_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 16.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = 18.0
	material.initial_velocity_max = 44.0
	material.damping_min = 18.0
	material.damping_max = 30.0
	material.scale_min = 0.12
	material.scale_max = 0.34
	material.angle_min = -180.0
	material.angle_max = 180.0
	material.angular_velocity_min = -18.0
	material.angular_velocity_max = 18.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(8.0, 0.8, 0.0)
	material.color_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(1.7, 2.0, 2.2, 0.0)},
		{"offset": 0.06, "color": Color(1.95, 2.36, 2.72, 0.92)},
		{"offset": 0.24, "color": Color(0.94, 1.34, 1.74, 0.56)},
		{"offset": 0.62, "color": Color(0.54, 0.92, 1.28, 0.16)},
		{"offset": 1.0, "color": Color(0.12, 0.18, 0.28, 0.0)},
	])
	material.color_initial_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(1.18, 0.94, 0.62, 1.0)},
		{"offset": 0.34, "color": Color(0.82, 1.22, 1.72, 1.0)},
		{"offset": 1.0, "color": Color(1.0, 1.0, 1.0, 1.0)},
	])
	material.scale_curve = _make_curve_texture([
		Vector2(0.0, 0.06),
		Vector2(0.12, 1.0),
		Vector2(0.36, 0.72),
		Vector2(0.78, 0.18),
		Vector2(1.0, 0.0),
	])
	return material


func _make_wake_particle_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 22.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 168.0
	material.damping_min = 42.0
	material.damping_max = 68.0
	material.linear_accel_min = -48.0
	material.linear_accel_max = -24.0
	material.scale_min = 0.42
	material.scale_max = 1.06
	material.angle_min = -18.0
	material.angle_max = 18.0
	material.angular_velocity_min = -32.0
	material.angular_velocity_max = 32.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(2.8, 1.2, 0.0)
	material.color_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(1.5, 1.92, 2.2, 0.0)},
		{"offset": 0.08, "color": Color(1.8, 2.24, 2.7, 0.8)},
		{"offset": 0.36, "color": Color(0.68, 1.08, 1.54, 0.28)},
		{"offset": 1.0, "color": Color(0.12, 0.18, 0.28, 0.0)},
	])
	material.color_initial_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(1.24, 0.94, 0.58, 1.0)},
		{"offset": 0.32, "color": Color(0.9, 1.32, 1.78, 1.0)},
		{"offset": 1.0, "color": Color(1.0, 1.0, 1.0, 1.0)},
	])
	material.scale_curve = _make_curve_texture([
		Vector2(0.0, 0.12),
		Vector2(0.16, 0.94),
		Vector2(0.64, 0.42),
		Vector2(1.0, 0.0),
	])
	return material


func _make_burst_particle_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 92.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = 96.0
	material.initial_velocity_max = 220.0
	material.damping_min = 16.0
	material.damping_max = 30.0
	material.scale_min = 0.42
	material.scale_max = 1.18
	material.angle_min = -180.0
	material.angle_max = 180.0
	material.angular_velocity_min = -64.0
	material.angular_velocity_max = 64.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(4.6, 2.0, 0.0)
	material.color_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(1.85, 2.3, 2.7, 0.0)},
		{"offset": 0.08, "color": Color(1.95, 2.45, 2.9, 0.86)},
		{"offset": 0.36, "color": Color(0.82, 1.26, 1.7, 0.34)},
		{"offset": 1.0, "color": Color(0.12, 0.18, 0.28, 0.0)},
	])
	material.color_initial_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(1.25, 0.96, 0.58, 1.0)},
		{"offset": 0.52, "color": Color(0.76, 1.16, 1.64, 1.0)},
		{"offset": 1.0, "color": Color(1.0, 1.0, 1.0, 1.0)},
	])
	material.scale_curve = _make_curve_texture([
		Vector2(0.0, 0.12),
		Vector2(0.14, 1.0),
		Vector2(0.54, 0.52),
		Vector2(1.0, 0.0),
	])
	return material


func _make_spark_particle_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 32.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = 180.0
	material.initial_velocity_max = 360.0
	material.damping_min = 24.0
	material.damping_max = 46.0
	material.scale_min = 0.14
	material.scale_max = 0.42
	material.angle_min = -18.0
	material.angle_max = 18.0
	material.angular_velocity_min = -28.0
	material.angular_velocity_max = 28.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(2.8, 0.8, 0.0)
	material.color_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(2.1, 2.2, 2.4, 0.0)},
		{"offset": 0.1, "color": Color(2.4, 2.3, 1.8, 0.92)},
		{"offset": 0.42, "color": Color(0.82, 1.1, 1.44, 0.22)},
		{"offset": 1.0, "color": Color(0.08, 0.1, 0.16, 0.0)},
	])
	material.scale_curve = _make_curve_texture([
		Vector2(0.0, 0.1),
		Vector2(0.18, 1.0),
		Vector2(0.42, 0.44),
		Vector2(1.0, 0.0),
	])
	return material


func _make_accel_streak_particle_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 12.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = 220.0
	material.initial_velocity_max = 420.0
	material.damping_min = 34.0
	material.damping_max = 58.0
	material.scale_min = 0.18
	material.scale_max = 0.48
	material.angle_min = -8.0
	material.angle_max = 8.0
	material.angular_velocity_min = -16.0
	material.angular_velocity_max = 16.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(2.2, 0.5, 0.0)
	material.color_ramp = _make_gradient_texture_1d([
		{"offset": 0.0, "color": Color(2.0, 2.2, 2.4, 0.0)},
		{"offset": 0.08, "color": Color(2.3, 2.35, 2.1, 0.88)},
		{"offset": 0.32, "color": Color(0.88, 1.18, 1.5, 0.18)},
		{"offset": 1.0, "color": Color(0.08, 0.1, 0.16, 0.0)},
	])
	material.scale_curve = _make_curve_texture([
		Vector2(0.0, 0.08),
		Vector2(0.12, 1.0),
		Vector2(0.28, 0.7),
		Vector2(1.0, 0.0),
	])
	return material


func _make_gradient_texture_1d(stops: Array) -> GradientTexture1D:
	var gradient := Gradient.new()
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for stop in stops:
		offsets.append(float(stop["offset"]))
		colors.append(Color(stop["color"]))
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture1D.new()
	texture.width = 128
	texture.gradient = gradient
	return texture


func _make_curve_texture(points: Array) -> CurveTexture:
	var curve := Curve.new()
	for point in points:
		curve.add_point(point)
	var texture := CurveTexture.new()
	texture.width = 128
	texture.curve = curve
	return texture


func _make_soft_particle_texture(size: int, stretch: float) -> ImageTexture:
	var width: int = max(int(round(float(size) * stretch)), 4)
	var height: int = max(size, 4)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center := Vector2((float(width) - 1.0) * 0.5, (float(height) - 1.0) * 0.5)
	var inv_width := 1.0 / maxf(center.x, 1.0)
	var inv_height := 1.0 / maxf(center.y, 1.0)
	for y in range(height):
		for x in range(width):
			var offset := Vector2((float(x) - center.x) * inv_width, (float(y) - center.y) * inv_height)
			var dist := offset.length()
			var alpha := pow(maxf(1.0 - dist, 0.0), 2.4)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _make_slice_texture(width: int, height: int) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center := Vector2((float(width) - 1.0) * 0.5, (float(height) - 1.0) * 0.5)
	var inv_width := 1.0 / maxf(center.x, 1.0)
	var inv_height := 1.0 / maxf(center.y, 1.0)
	for y in range(height):
		for x in range(width):
			var nx: float = (float(x) - center.x) * inv_width
			var ny: float = absf((float(y) - center.y) * inv_height)
			var body: float = pow(maxf(1.0 - ny * 1.28, 0.0), 3.8)
			var tip_falloff: float = pow(maxf(1.0 - absf(nx), 0.0), 0.34)
			var tail_cut: float = smoothstep(-0.82, -0.18, nx)
			var head_cut: float = 1.0 - smoothstep(0.62, 1.0, nx)
			var alpha: float = body * tip_falloff * tail_cut * head_cut
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _make_alpha_gradient(offsets: Array, alphas: Array) -> Gradient:
	var gradient := Gradient.new()
	var colors := PackedColorArray()
	var packed_offsets := PackedFloat32Array()
	var point_count: int = min(offsets.size(), alphas.size())
	for index in range(point_count):
		packed_offsets.append(float(offsets[index]))
		colors.append(Color(1.0, 1.0, 1.0, float(alphas[index])))
	gradient.offsets = packed_offsets
	gradient.colors = colors
	return gradient


func _make_curve(points: Array) -> Curve:
	var curve := Curve.new()
	for point in points:
		curve.add_point(point)
	return curve


func _clear_all() -> void:
	_clear_line(trail_halo)
	_clear_line(trail_ribbon)
	_clear_line(trail_core)
	_clear_line(trail_warm)
	_clear_polygon(base_blade_fill)
	_clear_polygon(base_blade_core_fill)
	_clear_polygon(base_handle_fill)
	_clear_polygon(base_guard_fill)
	_clear_polygon(base_pommel_fill)
	_clear_line(base_spine_line)
	_clear_line(base_upper_edge_line)
	_clear_line(base_lower_edge_line)
	_clear_line(base_guard_glint_line)
	_clear_line(body_flow_primary)
	_clear_line(body_flow_secondary)
	_clear_line(body_flow_tip)
	_clear_line(body_halo)
	_clear_line(body_ribbon)
	_clear_line(body_core)
	_clear_line(front_halo)
	_clear_line(front_ribbon)
	_clear_line(front_core)
	_clear_line(guard_ring)
	_clear_sprite(body_haze)
	for sprite in body_upper_side_haze_sprites:
		_clear_sprite(sprite as Sprite2D)
	for sprite in body_lower_side_haze_sprites:
		_clear_sprite(sprite as Sprite2D)
	_clear_sprite(trail_haze)
	_clear_sprite(front_haze)
	_clear_sprite(turn_slice)
	if distortion_backbuffer != null:
		distortion_backbuffer.visible = false
	_clear_sprite(distortion_sprite)
	_clear_sprite(distortion_debug_sprite)
	_clear_particles(aura_particles)
	_clear_particles(wake_particles)
	_clear_particle_array(body_upper_side_particles)
	_clear_particle_array(body_lower_side_particles)
	_clear_burst_emitters()
	for line in wake_halo_lines:
		_clear_line(line)
	for line in wake_core_lines:
		_clear_line(line)
	previous_sword_state = -1
	previous_turn_strength = 0.0
	previous_impact_timer = 0.0
	previous_speed_ratio = 0.0
	burst_trigger_cooldown = 0.0


func _clear_line(line: Line2D) -> void:
	if line == null:
		return
	line.visible = false
	line.points = PackedVector2Array()


func _clear_polygon(polygon: Polygon2D) -> void:
	if polygon == null:
		return
	polygon.visible = false
	polygon.polygon = PackedVector2Array()
	polygon.uv = PackedVector2Array()


func _clear_sprite(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	sprite.visible = false


func _clear_particles(particles: GPUParticles2D) -> void:
	if particles == null:
		return
	particles.visible = false
	particles.amount_ratio = 0.0
	particles.emitting = false


func _clear_burst_emitters() -> void:
	for emitter_variant in burst_emitters:
		var emitter := emitter_variant as GPUParticles2D
		_clear_particles(emitter)
	for emitter_variant in spark_emitters:
		var emitter := emitter_variant as GPUParticles2D
		_clear_particles(emitter)
	for emitter_variant in accel_emitters:
		var emitter := emitter_variant as GPUParticles2D
		_clear_particles(emitter)


func _hdr(color: Color, scale: float, alpha: float) -> Color:
	return Color(color.r * scale, color.g * scale, color.b * scale, alpha)


func _alpha_scaled(color: Color, scale: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * scale)


func _clear_sprite_array(sprites: Array) -> void:
	for sprite_variant in sprites:
		_clear_sprite(sprite_variant as Sprite2D)


func _clear_particle_array(particles_list: Array) -> void:
	for particles_variant in particles_list:
		_clear_particles(particles_variant as GPUParticles2D)


func _should_show_body_support(sword_state: int) -> bool:
	return _get_source_player_mode() == main.CombatMode.RANGED or sword_state != main.SwordState.ORBITING


func _get_sword_visual_forward() -> Vector2:
	var sword_angle: float = _get_source_visual_angle()
	var forward: Vector2 = Vector2.RIGHT.rotated(sword_angle)
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	return forward.normalized()


func _get_sword_motion_forward(sword_velocity: Vector2) -> Vector2:
	var forward: Vector2 = sword_velocity.normalized()
	if forward.is_zero_approx():
		forward = _get_sword_visual_forward()
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	return forward.normalized()


func _get_body_flow_presence(
	vfx,
	sword_state: int,
	speed_ratio: float,
	turn_strength: float,
	glow_strength: float,
	impact_ratio: float
) -> float:
	var flow_strength: float = clampf(
		float(vfx.body_flow_idle_strength)
		+ speed_ratio * float(vfx.body_flow_speed_strength)
		+ turn_strength * float(vfx.body_flow_turn_strength)
		+ glow_strength * 0.22
		+ impact_ratio * 0.18,
		0.0,
		1.0
	)
	if sword_state == main.SwordState.ORBITING:
		flow_strength = max(flow_strength * 0.72, float(vfx.body_flow_idle_strength))
	return clampf(flow_strength * 剑体流光整体强度, 0.0, 1.0)


func _get_body_support_color(sword_state: int) -> Color:
	if sword_state == main.SwordState.RECALLING:
		return main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.3)
	return main.COLORS["ranged_sword"].lerp(ART_BLUE_CORE, 0.42)


func _apply_side_backscatter_mist(
	sprites: Array,
	normal: Vector2,
	side_strength: float,
	root: Vector2,
	tip: Vector2,
	scale: float,
	body_length: float,
	visual_forward: Vector2,
	base_color: Color,
	speed_ratio: float,
	flow_strength: float,
	glow_strength: float
) -> void:
	if sprites.is_empty() or side_strength <= 0.001:
		_clear_sprite_array(sprites)
		return

	var plume_ratios := [0.84, 0.56, 0.28]
	for index in range(min(plume_ratios.size(), sprites.size())):
		var sprite := sprites[index] as Sprite2D
		if sprite == null:
			continue
		var along: float = float(plume_ratios[index])
		var edge_anchor: Vector2 = root.lerp(tip, along)
		var edge_width: float = _sample_body_flow_half_width(along, scale)
		edge_anchor += normal * edge_width * (0.9 + 0.08 * float(index))
		var plume_strength: float = side_strength * (1.0 - 0.14 * float(index))
		var scatter_dir := (
			-visual_forward * (0.94 + 0.16 * speed_ratio) * 剑气后外散距离倍率
			+ normal * (0.74 + 0.26 * flow_strength + 0.12 * glow_strength) * 剑气后外散角度倍率
		).normalized()
		var scatter_distance: float = (
			8.0
			+ 10.0 * plume_strength
			+ 0.035 * body_length
			+ 2.6 * float(index)
		) * scale * 剑气后外散距离倍率
		sprite.visible = true
		sprite.global_position = edge_anchor + scatter_dir * scatter_distance * 0.5
		sprite.global_rotation = scatter_dir.angle()
		sprite.scale = Vector2(
			(0.16 + 0.08 * float(index) + 0.22 * plume_strength + body_length / 520.0) * 剑气薄雾长度倍率,
			(0.048 + 0.015 * float(index) + 0.038 * plume_strength + 0.012 * glow_strength) * 剑气薄雾宽度倍率
		)
		sprite.self_modulate = _hdr(
			base_color.lerp(ART_BLUE_CORE, 0.08 + 0.06 * plume_strength),
			1.0 + 0.18 * plume_strength,
			(0.026 + 0.05 * plume_strength) * 剑气薄雾透明度倍率
		)


func _configure_segment_backscatter_particles(
	particles: GPUParticles2D,
	process_material: ParticleProcessMaterial,
	normal: Vector2,
	along: float,
	segment_bias: float,
	side_strength: float,
	root: Vector2,
	tip: Vector2,
	body_length: float,
	visual_forward: Vector2,
	scale: float,
	base_color: Color,
	speed_ratio: float,
	flow_strength: float,
	glow_strength: float
) -> void:
	if particles == null or process_material == null or side_strength <= 0.001:
		_clear_particles(particles)
		return

	var edge_anchor: Vector2 = root.lerp(tip, along)
	edge_anchor += visual_forward * (剑气沿剑身前后偏移 * scale)
	edge_anchor += normal * _sample_body_flow_half_width(along, scale) * 剑气贴刃距离倍率 * (0.9 + 0.06 * segment_bias)
	var scatter_dir: Vector2 = (
		-visual_forward * (0.92 + 0.18 * speed_ratio) * 剑气后外散距离倍率
		+ normal * (0.84 + 0.24 * flow_strength + 0.1 * glow_strength) * 剑气后外散角度倍率
	).normalized()
	var local_dir: Vector2 = scatter_dir.rotated(-visual_forward.angle())
	particles.visible = true
	particles.global_position = edge_anchor + scatter_dir * (剑气起喷外移 + 0.72 * side_strength + 0.34 * segment_bias) * scale
	particles.global_rotation = visual_forward.angle()
	particles.lifetime = 0.12 + 0.06 * side_strength
	particles.speed_scale = (0.82 + 0.4 * speed_ratio) * 剑气粒子速度倍率
	particles.amount_ratio = clampf((0.18 + 0.46 * side_strength) * 剑气粒子数量倍率, 0.0, 1.0)
	particles.self_modulate = _hdr(
		base_color.lerp(ART_BLUE_CORE, 0.16 + 0.08 * side_strength),
		1.04 + 0.22 * side_strength,
		(0.08 + 0.1 * side_strength) * 剑气薄雾透明度倍率
	)
	process_material.direction = Vector3(local_dir.x, local_dir.y, 0.0)
	process_material.spread = (10.0 + 12.0 * side_strength + 4.0 * segment_bias) * 剑气粒子散射倍率
	process_material.emission_box_extents = Vector3(
		body_length * (0.06 + 0.015 * segment_bias) * 剑气薄雾长度倍率,
		(0.18 + 0.07 * side_strength) * scale * 剑气薄雾宽度倍率,
		0.0
	)
	process_material.initial_velocity_min = (16.0 + 18.0 * side_strength) * 剑气粒子速度倍率
	process_material.initial_velocity_max = (36.0 + 34.0 * side_strength + 10.0 * speed_ratio) * 剑气粒子速度倍率
	process_material.scale_min = (0.08 + 0.04 * side_strength) * 剑气粒子尺寸倍率
	process_material.scale_max = (0.2 + 0.1 * side_strength) * 剑气粒子尺寸倍率
	process_material.damping_min = 18.0 + 4.0 * speed_ratio
	process_material.damping_max = 30.0 + 8.0 * speed_ratio
	particles.emitting = true


func _update_body_base() -> void:
	var sword_state: int = _get_source_sword_state()
	var show_body: bool = _get_source_player_mode() == main.CombatMode.RANGED or sword_state != main.SwordState.ORBITING
	if not show_body:
		_clear_polygon(base_blade_fill)
		_clear_polygon(base_blade_core_fill)
		_clear_polygon(base_handle_fill)
		_clear_polygon(base_guard_fill)
		_clear_polygon(base_pommel_fill)
		_clear_line(base_spine_line)
		_clear_line(base_upper_edge_line)
		_clear_line(base_lower_edge_line)
		_clear_line(base_guard_glint_line)
		return

	var glow_strength: float = _get_local_glow_strength()
	var sword_visual_pos: Vector2 = _get_source_visual_position()
	var sword_pos: Vector2 = main._to_screen(sword_visual_pos)
	var sword_angle: float = _get_source_visual_angle()
	var scale: float = MAIN_SWORD_VISUAL_SCALE
	var forward: Vector2 = Vector2.RIGHT.rotated(sword_angle)
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var side: Vector2 = forward.rotated(PI * 0.5)
	var impact_ratio: float = _get_source_impact_ratio()
	var focus_strength: float = clampf(
		(0.08 if _get_source_player_mode() == main.CombatMode.MELEE else 0.26)
		+ glow_strength * 0.24
		+ impact_ratio * (0.42 if _get_source_player_mode() == main.CombatMode.MELEE else 0.56),
		0.0,
		1.0
	)

	var blade_tip: Vector2 = sword_pos + forward * (24.4 * scale)
	var shoulder_center: Vector2 = sword_pos + forward * (0.25 * scale)
	var blade_root: Vector2 = sword_pos - forward * (8.6 * scale)
	var guard_center: Vector2 = blade_root - forward * (0.08 * scale)
	var handle_front: Vector2 = guard_center - forward * (0.56 * scale)
	var handle_back: Vector2 = sword_pos - forward * (17.2 * scale)
	var shoulder_half_width := 2.78 * scale
	var root_half_width := 0.82 * scale
	var handle_half_width := 0.58 * scale
	var pommel_radius := 0.96 * scale
	var guard_half_span := 3.05 * scale
	var guard_half_thickness := 0.58 * scale

	var base_color: Color = main.COLORS["melee_sword"] if _get_source_player_mode() == main.CombatMode.MELEE else main.COLORS["ranged_sword"]
	var blade_color: Color = base_color.lerp(ART_BLUE_CORE, 0.16 + 0.08 * focus_strength)
	var blade_edge_color: Color = base_color.lerp(ART_BLUE_CORE, 0.24 + 0.08 * focus_strength)
	var blade_core_color: Color = ART_BLUE_CORE.lerp(Color.WHITE, 0.42 + 0.12 * focus_strength)
	var handle_color: Color = Color(0.12, 0.15, 0.2, 1.0).lerp(base_color, 0.16)
	if sword_state == main.SwordState.RECALLING:
		blade_color = main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.22 + 0.08 * focus_strength)
		blade_edge_color = main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.28 + 0.08 * focus_strength)

	var blade_polygon := PackedVector2Array([
		blade_tip,
		shoulder_center + side * shoulder_half_width,
		blade_root + side * root_half_width,
		blade_root - side * root_half_width,
		shoulder_center - side * shoulder_half_width,
	])
	var blade_core := PackedVector2Array([
		sword_pos + forward * 20.8,
		shoulder_center + side * shoulder_half_width * 0.16,
		blade_root + side * root_half_width * 0.18,
		blade_root - side * root_half_width * 0.18,
		shoulder_center - side * shoulder_half_width * 0.16,
	])
	var handle_polygon := PackedVector2Array([
		handle_front + side * handle_half_width,
		handle_front - side * handle_half_width,
		handle_back - side * handle_half_width * 0.88,
		handle_back + side * handle_half_width * 0.88,
	])
	var guard_polygon := PackedVector2Array([
		guard_center + side * guard_half_span,
		guard_center + forward * guard_half_thickness + side * guard_half_span * 0.1,
		guard_center + forward * guard_half_thickness * 0.92,
		guard_center - side * guard_half_span,
		guard_center - forward * guard_half_thickness - side * guard_half_span * 0.1,
		guard_center - forward * guard_half_thickness * 0.92,
	])

	_apply_fill_polygon(base_blade_fill, blade_polygon, blade_color)
	_apply_fill_polygon(base_blade_core_fill, blade_core, Color(blade_core_color.r, blade_core_color.g, blade_core_color.b, 0.72 + 0.12 * focus_strength))
	_apply_fill_polygon(base_handle_fill, handle_polygon, handle_color)
	_apply_fill_polygon(base_guard_fill, guard_polygon, blade_edge_color.lerp(Color.WHITE, 0.12))
	_apply_fill_polygon(base_pommel_fill, _build_circle_polygon(handle_back, pommel_radius, 10), blade_edge_color.lerp(Color.WHITE, 0.28))

	var guard_glint_pos: Vector2 = guard_center + forward * 1.7
	var guard_glint_alpha: float = 0.06 + 0.08 * glow_strength + 0.05 * focus_strength
	_apply_line(
		base_guard_glint_line,
		PackedVector2Array([
			guard_glint_pos - forward * (0.3 * scale),
			guard_glint_pos + forward * (4.4 + 1.6 * glow_strength) * scale,
		]),
		0.68 * scale,
		Color(ART_GOLD.r, ART_GOLD.g, ART_GOLD.b, guard_glint_alpha * 0.78)
	)
	_apply_line(
		base_spine_line,
		PackedVector2Array([
			handle_front - forward * (0.78 * scale),
			blade_tip - forward * (1.6 * scale),
		]),
		0.78 + 0.48 * scale,
		Color(
			blade_core_color.lerp(Color.WHITE, 0.22).r,
			blade_core_color.lerp(Color.WHITE, 0.22).g,
			blade_core_color.lerp(Color.WHITE, 0.22).b,
			0.72 + 0.14 * focus_strength
		)
	)
	_apply_line(
		base_upper_edge_line,
		PackedVector2Array([
			shoulder_center + side * shoulder_half_width * 0.84,
			blade_tip,
		]),
		0.74 + 0.18 * scale,
		Color(blade_edge_color.r, blade_edge_color.g, blade_edge_color.b, 0.18 + 0.12 * glow_strength + 0.08 * focus_strength)
	)
	_apply_line(
		base_lower_edge_line,
		PackedVector2Array([
			shoulder_center - side * shoulder_half_width * 0.84,
			blade_tip,
		]),
		0.7 + 0.16 * scale,
		Color(blade_edge_color.r, blade_edge_color.g, blade_edge_color.b, 0.14 + 0.1 * glow_strength + 0.06 * focus_strength)
	)


func _update_body_flow() -> void:
	var sword_state: int = _get_source_sword_state()
	var show_body: bool = _should_show_body_support(sword_state)
	if not show_body or not 剑体流光启用:
		_clear_line(body_flow_primary)
		_clear_line(body_flow_secondary)
		_clear_line(body_flow_tip)
		return

	var vfx = main.get_sword_vfx_profile()
	var sword_visual_pos: Vector2 = _get_source_visual_position()
	var sword_pos: Vector2 = main._to_screen(sword_visual_pos)
	var scale: float = MAIN_SWORD_VISUAL_SCALE
	var sword_velocity: Vector2 = _get_source_velocity()
	var speed_reference: float = main.SWORD_RECALL_SPEED if sword_state == main.SwordState.RECALLING else main.SWORD_POINT_STRIKE_SPEED
	var speed_ratio: float = clampf(sword_velocity.length() / maxf(speed_reference, 0.001), 0.0, 1.0)
	var turn_strength := 0.0
	var trail_points: Array = _get_source_trail_points()
	if not trail_points.is_empty():
		turn_strength = clampf(float(trail_points[trail_points.size() - 1].get("turn_strength", 0.0)), 0.0, 1.0)
	var impact_ratio: float = _get_source_impact_ratio()
	var glow_strength: float = _get_local_glow_strength()
	var forward: Vector2 = _get_sword_visual_forward()
	var flow_strength: float = _get_body_flow_presence(vfx, sword_state, speed_ratio, turn_strength, glow_strength, impact_ratio)

	var sway_scale: float = float(vfx.body_flow_shell_width_scale) * (1.0 + 0.06 * speed_ratio + 0.14 * turn_strength) * 剑体流带摆幅倍率
	var ribbon_width_scale: float = float(vfx.body_flow_core_width_scale) * (1.0 + 0.06 * speed_ratio + 0.08 * impact_ratio) * 剑体流带宽度倍率
	if sword_state == main.SwordState.POINT_STRIKE:
		sway_scale *= 1.12
		ribbon_width_scale *= 1.08
		flow_strength = clampf(flow_strength + 0.14, 0.0, 1.0)
	elif sword_state == main.SwordState.SLICING:
		sway_scale *= 1.08
		ribbon_width_scale *= 1.04
	elif sword_state == main.SwordState.RECALLING:
		sway_scale *= 0.94
		ribbon_width_scale *= 0.96

	var pulse: float = 0.78 + 0.22 * sin(main.elapsed_time * (10.0 + 3.0 * speed_ratio))
	var primary_color: Color = _hdr(main.COLORS["ranged_sword"].lerp(ART_BLUE, 0.34), 1.08 + 0.3 * pulse, 0.28 + 0.24 * flow_strength)
	var secondary_color: Color = _hdr(ART_BLUE.lerp(ART_BLUE_CORE, 0.32), 1.22 + 0.38 * pulse, 0.2 + 0.18 * flow_strength)
	var tip_color: Color = _hdr(ART_GOLD.lerp(ART_BLUE_CORE, 0.18), 1.14 + 0.26 * pulse, 0.14 + 0.16 * flow_strength)
	if sword_state == main.SwordState.SLICING:
		primary_color = _hdr(main.COLORS["ranged_sword"].lerp(ART_GOLD, 0.16), 1.02 + 0.24 * pulse, 0.28 + 0.26 * flow_strength)
		secondary_color = _hdr(ART_BLUE.lerp(ART_GOLD, 0.12).lerp(ART_BLUE_CORE, 0.26), 1.16 + 0.3 * pulse, 0.22 + 0.2 * flow_strength)
		tip_color = _hdr(ART_GOLD.lerp(Color.WHITE, 0.08), 1.22 + 0.22 * pulse, 0.18 + 0.2 * flow_strength)
	elif sword_state == main.SwordState.RECALLING:
		primary_color = _hdr(main.COLORS["array_sword_return"].lerp(main.COLORS["ranged_sword"], 0.58), 1.02 + 0.24 * pulse, 0.24 + 0.22 * flow_strength)
		secondary_color = _hdr(main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.34), 1.12 + 0.26 * pulse, 0.18 + 0.16 * flow_strength)
		tip_color = _hdr(ART_GOLD.lerp(main.COLORS["array_sword_return"], 0.24), 1.1 + 0.2 * pulse, 0.12 + 0.14 * flow_strength)
	primary_color = _alpha_scaled(primary_color, 主流透明度倍率)
	secondary_color = _alpha_scaled(secondary_color, 副流透明度倍率)
	tip_color = _alpha_scaled(tip_color, 剑尖流光透明度倍率)

	var scroll_speed: float = float(vfx.body_flow_scroll_speed) * (1.0 + 0.35 * speed_ratio) * 剑体流动速度倍率
	if sword_state == main.SwordState.SLICING:
		scroll_speed *= 1.14
	elif sword_state == main.SwordState.RECALLING:
		scroll_speed *= 0.88
	var band_density: float = float(vfx.body_flow_band_density) * (1.0 + 0.08 * turn_strength) * 剑体流纹密度倍率
	var tip_bias: float = float(vfx.body_flow_tip_bias)
	if sword_state == main.SwordState.POINT_STRIKE:
		tip_bias += 0.1
	elif sword_state == main.SwordState.RECALLING:
		tip_bias -= 0.08

	_apply_line(
		body_flow_primary,
		_build_body_flow_ribbon_points(
			sword_pos,
			forward,
			scale,
			0.18,
			0.8,
			0.96,
			1.28,
			0.04,
			sway_scale,
			flow_strength,
			scroll_speed,
			band_density,
			tip_bias,
			turn_strength,
			speed_ratio,
			剑体翻绕强度倍率
		),
		(1.1 + 0.96 * ribbon_width_scale + 0.48 * flow_strength) * scale,
		primary_color
	)
	_apply_line(
		body_flow_secondary,
		_build_body_flow_ribbon_points(
			sword_pos,
			forward,
			scale,
			0.28,
			0.94,
			-0.88,
			1.04,
			0.26,
			sway_scale,
			flow_strength,
			scroll_speed * 1.08,
			band_density * 1.12,
			tip_bias,
			turn_strength,
			speed_ratio,
			剑体翻绕强度倍率
		),
		(0.72 + 0.72 * ribbon_width_scale + 0.34 * flow_strength) * scale,
		secondary_color
	)
	_apply_line(
		body_flow_tip,
		_build_body_flow_ribbon_points(
			sword_pos,
			forward,
			scale,
			0.62,
			1.0,
			0.78,
			1.22,
			0.62,
			sway_scale,
			clampf(flow_strength + 0.08, 0.0, 1.0),
			scroll_speed * 0.92,
			band_density * 0.72,
			tip_bias + 0.08,
			turn_strength,
			speed_ratio,
			剑体翻绕强度倍率
		),
		(0.46 + 0.44 * ribbon_width_scale + 0.24 * flow_strength) * scale,
		tip_color
	)


func _update_body_glow() -> void:
	var sword_state: int = _get_source_sword_state()
	var show_body: bool = _should_show_body_support(sword_state)
	if not show_body or not 剑体流光启用 or 贴身底辉强度倍率 <= 0.001:
		_clear_line(body_halo)
		_clear_line(body_ribbon)
		_clear_line(body_core)
		_clear_line(guard_ring)
		return

	var glow_strength: float = _get_local_glow_strength()
	var sword_visual_pos: Vector2 = _get_source_visual_position()
	var sword_pos: Vector2 = main._to_screen(sword_visual_pos)
	var sword_angle: float = _get_source_visual_angle()
	var scale: float = MAIN_SWORD_VISUAL_SCALE
	var forward: Vector2 = Vector2.RIGHT.rotated(sword_angle)
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()

	var body_start: Vector2 = sword_pos - forward * (8.2 * scale)
	var body_shoulder: Vector2 = sword_pos + forward * (2.1 * scale)
	var body_mid: Vector2 = sword_pos + forward * (12.2 * scale)
	var body_end: Vector2 = sword_pos + forward * (24.2 * scale)
	var body_points := PackedVector2Array([body_start, body_shoulder, body_mid, body_end])
	var pulse: float = 0.86 + 0.14 * sin(main.elapsed_time * 11.0)
	var body_energy: float = (0.16 + glow_strength * 0.28) * 贴身底辉强度倍率
	var halo_color: Color = _hdr(main.COLORS["ranged_sword"].lerp(ART_BLUE, 0.22), 1.18 + 0.22 * pulse, 0.016 + 0.024 * body_energy)
	var ribbon_color: Color = _hdr(ART_BLUE.lerp(ART_BLUE_CORE, 0.3), 1.3 + 0.24 * pulse, 0.026 + 0.03 * body_energy)
	var core_color: Color = _hdr(ART_BLUE_CORE.lerp(Color.WHITE, 0.2), 1.42 + 0.3 * pulse, 0.04 + 0.036 * body_energy)
	if sword_state == main.SwordState.RECALLING:
		halo_color = _hdr(main.COLORS["array_sword_return"].lerp(main.COLORS["ranged_sword"], 0.6), 1.14 + 0.2 * pulse, 0.014 + 0.02 * body_energy)
		ribbon_color = _hdr(main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.34), 1.24 + 0.22 * pulse, 0.024 + 0.024 * body_energy)
		core_color = _hdr(ART_BLUE_CORE.lerp(Color.WHITE, 0.16), 1.34 + 0.24 * pulse, 0.034 + 0.028 * body_energy)

	_apply_line(body_halo, body_points, (BODY_HALO_WIDTH_BASE + BODY_HALO_WIDTH_SCALE * glow_strength) * scale * 贴身底辉宽度倍率, halo_color)
	_apply_line(body_ribbon, body_points, (BODY_RIBBON_WIDTH_BASE + BODY_RIBBON_WIDTH_SCALE * glow_strength) * scale * 贴身底辉宽度倍率, ribbon_color)
	_apply_line(body_core, body_points, (BODY_CORE_WIDTH_BASE + BODY_CORE_WIDTH_SCALE * glow_strength) * scale * 贴身底辉宽度倍率, core_color)

	var guard_center: Vector2 = sword_pos - forward * (7.6 * scale)
	_apply_arc(
		guard_ring,
		guard_center,
		forward.angle() - 0.64,
		forward.angle() + 0.28,
		(1.8 + 1.2 * glow_strength) * scale * 贴身底辉宽度倍率,
		(0.42 + 0.42 * glow_strength) * scale * 贴身底辉宽度倍率,
		_hdr(ART_GOLD.lerp(ART_BLUE_CORE, 0.18), 1.12 + 0.18 * pulse, 0.04 + 0.04 * body_energy)
	)


func _update_front_beam() -> void:
	var sword_state: int = _get_source_sword_state()
	if sword_state != main.SwordState.POINT_STRIKE and sword_state != main.SwordState.RECALLING:
		_clear_line(front_halo)
		_clear_line(front_ribbon)
		_clear_line(front_core)
		return

	var vfx = main.get_sword_vfx_profile()
	var sword_velocity: Vector2 = _get_source_velocity()
	var speed: float = sword_velocity.length()
	var speed_reference: float = main.SWORD_RECALL_SPEED if sword_state == main.SwordState.RECALLING else main.SWORD_POINT_STRIKE_SPEED
	var speed_ratio: float = clampf(
		(speed / maxf(speed_reference, 0.001) - float(vfx.front_speed_start) * 0.6) / maxf(float(vfx.front_speed_span) * 0.9, 0.001),
		0.0,
		1.0
	)
	if speed_ratio <= 0.0:
		_clear_line(front_halo)
		_clear_line(front_ribbon)
		_clear_line(front_core)
		return

	var sword_visual_pos: Vector2 = _get_source_visual_position()
	var sword_pos: Vector2 = main._to_screen(sword_visual_pos)
	var forward: Vector2 = sword_velocity.normalized()
	if forward.is_zero_approx():
		var sword_angle: float = _get_source_visual_angle()
		forward = Vector2.RIGHT.rotated(sword_angle)
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()

	var pulse: float = 0.5 + 0.5 * sin(main.elapsed_time * (15.0 if sword_state == main.SwordState.POINT_STRIKE else 12.0))
	var front_origin: Vector2 = sword_pos + forward * (8.0 + 5.0 * speed_ratio)
	var front_length: float = lerpf(float(vfx.front_length_min), float(vfx.front_length_max), speed_ratio) * (float(vfx.front_recall_length_scale) if sword_state == main.SwordState.RECALLING else 1.0)
	var front_width: float = lerpf(float(vfx.front_width_min), float(vfx.front_width_max), speed_ratio) * (float(vfx.front_recall_width_scale) if sword_state == main.SwordState.RECALLING else 1.0)
	var pulse_strength: float = float(vfx.front_point_pulse) if sword_state == main.SwordState.POINT_STRIKE else float(vfx.front_recall_pulse)
	var beam_start: Vector2 = sword_pos - forward * (2.0 + 2.2 * speed_ratio)
	var beam_end: Vector2 = front_origin + forward * (front_length * 1.56 + pulse * pulse_strength * 0.9)
	var beam_points := PackedVector2Array([beam_start, beam_end])
	var halo_color: Color = _hdr(main.COLORS["ranged_sword"].lerp(ART_BLUE, 0.3), 2.1 + 1.3 * pulse, 0.24 + 0.3 * speed_ratio)
	var ribbon_color: Color = _hdr(ART_BLUE.lerp(ART_BLUE_CORE, 0.28), 2.6 + 1.4 * pulse, 0.42 + 0.44 * speed_ratio)
	var core_color: Color = _hdr(ART_BLUE_CORE.lerp(Color.WHITE, 0.36), 3.1 + 1.6 * pulse, 0.74 + 0.22 * speed_ratio)
	if sword_state == main.SwordState.RECALLING:
		halo_color = _hdr(main.COLORS["array_sword_return"].lerp(main.COLORS["ranged_sword"], 0.7), 1.9 + 0.8 * pulse, 0.22 + 0.22 * speed_ratio)
		ribbon_color = _hdr(main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.32), 2.2 + 0.9 * pulse, 0.36 + 0.3 * speed_ratio)

	_apply_line(front_halo, beam_points, maxf(front_width * 4.6, 12.0), halo_color)
	_apply_line(front_ribbon, beam_points, maxf(front_width * 2.3, 6.0), ribbon_color)
	_apply_line(front_core, beam_points, maxf(front_width * 0.78, 2.2), core_color)


func _update_trail() -> void:
	var trail_points: Array = _get_source_trail_points()
	if trail_points.is_empty():
		_clear_line(trail_halo)
		_clear_line(trail_ribbon)
		_clear_line(trail_core)
		_clear_line(trail_warm)
		return

	var raw_points: Array = []
	var total_half_width := 0.0
	var total_alpha := 0.0
	var sample_count := 0
	for entry in trail_points:
		raw_points.append(main._to_screen(entry["pos"]))
		total_half_width += float(entry.get("half_width", main.SWORD_TRAIL_BASE_HALF_WIDTH))
		total_alpha += float(entry.get("alpha_scale", 1.0))
		sample_count += 1

	var sword_visual_pos: Vector2 = _get_source_visual_position()
	var source_sword: Dictionary = _get_source_sword()
	var latest: Dictionary = trail_points[trail_points.size() - 1]
	var style: String = str(latest.get("style", "point"))
	var speed_ratio: float = clampf(float(latest.get("speed_ratio", 0.0)), 0.0, 1.0)
	var turn_strength: float = clampf(float(latest.get("turn_strength", 0.0)), 0.0, 1.0)
	var trail_forward: Vector2 = Vector2(latest.get("forward", Vector2.ZERO))
	if trail_forward.is_zero_approx():
		trail_forward = Vector2(source_sword.get("vel", Vector2.ZERO)).normalized()
	if trail_forward.is_zero_approx():
		trail_forward = Vector2.RIGHT.rotated(float(source_sword.get("angle", 0.0)))
	if trail_forward.is_zero_approx():
		trail_forward = Vector2.RIGHT
	trail_forward = trail_forward.normalized()
	raw_points.append(_build_trail_head_anchor(main._to_screen(sword_visual_pos), trail_forward, style, speed_ratio, turn_strength))
	var smooth_points: PackedVector2Array = _build_smooth_points(raw_points)
	if smooth_points.size() < 2:
		_clear_line(trail_halo)
		_clear_line(trail_ribbon)
		_clear_line(trail_core)
		_clear_line(trail_warm)
		return

	var vfx = main.get_sword_vfx_profile()
	var avg_half_width: float = total_half_width / maxf(float(sample_count), 1.0)
	var alpha_scale: float = total_alpha / maxf(float(sample_count), 1.0)
	var pulse: float = 0.88 + 0.12 * sin(main.elapsed_time * 10.0)
	var full_width: float = maxf(avg_half_width * float(vfx.node_trail_width_base_scale), 9.0)
	var halo_color: Color = _hdr(main.COLORS["ranged_sword"].lerp(ART_BLUE, 0.24), 1.8 + 0.7 * pulse, (0.16 + 0.12 * speed_ratio) * alpha_scale)
	var ribbon_color: Color = _hdr(ART_BLUE.lerp(ART_BLUE_CORE, 0.24), 2.2 + 0.9 * pulse, (0.3 + 0.2 * speed_ratio) * alpha_scale)
	var core_color: Color = _hdr(ART_BLUE_CORE.lerp(Color.WHITE, 0.28), 2.8 + 1.0 * pulse, minf((0.58 + 0.16 * speed_ratio) * alpha_scale, 1.0))
	var warm_color: Color = _hdr(ART_GOLD, 1.4 + 0.3 * pulse, (0.08 + 0.08 * speed_ratio) * alpha_scale)
	match style:
		"slice":
			ribbon_color = _hdr(main.COLORS["ranged_sword"].lerp(ART_BLUE_CORE, 0.18), 2.3 + 0.9 * pulse, (0.36 + 0.2 * speed_ratio) * alpha_scale)
			warm_color = _hdr(ART_GOLD.lerp(main.COLORS["ranged_sword"], 0.34), 1.6 + 0.25 * pulse, (0.12 + 0.12 * speed_ratio) * alpha_scale)
		"recall":
			halo_color = _hdr(main.COLORS["array_sword_return"].lerp(main.COLORS["ranged_sword"], 0.76), 1.6 + 0.4 * pulse, (0.14 + 0.12 * speed_ratio) * alpha_scale)
			ribbon_color = _hdr(main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.28), 1.9 + 0.55 * pulse, (0.28 + 0.18 * speed_ratio) * alpha_scale)
			warm_color = _hdr(ART_GOLD, 1.25 + 0.22 * pulse, (0.1 + 0.07 * speed_ratio) * alpha_scale)

	_apply_line(trail_halo, smooth_points, full_width * (float(vfx.node_trail_halo_width_scale) + 0.16 * turn_strength), halo_color)
	_apply_line(trail_ribbon, smooth_points, full_width * (float(vfx.node_trail_ribbon_width_scale) + 0.05 * turn_strength), ribbon_color)
	_apply_line(trail_core, smooth_points, full_width * float(vfx.node_trail_core_width_scale), core_color)
	_apply_line(trail_warm, smooth_points, full_width * float(vfx.node_trail_warm_width_scale), warm_color)


func _update_wakes() -> void:
	var air_wakes: Array = _get_source_air_wakes()
	var line_index := 0
	for wake_variant in air_wakes:
		if line_index >= wake_halo_lines.size() or line_index >= wake_core_lines.size():
			break
		if not (wake_variant is Dictionary):
			continue
		var wake: Dictionary = wake_variant
		var life_ratio: float = clampf(float(wake.get("life", 0.0)) / maxf(float(wake.get("max_life", 1.0)), 0.001), 0.0, 1.0)
		if life_ratio <= 0.0:
			continue
		var center: Vector2 = main._to_screen(Vector2(wake.get("pos", Vector2.ZERO)))
		var forward: Vector2 = Vector2(wake.get("forward", Vector2.RIGHT))
		if forward.is_zero_approx():
			forward = Vector2.RIGHT
		forward = forward.normalized()
		var outward: Vector2 = Vector2(wake.get("outward", forward.rotated(PI * 0.5)))
		if outward.is_zero_approx():
			outward = forward.rotated(PI * 0.5)
		outward = outward.normalized()
		var turn_strength: float = clampf(float(wake.get("turn_strength", 0.0)), 0.0, 1.0)
		var speed_ratio: float = clampf(float(wake.get("speed_ratio", 0.0)), 0.0, 1.0)
		var style: String = str(wake.get("style", "point"))
		var length: float = float(wake.get("length", main.SWORD_AIR_WAKE_BASE_LENGTH)) * (0.46 + 0.54 * life_ratio)
		var width: float = float(wake.get("width", main.SWORD_AIR_WAKE_BASE_WIDTH)) * (0.5 + 0.5 * life_ratio)
		var haze_color: Color = main.COLORS["ranged_sword"].lerp(UNSHEATH_FLASH_EDGE_COLOR, 0.22)
		var streak_color: Color = ART_BLUE_CORE.lerp(Color.WHITE, 0.22)
		if style == "recall":
			haze_color = main.COLORS["array_sword_return"].lerp(main.COLORS["ranged_sword"], 0.5)
			streak_color = main.COLORS["array_sword_return"].lerp(UNSHEATH_FLASH_CORE_COLOR, 0.44)
		var wake_points: PackedVector2Array = _build_wake_points(
			center,
			forward,
			outward,
			length,
			width,
			turn_strength,
			speed_ratio
		)
		_apply_line(
			wake_halo_lines[line_index] as Line2D,
			wake_points,
			maxf((1.7 + 0.9 * speed_ratio) * (0.7 + 0.28 * turn_strength), 0.45),
			Color(haze_color.r, haze_color.g, haze_color.b, 0.05 + 0.08 * life_ratio)
		)
		_apply_line(
			wake_core_lines[line_index] as Line2D,
			wake_points,
			maxf((0.7 + 0.28 * turn_strength) * (0.72 + 0.2 * speed_ratio), 0.4),
			Color(streak_color.r, streak_color.g, streak_color.b, 0.08 + 0.12 * life_ratio)
		)
		line_index += 1
	while line_index < wake_halo_lines.size() and line_index < wake_core_lines.size():
		_clear_line(wake_halo_lines[line_index] as Line2D)
		_clear_line(wake_core_lines[line_index] as Line2D)
		line_index += 1


func _update_particles() -> void:
	_clear_particles(aura_particles)
	_clear_particles(wake_particles)
	_clear_particle_array(body_upper_side_particles)
	_clear_particle_array(body_lower_side_particles)
	var sword_state: int = _get_source_sword_state()
	var show_body: bool = _should_show_body_support(sword_state)
	if not show_body or not 剑气补层启用 or 剑气补层整体强度 <= 0.001:
		return

	var vfx = main.get_sword_vfx_profile()
	var sword_visual_pos: Vector2 = _get_source_visual_position()
	var sword_pos: Vector2 = main._to_screen(sword_visual_pos)
	var sword_velocity: Vector2 = _get_source_velocity()
	var speed_reference: float = main.SWORD_RECALL_SPEED if sword_state == main.SwordState.RECALLING else main.SWORD_POINT_STRIKE_SPEED
	var speed_ratio: float = clampf(sword_velocity.length() / maxf(speed_reference, 0.001), 0.0, 1.0)
	var turn_strength: float = 0.0
	var trail_points: Array = _get_source_trail_points()
	if not trail_points.is_empty():
		turn_strength = clampf(float(trail_points[trail_points.size() - 1].get("turn_strength", 0.0)), 0.0, 1.0)
	var impact_ratio: float = _get_source_impact_ratio()
	var glow_strength: float = _get_local_glow_strength()
	var flow_strength: float = _get_body_flow_presence(vfx, sword_state, speed_ratio, turn_strength, glow_strength, impact_ratio)
	var scale: float = MAIN_SWORD_VISUAL_SCALE
	var visual_forward: Vector2 = _get_sword_visual_forward()
	var side: Vector2 = visual_forward.rotated(PI * 0.5)
	var root: Vector2 = sword_pos - visual_forward * ((7.2 + 剑体流光向后延伸) * scale)
	var tip: Vector2 = sword_pos + visual_forward * ((24.4 + 剑体流光向前延伸) * scale)
	var body_length: float = maxf(root.distance_to(tip), 1.0)
	var support_strength: float = clampf((0.22 + flow_strength * 0.78 + glow_strength * 0.12) * 剑气补层整体强度, 0.0, 1.4)
	if support_strength <= 0.001:
		return

	var support_color: Color = _get_body_support_color(sword_state)
	var plume_ratios := [0.82, 0.56, 0.3]
	for index in range(min(plume_ratios.size(), body_upper_side_particles.size(), body_upper_side_particle_materials.size())):
		_configure_segment_backscatter_particles(
			body_upper_side_particles[index] as GPUParticles2D,
			body_upper_side_particle_materials[index] as ParticleProcessMaterial,
			-side,
			float(plume_ratios[index]),
			float(index),
			clampf(support_strength * 剑气上刃外散强度, 0.0, 2.0) * (1.0 - 0.08 * float(index)),
			root,
			tip,
			body_length,
			visual_forward,
			scale,
			support_color,
			speed_ratio,
			flow_strength,
			glow_strength
		)
	for index in range(min(plume_ratios.size(), body_lower_side_particles.size(), body_lower_side_particle_materials.size())):
		_configure_segment_backscatter_particles(
			body_lower_side_particles[index] as GPUParticles2D,
			body_lower_side_particle_materials[index] as ParticleProcessMaterial,
			side,
			float(plume_ratios[index]),
			float(index),
			clampf(support_strength * 剑气下刃外散强度, 0.0, 2.0) * (1.0 - 0.08 * float(index)),
			root,
			tip,
			body_length,
			visual_forward,
			scale,
			support_color,
			speed_ratio,
			flow_strength,
			glow_strength
		)


func _update_haze() -> void:
	var sword_state: int = _get_source_sword_state()
	var is_flying: bool = sword_state != main.SwordState.ORBITING
	var show_body: bool = _should_show_body_support(sword_state)
	var sword_visual_pos: Vector2 = _get_source_visual_position()
	var sword_pos: Vector2 = main._to_screen(sword_visual_pos)
	var sword_velocity: Vector2 = _get_source_velocity()
	var speed_reference: float = main.SWORD_RECALL_SPEED if sword_state == main.SwordState.RECALLING else main.SWORD_POINT_STRIKE_SPEED
	var speed_ratio: float = clampf(sword_velocity.length() / maxf(speed_reference, 0.001), 0.0, 1.0)
	var trail_turn_strength: float = 0.0
	var trail_points: Array = _get_source_trail_points()
	if not trail_points.is_empty():
		trail_turn_strength = clampf(float(trail_points[trail_points.size() - 1].get("turn_strength", 0.0)), 0.0, 1.0)
	var motion_forward: Vector2 = _get_sword_motion_forward(sword_velocity)

	body_haze.visible = false
	_clear_sprite_array(body_upper_side_haze_sprites)
	_clear_sprite_array(body_lower_side_haze_sprites)
	trail_haze.visible = false
	front_haze.visible = false

	var turn_slice_active: bool = is_flying and (speed_ratio > 0.18 or trail_turn_strength > 0.18)
	turn_slice.visible = turn_slice_active
	if turn_slice_active:
		turn_slice.global_position = sword_pos - motion_forward * (18.0 + 10.0 * speed_ratio)
		turn_slice.global_rotation = motion_forward.angle() + PI
		turn_slice.scale = Vector2(0.42 + 0.68 * speed_ratio + 0.46 * trail_turn_strength, 0.1 + 0.05 * speed_ratio + 0.03 * trail_turn_strength)
		turn_slice.self_modulate = _hdr(ART_BLUE.lerp(ART_BLUE_CORE, 0.2), 1.02 + 0.24 * speed_ratio, 0.08 + 0.08 * speed_ratio + 0.06 * trail_turn_strength)
		if sword_state == main.SwordState.RECALLING:
			turn_slice.self_modulate = _hdr(main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.18), 0.96 + 0.18 * speed_ratio, 0.06 + 0.06 * speed_ratio)
	else:
		turn_slice.visible = false


func _update_distortion(_delta: float) -> void:
	var source_sword: Dictionary = _get_source_sword()
	var sword_state: int = _get_source_sword_state()
	var is_flying: bool = sword_state != main.SwordState.ORBITING
	var sword_visual_pos: Vector2 = _get_source_visual_position()
	var sword_pos: Vector2 = main._to_screen(sword_visual_pos)
	var sword_velocity: Vector2 = _get_source_velocity()
	var speed_reference: float = main.SWORD_RECALL_SPEED if sword_state == main.SwordState.RECALLING else main.SWORD_POINT_STRIKE_SPEED
	var speed_ratio: float = clampf(sword_velocity.length() / maxf(speed_reference, 0.001), 0.0, 1.0)
	var trail_turn_strength: float = 0.0
	var trail_points: Array = _get_source_trail_points()
	if not trail_points.is_empty():
		trail_turn_strength = clampf(float(trail_points[trail_points.size() - 1].get("turn_strength", 0.0)), 0.0, 1.0)
	var glow_strength: float = _get_local_glow_strength()
	var impact_ratio: float = _get_source_impact_ratio()
	var distortion_active: bool = 扭曲启用 and is_flying and (
		speed_ratio > 扭曲速度阈值
		or trail_turn_strength > 扭曲转向阈值
		or impact_ratio > 0.0
	)
	distortion_backbuffer.visible = distortion_active
	distortion_backbuffer.z_as_relative = false
	distortion_backbuffer.z_index = 扭曲渲染层级
	distortion_sprite.z_as_relative = false
	distortion_sprite.z_index = 扭曲渲染层级
	distortion_debug_sprite.z_as_relative = false
	distortion_debug_sprite.z_index = 扭曲渲染层级 + 1
	distortion_sprite.visible = distortion_active
	distortion_debug_sprite.visible = distortion_active and 扭曲调试可见
	if not distortion_active:
		return
	var forward: Vector2 = sword_velocity.normalized()
	if forward.is_zero_approx():
		forward = Vector2.RIGHT.rotated(float(source_sword.get("angle", 0.0)))
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	forward = forward.normalized()
	distortion_sprite.global_position = sword_pos + forward * (扭曲前移基础 + 扭曲前移速度系数 * speed_ratio)
	distortion_sprite.global_rotation = forward.angle()
	distortion_sprite.scale = Vector2(
		扭曲横向尺寸基础 + 扭曲横向尺寸速度系数 * speed_ratio + 扭曲横向尺寸转向系数 * trail_turn_strength,
		扭曲纵向尺寸基础 + 扭曲纵向尺寸辉光系数 * glow_strength + 扭曲纵向尺寸转向系数 * trail_turn_strength
	)
	distortion_debug_sprite.global_position = distortion_sprite.global_position
	distortion_debug_sprite.global_rotation = distortion_sprite.global_rotation
	distortion_debug_sprite.scale = distortion_sprite.scale
	distortion_debug_sprite.self_modulate = Color(0.24, 0.86, 1.0, 扭曲调试透明度)
	distortion_material.set_shader_parameter(
		"distortion_strength",
		扭曲强度基础 + speed_ratio * 扭曲强度速度系数 + trail_turn_strength * 扭曲强度转向系数
	)
	distortion_material.set_shader_parameter(
		"opacity",
		扭曲透明度基础 + speed_ratio * 扭曲透明度速度系数 + trail_turn_strength * 扭曲透明度转向系数
	)
	distortion_material.set_shader_parameter("flow_speed", 扭曲流动基础 + speed_ratio * 扭曲流动速度系数)


func _update_burst_events(_delta: float) -> void:
	_clear_burst_emitters()
	burst_trigger_cooldown = 0.0
	previous_sword_state = _get_source_sword_state()
	previous_impact_timer = float(_get_source_sword().get("impact_feedback_timer", 0.0))
	previous_speed_ratio = 0.0


func _emit_burst_pair(position: Vector2, forward: Vector2, intensity: float, style: String) -> void:
	var burst := _take_burst_emitter(burst_emitters, true)
	var spark := _take_burst_emitter(spark_emitters, false)
	var cool_color: Color = _hdr(ART_BLUE.lerp(ART_BLUE_CORE, 0.24), 1.34 + 0.7 * intensity, 0.76)
	var warm_color: Color = _hdr(ART_GOLD.lerp(ART_BLUE_CORE, 0.16), 1.22 + 0.42 * intensity, 0.84)
	if style == "recall":
		cool_color = _hdr(main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.18), 1.18 + 0.44 * intensity, 0.72)
		warm_color = _hdr(ART_GOLD, 1.16 + 0.24 * intensity, 0.78)
	elif style == "slice":
		warm_color = _hdr(ART_GOLD.lerp(main.COLORS["ranged_sword"], 0.3), 1.12 + 0.28 * intensity, 0.78)
	_prime_burst_emitter(burst, position, forward, intensity, cool_color, 0.78 + 0.46 * intensity)
	_prime_burst_emitter(spark, position + forward * (8.0 + 6.0 * intensity), forward, intensity, warm_color, 0.9 + 0.54 * intensity)


func _take_burst_emitter(pool: Array, is_burst: bool) -> GPUParticles2D:
	if pool.is_empty():
		return null
	if is_burst:
		var emitter := pool[burst_emitter_cursor] as GPUParticles2D
		burst_emitter_cursor = (burst_emitter_cursor + 1) % pool.size()
		return emitter
	var spark := pool[spark_emitter_cursor] as GPUParticles2D
	spark_emitter_cursor = (spark_emitter_cursor + 1) % pool.size()
	return spark


func _take_accel_emitter() -> GPUParticles2D:
	if accel_emitters.is_empty():
		return null
	var emitter := accel_emitters[accel_emitter_cursor] as GPUParticles2D
	accel_emitter_cursor = (accel_emitter_cursor + 1) % accel_emitters.size()
	return emitter


func _prime_burst_emitter(emitter: GPUParticles2D, position: Vector2, forward: Vector2, intensity: float, color: Color, scale_value: float) -> void:
	if emitter == null:
		return
	emitter.visible = true
	emitter.global_position = position
	emitter.global_rotation = forward.angle()
	emitter.scale = Vector2.ONE * scale_value
	emitter.speed_scale = 0.84 + intensity * 0.42
	emitter.amount_ratio = clampf(0.34 + intensity * 0.66, 0.0, 1.0)
	emitter.self_modulate = color
	emitter.restart()
	emitter.emitting = true


func _emit_accel_burst(position: Vector2, forward: Vector2, intensity: float, style: String) -> void:
	var emitter := _take_accel_emitter()
	if emitter == null:
		return
	var color: Color = _hdr(ART_BLUE_CORE.lerp(ART_BLUE, 0.16), 1.12 + 0.52 * intensity, 0.72)
	if style == "recall":
		color = _hdr(main.COLORS["array_sword_return"].lerp(ART_BLUE_CORE, 0.16), 1.0 + 0.34 * intensity, 0.68)
	_prime_burst_emitter(emitter, position, forward, intensity, color, 0.82 + 0.36 * intensity)


func _build_wake_points(center: Vector2, forward: Vector2, outward: Vector2, length: float, width: float, turn_strength: float, speed_ratio: float) -> PackedVector2Array:
	var start: Vector2 = center - forward * length * 0.62
	var end: Vector2 = center + forward * length * (0.32 + 0.08 * turn_strength) + outward * width * (0.42 + 0.14 * speed_ratio)
	var control: Vector2 = center + outward * width * (1.12 + 0.56 * turn_strength) - forward * length * 0.08
	var points := PackedVector2Array()
	for step in range(WAKE_SEGMENTS + 1):
		var t: float = float(step) / float(WAKE_SEGMENTS)
		points.append(_quadratic_point(start, control, end, t))
	return points


func _quadratic_point(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	var omt: float = 1.0 - t
	return omt * omt * start + 2.0 * omt * t * control + t * t * end


func _build_trail_head_anchor(sword_pos: Vector2, trail_forward: Vector2, style: String, speed_ratio: float, turn_strength: float) -> Vector2:
	var vfx = main.get_sword_vfx_profile()
	var clearance: float = float(vfx.node_trail_head_clearance_point) + 6.0 * speed_ratio
	match style:
		"slice":
			clearance = float(vfx.node_trail_head_clearance_slice) + 4.0 * turn_strength + 4.0 * speed_ratio
		"recall":
			clearance = float(vfx.node_trail_head_clearance_recall) + 4.0 * speed_ratio
	return sword_pos - trail_forward * clearance


func _build_smooth_points(raw_points: Array) -> PackedVector2Array:
	var packed := PackedVector2Array()
	if raw_points.size() == 0:
		return packed
	if raw_points.size() == 1:
		packed.append(raw_points[0])
		return packed
	for index in range(raw_points.size() - 1):
		var p0: Vector2 = raw_points[max(index - 1, 0)]
		var p1: Vector2 = raw_points[index]
		var p2: Vector2 = raw_points[index + 1]
		var p3: Vector2 = raw_points[min(index + 2, raw_points.size() - 1)]
		for step in range(TRAIL_SUBDIVISIONS):
			var t: float = float(step) / float(TRAIL_SUBDIVISIONS)
			packed.append(_catmull_rom(p0, p1, p2, p3, t))
	packed.append(raw_points[raw_points.size() - 1])
	return packed


func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


func _build_body_flow_ribbon_points(
	sword_pos: Vector2,
	forward: Vector2,
	scale: float,
	start_t: float,
	end_t: float,
	side_bias: float,
	amplitude_scale: float,
	phase_offset: float,
	sway_scale: float,
	flow_strength: float,
	scroll_speed: float,
	band_density: float,
	tip_bias: float,
	turn_strength: float,
	speed_ratio: float,
	wrap_scale: float
) -> PackedVector2Array:
	var side: Vector2 = forward.rotated(PI * 0.5)
	var root: Vector2 = sword_pos - forward * ((7.2 + 剑体流光向后延伸) * scale)
	var tip: Vector2 = sword_pos + forward * ((24.4 + 剑体流光向前延伸) * scale)
	var start_ratio: float = clampf(start_t, 0.0, 0.96)
	var end_ratio: float = clampf(maxf(end_t, start_ratio + 0.04), start_ratio + 0.04, 1.0)
	var tip_focus_start: float = clampf(0.56 - tip_bias * 0.18, 0.24, 0.82)
	var time_phase: float = main.elapsed_time * scroll_speed
	var points := PackedVector2Array()
	for index in range(BODY_FLOW_SAMPLE_COUNT):
		var local_t: float = float(index) / float(max(BODY_FLOW_SAMPLE_COUNT - 1, 1))
		var along: float = lerpf(start_ratio, end_ratio, local_t)
		var axis_pos: Vector2 = root.lerp(tip, along)
		var middle_mask: float = smoothstep(0.08, 0.36, along)
		var tip_mask: float = smoothstep(tip_focus_start, 1.0, along)
		var blade_half_width: float = _sample_body_flow_half_width(along, scale)
		var envelope: float = pow(maxf(sin(local_t * PI), 0.0), 0.74)
		envelope *= 0.34 + 0.44 * middle_mask + 0.28 * tip_mask
		var amplitude: float = (1.9 + 3.6 * flow_strength + 0.72 * speed_ratio + 0.42 * turn_strength) * sway_scale * amplitude_scale * scale * envelope
		var wave_a: float = sin((along * band_density - time_phase + phase_offset) * TAU)
		var wave_b: float = sin((along * band_density * 0.42 + time_phase * 0.78 + phase_offset * 1.7) * TAU)
		var wave_c: float = sin((along * band_density * 0.78 - time_phase * 1.16 + phase_offset * 2.1) * TAU)
		var wrap_wave: float = (wave_a * (0.62 + 0.18 * turn_strength) + wave_b * 0.26 + wave_c * 0.22) * wrap_scale
		var cross_amount: float = clampf(tip_mask * (0.82 + 0.12 * amplitude_scale) * wrap_scale, 0.0, 1.0)
		var side_profile: float = lerpf(side_bias, side_bias * -0.46, cross_amount)
		var surface_offset: float = blade_half_width * side_profile * (0.78 + 0.28 * middle_mask + 0.16 * tip_mask)
		var lateral_offset: float = surface_offset + amplitude * wrap_wave
		var forward_offset: float = amplitude * 0.22 * sin((along * band_density * 0.56 - time_phase * 0.48 + phase_offset * 0.9) * TAU)
		points.append(axis_pos + side * lateral_offset + forward * forward_offset)
	return points


func _sample_body_flow_half_width(along: float, scale: float) -> float:
	var clamped_along: float = clampf(along, 0.0, 1.0)
	if clamped_along <= 0.28:
		return lerpf(0.86 * scale, 3.2 * scale, smoothstep(0.0, 0.28, clamped_along))
	if clamped_along <= 0.54:
		return lerpf(3.2 * scale, 2.24 * scale, smoothstep(0.28, 0.54, clamped_along))
	return lerpf(2.24 * scale, 0.18 * scale, smoothstep(0.54, 1.0, clamped_along))


func _apply_fill_polygon(polygon: Polygon2D, points: PackedVector2Array, color: Color) -> void:
	if polygon == null:
		return
	polygon.visible = points.size() >= 3 and color.a > 0.001
	if not polygon.visible:
		polygon.polygon = PackedVector2Array()
		return
	polygon.polygon = points
	polygon.color = color


func _build_circle_polygon(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(max(segments, 3)):
		var angle: float = TAU * float(index) / float(max(segments, 3))
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)
	return points


func _apply_line(line: Line2D, points: PackedVector2Array, width: float, color: Color) -> void:
	line.visible = points.size() >= 2 and color.a > 0.001
	if not line.visible:
		line.points = PackedVector2Array()
		return
	line.width = width
	line.self_modulate = color
	line.points = points


func _apply_arc(line: Line2D, center: Vector2, start_angle: float, end_angle: float, radius: float, width: float, color: Color) -> void:
	var points := PackedVector2Array()
	for segment in range(RING_SEGMENTS):
		var t: float = float(segment) / float(max(RING_SEGMENTS - 1, 1))
		var angle: float = lerpf(start_angle, end_angle, t)
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)
	_apply_line(line, points, width, color)


func _get_local_glow_strength() -> float:
	var vfx = main.get_sword_vfx_profile()
	var source_sword: Dictionary = _get_source_sword()
	var sword_state: int = _get_source_sword_state()
	var glow_strength: float = float(vfx.local_glow_ranged_idle) if _get_source_player_mode() == main.CombatMode.RANGED else 0.0
	if sword_state == main.SwordState.POINT_STRIKE:
		var point_speed_ratio: float = clampf(Vector2(source_sword.get("vel", Vector2.ZERO)).length() / maxf(main.SWORD_POINT_STRIKE_SPEED, 0.001), 0.0, 1.0)
		glow_strength = float(vfx.local_glow_point_base) + float(vfx.local_glow_point_speed_scale) * point_speed_ratio
	elif sword_state == main.SwordState.SLICING:
		var slice_speed_ratio: float = clampf(Vector2(source_sword.get("vel", Vector2.ZERO)).length() / maxf(main.SWORD_POINT_STRIKE_SPEED, 0.001), 0.0, 1.0)
		glow_strength = float(vfx.local_glow_slice_base) + float(vfx.local_glow_slice_speed_scale) * slice_speed_ratio
		var hover_blend: float = main._get_sword_hover_blend()
		if hover_blend > 0.0:
			glow_strength = lerpf(glow_strength, maxf(float(vfx.local_glow_ranged_idle), 0.18), hover_blend)
	elif sword_state == main.SwordState.RECALLING:
		var recall_speed_ratio: float = clampf(Vector2(source_sword.get("vel", Vector2.ZERO)).length() / maxf(main.SWORD_RECALL_SPEED, 0.001), 0.0, 1.0)
		glow_strength = float(vfx.local_glow_recall_base) + float(vfx.local_glow_recall_speed_scale) * recall_speed_ratio
	var impact_ratio: float = _get_source_impact_ratio()
	glow_strength = clampf(
		glow_strength
		+ impact_ratio * float(vfx.local_glow_impact_bonus_scale),
		0.0,
		1.0
	)
	return glow_strength
