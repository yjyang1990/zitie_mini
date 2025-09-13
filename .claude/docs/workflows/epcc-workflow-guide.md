# EPCC (Explore-Plan-Code-Commit) Workflow Guide

## Overview

The EPCC (Explore-Plan-Code-Commit) pattern is the foundational workflow for all development activities in the CCPM project. This guide provides detailed implementation patterns and best practices for each phase.

## Phase 1: Explore 🔍

### Objective
Thoroughly understand the context, requirements, and existing codebase before any implementation begins.

### Key Activities:

#### Context Gathering:
- **Use file-analyzer agent** for comprehensive file analysis
- **Use code-analyzer agent** for logic tracing and vulnerability detection
- Read relevant documentation, PRDs, and existing code
- Understand dependencies and integration points

#### Information Collection:
```bash
# Essential exploration commands
gh issue view <issue-number>           # Understand the problem
bats tests/unit/*.bats                 # Review existing tests
grep -r "relevant_function" .claude/   # Find related implementations
git log --oneline -10                  # Recent changes context
```

#### Quality Gates:
- [ ] Problem statement is clearly understood
- [ ] Existing implementation is thoroughly reviewed
- [ ] Dependencies and constraints are identified
- [ ] Test coverage and quality standards are assessed
- [ ] Resource requirements are estimated

### Anti-Patterns to Avoid:
- ❌ Jumping directly to coding without understanding
- ❌ Skipping existing code analysis
- ❌ Ignoring test coverage and quality metrics
- ❌ Missing dependency analysis

## Phase 2: Plan 🎯

### Objective
Create a detailed, actionable implementation plan using advanced reasoning capabilities.

### Key Activities:

#### Deep Thinking:
- Use **"think hard"** for complex technical problems
- Use **"think harder"** for architectural decisions
- Use **"ultrathink"** for critical system changes
- Consider multiple solution approaches and trade-offs

#### Planning with Specialists:
- **pm-specialist agent**: For project management and epic coordination
- **workflow-orchestrator agent**: For multi-agent coordination
- **shell-auditor agent**: For security and quality planning

#### Plan Documentation:
```markdown
## Implementation Plan

### Approach:
- [ ] Solution architecture and design decisions
- [ ] File changes and new components required
- [ ] Test strategy and coverage plan
- [ ] Migration or rollback procedures

### Timeline:
- [ ] Task breakdown with effort estimates
- [ ] Dependencies and critical path
- [ ] Quality milestones and checkpoints
- [ ] Risk mitigation strategies

### Quality Assurance:
- [ ] Testing approach and test cases
- [ ] Security considerations and audits
- [ ] Performance requirements and validation
- [ ] Documentation and knowledge transfer
```

#### Quality Gates:
- [ ] Solution architecture is sound and scalable
- [ ] Implementation steps are clearly defined
- [ ] Test strategy covers all scenarios
- [ ] Security implications are addressed
- [ ] Performance impact is assessed

### Best Practices:
- ✅ Create GitHub issues or project documents for complex plans
- ✅ Get plan review and approval before implementation
- ✅ Consider multiple solution alternatives
- ✅ Plan for rollback and error handling

## Phase 3: Code 💻

### Objective
Implement the solution iteratively with continuous testing and validation.

### Key Activities:

#### Test-Driven Implementation:
```bash
# TDD cycle within Code phase
1. Write failing tests first
   bats tests/unit/test_new_feature.bats
   
2. Implement minimal code to pass tests
   edit .claude/lib/new_feature.sh
   
3. Run tests and iterate
   bats tests/unit/test_new_feature.bats
   
4. Refactor and improve
   # Use shell-auditor for quality review
```

#### Multi-Agent Collaboration:
- **test-runner agent**: Continuous testing and validation
- **shell-auditor agent**: Code quality and security review
- **github-specialist agent**: GitHub integration and coordination

#### Quality Assurance:
```bash
# Continuous quality checks
shellcheck .claude/scripts/*.sh        # Static analysis
bats tests/unit/*.bats                # Unit testing  
bash .claude/lib/validation.sh        # Configuration validation
/project:health-check                 # Comprehensive system check
```

