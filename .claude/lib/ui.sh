#!/bin/bash

# CCPM UI Library - Merged UX and Formatting Functions
# Provides user interface, formatting, progress display, and user interaction functions

set -euo pipefail

# Color codes for better output
[[ -z "${RED:-}" ]] && RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && BLUE='\033[0;34m'
[[ -z "${PURPLE:-}" ]] && PURPLE='\033[0;35m'
[[ -z "${CYAN:-}" ]] && CYAN='\033[0;36m'
[[ -z "${NC:-}" ]] && NC='\033[0m' # No Color

# =============================================================================
# BASIC MESSAGE FUNCTIONS
# =============================================================================

# Show error message with optional solution
show_error() {
    local error_type="$1"
    local message="$2"
    local solution="${3:-}"
    
    echo -e "${RED}❌ $error_type${NC}"
    echo -e "${RED}   $message${NC}"
    
    if [[ -n "$solution" ]]; then
        echo -e "${YELLOW}💡 Solution:${NC}"
        echo -e "${YELLOW}   $solution${NC}"
    fi
    echo ""
}

# Show success message with optional details
show_success() {
    local message="$1"
    local details="${2:-}"
    
    echo -e "${GREEN}✅ $message${NC}"
    if [[ -n "$details" ]]; then
        echo -e "${GREEN}   $details${NC}"
    fi
    echo ""
}

# Show warning message with optional suggestion
show_warning() {
    local message="$1"
    local suggestion="${2:-}"
    
    echo -e "${YELLOW}⚠️ $message${NC}"
    if [[ -n "$suggestion" ]]; then
        echo -e "${YELLOW}   Suggestion: $suggestion${NC}"
    fi
    echo ""
}

# Show info message
show_info() {
    local message="$1"
    echo -e "${BLUE}ℹ️ $message${NC}"
}

# Show progress message
show_progress() {
    local message="$1"
    echo -e "${CYAN}🔄 $message${NC}"
}

# Show completion message
show_completion() {
    local message="$1"
    echo -e "\n${GREEN}✅ $message${NC}"
}

# Show tips and suggestions
show_tip() {
    local tip="$1"
    echo -e "${PURPLE}💡 Tip: $tip${NC}"
}

# =============================================================================
# FORMATTING AND DISPLAY
# =============================================================================

# Show title with separator
show_title() {
    local title="$1"
    local width="${2:-50}"
    
    show_separator "$width" "="
    echo -e "${BLUE}${title}${NC}"
    show_separator "$width" "="
}

# Show subtitle with separator
show_subtitle() {
    local subtitle="$1"
    local width="${2:-30}"
    
    echo ""
    echo -e "${CYAN}${subtitle}${NC}"
    show_separator "$width" "-"
}

# Show separator line
show_separator() {
    local width="${1:-50}"
    local char="${2:-=}"
    printf '%0.s'"$char" $(seq 1 "$width")
    echo ""
}

# Show status header
show_status_header() {
    echo "Getting status..."
    echo ""
    echo ""
}

# =============================================================================
# PROGRESS AND STATUS
# =============================================================================

# Show progress bar
show_progress_bar() {
    local completed="${1:-0}"
    local total="${2:-0}"
    local width="${3:-20}"
    local label="${4:-Progress}"
    
    if [[ $total -gt 0 ]]; then
        local percent=$((completed * 100 / total))
        local filled=$((percent * width / 100))
        local empty=$((width - filled))
        
        echo -n -e "${label}: [${GREEN}"
        [[ $filled -gt 0 ]] && printf '%0.s█' $(seq 1 $filled)
        echo -n -e "${NC}${CYAN}"
        [[ $empty -gt 0 ]] && printf '%0.s░' $(seq 1 $empty)
        echo -e "${NC}] ${percent}% (${completed}/${total})"
    else
        echo -e "${label}: ${YELLOW}No items found${NC}"
    fi
}

# Show status icon based on status
show_status_icon() {
    local status="$1"
    case "$status" in
        "open"|"pending"|"todo")
            echo -n "📋"
            ;;
        "in_progress"|"working"|"active")
            echo -n "🔄"
            ;;
        "completed"|"done"|"closed")
            echo -n "✅"
            ;;
        "blocked"|"error")
            echo -n "❌"
            ;;
        "review"|"testing")
            echo -n "👀"
            ;;
        *)
            echo -n "📄"
            ;;
    esac
}

# Format status text with colors
format_status_text() {
    local status="$1"
    case "$status" in
        "open"|"pending"|"todo")
            echo -e "${YELLOW}$status${NC}"
            ;;
        "in_progress"|"working"|"active")
            echo -e "${BLUE}$status${NC}"
            ;;
        "completed"|"done"|"closed")
            echo -e "${GREEN}$status${NC}"
            ;;
        "blocked"|"error")
            echo -e "${RED}$status${NC}"
            ;;
        "review"|"testing")
            echo -e "${PURPLE}$status${NC}"
            ;;
        *)
            echo -e "${NC}$status${NC}"
            ;;
    esac
}

