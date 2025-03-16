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
rp_module_desc="Minecraft - Pi Edition (with GL4ES)"
rp_module_licence="PROP"
rp_module_section="exp"
rp_module_flags="!all"

function depends_minecraft() {
    getDepends xorg matchbox-window-manager
}

function install_bin_minecraft() {
    # Download Minecraft Pi Edition since it's not in Armbian repos
    mkdir -p "$md_inst"
    wget -O "$md_inst/minecraft-pi.tar.gz" https://github.com/adafruit/Raspberry-Pi-Installer-Scripts/raw/master/minecraft-pi/minecraft-pi.tar.gz
    tar -xvf "$md_inst/minecraft-pi.tar.gz" -C "$md_inst"
    rm "$md_inst/minecraft-pi.tar.gz"

    # Symlink GL4ES to force compatibility
    ln -sf /usr/local/lib/libGL.so.1 "$md_inst/lib/arm-linux-gnueabihf/libGL.so"
}

function remove_minecraft() {
    rm -rf "$md_inst"
}

function configure_minecraft() {
    addPort "$md_id" "minecraft" "Minecraft" "XINIT-WM:/usr/local/lib/gl4es/gl4es /usr/bin/minecraft-pi"
}
