#!/bin/bash

# CCPM Test Environment Setup v2.0
# Intelligent testing framework detection and environment preparation

set -euo pipefail

# Load core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Load libraries with error checking
if [[ -f "$LIB_DIR/core.sh" ]]; then
    source "$LIB_DIR/core.sh"
fi

if [[ -f "$LIB_DIR/ui.sh" ]]; then
    source "$LIB_DIR/ui.sh"
fi

if [[ -f "$LIB_DIR/project-detection.sh" ]]; then
    source "$LIB_DIR/project-detection.sh"
fi

# Configuration
TEST_CONFIG_DIR=".claude/config/testing"
AGENT_CONFIG_DIR=".claude/config/agents"
TEST_REPORTS_DIR=".claude/tmp/test-reports"

# Function to show usage
show_usage() {
    show_command_help "test-env-setup" "Setup and configure testing environment" \
        "test-env-setup [framework] [options]       # Setup testing environment
test-env-setup --auto-detect                  # Auto-detect framework
test-env-setup --configure                    # Interactive configuration
test-env-setup jest --agent-setup             # Setup Jest with agent integration"
    
    echo ""
    echo "Supported Frameworks:"
    echo "  jest            JavaScript testing with Jest"
    echo "  mocha           JavaScript testing with Mocha"
    echo "  vitest          Modern JavaScript testing with Vitest"
    echo "  pytest          Python testing with pytest"
    echo "  unittest        Python built-in unittest"
    echo "  cargo           Rust testing with Cargo"
    echo "  go              Go testing with built-in tools"
    echo ""
    echo "Detection Methods:"
    echo "  --auto-detect                   Force framework auto-detection"
    echo "  [framework]                     Override detected framework"
    echo ""
    echo "Configuration Options:"
    echo "  --configure                     Interactive testing setup"
    echo "  --validate                      Validate environment and dependencies"
    echo "  --agent-setup                   Configure test-runner agent integration"
    echo "  --dry-run                       Preview configuration without changes"
    echo "  --help                          Show this help message"
    echo ""
    echo "Examples:"
    echo "  test-env-setup --auto-detect               # Auto-detect and setup"
    echo "  test-env-setup jest --agent-setup          # Force Jest with agent config"
    echo "  test-env-setup --configure                 # Interactive setup"
    echo "  test-env-setup pytest --validate           # Setup pytest with validation"
}

# Detect testing framework
detect_testing_framework() {
    local override_framework="$1"
    
    show_subtitle "🔍 Testing Framework Detection"
    
    # Return override if provided
    if [[ -n "$override_framework" ]]; then
        show_info "Framework override: $override_framework"
        echo "$override_framework"
        return
    fi
    
    local detected_framework=""
    
    # Detect project type first
    local project_type
    project_type=$(detect_project_type)
    
    case "$project_type" in
        "node"|"javascript"|"typescript")
            show_info "Node.js project detected"
            
            # Check package.json for testing frameworks
            if [[ -f "package.json" ]]; then
                if grep -q '"jest"' package.json 2>/dev/null; then
                    detected_framework="jest"
                    show_info "✓ Jest found in package.json"
                elif grep -q '"mocha"' package.json 2>/dev/null; then
                    detected_framework="mocha"
                    show_info "✓ Mocha found in package.json"
                elif grep -q '"vitest"' package.json 2>/dev/null; then
                    detected_framework="vitest"
                    show_info "✓ Vitest found in package.json"
                else
                    show_warning "No Framework" "No testing framework found in package.json"
                fi
            fi
            ;;
        "python")
            show_info "Python project detected"
            
            # Check for pytest indicators
            if [[ -f "pytest.ini" ]] || [[ -f "conftest.py" ]] || [[ -f "pyproject.toml" ]] && grep -q "pytest" pyproject.toml 2>/dev/null; then
                detected_framework="pytest"
                show_info "✓ Pytest configuration found"
            elif find . -maxdepth 2 -name "test_*.py" -o -name "*_test.py" | head -1 >/dev/null 2>&1; then
                detected_framework="unittest"
                show_info "✓ Python unittest files found"
            else
                show_warning "No Framework" "No clear Python testing framework detected"
            fi
            ;;
        "rust")
            show_info "Rust project detected"
            detected_framework="cargo"
            show_info "✓ Cargo test framework (built-in)"
            ;;
        "go")
            show_info "Go project detected"
            detected_framework="go"
            show_info "✓ Go test framework (built-in)"
            ;;
        *)
            show_warning "Unknown Project" "Could not detect project type for testing framework"
            ;;
    esac
    
    if [[ -z "$detected_framework" ]]; then
        show_error "No Framework" "No testing framework detected"
        return 1
    fi
    
    echo "$detected_framework"
}

