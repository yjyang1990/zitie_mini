#!/bin/bash

# CCPM Project Management Data Manager v2.0
# Manages PRDs, Epics, and their relationships with indexing and search capabilities

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
PRDS_DIR=".claude/prds"
EPICS_DIR=".claude/epics"
INDEX_FILE=".claude/tmp/pm-index.json"
CACHE_DIR=".claude/tmp/pm-cache"

# Function to show usage
show_usage() {
    show_command_help "pm-data-manager" "Manage CCPM project data and indexing" \
        "pm-data-manager [COMMAND] [OPTIONS]         # Manage PM data
pm-data-manager init                            # Initialize data system
pm-data-manager update-index                    # Update data index
pm-data-manager search <query> [type]           # Search PRDs/Epics
pm-data-manager stats                           # Show statistics
pm-data-manager validate                        # Validate data integrity"
    
    echo ""
    echo "Commands:"
    echo "  init                         Initialize PM data management system"
    echo "  update-index                 Update searchable data index"
    echo "  search <query> [type]        Search PRDs and Epics (type: all|prds|epics)"
    echo "  stats                        Show PM statistics and overview"
    echo "  validate                     Validate data integrity and relationships"
    echo "  list-prds                    List all Product Requirements Documents"
    echo "  list-epics                   List all Epics with completion status"
    echo "  clean-cache                  Clean PM data cache"
    echo "  help                         Show this help message"
    echo ""
    echo "Search Types:"
    echo "  all                          Search both PRDs and Epics (default)"
    echo "  prds                         Search only PRDs"
    echo "  epics                        Search only Epics"
    echo ""
    echo "Examples:"
    echo "  pm-data-manager init                        # Initialize PM system"
    echo "  pm-data-manager update-index                # Refresh data index"
    echo "  pm-data-manager search \"authentication\"     # Search for auth items"
    echo "  pm-data-manager search \"john\" prds          # Search PRDs by author"
    echo "  pm-data-manager stats                       # Show data overview"
    echo "  pm-data-manager validate                    # Check data integrity"
}

# Initialize PM data management system
init_pm_data() {
    show_title "🔧 PM Data System Initialization" 45
    
    # Ensure required directories exist
    local directories=(
        "$PRDS_DIR"
        "$EPICS_DIR" 
        "$CACHE_DIR"
        "$(dirname "$INDEX_FILE")"
    )
    
    show_subtitle "📁 Directory Setup"
    for dir in "${directories[@]}"; do
        ensure_directory "$dir"
        
        # Create .gitkeep for empty directories
        if [[ ! -f "$dir/.gitkeep" ]]; then
            touch "$dir/.gitkeep"
        fi
    done
    
    show_success "Directories" "All PM directories created"
    
    # Create initial index if it doesn't exist
    show_subtitle "📋 Index Initialization"
    if [[ ! -f "$INDEX_FILE" ]]; then
        create_initial_index
        show_success "Index Created" "PM data index initialized"
    else
        show_info "Index already exists, updating..."
        update_index
    fi
    
    show_success "PM Data System" "Initialization complete"
}

# Create initial index structure
create_initial_index() {
    local timestamp
    timestamp=$(format_timestamp)
    
    cat > "$INDEX_FILE" << EOF
{
  "version": "2.0",
  "last_updated": "$timestamp",
  "prds": {},
  "epics": {},
  "relationships": {},
  "statistics": {
    "total_prds": 0,
    "total_epics": 0,
    "active_epics": 0,
    "completed_epics": 0
  },
  "metadata": {
    "auto_generated": true,
    "index_format": "ccpm-pm-v2",
    "created": "$timestamp"
  }
}
EOF
}

