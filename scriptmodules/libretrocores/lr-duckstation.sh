#!/usr/bin/env bash
# This file is part of the RetroPie project
# DuckStation install script for RetroPie (Libretro core)
rp_module_id="lr-duckstation"
rp_module_desc="PlayStation 1 emulator - DuckStation (Libretro core)"
rp_module_help="ROM Extensions: .bin .cue .iso .img .chd .pbp .ecm\n\nCopy your PS1 ROMs to $romdir/psx\n\nFor best results, use CHD format for your games."
rp_module_licence="GPL3 https://github.com/stenzek/duckstation/blob/master/LICENSE"
rp_module_repo="git https://github.com/libretro/duckstation.git master"
rp_module_section="opt"
rp_module_flags="arm armv8 neon mesa gles"

function depends_lr-duckstation() {
    local depends=(
        git cmake build-essential
        libgles2-mesa-dev libgl1-mesa-dev
        libevdev-dev libvulkan-dev
        pkg-config libsdl2-dev
        libfmt-dev
    )
    getDepends "${depends[@]}"
}

function sources_lr-duckstation() {
    # Use the repository URL defined in rp_module_repo and shallow clone to avoid authentication issues
    gitPullOrClone "$md_build" "https://github.com/libretro/duckstation.git" "master" "" "--depth=1"
    
    # Apply patches or fixes if needed
    # None required at this time
}

function build_lr-duckstation() {
    # Clean any previous build
    rm -rf build
    mkdir -p build
    cd build
    
    # Set platform-specific build parameters
    local params=(
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_LIBRETRO_CORE=ON
        -DENABLE_VULKAN=OFF
    )
    
    # Platform-specific optimizations
    if isPlatform "armv8"; then
        params+=(-DCMAKE_C_FLAGS="-march=armv8-a+crc+simd -mtune=cortex-a53")
        params+=(-DCMAKE_CXX_FLAGS="-march=armv8-a+crc+simd -mtune=cortex-a53")
    fi
    
    # If on Raspberry Pi 4, enable GLES
    if isPlatform "rpi4"; then
        params+=(-DENABLE_GLES=ON)
    fi
    
    # Configure the build
    cmake .. "${params[@]}"
    
    # Build with multiple cores
    make -j$(nproc)
    
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
    ensureSystemretroconfig "psx"
    
    # Create BIOS directory and provide information
    mkUserDir "$biosdir/psx"
    
    # RetroArch specific settings for DuckStation
    local config="$configdir/psx/retroarch.cfg"
    iniConfig " = " "" "$config"
    
    # Graphics settings
    iniSet "video_smooth" "false"
    iniSet "video_shader_enable" "false"
    
    # Performance settings
    iniSet "video_threaded" "true"
    iniSet "video_refresh_rate" "60.0"
    
    # Core-specific settings
    iniSet "duckstation_GPU.Renderer" "opengl"
    iniSet "duckstation_GPU.ResolutionScale" "1"
    iniSet "duckstation_GPU.UseGeometryShader" "false"
    iniSet "duckstation_CPU.ExecutionMode" "1"  # JIT Recompiler
    iniSet "duckstation_Main.ShowFPS" "false"
    
    # Add DuckStation as an emulator option (priority 0 means it's not the default)
    addEmulator 0 "$md_id" "psx" "$md_inst/duckstation_libretro.so"
    addSystem "psx"
    
    # Add helpful information about BIOS files
    echo "DuckStation libretro core has been installed."
    echo ""
    echo "For best performance, copy your PlayStation BIOS files to $biosdir/psx:"
    echo "- scph5500.bin (JP BIOS)"
    echo "- scph5501.bin or scph7003.bin (US BIOS)"
    echo "- scph5502.bin (EU BIOS)"
}
