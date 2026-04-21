#!/bin/bash
#
# generate-settings.sh
# Regenerates modelSelection.commands block in settings.json
# by parsing all .claude/commands/*.md files for Model Tier declarations.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

if [[ ! -d "$COMMANDS_DIR" ]]; then
    echo "ERROR: Commands directory not found: $COMMANDS_DIR"
    exit 1
fi

if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "ERROR: Settings file not found: $SETTINGS_FILE"
    exit 1
fi

# Create a temporary Python script to parse command files and regenerate settings
TEMP_SCRIPT=$(mktemp)

cat > "$TEMP_SCRIPT" << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
import json
import os
import re
import sys

commands_dir = sys.argv[1]
settings_file = sys.argv[2]

# Parse all command .md files and extract model tier
commands = {}

for filename in sorted(os.listdir(commands_dir)):
    if not filename.endswith('.md'):
        continue

    command_name = filename[:-3]  # Remove .md extension
    filepath = os.path.join(commands_dir, filename)

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read(3000)  # Read first 3000 chars to find frontmatter

            # Look for "Model Tier:" pattern - handle multiple formats:
            # - **Model Tier:** Haiku 4.5
            # - **Model Tier:** Sonnet 4.6
            # - **Model Tier:** Opus 4.6 (orchestrates 5 skills)
            # - **Model Tier:** Routed per stage
            match = re.search(r'\*\*Model Tier:\*?\*\s*([^\n|]+?)(?:\s*\||$|\n)', content, re.IGNORECASE)

            if match:
                tier_text = match.group(1).strip()
                # Extract model name (Haiku/Sonnet/Opus with version)
                if 'haiku' in tier_text.lower():
                    model = 'haiku-4.5'
                elif 'sonnet' in tier_text.lower():
                    model = 'sonnet-4.6'
                elif 'opus' in tier_text.lower():
                    model = 'opus-4.6'
                elif 'routed per stage' in tier_text.lower():
                    # Special case: sdlc orchestrator is routed per stage
                    model = 'sonnet-4.6'  # Default for orchestrator
                else:
                    print(f"WARNING: Could not determine model tier for {command_name}: {tier_text}", file=sys.stderr)
                    model = 'sonnet-4.6'  # Default to sonnet

                commands[command_name] = model
            else:
                print(f"WARNING: No Model Tier found in {command_name}", file=sys.stderr)
                commands[command_name] = 'sonnet-4.6'  # Default to sonnet
    except Exception as e:
        print(f"ERROR reading {filename}: {e}", file=sys.stderr)
        sys.exit(1)

# Load existing settings.json
try:
    with open(settings_file, 'r', encoding='utf-8') as f:
        settings = json.load(f)
except Exception as e:
    print(f"ERROR reading settings.json: {e}", file=sys.stderr)
    sys.exit(1)

# Update the modelSelection.commands block
if 'modelSelection' not in settings:
    settings['modelSelection'] = {}

settings['modelSelection']['commands'] = commands

# Write back to settings.json
try:
    with open(settings_file, 'w', encoding='utf-8') as f:
        json.dump(settings, f, indent=2)
        f.write('\n')  # Add trailing newline
    print(f"✓ Updated {settings_file}")
    print(f"✓ Generated {len(commands)} command model assignments")

    # Validate JSON
    with open(settings_file, 'r') as f:
        json.load(f)
    print("✓ Valid JSON output")

except Exception as e:
    print(f"ERROR writing settings.json: {e}", file=sys.stderr)
    sys.exit(1)

PYTHON_SCRIPT

# Execute the Python script
python3 "$TEMP_SCRIPT" "$COMMANDS_DIR" "$SETTINGS_FILE"
RESULT=$?

# Clean up
rm -f "$TEMP_SCRIPT"

if [[ $RESULT -eq 0 ]]; then
    echo ""
    echo "SUCCESS: settings.json regenerated with all command model assignments"
    exit 0
else
    echo ""
    echo "FAILED: Could not regenerate settings.json"
    exit 1
fi
