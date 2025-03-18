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
rp_module_desc="DuckStation - PlayStation Emulator"
rp_module_help="ROM Extensions: .iso .bin .img .pbp\n\nCopy your PlayStation ROMs to $romdir/psx"
rp_module_licence="GPL3 https://raw.githubusercontent.com/stenzek/duckstation/master/LICENSE"
rp_module_repo="git https://github.com/stenzek/duckstation.git master"
rp_module_section="opt"
rp_module_flags="arm mesa gles kms drm"

function depends_duckstation() {
    getDepends cmake gcc g++ libx11-dev \
               libgl1-mesa-dev libevdev-dev \
               libudev-dev libgbm-dev libdrm-dev \
               libsdl2-dev libgles2-mesa-dev libxrandr-dev qtbase5-dev
}

function sources_duckstation() {
    gitPullOrClone
}

function build_duckstation() {
    mkdir -p build
    cd build
    cmake .. \
        -DUSE_GLES=ON \
        -DUSE_EGL=ON \
        -DUSE_KMSDRM=ON \
        -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc)
    md_ret_require="$md_build/build/bin/duckstation-qt"
}

function install_duckstation() {
    md_ret_files=(
        'build/bin/duckstation-qt'
        'build/bin/duckstation-cli'
        'README.md'
        'LICENSE'
    )
}

function configure_duckstation() {
    mkRomDir "psx"

    # Add GUI and CLI options for flexibility
    addEmulator 1 "$md_id-qt" "psx" "$md_inst/duckstation-qt %ROM%"
    addEmulator 0 "$md_id-cli" "psx" "$md_inst/duckstation-cli --fullscreen --execute %ROM%"

    addSystem "psx"

    # Custom launcher script for runcommand support
    cat > "$md_inst/duckstation.sh" << _EOF_
#!/bin/bash
"$md_inst/duckstation-cli" --fullscreen --execute "\$1"
_EOF_

    chmod +x "$md_inst/duckstation.sh"
    chown "$__user":"$__group" "$md_inst/duckstation.sh"

    # Optional: Add the launcher to EmulationStation as a menu option
    local script="+Start DuckStation.sh"
    cat > "$romdir/psx/$script" << _EOF_
#!/bin/bash
"$md_inst/duckstation.sh"
_EOF_

    chmod +x "$romdir/psx/$script"
    chown "$__user":"$__group" "$romdir/psx/$script"
} 
