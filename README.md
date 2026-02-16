# claude-config

我的 Claude Code 配置同步仓库。

## 快速开始

```powershell
git clone https://github.com/yuanv4/claude-config.git
cd claude-config
.\install.ps1
```

## 目录结构

```
claude-config/
├── settings.json      # Claude Code 设置（不含密钥）
├── settings.local.json # 本地敏感配置（不入库）
├── skills/            # 技能（子目录含 SKILL.md）
├── rules/             # 规则文件
├── agents/            # 子代理定义
├── tests/             # Bats 测试
├── install.ps1        # 安装脚本（创建软链接）
└── sync.ps1           # 同步脚本（管理仓库与本地差异）
```

## 配置管理

```powershell
# 查看同步状态
.\sync.ps1

# 预览安装效果
.\install.ps1 --dry-run

# 添加本地 skill 到仓库
.\sync.ps1 add skill my-skill
.\sync.ps1 push

# 添加本地 command 到仓库
.\sync.ps1 add command my-command
.\sync.ps1 push

# 从仓库移除 skill（保留本地副本）
.\sync.ps1 remove skill my-skill
.\sync.ps1 push

# 从仓库移除 command（保留本地副本）
.\sync.ps1 remove command my-command
.\sync.ps1 push

# 拉取远程更改
.\sync.ps1 pull
```

## 敏感信息

- `settings.json` 中不包含密钥，可安全提交
- `settings.local.json` 包含 `ANTHROPIC_AUTH_TOKEN` 等敏感信息，已被 `.gitignore` 忽略
- 在新机器上安装后，需手动创建 `settings.local.json` 并填入密钥

## 参考

- [brianlovin/claude-config](https://github.com/brianlovin/claude-config)
- [Claude Code 文档](https://docs.anthropic.com/claude-code)
