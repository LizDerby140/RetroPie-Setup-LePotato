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
    local depends=(
        build-essential cmake extra-cmake-modules git pkg-config
        libsdl2-dev libepoxy-dev libegl1-mesa-dev libgles2-mesa-dev
        libdrm-dev libgbm-dev libxrandr-dev
        libevdev-dev libudev-dev libpulse-dev
        libsamplerate0-dev libcurl4-openssl-dev libzip-dev
        qtbase5-dev qtbase5-private-dev qtbase5-dev-tools libqt5widgets5
    )
    
    getDepends "${depends[@]}"
    
    # Check if we're on a Libre Le Potato
    if grep -q "Libre Computer Board AML-S905X-CC" /proc/device-tree/model 2>/dev/null; then
        printMsgs "console" "Detected Libre Computer Le Potato. Building with optimized settings."
    else
        printMsgs "console" "Warning: This module is optimized for Libre Le Potato."
        printMsgs "console" "Your device: $(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")"
    fi
}

function sources_duckstation() {
    gitPullOrClone "$md_build"
    git -C "$md_build" submodule update --init
}

function build_duckstation() {
    cd "$md_build"
    
    # Create build directory
    mkdir -p build
    cd build
    
    # Configure build with Mesa GLES, KMS, and DRM support
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
        -DUSE_GLES2=ON
    
    # Build
    make -j$(nproc)
    
    # Add verbose logging to help debug build issues
    printMsgs "console" "Build completed. Checking for binary files..."
    find "$md_build/build/bin" -type f -executable -print || true
}

function install_duckstation() {
    # Instead of using md_ret_files, manually install the files
    # This provides more flexibility if file paths change
    
    # First check if the binaries exist
    if [[ ! -f "$md_build/build/bin/duckstation-qt" ]]; then
        # Look for the qt binary in alternate locations
        local qt_binary=$(find "$md_build" -name "duckstation-qt" -type f -executable | head -n 1)
        
        if [[ -n "$qt_binary" ]]; then
            printMsgs "console" "Found duckstation-qt binary at alternate location: $qt_binary"
            # Create bin directory if it doesn't exist
            mkdir -p "$md_inst/bin"
            # Copy the binary and set permissions
            cp "$qt_binary" "$md_inst/bin/"
            chmod +x "$md_inst/bin/duckstation-qt"
        else
            md_ret_errors+=("Could not find duckstation-qt binary. Build may have failed.")
            return 1
        fi
    else
        # Create bin directory
        mkdir -p "$md_inst/bin"
        
        # Copy DuckStation binaries
        cp "$md_build/build/bin/duckstation-qt" "$md_inst/bin/"
        chmod +x "$md_inst/bin/duckstation-qt"
        
        if [[ -f "$md_build/build/bin/duckstation-nogui" ]]; then
            cp "$md_build/build/bin/duckstation-nogui" "$md_inst/bin/"
            chmod +x "$md_inst/bin/duckstation-nogui"
        else
            printMsgs "console" "duckstation-nogui binary not found, skipping."
        fi
    fi
    
    # Copy resources
    if [[ -d "$md_build/build/bin/resources" ]]; then
        cp -r "$md_build/build/bin/resources" "$md_inst/"
    elif [[ -d "$md_build/resources" ]]; then
        cp -r "$md_build/resources" "$md_inst/"
    else
        printMsgs "console" "Resources directory not found in expected locations."
        # Try to find resources directory
        local resources_dir=$(find "$md_build" -name "resources" -type d | head -n 1)
        if [[ -n "$resources_dir" ]]; then
            printMsgs "console" "Found resources at: $resources_dir"
            cp -r "$resources_dir" "$md_inst/"
        fi
    fi
    
    # Create BIOS directory
    mkUserDir "$biosdir/duckstation"
    
    # Create settings directory
    mkUserDir "$home/.local/share/duckstation"
    ln -sf "$biosdir/duckstation" "$home/.local/share/duckstation/bios"
}

function configure_duckstation() {
    mkRomDir "psx"
    
    # Create wrapper scripts to launch duckstation with proper paths
    cat > "$md_inst/duckstation.sh" << _EOF_
#!/bin/bash
cd "$md_inst"
./bin/duckstation-qt "\$@"
_EOF_

    cat > "$md_inst/duckstation-nogui.sh" << _EOF_
#!/bin/bash
cd "$md_inst"
if [[ -f "./bin/duckstation-nogui" ]]; then
    ./bin/duckstation-nogui "\$@"
else
    echo "duckstation-nogui binary not found. Using GUI version instead."
    ./bin/duckstation-qt "\$@"
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
