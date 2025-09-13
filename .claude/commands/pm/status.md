---
allowed-tools: Bash, Task
argument-hint: [filter]
description: Show project management status and current work items
model: inherit
---

# Project Status Dashboard

Display comprehensive project status including PRDs, epics, tasks, and GitHub integration status.

## Usage

```bash
/pm:status           # Show complete status
/pm:status overview  # Quick overview only
/pm:status epics     # Focus on epics
/pm:status tasks     # Focus on tasks
```

## Instructions

The project status functionality is implemented in `.claude/scripts/pm/status.sh`. This command provides comprehensive project status including PRDs, epics, tasks, and GitHub integration status.

## Features

### Project Overview

- **PRD Status**: Current state of Product Requirement Documents
- **Epic Progress**: Completion status and task breakdown for all epics
- **Active Tasks**: Currently in-progress and ready-to-start tasks
- **GitHub Integration**: Synchronization status with GitHub issues

### Status Filters

- **Complete Status**: Full dashboard with all project components
- **Overview Mode**: Quick summary of key metrics and active work
- **Epic Focus**: Detailed view of epic progress and task distribution
- **Task Focus**: Active task status and priority breakdown

### Real-time Metrics

- **Progress Tracking**: Completion percentages and velocity metrics
- **Workload Analysis**: Current capacity and task distribution
- **Dependency Status**: Blocked tasks and dependency chains
- **Health Indicators**: Project health and potential issues

## Display Sections

### 1. Project Summary

- Total epics and completion status
- Active tasks and assignee distribution
- Recent activity and progress velocity
- GitHub synchronization status

### 2. Epic Breakdown

- Individual epic progress with task counts
- Priority distribution and estimated completion
- Blocked tasks and dependency issues
- Recent epic activity and changes

### 3. Active Work

- Currently in-progress tasks
- Ready-to-start tasks with priority
- Task assignments and estimated effort
- Next recommended actions

### 4. System Health

- GitHub integration status
- File system consistency
- Configuration validation
- Recent errors or warnings

## Status Indicators

| Status | Meaning | Action |
|--------|---------|--------|
| ✅ Complete | Task/Epic fully finished | Archive or review |
| 🔄 In Progress | Currently being worked | Continue or check progress |
| ⏳ Ready | Available to start | Begin work |
| 🚧 Blocked | Waiting on dependencies | Resolve blockers |
| ⚠️ Issues | Problems detected | Investigation required |

## Integration Points

- **GitHub Sync**: Shows sync status with GitHub issues
- **Epic Progress**: Links to detailed epic status views
- **Task Management**: Connects to task start/complete workflows
- **PRD System**: Displays PRD completion and approval status