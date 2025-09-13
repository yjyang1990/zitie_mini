#!/bin/bash

# CCPM Project-Specific Test Runner
# Intelligently runs tests based on project type and available frameworks

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(find_project_root)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
CONFIG_DIR="$CLAUDE_DIR/config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Source core functions
if [[ -f "$CLAUDE_DIR/lib/core.sh" ]]; then
    source "$CLAUDE_DIR/lib/core.sh"
fi

if [[ -f "$CLAUDE_DIR/lib/ui.sh" ]]; then
    source "$CLAUDE_DIR/lib/ui.sh"
fi

# =============================================================================
# TEST FRAMEWORK DEFINITIONS
# =============================================================================

# Define test commands for different project types
declare -A TEST_FRAMEWORKS

# Frontend JavaScript/TypeScript frameworks
TEST_FRAMEWORKS[react]='
{
  "primary": {
    "framework": "jest",
    "commands": ["npm test", "npm run test:unit", "yarn test"],
    "coverage": ["npm run test:coverage", "yarn test:coverage"],
    "watch": ["npm run test:watch", "yarn test:watch"]
  },
  "secondary": {
    "framework": "cypress",
    "commands": ["npm run test:e2e", "npx cypress run"],
    "watch": ["npm run test:e2e:watch", "npx cypress open"]
  },
  "linting": {
    "commands": ["npm run lint", "npx eslint src/", "yarn lint"],
    "fix": ["npm run lint:fix", "npx eslint --fix src/", "yarn lint:fix"]
  },
  "type_check": {
    "commands": ["npm run type-check", "npx tsc --noEmit", "yarn type-check"]
  },
  "build_test": {
    "commands": ["npm run build", "yarn build"]
  }
}'

TEST_FRAMEWORKS[vue]='
{
  "primary": {
    "framework": "jest",
    "commands": ["npm run test:unit", "vue-cli-service test:unit"],
    "coverage": ["npm run test:unit -- --coverage"]
  },
  "secondary": {
    "framework": "cypress",
    "commands": ["npm run test:e2e", "vue-cli-service test:e2e"]
  },
  "linting": {
    "commands": ["npm run lint", "vue-cli-service lint"]
  }
}'

TEST_FRAMEWORKS[angular]='
{
  "primary": {
    "framework": "jasmine",
    "commands": ["ng test", "npm run test"],
    "coverage": ["ng test --code-coverage", "npm run test:coverage"]
  },
  "secondary": {
    "framework": "protractor",
    "commands": ["ng e2e", "npm run e2e"]
  },
  "linting": {
    "commands": ["ng lint", "npm run lint"]
  }
}'

TEST_FRAMEWORKS[nextjs]='
{
  "primary": {
    "framework": "jest",
    "commands": ["npm test", "npm run test:unit"],
    "coverage": ["npm run test:coverage"]
  },
  "secondary": {
    "framework": "playwright",
    "commands": ["npm run test:e2e", "npx playwright test"],
    "watch": ["npx playwright test --ui"]
  },
  "linting": {
    "commands": ["npm run lint", "next lint"]
  },
  "build_test": {
    "commands": ["npm run build", "next build"]
  }
}'

# Backend frameworks
TEST_FRAMEWORKS[nodejs]='
{
  "primary": {
    "framework": "jest",
    "commands": ["npm test", "npm run test:unit"],
    "coverage": ["npm run test:coverage", "npm test -- --coverage"]
  },
  "secondary": {
    "framework": "supertest",
    "commands": ["npm run test:integration", "npm run test:api"]
  },
  "linting": {
    "commands": ["npm run lint", "eslint .", "standard"]
  }
}'

TEST_FRAMEWORKS[python]='
{
  "primary": {
    "framework": "pytest",
    "commands": ["pytest", "python -m pytest", "poetry run pytest"],
    "coverage": ["pytest --cov", "python -m pytest --cov", "coverage run -m pytest"],
    "watch": ["pytest-watch", "ptw"]
  },
  "linting": {
    "commands": ["ruff check .", "flake8 .", "pylint src/"],
    "fix": ["ruff check --fix .", "black .", "isort ."]
  },
  "type_check": {
    "commands": ["mypy .", "python -m mypy src/"]
  }
}'

