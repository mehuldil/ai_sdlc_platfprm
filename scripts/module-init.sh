#!/usr/bin/env bash
################################################################################
# Unified Module System — module-init.sh
# Merges KB + MIS into one system. Scans repo, generates contracts + knowledge.
# Supports: Java, Kotlin/Android, Swift/iOS, React Native, Node.js, C/C++
################################################################################

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

REPO_PATH="${1:-.}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

if [[ ! -d "$REPO_PATH/.git" ]]; then
  log_error "Not a git repository: $REPO_PATH"
  exit 1
fi

MODULE_DIR="$REPO_PATH/.sdlc/module"
CONTRACTS_DIR="$MODULE_DIR/contracts"
KNOWLEDGE_DIR="$MODULE_DIR/knowledge"
CACHE_DIR="$MODULE_DIR/cache"
mkdir -p "$CONTRACTS_DIR" "$KNOWLEDGE_DIR" "$CACHE_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT_HASH=$(cd "$REPO_PATH" && git rev-parse HEAD 2>/dev/null || echo "unknown")
REPO_NAME=$(basename "$REPO_PATH")

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}MODULE SYSTEM — INITIALIZATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
log_info "Repository: $REPO_PATH"
echo ""

################################################################################
# STACK DETECTION — supports all platforms
################################################################################

detect_stack() {
  local has_pom=0 has_gradle=0 has_gradle_kts=0 has_package_json=0
  local has_metro=0 has_makefile=0 has_xcodeproj=0 has_swift_pkg=0
  local has_android_manifest=0 has_podfile=0

  [[ -f "$REPO_PATH/pom.xml" ]] && has_pom=1
  [[ -f "$REPO_PATH/build.gradle" ]] && has_gradle=1
  [[ -f "$REPO_PATH/build.gradle.kts" ]] && has_gradle_kts=1
  [[ -f "$REPO_PATH/package.json" ]] && has_package_json=1
  [[ -f "$REPO_PATH/metro.config.js" || -f "$REPO_PATH/metro.config.ts" ]] && has_metro=1
  [[ -f "$REPO_PATH/Makefile" || -f "$REPO_PATH/CMakeLists.txt" ]] && has_makefile=1
  [[ -f "$REPO_PATH/Podfile" ]] && has_podfile=1
  [[ -f "$REPO_PATH/Package.swift" ]] && has_swift_pkg=1

  # Nested Gradle/Maven (monorepos — build file not at repo root)
  if [[ $has_pom -eq 0 && $has_gradle -eq 0 && $has_gradle_kts -eq 0 ]]; then
    find "$REPO_PATH" -maxdepth 8 \( -name "build.gradle" -o -name "build.gradle.kts" \) \
      ! -path "*/.*" ! -path "*/build/*" 2>/dev/null | head -1 | grep -q . && has_gradle=1
    find "$REPO_PATH" -maxdepth 8 -name "pom.xml" ! -path "*/.*" ! -path "*/target/*" 2>/dev/null | head -1 | grep -q . && has_pom=1
    find "$REPO_PATH" -maxdepth 8 -name "build.gradle.kts" ! -path "*/.*" 2>/dev/null | head -1 | grep -q . && has_gradle_kts=1
  fi

  # Check for .xcodeproj directory
  find "$REPO_PATH" -maxdepth 2 -name "*.xcodeproj" -type d 2>/dev/null | head -1 | grep -q . && has_xcodeproj=1

  # Check for AndroidManifest.xml
  find "$REPO_PATH" -maxdepth 4 -name "AndroidManifest.xml" 2>/dev/null | head -1 | grep -q . && has_android_manifest=1

  # Kotlin Android: build.gradle.kts + AndroidManifest
  if [[ $has_gradle_kts -eq 1 && $has_android_manifest -eq 1 ]]; then
    echo "kotlin-android"
  # Java Android (rare but possible)
  elif [[ $has_gradle -eq 1 && $has_android_manifest -eq 1 ]]; then
    echo "java-android"
  # Swift/iOS: xcodeproj or Package.swift + Podfile
  elif [[ $has_xcodeproj -eq 1 || ($has_swift_pkg -eq 1 && $has_podfile -eq 1) ]]; then
    echo "swift-ios"
  # Java backend (Maven or Gradle without Android)
  elif [[ $has_pom -eq 1 || $has_gradle -eq 1 || $has_gradle_kts -eq 1 ]]; then
    echo "java"
  # React Native
  elif [[ $has_package_json -eq 1 && $has_metro -eq 1 ]]; then
    echo "react-native"
  # Node.js
  elif [[ $has_package_json -eq 1 ]]; then
    echo "node"
  # C/C++
  elif [[ $has_makefile -eq 1 ]]; then
    echo "c"
  else
    echo "unknown"
  fi
}

