---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, LS, Task
argument-hint: [prompt_text] [--template] [--save] [--batch] [--validate] [--dry-run]
description: Comprehensive complex prompt management system with template support, validation, and execution optimization
model: inherit
---

# Complex Prompt Management System

Comprehensive complex prompt management system with advanced template support, file reference validation, execution optimization, and intelligent prompt processing for handling sophisticated multi-file operations and complex command sequences.

## Usage

```bash
/prompt "Your complex prompt here"                   # Execute complex prompt directly
/prompt @src/main.js @tests/main.test.js analyze    # Process multiple file references
/prompt --template analysis                          # Use saved template for execution
/prompt "complex prompt" --save analysis-template   # Save prompt as reusable template
/prompt --batch prompts/*.txt                        # Execute multiple prompt files
/prompt "prompt text" --validate                     # Validate file references before execution
/prompt "prompt text" --dry-run                      # Preview execution without running
/prompt --template refactor --validate --dry-run     # Combined template usage with validation
```

## Implementation

This command is implemented by the comprehensive script located at:

**`.claude/scripts/prompt/execute-complex.sh`**

The script provides full functionality including:

- **Argument parsing and validation**: Processes all command-line options and flags
- **Template management**: Loading, saving, and managing reusable prompt templates
- **File reference processing**: Automatic validation and context inclusion for @file references
- **Session management**: Complete tracking with detailed logging and reports
- **Execution optimization**: Smart handling of complex multi-file operations
- **Error handling**: Robust error recovery with actionable suggestions

## Prompt Execution Modes

### 1. Direct Execution
Execute prompts immediately with full file context processing:
- Analyzes file references (@file patterns) in prompt text
- Validates file existence and accessibility
- Includes relevant file content as context when appropriate
- Handles glob patterns and directory references

### 2. Template-Based Execution
Use saved templates for consistent prompt execution:
- Load predefined prompt templates with metadata
- Support for template variables and customization
- Template versioning and author tracking
- Easy template discovery and listing

### 3. Validation Mode
Validate prompt structure and file references before execution:
- Check all @file references exist and are accessible
- Validate glob patterns match expected files
- Preview execution strategy without running
- Generate detailed validation reports

### 4. Batch Processing
Process multiple prompt files in sequence:
- Support for prompt file collections
- Consolidated reporting across multiple executions
- Session grouping for related prompt operations
- Progress tracking for large batch operations

## Template Management

The system provides comprehensive template management:

### Template Structure
Templates are stored in `.claude/prompts/templates/` with metadata:
- **Content**: The actual prompt text with placeholders
- **Metadata**: Author, creation date, description, usage notes
- **Validation**: File reference tracking and validation rules
- **Versioning**: Template history and change tracking

### Template Operations
- **Save**: `--save template-name` - Save current prompt as reusable template
- **Load**: `--template template-name` - Load and execute saved template
- **List**: Available templates are automatically discovered and listed
- **Update**: Templates can be modified and versioned appropriately

## File Reference Processing

Advanced file reference handling with intelligent context inclusion:

### Reference Types
- **Direct files**: `@src/main.js` - Include specific file content
- **Glob patterns**: `@src/**/*.js` - Match multiple files with patterns
- **Directories**: `@src/components` - Process directory contents
- **Relative paths**: `@./local/file.js` - Handle relative file references

### Context Optimization
- **Size limits**: Automatically handle large files appropriately
- **Content filtering**: Focus on relevant portions of large files
- **Pattern matching**: Smart inclusion based on file types and patterns
- **Performance optimization**: Efficient processing of multiple file references

## Session Management

Complete session tracking with professional documentation:

### Session Artifacts
Each prompt execution creates comprehensive documentation:
- **Session directory**: Organized storage for all execution artifacts
- **Execution log**: Detailed record of processing steps and results
- **File references report**: Analysis of all @file references used
- **Session summary**: Overview of execution metrics and outcomes

### Session Features
- **Unique session IDs**: Timestamp-based unique identification
- **Progress tracking**: Real-time monitoring of execution progress
- **Error logging**: Complete error capture with recovery suggestions
- **Performance metrics**: Execution timing and resource usage analysis

## Error Handling

**Common Issues:**
- **Empty prompt text**: No prompt provided and no template specified
- **Invalid file references**: Referenced files don't exist in the current codebase
- **Template not found**: Specified template doesn't exist in templates directory
- **Permission errors**: Cannot read referenced files or write session logs
- **Large file handling**: Referenced files too large to process efficiently
- **Glob pattern failures**: Glob patterns don't match any files
- **Session creation errors**: Cannot create session directories or logs

**Recovery Steps:**
1. **Empty prompt text**: Provide prompt text or specify a valid template
2. **Invalid file references**: Use --validate to check references, fix paths as needed
3. **Template not found**: List available templates and use correct template name
4. **Permission errors**: Check file permissions and directory access rights
5. **Large file handling**: Use file summaries or break into smaller operations
6. **Glob pattern failures**: Verify glob patterns and file locations
7. **Session creation errors**: Check disk space and directory permissions

## Features

- **Advanced template system**: Save, load, and manage reusable complex prompts with metadata
- **Intelligent file reference processing**: Automatic validation and context inclusion for @file references
- **Comprehensive validation framework**: File existence checking and reference validation before execution
- **Session management system**: Complete tracking of prompt sessions with detailed logging
- **Flexible execution modes**: Support for dry-run, batch processing, and validation-only modes
- **Professional documentation**: Detailed session reports, file references, and execution logs
- **Optimization strategies**: Smart handling of large files and complex multi-file operations
- **Error recovery mechanisms**: Robust error handling with actionable recovery suggestions