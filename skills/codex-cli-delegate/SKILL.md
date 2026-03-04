---
name: codex-cli-delegate
description: 使用 OpenAI Codex CLI（codex exec）处理高 token 开销任务。适用于多文件修改、批量重构、复杂排查、长文档生成、用户要求省 token/控成本、或明确要求用 Codex CLI 的场景。
argument-hint: "[任务描述]"
---

# Codex CLI 委托执行

## 目标

在高 token 或高复杂度任务中，优先把执行工作委托给 Codex CLI，降低主上下文消耗，同时保持可验证结果。

## 何时触发

满足任一条件即优先触发本技能：

1. 需要读取、对比、修改多个文件（通常 >= 3 个文件）。
2. 需要生成较长内容（方案、报告、批量注释、测试集等）。
3. 需要多轮排查与修复（复杂 Bug、链路追踪、反复验证）。
4. 需要批量重写或跨文件替换。
5. 用户明确提出“省 token / 控制成本 / 大任务交给 Codex”。
6. 用户明确要求使用 `codex` 或 `codex cli`。

低 token 轻量任务（短问答、很小改动、单次澄清）可直接处理，不必委托。

## 执行步骤

1. 先确认 CLI 可用：
   - 运行：`codex --version`
2. 组装高质量任务提示词（必须包含）：
   - 目标与完成标准
   - 文件路径/作用范围
   - 技术约束与禁改项
   - 验证要求（测试、构建、lint）
   - 输出格式要求
3. 使用**非交互模式**执行（优先通过 stdin 传入提示词，避免转义问题）：

```powershell
@'
[在这里填写给 Codex 的详细任务说明]
'@ | codex -a never exec --sandbox danger-full-access --skip-git-repo-check -
```

4. 如需连续迭代，复用上一次会话：

```powershell
codex exec resume --last "根据上一步结果继续修复，并确保测试通过"
```

5. 对 Codex 输出做本地验证（按任务需要执行测试/构建/lint）。
6. 向用户给出中文结论：结果、风险、验证状态、下一步建议。

## 默认策略

- 默认优先委托：高 token、高复杂度、多文件、批量任务。
- 默认安全参数：
  - `--sandbox danger-full-access`
  - `--ask-for-approval never`
  - `--skip-git-repo-check`
- 若任务是只读分析，可改为更保守的沙箱策略（如 `read-only`）。

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

- 若 `codex` 不可用：提示用户安装或修复环境，并退回本地直接处理。
- 若一次执行结果不达标：使用 `codex exec resume --last` 给出增量修正指令继续迭代。