STACK=$(detect_stack)
log_success "Detected stack: $STACK"
echo ""

################################################################################
# CONTRACTS — Source of truth (YAML)
################################################################################

generate_api_contract() {
  log_info "Generating API contract..."
  local api_file="$CONTRACTS_DIR/api.yaml"

  cat > "$api_file" << EOF
# API Contract — $REPO_NAME
# Generated: $TIMESTAMP | Commit: ${COMMIT_HASH:0:8} | Stack: $STACK
# Edit this file to define your module's API surface

version: "1.0"
module: "$REPO_NAME"
stack: "$STACK"

endpoints:
EOF

  # Scan for endpoints based on stack
  case "$STACK" in
    java|java-android)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        # Spring MVC
        grep -n '@GetMapping\|@PostMapping\|@PutMapping\|@DeleteMapping\|@RequestMapping' "$f" 2>/dev/null | head -20 | while IFS=: read -r line content; do
          local rel="${f#$REPO_PATH/}"
          local endpoint
          endpoint=$(echo "$content" | grep -oE '"[^"]+"' | head -1 | tr -d '"')
          if [[ -n "$endpoint" ]]; then
            echo "  - path: \"$endpoint\"" >> "$api_file"
            echo "    file: \"$rel:$line\"" >> "$api_file"
          fi
        done || true
        # RestExpress / JAX-RS: @Path("/segment") (HTTP method is often on the next line)
        grep -nE '@Path[[:space:]]*\([[:space:]]*"[^"]+"' "$f" 2>/dev/null | head -80 | while IFS=: read -r line content; do
          local rel="${f#$REPO_PATH/}"
          local endpoint
          endpoint=$(echo "$content" | grep -oE '"[^"]+"' | head -1 | tr -d '"')
          if [[ -n "$endpoint" ]]; then
            echo "  - path: \"$endpoint\"" >> "$api_file"
            echo "    file: \"$rel:$line\"" >> "$api_file"
          fi
        done || true
      done < <(find "$REPO_PATH" -name "*.java" -path "*/src/*" 2>/dev/null)
      ;;
    kotlin-android)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        grep -n '@GET\|@POST\|@PUT\|@DELETE\|@PATCH' "$f" 2>/dev/null | head -20 | while IFS=: read -r line content; do
          local rel="${f#$REPO_PATH/}"
          local endpoint=$(echo "$content" | grep -oP '"[^"]*"' | head -1 | tr -d '"')
          if [[ -n "$endpoint" ]]; then
            echo "  - path: \"$endpoint\"" >> "$api_file"
            echo "    file: \"$rel:$line\"" >> "$api_file"
          fi
        done || true
      done < <(find "$REPO_PATH" -name "*.kt" 2>/dev/null)
      ;;
    swift-ios)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        grep -n 'URLSession\|Alamofire\|AF\.\|URLRequest\|\.request(' "$f" 2>/dev/null | head -20 | while IFS=: read -r line content; do
          local rel="${f#$REPO_PATH/}"
          echo "  - path: \"# detected in $rel:$line\"" >> "$api_file"
        done || true
      done < <(find "$REPO_PATH" -name "*.swift" 2>/dev/null)
      ;;
    node)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        grep -n 'router\.get\|router\.post\|router\.put\|router\.delete\|app\.get\|app\.post\|app\.put\|app\.delete' "$f" 2>/dev/null | head -20 | while IFS=: read -r line content; do
          local rel="${f#$REPO_PATH/}"
          local endpoint=$(echo "$content" | grep -oP "'[^']*'" | head -1 | tr -d "'")
          if [[ -n "$endpoint" ]]; then
            echo "  - path: \"$endpoint\"" >> "$api_file"
            echo "    file: \"$rel:$line\"" >> "$api_file"
          fi
        done || true
      done < <(find "$REPO_PATH" \( -name "*.js" -o -name "*.ts" \) -not -path "*/node_modules/*" 2>/dev/null)
      ;;
  esac

  cat >> "$api_file" << 'EOF'

