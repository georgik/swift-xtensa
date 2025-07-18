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
# Problem: Swift generates ARM32 ELF target triple for embedded, need Xtensa target
# Solution: Replace with Xtensa target triple and compatible data layout

echo "  [1/7] Fixing target triple and data layout..."

# Fix target triple: ARM32 ELF -> Xtensa ESP ELF
sed -i '' 's/target triple = ".*"/target triple = "xtensa-esp-elf"/' "$OUTPUT_FILE"

# Fix data layout: 32-bit ARM -> 32-bit Xtensa (mainly ABI and format changes)
# Original: "e-m:e-p:32:32-Fi8-i64:64-v128:64:128-a:0:32-n32-S64" (ARM32 ELF)
# Fixed:    "e-m:e-p:32:32-i64:64-i128:128-n32" (Xtensa 32-bit)
# - e: little endian (same)
# - m:e: ELF mangling (same)
# - p:32:32: 32-bit pointers with 32-bit alignment (same)
# - i64:64: 64-bit integers with 64-bit alignment
# - i128:128: 128-bit integers with 128-bit alignment
# - n32: native integer width is 32 bits (same)
sed -i '' 's/target datalayout = ".*"/target datalayout = "e-m:e-p:32:32-i64:64-i128:128-n32"/' "$OUTPUT_FILE"

# =============================================================================
# PATCH 2: Fix Target CPU and Features
# =============================================================================
# Problem: Swift generates Apple M1 CPU with ARM-specific features
# Solution: Replace with ESP32-S3 CPU and remove ARM features

echo "  [2/7] Fixing target CPU and features..."

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

echo "  [3/7] Removing problematic linker options..."

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

echo "  [4/7] Removing macOS-specific metadata..."

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

echo "  [5/7] Fixing metadata references..."

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
# PATCH 6: Remove Conflicting Function Definitions
# =============================================================================
# Problem: Swift generates swift_beginAccess and swift_endAccess functions
# Solution: Remove these function definitions to avoid conflicts with atomic_stubs.c

echo "  [6/7] Removing conflicting function definitions..."

# Remove swift_beginAccess function definition
# This removes the entire function definition including the function body
sed -i '' '/^define.*swift_beginAccess.*{/,/^}$/d' "$OUTPUT_FILE"

# Remove swift_endAccess function definition
# This removes the entire function definition including the function body
sed -i '' '/^define.*swift_endAccess.*{/,/^}$/d' "$OUTPUT_FILE"

# =============================================================================
# PATCH 7: Clean Up Remaining Metadata
# =============================================================================
# Problem: Broken metadata references after cleanup
# Solution: Renumber and clean remaining metadata

echo "  [7/7] Cleaning up metadata..."

# Remove all old metadata definitions (they're now broken)
sed -i '' '/^![0-9][0-9]* = /d' "$OUTPUT_FILE"

# Add clean metadata definitions
cat >> "$OUTPUT_FILE" << 'EOF'
!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"Swift Version", i32 7}
!2 = !{!"standard-library", i1 false}
!3 = !{!"any pointer", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}
!7 = !{!"any pointer", !4, i64 0}
!12 = !{!"any pointer", !4, i64 0}
!17 = !{}
!18 = !{i64 8}
EOF

echo "✅ Swift LLVM IR patches applied successfully!"
echo "Input:  $LLVM_FILE"
echo "Output: $OUTPUT_FILE"
echo ""
echo "Key changes applied:"
echo "  • Target triple: ARM32 ELF → Xtensa ESP ELF"
echo "  • Data layout: ARM32 → Xtensa 32-bit (ABI changes)"
echo "  • Target CPU: ARM → ESP32-S3"
echo "  • Removed ARM-specific target features"
echo "  • Removed embedded-specific linker options"
echo "  • Removed conflicting function definitions"
echo "  • Removed unnecessary metadata"
echo "  • Cleaned up metadata references"
