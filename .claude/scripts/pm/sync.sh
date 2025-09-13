#!/bin/bash

# Project Sync Script - Bidirectional Local-GitHub Synchronization
# Sync project tasks and epics between local files and GitHub issues

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
    show_command_help "/pm:sync" "Synchronize project with GitHub" \
        "/pm:sync [MODE] [OPTIONS]                  # Sync with GitHub
/pm:sync                                      # Full bidirectional sync
/pm:sync pull                                 # Pull from GitHub only
/pm:sync push                                 # Push to GitHub only
/pm:sync preview                              # Preview sync operations
/pm:sync <epic-name>                          # Sync specific epic"
    
    echo ""
    echo "Sync Modes:"
    echo "  (none)       Full bidirectional sync (default)"
    echo "  pull         Pull changes from GitHub to local"
    echo "  push         Push local changes to GitHub"
    echo "  preview      Preview operations without making changes"
    echo "  force        Force sync, overriding safety checks"
    echo "  <epic-name>  Sync only the specified epic"
    echo ""
    echo "Options:"
    echo "  --help       Show this help message"
}

# Parse arguments
SYNC_MODE="${1:-full}"
EPIC_FILTER=""
DRY_RUN=false
FORCE_SYNC=false

case "$SYNC_MODE" in
    "dry-run"|"preview")
        DRY_RUN=true
        SYNC_MODE="full"
        ;;
    "pull"|"push"|"full")
        # Valid sync modes
        ;;
    "force")
        FORCE_SYNC=true
        SYNC_MODE="full"
        ;;
    "--help"|"-h")
        show_usage
        ;;
    "")
        SYNC_MODE="full"
        ;;
    *)
        # Assume it's an epic filter
        EPIC_FILTER="$SYNC_MODE"
        SYNC_MODE="full"
        ;;
esac

# Validate project structure
if ! validate_ccpm_structure 2>/dev/null; then
    show_error "Project Not Initialized" "CCPM project not initialized"
    show_tip "Run /pm:init to initialize the project"
    exit 1
fi

# Display header
show_title "🔄 CCPM Project Sync" 40
show_info "Mode: $SYNC_MODE"
if [[ -n "$EPIC_FILTER" ]]; then
    show_info "Epic Filter: $EPIC_FILTER"
fi
if [[ "$DRY_RUN" == "true" ]]; then
    show_warning "PREVIEW MODE" "No changes will be applied"
fi
show_info "Started: $(format_timestamp)"
echo ""

# Environment validation
show_subtitle "🔍 Environment Validation"

# Check GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
    show_error "GitHub CLI Missing" "GitHub CLI (gh) not found"
    show_tip "Install: https://cli.github.com"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    show_error "GitHub Authentication" "GitHub CLI not authenticated"
    show_tip "Authenticate: gh auth login"
    exit 1
fi

show_success "GitHub CLI" "Available and authenticated"

# Check git status
if [[ -d ".git" ]] && ! git diff --quiet 2>/dev/null; then
    show_warning "Uncommitted Changes" "Working directory has uncommitted changes"
    show_tip "Consider committing changes before sync"
fi

show_success "Environment Validated" "Ready for sync"
echo ""

# Initialize counters
created_count=0
updated_count=0
error_count=0
local_updated_count=0

# Create temporary sync directory
SYNC_DIR=".claude/tmp/sync-$(date +%s)"
ensure_directory "$SYNC_DIR"

# Cleanup function
cleanup() {
    if [[ -n "$SYNC_DIR" && -d "$SYNC_DIR" ]]; then
        rm -rf "$SYNC_DIR"
    fi
}
trap cleanup EXIT

# Function to update task status
update_task_status() {
    local task_file="$1"
    local new_status="$2"
    
    if grep -q "^status:" "$task_file"; then
        sed -i.bak "s/^status:.*/status: $new_status/" "$task_file"
    else
        # Add status if missing
        sed -i.bak "1 a\\
status: $new_status" "$task_file"
    fi
    rm -f "$task_file.bak"
}