consumers: []
  # - module: "ios-app"
  #   endpoints: ["GET /users/{id}"]

deprecations: []
  # - path: "/v1/users"
  #   deprecated_since: "2024-01-01"
  #   replacement: "/v2/users"
  #   removal_date: "2024-06-01"
EOF

  log_success "Created: contracts/api.yaml"
}

generate_data_contract() {
  log_info "Generating data contract..."
  local data_file="$CONTRACTS_DIR/data.yaml"

  cat > "$data_file" << EOF
# Data Contract — $REPO_NAME
# Generated: $TIMESTAMP | Commit: ${COMMIT_HASH:0:8} | Stack: $STACK

version: "1.0"
module: "$REPO_NAME"

storage_type: "$(case $STACK in
  java) echo "postgresql/mysql" ;;
  kotlin-android) echo "room" ;;
  swift-ios) echo "coredata/realm" ;;
  node) echo "mongodb/postgresql" ;;
  react-native) echo "asyncstorage/realm" ;;
  *) echo "unknown" ;;
esac)"

schemas:
EOF

  # Scan for data models based on stack
  case "$STACK" in
    java)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        local name=$(basename "$f" .java)
        echo "  - name: \"$name\"" >> "$data_file"
        echo "    file: \"${f#$REPO_PATH/}\"" >> "$data_file"
      done < <(find "$REPO_PATH" \( -name "*Entity.java" -o -name "*Model.java" \) 2>/dev/null | head -15)
      ;;
    kotlin-android)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        if grep -q '@Entity\|@Dao\|@Database' "$f" 2>/dev/null; then
          local name=$(basename "$f" .kt)
          echo "  - name: \"$name\"" >> "$data_file"
          echo "    file: \"${f#$REPO_PATH/}\"" >> "$data_file"
          echo "    type: \"room_entity\"" >> "$data_file"
        fi
      done < <(find "$REPO_PATH" -name "*.kt" 2>/dev/null)
      ;;
    swift-ios)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        local name=$(basename "$f" | sed 's/\..*//')
        echo "  - name: \"$name\"" >> "$data_file"
        echo "    file: \"${f#$REPO_PATH/}\"" >> "$data_file"
        echo "    type: \"coredata\"" >> "$data_file"
      done < <(find "$REPO_PATH" \( -name "*.xcdatamodeld" -o -name "*+CoreDataClass.swift" \) 2>/dev/null | head -15)
      ;;
    node)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        local name=$(basename "$f" | sed 's/\..*//')
        echo "  - name: \"$name\"" >> "$data_file"
        echo "    file: \"${f#$REPO_PATH/}\"" >> "$data_file"
      done < <(find "$REPO_PATH" \( -name "*model*.js" -o -name "*schema*.js" -o -name "*model*.ts" \) -not -path "*/node_modules/*" 2>/dev/null | head -15)
      ;;
  esac

  cat >> "$data_file" << 'EOF'

