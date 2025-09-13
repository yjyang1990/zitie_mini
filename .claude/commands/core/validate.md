---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, LS, Task
argument-hint: [validation_scope] [--fix] [--quick] [--report] [--benchmark] [--dry-run]
description: Comprehensive project validation system with intelligent health assessment and automated remediation capabilities
model: inherit
---

# Project Validation Management System

Comprehensive project validation management system with intelligent health assessment, automated issue detection, configuration validation, performance benchmarking, and remediation capabilities for maintaining optimal CCPM project integrity.

## Usage

```bash
/validate                                         # Comprehensive project validation
/validate scripts                                 # Validate only script files and permissions
/validate configs                                 # Validate configuration files and settings
/validate commands                                # Validate Claude Code command definitions
/validate --fix                                   # Auto-fix repairable issues during validation
/validate --quick                                 # Quick health check with essential validations
/validate --report                                # Generate detailed validation report
/validate --benchmark                             # Performance benchmarking with timing metrics
/validate --dry-run                               # Preview validation plan without execution
/validate scripts --fix --report                  # Combined script validation with auto-fix and reporting
```

## Implementation

This command utilizes a dedicated validation script located at:
- `.claude/scripts/validation/validate-project.sh`

The command parses arguments and delegates to the external script for comprehensive project validation. If the script is not available, it falls back to built-in validation logic.

## Validation Modes

### Scope-Based Validation
- **all** (default): Complete project validation across all components
- **scripts**: Shell script syntax, permissions, and best practices validation
- **configs**: JSON/YAML configuration file syntax and structure validation
- **commands**: Claude Code command definition and frontmatter validation

### Execution Options
- **--fix**: Enable auto-repair mode for repairable issues
- **--quick**: Fast validation focusing on critical issues only
- **--report**: Generate detailed validation report with recommendations
- **--benchmark**: Include performance timing and metrics analysis
- **--dry-run**: Preview validation plan without executing checks

## Validation Types

### Script Validation
- Shell script syntax checking with shellcheck integration
- Execute permission verification and auto-correction
- Best practices compliance assessment
- Security vulnerability scanning

### Configuration Validation  
- JSON syntax validation with jq integration
- YAML structure validation with yamllint support
- Configuration schema compliance checking
- Auto-formatting for malformed files

### Command Validation
- YAML frontmatter structure verification
- Required field presence checking (description, allowed-tools, model)
- Command documentation completeness assessment
- Usage example validation

## Health Assessment

### Health Scoring System
- **Excellent (90-100%)**: Project in optimal condition
- **Good (75-89%)**: Minor issues that should be addressed
- **Fair (60-74%)**: Several issues requiring attention
- **Poor (<60%)**: Critical issues requiring immediate action

### Issue Classification
- **Critical**: Blocking issues that prevent proper functionality
- **Warning**: Issues that should be fixed to maintain code quality
- **Info**: Minor improvements and best practice suggestions

## Error Handling

**Common Issues:**
- **Missing validation tools**: Required tools like shellcheck or jq not installed
- **Permission errors**: Cannot read files or write validation reports
- **Large file processing**: Validation takes too long on large codebases
- **Corrupted configuration files**: JSON/YAML files with syntax errors
- **Missing command frontmatter**: Claude Code commands without proper metadata
- **Script permission issues**: Shell scripts without execute permissions
- **Tool version conflicts**: Incompatible versions of validation tools

**Recovery Steps:**
1. **Missing validation tools**: Install required tools or run validation without them
2. **Permission errors**: Check file permissions and directory access rights
3. **Large file processing**: Use --quick mode for faster validation
4. **Corrupted configuration files**: Use --fix mode to attempt auto-repair
5. **Missing command frontmatter**: Manually add required YAML frontmatter to commands
6. **Script permission issues**: Use --fix mode to automatically add execute permissions
7. **Tool version conflicts**: Update validation tools to compatible versions

## Features

- **Multi-scope validation**: Support for scripts, configurations, and command definitions with targeted validation
- **Intelligent health assessment**: Comprehensive scoring system with detailed health status reporting
- **Automated issue remediation**: Auto-fix capabilities for common issues like permissions and formatting
- **Performance benchmarking**: Detailed timing analysis for validation operations and bottleneck identification
- **Comprehensive reporting system**: Detailed validation reports with actionable recommendations and issue categorization
- **Flexible execution modes**: Support for quick checks, dry-run previews, and comprehensive analysis
- **Professional documentation**: Industry-standard validation reports with detailed issue tracking and resolution guidance