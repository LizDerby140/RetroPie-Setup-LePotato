#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="micropolis"
rp_module_desc="Micropolis - Open Source City Building Game"
rp_module_licence="GPL https://raw.githubusercontent.com/SimHacker/micropolis/wiki/License.md"
rp_module_section="opt"
rp_module_flags="lepotato 64bit aarch64 arm mali"

function depends_micropolis() {
    ! isPlatform "x11" getDepends xorg matchbox-window-manager
}

function install_bin_micropolis() {
    aptInstall micropolis
}

function remove_micropolis() {
    aptRemove micropolis
}

function configure_micropolis() {
    local binary="/usr/games/micropolis"
    ! isPlatform "x11" && binary="XINIT-WMC:/usr/games/micropolis"

    addPort "$md_id" "micropolis" "Micropolis" "$binary"
}