migrations:
  # - id: "V001"
  #   description: "Initial schema"
  #   reversible: true
  #   status: "applied"
EOF

  log_success "Created: contracts/data.yaml"
}

generate_event_contract() {
  log_info "Generating event contract..."
  local event_file="$CONTRACTS_DIR/events.yaml"

  cat > "$event_file" << EOF
# Event Contract — $REPO_NAME
# Generated: $TIMESTAMP | Commit: ${COMMIT_HASH:0:8} | Stack: $STACK

version: "1.0"
module: "$REPO_NAME"

event_system: "$(case $STACK in
  java) echo "kafka" ;;
  kotlin-android) echo "eventbus/livedata" ;;
  swift-ios) echo "notificationcenter/combine" ;;
  node) echo "rabbitmq/kafka" ;;
  react-native) echo "eventemitter" ;;
  *) echo "custom" ;;
esac)"

events:
EOF

  # Scan for events based on stack
  case "$STACK" in
    java)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        grep -n 'KafkaTemplate\|@KafkaListener\|ProducerRecord' "$f" 2>/dev/null | head -10 | while IFS=: read -r line content; do
          echo "  - file: \"${f#$REPO_PATH/}:$line\"" >> "$event_file"
          echo "    type: \"kafka\"" >> "$event_file"
        done || true
      done < <(find "$REPO_PATH" -name "*.java" -path "*/src/*" 2>/dev/null)
      ;;
    kotlin-android)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        grep -n 'LiveData\|MutableLiveData\|SharedFlow\|StateFlow\|EventBus' "$f" 2>/dev/null | head -10 | while IFS=: read -r line content; do
          echo "  - file: \"${f#$REPO_PATH/}:$line\"" >> "$event_file"
          echo "    type: \"flow/livedata\"" >> "$event_file"
        done || true
      done < <(find "$REPO_PATH" -name "*.kt" 2>/dev/null)
      ;;
    swift-ios)
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        grep -n 'NotificationCenter\|Combine\|PassthroughSubject\|CurrentValueSubject' "$f" 2>/dev/null | head -10 | while IFS=: read -r line content; do
          echo "  - file: \"${f#$REPO_PATH/}:$line\"" >> "$event_file"
          echo "    type: \"combine/notification\"" >> "$event_file"
        done || true
      done < <(find "$REPO_PATH" -name "*.swift" 2>/dev/null)
      ;;
  esac

  cat >> "$event_file" << 'EOF'

producers: []
consumers: []
EOF

  log_success "Created: contracts/events.yaml"
}

generate_dependencies_contract() {
  log_info "Generating dependencies contract..."
  local dep_file="$CONTRACTS_DIR/dependencies.yaml"

  cat > "$dep_file" << EOF
# Dependencies Contract — $REPO_NAME
# Generated: $TIMESTAMP | Commit: ${COMMIT_HASH:0:8} | Stack: $STACK

version: "1.0"
module: "$REPO_NAME"

# Internal dependencies (cross-pod / cross-module)
internal:
  # - module: "pod-2-payments"
  #   interface: "PaymentManager"
  #   methods: ["processPayment", "getReceipt"]
  #   criticality: "high"

# External service dependencies
external:
  # - service: "UserService"
  #   version: "3.2"
  #   endpoints: ["GET /users/{id}"]
  #   fallback: "local_cache"
  #   sla: "99.9%"

# Third-party libraries (critical ones only)
libraries:
EOF

  # Scan critical dependencies
  case "$STACK" in
    java)
      if [[ -f "$REPO_PATH/pom.xml" ]]; then
        grep -o '<artifactId>[^<]*</artifactId>' "$REPO_PATH/pom.xml" 2>/dev/null | head -10 | while read -r line; do
          local lib=$(echo "$line" | sed 's/<[^>]*>//g')
          echo "  - name: \"$lib\"" >> "$dep_file"
        done || true
      fi
      ;;
    kotlin-android)
      if [[ -f "$REPO_PATH/build.gradle.kts" ]]; then
        grep 'implementation\|api(' "$REPO_PATH/build.gradle.kts" 2>/dev/null | head -10 | while read -r line; do
          local lib=$(echo "$line" | grep -oP '"[^"]*"' | head -1 | tr -d '"')
          [[ -n "$lib" ]] && echo "  - name: \"$lib\"" >> "$dep_file"
        done || true
      fi
      ;;
    swift-ios)
      if [[ -f "$REPO_PATH/Podfile" ]]; then
        grep "pod '" "$REPO_PATH/Podfile" 2>/dev/null | head -10 | while read -r line; do
          local lib=$(echo "$line" | grep -oP "'[^']*'" | head -1 | tr -d "'")
          [[ -n "$lib" ]] && echo "  - name: \"$lib\"" >> "$dep_file"
        done || true
      fi
      ;;
    node)
      if [[ -f "$REPO_PATH/package.json" ]]; then
        (grep -A50 '"dependencies"' "$REPO_PATH/package.json" 2>/dev/null || true) | grep '"' | head -10 | while read -r line; do
          local lib=$(echo "$line" | grep -oP '"[^"]*"' | head -1 | tr -d '"')
          [[ -n "$lib" && "$lib" != "dependencies" ]] && echo "  - name: \"$lib\"" >> "$dep_file"
        done || true
      fi
      ;;
  esac

  log_success "Created: contracts/dependencies.yaml"
}

