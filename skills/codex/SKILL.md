---
name: codex
description: 使用 OpenAI Codex CLI（codex exec）执行具体工程任务。适用于代码评审、只读分析、Bug 确认与修复、功能开发、跨文件修改、重构、测试编写、仓库分析、修改验证，或用户明确要求使用 codex/codex cli 的场景。
argument-hint: "[任务描述]"
---

# Codex CLI 委托执行

## 目标

将可执行工程任务直接委托给 Codex CLI，不做额外探索或预分析，**直接组装 → 直接执行**。

## 何时触发

命中以下任一场景即触发：

- 代码评审、只读分析、Bug 确认、修改验证
- 创建文件、实现功能、修复错误、编写测试
- 重构、跨文件批量替换、生成文档
- 用户明确要求使用 `codex` / `codex cli`

**不触发**：涉及文件 ≤ 2 个且改动 ≤ 20 行的简单任务，直接本地处理。

## 执行（直接执行，无需预检）

**Shell 环境已在系统 prompt 中明确，直接使用，不重复检测。**

**Bash（Git Bash / WSL / macOS / Linux）**：

```bash
cd <工作目录>
codex exec --sandbox danger-full-access --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check - <<'EOF'
<任务描述：目标 + 范围 + 约束 + 完成标准>
EOF
```

**PowerShell**：

```powershell
$prompt = @"
<任务描述：目标 + 范围 + 约束 + 完成标准>
"@
$tmp = "$env:TEMP\codex_$(Get-Random).txt"
[System.IO.File]::WriteAllText($tmp, $prompt, [System.Text.Encoding]::UTF8)
Push-Location <工作目录>
Get-Content $tmp -Raw -Encoding UTF8 | codex exec --sandbox danger-full-access --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check -
Pop-Location
Remove-Item $tmp -ErrorAction SilentlyContinue
```

大输出加 `tee` / `Tee-Object` 同时写入文件。

**禁止混用 Shell 语法**（heredoc 是 Bash 语法，`Get-Content`/`$env:` 是 PowerShell 语法）。

## 提示词内容（直接描述任务，不套模板）

```
<用自然语言描述任务即可，无需固定结构>

只读任务加一行：只读分析，不修改任何文件。
有修改任务加一行：改动完成后运行 <验证命令> 确认通过。
```

## 失败回退

| 场景 | 处理方式 |
|---|---|
| Windows 沙箱失败（`CreateProcessWithLogonW`） | `danger-full-access` → `--dangerously-bypass-approvals-and-sandbox` → 本地回退 |
| 退出码非零 | 读错误信息，判断是网络/权限/任务问题，决定是否重试 |
| 迭代超过 3 次仍不达标 | 停止委托，退回本地处理，说明卡点 |
| 挂起无响应 | 终止进程，检查网络/API 配额 |
| CLI 不可用 | 提示用户安装或修复环境，退回本地处理 |

迭代修复时，在提示词末尾追加上次的关键错误信息即可，最多 3 次。
