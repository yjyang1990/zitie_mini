#!/bin/bash

# Epic Show Script - Comprehensive Epic Information Display
# Display detailed epic information including task breakdown and progress tracking

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
    show_command_help "/pm:epic-show" "Display comprehensive epic information" \
        "/pm:epic-show <epic_name> [OPTIONS]       # Show epic details
/pm:epic-show user-auth                       # Full epic details
/pm:epic-show user-auth --format=brief       # Brief summary only
/pm:epic-show user-auth --tasks-only         # Show tasks list only
/pm:epic-show user-auth --format=json        # JSON output"
    
    echo ""
    echo "Options:"
    echo "  --format=<type>     Display format: full, brief, json"
    echo "  --tasks-only        Show only task information"
    echo "  --help              Show this help message"
}

# Parse arguments
EPIC_NAME=""
DISPLAY_FORMAT="full"
TASKS_ONLY=false

for arg in "$@"; do
  case "$arg" in
    "--format="*)
      DISPLAY_FORMAT="${arg#*=}"
      ;;
    "--tasks-only")
      TASKS_ONLY=true
      ;;
    "--help")
      show_usage
      ;;
    -*|--*)
      show_error "Unknown Option" "Unknown option: $arg"
      show_usage
      ;;
    *)
      if [[ -z "$EPIC_NAME" ]]; then
        EPIC_NAME="$arg"
      fi
      ;;
  esac
done

if [[ -z "$EPIC_NAME" ]]; then
    show_error "Missing Epic Name" "Epic name is required"
    show_usage
fi

# Validate project structure
if ! validate_ccpm_structure 2>/dev/null; then
    show_error "Project Not Initialized" "CCPM project not initialized"
    show_tip "Run /pm:init to initialize the project"
    exit 1
fi

# Epic validation and setup
EPIC_DIR=".claude/epics/$EPIC_NAME"
EPIC_FILE="$EPIC_DIR/epic.md"

if [[ ! -f "$EPIC_FILE" ]]; then
    show_error "Epic Not Found" "Epic '$EPIC_NAME' does not exist"
    echo ""
    show_info "Available epics:"
    find .claude/epics -name "epic.md" 2>/dev/null | while read -r epic_file; do
        epic_dir=$(dirname "$epic_file")
        available_epic=$(basename "$epic_dir")
        [[ "$available_epic" != ".archived" ]] && echo "   📐 $available_epic"
    done
    echo ""
    show_tip "Create epic from PRD: /pm:prd-parse $EPIC_NAME"
    exit 1
fi

