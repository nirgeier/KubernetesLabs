#!/bin/bash

# Function to detect OS type and architecture
detect_os() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    # Convert architecture names to match K9s release naming
    case "${ARCH}" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
    esac
    
    echo "${OS}_${ARCH}"
}

# Function to get the latest release version
get_latest_version() {
    curl -s https://api.github.com/repos/derailed/k9s/releases/latest | 
    grep '"tag_name":' | 
    sed -E 's/.*"([^"]+)".*/\1/' | 
    sed 's/^v//'
}

# Main installation function
install_k9s() {
    echo "Detecting system information..."
    OS_ARCH=$(detect_os)
    
    echo "Getting latest K9s version..."
    VERSION=$(get_latest_version)
    
    if [ -z "$VERSION" ]; then
        echo "Error: Could not determine latest version"
        exit 1
    fi
    
    DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/v${VERSION}/k9s_${OS_ARCH}.tar.gz"
    
    echo "Downloading K9s version ${VERSION}..."
    if ! curl -L -o k9s.tar.gz "${DOWNLOAD_URL}"; then
        echo "Error: Download failed"
        exit 1
    fi
    
    echo "Extracting archive..."
    tar xzf k9s.tar.gz
    
    echo "Installing K9s to /usr/local/bin..."
    if [ -w /usr/local/bin ]; then
        mv k9s /usr/local/bin/
    else
        sudo mv k9s /usr/local/bin/
    fi
    
    # Cleanup
    rm -f k9s.tar.gz README.md LICENSE
    
    echo "Setting executable permissions..."
    if [ -w /usr/local/bin/k9s ]; then
        chmod +x /usr/local/bin/k9s
    else
        sudo chmod +x /usr/local/bin/k9s
    fi
    
    echo "K9s $(k9s version) has been installed successfully!"
}

# Run the installation
install_k9s