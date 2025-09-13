#!/bin/bash

# CCPM Validation Script - Working Version
# Simple and reliable project validation

# Parse arguments
quick_mode=false
fix_mode=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "CCPM Validation Script"
            echo "Usage: validate [--quick] [--fix] [--help]"
            echo "  --quick  Quick validation (essential files only)"
            echo "  --fix    Auto-fix file permissions"
            echo "  --help   Show this help"
            exit 0
            ;;
        --quick)
            quick_mode=true
            shift
            ;;
        --fix)
            fix_mode=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Display header
if [[ "$quick_mode" == true ]]; then
    echo "🔍 CCPM Quick Validation"
else
    echo "🔍 CCPM Project Validation"
fi
echo "========================="

total=0
passed=0

# Essential Files Check
echo ""
echo "📋 Essential Files"
echo "-------------------"

files=(".claude/CLAUDE.md" ".claude/lib/core.sh" ".claude/lib/ui.sh" ".claude/settings.json")

for file in "${files[@]}"; do
    ((total++))
    if [[ -f "$file" ]]; then
        echo "✅ $(basename "$file")"
        ((passed++))
    else
        echo "❌ Missing: $file"
    fi
done

# Directory Structure Check
echo ""
echo "📁 Directory Structure"
echo "----------------------"

dirs=(".claude" ".claude/lib" ".claude/scripts" ".claude/commands" ".claude/config")

for dir in "${dirs[@]}"; do
    ((total++))
    if [[ -d "$dir" ]]; then
        echo "✅ $(basename "$dir")/"
        ((passed++))
    else
        echo "❌ Missing: $dir"
    fi
done

# JSON Configuration Check (if jq available)
if command -v jq >/dev/null 2>&1; then
    echo ""
    echo "📋 JSON Configuration"
    echo "---------------------"
    
    json_files=(".claude/settings.json" ".claude/commands/index.json")
    
    for json_file in "${json_files[@]}"; do
        if [[ -f "$json_file" ]]; then
            ((total++))
            if jq empty "$json_file" >/dev/null 2>&1; then
                echo "✅ $(basename "$json_file")"
                ((passed++))
            else
                echo "❌ Invalid JSON: $(basename "$json_file")"
            fi
        fi
    done
fi

# Script Permissions Check (if not quick mode)
if [[ "$quick_mode" != true ]]; then
    echo ""
    echo "🔒 Script Permissions"
    echo "---------------------"
    
    fixed_count=0
    
    for script_file in .claude/scripts/*.sh .claude/lib/*.sh; do
        if [[ -f "$script_file" ]]; then
            ((total++))
            if [[ -x "$script_file" ]]; then
                echo "✅ $(basename "$script_file")"
                ((passed++))
            elif [[ "$fix_mode" == true ]]; then
                chmod +x "$script_file"
                echo "🔧 Fixed: $(basename "$script_file")"
                ((passed++))
                ((fixed_count++))
            else
                echo "⚠️ Not executable: $(basename "$script_file")"
            fi
        fi
    done
    
    if [[ "$fixed_count" -gt 0 ]]; then
        echo "ℹ️ Fixed permissions for $fixed_count scripts"
    fi
fi

# Results
echo ""
echo "📊 Validation Results"
echo "====================="
echo "Passed: $passed/$total"
echo ""

if [[ $passed -eq $total ]]; then
    echo "🎉 All checks passed!"
    echo "✅ Project is ready for development!"
    echo ""
    exit 0
else
    echo "⚠️ Some checks failed."
    echo "Please fix the issues above and re-run validation."
    echo ""
    
    if [[ "$quick_mode" == true ]]; then
        echo "💡 Tip: Run 'bash .claude/scripts/validate.sh' for comprehensive validation"
    else
        echo "💡 Tip: Run with --fix to auto-repair permission issues"
    fi
    echo ""
    exit 1
fi