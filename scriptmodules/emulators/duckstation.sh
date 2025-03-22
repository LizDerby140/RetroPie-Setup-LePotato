#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="duckstation"
rp_module_desc="DuckStation - PlayStation 1 Emulator (Optimized for Libre Le Potato)"
rp_module_help="ROM Extensions: .bin .cue .img .iso .chd .pbp .mdf .toc .cbn .m3u .disc\n\nCopy your PlayStation 1 roms to $romdir/psx\n\nCopy BIOS files to $biosdir/duckstation\nRecommended BIOS files: scph5500.bin (JP), scph5501.bin (US), scph5502.bin (EU)"
rp_module_licence="GPL3 https://raw.githubusercontent.com/stenzek/duckstation/master/LICENSE"
rp_module_repo="git https://github.com/stenzek/duckstation.git master"
rp_module_section="exp"
rp_module_flags="!mali !x86"

function depends_duckstation() {
    # Enhanced dependency list for DuckStation
    local depends=(
        build-essential cmake extra-cmake-modules git pkg-config
        libsdl2-dev libepoxy-dev libegl1-mesa-dev libgles2-mesa-dev
        libdrm-dev libgbm-dev libxrandr-dev
        libevdev-dev libudev-dev libpulse-dev
        libsamplerate0-dev libcurl4-openssl-dev libzip-dev
        qtbase5-dev qtbase5-private-dev qtbase5-dev-tools libqt5widgets5
        qt5-default libxkbcommon-dev libwayland-dev
    )
    
    getDepends "${depends[@]}"
    
    # Check if we're on a Libre Le Potato
    if grep -q "Libre Computer Board AML-S905X-CC" /proc/device-tree/model 2>/dev/null; then
        printMsgs "console" "Detected Libre Computer Le Potato. Building with optimized settings."
    else
        printMsgs "console" "Warning: This module is optimized for Libre Le Potato."
        printMsgs "console" "Your device: $(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")"
    fi

    # Check for required Qt version
    printMsgs "console" "Checking Qt version..."
    if command -v qmake >/dev/null; then
        local qt_version=$(qmake -v | grep -oP 'Qt version \K[0-9\.]+')
        printMsgs "console" "Found Qt version: $qt_version"
    else
        printMsgs "console" "qmake not found, Qt may not be properly installed"
    fi

    # Check for other dependencies
    printMsgs "console" "Checking for other dependencies..."
    for dep in cmake pkg-config; do
        if command -v $dep >/dev/null; then
            local version=$($dep --version | head -n1)
            printMsgs "console" "Found $dep: $version"
        else
            printMsgs "console" "WARNING: $dep not found!"
        fi
    done
}

function sources_duckstation() {
    gitPullOrClone "$md_build"
    
    # Print git information
    printMsgs "console" "Using DuckStation repo: $md_repo_url"
    local git_hash=$(git -C "$md_build" rev-parse HEAD)
    printMsgs "console" "Git hash: $git_hash"
    
    # Initialize and update submodules with more detailed output
    printMsgs "console" "Initializing submodules..."
    git -C "$md_build" submodule init
    git -C "$md_build" submodule update --recursive
    
    # List submodules
    printMsgs "console" "Submodules status:"
    git -C "$md_build" submodule status
}

