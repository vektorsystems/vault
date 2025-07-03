#!/bin/bash

# =============================================================================
# VAULT AI - COMMON UTILITIES
# =============================================================================

# Ejecuta un comando, loguea y maneja errores. Si TEST_DEPLOY=1, solo imprime el comando.
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

# Carga la configuración de despliegue
load_deploy_config() {
    local script_dir="$1"
    local config_file="$2"

    # If config_file is not an absolute path, look in the parent directory of script_dir
    if [[ "$config_file" != /* ]]; then
        config_file="$(dirname "$script_dir")/$config_file"
    fi

    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        exit 1
    fi

    source "$config_file"
}

# Verifica si es root, excepto en modo test
deploy_check_root() {
    if [ "$TEST_DEPLOY" != "1" ]; then
      if ! is_root; then
          log_error "This script must be run as root (use sudo)"
          exit 1
      fi
    fi
}

# Verifica si es Ubuntu, excepto en modo test
deploy_check_ubuntu() {
    if [ "$TEST_DEPLOY" != "1" ]; then
      if ! is_ubuntu; then
          log_error "This script is designed for Ubuntu systems only"
          exit 1
      fi
    fi
}

# Simula o ejecuta cd según el modo
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

# Simula o ejecuta un comando de verificación/chequeo (status, curl, etc.)
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
export -f load_deploy_config
export -f deploy_check_root
export -f deploy_check_ubuntu
export -f run_cd
export -f dir_exists
export -f file_exists
export -f run_check 