# Yujian 8-Way Cruise Direction Prompts

Accepted outputs:

- `01_right.png`
- `02_up_right.png`
- `03_up.png`
- `05_left.png`
- `07_down.png`
- `08_down_right.png`

Candidate-only directions awaiting accepted output:

- `04_up_left.png`
- `06_down_left.png`

Reference inputs:

- Character master: `G:/SwordCultivator/resources/flight/Gemini_Generated_Image_193qyk193qyk193q.png`
- 01 RIGHT camera reference: `G:/SwordCultivator/docs/mockups/nanzhujue_8way_reference_from_model/01_right.png`
- 02 UP_RIGHT camera reference: `G:/SwordCultivator/docs/mockups/nanzhujue_8way_reference_from_model/02_up_right.png`
- 03 UP camera reference: `G:/SwordCultivator/docs/mockups/nanzhujue_8way_reference_from_model/03_up.png`
- 04 UP_LEFT camera reference: `G:/SwordCultivator/docs/mockups/nanzhujue_8way_reference_from_model/04_up_left.png`
- 05 LEFT camera reference: `G:/SwordCultivator/docs/mockups/nanzhujue_8way_reference_from_model/05_left.png`
- 06 DOWN_LEFT camera reference: `G:/SwordCultivator/docs/mockups/nanzhujue_8way_reference_from_model/06_down_left.png`
- 07 DOWN camera reference: `G:/SwordCultivator/docs/mockups/nanzhujue_8way_reference_from_model/07_down.png`
- 08 DOWN_RIGHT camera reference: `G:/SwordCultivator/docs/mockups/nanzhujue_8way_reference_from_model/08_down_right.png`

## 01 RIGHT

```text
Single full-body 2D game character, direction 01 RIGHT.

Use the reference character as strict identity: black ink wuxia male, dark faceless face, black-gray robe, wide sleeves, sash, layered robe panels, boots, top bun, very long flowing black hair. Preserve costume, silhouette, ink-wash style, grayscale palette, hair direction details, and asymmetrical character design. Do not mirror-flip any left-facing output.

View: fixed orthographic 2.5D game sprite camera, mid-high side-right view, matching the RIGHT reference. The character is flying straight toward the right side of the screen. This direction must feel like the exact midpoint between the accepted UP_RIGHT back-right cruise pose and the accepted DOWN_RIGHT front-right cruise pose, not a separate standing side illustration.

The viewer should see the crown of the head and hair bun slightly from above, a narrow right-side body silhouette, compressed shoulders, layered robe panels, and short foreshortened legs. Keep the same yujian cruise posture family as the accepted diagonal outputs: compact body, lowered center of gravity, and feet arranged on the invisible flight axis. Do not make the character tall, upright, walking, running, posing, or facing the camera.

Direction lock: flight direction is exactly horizontal screen-right. The invisible flying sword axis, head, torso, hips, robe flow, and feet align along a clean left-to-right horizontal line. Do not make it upper-right, lower-right, up, down, or front-facing.

Pose: yujian cruise pose, standing on an invisible narrow flying sword. Do not draw the sword. Feet staggered front-back along the rightward horizontal flight axis, knees slightly bent, lowered center of gravity, torso leaning subtly into the rightward flight direction. Arms asymmetrical for balance: one hand low forward pressing air, the other pulled slightly back near body. Match the action rhythm and balance language of the accepted diagonal cruise sprites. Not A-pose, not T-pose, not idle.

Motion: hair, sleeves, robe hems, ribbons stream backward toward the left of the image, opposite the rightward travel direction.

Neutral gray background, centered, full body visible. No sword, weapon, platform, VFX, trail, text, watermark.
```

## 03 UP

