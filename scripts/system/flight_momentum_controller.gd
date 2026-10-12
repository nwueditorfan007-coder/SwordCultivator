extends RefCounted
class_name FlightMomentumController

# 势：飞行速度与御剑切割互相驱动。
# 设计依据：docs/systems/YUJIAN_BATTLEFIELD_MOMENTUM_CORE.md 第 5 节。
# 势不可储存、不可主动消耗；它只由斩杀产生，并决定巡航速度、斩后爆速和出剑凝滞深度。

const MAX_VALUE := 100.0
const TIER_THRESHOLDS := [0.0, 25.0, 50.0, 75.0]
const TIER_NAMES := ["御风", "起势", "疾", "惊鸿"]
const TIER_CRUISE_MULTIPLIERS := [1.0, 1.12, 1.25, 1.4]
const TIER_DILATION_STARTS := [0.30, 0.22, 0.16, 0.12]
const TIER_DILATION_HOLDS := [0.25, 0.35, 0.45, 0.55]

const KILL_GAIN := 10.0
const MULTI_KILL_BONUS := 4.0
const DECAY_DELAY := 3.0
const DECAY_PER_SECOND := 8.0
const HIT_EXTRA_LOSS := 10.0
const HIT_COOLDOWN := 0.8
const BURST_BASE_DURATION := 0.30
const BURST_PER_KILL := 0.10
const BURST_MAX_DURATION := 0.90

var value := 0.0
var time_since_kill := 999.0
var pending_kills := 0
var burst_timer := 0.0
var last_settled_kills := 0
var hit_cooldown := 0.0


func reset() -> void:
	hit_cooldown = 0.0
	value = 0.0
	time_since_kill = 999.0
	pending_kills = 0
	burst_timer = 0.0
	last_settled_kills = 0


func update(delta: float) -> void:
	time_since_kill += delta
	burst_timer = maxf(burst_timer - delta, 0.0)
	hit_cooldown = maxf(hit_cooldown - delta, 0.0)
	if time_since_kill > DECAY_DELAY and pending_kills == 0:
		value = maxf(value - DECAY_PER_SECOND * delta, 0.0)


# 返回本次斩杀后势是否跨入了更高档位。
func register_kill() -> bool:
	var previous_tier := get_tier()
	pending_kills += 1
	value = minf(value + KILL_GAIN + MULTI_KILL_BONUS * float(pending_kills - 1), MAX_VALUE)
	time_since_kill = 0.0
	return get_tier() > previous_tier


# 一次御剑出手结束时结算：返回斩杀数，并按斩杀数开启斩后爆速。
func settle_strike() -> int:
	var kills := pending_kills
	pending_kills = 0
	last_settled_kills = kills
	if kills > 0:
		burst_timer = minf(BURST_BASE_DURATION + BURST_PER_KILL * float(kills), BURST_MAX_DURATION)
	return kills


func on_player_hit() -> void:
	# 持续接触伤害按帧结算，这里用冷却保证一次受击只降一档。
	if hit_cooldown > 0.0:
		return
	hit_cooldown = HIT_COOLDOWN
	var floor_value: float = TIER_THRESHOLDS[get_tier()]
	value = maxf(floor_value - HIT_EXTRA_LOSS, 0.0)


func is_bursting() -> bool:
	return burst_timer > 0.0


func get_tier() -> int:
	var tier := 0
	for index in range(TIER_THRESHOLDS.size()):
		if value >= float(TIER_THRESHOLDS[index]):
			tier = index
	return tier


func get_tier_name() -> String:
	return TIER_NAMES[get_tier()]


func get_tier_progress() -> float:
	var tier := get_tier()
	var low: float = TIER_THRESHOLDS[tier]
	var high: float = MAX_VALUE if tier >= TIER_THRESHOLDS.size() - 1 else float(TIER_THRESHOLDS[tier + 1])
	return clampf((value - low) / maxf(high - low, 0.001), 0.0, 1.0)


func get_cruise_multiplier() -> float:
	return TIER_CRUISE_MULTIPLIERS[get_tier()]


func get_dilation_start() -> float:
	return TIER_DILATION_STARTS[get_tier()]


func get_dilation_hold() -> float:
	return TIER_DILATION_HOLDS[get_tier()]
