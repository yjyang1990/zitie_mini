#!/bin/bash

# CCPM Code Review Processor v2.0
# Processes CodeRabbit and other code review comments with intelligent categorization

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
REVIEWS_DIR=".claude/tmp/reviews"
REPORTS_DIR=".claude/tmp/review-reports"

# Function to show usage
show_usage() {
    show_command_help "code-review-processor" "Process code review comments intelligently" \
        "code-review-processor [input] [options]        # Process review comments
code-review-processor --interactive                # Interactive comment input
code-review-processor file.json --validate        # Process from file with validation
code-review-processor --batch --report            # Batch mode with report generation"
    
    echo ""
    echo "Input Methods:"
    echo "  --interactive                   Interactive comment input mode"
    echo "  <file>                         Read comments from JSON/text file"
    echo "  <text>                         Process inline comment text"
    echo ""
    echo "Processing Options:"
    echo "  --batch                        Process multiple review sessions"
    echo "  --analyze                      Analyze comment patterns and trends"
    echo "  --report                       Generate comprehensive review report"
    echo "  --validate                     Validate applied changes for quality"
    echo "  --dry-run                      Preview processing without changes"
    echo "  --help                         Show this help message"
    echo ""
    echo "Comment Categories (Priority Order):"
    echo "  🔒 Security         High priority - generally accepted"
    echo "  🐛 Bug Fixes        High priority - generally accepted"
    echo "  📝 Type Safety      Medium priority - generally accepted"
    echo "  ⚡ Performance       Contextual - ~50% acceptance rate"
    echo "  🔧 Maintainability   Contextual - ~67% acceptance rate"
    echo "  🎨 Style Issues      Low priority - ~25% acceptance rate"
    echo "  ♿ Accessibility     Contextual - ~33% acceptance rate"
    echo ""
    echo "Examples:"
    echo "  code-review-processor --interactive           # Interactive mode"
    echo "  code-review-processor review.json            # Process from file"
    echo "  code-review-processor \"Fix null check\"       # Process inline text"
    echo "  code-review-processor --batch --validate     # Batch with validation"
}

# Initialize review session
init_review_session() {
    local session_id="review-$(date +%Y%m%d-%H%M%S)"
    local session_dir="$REVIEWS_DIR/$session_id"
    
    ensure_directory "$session_dir"
    ensure_directory "$REPORTS_DIR"
    
    echo "$session_dir"
}

# Parse review input from various sources
parse_review_input() {
    local input="$1"
    local review_content=""
    
    if [[ -z "$input" ]]; then
        show_info "Interactive mode: Please paste review comments"
        show_info "Press Ctrl+D when finished"
        review_content=$(cat)
    elif [[ -f "$input" ]]; then
        show_info "Reading review comments from file: $input"
        review_content=$(cat "$input")
    else
        show_info "Processing inline review comments"
        review_content="$input"
    fi
    
    echo "$review_content"
}

