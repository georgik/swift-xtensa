#!/bin/bash
# build-swift-compiler-final.sh - Swift 6.2 with Xtensa support (working)
set -e

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_DIR="$WORKSPACE_DIR/swift"
BUILD_DIR="$WORKSPACE_DIR/build"
INSTALL_DIR="$WORKSPACE_DIR/install"

log "Building Swift with Xtensa support..."

# Build using Swift's unified approach with correct parameters
"$SWIFT_DIR/utils/build-script" \
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
  --install-prefix="$INSTALL_DIR" \
  --build-dir="$BUILD_DIR" \
  --host-target="macosx-arm64" \
  --extra-cmake-options="-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=Xtensa" \
  --reconfigure

log "✅ Swift with Xtensa support is building..."
log "📍 This will complete the full toolchain"