function build_duckstation() {
    cd "$md_build"
    
    # Print working directory and available space
    printMsgs "console" "Working directory: $(pwd)"
    printMsgs "console" "Available disk space: $(df -h . | tail -n 1 | awk '{print $4}')"
    
    # Create build directory
    mkdir -p build
    cd build
    
    # Configure build with Mesa GLES, KMS, and DRM support
    printMsgs "console" "Running CMake configuration..."
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$md_inst" \
        -DBUILD_NOGUI_FRONTEND=ON \
        -DBUILD_QT_FRONTEND=ON \
        -DUSE_DRMKMS=ON \
        -DUSE_EGL=ON \
        -DUSE_WAYLAND=OFF \
        -DUSE_X11=OFF \
        -DUSE_SDL2=ON \
        -DUSE_OPENGL=OFF \
        -DUSE_GLES2=ON \
        -DCMAKE_VERBOSE_MAKEFILE=ON
    
    # Check CMake result
    if [ $? -ne 0 ]; then
        printMsgs "console" "CMake configuration failed!"
        # Show CMake error log if it exists
        if [ -f "CMakeFiles/CMakeError.log" ]; then
            printMsgs "console" "=== CMake Error Log ==="
            cat "CMakeFiles/CMakeError.log"
        fi
        return 1
    fi
    
    # Build with verbose output
    printMsgs "console" "Starting build process..."
    make -j$(nproc) VERBOSE=1
    
    # Check build result
    if [ $? -ne 0 ]; then
        printMsgs "console" "Build failed!"
        return 1
    fi
    
    # Check for binary files
    printMsgs "console" "Checking for output binaries..."
    if [ -d "bin" ]; then
        printMsgs "console" "Contents of bin directory:"
        ls -la bin/
    else
        printMsgs "console" "bin directory not found!"
        printMsgs "console" "Searching for DuckStation binaries in build directory..."
        find . -name "duckstation-qt" -o -name "duckstation-nogui" | while read file; do
            printMsgs "console" "Found: $file"
        done
    fi
    
    # Look for alternative binary locations
    printMsgs "console" "Searching for binaries in parent directories..."
    find "$md_build" -type f -name "duckstation-qt" -o -name "duckstation-nogui" | while read file; do
        printMsgs "console" "Found: $file"
    done
    
    # Try to determine output directory structure
    local build_dir_structure=$(find . -type d | sort)
    printMsgs "console" "Build directory structure:"
    echo "$build_dir_structure"
}

function install_duckstation() {
    printMsgs "console" "=== Starting installation process ==="
    
    # Create installation directories
    mkdir -p "$md_inst/bin"
    
    # Search for binaries
    printMsgs "console" "Searching for DuckStation binaries..."
    local qt_binary=$(find "$md_build" -type f -name "duckstation-qt" | head -n 1)
    local nogui_binary=$(find "$md_build" -type f -name "duckstation-nogui" | head -n 1)
    
    if [[ -n "$qt_binary" ]]; then
        printMsgs "console" "Found Qt binary: $qt_binary"
        cp "$qt_binary" "$md_inst/bin/"
        chmod +x "$md_inst/bin/duckstation-qt"
    else
        printMsgs "console" "ERROR: duckstation-qt binary not found!"
        
        # Fall back to pre-built binary if build fails
        printMsgs "console" "Attempting to download pre-built binary as fallback..."
        
        # Create a temporary directory
        local tmp_dir="$md_build/tmp_download"
        mkdir -p "$tmp_dir"
        cd "$tmp_dir"
        
        # Download pre-built binary for ARM
        wget -O duckstation-linux-arm64.tar.gz https://github.com/stenzek/duckstation/releases/download/latest/duckstation-linux-arm64.tar.gz
        
        if [ $? -eq 0 ]; then
            tar -xf duckstation-linux-arm64.tar.gz
            
            # Check if extraction produced the binary
            if [ -f "duckstation/bin/duckstation-qt" ]; then
                printMsgs "console" "Using pre-built binary as fallback"
                cp duckstation/bin/duckstation-qt "$md_inst/bin/"
                chmod +x "$md_inst/bin/duckstation-qt"
                
                if [ -f "duckstation/bin/duckstation-nogui" ]; then
                    cp duckstation/bin/duckstation-nogui "$md_inst/bin/"
                    chmod +x "$md_inst/bin/duckstation-nogui"
                fi
                
                # Copy resources
                if [ -d "duckstation/resources" ]; then
                    cp -r duckstation/resources "$md_inst/"
                fi
            else
                printMsgs "console" "Failed to extract pre-built binary"
                return 1
            fi
        else
            printMsgs "console" "Failed to download pre-built binary"
            return 1
        fi
    fi
    
    if [[ -n "$nogui_binary" ]]; then
        printMsgs "console" "Found NoGUI binary: $nogui_binary"
        cp "$nogui_binary" "$md_inst/bin/"
        chmod +x "$md_inst/bin/duckstation-nogui"
    fi
    
    # Search for resources directory
    printMsgs "console" "Searching for resources directory..."
    local resources_dir=$(find "$md_build" -type d -name "resources" | head -n 1)
    
    if [[ -n "$resources_dir" ]]; then
        printMsgs "console" "Found resources: $resources_dir"
        cp -r "$resources_dir" "$md_inst/"
    else
        printMsgs "console" "Resources directory not found in build"
        # If we're using pre-built binaries, resources should already be copied
    fi
    
    # Create BIOS directory
    printMsgs "console" "Creating BIOS directory..."
    mkUserDir "$biosdir/duckstation"
    
    # Create settings directory
    printMsgs "console" "Creating settings directory..."
    mkUserDir "$home/.local/share/duckstation"
    ln -sf "$biosdir/duckstation" "$home/.local/share/duckstation/bios"
    
    printMsgs "console" "Installation completed"
}

