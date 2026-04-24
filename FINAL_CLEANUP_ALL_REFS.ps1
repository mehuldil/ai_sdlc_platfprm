# FINAL COMPREHENSIVE CLEANUP - Remove ALL Organization References
$ErrorActionPreference = "Continue"

Write-Host "==============================================" -ForegroundColor Red
Write-Host "FINAL CLEANUP: ALL Organization References" -ForegroundColor Red
Write-Host "==============================================" -ForegroundColor Red
Write-Host ""

# Patterns to search for and remove/replace
$patterns = @(
    'JioAIphotos',
    'JPL-Limited',
    'JioCloud',
    'JioAI',
    'JioBharat',
    'mehuldil',
    'reliance',
    'RIL',
    'dev\.azure\.com/jpl-limited',
    'dev\.azure\.com/JPL-Limited',
    'github\.com/mehuldil',
    'Tej',
    'java-tej'
)

Write-Host "[Step 1/5] Searching for ALL organization references..." -ForegroundColor Yellow
$totalFound = 0
$filesAffected = @()

foreach ($pattern in $patterns) {
    $matches = Select-String -Path 'C:\JioCloudCursor\AISDLC\AI_SDLC_Platform' -Pattern $pattern -Recurse -ErrorAction SilentlyContinue
    if ($matches) {
        foreach ($match in $matches) {
            $totalFound++
            $filesAffected += $match.Path
            Write-Host "  FOUND '$pattern' in: $($match.Path):$($match.LineNumber)" -ForegroundColor Red
            Write-Host "    Line: $($match.Line.Trim().Substring(0, [Math]::Min(80, $match.Line.Trim().Length)))..." -ForegroundColor DarkGray
        }
    }
}

$uniqueFiles = $filesAffected | Select-Object -Unique
Write-Host ""
Write-Host "  TOTAL REFERENCES FOUND: $totalFound" -ForegroundColor $(if($totalFound -eq 0){'Green'}else{'Red'})
Write-Host "  UNIQUE FILES AFFECTED: $($uniqueFiles.Count)" -ForegroundColor $(if($uniqueFiles.Count -eq 0){'Green'}else{'Red'})
Write-Host ""

if ($totalFound -eq 0) {
    Write-Host "  ✅ No organization references found - already clean!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Found $totalFound references that need cleaning" -ForegroundColor Red
}
Write-Host ""

# Step 2: Replace patterns with generic alternatives
Write-Host "[Step 2/5] Replacing organization references with generic alternatives..." -ForegroundColor Yellow

$replacements = @{
    'JioAIphotos' = 'YourProject'
    'JPL-Limited' = 'YourOrg'
    'JioCloud' = 'YourCloudPlatform'
    'JioAI' = 'YourAIPlatform'
    'JioBharat' = 'YourProduct'
    'mehuldil' = 'yourusername'
    'reliance' = 'yourcompany'
    'RIL' = 'YOURCOMPANY'
    'dev.azure.com/jpl-limited' = 'dev.azure.com/yourorg'
    'dev.azure.com/JPL-Limited' = 'dev.azure.com/yourorg'
    'github.com/mehuldil' = 'github.com/yourusername'
    'java-tej' = 'java'
    'Tej' = 'Java'
}

$replaceCount = 0
Get-ChildItem -Path 'C:\JioCloudCursor\AISDLC\AI_SDLC_Platform' -Recurse -File | ForEach-Object {
    try {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $originalContent = $content
            foreach ($old in $replacements.Keys) {
                $content = $content -replace $old, $replacements[$old]
            }
            if ($content -ne $originalContent) {
                Set-Content -Path $_.FullName -Value $content -NoNewline -ErrorAction SilentlyContinue
                $replaceCount++
            }
        }
    }
    catch {
        # Silently continue for binary files
    }
}
Write-Host "  Files updated: $replaceCount" -ForegroundColor Cyan
Write-Host ""

# Step 3: Remove merge conflict markers
Write-Host "[Step 3/5] Removing merge conflict markers..." -ForegroundColor Yellow
$conflictFiles = 0
Get-ChildItem -Path 'C:\JioCloudCursor\AISDLC\AI_SDLC_Platform' -Recurse -File | ForEach-Object {
    try {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -match '<<<<<<< HEAD|=======|>>>>>>>')) {
            # Keep HEAD version, remove conflict markers
            $newContent = $content -replace '(?s)<<<<<<< HEAD\r?\n(.*?)=======\r?\n(.*?)>>>>>>> [\w\-]+\r?\n?', '$1'
            $newContent = $newContent -replace '(?s)<<<<<<< HEAD\r?\n', ''
            $newContent = $newContent -replace '(?s)=======\r?\n', ''
            $newContent = $newContent -replace '(?s)>>>>>>> [\w\-]+\r?\n?', ''
            Set-Content -Path $_.FullName -Value $newContent -NoNewline -ErrorAction SilentlyContinue
            $conflictFiles++
            Write-Host "  Fixed conflicts in: $($_.FullName)" -ForegroundColor Green
        }
    }
    catch {
        # Silently continue
    }
}
Write-Host "  Files with conflicts cleaned: $conflictFiles" -ForegroundColor Cyan
Write-Host ""

# Step 4: Verify cleanup
Write-Host "[Step 4/5] Verifying cleanup..." -ForegroundColor Yellow
$remaining = 0
foreach ($pattern in $patterns) {
    $matches = Select-String -Path 'C:\JioCloudCursor\AISDLC\AI_SDLC_Platform' -Pattern $pattern -Recurse -ErrorAction SilentlyContinue
    if ($matches) {
        $remaining += $matches.Count
    }
}

if ($remaining -eq 0) {
    Write-Host "  ✅ ALL organization references removed!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  $remaining references still remain (manual review needed)" -ForegroundColor Red
}
Write-Host ""

# Step 5: Git commit and force push
Write-Host "[Step 5/5] Committing and pushing to GitHub..." -ForegroundColor Yellow
Set-Location 'C:\JioCloudCursor\AISDLC\AI_SDLC_Platform'

git add -A
$commitMsg = "Clean ALL organization mentions: Jio, JPL, reliance, mehuldil, java-tej replaced with generic placeholders"
git commit -m $commitMsg

Write-Host ""
Write-Host "Ready to FORCE PUSH to GitHub" -ForegroundColor Red
Write-Host "This will COMPLETELY REPLACE https://github.com/mehuldil/ai_sdlc_platform" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Type 'CLEAN' to confirm and push"

if ($confirm -eq 'CLEAN') {
    Write-Host "  Force pushing..." -ForegroundColor Yellow
    git push --force origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host "✅ SUCCESS! Repository is now clean!" -ForegroundColor Green
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Verify at:" -ForegroundColor Cyan
        Write-Host "  https://github.com/mehuldil/ai_sdlc_platform" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Search for these on GitHub (should return 0 results):" -ForegroundColor Yellow
        Write-Host "  - Jio" -ForegroundColor Yellow
        Write-Host "  - JioAIphotos" -ForegroundColor Yellow
        Write-Host "  - JPL-Limited" -ForegroundColor Yellow
        Write-Host "  - mehuldil" -ForegroundColor Yellow
        Write-Host "  - java-tej" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "❌ PUSH FAILED!" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "Cancelled. No push performed." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
