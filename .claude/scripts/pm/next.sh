#!/bin/bash

# Next Available Work Script - Intelligent Task Prioritization
# Identify and prioritize next available tasks with filtering options

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
    show_command_help "/pm:next" "Find next available tasks" \
        "/pm:next [FILTER] [OPTIONS]              # Find available work
/pm:next                                # Show all available work
/pm:next high                           # High priority tasks only
/pm:next quick                          # Quick/small tasks
/pm:next blocked                        # Currently blocked tasks
/pm:next ready --verbose                # Ready tasks with details"
    
    echo ""
    echo "Filters:"
    echo "  all          Show all available work (default)"
    echo "  high         Show high priority tasks only"
    echo "  quick        Show quick/small tasks"
    echo "  blocked      Show what's currently blocked"
    echo "  ready        Show tasks ready to start"
    echo ""
    echo "Options:"
    echo "  --verbose    Show detailed task information"
    echo "  --help       Show this help message"
}

# Default configuration
FILTER="all"
VERBOSE_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    all|high|quick|blocked|ready)
      FILTER="$1"
      shift
      ;;
    --verbose|-v)
      VERBOSE_MODE=true
      shift
      ;;
    --help|-h)
      show_usage
      ;;
    -*|--*)
      show_error "Unknown Option" "Unknown option: $1"
      show_usage
      ;;
    *)
      show_error "Unknown Filter" "Unknown filter: $1"
      show_usage
      ;;
  esac
done

# Validate project structure
if ! validate_ccpm_structure 2>/dev/null; then
    show_error "Project Not Initialized" "CCPM project not initialized"
    show_tip "Run /pm:init to initialize the project"
    exit 1
fi

# Display header
show_title "🚀 Next Available Work" 40
show_info "Filter: $FILTER"
if [[ "$VERBOSE_MODE" == "true" ]]; then
    show_info "Mode: Verbose output enabled"
fi
echo ""

# Check for available work
if [[ ! -d ".claude/epics" ]] || [[ $(find .claude/epics -name "*.md" 2>/dev/null | wc -l) -eq 0 ]]; then
    show_warning "No Work Available" "No tasks found"
    echo ""
    show_info "Start by creating a PRD:"
    echo "  /pm:prd-new <feature-name>   # Create new feature PRD"
    echo ""
    show_info "Or check project status:"
    echo "  /pm:status                   # Project overview"
    exit 0
fi

# Initialize counters
found=0
blocked_count=0
high_priority_count=0
quick_task_count=0

