#!/bin/bash

# PRD New Script - Comprehensive PRD Creation System
# Creates Product Requirements Documents with intelligent templates and validation

set -euo pipefail

# Load core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/lib"

# Load libraries with error checking
if [[ -f "$LIB_DIR/core.sh" ]]; then
    source "$LIB_DIR/core.sh"
fi

if [[ -f "$LIB_DIR/ui.sh" ]]; then
    source "$LIB_DIR/ui.sh"
fi

if [[ -f "$LIB_DIR/validation.sh" ]]; then
    source "$LIB_DIR/validation.sh"
fi

# PRD Creation Setup and Validation
show_title "📝 Product Requirements Document Creation" 50
show_info "Started: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Parse arguments
FEATURE_NAME=""
PRD_TEMPLATE="standard"
INTERACTIVE_MODE=false
DRY_RUN=false
FORCE_CREATE=false

for arg in "$@"; do
  case "$arg" in
    "--template="*)
      PRD_TEMPLATE="${arg#*=}"
      show_info "📋 Template: $PRD_TEMPLATE"
      ;;
    "--interactive")
      INTERACTIVE_MODE=true
      show_info "🗺️ Interactive Mode: Full brainstorming session"
      ;;
    "--dry-run")
      DRY_RUN=true
      show_info "🧪 Dry run mode: Preview only"
      ;;
    "--force")
      FORCE_CREATE=true
      show_info "⚡ Force mode: Overwrite existing PRD"
      ;;
    "--help")
      show_usage
      exit 0
      ;;
    -*)
      show_error "Unknown Option" "Unknown option: $arg"
      exit 1
      ;;
    *)
      if [[ -z "$FEATURE_NAME" ]]; then
        FEATURE_NAME="$arg"
      fi
      ;;
  esac
done

# Function to show usage
show_usage() {
    show_command_help "/pm:prd-new" "Create a new Product Requirements Document" \
        "/pm:prd-new <feature-name>              # Create standard PRD
/pm:prd-new <name> --interactive        # Interactive mode with brainstorming
/pm:prd-new <name> --template=api       # Use API template
/pm:prd-new <name> --dry-run            # Preview without creating"
}

# Validate feature name
if [[ -z "$FEATURE_NAME" ]]; then
    show_error "Missing Feature Name" "Feature name is required"
    show_usage
    exit 1
fi

