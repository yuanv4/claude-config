#!/usr/bin/env pwsh
# Claude Code 配置安装脚本（PowerShell）
# 用法: .\install.ps1 [--dry-run] [--force]

$ErrorActionPreference = "Stop"

$ConfigDir = $PSScriptRoot
$BackupDir = Join-Path $ConfigDir ".backup"
$DryRun = $false
$Force = $false
$ShowHelp = $false

# 解析参数
for ($i = 0; $i -lt $Args.Count; $i++) {
  switch ($Args[$i]) {
    "-n" { $DryRun = $true }
    "--dry-run" { $DryRun = $true }
    "-f" { $Force = $true }
    "--force" { $Force = $true }
    "-h" { $ShowHelp = $true }
    "--help" { $ShowHelp = $true }
    default {
      Write-Host "未知选项: $($Args[$i])"
      Write-Host "使用 --help 查看帮助"
      exit 1
    }
  }
}

if ($ShowHelp) {
  Write-Host "用法: .\install.ps1 [选项]"
  Write-Host ""
  Write-Host "选项:"
  Write-Host "  -n, --dry-run  预览更改（不执行）"
  Write-Host "  -f, --force    强制覆盖冲突项"
  Write-Host "  -h, --help     显示帮助"
  exit 0
}

# 创建带时间戳的备份目录
function New-BackupPath {
  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $backupPath = Join-Path $BackupDir $timestamp
  New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
  return $backupPath
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
    return $resolved.Path ?? $candidate
  } catch {
    return $null
  }
}

# 备份文件或目录
function Backup-Item {
  param(
    [string]$Src,
    [string]$BackupPath
  )

  $relative = $Src
  if ($Src.StartsWith($HOME, [System.StringComparison]::OrdinalIgnoreCase)) {
    $relative = $Src.Substring($HOME.Length).TrimStart('\','/')
  } else {
    $relative = Split-Path -Leaf $Src
  }

  $dest = Join-Path $BackupPath $relative
  $destDir = Split-Path -Parent $dest
  New-Item -ItemType Directory -Path $destDir -Force | Out-Null

  if (Test-IsLink $Src) {
    $target = Get-LinkTarget $Src
    Set-Content -Path "$dest.symlink" -Value $target
    return
  }

  if (Test-Path -LiteralPath $Src -PathType Container) {
    Copy-Item -LiteralPath $Src -Destination $dest -Recurse -Force
  } else {
    Copy-Item -LiteralPath $Src -Destination $dest -Force
  }
}

# 写入清单
function Write-Manifest {
  param(
    [string]$BackupPath,
    [string]$Operation,
    [string[]]$Items
  )

  $payload = @{
    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    operation = $Operation
    items = $Items
  }
  $json = $payload | ConvertTo-Json -Depth 5
  Set-Content -Path (Join-Path $BackupPath "manifest.json") -Value $json
}

# 检查是否有冲突（本地存在且不是指向仓库的软链接）
function Has-Conflict {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return $false
  }

  if (-not (Test-IsLink $Path)) {
    return $true
  }

  $target = Get-LinkTarget $Path
  if (-not $target) {
    return $true
  }

  $configRoot = (Resolve-Path -LiteralPath $ConfigDir).Path.TrimEnd('\','/')
  $prefix = $configRoot + [IO.Path]::DirectorySeparatorChar
  return -not ($target.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase))
}

# 处理冲突
function Handle-Conflict {
  param(
    [string]$Src,
    [string]$Dest,
    [string]$BackupPath,
    [string]$ItemName
  )

  if ($Force) {
    Backup-Item $Dest $BackupPath
    return $true
  }

  Write-Host ""
  Write-Host "冲突: $ItemName 本地已存在且与仓库不同" -ForegroundColor Yellow
  Write-Host "  本地: $Dest"
  Write-Host "  仓库: $Src"
  Write-Host ""
  Show-ItemDiff $Src $Dest $ItemName
  Write-Host ""
  Write-Host "选项:"
  Write-Host "  [r] 使用仓库版本（备份本地）"
  Write-Host "  [l] 保留本地版本（跳过）"
  Write-Host "  [q] 退出"

  while ($true) {
    $choice = Read-Host "选择 [r/l/q]"
    switch ($choice.ToLowerInvariant()) {
      "r" {
        Backup-Item $Dest $BackupPath
        return $true
      }
      "l" {
        return $false
      }
      "q" {
        Write-Host "已取消。"
        exit 1
      }
      default {
        Write-Host "无效选择，请输入 r、l 或 q。"
      }
    }
  }
}

