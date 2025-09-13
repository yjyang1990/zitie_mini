#!/bin/bash

# PRD Parse Script - PRD to Epic Conversion System
# Convert Product Requirements Documents into implementation epics with task breakdown

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

# Function to show usage
show_usage() {
    show_command_help "/pm:prd-parse" "Convert PRD to implementation epic" \
        "/pm:prd-parse <feature_name> [OPTIONS]      # Convert PRD to epic
/pm:prd-parse user-auth                         # Basic conversion
/pm:prd-parse user-auth --template=backend      # Use backend template
/pm:prd-parse user-auth --force                 # Overwrite existing epic
/pm:prd-parse user-auth --dry-run               # Preview conversion"
    
    echo ""
    echo "Options:"
    echo "  --template=<type>   Epic template: frontend, backend, mobile, fullstack"
    echo "  --detailed          Comprehensive technical analysis"
    echo "  --minimal           Lightweight epic structure"
    echo "  --force             Overwrite existing epic"
    echo "  --dry-run           Preview conversion process"
    echo "  --help              Show this help message"
}

# Parse arguments
FEATURE_NAME=""
EPIC_TEMPLATE="standard"
DETAILED_MODE=false
MINIMAL_MODE=false
FORCE_CREATE=false
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    "--template="*)
      EPIC_TEMPLATE="${arg#*=}"
      ;;
    "--detailed")
      DETAILED_MODE=true
      ;;
    "--minimal")
      MINIMAL_MODE=true
      ;;
    "--force"|"-f")
      FORCE_CREATE=true
      ;;
    "--dry-run")
      DRY_RUN=true
      ;;
    "--help")
      show_usage
      ;;
    -*|--*)
      show_error "Unknown Option" "Unknown option: $arg"
      show_usage
      ;;
    *)
      if [[ -z "$FEATURE_NAME" ]]; then
        FEATURE_NAME="$arg"
      fi
      ;;
  esac
done

if [[ -z "$FEATURE_NAME" ]]; then
    show_error "Missing Feature Name" "Feature name is required"
    show_usage
fi

# Validate project structure
if ! validate_ccpm_structure 2>/dev/null; then
    show_error "Project Not Initialized" "CCPM project not initialized"
    show_tip "Run /pm:init to initialize the project"
    exit 1
fi

# Display header
show_title "🔄 PRD to Epic Conversion" 50
show_info "Feature: $FEATURE_NAME"
show_info "Template: $EPIC_TEMPLATE"

if [[ "$DRY_RUN" == "true" ]]; then
    show_warning "DRY RUN MODE" "Preview operations only"
fi

if [[ "$FORCE_CREATE" == "true" ]]; then
    show_warning "FORCE MODE" "Will overwrite existing epic"
fi

echo ""

