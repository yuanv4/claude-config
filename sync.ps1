#!/usr/bin/env pwsh
# Claude Code 配置同步脚本（精简版）
# 用法: .\sync.ps1 [命令] [类型] [名称]

$ErrorActionPreference = "Stop"

$ConfigDir = $PSScriptRoot
$ClaudeDir = Join-Path $HOME ".claude"

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

function Show-Help {
  Write-Host "Claude 配置同步（精简版）"
  Write-Host "========================"
  Write-Host ""
  Write-Host "用法:"
  Write-Host "  .\sync.ps1 add <类型> <名称>    添加本地项到仓库"
  Write-Host "  .\sync.ps1 remove <类型> <名称> 从仓库移除（保留本地）"
  Write-Host "  .\sync.ps1 pull                 拉取并重新安装"
  Write-Host "  .\sync.ps1 push                 提交并推送更改"
  Write-Host ""
  Write-Host "类型: skill, agent, rule, command"
}

function Assert-EnvironmentReady {
  param(
    [string]$Command,
    [string]$Type
  )

  if ($Command -in @("add", "remove", "pull")) {
    if (-not (Test-Path -LiteralPath $ClaudeDir -PathType Container)) {
      Write-Host "错误: 未检测到 Claude 配置目录: $ClaudeDir"
      Write-Host "请先执行 .\install.ps1 初始化环境。"
      exit 1
    }
  }

  if ($Command -in @("add", "remove")) {
    $subDir = switch ($Type) {
      "skill" { "skills" }
      "agent" { "agents" }
      "rule" { "rules" }
      "command" { "commands" }
      default { $null }
    }

    if ($subDir) {
      $targetDir = Join-Path $ClaudeDir $subDir
      if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        Write-Host "错误: 未检测到目录: $targetDir"
        Write-Host "请先执行 .\install.ps1 初始化环境，或手动创建该目录。"
        exit 1
      }
    }
  }
}

function Add-Skill {
  param([string]$Name)
  $src = Join-Path $HOME ".claude\skills\$Name"
  $dest = Join-Path $ConfigDir "skills\$Name"

  if (-not (Test-Path -LiteralPath $src -PathType Container)) {
    Write-Host "错误: Skill 不存在于 $src"
    exit 1
  }

  if (Test-IsLink $src) {
    $target = Get-LinkTarget $src
    if ($target -and $target.StartsWith($ConfigDir, [System.StringComparison]::OrdinalIgnoreCase)) {
      Write-Host "错误: '$Name' 已经在同步中"
      exit 1
    }
  }

  Write-Host "正在将 skill '$Name' 添加到仓库..."
  New-Item -ItemType Directory -Path (Join-Path $ConfigDir "skills") -Force | Out-Null
  Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force
  Remove-Item -LiteralPath $src -Recurse -Force
  New-Item -ItemType SymbolicLink -Path $src -Target $dest -Force | Out-Null
  Write-Host "✓ Skill '$Name' 已添加并创建软链接" -ForegroundColor Green
}

function Add-File {
  param(
    [string]$Type,
    [string]$Name
  )
  $src = Join-Path $HOME ".claude\$Type\$Name.md"
  $dest = Join-Path $ConfigDir "$Type\$Name.md"

  if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
    Write-Host "错误: $($Type.TrimEnd('s')) 不存在于 $src"
    exit 1
  }

  if (Test-IsLink $src) {
    $target = Get-LinkTarget $src
    if ($target -and $target.StartsWith($ConfigDir, [System.StringComparison]::OrdinalIgnoreCase)) {
      Write-Host "错误: '$Name' 已经在同步中"
      exit 1
    }
  }

  Write-Host "正在将 $($Type.TrimEnd('s')) '$Name' 添加到仓库..."
  New-Item -ItemType Directory -Path (Join-Path $ConfigDir $Type) -Force | Out-Null
  Copy-Item -LiteralPath $src -Destination $dest -Force
  Remove-Item -LiteralPath $src -Force
  New-Item -ItemType SymbolicLink -Path $src -Target $dest -Force | Out-Null
  Write-Host "✓ $($Type.TrimEnd('s')) '$Name' 已添加并创建软链接" -ForegroundColor Green
}

function Remove-Skill {
  param([string]$Name)
  $src = Join-Path $HOME ".claude\skills\$Name"
  $dest = Join-Path $ConfigDir "skills\$Name"

  if (-not (Test-Path -LiteralPath $dest -PathType Container)) {
    Write-Host "错误: Skill '$Name' 不在仓库中"
    exit 1
  }

  Write-Host "正在从仓库移除 skill '$Name'..."
  if (Test-IsLink $src) {
    $target = Get-LinkTarget $src
    if ($target -and $target.StartsWith($ConfigDir, [System.StringComparison]::OrdinalIgnoreCase)) {
      Remove-Item -LiteralPath $src -Force
      Copy-Item -LiteralPath $dest -Destination $src -Recurse -Force
    }
  }
  Remove-Item -LiteralPath $dest -Recurse -Force
  Write-Host "✓ Skill '$Name' 已从仓库移除（保留为本地）" -ForegroundColor Green
}

function Remove-File {
  param(
    [string]$Type,
    [string]$Name
  )
  $src = Join-Path $HOME ".claude\$Type\$Name.md"
  $dest = Join-Path $ConfigDir "$Type\$Name.md"

  if (-not (Test-Path -LiteralPath $dest -PathType Leaf)) {
    Write-Host "错误: $($Type.TrimEnd('s')) '$Name' 不在仓库中"
    exit 1
  }

  Write-Host "正在从仓库移除 $($Type.TrimEnd('s')) '$Name'..."
  if (Test-IsLink $src) {
    $target = Get-LinkTarget $src
    if ($target -and $target.StartsWith($ConfigDir, [System.StringComparison]::OrdinalIgnoreCase)) {
      Remove-Item -LiteralPath $src -Force
      Copy-Item -LiteralPath $dest -Destination $src -Force
    }
  }
  Remove-Item -LiteralPath $dest -Force
  Write-Host "✓ $($Type.TrimEnd('s')) '$Name' 已从仓库移除（保留为本地）" -ForegroundColor Green
}

function Pull-Changes {
  Write-Host "正在拉取最新更改..."
  Push-Location $ConfigDir
  & git pull
  Write-Host ""
  Write-Host "重新运行安装..."
  & (Join-Path $ConfigDir "install.ps1")
  Pop-Location
}

function Push-Changes {
  Push-Location $ConfigDir
  $status = & git status --porcelain
  if (-not $status) {
    Write-Host "没有更改需要推送 - 工作区干净"
    Pop-Location
    exit 0
  }

  Write-Host "待推送的更改:"
  & git status --short
  Write-Host ""
  $msg = Read-Host "提交信息（或 Ctrl+C 取消）"
  & git add -A
  & git commit -m $msg
  & git push
  Pop-Location

  Write-Host "✓ 已推送到远程" -ForegroundColor Green
}

$command = $Args[0]
$type = $Args[1]
$name = $Args[2]

switch ($command) {
  "add" {
    if (-not $type -or -not $name) {
      Write-Host "用法: .\sync.ps1 add <类型> <名称>"
      Write-Host "类型: skill, agent, rule, command"
      exit 1
    }
    Assert-EnvironmentReady "add" $type
    switch ($type) {
      "skill" { Add-Skill $name }
      "agent" { Add-File "agents" $name }
      "rule" { Add-File "rules" $name }
      "command" { Add-File "commands" $name }
      default { Write-Host "未知类型: $type（可用: skill, agent, rule, command）"; exit 1 }
    }
  }
  "remove" {
    if (-not $type -or -not $name) {
      Write-Host "用法: .\sync.ps1 remove <类型> <名称>"
      Write-Host "类型: skill, agent, rule, command"
      exit 1
    }
    Assert-EnvironmentReady "remove" $type
    switch ($type) {
      "skill" { Remove-Skill $name }
      "agent" { Remove-File "agents" $name }
      "rule" { Remove-File "rules" $name }
      "command" { Remove-File "commands" $name }
      default { Write-Host "未知类型: $type（可用: skill, agent, rule, command）"; exit 1 }
    }
  }
  "pull" {
    Assert-EnvironmentReady "pull" $null
    Pull-Changes
  }
  "push" { Push-Changes }
  "-h" { Show-Help }
  "--help" { Show-Help }
  default { Show-Help }
}
