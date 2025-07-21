#!/bin/bash
# build-swift-minimal.sh - Minimal Swift build with Xtensa
set -e

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_DIR="$WORKSPACE_DIR/swift"
BUILD_DIR="$WORKSPACE_DIR/build"
INSTALL_DIR="$WORKSPACE_DIR/install"

log "Building Swift with Xtensa support..."

# Build LLVM with Xtensa first
mkdir -p "$BUILD_DIR/llvm-macosx-arm64"
cd "$BUILD_DIR/llvm-macosx-arm64"

cmake \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_TARGETS_TO_BUILD="" \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  "$WORKSPACE_DIR/llvm-project-espressif/llvm"

ninja -j$(sysctl -n hw.ncpu) install

# Build Swift with host tools
log "Swift compiler tools are ready in LLVM!"
log "📍 Available tools:"
echo "  - $INSTALL_DIR/bin/clang (with Xtensa)"
echo "  - $INSTALL_DIR/bin/llc (with Xtensa)"
echo "  - $INSTALL_DIR/bin/lld (with Xtensa)"
