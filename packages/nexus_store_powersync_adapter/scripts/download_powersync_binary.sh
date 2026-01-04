#!/bin/bash
# download_powersync_binary.sh - Download PowerSync SQLite Core binary
#
# This script downloads the powersync-sqlite-core native extension required
# for running integration tests with real PowerSync databases.
#
# Usage:
#   ./scripts/download_powersync_binary.sh [version]
#
# Arguments:
#   version   Optional version tag (default: latest)
#
# Examples:
#   ./scripts/download_powersync_binary.sh           # Download latest
#   ./scripts/download_powersync_binary.sh v0.3.12   # Download specific version
#
# The script will:
#   1. Detect your platform (macOS, Linux, Windows)
#   2. Detect your architecture (x64, arm64)
#   3. Download the appropriate binary
#   4. Place it in the project root with the correct name

set -e

# Configuration
REPO="powersync-ja/powersync-sqlite-core"
VERSION="${1:-latest}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Detect platform
detect_platform() {
    local os
    local arch

    case "$(uname -s)" in
        Darwin*)
            os="macos"
            ;;
        Linux*)
            os="linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            os="windows"
            ;;
        *)
            error "Unsupported operating system: $(uname -s)"
            ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64)
            arch="x64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        *)
            error "Unsupported architecture: $(uname -m)"
            ;;
    esac

    echo "${os}_${arch}"
}

# Get binary filename based on platform
get_binary_name() {
    local platform="$1"

    case "$platform" in
        macos_x64)
            echo "libpowersync_x64.dylib"
            ;;
        macos_arm64)
            echo "libpowersync_aarch64.dylib"
            ;;
        linux_x64)
            echo "libpowersync_x64.so"
            ;;
        linux_arm64)
            echo "libpowersync_aarch64.so"
            ;;
        windows_x64)
            echo "powersync_x64.dll"
            ;;
        windows_arm64)
            echo "powersync_aarch64.dll"
            ;;
        *)
            error "Unknown platform: $platform"
            ;;
    esac
}

# Get target filename (without architecture suffix)
get_target_name() {
    local platform="$1"

    case "$platform" in
        macos_*)
            echo "libpowersync.dylib"
            ;;
        linux_*)
            echo "libpowersync.so"
            ;;
        windows_*)
            echo "powersync.dll"
            ;;
        *)
            error "Unknown platform: $platform"
            ;;
    esac
}

# Get latest release version
get_latest_version() {
    local api_url="https://api.github.com/repos/${REPO}/releases/latest"

    if command -v curl &> /dev/null; then
        curl -sL "$api_url" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'
    elif command -v wget &> /dev/null; then
        wget -qO- "$api_url" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Download binary
download_binary() {
    local version="$1"
    local binary_name="$2"
    local target_path="$3"

    local download_url="https://github.com/${REPO}/releases/download/${version}/${binary_name}"

    info "Downloading from: $download_url"

    if command -v curl &> /dev/null; then
        curl -L -o "$target_path" "$download_url"
    elif command -v wget &> /dev/null; then
        wget -O "$target_path" "$download_url"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Main
main() {
    info "PowerSync SQLite Core Binary Downloader"
    echo ""

    # Detect platform
    local platform
    platform=$(detect_platform)
    info "Detected platform: $platform"

    # Get version
    local version="$VERSION"
    if [ "$version" = "latest" ]; then
        info "Fetching latest version..."
        version=$(get_latest_version)
        if [ -z "$version" ]; then
            error "Failed to fetch latest version. Please specify a version manually."
        fi
    fi
    info "Using version: $version"

    # Get filenames
    local binary_name
    local target_name
    binary_name=$(get_binary_name "$platform")
    target_name=$(get_target_name "$platform")

    local target_path="${PROJECT_ROOT}/${target_name}"

    info "Binary name: $binary_name"
    info "Target path: $target_path"
    echo ""

    # Check if already exists
    if [ -f "$target_path" ]; then
        warn "Binary already exists at $target_path"
        read -p "Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Skipping download."
            exit 0
        fi
    fi

    # Download
    info "Downloading PowerSync binary..."
    download_binary "$version" "$binary_name" "$target_path"

    # Make executable (for Unix systems)
    if [[ "$platform" != windows_* ]]; then
        chmod +x "$target_path"
    fi

    echo ""
    info "Successfully downloaded PowerSync binary!"
    info "Location: $target_path"
    echo ""
    info "You can now run integration tests with:"
    echo "  cd $PROJECT_ROOT"
    echo "  dart test --tags=real_db"
}

main "$@"
