# Swift on ESP32-S3 - Technical Architecture

This document describes the technical architecture and implementation details of running Swift on ESP32-S3.

## Overview

The project uses a **two-stage compilation approach** to bridge the gap between Swift's high-level language features and the ESP32-S3's Xtensa architecture:

1. **Stage 1**: Swift → LLVM IR (using host Swift compiler)
2. **Stage 2**: LLVM IR → Xtensa assembly → Object file (using ESP LLVM toolchain)

## Compilation Pipeline

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Swift Source   │    │    LLVM IR      │    │ Xtensa Assembly │
│  (.swift)       │───▶│     (.ll)       │───▶│      (.s)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                ▲                       │
                                │                       │
                    ┌─────────────────┐                 │
                    │   Metadata      │                 │
                    │   Cleanup       │                 │
                    │   (sed)         │                 │
                    └─────────────────┘                 │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  ESP32-S3 Binary│    │  ESP-IDF Build  │    │  Object File    │
│    (.bin)       │◀───│    System       │◀───│     (.o)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Key Components

### 1. Swift Compiler (Stage 1)

**Tool**: `swiftc -emit-ir`
**Input**: Swift source code
**Output**: LLVM IR with macOS-specific metadata

**Process**:
- Compiles Swift to LLVM IR using the host Swift compiler
- Generates metadata for macOS target (which we need to clean)
- Produces unoptimized LLVM IR with all Swift runtime calls

### 2. Metadata Cleanup

**Tool**: `sed` commands
**Input**: Raw LLVM IR from Swift compiler
**Output**: Cleaned LLVM IR compatible with ESP toolchain

**Issues addressed**:
- Removes `!llvm.linker.options` metadata (macOS-specific)
- Strips metadata references that cause ESP LLVM to fail
- Preserves functional IR while removing target-specific metadata

### 3. ESP LLVM Toolchain (Stage 2)

**Tool**: `llc` (LLVM Static Compiler)
**Input**: Cleaned LLVM IR
**Output**: Xtensa assembly code

**Configuration**:
- Target: `xtensa`
- CPU: `esp32s3`
- Handles Xtensa-specific instruction selection and register allocation

### 4. Assembler

**Tool**: `llvm-mc` (LLVM Machine Code assembler)
**Input**: Xtensa assembly
**Output**: ELF object file

**Configuration**:
- Triple: `xtensa-esp-elf`
- Format: ELF32 for Xtensa architecture

## Runtime Support

### Swift Runtime Requirements

Swift requires several runtime components that we provide:

#### 1. Atomic Operations (`atomic_stubs.c`)

Swift uses atomic operations for reference counting and thread safety. We provide interrupt-based implementations:

```c
unsigned int __atomic_load_4(const volatile void *ptr, int memorder)
{
    portDISABLE_INTERRUPTS();
    unsigned int result = *(const volatile unsigned int *)ptr;
    portENABLE_INTERRUPTS();
    return result;
}
```

**Operations provided**:
- `__atomic_load_4`: Atomic load of 32-bit value
- `__atomic_store_4`: Atomic store of 32-bit value
- `__atomic_fetch_add_4`: Atomic fetch-and-add
- `__atomic_fetch_sub_4`: Atomic fetch-and-subtract
- `__atomic_compare_exchange_4`: Atomic compare-and-swap

#### 2. Memory Management

**Current**: Stack-based allocation only
**Limitation**: No heap allocator, limiting Swift features

#### 3. Section Handling (`swift_sections.ld`)

Swift generates metadata sections that ESP-IDF linker doesn't understand. We discard them:

```ld
/DISCARD/ :
{
    *(.swift1_autolink_entries)
    *("__TEXT, __swift5_entry, regular, no_dead_strip")
    *("__DATA,__objc_imageinfo,regular,no_dead_strip")
    *(.rodata.__swift_reflection_version)
}
```

## ESP-IDF Integration

### Build System Integration

**CMakeLists.txt** modifications:
1. Link Swift object file as external object
2. Include atomic stubs in build
3. Apply Swift-specific linker script
4. Force inclusion of atomic symbols

```cmake
# Link Swift object file
target_link_libraries(${COMPONENT_LIB} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/../test_simple.o")

# Force atomic symbols to be included
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_load_4")
```

### C-Swift Interop

**Function Export**: Swift functions use `@_silgen_name` for C compatibility:

```swift
@_silgen_name("swift_simple_loop")
public func swift_simple_loop() {
    // Implementation
}
```

**C Declaration**: C code declares Swift functions as external:

```c
extern void swift_simple_loop(void);
```

## Memory Layout

### Code Sections

- **Swift code**: Placed in `.text` section alongside C code
- **Swift constants**: Placed in `.rodata` section
- **Swift metadata**: Discarded by linker script

### Memory Usage

- **Flash**: Swift code compiled to Xtensa instructions
- **RAM**: Stack-based variables only (no heap allocation)
- **Atomic operations**: Use FreeRTOS interrupt disabling

## Limitations and Constraints

### Current Limitations

1. **No Swift Standard Library**: Core Swift types (String, Array) not available
2. **No Heap Allocation**: Only stack-based memory management
3. **No Reference Counting**: ARC disabled (would require heap)
4. **No Exceptions**: Swift error handling not implemented
5. **No Closures**: Complex Swift features not supported

### Technical Constraints

1. **Single-threaded**: Atomic operations use interrupt disabling
2. **No Dynamic Dispatch**: Virtual method calls not implemented
3. **No Reflection**: Swift reflection metadata discarded
4. **No Autolink**: Swift module linking not supported

## Performance Characteristics

### Binary Size

- **Minimal Swift function**: ~1-2KB additional code
- **Atomic operations**: ~200 bytes of runtime stubs
- **Total overhead**: <5KB for basic Swift support

### Runtime Performance

- **Function calls**: Native speed (no overhead)
- **Arithmetic**: Compiled to native Xtensa instructions
- **Atomic operations**: Interrupt-based (microsecond overhead)

## Future Architecture Improvements

### 1. Swift Standard Library Port

**Goal**: Port essential Swift types to ESP32-S3
**Approach**: Custom implementations of String, Array, etc.
**Challenges**: Memory management, performance optimization

### 2. Heap Allocator

**Goal**: Enable dynamic memory allocation
**Approach**: Integrate with ESP-IDF heap or custom allocator
**Benefits**: Enables ARC, closures, dynamic types

### 3. Hardware Abstraction Layer

**Goal**: Swift wrappers for ESP-IDF APIs
**Approach**: Swift bindings for GPIO, SPI, WiFi, etc.
**Benefits**: Type-safe hardware interaction

### 4. Optimization Pipeline

**Goal**: Optimize Swift code for embedded use
**Approach**: Custom LLVM passes, size optimization
**Benefits**: Smaller binaries, better performance

## Debugging and Development

### Build Artifacts

- **test_simple.ll**: LLVM IR for inspection
- **test_simple.s**: Xtensa assembly for debugging
- **test_simple.o**: Object file with symbols
- **swift_esp32s3_test.map**: Linker map file

### Debugging Tools

- **llvm-objdump**: Inspect object file sections
- **ESP-IDF monitor**: Runtime debugging
- **GDB**: Source-level debugging (with limitations)

### Development Workflow

1. **Edit Swift code** in `test_simple.swift`
2. **Run build script** to recompile
3. **Flash and monitor** to test
4. **Inspect artifacts** for debugging

This architecture successfully demonstrates Swift running on ESP32-S3 while identifying clear paths for future enhancements.
