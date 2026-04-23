extends Node2D

@export var contact_damage := 9999.0
@export_group("Idle Hover")
@export_range(0.0, 8.0, 0.1) var hover_idle_enter_distance := 0.8
@export_range(0.0, 16.0, 0.1) var hover_idle_exit_distance := 1.8
@export_range(0.0, 1.0, 0.01) var hover_idle_enter_delay := 0.14
@export_range(1.0, 30.0, 0.1) var hover_motion_filter_strength := 14.0
@export_range(0.0, 1.0, 0.01) var hover_blend_in_duration := 0.2
@export_range(0.0, 1.0, 0.01) var hover_blend_out_duration := 0.08
@export_range(0.0, 12.0, 0.1) var hover_float_amplitude := 4.2
@export_range(0.0, 12.0, 0.1) var hover_orbit_amplitude := 2.4
@export_range(0.1, 8.0, 0.1) var hover_float_frequency := 2.1
@export_range(0.1, 8.0, 0.1) var hover_orbit_frequency := 1.35
@export_range(0.0, 0.8, 0.01) var hover_glow_alpha := 0.2
@export_range(0.0, 6.0, 0.1) var hover_body_pulse := 1.0
@export_range(0.0, 6.0, 0.1) var hover_ring_pulse := 1.8
@export_range(0.0, 0.1, 0.001) var hover_settle_impulse_scale := 0.012
@export_range(0.0, 12.0, 0.1) var hover_settle_impulse_max := 5.0
@export_range(0.0, 60.0, 0.1) var hover_settle_spring_strength := 24.0
@export_range(0.0, 30.0, 0.1) var hover_settle_damping := 8.5
@export_range(0.0, 1.0, 0.01) var hover_trail_fade := 0.82

var active := false
var owner_player: CharacterBody2D
var movement_vector := Vector2.ZERO
var sword_forward := Vector2.RIGHT
var filtered_motion := 0.0
var recent_motion_speed := 0.0
var recent_motion_direction := Vector2.RIGHT
var hover_idle_candidate_time := 0.0
var hover_idle_active := false
var hover_idle_blend := 0.0
var hover_elapsed_time := 0.0
var hover_phase := 0.0
var hover_visual_offset := Vector2.ZERO
var hover_visual_rotation := 0.0
var hover_settle_offset := Vector2.ZERO
var hover_settle_velocity := Vector2.ZERO


func _ready() -> void:
	add_to_group("flying_sword")
	set_physics_process(true)
	hover_phase = randf() * TAU
	queue_redraw()


func _physics_process(delta: float) -> void:
	if owner_player == null:
		return

	if not active:
		global_position = owner_player.global_position
		movement_vector = Vector2.ZERO
		_reset_hover_state()
		queue_redraw()
		return

	var desired_position := owner_player.get_global_mouse_position()
	movement_vector = desired_position - global_position
	global_position = desired_position
	_update_sword_forward()
	_update_hover_state(delta)

	_slice_overlapping_enemies()
	queue_redraw()


func _draw() -> void:
	if not active:
		return

	var pulse_phase := hover_elapsed_time * TAU * 1.6 + hover_phase * 0.5
	var pulse := 0.5 + 0.5 * sin(pulse_phase)
	var pulse_offset := (pulse - 0.5) * 2.0
	var idle_visual_strength := maxf(
		hover_idle_blend,
		clampf(1.0 - filtered_motion / maxf(hover_idle_exit_distance * 1.4, 0.001), 0.0, 1.0) * 0.35
	)
	var body_radius := 11.0 + hover_idle_blend * hover_body_pulse * pulse_offset
	var ring_radius := 18.0 + hover_idle_blend * hover_ring_pulse * pulse_offset
	var body_color := Color(1.0, 0.88, 0.35).lerp(Color(1.0, 0.96, 0.82), idle_visual_strength * 0.28 + pulse * idle_visual_strength * 0.1)
	var ring_color := Color(1.0, 1.0, 1.0, 0.85 + idle_visual_strength * 0.1 * pulse)
	var aura_color := Color(0.74, 0.94, 1.0, hover_glow_alpha * idle_visual_strength * (0.65 + 0.35 * pulse))
	var facing_angle := sword_forward.angle() + hover_visual_rotation

	draw_set_transform(hover_visual_offset, facing_angle, Vector2.ONE)
	if idle_visual_strength > 0.01:
		draw_circle(Vector2.ZERO, ring_radius + 4.4 + pulse * 1.1, aura_color)
	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 20, ring_color, 2.0 + hover_idle_blend * 0.35)
	draw_line(Vector2(-9.0, 0.0), Vector2(15.0, 0.0), Color(1.0, 1.0, 1.0, 0.3 + 0.16 * idle_visual_strength), 2.6)
	draw_circle(Vector2(15.0, 0.0), 2.0 + 0.65 * idle_visual_strength, Color(1.0, 1.0, 1.0, 0.54 + 0.18 * idle_visual_strength))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if movement_vector.length() > 1.0:
		var tail_alpha := 0.7 * (1.0 - hover_idle_blend * hover_trail_fade)
		draw_line(
			hover_visual_offset,
			hover_visual_offset - movement_vector.normalized() * minf(movement_vector.length(), 22.0),
			Color(0.75, 0.95, 1.0, tail_alpha),
			3.0
		)