# Get framework configuration
get_framework_config() {
    local framework="$1"
    
    case "$framework" in
        "jest")
            echo "test_command=npm test"
            echo "test_directory=__tests__"
            echo "config_file=jest.config.js"
            echo "file_patterns=*.test.js,*.spec.js,*.test.ts,*.spec.ts"
            echo "env_vars=NODE_ENV=test"
            ;;
        "mocha")
            echo "test_command=npm test"
            echo "test_directory=test"
            echo "config_file=.mocharc.js"
            echo "file_patterns=*.test.js,*.spec.js"
            echo "env_vars=NODE_ENV=test"
            ;;
        "vitest")
            echo "test_command=npm test"
            echo "test_directory=test"
            echo "config_file=vitest.config.js"
            echo "file_patterns=*.test.js,*.spec.js,*.test.ts,*.spec.ts"
            echo "env_vars=NODE_ENV=test"
            ;;
        "pytest")
            echo "test_command=pytest"
            echo "test_directory=tests"
            echo "config_file=pytest.ini"
            echo "file_patterns=test_*.py,*_test.py"
            echo "env_vars=PYTHONPATH=."
            ;;
        "unittest")
            echo "test_command=python -m unittest"
            echo "test_directory=tests"
            echo "config_file=None"
            echo "file_patterns=test_*.py,*_test.py"
            echo "env_vars=PYTHONPATH=."
            ;;
        "cargo")
            echo "test_command=cargo test"
            echo "test_directory=tests"
            echo "config_file=Cargo.toml"
            echo "file_patterns=*_test.rs,tests/*.rs"
            echo "env_vars=RUST_BACKTRACE=1"
            ;;
        "go")
            echo "test_command=go test ./..."
            echo "test_directory=."
            echo "config_file=go.mod"
            echo "file_patterns=*_test.go"
            echo "env_vars=GO_ENV=test"
            ;;
        *)
            show_error "Unknown Framework" "Unsupported framework: $framework"
            return 1
            ;;
    esac
}

