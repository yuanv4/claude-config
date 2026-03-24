---
name: claudemd
description: 一个全面的入门流程，用于在当前仓库中设置 CLAUDE.md 及相关的技能/钩子，包括代码库探索、用户访谈和迭代式提案完善。支持已有 CLAUDE.md 时的轻量维护模式。
---
为此仓库设置一个最小化的 CLAUDE.md（以及可选的技能和钩子）。CLAUDE.md 会加载到每个 Claude Code 会话中，因此它必须简洁，只包含那些如果没有它 Claude 就会出错的内容。

## 第 0 阶段：判定是"首次设置"还是"维护模式"

先检查仓库根目录是否已存在 `CLAUDE.md`。

- 如果 **不存在**：按下面的完整流程执行（第 1-8 阶段）。
- 如果 **已存在**：**默认进入维护模式（maintenance mode）**，不要直接进入完整 onboarding。
- 如果用户明确表示想"重做 / 重新 onboarding / 从头整理 / 顺便设计 skills/hooks/CLAUDE.local.md / 跑完整流程"，则**退出维护模式**，改走完整的第 1-8 阶段。

### 维护模式目标

快速扫描现有 `CLAUDE.md`，检查它是否与当前代码状态一致，并提出最小必要修改。重点是：
- 找出过时、冲突、失效或应下沉到子目录的条目
- 补充少量当前缺失但高价值的事实
- 以最小改动维护现有知识，而不是重新做一轮完整设置

### 维护模式下要跳过的内容

- **不要询问第 1 阶段的完整 onboarding 问题**
- **不要执行第 3 阶段的完整补缺访谈**
- **不要默认进入第 5、6、7、8 阶段**
- **不要自动提议或创建 skills、hooks、CLAUDE.local.md、linting、GitHub CLI、插件或其他优化项**
- 只有在用户**明确要求**时，才恢复这些阶段中的相应内容

### 维护模式流程

#### A. 读取现有 CLAUDE 知识

读取根目录 `CLAUDE.md`。如有必要，再读取其中直接引用或明显相关的子目录 `CLAUDE.md`。

提取其中的关键事实：
- 构建、测试、lint、格式化命令
- 目录职责、模块边界、关键工作流
- 非默认约定、命名规则、接口约束
- 长期陷阱、环境变量、设置前提

#### B. 做最小必要的现状校验

只读取少量高信号文件来验证现有 `CLAUDE.md` 是否过时；**不要做完整代码库探索**。优先检查：
- 清单/构建文件（如 `package.json`、`pyproject.toml`、`Cargo.toml`、`go.mod`、`pom.xml` 等）
- README
- 顶层目录结构
- `CLAUDE.md` 中提到的路径、脚本、配置文件是否仍存在
- 与现有条目直接相关的少量配置文件

重点检测：
- 命令是否仍有效
- 框架、运行时、包管理器是否变化
- 目录结构或模块边界是否漂移
- 条目是否只适用于某个子目录，应该从根目录下沉
- 是否存在完全陈旧、应删除的内容

#### C. 仅在必要时做极少量澄清

只有当代码和现有文件**无法确认**某个条目应如何更新时，才询问用户。问题必须是**定向澄清**，而不是完整访谈。例如：
- "`make verify` 似乎已不存在，是否应改为 `just verify`？"
- "这条关于 `legacy/` 的说明看起来已过时，是否直接删除？"

不要询问团队角色、沟通偏好、个人习惯、skills/hooks 偏好等 onboarding 问题。

#### D. 产出最小变更提案

通过 AskUserQuestion 的 `preview` 字段展示变更提案，使用以下类型：

- **[Add]** `<new fact>` → `CLAUDE.md` (or `<subdir>/CLAUDE.md`)
- **[Update]** `<old entry>` → `<new entry>` in `CLAUDE.md`
- **[Downscope]** `<entry>` in root → `<subdir>/CLAUDE.md`
- **[Delete]** `<stale entry>` from `CLAUDE.md`
- **[Gap]** `<unconfirmed fact>` — needs user confirmation before writing

不要在维护模式中混入 skills、hooks、CLAUDE.local.md 或其他优化建议。

如果扫描没发现任何问题，直接告知用户"CLAUDE.md 已是最新，无需更改"，结束。

#### E. 执行变更并结束

