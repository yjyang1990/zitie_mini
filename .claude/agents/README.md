# CCPM Agent System

This directory contains the complete agent ecosystem for Claude Code development workflows.

## Directory Structure

```
agents/
├── registry.json              # Agent registry and selection rules
├── README.md                  # This file
├── core/                      # Fundamental analysis agents
│   ├── code-analyzer.md       # Code search and analysis
│   ├── file-analyzer.md       # File content analysis
│   └── test-runner.md         # Test execution and analysis
├── specialists/               # Domain expert agents  
│   ├── system-architect.md    # Architecture design
│   ├── backend-engineer.md    # Backend development
│   ├── frontend-engineer.md   # Frontend development
│   ├── devops-engineer.md     # DevOps and infrastructure
│   ├── test-engineer.md       # Testing strategies
│   ├── ui-expert.md           # UI/UX implementation
│   └── shell-auditor.md       # Shell script auditing
└── coordinators/              # Orchestration and management
    ├── workflow-orchestrator.md  # Multi-agent coordination
    ├── parallel-worker.md        # Parallel development
    ├── pm-specialist.md          # Project management
    └── github-specialist.md      # GitHub integration
```

## Agent Categories

### Core Agents (Priority 1)
**Always available for fundamental operations**
- `code-analyzer` - Code search, bug analysis, logic tracing
- `file-analyzer` - File content analysis, log parsing
- `test-runner` - Test execution with comprehensive analysis

### Specialists (Priority 2)  
**Domain experts for specific technical areas**
- `system-architect` - Architecture design and technology selection
- `backend-engineer` - API development, databases, server optimization
- `frontend-engineer` - UI components, state management, frameworks
- `devops-engineer` - CI/CD, containerization, cloud deployment
- `test-engineer` - Testing strategies and automation frameworks
- `ui-expert` - UI/UX design and accessibility implementation
- `shell-auditor` - Shell script security and best practices

### Coordinators (Priority 3)
**Orchestration and high-level management**
- `workflow-orchestrator` - Multi-agent workflow coordination
- `parallel-worker` - Parallel development in git worktrees
- `pm-specialist` - Project management and requirements analysis
- `github-specialist` - GitHub integration and repository management

## How to Use Agents

### Natural Language Invocation
Instead of calling agents directly, use natural language that triggers the appropriate agent:

```markdown
# Triggers code-analyzer
"Analyze this authentication flow and trace potential security issues"
"Search the codebase for all usage of the UserService class"

# Triggers system-architect  
"Design a scalable architecture for this microservices system"
"What's the best technology stack for this requirements?"

# Triggers test-runner
"Run all tests and analyze any failures in detail"
"Execute the authentication tests and provide comprehensive results"

# Triggers workflow-orchestrator
"Coordinate multiple agents to implement this feature end-to-end"
"Orchestrate a complete code review process across multiple components"
```

### Direct Agent Requests
For specific agent usage:

```markdown
# Direct agent invocation
"Use the file-analyzer agent to summarize this 10MB log file"
"Deploy the backend-engineer agent to implement this REST API"
"Have the github-specialist agent create issues from this epic"
```

## Workflow Patterns

### Feature Development
1. **system-architect** - Design technical approach
2. **backend-engineer** + **frontend-engineer** - Parallel implementation
3. **test-runner** - Comprehensive testing
4. **github-specialist** - PR creation and integration

### Bug Investigation
1. **code-analyzer** - Root cause analysis and logic tracing
2. **Auto-selected specialist** - Implement appropriate fix
3. **test-runner** - Verification and regression testing

### Architecture Review
1. **system-architect** - Current architecture analysis
2. **system-architect** - Improvement recommendations  
3. **workflow-orchestrator** - Implementation planning

## Best Practices

### Agent Selection
- **Let auto-selection work** - The registry uses keyword matching and priority
- **Be specific in requests** - Clear descriptions trigger better agent selection
- **Use workflow-orchestrator** - For complex multi-step operations

### Context Optimization
- **Use file-analyzer** - For large files before other agents analyze them
- **Clear context** - Use `/clear` between major agent task transitions
- **Batch related operations** - Group similar tasks for the same agent

### Quality Assurance
- **Always use test-runner** - For any testing operations
- **Leverage shell-auditor** - For script security and quality
- **Coordinate with github-specialist** - For repository operations

## Agent Communication

Agents are designed to work together through:
- **Shared context** - Information flows between related agents
- **Handoff protocols** - Clean transitions between agent phases
- **Result integration** - Consolidated outputs from parallel agents

## Troubleshooting

### Agent Selection Issues
- Check trigger keywords in registry.json
- Use workflow-orchestrator as fallback
- Be more specific in agent requests

### Performance Issues
- Use file-analyzer for large files first
- Clear context regularly
- Prefer parallel-worker for independent tasks

### Quality Issues
- Ensure test-runner is used for all testing
- Use appropriate specialist for domain expertise
- Leverage coordinators for complex workflows