---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, LS, Task
argument-hint: [test_target] [--pattern] [--validate] [--verbose] [--sequential] [--dry-run]
description: Comprehensive testing execution system with intelligent test-runner agent integration and detailed analysis
model: inherit
---

# Testing Execution System

Comprehensive testing execution system with intelligent test-runner agent integration, real-time monitoring, detailed failure analysis, and development workflow optimization for reliable and efficient test operations.

## Usage

```bash
/testing:run                                      # Execute all tests with comprehensive monitoring
/testing:run test/unit/auth.test.js               # Run specific test file with detailed analysis
/testing:run --pattern="auth"                     # Run tests matching pattern with validation
/testing:run --validate                           # Execute tests with enhanced validation mode
/testing:run --verbose                            # Run with maximum verbosity for debugging
/testing:run --sequential                         # Force sequential execution (no parallel)
/testing:run --dry-run                            # Preview test execution plan without running
/testing:run auth.test.js --verbose --validate    # Combined file-specific testing with full analysis
```

## Implementation

This command uses the comprehensive testing execution script located at `.claude/scripts/testing/run.sh` for all test execution operations. The script provides:

### Test Configuration Analysis
- **Configuration validation**: Verification of existing testing environment setup from `/testing:prime`
- **Framework detection**: Reading of stored testing configuration and framework settings
- **Target validation**: Verification of test files, patterns, and execution targets
- **Command preparation**: Framework-specific test command building with optimization flags

### Test Execution Planning
- **Framework optimization**: Tailored command construction for Jest, Mocha, Pytest, Cargo, Go frameworks
- **Execution modes**: Support for verbose, sequential, pattern-matching, and validation modes
- **Performance tuning**: Framework-specific flags for optimal test execution and debugging
- **Resource management**: Proper handling of test environments and cleanup operations

### Test-Runner Agent Integration
- **Agent coordination**: Seamless integration with test-runner agent for comprehensive test execution
- **Real-time monitoring**: Live progress tracking and output capture during test execution
- **Advanced analysis**: Intelligent failure analysis with test structure validation
- **Best practices enforcement**: Verbose output, real services usage, complete output capture

### Results Processing
- **Comprehensive reporting**: Detailed test execution summaries with pass/fail statistics
- **Failure analysis**: Intelligent categorization of test failures with actionable recommendations
- **Performance metrics**: Execution timing, coverage information, and performance analysis
- **Artifact generation**: Complete logging and documentation of test execution results

## Error Handling

**Common Issues:**
- **Testing not configured**: No testing configuration found in .claude/testing/
- **Test file not found**: Specified test file does not exist or is inaccessible
- **Framework not supported**: Unknown or unsupported testing framework detected
- **Dependencies missing**: Testing framework or dependencies not installed
- **Test execution failure**: Test command failed to execute or returned errors
- **Permission errors**: Cannot read test files or write execution logs
- **Agent execution errors**: Test-runner agent failed to execute or analyze results

**Recovery Steps:**
1. **Testing not configured**: Run `/testing:prime` to configure testing environment
2. **Test file not found**: Verify file path and existence, use pattern matching instead
3. **Framework not supported**: Check supported frameworks or configure manually
4. **Dependencies missing**: Install required testing framework and dependencies
5. **Test execution failure**: Check test framework installation and configuration
6. **Permission errors**: Verify file permissions and directory access rights
7. **Agent execution errors**: Use `--dry-run` to validate configuration first

## Features

- **Intelligent test execution**: Framework-specific optimization with comprehensive argument parsing
- **Test-runner agent integration**: Advanced agent-based execution with detailed analysis and reporting
- **Real-time monitoring**: Live test execution tracking with performance metrics and progress updates
- **Comprehensive validation**: Environment checking, dependency validation, and configuration verification
- **Flexible targeting**: Support for individual files, patterns, and full test suites
- **Advanced debugging**: Verbose output modes, sequential execution, and detailed failure analysis
- **Professional logging**: Comprehensive execution logs with timestamps and detailed configuration
- **Best practices enforcement**: Real service usage, comprehensive output capture, intelligent failure analysis