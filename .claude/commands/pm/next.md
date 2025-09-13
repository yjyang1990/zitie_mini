---
allowed-tools: Bash, Read, Grep
argument-hint: [priority|type]
description: Show next available work items ready to be started
model: inherit
---

# Next Available Work

Intelligently identify and prioritize the next tasks ready to be worked on based on dependencies, status, and project priorities.

## Usage

```bash
/pm:next              # Show all available work
/pm:next high         # Show high priority tasks only
/pm:next quick        # Show quick/small tasks
/pm:next blocked      # Show what's currently blocked
/pm:next ready        # Show tasks ready to start (no dependencies)
```

## Instructions

The next work functionality is implemented in `.claude/scripts/pm/next.sh`. This command provides intelligent task prioritization and availability analysis with comprehensive filtering options.

## Features

### Advanced Filtering

- **All tasks**: Complete view of available work items
- **High priority**: Critical and urgent tasks requiring immediate attention
- **Quick wins**: Small tasks (≤4 hours) for efficient completion
- **Blocked analysis**: Tasks waiting on dependencies with blocking reasons
- **Ready to start**: Tasks with no dependencies or completed prerequisites

### Smart Task Analysis

- **Dependency checking**: Validates all task prerequisites are met
- **Conflict detection**: Identifies tasks that cannot run in parallel
- **Priority assessment**: Considers task urgency and impact
- **Time estimation**: Shows estimated completion times when available
- **Epic integration**: Groups tasks by their parent epic context

### Comprehensive Output

Each available task displays:

- Task ID and descriptive name
- Associated epic and project context  
- Priority level and time estimates
- Parallel execution capability
- Blocking status and specific reasons
- Direct action commands for immediate execution

## Smart Recommendations

The system provides intelligent suggestions based on analysis:

- **Ready to start**: Tasks with no dependencies or all dependencies completed
- **High priority**: Tasks marked with high priority or blocking others  
- **Quick wins**: Small tasks that can be completed quickly
- **Blocked tasks**: Tasks waiting on dependencies with suggestions for unblocking

## Actionable Output

Every response includes specific next actions and clear commands to execute, enabling immediate productivity without additional analysis or decision-making overhead.

## Error Recovery

If no work is available:

1. Check if epics need to be synced to GitHub
2. Suggest creating new PRDs or epics
3. Review project status for missing setup steps

Common issues and solutions:

- **No tasks found**: Run `/pm:status` to check project setup
- **All tasks in progress**: Check `/pm:in-progress` for current work
- **GitHub sync issues**: Verify with `gh auth status`