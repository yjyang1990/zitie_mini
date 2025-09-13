#!/bin/bash

# Issue Start Script - Task Development Orchestration
# Start development on a GitHub issue with local task synchronization

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
    show_command_help "/pm:issue-start" "Start development on a GitHub issue" \
        "/pm:issue-start <issue_number> [OPTIONS]    # Start issue development
/pm:issue-start 1234                            # Start development
/pm:issue-start 1234 --analyze                  # Analyze before starting
/pm:issue-start 1234 --dry-run                  # Preview operations
/pm:issue-start 1234 --force                    # Force start despite warnings"
    
    echo ""
    echo "Options:"
    echo "  --analyze          Auto-analyze issue before starting"
    echo "  --dry-run          Preview development orchestration"
    echo "  --force            Override safety checks"
    echo "  --help             Show this help message"
}

# Parse arguments
ISSUE_NUMBER=""
AUTO_ANALYZE=false
DRY_RUN=false
FORCE_START=false

for arg in "$@"; do
  case "$arg" in
    "--analyze")
      AUTO_ANALYZE=true
      ;;
    "--dry-run")
      DRY_RUN=true
      ;;
    "--force"|"-f")
      FORCE_START=true
      ;;
    "--help")
      show_usage
      ;;
    -*|--*)
      show_error "Unknown Option" "Unknown option: $arg"
      show_usage
      ;;
    *)
      if [[ -z "$ISSUE_NUMBER" ]]; then
        ISSUE_NUMBER="$arg"
      fi
      ;;
  esac
done

if [[ -z "$ISSUE_NUMBER" ]]; then
    show_error "Missing Issue Number" "Issue number is required"
    show_usage
fi

