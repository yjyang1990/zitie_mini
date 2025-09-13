#!/bin/bash

# CCPM Cache and Temporary File Manager v2.0
# Modern cache management with categorization, compression, and monitoring

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

if [[ -f "$LIB_DIR/caching.sh" ]]; then
    source "$LIB_DIR/caching.sh"
fi

# Configuration
CACHE_CONFIG=".claude/tmp/cache-config.json"
CACHE_ROOT=".claude/tmp/cache"
TEMP_ROOT=".claude/tmp/temp"
LOGS_ROOT=".claude/logs"
USAGE_LOG="$LOGS_ROOT/cache-usage.log"

# Function to show usage
show_usage() {
    show_command_help "cache-manager" "Advanced CCPM cache management" \
        "cache-manager [COMMAND] [OPTIONS]           # Manage cache system
cache-manager init                              # Initialize cache system
cache-manager stats                             # Show cache statistics
cache-manager clear [category]                  # Clear cache entries
cache-manager cleanup [hours]                   # Clean expired entries
cache-manager cache <cat> <key> <content>       # Store cache item
cache-manager get <category> <key>              # Retrieve cache item"
    
    echo ""
    echo "Commands:"
    echo "  init                       Initialize cache system with categories"
    echo "  stats                      Show detailed cache statistics"
    echo "  clear [category]           Clear all cache or specific category"
    echo "  cleanup [hours]            Remove expired cache entries (default: 24h)"
    echo "  cleanup-temp [hours]       Remove old temporary files (default: 24h)"
    echo "  cache <cat> <key> <data>   Store item in cache with TTL"
    echo "  get <category> <key>       Retrieve cached item if not expired"
    echo "  monitor                    Show cache usage monitoring"
    echo "  help                       Show this help message"
    echo ""
    echo "Examples:"
    echo "  cache-manager init                       # Setup cache system"
    echo "  cache-manager stats                      # View cache overview"
    echo "  cache-manager clear general              # Clear general category"
    echo "  cache-manager cleanup 48                 # Remove 48h old entries"
    echo "  cache-manager cache github issues '...'  # Store GitHub data"
    echo "  cache-manager get github issues          # Retrieve cached data"
}

# Initialize cache system
init_cache_system() {
    show_title "🔧 CCPM Cache System Initialization" 45
    
    # Load or create configuration
    if [[ ! -f "$CACHE_CONFIG" ]]; then
        show_info "Creating default cache configuration..."
        create_default_cache_config
    else
        show_success "Configuration Found" "$CACHE_CONFIG"
    fi
    
    # Create cache directories
    local categories
    categories=$(jq -r '.cache_categories | keys[]' "$CACHE_CONFIG" 2>/dev/null || echo "general")
    
    ensure_directory "$CACHE_ROOT"
    ensure_directory "$TEMP_ROOT"
    ensure_directory "$LOGS_ROOT"
    
    show_subtitle "📁 Creating Cache Categories"
    local category_count=0
    while IFS= read -r category; do
        ensure_directory "$CACHE_ROOT/$category"
        show_info "✓ Created category: $category"
        ((category_count++))
    done <<< "$categories"
    
    show_success "Cache System" "Initialized with $category_count categories"
    show_info "Configuration: $CACHE_CONFIG"
    show_info "Cache Root: $CACHE_ROOT"
    show_info "Logs: $USAGE_LOG"
}

# Create default cache configuration
create_default_cache_config() {
    local config_dir
    config_dir=$(dirname "$CACHE_CONFIG")
    ensure_directory "$config_dir"
    
    cat > "$CACHE_CONFIG" << 'EOF'
{
  "version": "2.0",
  "cache_settings": {
    "enabled": true,
    "default_ttl_hours": 24,
    "max_cache_size_mb": 100,
    "compression_enabled": true
  },
  "cache_categories": {
    "general": {
      "ttl_hours": 24,
      "max_size_mb": 50,
      "compress": true,
      "priority": "medium"
    },
    "github": {
      "ttl_hours": 1,
      "max_size_mb": 20,
      "compress": true,
      "priority": "high"
    },
    "epic": {
      "ttl_hours": 6,
      "max_size_mb": 10,
      "compress": false,
      "priority": "high"
    },
    "task": {
      "ttl_hours": 2,
      "max_size_mb": 15,
      "compress": false,
      "priority": "high"
    }
  },
  "tmp_file_settings": {
    "preserve_patterns": [
      "*.lock",
      "cache-config.json"
    ]
  }
}
EOF
}