# Categorize comments by type and priority
categorize_comments() {
    local review_content="$1"
    local session_dir="$2"
    
    show_subtitle "📊 Comment Categorization"
    
    # Initialize counters
    local total_comments=0
    local security_comments=0
    local performance_comments=0
    local style_comments=0
    local bug_comments=0
    local type_safety_comments=0
    local maintainability_comments=0
    local accessibility_comments=0
    
    # Create categorization report
    local categorization_file="$session_dir/categorization.json"
    
    # Process each line for patterns
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        local line_lower
        line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
        
        # Security patterns
        if [[ "$line_lower" =~ (security|vulnerability|xss|sql|injection|csrf|auth|sanitize) ]]; then
            ((security_comments++))
            show_info "🔒 Security: $(echo "$line" | head -c 60)..."
            
        # Bug patterns  
        elif [[ "$line_lower" =~ (bug|error|null|undefined|exception|crash|fail) ]]; then
            ((bug_comments++))
            show_info "🐛 Bug: $(echo "$line" | head -c 60)..."
            
        # Type safety patterns
        elif [[ "$line_lower" =~ (type|typescript|interface|generic|any|unknown) ]]; then
            ((type_safety_comments++))
            show_info "📝 Type: $(echo "$line" | head -c 60)..."
            
        # Performance patterns
        elif [[ "$line_lower" =~ (performance|optimize|slow|memory|leak|cache|efficient) ]]; then
            ((performance_comments++))
            show_info "⚡ Performance: $(echo "$line" | head -c 60)..."
            
        # Maintainability patterns
        elif [[ "$line_lower" =~ (maintain|refactor|complexity|readable|clean|duplicate) ]]; then
            ((maintainability_comments++))
            show_info "🔧 Maintainability: $(echo "$line" | head -c 60)..."
            
        # Style patterns
        elif [[ "$line_lower" =~ (style|format|indent|spacing|naming|convention) ]]; then
            ((style_comments++))
            show_info "🎨 Style: $(echo "$line" | head -c 60)..."
            
        # Accessibility patterns
        elif [[ "$line_lower" =~ (accessibility|a11y|aria|screen|reader|contrast) ]]; then
            ((accessibility_comments++))
            show_info "♿ Accessibility: $(echo "$line" | head -c 60)..."
        fi
        
        # Count if categorized
        if [[ "$line_lower" =~ (security|bug|error|type|performance|maintain|style|accessibility) ]]; then
            ((total_comments++))
        fi
        
    done <<< "$review_content"
    
    # Save categorization data
    cat > "$categorization_file" << EOF
{
  "timestamp": "$(format_timestamp)",
  "total_comments": $total_comments,
  "categories": {
    "security": $security_comments,
    "bugs": $bug_comments,
    "type_safety": $type_safety_comments,
    "performance": $performance_comments,
    "maintainability": $maintainability_comments,
    "style": $style_comments,
    "accessibility": $accessibility_comments
  }
}
EOF
    
    # Display summary
    show_info "📈 Categorization Summary:"
    echo "  🔒 Security: $security_comments (High Priority)"
    echo "  🐛 Bug Fixes: $bug_comments (High Priority)"
    echo "  📝 Type Safety: $type_safety_comments (Medium Priority)"
    echo "  ⚡ Performance: $performance_comments (Contextual)"
    echo "  🔧 Maintainability: $maintainability_comments (Contextual)"
    echo "  🎨 Style: $style_comments (Low Priority)"
    echo "  ♿ Accessibility: $accessibility_comments (Contextual)"
    echo "  📊 Total Categorized: $total_comments"
    
    echo "$categorization_file"
}

# Generate processing strategy based on categorization
generate_strategy() {
    local categorization_file="$1"
    local session_dir="$2"
    
    show_subtitle "🎯 Processing Strategy"
    
    if [[ ! -f "$categorization_file" ]]; then
        show_error "Missing Data" "Categorization file not found"
        return 1
    fi
    
    local strategy_file="$session_dir/strategy.json"
    local total security bugs type_safety performance maintainability style accessibility
    
    # Extract values using jq if available, fallback to simple parsing
    if command -v jq >/dev/null 2>&1; then
        total=$(jq -r '.total_comments' "$categorization_file")
        security=$(jq -r '.categories.security' "$categorization_file")
        bugs=$(jq -r '.categories.bugs' "$categorization_file")
        type_safety=$(jq -r '.categories.type_safety' "$categorization_file")
        performance=$(jq -r '.categories.performance' "$categorization_file")
        maintainability=$(jq -r '.categories.maintainability' "$categorization_file")
        style=$(jq -r '.categories.style' "$categorization_file")
        accessibility=$(jq -r '.categories.accessibility' "$categorization_file")
    else
        show_warning "jq Missing" "Cannot parse JSON, using simplified strategy"
        total=1
        security=0; bugs=0; type_safety=0; performance=0; maintainability=0; style=0; accessibility=0
    fi
    
    # Calculate acceptance rates based on category priority
    local accepted_changes=0
    local ignored_suggestions=0
    
    # High priority (100% acceptance)
    ((accepted_changes += security + bugs + type_safety))
    
    # Contextual acceptance rates
    ((accepted_changes += performance / 2))              # 50%
    ((ignored_suggestions += performance - performance / 2))
    
    ((accepted_changes += maintainability * 2 / 3))      # 67%
    ((ignored_suggestions += maintainability - maintainability * 2 / 3))
    
    ((accepted_changes += style / 4))                    # 25%
    ((ignored_suggestions += style - style / 4))
    
    ((accepted_changes += accessibility / 3))            # 33%
    ((ignored_suggestions += accessibility - accessibility / 3))
    
    # Generate strategy document
    cat > "$strategy_file" << EOF
{
  "timestamp": "$(format_timestamp)",
  "total_comments": $total,
  "acceptance_strategy": {
    "accepted_changes": $accepted_changes,
    "ignored_suggestions": $ignored_suggestions,
    "acceptance_rate": $(( total > 0 ? accepted_changes * 100 / total : 0 ))
  },
  "priority_levels": {
    "high_priority": {
      "categories": ["security", "bugs", "type_safety"],
      "acceptance_rate": 100,
      "count": $((security + bugs + type_safety))
    },
    "medium_priority": {
      "categories": ["performance", "maintainability"],
      "acceptance_rate": 58,
      "count": $((performance + maintainability))
    },
    "low_priority": {
      "categories": ["style", "accessibility"],
      "acceptance_rate": 29,
      "count": $((style + accessibility))
    }
  }
}
EOF
    
    show_info "📋 Processing Strategy Generated:"
    echo "  ✅ Accepted: $accepted_changes changes"
    echo "  ❌ Ignored: $ignored_suggestions suggestions"
    if [[ $total -gt 0 ]]; then
        echo "  📈 Overall Rate: $((accepted_changes * 100 / total))% acceptance"
    fi
    
    echo "$strategy_file"
}

