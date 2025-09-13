---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
argument-hint: <issue_number> [--notes] [--dry-run] [--no-sync] [--continue]
description: Complete a task with automatic status synchronization and workflow continuation
model: inherit
---

# Mark Task as Complete (Development Done)

Mark a task as developmentally complete when all implementation work is finished. This updates the task status to 'completed' but keeps it open for potential review, testing, or approval before final closure.

## Usage

```bash
/pm:complete 1234                           # Mark task as complete (dev done)
/pm:complete 1234 --notes "Feature ready"  # Add completion notes
/pm:complete 1234 --dry-run                # Preview all operations
/pm:complete 1234 --no-sync                # Skip GitHub sync (local only)
/pm:complete 1234 --continue               # Auto-start next task after completion
```

## Semantic Distinction

**Complete vs Close**:
- `complete`: Development work is finished, task is ready for review/testing (status: 'completed')
- `issue-close`: Final closure after review/approval, permanently closes the task (status: 'closed')
- Use `complete` when development is done but task needs review
- Use `issue-close` when task is fully finished and verified

## Instructions

The task completion functionality is implemented in `.claude/scripts/pm/complete.sh`. This command provides a comprehensive one-command solution for completing tasks with automatic progress synchronization and workflow continuation.

## Features

### Automated Workflow Integration

- **Local Status Update**: Updates task status to 'completed' in local files (not 'closed')
- **GitHub Synchronization**: Keeps GitHub issue open but adds completion comment
- **Epic Progress Update**: Recalculates and updates epic progress percentages
- **Next Task Suggestion**: Identifies and suggests logical next tasks in the workflow
- **Review Preparation**: Prepares task for review/testing phase

### Flexible Completion Options

- **Completion Notes**: Add detailed completion notes with `--notes` option
- **Dry-Run Preview**: Preview all operations without making changes
- **Local-Only Mode**: Skip GitHub sync for offline or private development
- **Auto-Continue**: Automatically start the next available task after completion

### Comprehensive Status Management

- **Task File Updates**: Updates status, completion date, and notes in task files
- **Epic Integration**: Recalculates epic completion percentages and status
- **GitHub Issue Closure**: Closes corresponding GitHub issues with completion notes
- **Workflow Progression**: Identifies dependencies and suggests next steps

### Error Handling and Recovery

- **Validation Checks**: Ensures task exists and is in valid state for completion
- **GitHub Connectivity**: Handles GitHub API failures gracefully
- **Atomic Operations**: Ensures consistency between local and remote state
- **Recovery Options**: Provides clear recovery steps if operations fail

## Completion Workflow

### Standard Completion Process

1. **Task Validation**: Verifies task exists and is completable
2. **Local Update**: Updates task status and completion metadata
3. **Epic Recalculation**: Updates epic progress based on completed tasks
4. **GitHub Sync**: Closes GitHub issue and syncs completion status
5. **Next Steps**: Suggests logical next tasks or workflow actions

### Advanced Features

- **Notes Integration**: Completion notes are added to both local files and GitHub issues
- **Progress Tracking**: Automatic epic progress calculation and status updates
- **Dependency Resolution**: Identifies tasks that become available after completion
- **Team Coordination**: Updates assignee information and team visibility

## Error Scenarios

Common error handling scenarios:

- **Task Not Found**: Clear error message with suggestion to verify task ID
- **Already Completed**: Graceful handling of already-completed tasks
- **GitHub Sync Failures**: Local completion proceeds with sync retry options
- **Permission Issues**: Clear guidance on authentication and access requirements

## Example Workflows

### Standard Task Completion
- Complete development work on a task
- Run `/pm:complete <task-id>` for full completion and sync
- Follow suggested next steps for workflow continuation

### Batch Completion with Notes
- Complete related tasks with detailed notes
- Use `--notes` to document completion details
- Review epic progress after batch completion

### Development Review Process
- Use `--dry-run` to preview completion effects
- Validate GitHub sync and epic updates
- Execute completion after review approval