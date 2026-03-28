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

## Godot 报错协作

最简单的用法：

1. 直接双击根目录的 `START_GODOT.cmd`
2. 它会自动打开 Godot，并额外弹出一个错误监视窗口
3. 如果游戏里报错了，你只需要对 Codex 说一句：`看一下 Godot 日志`

如果你想自己看最近的错误，直接双击根目录的 `SHOW_GODOT_ERRORS.cmd`。

如果你希望 Codex 更快定位 Godot 报错，也可以手动用仓库里的启动脚本打开项目：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\start_godot_with_log.ps1
```

这个脚本会自动读取 `.vscode/settings.json` 里的 Godot 路径，并把日志写到 `.codex/godot/latest.log`。

报错后你只需要说一句：

```text
看一下 Godot 日志
```

如果你自己也想盯着错误输出，可以再开一个终端运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\show_godot_errors.ps1 -Watch
```

常用参数：

```powershell
# 直接运行游戏而不是打开编辑器
powershell -ExecutionPolicy Bypass -File .\tools\start_godot_with_log.ps1 -Mode run

# 启动后等待 Godot 退出，再把退出码回传到终端
powershell -ExecutionPolicy Bypass -File .\tools\start_godot_with_log.ps1 -Wait
```
