#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="melonds"
rp_module_desc="MelonDS Nintendo DS Emulator"
rp_module_help="ROM Extension: .nds .zip\n\nCopy your Nintendo DS games to $romdir/nds"
rp_module_licence="GPL3 https://github.com/melonDS-emu/melonDS/blob/master/LICENSE"
rp_module_repo="git https://github.com/melonDS-emu/melonDS.git"
rp_module_section="opt"
rp_module_flags=""

function depends_melonds() {
    local depends=(cmake g++ libsdl2-dev libpng-dev zlib1g-dev libsqlite3-dev)

    getDepends "${depends[@]}"
}

function sources_melonds() {
    gitPullOrClone
}

function build_melonds() {
    local platform="$__platform"

    # Prepare the build environment
    mkdir -p "$md_build"
    cd "$md_build"

    # Run cmake to configure the build
    cmake "$md_build" -DCMAKE_INSTALL_PREFIX="$md_inst"

    # Compile the emulator
    make clean
    make

    # Set required paths and libraries
    md_ret_require="$md_inst/bin/melonDS"
}

function install_melonds() {
    md_ret_files=(
        'bin/melonDS'
        'share'
    )
}

function configure_melonds() {
    # Add the emulator to the RetroPie configuration
    addEmulator 1 "melonds" "nds" "$md_inst/bin/melonDS %ROM%"
    addSystem "nds"

    [[ "$md_mode" == "remove" ]] && return

    # Create a directory for the games
    mkRomDir "nds"

    # Create default configuration directory
    mkUserDir "$md_conf_root/nds"

    # Set up a default configuration file if it doesn't exist
    if [[ ! -f "$md_conf_root/nds/melonds.conf" ]]; then
        echo "Creating default melonds.conf"
        echo "[config]" > "$md_conf_root/nds/melonds.conf"
        echo "screen_scaling=2" >> "$md_conf_root/nds/melonds.conf"
    fi

    # Symlink the configuration file for RetroPie
    ln -sf "$configdir/all/retroarch/autoconfig" "$md_inst/controllers"
    ln -sf "$configdir/all/retroarch.cfg" "$md_inst/conf/retroarch.cfg"

    chown -R "$__user":"$__group" "$md_inst"
    chown -R "$__user":"$__group" "$md_conf_root/nds"
}
