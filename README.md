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
├── claude-plugins/           # 独立 Claude Code plugin marketplace 骨架
│   └── plugins/yuanv4-workbench/ # 承载 skills / agents / commands 的个人插件
├── rules/                    # 规则文件
├── sync.ps1                  # 同步脚本（拉取、对齐 ~/.claude、安装插件、提交、推送）
└── sync.bat                  # 以管理员权限运行 sync.ps1（需提权时使用）
```

## 配置管理

```powershell
# 完整同步：拉取远程 -> 对齐 ~/.claude -> 安装托管插件 -> 提交并推送（如有变更）
.\sync.ps1 sync

# 不带参数等同于 sync
.\sync.ps1
```

若需以管理员权限运行（如符号链接创建失败时），可双击 `sync.bat` 或在 CMD 中执行 `sync.bat`。

> 注意：脚本现在只对齐仓库根 `settings.json` 与 `rules`，并显式安装托管插件；`skills`、`agents`、`commands` 已整体迁移到 `yuanv4/yuanv4-plugin-cc`，通过 `yuanv4-workbench@yuanv-personal` 分发到各机器。

## 托管插件

当前同步脚本会显式确保以下插件已安装：

- `yuanv4-workbench@yuanv-personal`（来自 GitHub marketplace `yuanv4/yuanv4-plugin-cc`）
- `skill-creator@claude-plugins-official`
- `codex@openai-codex`

并显式登记以下 marketplaces：

- `yuanv4/yuanv4-plugin-cc`
- `anthropics/claude-plugins-official`
- `openai/codex-plugin-cc`

`codex@openai-codex` 来自 `openai/codex-plugin-cc` marketplace。首次使用前请在 Claude Code 中运行：

```text
/codex:setup
```

如果本机尚未安装 Codex CLI，按提示安装，或手动执行：

```powershell
npm install -g @openai/codex
```

> 扩展方式：在 `sync.ps1` 顶部修改 `$ManagedSyncRules`（同步哪些宿主目录）、`$SyncTargets`（同步到哪些根目录）和 `$ManagedPlugins`（显式安装哪些插件）。

## 参考

- [brianlovin/claude-config](https://github.com/brianlovin/claude-config)
- [jarrodwatts/claude-delegator](https://github.com/jarrodwatts/claude-delegator)
- [Claude Code 文档](https://docs.anthropic.com/claude-code)
