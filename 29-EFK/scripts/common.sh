#!/bin/bash
# =============================================================================
# Common functions shared across all scripts
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

print_header() {
  echo ""
  echo "============================================"
  echo -e "${CYAN} $1 ${NC}"
  echo "============================================"
  echo ""
}

# Load .env file
load_env() {
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
  local ENV_FILE="${SCRIPT_DIR}/.env"

  # Check parent directories for .env
  while [[ ! -f "$ENV_FILE" && "$SCRIPT_DIR" != "/" ]]; do
    SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"
    ENV_FILE="${SCRIPT_DIR}/.env"
  done

  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    export PROJECT_ROOT="$SCRIPT_DIR"
  else
    print_error "Cannot find .env file"
    exit 1
  fi
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check required tools
check_tool() {
  if ! command_exists "$1"; then
    print_error "$1 is not installed. Please install it first."
    return 1
  fi
}

check_prerequisites() {
  local tools=("$@")
  local missing=0
  for tool in "${tools[@]}"; do
    if ! check_tool "$tool"; then
      missing=1
    fi
  done
  if [[ "$missing" -eq 1 ]]; then
    exit 1
  fi
  print_success "All prerequisites met"
}

# Wait for a Kubernetes resource
wait_for_pod() {
  local label="$1"
  local namespace="$2"
  local timeout="${3:-300}"
  print_info "Waiting for pod with label $label in namespace $namespace..."
  kubectl wait --for=condition=ready pod -l "$label" -n "$namespace" --timeout="${timeout}s"
}

# Ensure directories exist
ensure_dirs() {
  for dir in "$@"; do
    mkdir -p "$dir"
  done
}
