#!/bin/bash

# CCPM Script Template v2.0
# Standard template for all CCPM scripts with consistent structure and best practices

set -euo pipefail

# =============================================================================
# SCRIPT METADATA
# =============================================================================

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_VERSION="2.0"
SCRIPT_DESCRIPTION="CCPM script template - customize this description"
SCRIPT_USAGE="Usage: $SCRIPT_NAME [options] [arguments]"

# =============================================================================
# STANDARD LIBRARY LOADING
# =============================================================================

# Load core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Load libraries with error checking
if [[ -f "$LIB_DIR/core.sh" ]]; then
    source "$LIB_DIR/core.sh"
else
    echo "❌ ERROR: Cannot find CCPM core library at $LIB_DIR/core.sh" >&2
    echo "Make sure you're running this script from within a CCPM project." >&2
    exit 1
fi

if [[ -f "$LIB_DIR/ui.sh" ]]; then
    source "$LIB_DIR/ui.sh"
else
    echo "⚠️  WARNING: UI library not found at $LIB_DIR/ui.sh" >&2
    echo "Some display functions may not work correctly." >&2
fi

# =============================================================================
# SCRIPT-SPECIFIC CONFIGURATION
# =============================================================================

# Configuration variables - customize as needed
VERBOSE=false
DRY_RUN=false
OUTPUT_DIR=".claude/tmp"
CONFIG_FILE=""

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

show_usage() {
    show_command_help "$SCRIPT_NAME" "$SCRIPT_DESCRIPTION" \
        "$SCRIPT_NAME [options] [arguments]         # Basic usage
$SCRIPT_NAME --verbose                        # Enable verbose output
$SCRIPT_NAME --dry-run                        # Preview mode
$SCRIPT_NAME --help                           # Show this help"
    
    echo ""
    echo "Options:"
    echo "  -h, --help                      Show this help message"
    echo "  -v, --verbose                   Enable verbose output"
    echo "  --dry-run                       Preview mode - show what would be done"
    echo "  --version                       Show script version"
    echo "  --config <file>                 Use custom configuration file"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME --verbose arg1 arg2           # Run with verbose output"
    echo "  $SCRIPT_NAME --dry-run                     # Preview operations"
    echo "  $SCRIPT_NAME --config custom.json arg1     # Use custom config"
}

show_version() {
    echo "$SCRIPT_NAME version $SCRIPT_VERSION"
    echo "Part of CCPM (Claude Code Project Manager) v2.0"
}

# Validate script prerequisites
validate_prerequisites() {
    show_subtitle "🔍 Prerequisites Check"
    
    # Check if running in CCPM project
    if [[ ! -d ".claude" ]]; then
        show_error "Not in CCPM Project" "This script must be run from a CCPM project root"
        return 1
    fi
    
    # Check for required tools - customize as needed
    local required_tools=()  # Example: ("jq" "curl" "git")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            show_error "Missing Tool" "Required tool not found: $tool"
            return 1
        else
            show_info "✓ $tool available"
        fi
    done
    
    show_success "Prerequisites" "All checks passed"
    return 0
}

# Initialize script environment
init_script() {
    show_title "🚀 $SCRIPT_NAME" 40
    show_info "Version: $SCRIPT_VERSION"
    
    if [[ "$VERBOSE" == true ]]; then
        show_info "Verbose mode: Enabled"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        show_warning "Dry Run" "Preview mode - no changes will be made"
    fi
    
    echo ""
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    
    # Setup output directory
    ensure_directory "$OUTPUT_DIR"
    
    # Load custom configuration if provided
    if [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]]; then
        show_info "Loading configuration: $CONFIG_FILE"
        # Add configuration loading logic here
    fi
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    local positional_args=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --config)
                if [[ -n "${2:-}" ]]; then
                    CONFIG_FILE="$2"
                    shift 2
                else
                    show_error "Missing Argument" "--config requires a file path"
                    exit 1
                fi
                ;;
            -*)
                show_error "Unknown Option" "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                positional_args+=("$1")
                shift
                ;;
        esac
    done
    
    # Set positional arguments for use in main logic
    set -- "${positional_args[@]}"
    SCRIPT_ARGS=("$@")
}

# =============================================================================
# MAIN SCRIPT LOGIC - CUSTOMIZE THIS SECTION
# =============================================================================

# Main script function - replace with your logic
execute_main_logic() {
    show_subtitle "⚡ Main Logic Execution"
    
    # Dry run preview
    if [[ "$DRY_RUN" == true ]]; then
        show_info "Would execute main logic with arguments:"
        for arg in "${SCRIPT_ARGS[@]}"; do
            echo "  - $arg"
        done
        show_tip "Remove --dry-run to execute for real"
        return 0
    fi
    
    # Example main logic - customize this section
    show_info "Executing main script logic..."
    
    if [[ ${#SCRIPT_ARGS[@]} -eq 0 ]]; then
        show_warning "No Arguments" "No arguments provided"
        show_tip "Provide arguments or use --help for usage information"
        return 0
    fi
    
    # Process each argument
    for arg in "${SCRIPT_ARGS[@]}"; do
        show_info "Processing: $arg"
        
        # Add your processing logic here
        # Example:
        # process_argument "$arg"
        
        if [[ "$VERBOSE" == true ]]; then
            show_info "Verbose: Processing details for $arg"
        fi
    done
    
    show_success "Execution Complete" "Main logic completed successfully"
}

# Example function for argument processing
process_argument() {
    local arg="$1"
    
    # Add your argument-specific logic here
    show_info "Processing argument: $arg"
    
    # Example validation
    if [[ -f "$arg" ]]; then
        show_info "✓ File exists: $arg"
    elif [[ -d "$arg" ]]; then
        show_info "✓ Directory exists: $arg"
    else
        show_warning "Invalid Path" "Path does not exist: $arg"
    fi
}

# =============================================================================
# CLEANUP AND ERROR HANDLING
# =============================================================================

# Cleanup function - called on script exit
cleanup() {
    if [[ "$VERBOSE" == true ]]; then
        show_info "🧹 Cleaning up..."
    fi
    
    # Add cleanup logic here
    # Example:
    # - Remove temporary files
    # - Close connections
    # - Save state
    
    # Remove temporary files in output directory if needed
    # find "$OUTPUT_DIR" -name "temp_*" -type f -delete 2>/dev/null || true
}

# Error handler
handle_error() {
    local exit_code=$?
    show_error "Script Error" "Script failed with exit code $exit_code"
    cleanup
    exit $exit_code
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Set up error handling and cleanup
    trap cleanup EXIT
    trap handle_error ERR
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize script environment
    init_script
    
    # Execute main logic
    execute_main_logic
    
    # Show completion summary
    show_subtitle "✅ Script Complete"
    show_success "$SCRIPT_NAME" "Execution completed successfully"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# =============================================================================
# CUSTOMIZATION NOTES
# =============================================================================

# To use this template:
# 1. Copy this file to your new script location
# 2. Update SCRIPT_DESCRIPTION and SCRIPT_USAGE
# 3. Modify the configuration variables section
# 4. Add required tools to validate_prerequisites()
# 5. Implement your main logic in execute_main_logic()
# 6. Add any helper functions as needed
# 7. Update the usage help text
# 8. Test with --dry-run and --verbose flags

# Template features included:
# ✓ Consistent library loading
# ✓ Argument parsing with help/version
# ✓ Error handling and cleanup
# ✓ Verbose and dry-run modes
# ✓ Configuration file support
# ✓ UI library integration
# ✓ Prerequisites validation
# ✓ Proper exit codes and traps