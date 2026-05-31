# 御剑大战场背景素材生成与接入方案

- 日期：`2026-05-31`
- 状态：素材方案草案，供下一步生成与接入使用
- 目标原型：`res://scenes/prototypes/YujianSpriteSequencePrototype.tscn`
- 配套方案：`docs/discussions/YUJIAN_BATTLEFIELD_BACKGROUND_JET_LANCER_PLAN_2026-05-31.md`

## 1. 总体做法

我的建议不是生成一张完整背景图，而是生成一组可循环、可调的分层素材。原因很直接：当前原型是超大战场，镜头会移动、缩放、急转；如果只铺一张完整插画，很快会出现重复、拉伸、读性脏、和角色/飞剑抢视觉的问题。

正确做法是：

1. 天空底色和轻微色带先用代码画，不生成素材。
2. AI 生成阶段统一使用纯中性灰抠图底，不要求模型直接生成透明背景。
3. 后处理阶段把灰底抠掉，导出最终运行时使用的透明 PNG 层。
4. 每层独立控制视差、透明度、速度响应和主题颜色。
5. 速度线与风带继续使用现有实现，不重新生成。
6. 第一版只做 `CloudSeaDawn` 一个主题，先验证“云海大战场 + 清晰读性”是否成立。

玩家面对的感受目标是：

**悬停时安静、有高空云海；加速时空间掠过；急转时背景退让，人物和飞剑仍然第一眼可读。**

## 2. 现有素材可复用情况

项目已有一组旧 flight 背景素材：

```text
resources/flight/background/flight_mountain_far.png   1024x150
resources/flight/background/flight_mountain_mid.png   1024x172
resources/flight/background/flight_cloud_bank.png     1024x190
resources/flight/background/flight_wind_veil.png      640x112
```

它们可以用于临时占位和风格对照，但不够支撑新版大战场：

- 尺寸偏小，横向重复感会比较明显。
- 只有山、云、风幕，没有云海边界、仙域地标、结界层。
- 原始用途更像横版飞行背景，不是现在这个更大的御剑云海战场。

因此这次应该生成一套新版目录：

```text
resources/flight/background/yujian_cloudsea_v1/
  cloudsea_far_band_01.png
  cloudsea_mid_band_01.png
  mountain_far_ink_01.png
  mountain_mid_ink_01.png
  near_cloud_wisps_atlas_01.png
  landmark_silhouettes_atlas_01.png
  boundary_rune_strip_01.png
  boundary_cloud_wall_01.png
  yujian_cloudsea_v1_layers.json
```

## 3. 素材清单

### 3.1 必需素材

| 文件 | 尺寸 | 最终透明 | 用途 | 备注 |
| --- | --- | --- | --- | --- |
| `cloudsea_far_band_01.png` | `2048x256` | 是 | 远处云海大块 | 横向可循环，低对比，放画面中下部 |
| `cloudsea_mid_band_01.png` | `2048x320` | 是 | 中景云海厚度 | 比远云稍实，但不能遮人物 |
| `mountain_far_ink_01.png` | `2048x220` | 是 | 超远/远山墨带 | 极低透明度，主要给地平线 |
| `mountain_mid_ink_01.png` | `2048x260` | 是 | 中景山/悬浮山带 | 高度变化更明显，但仍低对比 |
| `near_cloud_wisps_atlas_01.png` | `1024x512` | 是 | 近景云缕 atlas | 6-10 个独立云缕块，运行时随机取区域 |
| `landmark_silhouettes_atlas_01.png` | `1024x512` | 是 | 远景地标 atlas | 剑峰、云塔、远处阵盘、飞舟剪影 |
| `boundary_rune_strip_01.png` | `2048x128` | 是 | 边界法阵纹 | 横向可循环，靠近边界时淡入 |
| `boundary_cloud_wall_01.png` | `2048x256` | 是 | 云海边界/云墙 | 替代调试矩形边界，低速也可极淡显示 |

### 3.2 暂不生成的东西

这些先用代码或现有实现，不进第一轮素材生成：

- 天空渐变：用 `_draw_sky_wash()` 画，方便主题调色。
- 速度线：现有 `scene_speed_streaks` 已经承担。
- 3D 风带：现有 `wind_ribbon` 已经承担。
- 世界网格：只保留为 debug，不做正式美术。
- 全屏高细节插画背景：不做，会破坏视差和战斗读性。

### 3.3 可选第二轮素材

第一轮读性通过后，再考虑：

