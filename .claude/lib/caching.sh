#!/bin/bash

# CCPM Caching System
# Provides caching functionality to improve performance

set -euo pipefail

# Cache directory
CACHE_DIR=".claude/cache"
CACHE_VERSION="1.0"

# Initialize cache directory
init_cache() {
    mkdir -p "$CACHE_DIR"
    
    # Create cache metadata file
    if [[ ! -f "$CACHE_DIR/metadata.json" ]]; then
        cat > "$CACHE_DIR/metadata.json" << EOF
{
    "version": "$CACHE_VERSION",
    "created": "$(get_current_datetime)",
    "last_updated": "$(get_current_datetime)"
}
EOF
    fi
}

# Get cache file path
get_cache_path() {
    local cache_key="$1"
    echo "$CACHE_DIR/${cache_key}.json"
}

# Check if cache is valid
is_cache_valid() {
    local cache_file="$1"
    local max_age_hours="${2:-24}"
    
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi
    
    local file_age
    # Platform-compatible file modification time
    if [[ "$(uname)" == "Darwin" ]]; then
        file_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
    else
        file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
    fi
    local max_age_seconds=$((max_age_hours * 3600))
    
    [[ $file_age -lt $max_age_seconds ]]
}

# Get cached data
get_cache() {
    local cache_key="$1"
    local max_age_hours="${2:-24}"
    local cache_file
    
    cache_file=$(get_cache_path "$cache_key")
    
    if is_cache_valid "$cache_file" "$max_age_hours"; then
        cat "$cache_file"
        return 0
    else
        return 1
    fi
}

# Set cached data
set_cache() {
    local cache_key="$1"
    local data="$2"
    local cache_file
    
    init_cache
    cache_file=$(get_cache_path "$cache_key")
    
    echo "$data" > "$cache_file"
    
    # Update metadata
    local metadata_file="$CACHE_DIR/metadata.json"
    if [[ -f "$metadata_file" ]]; then
        # Update last_updated timestamp
        local temp_file
        temp_file=$(mktemp)
        jq --arg timestamp "$(get_current_datetime)" '.last_updated = $timestamp' "$metadata_file" > "$temp_file"
        mv "$temp_file" "$metadata_file"
    fi
}

# Clear specific cache
clear_cache() {
    local cache_key="$1"
    local cache_file
    
    cache_file=$(get_cache_path "$cache_key")
    
    if [[ -f "$cache_file" ]]; then
        rm -f "$cache_file"
        echo "Cleared cache: $cache_key"
    fi
}

# Clear all cache
clear_all_cache() {
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        echo "Cleared all cache"
    fi
}

