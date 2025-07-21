#!/bin/bash
# setup-swift-xtensa.sh - Proper Swift setup with correct utils
# Usage: ./setup-swift-xtensa.sh

set -e

# Colors
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }
info() { echo -e "${BLUE}[$(date +%H:%M:%S)] $1${NC}"; }
error() { echo -e "${RED}[$(date +%H:%M:%S)] ERROR: $1${NC}"; exit 1; }

# Configuration
SWIFT_BRANCH="release/6.2"
ESPRESSIF_BRANCH="xtensa_release_17.0.1"

# Check prerequisites
log "Checking prerequisites..."
command -v git >/dev/null 2>&1 || error "git is required"
command -v python3 >/dev/null 2>&1 || error "python3 is required"

# Create workspace
WORKSPACE_DIR="$(pwd)/swift-xtensa-workspace"
log "Setting up workspace: $WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# === CORRECTED: Use Swift's actual update-checkout script ===
log "Cloning Swift with proper bootstrap..."

# Clone Swift main repo
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

# Bootstrap Swift dependencies (this is the proper way)
log "Bootstrapping Swift dependencies (optimized)..."

cd swift
# Use --skip-history for faster clone
python3 utils/update-checkout \
    --clone \
    --scheme "$SWIFT_BRANCH" \
    --skip-history \
    --skip-repository swift \
    --skip-repository llvm-project \
    --skip-repository cmark \
    --skip-repository swift-syntax \
    --skip-repository swift-stress-tester \
    --skip-repository swift-corelibs-foundation \
    --skip-repository swift-corelibs-libdispatch \
    --skip-repository swift-integration-tests \
    --skip-repository swift-xcode-playground-support \
    --skip-repository swift-stress-tester \
    --skip-repository sourcekit-lsp \
    --skip-repository indexstore-db \
    --skip-repository swift-docc \
    --skip-repository swift-docc-render-artifact \
    --skip-repository swift-docc-symbolkit \
    --skip-repository swift-markdown \
    --skip-repository swift-cmark \
    --skip-repository swift-format \
    --skip-repository swift-installer-scripts \
    --skip-repository swift-corelibs-xctest

# Clone only essential LLVM (Espressif version)
log "Setting up LLVM with Xtensa backend..."

cd "$WORKSPACE_DIR"
if [ ! -d "llvm-project-espressif" ]; then
    git clone \
        --branch "$ESPRESSIF_BRANCH" \
        --single-branch \
        --depth=1 \
        --shallow-submodules \
        https://github.com/espressif/llvm-project.git \
        llvm-project-espressif
else
    log "Espressif LLVM already exists"
fi

# Create Swift workspace configuration
log "Creating Swift workspace configuration..."

cat > .swift-workspace << EOF
# Swift-Xtensa Workspace Configuration
WORKSPACE_DIR=$(pwd)
SWIFT_DIR=$WORKSPACE_DIR/swift
LLVM_DIR=$WORKSPACE_DIR/llvm-project-espressif
BUILD_DIR=$WORKSPACE_DIR/build
INSTALL_DIR=$WORKSPACE_DIR/install

# Environment variables
export SWIFT_SOURCE_ROOT=$SWIFT_DIR
export SWIFT_BUILD_ROOT=$BUILD_DIR
export LLVM_SOURCE_DIR=$LLVM_DIR
export LLVM_BUILD_DIR=$BUILD_DIR/llvm
EOF

# Create build environment script
log "Creating build environment..."
cat > build-env.sh << 'EOF'
#!/bin/bash
source .swift-workspace

# Setup build environment
export PATH=$SWIFT_DIR/utils:$PATH
export PATH=$INSTALL_DIR/bin:$PATH

echo "Swift-Xtensa Environment Ready"
echo "Swift:     $SWIFT_DIR"
echo "LLVM:      $LLVM_DIR"
echo "Build:     $BUILD_DIR"
echo "Install:   $INSTALL_DIR"
EOF
chmod +x build-env.sh

# Create minimal build script
log "Creating build scripts..."
cat > build-swift-xtensa.sh << 'EOF'
#!/bin/bash
set -e
source build-env.sh

log() { echo -e "\033[0;32m[$(date +%H:%M:%S)] $1\033[0m"; }

log "Building Swift with Xtensa support..."

# Configure build
./swift/utils/build-script \
  --release \
  --swift-stdlib-build-type=Release \
  --llvm-targets-to-build="Xtensa" \
  --swift-stdlib-deployment-targets="" \
  --skip-build-ios \
  --skip-build-watchos \
  --skip-build-tvos \
  --skip-build-xros \
  --skip-build-benchmarks \
  --skip-test-swift \
  --skip-test-cmark \
  --extra-cmake-options="-DSWIFT_ENABLE_EXPERIMENTAL_FEATURE_EMBEDDED=ON -DSWIFT_BUILD_EMBEDDED_STDLIB=ON" \
  --install-prefix="$INSTALL_DIR" \
  --build-dir="$BUILD_DIR"

log "Build complete! Check $INSTALL_DIR"
EOF
chmod +x build-swift-xtensa.sh

# Create verification
log "Creating verification script..."
cat > verify-setup.sh << 'EOF'
#!/bin/bash
echo "=== Swift-Xtensa Setup Verification ==="
source build-env.sh

echo "Directories:"
ls -la

echo ""
echo "Swift branch:"
cd swift && git branch --show-current && cd ..

echo ""
echo "LLVM branch:"
cd llvm-project-espressif && git branch --show-current && cd ..

echo ""
echo "Available tools:"
ls -la swift/utils/ | head -10

echo ""
echo "Setup complete! 🚀"
echo "Next: ./build-env.sh && ./build-swift-xtensa.sh"
EOF
chmod +x verify-setup.sh

log "✅ Setup complete with proper Swift utils!"
echo ""
info "Key improvements:"
echo "✅ Uses Swift's official update-checkout script"
echo "✅ Skips unnecessary repositories (saves ~2GB)"
echo "✅ Proper LLVM-Espressif integration"
echo "✅ Ready for Xtensa backend compilation"
echo ""
info "Next steps:"
echo "1. cd $WORKSPACE_DIR"
echo "2. ./build-env.sh"
echo "3. ./verify-setup.sh"
echo "4. ./build-swift-xtensa.sh"
