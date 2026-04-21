# ADO Configuration Helper
# Run this script to configure ADO credentials

Write-Host "=== Azure DevOps Configuration ===" -ForegroundColor Cyan
Write-Host ""

$org = Read-Host -Prompt "Enter ADO Organization (e.g., 'jio')"
$project = Read-Host -Prompt "Enter ADO Project Name (e.g., 'JioPhotos')"
$pat = Read-Host -Prompt "Enter ADO Personal Access Token (PAT)" -AsSecureString

# Convert secure string to plain text for the env file
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pat)
$patPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Create env file content
$envContent = @"
# AI-SDLC Platform Environment Configuration
# Auto-generated for ADO push

ADO_ORG=$org
ADO_PROJECT=$project
ADO_PAT=$patPlain

# Optional: Add these if needed
# ADO_USER_NAME=
# ADO_USER_EMAIL=
# ADO_PROJECT_ID=
"@

# Write to env file
$envPath = "c:\JioCloudCursor\AISDLC\AI_SDLC_Platform\env\.env"
$envContent | Out-File -FilePath $envPath -Encoding UTF8

Write-Host ""
Write-Host "✓ Configuration saved to: $envPath" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. The .env file has been created with your credentials"
Write-Host "2. Run: sdlc story push stories/FH-001-master-family-hub-phase1.md --type=epic"
Write-Host "3. Or use the MCP ADO integration in Cursor"
Write-Host ""

# Clear the plain text variable
$patPlain = $null
[GC]::Collect()
