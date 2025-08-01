#!/bin/bash
# swift-xtensa-build-script.sh – Swift compiler with Xtensa support using build-script
# ---------------------------------------------------------------------------
# This script uses Swift's official build-script instead of direct CMake
# invocation to properly configure embedded Swift with cross-compilation support
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
  rm -rf "$WORKSPACE_DIR/build"
fi

# ---------------------------------------------------------------------------
# Directories
# ---------------------------------------------------------------------------
SWIFT_DIR="$WORKSPACE_DIR/swift"
LLVM_DIR="$WORKSPACE_DIR/llvm-project"
CMARK_DIR="$WORKSPACE_DIR/cmark"
SWIFT_SYNTAX_DIR="$WORKSPACE_DIR/swift-syntax"

BUILD_DIR="$WORKSPACE_DIR/build"
INSTALL_DIR="$WORKSPACE_DIR/install"

echo "Setting up Swift with Xtensa support using build-script..."
echo "Workspace directory: $WORKSPACE_DIR"
echo "Install directory:  $INSTALL_DIR"
echo "Usage: $0 [--clean|--clean-swift]"
echo "  --clean       Remove all build artifacts"
echo "  --clean-swift Remove only Swift build artifacts"

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
# 1. Clone sources
# ---------------------------------------------------------------------------
clone_if_needed "$SWIFT_DIR"          "https://github.com/georgik/swift.git"           "feature/xtensa"
clone_if_needed "$LLVM_DIR"     "https://github.com/georgik/swiftlang-llvm-project.git" "feature/xtensa"
clone_if_needed "$CMARK_DIR"          "https://github.com/apple/cmark.git"           "release/6.2"
clone_if_needed "$SWIFT_SYNTAX_DIR"   "https://github.com/apple/swift-syntax.git"    "release/6.2"

# ---------------------------------------------------------------------------
# 2. Source ESP-IDF environment for cross-compilation if available
# ---------------------------------------------------------------------------
ESP_IDF_PATH="$HOME/projects/esp-idf"
if [[ -f "$ESP_IDF_PATH/export.sh" ]]; then
  log "Sourcing ESP-IDF environment for cross-compilation support..."
  export IDF_PATH="$ESP_IDF_PATH"
  source "$ESP_IDF_PATH/export.sh" > /dev/null 2>&1
  
  # Verify ESP-IDF toolchain is available
  if command -v xtensa-esp32s3-elf-gcc > /dev/null 2>&1; then
    log "ESP32-S3 Xtensa toolchain found: $(xtensa-esp32s3-elf-gcc --version | head -1)"
    export XTENSA_TOOLCHAIN_PREFIX="xtensa-esp32s3-elf-"
    export XTENSA_SYSROOT="$(dirname $(which xtensa-esp32s3-elf-gcc))/../xtensa-esp32s3-elf"
  else
    log "Warning: ESP32-S3 toolchain not found after sourcing ESP-IDF"
  fi
else
  log "ESP-IDF not found at $ESP_IDF_PATH/export.sh - proceeding without cross-compilation environment"
fi

# ---------------------------------------------------------------------------
# 3. Build Swift using build-script with embedded support
# ---------------------------------------------------------------------------
log "Building Swift with embedded stdlib support using build-script..."

cd "$SWIFT_DIR"

run "./utils/build-script \
  --build-subdir '$BUILD_DIR' \
  --install-prefix '$INSTALL_DIR' \
  --release \
  --assertions \
  --build-embedded-stdlib \
  --build-embedded-stdlib-cross-compiling \
  --llvm-targets-to-build 'AArch64;RISCV' \
  --host-cc '$(which clang)' \
  --host-cxx '$(which clang++)' \
  --cmake '$(which cmake)' \
  --build-ninja \
  --verbose-build \
  --reconfigure \
  --skip-build-benchmarks \
  --skip-early-swift-driver \
  --skip-ios \
  --skip-tvos \
  --skip-watchos \
  --skip-xros \
  --skip-test-swift \
  --skip-test-cmark \
  --install-swift \
  --install-llvm \
  --llvm-cmake-options='-DLLVM_ENABLE_PROJECTS=clang;lld -DLLVM_ENABLE_MODULES=ON -DLLVM_INCLUDE_TOOLS=ON -DLLVM_INSTALL_UTILS=ON -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=Xtensa' \
  --swift-cmake-options='-DSWIFT_ENABLE_EXPERIMENTAL_EMBEDDED=ON -DSWIFT_STDLIB_SINGLE_THREADED=ON -DSWIFT_SHOULD_BUILD_EMBEDDED_STDLIB=TRUE -DSWIFT_SHOULD_BUILD_EMBEDDED_STDLIB_CROSS_COMPILING=TRUE -DSWIFT_EMBEDDED_STDLIB_EXTRA_TARGET_TRIPLES=xtensa-esp32-none-elf;xtensa-esp32s2-none-elf;xtensa-esp32s3-none-elf;xtensa-esp32-espidf;xtensa-esp32s2-espidf;xtensa-esp32s3-espidf;riscv32-none-none-eabi -DSWIFT_EMBEDDED_TARGETS=xtensa-esp32-none-elf;xtensa-esp32s2-none-elf;xtensa-esp32s3-none-elf;xtensa-esp32-espidf;xtensa-esp32s2-espidf;xtensa-esp32s3-espidf;riscv32-none-none-eabi -DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING=OFF -DSWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=OFF -DSWIFT_ENABLE_EXPERIMENTAL_DISTRIBUTED=OFF -DSWIFT_ENABLE_EXPERIMENTAL_DIFFERENTIABLE_PROGRAMMING=OFF -DSWIFT_ENABLE_BACKTRACING=OFF -DSWIFT_ENABLE_REFLECTION=OFF -DSWIFT_BUILD_REMOTE_MIRROR=OFF -DSWIFT_ENABLE_RUNTIME_FUNCTION_COUNTERS=OFF -DSWIFT_ENABLE_LLDB=OFF -DSWIFT_ENABLE_LLD=OFF -DSWIFT_ENABLE_DISPATCH=OFF -DSWIFT_ENABLE_LIBXML2=OFF -DSWIFT_ENABLE_EXPERIMENTAL_CXX_INTEROP=OFF -DSWIFT_ENABLE_CAS=OFF'"

# ---------------------------------------------------------------------------
# 4. Test the Swift compiler
# ---------------------------------------------------------------------------
log "Testing Swift compiler..."
"$INSTALL_DIR/bin/swiftc" --version

# Verify embedded Swift support
log "Verifying embedded Swift support..."
if echo 'print("Hello, embedded Swift!")' | "$INSTALL_DIR/bin/swiftc" -enable-experimental-feature Embedded - 2>/dev/null; then
  log "✅ Embedded Swift support is working!"
else
  log "⚠️  Embedded Swift support test failed - checking details..."
  echo 'print("Hello, embedded Swift!")' | "$INSTALL_DIR/bin/swiftc" -enable-experimental-feature Embedded - 2>&1 || true
fi

# Check what libraries were installed
log "Installed Swift libraries:"
find "$INSTALL_DIR/lib/swift" -name "*.dylib" -o -name "*.a" -o -name "*Embedded*" 2>/dev/null | head -10 || log "No Swift libraries found"

log "✅ Swift with Xtensa support is ready!"
log "📍 Tools available at: $INSTALL_DIR/bin/"
log "🚀 Use: $INSTALL_DIR/bin/swiftc to compile Swift code"
log "📚 Standard library installed at: $INSTALL_DIR/lib/swift/"
