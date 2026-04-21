#!/usr/bin/env bash
# ============================================================================
# Natural Language Story Parser
# Parses NL input from user and creates stories with AskUserQuestion
# ============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# NL PARSING FUNCTIONS
# ============================================================================

# Detect story type from NL input
detect_story_type() {
  local input="$1"

  if [[ "$input" =~ (master|strategic|outcome|business|quarter) ]]; then
    echo "master"
  elif [[ "$input" =~ (sprint|sprint[0-9]|weekly|execution|team|effort|hours) ]]; then
    echo "sprint"
  elif [[ "$input" =~ (architecture|tech|system|database|performance|queue|api) ]]; then
    echo "tech"
  elif [[ "$input" =~ (task|implement|component|feature|bug|function|method) ]]; then
    echo "task"
  else
    echo "unknown"
  fi
}

# Extract key information from NL input
extract_info() {
  local input="$1"
  local field="$2"

  case "$field" in
    outcome)
      # Extract outcome patterns like "Users can...", "Allow users to..."
      if [[ $input =~ [Uu]sers\ can\ ([^.]+) ]]; then
        echo "${BASH_REMATCH[1]}"
      elif [[ $input =~ [Aa]llow\ users\ to\ ([^.]+) ]]; then
        echo "${BASH_REMATCH[1]}"
      fi
      ;;
    metric)
      # Extract metric patterns like "25% adoption", "50% reduction"
      if [[ $input =~ ([0-9]+)%\ ([^ ]+) ]]; then
        echo "${BASH_REMATCH[1]}% ${BASH_REMATCH[2]}"
      fi
      ;;
    time)
      # Extract time patterns like "Q2", "2 weeks", "next month"
      if [[ $input =~ (Q[1-4]|next\ month|2\ weeks|this\ quarter) ]]; then
        echo "${BASH_REMATCH[1]}"
      fi
      ;;
  esac
}

# ============================================================================
# STORY CREATION WITH NL
# ============================================================================

create_story_interactive() {
  local story_type="${1:-}"
  local user_description="${2:-}"

  if [[ -z "$story_type" ]]; then
    # Auto-detect from description if provided
    if [[ -n "$user_description" ]]; then
      story_type=$(detect_story_type "$user_description")
    fi
  fi

  case "$story_type" in
    master)
      create_master_story_nl "$user_description"
      ;;
    sprint)
      create_sprint_story_nl "$user_description"
      ;;
    tech)
      create_tech_story_nl "$user_description"
      ;;
    task)
      create_task_nl "$user_description"
      ;;
    *)
      echo "Could not determine story type. Try:"
      echo "  sdlc story create master --help"
      echo "  sdlc story create sprint --help"
      return 1
      ;;
  esac
}

create_master_story_nl() {
  local description="${1:-}"

  echo ""
  echo "Creating Master Story..."
  echo ""

  # Extract key info if provided
  local outcome=$(extract_info "$description" "outcome")
  local metric=$(extract_info "$description" "metric")
  local time_horizon=$(extract_info "$description" "time")

  # Prompt for missing info
  read -p "Feature title: " title
  read -p "User outcome (what can users do?): " outcome
  read -p "Business impact (revenue, retention, engagement?): " business_impact
  read -p "Success metric (e.g., '↑ from 5% to 25%'): " metric
  read -p "Time horizon (Q1, Q2, Q3, or date): " time_horizon

  # Create story file
  local story_file=".sdlc/stories/MS-$(date +%s)-${title// /-}.md"
  mkdir -p "$(dirname "$story_file")"

  cat > "$story_file" << EOF
# 🧠 Master Story: $title

## 🎯 Outcome
- **User Outcome:** $outcome
- **Business Impact:** $business_impact
- **Success Metric:** $metric
- **Time Horizon:** $time_horizon

## 🔍 Problem Definition
- **Current user behavior:** [To be filled]
- **Pain/friction:** [To be filled]
- **Evidence:** [To be filled]
- **Why this matters now:** [To be filled]

## 👤 Target User & Context
- **Persona:** [To be filled]
- **Trigger moment:** [To be filled]
- **Environment:** [To be filled]

[Rest of template...]

---
**Status:** Draft
**Created:** $(date +%Y-%m-%d)
EOF

  echo "✓ Master story created: $story_file"
  echo "Next: Edit and fill in missing sections"
  echo "  nano $story_file"
  echo "  sdlc story validate $story_file"
}

