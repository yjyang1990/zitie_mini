---
allowed-tools: Bash, Read, Write, LS, Grep, Glob
argument-hint: [epic_name|mode|direction]
description: Full bidirectional sync between local and GitHub with conflict resolution
model: inherit
---

# Project Sync

Comprehensive bidirectional synchronization between local CCPM project data and GitHub Issues with intelligent conflict resolution and data integrity protection.

## Usage

```bash
/pm:sync                      # Full bidirectional sync
/pm:sync epic-name            # Sync specific epic only
/pm:sync pull                 # Pull from GitHub only
/pm:sync push                 # Push to GitHub only
/pm:sync dry-run              # Preview changes without applying
/pm:sync force                # Force sync with conflict override
```

## Instructions

The project synchronization functionality is implemented in `.claude/scripts/pm/sync.sh`. This command provides comprehensive bidirectional synchronization between local CCPM project data and GitHub Issues.

## Features

### Bidirectional Synchronization

- **Local to GitHub (Push)**: Creates and updates GitHub issues from local task files
- **GitHub to Local (Pull)**: Updates local task statuses based on GitHub issue states
- **Full Sync**: Combines both push and pull operations for complete synchronization
- **Epic Filtering**: Sync specific epics or entire project scope

### Advanced Sync Modes

- **Dry-run Mode**: Preview all changes without applying them
- **Push Only**: Send local changes to GitHub without pulling updates
- **Pull Only**: Update local files from GitHub without pushing changes
- **Force Sync**: Override conflicts and force synchronization

### Conflict Resolution

- **Timestamp Tracking**: Maintains sync history using `last_sync` field
- **Status Mapping**: Intelligent synchronization of task statuses between platforms
- **Conflict Detection**: Identifies conflicting changes between local and GitHub
- **Safe Defaults**: Conservative approach to prevent data loss

### GitHub Integration

- **Issue Creation**: Automatically creates GitHub issues for local tasks
- **Issue Updates**: Synchronizes task titles, descriptions, and status changes
- **Label Management**: Applies appropriate labels (task, epic, CCPM tags)
- **State Synchronization**: Maps between local status and GitHub issue states

## Status Mapping

The sync system intelligently maps statuses between local tasks and GitHub issues:

| Local Status | GitHub State | Action |
|--------------|--------------|--------|
| `completed`, `closed` | `open` → `closed` | Closes GitHub issue |
| `in-progress`, `pending`, `ready` | `closed` → `open` | Reopens GitHub issue |
| `open` | `open` | No change needed |
| `closed` | `closed` | No change needed |

## Data Processing

### GitHub Data Fetching

- Downloads all issues with comprehensive metadata
- Filters issues by labels (epic, task, story, feature, bug)
- Processes issue states and timestamps for conflict detection
- Handles pagination for large repositories

### Local File Processing

- Updates YAML frontmatter in task files
- Maintains GitHub URL references in local files
- Preserves task metadata and content
- Adds sync timestamps for conflict resolution

## Error Handling

**Common Issues:**

- **GitHub CLI not authenticated**: Run `gh auth login`
- **Network connectivity**: Check internet connection and GitHub status
- **Rate limiting**: Wait and retry, or use smaller sync batches
- **Conflicting changes**: Review conflicts manually and re-sync
- **Missing permissions**: Ensure repository access rights

**Recovery Steps:**

1. Validate authentication: `gh auth status`
2. Check connectivity: `gh repo view`
3. Reset sync state: Remove `.claude/.sync-*` directories
4. Manual conflict resolution: Edit files directly
5. Force sync: `/pm:sync force` (use with caution)