# Analyze test structure
analyze_test_structure() {
    local framework="$1"
    
    show_subtitle "📊 Test Structure Analysis"
    
    local test_files=() test_dirs=() config_files=()
    local total_tests=0
    
    # Get framework-specific patterns
    local patterns
    case "$framework" in
        "jest"|"mocha"|"vitest")
            patterns="-name '*.test.js' -o -name '*.spec.js' -o -name '*.test.ts' -o -name '*.spec.ts'"
            ;;
        "pytest"|"unittest")
            patterns="-name 'test_*.py' -o -name '*_test.py'"
            ;;
        "cargo")
            patterns="-name '*_test.rs'"
            ;;
        "go")
            patterns="-name '*_test.go'"
            ;;
    esac
    
    # Find test files
    if [[ -n "$patterns" ]]; then
        while IFS= read -r -d '' file; do
            test_files+=("$file")
        done < <(eval "find . -path '*/node_modules' -prune -o -path '*/target' -prune -o \( $patterns \) -print0" 2>/dev/null)
    fi
    
    # Find test directories
    while IFS= read -r -d '' dir; do
        test_dirs+=("$dir")
    done < <(find . -type d \( -name "test*" -o -name "__test*__" -o -name "spec*" \) -print0 2>/dev/null)
    
    # Find configuration files
    case "$framework" in
        "jest")
            [[ -f "jest.config.js" ]] && config_files+=("jest.config.js")
            [[ -f "jest.config.json" ]] && config_files+=("jest.config.json")
            ;;
        "mocha")
            [[ -f ".mocharc.js" ]] && config_files+=(".mocharc.js")
            [[ -f ".mocharc.json" ]] && config_files+=(".mocharc.json")
            ;;
        "pytest")
            [[ -f "pytest.ini" ]] && config_files+=("pytest.ini")
            [[ -f "conftest.py" ]] && config_files+=("conftest.py")
            ;;
    esac
    
    # Display analysis
    show_info "📁 Test Files: ${#test_files[@]}"
    show_info "📂 Test Directories: ${#test_dirs[@]}"
    show_info "⚙️ Config Files: ${#config_files[@]}"
    
    if [[ ${#test_files[@]} -gt 0 ]]; then
        echo "  Test files found:"
        for file in "${test_files[@]}"; do
            echo "    • $file"
        done | head -10
        if [[ ${#test_files[@]} -gt 10 ]]; then
            echo "    • ... and $((${#test_files[@]} - 10)) more files"
        fi
    fi
    
    # Create analysis report
    local analysis_file="$TEST_REPORTS_DIR/structure-analysis.json"
    ensure_directory "$TEST_REPORTS_DIR"
    
    cat > "$analysis_file" << EOF
{
  "framework": "$framework",
  "timestamp": "$(format_timestamp)",
  "test_files": $(printf '%s\n' "${test_files[@]}" | jq -R . | jq -s .),
  "test_directories": $(printf '%s\n' "${test_dirs[@]}" | jq -R . | jq -s .),
  "config_files": $(printf '%s\n' "${config_files[@]}" | jq -R . | jq -s .),
  "totals": {
    "files": ${#test_files[@]},
    "directories": ${#test_dirs[@]},
    "configs": ${#config_files[@]}
  }
}
EOF
    
    echo "$analysis_file"
}

# Validate dependencies
validate_dependencies() {
    local framework="$1"
    
    show_subtitle "📦 Dependency Validation"
    
    local status="unknown"
    local missing_deps=()
    
    case "$framework" in
        "jest"|"mocha"|"vitest")
            if [[ -f "package.json" ]]; then
                if npm list --depth=0 2>/dev/null | grep -E "jest|mocha|vitest" >/dev/null; then
                    status="installed"
                    show_success "Dependencies" "Node.js testing framework installed"
                else
                    status="missing"
                    missing_deps+=("npm install")
                    show_warning "Dependencies" "Testing framework not installed"
                fi
            else
                status="no_package_json"
                show_error "Missing File" "package.json not found"
            fi
            ;;
        "pytest")
            if command -v pytest >/dev/null 2>&1; then
                status="installed"
                show_success "Dependencies" "pytest is installed"
            else
                status="missing"
                missing_deps+=("pip install pytest")
                show_warning "Dependencies" "pytest not found"
            fi
            ;;
        "unittest")
            if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
                status="installed"
                show_success "Dependencies" "Python unittest (built-in) available"
            else
                status="missing"
                missing_deps+=("Install Python")
                show_error "Dependencies" "Python not found"
            fi
            ;;
        "cargo")
            if command -v cargo >/dev/null 2>&1; then
                status="installed"
                show_success "Dependencies" "Cargo test (built-in) available"
            else
                status="missing"
                missing_deps+=("Install Rust/Cargo")
                show_error "Dependencies" "Cargo not found"
            fi
            ;;
        "go")
            if command -v go >/dev/null 2>&1; then
                status="installed"
                show_success "Dependencies" "Go test (built-in) available"
            else
                status="missing"
                missing_deps+=("Install Go")
                show_error "Dependencies" "Go not found"
            fi
            ;;
    esac
    
    # Return status and missing dependencies
    echo "status=$status"
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        printf 'missing_deps=%s\n' "${missing_deps[@]}"
    fi
}

# Generate test configuration
generate_test_config() {
    local framework="$1"
    local analysis_file="$2"
    
    show_subtitle "📝 Configuration Generation"
    
    # Get framework configuration
    local config_data
    config_data=$(get_framework_config "$framework")
    
    # Parse configuration
    local test_command test_directory config_file file_patterns env_vars
    eval "$config_data"
    
    # Load analysis data
    local test_count=0 dir_count=0 config_count=0
    if [[ -f "$analysis_file" ]] && command -v jq >/dev/null 2>&1; then
        test_count=$(jq -r '.totals.files' "$analysis_file")
        dir_count=$(jq -r '.totals.directories' "$analysis_file")
        config_count=$(jq -r '.totals.configs' "$analysis_file")
    fi
    
    local timestamp
    timestamp=$(format_timestamp)
    
    # Create test configuration
    ensure_directory "$TEST_CONFIG_DIR"
    local config_file_path="$TEST_CONFIG_DIR/environment.json"
    
    cat > "$config_file_path" << EOF
{
  "framework": {
    "name": "$framework",
    "test_command": "$test_command",
    "test_directory": "$test_directory",
    "config_file": "$config_file",
    "file_patterns": "$file_patterns",
    "env_vars": "$env_vars"
  },
  "structure": {
    "test_files": $test_count,
    "test_directories": $dir_count,
    "config_files": $config_count
  },
  "metadata": {
    "generated": "$timestamp",
    "version": "2.0",
    "generator": "CCPM Test Environment Setup"
  }
}
EOF
    
    show_success "Configuration" "Test environment config generated"
    echo "$config_file_path"
}

# Setup test-runner agent integration
setup_agent_integration() {
    local framework="$1"
    local config_file="$2"
    
    show_subtitle "🤖 Test-Runner Agent Setup"
    
    ensure_directory "$AGENT_CONFIG_DIR"
    local agent_config="$AGENT_CONFIG_DIR/test-runner.json"
    
    # Load framework config
    local test_command=""
    if [[ -f "$config_file" ]] && command -v jq >/dev/null 2>&1; then
        test_command=$(jq -r '.framework.test_command' "$config_file")
    fi
    
    local timestamp
    timestamp=$(format_timestamp)
    
    # Generate agent-specific commands
    local verbose_command debug_command watch_command
    case "$framework" in
        "jest")
            verbose_command="npm test -- --verbose"
            debug_command="npm test -- --runInBand --verbose"
            watch_command="npm test -- --watch"
            ;;
        "mocha")
            verbose_command="npm test -- --reporter spec"
            debug_command="npm test -- --reporter spec --timeout 10000"
            watch_command="npm test -- --watch"
            ;;
        "vitest")
            verbose_command="npm test -- --reporter=verbose"
            debug_command="npm test -- --reporter=verbose --no-parallel"
            watch_command="npm test -- --watch"
            ;;
        "pytest")
            verbose_command="pytest -v"
            debug_command="pytest -v --tb=long"
            watch_command="pytest --looponfail"
            ;;
        "unittest")
            verbose_command="python -m unittest -v"
            debug_command="python -m unittest -v"
            watch_command="N/A"
            ;;
        "cargo")
            verbose_command="cargo test --verbose"
            debug_command="cargo test -- --nocapture"
            watch_command="N/A"
            ;;
        "go")
            verbose_command="go test -v ./..."
            debug_command="go test -v -count=1 ./..."
            watch_command="N/A"
            ;;
    esac
    
    cat > "$agent_config" << EOF
{
  "agent": "test-runner",
  "framework": "$framework",
  "commands": {
    "standard": "$test_command",
    "verbose": "$verbose_command",
    "debug": "$debug_command",
    "watch": "$watch_command"
  },
  "execution_rules": {
    "verbose_output": true,
    "sequential_execution": true,
    "no_mocking": true,
    "complete_capture": true,
    "failure_analysis": true
  },
  "metadata": {
    "generated": "$timestamp",
    "version": "2.0"
  }
}
EOF
    
    show_success "Agent Config" "Test-runner agent configured"
    echo "$agent_config"
}

