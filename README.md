# Swift on ESP32-S3 - Xtensa Cross-Compilation Validation

This project demonstrates building and running Swift on the ESP32-S3 using the Xtensa toolchain. It includes all necessary scripts and configurations to replicate the process for ESP32-S3 Xtensa builds with ESP-IDF.

## Prerequisites

- **System Requirements**: macOS or Linux
- **Build Tools**: git, cmake, ninja, python3
- **ESP-IDF 6.0+**: For ESP32-S3 development
- **Disk Space**: ~8GB for repositories and build artifacts

## Setup Instructions

### 1. **Initialize Swift-Xtensa Repositories**:
   ```bash
   ./setup-swift-xtensa-repos.sh
   ```
   This will:
   - Clone Swift compiler (release/6.2)
   - Clone LLVM with Xtensa backend (Espressif fork)
   - Set up minimal Swift dependencies
   - Create workspace configuration

### 2. **Copy Build Scripts to Workspace**:
   ```bash
   cp build-*.sh swift-xtensa-workspace/
   cd swift-xtensa-workspace
   ```

### 3. **Set Up the Build Environment**:
   ```bash
   source build-env.sh
   ```

### 4. **Build the Swift Compiler for Xtensa**:
   ```bash
   ./build-llvm-xtensa.sh    # Build LLVM with Xtensa backend
   ./build-swift-compiler.sh # Build Swift compiler for Xtensa
   ```

### 5. **Validate the Xtensa LLVM and Swift Toolchain**:
   ```bash
   cd ../swift-xtensa-validation
   ./verify-xtensa.sh
   ```

### 6. **Set Up ESP-IDF Environment**:
   ```bash
   source ~/esp-idf/export.sh  # Adjust path to your ESP-IDF installation
   ```

### 7. **Build and Flash the ESP-IDF Project**:
   ```bash
   cd esp-idf-project
   idf.py set-target esp32s3
   idf.py build
   idf.py flash monitor
   ```

## Description of Key Scripts
- **`build-llvm-xtensa.sh`**: Script to build the LLVM backend for Xtensa target.
- **`build-swift-compiler.sh`**: Script to build the Swift compiler.
- **`verify-xtensa.sh`**: Script to validate the Xtensa toolchain with basic computations.

## ESP-IDF Project
Located in `swift-xtensa-validation/esp-idf-project`.

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

## Troubleshooting

- **Build fails**: Ensure all prerequisites are installed and ESP-IDF is properly set up
- **Flash fails**: Check ESP32-S3 connection and permissions for USB device
- **Swift compilation issues**: Verify LLVM with Xtensa backend is properly built
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

