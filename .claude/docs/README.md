# CCPM Documentation

Comprehensive documentation for the Claude Code Project Manager framework.

## Directory Structure

```
docs/
├── README.md                    # This file
├── workflows/                   # Development workflow guides
│   ├── epcc-workflow-guide.md   # Explore-Plan-Code-Commit pattern
│   ├── context-manager.md       # Context management strategies
│   ├── project-overview.md      # Project overview generation
│   └── context-overview.md      # Context system overview
├── patterns/                    # Development patterns and practices
│   ├── standard-patterns.md     # Standard development patterns
│   ├── agent-coordination.md    # Agent coordination patterns
│   └── worktree-operations.md   # Git worktree usage patterns
└── guidelines/                  # Technical guidelines and rules
    ├── github-operations.md     # GitHub integration guidelines
    ├── branch-operations.md     # Git branch management
    ├── frontmatter-operations.md # Frontmatter handling rules
    ├── datetime.md              # Date/time operations
    ├── use-ast-grep.md          # AST-grep usage guidelines
    ├── strip-frontmatter.md     # Frontmatter stripping rules
    └── test-execution.md        # Test execution guidelines
```

## Documentation Categories

### Workflows
**Development process guides and methodologies**
- **EPCC Pattern**: Explore-Plan-Code-Commit development methodology
- **Context Management**: Strategies for optimizing Claude Code context
- **Project Overviews**: Generating and maintaining project documentation

### Patterns  
**Reusable development patterns and best practices**
- **Standard Patterns**: Common development patterns and approaches
- **Agent Coordination**: Multi-agent collaboration patterns
- **Worktree Operations**: Parallel development using git worktrees

### Guidelines
**Technical rules and operational procedures**
- **GitHub Operations**: Repository management and integration
- **Branch Operations**: Git workflow and branch management
- **Code Processing**: File handling, frontmatter, and AST operations  
- **Testing**: Test execution and validation procedures

## Usage

### For Developers
- **Getting Started**: Read workflows/epcc-workflow-guide.md
- **Best Practices**: Review patterns/standard-patterns.md
- **Technical Rules**: Follow guidelines as needed for specific operations

### For Framework Maintainers  
- **Agent Design**: Reference patterns/agent-coordination.md
- **Testing**: Follow guidelines/test-execution.md
- **Git Operations**: Use guidelines/branch-operations.md

### For Project Managers
- **Process Overview**: Start with workflows/project-overview.md
- **Context Planning**: Use workflows/context-manager.md

## Key Principles

### Agent-First Development
All workflows are designed around Claude Code's agent system:
- Use specialized agents for domain expertise
- Coordinate multiple agents for complex tasks
- Optimize context for agent performance

### Quality Assurance
Documentation emphasizes quality through:
- Comprehensive testing strategies
- Code review processes  
- Standardized patterns and practices

### Continuous Improvement
Documentation evolves with:
- Regular pattern updates
- Workflow optimization
- New agent integration

## Integration with CCPM

This documentation integrates with CCPM framework components:
- **Commands**: Reference these docs for implementation details
- **Agents**: Follow patterns for consistent agent design
- **Scripts**: Implement guidelines in script development
- **Configuration**: Use patterns for config file structure

## Contributing

When adding new documentation:
1. **Place in appropriate category** (workflows/patterns/guidelines)
2. **Follow existing format** and naming conventions  
3. **Update this README** with new file references
4. **Test documentation** with actual development workflows

## Quick Reference

### Most Used Documents
- `workflows/epcc-workflow-guide.md` - Core development methodology
- `patterns/agent-coordination.md` - Multi-agent workflows
- `guidelines/github-operations.md` - Repository management

### For Troubleshooting
- `workflows/context-manager.md` - Context optimization issues
- `guidelines/test-execution.md` - Testing problems
- `patterns/worktree-operations.md` - Parallel development issues