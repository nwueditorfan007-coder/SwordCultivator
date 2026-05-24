# Rider Body V9 Transitions

Transition source strips for the V9 rider body pass live here. These are production sources only; current runtime code does not read them.

Corrected state-machine coverage:

- `body_v9_transition_array_ring_to_fan_8.png`
- `body_v9_transition_array_fan_to_ring_8.png`
- `body_v9_transition_array_fan_to_pierce_8.png`
- `body_v9_transition_array_pierce_to_fan_8.png`
- `body_v9_transition_array_pierce_to_ring_8.png`
- `body_v9_transition_array_ring_to_pierce_8.png`
- `body_v9_transition_idle_to_sword_control_8.png`
- `body_v9_transition_sword_control_to_idle_8.png`
- `body_v9_transition_idle_to_array_ring_8.png`
- `body_v9_transition_array_ring_to_idle_8.png`
- `body_v9_transition_idle_to_array_fan_8.png`
- `body_v9_transition_array_fan_to_idle_8.png`
- `body_v9_transition_idle_to_array_pierce_8.png`
- `body_v9_transition_array_pierce_to_idle_8.png`
- `body_v9_transition_array_ring_to_release_8.png`
- `body_v9_transition_array_release_to_ring_8.png`
- `body_v9_transition_array_fan_to_release_8.png`
- `body_v9_transition_array_release_to_fan_8.png`
- `body_v9_transition_array_pierce_to_release_8.png`
- `body_v9_transition_array_release_to_pierce_8.png`

Optional locomotion polish:

- `body_v9_transition_idle_to_forward_8.png`
- `body_v9_transition_forward_to_idle_8.png`
- `body_v9_transition_idle_to_back_8.png`
- `body_v9_transition_back_to_idle_8.png`
- `body_v9_transition_forward_to_back_8.png`
- `body_v9_transition_back_to_forward_8.png`

Each transition strip is `2048 x 256`, `8 columns x 1 row`, `256 x 256` per frame, transparent PNG.

The previous generic `array_morph` transition list is obsolete for the current gameplay target. Array body animation should be organized around sustained `array_ring_idle`, `array_fan_idle`, and `array_pierce_idle` loops, with directed form transitions between them.

Validate after export:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_flight_rider_body_assets.ps1 -MainSheet resources/flight/rider/flight_rider_body_v9_sheet.png -TransitionDir resources/flight/rider/body_v9_transitions
```