# Main execution function
main() {
    local framework_override=""
    local auto_detect=false
    local configure_mode=false
    local validate_mode=false
    local agent_setup=false
    local dry_run=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-detect)
                auto_detect=true
                shift
                ;;
            --configure)
                configure_mode=true
                shift
                ;;
            --validate)
                validate_mode=true
                shift
                ;;
            --agent-setup)
                agent_setup=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h|help)
                show_usage
                exit 0
                ;;
            jest|mocha|vitest|pytest|unittest|cargo|go)
                framework_override="$1"
                shift
                ;;
            -*)
                show_error "Unknown Option" "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                show_error "Invalid Argument" "Unexpected argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    show_title "🧪 CCPM Test Environment Setup" 45
    
    # Show configuration
    if [[ -n "$framework_override" ]]; then
        show_info "Framework: $framework_override (override)"
    fi
    if [[ "$auto_detect" == true ]]; then
        show_info "Auto-detection: Enabled"
    fi
    if [[ "$validate_mode" == true ]]; then
        show_info "Validation: Enabled"
    fi
    if [[ "$agent_setup" == true ]]; then
        show_info "Agent Setup: Enabled"
    fi
    if [[ "$dry_run" == true ]]; then
        show_warning "Dry Run" "Preview mode - no changes will be made"
    fi
    
    echo ""
    
    # Detect framework
    local detected_framework
    if ! detected_framework=$(detect_testing_framework "$framework_override"); then
        if [[ "$configure_mode" == true ]]; then
            show_info "Starting interactive configuration..."
            # Interactive mode would go here
            show_error "Not Implemented" "Interactive mode not yet implemented"
            exit 1
        else
            exit 1
        fi
    fi
    
    # Dry run preview
    if [[ "$dry_run" == true ]]; then
        show_subtitle "🔍 Dry Run Preview"
        show_info "Would setup framework: $detected_framework"
        
        local config_preview
        config_preview=$(get_framework_config "$detected_framework")
        echo "Configuration preview:"
        echo "$config_preview" | sed 's/^/  /'
        
        exit 0
    fi
    
    # Analyze test structure
    local analysis_file
    analysis_file=$(analyze_test_structure "$detected_framework")
    
    # Validate dependencies if requested
    if [[ "$validate_mode" == true ]]; then
        local validation_result
        validation_result=$(validate_dependencies "$detected_framework")
        
        if echo "$validation_result" | grep -q "status=missing"; then
            show_error "Validation Failed" "Missing dependencies detected"
            echo "$validation_result" | grep "missing_deps=" | sed 's/missing_deps=/  Install: /'
            exit 1
        fi
    fi
    
    # Generate test configuration
    local config_file
    config_file=$(generate_test_config "$detected_framework" "$analysis_file")
    
    # Setup agent integration if requested
    local agent_config=""
    if [[ "$agent_setup" == true ]]; then
        agent_config=$(setup_agent_integration "$detected_framework" "$config_file")
    fi
    
    # Show completion summary
    show_subtitle "✅ Setup Complete"
    show_success "Framework" "$detected_framework testing environment configured"
    
    echo "📁 Generated files:"
    echo "  📄 Test config: $config_file"
    echo "  📊 Analysis: $analysis_file"
    
    if [[ -n "$agent_config" ]]; then
        echo "  🤖 Agent config: $agent_config"
    fi
    
    echo ""
    show_info "Ready to run tests with: test-runner"
    show_tip "Use 'test-runner --help' for execution options"
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi