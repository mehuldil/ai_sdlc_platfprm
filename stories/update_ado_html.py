#!/usr/bin/env python3
"""
Update ADO work items with properly formatted HTML content
Convert markdown to HTML using AI-SDLC Platform's converter
"""

import os
import sys
import json
import base64
import subprocess
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

def markdown_to_html(markdown_file):
    """Convert markdown to HTML with table support"""
    converter_path = r"c:\JioCloudCursor\AISDLC\stories\md_to_html_with_tables.js"
    
    try:
        # Read markdown content
        with open(markdown_file, 'r', encoding='utf-8') as f:
            md_content = f.read()
        
        # Run Node.js converter with table support
        result = subprocess.run(
            ['node', converter_path],
            input=md_content,
            capture_output=True,
            text=True,
            encoding='utf-8'
        )
        
        if result.returncode == 0:
            html = result.stdout
            # Add wrapper div for consistent styling
            return f'<div style="font-family:Segoe UI,sans-serif;font-size:14px;line-height:1.6;">{html}</div>'
        else:
            print(f"Converter error: {result.stderr}")
            # Fallback: use original AI-SDLC converter
            fallback_path = r"c:\JioCloudCursor\AISDLC\AI_SDLC_Platform\cli\lib\markdown-to-html.js"
            result2 = subprocess.run(
                ['node', fallback_path],
                input=md_content,
                capture_output=True,
                text=True,
                encoding='utf-8'
            )
            if result2.returncode == 0:
                return f'<div style="font-family:Segoe UI,sans-serif;font-size:14px;line-height:1.6;">{result2.stdout}</div>'
            return f"<pre>{md_content}</pre>"
    except Exception as e:
        print(f"Error converting markdown: {e}")
        return f"<pre>{open(markdown_file, 'r', encoding='utf-8').read()}</pre>"

def update_work_item(org, project, pat, work_item_id, html_content):
    """Update a work item's description with HTML content"""
    
    # Encode PAT for Basic auth
    auth_str = f":{pat}"
    base64_auth = base64.b64encode(auth_str.encode()).decode()
    
    # Build request body - update description
    body = [
        {"op": "add", "path": "/fields/System.Description", "value": html_content}
    ]
    
    url = f"https://dev.azure.com/{org}/{project}/_apis/wit/workitems/{work_item_id}?api-version=7.0"
    
    headers = {
        "Content-Type": "application/json-patch+json",
        "Authorization": f"Basic {base64_auth}"
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers=headers,
        method="PATCH"
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            return result.get("id")
    except urllib.error.HTTPError as e:
        print(f"Error updating work item {work_item_id}: {e.code} - {e.read().decode()}")
        raise
    except Exception as e:
        print(f"Error: {e}")
        raise

def main():
    print("=== Updating ADO Work Items with HTML Content ===\n")
    
    # Read env file
    env_path = r"c:\JioCloudCursor\AISDLC\AI_SDLC_Platform\env\.env"
    env_vars = read_env_file(env_path)
    
    org = env_vars.get('ADO_ORG', '')
    project = env_vars.get('ADO_PROJECT', '')
    pat = env_vars.get('ADO_PAT', '')
    
    if not org or not project or not pat:
        print("Error: ADO credentials not configured properly in env/.env")
        sys.exit(1)
    
    print(f"Organization: {org}")
    print(f"Project: {project}\n")
    
    # Work item IDs that were created
    work_items = [
        ("865620", "Feature", r"c:\JioCloudCursor\AISDLC\stories\FH-001-master-family-hub-phase1.md"),
        ("865621", "User Story", r"c:\JioCloudCursor\AISDLC\stories\FH-001-S01-sprint-hub-creation-invite.md"),
        ("865622", "User Story", r"c:\JioCloudCursor\AISDLC\stories\FH-001-S02-sprint-member-management.md"),
    ]
    
    for wi_id, wi_type, md_file in work_items:
        print(f"Converting {wi_type} {wi_id} to HTML...")
        html_content = markdown_to_html(md_file)
        
        # Truncate if too long (ADO has limits)
        if len(html_content) > 32000:
            print(f"  Warning: Content too long ({len(html_content)} chars), truncating...")
            html_content = html_content[:32000] + "<p>...</p><p>(Content truncated - see full story in file)</p>"
        
        print(f"  Updating work item {wi_id}...")
        try:
            update_work_item(org, project, pat, wi_id, html_content)
            print(f"  [OK] Updated {wi_type} {wi_id}\n")
        except Exception as e:
            print(f"  [FAILED] Could not update {wi_id}: {e}\n")
    
    print("=== All Work Items Updated ===")
    print("\nView in ADO:")
    print(f"https://dev.azure.com/{org}/{project}/_workitems/edit/865620")

if __name__ == "__main__":
    main()
