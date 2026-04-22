extends Resource
class_name SwordVfxProfile


@export_group("拖尾")
@export_range(0.02, 0.3, 0.005) var trail_duration := 0.11
@export_range(0.004, 0.05, 0.001) var trail_sample_interval := 0.012
@export_range(120.0, 1200.0, 10.0) var trail_min_speed := 560.0
@export_range(4, 32, 1) var trail_max_points := 12
@export_range(2.0, 24.0, 0.5) var trail_base_half_width := 11.0
@export_range(0.2, 1.4, 0.02) var trail_point_width_scale := 0.66
@export_range(0.4, 1.8, 0.02) var trail_slice_width_scale := 1.08
@export_range(0.2, 1.2, 0.02) var trail_recall_width_scale := 0.58
@export_range(0.0, 24.0, 0.5) var trail_forward_offset := 11.0
@export_range(0.3, 1.6, 0.02) var trail_point_life_scale := 0.9
@export_range(0.3, 1.8, 0.02) var trail_slice_life_scale := 1.12
@export_range(0.3, 1.6, 0.02) var trail_recall_life_scale := 0.96


@export_group("气流")
@export_range(0.02, 0.3, 0.005) var air_wake_duration := 0.1
@export_range(200.0, 2400.0, 10.0) var air_wake_min_speed := 680.0
@export_range(2, 32, 1) var air_wake_max_count := 14
@export_range(4.0, 80.0, 1.0) var air_wake_base_length := 24.0
@export_range(2.0, 40.0, 0.5) var air_wake_base_width := 12.0
@export_range(0.01, 0.4, 0.01) var air_wake_turn_threshold := 0.12
@export_range(0.004, 0.08, 0.001) var air_wake_emit_interval_min := 0.016
@export_range(0.004, 0.12, 0.001) var air_wake_emit_interval_max := 0.042


@export_group("前锋破空")
@export_range(0.0, 0.9, 0.01) var front_speed_start := 0.34
@export_range(0.1, 1.0, 0.01) var front_speed_span := 0.66
@export_range(4.0, 40.0, 0.5) var front_length_min := 14.0
@export_range(8.0, 80.0, 0.5) var front_length_max := 42.0
@export_range(0.2, 1.2, 0.02) var front_recall_length_scale := 0.8
@export_range(1.0, 16.0, 0.25) var front_width_min := 4.0
@export_range(2.0, 24.0, 0.25) var front_width_max := 10.0
@export_range(0.2, 1.2, 0.02) var front_recall_width_scale := 0.82
@export_range(0.0, 8.0, 0.1) var front_point_pulse := 4.0
@export_range(0.0, 8.0, 0.1) var front_recall_pulse := 2.0


@export_group("剑体辉光")
@export_range(0.0, 0.4, 0.01) var local_glow_ranged_idle := 0.05
@export_range(0.0, 1.0, 0.01) var local_glow_point_base := 0.22
@export_range(0.0, 1.0, 0.01) var local_glow_point_speed_scale := 0.5
@export_range(0.0, 1.0, 0.01) var local_glow_slice_base := 0.2
@export_range(0.0, 1.0, 0.01) var local_glow_slice_speed_scale := 0.34
@export_range(0.0, 1.0, 0.01) var local_glow_recall_base := 0.16
@export_range(0.0, 1.0, 0.01) var local_glow_recall_speed_scale := 0.32
@export_range(0.0, 1.0, 0.01) var local_glow_array_outbound := 0.18
@export_range(0.0, 1.0, 0.01) var local_glow_array_recall := 0.22
@export_range(0.0, 1.0, 0.01) var local_glow_array_channel_base := 0.14
@export_range(0.0, 0.4, 0.01) var local_glow_array_channel_hold_scale := 0.08
@export_range(0.0, 1.0, 0.01) var local_glow_impact_bonus_scale := 0.36
@export_range(0.0, 0.4, 0.01) var local_glow_time_stop_bonus_scale := 0.08
@export_range(0.5, 8.0, 0.1) var local_glow_tip_radius_min := 1.9
@export_range(0.0, 8.0, 0.1) var local_glow_tip_radius_scale := 3.8
@export_range(0.0, 4.0, 0.1) var local_glow_tip_radius_pulse := 1.1
@export_range(0.5, 10.0, 0.1) var local_glow_guard_radius_min := 2.8
@export_range(0.0, 10.0, 0.1) var local_glow_guard_radius_scale := 4.4
@export_range(0.1, 4.0, 0.05) var local_glow_spine_width_min := 0.84
@export_range(0.0, 4.0, 0.05) var local_glow_spine_width_scale := 1.3
@export_range(0.0, 0.4, 0.01) var local_glow_spine_alpha_base := 0.05
@export_range(0.0, 0.4, 0.01) var local_glow_spine_alpha_scale := 0.08
@export_range(0.0, 0.4, 0.01) var local_glow_tip_alpha_base := 0.05
@export_range(0.0, 0.4, 0.01) var local_glow_tip_alpha_scale := 0.08
@export_range(0.0, 0.4, 0.01) var local_glow_guard_alpha_base := 0.04
@export_range(0.0, 0.4, 0.01) var local_glow_guard_alpha_scale := 0.07
@export_range(0.0, 0.4, 0.01) var local_glow_spine_line_alpha_base := 0.08
@export_range(0.0, 0.4, 0.01) var local_glow_spine_line_alpha_scale := 0.1
@export_range(0.2, 4.0, 0.05) var local_glow_spine_line_width_base := 0.9
@export_range(0.0, 4.0, 0.05) var local_glow_spine_line_width_scale := 0.8


@export_group("回收归阵")
@export_range(0.02, 0.5, 0.01) var return_catch_duration := 0.24
@export_range(1, 24, 1) var return_catch_max_count := 8
@export_range(8.0, 80.0, 1.0) var return_catch_base_radius := 30.0
