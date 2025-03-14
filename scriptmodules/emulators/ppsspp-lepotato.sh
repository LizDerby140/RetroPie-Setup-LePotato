#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="ppsspp-lepotato"
rp_module_desc="PlayStation Portable emulator - PPSSPP (optimized for Le Potato)"
rp_module_help="Play your PSP games with PPSSPP\n\nROM Extension: .iso, .cso, .elf\n\nPlace your PSP ROMs in $romdir/psp"
rp_module_licence="GPL2 https://github.com/hrydgard/ppsspp/blob/master/LICENSE.txt"
rp_module_repo="git https://github.com/hrydgard/ppsspp.git master"
rp_module_section="exp"

function depends_ppsspp() {
    local depends=(
        libsdl2-dev
        libgles2-mesa-dev
        libssl-dev
        libzip-dev
        libaudiofile-dev
        build-essential
        cmake
        git
    )
    getDepends "${depends[@]}"
}

function sources_ppsspp() {
    gitPullOrClone
}

function build_ppsspp() {
    cd "$md_build"
    
    # Create optimized Makefile for Le Potato (AML-S905X-CC)
    local params=(
        -DCMAKE_BUILD_TYPE=Release
        -DUSER_CPP_FLAGS="-march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard"
        -DUSER_C_FLAGS="-O2 -ffunction-sections -fdata-sections -fno-stack-protector"
        -DGLES2=ON
        -DOPENAL=OFF
        -DUSE_GLES3=ON
        -DUSE_PIE=ON
        -DCMAKE_INSTALL_PREFIX="$md_inst"
    )
    
    # Build the project using cmake and make
    mkdir -p build
    cd build
    cmake .. "${params[@]}"
    make -j"$(nproc)"
    md_ret_require="$md_build/build/ppsspp"
}

function install_ppsspp() {
    make install
    md_ret_files=(
        'bin/ppsspp'
        'assets/ppsspp_config.ini'
    )
}

function configure_ppsspp() {
    local def=1
    
    # Create directories for ROMs
    mkRomDir "psp"
    defaultRAConfig "psp"
    
    # Le Potato specific optimizations
    if grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
        # Apply optimal RetroArch settings for this system on Le Potato
        ensureRetroArchConfig
        
        # Set video and audio options for better performance
        setRetroArchCoreOption "video_threaded" "true"
        setRetroArchCoreOption "video_smooth" "false"
        setRetroArchCoreOption "audio_sync" "false"
        setRetroArchCoreOption "audio_rate_control" "false"
        
        # PPSSPP-specific core options
        setRetroArchCoreOption "ppsspp-frameskip" "1"
        setRetroArchCoreOption "ppsspp-cpu-speed-adjust" "100"
    fi

    addEmulator $def "$md_id" "psp" "$md_inst/ppsspp"
    
    # Create any additional necessary directories for PPSSPP support
    mkUserDir "$biosdir/ppsspp"
    cp "$md_inst/assets/ppsspp_config.ini" "$configdir/all/ppsspp_config.ini"
    
    # Configure other necessary files and settings for PPSSPP
    chown "$__user":"$__group" "$configdir/all/ppsspp_config.ini"
}
