#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="redream"
rp_module_desc="Redream Dreamcast emulator"
rp_module_help="ROM Extensions: .cdi .cue .chd .gdi .iso\n\nCopy your Dreamcast roms to $romdir/dreamcast"
rp_module_licence="PROP"
rp_module_section="exp"
rp_module_flags=""

function __binary_url_redream() {
    local platf="universal-raspberry"
    isPlatform "x86_64" && platf="x86_64"
    local url="https://redream.io/download/redream.${platf}-linux-latest.tar.gz"

    echo "$url"
}

function install_bin_redream() {
    downloadAndExtract "$(__binary_url_redream)" "$md_inst"
}

function configure_redream() {
    mkRomDir "dreamcast"

    addEmulator 1 "$md_id" "dreamcast" "$md_inst/redream %ROM%"
    addSystem "dreamcast"

    [[ "$md_mode" == "remove" ]] && return

    chown -R "$__user":"$__group" "$md_inst"

    local dest="$md_conf_root/dreamcast/redream"
    mkUserDir "$dest"

    # symlinks configs and cache
    moveConfigFile "$md_inst/redream.cfg" "$dest/redream.cfg"
    moveConfigDir "$md_inst/cache" "$dest/cache"
    moveConfigDir "$md_inst/saves" "$dest/saves"
    moveConfigDir "$md_inst/states" "$dest/states"

    # copy / symlink vmus (memory cards)
    local i
    for i in 0 1 2 3; do
      moveConfigFile "$md_inst/vmu$i.bin" "$dest/vmu$i.bin"
    done

    # symlink bios files to libretro core install locations
    mkUserDir "$biosdir/dc"
    ln -sf "$biosdir/dc/dc_boot.bin" "$md_inst/boot.bin"
    ln -sf "$biosdir/dc/dc_flash.bin" "$md_inst/flash.bin"
}
