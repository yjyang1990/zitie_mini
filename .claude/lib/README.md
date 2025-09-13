# CCPM Library Structure

After refactoring to eliminate duplicates and improve maintainability.

## Core Libraries (Load Order)

1. **core.sh** - Essential functions, error handling, validation
   - GitHub operations
   - Date/time operations  
   - Path operations
   - Configuration loading
   - Validation functions
   - Logging functions

2. **config.sh** - Configuration management (depends on core.sh)
   - Configuration loading from JSON
   - Environment setup
   - User preferences

3. **ui.sh** - User interface and formatting (depends on core.sh)
   - Progress bars
   - Interactive prompts
   - Output formatting

4. **utils.sh** - Utility functions (depends on core.sh)
   - File operations
   - String manipulation
   - Helper functions

## Specialized Libraries

- **project-detection.sh** - Project type detection
- **validation.sh** - Extended validation (DEPRECATED - merged into core.sh)
- **common-functions.sh** - Legacy functions (DEPRECATED - merged into core.sh)
- **workflow-suggestions.sh** - Workflow recommendation engine
- **caching.sh** - Caching system
- **formatting.sh** - Advanced formatting
- **ux.sh** - User experience helpers

## Usage

Always source core.sh first:

```bash
#!/bin/bash
set -euo pipefail

# Load CCPM core
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$SCRIPT_DIR")/lib/core.sh"

# Load additional libraries as needed
source "$CLAUDE_DIR/lib/ui.sh"
source "$CLAUDE_DIR/lib/utils.sh"
```

## Migration Notes

- All scripts should be updated to use core.sh instead of common-functions.sh
- validation.sh functions are now in core.sh
- Configuration loading is standardized through load_config() function