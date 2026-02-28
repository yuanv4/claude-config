# claude-config

我的 Claude 配置同步仓库。

## 快速开始

```powershell
git clone https://github.com/yuanv4/claude-config.git
cd claude-config
.\sync.ps1 sync
```

## 目录结构

```
claude-config/
├── skills/             # 技能（子目录含 SKILL.md，如 commit、docx、pdf 等）
├── rules/              # 规则文件
├── agents/             # 子代理定义
├── commands/           # 命令定义
├── tests/              # Bats 测试
├── sync.ps1            # 同步脚本（拉取、对齐 ~/.claude、提交、推送）
└── sync.bat            # 以管理员权限运行 sync.ps1（需提权时使用）
```

## 配置管理

```powershell
# 完整同步：拉取远程 -> 对齐 ~/.claude -> 提交并推送（如有变更）
.\sync.ps1 sync

# 不带参数等同于 sync
.\sync.ps1
```

若需以管理员权限运行（如符号链接创建失败时），可双击 `sync.bat` 或在 CMD 中执行 `sync.bat`。

> 注意：脚本会对齐 `skills`、`agents`、`rules`、`commands`。

> 扩展方式：在 `sync.ps1` 顶部修改 `$ManagedSyncRules`（同步哪些目录）和 `$SyncTargets`（同步到哪些根目录）。

## 参考

- [brianlovin/claude-config](https://github.com/brianlovin/claude-config)
- [Claude Code 文档](https://docs.anthropic.com/claude-code)