按用户确认的变更列表更新 CLAUDE.md（同第 4 阶段的增量更新规则），完成后简短总结。

结束时附一句提示："如果你想改为完整 onboarding（重新访谈、重建结构、顺带设计 skills/hooks/CLAUDE.local.md），请明确说明，我会切回完整流程。"

## 第 1 阶段：询问要设置什么

使用 AskUserQuestion 弄清楚用户想要什么：

- “/claudemd 应该设置哪些 CLAUDE.md 文件？”
  Options: "Project CLAUDE.md" | "Personal CLAUDE.local.md" | "Both project + personal"
  Description for project: "团队共享并纳入源代码管理的说明——架构、编码规范、常见工作流。"
  Description for personal: "你针对此项目的私有偏好（被 gitignore，不共享）——你的角色、沙箱 URL、偏好的测试数据、工作流习惯。"

- “还要设置技能和钩子吗？”
  Options: "Skills + hooks" | "Skills only" | "Hooks only" | "Neither, just CLAUDE.md"
  Description for skills: "你或 Claude 可通过 `/skill-name` 调用的按需能力——适合可重复的工作流和参考知识。"
  Description for hooks: "在工具事件上运行的确定性 shell 命令（例如每次编辑后格式化）。Claude 不能跳过它们。"

## 第 2 阶段：探索代码库

> **维护模式下**：本阶段仅执行与现有 `CLAUDE.md` 条目直接相关的最小校验，不做完整代码库勘察。请参照第 0 阶段的维护模式流程步骤 A-B 执行。

启动一个子代理来勘察代码库，并让它读取关键文件以理解项目：清单文件（package.json、Cargo.toml、pyproject.toml、go.mod、pom.xml 等）、README、Makefile/构建配置、CI 配置、现有的 CLAUDE.md、.claude/rules/、AGENTS.md、.cursor/rules 或 .cursorrules、.github/copilot-instructions.md、.windsurfrules、.clinerules、.mcp.json。

检测：
- 构建、测试和 lint 命令（尤其是非标准的命令）
- 语言、框架和包管理器
- 项目结构（带工作区的 monorepo、多模块，或单项目）
- 不同于语言默认值的代码风格规则
- 不明显的陷阱、必需的环境变量或工作流习惯
- 现有的 .claude/skills/ 和 .claude/rules/ 目录
- 格式化器配置（prettier、biome、ruff、black、gofmt、rustfmt，或统一的格式化脚本，如 `npm run format` / `make fmt`）
- Git worktree 的使用情况：运行 `git worktree list` 检查此仓库是否有多个 worktree（仅当用户想要个人 CLAUDE.local.md 时相关）

记下哪些内容你无法仅从代码中弄清楚——这些会成为访谈问题。

还要在同一个子代理中扫描现有的 CLAUDE 知识系统：
- 读取根目录的 `CLAUDE.md`（如果存在）：标记已过时或与当前事实冲突的条目；标记仅适用于特定子目录的条目（为每个条目记录目标路径）；标记完全陈旧且应删除的条目
- 如果存在，读取 `.claude/rules/` 文件
- 如果根目录 `CLAUDE.md` 不存在，记下哪些子目录会从新的 `CLAUDE.md` 中受益

应下沉范围的候选项（属于某个子目录的根级条目）在此阶段识别。第 4 阶段只执行此处识别出来的内容。

## 第 3 阶段：补齐缺口

使用 AskUserQuestion 收集你仍然需要的信息，以写出高质量的 CLAUDE.md 文件和技能。只问代码无法回答的事情。

如果用户选择了项目 CLAUDE.md 或两者都要：询问代码库实践——不明显的命令、陷阱、分支/PR 约定、必需的环境设置、测试习惯。跳过 README 中已有的内容，或从清单文件中显而易见的内容。不要将任何选项标记为“recommended”——这里关注的是他们团队如何工作，而不是最佳实践。

