#Requires -Version 5.1
<#
.SYNOPSIS
  Regenerate platform registries + User_Manual/manual.html on Windows without needing `bash` on PATH.

.USAGE
  From repo root:
    powershell -ExecutionPolicy Bypass -File .\scripts\regenerate-all-windows.ps1

  Or from Cursor / VS Code terminal (PowerShell):
    .\scripts\regenerate-all-windows.ps1
#>

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

function ConvertTo-MsysPath([string]$WinPath) {
    if ($WinPath -match '^([A-Za-z]):\\(.*)$') {
        $d = $Matches[1].ToLower()
        $rest = $Matches[2] -replace '\\', '/'
        return "/$d/$rest"
    }
    return ($WinPath -replace '\\', '/')
}
$MsysRoot = ConvertTo-MsysPath $Root

function Find-GitBash {
    $candidates = @(
        "${env:ProgramFiles}\Git\bin\bash.exe",
        "${env:ProgramFiles}\Git\usr\bin\bash.exe",
        "${env:LocalAppData}\Programs\Git\bin\bash.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    $w = Get-Command bash -ErrorAction SilentlyContinue
    if ($w) { return $w.Source }
    return $null
}

function Find-Node {
    $n = Get-Command node -ErrorAction SilentlyContinue
    if ($n) { return $n.Source }
    $candidates = @(
        "${env:ProgramFiles}\nodejs\node.exe",
        "${env:ProgramFiles(x86)}\nodejs\node.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

$bash = Find-GitBash
if (-not $bash) {
    Write-Error @"
Git Bash not found. Install Git for Windows from https://git-scm.com/download/win
Or add Git's bin folder to your PATH (e.g. C:\Program Files\Git\bin).
"@
}

$node = Find-Node
if (-not $node) {
    Write-Error @"
Node.js not found. Install LTS from https://nodejs.org/ or ensure `node` is on PATH.
"@
}

Write-Host "Using bash: $bash" -ForegroundColor Cyan
Write-Host "Using node: $node" -ForegroundColor Cyan
Write-Host ""

& $bash -lc "cd '$MsysRoot' && ./scripts/regenerate-registries.sh --update"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
& $node "$Root\User_Manual\build-manual-html.mjs"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Done: registries + manual.html" -ForegroundColor Green
