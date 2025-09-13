#!/bin/bash

# Epic Sync Script - Epic-to-GitHub Synchronization System
# Synchronize epics and tasks with GitHub issues and set up development environment

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

# Function to show usage
show_usage() {
    show_command_help "/pm:epic-sync" "Synchronize epic with GitHub" \
        "/pm:epic-sync <epic_name> [OPTIONS]         # Sync epic to GitHub
/pm:epic-sync user-auth                         # Basic sync
/pm:epic-sync user-auth --dry-run               # Preview operations
/pm:epic-sync user-auth --force                 # Force re-sync
/pm:epic-sync user-auth --skip-worktree         # Skip worktree creation"
    
    echo ""
    echo "Options:"
    echo "  --dry-run          Preview sync operations"
    echo "  --force            Override safety checks and force re-sync"
    echo "  --skip-worktree    Skip worktree creation"
    echo "  --sync-only        Update existing issues only"
    echo "  --update           Refresh existing GitHub content"
    echo "  --help             Show this help message"
}

# Parse arguments
EPIC_NAME=""
DRY_RUN=false
FORCE_SYNC=false
SKIP_WORKTREE=false
SYNC_ONLY=false
UPDATE_EXISTING=false

for arg in "$@"; do
  case "$arg" in
    "--dry-run")
      DRY_RUN=true
      ;;
    "--force"|"-f")
      FORCE_SYNC=true
      ;;
    "--skip-worktree")
      SKIP_WORKTREE=true
      ;;
    "--sync-only")
      SYNC_ONLY=true
      ;;
    "--update")
      UPDATE_EXISTING=true
      ;;
    "--help")
      show_usage
      ;;
    -*|--*)
      show_error "Unknown Option" "Unknown option: $arg"
      show_usage
      ;;
    *)
      if [[ -z "$EPIC_NAME" ]]; then
        EPIC_NAME="$arg"
      fi
      ;;
  esac
done

if [[ -z "$EPIC_NAME" ]]; then
    show_error "Missing Epic Name" "Epic name is required"
    show_usage
fi

# Validate project structure
if ! validate_ccpm_structure 2>/dev/null; then
    show_error "Project Not Initialized" "CCPM project not initialized"
    show_tip "Run /pm:init to initialize the project"
    exit 1
fi

# Display sync header
show_title "🔗 Epic GitHub Synchronization" 50
show_info "Epic: $EPIC_NAME"
show_info "Started: $(format_timestamp)"

if [[ "$DRY_RUN" == "true" ]]; then
    show_warning "DRY RUN MODE" "Preview operations only"
fi

echo ""

# Epic validation
EPIC_DIR=".claude/epics/$EPIC_NAME"
EPIC_FILE="$EPIC_DIR/epic.md"
SYNC_CACHE_DIR="$EPIC_DIR/.sync-cache"

if [[ ! -f "$EPIC_FILE" ]]; then
    show_error "Epic Not Found" "Epic '$EPIC_NAME' does not exist"
    echo ""
    show_info "Available epics:"
    find .claude/epics -name "epic.md" 2>/dev/null | while read -r epic_file; do
        epic_dir=$(dirname "$epic_file")
        available_epic=$(basename "$epic_dir")
        [[ "$available_epic" != ".archived" ]] && echo "   📐 $available_epic"
    done
    echo ""
    show_tip "Create epic from PRD: /pm:prd-parse $EPIC_NAME"
    exit 1
fi

# Validate GitHub CLI
show_subtitle "🔍 GitHub Setup Validation"

if ! command -v gh >/dev/null 2>&1; then
    show_error "GitHub CLI Missing" "GitHub CLI (gh) not found"
    show_tip "Install: brew install gh"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    show_error "GitHub Authentication" "GitHub CLI not authenticated"
    show_tip "Authenticate: gh auth login"
    exit 1
fi

show_success "GitHub CLI" "Available and authenticated"

# Repository detection
if ! git remote -v | grep -q "github.com"; then
    show_error "GitHub Remote Missing" "No GitHub remote found"
    show_tip "Add GitHub remote: git remote add origin <github-repo-url>"
    exit 1
fi

github_remote=$(git remote -v | grep "github.com" | grep "(push)" | head -1 | awk '{print $2}')
repo_owner=$(echo "$github_remote" | sed 's/.*github\.com[:/]\([^/]*\)\/.*/\1/')
repo_name=$(echo "$github_remote" | sed 's/.*github\.com[:/][^/]*\/\([^.]*\).*/\1/' | sed 's/\.git$//')

