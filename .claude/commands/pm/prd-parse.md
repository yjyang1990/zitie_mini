---
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, LS, Task
argument-hint: [feature_name] [--template] [--force] [--dry-run] [--detailed] [--minimal]
description: Comprehensive PRD-to-Epic conversion system with intelligent technical analysis, architecture planning, and automated epic structure generation
model: inherit
---

# PRD to Epic Conversion System

Comprehensive PRD-to-Epic conversion system with intelligent technical analysis, sophisticated architecture planning, automated epic structure generation, and seamless development workflow integration.

## Usage

```bash
/pm:prd-parse feature-name                          # Standard PRD to epic conversion
/pm:prd-parse feature-name --template=web-app       # Use specific epic template
/pm:prd-parse feature-name --detailed               # Detailed technical analysis
/pm:prd-parse feature-name --minimal                # Minimal epic structure
/pm:prd-parse feature-name --force                  # Overwrite existing epic
/pm:prd-parse feature-name --dry-run                # Preview conversion process
/pm:prd-parse feature-name --template=api --dry-run # Preview with template
```

## Implementation

The PRD to Epic conversion functionality is implemented in `.claude/scripts/pm/prd-parse.sh`. This command provides comprehensive PRD-to-Epic conversion with intelligent technical analysis, sophisticated architecture planning, automated epic structure generation, and seamless development workflow integration.

## Agent-Assisted Enhancement

For superior results, consider using CCPM's specialized agents to enhance the PRD parsing process:

**Recommended Agent Workflow:**
1. **"Please use the pm-specialist agent to analyze this PRD and create a structured epic with proper task breakdown"**
   - Leverages project management expertise for better epic structure
   - Ensures industry-standard task organization and dependency mapping

2. **"Use the system-architect agent to design the technical implementation approach for this epic"**
   - Provides architecture-level thinking and technology decisions
   - Identifies potential technical challenges and solutions

3. **"Deploy the code-analyzer agent to examine existing codebase and identify integration points"**
   - Analyzes current code structure for implementation planning
   - Identifies potential conflicts or areas requiring refactoring

This agent-assisted approach provides significantly better analysis than basic script automation.

## Error Handling

**Common Issues:**
- **PRD file missing**: Source PRD doesn't exist or incorrect path
- **Invalid PRD format**: Malformed frontmatter or missing required fields
- **Epic already exists**: Target epic exists without force flag
- **Directory permissions**: Cannot create epic directory structure
- **Template conflicts**: Template mismatch between PRD and epic
- **Content analysis failure**: Unable to extract technical requirements
- **Validation failures**: Generated epic doesn't meet quality standards

**Recovery Steps:**
1. **PRD file missing**: Create PRD first with `/pm:prd-new <feature-name>`
2. **Invalid PRD format**: Fix PRD frontmatter and required sections
3. **Epic already exists**: Use `--force` to overwrite or choose different name
4. **Directory permissions**: Check permissions and manually create `.claude/epics/`
5. **Template conflicts**: Specify compatible template with `--template` option
6. **Content analysis failure**: Review PRD content and add missing sections
7. **Validation failures**: Review generated epic and customize as needed

## Features

- **Comprehensive PRD analysis**: Deep analysis of PRD content with intelligent requirement extraction
- **Template-based architecture planning**: Specialized architecture patterns for different project types
- **Intelligent task breakdown**: Smart consolidation of tasks with complexity-based organization
- **Technical decision mapping**: Automatic identification of key architecture decisions
- **Quality validation system**: Multi-layer validation of generated epic structure and content
- **Flexible conversion modes**: Dry-run preview, minimal/detailed modes, and force overwrite
- **Development workflow integration**: Seamless connection to epic management and task decomposition
- **Professional epic structure**: Industry-standard epic format with comprehensive technical planning