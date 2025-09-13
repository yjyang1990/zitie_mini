---
allowed-tools: Bash, Task
argument-hint: [--verbose] [--coverage] [--performance] [--report]
description: Execute comprehensive test suite with intelligent analysis using test-runner agent
model: inherit
---

# Comprehensive Test Suite Command

Execute the complete test suite for the CCPM project with comprehensive analysis.

## Usage

```bash
/test-all                    # Run complete test suite
/test-all --verbose          # Run with detailed output
/test-all --coverage         # Include coverage analysis
/test-all --performance      # Monitor performance metrics
/test-all --report           # Generate detailed report
```

## Test Execution Strategy

### 1. Pre-Test Validation

- Validate project structure and configuration
- Check test environment setup and dependencies
- Verify all test files are properly structured
- Ensure test data and fixtures are available

### 2. Unit Test Execution

```bash
# Run unit tests with detailed output
bats tests/unit/test_common_functions.bats
bats tests/unit/test_validation.bats
bats tests/unit/*.bats
```

### 3. Integration Test Execution

```bash
# Run integration tests
bats tests/integration/*.bats
```

### 4. End-to-End Test Execution

```bash
# Run complete workflow tests
bats tests/e2e/*.bats
```

### 5. Quality Validation Tests

```bash
# Run code quality tests
bats tests/quality/*.bats
```

## Use the test-runner Agent

IMPORTANT: Use the **test-runner** agent to execute all tests and provide comprehensive analysis:

- Capture full test output for debugging
- Analyze any test failures in detail
- Provide specific remediation steps for failures
- Generate test coverage reports
- Identify performance bottlenecks or slow tests
- Suggest test improvements or missing coverage

## Quality Gates

- [ ] All unit tests pass (100% success rate)
- [ ] Integration tests validate component interactions
- [ ] End-to-end tests verify complete workflows
- [ ] Quality tests enforce coding standards
- [ ] No security vulnerabilities detected
- [ ] Performance benchmarks are within acceptable ranges
- [ ] Test coverage meets minimum thresholds

## Failure Handling

If any tests fail:

1. **Analyze root cause** with detailed error investigation
2. **Provide specific fixes** with code examples
3. **Re-run failed tests** to verify fixes
4. **Update test documentation** if test changes are needed
5. **Consider adding additional tests** to prevent regression

## Performance Monitoring

- Track test execution times
- Identify slow or inefficient tests
- Monitor resource usage during test execution
- Suggest optimizations for test performance

## Reporting

Generate a comprehensive test report including:

- Overall pass/fail statistics
- Detailed failure analysis with remediation steps
- Performance metrics and trends
- Coverage analysis and gaps
- Recommendations for test suite improvements

Use this command when you need complete confidence in code quality before major releases or when validating significant changes across the codebase.