################################################################################
# KNOWLEDGE — Auto-generated from scan
################################################################################

generate_manifest() {
  log_info "Generating module manifest..."
  local manifest="$KNOWLEDGE_DIR/manifest.md"

  cat > "$manifest" << EOF
# Module Manifest — $REPO_NAME
**Stack:** $STACK | **Generated:** $TIMESTAMP | **Commit:** ${COMMIT_HASH:0:8}

## Source Structure
EOF

  case "$STACK" in
    java)
      find "$REPO_PATH" -path "*/src/main/java/*" -type d 2>/dev/null | head -20 | while read -r d; do
        echo "- ${d#$REPO_PATH/}" >> "$manifest"
      done || true
      echo "" >> "$manifest"
      echo "## Controllers" >> "$manifest"
      find "$REPO_PATH" -name "*Controller.java" 2>/dev/null | head -15 | while read -r f; do
        echo "- $(basename "$f" .java)" >> "$manifest"
      done || true
      ;;
    kotlin-android)
      echo "" >> "$manifest"
      echo "## Activities" >> "$manifest"
      find "$REPO_PATH" -name "*Activity.kt" 2>/dev/null | head -15 | while read -r f; do
        echo "- $(basename "$f" .kt)" >> "$manifest"
      done || true
      echo "" >> "$manifest"
      echo "## Fragments" >> "$manifest"
      find "$REPO_PATH" -name "*Fragment.kt" 2>/dev/null | head -15 | while read -r f; do
        echo "- $(basename "$f" .kt)" >> "$manifest"
      done || true
      echo "" >> "$manifest"
      echo "## ViewModels" >> "$manifest"
      find "$REPO_PATH" -name "*ViewModel.kt" 2>/dev/null | head -15 | while read -r f; do
        echo "- $(basename "$f" .kt)" >> "$manifest"
      done || true
      ;;
    swift-ios)
      echo "" >> "$manifest"
      echo "## ViewControllers" >> "$manifest"
      find "$REPO_PATH" -name "*ViewController.swift" 2>/dev/null | head -15 | while read -r f; do
        echo "- $(basename "$f" .swift)" >> "$manifest"
      done || true
      echo "" >> "$manifest"
      echo "## Views (SwiftUI)" >> "$manifest"
      find "$REPO_PATH" -name "*View.swift" 2>/dev/null | head -15 | while read -r f; do
        echo "- $(basename "$f" .swift)" >> "$manifest"
      done || true
      echo "" >> "$manifest"
      echo "## Models" >> "$manifest"
      find "$REPO_PATH" -name "*Model.swift" 2>/dev/null | head -15 | while read -r f; do
        echo "- $(basename "$f" .swift)" >> "$manifest"
      done || true
      ;;
    node|react-native)
      echo "" >> "$manifest"
      echo "## Source Files" >> "$manifest"
      find "$REPO_PATH/src" \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) -not -path "*/node_modules/*" 2>/dev/null | head -20 | while read -r f; do
        echo "- ${f#$REPO_PATH/}" >> "$manifest"
      done || true
      ;;
    *)
      echo "" >> "$manifest"
      echo "## Files" >> "$manifest"
      find "$REPO_PATH" -maxdepth 3 -type f \( -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.py" \) 2>/dev/null | head -20 | while read -r f; do
        echo "- ${f#$REPO_PATH/}" >> "$manifest"
      done || true
      ;;
  esac

  log_success "Created: knowledge/manifest.md"
}

