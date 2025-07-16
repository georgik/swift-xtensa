#!/bin/bash

# Build Swift with Xtensa support for ESP32 targets
# Optimized for M1 Mac, focusing only on Xtensa target
# Based on the approach discussed in chat.txt and Carl P's methodology

set -e

# Configuration
SWIFT_DIR="../swift"
LLVM_ESP_DIR="../llvm-project-espressif"
RUST_DIR="../rust"
BUILD_DIR="build"
INSTALL_DIR="install"
XTENSA_TARGET="xtensa-esp32s3-none-elf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if [ ! -d "$SWIFT_DIR" ]; then
        error "Swift directory not found: $SWIFT_DIR"
    fi
    
    if [ ! -d "$LLVM_ESP_DIR" ]; then
        error "ESP LLVM directory not found: $LLVM_ESP_DIR"
    fi
    
    # Check for required tools
    for tool in cmake ninja python3; do
        if ! command -v $tool &> /dev/null; then
            error "$tool is required but not installed"
        fi
    done
    
    # Check architecture
    if [[ $(uname -m) != "arm64" ]]; then
        warn "This script is optimized for M1 Mac (arm64). Current architecture: $(uname -m)"
    fi
    
    log "Prerequisites check passed"
}

# Build ESP LLVM with Xtensa support only
build_esp_llvm() {
    log "Building ESP LLVM with Xtensa support (minimal build)..."
    
    local llvm_build_dir="$BUILD_DIR/llvm-esp"
    mkdir -p "$llvm_build_dir"
    
    cd "$llvm_build_dir"
    
    # Configure LLVM build with Xtensa and ARM targets for Swift compatibility
    cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS="clang;lld" \
        -DLLVM_TARGETS_TO_BUILD="Xtensa;AArch64;ARM" \
        -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" \
        -DCMAKE_INSTALL_PREFIX="$(pwd)/../../$INSTALL_DIR/llvm-esp" \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_OPTIMIZED_TABLEGEN=ON \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_ENABLE_EXPENSIVE_CHECKS=OFF \
        -DLLVM_APPEND_VC_REV=OFF \
        -DLLVM_CCACHE_BUILD=ON \
        "../../$LLVM_ESP_DIR/llvm"
    
    # Build LLVM with parallel jobs optimized for M1
    ninja -j$(sysctl -n hw.logicalcpu)
    ninja install
    
    cd - > /dev/null
    log "ESP LLVM build completed"
}

# Build Swift compiler (host tools) - minimal for embedded use
build_swift_host() {
    log "Building Swift host compiler (minimal for embedded)..."
    
    local swift_build_dir="$BUILD_DIR/swift-host"
    mkdir -p "$swift_build_dir"
    
    cd "$SWIFT_DIR"
    
    # Build Swift with embedded support, minimal configuration
    ./utils/build-script \
        --release \
        --build-dir="../swift-xtensa/$swift_build_dir" \
        --install-prefix="../swift-xtensa/$INSTALL_DIR/swift-host" \
        --build-embedded-stdlib=true \
        --skip-build-benchmarks \
        --skip-ios \
        --skip-watchos \
        --skip-tvos \
        --skip-xros \
        --skip-test-swift \
        --skip-test-cmark \
        --skip-test-lldb \
        --skip-test-foundation \
        --skip-test-xctest \
        --skip-test-playgroundsupport \
        --llvm-targets-to-build="AArch64" \
        --extra-swift-args="-DSWIFT_ENABLE_EXPERIMENTAL_FEATURE_EMBEDDED=ON" \
        -j$(sysctl -n hw.logicalcpu)
    
    cd - > /dev/null
    log "Swift host compiler build completed"
}