# Update index with current data
update_index() {
    show_title "🔄 PM Data Index Update" 40
    
    if ! command -v jq >/dev/null 2>&1; then
        show_error "jq Required" "jq is required for index operations"
        return 1
    fi
    
    local timestamp
    timestamp=$(format_timestamp)
    
    show_subtitle "📚 Scanning PRDs"
    local prds_data="{}"
    local prd_count=0
    
    if [[ -d "$PRDS_DIR" ]]; then
        while IFS= read -r prd_file; do
            if [[ -f "$prd_file" && "$prd_file" == *.md ]]; then
                local prd_name
                prd_name=$(basename "$prd_file" .md)
                local prd_info
                prd_info=$(extract_prd_metadata "$prd_file")
                prds_data=$(echo "$prds_data" | jq --argjson info "$prd_info" ".\"$prd_name\" = \$info")
                ((prd_count++))
            fi
        done < <(find "$PRDS_DIR" -name "*.md" 2>/dev/null || true)
    fi
    
    show_info "✓ Scanned $prd_count PRDs"
    
    show_subtitle "🎯 Scanning Epics"
    local epics_data="{}"
    local epic_count=0
    
    if [[ -d "$EPICS_DIR" ]]; then
        while IFS= read -r epic_dir; do
            if [[ -d "$epic_dir" ]]; then
                local epic_file="$epic_dir/epic.md"
                if [[ -f "$epic_file" ]]; then
                    local epic_name
                    epic_name=$(basename "$epic_dir")
                    local epic_info
                    epic_info=$(extract_epic_metadata "$epic_file" "$epic_dir")
                    epics_data=$(echo "$epics_data" | jq --argjson info "$epic_info" ".\"$epic_name\" = \$info")
                    ((epic_count++))
                fi
            fi
        done < <(find "$EPICS_DIR" -maxdepth 1 -type d -not -name "$(basename "$EPICS_DIR")" 2>/dev/null || true)
    fi
    
    show_info "✓ Scanned $epic_count Epics"
    
    # Calculate statistics
    show_subtitle "📊 Calculating Statistics"
    local total_prds total_epics active_epics completed_epics
    total_prds=$(echo "$prds_data" | jq 'keys | length')
    total_epics=$(echo "$epics_data" | jq 'keys | length')
    active_epics=$(echo "$epics_data" | jq '[.[] | select(.status == "active" or .status == "in_progress" or .status == "planning")] | length')
    completed_epics=$(echo "$epics_data" | jq '[.[] | select(.status == "completed" or .status == "done")] | length')
    
    # Update index with all collected data
    if [[ ! -f "$INDEX_FILE" ]]; then
        create_initial_index
    fi
    
    jq --arg timestamp "$timestamp" \
       --argjson prds "$prds_data" \
       --argjson epics "$epics_data" \
       --argjson total_prds "$total_prds" \
       --argjson total_epics "$total_epics" \
       --argjson active_epics "$active_epics" \
       --argjson completed_epics "$completed_epics" \
       '.last_updated = $timestamp |
        .prds = $prds |
        .epics = $epics |
        .statistics.total_prds = $total_prds |
        .statistics.total_epics = $total_epics |
        .statistics.active_epics = $active_epics |
        .statistics.completed_epics = $completed_epics' \
       "$INDEX_FILE" > "${INDEX_FILE}.tmp"
    
    mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
    
    show_success "Index Updated" "$total_prds PRDs, $total_epics Epics indexed"
}

# Extract PRD metadata from markdown file
extract_prd_metadata() {
    local prd_file="$1"
    local title author version status created_date
    
    # Extract metadata from markdown frontmatter and content
    title=$(grep -m1 "^# " "$prd_file" 2>/dev/null | sed 's/^# //' || echo "Untitled PRD")
    author=$(grep -m1 "^\*\*Author:\*\*\|^Author:" "$prd_file" 2>/dev/null | sed 's/^.*Author[*:]*[ ]*//' | sed 's/\*//g' || echo "Unknown")
    version=$(grep -m1 "^\*\*Version:\*\*\|^Version:" "$prd_file" 2>/dev/null | sed 's/^.*Version[*:]*[ ]*//' | sed 's/\*//g' || echo "1.0")
    status=$(grep -m1 "^\*\*Status:\*\*\|^Status:" "$prd_file" 2>/dev/null | sed 's/^.*Status[*:]*[ ]*//' | sed 's/\*//g' || echo "Draft")
    
    # Get file modification time
    if command -v stat >/dev/null 2>&1; then
        if [[ "$(uname)" == "Darwin" ]]; then
            created_date=$(stat -f %Sm -t "%Y-%m-%d" "$prd_file" 2>/dev/null || date +%Y-%m-%d)
        else
            created_date=$(stat -c %y "$prd_file" 2>/dev/null | cut -d' ' -f1 || date +%Y-%m-%d)
        fi
    else
        created_date=$(date +%Y-%m-%d)
    fi
    
    # Calculate word count and size metrics
    local word_count line_count file_size
    word_count=$(wc -w < "$prd_file" 2>/dev/null || echo 0)
    line_count=$(wc -l < "$prd_file" 2>/dev/null || echo 0)
    file_size=$(wc -c < "$prd_file" 2>/dev/null || echo 0)
    
    jq -n \
        --arg title "$title" \
        --arg author "$author" \
        --arg version "$version" \
        --arg status "$status" \
        --arg created_date "$created_date" \
        --arg file_path "$prd_file" \
        --argjson word_count "$word_count" \
        --argjson line_count "$line_count" \
        --argjson file_size "$file_size" \
        '{
            title: $title,
            author: $author,
            version: $version,
            status: $status,
            created_date: $created_date,
            file_path: $file_path,
            metrics: {
                word_count: $word_count,
                line_count: $line_count,
                file_size: $file_size
            },
            last_scanned: now | strftime("%Y-%m-%dT%H:%M:%SZ")
        }'
}

