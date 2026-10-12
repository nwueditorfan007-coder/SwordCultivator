extends RefCounted
class_name FlightEncounterDirector

# 飞行大战场入场导演：用「敌群」而不是计时器刷怪。
# 敌群先在玩家前方远处的世界坐标中待机（屏幕边缘有方向标记），玩家飞近后整组转入交锋，
# 沿同一条相对轨迹掠过玩家身侧，保证一刀能串起多个。敌群清空或掠出后，间隔一段巡航空窗再派下一群。
# 设计依据：docs/systems/YUJIAN_BATTLEFIELD_MOMENTUM_CORE.md 第 7 节。

const STATE_DORMANT := "dormant"
const STATE_ACTIVE := "active"

const FIRST_GROUP_DELAY := 0.8
const SPAWN_DISTANCE_MIN := 2300.0
const SPAWN_DISTANCE_MAX := 3000.0
const SPAWN_HEADING_SPREAD := PI * 0.28
const ACTIVATION_MARGIN := 140.0
const RELOCATE_DISTANCE := 5600.0
const TWO_GROUP_UNLOCK_TIME := 40.0
const MAX_ALIVE_ENEMIES := 10
const GAP_AT_LOW_MOMENTUM := 3.2
const GAP_AT_HIGH_MOMENTUM := 1.6
const ROUTE_CROSS_ANGLE := PI * 0.16
const ROUTE_EXIT_BUFFER := 420.0
const FORMATION_SPACING := 96.0

var groups: Array = []
var elapsed := 0.0
var gap_timer := FIRST_GROUP_DELAY
var group_counter := 0


func reset() -> void:
	groups.clear()
	elapsed = 0.0
	gap_timer = FIRST_GROUP_DELAY
	group_counter = 0


func update(main: Node, delta: float) -> void:
	elapsed += delta
	var player_pos: Vector2 = Vector2(main.player.get("pos", Vector2.ZERO))
	var visible_rect: Rect2 = main._get_visible_world_rect().grow(ACTIVATION_MARGIN)
	var index := groups.size() - 1
	while index >= 0:
		var group: Dictionary = groups[index]
		var alive := _collect_alive_members(main, group)
		if alive.is_empty():
			groups.remove_at(index)
			gap_timer = maxf(gap_timer, _get_gap(main))
			index -= 1
			continue
		if str(group.get("state", "")) == STATE_DORMANT:
			var center: Vector2 = group["center"]
			if visible_rect.has_point(center):
				_activate_group(main, group, alive, player_pos)
			elif player_pos.distance_to(center) > RELOCATE_DISTANCE:
				_relocate_group(main, group, alive, player_pos)
		index -= 1

	gap_timer = maxf(gap_timer - delta, 0.0)
	if gap_timer > 0.0:
		return
	if groups.size() >= _get_target_group_count():
		return
	if _count_alive_enemies(main) >= MAX_ALIVE_ENEMIES:
		return
	_spawn_group(main, player_pos)
	gap_timer = _get_gap(main)


func activate_all(main: Node) -> void:
	var player_pos: Vector2 = Vector2(main.player.get("pos", Vector2.ZERO))
	for group_variant in groups:
		var group: Dictionary = group_variant
		if str(group.get("state", "")) == STATE_DORMANT:
			_activate_group(main, group, _collect_alive_members(main, group), player_pos)


func get_dormant_markers(main: Node) -> Array:
	var markers: Array = []
	for group_variant in groups:
		var group: Dictionary = group_variant
		if str(group.get("state", "")) != STATE_DORMANT:
			continue
		markers.append({
			"pos": group["center"],
			"count": _collect_alive_members(main, group).size(),
		})
	return markers


func _get_target_group_count() -> int:
	return 1 if elapsed < TWO_GROUP_UNLOCK_TIME else 2


func _get_gap(main: Node) -> float:
	var tier_ratio := 0.0
	if main.flight_momentum != null:
		tier_ratio = float(main.flight_momentum.get_tier()) / 3.0
	return lerpf(GAP_AT_LOW_MOMENTUM, GAP_AT_HIGH_MOMENTUM, tier_ratio)


