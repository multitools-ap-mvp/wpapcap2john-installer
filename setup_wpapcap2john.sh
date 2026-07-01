#!/usr/bin/env bash
#
# setup_wpapcap2john.sh
# Setup John the Ripper (jumbo) from Source and
# installs wpapcap2john to /usr/local/bin for system-wide use.
#
# Designed for Linux Mint/Kali/Debian
# Designed By Apex Multi Tools
#
# Usage:
#   chmod +x setup_wpapcap2john.sh
#   sudo ./setup_wpapcap2john.sh
#
set -euo pipefail

# ---- config ----------------------------------------------------------
BUILD_DIR="${BUILD_DIR:-/opt/john-build}"
JOBS="$(nproc)"
REPO_URL="https://github.com/openwall/john.git"

# ---- helpers -----------------------------------------------------------
log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
die()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; exit 1; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        die "Run this with sudo/root (apt install + writing to /usr/local/bin need it)."
    fi
}

# ---- steps -------------------------------------------------------------

install_deps() {
    log "Installing build dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        libssl-dev \
        zlib1g-dev \
        pkg-config \
        libgmp-dev \
        libpcap-dev \
        yasm \
        ca-certificates \
        >/dev/null
    log "Dependencies installed."
}

clone_repo() {
    if [[ -d "$BUILD_DIR/.git" ]]; then
        log "Existing John source found at $BUILD_DIR, pulling latest..."
        git -C "$BUILD_DIR" pull --ff-only
    else
        log "Cloning John the Ripper jumbo into $BUILD_DIR..."
        mkdir -p "$(dirname "$BUILD_DIR")"
        git clone --depth 1 "$REPO_URL" "$BUILD_DIR"
    fi
}

build_john() {
    log "Configuring build..."
    cd "$BUILD_DIR/src"
    ./configure

    log "Compiling with $JOBS jobs (this can take a few minutes)..."
    make -s clean
    make -sj"$JOBS"
}

verify_binary() {
    local bin="$BUILD_DIR/run/wpapcap2john"
    if [[ ! -x "$bin" ]]; then
        die "Build finished but wpapcap2john was not produced. Check the build log above for errors (commonly missing libssl-dev)."
    fi
    log "wpapcap2john built successfully at $bin"
}

install_symlinks() {
    log "Linking tools into /usr/local/bin..."
    local run_dir="$BUILD_DIR/run"

    ln -sf "$run_dir/wpapcap2john" /usr/local/bin/wpapcap2john
    ln -sf "$run_dir/john"         /usr/local/bin/john

    # Optional but handy: a few other *2john tools people usually want alongside it
    for tool in hccap2john zip2john rar2john ssh2john pdf2john.pl; do
        if [[ -e "$run_dir/$tool" ]]; then
            ln -sf "$run_dir/$tool" "/usr/local/bin/$tool"
        fi
    done

    log "Symlinks created."
}

sanity_check() {
    log "Verifying installation..."
    if command -v wpapcap2john >/dev/null 2>&1; then
        echo
        wpapcap2john -h || true
        echo
        log "All set. Try: wpapcap2john capture.pcap > hashes.txt"
    else
        die "wpapcap2john not found on PATH after install — something went wrong."
    fi
}

main() {
    require_root
    install_deps
    clone_repo
    build_john
    verify_binary
    install_symlinks
    sanity_check
}

main "$@"
