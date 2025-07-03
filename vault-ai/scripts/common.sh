#!/bin/bash

# =============================================================================
# VAULT AI - COMMON UTILITIES
# =============================================================================

# Run a command, log and handle errors. If TEST_DEPLOY=1, only print the command.
run_cmd() {
    if [ "$TEST_DEPLOY" = "1" ]; then
        log_info "[TEST] Would run: $*"
        return 0
    fi

    if eval "$*"; then
        log_success "${3:-Command completed successfully}"
        return 0
    else
        log_error "${2:-Command failed}"
        return 1
    fi
}

# Simulate or execute cd based on mode
run_cd() {
    local dir="$1"
    local error_msg="${2:-Failed to change directory to $dir}"

    if [ "$TEST_DEPLOY" = "1" ]; then
        log_info "[TEST] Would change directory to: $dir"
        return 0
    fi

    if cd "$dir"; then
        return 0
    else
        log_error "$error_msg"
        return 1
    fi
}

dir_exists() {
    if [ "$TEST_DEPLOY" = "1" ]; then
        return 0
    fi
    [ -d "$1" ]
}

file_exists() {
    if [ "$TEST_DEPLOY" = "1" ]; then
        return 0
    fi
    [ -f "$1" ]
}

# Simulate or execute a check command (status, curl, etc.)
run_check() {
    if [ "$TEST_DEPLOY" = "1" ]; then
        log_info "[TEST] Would check: $*"
        return 0
    fi

    if eval "$*" >/dev/null 2>&1; then
        log_success "${3:-Check passed}"
        return 0
    else
        log_error "${2:-Check failed}"
        return 1
    fi
}

export -f run_cmd
export -f run_cd
export -f dir_exists
export -f file_exists
export -f run_check 