如果用户选择了个人 CLAUDE.local.md 或两者都要：询问与他们本人有关的内容，而不是代码库。不要将任何选项标记为“recommended”——这里关注的是他们的个人偏好，而不是最佳实践。问题示例：
  - 他们在团队中的角色是什么？（例如，“后端工程师”、“数据科学家”、“新员工入职”）
  - 他们对这个代码库及其语言/框架有多熟悉？（这样 Claude 可以校准解释深度）
  - 他们是否有 Claude 应该知道的个人沙箱 URL、测试账号、API 密钥路径或本地设置细节？
  - 仅当第 2 阶段发现多个 git worktree 时：询问他们的 worktree 是嵌套在主仓库内部（例如 `.claude/worktrees/<name>/`）还是同级/外部（例如 `../myrepo-feature/`）。如果是嵌套的，向上查找文件会自动找到主仓库的 CLAUDE.local.md——不需要特殊处理。如果是同级/外部的，个人内容应放在 home 目录下的文件中（例如 `~/.claude/<project-name>-instructions.md`），并且每个 worktree 都有一个单行的 CLAUDE.local.md 存根来导入它：`@~/.claude/<project-name>-instructions.md`。绝不要把这个导入放进项目的 CLAUDE.md 中——那样会把个人引用提交进团队共享文件。
  - 有任何沟通偏好吗？（例如，“简洁一些”、“总是解释取舍”、“最后不要总结”）

**根据第 2 阶段的发现综合出一个提案**——例如，如果存在格式化器则进行编辑后格式化，如果存在测试则提供一个 `/verify` 技能，对于来自补缺回答中属于指导原则而非工作流的内容，写入 CLAUDE.md 备注。对每一项，都选择适合的制品类型，**并受限于第 1 阶段对 skills+hooks 的选择**：

  - **Hook**（更严格）——在工具事件上运行的确定性 shell 命令；Claude 不能跳过。适合机械性的、快速的、每次编辑都要执行的步骤：格式化、lint、对变更文件运行快速测试。
  - **Skill**（按需）——你或 Claude 在想用时调用 `/skill-name`。适合不应在每次编辑都执行的工作流：深度验证、会话报告、部署。
  - **CLAUDE.md note**（更宽松）——影响 Claude 的行为但不强制执行。适合沟通/思考偏好：“编码前先规划”、“保持简洁”、“解释取舍”。

  **将第 1 阶段对 skills+hooks 的选择视为硬性过滤条件**：如果用户选择了 “Skills only”，把你原本会建议的任何 hook 降级为 skill 或 CLAUDE.md 备注。如果是 “Hooks only”，把 skill 降级为 hook（在机械上可行时）或备注。如果是 “Neither”，所有内容都变成 CLAUDE.md 备注。绝不要提议用户没有选择的制品类型。

**通过 AskUserQuestion 的 `preview` 字段展示提案，而不是作为单独的文本消息**——对话框会覆盖你的输出，因此前面的文本会被隐藏。`preview` 字段会在侧边栏中渲染 markdown（类似 plan 模式）；`question` 字段只支持纯文本。结构如下：

  - `question`：简短且纯文本，例如 “Does this proposal look right?”
  - 每个选项都带一个包含完整提案 markdown 的 `preview`。 “Looks good — proceed” 选项的 preview 显示全部内容；按项删除的选项 preview 显示删除该项后剩余的内容。
  - **保持 preview 紧凑——preview 框会截断且无法滚动。** 每项一行，项与项之间不要留空行，也不要加标题。preview 内容示例：

    • **Format-on-edit hook** (automatic) — `ruff format <file>` via PostToolUse
    • **/verify skill** (on-demand) — `make lint && make typecheck && make test`
    • **CLAUDE.md note** (guideline) — "run lint/typecheck/test before marking done"

  - 选项标签保持简短（“Looks good”、“Drop the hook”、“Drop the skill”）——该工具会自动添加一个 “Other” 自由输入选项，因此不要自行添加兜底选项。

**如果用户选择了项目 CLAUDE.md 或两者都要**：还要在提案预览中包含 CLAUDE.md 知识变更。添加一个 `CLAUDE.md changes` 部分——每个操作一行，保持紧凑：

  • **[Add]** `<new fact>` → `CLAUDE.md` (or `<subdir>/CLAUDE.md`)
  • **[Update]** `<old entry>` → `<new entry>` in `CLAUDE.md`
  • **[Downscope]** `<entry>` in root → `<subdir>/CLAUDE.md`
  • **[Delete]** `<stale entry>` from `CLAUDE.md`
  • **[Gap]** `<unconfirmed fact>` — needs user confirmation before writing

只展示实际有内容的操作；空类别省略。未变化且准确的条目不必出现。

