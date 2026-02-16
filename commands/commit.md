---
allowed-tools: Bash(git add:*), Bash(git commit:*)
description: Generate a commit message and commit changes
---

## 上下文

- 显示当前 Git 状态：`!`git status`
- 显示当前差异：`!`git diff HEAD`
- 若存在 .uasset 文件差异，可使用 `blueprint-diff` 分析蓝图差异

## 你的任务

1. 分析已暂存的更改
2. 根据 conventional commit rules 生成中文提交消息候选
3. 使用选定的消息执行 `git commit` 命令，PowerShell **不支持 heredoc 语法**
