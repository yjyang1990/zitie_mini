#!/bin/bash
# Quick validation test for CCPM core functionality v2.0

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 CCPM v2.0 Quick Validation Test${NC}"
echo "=================================="

# Test 1: Check library files exist (v2.0 structure)
echo -n "📁 Checking core library files... "
if [[ -f ".claude/lib/core.sh" && -f ".claude/lib/ui.sh" ]]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Missing core libraries${NC}"
    exit 1
fi

# Test 2: Check if libraries can be sourced
echo -n "📚 Loading libraries... "
source ".claude/lib/core.sh" 2>/dev/null && \
source ".claude/lib/ui.sh" 2>/dev/null && \
echo -e "${GREEN}✓ Loaded${NC}" || {
    echo -e "${RED}✗ Failed${NC}"
    exit 1
}

# Test 3: Check key functions exist (v2.0 functions)
echo -n "🔧 Checking key functions... "
MISSING_FUNCS=()
for func in "get_timestamp" "log_info" "find_project_root" "validate_project_structure"; do
    if ! declare -F "$func" > /dev/null 2>&1; then
        MISSING_FUNCS+=("$func")
    fi
done

if [[ ${#MISSING_FUNCS[@]} -eq 0 ]]; then
    echo -e "${GREEN}✓ Available${NC}"
else
    echo -e "${RED}✗ Missing: ${MISSING_FUNCS[*]}${NC}"
    exit 1
fi

# Test 4: Test basic functionality
echo -n "⚡ Testing basic functions... "

# Test get_timestamp
if timestamp=$(get_timestamp 2>/dev/null) && [[ -n "$timestamp" ]]; then
    # Test find_project_root
    if project_root=$(find_project_root 2>/dev/null) && [[ -n "$project_root" ]]; then
        echo -e "${GREEN}✓ Working${NC}"
    else
        echo -e "${RED}✗ find_project_root failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ get_timestamp failed${NC}"
    exit 1
fi

# Test 5: Check project structure (v2.0)
echo -n "📂 Checking project structure... "
REQUIRED_DIRS=(".claude/lib" ".claude/scripts/pm" ".claude/agents" ".claude/commands" "tests")
MISSING_DIRS=()

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        MISSING_DIRS+=("$dir")
    fi
done

if [[ ${#MISSING_DIRS[@]} -eq 0 ]]; then
    echo -e "${GREEN}✓ Complete${NC}"
else
    echo -e "${YELLOW}⚠ Missing: ${MISSING_DIRS[*]}${NC}"
fi

# Test 6: Count available PM scripts
echo -n "🛠  PM scripts available... "
pm_script_count=$(find .claude/scripts/pm -name "*.sh" -type f | wc -l | xargs)
echo -e "${GREEN}$pm_script_count scripts${NC}"

# Test 7: Count available agents
echo -n "🤖 AI agents available... "
agent_count=$(find .claude/agents -name "*.md" -type f | wc -l | xargs)
echo -e "${GREEN}$agent_count agents${NC}"

# Test 8: Count available commands
echo -n "⚡ Custom commands available... "
command_count=$(find .claude/commands -name "*.md" -type f | wc -l | xargs)
echo -e "${GREEN}$command_count commands${NC}"

# Test 9: Verify version
echo -n "📦 Checking CCPM version... "
if [[ "$CCPM_VERSION" == "2.0" ]]; then
    echo -e "${GREEN}v$CCPM_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Version: ${CCPM_VERSION:-unknown}${NC}"
fi

echo ""
echo -e "${GREEN}🎉 CCPM v2.0 core functionality validated!${NC}"
echo -e "Ready for deployment to other projects."
echo ""
echo "📋 Usage:"
echo "  1. Copy entire .claude/ directory to your project"
echo "  2. Run bootstrap: bash .claude/bootstrap.sh"
echo "  3. Start using PM commands: /pm:init"
echo "  4. Access agents with Task tool in Claude Code"

exit 0