function configure_duckstation() {
    mkRomDir "psx"
    
    # Create wrapper scripts to launch duckstation with proper paths
    printMsgs "console" "Creating wrapper scripts..."
    cat > "$md_inst/duckstation.sh" << _EOF_
#!/bin/bash
cd "$md_inst"
if [[ -f "./bin/duckstation-qt" ]]; then
    ./bin/duckstation-qt "\$@"
else
    echo "Error: duckstation-qt binary not found!"
    exit 1
fi
_EOF_

    cat > "$md_inst/duckstation-nogui.sh" << _EOF_
#!/bin/bash
cd "$md_inst"
if [[ -f "./bin/duckstation-nogui" ]]; then
    ./bin/duckstation-nogui "\$@"
else
    echo "duckstation-nogui binary not found. Using GUI version instead."
    if [[ -f "./bin/duckstation-qt" ]]; then
        ./bin/duckstation-qt "\$@"
    else
        echo "Error: No DuckStation binaries found!"
        exit 1
    fi
fi
_EOF_

    chmod +x "$md_inst/duckstation.sh" "$md_inst/duckstation-nogui.sh"
    
    # Add the emulator to EmulationStation
    addEmulator 1 "$md_id" "psx" "$md_inst/duckstation.sh %ROM%"
    addEmulator 0 "${md_id}-nogui" "psx" "$md_inst/duckstation-nogui.sh %ROM%"
    
    # Make DuckStation the default PSX emulator
    addSystem "psx"
    
    # Create optimal settings for Le Potato
    local config_dir="$home/.local/share/duckstation"
    
    # Only create default settings if they don't exist yet
    if [[ ! -f "$config_dir/settings.ini" ]]; then
        mkdir -p "$config_dir"
        cat > "$config_dir/settings.ini" << _EOF_
[Main]
SettingsVersion = 1
ConfirmPowerOff = false

[Console]
Region = Auto

[GPU]
Renderer = OpenGLES
ResolutionScale = 2
UseDebugDevice = false
ThreadedPresentation = true
TrueColor = true
ScaledDithering = true
TextureFilter = Nearest
DownsampleMode = Disabled
DisableInterlacing = true
ForceNTSCTimings = false
WidescreenHack = false
PGXPEnable = false
PGXPCulling = true
PGXPTextureCorrection = true
PGXPVertexCache = false
PGXPCPU = false
PGXPPreserveProjFP = false

[Display]
ShowOSDMessages = true
ShowFPS = false
ShowSpeed = false
ShowVPS = false
ShowResolution = false
_EOF_
        chown $user:$user "$config_dir/settings.ini"
    fi

    # Verify installation
    printMsgs "console" "Verifying installation..."
    if [[ -f "$md_inst/bin/duckstation-qt" ]]; then
        printMsgs "console" "✓ duckstation-qt found at $md_inst/bin/duckstation-qt"
    else
        printMsgs "console" "✗ duckstation-qt not found!"
    fi
    
    if [[ -f "$md_inst/bin/duckstation-nogui" ]]; then
        printMsgs "console" "✓ duckstation-nogui found at $md_inst/bin/duckstation-nogui"
    else
        printMsgs "console" "ℹ duckstation-nogui not found, only GUI version will be available"
    fi
    
    if [[ -d "$md_inst/resources" ]]; then
        printMsgs "console" "✓ resources directory found at $md_inst/resources"
    else
        printMsgs "console" "✗ resources directory not found!"
    fi

    # Display setup instructions
    local custom_msg="
=== DuckStation for Libre Le Potato ===

DuckStation has been installed with optimized settings for GLES/DRM/KMS on the Libre Le Potato.

Key settings for optimal performance:
- Renderer: OpenGL (GLES)
- Resolution Scale: 2x (adjust down to 1x if performance issues)
- GPU Threaded Presentation: Enabled
- Settings are pre-configured for best performance

For BIOS files, place them in: $biosdir/duckstation
Recommended BIOS files: scph5500.bin (JP), scph5501.bin (US), scph5502.bin (EU)

DuckStation is now available in the PlayStation section of EmulationStation.
"
    printMsgs "console" "$custom_msg"
}

function remove_duckstation() {
    rm -rf "$home/.local/share/duckstation"
    delSystem psx duckstation
    delSystem psx "${md_id}-nogui"
}
