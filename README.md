# Swift on ESP32-S3 - Xtensa Cross-Compilation Validation

This project demonstrates building and running Swift on the ESP32-S3 using the Xtensa toolchain. It provides a comprehensive build script to compile a Swift compiler with Xtensa support for ESP32-S3 development with ESP-IDF.

This project includes **Embedded Swift Standard Library** support with cross-compilation for multiple ESP32 variants and RISC-V targets.

Note: for IR variant of experimental build, please check branch feature/llvm-ir

## Prerequisites

- **System Requirements**: macOS (tested) or Linux
- **Build Tools**: git, cmake, ninja, python3
- **Swift toolchain**: A working Swift installation (for bootstrapping)
- **ESP-IDF 6.0+**: For ESP32-S3 development
- **Disk Space**: ~15GB for repositories and build artifacts

## Quick Start

### 1. **Build Swift Compiler with Xtensa Support**:
   ```bash
   ./swift-xtensa-build.sh
   ```
   
   For a clean build (removes previous artifacts):
   ```bash
   ./swift-xtensa-build.sh --clean
   ```

   This single script will:
   - Clone Swift compiler (release/6.2)
   - Clone Apple's LLVM with CAS patches (swift/release/6.2)
   - Clone cmark and swift-syntax dependencies
   - Build and install all components
   - Create a working Swift compiler at `./install/bin/swiftc`

### 2. **Package the Toolchain** (Optional):
   ```bash
   ./package-toolchain.sh
   ```
   
   Or with a specific version:
   ```bash
   ./package-toolchain.sh v1.0.0
   ```
   
   This creates a distributable package in `packages/` directory that can be:
   - Shared with other developers
   - Installed on different machines
   - Used by package managers like swiftly

### 3. **Validate the Swift Compiler**:
   ```bash
   ./install/bin/swiftc --version
   ```
   
   **Test Embedded Swift compilation**:
   ```bash
   # Test simple embedded Swift program
   cd esp32-s3-swift-baremetal
   echo 'print("Hello, Embedded Swift!")' > test_embedded.swift
   ../install/bin/swiftc -target xtensa-esp32s3-none-elf -enable-experimental-feature Embedded test_embedded.swift
   ```

### 3. **Set Up ESP-IDF Environment** (for cross-compilation):
   ```bash
   source ~/esp-idf/export.sh  # Adjust path to your ESP-IDF installation
   ```

### 4. **Try the ESP32-S3 Bare Metal Demo**:
   ```bash
   cd esp32-s3-swift-baremetal
   make build
   make flash
   make monitor
   ```

### 5. **Build and Flash the ESP-IDF Project** (Alternative):
   ```bash
   cd swift-xtensa-validation/esp-idf-project
   idf.py set-target esp32s3
   idf.py build
   idf.py flash monitor
   ```

## Project Structure

```
swift-xtensa/
├── swift-xtensa-build.sh       # Main build script
├── package-toolchain.sh        # Package toolchain for distribution
├── swift/                      # Swift compiler source (auto-cloned)
├── llvm-apple/                 # Apple LLVM with CAS patches (auto-cloned)
├── cmark/                      # CommonMark library (auto-cloned)
├── swift-syntax/               # Swift syntax library (auto-cloned)
├── build/                      # Build artifacts (created during build)
├── install/                    # Installed tools and libraries
│   └── bin/
│       ├── swiftc             # Swift compiler
│       ├── swift-frontend     # Swift frontend
│       ├── clang             # Clang compiler
│       └── llvm-*            # LLVM tools
├── packages/                   # Generated distribution packages
├── esp32-s3-swift-baremetal/   # ESP32-S3 bare metal Swift demo
│   ├── Package.swift          # Swift Package Manager configuration
│   ├── Sources/
│   │   ├── Application/       # Swift application code (with embedded stdlib)
│   │   ├── Registers/         # Hardware register definitions (MMIO-based)
│   │   └── Support/           # C support and linker scripts
│   ├── Tools/                 # Build tools and configurations
│   ├── Makefile              # Build system for ESP32-S3
│   └── test_embedded.swift   # Simple embedded Swift test
└── swift-xtensa-validation/   # ESP32-S3 validation project (ESP-IDF)
    └── esp-idf-project/       # ESP-IDF project for testing
```