```text
Single full-body 2D game character, direction 03 UP.

Use the reference character as strict identity: black ink wuxia male, dark faceless face, black-gray robe, wide sleeves, sash, layered robe panels, boots, top bun, very long flowing black hair. Preserve costume, silhouette, ink-wash style, and grayscale palette.

View: fixed orthographic 2.5D game sprite camera, high top-down back view. The camera is almost above the character, looking steeply downward, with only a slight back-side bias. This is a top-down game character view, not a rear character illustration.

The character is flying straight upward away from the camera. The viewer mainly sees the crown of the head, hair bun from above, top planes of shoulders, upper back, and the back surface of the robe compressed by perspective. The torso and robe should look foreshortened and compact, not tall. Legs and feet should be very short, small, and partly hidden under the robe.

Do not show a long full-height back silhouette. Do not draw an eye-level rear view. Do not draw a normal standing back portrait. Do not use a cinematic rear angle. The image should feel like a small top-down action RPG sprite viewed from above.

Direction lock: flight direction is exactly vertical screen-up, not upper-right and not upper-left. Head, torso, hips, robe, and feet align around the image vertical centerline. No diagonal body axis, no 3/4 right-back view, no yaw toward the right.

Pose: yujian cruise pose, standing on an invisible narrow flying sword. Do not draw the sword. Feet staggered front-back on the vertical centerline, knees slightly bent, lowered center of gravity, torso leaning subtly into the straight-up flight direction. Arms asymmetrical for balance: one hand low forward pressing air, the other pulled slightly back near body. Not A-pose, not T-pose, not idle.

Motion: hair, sleeves, robe hems, ribbons stream backward toward bottom of image, centered around the vertical axis.

Neutral gray background, centered, full body visible. No sword, weapon, platform, VFX, trail, text, watermark.
```

## 05 LEFT

```text
Single full-body 2D game character, direction 05 LEFT.

Use the reference character as strict identity: black ink wuxia male, dark faceless face, black-gray robe, wide sleeves, sash, layered robe panels, boots, top bun, very long flowing black hair. Preserve costume, silhouette, ink-wash style, grayscale palette, hair direction details, and asymmetrical character design. Do not mirror-flip the right-facing output.

View: fixed orthographic 2.5D game sprite camera, mid-high side-left view, matching the LEFT reference. The character is flying straight toward the left side of the screen. This direction must feel like the exact midpoint between the UP_LEFT back-left cruise pose and the DOWN_LEFT front-left cruise pose, not a separate standing side illustration.

The viewer should see the crown of the head and hair bun slightly from above, a narrow left-side body silhouette, compressed shoulders, layered robe panels, and short foreshortened legs. Keep the same yujian cruise posture family as the accepted right-side diagonal outputs and the left diagonal prompt targets: compact body, lowered center of gravity, and feet arranged on the invisible flight axis. Do not make the character tall, upright, walking, running, posing, or facing the camera.

Direction lock: flight direction is exactly horizontal screen-left. The invisible flying sword axis, head, torso, hips, robe flow, and feet align along a clean right-to-left horizontal line. Do not make it upper-left, lower-left, up, down, or front-facing.

Pose: yujian cruise pose, standing on an invisible narrow flying sword. Do not draw the sword. Feet staggered front-back along the leftward horizontal flight axis, knees slightly bent, lowered center of gravity, torso leaning subtly into the leftward flight direction. Arms asymmetrical for balance: one hand low forward pressing air, the other pulled slightly back near body. Match the action rhythm and balance language of the other cruise-direction sprites. Not A-pose, not T-pose, not idle.

Motion: hair, sleeves, robe hems, ribbons stream backward toward the right of the image, opposite the leftward travel direction.

Neutral gray background, centered, full body visible. No sword, weapon, platform, VFX, trail, text, watermark.
```

## 07 DOWN