**根据接受的提案构建偏好队列**。每个条目：{type: hook|skill|note, description, target file, any Phase-2-sourced details like the actual test/format command}。第 4-7 阶段会消费这个队列。

还要把已确认的 CLAUDE.md 知识变更记录为一个**CLAUDE.md 变更列表**（与偏好队列分开）：每个条目包含 {operation: add|update|downscope|delete, content, target file}。第 4 阶段会消费这个列表。

## 第 4 阶段：编写 CLAUDE.md（如果用户选择了项目或两者都要）

**消费第 3 阶段偏好队列中目标为 CLAUDE.md 的 `note` 条目**（团队级备注）——将每一项作为简洁的一行加入最相关的章节。将面向个人的备注留到第 5 阶段处理。

### 写入/跳过判断

每一条候选内容都必须通过这个判断：“如果删掉它，Claude 会因此犯错吗？”如果不会，就删掉。

在以下情况下**写入**：
- 是非标准的构建、测试、lint、部署或格式化命令
- 引入或替换了关键框架、运行时或包管理器
- 定义了目录职责、模块边界或核心数据流
- 建立了不同于语言默认值的约定、接口约束或命名规则
- 暴露了长期存在的陷阱、必需的环境变量、设置前提或架构决策
- 来自现有 AI 配置文件（AGENTS.md、.cursor/rules、.cursorrules、.github/copilot-instructions.md、.windsurfrules、.clinerules），且值得保留

在以下情况下**跳过**：
- 是标准语言约定，或从清单文件显而易见的命令（例如 `npm test`、`cargo test`、`pytest`）
- 是目录清单、组件枚举或逐文件结构说明
- 是通用建议（“写干净的代码”、“处理错误”）
- 是很长的教程、详细的 API 参考，或经常变化的内容——改用 `@path/to/file`
- 无法从代码确认且用户也未确认——将其记录为知识缺口，不要猜测

要具体：“Use 2-space indentation in TypeScript” 而不是 “Format code properly.”。不要发明诸如 “Common Development Tasks” 或 “Tips for Development” 之类的章节。

### 路由

- 影响整个仓库的规则 → 根目录 `CLAUDE.md`
- 仅适用于某个子目录的规则 → 该子目录下的 `CLAUDE.md`
- 同时包含全局和模块特定知识 → 分别写入两个文件
- 根文件只保留全局事实；模块细节放入子目录文件

### 如果 CLAUDE.md 已存在：增量更新

执行第 3 阶段确认过的 CLAUDE.md 变更列表。不要静默覆盖。

1. **Update** 条目：找到匹配的章节并就地重写过时条目
2. **Add** 条目：追加到最相关的章节；只有在没有合适章节时才创建最小化新章节
3. **Delete** 条目：删除陈旧条目
4. **Downscope** 条目：从根目录 `CLAUDE.md` 中删除，并写入目标子目录的 `CLAUDE.md`
5. 合并重复信息；不要让同一事实在同一个文件中重复出现两次
6. 使用项目事实表述——不要包含 commit 哈希或 commit message

### 如果 CLAUDE.md 不存在：从零创建

前缀如下：

```
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
```

然后只写入能通过上述写入/跳过判断的内容。只包含你在所读文件中明确发现的信息。

### 子目录 CLAUDE.md 文件

对于第 2 阶段中被标记的任意子目录（或被下沉操作指向的子目录），创建 `<subdir>/CLAUDE.md`：
- 第一行：`# <dirname>`
- 只写入适用于该子目录内部的规则
- 不要重复根目录 `CLAUDE.md` 中已有的全局规则

对于包含多个关注点的项目，建议将规则组织到 `.claude/rules/` 中，拆成多个聚焦文件（例如 `code-style.md`、`testing.md`、`security.md`）。这些文件会与 `CLAUDE.md` 一起自动加载，并且可以使用 `paths` frontmatter 作用于特定文件路径。

## 第 5 阶段：编写 CLAUDE.local.md（如果用户选择了个人或两者都要）

> **维护模式默认跳过本阶段**，除非用户明确要求。

在项目根目录写一个最小化的 CLAUDE.local.md。这个文件会与 CLAUDE.md 一起自动加载。创建后，把 `CLAUDE.local.md` 加入项目的 .gitignore，以保持私有。

