# Yujian 3D To 2D Flight Prototype

- Prototype entry: `res://scenes/prototypes/YujianSpriteSequence3DModelPrototype.tscn`
- Pose editor entry: `res://scenes/prototypes/YujianModelPoseEditorPrototype.tscn`
- Base movement/VFX: inherits `res://scripts/prototypes/yujian_sprite_sequence_prototype.gd`
- 3D-to-2D visual node: `res://scripts/prototypes/yujian_model_to_2d_flight_visual.gd`
- Default model: `res://resources/modle/000_男主角/000_Nanzhujue_LOD.FBX`
- Pose JSON: `res://resources/flight/yujian_3d_model_pose_overrides.json`

## Goal

This prototype keeps the current `YujianSpriteSequencePrototype` flight feel intact and only replaces the character visual source.

The inherited prototype still owns:

- `target_heading / body_heading / velocity`
- camera look-ahead and zoom
- boost, carve, hard-turn clip requests
- wind, fog, trail, and direction-switch arc VFX

Sheet-based character afterimages are not inherited in this prototype because the model visual uses the procedural V4 branch rather than a frame sheet. This keeps the first validation focused on character scale, framing, and pose readability.

The new model visual only receives the same presentation parameters used by V4/V5:

- visual heading
- velocity
- boost energy
- turn energy
- carve energy
- throttle energy
- explicit turn/carve/switch context from the outer prototype

## Runtime Shape

The model visual renders the current male protagonist FBX through an internal `SubViewport`.
The result is displayed as a `Sprite2D` inside the existing Node2D flight prototype.

This is deliberately not a full 3D gameplay mode. The 3D scene is only a hidden pose source for a 2D flight read.

## Current Pose Strategy

The current pass maps the V4 skeleton prototype's flight semantics onto the 3D model:

- `fast_pose` uses the same speed-driven formula as V4, including boost/throttle contribution
- low-speed cruise keeps a more upright sword-riding read
- high-speed boost pushes the torso and model root forward, with arms, legs, hair, sleeves, robe, and ribbons trailing
- carve/switch context banks the whole visual and adds asymmetric limb pressure
- the glowing sword has its own heading pivot, so it stays as the foot contact axis instead of being dragged by the body lean
- the model keeps a screen-upright 3/4 read for the default right-facing flight pose, closer to the V4 prototype's readable rider silhouette
- if a `Skeleton3D` is found, biped, hair, sleeve, robe, and ribbon bones receive additive pose offsets
- the internal camera uses a conservative fixed overscan frame, because skinned mesh deformation can extend outside the static mesh AABB
- runtime bounds are kept only as debug telemetry; they no longer drive camera size

This lets the prototype validate the character replacement without waiting for final authored animation clips.

## Validation Captures

`res://tools/capture_yujian_3d_model_prototype.gd` writes:

- `res://artifacts/yujian_3d_model_prototype_capture.png`
- `res://artifacts/yujian_3d_model_subviewport.png`
- `res://artifacts/yujian_3d_model_states/01_cruise_right.png`
- `res://artifacts/yujian_3d_model_states/02_boost_right.png`
- `res://artifacts/yujian_3d_model_states/03_boost_up_right_carve.png`

The fixed state captures are used to check both V4-style pose separation and edge margins.
The script fails if any model subviewport capture has no visible alpha pixels or if the closest alpha pixel is below the configured minimum edge margin.

## Pose Editor

`YujianModelPoseEditorPrototype` is an in-project runtime editor for posing the current 3D model without Blender or Maya.

It instantiates the same `yujian_model_to_2d_flight_visual.gd` node, switches it into manual pose mode, and exposes:

- pose slots: `yujian_low`, `yujian_boost`, `yujian_turn_left`, `yujian_turn_right`
- all model skeleton bones, with core Biped bones sorted first
- per-bone X/Y/Z rotation controls
- reset selected bone, clear current pose, reload, and save

The editor writes JSON arrays in degrees. The visual node can receive these rotations through `set_manual_bone_pose_degrees(...)`, which resets the skeleton to rest pose before applying the selected manual pose. This is intentionally separate from the old procedural bone offsets, because direct scripted offsets caused folded character poses on this FBX.
