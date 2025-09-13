#!/bin/bash

# Project Search Script - Comprehensive search functionality across all CCPM project artifacts
# Comprehensive search functionality across all CCPM project artifacts including epics, issues, PRDs, and configuration files

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

# Initial Setup and Validation
show_title "🔍 CCPM v2.0 Project Search" 40
echo ""

# Extract search parameters
QUERY="${1:-}"
TYPE="${2:-all}"
SCOPE="${3:-all}"

if [[ -z "$QUERY" ]]; then
  show_error "Missing Search Query" "No search query provided"
  echo ""
  show_info "📋 Usage examples:"
  echo "   /pm:search 'authentication'           # Search everything"
  echo "   /pm:search 'API' epic                 # Search epics only"
  echo "   /pm:search 'bug fix' issue active     # Search active issues"
  echo "   /pm:search 'user story' prd           # Search PRDs"
  exit 1
fi

# Validate project structure
if ! validate_ccpm_structure 2>/dev/null; then
  show_error "Project Not Initialized" "CCPM project not initialized"
  show_tip "Run: /pm:init"
  exit 1
fi

show_info "🎯 Searching for: '$QUERY'"
show_info "📂 Type filter: $TYPE"
show_info "🔍 Scope: $SCOPE"
echo ""

# Built-in Search Implementation
search_results=0
case_insensitive_flag="-i"

show_subtitle "📊 Search Results"

# Function to search and display results
search_files() {
  local search_path="$1"
  local file_pattern="$2"
  local result_type="$3"
  local status_filter="${4:-}"
  
  if [[ ! -d "$search_path" ]]; then
    return 0
  fi
  
  local found_files
  found_files=$(find "$search_path" -name "$file_pattern" 2>/dev/null | head -50)  # Limit results
  
  if [[ -z "$found_files" ]]; then
    return 0
  fi
  
  local section_results=0
  show_info "🔍 $result_type Results:"
  show_separator 30 "-"
  
  while read -r file; do
    if [[ ! -f "$file" ]]; then continue; fi
    
    # Apply status filter for active scope
    if [[ "$SCOPE" == "active" && -n "$status_filter" ]]; then
      if ! grep -q "^status: *$status_filter" "$file" 2>/dev/null; then
        continue
      fi
    fi
    
    # Search for query in file content
    if grep $case_insensitive_flag -l "$QUERY" "$file" >/dev/null 2>&1; then
      ((section_results++))
      ((search_results++))
      
      # Extract metadata
      local file_name
      file_name=$(basename "$file" .md)
      local dir_name
      dir_name=$(dirname "$file" | xargs basename)
      local title
      title=$(grep "^name:" "$file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || \
              grep "^title:" "$file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || \
              echo "$file_name")
      local status
      status=$(grep "^status:" "$file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
      
      # Display result
      echo "📄 $title"
      echo "   File: $file"
      if [[ -n "$status" ]]; then
        echo "   Status: $status"
      fi
      if [[ "$result_type" == "Epic" && "$dir_name" != "epics" ]]; then
        echo "   Epic: $dir_name"
      fi
      
      # Show matching lines with context
      echo "   Matches:"
      if command -v rg >/dev/null 2>&1; then
        rg -i -A 1 -B 1 -n "$QUERY" "$file" 2>/dev/null | head -10 | sed 's/^/     /' || true
      else
        grep $case_insensitive_flag -n -A 1 -B 1 "$QUERY" "$file" 2>/dev/null | head -10 | sed 's/^/     /' || true
      fi
      echo ""
    fi
  done <<< "$found_files"
  
  if [[ "$section_results" -eq 0 ]]; then
    echo "   No matches found"
    echo ""
  fi
  
  return $section_results
}

# Search based on type filter
case "$TYPE" in
  "epic"|"epics")
    search_files ".claude/epics" "*.md" "Epic" "active"
    ;;
  "issue"|"issues"|"task"|"tasks")
    search_files ".claude/epics" "[0-9]*.md" "Issue/Task" "in-progress"
    ;;
  "prd"|"prds")
    search_files ".claude/prds" "*.md" "PRD"
    ;;
  "config"|"configuration")
    search_files ".claude/config" "*.json" "Configuration"
    search_files ".claude" "*.md" "Documentation"
    ;;
  "all"|*)
    show_info "🎯 Comprehensive Search Results"
    echo ""
    
    search_files ".claude/epics" "*.md" "Epic" "active"
    search_files ".claude/epics" "[0-9]*.md" "Issue/Task" "in-progress"  
    search_files ".claude/prds" "*.md" "PRD"
    search_files ".claude/config" "*.json" "Configuration"
    search_files ".claude" "*.md" "Documentation"
    ;;
esac

# Search Summary and Recommendations
echo ""
show_subtitle "📊 Search Summary"
show_info "Query: '$QUERY'"
show_info "Results found: $search_results"
echo ""

if [[ "$search_results" -eq 0 ]]; then
  show_warning "No matches found"
  echo ""
  show_tip "Search tips:"
  echo "   • Try different keywords or synonyms"
  echo "   • Use broader search terms"
  echo "   • Check spelling and try partial matches"
  echo "   • Search specific types: /pm:search '$QUERY' epic"
  echo ""
  show_info "📋 Available content:"
  echo "   • Epics: /pm:epic-list"
  echo "   • Issues: /pm:next"
  echo "   • PRDs: /pm:prd-list"
elif [[ "$search_results" -eq 1 ]]; then
  show_success "Found 1 match"
  echo ""
  show_tip "Related actions:"
  echo "   • View details: /pm:epic-show <name>"
  echo "   • Edit content: \$EDITOR <file-path>"
elif [[ "$search_results" -lt 10 ]]; then
  show_success "Found $search_results matches"
  echo ""
  show_tip "Refine your search:"
  echo "   • Narrow by type: /pm:search '$QUERY' epic"
  echo "   • Filter active only: /pm:search '$QUERY' all active"
else
  show_success "Found $search_results matches"
  echo ""
  show_tip "Too many results? Try:"
  echo "   • More specific keywords"
  echo "   • Filter by type: epic, issue, prd"
  echo "   • Scope to active items only"
fi

echo ""
show_info "🔍 Advanced search options:"
echo "   /pm:search '$QUERY' epic active    # Active epics only"
echo "   /pm:search '$QUERY' issue          # Issues/tasks only"
echo "   /pm:search '$QUERY' prd            # PRDs only"

# Integration with Other Commands
echo ""
show_subtitle "📋 Related Commands"

if [[ "$search_results" -gt 0 ]]; then
  show_info "🔍 Explore results:"
  echo "   /pm:epic-show <epic-name>     # View epic details"
  echo "   /pm:prd-list                  # View PRD list"
  echo ""
  show_info "✏️ Make changes:"
  echo "   \$EDITOR <file-path>          # Edit file directly"
  echo ""
fi

show_info "🚀 Project navigation:"
echo "   /pm:status                    # Project overview"
echo "   /pm:epic-list                 # List all epics"
echo "   /pm:next                      # Find next task"

echo ""
show_completion "Project search completed! Found $search_results matches for '$QUERY'."