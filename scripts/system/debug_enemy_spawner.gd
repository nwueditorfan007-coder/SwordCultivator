extends Node2D

@export var enemy_scene: PackedScene
@export var enemy_count := 4
@export var spawn_radius := 240.0
@export var respawn_interval := 1.5

var respawn_timer := 0.0


func _ready() -> void:
	_spawn_enemies()


func _physics_process(delta: float) -> void:
	respawn_timer -= delta
	if respawn_timer > 0.0:
		return

	var active_enemies := get_tree().get_nodes_in_group("enemies").size()
	if active_enemies >= enemy_count:
		return

	respawn_timer = respawn_interval
	_spawn_enemy(enemy_count + active_enemies)


func _spawn_enemies() -> void:
	if enemy_scene == null:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		call_deferred("_spawn_enemies")
		return

	for i in enemy_count:
		_spawn_enemy(i)


func _spawn_enemy(index: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var enemy := enemy_scene.instantiate()
	if enemy == null:
		return

	var angle: float = (TAU / float(max(enemy_count, 1))) * float(index % max(enemy_count, 1)) + randf_range(0.15, 0.85)
	enemy.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * spawn_radius
	get_tree().current_scene.add_child.call_deferred(enemy)
