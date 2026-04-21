<#
.SYNOPSIS
    Native PowerShell ADO helper — no admin, no bash, no WSL, no pip.
    Works on any Windows machine with PowerShell 5.1+ and curl.exe (built into Windows 10+).

.USAGE
    # Load env first (once per terminal session):
    . scripts\ado.ps1 -LoadEnv

    # Then run any command:
    powershell -File scripts\ado.ps1 description 863476 --file=stories\MS-FamilyHub-Phase1.md
    powershell -File scripts\ado.ps1 show       863476
    powershell -File scripts\ado.ps1 comment    863476 "Reviewed and approved"
    powershell -File scripts\ado.ps1 update     863476 --state=Active
    powershell -File scripts\ado.ps1 push-story stories\SS-FamilyHub-01.md
    powershell -File scripts\ado.ps1 list       --type=story
    powershell -File scripts\ado.ps1 link       863476 863480

.NOTES
    Reads credentials from env\.env in the repo root (or parent dirs).
    No installation required beyond PowerShell and curl.exe.
#>

param(
    [Parameter(Position=0)] [string]$Command = "help",
    [Parameter(Position=1)] [string]$Arg1    = "",
    [Parameter(Position=2)] [string]$Arg2    = "",
    [string]$file    = "",
    [string]$state   = "",
    [string]$type    = "story",
    [string]$title   = "",
    [string]$parent  = "",
    [string]$pushType = "story",
    [switch]$LoadEnv
)

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ── Locate and load env\.env ─────────────────────────────────────────────────
function Find-EnvFile {
    $dir = (Get-Location).Path
    for ($i = 0; $i -lt 6; $i++) {
        $candidate = Join-Path $dir "env\.env"
        if (Test-Path $candidate) { return $candidate }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    return $null
}

function Load-Env {
    $envFile = Find-EnvFile
    if (-not $envFile) {
        Write-Warning "env\.env not found. Set ADO_PAT, ADO_ORG, ADO_PROJECT manually or run from the repo root."
        return
    }
    Get-Content $envFile | Where-Object { $_ -match '^\s*[A-Z_]+=.+' -and $_ -notmatch '^\s*#' } | ForEach-Object {
        $k, $v = $_ -split '=', 2
        [System.Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim().Trim('"'), "Process")
    }
    Write-Host "Loaded: $envFile"
}

Load-Env   # always auto-load

$pat     = $env:ADO_PAT
$org     = $env:ADO_ORG
$project = $env:ADO_PROJECT

if ($LoadEnv) { return }   # caller just wanted to source env

function Assert-Creds {
    if (-not $pat -or -not $org -or -not $project) {
        Write-Error "ADO_PAT, ADO_ORG, ADO_PROJECT must be set in env\.env`nExample: ADO_PAT=your-pat  ADO_ORG=your-ado-org  ADO_PROJECT=YourAzureProject"
        exit 1
    }
}

# ── HTTP helpers ─────────────────────────────────────────────────────────────
function Invoke-Ado($method, $path, $bodyFile = $null, $contentType = "application/json") {
    $url = "https://dev.azure.com/$org/$project/_apis/wit/$($path)?api-version=7.0"
    $args = @("-s", "-X", $method, "-u", ":$pat", "-H", "Content-Type: $contentType")
    if ($bodyFile) { $args += @("--data-binary", "@$bodyFile") }
    $args += $url
    $raw = & curl.exe @args 2>&1
    return $raw
}

function Invoke-AdoUrl($method, $url, $bodyFile = $null, $contentType = "application/json") {
    $args = @("-s", "-X", $method, "-u", ":$pat", "-H", "Content-Type: $contentType")
    if ($bodyFile) { $args += @("--data-binary", "@$bodyFile") }
    $args += $url
    return (& curl.exe @args 2>&1)
}

function Write-Tmp($content) {
    $tmp = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmp, $content, [System.Text.Encoding]::UTF8)
    return $tmp
}

function Remove-Tmp($path) { if ($path -and (Test-Path $path)) { Remove-Item $path -Force -EA SilentlyContinue } }

