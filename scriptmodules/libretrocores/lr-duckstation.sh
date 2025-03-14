#!/usr/bin/env bash

# This file is part of the RetroPie project
# DuckStation install script for RetroPie (Libretro core)

rp_module_id="lr-duckstation"
rp_module_desc="PlayStation 1 emulator - DuckStation (Libretro core)"
rp_module_help="ROM Extensions: .bin .cue .iso .img\n\nCopy your PS1 ROMs to $romdir/psx"
rp_module_licence="GPL2 https://github.com/stenzek/duckstation/blob/master/LICENSE"
rp_module_repo="git https://github.com/libretro/duckstation.git master"
rp_module_section="opt"
rp_module_flags="arm armv8 neon mesa gles"

function depends_lr-duckstation() {
    local depends=(git cmake build-essential libgles2-mesa-dev libevdev-dev libvulkan-dev)
    getDepends "${depends[@]}"
}

function sources_lr-duckstation() {
    gitPullOrClone
}

function build_lr-duckstation() {
    local params=()
    # Set platform to ARMv8 for RetroPie
    params+=( -DCMAKE_BUILD_TYPE=Release )
    params+=( -DENABLE_VULKAN=ON )  # Enable Vulkan support (optional, depending on the platform)
    params+=( -DENABLE_GLES=ON )  # Enable GLES for ARM platforms

    # Build the core
    mkdir -p build
    cd build
    cmake ..
    make -j$(nproc)
    cd ..
    
    md_ret_require="$md_build/build/duckstation_libretro.so"
}

function install_lr-duckstation() {
    md_ret_files=(
        'build/duckstation_libretro.so'
        'LICENSE'
        'README.md'
    )
}

function configure_lr-duckstation() {
    mkRomDir "psx"
    defaultRAConfig "psx"
    
    # RetroArch specific settings for DuckStation
    local config="$configdir/psx/retroarch.cfg"
    iniConfig " = " "" "$config"
    iniSet "video_smooth" "false"
    iniSet "video_shader_enable" "false"
    
    # Enable threading and set video mode for performance
    iniSet "video_threaded" "true"
    iniSet "video_refresh_rate" "60.0"
    
    # Add DuckStation as the emulator for PS1
    addEmulator 0 "$md_id" "psx" "$md_inst/duckstation_libretro.so"
    addSystem "psx"
}