generate_known_issues() {
  log_info "Scanning known issues from git history..."
  local issues="$KNOWLEDGE_DIR/known-issues.md"

  cat > "$issues" << EOF
# Known Issues — $REPO_NAME
**Generated:** $TIMESTAMP

## Recent Bug Fixes
EOF

  (cd "$REPO_PATH" && git log --oneline --grep="fix\|bug\|hotfix\|patch" -i -n 25 2>/dev/null || true) | while read -r line; do
    echo "- $line" >> "$issues"
  done

  log_success "Created: knowledge/known-issues.md"
}

generate_impact_rules() {
  log_info "Generating impact rules..."
  local rules="$KNOWLEDGE_DIR/impact-rules.md"

  cat > "$rules" << EOF
# Change Impact Rules — $REPO_NAME
**Stack:** $STACK | **Generated:** $TIMESTAMP

## Impact Matrix
EOF

  case "$STACK" in
    java)
      cat >> "$rules" << 'EOF'

| Change | Check |
|--------|-------|
| Controller | Service layer, API contracts, consumers |
| Service | Repository calls, other services |
| Repository | Database migrations, entity changes |
| Entity | Migrations, API serialization |
| Config | All dependent code |
| pom.xml | Build, dependency conflicts |
EOF
      ;;
    kotlin-android)
      cat >> "$rules" << 'EOF'

| Change | Check |
|--------|-------|
| Activity | Fragment interactions, navigation |
| Fragment | ViewModel bindings, shared elements |
| ViewModel | Repository calls, UI state |
| Room Entity | Migration scripts, DAO queries |
| DAO | ViewModel queries, data flow |
| Retrofit API | Response models, error handling |
| Hilt Module | Dependency injection graph |
| build.gradle.kts | Build, version conflicts |
EOF
      ;;
    swift-ios)
      cat >> "$rules" << 'EOF'

| Change | Check |
|--------|-------|
| ViewController | Storyboard, navigation |
| SwiftUI View | Preview, binding contracts |
| Model | CoreData migration, codable |
| CoreData Entity | Migration, fetch requests |
| Network Layer | Response models, error handling |
| Podfile | Build, version conflicts |
EOF
      ;;
    node|react-native)
      cat >> "$rules" << 'EOF'

| Change | Check |
|--------|-------|
| Route/Controller | Middleware, validators |
| Model/Schema | Migration, serialization |
| Middleware | All routes using it |
| Config | Environment-specific behavior |
| package.json | Build, version conflicts |
EOF
      ;;
  esac

  log_success "Created: knowledge/impact-rules.md"
}

