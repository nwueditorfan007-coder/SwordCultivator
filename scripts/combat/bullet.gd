extends Area2D

@export var speed := 320.0
@export var direction := Vector2.LEFT
@export var reflectable := true
@export var lifetime := 8.0
@export var deflect_speed_multiplier := 10
@export var player_damage := 1

var owner_is_player := false
var source_enemy: Node2D
var source_position := Vector2.ZERO


func _ready() -> void:
	add_to_group("bullets")
	queue_redraw()


func _physics_process(delta: float) -> void:
	if is_instance_valid(source_enemy):
		source_position = source_enemy.global_position
	position += direction.normalized() * speed * delta
	lifetime -= delta
	_process_collisions()
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	var bullet_color := Color(0.6, 0.9, 1.0) if reflectable else Color(1.0, 0.3, 0.4)
	draw_circle(Vector2.ZERO, 7.0, bullet_color)
	if not reflectable:
		draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 18, Color(1.0, 0.65, 0.2), 2.0)


func launch(from_position: Vector2, travel_direction: Vector2, from_player := false, enemy_source: Node2D = null) -> void:
	global_position = from_position
	direction = travel_direction.normalized()
	owner_is_player = from_player
	source_enemy = enemy_source
	source_position = from_position
	queue_redraw()


func deflect_towards_source() -> void:
	owner_is_player = true
	direction = _get_return_direction()
	speed *= deflect_speed_multiplier
	queue_redraw()


func _get_return_direction() -> Vector2:
	var target_position := source_position
	if is_instance_valid(source_enemy):
		target_position = source_enemy.global_position
	var to_target := target_position - global_position
	if to_target.is_zero_approx():
		return Vector2.UP
	return to_target.normalized()


func _process_collisions() -> void:
	if owner_is_player:
		_process_enemy_collisions()
	else:
		_process_player_collision()


func _process_player_collision() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if player.global_position.distance_to(global_position) > 18.0:
		return
	if player.has_method("apply_damage"):
		player.apply_damage(player_damage)
	queue_free()


func _process_enemy_collisions() -> void:
	if is_instance_valid(source_enemy):
		if source_enemy.global_position.distance_to(global_position) <= 24.0:
			if source_enemy.has_method("apply_damage"):
				source_enemy.apply_damage(9999.0)
			queue_free()
			return
	if source_position.distance_to(global_position) <= 18.0:
		queue_free()
