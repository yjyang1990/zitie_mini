#!/bin/bash

# CCPM Utils Library - General utility functions
# Provides miscellaneous helper functions for file operations, text processing, etc.

set -euo pipefail

# =============================================================================
# FILE OPERATIONS
# =============================================================================

# Check if file exists and is readable
file_exists_readable() {
    local file="$1"
    [[ -f "$file" && -r "$file" ]]
}

# Get file size in human readable format
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        if command -v stat >/dev/null 2>&1; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                stat -f%z "$file" | numfmt --to=iec --suffix=B 2>/dev/null || echo "$(stat -f%z "$file")B"
            else
                stat -c%s "$file" | numfmt --to=iec --suffix=B 2>/dev/null || echo "$(stat -c%s "$file")B"
            fi
        else
            local size
            size=$(wc -c < "$file")
            if command -v numfmt >/dev/null 2>&1; then
                echo "$size" | numfmt --to=iec --suffix=B
            else
                echo "${size}B"
            fi
        fi
    else
        echo "0B"
    fi
}

# Create backup of a file
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if [[ -f "$file" ]]; then
        cp "$file" "${file}${backup_suffix}"
        echo "📦 Created backup: ${file}${backup_suffix}"
        return 0
    else
        echo "⚠️ File not found for backup: $file" >&2
        return 1
    fi
}

# =============================================================================
# TEXT PROCESSING
# =============================================================================

# Trim whitespace from string
trim_whitespace() {
    local string="$1"
    echo "$string" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Convert string to lowercase
to_lowercase() {
    local string="$1"
    echo "$string" | tr '[:upper:]' '[:lower:]'
}

# Convert string to uppercase
to_uppercase() {
    local string="$1"
    echo "$string" | tr '[:lower:]' '[:upper:]'
}

# Extract title from markdown file
extract_md_title() {
    local file="$1"
    if [[ -f "$file" ]]; then
        grep "^# " "$file" | head -1 | sed 's/^# //' | trim_whitespace
    fi
}

# Count lines in file
count_lines() {
    local file="$1"
    if [[ -f "$file" ]]; then
        wc -l < "$file" | trim_whitespace
    else
        echo "0"
    fi
}

# =============================================================================
# STRING UTILITIES
# =============================================================================

# Generate random string
generate_random_string() {
    local length="${1:-8}"
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-"$length"
    else
        head /dev/urandom | tr -dc A-Za-z0-9 | head -c "$length"
    fi
}

# Check if string is valid identifier (alphanumeric + underscore/hyphen)
is_valid_identifier() {
    local string="$1"
    [[ "$string" =~ ^[a-zA-Z0-9_-]+$ ]]
}

# Sanitize filename (remove/replace invalid characters)
sanitize_filename() {
    local filename="$1"
    echo "$filename" | tr -d '[:cntrl:]' | tr -s '/' '_' | tr -s ' ' '_'
}

# =============================================================================
# ARRAY UTILITIES
# =============================================================================

# Check if array contains element
array_contains() {
    local element="$1"
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

# Note: array_join function is available in core.sh to avoid duplication

# =============================================================================
# SYSTEM UTILITIES
# =============================================================================

# Get OS type
get_os_type() {
    case "$OSTYPE" in
        linux*) echo "linux" ;;
        darwin*) echo "macos" ;;
        cygwin*) echo "windows" ;;
        msys*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

# Check if running in CI environment
is_ci_environment() {
    [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${TRAVIS:-}" ]] || [[ -n "${JENKINS_URL:-}" ]]
}

# Get available disk space in current directory
get_available_space() {
    local path="${1:-.}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        df -h "$path" | awk 'NR==2 {print $4}'
    else
        df -h "$path" | awk 'NR==2 {print $4}'
    fi
}

# =============================================================================
# URL AND NETWORK UTILITIES
# =============================================================================

# Validate URL format
is_valid_url() {
    local url="$1"
    local regex='^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}([/?].*)?$'
    [[ "$url" =~ $regex ]]
}

# Extract domain from URL
extract_domain() {
    local url="$1"
    echo "$url" | sed -E 's|https?://([^/]+).*|\1|'
}

# Check if network is available
check_network() {
    if command -v curl >/dev/null 2>&1; then
        curl -s --max-time 5 https://httpbin.org/status/200 >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=5 -O /dev/null https://httpbin.org/status/200 >/dev/null 2>&1
    elif command -v ping >/dev/null 2>&1; then
        ping -c 1 8.8.8.8 >/dev/null 2>&1
    else
        return 1
    fi
}

# =============================================================================
# PERFORMANCE UTILITIES
# =============================================================================

# Execute command with timeout
execute_with_timeout() {
    local timeout="$1"
    shift
    local command=("$@")
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout" "${command[@]}"
    else
        # Fallback for systems without timeout command
        "${command[@]}" &
        local pid=$!
        sleep "$timeout" && kill $pid 2>/dev/null &
        local killer_pid=$!
        wait $pid
        local exit_code=$?
        kill $killer_pid 2>/dev/null
        return $exit_code
    fi
}

# =============================================================================
# DEBUGGING UTILITIES
# =============================================================================

# Debug print (only if DEBUG is set)
debug_print() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "🐛 DEBUG: $*" >&2
    fi
}

# Verbose print (only if VERBOSE is set)
verbose_print() {
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        echo "📝 VERBOSE: $*" >&2
    fi
}

# Print stack trace
print_stack_trace() {
    echo "📚 Stack trace:" >&2
    local frame=0
    while caller $frame; do
        ((frame++))
    done | while read -r line; do
        echo "  $line" >&2
    done
}

# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

# Export utility functions
export -f file_exists_readable
export -f get_file_size
export -f backup_file
export -f trim_whitespace
export -f to_lowercase
export -f to_uppercase
export -f extract_md_title
export -f count_lines
export -f generate_random_string
export -f is_valid_identifier
export -f sanitize_filename
export -f array_contains
export -f get_os_type
export -f is_ci_environment
export -f get_available_space
export -f is_valid_url
export -f extract_domain
export -f check_network
export -f execute_with_timeout
export -f debug_print
export -f verbose_print
export -f print_stack_trace