# Validate feature name format
if ! [[ "$FEATURE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    show_error "Invalid Feature Name" "Feature name must contain only letters, numbers, hyphens, and underscores"
    show_tip "Examples: user-auth, payment-v2, notification-system"
    exit 1
fi

show_success "Feature Name Validated" "$FEATURE_NAME"

# Verify PRD exists
PRD_FILE=".claude/prds/$FEATURE_NAME.md"
if [[ ! -f "$PRD_FILE" ]]; then
    show_error "PRD Not Found" "PRD file does not exist: $PRD_FILE"
    show_tip "Create PRD first: /pm:prd-new $FEATURE_NAME"
    exit 1
fi

show_success "PRD Found" "$PRD_FILE"

# Validate PRD structure
show_subtitle "📋 PRD Validation"

if ! grep -q "^name:" "$PRD_FILE" 2>/dev/null; then
    show_error "Invalid PRD" "PRD must have valid frontmatter with name field"
    exit 1
fi

required_fields=("name")
missing_fields=()

for field in "${required_fields[@]}"; do
    if ! grep -q "^$field:" "$PRD_FILE" 2>/dev/null; then
        missing_fields+=("$field")
    fi
done

if [[ ${#missing_fields[@]} -gt 0 ]]; then
    show_error "Missing PRD Fields" "Missing required fields: ${missing_fields[*]}"
    show_tip "Update PRD frontmatter: $PRD_FILE"
    exit 1
fi

show_success "PRD Validation" "Structure validated"

# Check for existing epic
EPIC_DIR=".claude/epics/$FEATURE_NAME"
EPIC_FILE="$EPIC_DIR/epic.md"

if [[ -f "$EPIC_FILE" ]]; then
    if [[ "$FORCE_CREATE" == "false" && "$DRY_RUN" == "false" ]]; then
        show_error "Epic Already Exists" "Epic '$FEATURE_NAME' already exists"
        show_info "Options:"
        echo "  /pm:prd-parse $FEATURE_NAME --force    # Overwrite existing epic"
        echo "  /pm:epic-show $FEATURE_NAME            # View existing epic"
        exit 1
    elif [[ "$FORCE_CREATE" == "true" ]]; then
        show_warning "Overwriting Existing Epic" "$EPIC_FILE"
    fi
fi

echo ""

# PRD content analysis
show_subtitle "📖 PRD Content Analysis"

# Extract PRD metadata
prd_name=$(grep "^name:" "$PRD_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "$FEATURE_NAME")
prd_template=$(grep "^template:" "$PRD_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "standard")
prd_status=$(grep "^status:" "$PRD_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "draft")

show_info "Name: $prd_name"
show_info "Template: $prd_template"
show_info "Status: $prd_status"

# Auto-detect epic template based on PRD
if [[ "$EPIC_TEMPLATE" == "standard" ]]; then
    case "$prd_template" in
        "web-app"|"webapp") 
            EPIC_TEMPLATE="frontend"
            show_info "Auto-selected template: frontend (based on PRD)"
            ;;
        "api"|"service") 
            EPIC_TEMPLATE="backend"
            show_info "Auto-selected template: backend (based on PRD)"
            ;;
        "mobile-app"|"mobile") 
            EPIC_TEMPLATE="mobile"
            show_info "Auto-selected template: mobile (based on PRD)"
            ;;
        *) 
            EPIC_TEMPLATE="fullstack"
            show_info "Auto-selected template: fullstack (default)"
            ;;
    esac
fi

# Determine epic complexity
epic_complexity="medium"
if [[ "$MINIMAL_MODE" == "true" ]]; then
    epic_complexity="minimal"
elif [[ "$DETAILED_MODE" == "true" ]]; then
    epic_complexity="detailed"
fi

show_info "Complexity: $epic_complexity"

echo ""

# Dry run preview
if [[ "$DRY_RUN" == "true" ]]; then
    show_subtitle "🔍 Dry Run Preview"
    
    show_info "Would generate epic structure:"
    echo "  Epic directory: $EPIC_DIR"
    echo "  Epic file: $EPIC_FILE"
    echo "  Template: $EPIC_TEMPLATE"
    echo "  Complexity: $epic_complexity"
    echo ""
    show_tip "Execute conversion: /pm:prd-parse $FEATURE_NAME"
    exit 0
fi

# Create epic directory
show_subtitle "📁 Epic Creation"

ensure_directory "$EPIC_DIR"
show_success "Epic Directory Created" "$EPIC_DIR"

# Generate epic content
show_progress "Generating epic content..."

current_datetime=$(format_timestamp)
formatted_date=$(date '+%Y-%m-%d')

# Create epic file
cat > "$EPIC_FILE" << EOF
---
name: $FEATURE_NAME
status: backlog
created: $current_datetime
progress: 0%
template: $EPIC_TEMPLATE
prd: .claude/prds/$FEATURE_NAME.md
complexity: $epic_complexity
---

# Epic: $FEATURE_NAME

> **PRD Source**: $PRD_FILE | **Template**: $EPIC_TEMPLATE | **Created**: $formatted_date

## Overview

**Business Context**: Implementation of $FEATURE_NAME feature as specified in the Product Requirements Document.

**Technical Summary**: This epic encompasses the complete technical implementation of $FEATURE_NAME, including $(
case "$EPIC_TEMPLATE" in
  "frontend") echo "user interface development, state management, and user experience optimization" ;;
  "backend") echo "API development, data management, and business logic implementation" ;;
  "mobile") echo "mobile application development, platform-specific features, and mobile user experience" ;;
  *) echo "full-stack development covering frontend, backend, and infrastructure components" ;;
esac
).

## Architecture Decisions

### Technology Stack
- **Template Focus**: $EPIC_TEMPLATE architecture pattern
- **Development Approach**: $(if [[ "$epic_complexity" == "minimal" ]]; then echo "Streamlined implementation"; elif [[ "$epic_complexity" == "detailed" ]]; then echo "Comprehensive development"; else echo "Balanced implementation"; fi)
- **Quality Standards**: Code review, automated testing, and performance optimization

### Design Patterns
- **Architecture Pattern**: $(case "$EPIC_TEMPLATE" in
  "frontend") echo "Component-based architecture with state management" ;;
  "backend") echo "Service-oriented architecture with API-first design" ;;
  "mobile") echo "Mobile-first architecture with platform optimization" ;;
  *) echo "Modular architecture with separation of concerns" ;;
esac)
- **Code Organization**: Feature-based structure with clear boundaries
- **Testing Strategy**: Unit, integration, and end-to-end testing approach

## Technical Approach

### Implementation Components
$(case "$EPIC_TEMPLATE" in
  "frontend") 
    echo "- **User Interface**: Component library and responsive design"
    echo "- **State Management**: Application state and data flow"
    echo "- **User Experience**: Interaction patterns and accessibility"
    ;;
  "backend")
    echo "- **API Services**: RESTful endpoints and business logic"
    echo "- **Data Management**: Database design and data access layer"
    echo "- **Authentication**: Security and authorization systems"
    ;;
  "mobile")
    echo "- **Mobile UI**: Platform-specific user interface components"
    echo "- **Device Integration**: Native device feature integration"
    echo "- **Offline Support**: Local data storage and synchronization"
    ;;
  *)
    echo "- **Frontend**: User interface and user experience implementation"
    echo "- **Backend**: API services and data management"
    echo "- **Integration**: System integration and deployment"
    ;;
esac)

### Quality Assurance
- **Testing**: Comprehensive test coverage at all levels
- **Performance**: Performance optimization and monitoring
- **Security**: Security assessment and vulnerability management

## Implementation Strategy

### Development Phases
1. **Foundation Phase**: Core architecture setup and basic functionality
2. **Feature Development**: Implementation of primary features and user stories  
3. **Integration Phase**: System integration and cross-component testing
4. **Quality Assurance**: Comprehensive testing and performance optimization
5. **Deployment**: Production deployment and monitoring setup

### Testing Approach
- **Unit Testing**: Component-level testing with high coverage
- **Integration Testing**: API and service integration verification
- **End-to-End Testing**: Complete user workflow validation
- **Performance Testing**: Load testing and optimization validation

## Task Breakdown Preview

Implementation will be organized into focused, manageable tasks:

- [ ] **Foundation Setup**: Core architecture and development environment
- [ ] **Core Implementation**: Primary functionality and business logic
- [ ] **User Interface**: User-facing components and interactions
- [ ] **Integration**: External system connections and data flow
- [ ] **Testing & Quality**: Comprehensive testing and validation
- [ ] **Deployment**: Production deployment and monitoring

### Task Organization
- **Estimated Scope**: $(if [[ "$epic_complexity" == "minimal" ]]; then echo "Small to Medium"; elif [[ "$epic_complexity" == "detailed" ]]; then echo "Medium to Large"; else echo "Medium"; fi) development effort
- **Parallel Work**: Tasks designed for potential parallel development streams

## Dependencies

### External Dependencies
- **External Services**: Third-party service integrations as specified in PRD
- **Infrastructure**: Production environment setup and configuration

