---
allowed-tools: Bash, Read, Grep
argument-hint: [command-name|workflow|troubleshooting]
description: Context-aware help system with intelligent guidance and project state analysis
model: inherit
---

# Dynamic Help System

Context-aware help system that provides intelligent guidance based on project state, with specific command help, workflow guides, and troubleshooting assistance.

## Usage

```bash
/pm:help                    # Context-aware help based on project state
/pm:help <command-name>     # Help for specific command (e.g., prd-new)
/pm:help workflow           # Step-by-step project workflow guide
/pm:help troubleshooting    # Common issues and solutions
```

## Instructions

The help functionality is implemented in `.claude/scripts/pm/help.sh`. This command provides a sophisticated, context-aware help system that adapts to your project state and needs.

## Features

### Context-Aware Intelligence

- **Project State Analysis**: Automatically detects current project phase (new, has PRDs, has epics, etc.)
- **Smart Suggestions**: Shows most relevant next steps based on project state
- **Dynamic Command Priority**: Prioritizes commands relevant to current work phase

### Specific Command Help

- **Individual Command Documentation**: `/pm:help <command>` shows detailed help for specific commands
- **Usage Examples**: Practical examples extracted from command documentation
- **Related Commands**: Suggests complementary commands for workflow completion

### Comprehensive Guides

- **Workflow Guide** (`/pm:help workflow`): Complete step-by-step project development workflow
- **Troubleshooting Guide** (`/pm:help troubleshooting`): Common issues, solutions, and prevention tips
- **Quick Reference**: Essential commands organized by category

### Advanced Features

- **State-Based Recommendations**: Different suggestions for new projects vs active development
- **Command Validation**: Checks if commands exist and provides alternatives
- **Fallback Content**: Built-in help when external resources unavailable
- **Interactive Guidance**: Contextual hints and workflow progression

## Help Topics

### Project State Analysis

The system recognizes these project states and adapts suggestions:

- **New Project**: Initialization and PRD creation guidance
- **Has PRDs**: Epic creation and decomposition suggestions
- **Has Epics**: Task breakdown and GitHub sync recommendations
- **Has Tasks**: Development workflow and progress tracking
- **Active Work**: Ongoing development support and coordination

### Workflow Guide Features

- Complete development lifecycle from requirements to deployment
- Step-by-step command sequences with explanations
- Pro tips for optimal project management
- Best practices for team coordination

### Troubleshooting System

- Common error scenarios with specific solutions
- Diagnostic commands for problem identification
- Recovery procedures for various failure modes
- Prevention strategies and maintenance tips

## Error Handling

Smart error handling and graceful degradation:

- **Missing Resources**: Provides built-in help when external files unavailable
- **Invalid Commands**: Suggests available alternatives and corrections
- **Project Detection**: Adapts to various project structures and states
- **Command Integration**: Seamlessly works with project management workflow

## Example Workflows

### New User Onboarding

- Run `/pm:help` for context-aware introduction
- Follow suggested initialization steps
- Use `/pm:help workflow` for complete guidance

### Command Discovery

- Use `/pm:help <command>` for specific command details
- Explore related commands through suggestions
- Reference quick command categories

### Problem Resolution

- Start with `/pm:help troubleshooting` for common issues
- Use diagnostic commands for problem identification
- Follow step-by-step resolution procedures