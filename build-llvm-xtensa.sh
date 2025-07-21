#!/bin/bash
# build-llvm-xtensa.sh - Build LLVM with Xtensa backend only
set -e

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }

# Load workspace configuration
if [ -f ./.swift-workspace ]; then
    source ./.swift-workspace
else
    # Fallback configuration
    WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LLVM_DIR="$WORKSPACE_DIR/llvm-project"
    LLVM_BUILD_DIR="$WORKSPACE_DIR/build/llvm"
    INSTALL_DIR="$WORKSPACE_DIR/install"
fi

log "Building LLVM Xtensa backend..."

mkdir -p "$LLVM_BUILD_DIR"
cd "$LLVM_BUILD_DIR"

cmake \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_TARGETS_TO_BUILD="" \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  "$LLVM_DIR/llvm"

ninja -j$(sysctl -n hw.ncpu)
ninja install

log "LLVM Xtensa backend built at $INSTALL_DIR"