# Extract Epic metadata from epic directory and file
extract_epic_metadata() {
    local epic_file="$1"
    local epic_dir="$2"
    local title prd_reference author status created_date
    
    # Extract metadata from epic.md file
    title=$(grep -m1 "^# Epic:" "$epic_file" 2>/dev/null | sed 's/^# Epic: *//' || 
            grep -m1 "^# " "$epic_file" 2>/dev/null | sed 's/^# //' || 
            echo "$(basename "$epic_dir")")
    
    prd_reference=$(grep -m1 "^\*\*Generated from PRD:\*\*\|^\*\*PRD:\*\*\|^PRD:" "$epic_file" 2>/dev/null | 
                   sed 's/^.*PRD[*:]*[ ]*//' | sed 's/\*//g' || echo "Unknown")
    
    author=$(grep -m1 "^\*\*Author:\*\*\|^Author:" "$epic_file" 2>/dev/null | 
             sed 's/^.*Author[*:]*[ ]*//' | sed 's/\*//g' || echo "Unknown")
    
    status=$(grep -m1 "^\*\*Status:\*\*\|^Status:" "$epic_file" 2>/dev/null | 
             sed 's/^.*Status[*:]*[ ]*//' | sed 's/\*//g' || echo "Planning")
    
    # Get creation date
    if command -v stat >/dev/null 2>&1; then
        if [[ "$(uname)" == "Darwin" ]]; then
            created_date=$(stat -f %Sm -t "%Y-%m-%d" "$epic_file" 2>/dev/null || date +%Y-%m-%d)
        else
            created_date=$(stat -c %y "$epic_file" 2>/dev/null | cut -d' ' -f1 || date +%Y-%m-%d)
        fi
    else
        created_date=$(date +%Y-%m-%d)
    fi
    
    # Count tasks from task files in epic directory
    local task_count completed_tasks
    task_count=$(find "$epic_dir" -name "[0-9]*.md" 2>/dev/null | wc -l || echo 0)
    
    # Count completed tasks (check for status: completed in task files)
    completed_tasks=0
    if [[ $task_count -gt 0 ]]; then
        while IFS= read -r task_file; do
            if [[ -f "$task_file" ]]; then
                if grep -q "^status: completed\|^status: done\|Status: Completed\|Status: Done" "$task_file" 2>/dev/null; then
                    ((completed_tasks++))
                fi
            fi
        done < <(find "$epic_dir" -name "[0-9]*.md" 2>/dev/null || true)
    fi
    
    jq -n \
        --arg title "$title" \
        --arg prd_reference "$prd_reference" \
        --arg author "$author" \
        --arg status "$status" \
        --arg created_date "$created_date" \
        --arg file_path "$epic_file" \
        --arg epic_dir "$epic_dir" \
        --argjson task_count "$task_count" \
        --argjson completed_tasks "$completed_tasks" \
        '{
            title: $title,
            prd_reference: $prd_reference,
            author: $author,
            status: $status,
            created_date: $created_date,
            file_path: $file_path,
            epic_directory: $epic_dir,
            tasks: {
                total: $task_count,
                completed: $completed_tasks,
                completion_percentage: (if $task_count > 0 then ($completed_tasks * 100 / $task_count) else 0 end)
            },
            last_scanned: now | strftime("%Y-%m-%dT%H:%M:%SZ")
        }'
}

