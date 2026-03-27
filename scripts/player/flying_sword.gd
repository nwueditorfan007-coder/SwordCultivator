extends Node2D

@export var contact_damage := 9999.0

var active := false
var owner_player: CharacterBody2D
var movement_vector := Vector2.ZERO


func _ready() -> void:
	add_to_group("flying_sword")
	set_physics_process(true)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if owner_player == null:
		return

	if not active:
		global_position = owner_player.global_position
		movement_vector = Vector2.ZERO
		queue_redraw()
		return

	var desired_position := owner_player.get_global_mouse_position()
	movement_vector = desired_position - global_position
	global_position = desired_position

	_slice_overlapping_enemies()
	queue_redraw()


func _draw() -> void:
	if not active and owner_player != null:
		return

	draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.88, 0.35))
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.85), 2.0)
	if movement_vector.length() > 1.0:
		draw_line(Vector2.ZERO, -movement_vector.normalized() * minf(movement_vector.length(), 22.0), Color(0.75, 0.95, 1.0, 0.7), 3.0)


func setup(player: CharacterBody2D) -> void:
	owner_player = player
	global_position = player.global_position
	queue_redraw()


func set_active(value: bool) -> void:
	active = value
	if owner_player != null and not active:
		global_position = owner_player.global_position
		movement_vector = Vector2.ZERO
	queue_redraw()


func _slice_overlapping_enemies() -> void:
	for enemy: CharacterBody2D in get_tree().get_nodes_in_group("enemies"):
		var distance := enemy.global_position.distance_to(global_position)
		if distance > 26.0:
			continue
		if enemy.has_method("apply_damage"):
			enemy.apply_damage(contact_damage)
