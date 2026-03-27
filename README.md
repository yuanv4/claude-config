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
├── skills/                   # 技能（子目录含 SKILL.md）
│   ├── claudemd/             # CLAUDE.md 初始化与维护
│   ├── docx/                 # Word 文档创建与编辑
│   ├── docx-to-md-polisher/  # DOCX 转 Markdown 清理
│   ├── find-skills/          # 技能发现与安装
│   ├── frontend-design/      # 前端界面设计
│   ├── mobile-android-design/# Android Material Design
│   ├── pdf/                  # PDF 处理
│   └── xlsx/                 # 表格创建与分析
├── plugins/                  # 插件元数据（已安装插件追踪）
├── rules/                    # 规则文件
├── agents/                   # 子代理定义（如 Codex 架构师、代码审查、安全审计）
├── commands/                 # 命令定义
├── sync.ps1                  # 同步脚本（拉取、对齐 ~/.claude、提交、推送）
└── sync.bat                  # 以管理员权限运行 sync.ps1（需提权时使用）
```

## 已安装插件

通过 Claude Code 插件系统安装，元数据追踪于 `plugins/installed_plugins.json`：

| 插件 | 来源 | 说明 |
|------|------|------|
| [claude-delegator](https://github.com/jarrodwatts/claude-delegator) | jarrodwatts | 将任务委托给 GPT / Gemini 专家（架构师、代码审查等） |
| skill-creator | claude-plugins-official | 创建、修改、评测技能 |

## 配置管理

```powershell
# 完整同步：拉取远程 -> 对齐 ~/.claude -> 提交并推送（如有变更）
.\sync.ps1 sync

# 不带参数等同于 sync
.\sync.ps1
```

若需以管理员权限运行（如符号链接创建失败时），可双击 `sync.bat` 或在 CMD 中执行 `sync.bat`。

> 注意：脚本会对齐 `skills`、`agents`、`rules`、`commands`。

目前 `skills/codex` 已重构为“技能入口 + 子代理定义”的混合架构：

- `skills/codex/SKILL.md` 负责触发判断、角色路由、委派格式和结果汇总
- `agents/*.md` 负责各个专家子代理的人设与输出约束

> 扩展方式：在 `sync.ps1` 顶部修改 `$ManagedSyncRules`（同步哪些目录）和 `$SyncTargets`（同步到哪些根目录）。

## 参考

- [brianlovin/claude-config](https://github.com/brianlovin/claude-config)
- [jarrodwatts/claude-delegator](https://github.com/jarrodwatts/claude-delegator)
- [Claude Code 文档](https://docs.anthropic.com/claude-code)