# Show system status with colors
show_system_status() {
    local component="$1"
    local status="$2"
    local details="${3:-}"
    
    case "$status" in
        "ok"|"success")
            echo -e "  ${component}: ${GREEN}✅ OK${NC}"
            ;;
        "warning")
            echo -e "  ${component}: ${YELLOW}⚠️ Warning${NC}"
            ;;
        "error"|"failed")
            echo -e "  ${component}: ${RED}❌ Failed${NC}"
            ;;
        *)
            echo -e "  ${component}: ${BLUE}ℹ️ $status${NC}"
            ;;
    esac
    
    if [[ -n "$details" ]]; then
        echo -e "    $details"
    fi
}

# =============================================================================
# TABLE FUNCTIONS
# =============================================================================

# Show table header
show_table_header() {
    local -a headers=("$@")
    local separator=""
    
    # Calculate separator length
    for header in "${headers[@]}"; do
        printf "%-20s" "$header"
        separator+="--------------------"
    done
    echo ""
    echo "$separator"
}

# Show table row
show_table_row() {
    local -a columns=("$@")
    for column in "${columns[@]}"; do
        printf "%-20s" "$column"
    done
    echo ""
}

# =============================================================================
# USER INTERACTION
# =============================================================================

# Interactive confirmation
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="$message (Y/n): "
    else
        prompt="$message (y/N): "
    fi
    
    echo -n -e "${YELLOW}$prompt${NC}"
    read -r response
    
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# =============================================================================
# HELP AND GUIDANCE
# =============================================================================

# Show command help with examples
show_command_help() {
    local command="$1"
    local description="$2"
    local examples="$3"
    
    echo -e "${BLUE}📖 $command${NC}"
    echo -e "${BLUE}   $description${NC}"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "$examples" | while read -r example; do
        echo -e "${CYAN}   $example${NC}"
    done
    echo ""
}

# Show next steps
show_next_steps() {
    local steps="$1"
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo "$steps" | while read -r step; do
        echo -e "${CYAN}   • $step${NC}"
    done
    echo ""
}

# Show help hint
show_help_hint() {
    local command="$1"
    echo ""
    echo -e "💡 ${YELLOW}Need help?${NC} Run: ${BLUE}$command --help${NC}"
}

# =============================================================================
# PROJECT-SPECIFIC DISPLAYS
# =============================================================================

# Show task list with progress
show_task_list() {
    local epic_dir="$1"
    local show_completed="${2:-false}"
    
    if [[ ! -d "$epic_dir" ]]; then
        show_error "Epic directory not found: $epic_dir"
        return 1
    fi
    
    local task_count=0
    local completed_count=0
    
    while IFS= read -r -d '' task_file; do
        if [[ -f "$task_file" ]]; then
            local task_name
            task_name=$(basename "$(dirname "$task_file")")
            
            # Check task status
            local status="open"
            if grep -q "Status: closed" "$task_file" 2>/dev/null; then
                status="closed"
                ((completed_count++))
            elif grep -q "Status: in_progress" "$task_file" 2>/dev/null; then
                status="in_progress"
            fi
            
            # Show task based on parameters
            if [[ "$show_completed" == "true" ]] || [[ "$status" != "closed" ]]; then
                printf "  %s %s\n" "$(show_status_icon "$status")" "$task_name"
            fi
            
            ((task_count++))
        fi
    done < <(find "$epic_dir" -name "task.md" -print0 2>/dev/null)
    
    echo ""
    show_progress_bar "$completed_count" "$task_count" 20 "Overall Progress"
}

# Show epic summary
show_epic_summary() {
    local epic_file="$1"
    
    if [[ ! -f "$epic_file" ]]; then
        show_error "Epic file not found: $epic_file"
        return 1
    fi
    
    # Extract basic information
    local title
    title=$(grep "^# " "$epic_file" | head -1 | sed 's/^# //' | xargs)
    
    local description
    description=$(sed -n '/^## Description/,/^## /p' "$epic_file" | grep -v "^##" | head -3 | xargs)
    
    echo -e "${BLUE}Title:${NC} $title"
    echo -e "${BLUE}Description:${NC} $description"
}

# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

# Export all functions for use in other scripts
export -f show_error
export -f show_success
export -f show_warning
export -f show_info
export -f show_progress
export -f show_completion
export -f show_tip
export -f show_title
export -f show_subtitle
export -f show_separator
export -f show_status_header
export -f show_progress_bar
export -f show_status_icon
export -f format_status_text
export -f show_system_status
export -f show_table_header
export -f show_table_row
export -f confirm_action
export -f show_command_help
export -f show_next_steps
export -f show_help_hint
export -f show_task_list
export -f show_epic_summary