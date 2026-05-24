# V15 Open Source Study Assets

下载日期：2026-05-21

本目录只作为 V15 水墨剪影路线的参考素材库，不是 Godot runtime 资源目录。正式项目资源仍应放在 `resources/`，并经过重绘、归一化、命名和授权复核。

## 目录结构

```text
AI/reference_assets/V15_open_source_study/
  _repos/       GitHub 仓库浅克隆或稀疏 checkout
  _downloads/   OpenGameArt / Kenney 原始下载包
  _extracted/   zip 解压后的浏览目录
  README.md     本索引
```

## 已下载资源

| 来源 | 本地目录 | 授权判断 | 主要学习点 |
|---|---|---:|---|
| OpenDuelyst | `_repos/open-duelyst-duelyst` | CC0 | 小体量人形单位比例、攻击/待机 GIF、强剪影战斗读屏、VFX 节奏 |
| Universal LPC Spritesheet Generator | `_repos/universal-lpc-generator` | 混合授权，含 CC0/CC-BY/CC-BY-SA/GPL | 分层身体、手臂/腿/衣服/武器拆分结构；不建议直接进商用素材 |
| GDQuest game-sprites | `_repos/gdquest-game-sprites` | CC0 | 极简原型角色比例、碰撞/占位参考 |
| Game-icons | `_repos/game-icons-icons` | CC BY 3.0，部分 CC0 | HUD 图标、剑阵符号、目标/环/箭头/斩击符号参考 |
| OpenGameArt VFX | `_downloads/opengameart_*`, `_extracted/opengameart_*` | 页面标注 CC0 | 斩击、法术、命中、能量球、黑色爆炸参考 |
| Kenney packs | `_downloads/kenney_*`, `_extracted/kenney_*` | 页面标注 CC0 | 平台角色/粒子/通用原型资产参考 |

## V15 适配优先级

1. OpenDuelyst 最值得重点看：它的角色体量和你当前 `256x256` 战斗帧里的可见高度最接近，适合学习“角色小但动作强”的做法。
2. OpenGameArt VFX 适合拆解剑光、斩击、爆点的帧节奏，但需要改成水墨飞白和冷白/淡金色系。
3. LPC 适合学习拆分逻辑，不适合直接沿用比例和授权。重点看 `spritesheets/body`、`arms`、`legs`、`torso`、`weapon`。
4. Game-icons 适合法印/HUD/剑阵图形语言，不适合直接当战斗 VFX。
5. Kenney/GDQuest 更适合快速原型，不适合作为最终角色风格。

## 授权注意

- OpenDuelyst、GDQuest、Kenney、这批 OpenGameArt 页面资源可作为低风险参考或原型资产，但正式使用前仍建议保留源链接和下载日期。
- Universal LPC 是混合授权。即使部分素材是 CC0，也必须逐项查 `CREDITS.csv`；不建议把 LPC 生成结果直接放进正式发行版本。
- Game-icons 默认需要署名，部分作者目录可能是 CC0；正式使用时必须按具体 SVG 作者和 `license.txt` 做 attribution。
- 当前下载目标是学习比例、拆骨骼、动作节奏和 VFX 结构。V15 最终角色仍应重绘为水墨黑影小人。

## 源链接

- OpenDuelyst: https://github.com/open-duelyst/duelyst
- Universal LPC Spritesheet Character Generator: https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator
- GDQuest game-sprites: https://github.com/GDQuest/game-sprites
- Game-icons: https://github.com/game-icons/icons
- Kenney Pixel Platformer: https://kenney.nl/assets/pixel-platformer
- Kenney Particle Pack: https://kenney.nl/assets/particle-pack
- Kenney Platformer Art Deluxe: https://kenney.nl/assets/platformer-art-deluxe
- OpenGameArt Weapon Slash Effect: https://opengameart.org/content/weapon-slash-effect
- OpenGameArt 2D Spell Effects: https://opengameart.org/content/2d-spell-effects
- OpenGameArt Pixel Art Sword Slash Effect: https://opengameart.org/content/pixel-art-sword-slash-effect
- OpenGameArt Slash: https://opengameart.org/content/slash-0
- OpenGameArt Double Slash Animation: https://opengameart.org/content/double-slash-animation
