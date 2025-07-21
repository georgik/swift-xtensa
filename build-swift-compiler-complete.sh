#!/bin/bash
# build-swift-compiler-complete.sh - Use Swift's official build system
set -e

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_DIR="$WORKSPACE_DIR/swift"
BUILD_DIR="$WORKSPACE_DIR/build"
INSTALL_DIR="$WORKSPACE_DIR/install"

log "Building complete Swift toolchain with Xtensa support..."

# Use Swift's official build-script with all dependencies
cd "$SWIFT_DIR"

# Build with Swift's unified approach
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
  --llvm-targets-to-build="" \
  --llvm-experimental-targets-to-build="Xtensa" \
  --install-prefix="$INSTALL_DIR" \
  --build-dir="$BUILD_DIR" \
  --host-target="macosx-arm64" \
  --reconfigure

log "✅ SUCCESS! Swift with Xtensa support is building..."
log "📍 This will take 10-20 minutes..."
log "🎯 Tools will be available at: $INSTALL_DIR/bin/"
