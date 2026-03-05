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

## Windows 沙箱说明

Windows 下的安全沙箱使用受限令牌（restricted token）机制，与 macOS（Seatbelt）和 Linux（Landlock）行为不同：

- `--sandbox read-only`：限制写入，但在 Windows 上部分场景下可能仍有限制不完整的问题
- `--sandbox workspace-write`：允许向工作目录写入，**Windows 推荐的默认策略**
- `--sandbox danger-full-access`：完全访问，不受沙箱限制
- `--dangerously-bypass-approvals-and-sandbox`：完全绕过沙箱和审批，**仅在外部已有隔离环境时使用**

> **Windows 重要提示**：`[windows] sandbox = "elevated"` 配置项在当前版本（≥0.107.0）中已无效（对应特性已被标记为 removed）。应通过 `--sandbox` 参数显式控制沙箱策略，而非依赖配置文件的 windows 节。

## 执行步骤

### 第一步：确认 CLI 可用

```powershell
codex --version
```

若命令不存在，提示用户安装并退出，退回本地直接处理。

### 第二步：轻量级分流判断

在委托前做快速预判（目标：3 秒内完成，不做深度分析）：

| 条件 | 处理方式 |
|---|---|
| 用户明确要求使用 Codex | 无条件委托 |
| 涉及文件 > 2 个，或需跨文件一致性保证 | 委托 Codex |
| 涉及文件 ≤ 2 个，且预估改动 ≤ 20 行 | 本地直接处理，无需委托 |

### 第三步：确定沙箱策略

根据任务风险选择沙箱策略，**禁止对低风险任务使用高权限参数**：

| 风险等级 | 典型场景 | 沙箱参数 |
|---|---|---|
| 只读 | 仓库分析、代码审查、文档阅读 | `--sandbox read-only` |
| 受限写入 | 生成文档、新建独立文件 | `--sandbox workspace-write` |
| 完全写入 | 重构、批量替换、修复 Bug、跨文件修改 | `--sandbox danger-full-access` |

> Windows 下 `read-only` 沙箱若出现异常（进程挂起、权限报错），降级为 `workspace-write`。

### 第四步：组装高质量任务提示词

提示词必须包含以下所有要素：

- 目标与完成标准
- 文件路径/作用范围
- 技术约束与禁改项
- 验证要求（测试、构建、lint）
- 输出格式要求

### 第五步：执行（非交互模式）

**Windows 下优先使用临时文件传递提示词**，避免 PowerShell here-string 编码问题（UTF-16LE vs UTF-8）和管道截断：

```powershell
# 推荐：将提示词写入临时文件，再用文件重定向传入
$prompt = @"
[在这里填写给 Codex 的详细任务说明]
"@
$tmpFile = "$env:TEMP\codex_prompt_$(Get-Random).txt"
[System.IO.File]::WriteAllText($tmpFile, $prompt, [System.Text.Encoding]::UTF8)
codex exec --sandbox <沙箱策略> --skip-git-repo-check - < $tmpFile
Remove-Item $tmpFile -ErrorAction SilentlyContinue
```

若使用 bash（Git Bash / WSL），可用 heredoc：

```bash
codex exec --sandbox <沙箱策略> --skip-git-repo-check - <<'EOF'
[在这里填写给 Codex 的详细任务说明]
EOF
```

**避免使用**的写法（Windows 下不稳定）：

```powershell
# 不推荐：PowerShell here-string 通过管道传入
@'
[任务说明]
'@ | codex exec --sandbox ... --skip-git-repo-check -
```

执行后立即检查退出码：

```powershell
if ($LASTEXITCODE -ne 0) {
    # 进入失败回退流程
}
```

对于输出内容可能较大的任务，将结果写入文件再读取：

```powershell
$tmpFile = "$env:TEMP\codex_prompt_$(Get-Random).txt"
[System.IO.File]::WriteAllText($tmpFile, $prompt, [System.Text.Encoding]::UTF8)
codex exec --sandbox danger-full-access --skip-git-repo-check - < $tmpFile | Tee-Object -FilePath "$env:TEMP\codex_output.txt"
Remove-Item $tmpFile -ErrorAction SilentlyContinue
```

### 第六步：迭代修复（有上限）

若结果不达标，使用 `resume` 继续迭代，**最多重试 3 次**：

```powershell
codex exec resume --last "根据上一步结果继续修复，并确保测试通过"
```

超过 3 次仍未达标，停止委托并退回本地直接处理，同时告知用户原因。

### 第七步：本地验证

按任务需要执行测试/构建/lint，验证 Codex 输出的实际效果。

### 第八步：向用户汇报

用中文给出结论，包含：结果摘要、潜在风险、验证状态、下一步建议。

## 提示词模板

调用 Codex 时优先使用以下结构：

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

## 失败回退

- **CLI 不可用**：提示用户安装或修复环境，退回本地直接处理。
- **退出码非零**：读取错误信息，判断是网络问题、权限问题还是任务本身问题，再决定是否重试。
- **Windows 沙箱挂起**：`read-only` 沙箱在 Windows 下有时会因受限令牌导致子进程挂起，改用 `--sandbox workspace-write` 或 `--dangerously-bypass-approvals-and-sandbox` 重试。
- **迭代超过 3 次仍不达标**：停止委托，退回本地处理，向用户说明卡点。
- **执行挂起无响应**：终止进程，检查网络连接或 API 配额，再决定是否重试。