# Cache epic metadata
cache_epic_metadata() {
    local epic_name="$1"
    local cache_key="epic-${epic_name}"
    
    local epic_file=".claude/epics/${epic_name}/epic.md"
    if [[ ! -f "$epic_file" ]]; then
        return 1
    fi
    
    # Extract metadata from epic file
    local metadata
    metadata=$(awk '
        /^---$/,/^---$/ {
            if ($0 != "---") print $0
        }
    ' "$epic_file")
    
    # Add task counts
    local total_tasks
    local closed_tasks
    local progress
    
    total_tasks=$(find ".claude/epics/${epic_name}" -name "[0-9]*.md" 2>/dev/null | wc -l)
    closed_tasks=$(find ".claude/epics/${epic_name}" -name "[0-9]*.md" -exec grep -l "^status: *closed" {} \; 2>/dev/null | wc -l)
    
    if [[ "$total_tasks" -gt 0 ]]; then
        progress=$((closed_tasks * 100 / total_tasks))
    else
        progress=0
    fi
    
    # Create JSON metadata
    local json_metadata
    json_metadata=$(cat << EOF
{
    "epic_name": "$epic_name",
    "total_tasks": $total_tasks,
    "closed_tasks": $closed_tasks,
    "progress": $progress,
    "cached_at": "$(get_current_datetime)"
}
EOF
)
    
    set_cache "$cache_key" "$json_metadata"
}

# Get cached epic metadata
get_cached_epic_metadata() {
    local epic_name="$1"
    local cache_key="epic-${epic_name}"
    
    get_cache "$cache_key" 1  # 1 hour cache
}

# Cache GitHub issue status
cache_github_issue_status() {
    local issue_number="$1"
    local cache_key="github-issue-${issue_number}"
    
    # Get issue data from GitHub
    local issue_data
    if ! issue_data=$(gh issue view "$issue_number" --json state,title,labels,updatedAt 2>/dev/null); then
        return 1
    fi
    
    # Add cache timestamp
    local cached_data
    cached_data=$(echo "$issue_data" | jq --arg timestamp "$(get_current_datetime)" '.cached_at = $timestamp')
    
    set_cache "$cache_key" "$cached_data"
}

# Get cached GitHub issue status
get_cached_github_issue_status() {
    local issue_number="$1"
    local cache_key="github-issue-${issue_number}"
    
    get_cache "$cache_key" 1  # 30 minutes cache
}

# Cache task status across all epics
cache_all_task_status() {
    local cache_key="all-task-status"
    
    local task_data
    task_data=$(cat << EOF
{
    "total_tasks": $(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l),
    "open_tasks": $(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *open" {} \; 2>/dev/null | wc -l),
    "closed_tasks": $(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *closed" {} \; 2>/dev/null | wc -l),
    "in_progress_tasks": $(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *in-progress" {} \; 2>/dev/null | wc -l),
    "cached_at": "$(get_current_datetime)"
}
EOF
)
    
    set_cache "$cache_key" "$task_data"
}

# Get cached task status
get_cached_task_status() {
    local cache_key="all-task-status"
    
    get_cache "$cache_key" 1  # 30 minutes cache
}

# Cache repository information
cache_repo_info() {
    local cache_key="repo-info"
    
    local repo_data
    if ! repo_data=$(gh repo view --json nameWithOwner,url,defaultBranch 2>/dev/null); then
        return 1
    fi
    
    # Add cache timestamp
    local cached_data
    cached_data=$(echo "$repo_data" | jq --arg timestamp "$(get_current_datetime)" '.cached_at = $timestamp')
    
    set_cache "$cache_key" "$cached_data"
}

# Get cached repository information
get_cached_repo_info() {
    local cache_key="repo-info"
    
    get_cache "$cache_key" 24  # 24 hours cache
}

# Cache cleanup - remove expired entries
cleanup_cache() {
    local max_age_hours="${1:-168}"  # Default 7 days
    
    if [[ ! -d "$CACHE_DIR" ]]; then
        return 0
    fi
    
    local max_age_seconds=$((max_age_hours * 3600))
    local current_time
    current_time=$(date +%s)
    
    find "$CACHE_DIR" -name "*.json" -not -name "metadata.json" | while read -r cache_file; do
        local file_age
        # Platform-compatible file modification time
        if [[ "$(uname)" == "Darwin" ]]; then
            file_age=$((current_time - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        else
            file_age=$((current_time - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        fi
        
        if [[ $file_age -gt $max_age_seconds ]]; then
            rm -f "$cache_file"
            echo "Removed expired cache: $(basename "$cache_file")"
        fi
    done
}

# Get cache statistics
get_cache_stats() {
    if [[ ! -d "$CACHE_DIR" ]]; then
        echo "No cache directory found"
        return 1
    fi
    
    local total_files
    local total_size
    local oldest_file
    local newest_file
    
    total_files=$(find "$CACHE_DIR" -name "*.json" -not -name "metadata.json" | wc -l)
    # Platform-compatible file size calculation
    if [[ "$(uname)" == "Darwin" ]]; then
        total_size=$(find "$CACHE_DIR" -name "*.json" -not -name "metadata.json" -exec stat -f %z {} \; 2>/dev/null | awk '{sum += $1} END {print sum}')
    else
        total_size=$(find "$CACHE_DIR" -name "*.json" -not -name "metadata.json" -exec stat -c %s {} \; 2>/dev/null | awk '{sum += $1} END {print sum}')
    fi
    
    if [[ "$total_files" -gt 0 ]]; then
        # Platform-compatible file timestamp sorting
        if [[ "$(uname)" == "Darwin" ]]; then
            oldest_file=$(find "$CACHE_DIR" -name "*.json" -not -name "metadata.json" -exec stat -f "%m %N" {} \; | sort -n | head -1 | cut -d' ' -f2-)
            newest_file=$(find "$CACHE_DIR" -name "*.json" -not -name "metadata.json" -exec stat -f "%m %N" {} \; | sort -n | tail -1 | cut -d' ' -f2-)
        else
            oldest_file=$(find "$CACHE_DIR" -name "*.json" -not -name "metadata.json" -exec stat -c "%Y %n" {} \; | sort -n | head -1 | cut -d' ' -f2-)
            newest_file=$(find "$CACHE_DIR" -name "*.json" -not -name "metadata.json" -exec stat -c "%Y %n" {} \; | sort -n | tail -1 | cut -d' ' -f2-)
        fi
        
        echo "Cache Statistics:"
        echo "  Total files: $total_files"
        echo "  Total size: $(format_file_size "$total_size")"
        echo "  Oldest: $(basename "$oldest_file")"
        echo "  Newest: $(basename "$newest_file")"
    else
        echo "No cache files found"
    fi
}

# Export functions
export -f init_cache
export -f get_cache_path
export -f is_cache_valid
export -f get_cache
export -f set_cache
export -f clear_cache
export -f clear_all_cache
export -f cache_epic_metadata
export -f get_cached_epic_metadata
export -f cache_github_issue_status
export -f get_cached_github_issue_status
export -f cache_all_task_status
export -f get_cached_task_status
export -f cache_repo_info
export -f get_cached_repo_info
export -f cleanup_cache
export -f get_cache_stats
