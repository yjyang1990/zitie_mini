---
allowed-tools: Task, Read, Edit, MultiEdit, Write, LS, Grep, Glob, Bash
argument-hint: [review_input] [--batch] [--analyze] [--report] [--validate] [--dry-run]
description: Comprehensive CodeRabbit review management system with intelligent comment analysis and context-aware processing
model: inherit
---

# CodeRabbit Review Management System

Comprehensive CodeRabbit review management system with intelligent comment analysis, context-aware discretionary processing, parallel file handling, and automated quality validation for efficient code review workflows.

## Usage

```bash
/code-rabbit                                      # Interactive CodeRabbit comment processing
/code-rabbit "paste comments here"               # Process specific review comments
/code-rabbit --batch                             # Batch process multiple review sessions
/code-rabbit --analyze                           # Analyze comment patterns and trends
/code-rabbit --report                            # Generate comprehensive review report
/code-rabbit --validate                          # Validate applied changes for quality
/code-rabbit --dry-run                           # Preview processing without making changes
/code-rabbit review.json --batch --validate      # Process JSON review data with validation
```

## Implementation

This command is implemented using the dedicated CodeRabbit processing script:

**Script Location**: `.claude/scripts/code-review/process-rabbit.sh`

The command automatically detects and executes the external script when available, falling back to built-in processing logic if needed. All command-line arguments and processing modes are passed through to the script for comprehensive review management.

## Features

### Core Functionality
- **Intelligent comment categorization**: Automatic classification of security, performance, style, and bug-related comments
- **Context-aware decision making**: Evaluation based on codebase patterns and project-specific requirements
- **Parallel processing capability**: Efficient handling of multi-file reviews using sub-agent delegation
- **Comprehensive validation framework**: Quality checks and safety verification for applied changes
- **Detailed reporting system**: Complete session logs, analysis reports, and decision matrices
- **Flexible processing modes**: Support for batch processing, analysis-only, and validation modes
- **Professional documentation**: Industry-standard review reports with actionable insights and recommendations

### Processing Approach
The system applies intelligent discretion when processing CodeRabbit comments, recognizing that automated review tools may not understand the full codebase context. For each comment, the system:

1. **Evaluates validity** - Determines if the issue actually exists given the complete codebase context
2. **Assesses relevance** - Checks if the suggestion applies to the current architecture and use case
3. **Measures benefit** - Weighs whether implementing the change improves code quality
4. **Considers safety** - Ensures the change won't introduce new problems or break existing functionality

### Comment Categories

**High Priority (Generally Accepted)**:
- 🔒 **Security Issues**: Vulnerabilities, XSS, SQL injection, authentication problems
- 🐛 **Bug Fixes**: Null checks, error handling, logic errors, exception handling

**Medium Priority (Generally Accepted)**:
- 📝 **Type Safety**: TypeScript improvements, interface definitions, type hints

**Contextual Priority (Selective Acceptance)**:
- ⚡ **Performance**: Optimization suggestions (accepted for performance-critical sections)
- 🔧 **Maintainability**: Refactoring suggestions (accepted if clearly beneficial)

**Low Priority (Often Ignored)**:
- 🎨 **Style Issues**: Generic formatting preferences, import reorganization
- ♿ **Accessibility**: Important for public-facing apps, often ignored for internal tools

### Multi-File Processing

**Single File**: Uses efficient batch processing with MultiEdit for consolidated changes

**Multiple Files**: Deploys parallel sub-agents via the Task tool for:
- Independent file processing
- Reduced processing time
- Isolated change contexts
- Comprehensive result consolidation

### Validation and Quality Assurance

**Built-in Quality Checks**:
- Code quality validation
- Change safety verification  
- Context compatibility confirmation
- Regression testing recommendations

**Session Documentation**:
- Raw comment storage and analysis
- Decision matrix with reasoning
- Processing reports and change logs
- Final comprehensive review report

## Error Handling

**Common Issues:**
- **Invalid comment format**: Malformed or unparseable CodeRabbit comments
- **File not found**: Referenced files don't exist in the current codebase
- **Permission errors**: Cannot read source files or write processing reports
- **Context analysis failure**: Unable to understand codebase patterns
- **Agent execution errors**: Parallel sub-agents fail to process files
- **Validation failures**: Applied changes introduce new issues
- **Report generation errors**: Cannot create processing reports or session logs

**Recovery Steps:**
1. **Invalid comment format**: Clean and reformat comments before processing
2. **File not found**: Verify file paths and update references if files were moved
3. **Permission errors**: Check file permissions and directory access rights
4. **Context analysis failure**: Use manual evaluation for complex scenarios
5. **Agent execution errors**: Fall back to sequential processing or manual review
6. **Validation failures**: Revert changes and re-evaluate with stricter criteria
7. **Report generation errors**: Check disk space and directory permissions

## Command Arguments

- `review_input`: CodeRabbit comments (inline text, file path, or interactive input)
- `--batch`: Process multiple review sessions in batch mode
- `--analyze`: Analyze comment patterns and trends without applying changes
- `--report`: Generate comprehensive review report with statistics
- `--validate`: Apply quality validation checks to all changes
- `--dry-run`: Preview processing decisions without making actual changes

## Output Artifacts

Each processing session creates a timestamped directory under `.claude/reviews/` containing:
- Raw comment storage and parsing results
- Comment analysis report with categorization
- Decision matrix with acceptance/rejection reasoning
- Processing reports for each affected file
- Final comprehensive review report
- Change logs and quality validation results