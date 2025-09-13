---
allowed-tools: Task, Read, Write, Edit, Bash
argument-hint: [architectural_problem]
description: Advanced architectural analysis using Claude Code's ultrathink reasoning mode with specialist agent coordination
model: inherit
---

# Deep Architectural Thinking Command

**IMPORTANT: This command uses Claude Code's advanced "ultrathink" reasoning mode for complex architectural decisions.**

Please think **ultrathink** about the architectural problem: $ARGUMENTS

## Deep Analysis Framework

### 1. Problem Space Exploration
- **Current State Analysis**: What is the existing architecture and its limitations?
- **Stakeholder Impact**: How does this decision affect different user groups?
- **Technical Constraints**: What are the hard technical limitations we must respect?
- **Business Constraints**: What are the business requirements and trade-offs?
- **Timeline Constraints**: What is the urgency and available time for implementation?

### 2. Solution Space Generation  
- **Alternative Approaches**: Generate 3-5 fundamentally different architectural approaches
- **Hybrid Solutions**: Consider combinations and variations of the primary approaches
- **Future-Proofing**: How will each solution adapt to future requirements?
- **Scalability Analysis**: How will each solution perform at 10x, 100x current scale?
- **Technology Evolution**: How do emerging technologies affect these choices?

### 3. Deep Trade-off Analysis
- **Performance vs Maintainability**: Analyze the spectrum and optimal balance points
- **Flexibility vs Simplicity**: When does added complexity provide sufficient value?
- **Cost vs Capability**: Short-term and long-term cost implications
- **Risk vs Reward**: Probability and impact analysis for each approach
- **Team Capability**: What can the current team realistically implement and maintain?

### 4. Implementation Strategy
- **Phased Rollout**: How to implement incrementally with measurable milestones
- **Rollback Strategy**: How to safely revert if the approach doesn't work
- **Resource Requirements**: Detailed breakdown of time, people, and technology needs
- **Success Metrics**: How will we measure if this architectural decision was correct?
- **Monitoring Strategy**: How will we detect problems early and adjust course?

### 5. Decision Documentation
- **Architecture Decision Record (ADR)**: Create formal documentation of the decision
- **Team Communication**: How to effectively communicate this decision to all stakeholders
- **Knowledge Transfer**: How to ensure the decision rationale is preserved
- **Review Schedule**: When and how to revisit this architectural decision
- **Update Triggers**: What changes would necessitate reconsidering this decision?

## Context Integration

### Use Multiple Specialist Agents:
- **system-architect**: For high-level system design analysis
- **code-analyzer**: For technical feasibility and impact analysis
- **pm-specialist**: For timeline and resource planning
- **shell-auditor**: For security and operational considerations

### Leverage Project Memory:
- Reference previous architectural decisions and their outcomes
- Consider established patterns and conventions in the codebase
- Build upon existing infrastructure and team knowledge
- Align with long-term project vision and roadmap

### Quality Gates:
- [ ] All stakeholder perspectives considered
- [ ] Alternative approaches thoroughly evaluated  
- [ ] Trade-offs explicitly documented with rationale
- [ ] Implementation plan is realistic and actionable
- [ ] Success criteria and monitoring plan defined
- [ ] Team consensus achieved on the approach
- [ ] Documentation created for future reference

## Output Format

Provide your architectural analysis in this structure:

### Executive Summary
- **Problem**: One-sentence problem statement
- **Recommended Solution**: One-sentence solution summary
- **Key Trade-offs**: Top 3 trade-offs being made
- **Implementation Timeline**: High-level timeline estimate

### Detailed Analysis
[Your ultrathink analysis following the framework above]

### Architecture Decision Record
```markdown
# ADR-XXX: [Decision Title]

**Status**: Proposed
**Date**: [Current Date]
**Decision Makers**: [Team/Stakeholders]

## Context
[Problem and constraints]

## Decision
[Chosen approach and rationale]

## Consequences
[Expected benefits and risks]

## Alternatives Considered
[Other options and why they were not chosen]
```

### Next Steps
- [ ] Specific actionable items with owners and timelines
- [ ] Risk mitigation plans
- [ ] Communication and alignment tasks
- [ ] Technical prototype or proof-of-concept plans

This command leverages Claude Code's most advanced reasoning capabilities to ensure architectural decisions are thoroughly analyzed, well-documented, and aligned with both technical excellence and business objectives.