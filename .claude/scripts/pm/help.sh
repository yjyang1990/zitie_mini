#!/bin/bash

# PM Help Script - Context-Aware Dynamic Help System
# Provides intelligent help based on project state and user needs

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

if [[ -f "$LIB_DIR/formatting.sh" ]]; then
    source "$LIB_DIR/formatting.sh"
fi

# Default configuration
HELP_TOPIC=""
SHOW_WORKFLOW=false
SHOW_TROUBLESHOOTING=false
COMMANDS_DIR=".claude/commands/pm"

# Function to show usage
show_usage() {
    show_command_help "/pm:help" "Context-aware help system with intelligent guidance" \
        "/pm:help                    # Context-aware help
/pm:help prd-new            # Help for prd-new command
/pm:help workflow           # Workflow guidance
/pm:help troubleshooting    # Troubleshooting guide"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    workflow|guide|getting-started)
      HELP_TOPIC="workflow"
      SHOW_WORKFLOW=true
      shift
      ;;
    troubleshooting|issues|problems)
      HELP_TOPIC="troubleshooting"
      SHOW_TROUBLESHOOTING=true
      shift
      ;;
    --help)
      show_usage
      ;;
    -*)
      show_error "Unknown Option" "Unknown option: $1"
      show_usage
      ;;
    *)
      # Assume it's a command name
      HELP_TOPIC="$1"
      shift
      ;;
  esac
done

