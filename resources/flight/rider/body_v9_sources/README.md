# Rider Body V9 Sources

Production source strips for the V9 rider body pass live here.

Expected files:

- `body_v9_master_reference.png`
- `body_v9_main_idle_8.png`
- `body_v9_main_forward_8.png`
- `body_v9_main_back_8.png`
- `body_v9_main_parry_8.png`
- `body_v9_main_sword_control_idle_8.png`
- `body_v9_main_array_ring_idle_8.png`
- `body_v9_main_array_fan_idle_8.png`
- `body_v9_main_array_pierce_idle_8.png`
- `body_v9_main_array_release_pulse_8.png`

Each main strip is `2048 x 256`, `8 columns x 1 row`, `256 x 256` per frame, transparent PNG.

The old `unsheath`, `array_release`, and `array_morph` strips can remain as source-library material, but they should be recomposed into the sustained rows above before becoming runtime rows.

Only the recombined runtime sheet belongs at `resources/flight/rider/flight_rider_body_v9_sheet.png`.