# Search PRDs and Epics with improved matching
search_pm_data() {
    local query="$1"
    local type="${2:-all}"
    
    show_title "🔍 PM Data Search" 40
    show_info "Query: '$query'"
    show_info "Type: $type"
    echo ""
    
    if [[ ! -f "$INDEX_FILE" ]]; then
        show_error "Index Missing" "PM index not found"
        show_tip "Run 'pm-data-manager update-index' first"
        return 1
    fi
    
    local results
    case "$type" in
        "prds")
            results=$(jq --arg query "$query" '
                .prds | to_entries[] | 
                select(.value.title | test($query; "i") or 
                       .value.author | test($query; "i") or
                       .value.status | test($query; "i") or
                       .key | test($query; "i")) |
                {name: .key, type: "PRD", data: .value}
            ' "$INDEX_FILE")
            ;;
        "epics")
            results=$(jq --arg query "$query" '
                .epics | to_entries[] | 
                select(.value.title | test($query; "i") or 
                       .value.author | test($query; "i") or
                       .value.prd_reference | test($query; "i") or
                       .value.status | test($query; "i") or
                       .key | test($query; "i")) |
                {name: .key, type: "Epic", data: .value}
            ' "$INDEX_FILE")
            ;;
        "all"|*)
            results=$(jq --arg query "$query" '
                (.prds | to_entries[] | 
                 select(.value.title | test($query; "i") or 
                        .value.author | test($query; "i") or
                        .value.status | test($query; "i") or
                        .key | test($query; "i")) |
                 {name: .key, type: "PRD", data: .value}),
                (.epics | to_entries[] | 
                 select(.value.title | test($query; "i") or 
                        .value.author | test($query; "i") or
                        .value.prd_reference | test($query; "i") or
                        .value.status | test($query; "i") or
                        .key | test($query; "i")) |
                 {name: .key, type: "Epic", data: .value})
            ' "$INDEX_FILE")
            ;;
    esac
    
    # Format and display results
    if [[ -n "$results" ]]; then
        local result_array
        result_array=$(echo "$results" | jq -s '.')
        local count
        count=$(echo "$result_array" | jq 'length')
        
        show_success "Search Results" "Found $count matches"
        echo ""
        
        echo "$result_array" | jq -r '.[] | "📄 \(.type): \(.name)\n   Title: \(.data.title)\n   Status: \(.data.status)\n"'
    else
        show_warning "No Results" "No matches found for '$query'"
    fi
}

# Show comprehensive PM statistics
show_pm_stats() {
    show_title "📊 Project Management Statistics" 45
    
    if [[ ! -f "$INDEX_FILE" ]]; then
        show_error "Index Missing" "PM index not found"
        show_tip "Run 'pm-data-manager update-index' first"
        return 1
    fi
    
    local stats
    stats=$(jq '.statistics' "$INDEX_FILE")
    
    show_subtitle "📈 Overview"
    echo "  PRDs: $(echo "$stats" | jq -r '.total_prds')"
    echo "  Epics: $(echo "$stats" | jq -r '.total_epics')"
    echo "    - Active: $(echo "$stats" | jq -r '.active_epics')"
    echo "    - Completed: $(echo "$stats" | jq -r '.completed_epics')"
    
    local last_updated
    last_updated=$(jq -r '.last_updated' "$INDEX_FILE")
    echo "  Last Updated: $last_updated"
    echo ""
    
    # Show recent PRDs
    show_subtitle "📚 Recent PRDs"
    if [[ "$(jq '.prds | keys | length' "$INDEX_FILE")" -gt 0 ]]; then
        jq -r '.prds | to_entries[] | "  \(.key): \(.value.title) (\(.value.status))"' "$INDEX_FILE" | head -5
    else
        echo "  No PRDs found"
    fi
    
    echo ""
    
    # Show active epics
    show_subtitle "🎯 Active Epics"
    if [[ "$(jq '.epics | keys | length' "$INDEX_FILE")" -gt 0 ]]; then
        jq -r '.epics | to_entries[] | select(.value.status == "active" or .value.status == "in_progress" or .value.status == "planning") | "  \(.key): \(.value.tasks.completion_percentage)% complete"' "$INDEX_FILE" | head -5
    else
        echo "  No active epics found"
    fi
}