# Fetch GitHub data
if [[ "$SYNC_MODE" == "full" || "$SYNC_MODE" == "pull" ]]; then
    show_subtitle "📥 Fetching GitHub Data"
    
    show_progress "Downloading issues from GitHub..."
    
    if gh issue list \
        --limit 1000 \
        --state all \
        --json number,title,state,body,labels,updatedAt,createdAt \
        > "$SYNC_DIR/github-issues.json" 2>/dev/null; then
        
        issue_count=$(jq length "$SYNC_DIR/github-issues.json" 2>/dev/null || echo "0")
        show_success "GitHub Issues" "Downloaded $issue_count issues"
        
        # Filter issues by labels if jq is available
        if command -v jq >/dev/null 2>&1; then
            jq '[.[] | select(.labels[]? | .name | test("task|story|feature|bug"))]' \
                "$SYNC_DIR/github-issues.json" > "$SYNC_DIR/github-tasks.json"
                
            task_count=$(jq length "$SYNC_DIR/github-tasks.json")
            show_info "Filtered Tasks: $task_count tasks found"
        fi
    else
        show_error "GitHub Fetch Failed" "Failed to fetch GitHub issues"
        exit 1
    fi
    
    echo ""
fi

# Push local changes to GitHub
if [[ "$SYNC_MODE" == "full" || "$SYNC_MODE" == "push" ]]; then
    show_subtitle "📤 Pushing Local Changes"
    
    created_count=0
    updated_count=0
    error_count=0
    
    # Process each epic
    for epic_dir in .claude/epics/*/; do
        [[ -d "$epic_dir" ]] || continue
        
        epic_name=$(basename "$epic_dir")
        
        # Skip if filtering by specific epic
        if [[ -n "$EPIC_FILTER" && "$epic_name" != "$EPIC_FILTER" ]]; then
            continue
        fi
        
        show_info "Processing epic: $epic_name"
        
        # Process all task files in epic
        for task_file in "$epic_dir"[0-9]*.md; do
            [[ -f "$task_file" ]] || continue
            
            issue_id=$(basename "$task_file" .md)
            task_title=$(grep "^name:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "Untitled")
            status=$(grep "^status:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "pending")
            github_url=$(grep "^github_url:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
            
            if [[ -z "$github_url" ]]; then
                # Create new GitHub issue
                if [[ "$DRY_RUN" == "false" ]]; then
                    show_progress "Creating GitHub issue for #$issue_id: $task_title"
                    
                    if gh issue create \
                        --title "$task_title" \
                        --body-file "$task_file" \
                        --label "task,ccpm,$epic_name" >/dev/null 2>&1; then
                        
                        ((created_count++))
                        show_success "Issue Created" "#$issue_id"
                        
                        # Update local file with GitHub URL
                        new_url=$(gh issue list --search "in:title $task_title" --json url --jq '.[0].url' 2>/dev/null)
                        if [[ -n "$new_url" ]]; then
                            if grep -q "^github_url:" "$task_file"; then
                                sed -i.bak "s|^github_url:.*|github_url: $new_url|" "$task_file"
                            else
                                sed -i.bak "1 a\\
github_url: $new_url" "$task_file"
                            fi
                            rm -f "$task_file.bak"
                        fi
                    else
                        ((error_count++))
                        show_error "Failed to create issue for #$issue_id"
                    fi
                else
                    show_info "Would create: #$issue_id: $task_title"
                fi
            else
                # Update existing GitHub issue
                github_issue_num=$(echo "$github_url" | grep -o '[0-9]\+$')
                
                if [[ -n "$github_issue_num" ]]; then
                    if [[ "$DRY_RUN" == "false" ]]; then
                        show_progress "Updating GitHub issue #$github_issue_num"
                        
                        if gh issue edit "$github_issue_num" \
                            --title "$task_title" \
                            --body-file "$task_file" >/dev/null 2>&1; then
                            
                            # Handle status changes
                            case "$status" in
                                "completed"|"closed")
                                    gh issue close "$github_issue_num" >/dev/null 2>&1
                                    ;;
                                "in-progress"|"pending"|"ready")
                                    gh issue reopen "$github_issue_num" >/dev/null 2>&1
                                    ;;
                            esac
                            
                            ((updated_count++))
                            show_success "Issue Updated" "#$github_issue_num"
                        else
                            ((error_count++))
                            show_error "Failed to update issue #$github_issue_num"
                        fi
                    else
                        show_info "Would update: #$github_issue_num"
                    fi
                fi
            fi
        done
    done
    
    echo ""
    show_info "Push Summary:"
    show_info "Created: $created_count issues"
    show_info "Updated: $updated_count issues"
    if [[ $error_count -gt 0 ]]; then
        show_warning "Errors: $error_count operations"
    fi
    echo ""
fi

# Pull changes from GitHub
if [[ "$SYNC_MODE" == "full" || "$SYNC_MODE" == "pull" ]] && [[ -f "$SYNC_DIR/github-tasks.json" ]]; then
    show_subtitle "📥 Pulling GitHub Changes"
    
    local_updated_count=0
    
    if command -v jq >/dev/null 2>&1; then
        # Process each GitHub issue
        while read -r issue_json; do
            issue_number=$(echo "$issue_json" | jq -r '.number')
            issue_title=$(echo "$issue_json" | jq -r '.title')
            issue_state=$(echo "$issue_json" | jq -r '.state')
            
            # Find corresponding local file
            local_file=$(find .claude/epics -name "$issue_number.md" 2>/dev/null | head -1)
            
            if [[ -f "$local_file" ]]; then
                show_progress "Checking issue #$issue_number"
                
                local_status=$(grep "^status:" "$local_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "unknown")
                
                # Update local status based on GitHub state
                case "$issue_state" in
                    "closed")
                        if [[ "$local_status" != "completed" && "$local_status" != "closed" ]]; then
                            if [[ "$DRY_RUN" == "false" ]]; then
                                show_info "Updating local status to completed"
                                update_task_status "$local_file" "completed"
                                ((local_updated_count++))
                            else
                                show_info "Would update status to completed"
                            fi
                        fi
                        ;;
                    "open")
                        if [[ "$local_status" == "completed" || "$local_status" == "closed" ]]; then
                            if [[ "$DRY_RUN" == "false" ]]; then
                                show_info "Reopening local task"
                                update_task_status "$local_file" "in-progress"
                                ((local_updated_count++))
                            else
                                show_info "Would reopen local task"
                            fi
                        fi
                        ;;
                esac
            fi
        done < <(jq -c '.[]' "$SYNC_DIR/github-tasks.json")
    fi
    
    echo ""
    show_info "Pull Summary:"
    show_info "Updated: $local_updated_count local files"
    echo ""
fi

# Update sync timestamps
if [[ "$DRY_RUN" == "false" ]]; then
    current_timestamp=$(format_timestamp)
    
    for epic_dir in .claude/epics/*/; do
        [[ -d "$epic_dir" ]] || continue
        
        for task_file in "$epic_dir"[0-9]*.md; do
            [[ -f "$task_file" ]] || continue
            
            if grep -q "^last_sync:" "$task_file"; then
                sed -i.bak "s/^last_sync:.*/last_sync: $current_timestamp/" "$task_file"
            else
                sed -i.bak "1 a\\
last_sync: $current_timestamp" "$task_file"
            fi
            rm -f "$task_file.bak"
        done
    done
fi

# Summary
show_subtitle "🎯 Sync Complete"

if [[ "$DRY_RUN" == "true" ]]; then
    show_warning "Preview Mode" "No actual changes were made"
    show_tip "Run /pm:sync to apply changes"
else
    show_success "Sync Operation" "Completed successfully"
fi

show_info "Completed: $(format_timestamp)"
echo ""

if [[ $error_count -gt 0 ]]; then
    show_warning "Sync Errors" "Review and fix $error_count sync errors"
    echo ""
fi

show_subtitle "📋 Next Steps"
show_info "Available actions:"
echo "  /pm:status                       # Check project status"
echo "  /pm:epic-list                    # View all epics"
echo "  /pm:next                         # Find next available tasks"

echo ""
show_completion "Project sync completed!"
show_info "Created: $created_count | Updated: $updated_count | Local Updates: $local_updated_count"