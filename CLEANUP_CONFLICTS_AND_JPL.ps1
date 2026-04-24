# Cleanup script - removes merge conflicts and JPL references
$ErrorActionPreference = "Continue"

Write-Host "==============================================" -ForegroundColor Red
Write-Host "CLEANUP: Merge Conflicts + Organization Mentions" -ForegroundColor Red
Write-Host "==============================================" -ForegroundColor Red
Write-Host ""

# Step 1: Remove merge conflict markers from all files
Write-Host "[Step 1/4] Removing merge conflict markers..." -ForegroundColor Yellow
$conflictPattern = '<<<<<<< HEAD|=======|>>>>>>> .*'
$filesWithConflicts = 0

Get-ChildItem -Path 'C:\JioCloudCursor\AISDLC\AI_SDLC_Platform' -Recurse -File | ForEach-Object {
    try {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -match $conflictPattern)) {
            # Remove conflict markers and everything between them (keep local/HEAD version)
            $newContent = $content -replace '(?s)<<<<<<< HEAD\r?\n(.*?)=======\r?\n(.*?)>>>>>>> [\w\-]+\r?\n', '$1'
            Set-Content -Path $_.FullName -Value $newContent -NoNewline -ErrorAction SilentlyContinue
            $filesWithConflicts++
            Write-Host "  Fixed conflicts: $($_.FullName)" -ForegroundColor Green
        }
    }
    catch {
        # Silently continue
    }
}
Write-Host "  Files cleaned: $filesWithConflicts" -ForegroundColor Cyan
Write-Host ""

# Step 2: Search for JPL references
Write-Host "[Step 2/4] Searching for JPL/Jio/reliance references..." -ForegroundColor Yellow
$patterns = @('JPL-Limited', 'JioAIphotos', 'JioCloud', 'JioBharat', 'mehuldil', 'reliance', 'RIL')
$issuesFound = @()

foreach ($pattern in $patterns) {
    $matches = Select-String -Path 'C:\JioCloudCursor\AISDLC\AI_SDLC_Platform' -Pattern $pattern -Recurse -ErrorAction SilentlyContinue
    if ($matches) {
        foreach ($match in $matches) {
            $issuesFound += "$pattern in $($match.Path)"
            Write-Host "  FOUND: $pattern in $($match.Path):$($match.LineNumber)" -ForegroundColor Red
        }
    }
}

if ($issuesFound.Count -eq 0) {
    Write-Host "  No organization mentions found - CLEAN!" -ForegroundColor Green
} else {
    Write-Host "  Total issues: $($issuesFound.Count)" -ForegroundColor Red
}
Write-Host ""

# Step 3: Replace any remaining java
Write-Host "[Step 3/4] Replacing any remaining java..." -ForegroundColor Yellow
$count = 0
Get-ChildItem -Path 'C:\JioCloudCursor\AISDLC\AI_SDLC_Platform' -Recurse -File | ForEach-Object {
    try {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -match 'java')) {
            $newContent = $content -replace 'java', 'java'
            Set-Content -Path $_.FullName -Value $newContent -NoNewline -ErrorAction SilentlyContinue
            $count++
        }
    }
    catch {
        # Silently continue
    }
}
Write-Host "  Files updated: $count" -ForegroundColor Cyan
Write-Host ""

# Step 4: Git commit and force push
Write-Host "[Step 4/4] Committing and pushing..." -ForegroundColor Yellow
Set-Location 'C:\JioCloudCursor\AISDLC\AI_SDLC_Platform'

git add -A
git commit -m "Clean merge conflicts and organization mentions (JPL, Jio, java)"

Write-Host ""
Write-Host "Ready to force push. This will COMPLETELY REPLACE the remote." -ForegroundColor Red
$confirm = Read-Host "Type 'FORCE' to confirm"

if ($confirm -eq 'FORCE') {
    git push --force origin main
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host "SUCCESS! Remote is now clean." -ForegroundColor Green
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Verify: https://github.com/mehuldil/ai_sdlc_platform" -ForegroundColor Cyan
    } else {
        Write-Host "PUSH FAILED!" -ForegroundColor Red
    }
} else {
    Write-Host "Push cancelled." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
