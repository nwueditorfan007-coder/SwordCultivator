# Yujian V4 Pixel 3D View Prototype

- 入口：`res://scenes/prototypes/YujianV4Pixel3DViewPrototype.tscn`
- 脚本：`res://scripts/prototypes/yujian_v4_pixel_3d_view_prototype.gd`
- 目标：验证“V4 小人尺度 + 正常 8 向动作视角 + 像素化 3D 场景”是否适合继续优化御剑动作表现

## 设计判断

这版不是把玩法改成全 3D。它继续继承 `YujianSpriteSequencePrototype` 的 2D 飞行输入、速度、回锋、镜头预判和大战场尺度；表现层把场景放进一个低分辨率 3D `SubViewport`，再 nearest 放大成像素化画面。

当前版本先切回正常 8 向动作视角，而不是纵向空气剖面。玩家的 `x/y` 仍然是玩法平面坐标，但在 3D 里映射到地面 `x/z` 平面；摄像机从上方斜看，方便先判断上、下、左、右和四个斜向动作是否能成立。

人物不加载项目里的 3D 模型，只使用脚本里绘制的小像素人占位。V4 原型提供的是 2D 玩法平面、`visual_heading`、速度压身、转向和上/下/斜向的语义；这些数据驱动小人的 8 向姿态、倾斜和飞剑方向，而不是只旋转整个人。

内部渲染分辨率从 `426x240` 提到 `640x360`，仍然保持 nearest 放大，但像素块更小，先解决“太糊、太粗”的判断问题。

玩家侧要验证的是：

- 小人是否仍然像 V4 一样“小而清楚”，不是贴脸动作角色
- 正常 8 向动作视角是否比纵向剖面更适合继续判断动作
- 固定俯斜动作视角是否能读出 8 个方向、敌我距离、飞剑方向和剑阵覆盖
- 像素化输出后是否接近《尘之回声》那类 3D 场景像素 ARPG，而不是糊成低模画面

## 技术形状

运行时结构：

```text
YujianV4Pixel3DViewPrototype (Node2D)
  Pixel3DWorldViewport (SubViewport, 640x360)
    Pixel3DWorldRoot (Node3D)
      V4OrthographicPixelCamera (Camera3D, orthogonal)
      ActionGroundBackdrop
      StreamingDecor
      V4SmallRider3D (drawn pixel rider placeholder, driven by V4 visual_heading)
      SwordArrayReadability (default hidden placeholder)
      ReadabilityEnemy*
  Pixel3DWorldComposite (Sprite2D, nearest upscale to 1280x720)
  inherited V4 gameplay, hidden sprite_root debug layer, 2D trail / debug / UI layers
```

2D 到 3D 的映射保持简单：

```gdscript
Vector2(x, y) -> Vector3(
    (x - FLIGHT_START_POS.x) * WORLD_TO_3D,
    0,
    (y - FLIGHT_START_POS.y) * WORLD_TO_3D
)
```

3D 相机继承 V4 的 `camera_center` 和 `camera_zoom`，换成固定俯斜正交相机。低分辨率 viewport 用 nearest 放大，先验证整体观感，不在第一版追求最终材质质量。

## 验证重点

先看视角，不看最终美术。

通过标准：

- WASD + Space 的飞行手感仍然和 V4 接近
- 人物使用脚本绘制的小像素人占位，朝向和姿态由 V4 的 8 向语义稳定驱动
- 镜头仍然是人小、场大、短预判，不晕、不贴脸
- 角色、飞剑、敌人、ring/fan/pierce 读法在像素化后仍然分得开
- 云块、山影和空中亮点能提供空间参照，但不抢战斗读法

不通过标准：

- 角色太小导致身份彻底丢失
- 3D 人物没有继承 V4 的上/下/左/右/斜向读法，只是在屏幕里平移
- 3D 场景遮挡了剑阵范围或敌人方向
- 像素化让角色、剑和敌人粘在一起
- 镜头太低或太侧，导致 8 向动作读不出来