**消费第 3 阶段偏好队列中目标为 CLAUDE.local.md 的 `note` 条目**（个人级备注）——把每项作为简洁的一行加入。如果用户在第 1 阶段只选择了 personal-only，这就是 `note` 条目的唯一消费方。

包含：
- 用户的角色以及对代码库的熟悉程度（这样 Claude 可以校准解释）
- 个人沙箱 URL、测试账号或本地设置细节
- 个人工作流或沟通偏好

保持简短——只包含那些会明显改善 Claude 对该用户响应质量的信息。

如果第 2 阶段发现多个 git worktree，且用户确认他们使用的是同级/外部 worktree（而不是嵌套在主仓库内）：向上查找文件将无法从所有 worktree 找到同一个 CLAUDE.local.md。把实际的个人内容写入 `~/.claude/<project-name>-instructions.md`，并让 CLAUDE.local.md 成为一个导入它的单行存根：`@~/.claude/<project-name>-instructions.md`。用户可以把这个单行存根复制到每个同级 worktree。绝不要把这个导入放进项目 CLAUDE.md 中。如果 worktree 嵌套在主仓库内部（例如 `.claude/worktrees/`），则不需要特殊处理——主仓库的 CLAUDE.local.md 会被自动找到。

如果 CLAUDE.local.md 已存在：读取它，提出具体补充建议，不要静默覆盖。

## 第 6 阶段：建议并创建技能（如果用户选择了 “Skills + hooks” 或 “Skills only”）

> **维护模式默认跳过本阶段**，除非用户明确要求。

技能为 Claude 提供按需使用的能力，而不会让每次会话都变得臃肿。

**首先，消费第 3 阶段偏好队列中的 `skill` 条目。** 每个排队的技能偏好都变成一个针对用户描述量身定制的 SKILL.md。对每一项：
- 根据偏好命名（例如 “verify-deep”、“session-report”、“deploy-sandbox”）
- 使用访谈中的用户原话以及第 2 阶段发现的内容（测试命令、报告格式、部署目标）编写正文。如果该偏好映射到现有内置技能（例如 `/verify`），则写一个项目技能，在其之上增加用户的具体约束——告诉用户内置技能仍然存在，而他们的技能是附加增强。
- 如果偏好定义得不够充分，快速追问一个补充问题（例如，“verify-deep 应该运行哪个测试命令？”）

**然后再建议额外的技能**，当你发现以下内容时：
- 特定任务的参考知识（某个子系统的约定、模式、风格指南）
- 用户会想直接触发的可重复工作流（部署、修复问题、发布流程、验证变更）

对每个建议的技能，提供：名称、单行用途，以及它为什么适合这个仓库。

如果 `.claude/skills/` 已存在技能，先审查它们。不要覆盖现有技能——只提议那些补充现有内容的新技能。

在 `.claude/skills/<skill-name>/SKILL.md` 创建每个技能：

```yaml
---
name: <skill-name>
description: <what the skill does and when to use it>
---

<Instructions for Claude>
```

默认情况下，用户（`/<skill-name>`）和 Claude 都可以调用技能。对于有副作用的工作流（例如 `/deploy`、`/fix-issue 123`），添加 `disable-model-invocation: true`，使其只能由用户触发，并使用 `$ARGUMENTS` 接收输入。

## 第 7 阶段：建议额外优化

> **维护模式默认跳过本阶段**，除非用户明确要求。

告诉用户，现在 CLAUDE.md 和技能（如果已选择）已经就位，你将建议几个额外的优化项。

检查环境，并针对发现的每个缺口提问（使用 AskUserQuestion）：

- **GitHub CLI**：运行 `which gh`（Windows 上用 `where gh`）。如果缺失，且项目使用 GitHub（检查 `git remote -v` 是否有 github.com），询问用户是否想安装它。说明 GitHub CLI 能让 Claude 直接帮助处理提交、拉取请求、问题和代码审查。

- **Linting**：如果第 2 阶段没发现 lint 配置（针对项目语言没有 .eslintrc、ruff.toml、.golangci.yml 等），询问用户是否希望 Claude 为这个代码库设置 linting。说明 linting 可以及早发现问题，并为 Claude 自己的编辑提供快速反馈。

