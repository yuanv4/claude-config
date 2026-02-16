---
name: docx-to-md-polisher
description: 将 DOCX 自动通过 Pandoc 转换为 Markdown，并在不改变原文含义的前提下进行结构与排版清理（标题/列表/表格/空行/图片），输出更干净、可 Git 维护的 Markdown
---

# DOCX → Markdown 转换与清理（Pandoc + Polisher）

## 何时使用

- 你拿到的是 **DOCX 文件**（而不是已经转换好的 Markdown），希望自动完成“DOCX → Markdown → 清理”的全流程。
- 输出需要更**干净、结构正确、便于 Git 维护**（标题层级/编号、列表缩进、表格、空行/尾随空格、图片语法统一等）。
- 目标是**转换 + 结构清理与格式标准化**，而不是内容改写/润色。

## 输入 / 输出

- **输入**：一个或多个 `.docx` 文件（可选：用户提供额外要求，如图片导出目录、是否保留参考文献、是否启用某个 Pandoc 选项）。
- **输出**：对应的 `.md` 文件（可能夹杂少量 HTML，如 `<table>`），语义不变、结构更规范、可读性更好、对版本控制更友好。

## 核心原则（必须遵守）

- **不改内容含义**：不新增、不删减、不改写任何正文句子；仅调整结构与排版。
- **不“补全”缺失信息**：原文没写的不要猜测补充。
- **保留代码原样**：代码块内容一字不动（仅处理代码块外的空行/缩进问题）。
- **优先 Markdown，复杂则保留 HTML**：表格若无法用 Markdown 正确表达（如合并单元格），保留为 HTML `<table>`，但不得丢数据。

## 操作步骤（按顺序执行）

0. **DOCX → Markdown（Pandoc 转换）**
   - 使用 Pandoc 将 DOCX 转为 Markdown（推荐 Git 友好输出）：
     - 基础命令示例（可按用户需求调整参数）：
       - `pandoc input.docx -t gfm -o output.md`
   - 若 DOCX 含图片且需要落盘：根据用户要求设置 `--extract-media`（避免擅自改路径/目录结构）。
   - 该步骤的目标是“得到可用的初始 Markdown”，不在此阶段做内容改写。

1. **标题（Headings）**
   - 统一使用 Markdown ATX 标题（`#` / `##` / `###` …），不要使用 Setext（`====`/`----`）风格。
   - 删除多余的编号前缀（不改变标题文本含义）：
     - 例：`## 1.2 Feature Description` → `## Feature Description`
   - 保持原始层级关系，不要凭空升/降级标题。

2. **列表（Lists）**
   - 无序列表统一使用 `-`。
   - 有序列表统一使用 Markdown 自动编号格式：`1.` `2.` `3.`（允许全部写 `1.` 让 Markdown 自动渲染，但需保持结构正确）。
   - 修复嵌套列表缩进（使其在常见渲染器中稳定显示），但**不得合并/拆分/重排**条目。

3. **表格（Tables）**
   - 保留所有行/列与单元格数据，不得丢失。
   - 能用 Markdown 表格表示则整理为规范 Markdown 表格。
   - 遇到合并单元格、复杂排版或转换后破碎的表格：保留/改写为等价的 HTML `<table>`，保证数据完整。

4. **代码块（Code Blocks）**
   - 保留围栏代码块（fenced code block）与语言标注（如 ```js）。
   - 不修改代码块内部任何字符。

5. **图片（Images）**
   - 图片统一为标准 Markdown：`![alt](path)`。
   - 不重命名文件、不改路径；除非用户明确要求。
   - 若缺少 alt 文本，保留现状或使用原转换结果（不要臆造描述性 alt）。

6. **空行与清洁度（Spacing & Cleanliness）**
   - 清理多余空行：段落之间保留 1 个空行即可。
   - 标题前确保有 1 个空行（文件开头标题除外）。
   - 删除行尾多余空格。

## 示例

### 示例 1：标题去编号 + 有序列表规范

**输入：**
```
## 1.2 Feature Description
1) First item
2) Second item
```

**输出：**
```
## Feature Description
1. First item
2. Second item
```

### 示例 2：列表风格与缩进修复

**输入：**
```
- Item one
  - Subitem a
  - Subitem b
2) Item two
```

**输出：**
```
- Item one
  - Subitem a
  - Subitem b
1. Item two
```

### 示例 3：表格保持不变（已规范时不乱动）

**输入：**
```
| Header1 | Header2 |
|---------|---------|
| Row1A   | Row1B   |
| Row2A   | Row2B   |
```

**输出：**
```
| Header1 | Header2 |
|---------|---------|
| Row1A   | Row1B   |
| Row2A   | Row2B   |
```

### 示例 4：图片语法规范化

**输入：**
```
![image](media/img.png)
```

**输出：**
```
![image](media/img.png)
```

## 备注

- 本 Skill 是“**转换 + 清理**”的一条龙流程：先用 Pandoc 从 DOCX 生成 Markdown，再对生成的 Markdown 做结构与排版规范化。
- 目标是生成**干净、结构正确、便于 Git 维护**的 Markdown。
- 避免“智能改写/润色”正文：只做格式与结构修复。