# Intelligent Context Management System

## Overview

The CCPM Context Management System provides intelligent context optimization for Claude Code sessions, ensuring optimal performance while preserving critical project information.

## Context Categories

### 1. Critical Context (Always Preserved)
- **Project Identity**: Project name, type, and core purpose
- **Current Epic/Task**: Active work context and progress
- **Agent Coordination**: Multi-agent workflow states and handoffs
- **Quality Gates**: Current testing and validation status
- **Security Context**: Security policies and audit requirements

### 2. Working Context (Session-Specific)
- **File References**: Currently relevant files and their relationships
- **Code Changes**: Recent modifications and their rationale
- **Test Results**: Latest test execution results and coverage
- **Performance Metrics**: Current system performance indicators
- **Error States**: Active issues and debugging context

### 3. Historical Context (Archivable)
- **Completed Tasks**: Finished work items and their outcomes
- **Previous Sessions**: Earlier conversation threads and decisions
- **Archived Files**: Old versions and deprecated implementations
- **Legacy Documentation**: Outdated guides and references
- **Performance History**: Historical metrics and trends

## Context Optimization Strategies

### Smart Context Switching
```markdown
## When to Switch Context:
1. **Task Completion**: After finishing a major epic or milestone
2. **Agent Handoff**: When transferring work between specialized agents
3. **Context Overload**: When response quality degrades due to context size
4. **Phase Transition**: Moving between EPCC phases (Explore → Plan → Code → Commit)
5. **Error Recovery**: After resolving complex debugging sessions
```

### Context Compression Techniques
```markdown
## Compression Methods:
1. **Summary Generation**: Convert verbose logs into key decision points
2. **Pattern Recognition**: Extract recurring themes and standard approaches
3. **State Consolidation**: Merge similar configuration and status information
4. **Reference Optimization**: Replace full file contents with targeted excerpts
5. **Temporal Filtering**: Focus on recent, relevant information over historical data
```

### Context Restoration Patterns
```markdown
## Quick Restoration Commands:
- `/context:restore-project` - Reload core project information
- `/context:restore-epic <name>` - Restore specific epic context  
- `/context:restore-agent <type>` - Restore agent-specific context
- `/context:restore-session <id>` - Reload previous session state
- `/context:restore-full` - Complete context restoration (use sparingly)
```

## Context Templates

### Project Initialization Template
```markdown
# Project Context Template

## Project Overview
**Name:** {PROJECT_NAME}
**Type:** {PROJECT_TYPE}
**Phase:** {CURRENT_PHASE}
**Priority:** {PRIORITY_LEVEL}

## Active Work
**Current Epic:** {EPIC_NAME}
**Status:** {EPIC_STATUS}
**Progress:** {COMPLETION_PERCENTAGE}
**Next Steps:** {IMMEDIATE_ACTIONS}

## Team Context
**Assigned Agents:** {AGENT_LIST}
**Coordination Mode:** {COORDINATION_PATTERN}
**Communication Protocol:** {HANDOFF_RULES}

## Quality Status
**Tests:** {TEST_STATUS}
**Security:** {SECURITY_STATUS}
**Performance:** {PERFORMANCE_STATUS}
**Documentation:** {DOCS_STATUS}

## Critical Files
{ESSENTIAL_FILE_REFERENCES}

## Recent Decisions
{KEY_ARCHITECTURAL_DECISIONS}
```

### Agent Handoff Template
```markdown
# Agent Handoff Context

## Transfer Details
**From Agent:** {SOURCE_AGENT}
**To Agent:** {TARGET_AGENT}
**Transfer Reason:** {HANDOFF_TRIGGER}
**Transfer Time:** {TIMESTAMP}

## Work Package
**Task:** {SPECIFIC_TASK}
**Context:** {TASK_CONTEXT}
**Requirements:** {TASK_REQUIREMENTS}
**Constraints:** {LIMITATIONS}

## Current State
**Progress:** {COMPLETION_STATUS}
**Blockers:** {CURRENT_BLOCKERS}
**Dependencies:** {DEPENDENCY_LIST}
**Resources:** {AVAILABLE_RESOURCES}

## Expected Outcome
**Deliverables:** {EXPECTED_OUTPUTS}
**Success Criteria:** {COMPLETION_CRITERIA}
**Timeline:** {EXPECTED_DURATION}
**Next Handoff:** {SUBSEQUENT_AGENT}
```

