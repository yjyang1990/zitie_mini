#!/bin/bash

# Enhanced project status script with caching and better error handling
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

if [[ -f "$LIB_DIR/formatting.sh" ]]; then
    source "$LIB_DIR/formatting.sh"
fi

if [[ -f "$LIB_DIR/caching.sh" ]]; then
    source "$LIB_DIR/caching.sh"
fi

# Compute fresh status data
compute_status_data() {
    local prd_count=0
    local epic_count=0
    local total_tasks=0
    local open_tasks=0
    local closed_tasks=0
    local in_progress_tasks=0
    local git_status=0
    local log_count=0
    
    # Count PRDs
    if [[ -d ".claude/prds" ]]; then
        prd_count=$(find .claude/prds -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # Count epics
    if [[ -d ".claude/epics" ]]; then
        epic_count=$(find .claude/epics -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # Count tasks in epics
    if [[ -d ".claude/epics" ]]; then
        while IFS= read -r -d '' epic_file; do
            if [[ -f "$epic_file" ]]; then
                # Count tasks by looking for task patterns
                local task_count
                task_count=$(grep -c "^- \[" "$epic_file" 2>/dev/null || echo "0")
                total_tasks=$((total_tasks + task_count))
                
                # Count completed tasks
                local completed_count
                completed_count=$(grep -c "^- \[x\]" "$epic_file" 2>/dev/null || echo "0")
                closed_tasks=$((closed_tasks + completed_count))
                
                # Count in-progress tasks
                local progress_count
                progress_count=$(grep -c "^- \[~\]" "$epic_file" 2>/dev/null || echo "0")
                in_progress_tasks=$((in_progress_tasks + progress_count))
            fi
        done < <(find .claude/epics -name "*.md" -print0 2>/dev/null)
    fi
    
    open_tasks=$((total_tasks - closed_tasks - in_progress_tasks))
    
    # Check Git status
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git_status=1
    fi
    
    # Count logs
    if [[ -d ".claude/tmp" ]]; then
        log_count=$(find .claude/tmp -name "*.log" 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # Return JSON-like data
    cat << EOF
{
    "prd_count": $prd_count,
    "epic_count": $epic_count,
    "total_tasks": $total_tasks,
    "open_tasks": $open_tasks,
    "closed_tasks": $closed_tasks,
    "in_progress_tasks": $in_progress_tasks,
    "git_status": $git_status,
    "log_count": $log_count
}
EOF
}

# Display project status
show_project_status() {
    show_title "📊 CCPM v2.0 Project Status" 50
    
    # Get status data
    local status_data
    status_data=$(compute_status_data)
    
    # Parse status data (simple parsing since we control the format)
    local prd_count epic_count total_tasks open_tasks closed_tasks in_progress_tasks git_status log_count
    prd_count=$(echo "$status_data" | grep '"prd_count"' | sed 's/.*: *\([0-9]*\).*/\1/')
    epic_count=$(echo "$status_data" | grep '"epic_count"' | sed 's/.*: *\([0-9]*\).*/\1/')
    total_tasks=$(echo "$status_data" | grep '"total_tasks"' | sed 's/.*: *\([0-9]*\).*/\1/')
    open_tasks=$(echo "$status_data" | grep '"open_tasks"' | sed 's/.*: *\([0-9]*\).*/\1/')
    closed_tasks=$(echo "$status_data" | grep '"closed_tasks"' | sed 's/.*: *\([0-9]*\).*/\1/')
    in_progress_tasks=$(echo "$status_data" | grep '"in_progress_tasks"' | sed 's/.*: *\([0-9]*\).*/\1/')
    git_status=$(echo "$status_data" | grep '"git_status"' | sed 's/.*: *\([0-9]*\).*/\1/')
    log_count=$(echo "$status_data" | grep '"log_count"' | sed 's/.*: *\([0-9]*\).*/\1/')
    
    echo ""
    show_subtitle "📊 Project Overview"
    
    # Project metrics
    show_table_header "Metric" "Count" "Status"
    show_table_row "PRDs" "$prd_count" "$(get_status_indicator $prd_count)"
    show_table_row "Epics" "$epic_count" "$(get_status_indicator $epic_count)"
    show_table_row "Total Tasks" "$total_tasks" "$(get_status_indicator $total_tasks)"
    
    echo ""
    show_subtitle "📋 Task Breakdown"
    
    if [[ $total_tasks -gt 0 ]]; then
        show_progress_bar "$closed_tasks" "$total_tasks" 20 "Completed"
        show_progress_bar "$in_progress_tasks" "$total_tasks" 20 "In Progress"
        show_progress_bar "$open_tasks" "$total_tasks" 20 "Open"
        
        local completion_percentage=$((closed_tasks * 100 / total_tasks))
        echo ""
        show_info "Overall Progress: ${completion_percentage}% complete"
    else
        show_warning "No tasks found" "Consider creating a PRD with /pm:prd-new"
    fi
    
    echo ""
    show_subtitle "🔧 System Status"
    
    # Git status
    if [[ $git_status -eq 1 ]]; then
        show_system_status "Git Repository" "ok"
        
        # Check for uncommitted changes
        if ! git diff --quiet 2>/dev/null; then
            show_system_status "Working Directory" "warning" "Uncommitted changes detected"
        else
            show_system_status "Working Directory" "ok"
        fi
        
        # Check for GitHub connectivity
        if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
            show_system_status "GitHub CLI" "ok"
        else
            show_system_status "GitHub CLI" "warning" "Not authenticated or not installed"
        fi
    else
        show_system_status "Git Repository" "error" "Not a git repository"
    fi
    
    # CCPM structure
    if [[ -d ".claude" ]]; then
        show_system_status "CCPM Structure" "ok"
    else
        show_system_status "CCPM Structure" "error" "Run /pm:init to initialize"
    fi
    
    echo ""
    show_subtitle "🚀 Quick Actions"
    
    if [[ $prd_count -eq 0 ]]; then
        show_info "Get started:"
        echo "  /pm:prd-new <feature>    # Create your first PRD"
        echo "  /pm:init                 # Initialize project structure"
    elif [[ $epic_count -eq 0 ]]; then
        show_info "Convert PRDs to epics:"
        echo "  /pm:prd-parse <prd-name> # Transform PRD into epic"
        echo "  /pm:prd-list             # See available PRDs"
    elif [[ $in_progress_tasks -eq 0 && $open_tasks -gt 0 ]]; then
        show_info "Start working on tasks:"
        echo "  /pm:next                 # View next available tasks"
        echo "  /pm:auto                 # Auto-start best task"
        echo "  /pm:epic-sync <epic>     # Sync epic to GitHub"
    elif [[ $in_progress_tasks -gt 0 ]]; then
        show_info "Continue active work:"
        echo "  /pm:standup              # Daily progress report"
        echo "  /pm:next                 # Check next priorities"
        echo "  /pm:blocked              # Review any blockers"
    else
        show_success "All tasks completed!" "Consider creating new work or cleaning up"
        echo "  /pm:clean                # Archive completed work"
        echo "  /pm:prd-new <feature>    # Start new feature"
    fi
    
    echo ""
    show_tip "Run /pm:help for detailed command reference"
}

# Helper function to get status indicator
get_status_indicator() {
    local count="$1"
    if [[ $count -eq 0 ]]; then
        echo "⚪"
    elif [[ $count -lt 3 ]]; then
        echo "🟡"
    else
        echo "🟢"
    fi
}

# Main execution
main() {
    # Validate project structure
    if ! validate_ccpm_structure 2>/dev/null; then
        show_error "Project Not Initialized" "CCPM project structure not found"
        show_tip "Run /pm:init to initialize the project"
        exit 1
    fi
    
    show_project_status
}

# Run main function
main "$@"