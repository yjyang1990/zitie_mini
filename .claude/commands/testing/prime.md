---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, LS, Task
argument-hint: [framework] [--auto-detect] [--configure] [--validate] [--agent-setup] [--dry-run]
description: Comprehensive testing environment preparation system with intelligent framework detection and agent configuration
model: inherit
---

# Testing Environment Preparation System

Comprehensive testing environment preparation system with intelligent framework detection, dependency validation, test-runner agent configuration, and development workflow integration for optimal testing performance.

## Usage

```bash
/testing:prime                                    # Auto-detect framework and prepare testing environment
/testing:prime jest                               # Configure for specific testing framework
/testing:prime --auto-detect                     # Force framework auto-detection
/testing:prime --configure                       # Interactive configuration setup
/testing:prime --validate                        # Validate testing environment setup
/testing:prime --agent-setup                     # Configure test-runner agent integration
/testing:prime --dry-run                         # Preview testing environment configuration
/testing:prime pytest --validate --agent-setup   # Combined framework-specific setup
```

## Implementation

This command uses the comprehensive testing preparation script located at `.claude/scripts/testing/prime.sh` for all testing environment setup operations. The script provides:

### Framework Detection
- **Multi-language support**: Automatic detection of Jest, Mocha, Vitest, Pytest, Cargo, Go test frameworks
- **Project analysis**: Comprehensive scanning of configuration files, dependencies, and test structure
- **Override capabilities**: Manual framework specification when auto-detection is insufficient
- **Version identification**: Framework version detection and compatibility checking

### Environment Configuration  
- **Dependency validation**: Verification of testing framework installation and accessibility
- **Configuration generation**: Automated creation of testing environment configuration files
- **Test file discovery**: Analysis of existing test files and directory structure
- **Command optimization**: Framework-specific test command configuration

### Agent Integration
- **Test-runner setup**: Comprehensive configuration for test-runner agent integration
- **Best practices enforcement**: Verbose output, sequential execution, real service usage guidelines
- **Performance optimization**: Framework-specific execution parameters and debugging configuration
- **Documentation generation**: Automated creation of agent configuration and usage documentation

## Error Handling

**Common Issues:**
- **No framework detected**: Unknown project type or missing configuration files
- **Missing dependencies**: Testing framework not installed or not accessible
- **No test files found**: Test directory exists but contains no test files  
- **Configuration conflicts**: Multiple frameworks detected or conflicting setup
- **Permission errors**: Cannot read test files or write configuration
- **Agent setup failures**: Test-runner agent configuration issues
- **Command execution errors**: Test commands fail or return unexpected results

**Recovery Steps:**
1. **No framework detected**: Specify framework manually with `/testing:prime [framework]`
2. **Missing dependencies**: Install required packages using framework-specific commands  
3. **No test files found**: Create test files following framework conventions
4. **Configuration conflicts**: Use `--auto-detect` or specify framework explicitly
5. **Permission errors**: Check file permissions and directory access rights
6. **Agent setup failures**: Use `--agent-setup` flag or configure manually
7. **Command execution errors**: Validate environment setup and dependencies

## Features

- **Intelligent framework detection**: Multi-language testing framework analysis with automatic configuration
- **Comprehensive environment validation**: Dependencies, test files, and configuration verification
- **Test-runner agent integration**: Advanced agent configuration for optimal testing workflow
- **Framework-specific optimization**: Tailored setup for Jest, Mocha, Pytest, Cargo, Go, and other frameworks
- **Dry-run and validation modes**: Safe preview and comprehensive environment checking
- **Configuration persistence**: Automated saving of testing environment configuration
- **Best practices enforcement**: Verbose output, sequential execution, real service usage
- **Professional documentation**: Industry-standard testing configuration with comprehensive guidance