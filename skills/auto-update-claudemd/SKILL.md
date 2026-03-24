---
name: auto-update-claudemd
description: 分析 git 变更，将产生的项目知识写入正确层级的 CLAUDE.md（根目录或对应子目录），保持知识库精简准确。
argument-hint: "[可选：分析最近 N 条 commit，默认 1]"
---

# 项目知识维护

## 目标

从 git 变更中提炼项目知识，路由到正确层级的 CLAUDE.md，保持根文件精简、子目录知识就近放置。

## 两层载体

| 载体 | 内容 | 目标行数 |
|------|------|----------|
| 根 `CLAUDE.md` | repo 级全局规则、架构地图、工作流命令 | **30-80 行** |
| 子目录 `CLAUDE.md` | 模块局部约定，就近于代码 | 按需，无硬限制 |

Claude Code 启动时读取根文件；访问子目录时按需加载该目录的 CLAUDE.md。

## 步骤

### 1. 获取变更

```bash
# 单条 commit（默认）
git show --stat --patch --find-renames --format=fuller HEAD

# 最近 N 条 commit
for commit in $(git log -n <N> --format=%H); do
  git show --stat --patch --find-renames --format=fuller "$commit"
done
```

> 多 commit 时，先读完全部 diff 再统一提炼知识，不逐条写入。

### 2. 判断是否产生项目级知识

**写入信号**（命中任一即可）：
- 新增/变更了构建、测试、部署命令或工作流
- 引入/替换了关键框架、运行时、基础依赖
- 调整了目录职责、模块边界、核心数据流
- 形成了新的代码约定、接口约束、组织方式
- 暴露出需要长期记住的限制、陷阱或环境要求

**跳过信号**：
- 纯注释 / 文案 / 排版 / 重命名（未改变职责）
- 局部实现细节，未形成可复用约定
- 仅补测试，未揭示新的业务不变量
- lockfile 变化，未带来新的工具链要求
- **CLAUDE.md 自身的变更**——避免循环更新

**判定标准**：若无法从 diff 中提炼出一句对未来协作仍有价值的项目事实，则跳过。

### 3. 路由

**写根 `CLAUDE.md`**——变更影响整个 repo：
- repo 级工作流命令（dev / build / test / deploy）
- 全局架构边界和禁止事项
- 全仓库通用技术栈摘要（1-2 行，细节下推到子目录）

**写子目录 `CLAUDE.md`**——变更集中在某个模块：
- 写到**变更文件所在目录**的 CLAUDE.md
- 例：`src/auth/` 下的变更 → `src/auth/CLAUDE.md`
- 不要把模块级知识上推到根文件

**目标文件不存在时**：直接创建，首行用 `#` 标题标明模块名称。

### 4. 写入规则

- **更新已有 section**，不按 commit 追加历史
- 已有信息仍准确则保留；发生变化则改写
- 同类信息合并去重
- 用项目事实表述，不引用 commit hash 或 commit message

**对比**：
- NG: `feat(auth): add JWT token refresh`
- OK: `Auth 使用 JWT。Access token 15min，Refresh token 7d，存于 httpOnly cookie。`

### 5. 根文件膨胀检查

写入后检查根 `CLAUDE.md` 行数：

```bash
wc -l CLAUDE.md
```

若超过 **80 行**，审视其中仅对某子目录有效的规则，**下推**到对应子目录的 CLAUDE.md。

## 输出

告知用户：
- 写入了哪个文件（根 / 子目录路径）
- 判断依据（变更范围 + 知识类型）
- 若跳过，说明"未形成项目级知识"
- 若执行了下推，说明移动了哪些规则
