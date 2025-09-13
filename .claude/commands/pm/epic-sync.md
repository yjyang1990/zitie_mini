---
allowed-tools: Bash
argument-hint: [epic_name] [--dry-run] [--force] [--skip-worktree] [--sync-only]
description: Comprehensive epic-to-GitHub synchronization with intelligent issue management, task linking, and progress tracking
model: inherit
---

# Epic GitHub Synchronization

Comprehensive epic-to-GitHub synchronization system with intelligent issue management, task dependency linking, automated progress tracking, and robust error recovery.

## Usage

```bash
/pm:epic-sync epic-name                     # Standard GitHub synchronization
/pm:epic-sync epic-name --dry-run           # Preview sync operations
/pm:epic-sync epic-name --force             # Force sync despite warnings
/pm:epic-sync epic-name --skip-worktree     # Sync without creating worktree
/pm:epic-sync epic-name --sync-only         # Update existing issues only
/pm:epic-sync epic-name --dry-run --force   # Preview force operations
```

## Features

- **Comprehensive GitHub integration**: Complete epic and task synchronization
- **Intelligent issue management**: Smart creation, linking, and updates
- **Atomic operations**: Safe sync process with rollback capabilities
- **Progress preservation**: Maintains sync state across operations
- **Flexible sync modes**: Multiple operation modes for different scenarios
- **Metadata enrichment**: Automatic frontmatter updates with GitHub URLs
- **Task dependency mapping**: Preserves task relationships in GitHub
- **Development integration**: GitHub sync focused - use /pm:epic-start-worktree for worktree creation
- **Comprehensive logging**: Detailed operation logs and sync summaries

## Agent-Assisted Enhancement

For more intelligent GitHub synchronization, leverage CCPM's specialized agents:

**Recommended Agent Workflow:**
1. **"Use the pm-specialist agent to analyze the epic structure and prepare a comprehensive synchronization plan"**
   - Reviews epic completeness and identifies GitHub sync requirements
   - Ensures proper task organization and dependency mapping

2. **"Deploy the github-specialist agent to handle GitHub API operations and issue management"**
   - Manages GitHub API interactions with proper error handling
   - Creates well-structured issues with appropriate labels and milestones
   - Handles API rate limiting and authentication efficiently

3. **"Use the code-analyzer agent to validate implementation status by examining recent commits"**
   - Analyzes code changes related to the epic
   - Updates task completion status based on actual implementation
   - Identifies discrepancies between planned and actual progress

This multi-agent approach provides superior synchronization accuracy and intelligent error recovery.

## Implementation

```bash
COMMAND_SCRIPT=".claude/scripts/pm/epic-sync.sh"

if [[ -f "$COMMAND_SCRIPT" && -x "$COMMAND_SCRIPT" ]]; then
  bash "$COMMAND_SCRIPT" "$@"
else
  echo "❌ Epic sync script not found: $COMMAND_SCRIPT"
  echo "💡 Run: /pm:init to initialize the project management system"
  exit 1
fi
```

## Workflow

1. **Validation**: Epic existence, GitHub CLI authentication, and repository access
2. **Repository Setup**: GitHub remote detection and access verification
3. **Epic Issue Management**: Create or update main epic issue with task list
4. **Task Processing**: Individual task issue creation and linking to epic
5. **Metadata Updates**: Epic file updates with GitHub URLs and sync timestamps
6. **Development Environment**: References to dedicated worktree management (use /pm:epic-start-worktree)
7. **Summary Generation**: Comprehensive sync report with links and next steps

## Sync Options

- **--dry-run**: Preview all sync operations without making changes
- **--force**: Override safety checks and force synchronization
- **--skip-worktree**: Skip worktree creation (default - use /pm:epic-start-worktree instead)
- **--sync-only**: Only update existing issues, don't create new ones
- **--update**: Refresh existing GitHub content with latest local changes

## Error Handling

**Common Issues:**
- **Epic not found**: Epic doesn't exist or incorrect name specified
- **GitHub CLI unavailable**: GitHub CLI not installed or not authenticated
- **Repository access**: Cannot access target GitHub repository
- **Existing sync conflicts**: Epic already synced with different configuration
- **API rate limits**: GitHub API rate limiting during bulk operations
- **Network connectivity**: Internet connection issues during sync

**Recovery Steps:**
1. **Epic not found**: Check available epics with `/pm:epic-show --all`
2. **GitHub CLI issues**: Install with `brew install gh` and authenticate with `gh auth login`
3. **Repository access**: Verify repository permissions and remote configuration
4. **Sync conflicts**: Use `--force` to override or `--update` to refresh existing
5. **Rate limits**: Wait and retry, or use smaller batch sizes
6. **Network issues**: Check connectivity and retry operation
7. **Worktree needs**: Use `/pm:epic-start-worktree <epic-name>` for development environment