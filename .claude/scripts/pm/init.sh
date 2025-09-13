#!/bin/bash

# PM Init Script - CCPM Project Management System Initialization
# Initialize the CCPM system with proper directory structure and configuration

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

# Parse arguments
ARGUMENTS="${1:-}"

show_progress "Initializing..."
echo ""

echo " ██████╗ ██████╗██████╗ ███╗   ███╗"
echo "██╔════╝██╔════╝██╔══██╗████╗ ████║"
echo "██║     ██║     ██████╔╝██╔████╔██║"
echo "██║     ██║     ██║     ██║ ╚═╝ ██║"
echo "╚██████╗╚██████╗██║     ██║     ██║"
echo " ╚═════╝ ╚═════╝╚═╝     ╚═╝     ╚═╝"

echo "┌─────────────────────────────────┐"
echo "│ Claude Code Project Manager v2.0│"
echo "│ by https://x.com/aroussi        │"
echo "└─────────────────────────────────┘"
echo "https://github.com/automazeio/ccpm"
echo ""

# Handle check mode
if [[ "${ARGUMENTS}" == "check" ]]; then
  show_info "Checking project initialization status..."
  echo ""
  
  # Check directory structure
  required_dirs=(".claude/config" ".claude/prds" ".claude/epics" ".claude/tmp")
  missing_dirs=()
  
  for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      show_success "$dir exists" ""
    else
      show_error "Missing Directory" "$dir missing"
      missing_dirs+=("$dir")
    fi
  done
  
  # Check configuration files
  config_files=(".claude/config/defaults.json" ".claude/settings.local.json")
  for file in "${config_files[@]}"; do
    if [[ -f "$file" ]]; then
      show_success "$file exists" ""
    else
      show_warning "$file missing"
    fi
  done
  
  echo ""
  if [[ ${#missing_dirs[@]} -eq 0 ]]; then
    show_success "Project is properly initialized"
    show_tip "Run /pm:status to see current project state"
  else
    show_error "Initialization Incomplete" "Project initialization incomplete"
    show_tip "Run /pm:init to complete setup"
  fi
  
  exit 0
fi

# Check if already initialized (unless force mode)
if [[ -d ".claude" && "${ARGUMENTS}" != "force" ]]; then
  show_warning "Project already appears to be initialized"
  echo ""
  echo "Current .claude directory structure:"
  find .claude -type d -maxdepth 2 2>/dev/null | sort
  echo ""
  show_info "Use '/pm:init force' to reinitialize or '/pm:init check' to validate"
  exit 0
fi

# If force mode, remove existing .claude directory
if [[ "${ARGUMENTS}" == "force" && -d ".claude" ]]; then
  show_warning "Removing existing .claude directory (force mode)..."
  rm -rf .claude
fi

show_title "Initializing Claude Code PM System v2.0" 50
echo ""

# Check if we're in a git repository
if [[ ! -d ".git" ]]; then
  show_warning "Not in a git repository"
  show_tip "Consider running 'git init' first"
  echo ""
fi

# Check for required tools
show_progress "Checking dependencies..."

# Check GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
  show_warning "GitHub CLI not found"
  show_tip "Install from: https://cli.github.com (optional but recommended)"
  echo ""
else
  show_success "GitHub CLI (gh) installed"
fi

# Check gh auth status
echo ""
show_progress "Checking GitHub authentication..."
if gh auth status &> /dev/null; then
  show_success "GitHub authenticated"
else
  show_info "GitHub not authenticated - running: gh auth login"
  if command -v gh >/dev/null 2>&1; then
    gh auth login
  fi
fi

# Check for gh-sub-issue extension
echo ""
show_progress "Checking gh extensions..."
if command -v gh >/dev/null 2>&1 && gh extension list | grep -q "yahsan2/gh-sub-issue"; then
  show_success "gh-sub-issue extension installed"
else
  show_info "Installing gh-sub-issue extension..."
  if command -v gh >/dev/null 2>&1; then
    gh extension install yahsan2/gh-sub-issue
  fi
fi

# Create directory structure
echo ""
show_progress "Creating directory structure..."
ensure_directory ".claude/config"
ensure_directory ".claude/lib"
ensure_directory ".claude/scripts/pm"
ensure_directory ".claude/commands"
ensure_directory ".claude/agents"
ensure_directory ".claude/docs"
ensure_directory ".claude/tmp"
ensure_directory ".claude/prds"
ensure_directory ".claude/epics"
ensure_directory ".claude/templates"
ensure_directory ".claude/hooks"
ensure_directory ".claude/tests"

show_success "Directory structure created"

# Check Git configuration
echo ""
show_progress "Checking Git configuration..."
if git rev-parse --git-dir > /dev/null 2>&1; then
  show_success "Git repository detected"

  # Check remote and validate
  if git remote -v | grep -q origin; then
    remote_url=$(git remote get-url origin)
    show_success "Remote configured: $remote_url"
    
    # Check if remote is the CCPM template repository
    if ! check_github_repository; then
      exit 1
    fi
  else
    show_warning "No remote configured"
    show_tip "Add with: git remote add origin <url>"
  fi
else
  show_warning "Not a git repository"
  show_tip "Initialize with: git init"
fi

# Create CLAUDE.md if it doesn't exist
if [[ ! -f "CLAUDE.md" ]]; then
  echo ""
  show_progress "Creating CLAUDE.md..."
  cat > CLAUDE.md << 'EOF'
# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## Project-Specific Instructions

Add your project-specific instructions here.

## Testing

Always run tests before committing:
- `npm test` or equivalent for your stack

## Code Style

Follow existing patterns in the codebase.
EOF
  show_success "CLAUDE.md created"
fi

echo ""
show_completion "Project Management System Initialized!"

echo ""
show_info "Created directory structure:"
echo "  .claude/prds/      - Product Requirements Documents"
echo "  .claude/epics/     - Epic breakdowns and tasks"  
echo "  .claude/config/    - Configuration files"
echo "  .claude/tmp/       - Temporary files and cache"
echo ""

show_info "System Status:"
if command -v gh >/dev/null 2>&1; then
  gh --version | head -1
  echo "  Extensions: $(gh extension list 2>/dev/null | wc -l) installed"
  echo "  Auth: $(gh auth status 2>&1 | grep -o 'Logged in to [^ ]*' || echo 'Not authenticated')"
else
  echo "  GitHub CLI: Not installed"
fi

echo ""
show_info "Quick Start:"
echo "  1. Create your first PRD: /pm:prd-new <feature-name>"
echo "  2. Check system status: /pm:status"
echo "  3. Get help anytime: /pm:help"

echo ""
show_info "Optional Setup:"
echo "  - Configure GitHub: gh auth login"
echo "  - Validate setup: /pm:validate"
echo "  - Initialize context: /context:create"

echo ""
show_tip "Documentation: README.md"

exit 0