func setup(player: CharacterBody2D) -> void:
	owner_player = player
	global_position = player.global_position
	_reset_hover_state()
	queue_redraw()


func set_active(value: bool) -> void:
	active = value
	if owner_player != null and not active:
		global_position = owner_player.global_position
		movement_vector = Vector2.ZERO
		_reset_hover_state()
	queue_redraw()


func _slice_overlapping_enemies() -> void:
	for enemy: CharacterBody2D in get_tree().get_nodes_in_group("enemies"):
		var distance := enemy.global_position.distance_to(global_position)
		if distance > 26.0:
			continue
		if enemy.has_method("apply_damage"):
			enemy.apply_damage(contact_damage)


func _update_sword_forward() -> void:
	if movement_vector.length_squared() > 0.0001:
		recent_motion_direction = movement_vector.normalized()
		sword_forward = recent_motion_direction
		return

	var anchor_vector := global_position - owner_player.global_position
	if anchor_vector.length_squared() > 0.0001:
		sword_forward = anchor_vector.normalized()


func _update_hover_state(delta: float) -> void:
	hover_elapsed_time += delta

	var frame_motion := movement_vector.length()
	var current_speed := frame_motion / maxf(delta, 0.0001)
	var filter_weight := clampf(delta * hover_motion_filter_strength, 0.0, 1.0)
	filtered_motion = lerpf(filtered_motion, frame_motion, filter_weight)

	if frame_motion > 0.05 and movement_vector.length_squared() > 0.0001:
		recent_motion_speed = current_speed
		recent_motion_direction = movement_vector.normalized()

	var was_idle := hover_idle_active
	if hover_idle_active:
		if filtered_motion >= hover_idle_exit_distance:
			hover_idle_active = false
			hover_idle_candidate_time = 0.0
	else:
		if filtered_motion <= hover_idle_enter_distance:
			hover_idle_candidate_time += delta
			if hover_idle_candidate_time >= hover_idle_enter_delay:
				hover_idle_active = true
		else:
			hover_idle_candidate_time = 0.0

	if hover_idle_active and not was_idle:
		var settle_impulse := -recent_motion_direction * minf(recent_motion_speed * hover_settle_impulse_scale, hover_settle_impulse_max)
		hover_settle_offset += settle_impulse

	var blend_duration := hover_blend_in_duration if hover_idle_active else hover_blend_out_duration
	hover_idle_blend = move_toward(
		hover_idle_blend,
		1.0 if hover_idle_active else 0.0,
		delta / maxf(blend_duration, 0.001)
	)

	hover_settle_velocity += (-hover_settle_offset * hover_settle_spring_strength - hover_settle_velocity * hover_settle_damping) * delta
	hover_settle_offset += hover_settle_velocity * delta

	var float_phase := hover_elapsed_time * TAU * hover_float_frequency + hover_phase
	var orbit_phase := hover_elapsed_time * TAU * hover_orbit_frequency + hover_phase * 1.37
	var sideways := sword_forward.orthogonal().normalized()
	var idle_offset := sideways * sin(float_phase) * hover_float_amplitude
	idle_offset += sword_forward * cos(orbit_phase) * hover_orbit_amplitude
	var idle_visual_strength := maxf(
		hover_idle_blend,
		clampf(1.0 - filtered_motion / maxf(hover_idle_exit_distance * 1.4, 0.001), 0.0, 1.0) * 0.35
	)
	hover_visual_offset = idle_offset * idle_visual_strength + hover_settle_offset
	hover_visual_rotation = deg_to_rad(8.0) * idle_visual_strength * sin(orbit_phase + 0.4)
	hover_visual_rotation += deg_to_rad(2.2) * clampf(
		hover_settle_offset.dot(sideways) / maxf(hover_settle_impulse_max, 0.001),
		-1.0,
		1.0
	)


func _reset_hover_state() -> void:
	filtered_motion = 0.0
	recent_motion_speed = 0.0
	hover_idle_candidate_time = 0.0
	hover_idle_active = false
	hover_idle_blend = 0.0
	hover_elapsed_time = 0.0
	hover_visual_offset = Vector2.ZERO
	hover_visual_rotation = 0.0
	hover_settle_offset = Vector2.ZERO
	hover_settle_velocity = Vector2.ZERO
