#!/usr/bin/env bash
# templates/ado-field-registry.sh — ADO field definitions and defaults
# Part of AI SDLC Platform v2.0.0
# Sourced by cli/lib/ado.sh to define mandatory fields for each work item type

# Field Registry Format:
# Each work item type defines its mandatory fields.
# Fields are collected from environment variables, defaults, or interactive prompts.

# ============================================================================
# FIELD DEFINITIONS BY WORK ITEM TYPE
# ============================================================================

# Field metadata: FIELD_ID|DISPLAY_NAME|ALLOWED_VALUES|DEFAULT|ENV_VAR
# - FIELD_ID: ADO field path (e.g., System.Title, Custom.AnalyticsFunnel)
# - DISPLAY_NAME: User-friendly name for prompts
# - ALLOWED_VALUES: Semicolon-separated list (empty if free-form)
# - DEFAULT: Default value if not in env
# - ENV_VAR: Environment variable to check (optional)

declare -gA ADO_FIELD_REGISTRY=(
  # Common fields (all types)
  [System.Title]="Title|System.Title||ADO_WI_TITLE"
  [System.AreaPath]="Area Path|System.AreaPath||YourAzureProject\\POD 1|ADO_WI_AREA_PATH"
  [System.IterationPath]="Iteration Path|System.IterationPath||YourAzureProject\\Sprint 1|ADO_WI_ITERATION_PATH"

  # Epic-specific fields
  [Epic.Title]="Epic Title|System.Title||ADO_EPIC_TITLE"

  # Feature-specific fields
  [Feature.Analytics]="Analytics Funnel|Custom.AnalyticsFunnel|Yes;No||ADO_FEATURE_ANALYTICS_FUNNEL"
  [Feature.Firebase]="Firebase Config Required|Custom.FirebaseConfigRequired|Yes;No||ADO_FEATURE_FIREBASE_CONFIG_REQUIRED"
  [Feature.Success]="Success Criteria|Custom.SuccessCriteria|||ADO_FEATURE_SUCCESS_CRITERIA"
  [Feature.Platform]="Application platform|Custom.ApplicationPlatform|Android;Database;Devops;Server;Web|Android;Database;Devops;Server;Web|ADO_WI_PLATFORM_example-org"
  [Feature.AssignedTo]="Assigned To|System.AssignedTo|||ADO_USER_EMAIL"

  # User Story-specific fields
  [UserStory.Dependency]="Dependency|Custom.Dependency|Android;Server;Web|Android;Server;Web|ADO_WI_DEPENDENCY"
  [UserStory.Source]="Userstory Source|Custom.UserstorySource||Product Backlog|ADO_WI_USERSTORY_SOURCE"
  [UserStory.Platform]="Application platform|Custom.ApplicationPlatform|Android;Database;Devops;Server;Web|Android;Database;Devops;Server;Web|ADO_WI_PLATFORM_example-org"
  [UserStory.AssignedTo]="Assigned To|System.AssignedTo|||ADO_USER_EMAIL"

  # Task-specific fields
  [Task.Platform]="Application platform|Custom.ApplicationPlatform|Android;Database;Devops;Server;Web|Android;Database;Devops;Server;Web|ADO_WI_PLATFORM_example-org"

  # Bug-specific fields
  [Bug.Priority]="Priority|System.Priority|1;2;3;4|3|ADO_BUG_PRIORITY"
  [Bug.Severity]="Severity|Microsoft.VSTS.Common.Severity|1;2;3;4|3|ADO_BUG_SEVERITY"
)

# ============================================================================
# FIELD LOOKUP FUNCTIONS
# ============================================================================

# Get field metadata for a work item type
_ado_get_field_metadata() {
  local wi_type="$1"
  local field_id="$2"
  local index="${3:-0}"

  case "$index" in
    0) echo "FIELD_ID" ;;
    1) echo "DISPLAY_NAME" ;;
    2) echo "ALLOWED_VALUES" ;;
    3) echo "DEFAULT" ;;
    4) echo "ENV_VAR" ;;
    *) return 1 ;;
  esac
}

