---
allowed-tools: Task, Bash, Read, Write, Edit, MultiEdit, Grep, Glob
argument-hint: [issue_number]
description: Comprehensive GitHub issue resolution workflow using multiple specialist agents with quality gates
model: inherit
---

# Fix GitHub Issue Command

Please analyze and fix the GitHub issue: $ARGUMENTS.

## Workflow Steps

### 1. Explore Phase
- Use the **github-specialist** agent to gather issue details: `gh issue view $ARGUMENTS`
- Use the **code-analyzer** agent to search the codebase for relevant files
- Use the **file-analyzer** agent to understand the current implementation
- Identify the root cause and scope of the issue

### 2. Plan Phase  
- Think hard about the problem and potential solutions
- Create a detailed implementation plan with the **pm-specialist** agent
- Identify any dependencies or breaking changes
- Estimate complexity and timeline

### 3. Code Phase
- Implement the necessary changes to fix the issue
- Write comprehensive tests using the **test-runner** agent
- Use the **shell-auditor** agent to validate script security if applicable
- Ensure code passes all quality checks (linting, type checking, etc.)

### 4. Commit Phase
- Create a descriptive commit message linking to the issue
- Use the **github-specialist** agent to update the issue with progress
- Push changes and create a pull request
- Ensure all CI/CD checks pass

## Quality Gates

- [ ] Issue is clearly understood and reproducible
- [ ] Root cause has been identified
- [ ] Solution addresses the core problem  
- [ ] Tests cover the fix and prevent regression
- [ ] Code follows project standards and conventions
- [ ] Security implications have been considered
- [ ] Documentation is updated if necessary
- [ ] Issue is linked to the PR for traceability

## Agent Coordination

Use the **workflow-orchestrator** agent to coordinate between specialists and ensure all quality gates are met before considering the issue resolved.

Remember: Focus on fixing the root cause, not just the symptoms. Ensure the solution is robust, tested, and maintainable.