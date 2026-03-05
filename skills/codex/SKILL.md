---
name: codex
description: 使用 OpenAI Codex CLI（codex exec）执行具体工程任务。适用于功能开发、Bug 修复、跨文件修改、重构与批量替换、测试编写、仓库分析、技术文档生成，或用户明确要求使用 codex/codex cli 的场景。
argument-hint: "[任务描述]"
---

# Codex CLI 委托执行

## 目标

将可执行工程任务直接委托给 Codex CLI 完成，减少中间判断步骤，并保持结果可验证。

## 何时触发

命中以下任一任务类型，直接触发本技能：

1. 创建新文件、模块、组件、脚手架。
2. 实现功能代码、接口、数据处理逻辑。
3. 修复报错、修复测试失败、定位并修复缺陷。
4. 编写或补齐单元测试、集成测试。
5. 重构、重命名、跨文件批量替换。
6. 生成技术文档、发布说明、迁移说明。
7. 分析仓库结构并输出风险点或改进建议。
8. 用户明确要求使用 `codex`、`codex cli`、`codex exec`。

**不触发**：涉及文件 ≤ 2 个且预估改动 ≤ 20 行的简单任务，本地直接处理即可。

## Windows 沙箱说明

Windows 下统一使用 `--sandbox danger-full-access`。`read-only` 和 `workspace-write` 均使用受限令牌机制，高概率触发 `CreateProcessWithLogonW failed: 1326/1909` 而无法执行子进程。

降级链（当 `danger-full-access` 也失败时）：

```
danger-full-access → --dangerously-bypass-approvals-and-sandbox → 本地回退
```

> macOS/Linux 可根据任务风险选择 `read-only`（只读分析）、`workspace-write`（生成文件）或 `danger-full-access`（跨文件修改）。

> `[windows] sandbox = "elevated"` 配置项在当前版本（≥0.107.0）中已无效。应通过 `--sandbox` 参数显式控制。

## 执行步骤

### 第一步：识别 Shell 环境 & 组装提示词

**先确认当前终端类型**，不要在 Bash 中使用 PowerShell 语法，也不要在 PowerShell 中使用 Bash 语法。判断方式：

- 检查终端元数据中的 shell 类型
- 或执行 `echo $PSVersionTable`（PowerShell 有输出）/ `echo $SHELL`（Bash 有输出）

**然后组装提示词**，使用以下结构：

```text
任务目标：
- ...

范围与文件：
- ...

约束：
- 不要修改 ...
- 保持 ...

执行要求：
- 先分析再改动
- 改动后运行 ...

完成标准：
- ...

输出格式：
- 先给改动摘要
- 再给验证结果
```

### 第二步：执行（非交互模式）

根据 Shell 环境选择对应方式。

**PowerShell**：临时文件 + `Get-Content` 管道（PowerShell 不支持 `<` 输入重定向）。

```powershell
$prompt = @"
[给 Codex 的详细任务说明]
"@
$tmpFile = "$env:TEMP\codex_prompt_$(Get-Random).txt"
[System.IO.File]::WriteAllText($tmpFile, $prompt, [System.Text.Encoding]::UTF8)
Push-Location <工作目录>
Get-Content $tmpFile -Raw -Encoding UTF8 | codex exec --sandbox danger-full-access --skip-git-repo-check -
$exitCode = $LASTEXITCODE
Pop-Location
Remove-Item $tmpFile -ErrorAction SilentlyContinue
if ($exitCode -ne 0) { <# 进入失败回退流程 #> }
```

大输出任务加 `Tee-Object` 同时写入文件：

```powershell
Get-Content $tmpFile -Raw -Encoding UTF8 | codex exec --sandbox danger-full-access --skip-git-repo-check - | Tee-Object -FilePath "$env:TEMP\codex_output.txt"
```

**Bash（Git Bash / WSL）**：heredoc 传递提示词。

```bash
cd <工作目录>
codex exec --sandbox danger-full-access --skip-git-repo-check - <<'EOF'
[给 Codex 的详细任务说明]
EOF
```

大输出任务加 `tee`：

```bash
codex exec --sandbox danger-full-access --skip-git-repo-check - <<'EOF' | tee /tmp/codex_output.txt
[给 Codex 的详细任务说明]
EOF
```

**禁止混用**：

| 错误做法 | 原因 |
|---|---|
| 在 PowerShell 中使用 `<<'EOF'` heredoc | PowerShell 不支持此语法 |
| 在 Bash 中使用 `Get-Content`、`$env:TEMP`、`Push-Location` | 这些是 PowerShell cmdlet |
| 在 PowerShell 中使用 `<` 重定向 | `<` 在 PowerShell 中为保留符号 |
| 在 Bash 中使用 `@"..."@` here-string | 这是 PowerShell 语法 |

### 第三步：迭代修复（最多 3 次）

若结果不达标，构造包含上次错误信息的**新提示词**重新调用 `codex exec`，最多重试 3 次。

在新提示词中追加：

```text
上次执行的问题：
- [关键错误信息]

请在上次结果基础上修复以上问题，并确保验证通过。
```

超过 3 次仍未达标，停止委托并退回本地处理，告知用户卡点。

### 第四步：验证

检查 Codex 输出中是否已包含验证结果（测试通过、构建成功等）。如缺失，本地补充执行验证命令。

## 失败回退

| 场景 | 处理方式 |
|---|---|
| CLI 不可用 | 提示用户安装或修复环境，退回本地处理 |
| 退出码非零 | 读取错误信息，判断网络/权限/任务问题，决定是否重试 |
| Windows 沙箱失败（`CreateProcessWithLogonW`） | 按降级链：`danger-full-access` → `--dangerously-bypass-approvals-and-sandbox` → 本地回退 |
| 退出码为 0 但子进程全部失败 | 检查输出中的 `exec error` 或 `CreateProcessWithLogonW`，按沙箱降级处理 |
| 迭代超过 3 次仍不达标 | 停止委托，退回本地处理，说明卡点 |
| 执行挂起无响应 | 终止进程，检查网络/API 配额，再决定是否重试 |
| Shell 语法不匹配 | 确认当前终端类型（PowerShell / Bash），切换到对应的执行方式 |
