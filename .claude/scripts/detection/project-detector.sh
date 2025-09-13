#!/bin/bash

# CCPM Project Detection and Auto-Configuration System
# Intelligently detects project type and automatically configures CCPM

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(find_project_root)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
CONFIG_DIR="$CLAUDE_DIR/config"

# Source core functions
if [[ -f "$CLAUDE_DIR/lib/core.sh" ]]; then
    source "$CLAUDE_DIR/lib/core.sh"
fi

if [[ -f "$CLAUDE_DIR/lib/ui.sh" ]]; then
    source "$CLAUDE_DIR/lib/ui.sh"
fi

# =============================================================================
# PROJECT DETECTION RULES
# =============================================================================

# Detection patterns for different project types
declare -A DETECTION_PATTERNS

# Frontend frameworks
DETECTION_PATTERNS[react]='
{
  "priority": 1,
  "confidence_threshold": 0.8,
  "file_indicators": [
    {"file": "package.json", "patterns": ["\"react\":", "\"@types/react\":", "\"create-react-app\""], "weight": 5},
    {"file": "src/App.js", "patterns": ["import React", "export default"], "weight": 3},
    {"file": "src/App.tsx", "patterns": ["import React", "export default"], "weight": 3},
    {"file": "public/index.html", "patterns": ["<div id=\"root\">"], "weight": 2}
  ],
  "directory_indicators": [
    {"path": "src/components", "weight": 2},
    {"path": "src/hooks", "weight": 1},
    {"path": "public", "weight": 1}
  ],
  "exclusion_patterns": [
    {"file": "package.json", "patterns": ["\"next\":", "\"nuxt\":", "\"vue\":"], "weight": -10}
  ]
}'

DETECTION_PATTERNS[nextjs]='
{
  "priority": 1,
  "confidence_threshold": 0.8,
  "file_indicators": [
    {"file": "package.json", "patterns": ["\"next\":", "\"next/"], "weight": 5},
    {"file": "next.config.js", "patterns": ["module.exports"], "weight": 4},
    {"file": "pages/_app.js", "patterns": ["export default"], "weight": 3},
    {"file": "pages/index.js", "patterns": ["export default"], "weight": 2}
  ],
  "directory_indicators": [
    {"path": "pages", "weight": 4},
    {"path": "public", "weight": 1},
    {"path": "styles", "weight": 1}
  ]
}'

DETECTION_PATTERNS[vue]='
{
  "priority": 1,
  "confidence_threshold": 0.8,
  "file_indicators": [
    {"file": "package.json", "patterns": ["\"vue\":", "\"@vue/"], "weight": 5},
    {"file": "vue.config.js", "patterns": ["module.exports"], "weight": 4},
    {"file": "src/main.js", "patterns": ["Vue", "createApp"], "weight": 3},
    {"file": "src/App.vue", "patterns": ["<template>", "<script>", "<style>"], "weight": 3}
  ],
  "directory_indicators": [
    {"path": "src/components", "weight": 2},
    {"path": "src/views", "weight": 2}
  ]
}'

DETECTION_PATTERNS[angular]='
{
  "priority": 1,
  "confidence_threshold": 0.8,
  "file_indicators": [
    {"file": "package.json", "patterns": ["\"@angular/core\":", "\"@angular/cli\":"], "weight": 5},
    {"file": "angular.json", "patterns": ["\"projects\":", "\"architect\":"], "weight": 4},
    {"file": "src/main.ts", "patterns": ["platformBrowserDynamic", "AppModule"], "weight": 3},
    {"file": "src/app/app.module.ts", "patterns": ["@NgModule", "bootstrap"], "weight": 3}
  ],
  "directory_indicators": [
    {"path": "src/app", "weight": 3},
    {"path": "e2e", "weight": 1}
  ]
}'