# Create wrapper scripts for cross-compilation
create_wrapper_scripts() {
    log "Creating wrapper scripts..."
    
    local wrapper_dir="$INSTALL_DIR/bin"
    mkdir -p "$wrapper_dir"
    
    # Create swiftc wrapper that emits LLVM IR
    cat > "$wrapper_dir/swiftc-xtensa" << 'EOF'
#!/bin/bash

# Swift to LLVM IR compiler for Xtensa
SWIFT_HOST_DIR="$(dirname "$0")/../swift-host"
LLVM_ESP_DIR="$(dirname "$0")/../llvm-esp"

# Use host Swift to compile to LLVM IR
"$SWIFT_HOST_DIR/bin/swiftc" \
    -target armv7-unknown-none-eabi \
    -enable-experimental-feature Embedded \
    -wmo \
    -parse-as-library \
    -emit-ir \
    -o "${@: -1}.ll" \
    "$@"

# Use ESP LLVM to compile IR to Xtensa object file
if [ $? -eq 0 ]; then
    "$LLVM_ESP_DIR/bin/llc" \
        -march=xtensa \
        -mcpu=esp32s3 \
        -filetype=obj \
        -o "${@: -1}.o" \
        "${@: -1}.ll"
fi
EOF

    chmod +x "$wrapper_dir/swiftc-xtensa"
    
    # Create utility script to compile Swift to LLVM IR only
    cat > "$wrapper_dir/swift-to-ir" << 'EOF'
#!/bin/bash

# Swift to LLVM IR only
SWIFT_HOST_DIR="$(dirname "$0")/../swift-host"

"$SWIFT_HOST_DIR/bin/swiftc" \
    -target armv7-unknown-none-eabi \
    -enable-experimental-feature Embedded \
    -wmo \
    -parse-as-library \
    -emit-ir \
    "$@"
EOF

    chmod +x "$wrapper_dir/swift-to-ir"
    
    # Create utility script to compile LLVM IR to Xtensa object
    cat > "$wrapper_dir/ir-to-xtensa" << 'EOF'
#!/bin/bash

# LLVM IR to Xtensa object compiler
LLVM_ESP_DIR="$(dirname "$0")/../llvm-esp"

"$LLVM_ESP_DIR/bin/llc" \
    -march=xtensa \
    -mcpu=esp32s3 \
    -filetype=obj \
    "$@"
EOF

    chmod +x "$wrapper_dir/ir-to-xtensa"
    
    # Create ESP32-S3 specific variant
    cat > "$wrapper_dir/swiftc-esp32s3" << 'EOF'
#!/bin/bash

# Swift compiler specifically for ESP32-S3
SWIFT_HOST_DIR="$(dirname "$0")/../swift-host"
LLVM_ESP_DIR="$(dirname "$0")/../llvm-esp"

# Use host Swift to compile to LLVM IR with ESP32-S3 optimizations
"$SWIFT_HOST_DIR/bin/swiftc" \
    -target armv7-unknown-none-eabi \
    -enable-experimental-feature Embedded \
    -wmo \
    -parse-as-library \
    -emit-ir \
    -O \
    -o "${@: -1}.ll" \
    "$@"

# Use ESP LLVM to compile IR to Xtensa object file with ESP32-S3 specific settings
if [ $? -eq 0 ]; then
    "$LLVM_ESP_DIR/bin/llc" \
        -march=xtensa \
        -mcpu=esp32s3 \
        -filetype=obj \
        -O2 \
        -o "${@: -1}.o" \
        "${@: -1}.ll"
fi
EOF

    chmod +x "$wrapper_dir/swiftc-esp32s3"
    
    log "Wrapper scripts created"
}

