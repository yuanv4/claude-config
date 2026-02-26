#!/usr/bin/env pwsh
# Claude/Codex 配置同步脚本（仓库完全同步版）
# 用法: .\sync.ps1 [sync|--help]

$ErrorActionPreference = "Stop"

$ConfigDir = $PSScriptRoot

# Central sync rules: add/remove entries here to control what gets synced.
$ManagedSyncRules = @(
  @{ RepoPath = "skills";   TargetPath = "skills";   Kind = "dir"  }
  @{ RepoPath = "agents";   TargetPath = "agents";   Kind = "file" }
  @{ RepoPath = "rules";    TargetPath = "rules";    Kind = "file" }
  @{ RepoPath = "commands"; TargetPath = "commands"; Kind = "file" }
)

# Target profiles: add/remove profiles here.
$SyncTargets = @(
  @{
    Name = "claude"
    RootDir = (Join-Path $HOME ".claude")
    ProtectedNames = @{
      skills = @()
    }
  }
  @{
    Name = "codex"
    RootDir = (Join-Path $HOME ".codex")
    ProtectedNames = @{
      skills = @(".system")
    }
  }
)

function Show-Help {
  Write-Host "Claude/Codex 配置同步（仓库完全同步版）"
  Write-Host "======================================"
  Write-Host ""
  Write-Host "用法:"
  Write-Host "  .\sync.ps1 sync    拉取远程、对齐 ~/.claude 和 ~/.codex、提交并推送"
  Write-Host "  .\sync.ps1         默认执行 sync"
  Write-Host ""
  Write-Host "说明:"
  Write-Host "  同步规则可在脚本顶部的 `$ManagedSyncRules / `$SyncTargets 中增删。"
}

function Test-IsLink {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return $false
  }
  $item = Get-Item -LiteralPath $Path -Force
  return ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
}

function Get-LinkTarget {
  param([string]$Path)
  try {
    $item = Get-Item -LiteralPath $Path -Force
    $target = $item.Target
    if ($target -is [array]) {
      $target = $target[0]
    }
    if (-not $target) {
      return $null
    }
    if ([IO.Path]::IsPathRooted($target)) {
      return $target
    }
    $base = Split-Path -Parent $Path
    $candidate = Join-Path $base $target
    $resolved = Resolve-Path -LiteralPath $candidate -ErrorAction SilentlyContinue
    if ($resolved) {
      return $resolved.Path
    }
    return $candidate
  } catch {
    return $null
  }
}

function Ensure-SymbolicLink {
  param(
    [string]$Src,
    [string]$Dest,
    [string]$ItemName
  )

  $resolvedSrc = (Resolve-Path -LiteralPath $Src).Path

  if (Test-IsLink $Dest) {
    $target = Get-LinkTarget $Dest
    if ($target) {
      $resolvedTarget = Resolve-Path -LiteralPath $target -ErrorAction SilentlyContinue
      if ($resolvedTarget -and $resolvedTarget.Path -eq $resolvedSrc) {
        Write-Host "OK $ItemName" -ForegroundColor DarkGray
        return
      }
    }
  }

  if (Test-Path -LiteralPath $Dest) {
    Remove-Item -LiteralPath $Dest -Force -Recurse
  }

  $destParent = Split-Path -Parent $Dest
  if ($destParent) {
    New-Item -ItemType Directory -Path $destParent -Force | Out-Null
  }

  try {
    New-Item -ItemType SymbolicLink -Path $Dest -Target $Src -Force | Out-Null
  } catch {
    Write-Host "无法创建软链接: $ItemName" -ForegroundColor Yellow
    Write-Host "请以管理员权限运行 PowerShell 或启用开发者模式。"
    throw
  }

  Write-Host "LINK $ItemName" -ForegroundColor Green
}

function Sync-ManagedDirectory {
  param(
    [string]$SourceDir,
    [string]$TargetDir,
    [string]$Kind,
    [string[]]$ProtectedNames = @()
  )

  $desired = @{}
  if (Test-Path -LiteralPath $SourceDir -PathType Container) {
    if ($Kind -eq "dir") {
      $items = Get-ChildItem -LiteralPath $SourceDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne ".gitkeep" }
    } else {
      $items = Get-ChildItem -LiteralPath $SourceDir -File -Filter "*.md" -ErrorAction SilentlyContinue
    }
    foreach ($item in $items) {
      $desired[$item.Name] = $item.FullName
    }
  }

  New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

  $existing = Get-ChildItem -LiteralPath $TargetDir -Force -ErrorAction SilentlyContinue
  foreach ($entry in $existing) {
    if ($entry.Name.StartsWith(".")) {
      continue
    }
    if ($ProtectedNames -contains $entry.Name) {
      continue
    }
    if (-not $desired.ContainsKey($entry.Name)) {
      Remove-Item -LiteralPath $entry.FullName -Recurse -Force
      Write-Host "REMOVE $($entry.FullName)" -ForegroundColor Yellow
    }
  }

  foreach ($name in $desired.Keys) {
    $dest = Join-Path $TargetDir $name
    Ensure-SymbolicLink $desired[$name] $dest $dest
  }
}

function Apply-ConfigSyncToTarget {
  param([hashtable]$Target)

  $rootDir = $Target.RootDir

  New-Item -ItemType Directory -Path $rootDir -Force | Out-Null

  foreach ($rule in $ManagedSyncRules) {
    $protected = @()
    if ($Target.ProtectedNames -and $Target.ProtectedNames.ContainsKey($rule.TargetPath)) {
      $protected = $Target.ProtectedNames[$rule.TargetPath]
    }
    Sync-ManagedDirectory `
      (Join-Path $ConfigDir $rule.RepoPath) `
      (Join-Path $rootDir $rule.TargetPath) `
      $rule.Kind `
      $protected
  }
}

function Apply-ConfigSync {
  for ($i = 0; $i -lt $SyncTargets.Count; $i++) {
    $target = $SyncTargets[$i]
    Write-Host "正在对齐 ~/$($target.Name) ..."
    Apply-ConfigSyncToTarget $target
    if ($i -lt ($SyncTargets.Count - 1)) {
      Write-Host ""
    }
  }
}

function Sync-Changes {
  Push-Location $ConfigDir
  try {
    Write-Host "正在拉取远程更改..."
    & git pull --rebase

    Write-Host ""
    Apply-ConfigSync

    $status = & git status --porcelain
    if (-not $status) {
      Write-Host ""
      Write-Host "已与远程同步，工作区干净。" -ForegroundColor Green
      return
    }

    Write-Host ""
    Write-Host "检测到本地更改:"
    & git status --short
    Write-Host ""
    $msg = Read-Host "提交信息（留空则跳过推送）"
    if ([string]::IsNullOrWhiteSpace($msg)) {
      Write-Host "已跳过提交与推送。" -ForegroundColor Yellow
      return
    }

    & git add -A
    & git commit -m $msg
    & git push
    Write-Host "✓ 已推送到远程" -ForegroundColor Green
  } finally {
    Pop-Location
  }
}

$command = $Args[0]

switch ($command) {
  "sync" { Sync-Changes }
  "-h" { Show-Help }
  "--help" { Show-Help }
  "" { Sync-Changes }
  $null { Sync-Changes }
  default {
    Write-Host "未知命令: $command"
    Write-Host ""
    Show-Help
    exit 1
  }
}