show_info "Repository: $repo_owner/$repo_name"

# Verify repository access
if [[ "$DRY_RUN" == "false" ]]; then
    if ! gh repo view "$repo_owner/$repo_name" >/dev/null 2>&1; then
        show_error "Repository Access" "Cannot access repository: $repo_owner/$repo_name"
        show_tip "Check permissions or repository name"
        exit 1
    fi
    show_success "Repository Access" "Confirmed"
fi

echo ""

# Extract epic metadata
epic_name=$(grep "^name:" "$EPIC_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "$EPIC_NAME")
epic_status=$(grep "^status:" "$EPIC_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "pending")
existing_github_url=$(grep "^github_url:" "$EPIC_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')

# Count task files
task_files=($(find "$EPIC_DIR" -name "[0-9]*.md" 2>/dev/null | sort))
total_tasks=${#task_files[@]}

show_subtitle "📋 Epic Analysis"
show_info "Name: $epic_name"
show_info "Status: $epic_status"
show_info "Tasks: $total_tasks found"

if [[ -n "$existing_github_url" ]]; then
    show_info "GitHub: Already synced"
else
    show_info "GitHub: Not synced"
fi

# Check sync conditions
if [[ $total_tasks -eq 0 && "$FORCE_SYNC" == "false" ]]; then
    show_error "No Tasks Found" "Epic has no tasks to sync"
    show_tip "Decompose epic first: /pm:epic-decompose $EPIC_NAME"
    show_tip "Or force sync: /pm:epic-sync $EPIC_NAME --force"
    exit 1
fi

if [[ -n "$existing_github_url" && "$SYNC_ONLY" == "false" && "$UPDATE_EXISTING" == "false" && "$FORCE_SYNC" == "false" ]]; then
    show_warning "Already Synced" "Epic already synced to GitHub"
    show_info "URL: $existing_github_url"
    echo ""
    show_info "Options:"
    echo "  /pm:epic-sync $EPIC_NAME --sync-only    # Update existing issues"
    echo "  /pm:epic-sync $EPIC_NAME --update       # Refresh content"
    echo "  /pm:epic-sync $EPIC_NAME --force        # Force re-sync"
    exit 0
fi

echo ""

# Create sync cache directory
ensure_directory "$SYNC_CACHE_DIR"

# Epic issue management
show_subtitle "📝 Epic Issue Management"

epic_issue_number=""
epic_issue_url=""

if [[ -n "$existing_github_url" ]]; then
    epic_issue_number=$(echo "$existing_github_url" | grep -o '[0-9]\+$' || echo "")
    if [[ -n "$epic_issue_number" ]]; then
        epic_issue_url="$existing_github_url"
        show_info "Found existing epic issue: #$epic_issue_number"
        
        if [[ "$UPDATE_EXISTING" == "true" || "$SYNC_ONLY" == "true" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                show_info "Would update issue #$epic_issue_number with latest content"
            else
                show_progress "Updating existing epic issue..."
                show_success "Epic Issue Updated" "#$epic_issue_number"
            fi
        fi
    fi
fi

# Create new epic issue if needed
if [[ -z "$epic_issue_number" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        show_info "Would create epic issue:"
        show_info "Title: Epic: $epic_name"
        show_info "Labels: epic, $epic_status"
    else
        show_progress "Creating new epic issue..."
        
        # Prepare epic issue content
        epic_title="Epic: $epic_name"
        epic_body_file="$SYNC_CACHE_DIR/epic-body.md"
        
        # Generate epic issue body
        cat > "$epic_body_file" << EOF
# Epic: $epic_name

## Overview
$(sed -n '/^## Overview/,/^##/{//!p}' "$EPIC_FILE" 2>/dev/null || echo "No overview available")

## Tasks
$(if [[ $total_tasks -gt 0 ]]; then
  echo ""
  for task_file in "${task_files[@]}"; do
    task_id=$(basename "$task_file" .md)
    task_name=$(grep "^name:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "Untitled")
    echo "- [ ] $task_name (Task: $task_id)"
  done
else
  echo "No tasks defined yet."
fi)

## Status
- **Progress**: 0%
- **Status**: $epic_status
- **Created**: $(date '+%Y-%m-%d')

## Development
This epic is managed using Claude Code Project Manager (CCPM) v2.0.

---
*Generated by CCPM v2.0 on $(format_timestamp)*
EOF

        # Create GitHub issue
        if epic_issue_url=$(gh issue create --title "$epic_title" --body-file "$epic_body_file" --label "epic" --label "$epic_status" 2>/dev/null); then
            epic_issue_number=$(echo "$epic_issue_url" | grep -o '[0-9]\+$')
            show_success "Epic Issue Created" "#$epic_issue_number"
            show_info "URL: $epic_issue_url"
        else
            show_error "Creation Failed" "Failed to create epic issue"
            exit 1
        fi
    fi
fi

echo ""

# Task issues management
show_subtitle "📋 Task Issues Management"

task_issues_created=0
task_issues_updated=0
task_mapping_file="$SYNC_CACHE_DIR/task-mapping.txt"

# Clear previous mapping
> "$task_mapping_file"

if [[ $total_tasks -gt 0 ]]; then
    show_progress "Processing $total_tasks tasks..."
    
    for task_file in "${task_files[@]}"; do
        task_id=$(basename "$task_file" .md)
        task_name=$(grep "^name:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "Untitled Task")
        task_status=$(grep "^status:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "pending")
        existing_task_url=$(grep "^github_url:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//')
        
        show_info "Processing task $task_id: $task_name"
        
        # Check if task already has GitHub issue
        if [[ -n "$existing_task_url" && "$FORCE_SYNC" == "false" ]]; then
            task_issue_number=$(echo "$existing_task_url" | grep -o '[0-9]\+$' || echo "")
            if [[ -n "$task_issue_number" ]]; then
                show_info "Task already synced: #$task_issue_number"
                echo "$task_id:$task_issue_number:$existing_task_url" >> "$task_mapping_file"
                
                if [[ "$UPDATE_EXISTING" == "true" || "$SYNC_ONLY" == "true" ]]; then
                    if [[ "$DRY_RUN" == "true" ]]; then
                        show_info "Would update task issue #$task_issue_number"
                    else
                        show_info "Updated task issue: #$task_issue_number"
                        ((task_issues_updated++))
                    fi
                fi
                continue
            fi
        fi
        
        # Create new task issue
        if [[ "$DRY_RUN" == "true" ]]; then
            show_info "Would create task issue: $task_name"
        else
            # Prepare task issue content
            task_title="$task_name"
            task_body_file="$SYNC_CACHE_DIR/task-$task_id-body.md"
            
            # Generate task issue body
            cat > "$task_body_file" << EOF
# Task: $task_name

$(sed '1,/^---$/d; /^---$/,$d' "$task_file" 2>/dev/null || echo "No task description available")

## Epic Connection
This task is part of Epic #$epic_issue_number: $epic_name

## Status
- **Current Status**: $task_status
- **Task ID**: $task_id
- **Created**: $(date '+%Y-%m-%d')

---
*Part of Epic #$epic_issue_number - Managed by CCPM v2.0*
EOF

            # Create GitHub issue for task
            if task_issue_url=$(gh issue create --title "$task_title" --body-file "$task_body_file" --label "task" --label "$task_status" 2>/dev/null); then
                task_issue_number=$(echo "$task_issue_url" | grep -o '[0-9]\+$')
                show_success "Task Issue Created" "#$task_issue_number"
                echo "$task_id:$task_issue_number:$task_issue_url" >> "$task_mapping_file"
                ((task_issues_created++))
                
                # Update task file with GitHub URL
                temp_task_file="$SYNC_CACHE_DIR/task-$task_id-temp.md"
                awk -v url="$task_issue_url" '
                  BEGIN { in_frontmatter = 0; github_added = 0 }
                  /^---$/ { 
                    if (!in_frontmatter) { 
                      in_frontmatter = 1 
                    } else { 
                      if (!github_added) print "github_url: " url
                      in_frontmatter = 0 
                    }
                    print; next 
                  }
                  in_frontmatter && /^github_url:/ { 
                    print "github_url: " url
                    github_added = 1
                    next 
                  }
                  { print }
                ' "$task_file" > "$temp_task_file"
                
                if mv "$temp_task_file" "$task_file"; then
                    show_info "Updated task file with GitHub URL"
                fi
            else
                show_error "Failed to create task issue for: $task_name"
            fi
        fi
    done
else
    show_warning "No tasks to process"
fi

echo ""

# Epic metadata finalization
show_subtitle "📝 Epic Metadata Update"

if [[ "$DRY_RUN" == "true" ]]; then
    show_info "Would update epic metadata:"
    show_info "GitHub URL: $epic_issue_url"
    show_info "Sync timestamp: $(format_timestamp)"
else
    show_progress "Updating epic metadata..."
    
    current_datetime=$(format_timestamp)
    temp_epic_file="$SYNC_CACHE_DIR/epic-temp.md"
    
    # Update epic file with GitHub information
    awk -v github_url="$epic_issue_url" -v synced="$current_datetime" '
      BEGIN { in_frontmatter = 0; github_added = 0; synced_added = 0 }
      /^---$/ { 
        if (!in_frontmatter) { 
          in_frontmatter = 1 
        } else { 
          if (!github_added) print "github_url: " github_url
          if (!synced_added) print "github_synced: " synced
          in_frontmatter = 0 
        }
        print; next 
      }
      in_frontmatter && /^github_url:/ { 
        print "github_url: " github_url
        github_added = 1
        next 
      }
      in_frontmatter && /^github_synced:/ { 
        print "github_synced: " synced
        synced_added = 1
        next 
      }
      { print }
    ' "$EPIC_FILE" > "$temp_epic_file"
    
    if mv "$temp_epic_file" "$EPIC_FILE"; then
        show_success "Epic Metadata Updated"
    else
        show_warning "Failed to update epic metadata"
    fi
fi

echo ""

# Worktree setup
if [[ "$SKIP_WORKTREE" != "true" ]]; then
    show_subtitle "🌿 Worktree Setup"
    
    WORKTREE_PATH="../ccpm-$EPIC_NAME"
    EPIC_BRANCH="epic/$EPIC_NAME"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        show_info "Would create development worktree:"
        show_info "Path: $WORKTREE_PATH"
        show_info "Branch: $EPIC_BRANCH"
    else
        show_progress "Setting up development worktree..."
        
        # Check if worktree already exists
        if git worktree list 2>/dev/null | grep -q "$WORKTREE_PATH"; then
            show_success "Worktree Exists" "$WORKTREE_PATH"
        else
            # Create epic branch if it doesn't exist
            if ! git show-ref --verify --quiet "refs/heads/$EPIC_BRANCH"; then
                git checkout main
                git pull origin main 2>/dev/null || show_warning "Failed to pull main"
                git checkout -b "$EPIC_BRANCH"
                git push -u origin "$EPIC_BRANCH" 2>/dev/null || show_warning "Failed to push branch"
                show_info "Created branch: $EPIC_BRANCH"
            fi
            
            # Create worktree
            if git worktree add "$WORKTREE_PATH" "$EPIC_BRANCH" 2>/dev/null; then
                show_success "Worktree Created" "$WORKTREE_PATH"
            else
                show_warning "Worktree creation failed"
            fi
        fi
    fi
    
    echo ""
fi

# Summary
show_subtitle "🎉 Sync Complete"

if [[ "$DRY_RUN" == "true" ]]; then
    show_info "Dry run summary:"
    show_info "Epic: $EPIC_NAME"
    show_info "Tasks: $total_tasks would be processed"
    show_info "GitHub Issues: 1 epic + $total_tasks tasks"
    echo ""
    show_tip "Execute sync: /pm:epic-sync $EPIC_NAME"
else
    show_success "Epic Synchronized" "$EPIC_NAME"
    echo ""
    show_info "Summary:"
    show_info "Epic Issue: #$epic_issue_number"
    show_info "Tasks Created: $task_issues_created"
    show_info "Tasks Updated: $task_issues_updated"
    echo ""
    show_info "GitHub Links:"
    show_info "Epic: $epic_issue_url"
    
    if [[ -f "$task_mapping_file" && -s "$task_mapping_file" ]]; then
        show_info "Tasks:"
        while IFS=':' read -r task_id issue_number issue_url; do
            show_info "  Task $task_id: #$issue_number"
        done < "$task_mapping_file"
    fi
    
    echo ""
    show_info "Next steps:"
    echo "  /pm:epic-start $EPIC_NAME         # Begin development work"
    if [[ "$SKIP_WORKTREE" != "true" ]]; then
        echo "  cd ../ccpm-$EPIC_NAME            # Work in dedicated environment"
    fi
    echo "  /pm:epic-show $EPIC_NAME          # Monitor progress"
fi

# Cleanup temporary files
if [[ "$DRY_RUN" == "false" ]]; then
    find "$SYNC_CACHE_DIR" -name "*.md" -type f -delete 2>/dev/null || true
fi