# Validate feature name format
if ! [[ "$FEATURE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    show_error "Invalid Feature Name" "Feature name must contain only letters, numbers, hyphens, and underscores"
    exit 1
fi

# Initialize directories
ensure_directory ".claude/prds"
ensure_directory ".claude/templates/prd"

# Check if PRD already exists
PRD_FILE=".claude/prds/${FEATURE_NAME}.md"
if [[ -f "$PRD_FILE" && "$FORCE_CREATE" != "true" ]]; then
    show_error "PRD Already Exists" "PRD '$FEATURE_NAME' already exists at $PRD_FILE"
    show_tip "Use --force to overwrite or choose a different name"
    exit 1
fi

# Function to get PRD template
get_prd_template() {
    local template_name="$1"
    local template_file=".claude/templates/prd/${template_name}.md"
    
    # If custom template exists, use it
    if [[ -f "$template_file" ]]; then
        cat "$template_file"
        return 0
    fi
    
    # Default standard template
    cat << 'EOF'
# PRD: {{FEATURE_NAME}}

**Created:** {{DATE}}  
**Status:** Draft  
**Priority:** Medium  

## Overview

### Problem Statement
<!-- Describe the problem this feature solves -->

### Solution Summary
<!-- Brief description of the proposed solution -->

## Requirements

### Functional Requirements
<!-- What the feature must do -->

1. **Core Functionality**
   - [ ] Requirement 1
   - [ ] Requirement 2
   - [ ] Requirement 3

2. **User Interface**
   - [ ] UI Requirement 1
   - [ ] UI Requirement 2

3. **Integration Points**
   - [ ] Integration 1
   - [ ] Integration 2

### Non-Functional Requirements

1. **Performance**
   - Response time: < 200ms
   - Throughput: 1000 requests/second

2. **Security**
   - Authentication required
   - Data encryption in transit

3. **Scalability**
   - Support 10,000 concurrent users
   - Horizontal scaling capability

## User Stories

### Primary User Flows

1. **Happy Path**
   ```
   Given: User is authenticated
   When: User performs primary action
   Then: System responds appropriately
   ```

2. **Error Handling**
   ```
   Given: Invalid input
   When: User submits request
   Then: System shows clear error message
   ```

## Technical Considerations

### Dependencies
- Dependency 1
- Dependency 2

### Risks & Mitigations
1. **Risk:** Description
   - **Mitigation:** Solution approach

### Implementation Approach
- [ ] Phase 1: Foundation
- [ ] Phase 2: Core Features
- [ ] Phase 3: Optimization

## Acceptance Criteria

### Definition of Done
- [ ] All functional requirements implemented
- [ ] Code reviewed and tested
- [ ] Documentation updated
- [ ] Performance benchmarks met

### Testing Strategy
- [ ] Unit tests (>90% coverage)
- [ ] Integration tests
- [ ] End-to-end tests
- [ ] Performance tests

## Metrics & Success Criteria

### Key Performance Indicators
- Metric 1: Target value
- Metric 2: Target value

### Success Metrics
- User adoption: X% increase
- Performance: Y% improvement

## Timeline

### Milestones
- **Week 1:** Discovery and design
- **Week 2-3:** Core implementation
- **Week 4:** Testing and refinement
- **Week 5:** Deployment and monitoring

### Estimated Effort
- Development: X days
- Testing: Y days
- Documentation: Z days

---

**Next Steps:**
1. Review and approve this PRD
2. Convert to Epic: `/pm:prd-parse {{FEATURE_NAME}}`
3. Begin implementation planning
EOF
}

# Function to create PRD with interactive mode
create_interactive_prd() {
    show_subtitle "🗺️ Interactive PRD Creation"
    
    echo ""
    show_info "Let's build a comprehensive PRD together. I'll ask you some questions to help create a detailed requirements document."
    echo ""
    
    # Collect basic information
    echo "1. Problem Statement"
    echo -n "What problem does this feature solve? "
    read -r problem_statement
    
    echo ""
    echo "2. Solution Overview"
    echo -n "Briefly describe your proposed solution: "
    read -r solution_overview
    
    echo ""
    echo "3. Priority Level"
    echo "Choose priority: (1) Low (2) Medium (3) High (4) Critical"
    echo -n "Enter number [2]: "
    read -r priority_input
    
    case "${priority_input:-2}" in
        1) priority="Low" ;;
        2) priority="Medium" ;;
        3) priority="High" ;;
        4) priority="Critical" ;;
        *) priority="Medium" ;;
    esac
    
    # Create enhanced template with user input
    local template
    template=$(get_prd_template "$PRD_TEMPLATE")
    template="${template//\{\{FEATURE_NAME\}\}/$FEATURE_NAME}"
    template="${template//\{\{DATE\}\}/$(date '+%Y-%m-%d')}"
    template="${template//\{\{PROBLEM_STATEMENT\}\}/$problem_statement}"
    template="${template//\{\{SOLUTION_OVERVIEW\}\}/$solution_overview}"
    template="${template//Priority:** Medium/Priority:** $priority}"
    
    echo "$template"
}

# Function to create standard PRD
create_standard_prd() {
    local template
    template=$(get_prd_template "$PRD_TEMPLATE")
    template="${template//\{\{FEATURE_NAME\}\}/$FEATURE_NAME}"
    template="${template//\{\{DATE\}\}/$(date '+%Y-%m-%d')}"
    
    echo "$template"
}

# Generate PRD content
show_progress "Generating PRD content..."

if [[ "$INTERACTIVE_MODE" == "true" ]]; then
    PRD_CONTENT=$(create_interactive_prd)
else
    PRD_CONTENT=$(create_standard_prd)
fi

# Preview in dry-run mode
if [[ "$DRY_RUN" == "true" ]]; then
    show_subtitle "📋 PRD Preview (Dry Run)"
    echo ""
    echo "$PRD_CONTENT"
    echo ""
    show_info "This is a preview. Remove --dry-run to create the actual PRD file."
    exit 0
fi

# Create the PRD file
show_progress "Creating PRD file..."
echo "$PRD_CONTENT" > "$PRD_FILE"

# Verify creation
if [[ -f "$PRD_FILE" ]]; then
    show_success "PRD Created Successfully" "PRD '$FEATURE_NAME' created at $PRD_FILE"
    
    # Show file info
    local file_size
    file_size=$(wc -l < "$PRD_FILE" | tr -d ' ')
    show_info "File contains $file_size lines"
    
    echo ""
    show_subtitle "🚀 Next Steps"
    echo ""
    echo "1. 📝 Review and edit the PRD:"
    echo "   \$EDITOR $PRD_FILE"
    echo ""
    echo "2. 📊 Convert to Epic when ready:"
    echo "   /pm:prd-parse $FEATURE_NAME"
    echo ""
    echo "3. 📋 View all PRDs:"
    echo "   /pm:prd-list"
    echo ""
    show_tip "Edit the PRD to add specific requirements before converting to an epic"
    
else
    show_error "Creation Failed" "Failed to create PRD file at $PRD_FILE"
    exit 1
fi

exit 0