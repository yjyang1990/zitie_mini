---
allowed-tools: Task, Read, Bash, Grep, Glob
argument-hint: [epic_name]
description: Generate comprehensive epic status report using pm-specialist agent with detailed progress analysis
model: inherit
---

# Epic Status Report Command

Generate a comprehensive status report for the specified epic: $ARGUMENTS.

## Use the pm-specialist Agent

IMPORTANT: Use the **pm-specialist** agent to generate this report, as it has specialized knowledge of epic management and project tracking.

## Report Sections

### 1. Epic Overview
- Epic name, description, and current status
- Creation date and last update timestamp
- Associated PRD and requirements traceability
- Priority level and business value assessment

### 2. Task Breakdown Analysis
- Total number of tasks in the epic
- Tasks by status: open, in-progress, completed, blocked
- Task completion percentage and progress trends
- Critical path analysis and dependencies

### 3. GitHub Integration Status
- Linked GitHub issues and their current state
- Pull requests associated with the epic
- GitHub milestone progress and targets
- Label consistency and metadata validation

### 4. Timeline and Progress Tracking
- Original timeline vs. actual progress
- Estimated completion date based on current velocity
- Milestone achievements and missed deadlines
- Velocity trends and performance metrics

### 5. Blocker and Risk Analysis
- Current blockers and impediments
- Risk factors affecting timeline
- Dependency issues with other epics
- Resource allocation concerns

### 6. Quality Metrics
- Code review status for completed tasks
- Test coverage for epic-related code
- Security audit status
- Documentation completeness

## Interactive Elements

### If no epic name provided:
- List all available epics with basic status
- Suggest which epics might need attention
- Provide epic selection guidance

### If epic doesn't exist:
- Show available epics
- Provide epic creation guidance
- Suggest similar epic names (typo detection)

## Output Format

Generate a well-formatted report using:
- Clear section headers and organization
- Progress bars and percentage indicators
- Color-coded status indicators (🟢 🟡 🔴)
- Actionable recommendations
- Links to relevant GitHub issues and PRs

## Example Usage

```bash
/workflow:epic-status user-authentication
/workflow:epic-status payment-integration
/workflow:epic-status                    # shows all epics
```

## Integration with Other Tools

- Use **github-specialist** for GitHub data accuracy
- Use **workflow-orchestrator** for dependency analysis
- Cross-reference with project-wide metrics and KPIs

## Actionable Insights

The report should conclude with:
- Top 3 priorities for epic progression
- Specific next steps and responsible parties
- Risk mitigation strategies
- Resource reallocation recommendations

This command is essential for project managers, stakeholders, and team leads who need comprehensive visibility into epic progress and health.