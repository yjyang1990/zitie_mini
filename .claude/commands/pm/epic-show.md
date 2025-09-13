---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [epic_name] [--format] [--watch] [--tasks-only] [--agents-only] [--all] [--status]
description: Display comprehensive epic information and status monitoring with real-time updates, task analysis, and GitHub integration
model: inherit
---

# Epic Details Viewer and Status Monitor

Display comprehensive epic information and real-time status monitoring including task breakdown, progress tracking, dependencies analysis, active agents monitoring, and GitHub integration status with multiple output formats and continuous updates.

## Usage

```bash
# Information Display Mode (default)
/pm:epic-show epic-name                  # Full epic details
/pm:epic-show epic-name --format=brief   # Brief summary only
/pm:epic-show epic-name --tasks-only     # Show tasks list only
/pm:epic-show epic-name --format=json    # JSON output
/pm:epic-show --all                      # Status of all active epics
/pm:epic-show --all --format=table       # All epics in table format

# Status Monitoring Mode
/pm:epic-show epic-name --status         # Focus on real-time status monitoring
/pm:epic-show epic-name --status --watch # Continuous monitoring with live updates
/pm:epic-show epic-name --status --agents-only # Show only active agents
/pm:epic-show --all --status              # Status of all active epics
```

## Features

### Information Display Mode (Default)
- **Comprehensive Epic Information**: Name, status, priority, assignee, and creation date
- **Multi-epic Support**: View all epics with --all flag and advanced filtering
- **Task Analysis**: Detailed task breakdown with status distribution and progress tracking
- **Multiple Output Formats**: Brief, detailed, JSON, and table formats
- **Dependencies Analysis**: Task dependencies and workflow progression

### Status Monitoring Mode (--status)
- **Real-time Monitoring**: Live updates with --watch mode for continuous tracking
- **Agent Tracking**: Detect and display active development agents
- **Progress Visualization**: Visual progress bars and status indicators
- **GitHub Integration**: Shows sync status and issue states
- **Development Environment**: Shows branch and worktree status
- **Intelligent Recommendations**: Context-aware next steps
- **Agent Tracking**: Monitor active development agents with --agents-only
- **GitHub Integration**: Issue links, status synchronization, and repository information
- **Multiple Display Formats**: Full, brief, table, tasks-only, and JSON output modes
- **Dependencies Tracking**: Task relationships and dependency visualization
- **Progress Metrics**: Completion percentages and visual progress indicators
- **Relationship Analysis**: PRD connections, worktree status, and git branch information
- **Action Recommendations**: Smart suggestions for next steps based on epic state

## Implementation

```bash
COMMAND_SCRIPT=".claude/scripts/pm/epic-show.sh"

if [[ -f "$COMMAND_SCRIPT" && -x "$COMMAND_SCRIPT" ]]; then
  bash "$COMMAND_SCRIPT" "$@"
else
  echo "❌ Epic show script not found: $COMMAND_SCRIPT"
  echo "💡 Run: /pm:init to initialize the project management system"
  exit 1
fi
```

## Display Formats

- **full** (default): Complete epic information with all sections
- **brief**: Essential information and progress summary only
- **table**: Clean tabular display for dashboards (works with --all)
- **json**: Structured JSON output for programmatic use
- **--tasks-only**: Focus on task list with minimal metadata
- **--agents-only**: Show only active agent information
- **--watch**: Enable continuous monitoring with live updates
- **--all**: Display information for all epics (supports filtering by status)

## Epic Sections

1. **Basic Information**: Epic metadata and GitHub status
2. **Task Analysis**: Status breakdown and progress metrics
3. **Task Details**: Individual task information with dependencies
4. **Epic Description**: Overview and goals preview
5. **Relationships**: PRD links, worktrees, and git branches
6. **Recommended Actions**: Context-aware next steps

## Error Handling

**Common Issues:**
- **Epic not found**: Epic doesn't exist or incorrect name specified
- **No tasks available**: Epic hasn't been decomposed into tasks yet
- **GitHub access issues**: GitHub CLI not available or not authenticated
- **Invalid format**: Unsupported display format specified

**Recovery Steps:**
1. **Epic not found**: Use `/pm:epic-show --all` to see available epics
2. **No tasks**: Run `/pm:epic-decompose <epic-name>` to create tasks
3. **GitHub issues**: Install GitHub CLI with `brew install gh` and authenticate
4. **Format issues**: Use supported formats: full, brief, table, json
5. **Agent issues**: Restart with `/pm:epic-start <epic-name>`
6. **Watch mode problems**: Check file permissions with `ls -la .claude/epics/`