TEST_FRAMEWORKS[django]='
{
  "primary": {
    "framework": "pytest-django",
    "commands": ["pytest", "python manage.py test", "poetry run pytest"],
    "coverage": ["pytest --cov", "coverage run --source=\".\" manage.py test"]
  },
  "secondary": {
    "framework": "selenium",
    "commands": ["pytest tests/integration/", "python manage.py test --tag=integration"]
  },
  "linting": {
    "commands": ["ruff check .", "flake8 .", "django-admin check"],
    "fix": ["ruff check --fix .", "black ."]
  }
}'

TEST_FRAMEWORKS[flask]='
{
  "primary": {
    "framework": "pytest",
    "commands": ["pytest", "python -m pytest tests/"],
    "coverage": ["pytest --cov=app", "coverage run -m pytest"]
  },
  "linting": {
    "commands": ["ruff check .", "flake8 app/"],
    "fix": ["ruff check --fix .", "black app/"]
  }
}'

# Systems programming languages
TEST_FRAMEWORKS[golang]='
{
  "primary": {
    "framework": "go-test",
    "commands": ["go test ./...", "go test -v ./..."],
    "coverage": ["go test -cover ./...", "go test -coverprofile=coverage.out ./..."],
    "bench": ["go test -bench=.", "go test -bench=. -benchmem"]
  },
  "linting": {
    "commands": ["golangci-lint run", "go vet ./...", "go fmt ./..."],
    "fix": ["go fmt ./...", "goimports -w ."]
  }
}'

TEST_FRAMEWORKS[rust]='
{
  "primary": {
    "framework": "cargo-test",
    "commands": ["cargo test", "cargo test --all"],
    "coverage": ["cargo tarpaulin", "cargo llvm-cov"],
    "bench": ["cargo bench"]
  },
  "linting": {
    "commands": ["cargo clippy", "cargo fmt --check"],
    "fix": ["cargo fmt", "cargo clippy --fix"]
  },
  "audit": {
    "commands": ["cargo audit", "cargo outdated"]
  }
}'

# Java ecosystem
TEST_FRAMEWORKS[maven]='
{
  "primary": {
    "framework": "junit",
    "commands": ["mvn test", "mvn surefire:test"],
    "coverage": ["mvn jacoco:report", "mvn test jacoco:report"],
    "integration": ["mvn failsafe:integration-test", "mvn verify"]
  },
  "linting": {
    "commands": ["mvn checkstyle:check", "mvn spotbugs:check"],
    "fix": ["mvn fmt:format"]
  }
}'

TEST_FRAMEWORKS[gradle]='
{
  "primary": {
    "framework": "junit",
    "commands": ["./gradlew test", "gradle test"],
    "coverage": ["./gradlew jacocoTestReport", "gradle jacocoTestReport"],
    "integration": ["./gradlew integrationTest", "./gradlew check"]
  },
  "linting": {
    "commands": ["./gradlew checkstyleMain", "./gradlew spotbugsMain"],
    "fix": ["./gradlew spotlessApply"]
  }
}'

# DevOps and containerization
TEST_FRAMEWORKS[docker]='
{
  "primary": {
    "framework": "docker",
    "commands": ["docker build -t test-image .", "docker-compose build"],
    "integration": ["docker-compose up --abort-on-container-exit test"]
  },
  "linting": {
    "commands": ["hadolint Dockerfile", "docker run --rm -i hadolint/hadolint < Dockerfile"]
  },
  "security": {
    "commands": ["docker scout cves", "trivy image test-image"]
  }
}'

