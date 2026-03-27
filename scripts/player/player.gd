extends CharacterBody2D

enum CombatMode {
	MELEE,
	RANGED,
}

@export var move_speed := 280.0
@export var dash_speed := 620.0
@export var dash_duration := 0.18
@export var attack_cooldown := 0.22
@export var attack_radius := 96.0
@export var attack_arc := 1.45
@export var max_health := 5
@export var invulnerability_duration := 0.8

var combat_mode: CombatMode = CombatMode.MELEE
var facing_direction := Vector2.RIGHT
var move_facing_direction := Vector2.DOWN
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var attack_timer := 0.0
var attack_flash_timer := 0.0
var current_health := max_health
var invulnerability_timer := 0.0
var is_dead := false

@onready var flying_sword: Node2D = $FlyingSword
@onready var health_label: Label = get_tree().current_scene.get_node_or_null("CanvasLayer/HealthLabel")
@onready var mode_label: Label = get_tree().current_scene.get_node_or_null("CanvasLayer/ModeLabel")
@onready var game_over_label: Label = get_tree().current_scene.get_node_or_null("CanvasLayer/GameOverLabel")

func _ready() -> void:
	add_to_group("player")
	if flying_sword != null and flying_sword.has_method("setup"):
		flying_sword.setup(self)
		flying_sword.set_active(false)
	_update_mode_label()
	_update_health_label()


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		queue_redraw()
		return

	attack_timer = maxf(0.0, attack_timer - delta)
	attack_flash_timer = maxf(0.0, attack_flash_timer - delta)
	invulnerability_timer = maxf(0.0, invulnerability_timer - delta)

	if Input.is_action_just_pressed("switch_mode"):
		_toggle_mode()

	if Input.is_action_just_pressed("dash"):
		_start_dash()

	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var mouse_position := get_global_mouse_position()
	if not mouse_position.is_equal_approx(global_position):
		facing_direction = (mouse_position - global_position).normalized()
	if not move_input.is_zero_approx():
		move_facing_direction = move_input.normalized()

	if Input.is_action_just_pressed("attack") and combat_mode == CombatMode.MELEE and attack_timer <= 0.0:
		_perform_melee_attack()

	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		velocity = dash_direction * dash_speed
	else:
		velocity = move_input * move_speed

	move_and_slide()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 18.0, _get_body_color())

	var sword_anchor := facing_direction * 28.0
	if combat_mode == CombatMode.MELEE:
		draw_arc(Vector2.ZERO, 32.0, facing_direction.angle() - 0.65, facing_direction.angle() + 0.65, 24, Color(0.8, 0.95, 1.0), 5.0)
		draw_line(Vector2.ZERO, sword_anchor, Color(1.0, 1.0, 1.0), 4.0)
	else:
		draw_arc(Vector2.ZERO, 24.0, facing_direction.angle() - 0.45, facing_direction.angle() + 0.45, 16, Color(1.0, 0.6, 0.22, 0.8), 3.0)

	if attack_flash_timer > 0.0:
		draw_arc(
			Vector2.ZERO,
			attack_radius,
			facing_direction.angle() - attack_arc * 0.5,
			facing_direction.angle() + attack_arc * 0.5,
			30,
			Color(1.0, 1.0, 1.0, 0.85),
			7.0
		)


func _toggle_mode() -> void:
	combat_mode = CombatMode.RANGED if combat_mode == CombatMode.MELEE else CombatMode.MELEE
	if flying_sword != null and flying_sword.has_method("set_active"):
		flying_sword.set_active(combat_mode == CombatMode.RANGED)
	_update_mode_label()


func _start_dash() -> void:
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not move_input.is_zero_approx():
		dash_direction = move_input.normalized()
	else:
		dash_direction = move_facing_direction
	dash_timer = dash_duration


func _perform_melee_attack() -> void:
	attack_timer = attack_cooldown
	attack_flash_timer = 0.08

	for bullet: Area2D in get_tree().get_nodes_in_group("bullets"):
		if bullet.owner_is_player:
			continue

		var offset := bullet.global_position - global_position
		if offset.length() > attack_radius:
			continue
		if absf(facing_direction.angle_to(offset.normalized())) > attack_arc * 0.5:
			continue

		if bullet.reflectable:
			bullet.deflect_towards_source()
		else:
			bullet.queue_free()

	queue_redraw()


func _update_mode_label() -> void:
	if mode_label == null:
		return
	mode_label.text = "Mode: %s" % ("Melee" if combat_mode == CombatMode.MELEE else "Ranged")


func _update_health_label() -> void:
	if health_label == null:
		return
	health_label.text = "Health: %d / %d" % [current_health, max_health]


func apply_damage(amount: int) -> void:
	if is_dead or invulnerability_timer > 0.0:
		return

	current_health = maxi(0, current_health - amount)
	invulnerability_timer = invulnerability_duration
	_update_health_label()
	if current_health <= 0:
		_die()
	queue_redraw()


func _die() -> void:
	is_dead = true
	if flying_sword != null and flying_sword.has_method("set_active"):
		flying_sword.set_active(false)
	if game_over_label != null:
		game_over_label.visible = true


func _get_body_color() -> Color:
	if is_dead:
		return Color(0.25, 0.25, 0.28)
	if invulnerability_timer > 0.0 and Engine.get_process_frames() % 6 < 3:
		return Color(1.0, 1.0, 1.0)
	if combat_mode == CombatMode.MELEE:
		return Color(0.3, 0.75, 1.0)
	return Color(1.0, 0.55, 0.25)
