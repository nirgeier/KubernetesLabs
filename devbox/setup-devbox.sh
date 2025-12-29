#!/bin/bash

################################################################################
# Devbox Installation and Setup Script
#
# This script automates the installation of Devbox and sets up the environment
# for the KubernetesLabs project.
#
# Usage:
#   ./scripts/setup-devbox.sh [options]
#
# Options:
#   --skip-install    Skip devbox installation if already installed
#   --skip-nix        Skip Nix installation (assume it's already installed)
#   --global-tools    Install tools globally instead of project-only
#   --verify-only     Only verify installation, don't install
#   -h, --help        Show this help message
#
################################################################################

set -e # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEVBOX_VERSION="0.16.0"

# Parse command line arguments
SKIP_INSTALL=false
GLOBAL_TOOLS=false
VERIFY_ONLY=false
SKIP_NIX=false

while [[ $# -gt 0 ]]; do
  case $1 in
  --skip-install)
    SKIP_INSTALL=true
    shift
    ;;
  --skip-nix)
    SKIP_NIX=true
    shift
    ;;
  --global-tools)
    GLOBAL_TOOLS=true
    shift
    ;;
  --verify-only)
    VERIFY_ONLY=true
    shift
    ;;
  -h | --help)
    grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //'
    exit 0
    ;;
  *)
    echo -e "${RED}Unknown option: $1${NC}"
    echo "Use --help for usage information"
    exit 1
    ;;
  esac
done

################################################################################
# Helper Functions
################################################################################

print_header() {
  echo -e "\n${BLUE}================================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}================================================${NC}\n"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ $1${NC}"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

check_os() {
  case "$(uname -s)" in
  Darwin*)
    OS="macOS"
    ;;
  Linux*)
    OS="Linux"
    ;;
  MINGW* | MSYS* | CYGWIN*)
    OS="Windows"
    ;;
  *)
    OS="Unknown"
    ;;
  esac
  echo "$OS"
}

################################################################################
# Main Functions
################################################################################

generate_devbox_json() {
  print_header "Generating devbox.json"

  cd "$PROJECT_ROOT"

  if [[ -f "devbox.json" ]]; then
    print_warning "devbox.json already exists. Skipping generation."
    return 0
  fi

  cat >devbox.json <<'EOF'
{
  "$schema": "https://raw.githubusercontent.com/jetify-com/devbox/0.16.0/.schema/devbox.schema.json",
  "packages": {
    "helm": {
      "version": "latest",
      "excluded_platforms": [
        "aarch64-darwin"
      ]
    },
    "kubectl": "latest",
    "k3d": "latest",
    "docker": "latest",
    "git": "latest",
    "python": "latest",
    "nodejs": "latest",
    "k9s": "latest",
    "vscode": "latest"
  },
  "shell": {
    "init_hook": [
      "echo 'Welcome to devbox!' > /dev/null"
    ],
    "scripts": {
      "test": [
        "echo \"Error: no test specified\" && exit 1"
      ]
    }
  }
}
EOF

  print_success "devbox.json generated successfully"
}

check_prerequisites() {
  print_header "Checking Prerequisites"

  local os=$(check_os)
  print_info "Operating System: $os"

  if [[ "$os" == "Unknown" ]]; then
    print_error "Unsupported operating system"
    exit 1
  fi

  if [[ "$os" == "Windows" ]]; then
    print_warning "Windows detected. WSL2 is required for Devbox."
    print_info "Please ensure you're running this script in WSL2"
  fi

  # Check for curl or wget
  if ! command_exists curl && ! command_exists wget; then
    print_error "Neither curl nor wget is installed. Please install one of them."
    exit 1
  fi

  # Check for Nix (required by Devbox)
  if ! command_exists nix && ! command_exists nix-shell; then
    print_warning "Nix is not installed. Devbox requires Nix for package management."
    print_info "Nix will be installed automatically during Devbox setup."
  else
    print_success "Nix is already installed"
  fi

  print_success "Prerequisites check passed"
}