# Backend frameworks
DETECTION_PATTERNS[nodejs]='
{
  "priority": 2,
  "confidence_threshold": 0.7,
  "file_indicators": [
    {"file": "package.json", "patterns": ["\"express\":", "\"koa\":", "\"fastify\":", "\"node\":"], "weight": 4},
    {"file": "server.js", "patterns": ["require", "app.listen"], "weight": 3},
    {"file": "index.js", "patterns": ["require", "module.exports"], "weight": 2},
    {"file": "app.js", "patterns": ["express()", "app.use"], "weight": 3}
  ],
  "directory_indicators": [
    {"path": "routes", "weight": 2},
    {"path": "middleware", "weight": 1},
    {"path": "controllers", "weight": 2}
  ],
  "exclusion_patterns": [
    {"file": "package.json", "patterns": ["\"react\":", "\"vue\":", "\"angular\":"], "weight": -5}
  ]
}'

DETECTION_PATTERNS[python]='
{
  "priority": 1,
  "confidence_threshold": 0.8,
  "file_indicators": [
    {"file": "requirements.txt", "patterns": [".*"], "weight": 4},
    {"file": "pyproject.toml", "patterns": ["\\[build-system\\]", "\\[tool.poetry\\]"], "weight": 4},
    {"file": "setup.py", "patterns": ["from setuptools import", "setup("], "weight": 3},
    {"file": "Pipfile", "patterns": ["\\[packages\\]", "\\[dev-packages\\]"], "weight": 3},
    {"file": "main.py", "patterns": ["if __name__ == \"__main__\":"], "weight": 2}
  ],
  "directory_indicators": [
    {"path": "src", "weight": 1},
    {"path": "tests", "weight": 1},
    {"path": "venv", "weight": 1}
  ]
}'

DETECTION_PATTERNS[django]='
{
  "priority": 1,
  "confidence_threshold": 0.9,
  "file_indicators": [
    {"file": "manage.py", "patterns": ["django", "DJANGO_SETTINGS_MODULE"], "weight": 5},
    {"file": "settings.py", "patterns": ["INSTALLED_APPS", "DATABASES"], "weight": 4},
    {"file": "urls.py", "patterns": ["urlpatterns", "django.urls"], "weight": 3},
    {"file": "requirements.txt", "patterns": ["Django", "django"], "weight": 3}
  ],
  "directory_indicators": [
    {"path": "templates", "weight": 2},
    {"path": "static", "weight": 1},
    {"path": "apps", "weight": 2}
  ]
}'

DETECTION_PATTERNS[flask]='
{
  "priority": 1,
  "confidence_threshold": 0.8,
  "file_indicators": [
    {"file": "app.py", "patterns": ["from flask import", "Flask(__name__)"], "weight": 5},
    {"file": "main.py", "patterns": ["from flask import", "app.run"], "weight": 4},
    {"file": "requirements.txt", "patterns": ["Flask", "flask"], "weight": 3},
    {"file": "__init__.py", "patterns": ["Flask"], "weight": 2}
  ],
  "directory_indicators": [
    {"path": "templates", "weight": 2},
    {"path": "static", "weight": 1}
  ]
}'

# Systems languages
DETECTION_PATTERNS[golang]='
{
  "priority": 1,
  "confidence_threshold": 0.9,
  "file_indicators": [
    {"file": "go.mod", "patterns": ["module ", "go [0-9]+\\.[0-9]+"], "weight": 5},
    {"file": "go.sum", "patterns": [".*"], "weight": 3},
    {"file": "main.go", "patterns": ["package main", "func main()"], "weight": 4},
    {"file": "Makefile", "patterns": ["go build", "go test"], "weight": 2}
  ],
  "directory_indicators": [
    {"path": "cmd", "weight": 2},
    {"path": "pkg", "weight": 2},
    {"path": "internal", "weight": 1}
  ]
}'

