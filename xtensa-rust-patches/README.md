# Xtensa Support Patches for Rust Compiler

This directory contains patches created by **MabezDev (Scott Mabin)** to add Xtensa architecture support to the Rust compiler.

## Overview

These patches enable Rust compilation for Xtensa-based microcontrollers, particularly ESP8266 and other ESP devices. The changes include:

1. **LLVM Submodule Update** - Switch to LLVM fork with Xtensa support
2. **Inline Assembly Support** - Add `asm!` macro support for Xtensa architecture
3. **GCC Codegen Support** - Enable Xtensa in rustc_codegen_gcc
4. **Target Specification** - Add ESP8266 target definition
5. **Documentation** - Updated README for esp-rs/rust fork

## Patch Files

The patches are generated in chronological order:

1. **0001-Use-llvm-submodule-with-Xtensa-arch-support.patch**
   - Updates .gitmodules to use LLVM fork with Xtensa support
   - Commit: ccbc50a8ffb823eeaa775be0204772d0534ebdf3

2. **0002-asm-support-for-the-Xtensa-architecture-68.patch**
   - Adds comprehensive inline assembly support for Xtensa
   - Includes register definitions, constraints, and instruction templates
   - Adds test cases for Xtensa assembly
   - Commit: a51c50c32456ae9de62d07321ce2e6b64d00342a

3. **0003-Enable-Xtensa-codegen-for-rustc_codegen_gcc.patch**
   - Enables Xtensa architecture in GCC-based code generation
   - Updates object::Architecture usage
   - Commit: 95996c4ee99ce19ae47a2fe020fcb6b16e14dcbc

4. **0004-README-for-esp-rs-rust.patch**
   - Updates documentation for the esp-rs/rust fork
   - Commit: fae8f4553e964831aa2c8e3bd122320cc144ddd2

5. **0005-Add-esp8266-no_std-target.patch**
   - Adds specific target definition for ESP8266 no_std environment
   - Commit: 2ab28d2e728c222edd27f881fd18de24fd88332c

## Base Commit

These patches are based on upstream Rust commit:
- **6b00bc38** - Auto merge of #142918 - cuviper:stable-next, r=cuviper

## File Summary

- **Individual Patches**: `000*.patch` files for incremental application
- **Combined Diff**: `all-xtensa-changes.diff` - Single file with all changes
- **This README**: Documentation and analysis

## Key Changes by Category

### LLVM Integration
- Updates LLVM submodule to version with Xtensa backend
- Located in: `.gitmodules`, `src/llvm-project`

### Compiler Core Changes
- **Assembly Support**: New Xtensa assembly implementation
  - `compiler/rustc_target/src/asm/xtensa.rs` (293 lines)
  - `compiler/rustc_target/src/asm/mod.rs` updates
  - `compiler/rustc_span/src/symbol.rs` symbol additions

- **Codegen Support**: 
  - `compiler/rustc_codegen_llvm/src/asm.rs` updates
  - `compiler/rustc_codegen_gcc/src/asm.rs` Xtensa handling

- **Target Features**: 
  - `compiler/rustc_target/src/target_features.rs` Xtensa features
  - `compiler/rustc_target/src/spec/targets/xtensa_esp8266_none_elf.rs` target spec

### Testing
- `tests/assembly/asm/xtensa-types.rs` - Comprehensive assembly test suite

## Statistics

- **Total commits**: 5
- **Files changed**: ~10 core files
- **Lines added**: ~550+ lines
- **Test coverage**: Assembly instruction testing included

## Usage

To apply these patches to an upstream Rust compiler:

```bash
# Apply individual patches in order
git am xtensa-rust-patches/0001-*.patch
git am xtensa-rust-patches/0002-*.patch
# ... continue with remaining patches

# Or apply the complete diff
git apply xtensa-rust-patches/all-xtensa-changes.diff
```

## Author

**Scott Mabin (MabezDev)**
- Email: scott@mabez.dev
- GitHub: @MabezDev
- Organization: esp-rs project

These patches represent the foundational work to bring Xtensa architecture support to the Rust programming language, enabling embedded development for ESP devices.