# Create example project structure
create_example_project() {
    log "Creating example project..."
    
    local example_dir="examples/esp32s3-blink"
    mkdir -p "$example_dir"
    
    # Create a simple blink example
    cat > "$example_dir/main.swift" << 'EOF'
@_silgen_name("app_main")
public func app_main() {
    // Simple blink example for ESP32-S3
    // This would need to be integrated with ESP-IDF
    
    // GPIO configuration would be done through C interop
    // For now, this demonstrates the basic structure
    
    var counter: UInt32 = 0
    
    while true {
        // Toggle LED logic
        counter = counter &+ 1
        
        // Simulate delay (actual implementation would use ESP-IDF delay)
        for _ in 0..<1000000 {
            // Busy wait
        }
        
        // In real implementation, this would toggle GPIO
        if counter % 2 == 0 {
            // LED ON
        } else {
            // LED OFF
        }
    }
}
EOF

    # Create build script for the example
    cat > "$example_dir/build.sh" << 'EOF'
#!/bin/bash
set -e

echo "Building Swift code for ESP32-S3..."

# Build Swift source to LLVM IR
../../install/bin/swift-to-ir -o main.ll main.swift

# Convert LLVM IR to Xtensa object file
../../install/bin/ir-to-xtensa -o main.o main.ll

echo "Build completed successfully!"
echo "Generated files:"
echo "  - main.ll (LLVM IR)"
echo "  - main.o (Xtensa object file)"
echo ""
echo "Next steps:"
echo "  1. Integrate with ESP-IDF project"
echo "  2. Link with ESP-IDF components using xtensa-esp32s3-elf-gcc"
echo "  3. Flash to ESP32-S3 device"
EOF

    chmod +x "$example_dir/build.sh"
    
    # Create README for the example
    cat > "$example_dir/README.md" << 'EOF'
# ESP32-S3 Blink Example

This example demonstrates how to compile Swift code for ESP32-S3 using the Xtensa toolchain.

## Building

```bash
./build.sh
```

## Integration with ESP-IDF

To integrate this with an ESP-IDF project:

1. Copy the generated `main.o` file to your ESP-IDF project
2. Add the object file to your CMakeLists.txt
3. Ensure proper C interop for GPIO functions
4. Build with `idf.py build`

## Files

- `main.swift` - Swift source code
- `build.sh` - Build script
- `main.ll` - Generated LLVM IR (after build)
- `main.o` - Generated Xtensa object file (after build)
EOF

    log "Example project created in $example_dir"
}

# Create minimal CI configuration
create_ci_config() {
    log "Creating CI configuration..."
    
    mkdir -p ".github/workflows"
    
    cat > ".github/workflows/build-swift-xtensa.yml" << 'EOF'
name: Build Swift for Xtensa (M1 Mac)

on:
  workflow_dispatch:
    inputs:
      swift_version:
        description: "Swift version to build"
        required: true
        default: 'main'

jobs:
  build-swift-xtensa:
    name: Build Swift with Xtensa Support
    runs-on: macos-14  # M1 Mac runner
    
    steps:
      - name: Checkout Swift Xtensa Build
        uses: actions/checkout@v4
      
      - name: Setup Dependencies
        run: |
          brew install cmake ninja python3
      
      - name: Checkout Swift
        run: |
          git clone --depth 1 --branch ${{ github.event.inputs.swift_version }} https://github.com/apple/swift.git ../swift
          cd ../swift
          ./utils/update-checkout --clone
      
      - name: Checkout ESP LLVM
        run: |
          git clone --depth 1 https://github.com/espressif/llvm-project.git ../llvm-project-espressif
      
      - name: Build Swift Xtensa
        run: |
          ./build-swift-xtensa.sh
      
      - name: Test Build
        run: |
          cd examples/esp32s3-blink
          ./build.sh
      
      - name: Package Artifacts
        run: |
          cd install
          tar -czf ../swift-xtensa-aarch64-apple-darwin.tar.gz .
          cd ..
      
      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: swift-xtensa-aarch64-apple-darwin
          path: swift-xtensa-aarch64-apple-darwin.tar.gz
EOF

    log "CI configuration created"
}

