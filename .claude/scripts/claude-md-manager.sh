#!/bin/bash

# CCPM CLAUDE.md Manager v2.0
# Comprehensive CLAUDE.md management with synchronization, validation, and backup

set -euo pipefail

# Load core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Load libraries with error checking
if [[ -f "$LIB_DIR/core.sh" ]]; then
    source "$LIB_DIR/core.sh"
fi

if [[ -f "$LIB_DIR/ui.sh" ]]; then
    source "$LIB_DIR/ui.sh"
fi

# Configuration
SOURCE_CLAUDE_MD=".claude/CLAUDE.md"
TARGET_CLAUDE_MD="CLAUDE.md"
SESSIONS_DIR=".claude/tmp/claude-md-sessions"

# Function to show usage
show_usage() {
    show_command_help "claude-md-manager" "Manage CLAUDE.md configuration files" \
        "claude-md-manager [ACTION] [OPTIONS]        # Manage CLAUDE.md
claude-md-manager sync                          # Sync configurations
claude-md-manager validate                      # Validate configuration
claude-md-manager backup                        # Create backup
claude-md-manager merge --source source.md     # Merge configurations"
    
    echo ""
    echo "Actions:"
    echo "  sync               Synchronize .claude/CLAUDE.md to CLAUDE.md"
    echo "  update             Alias for sync"
    echo "  validate           Validate configuration integrity"
    echo "  backup             Create configuration backup"
    echo "  merge              Merge configurations intelligently"
    echo "  compare            Compare source and target configurations"
    echo "  help               Show this help message"
    echo ""
    echo "Options:"
    echo "  --force            Overwrite existing files without confirmation"
    echo "  --backup           Create backup before modification"
    echo "  --merge            Perform intelligent merge of configurations"
    echo "  --dry-run          Preview changes without applying"
    echo "  --source <file>    Specify alternative source file"
    echo "  --target <file>    Specify alternative target file"
    echo ""
    echo "Examples:"
    echo "  claude-md-manager sync --backup           # Sync with backup"
    echo "  claude-md-manager validate                # Validate integrity"
    echo "  claude-md-manager merge --force           # Force merge configs"
    echo "  claude-md-manager sync --dry-run          # Preview sync operation"
}

# Initialize session management
init_session() {
    local session_id="session-$(date +%Y%m%d-%H%M%S)"
    local session_dir="$SESSIONS_DIR/$session_id"
    
    ensure_directory "$session_dir"
    echo "$session_dir"
}

# Analyze configuration file
analyze_config() {
    local file_path="$1"
    local file_label="${2:-Configuration}"
    
    if [[ ! -f "$file_path" ]]; then
        show_warning "$file_label Missing" "File not found: $file_path"
        return 1
    fi
    
    local size lines words sections
    size=$(wc -c < "$file_path" 2>/dev/null || echo 0)
    lines=$(wc -l < "$file_path" 2>/dev/null || echo 0)
    words=$(wc -w < "$file_path" 2>/dev/null || echo 0)
    sections=$(grep -c "^## " "$file_path" 2>/dev/null || echo 0)
    
    show_info "📊 $file_label Analysis:"
    echo "  Size: $(format_file_size "$size")"
    echo "  Lines: $lines"
    echo "  Words: $words"
    echo "  Sections: $sections"
    
    return 0
}

