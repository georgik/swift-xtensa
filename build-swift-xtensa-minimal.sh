#!/bin/bash
# build-swift-xtensa-minimal.sh - Swift 6.2 minimal build
set -e

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_DIR="$WORKSPACE_DIR/swift"
LLVM_DIR="$WORKSPACE_DIR/llvm-project-espressif"
BUILD_DIR="$WORKSPACE_DIR/build"
INSTALL_DIR="$WORKSPACE_DIR/install"

log "Starting Swift 6.2 minimal build..."

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$SWIFT_DIR"

# Configure LLVM build first
log "Configuring LLVM with Xtensa backend..."

mkdir -p "$BUILD_DIR/llvm"
cd "$BUILD_DIR/llvm"

cmake \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_TARGETS_TO_BUILD="Xtensa" \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  "$LLVM_DIR/llvm"

# Build LLVM
log "Building LLVM Xtensa backend..."
ninja -j$(sysctl -n hw.ncpu)

# Now build Swift
log "Building Swift compiler..."

cd "$SWIFT_DIR"
mkdir -p "$BUILD_DIR/swift"

./utils/build-script \
  --release \
  --skip-build-ios \
  --skip-build-watchos \
  --skip-build-tvos \
  --skip-build-xros \
  --skip-build-benchmarks \
  --skip-test-swift \
  --skip-test-cmark \
  --skip-build-foundation \
  --skip-build-libdispatch \
  --skip-build-xctest \
  --skip-early-swift-driver \
  --llvm-targets-to-build="Xtensa" \
  --install-prefix="$INSTALL_DIR" \
  --build-dir="$BUILD_DIR/swift" \
  --llvm-build-dir="$BUILD_DIR/llvm" \
  --host-target="macosx-arm64" \
  --reconfigure

log "✅ Build complete! Check $INSTALL_DIR"
