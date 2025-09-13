#!/bin/bash
# CCPM Intelligent Workflow Suggestion System

# Import common functions
source "$(dirname "${BASH_SOURCE[0]}")/common-functions.sh"
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/ux.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/ux.sh"
else
    # Fallback functions if ux.sh doesn't exist
    print_section() { echo "--- $1 ---"; }
    print_subsection() { echo "* $1"; }
    show_next_steps() { echo "Next steps:"; for step in "$@"; do echo "  - $step"; done; }
    show_tip() { echo "💡 Tip: $1"; }
fi

# Analyze current project status and provide intelligent suggestions
suggest_smart_next_actions() {
    local command_context="$1"
    local current_dir="$(pwd)"
    
    echo ""
    print_section "🤖 Smart Suggestions"
    
    # Detect project status
    local has_prds=$(find .claude/prds -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    local has_epics=$(find .claude/epics -maxdepth 1 -type d 2>/dev/null | grep -v "^\.claude/epics$" | wc -l | tr -d ' ')
    local open_issues=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l | tr -d ' ')
    
    # Detect GitHub sync status
    local synced_issues=0
    if command -v gh >/dev/null 2>&1; then
        synced_issues=$(gh issue list --limit 100 --label "pm:*" 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # Provide suggestions based on current status
    case "$command_context" in
        "prd-new")
            suggest_after_prd_creation
            ;;
        "prd-parse") 
            suggest_after_prd_parse
            ;;
        "epic-decompose")
            suggest_after_epic_decompose
            ;;
        "epic-sync"|"epic-oneshot")
            suggest_after_github_sync
            ;;
        "issue-start")
            suggest_during_development
            ;;
        *)
            suggest_general_workflow "$has_prds" "$has_epics" "$open_issues" "$synced_issues"
            ;;
    esac
    
    # Show overall project status
    show_project_health_summary
}

# Suggestions after PRD creation
suggest_after_prd_creation() {
    show_next_steps \
        "📋 Review and refine PRD content" \
        "🔧 /pm:prd-parse <name> - Convert to technical implementation plan" \
        "📊 /pm:prd-status - View all PRD statuses"
}

# Suggestions after PRD parsing
suggest_after_prd_parse() {
    show_next_steps \
        "📖 Review generated Epic plan" \
        "⚡ /pm:epic-decompose <name> - Break down into specific tasks" \
        "🚀 /pm:epic-oneshot <name> - One-click decompose and sync to GitHub"
}

# Suggestions after Epic decomposition
suggest_after_epic_decompose() {
    show_next_steps \
        "📋 Check if task breakdown is reasonable" \
        "🔄 /pm:epic-sync <name> - Sync to GitHub Issues" \
        "👀 /pm:epic-show <name> - View complete Epic structure"
}

# Suggestions after GitHub sync
suggest_after_github_sync() {
    show_next_steps \
        "🚀 /pm:issue-start <issue-id> - Start development task" \
        "🎯 /pm:next - Get recommended next task" \
        "📊 /pm:status - View overall project progress"
}

# Suggestions during development
suggest_during_development() {
    show_next_steps \
        "💾 Commit code progress regularly" \
        "🔄 /pm:issue-sync <issue-id> - Sync progress to GitHub" \
        "✅ Run tests for verification after completion"
}

# General workflow suggestions
suggest_general_workflow() {
    local has_prds="$1"
    local has_epics="$2"  
    local open_issues="$3"
    local synced_issues="$4"
    
    if [[ "$has_prds" -eq 0 ]]; then
        show_tip "🚀 Start your first project: /pm:prd-new <feature-name>"
        
    elif [[ "$has_epics" -eq 0 ]]; then
        echo "📋 Found $has_prds PRDs, suggested next step:"
        show_next_steps \
            "/pm:prd-list - View all PRDs" \
            "/pm:prd-parse <name> - Choose a PRD to start implementation"
            
    elif [[ "$open_issues" -eq 0 ]]; then
        echo "📐 Found $has_epics Epics, suggested next step:"
        show_next_steps \
            "/pm:epic-list - View all Epics" \
            "/pm:epic-decompose <name> - Decompose Epic into tasks"
            
    elif [[ "$synced_issues" -eq 0 ]]; then
        echo "⚡ Found $open_issues pending tasks, suggest syncing to GitHub:"
        show_next_steps \
            "/pm:epic-sync <name> - Sync specific Epic" \
            "/pm:sync - Full sync of all content"
            
    else
        echo "🎯 Project running, suggested next step:"
        show_next_steps \
            "/pm:next - Get recommended tasks" \
            "/pm:status - View project dashboard" \
            "/pm:standup - Generate progress report"
    fi
}

# Show project health status summary
show_project_health_summary() {
    echo ""
    print_subsection "📊 Project Status Overview"
    
    local prd_count=$(find .claude/prds -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    local epic_count=$(find .claude/epics -maxdepth 1 -type d 2>/dev/null | grep -v "^\.claude/epics$" | wc -l | tr -d ' ')
    local task_count=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l | tr -d ' ')
    
    echo "📋 PRD: $prd_count | 📐 Epic: $epic_count | ⚡ Tasks: $task_count"
    
    if command -v gh >/dev/null 2>&1; then
        local github_issues=$(gh issue list --limit 100 --label "pm:*" 2>/dev/null | wc -l | tr -d ' ')
        echo "🔗 GitHub Issues: $github_issues"
    fi
    
    echo ""
    echo "💡 Tip: Use /pm:help to view complete command list"
}

# Check workflow integrity and provide repair suggestions
check_workflow_integrity() {
    local issues_found=0
    
    print_section "🔍 Workflow Integrity Check"
    
    # Check isolated PRDs (have PRD but no corresponding Epic)
    for prd in .claude/prds/*.md 2>/dev/null; do
        if [[ -f "$prd" ]]; then
            local prd_name=$(basename "$prd" .md)
            if [[ ! -d ".claude/epics/$prd_name" ]]; then
                echo "⚠️  Found isolated PRD: $prd_name (suggest running: /pm:prd-parse $prd_name)"
                ((issues_found++))
            fi
        fi
    done
    
    # Check empty Epics (have directory but no task files)
    for epic_dir in .claude/epics/*/; do
        if [[ -d "$epic_dir" ]]; then
            local epic_name=$(basename "$epic_dir")
            local task_count=$(find "$epic_dir" -name "[0-9]*.md" 2>/dev/null | wc -l)
            if [[ "$task_count" -eq 0 ]]; then
                echo "⚠️  Found empty Epic: $epic_name (suggest running: /pm:epic-decompose $epic_name)"
                ((issues_found++))
            fi
        fi
    done
    
    if [[ "$issues_found" -eq 0 ]]; then
        echo "✅ Workflow integrity is good"
    else
        echo ""
        echo "🔧 Found $issues_found issues, suggest using above commands to fix"
    fi
}

# Export functions
export -f suggest_smart_next_actions
export -f suggest_after_prd_creation
export -f suggest_after_prd_parse
export -f suggest_after_epic_decompose
export -f suggest_after_github_sync
export -f suggest_during_development
export -f suggest_general_workflow
export -f show_project_health_summary
export -f check_workflow_integrity