func _spawn_group(main: Node, player_pos: Vector2) -> void:
	var heading: Vector2 = Vector2(main.body_heading)
	if heading.length_squared() < 0.0001:
		heading = Vector2.RIGHT
	var direction := heading.normalized().rotated(randf_range(-SPAWN_HEADING_SPREAD, SPAWN_HEADING_SPREAD))
	var center := player_pos + direction * randf_range(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
	center = center.clamp(main.PLAY_RECT.position + Vector2(200.0, 200.0), main.PLAY_RECT.end - Vector2(200.0, 200.0))
	group_counter += 1
	var formation := _pick_formation()
	var group := {
		"id": "flight_group_%d" % group_counter,
		"state": STATE_DORMANT,
		"center": center,
		"formation": formation.get("name", ""),
		"members": [],
	}
	var axis := (center - player_pos).normalized().orthogonal()
	for slot_variant in formation.get("slots", []):
		var slot: Dictionary = slot_variant
		var offset: Vector2 = Vector2(slot["offset"])
		var world_pos: Vector2 = center + axis * offset.x * FORMATION_SPACING + (center - player_pos).normalized() * offset.y * FORMATION_SPACING
		var enemy: Dictionary = main._spawn_flight_enemy_world(str(slot["type"]), world_pos, str(slot["behavior"]))
		enemy["flight_group_id"] = group["id"]
		enemy["flight_dormant"] = true
		enemy["flight_group_offset"] = world_pos - center
		group["members"].append(str(enemy.get("id", "")))
	groups.append(group)


# 早期只派小而规整的一字编队，让玩家先学会「飞过去、一刀串」；之后混入追击与重装。
func _pick_formation() -> Dictionary:
	if group_counter <= 2:
		return {"name": "needle_line_3", "slots": [
			{"type": "shooter", "behavior": "drift_shooter", "offset": Vector2(-1.0, 0.0)},
			{"type": "shooter", "behavior": "drift_shooter", "offset": Vector2(0.0, 0.0)},
			{"type": "shooter", "behavior": "drift_shooter", "offset": Vector2(1.0, 0.0)},
		]}
	var roll := randi() % 3
	match roll:
		0:
			return {"name": "needle_line_4", "slots": [
				{"type": "shooter", "behavior": "drift_shooter", "offset": Vector2(-1.5, 0.0)},
				{"type": "shooter", "behavior": "drift_shooter", "offset": Vector2(-0.5, 0.0)},
				{"type": "shooter", "behavior": "drift_shooter", "offset": Vector2(0.5, 0.0)},
				{"type": "shooter", "behavior": "drift_shooter", "offset": Vector2(1.5, 0.0)},
			]}
		1:
			return {"name": "leech_wedge", "slots": [
				{"type": "ring_leech", "behavior": "ring_pursuer", "offset": Vector2(0.0, -0.6)},
				{"type": "ring_leech", "behavior": "ring_pursuer", "offset": Vector2(-1.0, 0.4)},
				{"type": "ring_leech", "behavior": "ring_pursuer", "offset": Vector2(1.0, 0.4)},
			]}
		_:
			return {"name": "heavy_escort", "slots": [
				{"type": "heavy", "behavior": "heavy_gate", "offset": Vector2(0.0, 0.0)},
				{"type": "shooter", "behavior": "drift_shooter", "offset": Vector2(-1.3, 0.3)},
				{"type": "shooter", "behavior": "drift_shooter", "offset": Vector2(1.3, 0.3)},
			]}


# 整组共用同一条相对轨迹方向：编队保持队形掠过玩家身侧。
func _activate_group(main: Node, group: Dictionary, alive: Array, player_pos: Vector2) -> void:
	group["state"] = STATE_ACTIVE
	var center: Vector2 = group["center"]
	var to_group := center - player_pos
	var entry_direction := to_group.normalized()
	if entry_direction.is_zero_approx():
		entry_direction = Vector2.RIGHT
	var side := 1.0 if randf() < 0.5 else -1.0
	var travel_direction := (-entry_direction).rotated(ROUTE_CROSS_ANGLE * side).normalized()
	var route_length := to_group.length() * 2.0 + ROUTE_EXIT_BUFFER
	for enemy_variant in alive:
		var enemy: Dictionary = enemy_variant
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", center))
		enemy["flight_dormant"] = false
		enemy["large_arena_trajectory_active"] = true
		enemy["large_arena_entry_progress"] = 0.0
		enemy["large_arena_entry_direction"] = entry_direction
		enemy["large_arena_entry_distance"] = to_group.length()
		enemy["flight_route_origin_relative"] = enemy_pos - player_pos
		enemy["flight_route_direction"] = travel_direction
		enemy["flight_route_length"] = route_length
		# 从世界静止平滑过渡到跟随玩家，避免入场瞬间被整体拽动。
		enemy["flight_engagement_follow"] = 0.0


func _relocate_group(main: Node, group: Dictionary, alive: Array, player_pos: Vector2) -> void:
	var heading: Vector2 = Vector2(main.body_heading)
	if heading.length_squared() < 0.0001:
		heading = Vector2.RIGHT
	var center := player_pos + heading.normalized() * SPAWN_DISTANCE_MAX
	center = center.clamp(main.PLAY_RECT.position + Vector2(200.0, 200.0), main.PLAY_RECT.end - Vector2(200.0, 200.0))
	group["center"] = center
	for enemy_variant in alive:
		var enemy: Dictionary = enemy_variant
		enemy["pos"] = center + Vector2(enemy.get("flight_group_offset", Vector2.ZERO))


func _collect_alive_members(main: Node, group: Dictionary) -> Array:
	var alive: Array = []
	for member_id in group.get("members", []):
		var enemy: Variant = main._find_enemy_by_id(str(member_id))
		if enemy == null:
			continue
		if bool(enemy.get("is_dying", false)) or float(enemy.get("health", 0.0)) <= 0.0:
			continue
		alive.append(enemy)
	return alive


func _count_alive_enemies(main: Node) -> int:
	var count := 0
	for enemy_variant in main.enemies:
		var enemy: Dictionary = enemy_variant
		if not bool(enemy.get("is_dying", false)):
			count += 1
	return count
