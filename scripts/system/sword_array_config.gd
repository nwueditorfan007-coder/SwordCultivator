extends RefCounted
class_name SwordArrayConfig


const MODE_RING := "ring"
const MODE_FAN := "fan"
const MODE_PIERCE := "pierce"

const HOLD_THRESHOLD := 0.10
const ABSORB_RANGE := 250.0
const ABSORB_ENERGY_COST := 10.0
const MAX_ABSORBED := 12
const FIRED_SPEED := 45.0 * 60.0
const FIRED_DAMAGE := 100.0

const RING_THRESHOLD := 160.0
const FAN_THRESHOLD := 420.0

const MODE_PROFILES := {
	MODE_RING: {
		"ring_radius": 68.0,
		"idle_ring_radius": 44.0,
		"slot_count": 10,
		"fire_interval": 0.32,
		"burst_mode": "all",
		"preview_outer_offset_idle": 6.0,
		"preview_outer_offset_active": 10.0,
		"accent_color": Color(0.35, 1.0, 0.92),
		"accent_soft_color": Color(0.25, 1.0, 0.9),
		"fire_particles_base": 6,
		"fire_particles_per_shot": 1,
		"fire_particles_cap": 20,
		"fire_offset": 0.0,
		"fire_shake": 2.2,
	},
	MODE_FAN: {
		"arc": 1.0,
		"idle_arc": 0.42,
		"radius": 110.0,
		"idle_radius": 72.0,
		"slot_count": 7,
		"fire_interval": 0.16,
		"burst_mode": "three_step",
		"accent_color": Color(0.72, 0.96, 1.0),
		"accent_soft_color": Color(0.9, 1.0, 1.0),
		"fire_particles_base": 5,
		"fire_particles_per_shot": 1,
		"fire_particles_cap": 18,
		"fire_offset": 40.0,
		"fire_shake": 2.4,
	},
	MODE_PIERCE: {
		"spread": 0.08,
		"start_offset": 52.0,
		"idle_start_offset": 28.0,
		"slot_step": 28.0,
		"idle_slot_step": 18.0,
		"preview_length": 180.0,
		"preview_length_idle_scale": 0.65,
		"preview_half_width": 6.0,
		"idle_half_width": 18.0,
		"slot_count": 5,
		"fire_interval": 0.08,
		"burst_mode": "single",
		"accent_color": Color(0.9, 1.0, 1.0),
		"accent_soft_color": Color(0.8, 1.0, 1.0),
		"fire_particles_base": 4,
		"fire_particles_per_shot": 2,
		"fire_particles_cap": 22,
		"fire_offset": 72.0,
		"fire_shake": 2.8,
	},
}


static func get_mode_for_distance(aim_distance: float) -> String:
	if aim_distance <= RING_THRESHOLD:
		return MODE_RING
	if aim_distance <= FAN_THRESHOLD:
		return MODE_FAN
	return MODE_PIERCE


static func get_profile(mode: String) -> Dictionary:
	return MODE_PROFILES.get(mode, MODE_PROFILES[MODE_PIERCE])
