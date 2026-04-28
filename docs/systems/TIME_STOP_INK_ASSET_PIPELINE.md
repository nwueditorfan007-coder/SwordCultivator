# 时停水墨效果素材制作与接入指南

本文记录“御剑时停水墨化”下一阶段的美术素材需求、生成提示词、导入目录、Godot 接入原则，以及上传 GitHub 前检查清单。

## 目标效果

这套效果不是普通灰屏滤镜，而是：

- 背景像宣纸水墨画一样失色、静止、退后。
- 飞剑、剑轨、敌人目标、Boss 血条、HUD 保持清楚。
- 进入时停时有“剑意撕开画面”的破墨动态。
- 敌人和目标背后有黑墨爆点，红点/弱点从墨里亮出来。
- 持续阶段有低速墨纹和冷蓝剑意流动，但不抢读屏。

当前代码已经有程序化占位效果，但质感不够。下一步应该引入真实水墨贴图素材，替代大部分程序多边形。

## 最小素材包

先做 12 张即可，不建议一开始做太多。

```text
resources/vfx/ink/
  paper/
    paper_gray_01.png
    paper_fiber_01.png
  brush/
    brush_sweep_01.png
    brush_sweep_02.png
    brush_sweep_03.png
  blot/
    ink_blot_01.png
    ink_blot_02.png
    ink_blot_03.png
  crack/
    ink_crack_01.png
    ink_crack_02.png
  droplet/
    ink_droplets_01.png
    ink_droplets_02.png
```

### 素材优先级

1. `ink_blot_*`：敌人/目标背后的黑墨爆点，最能提升质感。
2. `brush_sweep_*`：背景大笔触，决定画面是否像水墨画。
3. `paper_*`：宣纸底纹，避免纯色灰罩。
4. `ink_crack_*`：飞剑方向破墨入场。
5. `ink_droplets_*`：入场瞬间喷溅细节。

## 规格要求

### 通用要求

- 格式：PNG。
- 色彩：灰度/黑白优先，Godot 内再调色。
- 边缘：必须自然 alpha，不能有白底硬边。
- 风格：真实水墨、宣纸纤维、干笔毛边，不要卡通烟雾，不要科幻粒子。
- 禁止：文字、水印、边框、UI、具体人物、武器、logo。

### 尺寸建议

| 类型 | 建议尺寸 | 背景 |
|---|---:|---|
| 宣纸底纹 | 2048x2048 或 4096x2048 | 可不透明 |
| 大笔刷扫痕 | 2048x512 或 1024x256 | 透明 |
| 墨团爆点 | 1024x1024 或 512x512 | 透明 |
| 裂墨长条 | 2048x512 或 1024x256 | 透明 |
| 墨滴飞溅 | 1024x1024 或 512x512 | 透明 |
| 淡墨云雾 | 1024x1024 | 透明 |
| 蓝白剑光笔触 | 2048x256 | 透明 |

## AI 生成提示词

如果使用图像生成工具，建议先做 4 张预览：宣纸、笔刷、墨爆、裂墨。确认风格后再扩展到 12 张。

### 宣纸底纹

```text
A seamless gray-white xuan paper texture for a 2D game VFX overlay, subtle rice paper fibers, uneven ink wash stains, soft grayscale, high resolution, no text, no border, no watermark, no objects, tileable texture, neutral lighting.
```

输出建议：`paper_gray_01.png`、`paper_fiber_01.png`。

### 大笔刷扫痕

```text
Transparent PNG asset, large horizontal Chinese ink brush stroke, dry brush edges, soft gray and charcoal ink, long sweeping motion, natural bristle texture, empty transparent background, no text, no frame, no watermark, suitable for 2D game VFX overlay.
```

输出建议：`brush_sweep_01.png` 到 `brush_sweep_03.png`。需要横向、斜向、弧形各一张。

### 敌人背后黑墨爆点

```text
Transparent PNG asset, explosive black ink blot for enemy target marker, circular splattered ink burst, rough dry edges, small droplets around, strong black center fading to transparent, no text, no symbols, no red color, no background, no watermark, top-down 2D game VFX decal.
```

输出建议：`ink_blot_01.png` 到 `ink_blot_03.png`。中心要留出放红点的位置。

### 飞剑破墨裂纹

```text
Transparent PNG asset, long diagonal torn ink crack, like a sword slash ripping through wet Chinese ink on paper, black ink edges with white paper tear in the center, dry brush feathering, scattered tiny droplets, no text, no background, no watermark, 2D VFX slash decal.
```

输出建议：`ink_crack_01.png`、`ink_crack_02.png`。一张细长，一张更爆裂。

### 墨滴飞溅

```text
Transparent PNG asset, scattered Chinese ink droplets and splatter particles, varied dot sizes, black and dark gray ink, natural randomness, no central object, no text, no background, no watermark, suitable for 2D game VFX particle sheet.
```

输出建议：`ink_droplets_01.png`、`ink_droplets_02.png`。

### 淡墨云雾

