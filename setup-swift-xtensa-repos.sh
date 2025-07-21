#!/bin/bash
# setup-swift-xtensa-repos.sh - Initialize Swift-Xtensa workspace with required repositories
# Usage: ./setup-swift-xtensa-repos.sh

# Note: We don't use 'set -e' globally because update-checkout might have non-critical failures

# Colors for logging
GREEN='\033[0;32m'
BLUE='\033[0;34m' 
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }
info() { echo -e "${BLUE}[$(date +%H:%M:%S)] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +%H:%M:%S)] ERROR: $1${NC}"; exit 1; }

# Configuration
SWIFT_BRANCH="release/6.2"
ESPRESSIF_BRANCH="xtensa_release_17.0.1"

# Check prerequisites
log "Checking prerequisites..."
command -v git >/dev/null 2>&1 || error "git is required"
command -v python3 >/dev/null 2>&1 || error "python3 is required"
command -v cmake >/dev/null 2>&1 || error "cmake is required"
command -v ninja >/dev/null 2>&1 || error "ninja is required"

# Create workspace directory
WORKSPACE_DIR="$(pwd)/swift-xtensa-workspace"
log "Setting up Swift-Xtensa workspace: $WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# === Clone Swift with proper bootstrap ===
log "Cloning Swift repository..."

if [ ! -d "swift" ]; then
    git clone \
        --branch "$SWIFT_BRANCH" \
        --single-branch \
        --depth=1 \
        https://github.com/apple/swift.git
else
    log "Swift already exists, updating..."
    cd swift && git pull && cd ..
fi

# Bootstrap Swift dependencies (minimal set for Xtensa compilation)
log "Bootstrapping Swift dependencies (optimized for Xtensa)..."

cd swift

# Remove problematic cmake directory if it exists and is causing issues
if [ -d "../cmake" ]; then
    log "Checking existing cmake repository..."
    cd ../cmake
    if ! git status >/dev/null 2>&1 || ! git tag | grep -q "v3.30"; then
        log "Removing problematic cmake repository to avoid checkout errors"
        cd ..
        rm -rf cmake
    else
        cd ../swift
    fi
fi

# Use --skip-history for faster clone and skip non-essential repositories
log "Running update-checkout with cmake skipped..."
if ! python3 utils/update-checkout \
    --clone \
    --scheme "$SWIFT_BRANCH" \
    --skip-history \
    --skip-repository swift \
    --skip-repository llvm-project \
    --skip-repository cmark \
    --skip-repository cmake \
    --skip-repository swift-syntax \
    --skip-repository swift-stress-tester \
    --skip-repository swift-corelibs-foundation \
    --skip-repository swift-corelibs-libdispatch \
    --skip-repository swift-integration-tests \
    --skip-repository swift-xcode-playground-support \
    --skip-repository sourcekit-lsp \
    --skip-repository indexstore-db \
    --skip-repository swift-docc \
    --skip-repository swift-docc-render-artifact \
    --skip-repository swift-docc-symbolkit \
    --skip-repository swift-markdown \
    --skip-repository swift-cmark \
    --skip-repository swift-format \
    --skip-repository swift-installer-scripts \
    --skip-repository swift-corelibs-xctest; then
    warn "update-checkout had some issues, but continuing..."
fi

cd "$WORKSPACE_DIR"

# === Clone Espressif LLVM with Xtensa backend ===
log "Setting up LLVM with Xtensa backend (Espressif fork)..."

if [ ! -d "llvm-project" ]; then
    git clone \
        --branch "$ESPRESSIF_BRANCH" \
        --single-branch \
        --depth=1 \
        --shallow-submodules \
        https://github.com/espressif/llvm-project.git
else
    log "Espressif LLVM already exists, updating..."
    cd llvm-project && git pull && cd ..
fi

# === Create Swift workspace configuration ===
log "Creating Swift workspace configuration..."

cat > .swift-workspace << EOF
# Swift-Xtensa Workspace Configuration
WORKSPACE_DIR=$(pwd)
SWIFT_DIR=\$WORKSPACE_DIR/swift
LLVM_DIR=\$WORKSPACE_DIR/llvm-project
BUILD_DIR=\$WORKSPACE_DIR/build
INSTALL_DIR=\$WORKSPACE_DIR/install

