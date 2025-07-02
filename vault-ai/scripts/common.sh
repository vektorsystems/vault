#!/bin/bash

# =============================================================================
# VAULT AI - COMMON UTILITIES
# =============================================================================

# Ejecuta un comando, loguea y maneja errores. Si TEST_DEPLOY=1, solo imprime el comando.
run_cmd() {
    local cmd="$*"
    if [ "$TEST_DEPLOY" = "1" ]; then
        log_info "[test] executing command: $cmd"
        return 0
    fi
    log_info "[exec] $cmd"
    eval "$cmd"
    local status=$?
    if [ $status -ne 0 ]; then
        log_error "Command failed: $cmd"
        exit $status
    fi
    return 0
}

# Carga la configuración de despliegue
load_deploy_config() {
    local script_dir="$1"
    local config_path="$(cd "$script_dir/.." && pwd)/.env-deploy-config"
    if [ -f "$config_path" ]; then
      export $(grep -v '^#' "$config_path" | xargs)
    else
      log_error "No se encontró el archivo de configuración $config_path"
      exit 1
    fi
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
    if [ "$TEST_DEPLOY" = "1" ]; then
        log_info "[test] cd $dir"
        return 0
    fi
    cd "$dir"
    local status=$?
    if [ $status -ne 0 ]; then
        log_error "cd failed: $dir"
        exit $status
    fi
    return 0
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
    local cmd="$*"
    if [ "$TEST_DEPLOY" = "1" ]; then
        log_info "[test] check: $cmd (simulated success)"
        return 0
    fi
    eval "$cmd"
    return $?
}

export -f run_cmd
export -f load_deploy_config
export -f deploy_check_root
export -f deploy_check_ubuntu
export -f run_cd
export -f dir_exists
export -f file_exists
export -f run_check 