# Get enhanced cache statistics
get_cache_stats() {
    show_title "📊 CCPM Cache Statistics" 40
    
    if [[ ! -d "$CACHE_ROOT" ]]; then
        show_error "Cache Directory Missing" "Cache not initialized"
        show_tip "Run 'cache-manager init' to initialize cache system"
        return 1
    fi
    
    # Overall statistics
    local total_size_kb total_files
    if command -v du >/dev/null 2>&1; then
        total_size_kb=$(du -sk "$CACHE_ROOT" 2>/dev/null | cut -f1 || echo 0)
    else
        total_size_kb=0
    fi
    
    total_files=$(find "$CACHE_ROOT" -type f 2>/dev/null | wc -l || echo 0)
    local total_size_mb=$((total_size_kb / 1024))
    
    show_subtitle "📈 Overall Cache Usage"
    echo "  Total Size: ${total_size_mb}MB (${total_size_kb}KB)"
    echo "  Total Files: $total_files"
    echo ""
    
    # Category statistics
    if [[ -f "$CACHE_CONFIG" ]]; then
        local categories
        categories=$(jq -r '.cache_categories | keys[]' "$CACHE_CONFIG" 2>/dev/null || echo "")
        
        if [[ -n "$categories" ]]; then
            show_subtitle "📂 Cache Categories"
            while IFS= read -r category; do
                local category_path="$CACHE_ROOT/$category"
                if [[ -d "$category_path" ]]; then
                    local cat_size_kb cat_files
                    if command -v du >/dev/null 2>&1; then
                        cat_size_kb=$(du -sk "$category_path" 2>/dev/null | cut -f1 || echo 0)
                    else
                        cat_size_kb=0
                    fi
                    cat_files=$(find "$category_path" -type f 2>/dev/null | wc -l || echo 0)
                    local cat_size_mb=$((cat_size_kb / 1024))
                    
                    local ttl priority
                    ttl=$(jq -r ".cache_categories.\"$category\".ttl_hours" "$CACHE_CONFIG" 2>/dev/null || echo "unknown")
                    priority=$(jq -r ".cache_categories.\"$category\".priority" "$CACHE_CONFIG" 2>/dev/null || echo "unknown")
                    
                    echo "  $category: ${cat_size_mb}MB, $cat_files files (TTL: ${ttl}h, Priority: $priority)"
                fi
            done <<< "$categories"
        fi
    fi
    
    echo ""
    
    # Temporary files statistics
    if [[ -d "$TEMP_ROOT" ]]; then
        local temp_size_kb temp_files
        if command -v du >/dev/null 2>&1; then
            temp_size_kb=$(du -sk "$TEMP_ROOT" 2>/dev/null | cut -f1 || echo 0)
        else
            temp_size_kb=0
        fi
        temp_files=$(find "$TEMP_ROOT" -type f 2>/dev/null | wc -l || echo 0)
        local temp_size_mb=$((temp_size_kb / 1024))
        
        show_subtitle "📄 Temporary Files"
        echo "  Size: ${temp_size_mb}MB"
        echo "  Files: $temp_files"
    fi
}

