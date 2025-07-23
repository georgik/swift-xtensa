# Swift on ESP32-S3 - Xtensa Cross-Compilation Validation

This project demonstrates building and running Swift on the ESP32-S3 using the Xtensa toolchain. It provides a comprehensive build script to compile a Swift compiler with Xtensa support for ESP32-S3 development with ESP-IDF.

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

### 2. **Validate the Swift Compiler**:
   ```bash
   ./install/bin/swiftc --version
   ```

### 3. **Set Up ESP-IDF Environment** (for cross-compilation):
   ```bash
   source ~/esp-idf/export.sh  # Adjust path to your ESP-IDF installation
   ```

### 4. **Build and Flash the ESP-IDF Project**:
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
└── swift-xtensa-validation/   # ESP32-S3 validation project
    └── esp-idf-project/       # ESP-IDF project for testing
```

## Key Components

- **`swift-xtensa-build.sh`**: Single comprehensive build script that handles all dependencies
- **Apple LLVM**: Uses Swift's official LLVM fork with CAS (Content Addressable Storage) patches
- **Swift Frontend**: Host-only Swift compiler without standard library
- **ESP-IDF Integration**: Cross-compilation support for ESP32-S3 Xtensa targets

## Swift Functions
`swift-functions.swift` contains simple Swift functions for addition, multiplication, and Fibonacci calculation, intended to demonstrate execution on the ESP32-S3.

## Expected Output

When successfully flashed and running on ESP32-S3, you should see:

```
I (265) SWIFT: === Swift on ESP32-S3 Validation ===
I (265) SWIFT: Swift add: 7 + 8 = 15
I (265) SWIFT: Swift multiply: 4 * 6 = 24
I (275) SWIFT: Swift fibonacci(10) = 55
I (275) SWIFT: ✅ All Swift computations passed!
I (285) SWIFT: Swift code running on ESP32-S3!
```

## Build Details

The build process creates:
1. **cmark**: CommonMark library for Swift documentation
2. **LLVM + Clang**: Apple's LLVM fork with CAS (Content Addressable Storage) patches
3. **Swift Frontend**: Host-only Swift compiler (no standard library)

Swiftc for building:
- Apple Swift version 6.2-dev (LLVM 4197ac1672a278c, Swift acbdfef4f4d71b1)
- Target: arm64-apple-macosx15.0
- Build config: +assertions

### Build Configuration
- **CAS Support**: Disabled (`-DSWIFT_ENABLE_CAS=OFF`)
- **Swift Syntax**: Disabled to avoid C++ interoperability issues
- **Standard Library**: Disabled for minimal build
- **Target**: Host architecture only (arm64-apple-macosx13.0)

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

## Architecture

This project uses a two-stage compilation approach:
1. **Swift → LLVM IR**: Standard Swift compiler generates LLVM IR
2. **LLVM IR → Xtensa Assembly**: LLVM backend with Xtensa support generates assembly
3. **Assembly → Object**: LLVM assembler creates object files
4. **Object → ESP32 Binary**: ESP-IDF links with Swift object files

## Limitations

- **Basic Swift support only**: No Swift standard library
- **Simple data types**: Integers and basic arithmetic operations
- **Manual compilation**: Requires custom build process
- **Debugging limited**: Standard Swift debugging tools not available

