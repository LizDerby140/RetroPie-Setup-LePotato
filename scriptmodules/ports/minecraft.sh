#!/usr/bin/env bash
# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
rp_module_id="minecraft"
rp_module_desc="Minecraft - Pi Edition (LePotato port)"
rp_module_licence="PROP"
rp_module_section="exp"
rp_module_flags="!all mesa gles drm kms"

function depends_minecraft() {
    getDepends xorg matchbox-window-manager mesa-utils libgles2-mesa-dev
}

function install_bin_minecraft() {
    [[ -f "$md_inst/minecraft-pi" ]] && rm -rf "$md_inst/"*
    
    # Since we can't use the Pi package directly, we need to get a compatible build
    # or build from source for LePotato/Amlogic hardware
    
    # Create directory for Minecraft files
    mkdir -p "$md_inst"
    
    # Download MCPI-Reborn which has better compatibility with non-Pi hardware
    gitPullOrClone "$md_inst/mcpi-reborn" "https://github.com/MCPI-Revival/minecraft-pi-reborn.git"
    
    # Build MCPI-Reborn
    cd "$md_inst/mcpi-reborn"
    apt-get update
    getDepends cmake g++ libglfw3-dev
    mkdir -p build
    cd build
    cmake ..
    make -j$(nproc)
    
    # Copy the executable to our install directory
    cp "$md_inst/mcpi-reborn/build/src/minecraft-pi-reborn/minecraft-pi" "$md_inst/"
    
    # Create a launcher script with appropriate environment variables for Mesa/GLES
    cat > "$md_inst/minecraft-pi-launcher.sh" << _EOF_
#!/bin/bash
export MESA_GL_VERSION_OVERRIDE=2.1
export LIBGL_ALWAYS_SOFTWARE=1
cd "$md_inst"
./minecraft-pi
_EOF_
    
    chmod +x "$md_inst/minecraft-pi-launcher.sh"
}

function remove_minecraft() {
    rm -rf "$md_inst"
}

function configure_minecraft() {
    addPort "$md_id" "minecraft" "Minecraft" "XINIT-WM:$md_inst/minecraft-pi-launcher.sh"
}
