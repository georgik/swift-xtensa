#!/bin/bash

# Setup script for Swift Xtensa build environment
# Clones the required repositories in the correct structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if we're in the right directory
if [[ ! -f "build-swift-xtensa.sh" ]]; then
    error "Please run this script from the swift-xtensa directory"
fi

log "Setting up Swift Xtensa build environment..."

# Clone Swift repository
if [ ! -d "../swift" ]; then
    log "Cloning Swift repository..."
    git clone https://github.com/apple/swift.git ../swift
    
    log "Updating Swift checkout (this may take a while)..."
    cd ../swift
    ./utils/update-checkout --clone
    cd - > /dev/null
else
    log "Swift repository already exists, updating..."
    cd ../swift
    git pull origin main
    ./utils/update-checkout --clone
    cd - > /dev/null
fi

# Clone ESP LLVM repository
if [ ! -d "../llvm-project-espressif" ]; then
    log "Cloning ESP LLVM repository..."
    git clone https://github.com/espressif/llvm-project.git ../llvm-project-espressif
else
    log "ESP LLVM repository already exists, updating..."
    cd ../llvm-project-espressif
    git pull origin esp_main
    cd - > /dev/null
fi

log "Repository setup completed!"
log ""
log "Directory structure:"
log "  swift-xtensa/           (current directory)"
log "  swift/                  (Apple Swift compiler)"
log "  llvm-project-espressif/ (ESP LLVM with Xtensa support)"
log "  rust/                   (ESP Rust for reference)"
log ""
log "Next steps:"
log "  1. Install dependencies: brew install cmake ninja python3"
log "  2. Run build script: ./build-swift-xtensa.sh"