- **来自提案的 hooks**（如果用户选择了 “Skills + hooks” 或 “Hooks only”）：消费第 3 阶段偏好队列中的 `hook` 条目。如果第 2 阶段发现了格式化器，而队列中没有格式化 hook，则把编辑后自动格式化作为兜底建议。如果用户在第 1 阶段选择了 “Neither” 或 “Skills only”，则完全跳过这一条。

  对于每个 hook 偏好（来自队列或格式化兜底）：

  1. 目标文件：默认基于第 1 阶段的 CLAUDE.md 选择——project → `.claude/settings.json`（团队共享、会提交）；personal → `.claude/settings.local.json`。只有当用户在第 1 阶段选择了 “both” 或该偏好存在歧义时才询问。针对所有 hooks 只问一次，不要每个 hook 都问。

  2. 根据偏好选择事件和 matcher：
     - “after every edit” → `PostToolUse`，matcher 为 `Write|Edit`
     - “when Claude finishes” / “before I review” → `Stop` 事件（在每轮结束时触发——包括只读轮次）
     - “before running bash” → `PreToolUse`，matcher 为 `Bash`
     - “before committing”（字面意义上的 git-commit 门禁）→ **不是 hooks.json hook。** matcher 不能按 Bash 命令内容过滤，所以无法只针对 `git commit`。应将其路由到 git pre-commit hook（`.git/hooks/pre-commit`、husky、pre-commit framework）——可以提议帮忙编写。如果用户真正想表达的是 “在我审查并提交 Claude 的输出之前”，那就是 `Stop`——需要进一步追问以消除歧义。
     如果偏好有歧义，就追问。

  3. **加载 hook 参考**（每次 `/claudemd` 运行只做一次，在第一个 hook 之前）：调用 Skill 工具，传入 `skill: 'update-config'`，参数以 `[hooks-only]` 开头，后跟一行你正在构建内容的摘要——例如，`[hooks-only] Constructing a PostToolUse/Write|Edit format hook for .claude/settings.json using ruff`。这会把 hooks 的 schema 和验证流程加载进上下文。后续 hooks 复用它——不要重复调用。

  4. 遵循该技能中的 **“Constructing a Hook”** 流程：去重检查 → 针对此项目构建 → 原始管道测试 → 包装 → 写入 JSON → `jq -e` 校验 → 实际证明（对于可触发 matcher 的 `Pre|PostToolUse`）→ 清理 → 交接。目标文件和事件/matcher 来自上面的第 1-2 步。

对每个 “yes” 都先执行，再继续下一项。

## 第 8 阶段：总结和后续步骤

> **维护模式默认跳过本阶段**，除非用户明确要求。

回顾已设置的内容——写了哪些文件，以及每个文件中包含的关键点。提醒用户这些文件只是起点：他们应该审阅并调整，也可以随时再次运行 `/claudemd` 来重新扫描。

然后告诉用户，基于你的发现，你将再介绍一些优化其代码库和 Claude Code 设置的建议。将这些建议整理成一个格式良好的单一待办列表，其中每一项都必须与此仓库相关。把影响最大的项放在最前面。

构建列表时，按以下检查项进行，只包含适用的内容：
- 如果检测到了前端代码（React、Vue、Svelte 等）：`/plugin install frontend-design@claude-plugins-official` 为 Claude 提供设计原则和组件模式，从而生成更精致的 UI；`/plugin install playwright@claude-plugins-official` 让 Claude 启动真实浏览器、为其构建内容截图，并自行修复视觉 bug。
- 如果你在第 7 阶段发现了缺口（缺少 GitHub CLI、缺少 linting），且用户拒绝了：把它们列在这里，并用一句话说明各自为什么有帮助。
- 如果测试缺失或很稀疏：建议设置测试框架，以便 Claude 能验证自己的变更。
- 为了帮助你使用 evals 创建技能和优化现有技能，Claude Code 有一个官方的 skill-creator 插件可安装。使用 `/plugin install skill-creator@claude-plugins-official` 安装，然后运行 `/skill-creator <skill-name>` 来创建新技能或改进任何现有技能。（这一项始终要包含。）
- 使用 `/plugin` 浏览官方插件——这些插件打包了技能、代理、hooks 和 MCP 服务器，你可能会觉得有帮助。你也可以创建自己的自定义插件并与他人共享。（这一项始终要包含。）