# Validate PM data integrity
validate_pm_data() {
    show_title "🔍 PM Data Integrity Validation" 45
    
    local issues=()
    local warnings=()
    
    # Check if index exists
    if [[ ! -f "$INDEX_FILE" ]]; then
        show_error "Index Missing" "PM index file not found"
        return 1
    fi
    
    show_subtitle "🔗 Checking Relationships"
    
    # Check for orphaned epics
    while IFS= read -r epic_name; do
        local prd_ref
        prd_ref=$(jq -r ".epics.\"$epic_name\".prd_reference" "$INDEX_FILE")
        
        if [[ "$prd_ref" != "Unknown" && "$prd_ref" != "null" && -n "$prd_ref" ]]; then
            local prd_exists
            prd_exists=$(jq -r ".prds | has(\"$prd_ref\")" "$INDEX_FILE")
            
            if [[ "$prd_exists" != "true" ]]; then
                issues+=("Epic '$epic_name' references missing PRD '$prd_ref'")
            fi
        else
            warnings+=("Epic '$epic_name' has no PRD reference")
        fi
    done < <(jq -r '.epics | keys[]' "$INDEX_FILE" 2>/dev/null || true)
    
    show_subtitle "📁 Checking File Existence"
    
    # Check PRD files
    while IFS= read -r prd_file; do
        if [[ -n "$prd_file" && ! -f "$prd_file" ]]; then
            issues+=("Indexed PRD file not found: $prd_file")
        fi
    done < <(jq -r '.prds[].file_path' "$INDEX_FILE" 2>/dev/null || true)
    
    # Check Epic files
    while IFS= read -r epic_file; do
        if [[ -n "$epic_file" && ! -f "$epic_file" ]]; then
            issues+=("Indexed Epic file not found: $epic_file")
        fi
    done < <(jq -r '.epics[].file_path' "$INDEX_FILE" 2>/dev/null || true)
    
    # Report results
    show_subtitle "📋 Validation Results"
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        show_success "Data Integrity" "All validation checks passed"
    else
        show_error "Integrity Issues" "Found ${#issues[@]} data integrity issues:"
        for issue in "${issues[@]}"; do
            echo "  ❌ $issue"
        done
    fi
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo ""
        show_warning "Data Warnings" "Found ${#warnings[@]} potential issues:"
        for warning in "${warnings[@]}"; do
            echo "  ⚠️  $warning"
        done
    fi
    
    return $([[ ${#issues[@]} -eq 0 ]])
}

# Clean PM data cache
clean_cache() {
    show_title "🧹 PM Data Cache Cleanup" 40
    
    if [[ -d "$CACHE_DIR" ]]; then
        local file_count
        file_count=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l || echo 0)
        
        rm -rf "$CACHE_DIR"/*
        ensure_directory "$CACHE_DIR"
        
        show_success "Cache Cleaned" "Removed $file_count cached files"
    else
        show_info "No cache directory found"
    fi
}

# Parse command and execute
COMMAND="${1:-help}"

case "$COMMAND" in
    "init")
        init_pm_data
        ;;
    "update-index")
        update_index
        ;;
    "search")
        if [[ $# -lt 2 ]]; then
            show_error "Missing Query" "Usage: pm-data-manager search <query> [type]"
            exit 1
        fi
        search_pm_data "$2" "${3:-all}"
        ;;
    "stats")
        show_pm_stats
        ;;
    "validate")
        validate_pm_data
        ;;
    "list-prds")
        if [[ -f "$INDEX_FILE" ]]; then
            show_title "📚 All PRDs" 40
            jq -r '.prds | to_entries[] | "  \(.key): \(.value.title) (\(.value.status))"' "$INDEX_FILE"
        else
            show_warning "No Index" "Index not found. Run 'update-index' first."
        fi
        ;;
    "list-epics")
        if [[ -f "$INDEX_FILE" ]]; then
            show_title "🎯 All Epics" 40
            jq -r '.epics | to_entries[] | "  \(.key): \(.value.title) - \(.value.tasks.completion_percentage)% complete"' "$INDEX_FILE"
        else
            show_warning "No Index" "Index not found. Run 'update-index' first."
        fi
        ;;
    "clean-cache")
        clean_cache
        ;;
    "--help"|"-h"|"help"|*)
        show_usage
        ;;
esac

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script was executed directly
    :
fi