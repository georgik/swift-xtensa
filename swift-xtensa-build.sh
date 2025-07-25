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

# Check for clean build flags
if [[ "$1" == "--clean" ]]; then
  log "Clean build requested - removing existing build and install directories"
  rm -rf "$WORKSPACE_DIR/build" "$WORKSPACE_DIR/install"
elif [[ "$1" == "--clean-swift" ]]; then
  log "Clean Swift build requested - removing Swift build directory only"
  rm -rf "$WORKSPACE_DIR/build/swift-macosx-arm64"
  # Remove Swift binaries from install directory but keep LLVM
  if [[ -d "$WORKSPACE_DIR/install/bin" ]]; then
    rm -f "$WORKSPACE_DIR/install/bin/swift-frontend"
    rm -f "$WORKSPACE_DIR/install/bin/swiftc"
  fi
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
echo "Usage: $0 [--clean|--clean-swift]"
echo "  --clean       Remove all build artifacts (LLVM + Swift)"
echo "  --clean-swift Remove only Swift build artifacts (keeps LLVM)"

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
#clone_if_needed "$LLVM_APPLE_DIR"     "git@github.com:georgik/swiftlang-llvm-project.git" "feature/xtensa"
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
  -DLLVM_TARGETS_TO_BUILD='AArch64;RISCV' \
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
# 4.  Build Swift host tools with embedded support
# ---------------------------------------------------------------------------
log "Building Swift host tools with embedded stdlib support..."

# Source ESP-IDF environment for cross-compilation if available
ESP_IDF_PATH="$HOME/projects/esp-idf"
if [[ -f "$ESP_IDF_PATH/export.sh" ]]; then
  log "Sourcing ESP-IDF environment for ESP32-S3 cross-compilation support..."
  export IDF_PATH="$ESP_IDF_PATH"
  source "$ESP_IDF_PATH/export.sh" > /dev/null 2>&1
  
  # Verify ESP-IDF toolchain is available
  if command -v xtensa-esp32s3-elf-gcc >/dev/null 2>&1; then
    log "ESP32-S3 Xtensa toolchain found: $(xtensa-esp32s3-elf-gcc --version | head -1)"
    export XTENSA_TOOLCHAIN_PREFIX="xtensa-esp32s3-elf-"
    export XTENSA_SYSROOT="$(dirname $(which xtensa-esp32s3-elf-gcc))/../xtensa-esp32s3-elf"
  else
    log "Warning: ESP32-S3 toolchain not found after sourcing ESP-IDF"
  fi
else
  log "ESP-IDF not found at $ESP_IDF_PATH/export.sh - proceeding without cross-compilation environment"
fi

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
  -DLLVM_MAIN_INCLUDE_DIR='$INSTALL_DIR/include' \
  -DSWIFT_PATH_TO_CMARK_SOURCE='$CMARK_DIR' \
  -DSWIFT_PATH_TO_CMARK_BUILD='$BUILD_DIR/cmark-macosx-arm64' \
  -DSWIFT_PATH_TO_SWIFT_SYNTAX_SOURCE='$SWIFT_SYNTAX_DIR' \
  -DSWIFT_BUILD_SWIFT_SYNTAX=OFF \
  -DSWIFT_INCLUDE_TOOLS=ON \
  -DSWIFT_ENABLE_SWIFT_IN_SWIFT=OFF \
  -DSWIFT_SHOULD_BUILD_EMBEDDED_STDLIB=TRUE \
  -DSWIFT_SHOULD_BUILD_EMBEDDED_STDLIB_CROSS_COMPILING=TRUE \
  -DSWIFT_EMBEDDED_STDLIB_EXTRA_TARGET_TRIPLES='xtensa-esp32-none-elf;xtensa-esp32s2-none-elf;xtensa-esp32s3-none-elf;xtensa-esp32-espidf;xtensa-esp32s2-espidf;xtensa-esp32s3-espidf;riscv32-none-none-eabi' \
  -DSWIFT_BUILD_STDLIB=ON \
  -DSWIFT_BUILD_SDK_OVERLAY=OFF \
  -DSWIFT_BUILD_CLANG_OVERLAYS_SKIP_BUILTIN_FLOAT=ON \
  -DSWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER=ON \
  -DSWIFT_ENABLE_EXPERIMENTAL_EMBEDDED=ON \
  -DSWIFT_STDLIB_SINGLE_THREADED=ON \
  -DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_DISTRIBUTED=OFF \
  -DSWIFT_ENABLE_EXPERIMENTAL_DIFFERENTIABLE_PROGRAMMING=OFF \
  -DSWIFT_ENABLE_BACKTRACING=OFF \
  -DSWIFT_ENABLE_REFLECTION=OFF \
  -DSWIFT_BUILD_REMOTE_MIRROR=OFF \
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
  -DSWIFT_EMBEDDED_TARGETS='xtensa-esp32-none-elf;xtensa-esp32s2-none-elf;xtensa-esp32s3-none-elf;xtensa-esp32-espidf;xtensa-esp32s2-espidf;xtensa-esp32s3-espidf;riscv32-none-none-eabi' \
  '$SWIFT_DIR'"

# Build the Swift frontend and embedded stdlib
log "Building Swift frontend and embedded stdlib for Xtensa development..."
run "ninja -j$(sysctl -n hw.ncpu) swift-frontend"

# Build embedded stdlib and all libraries
log "Building embedded stdlib and all Swift libraries..."
run "ninja -j$(sysctl -n hw.ncpu) swift-stdlib-macosx-arm64"

# Build embedded-libraries target if it exists
log "Checking for embedded stdlib targets..."
if ninja -t targets | grep -q "embedded-libraries"; then
  log "Building embedded-libraries target..."
  run "ninja -j$(sysctl -n hw.ncpu) embedded-libraries"
else
  log "embedded-libraries target not found - checking for individual embedded stdlib targets"
  # Try to build individual embedded stdlib targets
  for target in xtensa-esp32-none-elf xtensa-esp32s2-none-elf xtensa-esp32s3-none-elf xtensa-esp32-espidf xtensa-esp32s2-espidf xtensa-esp32s3-espidf riscv32-none-none-eabi; do
    if ninja -t targets | grep -q "swift-stdlib.*$target"; then
      log "Building embedded stdlib for $target..."
      run "ninja -j$(sysctl -n hw.ncpu) swift-stdlib-$target" || true
    fi
  done
fi

# Install the Swift standard library and embedded libraries
log "Installing Swift standard library..."
run "ninja install-stdlib"
run "ninja install-stdlib-experimental"

# Manually install just the binaries we need
log "Installing Swift compiler tools manually..."
mkdir -p "$INSTALL_DIR/bin"
if [[ -f "bin/swift-frontend" ]]; then
  cp "bin/swift-frontend" "$INSTALL_DIR/bin/"
  log "Installed swift-frontend"
else
  log "ERROR: swift-frontend binary not found!"
  exit 1
fi

# Create swiftc wrapper script
log "Creating swiftc wrapper script..."
cat > "$INSTALL_DIR/bin/swiftc" << 'EOF'
#!/bin/bash
exec "$(dirname $0)/swift-frontend" "$@"
EOF
chmod +x "$INSTALL_DIR/bin/swiftc"

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

# Verify embedded Swift support
log "Verifying embedded Swift support..."
if echo 'print("Hello, embedded Swift!")' | "$INSTALL_DIR/bin/swiftc" -enable-experimental-feature Embedded - 2>/dev/null; then
  log "✅ Embedded Swift support is working!"
else
  log "⚠️  Embedded Swift support test failed - may need additional configuration"
  log "Error details:"
  echo 'print("Hello, embedded Swift!")' | "$INSTALL_DIR/bin/swiftc" -enable-experimental-feature Embedded - 2>&1 || true
fi

# Check what libraries were installed
log "Installed Swift libraries:"
find "$INSTALL_DIR/lib/swift" -name "*.dylib" -o -name "*.a" -o -name "*Embedded*" 2>/dev/null | head -10 || log "No Swift libraries found"

log "✅ Swift with Xtensa support is ready!"
log "📍 Tools available at: $INSTALL_DIR/bin/"
log "🚀 Use: $INSTALL_DIR/bin/swiftc to compile Swift code"
log "📚 Standard library installed at: $INSTALL_DIR/lib/swift/"
