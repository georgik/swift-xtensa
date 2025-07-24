# ESP32-S3 Bootloader and Partition Files

This directory should contain the ESP32-S3 bootloader and partition table files needed for flashing.

## Required Files

- `bootloader.bin` - ESP32-S3 bootloader binary
- `partition-table.bin` - Partition table for the application

## How to Obtain

These files can be obtained from:

1. **ESP-IDF**: Build an ESP-IDF project for ESP32-S3 and copy from `build/` directory
2. **esp-rs Projects**: Extract from esp-hal examples for ESP32-S3
3. **espflash**: Can generate basic bootloader with `espflash save-image`

## Temporary Solution

For testing without bootloader files, you can use espflash to flash just the application:

```bash
# Flash application directly (without bootloader)
espflash flash --chip esp32s3 .build/release/Application
```

Note: This requires a pre-existing bootloader on the ESP32-S3.