## Key Components

- **`swift-xtensa-build.sh`**: Single comprehensive build script that handles all dependencies
- **Apple LLVM**: Uses Swift's official LLVM fork with CAS (Content Addressable Storage) patches
- **Swift Frontend**: Host Swift compiler with **Embedded Standard Library** support
- **Embedded Standard Library**: Cross-compiled Swift standard library for embedded targets
- **ESP-IDF Integration**: Cross-compilation support for ESP32-S3 Xtensa targets
- **Swift Package Manager**: Full SwiftPM support with embedded target configuration

## Embedded Swift Features

The project now includes comprehensive **Embedded Swift** support:

- **Swift Package Manager Integration**: Full SwiftPM support with `Package.swift` configuration
- **MMIO Support**: Hardware register access using Apple's `swift-mmio` package
- **Bare Metal Runtime**: Custom runtime functions for embedded environment
- **Cross-compiled Standard Library**: Embedded stdlib built for all supported targets
- **Memory Management**: Custom allocators suitable for embedded systems
- **Advanced GPIO Control**: Direct hardware register manipulation with type safety

## Expected Output

When successfully flashed and running on ESP32-S3, you should see:

```
=== ESP32-S3 Swift Bare Metal Demo ===
Architecture: Xtensa LX7
Compiler: Swift with Xtensa Support

Disabling watchdog timers...
Watchdogs disabled.
Initializing LED on GPIO48...
LED initialized.
=== Testing Swift Arithmetic on ESP32-S3 ===
15 + 25 = 40
15 * 25 = 375
Fibonacci(10) = 55
✅ All arithmetic tests PASSED!

🎉 Swift running successfully on ESP32-S3!
All tests completed. Starting LED blink loop...

Cycle 0 - LED ON
Cycle 0 - LED OFF
Cycle 1 - LED ON
...
```

## Build Details

The build process creates:
1. **cmark**: CommonMark library for Swift documentation
2. **LLVM + Clang**: Apple's LLVM fork with Xtensa experimental target support
3. **Swift Frontend**: Host Swift compiler with embedded stdlib support
4. **Embedded Standard Library**: Cross-compiled Swift stdlib for 7 target triples:
   - 3 ESP32 variants (ESP32, ESP32-S2, ESP32-S3) for bare metal
   - 3 ESP32 variants for ESP-IDF framework
   - 1 RISC-V 32-bit target for additional embedded support

Swiftc for building:
- Apple Swift version 6.2-dev (LLVM 4197ac1672a278c, Swift acbdfef4f4d71b1)
- Target: arm64-apple-macosx15.0
- Build config: +assertions

### Build Configuration
- **CAS Support**: Disabled (`-DSWIFT_ENABLE_CAS=OFF`)
- **Swift Syntax**: Disabled to avoid C++ interoperability issues
- **Embedded Standard Library**: **ENABLED** with cross-compilation support
- **Supported Embedded Targets**: 
  - `xtensa-esp32-none-elf` (ESP32 bare metal)
  - `xtensa-esp32s2-none-elf` (ESP32-S2 bare metal)
  - `xtensa-esp32s3-none-elf` (ESP32-S3 bare metal)
  - `xtensa-esp32-espidf` (ESP32 with ESP-IDF)
  - `xtensa-esp32s2-espidf` (ESP32-S2 with ESP-IDF)
  - `xtensa-esp32s3-espidf` (ESP32-S3 with ESP-IDF)
  - `riscv32-none-none-eabi` (RISC-V 32-bit bare metal)
- **Host Target**: arm64-apple-macosx15.0
- **Experimental Features**: Embedded Swift enabled

## Troubleshooting

### Build Issues
- **cmark conflicts**: The script automatically removes conflicting module maps
- **LLVM config missing**: The script ensures `llvm/Config/config.h` is properly installed
- **C++ interop errors**: Swift-Syntax and experimental features are disabled
- **Clean build**: Use `./swift-xtensa-build.sh --clean` to start fresh

