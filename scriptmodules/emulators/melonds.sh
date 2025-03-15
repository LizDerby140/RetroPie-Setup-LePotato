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
rp_module_help="ROM Extension: .nds .zip\n\nCopy your Nintendo DS games to $romdir/nds\n\nPlace firmware.bin, bios7.bin, and bios9.bin in $biosdir/nds"
rp_module_licence="GPL3 https://github.com/melonDS-emu/melonDS/blob/master/LICENSE"
rp_module_repo="git https://github.com/melonDS-emu/melonDS.git master"
rp_module_section="opt"
rp_module_flags="arm armv8"

function depends_melonds() {
    local depends=(
        cmake
        build-essential
        libsdl2-dev
        libpng-dev
        zlib1g-dev
        libsqlite3-dev
        pkg-config
        libcurl4-openssl-dev
        qtbase5-dev
        qtbase5-dev-tools
    )
    getDepends "${depends[@]}"
}

function sources_melonds() {
    gitPullOrClone "$md_build" "https://github.com/melonDS-emu/melonDS.git" "master" "" "--depth=1"
}

function build_melonds() {
    # Clear previous build files if they exist
    rm -rf builddir
    mkdir -p builddir
    cd builddir
    
    # Set optimized build flags for Le Potato
    if grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
        # Le Potato specific optimizations
        local CFLAGS="-O2 -march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard"
        local CXXFLAGS="$CFLAGS"
        export CFLAGS CXXFLAGS
        
        # Configure with optimized settings for Le Potato
        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="$md_inst" \
            -DBUILD_SHARED_LIBS=OFF \
            -DENABLE_WIFI=OFF \
            -DENABLE_JIT=ON \
            -DENABLE_OPENGL=OFF \
            -DENABLE_FRONTEND=ON
    else
        # Default configuration for other systems
        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="$md_inst" \
            -DBUILD_SHARED_LIBS=OFF \
            -DENABLE_WIFI=OFF \
            -DENABLE_JIT=ON
    fi
    
    # Build using available cores, but limit to 2 on low-memory devices
    local NUM_CORES=$(nproc)
    if [[ $NUM_CORES -gt 2 ]] && [[ $(free -m | awk '/^Mem:/{print $2}') -lt 1024 ]]; then
        make -j2
    else
        make -j$NUM_CORES
    fi
    
    md_ret_require="$md_build/builddir/melonDS"
}

function install_melonds() {
    cd builddir
    make install
    
    # Fallback if installation fails
    if [[ ! -f "$md_inst/bin/melonDS" ]]; then
        mkdir -p "$md_inst/bin"
        cp "melonDS" "$md_inst/bin/"
    fi
}

function configure_melonds() {
    # Create ROM directory
    mkRomDir "nds"
    
    # Create BIOS directory
    mkUserDir "$biosdir/nds"
    
    # Create config directories
    mkUserDir "$home/.config/melonDS"
    mkUserDir "$md_conf_root/nds"
    
    # Add the emulator to RetroPie
    addEmulator 1 "$md_id" "nds" "$md_inst/bin/melonDS %ROM%"
    addSystem "nds"
    
    [[ "$md_mode" == "remove" ]] && return
    
    # Create default configuration file if it doesn't exist
    if [[ ! -f "$home/.config/melonDS/melonDS.ini" ]]; then
        cat > "$home/.config/melonDS/melonDS.ini" << EOF
[BIOS]
DSiBIOSPath=$biosdir/nds/dsi_bios7.bin
DSiBIOSPathARM9=$biosdir/nds/dsi_bios9.bin
DSiBIOSPathNAND=$biosdir/nds/dsi_nand.bin
DSiSDCardSaveFile=
FirmwarePath=$biosdir/nds/firmware.bin
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
EOF
    fi
    
    # Le Potato specific optimizations for the config file
    if grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
        # Modify the default configuration for better performance on Le Potato
        iniConfig "=" "" "$home/.config/melonDS/melonDS.ini"
        
        # Lower 3D resolution for better performance
        iniSet "ScaleFactor" "0.5"
        
        # Use software rendering instead of OpenGL
        iniSet "Renderer" "0"
        
        # Enable JIT but with smaller block size for better stability
        iniSet "JIT_Enable" "1"
        iniSet "JIT_MaxBlockSize" "16"
        
        # Disable screen filtering to improve performance
        iniSet "ScreenFilter" "0"
    fi
    
    # Set permissions
    chown -R "$user:$user" "$home/.config/melonDS"
    chown -R "$user:$user" "$md_conf_root/nds"
    
    # Display help message
    echo
    echo "MelonDS has been installed successfully."
    echo
    echo "For best performance, place these BIOS files in $biosdir/nds:"
    echo "- firmware.bin (Nintendo DS firmware)"
    echo "- bios7.bin (Nintendo DS ARM7 BIOS)"
    echo "- bios9.bin (Nintendo DS ARM9 BIOS)"
    echo
    echo "Optional DSi files (for DSi enhanced games):"
    echo "- dsi_bios7.bin"
    echo "- dsi_bios9.bin"
    echo "- dsi_nand.bin"
    echo
    echo "On the Le Potato board, performance may be limited."
    echo "Consider lowering settings further in the melonDS configuration."
}