# Function to check if task is blocked
check_task_blocked() {
    local task_file="$1"
    local depends_on blocking_reason dep dep_file dep_status
    
    depends_on=$(grep "^depends_on:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | sed 's/\[//g' | sed 's/\]//g' || echo "")
    
    if [[ -n "$depends_on" && "$depends_on" != "depends_on:" ]]; then
        IFS=', ' read -ra dep_array <<< "$depends_on"
        for dep in "${dep_array[@]}"; do
            dep=$(echo "$dep" | xargs) # trim whitespace
            [[ -z "$dep" ]] && continue
            
            # Find dependency file
            dep_file=""
            for check_epic in .claude/epics/*/; do
                [[ -d "$check_epic" ]] || continue
                check_file="$check_epic/${dep}.md"
                if [[ -f "$check_file" ]]; then
                    dep_file="$check_file"
                    break
                fi
            done
            
            if [[ -z "$dep_file" ]]; then
                echo "Missing dependency: $dep"
                return 0 # is blocked
            fi
            
            dep_status=$(grep "^status:" "$dep_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "open")
            if [[ "$dep_status" != "completed" && "$dep_status" != "closed" ]]; then
                echo "Waiting for task $dep ($dep_status)"
                return 0 # is blocked
            fi
        done
    fi
    
    echo "" # not blocked
    return 1
}

# Find and analyze available tasks
show_subtitle "📋 Available Tasks"

for epic_dir in .claude/epics/*/; do
    [[ -d "$epic_dir" ]] || continue
    [[ "$epic_dir" == *"/.archived/"* ]] && continue
    
    epic_name=$(basename "$epic_dir")
    epic_file="$epic_dir/epic.md"
    
    # Skip archived or completed epics
    if [[ -f "$epic_file" ]]; then
        epic_status=$(grep "^status:" "$epic_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "planning")
        [[ "$epic_status" =~ ^(completed|done|closed|archived)$ ]] && continue
    fi

    for task_file in "$epic_dir"[0-9]*.md; do
        [[ -f "$task_file" ]] || continue

        # Extract task metadata
        task_id=$(basename "$task_file" .md)
        task_status=$(grep "^status:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "open")
        task_name=$(grep "^name:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "Unnamed Task")
        priority=$(grep "^priority:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "medium")
        estimated_hours=$(grep "^estimated_hours:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "")
        assignee=$(grep "^assignee:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "")
        
        # Skip non-open tasks
        [[ "$task_status" != "open" && -n "$task_status" ]] && continue
        
        # Check if task is blocked
        blocking_reason=$(check_task_blocked "$task_file")
        is_blocked=$?
        
        # Apply filters
        show_task=false
        task_category=""
        
        case "$FILTER" in
            "all")
                show_task=true
                ;;
            "high")
                if [[ "$priority" =~ ^(high|critical|urgent)$ ]]; then
                    show_task=true
                    task_category="HIGH PRIORITY"
                    ((high_priority_count++))
                fi
                ;;
            "quick")
                if [[ -n "$estimated_hours" ]] && [[ "$estimated_hours" =~ ^[0-9]+$ ]] && [[ "$estimated_hours" -le 4 ]]; then
                    show_task=true
                    task_category="QUICK TASK"
                    ((quick_task_count++))
                elif [[ -z "$estimated_hours" ]]; then
                    show_task=true
                    task_category="UNESTIMATED"
                fi
                ;;
            "blocked")
                if [[ $is_blocked -eq 0 ]]; then
                    show_task=true
                    task_category="BLOCKED"
                    ((blocked_count++))
                fi
                ;;
            "ready")
                if [[ $is_blocked -ne 0 ]]; then
                    show_task=true
                    task_category="READY"
                fi
                ;;
        esac
        
        if [[ "$show_task" == true ]]; then
            ((found++))
            
            # Display task information
            if [[ $is_blocked -eq 0 && "$FILTER" != "blocked" ]]; then
                echo "🚧 Blocked: #$task_id - $task_name"
                echo "   Epic: $epic_name"
                echo "   Reason: $blocking_reason"
            else
                if [[ $is_blocked -eq 0 ]]; then
                    echo "🚧 #$task_id - $task_name"
                else
                    echo "✅ Ready: #$task_id - $task_name"
                fi
                echo "   Epic: $epic_name"
                
                if [[ -n "$task_category" ]]; then
                    echo "   Category: $task_category"
                fi
                
                if [[ "$VERBOSE_MODE" == "true" ]]; then
                    [[ "$priority" != "medium" ]] && echo "   Priority: $priority"
                    [[ -n "$estimated_hours" ]] && echo "   Estimated: ${estimated_hours}h"
                    [[ -n "$assignee" ]] && echo "   Assignee: $assignee"
                    [[ $is_blocked -eq 0 ]] && echo "   Blocking: $blocking_reason"
                fi
                
                # Show action command
                echo "   Command: /pm:issue-start $task_id"
            fi
            echo ""
        fi
    done
done

# Summary and recommendations
echo ""
show_subtitle "📊 Summary"

case "$FILTER" in
    "all")
        show_info "Total available tasks: $found"
        ;;
    "high")
        show_info "High priority tasks: $high_priority_count"
        ;;
    "quick")
        show_info "Quick tasks (≤4h): $quick_task_count"
        ;;
    "blocked")
        show_info "Blocked tasks: $blocked_count"
        ;;
    "ready")
        show_info "Ready to start: $found"
        ;;
esac

if [[ $found -eq 0 ]]; then
    echo ""
    show_subtitle "💡 Suggestions"
    
    case "$FILTER" in
        "blocked")
            show_success "No Blocked Tasks" "Great! No blocked tasks found"
            show_info "Next steps:"
            echo "  /pm:next all                 # View all work"
            echo "  /pm:epic-list                # Check epic status"
            ;;
        "high")
            show_warning "No High Priority Tasks" "No high priority tasks available"
            show_info "Try:"
            echo "  /pm:next all                 # Check all tasks"
            echo "  /pm:epic-list                # Review priorities"
            ;;
        "quick")
            show_warning "No Quick Tasks" "No quick tasks available"
            show_info "Options:"
            echo "  /pm:next all                 # View all tasks"
            echo "  /pm:epic-decompose <epic>    # Break down large tasks"
            ;;
        *)
            show_warning "No Available Tasks" "No tasks ready to work on"
            show_info "Options:"
            echo "  /pm:next blocked             # Check blocked tasks"
            echo "  /pm:epic-list                # Review epic status"
            echo "  /pm:prd-new <feature>        # Create new feature"
            ;;
    esac
else
    echo ""
    show_subtitle "🚀 Next Actions"
    
    show_info "Ready to start work? Pick a task above and run:"
    echo "  /pm:issue-start <task-id>"
    echo ""
    show_info "Need different view?"
    echo "  /pm:next high                # High priority only"
    echo "  /pm:next quick               # Quick wins"
    echo "  /pm:next blocked             # See what's blocked"
    echo "  /pm:next ready               # Ready to start tasks"
    echo "  /pm:status                   # Project overview"
fi

echo ""
show_completion "Task analysis completed!"
show_info "Found $found tasks with filter: $FILTER"