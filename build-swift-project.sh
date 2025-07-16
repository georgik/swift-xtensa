#!/bin/bash

# Swift to ESP32-S3 Build Script
# This script automates the compilation of Swift code to ESP32-S3 firmware

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
ESP_PROJECT_DIR="$PROJECT_DIR/esp32s3-swift-test"
LLVM_BIN="$PROJECT_DIR/build/llvm-esp/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Swift to ESP32-S3 Build Script${NC}"
echo "=================================================="

# Check if LLVM toolchain exists
if [ ! -d "$LLVM_BIN" ]; then
    echo -e "${RED}❌ ESP LLVM toolchain not found at $LLVM_BIN${NC}"
    echo "Please run ./build-swift-xtensa.sh first to build the toolchain"
    exit 1
fi

# Check if Swift source file exists
SWIFT_FILE="$ESP_PROJECT_DIR/test_simple.swift"
if [ ! -f "$SWIFT_FILE" ]; then
    echo -e "${RED}❌ Swift source file not found: $SWIFT_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}📁 Working directory: $ESP_PROJECT_DIR${NC}"
cd "$ESP_PROJECT_DIR"

# Step 1: Compile Swift to LLVM IR
echo -e "${BLUE}🔨 Step 1: Compiling Swift to LLVM IR...${NC}"
swiftc -emit-ir test_simple.swift -o test_simple.ll
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Swift compilation successful${NC}"
else
    echo -e "${RED}❌ Swift compilation failed${NC}"
    exit 1
fi

# Step 2: Clean LLVM IR metadata
echo -e "${BLUE}🧹 Step 2: Cleaning LLVM IR metadata...${NC}"
sed '/!llvm.linker.options/d' test_simple.ll > test_simple_clean.ll
sed '/^!1[2-9] = /d' test_simple_clean.ll > test_simple_final.ll
echo -e "${GREEN}✅ LLVM IR cleaned${NC}"

# Step 3: Compile LLVM IR to Xtensa assembly
echo -e "${BLUE}🔧 Step 3: Compiling LLVM IR to Xtensa assembly...${NC}"
"$LLVM_BIN/llc" -march=xtensa -mcpu=esp32s3 test_simple_final.ll -o test_simple.s
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Xtensa assembly generation successful${NC}"
else
    echo -e "${RED}❌ Xtensa assembly generation failed${NC}"
    exit 1
fi

# Step 4: Assemble to object file
echo -e "${BLUE}🔗 Step 4: Assembling to object file...${NC}"
"$LLVM_BIN/llvm-mc" -triple=xtensa-esp-elf -filetype=obj test_simple.s -o test_simple.o
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Object file generation successful${NC}"
else
    echo -e "${RED}❌ Object file generation failed${NC}"
    exit 1
fi

# Step 5: Build ESP-IDF project
echo -e "${BLUE}🏗️ Step 5: Building ESP-IDF project...${NC}"
idf.py build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ESP-IDF build successful${NC}"
else
    echo -e "${RED}❌ ESP-IDF build failed${NC}"
    exit 1
fi

# Show build summary
echo ""
echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo "=================================================="
echo -e "${BLUE}📊 Build Summary:${NC}"
echo "  Swift source:     test_simple.swift"
echo "  LLVM IR:          test_simple.ll"
echo "  Cleaned IR:       test_simple_final.ll"
echo "  Xtensa assembly:  test_simple.s"
echo "  Object file:      test_simple.o"
echo "  ESP32-S3 binary:  build/swift_esp32s3_test.bin"
echo ""
echo -e "${YELLOW}📦 Generated files:${NC}"
ls -la test_simple.*
echo ""
echo -e "${YELLOW}💾 Binary size:${NC}"
ls -lh build/swift_esp32s3_test.bin
echo ""
echo -e "${BLUE}🚀 To flash to ESP32-S3:${NC}"
echo "  idf.py flash monitor"
echo ""
echo -e "${BLUE}🔍 To view assembly:${NC}"
echo "  less test_simple.s"
echo ""
echo -e "${BLUE}🔍 To view LLVM IR:${NC}"
echo "  less test_simple_final.ll"