### Runtime Issues
- **Target architecture errors**: Use explicit target: `swiftc -target arm64-apple-macosx13.0`
- **Missing swift-driver**: Warning about legacy driver is expected and safe to ignore
- **ESP32-S3 flash fails**: Check ESP32-S3 connection and permissions for USB device
- **Object file not found**: Ensure `swift-functions.o` is compiled and in correct location

## Distribution and Packaging

### Creating Distributable Packages

The `package-toolchain.sh` script creates distributable packages that can be shared with other developers or used on different machines:

```bash
# Create package with auto-generated version
./package-toolchain.sh

# Create package with specific version
./package-toolchain.sh v1.0.0

# Create package in custom directory
./package-toolchain.sh v1.0.0 /path/to/output
```

The package includes:
- Complete Swift compiler with Xtensa support
- All required libraries and headers
- Installation script for system-wide deployment
- Usage documentation and metadata
- SHA256 checksum for integrity verification

### Using Pre-built Packages

To use a pre-built package (from GitHub Releases or CI artifacts):

```bash
# Download and extract
tar -xzf swift-xtensa-toolchain-v1.0.0-macos-arm64.tar.gz
cd swift-xtensa-toolchain-v1.0.0-macos-arm64

# Verify the toolchain
./bin/swiftc --version

# Optional: Install system-wide
sudo ./install.sh
```

### GitHub Actions Integration

The project includes GitHub Actions workflow that:
- Automatically builds the toolchain on pushes and tags
- Creates distributable packages
- Uploads build artifacts for easy download
- Creates GitHub releases for tagged versions

Artifacts are available for 90 days and can be downloaded from the Actions tab.

## Target Triple Standard

**IMPORTANT**: This project supports **7 standardized LLVM target triples** for embedded development, following the same convention as Rust:

### Bare Metal Targets (ELF format)
```
xtensa-esp32-none-elf      # ESP32 bare metal
xtensa-esp32s2-none-elf    # ESP32-S2 bare metal
xtensa-esp32s3-none-elf    # ESP32-S3 bare metal
riscv32-none-none-eabi     # RISC-V 32-bit bare metal (NEW)
```

### ESP-IDF Framework Targets
```
xtensa-esp32-espidf        # ESP32 with ESP-IDF
xtensa-esp32s2-espidf      # ESP32-S2 with ESP-IDF
xtensa-esp32s3-espidf      # ESP32-S3 with ESP-IDF
```

### Target Triple Format
Where:
- **Architecture**: `xtensa` - Recognized by LLVM and Swift as the Xtensa architecture
- **Vendor**: `esp32`/`esp32s2`/`esp32s3` - Specific chip variant identifier
- **OS**: `none` - Bare metal (no operating system)
- **Environment**: `elf` - ELF object file format, or `espidf` - ESP-IDF framework environment

This format is used consistently across:
- **LLVM**: Recognizes `xtensa` and `riscv32` as experimental target architectures
- **Swift**: Embedded stdlib support for all **7 target triples**
- **Applications**: Example projects can target appropriate variant
- **Build Scripts**: Configured to generate Swift stdlib for all supported targets
- **Swift Package Manager**: Native support for embedded target configuration

**Note**: These target triples exactly match the Rust toolchain convention for embedded development, ensuring consistency across language ecosystems. Do not use simplified forms like `esp32s3-none-elf` as they won't be recognized by LLVM's architecture parsing.

## Architecture

This project uses a two-stage compilation approach:
1. **Swift → LLVM IR**: Standard Swift compiler generates LLVM IR
2. **LLVM IR → Xtensa Assembly**: LLVM backend with Xtensa support generates assembly
3. **Assembly → Object**: LLVM assembler creates object files
4. **Object → ESP32 Binary**: ESP-IDF links with Swift object files

## New Features & Improvements


## Current Limitations

- **Debugging**: Limited debugging support (no LLDB integration yet)
- **Concurrency**: No async/await or Actor support in embedded mode
- **Reflection**: Reflection APIs disabled for embedded targets
- **Platform Dependencies**: Some Swift features disabled for embedded compatibility

