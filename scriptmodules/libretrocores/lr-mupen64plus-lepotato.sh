#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-mupen64plus-lepotato"
rp_module_desc="N64 emu - Mupen64Plus + GLideN64 for libretro (Le Potato optimized)"
rp_module_help="ROM Extensions: .z64 .n64 .v64\n\nCopy your N64 roms to $romdir/n64"
rp_module_licence="GPL2 https://raw.githubusercontent.com/libretro/mupen64plus-libretro/master/LICENSE"
rp_module_repo="git https://github.com/RetroPie/mupen64plus-libretro.git master"
rp_module_section="opt"
rp_module_flags="arm armv8 neon mesa gles"

function depends_lr-mupen64plus-lepotato() {
    local depends=(flex bison libpng-dev)
    isPlatform "mesa" && depends+=(libgles2-mesa-dev)
    getDepends "${depends[@]}"
}

function sources_lr-mupen64plus-lepotato() {
    gitPullOrClone

    # mesa workaround; see: https://github.com/libretro/libretro-common/issues/98
    if hasPackage libgles2-mesa-dev 18.2 ge; then
        applyPatch "$md_data/0001-eliminate-conflicting-typedefs.patch"
    fi
    
    # Clone and build GLideN64
    git clone --depth 1 https://github.com/gonetz/GLideN64.git "$md_build/GLideN64"
    cd "$md_build/GLideN64"
    make clean
    make -j$(nproc)
    cd "$md_build"
}

function build_lr-mupen64plus-lepotato() {
    rpSwap on 750
    local params=()
    
    # Set platform to mesa for Le Potato
    params+=(platform="unix-armv")
    
    # Enable appropriate ARM optimizations
    params+=(WITH_DYNAREC=arm)
    params+=(HAVE_NEON=1)
    
    # Set GLES mode based on device capability
    if isPlatform "gles3"; then
        params+=(FORCE_GLES3=1)
    else
        params+=(FORCE_GLES=1)
    fi
    
    # Le Potato specific build parameters
    params+=(ARCH=arm64)
    params+=(HAVE_PARALLEL_RSP=1)
    params+=(HAVE_THR_AL=1)
    
    make clean
    make "${params[@]}"
    rpSwap off
    md_ret_require="$md_build/mupen64plus_libretro.so"
}

function install_lr-mupen64plus-lepotato() {
    md_ret_files=(
        'mupen64plus_libretro.so'
        'LICENSE'
        'README.md'
        'BUILDING.md'
    )
    # Install GLideN64 to the appropriate directory
    cp "$md_build/GLideN64/GLideN64.so" "$md_inst"
}

function configure_lr-mupen64plus-lepotato() {
    mkRomDir "n64"
    defaultRAConfig "n64"
    
    # Add custom configurations for Le Potato performance
    local config="$configdir/n64/retroarch.cfg"
    iniConfig " = " "" "$config"
    iniSet "video_smooth" "false"
    iniSet "video_shader_enable" "false"
    
    # Use GLideN64 as the video driver
    iniSet "video_driver" "glcore"  # Set OpenGL driver
    iniSet "video_plugin" "$md_inst/GLideN64.so"  # Set GLideN64 plugin

    # Optimize threading for Le Potato
    iniSet "video_threaded" "true"
    iniSet "video_refresh_rate" "60.0"
    
    # Add emulator and system
    addEmulator 0 "$md_id" "n64" "$md_inst/mupen64plus_libretro.so"
    addSystem "n64"
}