# Extract epic metadata
epic_title=$(grep "^name:" "$EPIC_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "$EPIC_NAME")
epic_status=$(grep "^status:" "$EPIC_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "unknown")
epic_created=$(grep "^created:" "$EPIC_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "unknown")
epic_priority=$(grep "^priority:" "$EPIC_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "normal")
epic_assignee=$(grep "^assignee:" "$EPIC_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "unassigned")
github_url=$(grep "^github_url:" "$EPIC_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')

# Find and analyze tasks
task_files=($(find "$EPIC_DIR" -name "[0-9]*.md" 2>/dev/null | sort))
total_tasks=${#task_files[@]}

# Count tasks by status
pending_count=0
in_progress_count=0
completed_count=0
blocked_count=0

for task_file in "${task_files[@]}"; do
    task_status=$(grep "^status:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "pending")
    case "$task_status" in
      "pending"|"ready") ((pending_count++)) ;;
      "in-progress") ((in_progress_count++)) ;;
      "completed"|"closed") ((completed_count++)) ;;
      "blocked") ((blocked_count++)) ;;
    esac
done

# Calculate progress
progress_percent=0
if [[ $total_tasks -gt 0 ]]; then
    progress_percent=$(( (completed_count * 100) / total_tasks ))
fi

# JSON format output
if [[ "$DISPLAY_FORMAT" == "json" ]]; then
    task_list=""
    
    for task_file in "${task_files[@]}"; do
        task_id=$(basename "$task_file" .md)
        task_name=$(grep "^name:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "Untitled")
        task_status=$(grep "^status:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "pending")
        task_assignee=$(grep "^assignee:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "unassigned")
        task_github_url=$(grep "^github_url:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
        
        if [[ -n "$task_list" ]]; then
            task_list="${task_list},"
        fi
        task_list="${task_list}{\"id\":\"$task_id\",\"name\":\"$task_name\",\"status\":\"$task_status\",\"assignee\":\"$task_assignee\",\"github_url\":\"$task_github_url\"}"
    done

    cat << EOF
{
  "epic": {
    "name": "$epic_title",
    "directory": "$EPIC_NAME",
    "status": "$epic_status",
    "priority": "$epic_priority",
    "assignee": "$epic_assignee",
    "created": "$epic_created",
    "github_url": "$github_url",
    "progress": {
      "total_tasks": $total_tasks,
      "pending": $pending_count,
      "in_progress": $in_progress_count,
      "completed": $completed_count,
      "blocked": $blocked_count,
      "percentage": $progress_percent
    },
    "tasks": [$task_list]
  }
}
EOF
    exit 0
fi

# Display epic header
show_title "📐 Epic: $epic_title" 50
show_info "Directory: $EPIC_NAME"
echo ""

# Basic information (skip if tasks-only)
if [[ "$TASKS_ONLY" == "false" ]]; then
    show_subtitle "📋 Epic Information"
    
    show_table_header "Property" "Value"
    show_table_row "Status" "$epic_status"
    show_table_row "Priority" "$epic_priority"
    show_table_row "Assignee" "$epic_assignee"
    show_table_row "Created" "$epic_created"
    
    # GitHub integration status
    if [[ -n "$github_url" ]]; then
        issue_number=$(echo "$github_url" | grep -o '[0-9]\+$' || echo "unknown")
        show_table_row "GitHub" "#$issue_number"
        
        # Check GitHub status if CLI available
        if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
            gh_status=$(gh issue view "$issue_number" --json state 2>/dev/null | jq -r '.state' 2>/dev/null || echo "unknown")
            show_table_row "GitHub Status" "$gh_status"
        fi
    else
        show_table_row "GitHub" "Not synced"
    fi
    
    echo ""
fi

# Task analysis and display
show_subtitle "📝 Task Analysis"

if [[ $total_tasks -eq 0 ]]; then
    show_warning "No Tasks Found" "Epic has not been decomposed yet"
    show_tip "Decompose epic: /pm:epic-decompose $EPIC_NAME"
else
    show_info "Total tasks: $total_tasks"
    echo ""
    
    # Status breakdown with progress bar
    show_info "Status Breakdown:"
    show_progress_bar "$completed_count" "$total_tasks" 30 "Completed ($completed_count)"
    show_progress_bar "$in_progress_count" "$total_tasks" 30 "In Progress ($in_progress_count)"
    show_progress_bar "$pending_count" "$total_tasks" 30 "Pending ($pending_count)"
    if [[ $blocked_count -gt 0 ]]; then
        show_progress_bar "$blocked_count" "$total_tasks" 30 "Blocked ($blocked_count)"
    fi
    
    echo ""
    show_info "Overall Progress: ${progress_percent}%"
    echo ""
    
    # Detailed task list (skip for brief format)
    if [[ "$DISPLAY_FORMAT" != "brief" ]]; then
        show_subtitle "📋 Task Details"
        
        for task_file in "${task_files[@]}"; do
            task_id=$(basename "$task_file" .md)
            task_name=$(grep "^name:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "Untitled")
            task_status=$(grep "^status:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "pending")
            task_assignee=$(grep "^assignee:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "unassigned")
            
            # Status icon
            case "$task_status" in
                "pending"|"ready") status_icon="⏳" ;;
                "in-progress") status_icon="🔄" ;;
                "completed"|"closed") status_icon="✅" ;;
                "blocked") status_icon="🚧" ;;
                *) status_icon="❓" ;;
            esac
            
            echo "$status_icon $task_id: $task_name"
            echo "   Status: $task_status | Assignee: $task_assignee"
            
            # Dependencies
            depends_on=$(grep "^depends_on:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | sed 's/\[//g' | sed 's/\]//g' || echo "")
            if [[ -n "$depends_on" && "$depends_on" != "[]" ]]; then
                echo "   Dependencies: $depends_on"
            fi
            
            # GitHub integration
            task_github_url=$(grep "^github_url:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
            if [[ -n "$task_github_url" ]]; then
                task_issue_number=$(echo "$task_github_url" | grep -o '[0-9]\+$' || echo "unknown")
                echo "   GitHub: #$task_issue_number"
            fi
            
            echo ""
        done
    fi
fi

# Epic content preview (skip for brief format and tasks-only)
if [[ "$TASKS_ONLY" == "false" && "$DISPLAY_FORMAT" != "brief" ]]; then
    show_subtitle "📄 Epic Description"
    
    # Extract overview section
    if grep -q "^## Overview" "$EPIC_FILE"; then
        echo "Overview:"
        sed -n '/^## Overview/,/^##/{//!p}' "$EPIC_FILE" | head -5 | sed 's/^/   /'
        echo ""
    fi
    
    # Extract goals if available
    if grep -q "^## Goals" "$EPIC_FILE"; then
        echo "Goals:"
        sed -n '/^## Goals/,/^##/{//!p}' "$EPIC_FILE" | head -3 | sed 's/^/   /'
        echo ""
    fi
fi

# Relationships section (skip for brief format and tasks-only)
if [[ "$TASKS_ONLY" == "false" && "$DISPLAY_FORMAT" != "brief" ]]; then
    show_subtitle "🔗 Relationships"
    
    # Check for related PRD
    prd_file=".claude/prds/$EPIC_NAME.md"
    if [[ -f "$prd_file" ]]; then
        show_system_status "PRD" "ok" "$prd_file"
    else
        show_system_status "PRD" "warning" "Not found"
    fi
    
    # Check for worktree
    worktree_dir="../ccpm-$EPIC_NAME"
    if [[ -d "$worktree_dir" ]]; then
        show_system_status "Worktree" "ok" "$worktree_dir"
    else
        show_system_status "Worktree" "warning" "Not created"
    fi
    
    # Check git branch
    epic_branch="epic/$EPIC_NAME"
    if git rev-parse --verify "$epic_branch" >/dev/null 2>&1; then
        show_system_status "Branch" "ok" "$epic_branch"
    else
        show_system_status "Branch" "warning" "Not created"
    fi
    
    echo ""
fi

# Action recommendations (skip for tasks-only)
if [[ "$TASKS_ONLY" == "false" ]]; then
    show_subtitle "🎯 Recommended Actions"
    
    if [[ $total_tasks -eq 0 ]]; then
        show_info "Next steps:"
        echo "  /pm:epic-decompose $EPIC_NAME   # Break down into tasks"
    elif [[ -z "$github_url" ]]; then
        show_info "Next steps:"
        echo "  /pm:epic-sync $EPIC_NAME        # Sync to GitHub"
    elif [[ $in_progress_count -eq 0 && $pending_count -gt 0 ]]; then
        show_info "Ready to start work:"
        echo "  /pm:epic-start $EPIC_NAME       # Start epic work"
        echo "  /pm:next                        # Find next task"
    elif [[ $blocked_count -gt 0 ]]; then
        show_warning "Attention needed:"
        echo "  /pm:blocked                     # Review blockers"
    else
        show_info "In progress:"
        echo "  /pm:standup                     # Check progress"
    fi
    
    echo ""
    show_info "Additional commands:"
    echo "  /pm:epic-edit $EPIC_NAME        # Edit epic"
    echo "  /pm:sync $EPIC_NAME             # Sync changes"
fi

echo ""
show_completion "Epic details displayed successfully!"