```text
Single full-body 2D game character, direction 07 DOWN.

Use the reference character as strict identity: black ink wuxia male, dark faceless face, black-gray robe, wide sleeves, sash, layered robe panels, boots, top bun, very long flowing black hair. Preserve costume, silhouette, ink-wash style, and grayscale palette.

View: fixed orthographic 2.5D high-angle top-down front view. Flying downward toward camera. Show top of head, bun, forehead/hair mass, shoulders from above, chest/robe front from above, shortened lower body.

Pose: yujian cruise pose, standing on an invisible narrow flying sword. Do not draw the sword. Feet staggered front-back along flight direction, knees slightly bent, lowered center of gravity, torso leaning subtly forward. Arms asymmetrical: one hand low forward pressing air, the other pulled slightly back near body. Not A-pose, not T-pose, not idle.

Motion: hair, sleeves, robe hems, ribbons stream backward toward top of image.

Neutral gray background, centered, full body visible. No sword, weapon, platform, VFX, trail, text, watermark.
```

## 02 UP_RIGHT

```text
Single full-body 2D game character, direction 02 UP_RIGHT.

Use the reference character as strict identity: black ink wuxia male, dark faceless face, black-gray robe, wide sleeves, sash, layered robe panels, boots, top bun, very long flowing black hair. Preserve costume, silhouette, ink-wash style, grayscale palette, hair direction details, and asymmetrical character design. Do not mirror-flip the character.

View: fixed orthographic 2.5D game sprite camera, high top-down 3/4 back-right view, matching the UP_RIGHT reference. The character is flying diagonally toward the upper-right of the screen, away from the camera. This is between the accepted UP back view and the RIGHT side view, with a stronger top-down game-sprite camera than a normal illustration.

The viewer should see the crown of the head and hair bun from above, top planes of shoulders, upper back, part of the right-side silhouette, and robe compressed by perspective. The face and chest should be hidden or almost hidden. Legs and feet are short, small, and partly hidden under the robe due to high camera angle.

Direction lock: flight direction is exactly diagonal screen upper-right. The invisible flying sword axis, head, torso, hips, robe flow, and feet align along a 45-degree upper-right line. Do not make it straight up, straight right, or upper-left. No front-facing chest view.

Pose: yujian cruise pose, standing on an invisible narrow flying sword. Do not draw the sword. Feet staggered front-back along the upper-right flight axis, knees slightly bent, lowered center of gravity, torso leaning subtly into the upper-right flight direction. Arms asymmetrical for balance: one hand low forward pressing air, the other pulled slightly back near body. Not A-pose, not T-pose, not idle.

Motion: hair, sleeves, robe hems, ribbons stream backward toward the lower-left of the image, opposite the upper-right travel direction.

Neutral gray background, centered, full body visible. No sword, weapon, platform, VFX, trail, text, watermark.
```

## 08 DOWN_RIGHT

```text
Single full-body 2D game character, direction 08 DOWN_RIGHT.

Use the reference character as strict identity: black ink wuxia male, dark faceless face, black-gray robe, wide sleeves, sash, layered robe panels, boots, top bun, very long flowing black hair. Preserve costume, silhouette, ink-wash style, grayscale palette, hair direction details, and asymmetrical character design. Do not mirror-flip the character.

View: fixed orthographic 2.5D game sprite camera, high top-down 3/4 front-right view, matching the DOWN_RIGHT reference. The character is flying diagonally toward the lower-right of the screen, toward the camera. This is between the accepted DOWN front view and the RIGHT side view, with a clear top-down game-sprite camera.

The viewer should see the crown of the head and hair bun from above, forehead/hair mass, shoulders from above, chest and robe front from above, plus part of the right-side silhouette. The lower body should be shortened by perspective. Legs and feet are small and compressed, not tall.

Direction lock: flight direction is exactly diagonal screen lower-right. The invisible flying sword axis, head, torso, hips, robe flow, and feet align along a 45-degree lower-right line. Do not make it straight down, straight right, or lower-left. Do not make it a flat front portrait.

Pose: yujian cruise pose, standing on an invisible narrow flying sword. Do not draw the sword. Feet staggered front-back along the lower-right flight axis, knees slightly bent, lowered center of gravity, torso leaning subtly into the lower-right flight direction. Arms asymmetrical for balance: one hand low forward pressing air, the other pulled slightly back near body. Not A-pose, not T-pose, not idle.

Motion: hair, sleeves, robe hems, ribbons stream backward toward the upper-left of the image, opposite the lower-right travel direction.

Neutral gray background, centered, full body visible. No sword, weapon, platform, VFX, trail, text, watermark.
```

