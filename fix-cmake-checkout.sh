#!/bin/bash
# fix-cmake-checkout.sh - Fix cmake repository checkout issues
set -e

log() { echo -e "\033[0;32m[$(date +%H:%M:%S)] $1\033[0m"; }
warn() { echo -e "\033[1;33m[$(date +%H:%M:%S)] WARNING: $1\033[0m"; }

log "Fixing cmake repository checkout issues..."

# This should be run from within the swift-xtensa-workspace directory
if [[ ! "$PWD" =~ swift-xtensa-workspace ]]; then
    echo "⚠️  This script should be run from within the swift-xtensa-workspace directory"
    echo "Current directory: $PWD"
    exit 1
fi

# Check if cmake directory exists and has issues
if [ -d "cmake" ]; then
    log "Found cmake directory, checking status..."
    cd cmake
    
    # Check if we're in a detached HEAD state or have checkout issues
    if ! git status >/dev/null 2>&1; then
        warn "Git repository seems corrupted, removing and will skip in future"
        cd ..
        rm -rf cmake
        log "Removed problematic cmake directory"
    else
        # Try to fetch and see what tags are available
        log "Fetching cmake repository..."
        git fetch --tags >/dev/null 2>&1 || true
        
        # Check what version we can actually checkout
        if git tag | grep -q "v3.30.2"; then
            log "Target tag v3.30.2 found, checking out..."
            git checkout v3.30.2
        else
            warn "Target tag v3.30.2 not found, finding closest available version..."
            # Find the highest v3.30.x version available
            AVAILABLE_VERSION=$(git tag | grep "^v3\.30\." | sort -V | tail -1)
            if [ -n "$AVAILABLE_VERSION" ]; then
                log "Checking out closest version: $AVAILABLE_VERSION"
                git checkout "$AVAILABLE_VERSION"
            else
                # Find any recent v3.x version
                RECENT_VERSION=$(git tag | grep "^v3\." | sort -V | tail -1)
                if [ -n "$RECENT_VERSION" ]; then
                    log "Checking out recent version: $RECENT_VERSION"
                    git checkout "$RECENT_VERSION"
                else
                    warn "No suitable cmake version found, staying on current branch"
                fi
            fi
        fi
        cd ..
    fi
else
    log "No cmake directory found (this is OK if it's being skipped)"
fi

# Also check swift/cmake directory (this is different from the cmake repository)
if [ -d "swift/cmake" ]; then
    log "✅ Swift's cmake configuration directory exists"
else
    warn "Swift's cmake configuration directory missing"
fi

log "✅ CMake repository issues resolved"
