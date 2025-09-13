---
allowed-tools: Bash
argument-hint: [issue_number] [--analyze] [--dry-run] [--force] [--max-agents]
description: Comprehensive issue development orchestration with intelligent work stream analysis, parallel agent management, and GitHub integration
model: inherit
---

# Issue Development Orchestration

Comprehensive issue development orchestration system with intelligent work stream analysis, parallel agent coordination, GitHub integration, and automated progress tracking.

## Usage

```bash
/pm:issue-start issue-number                    # Start development on GitHub issue
/pm:issue-start issue-number --analyze          # Auto-analyze before starting
/pm:issue-start issue-number --dry-run          # Preview development plan
/pm:issue-start issue-number --force            # Force start despite warnings
/pm:issue-start issue-number --max-agents=3     # Limit concurrent agents
/pm:issue-start issue-number --analyze --dry-run # Preview with analysis
```

## Features

- **GitHub Integration**: Automatic issue assignment, labeling, and progress comments
- **Task Discovery**: Intelligent local task file discovery across epics
- **Progress Tracking**: Comprehensive session logging and status updates
- **Agent Coordination**: Specialized development agent with clear instructions
- **Status Management**: Automatic task status updates and metadata management

## Agent-Assisted Development

Enhance your issue development workflow with CCPM's specialized agents:

**Recommended Agent Workflow:**
1. **"Use the github-specialist agent to analyze this GitHub issue and extract detailed requirements"**
   - Provides thorough issue analysis and context understanding
   - Identifies dependencies and related issues
   - Extracts technical requirements and acceptance criteria

2. **"Deploy the code-analyzer agent to examine the codebase and identify implementation approach"**
   - Analyzes existing code structure and patterns
   - Identifies files that need modification
   - Suggests implementation strategies based on codebase patterns

3. **"Use the appropriate engineering specialist (frontend-engineer, backend-engineer, etc.) for implementation guidance"**
   - Provides domain-specific implementation expertise
   - Suggests best practices and architectural patterns
   - Identifies potential challenges and solutions

This agent-assisted approach provides comprehensive development planning beyond basic issue assignment.
- **Dry Run Mode**: Preview all actions before execution
- **Force Mode**: Override assignment and state validation checks
- **Error Recovery**: Helpful guidance for common issues and dependencies

## Implementation

```bash
COMMAND_SCRIPT=".claude/scripts/pm/issue-start.sh"

if [[ -f "$COMMAND_SCRIPT" && -x "$COMMAND_SCRIPT" ]]; then
  bash "$COMMAND_SCRIPT" "$@"
else
  echo "❌ Issue start script not found: $COMMAND_SCRIPT"
  echo "💡 Run: /pm:init to initialize the project management system"
  exit 1
fi
```

## Workflow

1. **Validation**: GitHub CLI authentication and issue accessibility
2. **Discovery**: Local task file discovery across epic directories  
3. **Analysis**: Task requirements, dependencies, and metadata extraction
4. **GitHub Update**: Issue assignment, labeling, and start comment
5. **Tracking Setup**: Progress directory and session logging initialization
6. **Status Update**: Local task file status update to 'in_progress'
7. **Agent Launch**: Specialized development agent with clear instructions

## Error Handling

**Common Issues:**
- **Invalid issue number**: Must be numeric GitHub issue ID
- **GitHub authentication**: GitHub CLI not installed or not authenticated
- **Issue not found**: Check issue number and repository permissions
- **Task file missing**: Issue may not be synced locally yet
- **Issue already assigned**: Use --force to override assignment checks
- **Issue closed**: Use --force to work on closed issues

**Recovery Steps:**
1. **Authentication issues**: Run `gh auth login` to authenticate
2. **Missing task files**: Run `/pm:sync` to sync from GitHub
3. **Permission issues**: Check repository access and GitHub permissions
4. **Assignment conflicts**: Coordinate with assignee or use --force flag
5. **Epic sync issues**: Run `/pm:status` to check project status