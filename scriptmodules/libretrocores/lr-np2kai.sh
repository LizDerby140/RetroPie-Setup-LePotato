#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-np2kai"
rp_module_desc="PC98 emu - Modified Neko Project II port for libretro"
rp_module_help="ROM Extensions: .d88 .d98 .88d .98d .fdi .xdf .hdm .dup .2hd .tfd .hdi .thd .nhd .hdd\n\nCopy your pc98 games to to $romdir/pc98\n\nCopy bios files 2608_bd.wav, 2608_hh.wav, 2608_rim.wav, 2608_sd.wav, 2608_tom.wav 2608_top.wav, bios.rom, FONT.ROM and sound.rom to $biosdir/np2kai"
rp_module_licence="MIT https://raw.githubusercontent.com/libretro/NP2kai/master/LICENSE"
rp_module_repo="git https://github.com/AZO234/NP2kai.git master 701092a"
rp_module_section="exp"

function sources_lr-np2kai() {
    gitPullOrClone
}

function build_lr-np2kai() {
    cd "$md_build/sdl"
    make -f Makefile.libretro clean GIT_TAG="master"
    make -f Makefile.libretro GIT_TAG="master"
    md_ret_require="$md_build/sdl/np2kai_libretro.so"
}

function install_lr-np2kai() {
    md_ret_files=(
        'sdl/np2kai_libretro.so'
    )
}

function configure_lr-np2kai() {
    mkRomDir "pc98"
    defaultRAConfig "pc98"

    addEmulator 1 "$md_id" "pc98" "$md_inst/np2kai_libretro.so"
    addSystem "pc98"
}