# Validate configuration integrity
validate_configuration() {
    local file_path="$1"
    local validation_name="${2:-Configuration}"
    
    show_subtitle "🔍 $validation_name Validation"
    
    if [[ ! -f "$file_path" ]]; then
        show_error "File Missing" "Cannot validate: $file_path"
        return 1
    fi
    
    local issues=0
    local warnings=0
    
    # Check for required sections
    local required_sections=(
        "# "
        "## Quick Start"
        "## Bash Commands"
        "## Project Structure"
        "## Development Workflow"
    )
    
    show_info "Checking required sections:"
    for section in "${required_sections[@]}"; do
        if grep -q "^$section" "$file_path" 2>/dev/null; then
            show_info "  ✓ Found: $section"
        else
            show_warning "  ⚠️  Missing: $section"
            ((warnings++))
        fi
    done
    
    # Check for critical patterns
    show_info "Checking critical patterns:"
    
    local critical_patterns=(
        "Claude Code"
        "CCPM"
        "tool permissions"
        "MCP"
    )
    
    for pattern in "${critical_patterns[@]}"; do
        if grep -qi "$pattern" "$file_path" 2>/dev/null; then
            show_info "  ✓ Found pattern: $pattern"
        else
            show_warning "  ⚠️  Missing pattern: $pattern"
            ((warnings++))
        fi
    done
    
    # Check file structure
    show_info "Checking file structure:"
    
    if head -10 "$file_path" | grep -q "^# " 2>/dev/null; then
        show_info "  ✓ Valid markdown structure"
    else
        show_error "  ❌ Invalid markdown structure"
        ((issues++))
    fi
    
    # Calculate quality score
    local total_checks=$((${#required_sections[@]} + ${#critical_patterns[@]} + 1))
    local score=$((total_checks - warnings - issues))
    local quality_percent=$((score * 100 / total_checks))
    
    show_info "Quality Assessment:"
    echo "  Score: $score/$total_checks ($quality_percent%)"
    
    if [[ $quality_percent -ge 90 ]]; then
        show_success "Quality Rating" "Excellent"
    elif [[ $quality_percent -ge 75 ]]; then
        show_success "Quality Rating" "Good"
    elif [[ $quality_percent -ge 60 ]]; then
        show_warning "Quality Rating" "Fair"
    else
        show_error "Quality Rating" "Poor"
    fi
    
    return $issues
}

# Create configuration backup
create_backup() {
    local source_file="$1"
    local session_dir="$2"
    
    if [[ ! -f "$source_file" ]]; then
        show_warning "Backup Skipped" "Source file not found: $source_file"
        return 1
    fi
    
    local backup_name="$(basename "$source_file").backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$session_dir/$backup_name"
    
    cp "$source_file" "$backup_path"
    
    show_success "Backup Created" "$backup_path"
    echo "$backup_path"
}

# Intelligent configuration merge
merge_configurations() {
    local source_file="$1"
    local target_file="$2"
    local session_dir="$3"
    
    show_subtitle "🔄 Configuration Merge"
    
    if [[ ! -f "$source_file" ]]; then
        show_error "Source Missing" "Source file not found: $source_file"
        return 1
    fi
    
    if [[ ! -f "$target_file" ]]; then
        show_info "Target not found, copying source"
        cp "$source_file" "$target_file"
        return 0
    fi
    
    # Create merge working directory
    local merge_dir="$session_dir/merge"
    ensure_directory "$merge_dir"
    
    # Copy files for merge analysis
    cp "$source_file" "$merge_dir/source.md"
    cp "$target_file" "$merge_dir/target.md"
    
    show_info "Analyzing merge requirements..."
    
    # Simple merge strategy: use source as base, preserve target customizations
    local merged_content
    merged_content=$(cat "$source_file")
    
    # Check for target-specific customizations
    if grep -q "# PROJECT-SPECIFIC" "$target_file" 2>/dev/null; then
        show_info "Found project-specific customizations"
        local custom_content
        custom_content=$(sed -n '/# PROJECT-SPECIFIC/,$p' "$target_file")
        
        # Append custom content
        merged_content="$merged_content

$custom_content"
    fi
    
    # Write merged content
    local merged_file="$merge_dir/merged.md"
    echo "$merged_content" > "$merged_file"
    
    show_success "Merge Complete" "Preview: $merged_file"
    analyze_config "$merged_file" "Merged Configuration"
    
    echo "$merged_file"
}

# Compare configurations
compare_configurations() {
    local source_file="$1"
    local target_file="$2"
    
    show_title "📊 Configuration Comparison" 40
    
    # Analyze both files
    if [[ -f "$source_file" ]]; then
        analyze_config "$source_file" "Source"
    else
        show_error "Source Missing" "$source_file not found"
    fi
    
    echo ""
    
    if [[ -f "$target_file" ]]; then
        analyze_config "$target_file" "Target"
    else
        show_warning "Target Missing" "$target_file not found"
    fi
    
    # Show differences if both exist
    if [[ -f "$source_file" && -f "$target_file" ]]; then
        echo ""
        show_subtitle "📋 Content Differences"
        
        if command -v diff >/dev/null 2>&1; then
            local diff_output
            if diff_output=$(diff -u "$target_file" "$source_file" 2>/dev/null); then
                show_success "Files Identical" "No differences found"
            else
                show_info "Differences found (unified diff format):"
                echo "$diff_output" | head -20
                if [[ $(echo "$diff_output" | wc -l) -gt 20 ]]; then
                    show_info "... (output truncated, showing first 20 lines)"
                fi
            fi
        else
            show_warning "diff not available" "Cannot show detailed differences"
        fi
    fi
}

# Generate session report
generate_report() {
    local session_dir="$1"
    local action="$2"
    local operation_details="$3"
    
    local report_file="$session_dir/session-report.md"
    local timestamp
    timestamp=$(format_timestamp)
    
    cat > "$report_file" << EOF
# CLAUDE.md Management Session Report

**Session ID**: $(basename "$session_dir")  
**Generated**: $timestamp  
**Action**: $action

## Operation Summary
$operation_details

## Session Artifacts
- Session Directory: $session_dir
- Report File: $report_file

## File Locations
- Source: $SOURCE_CLAUDE_MD
- Target: $TARGET_CLAUDE_MD

## Recommendations
1. Review the updated configuration carefully
2. Test Claude Code functionality with new settings
3. Consider committing changes to version control
4. Document any project-specific customizations

---
*Generated by CCPM CLAUDE.md Manager v2.0*
EOF
    
    echo "$report_file"
}

# Main function
main() {
    local action="sync"
    local force_mode=false
    local backup_mode=false
    local merge_mode=false
    local dry_run=false
    local source_file="$SOURCE_CLAUDE_MD"
    local target_file="$TARGET_CLAUDE_MD"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            sync|update|validate|backup|merge|compare)
                action="$1"
                shift
                ;;
            --force)
                force_mode=true
                shift
                ;;
            --backup)
                backup_mode=true
                shift
                ;;
            --merge)
                merge_mode=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --source)
                if [[ -n "${2:-}" ]]; then
                    source_file="$2"
                    shift 2
                else
                    show_error "Missing Source" "--source requires a file path"
                    exit 1
                fi
                ;;
            --target)
                if [[ -n "${2:-}" ]]; then
                    target_file="$2"
                    shift 2
                else
                    show_error "Missing Target" "--target requires a file path"
                    exit 1
                fi
                ;;
            --help|-h|help)
                show_usage
                exit 0
                ;;
            *)
                show_error "Unknown Option" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Initialize session
    local session_dir
    session_dir=$(init_session)
    
    show_title "📋 CCPM CLAUDE.md Manager" 45
    show_info "Action: $action"
    show_info "Source: $source_file"
    show_info "Target: $target_file"
    show_info "Session: $(basename "$session_dir")"
    
    if [[ "$force_mode" == true ]]; then
        show_info "Mode: Force enabled"
    fi
    if [[ "$backup_mode" == true ]]; then
        show_info "Mode: Backup enabled"
    fi
    if [[ "$merge_mode" == true ]]; then
        show_info "Mode: Merge enabled"
    fi
    if [[ "$dry_run" == true ]]; then
        show_warning "Mode: Dry run (no changes will be made)"
    fi
    
    echo ""
    
    # Execute action
    case "$action" in
        "sync"|"update")
            show_subtitle "🔄 Configuration Sync"
            
            # Validate source exists
            if [[ ! -f "$source_file" ]]; then
                show_error "Source Missing" "Source configuration not found: $source_file"
                exit 1
            fi
            
            analyze_config "$source_file" "Source"
            
            # Check if target exists and handle accordingly
            if [[ -f "$target_file" ]]; then
                echo ""
                analyze_config "$target_file" "Current Target"
                
                if [[ "$force_mode" == false && "$merge_mode" == false && "$dry_run" == false ]]; then
                    show_warning "Target Exists" "Target file exists: $target_file"
                    show_tip "Use --force to overwrite, --merge to merge, or --backup to create backup first"
                    exit 1
                fi
            fi
            
            # Create backup if requested or if target exists
            local backup_file=""
            if [[ "$backup_mode" == true || (-f "$target_file" && "$dry_run" == false) ]]; then
                backup_file=$(create_backup "$target_file" "$session_dir")
            fi
            
            # Handle merge mode
            local source_for_sync="$source_file"
            if [[ "$merge_mode" == true ]]; then
                source_for_sync=$(merge_configurations "$source_file" "$target_file" "$session_dir")
            fi
            
            # Perform sync
            if [[ "$dry_run" == true ]]; then
                show_info "Would copy: $source_for_sync → $target_file"
            else
                cp "$source_for_sync" "$target_file"
                show_success "Sync Complete" "Configuration synchronized"
                analyze_config "$target_file" "Updated Target"
            fi
            ;;
            
        "validate")
            show_title "🔍 Configuration Validation" 40
            
            local validation_passed=true
            
            if [[ -f "$source_file" ]]; then
                if ! validate_configuration "$source_file" "Source"; then
                    validation_passed=false
                fi
            else
                show_error "Source Missing" "Cannot validate source: $source_file"
                validation_passed=false
            fi
            
            echo ""
            
            if [[ -f "$target_file" ]]; then
                if ! validate_configuration "$target_file" "Target"; then
                    validation_passed=false
                fi
            else
                show_warning "Target Missing" "Target not found: $target_file"
            fi
            
            if [[ "$validation_passed" == true ]]; then
                show_success "Validation Complete" "All configurations passed validation"
            else
                show_error "Validation Failed" "Some configurations have issues"
                exit 1
            fi
            ;;
            
        "backup")
            show_subtitle "💾 Configuration Backup"
            
            local backup_created=false
            
            if [[ -f "$source_file" ]]; then
                create_backup "$source_file" "$session_dir"
                backup_created=true
            fi
            
            if [[ -f "$target_file" ]]; then
                create_backup "$target_file" "$session_dir"
                backup_created=true
            fi
            
            if [[ "$backup_created" == true ]]; then
                show_success "Backup Complete" "Configuration files backed up"
            else
                show_warning "No Backups" "No configuration files found to backup"
            fi
            ;;
            
        "merge")
            merge_configurations "$source_file" "$target_file" "$session_dir"
            ;;
            
        "compare")
            compare_configurations "$source_file" "$target_file"
            ;;
            
        *)
            show_error "Unknown Action" "Unknown action: $action"
            show_usage
            exit 1
            ;;
    esac
    
    # Generate session report
    local operation_summary="Action '$action' completed successfully"
    if [[ -n "${backup_file:-}" ]]; then
        operation_summary="$operation_summary with backup created"
    fi
    
    local report_file
    report_file=$(generate_report "$session_dir" "$action" "$operation_summary")
    
    echo ""
    show_success "Session Complete" "Report saved: $report_file"
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi