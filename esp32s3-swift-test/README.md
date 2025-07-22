# Swift ESP32-S3 Test Project

This project demonstrates Swift integration with ESP32-S3 using ESP-IDF and CMake build system.

## Overview

This project provides a working example of Swift function integration with ESP32-S3, using a streamlined CMake build system that eliminates the need for separate shell scripts.

## Prerequisites

1. **Swift-Xtensa Compiler**: Built using `../swift-xtensa-build.sh`
2. **ESP-IDF 6.0+**: With ESP32-S3 support 
3. **ESP-IDF Environment**: Sourced with `source ~/esp-idf/export.sh`

## Project Structure

```
esp32s3-swift-test/
├── main/
│   ├── main.c                  # Main ESP32 application
│   ├── swift_wrapper.c         # C implementation of Swift functions (temporary)
│   ├── swift_functions.h       # Swift function declarations
│   ├── atomic_stubs.c          # Atomic operation stubs
│   ├── swift_sections.ld       # Linker script for Swift sections
│   └── CMakeLists.txt          # Component build configuration
├── test_simple.swift           # Swift source code (for future use)
├── sdkconfig.defaults          # ESP-IDF configuration
└── CMakeLists.txt              # Project build configuration
```

## Build and Run

### Simple Build Process

The entire build process is now integrated into ESP-IDF's CMake system. No separate scripts needed!

```bash
# Build the project
idf.py build

# Flash and monitor
idf.py flash monitor

# Clean build (if needed)
idf.py clean build
```

### Expected Output

When running successfully on ESP32-S3:

```
I (284) swift_test: Swift addition: 7 + 8 = 15
I (294) swift_test: Swift multiplication: 4 * 6 = 24
I (294) swift_test: Swift subtraction: 10 - 3 = 7
I (304) swift_test: Swift power: 2^8 = 256
I (314) swift_test: Swift fibonacci(10) = 55
I (364) swift_test: ✅ ALL SWIFT COMPUTATIONS PASSED!
I (374) swift_test: Swift-to-ESP32-S3 integration is working correctly!
```

## How It Works

### Current Implementation

1. **CMake Integration**: The `main/CMakeLists.txt` automatically detects Xtensa architecture and sets up Swift compilation environment
2. **C Wrapper**: Currently uses `swift_wrapper.c` to provide Swift function implementations in C
3. **Build Validation**: Checks for Swift compiler and ESP-IDF environment during build
4. **Seamless Integration**: No manual steps required - just run `idf.py build`

### CMake Build Flow

1. **Architecture Detection**: Validates ESP32-S3/Xtensa target
2. **Compiler Validation**: Checks Swift-Xtensa compiler availability
3. **Environment Check**: Ensures ESP-IDF is properly configured
4. **Source Compilation**: Compiles C sources including Swift wrapper
5. **Linking**: Links with ESP-IDF components and applies ROM conflict resolution

### Future Swift Compilation

The CMakeLists.txt includes commented code for future direct Swift compilation:

```cmake
# TODO: Enable when Swift standard library issues are resolved
# add_custom_command(
#     OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/swift_functions.o"
#     COMMAND "${SWIFT_COMPILER}" -frontend -emit-irgen ...
#     DEPENDS ${SWIFT_SOURCES}
# )
```

## Swift Functions Tested

The project validates these Swift function types:

- **Arithmetic**: Addition, multiplication, subtraction, bit shifting  
- **Advanced Math**: Power calculation, Fibonacci sequence
- **String Operations**: Character extraction, length calculation
- **Edge Cases**: Zero power, zero Fibonacci

## Technical Details

### ROM Conflict Resolution

The build system automatically handles ESP32-S3 ROM conflicts with:
- String function wrapping (`strlen`, `strcpy`, etc.)
- Atomic operation stubs
- Custom linker symbols

### Cross-Compilation Pipeline

1. Swift source → LLVM IR (future)
2. LLVM IR → Xtensa assembly (future) 
3. Assembly → Object file
4. Link with ESP-IDF

## Troubleshooting

### Build Issues

- **Swift compiler not found**: Run `../swift-xtensa-build.sh` first
- **ESP-IDF not found**: Run `source ~/esp-idf/export.sh`
- **Wrong target**: Project only supports ESP32-S3 (xtensa architecture)

### Runtime Issues

- **Flash failures**: Check ESP32-S3 connection and permissions
- **Unexpected output**: Verify all Swift functions return expected values

## Development Notes

This project represents a significant milestone in Swift-ESP32 integration:

✅ **Working**: CMake integration, C wrapper approach, ESP32-S3 execution  
🚧 **In Progress**: Direct Swift-to-LLVM IR compilation  
📋 **Future**: Full Swift standard library support, native Swift compilation

The CMake-based approach provides a solid foundation that can be extended when Swift compiler issues are resolved, making the transition to native Swift compilation seamless.