create_sprint_story_nl() {
  local description="${1:-}"

  echo ""
  echo "Creating Sprint Story..."
  echo ""

  read -p "Sprint story title: " title
  read -p "Parent master story ID (MS-XXX): " parent_id
  read -p "Sprint name/number: " sprint
  read -p "Team member name: " assignee
  read -p "Effort (5d, 10d, 15d): " effort

  local story_file=".sdlc/stories/SS-$(date +%s)-${title// /-}.md"
  mkdir -p "$(dirname "$story_file")"

  cat > "$story_file" << EOF
# 📋 Sprint Story: $title

**Parent Master Story:** $parent_id

## 🎯 What We're Building
- **Feature/Change:** $title
- **User Impact:** [To be filled]
- **Sprint Acceptance:** [To be filled]

## 🔍 Context
- **Why now:** [To be filled]
- **What it enables:** [To be filled]
- **User scenario:** [To be filled]

## ⚡ Scope
### ✅ Included
| Capability | From Master |
|------------|-------------|
| [Feature] | [Reference] |

## 👥 Team & Effort
- **Assignee:** $assignee
- **Sprint:** $sprint
- **Estimated effort:** $effort

[Rest of template...]

---
**Status:** To Do
**Created:** $(date +%Y-%m-%d)
EOF

  echo "✓ Sprint story created: $story_file"
  echo "Next: Fill in remaining sections"
}

create_tech_story_nl() {
  local description="${1:-}"

  echo ""
  echo "Creating Tech Story..."
  echo ""

  read -p "Technical title: " title
  read -p "Performance target (e.g., 'P95 <2s'): " perf_target
  read -p "Relates to sprint story ID (SS-XXX): " sprint_id

  local story_file=".sdlc/stories/TS-$(date +%s)-${title// /-}.md"
  mkdir -p "$(dirname "$story_file")"

  cat > "$story_file" << EOF
# 🏗️ Tech Story: $title

**Relates to Sprint Story:** $sprint_id

## 🎯 Technical Goal
- **System capability:** [To be filled]
- **Performance target:** $perf_target
- **Reliability target:** [To be filled]

[Rest of template...]

---
**Status:** Design
**Created:** $(date +%Y-%m-%d)
EOF

  echo "✓ Tech story created: $story_file"
}

create_task_nl() {
  local description="${1:-}"

  echo ""
  echo "Creating Task..."
  echo ""

  read -p "Task title: " title
  read -p "Parent sprint story ID (SS-XXX): " sprint_id
  read -p "Effort (2h, 4h, 8h, 1d, 2d): " effort
  read -p "Assignee (name or TBD): " assignee

  local story_file=".sdlc/stories/T-$(date +%s)-${title// /-}.md"
  mkdir -p "$(dirname "$story_file")"

  cat > "$story_file" << EOF
# ✅ Task: $title

**Sprint Story:** $sprint_id

## 🎯 What's the Task?
- **Do this:** $title
- **Why:** [To be filled]
- **Definition of Done:** [To be filled]

## 📋 Acceptance Criteria
- [ ] [Test item 1]
- [ ] [Test item 2]
- [ ] [Test item 3]

## 🏗️ Implementation Notes
- **Approach:** [To be filled]
- **Files to modify:** [To be filled]
- **Estimated time:** $effort

---
**Status:** To Do
**Assignee:** $assignee
**Created:** $(date +%Y-%m-%d)
EOF

  echo "✓ Task created: $story_file"
}

# ============================================================================
# MAIN
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_story_interactive "$@"
fi
