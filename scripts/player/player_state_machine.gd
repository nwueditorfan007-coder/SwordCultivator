extends RefCounted
class_name PlayerStateMachine

enum CombatMode {
	MELEE,
	RANGED,
}

var current_mode: CombatMode = CombatMode.MELEE


func set_mode(next_mode: CombatMode) -> void:
	current_mode = next_mode


func toggle_mode() -> CombatMode:
	current_mode = CombatMode.RANGED if current_mode == CombatMode.MELEE else CombatMode.MELEE
	return current_mode
