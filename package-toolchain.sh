#!/bin/bash
# package-toolchain.sh - Package Swift Xtensa toolchain for distribution
# Usage: ./package-toolchain.sh [version] [output-dir]

set -e

# Show usage if help requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Swift Xtensa Toolchain Packager"
    echo "Usage: $0 [version] [output-dir]"
    echo ""
    echo "Arguments:"
    echo "  version     Version string for the package (default: git short hash)"
    echo "  output-dir  Directory to create packages in (default: ./packages)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Create package with auto-generated version"
    echo "  $0 v1.0.0            # Create package with specific version"
    echo "  $0 v1.0.0 /tmp       # Create package in /tmp directory"
    echo ""
    echo "Prerequisites:"
    echo "  - Run ./swift-xtensa-build.sh first to build the toolchain"
    echo "  - Ensure ./install/ directory exists with built tools"
    exit 0
fi

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}"; }

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$WORKSPACE_DIR/install"

# Parse arguments
VERSION="${1:-$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")}"
OUTPUT_DIR="${2:-$WORKSPACE_DIR/packages}"
PACKAGE_NAME="swift-xtensa-toolchain-${VERSION}-macos-arm64"

log "Packaging Swift Xtensa Toolchain"
echo "Version: $VERSION"
echo "Install directory: $INSTALL_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Package name: $PACKAGE_NAME"

# Verify install directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "❌ Install directory not found: $INSTALL_DIR"
    echo "Please run ./swift-xtensa-build.sh first to build the toolchain"
    exit 1
fi

# Verify key binaries exist
if [[ ! -f "$INSTALL_DIR/bin/swiftc" ]]; then
    echo "❌ swiftc not found in install directory"
    echo "Please run ./swift-xtensa-build.sh to build the toolchain"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
PACKAGE_DIR="$OUTPUT_DIR/$PACKAGE_NAME"

log "Creating package directory: $PACKAGE_DIR"
rm -rf "$PACKAGE_DIR"  # Clean up any existing package
mkdir -p "$PACKAGE_DIR"

# Copy the entire install directory
log "Copying toolchain files..."
cp -r "$INSTALL_DIR"/* "$PACKAGE_DIR/"

# Create package metadata
log "Creating package metadata..."
cat > "$PACKAGE_DIR/PACKAGE_INFO.txt" << EOF
Swift Xtensa Toolchain Package
==============================

Version: $VERSION
Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Platform: macOS ARM64

Components:
- Swift Compiler (swiftc) with Xtensa support
- Swift Frontend (swift-frontend)
- LLVM with Xtensa experimental target
- Clang compiler
- Required libraries and headers

Installation:
1. Extract this package to your desired location
2. Add the bin/ directory to your PATH
3. Verify installation: ./bin/swiftc --version

Usage:
- Use './bin/swiftc' to compile Swift code
- Supports Xtensa target for ESP32-S3 development
- Integrate with ESP-IDF for embedded development

Repository: https://github.com/georgik/swift-xtensa
EOF

# Create installation script
log "Creating installation script..."
cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash
# Swift Xtensa Toolchain Installation Script

set -e

INSTALL_PREFIX="${1:-/usr/local}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Swift Xtensa Toolchain to: $INSTALL_PREFIX"

# Create directories
mkdir -p "$INSTALL_PREFIX/bin"
mkdir -p "$INSTALL_PREFIX/lib"
mkdir -p "$INSTALL_PREFIX/include"

# Copy binaries
cp -r "$SCRIPT_DIR/bin/"* "$INSTALL_PREFIX/bin/"

# Copy libraries and headers
if [ -d "$SCRIPT_DIR/lib" ]; then
    cp -r "$SCRIPT_DIR/lib/"* "$INSTALL_PREFIX/lib/"
fi

if [ -d "$SCRIPT_DIR/include" ]; then
    cp -r "$SCRIPT_DIR/include/"* "$INSTALL_PREFIX/include/"
fi

echo "Installation complete!"
echo "Add $INSTALL_PREFIX/bin to your PATH to use the Swift Xtensa toolchain."
echo "Verify installation: $INSTALL_PREFIX/bin/swiftc --version"
EOF

chmod +x "$PACKAGE_DIR/install.sh"

# Create package README
log "Creating package README..."
cat > "$PACKAGE_DIR/README.md" << EOF
# Swift Xtensa Toolchain

This package contains a Swift compiler with Xtensa support for ESP32-S3 development.

## Quick Start

1. **Extract the package**:
   \`\`\`bash
   tar -xzf $PACKAGE_NAME.tar.gz
   cd $PACKAGE_NAME
   \`\`\`

2. **Verify the installation**:
   \`\`\`bash
   ./bin/swiftc --version
   \`\`\`

3. **Install system-wide** (optional):
   \`\`\`bash
   sudo ./install.sh
   \`\`\`

## Contents

- \`bin/\`: Swift compiler and related tools
- \`lib/\`: Required libraries
- \`include/\`: Header files
- \`install.sh\`: Installation script
- \`PACKAGE_INFO.txt\`: Detailed package information

## Integration with ESP-IDF

This toolchain is designed to work with ESP-IDF for ESP32-S3 development. See the main repository for usage examples and validation projects.

Repository: https://github.com/georgik/swift-xtensa
EOF

# Create the archive
log "Creating archive..."
cd "$OUTPUT_DIR"
tar -czf "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME"

# Generate checksums
log "Generating checksums..."
shasum -a 256 "$PACKAGE_NAME.tar.gz" > "$PACKAGE_NAME.tar.gz.sha256"

# Show results
log "✅ Package created successfully!"
echo "📦 Archive: $OUTPUT_DIR/$PACKAGE_NAME.tar.gz"
echo "📏 Size: $(du -h "$PACKAGE_NAME.tar.gz" | cut -f1)"
echo "🔒 SHA256: $(cat "$PACKAGE_NAME.tar.gz.sha256")"
echo ""
echo "To test the package:"
echo "  cd /tmp"
echo "  tar -xzf $OUTPUT_DIR/$PACKAGE_NAME.tar.gz"
echo "  ./$PACKAGE_NAME/bin/swiftc --version"
