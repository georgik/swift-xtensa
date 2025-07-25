# Paths
REPOROOT         := $(shell git rev-parse --show-toplevel)
TOOLSROOT        := $(REPOROOT)/esp32-s3-swift-baremetal/Tools
LLVM_OBJCOPY     := $(REPOROOT)/install/bin/llvm-objcopy
SWIFTC           := $(REPOROOT)/install/bin/swiftc
ESP_FLASH        := espflash
LINKERSCRIPT_DIR := $(REPOROOT)/esp32-s3-swift-baremetal/Sources/Support

# Flags - ESP32-S3 uses Xtensa architecture
ARCH             := xtensa
VENDOR           := esp32s3
TARGET           := $(ARCH)-$(VENDOR)-none-elf
BUILDDIR         := .build/$(TARGET)
APP_BINARY       := $(BUILDDIR)/Application
FLASH_BAUD       := 460800

# Swift source files
SWIFT_SOURCES    := Sources/Application/main_minimal.swift
C_SOURCES        := Sources/Support/esp_app_desc.c
LINKER_SCRIPT    := $(LINKERSCRIPT_DIR)/esp32s3.ld

# Compiler flags
SWIFT_FLAGS      := \
    -target $(TARGET) \
    -parse-as-library \
    -wmo \
    -disable-cmo \
    -Osize \
    -I Sources/Support

C_FLAGS          := \
    -target $(TARGET) \
    -O3 \
    -I Sources/Support

LINKER_FLAGS     := \
    -Xlinker -T$(LINKER_SCRIPT) \
    -Xlinker --gc-sections \
    -Xlinker -Map=$(BUILDDIR)/Application.map

.PHONY: build
build:
	@echo "building ESP32-S3 Swift application (bare metal)..."
	mkdir -p $(BUILDDIR)

	@echo "compiling Swift sources to object files..."
	$(SWIFTC) \
		$(SWIFT_FLAGS) \
		-emit-object \
		-o "$(BUILDDIR)/main.o" \
		$(SWIFT_SOURCES)

	@echo "compiling C sources..."
	$(REPOROOT)/install/bin/clang \
		$(C_FLAGS) \
		-c \
		-o "$(BUILDDIR)/esp_app_desc.o" \
		$(C_SOURCES)

	@echo "linking..."
	$(REPOROOT)/install/bin/ld.lld \
		-T$(LINKER_SCRIPT) \
		--gc-sections \
		-Map=$(BUILDDIR)/Application.map \
		-o "$(APP_BINARY)" \
		"$(BUILDDIR)/main.o" \
		"$(BUILDDIR)/esp_app_desc.o"

	@echo "extracting binary..."
	$(LLVM_OBJCOPY) \
		--only-section .text \
		--only-section .rodata \
		-O binary \
		"$(APP_BINARY)" \
		"$(APP_BINARY).bin"

.PHONY: clean
clean:
	@echo "cleaning..."
	@rm -rf .build

.PHONY: elf2image
elf2image:
	@echo "generating esp32-s3 flash image using espflash..."
	$(ESP_FLASH) save-image \
		--chip esp32s3 \
		--flash-mode dio \
		--flash-size 8mb \
		--skip-padding \
		--merge \
		"$(APP_BINARY)" \
		"$(APP_BINARY)_flash.bin" \
		--bootloader Tools/Partitions/bootloader.bin \
		--partition-table Tools/Partitions/partition-table.bin \
		--partition-table-offset 0x8000

.PHONY: flash
flash:
	@echo "flashing ESP32-S3 with espflash (application only)..."
	$(ESP_FLASH) flash \
		--chip esp32s3 \
		--baud $(FLASH_BAUD) \
		--before default-reset \
		--after hard-reset \
		"$(APP_BINARY)"

.PHONY: flash-full
flash-full:
	@echo "flashing ESP32-S3 with bootloader (requires bootloader files)..."
	@if [ ! -f "Tools/Partitions/bootloader.bin" ]; then \
		echo "❌ bootloader.bin not found. See Tools/Partitions/README.md for instructions."; \
		exit 1; \
	fi
	@if [ ! -f "Tools/Partitions/partition-table.bin" ]; then \
		echo "❌ partition-table.bin not found. See Tools/Partitions/README.md for instructions."; \
		exit 1; \
	fi
	$(ESP_FLASH) flash \
		--chip esp32s3 \
		--baud $(FLASH_BAUD) \
		--before default-reset \
		--after hard-reset \
		--flash-mode dio \
		--flash-size 8mb \
		--bootloader Tools/Partitions/bootloader.bin \
		--partition-table Tools/Partitions/partition-table.bin \
		--partition-table-offset 0x8000 \
		"$(APP_BINARY)"

.PHONY: monitor
monitor:
	@echo "Starting ESP32-S3 monitor..."
	$(ESP_FLASH) monitor --chip esp32s3

.PHONY: image_info
image_info:
	@echo ""
	@echo "=== ELF sections ==="
	xtensa-esp32s3-elf-objdump -h "$(APP_BINARY)"
