#!/usr/bin/env python3
"""
Push Family Hub Stories to Azure DevOps
Using AI-SDLC Platform approach
"""

import os
import sys
import json
import base64
import urllib.request
import urllib.error

def read_env_file(filepath):
    """Read environment variables from .env file"""
    env_vars = {}
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                env_vars[key.strip()] = value.strip()
    return env_vars

def create_work_item(org, project, pat, work_item_type, title, description, parent_id=None, is_master=False):
    """Create a work item in Azure DevOps"""
    
    # Encode PAT for Basic auth
    auth_str = f":{pat}"
    base64_auth = base64.b64encode(auth_str.encode()).decode()
    
    # Build request body
    body = [
        {"op": "add", "path": "/fields/System.Title", "value": title},
        {"op": "add", "path": "/fields/System.Description", "value": description}
    ]
    
    # Add required fields based on work item type
    if work_item_type == "Feature":
        # Assigned To - required field
        body.append({"op": "add", "path": "/fields/System.AssignedTo", "value": "mehul.dedhia@ril.com"})
        
        # Analytics Funnel - Yes/No per AI-SDLC Platform template
        body.append({"op": "add", "path": "/fields/Jio.Common.AnalyticsFunnel", "value": "Yes"})
        
        # Firebase Config Required - Yes/No
        body.append({"op": "add", "path": "/fields/Jio.Common.FirebaseConfigRequired", "value": "Yes"})
        
        # Platform(JioCloud) - Android, iOS, Web, Server, etc.
        body.append({"op": "add", "path": "/fields/Jio.Common.PlatformJioCloud", "value": "Android"})
        
        # Success Criteria
        body.append({"op": "add", "path": "/fields/Jio.Common.SuccessCriteria", 
                    "value": "Feature works end-to-end with all acceptance criteria met"})
    
    elif work_item_type == "User Story":
        # Assigned To - required field
        body.append({"op": "add", "path": "/fields/System.AssignedTo", "value": "mehul.dedhia@ril.com"})
        
        # Dependency - Android;Server;Web per AI-SDLC Platform template
        body.append({"op": "add", "path": "/fields/Jio.Common.Dependency", "value": "Android"})
        
        # Userstory Source - Product Backlog per AI-SDLC Platform template
        body.append({"op": "add", "path": "/fields/Jio.Common.UserstorySource", "value": "Product Backlog"})
        
        # Platform(JioCloud)
        body.append({"op": "add", "path": "/fields/Jio.Common.PlatformJioCloud", "value": "Android"})
    
    if parent_id:
        body.append({
            "op": "add",
            "path": "/relations/-",
            "value": {
                "rel": "System.LinkTypes.Hierarchy-Reverse",
                "url": f"https://dev.azure.com/{org}/_apis/wit/workItems/{parent_id}"
            }
        })
    
    # URL encode work item type (spaces become %20)
    from urllib.parse import quote
    encoded_type = quote(work_item_type, safe='')
    url = f"https://dev.azure.com/{org}/{project}/_apis/wit/workitems/${encoded_type}?api-version=7.0"
    
    headers = {
        "Content-Type": "application/json-patch+json",
        "Authorization": f"Basic {base64_auth}"
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers=headers,
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            return result.get("id")
    except urllib.error.HTTPError as e:
        print(f"Error creating work item: {e.code} - {e.read().decode()}")
        raise
    except Exception as e:
        print(f"Error: {e}")
        raise

def main():
    print("=== Pushing Stories to Azure DevOps ===\n")
    
    # Read env file
    env_path = r"c:\JioCloudCursor\AISDLC\AI_SDLC_Platform\env\.env"
    env_vars = read_env_file(env_path)
    
    org = env_vars.get('ADO_ORG', '')
    project = env_vars.get('ADO_PROJECT', '')
    pat = env_vars.get('ADO_PAT', '')
    
    if not org or not project or not pat:
        print("Error: ADO credentials not configured properly in env/.env")
        sys.exit(1)
    
    if org == 'USER_INPUT_REQUIRED' or project == 'USER_INPUT_REQUIRED':
        print("Error: Please fill in ADO_ORG and ADO_PROJECT in env/.env")
        sys.exit(1)
    
    print(f"Organization: {org}")
    print(f"Project: {project}\n")
    
    # Read Master Story
    print("Creating Feature (Master Story)...")
    master_path = r"c:\JioCloudCursor\AISDLC\stories\FH-001-master-family-hub-phase1.md"
    with open(master_path, 'r', encoding='utf-8') as f:
        master_content = f.read()
    
    feature_id = create_work_item(org, project, pat, "Feature", 
                                "Family Hub Phase 1 - Master Story", 
                                master_content)
    print(f"[OK] Feature created with ID: {feature_id}\n")
    
    # Read Sprint Story 1
    print("Creating User Story 1 (Sprint 3)...")
    sprint1_path = r"c:\JioCloudCursor\AISDLC\stories\FH-001-S01-sprint-hub-creation-invite.md"
    with open(sprint1_path, 'r', encoding='utf-8') as f:
        sprint1_content = f.read()
    
    story1_id = create_work_item(org, project, pat, "User Story",
                                 "Sprint 3: Hub Creation and Invite Flow",
                                 sprint1_content, feature_id)
    print(f"[OK] User Story created with ID: {story1_id}\n")
    
    # Read Sprint Story 2
    print("Creating User Story 2 (Sprint 4)...")
    sprint2_path = r"c:\JioCloudCursor\AISDLC\stories\FH-001-S02-sprint-member-management.md"
    with open(sprint2_path, 'r', encoding='utf-8') as f:
        sprint2_content = f.read()
    
    story2_id = create_work_item(org, project, pat, "User Story",
                                 "Sprint 4: Member Management and Storage Alerts",
                                 sprint2_content, feature_id)
    print(f"[OK] User Story created with ID: {story2_id}\n")
    
    print("=== All Stories Pushed Successfully ===\n")
    print(f"Feature: {feature_id}")
    print(f"  -> Story 1: {story1_id}")
    print(f"  -> Story 2: {story2_id}\n")
    print(f"View in ADO: https://dev.azure.com/{org}/{project}/_workitems/edit/{feature_id}")
    
    # Update stories with ADO IDs
    update_stories_with_ado_ids(feature_id, story1_id, story2_id)

def update_stories_with_ado_ids(feature_id, story1_id, story2_id):
    """Update story files with ADO work item IDs"""
    
    # Update Master Story
    master_path = r"c:\JioCloudCursor\AISDLC\stories\FH-001-master-family-hub-phase1.md"
    with open(master_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace the PRD Traceability table
    old_table = """| PRD document | Section IDs | ADO Feature / Epic ID |
|--------------|-------------|----------------------|
| FamilyHub_Phase 1.docx | Flow A, Flow B, Flow D, Flow E, Notification Matrix, Error Scenarios, Storage & Membership | USER_INPUT_REQUIRED |"""
    
    new_table = f"""| PRD document | Section IDs | ADO Feature / Epic ID |
|--------------|-------------|----------------------|
| FamilyHub_Phase 1.docx | Flow A, Flow B, Flow D, Flow E, Notification Matrix, Error Scenarios, Storage & Membership | {feature_id} |"""
    
    content = content.replace(old_table, new_table)
    
    with open(master_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"\n[OK] Updated Master Story with Feature ID: {feature_id}")
    
    # Update Sprint Story 1
    sprint1_path = r"c:\JioCloudCursor\AISDLC\stories\FH-001-S01-sprint-hub-creation-invite.md"
    with open(sprint1_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("**Parent Master Story:** FH-001-master-family-hub-phase1.md",
                             f"**Parent Master Story:** FH-001-master-family-hub-phase1.md (ADO Feature: {feature_id})")
    
    with open(sprint1_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"[OK] Updated Sprint Story 1 with ADO ID: {story1_id}")
    
    # Update Sprint Story 2
    sprint2_path = r"c:\JioCloudCursor\AISDLC\stories\FH-001-S02-sprint-member-management.md"
    with open(sprint2_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("**Parent Master Story:** FH-001-master-family-hub-phase1.md",
                             f"**Parent Master Story:** FH-001-master-family-hub-phase1.md (ADO Feature: {feature_id})")
    
    with open(sprint2_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"[OK] Updated Sprint Story 2 with ADO ID: {story2_id}")

if __name__ == "__main__":
    main()