install_nix() {
  print_header "Installing Nix"

  if command_exists nix || command_exists nix-shell; then
    print_success "Nix is already installed"
    return 0
  fi

  print_info "Installing Nix package manager (required by Devbox)..."

  local os=$(check_os)

  if [[ "$os" == "macOS" ]]; then
    # Install Nix on macOS
    print_info "Installing Nix on macOS..."
    if command_exists curl; then
      if sh <(curl -L https://nixos.org/nix/install) --daemon; then
        print_success "Nix installed successfully on macOS"
      else
        print_error "Failed to install Nix on macOS"
        exit 1
      fi
    else
      print_error "curl is required for Nix installation on macOS"
      exit 1
    fi
  elif [[ "$os" == "Linux" ]]; then
    # Install Nix on Linux
    print_info "Installing Nix on Linux..."
    if command_exists curl; then
      if sh <(curl -L https://nixos.org/nix/install) --daemon; then
        print_success "Nix installed successfully on Linux"
      else
        print_error "Failed to install Nix on Linux"
        exit 1
      fi
    else
      print_error "curl is required for Nix installation on Linux"
      exit 1
    fi
  else
    print_error "Unsupported OS for automatic Nix installation"
    print_info "Please install Nix manually from https://nixos.org/download.html"
    exit 1
  fi

  # Source nix environment
  if [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    print_success "Nix environment sourced"
  elif [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    print_success "Nix daemon environment sourced"
  else
    print_warning "Could not find Nix profile script. You may need to restart your shell."
  fi

  # Verify Nix installation
  if command_exists nix || command_exists nix-shell; then
    print_success "Nix installation verified"
  else
    print_error "Nix installation failed verification"
    exit 1
  fi
}

install_devbox() {
  print_header "Installing Devbox"

  if command_exists devbox; then
    local current_version=$(devbox version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    print_warning "Devbox is already installed (version: ${current_version})"

    if [[ "$SKIP_INSTALL" == true ]]; then
      print_info "Skipping installation as requested"
      return 0
    fi

    read -p "Do you want to reinstall/update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      print_info "Keeping existing installation"
      return 0
    fi
  fi

  local os=$(check_os)

  # Always use the official installer as it's more reliable
  # Homebrew tap is not maintained/available
  print_info "Installing via official installer..."

  if command_exists curl; then
    if curl -fsSL https://get.jetify.com/devbox | bash; then
      print_success "Installation completed successfully"
    else
      print_error "Installation failed"
      exit 1
    fi
  elif command_exists wget; then
    if wget -qO- https://get.jetify.com/devbox | bash; then
      print_success "Installation completed successfully"
    else
      print_error "Installation failed"
      exit 1
    fi
  else
    print_error "Neither curl nor wget is available"
    exit 1
  fi

  # Update PATH for current session
  export PATH="$HOME/.local/bin:$PATH"

  # Verify installation
  if command_exists devbox; then
    local installed_version=$(devbox version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    print_success "Devbox installed successfully (version: ${installed_version})"
  else
    print_error "Devbox installation failed"
    exit 1
  fi
}

setup_shell_integration() {
  print_header "Setting Up Shell Integration"

  local shell_config=""
  local shell_name=""

  if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
    shell_name="zsh"
  elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
    shell_config="$HOME/.bashrc"
    shell_name="bash"
  else
    print_warning "Unknown shell. Please manually add devbox to your PATH if needed."
    return 0
  fi

  print_info "Detected shell: $shell_name"

  # Check if devbox is in PATH
  if command_exists devbox; then
    print_success "Devbox is already in PATH"
  else
    print_info "Adding devbox to PATH in $shell_config"
    echo '' >>"$shell_config"
    echo '# Devbox' >>"$shell_config"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$shell_config"
    print_success "Added devbox to PATH. Please run: source $shell_config"
  fi
}

verify_devbox_initialization() {
  print_header "Verifying Devbox Initialization"

  cd "$PROJECT_ROOT"

  # Check if devbox.json exists
  if [[ ! -f "devbox.json" ]]; then
    print_error "devbox.json not found in project root"
    return 1
  fi
  print_success "devbox.json found"

  # Check if devbox.json is valid JSON
  if command_exists jq; then
    if jq empty devbox.json &>/dev/null; then
      print_success "devbox.json is valid JSON"
    else
      print_error "devbox.json is not valid JSON"
      return 1
    fi
  else
    print_info "jq not available, skipping JSON validation"
  fi

  # Check if devbox can list packages (validates configuration)
  if devbox list &>/dev/null; then
    print_success "devbox.json configuration is valid"
    print_info "Configured packages:"
    devbox list 2>/dev/null | sed 's/^/  /'
  else
    print_warning "Could not list packages, but will continue"
  fi

  # Verify devbox lockfile exists or can be created
  if [[ -f "devbox.lock" ]]; then
    print_success "devbox.lock file exists"
  else
    print_info "devbox.lock not found, will be created during initialization"
  fi

  print_success "Devbox initialization verified"
}

setup_project() {
  print_header "Setting Up Project Environment"

  cd "$PROJECT_ROOT"

  if [[ ! -f "devbox.json" ]]; then
    print_error "devbox.json not found in project root"
    exit 1
  fi

  print_info "Found devbox.json"

  # Show configured packages
  print_info "Configured packages:"
  if command_exists jq; then
    jq -r '.packages | keys[]' devbox.json | while read -r pkg; do
      echo "  - $pkg"
    done
  else
    grep -A 20 '"packages"' devbox.json | grep '"' | grep -v packages | sed 's/[":,]//g' | sed 's/^/  - /'
  fi

  print_info "Initializing devbox environment (this may take a few minutes on first run)..."

  # Initialize devbox and install packages
  if devbox install; then
    print_success "Devbox packages installed successfully"
  else
    print_error "Failed to install devbox packages"
    exit 1
  fi

  # Test the environment with better error reporting
  print_info "Testing devbox environment..."
  local test_output
  local test_exit_code

  test_output=$(devbox run -- bash -c 'echo "Devbox environment ready"' 2>&1)
  test_exit_code=$?

  if [[ $test_exit_code -eq 0 ]]; then
    print_success "Devbox environment is functional"
  else
    print_warning "Devbox environment test returned exit code: $test_exit_code"
    if [[ -n "$test_output" ]]; then
      print_info "Test output: $test_output"
    fi
    # Don't exit, continue to full testing
    print_info "Will perform comprehensive tests in next step"
  fi

  print_success "Project environment setup complete"
}

test_devbox_shell() {
  print_header "Testing Devbox Shell"

  cd "$PROJECT_ROOT"

  # Test basic shell execution
  print_info "Testing basic shell command execution..."
  if devbox run -- bash -c 'echo "Shell test successful"' &>/dev/null; then
    print_success "Devbox can execute commands"
  else
    print_error "Failed to execute commands in devbox"
    return 1
  fi

  # Test environment variables
  print_info "Testing environment setup..."
  local test_output=$(devbox run -- printenv | grep -c PATH || echo "0")
  if [[ $test_output -gt 0 ]]; then
    print_success "Environment variables are properly set"
  else
    print_warning "Could not verify environment variables"
  fi

  # Test each configured tool
  print_info "Testing configured tools in devbox environment..."

  local tools_tested=0
  local tools_passed=0

  # Test kubectl
  if devbox run -- kubectl version --client &>/dev/null; then
    print_success "kubectl is accessible"
    tools_tested=$((tools_tested + 1))
    tools_passed=$((tools_passed + 1))
  else
    print_warning "kubectl test failed"
    tools_tested=$((tools_tested + 1))
  fi

  # Test helm
  if devbox run -- helm version &>/dev/null; then
    print_success "helm is accessible"
    tools_tested=$((tools_tested + 1))
    tools_passed=$((tools_passed + 1))
  else
    print_warning "helm test failed"
    tools_tested=$((tools_tested + 1))
  fi

  # Test k3d
  if devbox run -- k3d version &>/dev/null; then
    print_success "k3d is accessible"
    tools_tested=$((tools_tested + 1))
    tools_passed=$((tools_passed + 1))
  else
    print_warning "k3d test failed"
    tools_tested=$((tools_tested + 1))
  fi

  print_info "Tools test result: $tools_passed/$tools_tested passed"

  if [[ $tools_passed -eq $tools_tested ]]; then
    print_success "All tools are working correctly"
  elif [[ $tools_passed -gt 0 ]]; then
    print_warning "Some tools are not working correctly"
  else
    print_error "No tools are working. Please check the installation"
    return 1
  fi

  print_success "Devbox environment test completed"
}

install_global_tools() {
  print_header "Installing Global Tools"

  print_warning "This will install tools globally (available in all projects)"
  read -p "Continue? (y/N): " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Skipping global tools installation"
    return 0
  fi

  print_info "Installing kubectl globally..."
  devbox global add kubectl

  print_info "Installing helm globally..."
  devbox global add helm

  print_info "Installing k3d globally..."
  devbox global add k3d

  print_success "Global tools installed"
}

verify_installation() {
  print_header "Verifying Installation"

  cd "$PROJECT_ROOT"

  # Check devbox
  if ! command_exists devbox; then
    print_error "Devbox is not installed or not in PATH"
    return 1
  fi
  print_success "Devbox is installed"

  # Check project packages in devbox shell
  print_info "Checking project packages..."

  if devbox run -- kubectl version --client &>/dev/null; then
    print_success "kubectl is available"
  else
    print_warning "kubectl check failed"
  fi

  if devbox run -- helm version &>/dev/null; then
    print_success "helm is available"
  else
    print_warning "helm check failed"
  fi

  if devbox run -- k3d version &>/dev/null; then
    print_success "k3d is available"
  else
    print_warning "k3d check failed"
  fi

  print_success "Verification complete"
}

print_next_steps() {
  print_header "Next Steps"

  cat <<EOF
${GREEN}Devbox setup is complete!${NC}

To start using devbox in this project:

  ${YELLOW}1. Navigate to the project directory:${NC}
     cd $PROJECT_ROOT

  ${YELLOW}2. Start a devbox shell:${NC}
     devbox shell

  ${YELLOW}3. Verify tools are available:${NC}
     kubectl version --client
     helm version
     k3d version

${BLUE}Useful commands:${NC}

  devbox shell              # Enter devbox environment
  devbox run <command>      # Run command in devbox environment
  devbox add <package>      # Add a new package
  devbox update             # Update all packages
  devbox search <package>   # Search for packages

${BLUE}Documentation:${NC}

  Local:    $PROJECT_ROOT/docs/DEVBOX-SETUP.md
  Official: https://www.jetify.com/devbox/docs/

${GREEN}Happy coding!${NC}
EOF
}

################################################################################
# Main Script Execution
################################################################################

main() {
  print_header "Devbox Setup Script for KubernetesLabs"

  check_prerequisites

  generate_devbox_json

  if [[ "$VERIFY_ONLY" == true ]]; then
    verify_devbox_initialization
    test_devbox_shell
    verify_installation
    exit 0
  fi

  if [[ "$SKIP_INSTALL" == false ]]; then
    if [[ "$SKIP_NIX" == false ]]; then
      install_nix
    fi
    install_devbox
    setup_shell_integration
  fi

  # Verify devbox is properly initialized
  verify_devbox_initialization

  setup_project

  # Test devbox shell functionality
  test_devbox_shell

  if [[ "$GLOBAL_TOOLS" == true ]]; then
    install_global_tools
  fi

  verify_installation
  print_next_steps

  #docker build -t nirgeier/kubernetes-labs .

  print_success "Setup complete!"
}

# Run main function
main "$@"
