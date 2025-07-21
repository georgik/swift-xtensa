#!/bin/bash
# fix-llvm-path.sh - Verify LLVM directory structure for Swift-Xtensa build
set -e

log() { echo -e "\033[0;32m[$(date +%H:%M:%S)] $1\033[0m"; }

log "Verifying LLVM directory structure..."

# This should be run from within the swift-xtensa-workspace directory
if [[ ! "$PWD" =~ swift-xtensa-workspace ]]; then
    echo "⚠️  This script should be run from within the swift-xtensa-workspace directory"
    echo "Current directory: $PWD"
    echo "Expected pattern: *swift-xtensa-workspace*"
fi

# Verify the structure - we should have llvm-project with Espressif LLVM
if [ -d "llvm-project/llvm" ]; then
    log "✅ LLVM directory structure is correct"
    log "LLVM source: $(pwd)/llvm-project/llvm"
    
    # Check if this is the Espressif LLVM with Xtensa support
    if [ -f "llvm-project/llvm/lib/Target/Xtensa/CMakeLists.txt" ]; then
        log "✅ Xtensa target found in LLVM"
        
        # Show some details about the Xtensa target
        echo ""
        echo "Xtensa target details:"
        ls -la llvm-project/llvm/lib/Target/Xtensa/ | head -5
    else
        echo "⚠️  Xtensa target not found - ensure you're using Espressif LLVM fork"
        echo "Expected: llvm-project/llvm/lib/Target/Xtensa/CMakeLists.txt"
        exit 1
    fi
    
    # Check workspace configuration
    if [ -f ".swift-workspace" ]; then
        log "✅ Workspace configuration found"
        source .swift-workspace
        echo "LLVM_DIR configured as: $LLVM_DIR"
    else
        echo "⚠️  .swift-workspace configuration missing"
    fi
    
else
    echo "❌ LLVM directory missing: llvm-project/llvm"
    echo "Expected: $(pwd)/llvm-project/llvm"
    echo ""
    echo "Available directories:"
    ls -la | grep -E "(llvm|swift)"
    exit 1
fi

log "Ready to continue build!"