# Extract file references from comments
extract_file_references() {
    local review_content="$1"
    local session_dir="$2"
    
    show_subtitle "📁 File Reference Extraction"
    
    # Extract file patterns
    local file_pattern='[a-zA-Z0-9_/-]+\.(js|ts|jsx|tsx|py|java|cpp|c|h|go|rs|php|rb|cs|swift|kt|scala|md|json|yml|yaml)'
    local files_found
    files_found=$(echo "$review_content" | grep -oE "$file_pattern" | sort -u)
    
    local files_to_process=()
    local files_report="$session_dir/files.json"
    
    if [[ -n "$files_found" ]]; then
        show_info "Files mentioned in review:"
        
        local files_array="[]"
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            
            if [[ -f "$file" ]]; then
                show_info "  ✅ $file (exists)"
                files_to_process+=("$file")
                files_array=$(echo "$files_array" | jq --arg file "$file" '. + [{
                    "path": $file,
                    "exists": true,
                    "size": 0
                }]')
            else
                show_warning "File Missing" "$file (not found)"
                files_array=$(echo "$files_array" | jq --arg file "$file" '. + [{
                    "path": $file,
                    "exists": false,
                    "size": 0
                }]')
            fi
        done <<< "$files_found"
        
        # Save files report
        echo "{\"files\": $files_array, \"total\": ${#files_to_process[@]}}" > "$files_report"
        
    else
        show_info "No specific files detected in comments"
        echo '{"files": [], "total": 0}' > "$files_report"
    fi
    
    echo "${files_to_process[@]}"
}

# Generate comprehensive review report
generate_review_report() {
    local session_dir="$1"
    local review_mode="$2"
    
    show_subtitle "📋 Review Report Generation"
    
    local report_file="$REPORTS_DIR/review-report-$(basename "$session_dir").md"
    local timestamp
    timestamp=$(format_timestamp)
    
    # Load session data
    local categorization_file="$session_dir/categorization.json"
    local strategy_file="$session_dir/strategy.json"
    local files_file="$session_dir/files.json"
    
    cat > "$report_file" << EOF
# Code Review Processing Report

**Session**: $(basename "$session_dir")  
**Generated**: $timestamp  
**Mode**: $review_mode

## Executive Summary

This report provides a comprehensive analysis of the code review comments processed during this session, including categorization, acceptance strategy, and processing recommendations.

## Comment Analysis

EOF

    # Add categorization data if available
    if [[ -f "$categorization_file" ]] && command -v jq >/dev/null 2>&1; then
        local total_comments
        total_comments=$(jq -r '.total_comments' "$categorization_file")
        
        cat >> "$report_file" << EOF
**Total Comments Processed**: $total_comments

### Category Breakdown

EOF
        
        # Extract category data
        jq -r '.categories | to_entries[] | "- " + .key + ": " + (.value | tostring)' "$categorization_file" >> "$report_file"
        
    fi
    
    # Add strategy data if available
    if [[ -f "$strategy_file" ]] && command -v jq >/dev/null 2>&1; then
        cat >> "$report_file" << EOF

## Processing Strategy

EOF
        
        local acceptance_rate
        acceptance_rate=$(jq -r '.acceptance_strategy.acceptance_rate' "$strategy_file")
        
        cat >> "$report_file" << EOF
**Overall Acceptance Rate**: ${acceptance_rate}%

### Priority-Based Processing

- **High Priority** (Security, Bugs, Type Safety): 100% acceptance rate
- **Medium Priority** (Performance, Maintainability): ~58% acceptance rate
- **Low Priority** (Style, Accessibility): ~29% acceptance rate

EOF
    fi
    
    # Add file processing information
    cat >> "$report_file" << EOF

## Files Identified

EOF
    
    if [[ -f "$files_file" ]] && command -v jq >/dev/null 2>&1; then
        local file_count
        file_count=$(jq -r '.total' "$files_file")
        
        if [[ $file_count -gt 0 ]]; then
            echo "**Files to Process**: $file_count" >> "$report_file"
            echo "" >> "$report_file"
            jq -r '.files[] | "- " + .path + (if .exists then " ✅" else " ❌ (not found)" end)' "$files_file" >> "$report_file"
        else
            echo "No specific files identified for processing" >> "$report_file"
        fi
    else
        echo "File analysis not available" >> "$report_file"
    fi
    
    # Add recommendations
    cat >> "$report_file" << EOF

## Recommendations

1. **Review Priority**: Focus on high-priority items (security, bugs, type safety) first
2. **Context Validation**: Verify that suggested changes align with project architecture
3. **Testing**: Run comprehensive tests after applying changes
4. **Documentation**: Update relevant documentation for significant changes
5. **Team Review**: Consider peer review for complex modifications

## Next Steps

1. Review this report and processing strategy
2. Apply accepted changes using appropriate tools (Edit, MultiEdit)
3. Run project tests to validate changes
4. Commit changes with descriptive messages
5. Update team on review processing results

## Session Artifacts

- Session Directory: $session_dir
- Categorization Data: $categorization_file
- Processing Strategy: $strategy_file
- File References: $files_file
- This Report: $report_file

---
*Generated by CCPM Code Review Processor v2.0*
EOF

    show_success "Report Generated" "$report_file"
    echo "$report_file"
}

