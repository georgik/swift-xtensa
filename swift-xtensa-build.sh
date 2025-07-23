#!/bin/bash
# swift-xtensa-build.sh – reproducible host-only Swift compiler with Xtensa back-end
# ---------------------------------------------------------------------------
# 1.  Apple LLVM (CAS patches)  → used by Swift *frontend*
# 2.  Espressif LLVM (Xtensa)    → kept for future cross-linking only
# ---------------------------------------------------------------------------
set -e

GREEN='\033[0;32m'; NC='\033[0m'
log()  { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }
run()  { log "Running: $*"; eval "$*"; }

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for clean build flag
if [[ "$1" == "--clean" ]]; then
  log "Clean build requested - removing existing build and install directories"
  rm -rf "$WORKSPACE_DIR/build" "$WORKSPACE_DIR/install"
fi

# ---------------------------------------------------------------------------
# Directories
# ---------------------------------------------------------------------------
SWIFT_DIR="$WORKSPACE_DIR/swift"
LLVM_APPLE_DIR="$WORKSPACE_DIR/llvm-apple"           # Apple LLVM (CAS + 6.2)
LLVM_XTENSA_DIR="$WORKSPACE_DIR/llvm-project-espressif"  # Espressif LLVM (Xtensa)
CMARK_DIR="$WORKSPACE_DIR/cmark"
SWIFT_SYNTAX_DIR="$WORKSPACE_DIR/swift-syntax"

BUILD_DIR="$WORKSPACE_DIR/build"
INSTALL_DIR="$WORKSPACE_DIR/install"

echo "Setting up Swift with Xtensa support..."
echo "Workspace directory: $WORKSPACE_DIR"
echo "Install directory:  $INSTALL_DIR"
echo "Usage: $0 [--clean] # Use --clean to remove previous build artifacts"

# ---------------------------------------------------------------------------
# Helper: clone once
# ---------------------------------------------------------------------------
clone_if_needed() {
  local dir=$1 repo=$2 branch=$3
  [[ -d "$dir" ]] && { log "Directory '$dir' exists – skipping clone."; return 0; }
  log "Cloning $repo ($branch) into $dir"
  run "git clone --depth=1 --branch $branch $repo $dir"
}

# ---------------------------------------------------------------------------
# 1.  Clone sources
# ---------------------------------------------------------------------------
#clone_if_needed "$SWIFT_DIR"          "https://github.com/apple/swift.git"           "release/6.2"
clone_if_needed "$SWIFT_DIR"          "https://github.com/georgik/swift.git"           "feature/xtensa"
clone_if_needed "$LLVM_APPLE_DIR"     "https://github.com/georgik/swiftlang-llvm-project.git" "feature/xtensa"
#clone_if_needed "$LLVM_APPLE_DIR"     "https://github.com/swiftlang/llvm-project.git" "swift/release/6.2"
clone_if_needed "$CMARK_DIR"          "https://github.com/apple/cmark.git"           "release/6.2"
clone_if_needed "$SWIFT_SYNTAX_DIR"   "https://github.com/apple/swift-syntax.git"    "release/6.2"
# clone_if_needed "$LLVM_XTENSA_DIR" "https://github.com/espressif/llvm-project.git" "esp_main"  # not needed for frontend

# ---------------------------------------------------------------------------
# 2.  Build cmark host tool
# ---------------------------------------------------------------------------
log "Building cmark..."
mkdir -p "$BUILD_DIR/cmark-macosx-arm64"
cd "$BUILD_DIR/cmark-macosx-arm64"
run "cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR' \
  -DCMARK_BUILD_TESTS=OFF \
  -DCMARK_BUILD_SHARED_LIBS=OFF \
  -DCMARK_BUILD_STATIC_LIBS=ON \
  -DCMARK_INSTALL_MODULEMAP=OFF \
  '$CMARK_DIR'"
run "ninja -j$(sysctl -n hw.ncpu)"
run "ninja install"

# Remove conflicting module map from installed cmark to avoid redefinition
if [[ -f "$INSTALL_DIR/include/cmark_gfm/module.modulemap" ]]; then
  log "Removing conflicting cmark module map from install directory"
  rm "$INSTALL_DIR/include/cmark_gfm/module.modulemap"
fi

# ---------------------------------------------------------------------------
# 3.  Build Apple LLVM (with Xtensa support patches from Rust)
# ---------------------------------------------------------------------------
log "Building Apple LLVM + Clang with Xtensa experimental target..."
mkdir -p "$BUILD_DIR/llvm-apple-macosx-arm64"
cd "$BUILD_DIR/llvm-apple-macosx-arm64"
run "cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR' \
  -DLLVM_TARGETS_TO_BUILD='AArch64' \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD='Xtensa' \
  -DLLVM_ENABLE_PROJECTS='clang;lld' \
  -DLLVM_ENABLE_MODULES=ON \
  -DLLVM_INCLUDE_TOOLS=ON \
  -DLLVM_INSTALL_UTILS=ON \
  '$LLVM_APPLE_DIR/llvm'"