generate_tech_decisions() {
  log_info "Scanning tech decisions..."
  local tech="$KNOWLEDGE_DIR/tech-decisions.md"

  cat > "$tech" << EOF
# Tech Decisions — $REPO_NAME
**Stack:** $STACK | **Generated:** $TIMESTAMP

## Detected Frameworks
EOF

  case "$STACK" in
    java)
      [[ -f "$REPO_PATH/pom.xml" ]] && echo "- Build: Maven" >> "$tech"
      [[ -f "$REPO_PATH/build.gradle" ]] && echo "- Build: Gradle" >> "$tech"
      grep -q "spring-boot" "$REPO_PATH/pom.xml" 2>/dev/null && echo "- Framework: Spring Boot" >> "$tech"
      grep -q "spring-cloud" "$REPO_PATH/pom.xml" 2>/dev/null && echo "- Cloud: Spring Cloud" >> "$tech"
      ;;
    kotlin-android)
      echo "- Language: Kotlin" >> "$tech"
      grep -q "hilt" "$REPO_PATH/build.gradle.kts" 2>/dev/null && echo "- DI: Hilt" >> "$tech"
      grep -q "retrofit" "$REPO_PATH/build.gradle.kts" 2>/dev/null && echo "- Network: Retrofit" >> "$tech"
      grep -q "room" "$REPO_PATH/build.gradle.kts" 2>/dev/null && echo "- Database: Room" >> "$tech"
      grep -q "compose" "$REPO_PATH/build.gradle.kts" 2>/dev/null && echo "- UI: Jetpack Compose" >> "$tech"
      ;;
    swift-ios)
      echo "- Language: Swift" >> "$tech"
      [[ -f "$REPO_PATH/Podfile" ]] && echo "- Dependencies: CocoaPods" >> "$tech"
      [[ -f "$REPO_PATH/Package.swift" ]] && echo "- Dependencies: Swift Package Manager" >> "$tech"
      grep -q "Alamofire" "$REPO_PATH/Podfile" 2>/dev/null && echo "- Network: Alamofire" >> "$tech"
      grep -q "Realm" "$REPO_PATH/Podfile" 2>/dev/null && echo "- Database: Realm" >> "$tech"
      ;;
    node)
      [[ -f "$REPO_PATH/tsconfig.json" ]] && echo "- Language: TypeScript" >> "$tech" || echo "- Language: JavaScript" >> "$tech"
      grep -q "express" "$REPO_PATH/package.json" 2>/dev/null && echo "- Framework: Express" >> "$tech"
      grep -q "nestjs" "$REPO_PATH/package.json" 2>/dev/null && echo "- Framework: NestJS" >> "$tech"
      ;;
  esac

  log_success "Created: knowledge/tech-decisions.md"
}

################################################################################
# METADATA
################################################################################

generate_metadata() {
  log_info "Saving metadata..."
  cat > "$MODULE_DIR/meta.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "commit": "$COMMIT_HASH",
  "stack": "$STACK",
  "repo": "$REPO_NAME",
  "repo_path": "$REPO_PATH",
  "version": "2.0",
  "system": "unified-module"
}
EOF
  log_success "Created: meta.json"
}

################################################################################
# MAIN
################################################################################

generate_api_contract
generate_data_contract
generate_event_contract
generate_dependencies_contract
generate_manifest
generate_known_issues
generate_impact_rules
generate_tech_decisions
generate_metadata

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Module system initialized at: $MODULE_DIR${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Structure:"
echo "  contracts/api.yaml          — API endpoints, consumers, deprecations"
echo "  contracts/data.yaml         — DB schemas, migrations"
echo "  contracts/events.yaml       — Event system (Kafka/EventBus/Combine)"
echo "  contracts/dependencies.yaml — Cross-pod + external service deps"
echo "  knowledge/manifest.md       — Code structure"
echo "  knowledge/known-issues.md   — Bug history from git"
echo "  knowledge/impact-rules.md   — Change impact matrix"
echo "  knowledge/tech-decisions.md — Framework versions"
echo "  meta.json                   — Scan metadata"
echo ""
echo "Next steps:"
echo "  sdlc module show            — View contracts and knowledge"
echo "  sdlc module load            — Smart load for current changes"
echo "  sdlc module validate        — Pre-merge contract validation"
echo ""
