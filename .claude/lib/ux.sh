#!/bin/bash

# CCPM User Experience Enhancement
# Provides user-friendly error messages and progress feedback

set -euo pipefail

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"
if [[ -f "$LIB_DIR/common-functions.sh" ]]; then
    source "$LIB_DIR/common-functions.sh"
fi

# Color codes for better output (only define if not already set)
[[ -z "${RED:-}" ]] && RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && BLUE='\033[0;34m'
[[ -z "${PURPLE:-}" ]] && PURPLE='\033[0;35m'
[[ -z "${CYAN:-}" ]] && CYAN='\033[0;36m'
[[ -z "${NC:-}" ]] && NC='\033[0m' # No Color

# Enhanced error messages with solutions
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

# Show success message
show_success() {
    local message="$1"
    local details="${2:-}"
    
    echo -e "${GREEN}✅ $message${NC}"
    if [[ -n "$details" ]]; then
        echo -e "${GREEN}   $details${NC}"
    fi
    echo ""
}

# Show warning message
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

# Show progress (simplified - no hanging)
show_progress() {
    local message="$1"
    echo -e "${CYAN}🔄 $message${NC}"
}

# show_progress_bar function moved to formatting.sh (more flexible implementation)

# Show completion
show_completion() {
    local message="$1"
    echo -e "\n${GREEN}✅ $message${NC}"
}

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

# Show help with examples
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

# Show tips and suggestions
show_tip() {
    local tip="$1"
    echo -e "${PURPLE}💡 Tip: $tip${NC}"
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

# Export functions
export -f show_error
export -f show_success
export -f show_warning
export -f show_info
export -f show_progress
# show_progress_bar exported from formatting.sh
export -f show_completion
export -f confirm_action
export -f show_command_help
export -f show_system_status
export -f show_tip
export -f show_next_steps