# Create README
create_readme() {
    log "Creating README..."
    
    cat > "README.md" << 'EOF'
# Swift for Xtensa (ESP32)

This repository provides tooling to build Swift with Xtensa support for ESP32 microcontrollers, specifically focusing on ESP32-S3.

## Overview

Based on the two-stage compilation approach discussed in the Swift embedded community:

1. **Stage 1**: Use host Swift compiler to emit LLVM IR
2. **Stage 2**: Use ESP's LLVM fork with Xtensa backend to compile IR to machine code

## Prerequisites

- macOS (M1 Mac recommended)
- Xcode Command Line Tools
- CMake
- Ninja
- Python 3

```bash
brew install cmake ninja python3
```

## Quick Start

1. **Clone repositories**:
   ```bash
   # Clone Swift
   git clone https://github.com/apple/swift.git ../swift
   cd ../swift && ./utils/update-checkout --clone
   
   # Clone ESP LLVM
   git clone https://github.com/espressif/llvm-project.git ../llvm-project-espressif
   ```

2. **Build Swift with Xtensa support**:
   ```bash
   ./build-swift-xtensa.sh
   ```

3. **Test with example**:
   ```bash
   cd examples/esp32s3-blink
   ./build.sh
   ```

## Usage

### Compile Swift to Xtensa Object File
```bash
./install/bin/swiftc-xtensa -o output main.swift
```

### Two-Stage Compilation (Manual)
```bash
# Stage 1: Swift to LLVM IR
./install/bin/swift-to-ir -o main.ll main.swift

# Stage 2: LLVM IR to Xtensa object
./install/bin/ir-to-xtensa -o main.o main.ll
```

## Architecture

```
Swift Source (.swift)
        ↓
    Host Swift Compiler
        ↓
    LLVM IR (.ll)
        ↓
    ESP LLVM (LLC with Xtensa backend)
        ↓
    Xtensa Object File (.o)
        ↓
    ESP-IDF Linker
        ↓
    ESP32 Firmware
```

## Integration with ESP-IDF

To use the generated object files in an ESP-IDF project:

1. Add the object file to your CMakeLists.txt
2. Ensure proper C interop for hardware functions
3. Build with `idf.py build`

## Supported Targets

- ESP32-S3 (primary focus)
- Future: ESP32-C6/C5 (RISC-V)

## References

- [Swift Embedded Documentation](https://github.com/apple/swift/blob/main/docs/EmbeddedSwift.md)
- [ESP-RS Rust Build Process](https://github.com/esp-rs/rust-build)
- [Espressif LLVM Fork](https://github.com/espressif/llvm-project)

## Contributing

This project follows the approach suggested by the Swift embedded community and builds upon the work done by the ESP-RS team for Rust.
EOF

    log "README created"
}

# Main build function
main() {
    log "Starting Swift Xtensa build process (optimized for M1 Mac)..."
    
    # Create build directories
    mkdir -p "$BUILD_DIR" "$INSTALL_DIR"
    
    # Run build steps
    check_prerequisites
    build_esp_llvm
    build_swift_host
    create_wrapper_scripts
    create_example_project
    create_ci_config
    create_readme
    
    log "Build process completed successfully!"
    log ""
    log "🚀 Swift Xtensa Toolchain Ready!"
    log ""
    log "Available tools:"
    log "  - install/bin/swiftc-xtensa     → Compile Swift directly to Xtensa"
    log "  - install/bin/swiftc-esp32s3    → ESP32-S3 optimized compiler"
    log "  - install/bin/swift-to-ir       → Compile Swift to LLVM IR"
    log "  - install/bin/ir-to-xtensa      → Compile LLVM IR to Xtensa"
    log ""
    log "Example project: examples/esp32s3-blink/"
    log ""
    log "Next steps:"
    log "  1. Test the example: cd examples/esp32s3-blink && ./build.sh"
    log "  2. Integrate with ESP-IDF projects"
    log "  3. Consider adding RISC-V support for ESP32-C6/C5"
}

# Run main function
main "$@"