## 04 UP_LEFT

```text
Single full-body 2D game character, direction 04 UP_LEFT.

Use the reference character as strict identity: black ink wuxia male, dark faceless face, black-gray robe, wide sleeves, sash, layered robe panels, boots, top bun, very long flowing black hair. Preserve costume, silhouette, ink-wash style, grayscale palette, hair direction details, and asymmetrical character design. Do not mirror-flip the right-facing output.

View: fixed orthographic 2.5D game sprite camera, high top-down 3/4 back-left view, matching the UP_LEFT reference. The character is flying diagonally toward the upper-left of the screen, away from the camera. This is between the accepted UP back view and the LEFT side view, with a clear top-down game-sprite camera.

The viewer should see the crown of the head and hair bun from above, top planes of shoulders, upper back, part of the left-side silhouette, and robe compressed by perspective. The face and chest should be hidden or almost hidden. Legs and feet are short, small, and partly hidden under the robe due to high camera angle.

Direction lock: flight direction is exactly diagonal screen upper-left. The invisible flying sword axis, head, torso, hips, robe flow, and feet align along a 45-degree upper-left line. Do not make it straight up, straight left, upper-right, or a mirrored right-facing image. No front-facing chest view.

Pose: yujian cruise pose, standing on an invisible narrow flying sword. Do not draw the sword. Feet staggered front-back along the upper-left flight axis, knees slightly bent, lowered center of gravity, torso leaning subtly into the upper-left flight direction. Arms asymmetrical for balance: one hand low forward pressing air, the other pulled slightly back near body. Not A-pose, not T-pose, not idle.

Motion: hair, sleeves, robe hems, ribbons stream backward toward the lower-right of the image, opposite the upper-left travel direction.

Neutral gray background, centered, full body visible. No sword, weapon, platform, VFX, trail, text, watermark.
```

## 06 DOWN_LEFT

```text
Single full-body 2D game character, direction 06 DOWN_LEFT.

Use the reference character as strict identity: black ink wuxia male, dark faceless face, black-gray robe, wide sleeves, sash, layered robe panels, boots, top bun, very long flowing black hair. Preserve costume, silhouette, ink-wash style, grayscale palette, hair direction details, and asymmetrical character design. Do not mirror-flip the right-facing output.

View: fixed orthographic 2.5D game sprite camera, high top-down 3/4 front-left view, matching the DOWN_LEFT reference. The character is flying diagonally toward the lower-left of the screen, toward the camera. This is between the accepted DOWN front view and the LEFT side view, with a clear top-down game-sprite camera.

The viewer should see the crown of the head and hair bun from above, forehead/hair mass, shoulders from above, chest and robe front from above, plus part of the left-side silhouette. The lower body should be shortened by perspective. Legs and feet are small and compressed, not tall.

Direction lock: flight direction is exactly diagonal screen lower-left. The invisible flying sword axis, head, torso, hips, robe flow, and feet align along a 45-degree lower-left line. Do not make it straight down, straight left, lower-right, or a mirrored right-facing image. Do not make it a flat front portrait.

Pose: yujian cruise pose, standing on an invisible narrow flying sword. Do not draw the sword. Feet staggered front-back along the lower-left flight axis, knees slightly bent, lowered center of gravity, torso leaning subtly into the lower-left flight direction. Arms asymmetrical for balance: one hand low forward pressing air, the other pulled slightly back near body. Not A-pose, not T-pose, not idle.

Motion: hair, sleeves, robe hems, ribbons stream backward toward the upper-right of the image, opposite the lower-left travel direction.

Neutral gray background, centered, full body visible. No sword, weapon, platform, VFX, trail, text, watermark.
```