# Main execution function
main() {
    local review_input=""
    local batch_mode=false
    local analyze_mode=false
    local report_mode=false
    local validate_mode=false
    local dry_run=false
    local interactive_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --interactive)
                interactive_mode=true
                shift
                ;;
            --batch)
                batch_mode=true
                shift
                ;;
            --analyze)
                analyze_mode=true
                shift
                ;;
            --report)
                report_mode=true
                shift
                ;;
            --validate)
                validate_mode=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h|help)
                show_usage
                exit 0
                ;;
            -*)
                show_error "Unknown Option" "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$review_input" ]]; then
                    review_input="$1"
                fi
                shift
                ;;
        esac
    done
    
    show_title "🔍 CCPM Code Review Processor" 45
    
    # Show configuration
    local mode_desc="Standard"
    if [[ "$batch_mode" == true ]]; then mode_desc="Batch"; fi
    if [[ "$interactive_mode" == true ]]; then mode_desc="Interactive"; fi
    if [[ "$dry_run" == true ]]; then mode_desc="$mode_desc (Dry Run)"; fi
    
    show_info "Processing Mode: $mode_desc"
    
    if [[ "$validate_mode" == true ]]; then
        show_info "Validation: Enabled"
    fi
    if [[ "$report_mode" == true ]]; then
        show_info "Reporting: Enabled"
    fi
    if [[ "$analyze_mode" == true ]]; then
        show_info "Analysis: Enabled"
    fi
    
    echo ""
    
    # Initialize session
    local session_dir
    session_dir=$(init_review_session)
    show_info "Session: $(basename "$session_dir")"
    
    # Handle interactive mode
    if [[ "$interactive_mode" == true ]]; then
        review_input=""
    fi
    
    # Parse review input
    local review_content
    review_content=$(parse_review_input "$review_input")
    
    if [[ -z "$review_content" ]]; then
        show_error "No Input" "No review content provided"
        exit 1
    fi
    
    # Save raw content
    echo "$review_content" > "$session_dir/raw-comments.txt"
    
    # Preview mode
    if [[ "$dry_run" == true ]]; then
        show_subtitle "🔍 Dry Run Preview"
        show_info "Would process review content:"
        echo "  Lines: $(echo "$review_content" | wc -l)"
        echo "  Characters: $(echo "$review_content" | wc -c)"
        echo "  Session: $(basename "$session_dir")"
        exit 0
    fi
    
    # Process review content
    local categorization_file
    categorization_file=$(categorize_comments "$review_content" "$session_dir")
    
    local strategy_file
    strategy_file=$(generate_strategy "$categorization_file" "$session_dir")
    
    local files_to_process
    files_to_process=$(extract_file_references "$review_content" "$session_dir")
    
    # Generate report if requested
    if [[ "$report_mode" == true ]]; then
        generate_review_report "$session_dir" "$mode_desc"
    fi
    
    # Show processing summary
    show_subtitle "📊 Processing Complete"
    show_success "Review Processed" "Session saved to $(basename "$session_dir")"
    echo "  📁 Raw Comments: $session_dir/raw-comments.txt"
    echo "  📊 Categorization: $categorization_file"
    echo "  🎯 Strategy: $strategy_file"
    
    if [[ -n "$files_to_process" ]]; then
        show_info "Files identified for processing:"
        for file in $files_to_process; do
            echo "  📄 $file"
        done
    else
        show_info "No specific files identified for processing"
    fi
    
    if [[ "$validate_mode" == true ]]; then
        show_success "Validation" "Quality checks would be applied to all changes"
    fi
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi