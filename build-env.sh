#!/bin/bash
# build-env.sh - Proper environment setup for Swift-Xtensa

# Get absolute paths
export WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SWIFT_SOURCE_ROOT="$WORKSPACE_DIR/swift"
export SWIFT_BUILD_ROOT="$WORKSPACE_DIR/build"
export LLVM_SOURCE_DIR="$WORKSPACE_DIR/llvm-project-espressif"
export LLVM_BUILD_DIR="$SWIFT_BUILD_ROOT/llvm"
export INSTALL_PREFIX="$WORKSPACE_DIR/install"

# Add Swift utils to PATH
export PATH="$SWIFT_SOURCE_ROOT/utils:$PATH"
export PATH="$INSTALL_PREFIX/bin:$PATH"

# Ensure we're in the right directory
cd "$WORKSPACE_DIR"

echo "Swift-Xtensa Environment Ready"
echo "============================="
echo "SWIFT_SOURCE_ROOT: $SWIFT_SOURCE_ROOT"
echo "SWIFT_BUILD_ROOT:  $SWIFT_BUILD_ROOT"
echo "LLVM_SOURCE_DIR:   $LLVM_SOURCE_DIR"
echo "INSTALL_PREFIX:    $INSTALL_PREFIX"
echo "PWD:               $(pwd)"
