#!/bin/bash
# swift-xtensa-build.sh - Complete build script for Swift on ESP32-S3

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m'

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"
}

# Function to run commands with logging
run() {
    log "Running: $1"
    eval "$1"
}

# Main workspace directory
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_DIR="$WORKSPACE_DIR/swift"
LLVM_DIR="$WORKSPACE_DIR/llvm-project-espressif"
BUILD_DIR="$WORKSPACE_DIR/build"
INSTALL_DIR="$WORKSPACE_DIR/install"

# Step 1: Clone dependencies
log "Cloning dependencies..."
#run "git clone --depth=1 --branch release/6.2 https://github.com/apple/swift.git"
#run "git clone --depth=1 --branch release/6.2 https://github.com/apple/swift-syntax.git"
#run "git clone --depth=1 --branch release/6.2 https://github.com/apple/swift-experimental-string-processing.git"
#run "git clone --depth=1 --branch release/6.2 https://github.com/apple/swift-corelibs-libdispatch.git"
#run "git clone --depth=1 --branch xtensa_release_17.0.1 https://github.com/espressif/llvm-project.git llvm-project-espressif"
#run "git clone --depth=1 --branch release/6.2 https://github.com/apple/cmark.git"

# Step 2: Build LLVM with Xtensa support

# build cmark host tools
log "Building cmark..."
mkdir -p "$BUILD_DIR/cmark-macosx-arm64"
cd "$BUILD_DIR/cmark-macosx-arm64"
run "cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR' '$WORKSPACE_DIR/cmark'"
run "ninja -j$(sysctl -n hw.ncpu)"
run "ninja install"

# Step 2: Build LLVM with Xtensa support
log "Building LLVM with Xtensa support..."
mkdir -p "$BUILD_DIR/llvm-macosx-arm64"
cd "$BUILD_DIR/llvm-macosx-arm64"
run "cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_TARGETS_TO_BUILD='' \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD='Xtensa' \
  -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR' \
  -DLLVM_ENABLE_PROJECTS='clang;lld' \
  '$LLVM_DIR/llvm'"
run "ninja -j$(sysctl -n hw.ncpu)"
run "ninja install"
run "ninja install-clang-resource-headers"

# Step 3: Build Swift with Xtensa support (host tools only)
log "Building Swift with Xtensa support..."
cd "$SWIFT_DIR"
mkdir -p "$BUILD_DIR/swift-macosx-arm64"
cd "$BUILD_DIR/swift-macosx-arm64"

run "cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR' \
  -DLLVM_DIR='$BUILD_DIR/llvm-macosx-arm64/lib/cmake/llvm' \
  -DClang_DIR='$BUILD_DIR/llvm-macosx-arm64/lib/cmake/clang' \
  -DSWIFT_PATH_TO_CMARK_SOURCE='$WORKSPACE_DIR/cmark' \
  -DSWIFT_PATH_TO_CMARK_BUILD='$BUILD_DIR/cmark-macosx-arm64' \
  -DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE='$WORKSPACE_DIR/swift-syntax' \
  -DSWIFT_BUILD_SWIFT_SYNTAX=ON \
  -DSWIFT_INCLUDE_TOOLS=ON \
  -DSWIFT_BUILD_STDLIB=OFF \
  -DSWIFT_BUILD_SDK_OVERLAY=OFF \
  -DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
  -DSWIFT_HOST_VARIANT=macosx \
  -DSWIFT_HOST_VARIANT_ARCH='arm64' \
  -DSWIFT_DARWIN_SUPPORTED_ARCHS='arm64' \
  '$SWIFT_DIR'"

# Build the real compiler
run "ninja -j$(sysctl -n hw.ncpu) swift-frontend"

# Install swift-frontend *and* the swiftc wrapper
run "ninja install-swift-frontend install-swiftc"
log "✅ Swift with Xtensa support is ready!"
log "📍 Tools available at: $INSTALL_DIR/bin/"