| 文件 | 尺寸 | 用途 |
| --- | --- | --- |
| `inkstorm_cloudsea_mid_01.png` | `2048x320` | Boss / Silk 压力主题云层 |
| `sunset_cloudsea_far_01.png` | `2048x256` | 夕照高速演示主题 |
| `distant_celestial_gate_01.png` | `1024x512` | 稀有远景仙门地标 |
| `soft_paper_noise_01.png` | `512x512` | 极低透明度纸纹/水墨扩散 |

## 4. 生成风格规则

所有素材必须遵守：

- AI 生成源图必须是纯中性灰背景，建议 `#808080` 或 `#7a7a7a`。
- 提示词里不要写 transparent / alpha / no background / 透明背景。
- 背景必须是纯色、平整、无渐变、无棋盘格、无纸纹、无投影，方便后处理抠图。
- 最终导入 Godot 的运行时素材才是透明 PNG。
- 美术风格走柔和水墨 2D 游戏背景，边缘可以有自然晕染和抗锯齿，不要低清硬边、颗粒化格子感或复古小图块质感。
- 无人物、无主角、无飞剑主体、无敌人、无 UI、无文字、无水印。
- 横向长条素材必须能左右循环。
- 中央战斗区留白，不能有高对比大块压在屏幕中心。
- 远山和地标只提供尺度感，不能像可碰撞平台。
- 颜色低饱和，以冷青、灰白、淡墨、少量古金为主。
- 亮度永远低于玩家飞剑、敌弹、丝线、Boss 弱点和 UI 预警色。

不要生成：

- 现代城市、跑道、飞机、机库。
- 写实厚涂云海壁纸。
- 大面积纯黑山体压住人物。
- 高饱和蓝紫霓虹。
- 大太阳/月亮/巨型建筑正贴中心。
- 粒子爆炸、闪电、战斗特效，这些应该属于 VFX 层，不属于背景层。

## 5. 具体生成提示词

### 5.1 远处云海

输出文件：`cloudsea_far_band_01.png`

```text
2D side-scrolling xianxia cloud sea background layer, 2048x256, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Long horizontal seamless cloud bank, soft ink-wash 2D game illustration style, smooth anti-aliased edges, pale gray white clouds with faint cyan shadows and very subtle warm gold light.
Low contrast, large simple shapes, clear separation from the gray background, solid gray matte background, no checkerboard pattern, no gradient background, no shadows on the background, no characters, no flying sword, no buildings, no text, no watermark.
Designed as a far parallax layer behind combat; must not distract from small player and bullets.
```

### 5.2 中景云海

输出文件：`cloudsea_mid_band_01.png`

```text
2D xianxia flying battlefield cloud-sea layer, 2048x320, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Mid-distance cloud sea layer, wider and slightly denser than far clouds, soft Chinese ink wash edges, pale cool white and gray cyan, a few broken gaps and wispy holes.
Horizontal seamless tile, low contrast, readable as cloud sea from far away, clear edges against the gray background, solid gray matte background, no checkerboard pattern, no hard platform edge, no character, no sword, no text, no watermark.
Keep the center visually calm for action readability.
```

### 5.3 远山墨带

输出文件：`mountain_far_ink_01.png`

```text
2D game background layer, 2048x220, horizontal seamless far mountain silhouette for a xianxia cloud-sea flying battlefield, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Very distant ink-wash mountains, dark desaturated blue gray, soft edges, low opacity feeling, sparse ridge highlights.
Clear separation from the gray background, solid gray matte background, no checkerboard pattern, no buildings, no characters, no moon, no sun, no text, no watermark.
The mountains should give horizon scale but never look like gameplay platforms.
```

### 5.4 中景山/悬浮山带

输出文件：`mountain_mid_ink_01.png`

```text
2D game background layer, 2048x260, horizontal seamless distant xianxia mountain band for a cloud-sea flying battlefield, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Soft mist-veiled ink-wash mountains, desaturated blue gray, pale fog covering most mountain bases, low contrast, sparse ridge hints, no black hard silhouettes.
If floating peaks appear, make them tiny, far away, soft-edged, and partly hidden by mist; they must not become dominant objects.
Clear separation from the gray background, solid gray matte background, no checkerboard pattern, no characters, no birds, no city, no combat effects, no text, no watermark.
Designed for parallax far behind a tiny fast flying sword rider; keep the center visually quiet, no high contrast landmark in the exact center, no obstacle-like platform shapes.
```

### 5.5 近景云缕 atlas

输出文件：`near_cloud_wisps_atlas_01.png`

