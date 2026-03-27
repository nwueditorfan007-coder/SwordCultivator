extends CharacterBody2D

@export var max_health := 8.0
@export var move_speed := 55.0
@export var shoot_interval := 1.1
@export var bullet_speed := 260.0
@export var bullet_scene: PackedScene = preload("res://scenes/combat/Bullet.tscn")

var current_health := max_health
var shoot_timer := 0.0
var shot_index := 0


func _ready() -> void:
	add_to_group("enemies")
	shoot_timer = randf_range(0.15, shoot_interval)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var to_player := player.global_position - global_position
	if to_player.length() > 70.0:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_process_shooting(delta, player, to_player)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(0.8, 0.18, 0.18))
	var health_ratio := maxf(0.0, current_health / max_health)
	draw_rect(Rect2(Vector2(-20.0, -32.0), Vector2(40.0, 5.0)), Color(0.18, 0.08, 0.08), true)
	draw_rect(Rect2(Vector2(-20.0, -32.0), Vector2(40.0 * health_ratio, 5.0)), Color(0.95, 0.35, 0.3), true)


func apply_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0.0:
		queue_free()
	else:
		queue_redraw()


func _process_shooting(delta: float, player: Node2D, to_player: Vector2) -> void:
	if bullet_scene == null:
		return

	shoot_timer -= delta
	if shoot_timer > 0.0:
		return

	shoot_timer = shoot_interval
	var bullet := bullet_scene.instantiate()
	if bullet == null:
		return

	var shoot_direction := to_player.normalized()
	if shoot_direction.is_zero_approx():
		shoot_direction = Vector2.DOWN

	var is_blue_bullet := shot_index % 3 != 2
	bullet.reflectable = is_blue_bullet
	bullet.speed = bullet_speed if is_blue_bullet else bullet_speed * 1.15
	get_tree().current_scene.add_child.call_deferred(bullet)
	bullet.launch.call_deferred(global_position, shoot_direction, false, self)
	shot_index += 1
