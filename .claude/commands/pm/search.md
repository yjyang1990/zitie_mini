---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [query] [type] [scope]
description: Search for work items, epics, issues, or PRDs across the project
model: inherit
---

# Project Search

Comprehensive search functionality across all CCPM project artifacts including epics, issues, PRDs, and configuration files.

## Usage

```bash
/pm:search "keyword"              # Search everything
/pm:search "keyword" epic         # Search epics only
/pm:search "keyword" issue        # Search issues only
/pm:search "keyword" prd          # Search PRDs only
/pm:search "keyword" config       # Search configuration
/pm:search "keyword" all active   # Search active items only
```

## Implementation

The Project Search functionality is implemented in `.claude/scripts/pm/search.sh`. This command provides comprehensive search functionality across all CCPM project artifacts including epics, issues, PRDs, and configuration files.

## Error Handling

**Common Issues:**
- **No search query**: Provide usage examples and guidance
- **No results found**: Suggest alternative search strategies
- **Script not found**: Fall back to built-in search functionality
- **Invalid file paths**: Handle gracefully with error messages

**Recovery Steps:**
1. Check project initialization: `/pm:status`
2. Verify content exists: `/pm:epic-list` and `/pm:prd-list`
3. Try broader search terms or different types
4. Use exact file browsing: `/pm:help` for available commands

## Features

- **Multi-type search**: Epics, issues, PRDs, configuration, documentation
- **Scope filtering**: All items vs. active items only
- **Context display**: Show matching lines with surrounding context
- **Metadata extraction**: Display status, titles, and file information
- **Smart suggestions**: Context-aware recommendations based on results
- **Graceful fallback**: Works without dedicated search script
- **Integration ready**: Links to related commands for found items