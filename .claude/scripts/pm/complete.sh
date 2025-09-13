#!/bin/bash

# Task Completion Script - Complete tasks with automatic synchronization
# Handles local task updates, GitHub sync, and epic progress tracking

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
    show_command_help "/pm:complete" "Complete a task with automatic synchronization" \
        "/pm:complete <issue_number> [OPTIONS]        # Complete a task
/pm:complete 1234                           # Basic completion
/pm:complete 1234 --notes='Implementation done'  # With notes
/pm:complete 1234 --dry-run                 # Preview operations
/pm:complete 1234 --continue                # Auto-start next task"
    
    echo ""
    echo "Options:"
    echo "  --notes=<text>      Add completion notes"
    echo "  --dry-run          Preview all operations without executing"
    echo "  --no-sync          Skip GitHub sync (local updates only)"
    echo "  --continue         Auto-start next task after completion"
    echo "  --help             Show this help message"
}

# Parse command line arguments
ISSUE_NUMBER=""
COMPLETION_NOTES=""
DRY_RUN=false
NO_SYNC=false
AUTO_CONTINUE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --notes=*)
      COMPLETION_NOTES="${1#*=}"
      shift
      ;;
    --notes)
      shift
      if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
        COMPLETION_NOTES="$1"
        shift
      else
        show_error "Missing Value" "--notes requires a value"
        show_usage
      fi
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --no-sync)
      NO_SYNC=true
      shift
      ;;
    --continue)
      AUTO_CONTINUE=true
      shift
      ;;
    --help)
      show_usage
      ;;
    -*|--*)
      show_error "Unknown Option" "Unknown option: $1"
      show_usage
      ;;
    *)
      if [[ -z "$ISSUE_NUMBER" ]]; then
        ISSUE_NUMBER="$1"
      elif [[ -z "$COMPLETION_NOTES" ]]; then
        COMPLETION_NOTES="$1"
      else
        show_error "Too Many Arguments" "Unexpected argument: $1"
        show_usage
      fi
      shift
      ;;
  esac
done

# Validate required arguments
if [[ -z "$ISSUE_NUMBER" ]]; then
    show_error "Missing Issue Number" "Issue number is required"
    show_usage
fi

# Validate issue number format
if [[ ! "$ISSUE_NUMBER" =~ ^[0-9]+$ ]]; then
    show_error "Invalid Issue Number" "Issue number must be numeric (e.g., 1234)"
    exit 1
fi

# Validate project structure
if ! validate_ccpm_structure 2>/dev/null; then
    show_error "Project Not Initialized" "CCPM project not initialized"
    show_tip "Run /pm:init to initialize the project"
    exit 1
fi

# Display task completion header
show_title "✅ Task Completion System" 40
show_info "Started: $(format_timestamp)"
show_info "Issue: #$ISSUE_NUMBER"

if [[ -n "$COMPLETION_NOTES" ]]; then
    show_info "Notes: $COMPLETION_NOTES"
fi

if [[ "$DRY_RUN" == "true" ]]; then
    show_warning "DRY RUN MODE" "Preview operations only"
fi

echo ""

# Step 1: Find and validate local task file
show_subtitle "📝 Local Task Discovery"

task_file=""
epic_name=""

