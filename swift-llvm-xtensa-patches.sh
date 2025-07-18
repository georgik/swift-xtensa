#!/bin/bash

# Swift LLVM IR Patches for Xtensa ESP32-S3 Compilation
# This script applies necessary patches to convert Swift-generated LLVM IR 
# from ARM64 macOS target to Xtensa ESP32-S3 target

set -e

LLVM_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$LLVM_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input_llvm_file> <output_llvm_file>"
    echo "Example: $0 test_simple.ll test_simple_xtensa.ll"
    exit 1
fi

if [ ! -f "$LLVM_FILE" ]; then
    echo "Error: Input file '$LLVM_FILE' not found"
    exit 1
fi

echo "Applying Swift LLVM IR patches for Xtensa ESP32-S3..."

# Start with a copy of the original file
cp "$LLVM_FILE" "$OUTPUT_FILE"

# =============================================================================
# PATCH 1: Fix Target Triple and Data Layout
# =============================================================================
# Problem: Swift generates ARM64 macOS target triple and 64-bit data layout
# Solution: Replace with Xtensa target triple and 32-bit data layout

echo "  [1/6] Fixing target triple and data layout..."

# Fix target triple: ARM64 macOS -> Xtensa ESP ELF
sed -i '' 's/target triple = ".*"/target triple = "xtensa-esp-elf"/' "$OUTPUT_FILE"

# Fix data layout: 64-bit ARM -> 32-bit Xtensa
# Original: "e-m:o-i64:64-i128:128-n32:64-S128-Fn32" (ARM64 macOS)
# Fixed:    "e-m:e-p:32:32-i64:64-i128:128-n32" (Xtensa 32-bit)
# - e: little endian
# - m:e: ELF mangling (instead of m:o for macOS)
# - p:32:32: 32-bit pointers with 32-bit alignment
# - i64:64: 64-bit integers with 64-bit alignment
# - i128:128: 128-bit integers with 128-bit alignment
# - n32: native integer width is 32 bits
sed -i '' 's/target datalayout = ".*"/target datalayout = "e-m:e-p:32:32-i64:64-i128:128-n32"/' "$OUTPUT_FILE"

# =============================================================================
# PATCH 2: Fix Target CPU and Features
# =============================================================================
# Problem: Swift generates Apple M1 CPU with ARM-specific features
# Solution: Replace with ESP32-S3 CPU and remove ARM features

echo "  [2/6] Fixing target CPU and features..."

# Fix target CPU: Apple M1 -> ESP32-S3
sed -i '' 's/"target-cpu"=".*"/"target-cpu"="esp32s3"/' "$OUTPUT_FILE"

# Remove ARM-specific target features completely
# These include: +aes,+altnzcv,+ccdp,+ccidx,+complxnum,+crc,+dit,+dotprod,etc.
sed -i '' 's/"target-features"="[^"]*"//' "$OUTPUT_FILE"

# =============================================================================
# PATCH 3: Remove Problematic Linker Options
# =============================================================================
# Problem: Swift generates macOS-specific linker options that Xtensa doesn't understand
# Solution: Remove these metadata entries

echo "  [3/6] Removing problematic linker options..."

# Remove Swift linker options (causes LLVM errors on Xtensa)
sed -i '' '/!llvm.linker.options/d' "$OUTPUT_FILE"

# Remove references to Swift libraries that don't exist on Xtensa
sed -i '' '/lswiftSwiftOnoneSupport/d' "$OUTPUT_FILE"
sed -i '' '/lswiftCore/d' "$OUTPUT_FILE"
sed -i '' '/lswift_Concurrency/d' "$OUTPUT_FILE"
sed -i '' '/lswift_StringProcessing/d' "$OUTPUT_FILE"
sed -i '' '/lobjc/d' "$OUTPUT_FILE"

# =============================================================================
# PATCH 4: Remove macOS-Specific Metadata
# =============================================================================
# Problem: Swift generates macOS SDK and Objective-C metadata
# Solution: Remove these metadata entries

echo "  [4/6] Removing macOS-specific metadata..."

# Remove macOS SDK version metadata
sed -i '' '/SDK Version/d' "$OUTPUT_FILE"

# Remove Objective-C metadata (not supported on Xtensa)
sed -i '' '/Objective-C Version/d' "$OUTPUT_FILE"
sed -i '' '/Objective-C Image Info/d' "$OUTPUT_FILE"
sed -i '' '/Objective-C Garbage Collection/d' "$OUTPUT_FILE"
sed -i '' '/Objective-C Class Properties/d' "$OUTPUT_FILE"

# Remove macOS-specific sections
sed -i '' '/__DATA,__objc_imageinfo/d' "$OUTPUT_FILE"

# =============================================================================
# PATCH 5: Fix Metadata References
# =============================================================================
# Problem: Removing metadata entries breaks references in !llvm.module.flags
# Solution: Clean up metadata references and renumber them

echo "  [5/6] Fixing metadata references..."

# Remove PIC Level metadata (Position Independent Code - not needed for embedded)
sed -i '' '/PIC Level/d' "$OUTPUT_FILE"

# Remove uwtable metadata (unwind tables - not needed for embedded)
sed -i '' '/uwtable/d' "$OUTPUT_FILE"

# Remove frame-pointer metadata (keep only essential ones)
sed -i '' '/frame-pointer.*metadata/d' "$OUTPUT_FILE"

# Simplify !llvm.module.flags to only include essential metadata
# This is a more aggressive approach - replace the entire flags section
sed -i '' '/!llvm.module.flags = /c\
!llvm.module.flags = !{!0, !1}' "$OUTPUT_FILE"

# Update remaining metadata references
sed -i '' '/!swift.module.flags = /c\
!swift.module.flags = !{!2}' "$OUTPUT_FILE"

# =============================================================================
# PATCH 6: Clean Up Remaining Metadata
# =============================================================================
# Problem: Broken metadata references after cleanup
# Solution: Renumber and clean remaining metadata

echo "  [6/6] Cleaning up metadata..."

# Remove all old metadata definitions (they're now broken)
sed -i '' '/^![0-9][0-9]* = /d' "$OUTPUT_FILE"

# Add clean metadata definitions
cat >> "$OUTPUT_FILE" << 'EOF'
!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"Swift Version", i32 7}
!2 = !{!"standard-library", i1 false}
EOF

echo "✅ Swift LLVM IR patches applied successfully!"
echo "Input:  $LLVM_FILE"
echo "Output: $OUTPUT_FILE"
echo ""
echo "Key changes applied:"
echo "  • Target triple: ARM64 macOS → Xtensa ESP ELF"
echo "  • Data layout: 64-bit ARM → 32-bit Xtensa"
echo "  • Target CPU: Apple M1 → ESP32-S3"
echo "  • Removed ARM-specific target features"
echo "  • Removed macOS-specific linker options"
echo "  • Removed Objective-C and macOS SDK metadata"
echo "  • Cleaned up metadata references"
