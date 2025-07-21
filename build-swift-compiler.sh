#!/bin/bash
# build-swift-compiler.sh - Complete Swift build with proper LLVM paths and dependencies
set -e

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }
info() { echo -e "${BLUE}[$(date +%H:%M:%S)] $1${NC}"; }

# Load workspace configuration
if [ -f ./.swift-workspace ]; then
    source ./.swift-workspace
else
    # Fallback configuration
    WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SWIFT_DIR="$WORKSPACE_DIR/swift"
    LLVM_DIR="$WORKSPACE_DIR/llvm-project-espressif"
    CMARK_DIR="$WORKSPACE_DIR/cmark"
    BUILD_DIR="$WORKSPACE_DIR/build"
    INSTALL_DIR="$WORKSPACE_DIR/install"
fi

log "Building Swift compiler with Xtensa support..."

# Step 1: Build cmark first
if [ ! -d "$BUILD_DIR/cmark-macosx-arm64" ]; then
    log "Step 1: Building cmark..."
    mkdir -p "$BUILD_DIR/cmark-macosx-arm64"
    cd "$BUILD_DIR/cmark-macosx-arm64"
    
    cmake \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
      "$CMARK_DIR"
    
    ninja -j$(sysctl -n hw.ncpu)
    info "✅ cmark build completed"
else
    info "✅ cmark already built"
fi

# Step 2: Ensure LLVM is built
if [ ! -d "$BUILD_DIR/llvm-macosx-arm64" ]; then
    log "Step 2: Building LLVM with Xtensa support..."
    mkdir -p "$BUILD_DIR/llvm-macosx-arm64"
    cd "$BUILD_DIR/llvm-macosx-arm64"
    
    cmake \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_TARGETS_TO_BUILD="" \
      -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" \
      -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
      -DLLVM_ENABLE_PROJECTS="clang;lld" \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_INCLUDE_TESTS=OFF \
      "$LLVM_DIR/llvm"
    
    ninja -j$(sysctl -n hw.ncpu)
    info "✅ LLVM build completed"
else
    info "✅ LLVM already built"
fi

# Step 3: Build Swift with proper LLVM and cmark paths
log "Step 3: Building Swift compiler..."
cd "$SWIFT_DIR"

# Use standalone build with correct LLVM paths
mkdir -p "$BUILD_DIR/swift-macosx-arm64"
cd "$BUILD_DIR/swift-macosx-arm64"

cmake \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DLLVM_DIR="$BUILD_DIR/llvm-macosx-arm64/lib/cmake/llvm" \
  -DClang_DIR="$BUILD_DIR/llvm-macosx-arm64/lib/cmake/clang" \
  -DSWIFT_PATH_TO_CMARK_SOURCE="$WORKSPACE_DIR/cmark" \
  -DSWIFT_PATH_TO_CMARK_BUILD="$BUILD_DIR/cmark-macosx-arm64" \
  -DSWIFT_INCLUDE_TOOLS=ON \
  -DSWIFT_BUILD_STDLIB=OFF \
  -DSWIFT_BUILD_SDK_OVERLAY=OFF \
  -DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
  -DSWIFT_ENABLE_EXPERIMENTAL_CAS=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING=OFF \
  "$SWIFT_DIR"

ninja -j$(sysctl -n hw.ncpu) swift-frontend
ninja install-swift-frontend

log "✅ SUCCESS! Swift compiler with Xtensa support is ready!"
log "📍 Location: $INSTALL_DIR/bin/swiftc"
log "🎯 You can now compile Swift → LLVM IR → Xtensa assembly!"