# Search for task file in epics
for epic_dir in .claude/epics/*/; do
  if [[ -d "$epic_dir" && -f "$epic_dir$ISSUE_NUMBER.md" ]]; then
    task_file="$epic_dir$ISSUE_NUMBER.md"
    epic_name=$(basename "$epic_dir")
    break
  fi
done

if [[ -n "$task_file" && -f "$task_file" ]]; then
  show_success "Task Found" "$task_file"
  show_info "Epic: $epic_name"
  
  # Check current status
  current_status=$(grep "^status:" "$task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "pending")
  show_info "Current Status: $current_status"
  
  if [[ "$current_status" == "completed" || "$current_status" == "closed" ]]; then
    show_warning "Already Completed" "Task already marked as completed"
  fi
else
  show_warning "Task Not Found" "Local task file not found: $ISSUE_NUMBER.md"
  show_info "Will proceed with GitHub-only completion"
fi

echo ""

# Step 2: Update local task status
show_subtitle "📝 Local Status Update"

if [[ "$DRY_RUN" == "true" ]]; then
  show_info "Would update local task status to 'completed'"
  if [[ -n "$COMPLETION_NOTES" ]]; then
    show_info "With notes: $COMPLETION_NOTES"
  fi
else
  if [[ -n "$task_file" && -f "$task_file" ]]; then
    show_progress "Updating local task status..."
    
    # Create backup
    ensure_directory ".claude/tmp/backups"
    backup_file=".claude/tmp/backups/$(basename "$task_file").$(date +%s).backup"
    cp "$task_file" "$backup_file"
    show_info "Backup created: $backup_file"
    
    # Update task status
    current_datetime=$(format_timestamp)
    temp_file=$(mktemp)
    
    awk -v updated="$current_datetime" -v status="completed" -v notes="$COMPLETION_NOTES" '
      BEGIN { in_frontmatter = 0; updated_added = 0; status_updated = 0; notes_added = 0 }
      /^---$/ { 
        if (!in_frontmatter) { 
          in_frontmatter = 1 
        } else { 
          if (!updated_added) print "updated: " updated
          if (!notes_added && notes != "") print "completion_notes: " notes
          in_frontmatter = 0 
        }
        print; next 
      }
      in_frontmatter && /^updated:/ { 
        print "updated: " updated
        updated_added = 1
        next 
      }
      in_frontmatter && /^status:/ { 
        print "status: " status
        status_updated = 1
        next 
      }
      in_frontmatter && /^completion_notes:/ { 
        if (notes != "") {
          print "completion_notes: " notes
          notes_added = 1
        }
        next 
      }
      { print }
    ' "$task_file" > "$temp_file"
    
    if mv "$temp_file" "$task_file"; then
      show_success "Status Updated" "Task marked as completed"
      show_info "Updated: $current_datetime"
    else
      show_error "Update Failed" "Failed to update local status"
      rm -f "$temp_file"
    fi
  else
    show_info "No local task file to update"
  fi
fi

echo ""

# Step 3: GitHub Sync (unless --no-sync)
if [[ "$NO_SYNC" != "true" ]]; then
  show_subtitle "🔄 GitHub Synchronization"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    show_info "Would close issue #$ISSUE_NUMBER on GitHub"
    if [[ -n "$COMPLETION_NOTES" ]]; then
      show_info "With completion notes: $COMPLETION_NOTES"
    fi
  else
    show_progress "Closing issue on GitHub..."
    
    # Check for GitHub CLI
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
      
      # Create completion comment
      completion_comment="✅ **Task Completed via /pm:complete**

**Issue**: #$ISSUE_NUMBER  
**Completed**: $(format_timestamp)"

      if [[ -n "$epic_name" ]]; then
        completion_comment+="  
**Epic**: $epic_name"
      fi

      if [[ -n "$COMPLETION_NOTES" ]]; then
        completion_comment+="  
**Notes**: $COMPLETION_NOTES"
      fi

      completion_comment+="

---
*Completed automatically by CCPM v2.0*"

      # Add completion comment and close issue
      if echo "$completion_comment" | gh issue comment "$ISSUE_NUMBER" --body-file - >/dev/null 2>&1; then
        show_info "Completion comment added"
      else
        show_warning "Failed to add completion comment"
      fi
      
      if gh issue close "$ISSUE_NUMBER" >/dev/null 2>&1; then
        show_success "Issue Closed" "Issue #$ISSUE_NUMBER closed on GitHub"
      else
        show_error "Close Failed" "Failed to close issue on GitHub"
        show_tip "Try manually: gh issue close $ISSUE_NUMBER"
      fi
    else
      show_warning "GitHub CLI Unavailable" "Not authenticated or not installed"
      show_tip "Install: brew install gh && gh auth login"
    fi
  fi
else
  show_info "GitHub sync skipped (--no-sync mode)"
fi

echo ""

# Step 4: Epic Progress Update
if [[ -n "$epic_name" && -n "$task_file" ]]; then
  show_subtitle "📊 Epic Progress Update"
  
  epic_file="$(dirname "$task_file")/epic.md"
  
  if [[ -f "$epic_file" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      show_info "Would update epic progress for: $epic_name"
    else
      show_progress "Updating epic progress: $epic_name"
      
      # Count completed tasks in epic
      epic_dir="$(dirname "$task_file")"
      task_files_in_epic=($(find "$epic_dir" -name "[0-9]*.md" -type f 2>/dev/null | sort))
      total_tasks=${#task_files_in_epic[@]}
      completed_tasks=0
      
      for epic_task_file in "${task_files_in_epic[@]}"; do
        if [[ -f "$epic_task_file" ]]; then
          task_status=$(grep "^status:" "$epic_task_file" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' || echo "pending")
          if [[ "$task_status" == "completed" || "$task_status" == "closed" ]]; then
            ((completed_tasks++))
          fi
        fi
      done
      
      # Calculate progress percentage
      if [[ $total_tasks -gt 0 ]]; then
        progress_percent=$((completed_tasks * 100 / total_tasks))
      else
        progress_percent=0
      fi
      
      show_info "Epic Progress: ${progress_percent}% (${completed_tasks}/${total_tasks} tasks)"
      
      # Update epic file frontmatter
      temp_epic_file=$(mktemp)
      current_datetime=$(format_timestamp)
      
      awk -v updated="$current_datetime" -v progress="$progress_percent" '
        BEGIN { in_frontmatter = 0; updated_added = 0; progress_added = 0 }
        /^---$/ { 
          if (!in_frontmatter) { 
            in_frontmatter = 1 
          } else { 
            if (!updated_added) print "updated: " updated
            if (!progress_added) print "progress: " progress "%"
            in_frontmatter = 0 
          }
          print; next 
        }
        in_frontmatter && /^updated:/ { 
          print "updated: " updated
          updated_added = 1
          next 
        }
        in_frontmatter && /^progress:/ { 
          print "progress: " progress "%"
          progress_added = 1
          next 
        }
        { print }
      ' "$epic_file" > "$temp_epic_file"
      
      if mv "$temp_epic_file" "$epic_file"; then
        show_success "Epic Updated" "Progress: ${progress_percent}%"
        
        # Check if epic is completed
        if [[ $progress_percent -eq 100 ]]; then
          echo ""
          show_success "Epic Completed!" "All $total_tasks tasks finished"
          show_tip "Consider closing the epic: /pm:epic-close $epic_name"
        fi
      else
        show_warning "Failed to update epic progress"
        rm -f "$temp_epic_file"
      fi
    fi
  else
    show_info "Epic file not found: $epic_file"
  fi
else
  show_info "No epic context available"
fi

echo ""

# Step 5: Workflow Continuation
show_subtitle "🚀 Next Steps"

if [[ "$AUTO_CONTINUE" == "true" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    show_info "Would auto-start next available task: /pm:auto"
  else
    show_info "Auto-starting next available task..."
    echo ""
    
    AUTO_SCRIPT="$SCRIPT_DIR/auto.sh"
    if [[ -f "$AUTO_SCRIPT" && -x "$AUTO_SCRIPT" ]]; then
      exec bash "$AUTO_SCRIPT"
    else
      show_warning "auto.sh not found"
      show_tip "Manually run: /pm:auto"
    fi
  fi
else
  show_info "Available actions:"
  echo "  /pm:auto                      # Start next best task"
  echo "  /pm:next                      # See all available tasks"
  if [[ -n "$epic_name" ]]; then
    echo "  /pm:epic-show $epic_name      # Check epic progress"
  fi
  echo "  /pm:status                    # Overall project status"
fi

echo ""

# Summary
if [[ "$DRY_RUN" == "true" ]]; then
  show_info "Dry run complete - no changes made"
  show_tip "Remove --dry-run to execute: /pm:complete $ISSUE_NUMBER"
else
  show_completion "Task #$ISSUE_NUMBER completed successfully!"
fi