function Show-ItemDiff {
  param(
    [string]$Src,
    [string]$Dest,
    [string]$ItemName
  )

  Write-Host ""
  Write-Host "差异: $ItemName" -ForegroundColor Cyan

  try {
    $diffText = & git --no-pager diff --no-index --patch --no-color --unified=3 -- $Dest $Src
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
      if ($diffText) {
        $diffText | ForEach-Object { Write-Host $_ }
        return
      }
    }
  } catch {
    # 继续回退方案
  }

  if (-not (Test-Path -LiteralPath $Dest -PathType Leaf) -or -not (Test-Path -LiteralPath $Src -PathType Leaf)) {
    Write-Host "无法显示差异：需要 git 或文件内容可读。" -ForegroundColor Yellow
    return
  }

  $local = Get-Content -LiteralPath $Dest -ErrorAction SilentlyContinue
  $repo = Get-Content -LiteralPath $Src -ErrorAction SilentlyContinue
  if ($null -eq $local -or $null -eq $repo) {
    Write-Host "无法读取文件内容以显示差异。" -ForegroundColor Yellow
    return
  }

  $diff = Compare-Object $local $repo -IncludeEqual:$false
  if (-not $diff) {
    $localHash = (Get-FileHash -LiteralPath $Dest -Algorithm SHA256).Hash
    $repoHash = (Get-FileHash -LiteralPath $Src -Algorithm SHA256).Hash
    if ($localHash -eq $repoHash) {
      Write-Host "内容一致，但本地不是指向仓库的软链接。" -ForegroundColor Yellow
    } else {
      Write-Host "未检测到差异（可能是行结尾差异或比较受限）。" -ForegroundColor Yellow
    }
    return
  }

  foreach ($line in $diff) {
    $prefix = if ($line.SideIndicator -eq "<=") { "- " } else { "+ " }
    Write-Host ($prefix + $line.InputObject)
  }
}

function Dry-RunMsg {
  param([string]$Text)
  Write-Host "[预览] $Text" -ForegroundColor Blue
}

function Ensure-Link {
  param(
    [string]$Src,
    [string]$Dest,
    [string]$ItemName
  )

  if ($DryRun) {
    if (Has-Conflict $Dest) {
      Dry-RunMsg "将备份并替换 $ItemName"
    } else {
      Dry-RunMsg "将创建软链接 $ItemName"
    }
    return
  }

  $destParent = Split-Path -Parent $Dest
  if ($destParent) {
    New-Item -ItemType Directory -Path $destParent -Force | Out-Null
  }

  if (Has-Conflict $Dest) {
    if (-not $script:BackupPath) {
      $script:BackupPath = New-BackupPath
    }
    if (Handle-Conflict $Src $Dest $script:BackupPath $ItemName) {
      $script:BackedUpItems += $ItemName
      Remove-Item -LiteralPath $Dest -Force -Recurse
      try {
        New-Item -ItemType SymbolicLink -Path $Dest -Target $Src -Force | Out-Null
      } catch {
        Write-Host "无法创建软链接：需要以管理员运行 PowerShell。" -ForegroundColor Yellow
        throw
      }
      Write-Host "OK $ItemName（已替换，备份已保存）" -ForegroundColor Green
    } else {
      Write-Host "SKIP $ItemName（保留本地）" -ForegroundColor Yellow
    }
  } else {
    Remove-Item -LiteralPath $Dest -Force -Recurse -ErrorAction SilentlyContinue
    try {
      New-Item -ItemType SymbolicLink -Path $Dest -Target $Src -Force | Out-Null
    } catch {
      Write-Host "无法创建软链接：需要以管理员运行 PowerShell。" -ForegroundColor Yellow
      throw
    }
    Write-Host "OK $ItemName" -ForegroundColor Green
  }
}

# 主安装流程
if ($DryRun) {
  Write-Host "预览模式 - 显示将执行的操作:"
  Write-Host ""
} else {
  Write-Host "正在从 $ConfigDir 安装 Claude Code 配置"
  Write-Host ""
}

$script:BackupPath = $null
$script:BackedUpItems = @()

$claudeDir = Join-Path $HOME ".claude"
if (-not $DryRun) {
  New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

# Settings
$settingsSrc = Join-Path $ConfigDir "settings.json"
if (Test-Path -LiteralPath $settingsSrc) {
  Ensure-Link $settingsSrc (Join-Path $claudeDir "settings.json") "settings.json"
}

# Statusline
$statuslineSrc = Join-Path $ConfigDir "statusline.sh"
if (Test-Path -LiteralPath $statuslineSrc) {
  Ensure-Link $statuslineSrc (Join-Path $claudeDir "statusline.sh") "statusline.sh"
}

# Skills（目录软链接）
$skillsDir = Join-Path $ConfigDir "skills"
if (Test-Path -LiteralPath $skillsDir) {
  $skillDirs = Get-ChildItem -LiteralPath $skillsDir -Directory -ErrorAction SilentlyContinue
  if ($skillDirs) {
    $skillsTarget = Join-Path $claudeDir "skills"
    if (-not $DryRun) {
      New-Item -ItemType Directory -Path $skillsTarget -Force | Out-Null
    }
    foreach ($skill in $skillDirs) {
      if ($skill.Name -eq ".gitkeep") { continue }
      Ensure-Link $skill.FullName (Join-Path $skillsTarget $skill.Name) ("skills/$($skill.Name)")
    }
  }
}

# Agents（文件软链接）
$agentsDir = Join-Path $ConfigDir "agents"
if (Test-Path -LiteralPath $agentsDir) {
  $agentFiles = Get-ChildItem -LiteralPath $agentsDir -Filter "*.md" -File -ErrorAction SilentlyContinue
  if ($agentFiles) {
    $agentsTarget = Join-Path $claudeDir "agents"
    if (-not $DryRun) {
      New-Item -ItemType Directory -Path $agentsTarget -Force | Out-Null
    }
    foreach ($agent in $agentFiles) {
      Ensure-Link $agent.FullName (Join-Path $agentsTarget $agent.Name) ("agents/$($agent.Name)")
    }
  }
}

# Rules（文件软链接）
$rulesDir = Join-Path $ConfigDir "rules"
if (Test-Path -LiteralPath $rulesDir) {
  $ruleFiles = Get-ChildItem -LiteralPath $rulesDir -Filter "*.md" -File -ErrorAction SilentlyContinue
  if ($ruleFiles) {
    $rulesTarget = Join-Path $claudeDir "rules"
    if (-not $DryRun) {
      New-Item -ItemType Directory -Path $rulesTarget -Force | Out-Null
    }
    foreach ($rule in $ruleFiles) {
      Ensure-Link $rule.FullName (Join-Path $rulesTarget $rule.Name) ("rules/$($rule.Name)")
    }
  }
}

# Commands（文件软链接）
$commandsDir = Join-Path $ConfigDir "commands"
if (Test-Path -LiteralPath $commandsDir) {
  $commandFiles = Get-ChildItem -LiteralPath $commandsDir -Filter "*.md" -File -ErrorAction SilentlyContinue
  if ($commandFiles) {
    $commandsTarget = Join-Path $claudeDir "commands"
    if (-not $DryRun) {
      New-Item -ItemType Directory -Path $commandsTarget -Force | Out-Null
    }
    foreach ($command in $commandFiles) {
      Ensure-Link $command.FullName (Join-Path $commandsTarget $command.Name) ("commands/$($command.Name)")
    }
  }
}

Write-Host ""

if ($DryRun) {
  Write-Host "不带 --dry-run 运行以执行更改。"
} else {
  if ($script:BackupPath -and $script:BackedUpItems.Count -gt 0) {
    Write-Manifest $script:BackupPath "install" $script:BackedUpItems
    Write-Host "备份已保存: $script:BackupPath" -ForegroundColor Blue
    Write-Host "运行 '.\sync.ps1 undo' 可恢复。"
    Write-Host ""
  }

  Write-Host "完成！Claude Code 配置已安装。"
  Write-Host ""
  Write-Host "~/.claude/ 中的本地专有文件已保留。"
  Write-Host "使用 .\sync.ps1 管理同步内容。"
  Write-Host ""
  Write-Host "注意: 如有敏感配置，请确保 ~/.claude/settings.local.json 存在。" -ForegroundColor Yellow
}
