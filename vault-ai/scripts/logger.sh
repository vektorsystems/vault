#!/bin/bash

# =============================================================================
# VAULT AI - LOGGING SYSTEM
# =============================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log levels
LOG_LEVEL_INFO=0
LOG_LEVEL_WARN=1
LOG_LEVEL_ERROR=2
LOG_LEVEL_SUCCESS=3

# Current log level (can be overridden)
CURRENT_LOG_LEVEL=${LOG_LEVEL:-0}

# Timestamp function
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Log functions
log_info() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ]; then
        echo -e "${BLUE}[INFO]${NC} $(get_timestamp) - $1"
    fi
}

log_warn() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARN ]; then
        echo -e "${YELLOW}[WARN]${NC} $(get_timestamp) - $1"
    fi
}

log_error() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ]; then
        echo -e "${RED}[ERROR]${NC} $(get_timestamp) - $1" >&2
    fi
}

log_success() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_SUCCESS ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $(get_timestamp) - $1"
    fi
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $(get_timestamp) - $1"
}

log_header() {
    echo -e "${PURPLE}=============================================================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}=============================================================================${NC}"
}

log_subheader() {
    echo -e "${CYAN}-----------------------------------------------------------------------------${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}-----------------------------------------------------------------------------${NC}"
}

# Progress indicator
show_progress() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Check if command exists
command_exists() {
    if [ "$TEST_DEPLOY" = "1" ]; then
        return 0
    fi
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
is_root() {
    [ "$(id -u)" -eq 0 ]
}

# Check if running on Ubuntu
is_ubuntu() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        [ "$ID" = "ubuntu" ]
    else
        false
    fi
}

# Check Ubuntu version
get_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_ID"
    else
        echo "unknown"
    fi
}

# Export functions for use in other scripts
export -f log_info log_warn log_error log_success log_step log_header log_subheader
export -f show_progress command_exists is_root is_ubuntu get_ubuntu_version 