# Clear cache by category
clear_cache_category() {
    local category="$1"
    local category_path="$CACHE_ROOT/$category"
    
    if [[ ! -d "$category_path" ]]; then
        show_error "Category Not Found" "Cache category '$category' does not exist"
        return 1
    fi
    
    show_info "Clearing cache category: $category"
    
    local files_removed
    files_removed=$(find "$category_path" -type f | wc -l)
    
    rm -rf "$category_path"/*
    
    show_success "Category Cleared" "$files_removed files removed from $category"
    log_cache_action "clear_category" "$category" "$files_removed"
}

# Clear all cache
clear_all_cache() {
    show_warning "Clearing All Cache" "This will remove all cached data"
    
    if [[ ! -d "$CACHE_ROOT" ]]; then
        show_error "Cache Directory Missing" "$CACHE_ROOT not found"
        return 1
    fi
    
    local total_files
    total_files=$(find "$CACHE_ROOT" -type f 2>/dev/null | wc -l || echo 0)
    
    rm -rf "$CACHE_ROOT"/*
    
    show_success "All Cache Cleared" "$total_files files removed"
    log_cache_action "clear_all" "all" "$total_files"
}

# Cleanup expired cache entries
cleanup_expired_cache() {
    local max_age_hours="${1:-24}"
    
    show_info "Cleaning cache entries older than $max_age_hours hours..."
    
    if [[ ! -d "$CACHE_ROOT" ]]; then
        show_error "Cache Directory Missing" "$CACHE_ROOT not found"
        return 1
    fi
    
    local removed_count=0
    
    # Find and remove files older than specified hours
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            # Also remove metadata file if exists
            [[ -f "${file}.meta" ]] && rm -f "${file}.meta"
            ((removed_count++))
        fi
    done < <(find "$CACHE_ROOT" -type f -name "*.json" -not -name "*.meta" -mmin "+$((max_age_hours * 60))" 2>/dev/null || true)
    
    show_success "Cleanup Complete" "Removed $removed_count expired entries"
    log_cache_action "cleanup_expired" "all" "$removed_count"
}

# Cleanup temporary files
cleanup_temp_files() {
    local max_age_hours="${1:-24}"
    
    show_info "Cleaning temporary files older than $max_age_hours hours..."
    
    if [[ ! -d "$TEMP_ROOT" ]]; then
        show_warning "No temporary directory found"
        return 0
    fi
    
    local removed_count=0
    
    # Find and remove temp files older than specified hours
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            # Check if file should be preserved
            local preserve=false
            if [[ -f "$CACHE_CONFIG" ]]; then
                local preserve_patterns
                preserve_patterns=$(jq -r '.tmp_file_settings.preserve_patterns[]?' "$CACHE_CONFIG" 2>/dev/null || echo "")
                
                if [[ -n "$preserve_patterns" ]]; then
                    while IFS= read -r pattern; do
                        if [[ "$(basename "$file")" == $pattern ]]; then
                            preserve=true
                            break
                        fi
                    done <<< "$preserve_patterns"
                fi
            fi
            
            if [[ "$preserve" == "false" ]]; then
                rm -f "$file"
                ((removed_count++))
            fi
        fi
    done < <(find "$TEMP_ROOT" -type f -mmin "+$((max_age_hours * 60))" 2>/dev/null || true)
    
    show_success "Temp Cleanup" "Removed $removed_count temporary files"
    log_cache_action "cleanup_temp" "temp" "$removed_count"
}

# Log cache actions
log_cache_action() {
    local action="$1"
    local target="$2"
    local count="$3"
    
    local timestamp
    timestamp=$(format_timestamp)
    
    ensure_directory "$(dirname "$USAGE_LOG")"
    echo "[$timestamp] $action: $target ($count files)" >> "$USAGE_LOG"
}

# Cache item by category with metadata
cache_item() {
    local category="$1"
    local key="$2"
    local content="$3"
    local ttl_hours="${4:-}"
    
    # Use default TTL if not specified
    if [[ -z "$ttl_hours" ]] && [[ -f "$CACHE_CONFIG" ]]; then
        ttl_hours=$(jq -r ".cache_categories.\"$category\".ttl_hours // .cache_settings.default_ttl_hours" "$CACHE_CONFIG" 2>/dev/null || echo "24")
    fi
    ttl_hours="${ttl_hours:-24}"
    
    local category_path="$CACHE_ROOT/$category"
    ensure_directory "$category_path"
    
    local cache_file="$category_path/${key}.json"
    local metadata_file="$category_path/${key}.meta"
    
    # Store content
    echo "$content" > "$cache_file"
    
    # Store metadata with expiry timestamp
    local expiry_timestamp
    expiry_timestamp=$(date -d "+${ttl_hours} hours" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || 
                      date -v "+${ttl_hours}H" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || 
                      echo "")
    
    if command -v jq >/dev/null 2>&1; then
        jq -n \
            --arg key "$key" \
            --arg category "$category" \
            --arg created "$(format_timestamp)" \
            --arg expires "$expiry_timestamp" \
            --argjson ttl_hours "$ttl_hours" \
            '{
                key: $key,
                category: $category,
                created: $created,
                expires: $expires,
                ttl_hours: $ttl_hours
            }' > "$metadata_file"
    fi
    
    show_success "Item Cached" "$category/$key (TTL: ${ttl_hours}h)"
    log_cache_action "cache_item" "$category/$key" "1"
}

# Retrieve cached item with expiry check
get_cached_item() {
    local category="$1"
    local key="$2"
    
    local cache_file="$CACHE_ROOT/$category/${key}.json"
    local metadata_file="$CACHE_ROOT/$category/${key}.meta"
    
    if [[ ! -f "$cache_file" ]]; then
        show_warning "Cache Miss" "Item $category/$key not found"
        return 1
    fi
    
    # Check if expired using metadata
    if [[ -f "$metadata_file" ]] && command -v jq >/dev/null 2>&1; then
        local expires
        expires=$(jq -r '.expires' "$metadata_file" 2>/dev/null || echo "")
        
        if [[ -n "$expires" ]]; then
            local current_timestamp expires_timestamp
            current_timestamp=$(date -u +%s 2>/dev/null || echo 0)
            expires_timestamp=$(date -d "$expires" -u +%s 2>/dev/null || 
                              date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires" +%s 2>/dev/null || 
                              echo 0)
            
            if [[ $current_timestamp -gt $expires_timestamp ]]; then
                # Expired, remove files
                rm -f "$cache_file" "$metadata_file"
                show_warning "Cache Expired" "Item $category/$key has expired"
                return 1
            fi
        fi
    fi
    
    # Return cached content
    cat "$cache_file"
    return 0
}

# Monitor cache usage with analytics
monitor_cache() {
    show_title "📈 CCPM Cache Monitoring" 40
    
    if [[ ! -f "$USAGE_LOG" ]]; then
        show_warning "No Usage Log" "Cache monitoring log not found"
        return 0
    fi
    
    show_subtitle "📊 Recent Activity"
    echo "Last 10 cache operations:"
    tail -10 "$USAGE_LOG"
    
    echo ""
    show_subtitle "📈 Operation Summary"
    if command -v awk >/dev/null 2>&1; then
        awk -F': ' '{
            gsub(/^\[.*\] /, "", $1)
            count[$1]++
        } 
        END {
            for (action in count) {
                print "  " action ": " count[action] " times"
            }
        }' "$USAGE_LOG"
    fi
}

# Parse command and execute
COMMAND="${1:-help}"

case "$COMMAND" in
    "init")
        init_cache_system
        ;;
    "stats")
        get_cache_stats
        ;;
    "clear")
        if [[ -n "${2:-}" ]]; then
            clear_cache_category "$2"
        else
            clear_all_cache
        fi
        ;;
    "cleanup")
        cleanup_expired_cache "${2:-24}"
        ;;
    "cleanup-temp")
        cleanup_temp_files "${2:-24}"
        ;;
    "cache")
        if [[ $# -lt 4 ]]; then
            show_error "Invalid Arguments" "Usage: cache-manager cache <category> <key> <content> [ttl_hours]"
            exit 1
        fi
        cache_item "$2" "$3" "$4" "${5:-}"
        ;;
    "get")
        if [[ $# -lt 3 ]]; then
            show_error "Invalid Arguments" "Usage: cache-manager get <category> <key>"
            exit 1
        fi
        if get_cached_item "$2" "$3"; then
            exit 0
        else
            exit 1
        fi
        ;;
    "monitor")
        monitor_cache
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