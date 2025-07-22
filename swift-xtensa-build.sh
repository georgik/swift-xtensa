#!/bin/bash
# swift-xtensa-build.sh – reproducible host-only Swift compiler with Xtensa back-end
set -e

GREEN='\033[0;32m'; NC='\033[0m'
log()  { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }
run()  { log "Running: $*"; eval "$*"; }

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_DIR="$WORKSPACE_DIR/swift"
LLVM_DIR="$WORKSPACE_DIR/llvm-project-espressif"
BUILD_DIR="$WORKSPACE_DIR/build"
INSTALL_DIR="$WORKSPACE_DIR/install"

echo "Setting up Swift with Xtensa support..."
echo "Workspace directory: $WORKSPACE_DIR"
echo "Swift source directory: $SWIFT_DIR"
echo "LLVM source directory: $LLVM_DIR"
echo "Build directory: $BUILD_DIR"
echo "Install directory: $INSTALL_DIR"

# ---------------------------------------------------------------------------
# 1.  Clone once (commented out after first run)
# ---------------------------------------------------------------------------

clone_if_needed() {
  local dir=$1
  local repo=$2
  local branch=$3
  if [[ -d "$dir" ]]; then
    log "Directory '$dir' already exists – skipping clone."
  else
    log "Cloning $repo (branch $branch) into $dir..."
    run "git clone --depth=1 --branch $branch $repo $dir"
  fi
}

clone_if_needed "$WORKSPACE_DIR/swift"          "https://github.com/apple/swift.git"           "release/6.2"
clone_if_needed "$WORKSPACE_DIR/cmark"          "https://github.com/apple/cmark.git"           "release/6.2"
clone_if_needed "$WORKSPACE_DIR/swift-syntax"   "https://github.com/apple/swift-syntax.git"    "release/6.2"
clone_if_needed "$LLVM_DIR" "https://github.com/espressif/llvm-project.git" "esp_main"

# ---------------------------------------------------------------------------
# 2.  Build & install cmark (host tool, tiny)
# ---------------------------------------------------------------------------
log "Building cmark..."
mkdir -p "$BUILD_DIR/cmark-macosx-arm64"
cd "$BUILD_DIR/cmark-macosx-arm64"
run "cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR' '$WORKSPACE_DIR/cmark'"
run "ninja -j$(sysctl -n hw.ncpu)"
run "ninja install"

# ---------------------------------------------------------------------------
# 3.  Build & install LLVM/Clang with Xtensa back-end
#     (adds the cache vars Swift expects)
# ---------------------------------------------------------------------------
log "Building LLVM + Clang with Xtensa support..."
mkdir -p "$BUILD_DIR/llvm-macosx-arm64"
cd "$BUILD_DIR/llvm-macosx-arm64"
run "cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR' \
  -DSWIFT_NATIVE_SWIFT_TOOLS_PATH=/Users/georgik/.swiftly/bin \
  -DLLVM_TARGETS_TO_BUILD='' \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD='Xtensa' \
  -DLLVM_ENABLE_PROJECTS='clang;lld' \
  -DLLVM_BUILD_LIBRARY_DIR='lib' \
  -DLLVM_LIBRARY_DIR='$INSTALL_DIR/lib' \
  '$LLVM_DIR/llvm'"
run "ninja -j$(sysctl -n hw.ncpu)"
run "ninja install"
run "ninja install-clang-resource-headers"

# ---------------------------------------------------------------------------
# 4.  Build & install Swift **host tools** only
# ---------------------------------------------------------------------------
log "Building Swift host tools (swift-frontend + swiftc)..."
mkdir -p "$BUILD_DIR/swift-macosx-arm64"
cd "$BUILD_DIR/swift-macosx-arm64"
log "Configuring Swift host tools (no-CAS, no-runtime)..."
run "cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX='$INSTALL_DIR' \
  -DLLVM_DIR='$INSTALL_DIR/lib/cmake/llvm' \
  -DClang_DIR='$INSTALL_DIR/lib/cmake/clang' \
  -DLLVM_BUILD_LIBRARY_DIR='lib' \
  -DLLVM_LIBRARY_DIR='$INSTALL_DIR/lib' \
  -DLLVM_MAIN_SRC_DIR='$LLVM_DIR/llvm' \
  -DSWIFT_PATH_TO_CMARK_SOURCE='$WORKSPACE_DIR/cmark' \
  -DSWIFT_PATH_TO_CMARK_BUILD='$BUILD_DIR/cmark-macosx-arm64' \
  -DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE='$WORKSPACE_DIR/swift-syntax' \
  -DSWIFT_BUILD_SWIFT_SYNTAX=ON \
  -DSWIFT_INCLUDE_TOOLS=ON \
  -DSWIFT_BUILD_STDLIB=OFF \
  -DSWIFT_BUILD_SDK_OVERLAY=OFF \
  -DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
  -DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_DISTRIBUTED=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_DIFFERENTIABLE_PROGRAMMING=OFF \
  -DSWIFT_ENABLE_BACKTRACING=OFF \
  -DSWIFT_ENABLE_CRASHREPORTERCLIENT=OFF \
  -DSWIFT_ENABLE_REFLECTION=OFF \
  -DSWIFT_ENABLE_RUNTIME_FUNCTION_COUNTERS=OFF \
  -DSWIFT_ENABLE_LLDB=OFF \
  -DSWIFT_ENABLE_LLD=OFF \
  -DSWIFT_ENABLE_DISPATCH=OFF \
  -DSWIFT_ENABLE_LIBXML2=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_CXX_INTEROP=OFF \
  -DCMAKE_Swift_COMPILER=/Users/georgik/.swiftly/bin/swiftc \
  -DCMAKE_Swift_FLAGS='-sdk $(xcrun --sdk macosx --show-sdk-path)' \
  -DSWIFT_HOST_VARIANT=macosx \
  -DSWIFT_HOST_VARIANT_ARCH=arm64 \
  -DSWIFT_DARWIN_SUPPORTED_ARCHS=arm64 \
  '$SWIFT_DIR'"

run "ninja -j$(sysctl -n hw.ncpu) swift-frontend"
run "ninja install-swift-frontend install-swiftc"

log "✅ Swift with Xtensa support is ready!"
log "📍 Tools available at: $INSTALL_DIR/bin/"