# Get mandatory fields for a work item type
_ado_get_mandatory_fields() {
  local wi_type="$1"

  case "$wi_type" in
    Epic)
      echo "System.Title"
      echo "System.AreaPath"
      echo "System.IterationPath"
      ;;
    Feature)
      echo "System.Title"
      echo "System.AreaPath"
      echo "System.IterationPath"
      echo "System.AssignedTo"
      echo "Custom.AnalyticsFunnel"
      echo "Custom.FirebaseConfigRequired"
      echo "Custom.SuccessCriteria"
      echo "Custom.ApplicationPlatform"
      ;;
    "User Story")
      echo "System.Title"
      echo "System.AreaPath"
      echo "System.IterationPath"
      echo "System.AssignedTo"
      echo "Custom.Dependency"
      echo "Custom.UserstorySource"
      echo "Custom.ApplicationPlatform"
      ;;
    Task)
      echo "System.Title"
      echo "System.AreaPath"
      echo "System.IterationPath"
      echo "Custom.ApplicationPlatform"
      ;;
    Bug)
      echo "System.Title"
      echo "System.AreaPath"
      echo "System.IterationPath"
      echo "System.Priority"
      echo "Microsoft.VSTS.Common.Severity"
      ;;
    "Test Case")
      echo "System.Title"
      echo "System.AreaPath"
      ;;
    "Test Plan")
      echo "System.Title"
      ;;
  esac
}

# ============================================================================
# DOCUMENTATION: Field Mappings
# ============================================================================

# ADO Custom Fields (example process template)
# ================================
# Custom.AnalyticsFunnel              - Analytics funnel (Yes/No)
# Custom.FirebaseConfigRequired       - Firebase config required (Yes/No)
# Custom.SuccessCriteria              - Free-form success criteria text
# Custom.ApplicationPlatform             - Platform targets (Android, Server, etc.)
# Custom.Dependency                   - Dependencies (for User Stories)
# Custom.UserstorySource              - Source of user story (e.g., "Product Backlog")

# System Fields (Azure DevOps)
# ============================
# System.Title                            - Work item title
# System.Description                      - Work item description (HTML)
# System.AreaPath                         - Area path (project structure)
# System.IterationPath                    - Iteration/Sprint path
# System.AssignedTo                       - Assigned person (email or identity)
# System.Priority                         - Priority (1-4, lower is higher priority)
# System.State                            - Work item state (New, Active, Closed, etc.)
# System.WorkItemType                     - Type of work item

# Microsoft Standard Fields
# ==========================
# Microsoft.VSTS.Common.Severity          - Bug severity (1-4)
# Microsoft.VSTS.Common.AcceptanceCriteria - Acceptance criteria text

# Environment Variables
# =====================
# ADO_FEATURE_ANALYTICS_FUNNEL            - Feature: Analytics funnel default
# ADO_FEATURE_FIREBASE_CONFIG_REQUIRED    - Feature: Firebase config default
# ADO_FEATURE_SUCCESS_CRITERIA            - Feature: Success criteria default
# ADO_WI_PLATFORM_example-org                - Work item: Platform targets default
# ADO_WI_DEPENDENCY                       - User Story: Dependency default
# ADO_WI_USERSTORY_SOURCE                 - User Story: Source default
# ADO_WI_AREA_PATH                        - Work item: Area path default
# ADO_WI_ITERATION_PATH                   - Work item: Iteration path default
# ADO_USER_EMAIL                          - Current user email for "Assigned To"
# ADO_USER_NAME                           - Current user display name (optional)
# ADO_BUG_PRIORITY                        - Bug: Priority default
# ADO_BUG_SEVERITY                        - Bug: Severity default