# Validate issue number format
if [[ ! "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
    show_error "Invalid Issue Number" "Issue number must be numeric (e.g., 1234)"
    exit 1
fi

# Validate project structure
if ! validate_ccmp_structure 2>/dev/null; then
    show_error "Project Not Initialized" "CCPM project not initialized"
    show_tip "Run /pm:init to initialize the project"
    exit 1
fi

# Display header
show_title "🚀 Issue Development Orchestration" 50
show_info "Issue: #$ISSUE_NUMBER"
show_info "Started: $(format_timestamp)"

if [[ "$DRY_RUN" == "true" ]]; then
    show_warning "DRY RUN MODE" "Preview operations only"
fi

if [[ "$FORCE_START" == "true" ]]; then
    show_warning "FORCE MODE" "Override safety checks enabled"
fi

echo ""

# GitHub CLI validation
show_subtitle "🔍 GitHub Setup Validation"

if ! command -v gh >/dev/null 2>&1; then
    show_error "GitHub CLI Missing" "GitHub CLI (gh) not found"
    show_tip "Install: brew install gh"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    show_error "GitHub Authentication" "GitHub CLI not authenticated"
    show_tip "Authenticate: gh auth login"
    exit 1
fi

show_success "GitHub CLI" "Available and authenticated"

# Fetch issue details
show_progress "Fetching issue details: #$ISSUE_NUMBER"
issue_data=$(gh issue view "$ISSUE_NUMBER" --json state,title,labels,body,assignees,url 2>/dev/null)

if [[ -z "$issue_data" ]]; then
    show_error "Issue Not Found" "Cannot access issue #$ISSUE_NUMBER"
    show_tip "Check issue number and repository permissions"
    exit 1
fi

# Extract issue information
issue_state=$(echo "$issue_data" | jq -r '.state' 2>/dev/null || echo "unknown")
issue_title=$(echo "$issue_data" | jq -r '.title' 2>/dev/null || echo "Unknown Issue")
issue_url=$(echo "$issue_data" | jq -r '.url' 2>/dev/null || echo "")
issue_assignees=$(echo "$issue_data" | jq -r '.assignees[].login' 2>/dev/null || echo "")

show_success "Issue Retrieved" "#$ISSUE_NUMBER"
show_info "Title: $issue_title"
show_info "State: $issue_state"
show_info "Assignees: $(if [[ -n "$issue_assignees" ]]; then echo "$issue_assignees"; else echo "None"; fi)"

# Validate issue state
if [[ "$issue_state" == "closed" && "$FORCE_START" == "false" ]]; then
    show_error "Issue Closed" "Issue is already closed"
    show_tip "Reopen issue: gh issue reopen $ISSUE_NUMBER"
    show_tip "Or use --force to work on closed issue"
    exit 1
fi

# Check assignment
current_user=$(gh api user --jq '.login' 2>/dev/null || echo "")
if [[ -n "$issue_assignees" && "$issue_assignees" != "$current_user" && "$FORCE_START" == "false" ]]; then
    show_warning "Issue Assigned" "Issue assigned to: $issue_assignees"
    show_tip "Use --force to work on assigned issue or coordinate with assignee"
    if [[ "$DRY_RUN" == "false" ]]; then
        exit 1
    fi
fi

echo ""

# Local task file discovery
show_subtitle "🔍 Local Task Discovery"

TASK_FILE=""
EPIC_NAME=""

show_progress "Searching for local task files..."

# Search for the issue number file in epics directories
for epic_dir in .claude/epics/*/; do
    if [[ -d "$epic_dir" && -f "$epic_dir$ISSUE_NUMBER.md" ]]; then
        TASK_FILE="$epic_dir$ISSUE_NUMBER.md"
        EPIC_NAME=$(basename "$epic_dir")
        break
    fi
done

if [[ -z "$TASK_FILE" ]]; then
    show_error "Task File Not Found" "Local task file not found for issue #$ISSUE_NUMBER"
    echo ""
    show_info "This could mean:"
    echo "  • The issue hasn't been synced to local files yet"
    echo "  • The issue number is incorrect"
    echo "  • The epic hasn't been decomposed locally"
    echo ""
    show_info "Try:"
    echo "  /pm:sync                     # Sync from GitHub"
    echo "  /pm:status                   # Check project status"
    echo "  /pm:next                     # Get recommended next task"
    exit 1
fi

show_success "Task File Found" "$TASK_FILE"
show_info "Epic: $EPIC_NAME"

echo ""

# Task analysis
show_subtitle "📋 Task Requirements Analysis"

if [[ -f "$TASK_FILE" ]]; then
    # Extract task name
    TASK_NAME=$(grep "^name:" "$TASK_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "Issue #$ISSUE_NUMBER")
    TASK_STATUS=$(grep "^status:" "$TASK_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "pending")
    TASK_PRIORITY=$(grep "^priority:" "$TASK_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "medium")
    
    show_info "Task: $TASK_NAME"
    show_info "Status: $TASK_STATUS"
    show_info "Priority: $TASK_PRIORITY"
    
    # Show description if available
    if grep -q "## Description" "$TASK_FILE"; then
        echo ""
        show_info "Description:"
        sed -n '/## Description/,/^##/p' "$TASK_FILE" | sed '1d;$d' | sed 's/^/   /'
    fi
    
    # Show acceptance criteria if available
    if grep -q "## Acceptance Criteria" "$TASK_FILE"; then
        echo ""
        show_info "Acceptance Criteria:"
        sed -n '/## Acceptance Criteria/,/^##/p' "$TASK_FILE" | sed '1d;$d' | sed 's/^/   /'
    fi
    
    # Show dependencies
    DEPENDENCIES=$(grep "^dependencies:" "$TASK_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "")
    if [[ "$DEPENDENCIES" != "none" && -n "$DEPENDENCIES" ]]; then
        echo ""
        show_warning "Dependencies" "$DEPENDENCIES"
    fi
fi

echo ""

# Dry run preview
if [[ "$DRY_RUN" == "true" ]]; then
    show_subtitle "🔍 Dry Run Preview"
    
    show_info "Would execute the following actions:"
    echo "  ✓ Assign issue #$ISSUE_NUMBER to current user"
    echo "  ✓ Add 'in-progress' label to GitHub issue"
    echo "  ✓ Post development start comment"
    echo "  ✓ Create progress tracking directory"
    echo "  ✓ Update local task status to 'in_progress'"
    echo ""
    show_tip "Execute with: /pm:issue-start $ISSUE_NUMBER"
    exit 0
fi

# GitHub issue management
show_subtitle "🔄 GitHub Issue Management"

# Assign issue to current user
if [[ -z "$issue_assignees" || "$issue_assignees" != "$current_user" ]]; then
    show_progress "Assigning issue to current user..."
    if gh issue edit "$ISSUE_NUMBER" --add-assignee "@me" >/dev/null 2>&1; then
        show_success "Issue Assigned" "Assigned to $current_user"
    else
        show_warning "Assignment failed (may lack permissions)"
    fi
fi

# Add in-progress label
show_progress "Adding 'in-progress' label..."
if gh issue edit "$ISSUE_NUMBER" --add-label "in-progress" >/dev/null 2>&1; then
    show_success "Label Added" "'in-progress'"
else
    show_warning "Could not add label (may not exist or lack permissions)"
fi

# Post start comment
show_progress "Posting development start comment..."
start_comment="🚀 **Development Started**

Started working on this issue using Claude Code Project Manager (CCPM) v2.0.

**Task Information:**
- Epic: $EPIC_NAME  
- Local Task File: \`$TASK_FILE\`
- Status: In Progress

**Next Steps:**
- Implement acceptance criteria
- Run comprehensive tests  
- Update progress tracking
- Coordinate with project workflow

---
*Automated by CCPM v2.0 - $(format_timestamp)*"

if gh issue comment "$ISSUE_NUMBER" --body "$start_comment" >/dev/null 2>&1; then
    show_success "Comment Posted" "Development start comment added"
else
    show_warning "Could not post comment (may lack permissions)"
fi

echo ""

# Progress tracking setup
show_subtitle "📁 Progress Tracking Setup"

PROGRESS_DIR=".claude/tmp/progress/issue-$ISSUE_NUMBER"
ensure_directory "$PROGRESS_DIR"

# Create session log
cat > "$PROGRESS_DIR/session.md" << EOF
# Development Session: Issue #$ISSUE_NUMBER

**Started:** $(format_timestamp)  
**Issue:** $issue_title  
**Epic:** $EPIC_NAME  
**Task File:** $TASK_FILE  

## Session Log

- Started development orchestration
- GitHub issue assigned and labeled
- Progress tracking initialized

## Next Steps

- [ ] Analyze task requirements thoroughly
- [ ] Implement functionality according to acceptance criteria
- [ ] Write/update tests
- [ ] Verify implementation
- [ ] Update task status and sync progress

## Notes

(Add development notes, decisions, and findings here)

---
*Generated by CCPM v2.0*
EOF

show_success "Progress Tracking Created" "$PROGRESS_DIR"
show_info "Session log: $PROGRESS_DIR/session.md"

echo ""

# Update local task status
show_subtitle "📝 Task Status Update"

if [[ -f "$TASK_FILE" ]]; then
    show_progress "Updating task status to 'in_progress'..."
    
    # Create backup
    backup_file="$PROGRESS_DIR/task-backup.md"
    cp "$TASK_FILE" "$backup_file"
    
    # Create temporary file for update
    temp_task_file="$PROGRESS_DIR/task-temp.md"
    
    # Update status in frontmatter
    awk -v new_status="in_progress" -v update_time="$(format_timestamp)" '
        BEGIN { in_frontmatter = 0; status_updated = 0; updated_added = 0 }
        /^---$/ { 
            if (!in_frontmatter) { 
                in_frontmatter = 1 
            } else { 
                if (!status_updated) print "status: " new_status
                if (!updated_added) print "updated: " update_time
                in_frontmatter = 0 
            }
            print; next 
        }
        in_frontmatter && /^status:/ { 
            print "status: " new_status
            status_updated = 1
            next 
        }
        in_frontmatter && /^updated:/ { 
            print "updated: " update_time
            updated_added = 1
            next 
        }
        { print }
    ' "$TASK_FILE" > "$temp_task_file"
    
    if mv "$temp_task_file" "$TASK_FILE"; then
        show_success "Task Status Updated" "Status: in_progress"
        show_info "Backup created: $backup_file"
    else
        show_warning "Could not update task file"
        rm -f "$temp_task_file"
    fi
fi

echo ""

# Development instructions
show_subtitle "🤖 Development Instructions"

show_info "Issue #$ISSUE_NUMBER is ready for development!"
echo ""
show_info "The development context includes:"
echo "  📋 Task requirements: $TASK_FILE"
echo "  📐 Epic context: .claude/epics/$EPIC_NAME/epic.md"
echo "  📊 Progress tracking: $PROGRESS_DIR/session.md"
echo ""
show_info "Development workflow:"
echo "  1. Read the full task requirements"
echo "  2. Understand the epic context"
echo "  3. Implement all acceptance criteria"
echo "  4. Test implementation thoroughly"
echo "  5. Update progress tracking"
echo ""
show_info "Post-completion workflow:"
echo "  /pm:complete $ISSUE_NUMBER         # Complete and sync task"
echo "  /pm:epic-show $EPIC_NAME           # View epic progress"
echo "  /pm:next                          # Get next available task"

echo ""
show_completion "Issue development orchestration completed!"
show_info "Ready to start development on: $issue_title"