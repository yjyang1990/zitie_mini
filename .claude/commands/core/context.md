---
description: Simple project context management for Claude Code sessions
argument-hint: [create|prime|update|cleanup]
---

# Simple Context Manager

Manage project context for Claude Code sessions with essential functionality only.

## Usage

```bash
/context create     # Generate project overview
/context prime      # Display project context (good for new sessions)  
/context update     # Refresh project metrics
/context cleanup    # Remove generated context
```

## Implementation

```bash
CONTEXT_SCRIPT=".claude/scripts/context-manager.sh"

if [[ -f "$CONTEXT_SCRIPT" && -x "$CONTEXT_SCRIPT" ]]; then
    bash "$CONTEXT_SCRIPT" "$@"
else
    echo "❌ Context manager script not found: $CONTEXT_SCRIPT"
    exit 1
fi
```

Simple, focused, no over-engineering.