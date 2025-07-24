# ESP32-S3 Swift Bare Metal Demo

This project demonstrates **Swift running bare metal on ESP32-S3** using the **Xtensa LX7** architecture. It showcases Swift code compiled with the custom Xtensa-enabled Swift compiler built in the parent directory.

## What it does

The application:
- Runs bare metal Swift code on ESP32-S3 (Xtensa LX7 architecture)
- Demonstrates Swift arithmetic operations (addition, multiplication, Fibonacci)
- Controls GPIO for LED blinking
- Uses direct register access for UART console output
- Disables watchdog timers for stable operation

## Architecture Overview

This project demonstrates the complete toolchain for ESP32-S3 Swift development:

### 1. **Swift Application Layer**
- **`Sources/Application/main.swift`**: Main Swift application with console output and LED control
- Uses `@_cdecl("swift_main")` to provide C-compatible entry point
- Implements direct memory-mapped I/O for hardware access

### 2. **Hardware Abstraction Layer**
- **Direct Register Access**: Uses memory-mapped I/O for hardware control
- **ESP32-S3 Peripherals**: GPIO, UART, Timer, Watchdog control
- **Xtensa LX7 Architecture**: Native support for ESP32-S3's dual-core processor

### 3. **Build System**
- **Embedded Swift**: Uses Swift's experimental embedded mode
- **Xtensa Target**: Compiles for `xtensa-esp32s3-none-elf` architecture
- **Custom Toolchain**: Uses the Swift compiler with Xtensa support from parent project
- **ESP-HAL Linker Scripts**: ESP32-S3 specific memory layout and startup code

### 4. **Memory Layout**
- **IRAM**: Instruction RAM for performance-critical code
- **DRAM**: Data RAM for variables and heap
- **Flash**: External flash memory for program storage
- **RTC Memory**: Persistent memory for deep sleep applications

## Hardware Requirements

- ESP32-S3 development board (ESP32-S3-DevKitC-1 recommended)
- USB cable for programming and console output
- Optional: LED connected to GPIO48 (or adjust LED_PIN in main.swift)

## Build Requirements

- **Swift with Xtensa Support**: Built using the toolchain from parent directory
- **espflash**: Single binary flasher for ESP32 series
  - Installation: `cargo install espflash`

## Building and Running

### 1. Build the Swift Xtensa Compiler (if not done)
```bash
cd .. # Go to swift-xtensa directory
./swift-xtensa-build.sh
```

### 2. Build the ESP32-S3 application
```bash
cd esp32-s3-swift-baremetal
make build
```

### 3. Flash to ESP32-S3
```bash
make flash
```

### 4. Monitor console output
```bash
espflash monitor --chip esp32s3
```

## Expected Output

When successfully flashed and running on ESP32-S3:

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
Cycle 1 - LED OFF
...
--- 10 cycles completed ---
GPIO_OUT register: 0x000100000000000
GPIO_ENABLE register: 0x000100000000000
```

## Project Structure

```
esp32-s3-swift-baremetal/
├── Sources/
│   ├── Application/
│   │   └── main.swift              # Main Swift application
│   ├── Registers/                  # Generated register definitions (optional)
│   └── Support/
│       ├── include/               # C headers
│       ├── ld/                    # Linker scripts
│       │   ├── esp32s3/          # ESP32-S3 specific scripts
│       │   ├── sections/         # Common section definitions
│       │   └── xtensa/           # Xtensa architecture scripts
│       └── esp_app_desc.c        # ESP32 app descriptor
├── Tools/
│   └── Toolsets/
│       └── esp32-s3-elf.json    # Embedded Swift compiler configuration
├── Makefile                       # Build system
├── Package.swift                  # Swift package definition
├── swift-export.sh               # Register export script (optional)
└── README.md                      # This file
```

## Advanced Usage

### Register Generation (Optional)

To generate type-safe register definitions from ESP32-S3 SVD:

```bash
# Prerequisites: Build SVD2Swift from swift-mmio
./swift-export.sh
```

This will generate Swift register definitions in `Sources/Registers/` from the ESP32-S3 SVD file.

## Technical Details

### Compilation Process
1. **Swift → LLVM IR**: Swift compiler generates LLVM intermediate representation
2. **LLVM IR → Xtensa Assembly**: LLVM backend with Xtensa support generates assembly
3. **Assembly → Object Code**: LLVM assembler creates Xtensa object files
4. **Linking**: Custom linker scripts create ESP32-S3 compatible binary
5. **Flash Image**: espflash creates bootable ESP32-S3 flash image

### Memory Usage
- **Text Section**: ~20KB (Swift application code)
- **Data Section**: ~2KB (constants and initialized variables)
- **BSS Section**: ~1KB (uninitialized variables)
- **Stack**: 8KB (configurable in linker scripts)

### Performance Characteristics
- **Boot Time**: ~50ms from reset to Swift code execution
- **Arithmetic Performance**: Native Xtensa LX7 speeds
- **Memory Access**: Direct hardware register access with zero overhead

## Limitations

- **Basic Swift Support**: No Swift standard library
- **Simple Data Types**: Integers and basic operations
- **Manual Hardware Control**: Direct register manipulation required
- **No Dynamic Memory**: Embedded environment constraints

## Troubleshooting

### Build Issues
- **Compiler Not Found**: Ensure parent directory Swift compiler is built
- **Linker Errors**: Check that all linker scripts are present
- **Target Mismatch**: Verify toolchain configuration targets ESP32-S3

### Runtime Issues
- **No Console Output**: Check UART connections and baud rate
- **LED Not Blinking**: Verify GPIO pin number matches your board
- **Watchdog Reset**: Ensure watchdog disabling code runs early

## Key Technologies

- **[Embedded Swift](https://github.com/swiftlang/swift/tree/main/docs/EmbeddedSwift)**: Swift's embedded compilation mode
- **ESP32-S3**: Dual-core Xtensa LX7 microcontroller with WiFi/Bluetooth
- **Xtensa Architecture**: 32-bit RISC processor with DSP extensions
- **ESP-HAL**: Hardware abstraction layer for ESP32 series
- **Bare Metal**: No operating system, direct hardware control