function Check-Success($raw, $wiId) {
    if ($raw -match '"id"\s*:\s*' + $wiId) {
        $rev = ([regex]::Match($raw, '"rev"\s*:\s*(\d+)')).Groups[1].Value
        Write-Host "SUCCESS — WI $wiId updated (rev $rev)"
    } elseif ($raw -match '"message"\s*:\s*"([^"]+)"') {
        Write-Warning "ADO error: $($Matches[1])"
    } else {
        Write-Host $raw.Substring(0, [Math]::Min(800, $raw.Length))
    }
}

# ── Markdown → HTML (no external deps) ───────────────────────────────────────
function Convert-MdToHtml([string]$text) {
    $lines   = $text -split "`n"
    $sb      = [System.Text.StringBuilder]::new()
    $inUl    = $false; $inTable = $false; $firstRow = $true

    foreach ($raw in $lines) {
        $l = $raw.TrimEnd()
        if ($l -match '^---+$') {
            if ($inUl)    { [void]$sb.Append("</ul>");    $inUl = $false }
            if ($inTable) { [void]$sb.Append("</table>"); $inTable = $false }
            [void]$sb.Append("<hr/>"); continue
        }
        if ($l -match '^(#{1,6})\s+(.+)$') {
            if ($inUl)    { [void]$sb.Append("</ul>");    $inUl = $false }
            if ($inTable) { [void]$sb.Append("</table>"); $inTable = $false }
            $lv = $Matches[1].Length
            [void]$sb.Append("<h$lv>$($Matches[2])</h$lv>"); continue
        }
        if ($l -match '^\|') {
            if ($inUl) { [void]$sb.Append("</ul>"); $inUl = $false }
            if (-not $inTable) {
                [void]$sb.Append("<table border='1' cellpadding='4' style='border-collapse:collapse;width:100%'>")
                $inTable = $true; $firstRow = $true
            }
            if ($l -match '^\|[\s:\-\|]+$') { continue }
            $cells = ($l -split '\|') | Where-Object { $_ -ne '' } | ForEach-Object { $_.Trim() }
            $tag   = if ($firstRow) { $firstRow = $false; "th" } else { "td" }
            $row   = "<tr>" + (($cells | ForEach-Object { "<$tag>$_</$tag>" }) -join "") + "</tr>"
            [void]$sb.Append($row); continue
        } else {
            if ($inTable) { [void]$sb.Append("</table>"); $inTable = $false }
        }
        if ($l -match '^\s*[-\*]\s+(.+)$') {
            if (-not $inUl) { [void]$sb.Append("<ul>"); $inUl = $true }
            [void]$sb.Append("<li>$($Matches[1])</li>"); continue
        } else {
            if ($inUl -and $l -ne '') { [void]$sb.Append("</ul>"); $inUl = $false }
        }
        if ($l -eq '') { continue }
        [void]$sb.Append("<p>$l</p>")
    }
    if ($inUl)    { [void]$sb.Append("</ul>") }
    if ($inTable) { [void]$sb.Append("</table>") }

    $r = $sb.ToString()
    $r = [regex]::Replace($r, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    $r = [regex]::Replace($r, '`([^`]+)`',      '<code>$1</code>')
    $r = [regex]::Replace($r, '\[([^\]]+)\]\(([^\)]+)\)', '<a href="$2">$1</a>')
    return $r
}

function Build-PatchJson($field, $value) {
    Add-Type -AssemblyName System.Web.Extensions -EA SilentlyContinue
    try {
        $js = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
        $js.MaxJsonLength = [int]::MaxValue
        return $js.Serialize(@(@{ op = "add"; path = "/fields/$field"; value = $value }))
    } catch {
        # Fallback: manual escape
        $escaped = $value -replace '\\','\\\\' -replace '"','\"' -replace "`r`n",'\n' -replace "`n",'\n' -replace "`t",'\t'
        return "[{`"op`":`"add`",`"path`":`"/fields/$field`",`"value`":`"$escaped`"}]"
    }
}

# ── Commands ──────────────────────────────────────────────────────────────────

function Cmd-Show($wiId) {
    Assert-Creds
    Write-Host "Fetching WI $wiId…"
    $raw = Invoke-Ado "GET" "workitems/$wiId"
    $title = ([regex]::Match($raw, '"System.Title"\s*:\s*"([^"]+)"')).Groups[1].Value
    $state = ([regex]::Match($raw, '"System.State"\s*:\s*"([^"]+)"')).Groups[1].Value
    $type  = ([regex]::Match($raw, '"System.WorkItemType"\s*:\s*"([^"]+)"')).Groups[1].Value
    Write-Host "ID:    $wiId"
    Write-Host "Type:  $type"
    Write-Host "State: $state"
    Write-Host "Title: $title"
    Write-Host "URL:   https://dev.azure.com/$org/$project/_workitems/edit/$wiId"
}

function Cmd-Description($wiId, $filePath) {
    Assert-Creds
    if (-not $filePath -or -not (Test-Path $filePath)) {
        Write-Error "File not found: '$filePath'. Usage: ado.ps1 description <id> --file=<path>"
        exit 1
    }
    Write-Host "Converting '$filePath' to HTML…"
    $md   = Get-Content $filePath -Raw -Encoding UTF8
    $html = Convert-MdToHtml $md
    Write-Host "HTML: $($html.Length) chars — sending to ADO…"
    $json = Build-PatchJson "System.Description" $html
    $tmp  = Write-Tmp $json
    $raw  = Invoke-Ado "PATCH" "workitems/$wiId" $tmp "application/json-patch+json"
    Remove-Tmp $tmp
    Check-Success $raw $wiId
}

function Cmd-Comment($wiId, $text) {
    Assert-Creds
    if (-not $text) { Write-Error "Usage: ado.ps1 comment <id> <text>"; exit 1 }
    $json = Build-PatchJson "System.History" $text
    $tmp  = Write-Tmp $json
    $raw  = Invoke-Ado "PATCH" "workitems/$wiId" $tmp "application/json-patch+json"
    Remove-Tmp $tmp
    Check-Success $raw $wiId
}

function Cmd-Update($wiId, $stateVal) {
    Assert-Creds
    if (-not $stateVal) { Write-Error "Usage: ado.ps1 update <id> --state=<state>"; exit 1 }
    $json = Build-PatchJson "System.State" $stateVal
    $tmp  = Write-Tmp $json
    $raw  = Invoke-Ado "PATCH" "workitems/$wiId" $tmp "application/json-patch+json"
    Remove-Tmp $tmp
    Check-Success $raw $wiId
}

function Cmd-Link($wiId1, $wiId2) {
    Assert-Creds
    $wiUrl = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$wiId2"
    $patch = @(@{ op = "add"; path = "/relations/-"; value = @{
        rel        = "System.LinkTypes.Hierarchy-Reverse"
        url        = $wiUrl
        attributes = @{ comment = "Linked by ado.ps1" }
    }})
    Add-Type -AssemblyName System.Web.Extensions -EA SilentlyContinue
    $js   = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
    $json = $js.Serialize($patch)
    $tmp  = Write-Tmp $json
    $raw  = Invoke-Ado "PATCH" "workitems/$wiId1" $tmp "application/json-patch+json"
    Remove-Tmp $tmp
    Check-Success $raw $wiId1
}

function Cmd-List($wiType) {
    Assert-Creds
    $wiql = @{ query = "SELECT [System.Id],[System.Title],[System.State] FROM WorkItems WHERE [System.TeamProject]='$project' AND [System.WorkItemType]='$wiType' ORDER BY [System.CreatedDate] DESC" }
    Add-Type -AssemblyName System.Web.Extensions -EA SilentlyContinue
    $js   = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
    $json = $js.Serialize($wiql)
    $tmp  = Write-Tmp $json
    $url  = "https://dev.azure.com/$org/$project/_apis/wit/wiql?api-version=7.0"
    $raw  = Invoke-AdoUrl "POST" $url $tmp "application/json"
    Remove-Tmp $tmp
    $ids  = [regex]::Matches($raw, '"id"\s*:\s*(\d+)') | ForEach-Object { $_.Groups[1].Value }
    Write-Host "Work items ($wiType): $($ids -join ', ')"
}

function Cmd-PushStory($filePath) {
    Assert-Creds
    if (-not $filePath -or -not (Test-Path $filePath)) {
        Write-Error "File not found: '$filePath'. Usage: ado.ps1 push-story <file>"
        exit 1
    }
    $md = Get-Content $filePath -Raw -Encoding UTF8

    # Extract title from first # heading
    $titleLine = ($md -split "`n" | Where-Object { $_ -match '^#\s+' } | Select-Object -First 1)
    $storyTitle = if ($titleLine) { $titleLine -replace '^#+\s*', '' } else { [System.IO.Path]::GetFileNameWithoutExtension($filePath) }

    $html = Convert-MdToHtml $md

    Add-Type -AssemblyName System.Web.Extensions -EA SilentlyContinue
    $js = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
    $js.MaxJsonLength = [int]::MaxValue

    $patch = @(
        @{ op = "add"; path = "/fields/System.Title";       value = $storyTitle },
        @{ op = "add"; path = "/fields/System.Description"; value = $html }
    )
    if ($parent) { $patch += @{ op = "add"; path = "/relations/-"; value = @{
        rel = "System.LinkTypes.Hierarchy-Reverse"
        url = "https://dev.azure.com/$org/$project/_apis/wit/workitems/$parent"
    }}}

    $json = $js.Serialize($patch)
    $tmp  = Write-Tmp $json
    $wiInUrl = switch ($pushType.ToLower()) {
        "feature" { "`$Feature" }
        "epic" { "`$Epic" }
        default { "`$User Story" }
    }
    $url  = "https://dev.azure.com/$org/$project/_apis/wit/workitems/${wiInUrl}?api-version=7.0"
    $raw  = Invoke-AdoUrl "POST" $url $tmp "application/json-patch+json"
    Remove-Tmp $tmp

    $newId = ([regex]::Match($raw, '"id"\s*:\s*(\d+)')).Groups[1].Value
    if ($newId) {
        Write-Host "SUCCESS — Created WI $newId: $storyTitle"
        Write-Host "URL: https://dev.azure.com/$org/$project/_workitems/edit/$newId"
    } else {
        Write-Host $raw.Substring(0, [Math]::Min(800, $raw.Length))
    }
}

function Cmd-Help {
    Write-Host @"

ado.ps1 — Native Windows ADO helper (no admin, no bash, no WSL)
Reads env\.env automatically.

COMMANDS
  description <id> --file=<path.md>   Update WI description from markdown file
  show        <id>                     Show WI title, state, URL
  comment     <id> <text>             Add comment / discussion entry
  update      <id> --state=<state>    Update state (Active, Resolved, Closed…)
  push-story  <file.md> [-pushType story|feature|epic]  Create WI from markdown (default: User Story)
  list        --type=<type>           List work items (default: story)
  link        <id1> <id2>             Link id2 as parent of id1

EXAMPLES
  powershell -File scripts\ado.ps1 description 863476 --file=stories\MS-FamilyHub-Phase1.md
  powershell -File scripts\ado.ps1 show 863476
  powershell -File scripts\ado.ps1 comment 863476 "Reviewed OK"
  powershell -File scripts\ado.ps1 update 863476 --state=Active
  powershell -File scripts\ado.ps1 push-story stories\SS-FamilyHub-01.md --parent=863476
  powershell -File scripts\ado.ps1 push-story stories\MS-scope.md -pushType feature
  powershell -File scripts\ado.ps1 list --type="User Story"

REQUIREMENTS  curl.exe (built into Windows 10+), PowerShell 5.1+, no admin needed.
"@
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
switch ($Command.ToLower()) {
    "description" { Cmd-Description $Arg1 $file }
    "show"        { Cmd-Show $Arg1 }
    "comment"     { Cmd-Comment $Arg1 $Arg2 }
    "update"      { Cmd-Update $Arg1 $state }
    "push-story"  { Cmd-PushStory (if ($file) { $file } else { $Arg1 }) }
    "list"        { Cmd-List (if ($type) { $type } else { "User Story" }) }
    "link"        { Cmd-Link $Arg1 $Arg2 }
    "help"        { Cmd-Help }
    default       { Write-Warning "Unknown command: $Command"; Cmd-Help }
}