```text
2D game asset atlas, 1024x512, containing 8 separate soft cloud wisps for a 2D xianxia flying game, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Each wisp is an elongated horizontal ink-wash cloud streak, pale gray white with faint cyan shadow, soft feathered edges, no hard outline.
Leave clear flat gray spacing between wisps for atlas cropping and matte removal.
Solid gray matte background, no checkerboard pattern, no characters, no sword, no landscape, no text, no watermark.
These wisps are foreground speed reference and must stay low contrast.
```

### 5.6 远景地标 atlas

输出文件：`landmark_silhouettes_atlas_01.png`

```text
2D game asset atlas, 1024x512, containing 8 extremely distant tiny xianxia background landmark silhouettes, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Include small far-away hints only: a tiny cloud tower shadow, a broken far array fragment, a faint immortal gate outline, a tiny flying boat silhouette, a small suspended island, a thin hanging mountain, a remote temple shadow, a distant sword-peak sliver.
Each landmark should occupy only a small part of its atlas cell, with lots of empty gray space around it. Make every landmark mist-veiled, low contrast, soft-edged, and partially faded into fog.
Do not create large centerpiece buildings, sharp foreground objects, readable icons, complete circular portals, giant gates, strong black silhouettes, bright centers, characters, text, or watermark.
They must feel like rare far background scale references, not interactable targets, not gameplay mechanisms, and not obstacles.
```

### 5.7 边界法阵条

输出文件：`boundary_rune_strip_01.png`

```text
2D game background edge asset, 2048x128, horizontal seamless distant cloud-sea barrier trace, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Very sparse broken boundary marks: faint short talisman strokes, thin interrupted arc fragments, pale cyan-white hairline scratches, a few muted gold dust lines. Most of the strip should remain empty gray background.
The marks should feel like distant residual barrier traces half-buried in mist, not a spell being cast.
No complete circles, no large magic arrays, no repeated big rings, no readable rune text, no UI frame, no skill effect burst, no bright center, no hard rectangle, no thick lines, no characters, no watermark.
Designed to fade in subtly only when player nears the battlefield edge; it must stay calmer and dimmer than player sword VFX, sword-array shapes, enemy bullets, silk lines, and Boss weakness markers.
```

### 5.8 边界云墙

输出文件：`boundary_cloud_wall_01.png`

```text
2D game background asset, 2048x256, horizontal seamless soft cloud wall for the edge of a xianxia flying battlefield, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Pale gray-white cloud mass with faint cyan underside, soft feathered top edge, clear separation from the flat gray background, low contrast.
Solid gray matte background, no checkerboard pattern, no mountain platform, no characters, no sword, no buildings, no text, no watermark.
It should read as a distant cloud-sea barrier, not a solid wall.
```

### 5.9 云下海平面水洗

输出文件：`sea_horizon_wash_01.png`

用途：放在画面中下部，给山脚一个可信的海平面/地平面承托。它不是主角，不表现真实海浪，只提供大平面和远处水汽。

```text
2D game background layer, distant calm sea horizon wash for a xianxia flying battlefield, 2048x320, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Soft watercolor ink wash, pale cyan gray sea plane, subtle horizontal depth, broad simple shapes, very low contrast, gentle atmospheric perspective, lots of quiet empty sea-air space.
The layer should make distant mountains feel grounded beyond a misty sea horizon, not floating in empty sky.
No framed panorama strip, no hard horizontal rectangular bands, no strong dark top gradient, no dominant mountain scene, no clear scenic postcard composition. The sea plane should be broad, quiet, atmospheric, and secondary to the existing mountain and cloud layers.
Solid gray matte background, no checkerboard pattern, no gradient background, no ships, no characters, no flying sword, no buildings, no text, no watermark, not realistic photo, not pixel art.
Keep it quiet enough to sit behind combat VFX, sword trails, silk lines, enemy bullets, and UI.
```

### 5.10 远岛链 / 山脚海岸线

输出文件：`far_island_chain_01.png`

用途：放在远山和海平面之间，用不连续的岛链、海岸线、低矮山脚把“山”落到“海/雾”里。

```text
2D side-scrolling xianxia background layer, distant island chain and low mountain foothills, 2048x220, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Soft ink wash style, pale blue gray and muted green gray, very low contrast, horizontal composition, sparse broken coastline, tiny far island silhouettes partly hidden by mist.
The islands should visually connect mountain bases to a sea horizon, making the mountains feel grounded and far away.
The island chain must be extremely distant, soft, broken, and partially submerged in mist. Most of the layer should remain quiet mist and empty sea-air space.
Solid gray matte background, no checkerboard pattern, no gradient background, no characters, no flying sword, no ships, no modern city, no large buildings, no text, no watermark.
Avoid continuous platform-like coastlines, walkable ledges, hard dark silhouettes, detailed waves, foreground rocks, solid land strips, readable gameplay obstacles, sharp black cliffs, or high contrast center landmarks.
```

### 5.11 山脚海雾 / 拼接遮罩

输出文件：`sea_mist_foot_01.png`

用途：覆盖远山、岛链、海平面之间的接缝。它是把层级“焊”在一起的关键素材，宁可淡，不要抢。

```text
2D game background layer, horizontal sea mist and cloud-foot veil, 2048x180, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Soft pale gray white mist, faint cyan underside, feathered ink wash edges, thin broken horizontal fog bands, very low contrast, large quiet shapes.
Designed to hide the bases of distant mountains and island chains, blending them into a calm sea horizon.
This is a thin horizontal blending veil, not a foreground cloud wall. Keep it low, soft, sparse, and semi-transparent-looking, with most detail concentrated near the mountain base line.
Solid gray matte background, no checkerboard pattern, no gradient background, no mountains as main subject, no characters, no flying sword, no buildings, no text, no watermark.
Avoid tall cloud masses, dramatic storm shapes, thick white cloud banks, hard top edges, large foreground clouds, hard platform edges, solid walls, bright centers, spell effects, or storm clouds.
```

### 5.12 海面反光短线 atlas

输出文件：`sea_shimmer_lines_atlas_01.png`

用途：下半部少量水面反光线。只做轻微空间参照，不负责速度主表现，不能像弹道或丝线。

```text
2D game asset atlas, 1024x256, containing 8 to 12 separate subtle sea shimmer line groups for a xianxia flying battlefield, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Each group is a few short broken horizontal water reflection strokes, pale cyan white and soft gray, thin and low contrast, with lots of empty gray space around each group for atlas cropping.
Very sparse placement, irregular spacing, each shimmer group should be short and calm; do not fill the atlas evenly like a pattern or motion streak sheet.
Soft ink wash anti-aliased edges, calm distant sea feeling, not bright, not sharp, not energetic.
Solid gray matte background, no checkerboard pattern, no gradient background, no characters, no flying sword, no ships, no landscape, no text, no watermark.
Avoid diagonal speed lines, bullet-like streaks, silk-line shapes, magic runes, UI marks, repeated grid patterns, or high contrast white scratches.
```

### 5.13 极远小岛 / 礁影 atlas（可选）

输出文件：`distant_sea_rocks_atlas_01.png`

用途：非常稀疏地点缀下半部空间，只在远处偶尔出现，不能常驻铺满。

```text
2D game asset atlas, 1024x512, containing 8 very small distant sea rocks or tiny island silhouettes for a xianxia cloud-sea flying background, on a flat neutral matte gray background (#808080) for chroma key cleanup.
Tiny low-contrast blue gray silhouettes, mist-veiled, soft-edged, partially faded, each occupying only a small part of its atlas cell with lots of empty gray space.
They should read as far scale references near the sea horizon, not interactable objects, not enemies, not obstacles, not platforms.
Solid gray matte background, no checkerboard pattern, no gradient background, no characters, no flying sword, no ships, no buildings, no text, no watermark.
No large centerpiece island, no sharp black cliff, no high contrast outline, no repeated obvious pattern.
```

## 6. 生成后的处理流程

每张图生成后按这个流程处理：

1. 保留 2-4 个候选，不急着覆盖运行时资源。
2. 检查是否有文字、水印、人物、飞剑、现代元素。
3. 用纯灰背景做 matte/chroma key，把灰底抠成透明 PNG。
4. 检查横向循环：至少平铺三份看接缝。
5. 降低对比和透明度，宁可偏淡，不要偏抢。
6. 放入 `resources/flight/background/yujian_cloudsea_v1/`。
7. Godot 重新导入后，再接到 `YujianSpriteSequencePrototype`。

第一轮接入可以先不做 manifest，直接 preload。稳定后再加：

```json
{
  "theme": "CloudSeaDawn",
  "layers": [
    {"path": "res://resources/flight/background/yujian_cloudsea_v1/mountain_far_ink_01.png", "parallax": [0.035, 0.01], "alpha": 0.16, "repeat_x": true},
    {"path": "res://resources/flight/background/yujian_cloudsea_v1/cloudsea_far_band_01.png", "parallax": [0.10, 0.02], "alpha": 0.18, "repeat_x": true},
    {"path": "res://resources/flight/background/yujian_cloudsea_v1/mountain_mid_ink_01.png", "parallax": [0.18, 0.03], "alpha": 0.20, "repeat_x": true},
    {"path": "res://resources/flight/background/yujian_cloudsea_v1/cloudsea_mid_band_01.png", "parallax": [0.28, 0.05], "alpha": 0.22, "repeat_x": true}
  ]
}
```

## 7. 接入方式

在 `YujianSpriteSequencePrototype` 里先走低风险路线：

1. 新增素材 preload 常量。
2. `_draw_background()` 改成：
   - `_draw_sky_wash()`
   - `_draw_texture_parallax_layer(...)`
   - `_draw_far_landmarks(...)`
   - `_draw_battlefield_boundary(...)`
   - debug 开关下才画 `_draw_world_guides()`
3. 速度线和风带保持现在逻辑。
4. `near_cloud_wisps_atlas_01.png` 先用少量固定 tile/hash 生成，不跟着急转方向硬旋转。
5. 边界素材根据玩家到 `PLAY_RECT` 的距离淡入，不常驻高亮。

第一版不要抽独立节点。等画面稳定后，再把背景抽成 `YujianBattlefieldBackground2D`，否则现在会增加调试成本。

## 8. 优先级

第一轮最少生成这 5 张就能落地：

1. `cloudsea_far_band_01.png`
2. `cloudsea_mid_band_01.png`
3. `mountain_far_ink_01.png`
4. `mountain_mid_ink_01.png`
5. `boundary_cloud_wall_01.png`

第二轮再补：

6. `boundary_rune_strip_01.png`
7. `near_cloud_wisps_atlas_01.png`
8. `landmark_silhouettes_atlas_01.png`

原因是：第一轮先建立“云海大战场”的基本空间身份；近景云缕和地标容易抢读性，应该等底层空间成立后再加。

第三轮补下半部空间承托：

9. `sea_horizon_wash_01.png`
10. `far_island_chain_01.png`
11. `sea_mist_foot_01.png`
12. `sea_shimmer_lines_atlas_01.png`
13. `distant_sea_rocks_atlas_01.png`（可选）

原因是：当前山带已经能提供横向空间，但山脚缺少海平面或地平面承托，容易读成漂浮在空中。第三轮优先把“山 - 雾 - 岛链 - 海面”焊成一个低对比远景平面，再考虑增加更丰富的地景变化。

## 9. 验收标准

素材接入后，至少检查四个状态：

- 悬停：画面应该安静，有云海和远山深度。
- 巡航：云层和山带有慢视差，角色不被吞掉。
- Boost：速度线和风带是速度主力，背景只辅助。
- 急转：背景不跟着乱甩，人物压身、飞剑弧线和短速度线最清楚。

失败信号：

- 一眼先看到背景地标，而不是角色/飞剑。
- 云缕像弹道或丝线。
- 山体像平台或墙。
- 边界像 UI 框或调试框。
- 背景颜色接近敌弹、丝线或飞剑高亮。

第一轮最终验收句：

**背景让战场变大、变高、变像云海，但不增加玩家识别成本。**

## 10. 运行后待优化项

2026-05-31 第一轮接入后，背景整体方向成立，但有三项需要分步优化：

1. **天空渐变横线分割感。**
   当前天空底层容易读成几条横向色带，破坏高空连续感。优先修正 `_draw_sky_wash()`，避免大块实色矩形和硬边透明叠层。
2. **背景循环/视差衔接跳变。**
   飞行过程中所有背景层都需要检查横向平移、图内 pan、平铺、非无缝素材边缘和 camera parallax 的衔接。目标是背景持续流动，不出现突然换图或跳一下的感觉。
   - 2026-05-31：已处理主背景层的硬切问题。原因是 2048 宽背景图使用图内 pan 时，平移到末端后通过取模直接回到开头，导致整层画面突然换段。运行时已改为镜像循环 tile，让右边缘接右边缘、左边缘接左边缘，避免非无缝素材硬切。后续如果仍有细小跳动，再检查近景云缕/地标 hash 生成和边界素材淡入淡出。
3. **下半部空间内容不足。**
   当前有山和云，但纵向空间还偏单薄。后续下半部可补大海、云下岛屿、远处陆块或悬浮岛剪影，参考 Jet Lancer 的“上部天空 / 下部地景”空间组织方式，但仍保持低对比、低信息量，不抢战斗主体。