#### Quality Gates:
- [ ] All tests pass with comprehensive coverage
- [ ] Code follows project standards and conventions
- [ ] Security audit shows no vulnerabilities
- [ ] Performance meets required benchmarks
- [ ] Documentation is updated appropriately

### Implementation Patterns:
- ✅ Implement incrementally with frequent testing
- ✅ Use sub-agents for specialized tasks
- ✅ Validate changes against existing functionality
- ✅ Maintain backward compatibility where required

## Phase 4: Commit 🚀

### Objective
Finalize the implementation with proper documentation, testing, and version control.

### Key Activities:

#### Final Validation:
```bash
# Comprehensive final checks
/project:test-all                      # Full test suite
/project:health-check                  # System health validation
bats tests/integration/*.bats          # Integration testing
bash .claude/scripts/security-audit.sh # Security final check
```

#### Git Operations:
```bash
# Commit workflow
git status                             # Review changes
git add .                              # Stage changes
git commit -m "feat: implement feature XYZ

- Add new functionality for user authentication
- Include comprehensive test coverage  
- Update documentation and examples
- Maintain backward compatibility

Fixes: #123
Tests: All passing
Security: Audited and approved

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push origin feature/branch         # Push to remote
```

#### GitHub Integration:
```bash
# Create pull request with comprehensive details
gh pr create --title "Add user authentication feature" \
--body "$(cat <<'EOF'
## Summary
- Implements secure user authentication system
- Adds comprehensive test coverage
- Updates documentation with usage examples

## Testing
- [x] Unit tests: 100% pass rate
- [x] Integration tests: All scenarios covered  
- [x] Security audit: No vulnerabilities found
- [x] Performance: Within acceptable benchmarks

## Breaking Changes
None - maintains full backward compatibility

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

#### Quality Gates:
- [ ] All tests pass in final validation
- [ ] Code quality meets all standards
- [ ] Documentation is complete and accurate
- [ ] Security audit shows clean results
- [ ] Pull request includes comprehensive description
- [ ] Commit message follows project conventions

### Commit Best Practices:
- ✅ Include comprehensive commit messages with context
- ✅ Link to relevant issues and documentation
- ✅ Ensure all quality gates are met
- ✅ Include test results and security validation

## EPCC Workflow Integration

### With Git Worktrees:
```bash
# Parallel EPCC workflows
git worktree add ../ccpm-feature-a feature-a
cd ../ccpm-feature-a

# Run complete EPCC cycle in worktree
1. Explore: Understand feature requirements
2. Plan: Design implementation approach  
3. Code: Implement with testing
4. Commit: Finalize and create PR
```

### With Multi-Agent Coordination:
- **workflow-orchestrator**: Manages overall EPCC progression
- **Specialist agents**: Handle phase-specific expertise
- **Context management**: Maintains information across phases
- **Quality gates**: Ensure standards at each transition

## Success Metrics

### Phase Completion Indicators:
- **Explore**: Context fully understood, no unknown dependencies
- **Plan**: Detailed implementation plan approved and documented
- **Code**: All tests pass, quality standards met
- **Commit**: Changes merged and deployed successfully

### Overall EPCC Success:
- Feature delivers expected value
- Implementation is maintainable and secure
- Knowledge is properly documented and transferred
- Team productivity is enhanced, not hindered

## Common Anti-Patterns

### Explore Phase:
- ❌ Rushing to implementation without full context
- ❌ Skipping existing code analysis
- ❌ Ignoring test coverage assessment

### Plan Phase:
- ❌ Creating vague or incomplete implementation plans
- ❌ Skipping architecture review and approval
- ❌ Missing risk assessment and mitigation

### Code Phase:
- ❌ Implementing without tests
- ❌ Ignoring code quality standards
- ❌ Skipping security considerations

### Commit Phase:
- ❌ Committing without final validation
- ❌ Poor commit messages and documentation
- ❌ Missing pull request context and links

The EPCC pattern ensures high-quality, well-tested, and maintainable code while maximizing team productivity and minimizing risks.