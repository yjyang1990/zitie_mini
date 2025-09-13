---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, LS, Task
argument-hint: [action] [--force] [--backup] [--validate] [--merge] [--dry-run]
description: Comprehensive CLAUDE.md management system with intelligent synchronization, validation, and configuration optimization
model: inherit
---

# CLAUDE.md Management System

Comprehensive CLAUDE.md management system with intelligent synchronization, configuration validation, backup management, merge conflict resolution, and automated optimization for maintaining consistent Claude Code project configuration across environments.

## Usage

```bash
/re-init                                          # Smart synchronization from .claude/CLAUDE.md
/re-init update                                   # Update CLAUDE.md with latest configuration
/re-init sync                                     # Bidirectional synchronization between files
/re-init validate                                 # Validate CLAUDE.md configuration integrity
/re-init --force                                  # Force overwrite existing CLAUDE.md
/re-init --backup                                 # Create backup before modification
/re-init --validate                               # Validate configuration before applying
/re-init --merge                                  # Intelligent merge of configuration changes
/re-init --dry-run                                # Preview changes without applying
/re-init sync --backup --validate                 # Combined synchronization with safety checks
```

## Implementation

The CLAUDE.md management functionality is implemented in the dedicated script:

```
.claude/scripts/config/claude-md-manager.sh
```

This script provides comprehensive CLAUDE.md management with:

- **Argument parsing and validation**: Handles all command-line options and flags
- **Configuration analysis**: Analyzes source and target files with detailed metrics
- **Backup and safety management**: Creates backups and safety checks before operations
- **Intelligent synchronization**: Supports sync, update, and validate operations
- **Merge capabilities**: Handles intelligent merging of configuration changes
- **Session management**: Tracks operations with detailed logging and session artifacts
- **Results documentation**: Generates comprehensive reports and recommendations

The command framework automatically delegates to this script when available, providing a fallback to built-in functionality if the script is not present or executable.

## Error Handling

**Common Issues:**
- **Source file not found**: .claude/CLAUDE.md doesn't exist or is inaccessible
- **Permission errors**: Cannot read source or write target configuration files
- **Configuration validation failures**: Source configuration has structural issues
- **Merge conflicts**: Incompatible changes between source and target configurations
- **Backup creation failures**: Cannot create backup due to disk space or permissions
- **Large file handling**: Configuration files too large for efficient processing
- **Target file conflicts**: Target exists but force mode not enabled

**Recovery Steps:**
1. **Source file not found**: Ensure .claude/CLAUDE.md exists with valid configuration
2. **Permission errors**: Check file permissions and directory access rights
3. **Configuration validation failures**: Fix structural issues in source configuration
4. **Merge conflicts**: Use --force mode or manually resolve conflicts
5. **Backup creation failures**: Check disk space and directory permissions
6. **Large file handling**: Use streaming operations for very large configurations
7. **Target file conflicts**: Use --force or --merge flags to resolve conflicts

## Features

- **Intelligent synchronization**: Smart detection and merging of configuration changes with conflict resolution
- **Comprehensive backup system**: Automatic backup creation with rollback capabilities and safety verification
- **Advanced validation framework**: Configuration integrity checking with completeness scoring and quality assessment
- **Flexible operation modes**: Support for force updates, intelligent merging, and dry-run previews
- **Professional session management**: Complete tracking of configuration operations with detailed logging
- **Safety-first approach**: Multiple safety checks and confirmations before destructive operations
- **Comprehensive documentation**: Detailed session reports with actionable recommendations and rollback instructions