# Function to analyze project state
analyze_project_state() {
    local state="new"
    
    # Check for PRDs
    if [[ -d ".claude/prds" ]] && [[ $(ls -1 .claude/prds/*.md 2>/dev/null | wc -l) -gt 0 ]]; then
        state="has_prds"
        
        # Check for epics
        if [[ -d ".claude/epics" ]] && [[ $(find .claude/epics -maxdepth 1 -name "*.md" 2>/dev/null | wc -l) -gt 0 ]]; then
            state="has_epics"
            
            # Check for tasks
            if [[ $(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l) -gt 0 ]]; then
                state="has_tasks"
                
                # Check for active work
                if [[ $(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *in-progress" {} \; 2>/dev/null | wc -l) -gt 0 ]]; then
                    state="active_work"
                fi
            fi
        fi
    fi
    
    echo "$state"
}

# Function to show context-aware suggestions
show_context_suggestions() {
    local state="$1"
    
    show_subtitle "🎯 Suggested Next Steps"
    
    case "$state" in
        new)
            show_info "🚀 Start your first project:"
            echo "      /pm:init                    # Initialize project structure"
            echo "      /pm:prd-new <feature-name>  # Create first PRD"
            echo ""
            show_info "📋 Or import existing work:"
            echo "      /pm:import <github-issue>   # Import from GitHub"
            ;;
        has_prds)
            show_info "📋 Convert PRDs to actionable epics:"
            local prds
            prds=$(ls -1 .claude/prds/*.md 2>/dev/null | head -3 | xargs -I {} basename {} .md)
            for prd in $prds; do
                echo "      /pm:prd-parse $prd          # Convert PRD to epic"
            done
            echo "      /pm:prd-list                # View all PRDs"
            ;;
        has_epics)
            show_info "⚡ Break down epics into tasks:"
            local epics
            epics=$(find .claude/epics -maxdepth 1 -type d -name "[!.]*" 2>/dev/null | head -3 | xargs -I {} basename {})
            for epic in $epics; do
                echo "      /pm:epic-decompose $epic    # Break into tasks"
            done
            echo "      /pm:epic-list               # View all epics"
            ;;
        has_tasks)
            show_info "🔗 Sync to GitHub and start development:"
            local epics
            epics=$(find .claude/epics -maxdepth 1 -type d -name "[!.]*" 2>/dev/null | head -3 | xargs -I {} basename {})
            for epic in $epics; do
                echo "      /pm:epic-sync $epic         # Push to GitHub"
            done
            echo "      /pm:next                    # Find next task"
            echo "      /pm:auto                    # Auto-start best task"
            ;;
        active_work)
            show_info "📈 Continue development:"
            echo "      /pm:status                  # Project dashboard"
            echo "      /pm:standup                 # Daily standup"
            echo "      /pm:next                    # Next available task"
            echo "      /pm:blocked                 # Review blockers"
            ;;
    esac
    echo ""
}

# Function to show specific command help
show_command_help_detailed() {
    local command="$1"
    local command_file="$COMMANDS_DIR/$command.md"
    
    if [[ -f "$command_file" ]]; then
        show_subtitle "📚 Help: /pm:$command"
        
        # Extract description from frontmatter
        local description
        description=$(grep "^description:" "$command_file" 2>/dev/null | sed 's/^description: *//' || echo "")
        if [[ -n "$description" ]]; then
            show_info "$description"
            echo ""
        fi
        
        # Show usage section
        if grep -q "## Usage" "$command_file" 2>/dev/null; then
            show_info "## Usage"
            sed -n '/## Usage/,/## /p' "$command_file" | sed '1d;$d' | sed '/^$/d'
            echo ""
        fi
        
        # Show examples if available
        if grep -q -i "example" "$command_file" 2>/dev/null; then
            show_info "## Examples"
            sed -n '/[Ee]xample/,/## /p' "$command_file" | grep -E "^\s*/pm:" | head -5
            echo ""
        fi
        
        # Show related commands
        show_info "💡 Related Commands"
        case "$command" in
            prd-*)
                echo "   /pm:prd-list     # List all PRDs"
                echo "   /pm:prd-status   # PRD status overview"
                ;;
            epic-*)
                echo "   /pm:epic-list    # List all epics"
                echo "   /pm:epic-show --status  # Epic progress"
                echo "   /pm:status       # Project overview"
                ;;
            issue-*)
                echo "   /pm:next         # Next available tasks"
                echo "   /pm:status       # Project dashboard"
                echo "   /pm:blocked      # Blocked tasks"
                ;;
            *)
                echo "   /pm:status       # Project overview"
                echo "   /pm:help workflow # Workflow guide"
                ;;
        esac
    else
        show_error "Command Not Found" "No help available for command: $command"
        echo ""
        show_info "💡 Available commands:"
        if [[ -d "$COMMANDS_DIR" ]]; then
            ls -1 "$COMMANDS_DIR"/*.md 2>/dev/null | xargs -I {} basename {} .md | sed 's/^/   \/pm:/' | head -10
        else
            echo "   /pm:prd-new      # Create new PRD"
            echo "   /pm:epic-list    # List epics"
            echo "   /pm:status       # Project status"
            echo "   /pm:help workflow # Workflow guide"
        fi
    fi
    echo ""
}

# Function to show workflow guide
show_workflow_guide() {
    show_subtitle "🔄 Project Workflow Guide"
    
    show_info "📋 Complete Development Workflow:"
    echo ""
    echo "1. 📝 Requirements & Planning"
    echo "   /pm:init                     # Initialize project (one-time)"
    echo "   /pm:prd-new <feature-name>   # Create Product Requirements Document"
    echo "   /pm:prd-edit <name>          # Refine requirements"
    echo ""
    echo "2. 📊 Epic Creation & Decomposition"
    echo "   /pm:prd-parse <prd-name>     # Convert PRD to epic"
    echo "   /pm:epic-decompose <epic>    # Break epic into tasks"
    echo "   /pm:epic-show <epic>         # Review epic structure"
    echo ""
    echo "3. 🔗 GitHub Integration"
    echo "   /pm:epic-sync <epic>         # Sync epic to GitHub"
    echo "   /pm:epic-oneshot <epic>      # Decompose + sync in one command"
    echo ""
    echo "4. 🚀 Development Execution"
    echo "   /pm:auto                     # Auto-start best available task"
    echo "   /pm:issue-start <task-id>    # Start specific task"
    echo "   /pm:next                     # View next available tasks"
    echo ""
    echo "5. 📈 Progress Tracking"
    echo "   /pm:standup                  # Daily progress report"
    echo "   /pm:status                   # Overall project status"
    echo "   /pm:blocked                  # Review blocked tasks"
    echo ""
    echo "6. 🎯 Completion & Cleanup"
    echo "   /pm:complete <task-id>       # Mark tasks complete"
    echo "   /pm:epic-close <epic>        # Close completed epics"
    echo "   /pm:clean                    # Archive completed work"
    echo ""
    show_tip "Pro Tips:"
    echo "   • Use /pm:status frequently for project overview"
    echo "   • Run /pm:standup for daily team updates"
    echo "   • Keep PRDs focused and specific"
    echo "   • Break epics into 3-8 tasks for optimal parallelization"
    echo ""
}

# Function to show troubleshooting guide
show_troubleshooting_guide() {
    show_subtitle "🔧 Troubleshooting Guide"
    
    show_info "🚨 Common Issues & Solutions:"
    echo ""
    echo "1. ❌ \"No epics directory found\""
    echo "   Solution: /pm:init                    # Initialize project structure"
    echo "   Or:       /pm:prd-new <feature>      # Create first PRD"
    echo ""
    echo "2. ❌ \"GitHub CLI not authenticated\""
    echo "   Solution: gh auth login               # Authenticate with GitHub"
    echo "   Check:    gh auth status              # Verify authentication"
    echo ""
    echo "3. ❌ \"No available tasks found\""
    echo "   Check:    /pm:blocked                 # Review blocked tasks"
    echo "   Or:       /pm:epic-decompose <epic>  # Break down epics"
    echo "   Or:       /pm:prd-parse <prd>        # Convert PRDs to epics"
    echo ""
    echo "4. ❌ \"Script not found\" errors"
    echo "   Solution: /pm:init                   # Reinstall project structure"
    echo "   Check:    ls .claude/scripts/pm/     # Verify scripts exist"
    echo ""
    echo "5. ❌ Tasks stuck \"in-progress\""
    echo "   Review:   /pm:standup                # Check active work"
    echo "   Reset:    /pm:issue-reopen <task>    # Reset task status"
    echo "   Update:   /pm:issue-sync <task>      # Sync with GitHub"
    echo ""
    echo "6. ❌ Sync issues with GitHub"
    echo "   Check:    gh issue list              # Verify GitHub connectivity"
    echo "   Retry:    /pm:epic-sync <epic>       # Re-sync epic"
    echo "   Manual:   /pm:import <issue-id>      # Import specific issue"
    echo ""
    show_info "🔍 Diagnostic Commands:"
    echo "   /pm:status           # Overall project health"
    echo "   /pm:epic-list        # Epic inventory"
    echo "   /pm:blocked          # Blocked tasks analysis"
    echo "   gh auth status       # GitHub authentication"
    echo ""
    show_tip "Prevention Tips:"
    echo "   • Run /pm:status regularly to catch issues early"
    echo "   • Keep GitHub CLI updated: brew upgrade gh"
    echo "   • Use /pm:standup for team coordination"
    echo "   • Backup project data before major changes"
    echo ""
}

# Main help logic
case "$HELP_TOPIC" in
    workflow)
        show_title "📚 CCPM v2.0 - Workflow Guide" 50
        show_workflow_guide
        ;;
    troubleshooting)
        show_title "📚 CCPM v2.0 - Troubleshooting Guide" 50
        show_troubleshooting_guide
        ;;
    "")
        # Context-aware help
        show_title "📚 CCPM v2.0 - Help System" 50
        
        project_state=$(analyze_project_state)
        show_context_suggestions "$project_state"
        
        show_subtitle "📚 Quick Command Reference"
        
        show_info "📄 PRD Commands"
        echo "  /pm:prd-new <name>     # Create new product requirement"
        echo "  /pm:prd-parse <name>   # Convert PRD to implementation epic"
        echo "  /pm:prd-list           # List all PRDs"
        echo ""
        show_info "📚 Epic Commands"
        echo "  /pm:epic-decompose <name> # Break epic into task files"
        echo "  /pm:epic-sync <name>      # Push epic and tasks to GitHub"
        echo "  /pm:epic-list             # List all epics with status"
        echo "  /pm:epic-show <name>      # Display epic details"
        echo ""
        show_info "📝 Task Commands"
        echo "  /pm:issue-start <num>     # Begin work with specialized agent"
        echo "  /pm:next                  # Show next priority tasks"
        echo "  /pm:auto                  # Auto-start best available task"
        echo ""
        show_info "🔄 Workflow Commands"
        echo "  /pm:status             # Overall project dashboard"
        echo "  /pm:standup            # Daily standup report"
        echo "  /pm:blocked            # Show blocked tasks"
        echo "  /pm:complete <num>     # Mark task complete"
        echo ""
        show_info "🔧 System Commands"
        echo "  /pm:init               # Initialize project structure"
        echo "  /pm:help workflow      # Detailed workflow guide"
        echo "  /pm:help troubleshooting # Problem diagnosis"
        echo ""
        show_tip "For specific command help: /pm:help <command-name>"
        show_tip "For workflow guidance: /pm:help workflow"
        ;;
    *)
        # Specific command help
        show_title "📚 CCPM v2.0 - Command Help" 50
        show_command_help_detailed "$HELP_TOPIC"
        
        local project_state
        project_state=$(analyze_project_state)
        if [[ "$project_state" != "active_work" ]]; then
            show_context_suggestions "$project_state"
        fi
        ;;
esac

exit 0