# Push Family Hub Stories to Azure DevOps
# Using AI-SDLC Platform approach

$ErrorActionPreference = "Stop"

# Read env file
$envFile = Get-Content "c:\JioCloudCursor\AISDLC\AI_SDLC_Platform\env\.env"
$envVars = @{}
foreach ($line in $envFile) {
    if ($line -match '^([^#][^=]*)=(.*)$') {
        $key = $Matches[1].Trim()
        $val = $Matches[2].Trim()
        $envVars[$key] = $val
    }
}

$org = $envVars['ADO_ORG']
$project = $envVars['ADO_PROJECT']
$pat = $envVars['ADO_PAT']

if ($org -eq 'USER_INPUT_REQUIRED' -or $project -eq 'USER_INPUT_REQUIRED' -or $pat -eq 'USER_INPUT_REQUIRED') {
    Write-Error "ADO credentials not configured. Please update AI_SDLC_Platform/env/.env"
    exit 1
}

Write-Host "=== Pushing Stories to Azure DevOps ===" -ForegroundColor Cyan
Write-Host "Organization: $org" -ForegroundColor Gray
Write-Host "Project: $project" -ForegroundColor Gray
Write-Host ""

# Encode PAT for Basic auth
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    "Content-Type" = "application/json-patch+json"
}

$adoUrl = "https://dev.azure.com/$org/$project/_apis/wit/workitems"

# Function to create work item
function Create-WorkItem($type, $title, $description, $parentId = $null) {
    $body = @(
        @{ op = "add"; path = "/fields/System.Title"; value = $title },
        @{ op = "add"; path = "/fields/System.Description"; value = $description }
    )
    
    if ($parentId) {
        $body += @{ op = "add"; path = "/relations/-"; value = @{ 
            rel = "System.LinkTypes.Hierarchy-Reverse"
            url = "https://dev.azure.com/$org/_apis/wit/workItems/$parentId"
        }}
    }
    
    $jsonBody = $body | ConvertTo-Json -Depth 10
    $url = "$adoUrl/`$$type`?api-version=7.0"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $jsonBody
        return $response.id
    } catch {
        Write-Error "Failed to create work item: $_"
        throw
    }
}

# Read Master Story content
$masterContent = Get-Content "c:\JioCloudCursor\AISDLC\stories\FH-001-master-family-hub-phase1.md" -Raw
$masterTitle = "Family Hub Phase 1 - Master Story"

Write-Host "Creating Epic (Master Story)..." -ForegroundColor Yellow
$epicId = Create-WorkItem -type "Epic" -title $masterTitle -description $masterContent
Write-Host "✓ Epic created with ID: $epicId" -ForegroundColor Green
Write-Host ""

# Read Sprint Story 1
$sprint1Content = Get-Content "c:\JioCloudCursor\AISDLC\stories\FH-001-S01-sprint-hub-creation-invite.md" -Raw
$sprint1Title = "Sprint 3: Hub Creation and Invite Flow"

Write-Host "Creating User Story 1 (Sprint 3)..." -ForegroundColor Yellow
$story1Id = Create-WorkItem -type "User Story" -title $sprint1Title -description $sprint1Content -parentId $epicId
Write-Host "✓ User Story created with ID: $story1Id" -ForegroundColor Green
Write-Host ""

# Read Sprint Story 2
$sprint2Content = Get-Content "c:\JioCloudCursor\AISDLC\stories\FH-001-S02-sprint-member-management.md" -Raw
$sprint2Title = "Sprint 4: Member Management & Storage Alerts"

Write-Host "Creating User Story 2 (Sprint 4)..." -ForegroundColor Yellow
$story2Id = Create-WorkItem -type "User Story" -title $sprint2Title -description $sprint2Content -parentId $epicId
Write-Host "✓ User Story created with ID: $story2Id" -ForegroundColor Green
Write-Host ""

Write-Host "=== All Stories Pushed Successfully ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Epic: $epicId" -ForegroundColor White
Write-Host "  └─ Story 1: $story1Id" -ForegroundColor White
Write-Host "  └─ Story 2: $story2Id" -ForegroundColor White
Write-Host ""
Write-Host "View in ADO: https://dev.azure.com/$org/$project/_workitems/edit/$epicId" -ForegroundColor Blue