run "ninja -j$(sysctl -n hw.ncpu)"
run "ninja install"
run "ninja install-clang-resource-headers"

# Copy LLVM config header that Swift needs
mkdir -p "$INSTALL_DIR/include/llvm/Config"
cp "$BUILD_DIR/llvm-apple-macosx-arm64/include/llvm/Config/config.h" "$INSTALL_DIR/include/llvm/Config/config.h"

# ---------------------------------------------------------------------------
# 4.  Build Swift host tools
# ---------------------------------------------------------------------------
log "Building Swift host tools (swift-frontend + swiftc)..."
mkdir -p "$BUILD_DIR/swift-macosx-arm64"
cd "$BUILD_DIR/swift-macosx-arm64"
run "cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR' \
  -DLLVM_DIR='$INSTALL_DIR/lib/cmake/llvm' \
  -DClang_DIR='$INSTALL_DIR/lib/cmake/clang' \
  -DLLVM_BUILD_LIBRARY_DIR='lib' \
  -DLLVM_LIBRARY_DIR='$INSTALL_DIR/lib' \
  -DLLVM_MAIN_SRC_DIR='$LLVM_APPLE_DIR/llvm' \
  -DSWIFT_PATH_TO_CMARK_SOURCE='$CMARK_DIR' \
  -DSWIFT_PATH_TO_CMARK_BUILD='$BUILD_DIR/cmark-macosx-arm64' \
  -DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE='$SWIFT_SYNTAX_DIR' \
  -DSWIFT_BUILD_SWIFT_SYNTAX=OFF \
  -DSWIFT_INCLUDE_TOOLS=ON \
  -DSWIFT_BUILD_STDLIB=OFF \
  -DSWIFT_BUILD_SDK_OVERLAY=OFF \
  -DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
  -DSWIFT_ENABLE_EXPERIMENTAL_EMBEDDED=ON \
  -DSWIFT_STDLIB_SINGLE_THREADED=ON \
  -DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_DISTRIBUTED=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_DIFFERENTIABLE_PROGRAMMING=OFF \
  -DSWIFT_ENABLE_BACKTRACING=OFF \
  -DSWIFT_ENABLE_REFLECTION=OFF \
  -DSWIFT_ENABLE_RUNTIME_FUNCTION_COUNTERS=OFF \
  -DSWIFT_ENABLE_LLDB=OFF \
  -DSWIFT_ENABLE_LLD=OFF \
  -DSWIFT_ENABLE_DISPATCH=OFF \
  -DSWIFT_ENABLE_LIBXML2=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_CXX_INTEROP=OFF \
  -DSWIFT_ENABLE_CAS=OFF \
  -DSWIFT_HOST_VARIANT=macosx \
  -DSWIFT_HOST_VARIANT_ARCH=arm64 \
  -DSWIFT_DARWIN_SUPPORTED_ARCHS=arm64 \
  '$SWIFT_DIR'"

run "ninja -j$(sysctl -n hw.ncpu) swift-frontend"

# Install Swift tools manually since install targets may not be available
log "Installing Swift tools..."
cp "bin/swift-frontend" "$INSTALL_DIR/bin/"
cp "bin/swiftc" "$INSTALL_DIR/bin/"

# ---------------------------------------------------------------------------
# 5.  Build Espressif LLVM (Xtensa) – optional, kept for future cross-linking
#    Uncomment the block below when you need the Xtensa backend binaries
# ---------------------------------------------------------------------------
# log "Building Espressif LLVM (Xtensa backend)..."
# mkdir -p "$BUILD_DIR/llvm-xtensa-macosx-arm64"
# cd "$BUILD_DIR/llvm-xtensa-macosx-arm64"
# run "cmake -G Ninja \
#   -DCMAKE_BUILD_TYPE=Release \
#   -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR/llvm-xtensa' \
#   -DLLVM_TARGETS_TO_BUILD='' \
#   -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD='Xtensa' \
#   -DLLVM_ENABLE_PROJECTS='clang;lld' \
#   '$LLVM_XTENSA_DIR/llvm'"
# run "ninja -j$(sysctl -n hw.ncpu)"
# run "ninja install"

# Test the Swift compiler
log "Testing Swift compiler..."
"$INSTALL_DIR/bin/swiftc" --version

log "✅ Swift with Xtensa support is ready!"
log "📍 Tools available at: $INSTALL_DIR/bin/"
log "🚀 Use: $INSTALL_DIR/bin/swiftc to compile Swift code"
