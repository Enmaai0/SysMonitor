#!/bin/bash
#
# Test script for SysMonitor
# Author: Enmaai0
# License: MIT

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Counter for tests
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$TEST_DIR/../src" && pwd)"
SYSMONITOR="${SCRIPT_DIR}/sysmonitor.sh"

# Detect OS type
OS_TYPE=$(uname)

# Function to run a test
function run_test {
    local test_name=$1
    local test_cmd=$2
    local expected_exit_code=${3:-0}
    
    echo -e "${YELLOW}Running test: ${test_name}${NC}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # Run the command
    eval "$test_cmd"
    local exit_code=$?
    
    # Check if the exit code matches the expected exit code
    if [ $exit_code -eq $expected_exit_code ]; then
        echo -e "${GREEN}✓ Test passed${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ Test failed: Expected exit code $expected_exit_code, got $exit_code${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    echo
}

# Check if the script file exists
function test_script_exists {
    run_test "Script exists" "[ -f \"$SYSMONITOR\" ]"
}

# Check if the script is executable
function test_script_executable {
    run_test "Script is executable" "[ -x \"$SYSMONITOR\" ]"
}

# Test help command
function test_help_command {
    run_test "Help command" "$SYSMONITOR --help | grep -q 'Usage:'"
}

# Test version command
function test_version_command {
    run_test "Version command" "$SYSMONITOR --version | grep -q 'SysMonitor version'"
}

# Test invalid option
function test_invalid_option {
    run_test "Invalid option" "$SYSMONITOR --invalid-option" 1
}

# Test output directory creation
function test_output_directory {
    # Create a temporary directory for testing
    local temp_dir
    if [ "$OS_TYPE" = "Darwin" ]; then
        temp_dir=$(mktemp -d -t sysmonitor_test)
    else
        temp_dir=$(mktemp -d)
    fi
    local output_dir="${temp_dir}/output"
    
    run_test "Output directory creation" "$SYSMONITOR --output \"$output_dir\" && [ -d \"$output_dir\" ]"
    
    # Clean up
    rm -rf "$temp_dir"
}

# Test report generation
function test_report_generation {
    # Create a temporary directory for testing
    local temp_dir
    if [ "$OS_TYPE" = "Darwin" ]; then
        temp_dir=$(mktemp -d -t sysmonitor_test)
    else
        temp_dir=$(mktemp -d)
    fi
    local output_dir="${temp_dir}/output"
    
    run_test "Report generation" "$SYSMONITOR --output \"$output_dir\" && ls \"$output_dir\" | grep -q 'report_.*\\.txt'"
    
    # Clean up
    rm -rf "$temp_dir"
}

# Test CSV data generation
function test_csv_generation {
    # Create a temporary directory for testing
    local temp_dir
    if [ "$OS_TYPE" = "Darwin" ]; then
        temp_dir=$(mktemp -d -t sysmonitor_test)
    else
        temp_dir=$(mktemp -d)
    fi
    local output_dir="${temp_dir}/output"
    
    run_test "CSV data generation" "$SYSMONITOR --output \"$output_dir\" && ls \"$output_dir\" | grep -q 'data_.*\\.csv'"
    
    # Clean up
    rm -rf "$temp_dir"
}

# Run all tests
function run_all_tests {
    echo -e "${YELLOW}Starting SysMonitor tests on ${OS_TYPE}${NC}"
    echo
    
    test_script_exists
    test_script_executable
    test_help_command
    test_version_command
    test_invalid_option
    test_output_directory
    test_report_generation
    test_csv_generation
    
    echo -e "${YELLOW}Test summary:${NC}"
    echo -e "Total tests: $TESTS_TOTAL"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    fi
}

# Run the tests
run_all_tests