DETECTION_PATTERNS[rust]='
{
  "priority": 1,
  "confidence_threshold": 0.9,
  "file_indicators": [
    {"file": "Cargo.toml", "patterns": ["\\[package\\]", "edition = "], "weight": 5},
    {"file": "Cargo.lock", "patterns": ["# This file is automatically"], "weight": 3},
    {"file": "src/main.rs", "patterns": ["fn main()", "use std::"], "weight": 4},
    {"file": "src/lib.rs", "patterns": ["pub fn", "pub mod"], "weight": 3}
  ],
  "directory_indicators": [
    {"path": "src", "weight": 2},
    {"path": "tests", "weight": 1},
    {"path": "benches", "weight": 1}
  ]
}'

# Java ecosystem
DETECTION_PATTERNS[maven]='
{
  "priority": 1,
  "confidence_threshold": 0.9,
  "file_indicators": [
    {"file": "pom.xml", "patterns": ["<project", "<modelVersion>", "<groupId>"], "weight": 5},
    {"file": "src/main/java", "patterns": [".*"], "weight": 3},
    {"file": "mvnw", "patterns": ["exec java"], "weight": 2}
  ],
  "directory_indicators": [
    {"path": "src/main/java", "weight": 3},
    {"path": "src/test/java", "weight": 2},
    {"path": "src/main/resources", "weight": 1}
  ]
}'

DETECTION_PATTERNS[gradle]='
{
  "priority": 1,
  "confidence_threshold": 0.9,
  "file_indicators": [
    {"file": "build.gradle", "patterns": ["plugins", "dependencies"], "weight": 5},
    {"file": "build.gradle.kts", "patterns": ["plugins", "dependencies"], "weight": 5},
    {"file": "gradlew", "patterns": ["gradle"], "weight": 3},
    {"file": "settings.gradle", "patterns": ["rootProject.name"], "weight": 2}
  ],
  "directory_indicators": [
    {"path": "src/main/java", "weight": 3},
    {"path": "src/test/java", "weight": 2},
    {"path": "gradle", "weight": 1}
  ]
}'

# DevOps and containerization
DETECTION_PATTERNS[docker]='
{
  "priority": 3,
  "confidence_threshold": 0.7,
  "file_indicators": [
    {"file": "Dockerfile", "patterns": ["FROM ", "RUN ", "COPY "], "weight": 5},
    {"file": "docker-compose.yml", "patterns": ["version:", "services:"], "weight": 4},
    {"file": "docker-compose.yaml", "patterns": ["version:", "services:"], "weight": 4},
    {"file": ".dockerignore", "patterns": [".*"], "weight": 2}
  ],
  "directory_indicators": [
    {"path": ".docker", "weight": 2},
    {"path": "docker", "weight": 2}
  ]
}'

# Generic fallback
DETECTION_PATTERNS[generic]='
{
  "priority": 10,
  "confidence_threshold": 0.1,
  "file_indicators": [
    {"file": "README.md", "patterns": [".*"], "weight": 1},
    {"file": "Makefile", "patterns": [".*"], "weight": 1},
    {"file": ".gitignore", "patterns": [".*"], "weight": 1}
  ]
}'

# =============================================================================
# DETECTION FUNCTIONS
# =============================================================================

# Calculate confidence score for a project type
calculate_confidence() {
    local project_type="$1"
    local patterns="${DETECTION_PATTERNS[$project_type]}"
    local total_score=0
    local max_possible_score=0
    
    # Process file indicators
    local file_indicators
    file_indicators=$(echo "$patterns" | jq -c '.file_indicators[]?' 2>/dev/null || echo "")
    
    while IFS= read -r indicator; do
        if [[ -n "$indicator" ]]; then
            local file
            local pattern_list
            local weight
            
            file=$(echo "$indicator" | jq -r '.file')
            pattern_list=$(echo "$indicator" | jq -r '.patterns[]')
            weight=$(echo "$indicator" | jq -r '.weight')
            
            max_possible_score=$((max_possible_score + weight))
            
            if [[ -f "$file" ]]; then
                local file_content
                file_content=$(cat "$file" 2>/dev/null || echo "")
                
                local pattern_matched=false
                while IFS= read -r pattern; do
                    if [[ -n "$pattern" && "$file_content" =~ $pattern ]]; then
                        pattern_matched=true
                        break
                    fi
                done <<< "$pattern_list"
                
                if [[ "$pattern_matched" == "true" ]]; then
                    total_score=$((total_score + weight))
                fi
            fi
        fi
    done <<< "$file_indicators"
    
    # Process directory indicators
    local dir_indicators
    dir_indicators=$(echo "$patterns" | jq -c '.directory_indicators[]?' 2>/dev/null || echo "")
    
    while IFS= read -r indicator; do
        if [[ -n "$indicator" ]]; then
            local path
            local weight
            
            path=$(echo "$indicator" | jq -r '.path')
            weight=$(echo "$indicator" | jq -r '.weight')
            
            max_possible_score=$((max_possible_score + weight))
            
            if [[ -d "$path" ]]; then
                total_score=$((total_score + weight))
            fi
        fi
    done <<< "$dir_indicators"
    
    # Process exclusion patterns (negative weight)
    local exclusion_indicators
    exclusion_indicators=$(echo "$patterns" | jq -c '.exclusion_patterns[]?' 2>/dev/null || echo "")
    
    while IFS= read -r indicator; do
        if [[ -n "$indicator" ]]; then
            local file
            local pattern_list
            local weight
            
            file=$(echo "$indicator" | jq -r '.file')
            pattern_list=$(echo "$indicator" | jq -r '.patterns[]')
            weight=$(echo "$indicator" | jq -r '.weight')
            
            if [[ -f "$file" ]]; then
                local file_content
                file_content=$(cat "$file" 2>/dev/null || echo "")
                
                while IFS= read -r pattern; do
                    if [[ -n "$pattern" && "$file_content" =~ $pattern ]]; then
                        total_score=$((total_score + weight))
                        break
                    fi
                done <<< "$pattern_list"
            fi
        fi
    done <<< "$exclusion_indicators"
    
    # Calculate confidence percentage
    if [[ $max_possible_score -gt 0 ]]; then
        local confidence=$((total_score * 100 / max_possible_score))
        # Ensure confidence is not negative
        if [[ $confidence -lt 0 ]]; then
            confidence=0
        fi
        echo "$confidence"
    else
        echo "0"
    fi
}

# Detect all possible project types with confidence scores
detect_all_project_types() {
    local results=()
    
    echo "🔍 Analyzing project structure..."
    echo ""
    
    for project_type in "${!DETECTION_PATTERNS[@]}"; do
        if [[ "$project_type" != "generic" ]]; then
            local confidence
            confidence=$(calculate_confidence "$project_type")
            
            local threshold
            threshold=$(echo "${DETECTION_PATTERNS[$project_type]}" | jq -r '.confidence_threshold * 100' 2>/dev/null || echo "70")
            
            if [[ $confidence -ge $threshold ]]; then
                results+=("$confidence:$project_type")
                echo "  ✅ $project_type: ${confidence}% confidence"
            else
                echo "  ❌ $project_type: ${confidence}% confidence (below ${threshold}% threshold)"
            fi
        fi
    done
    
    # Sort results by confidence (descending)
    if [[ ${#results[@]} -gt 0 ]]; then
        printf '%s\n' "${results[@]}" | sort -rn -t: -k1
    else
        echo "0:generic"
    fi
}

# Get the best matching project type
get_best_project_type() {
    local detection_results
    detection_results=$(detect_all_project_types)
    
    # Get the highest confidence result
    local best_result
    best_result=$(echo "$detection_results" | head -1)
    
    if [[ -n "$best_result" ]]; then
        echo "${best_result#*:}"
    else
        echo "generic"
    fi
}

# =============================================================================
# AUTO-CONFIGURATION FUNCTIONS
# =============================================================================

# Auto-configure CCPM based on detected project type
auto_configure_ccpm() {
    local project_type="$1"
    local force="${2:-false}"
    
    show_info "Auto-configuring CCPM for $project_type project..."
    
    # Run agent configuration
    if [[ -x "$CLAUDE_DIR/scripts/agents/configure-agents.sh" ]]; then
        echo "🤖 Configuring AI agents..."
        bash "$CLAUDE_DIR/scripts/agents/configure-agents.sh" "$project_type" ${force:+--force}
    fi
    
    # Run MCP configuration
    if [[ -x "$CLAUDE_DIR/scripts/mcp/configure-mcp.sh" ]]; then
        echo "🔌 Configuring MCP servers..."
        bash "$CLAUDE_DIR/scripts/mcp/configure-mcp.sh" "$project_type"
    fi
    
    # Update project configuration
    local project_config_file="$CONFIG_DIR/project.json"
    ensure_directory "$CONFIG_DIR"
    
    if [[ ! -f "$project_config_file" ]] || [[ "$force" == "true" ]]; then
        cat > "$project_config_file" << EOF
{
  "project": {
    "type": "$project_type",
    "name": "$(basename "$PROJECT_ROOT")",
    "auto_detected": true,
    "detected_at": "$(date -Iseconds)",
    "ccpm_version": "2.0"
  },
  "detection": {
    "method": "automatic",
    "confidence": $(calculate_confidence "$project_type"),
    "alternatives": $(detect_all_project_types | jq -Rn '[inputs | split(":") | {type: .[1], confidence: (.[0] | tonumber)}]')
  }
}
EOF
        echo "📄 Updated project configuration"
    fi
    
    show_success "Auto-configuration completed for $project_type"
}

# Validate detection accuracy
validate_detection() {
    local detected_type="$1"
    
    echo "🔍 Validating detection accuracy..."
    
    # Load project-specific validation rules
    local validation_rules
    if [[ -f "$CONFIG_DIR/project-types.json" ]]; then
        validation_rules=$(jq -r ".templates.$detected_type.validation // empty" "$CONFIG_DIR/project-types.json" 2>/dev/null)
    fi
    
    # Basic validation checks
    local validation_score=0
    local total_checks=0
    
    case "$detected_type" in
        "react"|"vue"|"angular"|"nextjs")
            if [[ -f "package.json" ]]; then
                ((validation_score++))
            fi
            ((total_checks++))
            
            if [[ -d "src" ]]; then
                ((validation_score++))
            fi
            ((total_checks++))
            ;;
        "python"|"django"|"flask")
            if [[ -f "requirements.txt" || -f "pyproject.toml" || -f "setup.py" ]]; then
                ((validation_score++))
            fi
            ((total_checks++))
            ;;
        "golang")
            if [[ -f "go.mod" ]]; then
                ((validation_score++))
            fi
            ((total_checks++))
            ;;
        "rust")
            if [[ -f "Cargo.toml" ]]; then
                ((validation_score++))
            fi
            ((total_checks++))
            ;;
    esac
    
    local accuracy=100
    if [[ $total_checks -gt 0 ]]; then
        accuracy=$((validation_score * 100 / total_checks))
    fi
    
    echo "  Validation accuracy: ${accuracy}%"
    
    if [[ $accuracy -ge 80 ]]; then
        echo "  ✅ Detection appears accurate"
        return 0
    else
        echo "  ⚠️  Detection may be inaccurate"
        return 1
    fi
}

# =============================================================================
# REPORTING AND ANALYSIS
# =============================================================================

# Generate detection report
generate_detection_report() {
    local output_file="$1"
    
    local all_results
    all_results=$(detect_all_project_types)
    
    local best_type
    best_type=$(get_best_project_type)
    
    cat > "$output_file" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "project_root": "$PROJECT_ROOT",
  "detection_results": $(echo "$all_results" | jq -Rn '[inputs | split(":") | {type: .[1], confidence: (.[0] | tonumber)}]'),
  "best_match": {
    "type": "$best_type",
    "confidence": $(calculate_confidence "$best_type")
  },
  "environment": {
    "os": "$(uname -s)",
    "arch": "$(uname -m)",
    "shell": "$SHELL"
  },
  "files_analyzed": $(find . -maxdepth 2 -type f | wc -l),
  "directories_analyzed": $(find . -maxdepth 2 -type d | wc -l)
}
EOF
    
    echo "📊 Detection report saved: $output_file"
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

show_help() {
    cat << EOF
CCPM Project Detection and Auto-Configuration

Intelligently detects project type and automatically configures CCPM.

Usage: $0 [options]

Options:
  --auto-configure       Auto-configure CCPM after detection
  --force                Force reconfiguration even if already configured
  --report FILE          Generate detailed detection report
  --validate             Validate detection accuracy
  --list-types           List all supported project types
  --confidence-only      Only show confidence scores, don't configure
  -v, --verbose          Verbose output
  -h, --help             Show this help

Examples:
  $0                              # Detect project type
  $0 --auto-configure            # Detect and auto-configure CCPM
  $0 --report detection.json     # Generate detection report
  $0 --validate                  # Validate detection accuracy

Supported Project Types:
  Frontend: react, vue, angular, nextjs
  Backend:  nodejs, python, django, flask, golang, rust
  Java:     maven, gradle
  DevOps:   docker
  Generic:  fallback for unrecognized projects

EOF
}

# List all supported project types
list_project_types() {
    echo "Supported Project Types:"
    echo ""
    
    for project_type in "${!DETECTION_PATTERNS[@]}"; do
        if [[ "$project_type" != "generic" ]]; then
            local threshold
            threshold=$(echo "${DETECTION_PATTERNS[$project_type]}" | jq -r '.confidence_threshold * 100' 2>/dev/null || echo "70")
            echo "  $project_type (threshold: ${threshold}%)"
        fi
    done
    
    echo "  generic (fallback)"
}

# Main function
main() {
    local auto_configure=false
    local force=false
    local report_file=""
    local validate_only=false
    local confidence_only=false
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-configure)
                auto_configure=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --report)
                report_file="$2"
                shift 2
                ;;
            --validate)
                validate_only=true
                shift
                ;;
            --list-types)
                list_project_types
                exit 0
                ;;
            --confidence-only)
                confidence_only=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "❌ Error: Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    show_title "CCPM Project Detection" 50
    echo "Project Directory: $PROJECT_ROOT"
    echo ""
    
    # Detect project types
    local detection_results
    detection_results=$(detect_all_project_types)
    
    local best_type
    best_type=$(get_best_project_type)
    
    echo ""
    echo "🎯 Best Match: $best_type ($(calculate_confidence "$best_type")% confidence)"
    
    # Show all results if verbose
    if [[ "$verbose" == "true" ]]; then
        echo ""
        echo "All Detection Results:"
        echo "$detection_results" | while IFS=: read -r confidence type; do
            echo "  $type: ${confidence}%"
        done
    fi
    
    # Generate report if requested
    if [[ -n "$report_file" ]]; then
        echo ""
        generate_detection_report "$report_file"
    fi
    
    # Validate detection if requested
    if [[ "$validate_only" == "true" ]]; then
        echo ""
        validate_detection "$best_type"
        exit $?
    fi
    
    # Exit if only confidence scores requested
    if [[ "$confidence_only" == "true" ]]; then
        exit 0
    fi
    
    # Auto-configure if requested
    if [[ "$auto_configure" == "true" ]]; then
        echo ""
        auto_configure_ccpm "$best_type" "$force"
        
        echo ""
        show_completion "Project detection and configuration completed!"
        show_next_steps "
        /validate --quick     # Validate CCPM setup
        /pm:init             # Initialize project management
        claude               # Start Claude Code session"
    else
        echo ""
        echo "💡 To auto-configure CCPM for this project type, run:"
        echo "   $0 --auto-configure"
    fi
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi