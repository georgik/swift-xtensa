# Quick Start Guide - Swift on ESP32-S3

This guide will get you up and running with Swift on ESP32-S3 in the shortest time possible.

## Prerequisites

- macOS with Xcode and Swift toolchain
- ESP-IDF v6.0+ installed and configured
- ESP32-S3 development board
- Git, CMake, Ninja

## Step 1: Clone and Setup

```bash
# Clone the repository
git clone <repository-url> swift-esp32s3
cd swift-esp32s3

# Setup ESP-IDF environment
. $HOME/esp/esp-idf/export.sh
```

## Step 2: Build LLVM Toolchain

```bash
# Build the ESP LLVM toolchain (this takes ~30-60 minutes)
./build-swift-xtensa.sh
```

## Step 3: Build Swift Project

```bash
# Compile Swift code and build ESP-IDF project
./build-swift-project.sh
```

## Step 4: Flash and Monitor

```bash
# Flash to ESP32-S3 and monitor output
cd esp32s3-swift-test
idf.py flash monitor
```

## Expected Output

You should see the ESP32-S3 boot up and then task watchdog messages indicating the Swift infinite loop is running:

```
I (253) swift_test: Starting Swift ESP32-S3 simple test
I (253) swift_test: About to call Swift simple loop function
E (5253) task_wdt: Task watchdog got triggered...
```

The watchdog messages are **expected** - they confirm the Swift infinite loop is working!

## What's Happening

1. **Swift Code**: The `swift_simple_loop()` function runs an infinite loop
2. **C Integration**: The `main.c` calls the Swift function
3. **Watchdog**: FreeRTOS task watchdog triggers because the loop prevents other tasks from running
4. **Success**: The ESP32-S3 is successfully executing Swift code!

## Troubleshooting

### Build Failures

1. **LLVM not found**: Run `./build-swift-xtensa.sh` first
2. **Swift compilation error**: Check macOS Swift toolchain installation
3. **ESP-IDF error**: Verify ESP-IDF environment with `. $HOME/esp/esp-idf/export.sh`

### Flash Failures

1. **Port not found**: Check USB cable and ESP32-S3 connection
2. **Permission denied**: Try `sudo` or check USB permissions
3. **Flash timeout**: Press and hold BOOT button while flashing

### No Output

1. **Wrong serial port**: Check `idf.py monitor` port selection
2. **Baud rate**: Ensure monitor uses 115200 baud
3. **Reset**: Press RST button on ESP32-S3

## Next Steps

1. **Modify Swift Code**: Edit `esp32s3-swift-test/test_simple.swift`
2. **Rebuild**: Run `./build-swift-project.sh`
3. **Flash**: Run `idf.py flash monitor`
4. **Experiment**: Try the counter loop function or create your own

## File Structure

```
swift-esp32s3/
├── build-swift-project.sh       # ← Main build script
├── esp32s3-swift-test/
│   ├── test_simple.swift        # ← Edit this file
│   └── main/main.c              # ← C integration
└── README.md                    # ← Full documentation
```

## Success Indicators

✅ **Build completes without errors**
✅ **ESP32-S3 boots successfully**  
✅ **Log shows "About to call Swift simple loop function"**
✅ **Task watchdog messages appear** (this means Swift is running!)

🎉 **You now have Swift running on ESP32-S3!**
