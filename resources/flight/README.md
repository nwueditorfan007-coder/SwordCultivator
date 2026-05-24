# Flight Asset Intake

Use this folder for FrameRonin-generated or FrameRonin-processed flight assets.

## Rider

Runtime layered paths:

- V10 body runtime: `res://resources/flight/rider/flight_rider_body_v10_sheet.png`
- V10 body transitions: `res://resources/flight/rider/flight_rider_body_v10_transitions.png`
- V9 fallback: `res://resources/flight/rider/flight_rider_body_v9_sheet.png`
- `res://resources/flight/rider/flight_rider_weapon_v3_sheet.png`
- `res://resources/flight/rider/flight_rider_mount_v3_sheet.png`

Legacy single-sheet path:

- `res://resources/flight/rider/flight_rider_ink_sheet.png`

Layered sheet contract:

- V10 body sheet: `2048 x 2816`, `8 columns x 11 rows`, `256 x 256` per frame
- V10 transition sheet: `2048 x 3584`, `8 columns x 14 rows`, `256 x 256` per frame
- weapon/mount sheets: `1536 x 1120`, `8 columns x 7 rows`, `192 x 160` per frame
- transparent PNG
- body sheets use the same frame index, anchor, and facing direction
- weapon and mount still use the legacy 7-row row mapping through `FlightRiderSpriteFx`
- body sheet should not include handheld swords or the flying mount platform
- weapon sheet should not include the body or large formation VFX
- mount sheet should not include the body, handheld sword, or long wind trails

V10 body rows:

1. `idle`
2. `forward`
3. `back`
4. `parry`
5. `sword_control_idle`
6. `array_ring_idle`
7. `array_fan_idle`
8. `array_pierce_idle`
9. `array_ring_release`
10. `array_fan_release`
11. `array_pierce_release`

V10 transition rows:

1. `idle_to_sword_control`
2. `sword_control_to_idle`
3. `idle_to_array_ring`
4. `array_ring_to_idle`
5. `idle_to_array_fan`
6. `array_fan_to_idle`
7. `idle_to_array_pierce`
8. `array_pierce_to_idle`
9. `array_ring_to_fan`
10. `array_fan_to_ring`
11. `array_fan_to_pierce`
12. `array_pierce_to_fan`
13. `array_pierce_to_ring`
14. `array_ring_to_pierce`

Playback state model:

- `sword_control_idle` is a sustained right-mouse sword-control state, not a one-shot unsheath row.
- `array_ring_idle`, `array_fan_idle`, and `array_pierce_idle` are sustained array states. They should hold a clear posture with slow, tiny variation: ring as embrace/guard, fan as opened-arm control, and pierce as pointing/line intent.
- `array_*_release` rows are short pulses. After the timed action ends, the rider returns to the current sustained array idle.
- `array_*_to_*` transition rows only play when the dominant array mode changes.

`FlightRiderSpriteFx` exposes `body_sheet`, `body_transition_sheet`, `weapon_sheet`, `mount_sheet`, `frame_size`, `frame_count`, and `use_pixel_filter`, so alternate FrameRonin sheets can be tested from the scene inspector as long as their rows keep this order.

## Rider V9 Body Source Layout

The V10 runtime atlases were recombined from these V9 source strips. Keep the source files for future repair passes, but the runtime contract is now the V10 row layout above.

Recommended source files:

- `res://resources/flight/rider/body_v9_sources/body_v9_master_reference.png`
- `res://resources/flight/rider/body_v9_sources/body_v9_main_idle_8.png`
- `res://resources/flight/rider/body_v9_sources/body_v9_main_forward_8.png`
- `res://resources/flight/rider/body_v9_sources/body_v9_main_back_8.png`
- `res://resources/flight/rider/body_v9_sources/body_v9_main_parry_8.png`
- `res://resources/flight/rider/body_v9_sources/body_v9_main_unsheath_8.png`
- `res://resources/flight/rider/body_v9_sources/body_v9_main_array_release_8.png`
- `res://resources/flight/rider/body_v9_sources/body_v9_main_array_morph_8.png`
- `res://resources/flight/rider/body_v9_transitions/body_v9_transition_*_8.png`

Validation for the current V10 runtime pass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_flight_rider_body_assets.ps1 -MainSheet resources/flight/rider/flight_rider_body_v10_sheet.png -TransitionSheet resources/flight/rider/flight_rider_body_v10_transitions.png
```

## Background

Runtime paths:

- `res://resources/flight/background/flight_mountain_far.png` (`1024 x 150`)
- `res://resources/flight/background/flight_mountain_mid.png` (`1024 x 172`)
- `res://resources/flight/background/flight_cloud_bank.png` (`1024 x 190`)
- `res://resources/flight/background/flight_wind_veil.png` (`640 x 112`)

Keep these as separate transparent layers. The renderer scrolls them at different speeds for parallax.

## FrameRonin Cleanup Pass

1. Generate the raw character or layer.
2. Remove watermark if present.
3. Matte to transparent background.
4. Hard resize with nearest-neighbor only.
5. Check rows/columns in Sprite Sheet preview.
6. Recombine and export PNG.