# Generic fallback
TEST_FRAMEWORKS[generic]='
{
  "primary": {
    "framework": "auto-detect",
    "commands": ["make test", "./test.sh", "npm test", "pytest"],
    "coverage": ["make coverage", "./coverage.sh"]
  },
  "linting": {
    "commands": ["make lint", "./lint.sh", "shellcheck *.sh"]
  }
}'

# =============================================================================
# TEST EXECUTION FUNCTIONS
# =============================================================================

# Execute a test command with proper error handling
execute_test_command() {
    local command="$1"
    local test_type="$2"
    local timeout="${3:-300}"
    
    echo -e "${CYAN}  Running: $command${NC}"
    
    local start_time=$(date +%s)
    local output
    local exit_code
    
    # Execute command with timeout
    if timeout "$timeout" bash -c "$command" >/tmp/test_output 2>&1; then
        exit_code=0
        output=$(cat /tmp/test_output)
    else
        exit_code=$?
        output=$(cat /tmp/test_output)
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Clean up temp file
    rm -f /tmp/test_output
    
    # Report results
    if [[ $exit_code -eq 0 ]]; then
        test_pass "$test_type completed successfully (${duration}s)"
        return 0
    else
        test_fail "$test_type failed with exit code $exit_code (${duration}s)"
        if [[ -n "$output" ]]; then
            echo -e "${RED}    Error output:${NC}"
            echo "$output" | head -20 | sed 's/^/    /'
            if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
                echo "    ... (output truncated)"
            fi
        fi
        return 1
    fi
}

# Try multiple commands until one succeeds
try_commands() {
    local commands_json="$1"
    local test_type="$2"
    
    local commands
    commands=$(echo "$commands_json" | jq -r '.[]' 2>/dev/null || echo "$commands_json")
    
    for command in $commands; do
        # Check if command is available
        local cmd_name
        cmd_name=$(echo "$command" | awk '{print $1}')
        
        if command -v "$cmd_name" >/dev/null 2>&1; then
            echo -e "${BLUE}  Trying: $command${NC}"
            if execute_test_command "$command" "$test_type"; then
                return 0
            fi
        else
            echo -e "${YELLOW}  Skipping: $command (command not found)${NC}"
            ((TESTS_SKIPPED++))
        fi
    done
    
    return 1
}