```text
Transparent PNG asset, soft gray ink mist cloud, subtle watercolor diffusion, low contrast, feathered edges, no smoke realism, no text, no background, no watermark, suitable for calm time-stop atmosphere overlay.
```

输出建议：后续可加 `mist/ink_mist_01.png`。

### 蓝白剑光笔触

```text
Transparent PNG asset, thin cyan-white sword energy brush stroke, elegant xianxia flying sword trail, bright white core, cyan glow, dry ink-brush edges, long diagonal slash, no text, no background, no watermark, 2D VFX overlay.
```

输出建议：后续可加 `sword/sword_streak_ink_01.png`。

## 后处理建议

AI 图通常需要二次处理：

1. 去白底或增强 alpha。
2. 裁掉空白边缘。
3. 统一灰度和对比度。
4. 导出 PNG。
5. 在 Godot 中关闭 Filter 或按效果选择 Linear。

如果素材有白底，优先处理成透明：

- 白色/浅灰区域转 alpha。
- 黑色墨迹保留 RGB 和 alpha。
- 半透明边缘保留毛边，不要硬擦。

## Godot 导入目录

最终目录建议：

```text
resources/vfx/ink/
  paper/
  brush/
  blot/
  crack/
  droplet/
  mist/
  sword/
```

导入后检查 `.import` 文件是否生成。提交 GitHub 时需要提交 PNG 和对应 `.import` 文件。

## 当前代码接入点

相关脚本：

- `scripts/system/main.gd`
  - `_trigger_time_rift_enter`：右键御剑出手时触发夜界入场。
  - `_trace_time_rift_sword`：持续把飞剑屏幕位置传给特效。
  - `_build_time_rift_freeze_markers`：把敌人、Boss、弹幕转成冻结标记。
- `scripts/vfx/time_rift_fx.gd`
  - 运行时驱动层，只负责阶段、位置、方向、强度和池化标记。
  - 不再保留旧版 `BackBuffer + time_rift_screen.gdshader + Line2D` 裂隙系统。
- `scenes/vfx/TimeStopDomainArt.tscn`
  - 正式节点化美术层，承载宣纸、笔刷、墨斑、裂墨、剑光、粒子和 AnimationPlayer。

素材接入时，优先替换 `TimeStopDomainArt.tscn` 里的贴图节点：

- `brush_sweep_*` 用于 `BackgroundBrush`。
- `ink_blot_*` 用于 `TargetLayer` 和运行时冻结标记池。
- `ink_crack_*` 用于 `EntryLayer/Crack*`。
- `ink_droplets_*` 用于入场喷溅贴片或粒子贴图。

## 参数调试建议

优先在 `TimeRiftFx` 节点和 `TimeStopDomainArt.tscn` 中调：

1. `TimeRiftFx/冻结标记强度`
2. `TimeRiftFx/剑光放射强度`
3. `resources/vfx/time_rift_profile_default.tres` 的进入和恢复时长
4. `TimeStopDomainArt.tscn` 中 `Crack*`、`Streak*`、`BackgroundBrush` 的贴图和初始调色

推荐目标：

- 背景像灰白宣纸，不像蓝灰玻璃罩。
- 网格只能隐约存在，不能抢过水墨笔触。
- 怪物不失色，但背后有黑墨重量。
- 飞剑轨迹比背景亮两个层级。
- Boss 血条、生命、剑意等 UI 完全不受水墨影响。

## GitHub 上传前检查清单

### 清理

上传前建议不要提交这些目录：

```text
.godot/
.codex/
.codex_tmp/
dist/
```

如果需要保留导出包，单独建 release，不要塞进源码主分支。

### 查看状态

```powershell
git status --short
```

重点确认：

- 新增素材 PNG 已在 `resources/vfx/ink/`。
- Godot 自动生成的 `.import` 文件也在。
- 不要误提交临时截图、日志、缓存。

### 运行校验

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start_godot_with_log.ps1 -Mode run -Headless -Wait -ExtraArgs '--quit-after','2'
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\show_godot_errors.ps1
```

日志应显示没有明显错误。

### 提交建议

```powershell
git add README.md docs/systems/TIME_STOP_INK_ASSET_PIPELINE.md docs/mockups/time_stop_ink_layering_plan.svg scripts/system/main.gd scripts/system/game_renderer.gd scripts/system/game_boss_controller.gd scripts/system/game_state_factory.gd resources/vfx/time_stop_ink_wash.gdshader

git commit -m "Improve time stop ink wash VFX layering"
```

如果已经加入素材，再额外 add：

```powershell
git add resources/vfx/ink
```

### 首次上传到 GitHub

如果本地还没有远端：

```powershell
git remote add origin https://github.com/<your-name>/<repo-name>.git
git push -u origin main
```

如果已有远端：

```powershell
git remote -v
git push
```

## 下一步计划

1. 先制作 4 张预览素材：`paper_gray_01`、`brush_sweep_01`、`ink_blot_01`、`ink_crack_01`。
2. 导入 Godot 后，先替换敌人墨斑和破墨裂纹。
3. 确认质感后扩展完整 12 张素材包。
4. 最后再做时停持续阶段的低速墨纹流动。
