---
allowed-tools: Bash
argument-hint: [feature_name] [--template] [--interactive] [--dry-run] [--force]
description: Comprehensive PRD creation system with intelligent brainstorming, template selection, and interactive requirement gathering
model: inherit
---

# Product Requirements Document Creation System

Comprehensive PRD creation system with intelligent brainstorming capabilities, template selection, interactive requirement gathering, and automated validation.

## Usage

```bash
/pm:prd-new feature-name                          # Interactive PRD creation
/pm:prd-new feature-name --template=web-app       # Use specific template
/pm:prd-new feature-name --interactive             # Full interactive mode
/pm:prd-new feature-name --dry-run                 # Preview PRD structure
/pm:prd-new feature-name --force                   # Overwrite existing PRD
/pm:prd-new feature-name --template=api --dry-run  # Preview with template
```

## Templates Available

- **standard** - Comprehensive feature development (default)
- **web-app** - Frontend applications with UI/UX focus
- **api** - Backend services and API development
- **mobile-app** - Mobile applications (iOS/Android)
- **integration** - System integrations and connectors
- **data-pipeline** - Data processing and ETL systems
- **ml-feature** - Machine learning and AI features
- **infrastructure** - Infrastructure and DevOps projects

## Implementation

The PRD creation functionality is implemented in `.claude/scripts/pm/prd-new.sh`. This command provides comprehensive PRD creation with intelligent brainstorming capabilities, template selection, and interactive requirement gathering.

## Features

- **8 specialized templates** for different project types
- **Interactive brainstorming mode** with guided discovery questions
- **Quality validation** with completeness checking
- **Professional PRD structure** with comprehensive sections
- **Template-specific content** tailored to project needs
- **Dry-run preview** to validate structure before creation
- **Force overwrite** for updating existing PRDs
- **Integration ready** for epic creation workflow

## Error Handling

**Common Issues:**
- **Invalid feature name**: Must be kebab-case format (lowercase, hyphens only)
- **Existing PRD conflict**: PRD already exists without --force flag
- **Directory creation failure**: Check permissions for .claude/prds directory
- **Template not found**: Use valid template name from list above

**Recovery Steps:**
1. **Invalid name**: Use lowercase letters, numbers, and hyphens only
2. **Existing PRD**: Use --force to overwrite or choose different name
3. **Directory issues**: Run `mkdir -p .claude/prds` manually
4. **Template issues**: Check available templates in usage section