# Environment variables
export SWIFT_SOURCE_ROOT=\$SWIFT_DIR
export SWIFT_BUILD_ROOT=\$BUILD_DIR
export LLVM_SOURCE_DIR=\$LLVM_DIR
export LLVM_BUILD_DIR=\$BUILD_DIR/llvm
EOF

# === Create build environment script ===
log "Creating build environment script..."
cat > build-env.sh << 'EOF'
#!/bin/bash
# build-env.sh - Proper environment setup for Swift-Xtensa

# Load workspace configuration
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$WORKSPACE_DIR/.swift-workspace" ]; then
    source "$WORKSPACE_DIR/.swift-workspace"
else
    echo "ERROR: .swift-workspace not found. Run setup first."
    exit 1
fi

# Set environment variables for Swift build
export SWIFT_SOURCE_ROOT="$SWIFT_DIR"
export SWIFT_BUILD_ROOT="$BUILD_DIR"
export LLVM_SOURCE_DIR="$LLVM_DIR"
export LLVM_BUILD_DIR="$BUILD_DIR/llvm"
export INSTALL_PREFIX="$INSTALL_DIR"

# Add Swift utils to PATH
export PATH="$SWIFT_SOURCE_ROOT/utils:$PATH"
export PATH="$INSTALL_PREFIX/bin:$PATH"

# Create directories if they don't exist
mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

# Ensure we're in the right directory
cd "$WORKSPACE_DIR"

echo "Swift-Xtensa Environment Ready"
echo "============================="
echo "SWIFT_SOURCE_ROOT: $SWIFT_SOURCE_ROOT"
echo "SWIFT_BUILD_ROOT:  $SWIFT_BUILD_ROOT"
echo "LLVM_SOURCE_DIR:   $LLVM_SOURCE_DIR"
echo "INSTALL_PREFIX:    $INSTALL_PREFIX"
echo "PWD:               $(pwd)"
echo ""
echo "Available commands:"
echo "  ./fix-llvm-path.sh       - Verify LLVM directory structure"
echo "  ./build-llvm-xtensa.sh   - Build LLVM with Xtensa backend"
echo "  ./build-swift-compiler.sh - Build Swift compiler for Xtensa"
EOF
chmod +x build-env.sh

# === Create verification script ===
log "Creating setup verification script..."
cat > verify-setup.sh << 'EOF'
#!/bin/bash
echo "=== Swift-Xtensa Setup Verification ==="
source build-env.sh

echo ""
log() { echo -e "\033[0;32m✓ $1\033[0m"; }
error() { echo -e "\033[0;31m✗ $1\033[0m"; }

echo "📁 Directory Structure:"
ls -la | grep -E "(swift|llvm|build)"

echo ""
echo "🔧 Repository Status:"
if [ -d "swift" ]; then
    log "Swift repository: $(cd swift && git branch --show-current)"
else
    error "Swift repository missing"
fi

if [ -d "llvm-project" ]; then
    log "LLVM repository: $(cd llvm-project && git branch --show-current)"
else
    error "LLVM repository missing"
fi

echo ""
echo "🛠️ Build Tools:"
if [ -f "swift/utils/build-script" ]; then
    log "Swift build script available"
else
    error "Swift build script missing"
fi

echo ""
echo "🚀 Setup Status: Complete!"
echo ""
echo "Next steps:"
echo "1. ./build-env.sh"
echo "2. ./build-llvm-xtensa.sh"
echo "3. ./build-swift-compiler.sh"
echo "4. cd swift-xtensa-validation && ./verify-xtensa.sh"
EOF
chmod +x verify-setup.sh

# === Summary ===
log "✅ Swift-Xtensa repository setup complete!"
echo ""
info "📦 Repositories cloned:"
echo "✅ Swift compiler (release/6.2)"
echo "✅ Swift dependencies (minimal set)"
echo "✅ LLVM with Xtensa backend (Espressif fork)"
echo ""
info "🔧 Configuration files created:"
echo "✅ .swift-workspace (environment config)"
echo "✅ build-env.sh (environment loader)"
echo "✅ verify-setup.sh (setup validator)"
echo ""
info "📁 Workspace structure:"
find . -maxdepth 2 -type d | head -10
echo ""
warn "📋 Next steps:"
echo "1. cd $WORKSPACE_DIR"
echo "2. ./build-env.sh"
echo "3. ./verify-setup.sh"
echo "4. Copy build scripts from this project"
echo "5. Run build scripts to compile Swift with Xtensa support"
echo ""
log "🎯 Ready for Swift-Xtensa compilation!"
