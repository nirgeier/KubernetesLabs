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
MAGENTA='\033[0;35m'
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
  print_info "Checking prerequisites..."

  local missing=0

  if ! check_tool kubectl; then missing=1; fi
  if ! check_tool helm; then missing=1; fi

  if [[ "$missing" -eq 1 ]]; then
    exit 1
  fi

  # Check if kubectl can connect to cluster
  if ! kubectl cluster-info &>/dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please configure kubectl."
    exit 1
  fi

  print_success "All prerequisites are met!"
}

# Wait for pods with a label in a namespace
wait_for_pods() {
  local label="$1"
  local namespace="$2"
  local timeout="${3:-300}"
  print_info "Waiting for pods with label '$label' in namespace '$namespace'..."
  kubectl wait --for=condition=ready pod -l "$label" -n "$namespace" --timeout="${timeout}s" 2>/dev/null
}

# Get the directory of this script
get_lab_dir() {
  cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd
}
