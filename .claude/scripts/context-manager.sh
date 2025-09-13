#!/bin/bash

# CCPM Context Manager v2.0 - Project Context Management
# Simple and focused context management for project sessions

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
CONTEXT_DIR=".claude/context"
CONTEXT_FILE="$CONTEXT_DIR/project-overview.md"
SESSION_FILE="$CONTEXT_DIR/session-context.md"

# Function to show usage
show_usage() {
    show_command_help "context-manager" "Manage project context sessions" \
        "context-manager [COMMAND] [OPTIONS]         # Manage context
context-manager create                          # Generate project overview
context-manager prime                           # Load session context
context-manager update                          # Refresh context data
context-manager cleanup                         # Clear context files
context-manager session                         # Show session details"
    
    echo ""
    echo "Commands:"
    echo "  create     Generate comprehensive project context overview"
    echo "  prime      Load context for new session (display overview)"
    echo "  update     Refresh project context with latest data"
    echo "  session    Generate and show current session context"
    echo "  cleanup    Clear all generated context files"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  context-manager create              # Generate project overview"
    echo "  context-manager prime               # Display context for session"
    echo "  context-manager update              # Refresh with latest data"
    echo "  context-manager session             # Show session-specific context"
}

# Detect project type with enhanced detection
detect_project_type() {
    local project_types=()
    
    # Check for various project indicators
    [[ -f "package.json" ]] && project_types+=("Node.js/JavaScript")
    [[ -f "requirements.txt" || -f "pyproject.toml" || -f "setup.py" ]] && project_types+=("Python")
    [[ -f "Cargo.toml" ]] && project_types+=("Rust")
    [[ -f "go.mod" ]] && project_types+=("Go")
    [[ -f "composer.json" ]] && project_types+=("PHP")
    [[ -f "pom.xml" || -f "build.gradle" ]] && project_types+=("Java")
    [[ -f ".claude/CLAUDE.md" ]] && project_types+=("Claude Code Project")
    [[ -f "Dockerfile" ]] && project_types+=("Docker")
    
    if [[ ${#project_types[@]} -eq 0 ]]; then
        echo "General"
    else
        # Join array elements with " + "
        local IFS=" + "
        echo "${project_types[*]}"
    fi
}

# Get comprehensive project metrics
get_project_metrics() {
    local scripts_count=0 epics_count=0 tests_count=0 commands_count=0 agents_count=0
    
    # Count CCPM components
    [[ -d ".claude/scripts" ]] && scripts_count=$(find .claude/scripts -name "*.sh" 2>/dev/null | wc -l || echo "0")
    [[ -d ".claude/epics" ]] && epics_count=$(find .claude/epics -name "*.md" 2>/dev/null | wc -l || echo "0")
    [[ -d ".claude/commands" ]] && commands_count=$(find .claude/commands -name "*.md" 2>/dev/null | wc -l || echo "0")
    [[ -d ".claude/agents" ]] && agents_count=$(find .claude/agents -name "*.md" 2>/dev/null | wc -l || echo "0")
    
    # Count test files
    if [[ -d "tests" ]]; then
        tests_count=$(find tests -name "*.bats" -o -name "*test*" 2>/dev/null | wc -l || echo "0")
    fi
    
    echo "$scripts_count,$epics_count,$tests_count,$commands_count,$agents_count"
}

# Get git repository status
get_git_status() {
    if ! command -v git >/dev/null 2>&1 || ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "No git repository"
        return
    fi
    
    local branch status
    branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    
    # Check for uncommitted changes
    if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
        status="clean"
    else
        status="uncommitted changes"
    fi
    
    echo "Branch: $branch ($status)"
}

# Get project file structure overview
get_structure_overview() {
    local structure=""
    
    # Check for key directories and files
    [[ -d ".claude" ]] && structure+="- 🔧 Claude Code project (.claude/ directory)\\n"
    [[ -f "README.md" ]] && structure+="- 📖 README.md present\\n"
    [[ -d "tests" ]] && structure+="- 🧪 Test directory exists\\n"
    [[ -f ".gitignore" ]] && structure+="- 📝 .gitignore configured\\n"
    [[ -f "package.json" ]] && structure+="- 📦 Node.js package.json\\n"
    [[ -f "requirements.txt" ]] && structure+="- 🐍 Python requirements.txt\\n"
    [[ -f "Cargo.toml" ]] && structure+="- 🦀 Rust Cargo.toml\\n"
    [[ -f "go.mod" ]] && structure+="- 🐹 Go module definition\\n"
    [[ -f "Dockerfile" ]] && structure+="- 🐳 Docker configuration\\n"
    
    if [[ -n "$structure" ]]; then
        echo -e "$structure"
    else
        echo "- Basic project structure"
    fi
}

# Create comprehensive project context
create_context() {
    show_title "📝 CCPM Context Generation" 40
    
    ensure_directory "$CONTEXT_DIR"
    
    local project_type metrics git_status
    local scripts_count epics_count tests_count commands_count agents_count
    
    show_progress "Analyzing project structure..."
    project_type=$(detect_project_type)
    metrics=$(get_project_metrics)
    IFS=',' read -r scripts_count epics_count tests_count commands_count agents_count <<< "$metrics"
    git_status=$(get_git_status)
    
    show_progress "Generating context overview..."
    
    cat > "$CONTEXT_FILE" << EOF
# Project Context Overview

**Project Type**: $project_type  
**Generated**: $(format_timestamp)  
**Location**: $(pwd)  
**Git Status**: $git_status

## CCPM Framework Statistics
- Scripts: $scripts_count
- Epics: $epics_count  
- Commands: $commands_count
- Agents: $agents_count
- Tests: $tests_count

## Project Structure
$(get_structure_overview)

## Recent Git Activity
$(if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Recent commits:"
    git log --oneline -5 --no-merges 2>/dev/null | sed 's/^/  /' || echo "  No git history"
else
    echo "No git repository found"
fi)

## Active Epics
$(if [[ -d ".claude/epics" ]] && [[ $epics_count -gt 0 ]]; then
    echo "Current epic status:"
    find .claude/epics -name "epic.md" 2>/dev/null | head -5 | while read -r epic_file; do
        epic_dir=$(dirname "$epic_file")
        epic_name=$(basename "$epic_dir")
        task_count=$(find "$epic_dir" -name "[0-9]*.md" 2>/dev/null | wc -l)
        echo "  - $epic_name: $task_count tasks"
    done
else
    echo "No active epics found"
fi)

## Quick Commands
- \`/pm:status\` - Show project status dashboard
- \`/pm:next\` - Find next available tasks  
- \`/pm:epic-list\` - List all epics
- \`cache-manager stats\` - Show cache statistics
- \`validate\` - Validate project integrity

---
*Auto-generated by CCPM Context Manager v2.0*
EOF
    
    show_success "Context Created" "$CONTEXT_FILE"
}

# Generate session-specific context
create_session_context() {
    show_subtitle "📊 Session Context Generation"
    
    ensure_directory "$CONTEXT_DIR"
    
    local session_start cache_status recent_activity
    session_start=$(format_timestamp)
    
    # Check cache status
    if [[ -d ".claude/tmp/cache" ]]; then
        cache_status="Available"
    else
        cache_status="Not initialized"
    fi
    
    cat > "$SESSION_FILE" << EOF
# Session Context

**Session Started**: $session_start  
**Working Directory**: $(pwd)  
**Cache Status**: $cache_status

## Environment Check
- Git: $(command -v git >/dev/null 2>&1 && echo "✓ Available" || echo "✗ Not found")
- jq: $(command -v jq >/dev/null 2>&1 && echo "✓ Available" || echo "✗ Not found")
- GitHub CLI: $(command -v gh >/dev/null 2>&1 && echo "✓ Available" || echo "✗ Not found")

## Recently Modified Files
$(find . -name "*.md" -o -name "*.sh" -o -name "*.json" -not -path "./.git/*" -not -path "./node_modules/*" \
  -mtime -1 2>/dev/null | head -10 | sed 's/^/  /' || echo "  No recent modifications")

## Recommended Actions
- Run \`/pm:status\` to see project dashboard
- Use \`cache-manager init\` to setup caching
- Check \`validate --quick\` for project health

---
*Session context for $(basename "$(pwd)") project*
EOF
    
    show_success "Session Context" "$SESSION_FILE"
}

# Prime context for new session
prime_context() {
    show_title "🚀 CCPM Session Context" 40
    
    if [[ ! -f "$CONTEXT_FILE" ]]; then
        show_info "No context file found, generating..."
        create_context
    fi
    
    show_subtitle "📋 Project Overview"
    cat "$CONTEXT_FILE"
    
    echo ""
    show_subtitle "🎯 Session Information"
    create_session_context
    cat "$SESSION_FILE"
}

# Update context with latest data
update_context() {
    show_title "♻️ CCPM Context Update" 40
    
    if [[ -f "$CONTEXT_FILE" ]]; then
        show_info "Refreshing existing context..."
        create_context
    else
        show_info "No context to update, creating new..."
        create_context
    fi
    
    # Also update session context
    create_session_context
    
    show_success "Context Updated" "Project and session context refreshed"
}

# Cleanup context files
cleanup_context() {
    show_title "🧹 CCPM Context Cleanup" 40
    
    local removed_count=0
    
    if [[ -f "$CONTEXT_FILE" ]]; then
        rm "$CONTEXT_FILE"
        ((removed_count++))
        show_info "✓ Removed project context"
    fi
    
    if [[ -f "$SESSION_FILE" ]]; then
        rm "$SESSION_FILE"
        ((removed_count++))
        show_info "✓ Removed session context"
    fi
    
    if [[ $removed_count -gt 0 ]]; then
        show_success "Cleanup Complete" "Removed $removed_count context files"
    else
        show_info "No context files to remove"
    fi
}

# Show session details
show_session() {
    show_title "📊 CCPM Session Details" 40
    
    if [[ -f "$SESSION_FILE" ]]; then
        cat "$SESSION_FILE"
    else
        show_info "No session context found, generating..."
        create_session_context
        cat "$SESSION_FILE"
    fi
}

# Parse command and execute
COMMAND="${1:-help}"

case "$COMMAND" in
    "create")
        create_context
        ;;
    "prime")
        prime_context
        ;;
    "update")
        update_context
        ;;
    "session")
        show_session
        ;;
    "cleanup")
        cleanup_context
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