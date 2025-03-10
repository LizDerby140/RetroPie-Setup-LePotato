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
rp_module_desc="Minecraft - Pi Edition"
rp_module_licence="PROP"
rp_module_section="exp"
rp_module_flags=""

function depends_minecraft() {
    getDepends xorg matchbox-window-manager
}

function install_bin_minecraft() {
    [[ -f "$md_inst/minecraft-pi" ]] && rm -rf "$md_inst/"*
    aptInstall minecraft-pi
}

function remove_minecraft() {
    aptRemove minecraft-pi
}

function configure_minecraft() {
    addPort "$md_id" "minecraft" "Minecraft" "XINIT-WM:/usr/bin/minecraft-pi"
}