# Run tests for a specific project type
run_project_tests() {
    local project_type="$1"
    local test_types=("${@:2}")
    
    # Get test framework configuration
    local framework_config="${TEST_FRAMEWORKS[$project_type]:-${TEST_FRAMEWORKS[generic]}}"
    
    if [[ -z "$framework_config" ]]; then
        test_fail "No test configuration found for project type: $project_type"
        return 1
    fi
    
    echo -e "${BLUE}🧪 Running tests for $project_type project${NC}"
    echo ""
    
    # If no specific test types requested, run all available
    if [[ ${#test_types[@]} -eq 0 ]]; then
        test_types=($(echo "$framework_config" | jq -r 'keys[]' 2>/dev/null || echo "primary"))
    fi
    
    local overall_success=true
    
    for test_type in "${test_types[@]}"; do
        test_start "$test_type tests"
        
        local commands
        commands=$(echo "$framework_config" | jq -c ".$test_type.commands // empty" 2>/dev/null)
        
        if [[ -n "$commands" ]]; then
            if try_commands "$commands" "$test_type"; then
                echo ""
            else
                overall_success=false
                echo ""
            fi
        else
            test_skip "$test_type tests (not configured)"
            echo ""
        fi
    done
    
    return $overall_success
}

# Auto-detect available test frameworks
detect_test_frameworks() {
    local project_type="$1"
    local detected_frameworks=()
    
    echo -e "${CYAN}🔍 Detecting available test frameworks...${NC}"
    
    # Check for common test files and configurations
    local test_indicators=(
        "package.json:jest"
        "package.json:cypress" 
        "package.json:playwright"
        "pytest.ini:pytest"
        "tox.ini:pytest"
        "Cargo.toml:cargo-test"
        "go.mod:go-test"
        "pom.xml:junit"
        "build.gradle:junit"
        "Dockerfile:docker"
    )
    
    for indicator in "${test_indicators[@]}"; do
        local file="${indicator%%:*}"
        local framework="${indicator##*:}"
        
        if [[ -f "$file" ]]; then
            case "$framework" in
                "jest"|"cypress"|"playwright")
                    if grep -q "$framework" "$file" 2>/dev/null; then
                        detected_frameworks+=("$framework")
                    fi
                    ;;
                *)
                    detected_frameworks+=("$framework")
                    ;;
            esac
        fi
    done
    
    # Check for test directories
    if [[ -d "tests" || -d "test" || -d "__tests__" || -d "spec" ]]; then
        echo "  ✅ Test directory found"
    fi
    
    # Report detected frameworks
    if [[ ${#detected_frameworks[@]} -gt 0 ]]; then
        echo "  ✅ Detected frameworks: ${detected_frameworks[*]}"
    else
        echo "  ⚠️  No specific test frameworks detected, using generic approach"
    fi
    
    echo ""
}

# Test helper functions
test_start() {
    local test_name="$1"
    echo -e "${BLUE}[TEST]${NC} $test_name"
    ((TESTS_RUN++))
}

test_pass() {
    local message="${1:-Test passed}"
    echo -e "${GREEN}  ✅ $message${NC}"
    ((TESTS_PASSED++))
}

test_fail() {
    local message="${1:-Test failed}"
    echo -e "${RED}  ❌ $message${NC}"
    ((TESTS_FAILED++))
}

test_skip() {
    local message="${1:-Test skipped}"
    echo -e "${YELLOW}  ⏸️  $message${NC}"
    ((TESTS_SKIPPED++))
}

# =============================================================================
# COVERAGE AND REPORTING
# =============================================================================

# Generate test coverage report
generate_coverage_report() {
    local project_type="$1"
    
    echo -e "${CYAN}📊 Generating coverage report...${NC}"
    
    local framework_config="${TEST_FRAMEWORKS[$project_type]:-${TEST_FRAMEWORKS[generic]}}"
    local coverage_commands
    coverage_commands=$(echo "$framework_config" | jq -c '.primary.coverage // empty' 2>/dev/null)
    
    if [[ -n "$coverage_commands" ]]; then
        try_commands "$coverage_commands" "coverage"
    else
        echo -e "${YELLOW}  No coverage configuration found for $project_type${NC}"
    fi
}

# Generate test report
generate_test_report() {
    local project_type="$1"
    local report_file="$PROJECT_ROOT/.claude/reports/test-report-$(date +%Y%m%d_%H%M%S).json"
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
{
  "project_type": "$project_type",
  "timestamp": "$(date -Iseconds)",
  "test_summary": {
    "total": $TESTS_RUN,
    "passed": $TESTS_PASSED,
    "failed": $TESTS_FAILED,
    "skipped": $TESTS_SKIPPED,
    "pass_rate": $(( TESTS_PASSED * 100 / (TESTS_RUN > 0 ? TESTS_RUN : 1) ))
  },
  "environment": {
    "os": "$(uname -s)",
    "arch": "$(uname -m)",
    "shell": "$SHELL",
    "pwd": "$PWD"
  }
}
EOF
    
    echo -e "${GREEN}📄 Test report saved: $report_file${NC}"
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

show_help() {
    cat << EOF
CCPM Project-Specific Test Runner

Intelligently runs tests based on project type and available frameworks.

Usage: $0 [options] [test_types...]

Arguments:
  test_types      Specific test types to run (primary, linting, coverage, etc.)
                 If not provided, runs all available test types

Options:
  --project-type TYPE    Force specific project type
  --coverage             Generate coverage report
  --report               Generate detailed test report
  --detect               Only detect available frameworks
  --timeout SECONDS      Set timeout for individual tests (default: 300)
  --parallel             Run tests in parallel where possible
  -v, --verbose          Verbose output
  -h, --help             Show this help

Examples:
  $0                              # Run all tests for auto-detected project
  $0 primary linting             # Run only primary and linting tests
  $0 --project-type react        # Force React project testing
  $0 --coverage --report         # Run tests with coverage and reporting
  $0 --detect                    # Only detect available frameworks

Supported Project Types:
  Frontend: react, vue, angular, nextjs
  Backend:  nodejs, python, django, flask, golang, rust
  Java:     maven, gradle  
  DevOps:   docker
  Generic:  auto-detect approach

EOF
}

# Auto-detect project type
auto_detect_project_type() {
    if [[ -f "$CONFIG_DIR/project.json" ]]; then
        jq -r '.project.type // "generic"' "$CONFIG_DIR/project.json"
    else
        # Simple detection based on files
        if [[ -f "package.json" ]]; then
            if grep -q "react" package.json 2>/dev/null; then
                echo "react"
            elif grep -q "vue" package.json 2>/dev/null; then
                echo "vue"
            elif grep -q "next" package.json 2>/dev/null; then
                echo "nextjs"
            else
                echo "nodejs"
            fi
        elif [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then
            if [[ -f "manage.py" ]]; then
                echo "django"
            else
                echo "python"
            fi
        elif [[ -f "go.mod" ]]; then
            echo "golang"
        elif [[ -f "Cargo.toml" ]]; then
            echo "rust"
        elif [[ -f "pom.xml" ]]; then
            echo "maven"
        elif [[ -f "build.gradle" ]]; then
            echo "gradle"
        elif [[ -f "Dockerfile" ]]; then
            echo "docker"
        else
            echo "generic"
        fi
    fi
}

# Main function
main() {
    local project_type=""
    local test_types=()
    local generate_coverage=false
    local generate_report=false
    local detect_only=false
    local timeout=300
    local parallel=false
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project-type)
                project_type="$2"
                shift 2
                ;;
            --coverage)
                generate_coverage=true
                shift
                ;;
            --report)
                generate_report=true
                shift
                ;;
            --detect)
                detect_only=true
                shift
                ;;
            --timeout)
                timeout="$2"
                shift 2
                ;;
            --parallel)
                parallel=true
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
                test_types+=("$1")
                shift
                ;;
        esac
    done
    
    # Auto-detect project type if not provided
    if [[ -z "$project_type" ]]; then
        project_type=$(auto_detect_project_type)
    fi
    
    echo -e "${YELLOW}🚀 CCPM Project Test Runner${NC}"
    echo -e "${YELLOW}Project Type: $project_type${NC}"
    echo -e "${YELLOW}Test Types: ${test_types[*]:-all}${NC}"
    echo ""
    
    # Detect frameworks
    detect_test_frameworks "$project_type"
    
    # If only detection requested, exit here
    if [[ "$detect_only" == "true" ]]; then
        exit 0
    fi
    
    # Run tests
    local start_time=$(date +%s)
    
    if run_project_tests "$project_type" "${test_types[@]}"; then
        local test_success=true
    else
        local test_success=false
    fi
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    # Generate coverage if requested
    if [[ "$generate_coverage" == "true" ]]; then
        echo ""
        generate_coverage_report "$project_type"
    fi
    
    # Generate report if requested
    if [[ "$generate_report" == "true" ]]; then
        echo ""
        generate_test_report "$project_type"
    fi
    
    # Print summary
    echo ""
    echo -e "${YELLOW}=================================${NC}"
    echo -e "${YELLOW}Test Summary (${total_duration}s total):${NC}"
    echo -e "  Total: $TESTS_RUN"
    echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    echo -e "  ${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
    
    if [[ $TESTS_RUN -gt 0 ]]; then
        local pass_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
        echo -e "  Pass rate: ${pass_rate}%"
    fi
    
    if [[ "$test_success" == "true" && $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All tests passed! Project is ready.${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some tests failed or errors occurred${NC}"
        exit 1
    fi
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi