#Requires -Version 5.1
<#
  Windows mirror: canonical repo -> public GitHub checkout (no rsync required).
  Same directory/file excludes as rsync-excludes.txt.
  After robocopy, run Git Bash: bash scripts/mirror-public/sync-to-public-mirror.sh /path/to/dest
  with rsync disabled — or source neutralize-public-mirror.sh and run neutralize_public_mirror,
  then copy overlays (see sync-to-public-mirror.sh).
#>
param(
  [Parameter(Mandatory = $false)]
  [string] $Dest = ""
)

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not $Dest) {
  $Dest = Join-Path (Split-Path $RepoRoot -Parent) "AI_SDLC_Platform"
}
if (-not (Test-Path -LiteralPath $Dest)) {
  New-Item -ItemType Directory -Path $Dest -Force | Out-Null
}
$Dest = (Resolve-Path -LiteralPath $Dest).Path

$Xd = @(
  ".git", ".claude", ".cursor", "node_modules", "stories", ".sdlc"
)
$Xf = @(
  ".env", ".env.local", ".env.production", ".env.staging", "mcp.json", ".mcp.json", ".last-ado-create.json"
)

Write-Host "Source: $RepoRoot"
Write-Host "Dest:   $Dest"
Write-Host ""

$robocopyArgs = @($RepoRoot, $Dest, "/MIR", "/R:2", "/W:2", "/NFL", "/NDL", "/NJH", "/NS", "/NC", "/FFT")
foreach ($d in $Xd) { $robocopyArgs += "/XD"; $robocopyArgs += $d }
foreach ($f in $Xf) { $robocopyArgs += "/XF"; $robocopyArgs += $f }

$proc = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
$code = $proc.ExitCode
if ($code -ge 8) {
  Write-Error "robocopy failed with exit code $code"
  exit $code
}
Write-Host "robocopy completed (exit $code). Next: run neutralize + overlays via Git Bash (sync-to-public-mirror.sh)."
exit 0
