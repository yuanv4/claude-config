---
name: git-commit
description: Generate Chinese Conventional Commit messages and run git commit in PowerShell. Use when asked to review Git changes, propose commit message candidates, or perform a commit based on staged changes.
---

# Git Commit Workflow

Execute this workflow to prepare and run commits safely in PowerShell.

## Inspect Changes

1. Run `git status` to confirm staged and unstaged files.
2. Run `git diff --staged` to analyze staged content for commit scope.
3. Run `git diff HEAD` when full-repo context is needed.
4. If staged changes include `.uasset` files and `blueprint-diff` is available, run it to inspect Blueprint-level differences.

## Propose Messages

1. Infer change type using Conventional Commit categories: `feat`, `fix`, `refactor`, `docs`, `test`, `build`, `ci`, `chore`, `perf`, `revert`.
2. Generate 2-4 concise Chinese commit message candidates in format:
`type(scope): 中文摘要`
3. Keep summary action-oriented and specific to staged changes only.
4. If multiple unrelated change groups exist, recommend splitting commits.

## Commit in PowerShell

1. Use the selected candidate to run:
`git commit -m "<message>"`
2. Do not use heredoc syntax in PowerShell.
3. If commit fails due to empty staging area, report it and ask whether to stage files first.

## Output Format

1. Show a short staged-change summary.
2. List candidate messages.
3. State the exact `git commit` command before execution.
4. Report commit result (success or failure) and next action.