### Internal Dependencies
- **Design System**: UI/UX design specifications and component library
- **Development Environment**: Local development setup and tooling
- **Testing Infrastructure**: Test environment and automated testing pipeline

## Success Criteria

### Quality Gates
- **Code Quality**: Code review approval and automated quality checks pass
- **Test Coverage**: Minimum test coverage requirements met across all components
- **Performance**: Performance benchmarks met in production-like environment

### Acceptance Criteria
- **Functional Requirements**: All PRD functional requirements implemented and verified
- **Non-Functional Requirements**: Performance, security, and usability requirements met
- **Documentation**: Complete technical documentation and deployment guides

## Estimated Effort

### Timeline
- **Development Phase**: $(if [[ "$epic_complexity" == "minimal" ]]; then echo "2-4 weeks"; elif [[ "$epic_complexity" == "detailed" ]]; then echo "4-8 weeks"; else echo "3-6 weeks"; fi) for core implementation
- **Testing Phase**: 1-2 weeks for comprehensive testing and validation
- **Deployment Phase**: 3-5 days for production deployment and monitoring setup

### Resource Requirements
- **Development**: $(if [[ "$EPIC_TEMPLATE" == "fullstack" ]]; then echo "Full-stack developer"; else echo "Specialized $EPIC_TEMPLATE developer"; fi) with relevant experience
- **Testing**: QA engineer for comprehensive testing and validation
- **DevOps**: Infrastructure engineer for deployment and monitoring setup

---

*Epic generated from PRD: $PRD_FILE*  
*Created: $formatted_date | Template: $EPIC_TEMPLATE | Complexity: $epic_complexity*  
*Ready for task breakdown: /pm:epic-decompose $FEATURE_NAME*
EOF

show_success "Epic Created" "$EPIC_FILE"

# Validation
show_progress "Validating epic structure..."

validation_errors=0
validation_warnings=0

# Check file creation and basic structure
if [[ ! -f "$EPIC_FILE" ]]; then
    show_error "Epic file not created"
    ((validation_errors++))
else
    file_size=$(wc -c < "$EPIC_FILE" 2>/dev/null || echo "0")
    if [[ $file_size -lt 1000 ]]; then
        show_warning "Epic file seems small ($file_size bytes)"
        ((validation_warnings++))
    fi
    
    if grep -q "^name: $FEATURE_NAME" "$EPIC_FILE"; then
        show_success "Epic Structure" "Frontmatter validated"
    else
        show_error "Epic frontmatter validation failed"
        ((validation_errors++))
    fi
fi

if [[ $validation_errors -gt 0 ]]; then
    show_error "Epic validation failed with $validation_errors errors"
    exit 1
fi

echo ""

# Summary
show_subtitle "🎉 Conversion Complete"

show_success "PRD Converted" "Epic created successfully!"
echo ""
show_info "Summary:"
show_info "Feature: $FEATURE_NAME"
show_info "PRD Source: $PRD_FILE"
show_info "Epic Created: $EPIC_FILE"
show_info "Template: $EPIC_TEMPLATE"
show_info "Complexity: $epic_complexity"

if [[ $validation_warnings -gt 0 ]]; then
    show_warning "Warnings: $validation_warnings (review recommended)"
fi

echo ""
show_subtitle "🚀 Next Steps"

show_info "Epic development workflow:"
echo "  /pm:epic-decompose $FEATURE_NAME    # Break down into detailed tasks"
echo "  /pm:epic-sync $FEATURE_NAME         # Sync with GitHub"
echo "  /pm:epic-show $FEATURE_NAME         # Review epic details"
echo ""
show_info "Development workflow:"
echo "  /pm:epic-start $FEATURE_NAME        # Initialize development"
echo "  /pm:next                           # Find next available tasks"
echo "  /pm:status                         # Project overview"

echo ""
show_completion "PRD to Epic conversion completed!"
show_tip "Review the generated epic and decompose into tasks when ready"