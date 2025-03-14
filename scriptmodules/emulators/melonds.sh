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
    local depends=(cmake g++ libsdl2-dev libpng-dev zlib1g-dev libsqlite3-dev pkg-config libcurl4-openssl-dev)
    getDepends "${depends[@]}"
}

function sources_melonds() {
    # Use shallow clone to avoid authentication issues
    gitPullOrClone "" "" "" "" "--depth=1"
}

function build_melonds() {
    # Create a build directory
    mkdir -p builddir
    cd builddir
    
    # Configure with proper flags and disable features that might cause issues
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$md_inst" \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_WIFI=OFF \
        -DENABLE_JIT=ON
    
    # Build with multiple cores for speed
    make -j$(nproc)
    
    # Set the required file for checking successful build
    md_ret_require="$md_build/builddir/melonDS"
}

function install_melonds() {
    cd builddir
    make install
    
    # Fall back to copying the binary directly if make install fails
    if [[ ! -f "$md_inst/bin/melonDS" ]]; then
        mkdir -p "$md_inst/bin"
        cp "melonDS" "$md_inst/bin/"
    fi
}

function configure_melonds() {
    # Add the emulator to the RetroPie configuration
    addEmulator 1 "melonds" "nds" "$md_inst/bin/melonDS %ROM%"
    addSystem "nds"
    
    [[ "$md_mode" == "remove" ]] && return
    
    # Create a directory for the games
    mkRomDir "nds"
    
    # Create user config directory
    mkUserDir "$home/.config/melonDS"
    
    # Create default configuration directory
    mkUserDir "$md_conf_root/nds"
    
    # Create a basic configuration file if it doesn't exist
    if [[ ! -f "$home/.config/melonDS/melonDS.ini" ]]; then
        echo "Creating default melonDS.ini"
        cat > "$home/.config/melonDS/melonDS.ini" << _EOF_
[BIOS]
DSiBIOSPath=/home/pi/RetroPie/BIOS/dsi_bios7.bin
DSiBIOSPathARM9=/home/pi/RetroPie/BIOS/dsi_bios9.bin
DSiBIOSPathNAND=/home/pi/RetroPie/BIOS/dsi_nand.bin
DSiBIOSPathSDCard=
DSiSDCardSaveFile=
FirmwarePath=/home/pi/RetroPie/BIOS/firmware.bin

[NDS]
DirectBoot=1
JIT_Enable=1
JIT_MaxBlockSize=32
ScreenRotation=0
ScreenSwap=0
ScreenSizing=1
ScreenFilter=1
ScreenAspectTop=0
ScreenAspectBot=0
ScreenGap=0
IntegerScaling=0
ShowFPS=0

[3D]
Renderer=1
ScaleFactor=1
_EOF_
    fi
    
    # Set permissions
    chown -R "$__user":"$__group" "$home/.config/melonDS"
    chown -R "$__user":"$__group" "$md_inst"
    chown -R "$__user":"$__group" "$md_conf_root/nds"
    
    # Add a message about BIOS files
    echo "MelonDS installed successfully. For best experience, copy the following BIOS files to $biosdir:"
    echo "- firmware.bin (Nintendo DS firmware)"
    echo "- dsi_bios7.bin, dsi_bios9.bin, dsi_nand.bin (optional, for DSi emulation)"
}
