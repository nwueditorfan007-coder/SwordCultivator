# SwordCultivator

一个以 Godot 为主的修仙题材动作项目原型，当前仓库包含主游戏工程、战斗/剑阵系统脚本、设计文档，以及一个独立的前端原型目录 `sword-cultivator_-dual-path/`。

## 目录说明

- `project.godot`: Godot 主工程入口
- `scenes/`: 场景资源
- `scripts/`: 核心游戏逻辑脚本
- `docs/`: 设计、评审、系统说明与内部进度文档
- `resources/`: 调试和运行时资源
- `sword-cultivator_-dual-path/`: Web 方向原型

## 分支约定

- `main`: 稳定可回看的主分支
- `dev`: 日常开发分支

功能开发建议从 `dev` 拉新分支，例如：

```bash
git checkout dev
git checkout -b feature/sword-array-tuning
```

## 文档入口

优先阅读 `docs/project/`、`docs/decisions/` 与 `docs/systems/`。
