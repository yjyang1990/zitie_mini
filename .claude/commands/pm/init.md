---
allowed-tools: Bash, Read, Write, LS, Task
argument-hint: [force]
description: Initialize project management system with directory structure and configuration
model: inherit
---

# Project Management Initialization

Initialize the CCPM (Claude Code Project Manager) system with proper directory structure, configuration files, and GitHub integration setup.

## Usage

```bash
/pm:init              # Initialize with safety checks
/pm:init force        # Force reinitialize (overwrites existing)
/pm:init check        # Check current initialization status
```

## Instructions

### 1. Pre-Initialization Checks
The initialization script performs comprehensive environment validation:

- **Already Initialized Check**: Detects existing `.claude` directory and warns user
- **Git Repository Check**: Verifies if running in a git repository (optional)
- **GitHub CLI Check**: Validates GitHub CLI availability for enhanced integration
- **Force Mode Support**: Allows reinitializing with `force` parameter

### 2. Execute Initialization
The initialization functionality is implemented in `.claude/scripts/pm/init.sh`. The system provides:

- **Comprehensive Error Handling**: Validates execution and provides clear error messages
- **Fallback Creation**: Creates basic directory structure if script is unavailable
- **Argument Passing**: Supports force mode and check mode parameters
- **Success Validation**: Confirms successful completion with status messages

### 3. Post-Initialization Setup
After successful initialization, the system provides comprehensive guidance:

- **Directory Structure Overview**: Shows created directories and their purposes
- **Quick Start Guide**: Essential first steps for new users
- **Optional Configuration**: GitHub authentication and validation steps
- **Next Actions**: Clear path forward for immediate productivity

### 4. Check Mode
Validation mode (`/pm:init check`) provides non-destructive setup verification:

- **Directory Structure Check**: Validates all required directories exist
- **Configuration File Check**: Verifies essential configuration files
- **Comprehensive Reporting**: Shows missing components with clear status indicators
- **Remediation Guidance**: Provides specific next steps for incomplete setups

## Error Handling

**Common Issues:**
- **Permission denied**: Check directory write permissions
- **Already initialized**: Use `force` flag or check current status
- **Script not found**: Falls back to manual directory creation
- **Git not initialized**: Warns but continues (optional for basic PM features)

**Recovery Steps:**
1. Check permissions: `ls -la .`
2. Verify git status: `git status`
3. Force reinitialize: `/pm:init force`
4. Manual cleanup: `rm -rf .claude` then `/pm:init`

## Advanced Options

**Force Mode**: `--force` or `force`
- Removes existing `.claude` directory
- Performs fresh initialization
- Use when configuration is corrupted

**Validation Mode**: `check`
- Non-destructive check of current setup
- Reports missing components
- Suggests remediation steps