### Debug Session Template
```markdown
# Debug Session Context

## Issue Summary
**Problem:** {ISSUE_DESCRIPTION}
**Severity:** {SEVERITY_LEVEL}
**Impact:** {AFFECTED_SYSTEMS}
**First Observed:** {DISCOVERY_TIME}

## Investigation Progress
**Symptoms:** {OBSERVED_SYMPTOMS}
**Hypotheses:** {POTENTIAL_CAUSES}
**Tests Performed:** {DEBUGGING_STEPS}
**Evidence Collected:** {DIAGNOSTIC_DATA}

## Current Focus
**Active Investigation:** {CURRENT_DEBUG_AREA}
**Tools Being Used:** {DEBUG_TOOLS}
**Data Sources:** {LOG_FILES_CONFIGS}
**Team Members:** {INVOLVED_PEOPLE}

## Resolution Strategy
**Approach:** {SOLUTION_APPROACH}
**Rollback Plan:** {EMERGENCY_ROLLBACK}
**Testing Plan:** {VERIFICATION_STRATEGY}
**Communication Plan:** {STAKEHOLDER_UPDATES}
```

## Context Lifecycle Management

### Session Start Protocol
1. **Load Critical Context**: Project identity, active epic, agent assignments
2. **Assess Session Type**: Development, debugging, planning, or maintenance
3. **Load Relevant Templates**: Apply appropriate context templates
4. **Validate Context Completeness**: Ensure all required information is present
5. **Set Context Optimization Rules**: Configure compression and switching triggers

### During Session Management
1. **Monitor Context Growth**: Track context window utilization
2. **Apply Smart Compression**: Automatically compress verbose information
3. **Update Critical Context**: Keep essential information current
4. **Log Key Decisions**: Preserve important architectural and implementation choices
5. **Prepare for Handoffs**: Maintain agent coordination context

### Session End Protocol
1. **Archive Working Context**: Store session-specific information
2. **Update Project State**: Persist progress and status changes
3. **Generate Session Summary**: Create condensed summary for future reference
4. **Clean Temporary Context**: Remove ephemeral debugging and exploration context
5. **Optimize for Next Session**: Prepare clean context for future work

## Context Storage and Retrieval

### File-Based Context Storage
```bash
# Context file organization
.claude/context/
├── critical/          # Never compressed, always available
│   ├── project.md     # Core project information
│   ├── epics/         # Active epic contexts
│   └── agents/        # Agent coordination states
├── working/           # Session-specific context
│   ├── current.md     # Current session context
│   ├── files/         # Relevant file references
│   └── decisions/     # Session decisions and rationale
├── archived/          # Historical context
│   ├── sessions/      # Previous session summaries
│   ├── completed/     # Finished work context
│   └── deprecated/    # Outdated information
└── templates/         # Context templates
    ├── project.md     # Project initialization
    ├── handoff.md     # Agent handoff
    └── debug.md       # Debug session
```

### Context Metadata
```json
{
  "context_id": "unique-session-identifier",
  "created": "timestamp",
  "updated": "timestamp",
  "type": "session|handoff|debug|planning",
  "priority": "critical|working|archived",
  "agents": ["pm-specialist", "code-analyzer"],
  "epic": "epic-name",
  "phase": "explore|plan|code|commit",
  "size_estimate": "token-count-estimate",
  "compression_ratio": "original:compressed-size-ratio",
  "restoration_keys": ["key-information-pointers"]
}
```

## Performance Optimization

### Context Window Monitoring
- Track context utilization as percentage of available window
- Trigger compression at 70% utilization
- Force context switching at 85% utilization
- Monitor response quality degradation patterns

### Intelligent Compression
- Preserve decision rationale over implementation details
- Maintain error patterns and solution approaches
- Keep architectural constraints and design principles
- Archive verbose logs while preserving key insights

### Context Caching
- Cache frequently accessed project information
- Pre-load templates for common session types
- Optimize context restoration for common patterns
- Balance memory usage with restoration speed

## Usage Guidelines

### For Developers
1. Use context templates for consistent session setup
2. Regularly use `/context:cleanup` to maintain performance
3. Document key decisions in persistent context files
4. Coordinate context management across team members

### For Agents
1. Preserve critical context across agent handoffs
2. Compress working context before task completion
3. Update agent coordination context after major actions
4. Use context templates for consistent communication

### For Project Managers
1. Monitor context health across all active epics
2. Ensure context consistency across team members
3. Archive completed epic contexts systematically
4. Maintain strategic context for project continuity

This intelligent context management system ensures optimal Claude Code performance while preserving essential project knowledge and enabling seamless collaboration across agents and team members.