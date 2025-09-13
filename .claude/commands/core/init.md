---
description: Initialize CCPM framework for current project with auto-detection and customization
argument-hint: [--type PROJECT_TYPE] [--skip-git] [--minimal] [--help]
---

# CCPM Project Initialization

Initialize and customize the CCPM framework for your current project with automatic project type detection and appropriate configuration.

## Usage

```bash
/init                           # Auto-detect project type and full setup
/init --type react             # Force React project setup
/init --type python            # Force Python project setup  
/init --skip-git               # Skip git initialization
/init --minimal                # Minimal setup without customization
/init --help                   # Show detailed help
```

## Supported Project Types

- **Frontend**: react, vue, angular, nextjs, nodejs
- **Backend**: python, django, python-api, rust, golang, java, php
- **Full-stack**: rails (Ruby on Rails)
- **Generic**: generic-git, generic

## What This Command Does

1. **Detects project type** based on configuration files (package.json, requirements.txt, etc.)
2. **Updates CLAUDE.md** with project-specific commands and coding guidelines
3. **Configures .gitignore** with CCPM-specific exclusions
4. **Initializes git repository** (unless --skip-git)
5. **Shows next steps** and recommended agents for your project type

## Implementation

```bash
INIT_SCRIPT=".claude/scripts/init-project.sh"

if [[ -f "$INIT_SCRIPT" && -x "$INIT_SCRIPT" ]]; then
    bash "$INIT_SCRIPT" "$@"
else
    echo "❌ Initialization script not found: $INIT_SCRIPT"
    echo "💡 Make sure you have copied the complete CCPM framework to your project"
    exit 1
fi
```

## Examples

### React Project
```bash
/init --type react
# Configures for React development with appropriate commands and linting rules
```

### Python/Django Project  
```bash
/init --type django
# Sets up Django-specific commands and Python coding standards
```

### Auto-detection
```bash
/init
# Automatically detects project type and configures accordingly
```

This command transforms the generic CCPM framework into a project-specific development environment with tailored workflows, commands, and best practices.