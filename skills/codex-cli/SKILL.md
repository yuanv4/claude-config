---
name: codex-cli
description: Invoke the local Codex CLI (codex-cli) to execute coding tasks, review code, or run autonomous agents. Use when the user asks to delegate a task to Codex, run Codex, use Codex CLI, perform a code review with Codex, or wants an AI agent to work on a task in the background via Codex.
---

# Codex CLI

通过 Shell 工具调用本地安装的 `codex` 命令行工具来执行编码任务、代码审查等。

## 前提条件

- Codex CLI 已安装并可在 PATH 中访问（命令名：`codex`）
- 当前配置文件位于 `~/.codex/config.toml`

## 核心命令

### 1. 非交互式执行任务（`codex exec`）

这是最常用的模式，将任务委托给 Codex 在后台自主完成。

```bash
codex exec --full-auto -C "<工作目录>" "<任务描述>"
```

关键参数：
- `--full-auto`：自动执行模式，无需人工确认（sandbox + workspace-write）
- `-C <DIR>`：指定工作目录（默认为当前目录）
- `-m <MODEL>`：指定模型（默认使用配置文件中的模型）
- `-s <MODE>`：沙箱策略（`read-only`、`workspace-write`、`danger-full-access`）
- `--json`：以 JSONL 格式输出事件流
- `-o <FILE>`：将最终消息写入指定文件
- `--ephemeral`：不保存会话记录

### 2. 代码审查（`codex review`）

审查代码变更，支持未提交的更改或特定分支的 diff。

```bash
# 审查未提交的所有更改
codex review --uncommitted

# 审查相对于某个基准分支的更改
codex review --base main

# 审查特定 commit
codex review --commit <SHA>

# 自定义审查指令
codex review --uncommitted "重点关注安全漏洞和性能问题"
```

### 3. 交互式模式

直接启动交互式会话（一般不在 Cursor 中使用，仅供参考）：

```bash
codex --full-auto -C "<工作目录>" "<提示词>"
```

## 使用工作流

### 委托编码任务

当用户希望将任务委托给 Codex 执行时：

1. 确认工作目录（通常是当前项目目录或用户指定的目录）
2. 构建清晰的任务描述提示词
3. 使用 `codex exec` 执行，设置 `block_until_ms: 0` 将其放到后台
4. 通过读取终端文件监控进度
5. 完成后向用户报告结果

```bash
# 示例：让 Codex 重构某个模块
codex exec --full-auto -C "D:/projects/myapp" "将 utils.js 中的所有函数重构为 TypeScript，添加类型注解"
```

**重要**：由于 Codex 任务通常耗时较长，务必设置 `block_until_ms: 0` 立即放到后台运行，然后轮询终端文件查看进度。

### 代码审查工作流

当用户希望用 Codex 审查代码时：

1. 确认审查范围（未提交更改、特定分支、特定 commit）
2. 可选：提供审查重点说明
3. 运行 `codex review` 并捕获输出
4. 将审查结果整理后呈现给用户

```bash
# 审查当前未提交的更改
codex review --uncommitted
```

### 捕获 Codex 输出

如果需要获取 Codex 的最终输出用于后续处理：

```bash
codex exec --full-auto -o result.md -C "<工作目录>" "<任务>"
```

执行完成后读取 `result.md` 获取结果。

## 模型选择

通过 `-m` 参数指定模型，常用选项：

| 模型 | 适用场景 |
|------|---------|
| `o4-mini` | 快速简单任务 |
| `o3` | 复杂推理任务 |
| `gpt-5.3-codex` | 默认模型，均衡性能（当前配置） |
| `claude-sonnet-4-20250514` | Claude 模型 |

示例：

```bash
codex exec --full-auto -m o4-mini -C "<目录>" "<简单任务>"
```

## 注意事项

- `codex exec` 是非交互式的，适合从 Cursor 调用
- 交互式的 `codex` 命令不适合在 Cursor 的 Shell 工具中运行（无法响应交互提示）
- 始终使用 `--full-auto` 或明确指定 `-s` 和 `-a never` 来避免交互式提示
- 长时间任务请使用 `block_until_ms: 0` 放到后台
- Codex 在 Windows 上的沙箱配置为 `elevated` 模式
- 工作目录路径在 Windows 上使用正斜杠或双反斜杠
