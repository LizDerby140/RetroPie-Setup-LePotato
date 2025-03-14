#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="alephone"
rp_module_desc="AlephOne - Marathon Engine"
rp_module_help="To get the games running on the Raspberry Pi/Odroid, make sure to set each game to use the software renderer and disable the enhanced HUD from the Plugins menu. For Marathon 1, disable both HUDs from the Plugins menu, start a game, quit back to the title screen and enable Enhanced HUD and it will work and properly."
rp_module_licence="GPL3 https://raw.githubusercontent.com/Aleph-One-Marathon/alephone/master/COPYING"
rp_module_repo="git https://github.com/Aleph-One-Marathon/alephone.git :_get_branch_alephone"
rp_module_section="opt"
rp_module_flags=""

function _get_branch_alephone() {
    local branch="release-20150620"
    if [[ "$__os_debian_ver" -ge 9 ]] || [[ -n "$__os_ubuntu_ver" ]]; then
        branch="master"
    fi
    echo "$branch"
}

function depends_alephone() {
    local depends=(libboost-all-dev libspeexdsp-dev libzzip-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev autoconf automake libboost-system-dev libcurl4-openssl-dev autoconf-archive libopenal-dev libsndfile1-dev)
    if [[ "$__os_debian_ver" -ge 9 ]] || [[ -n "$__os_ubuntu_ver" ]]; then
        depends+=(libsdl2-dev libsdl2-net-dev libsdl2-image-dev libsdl2-ttf-dev libglu1-mesa-dev libgl1-mesa-dev)
    else
        depends+=(libsdl1.2-dev libsdl-net1.2-dev libsdl-image1.2-dev libsdl-ttf2.0-dev)
    fi
    getDepends "${depends[@]}"
}

function sources_alephone() {
    gitPullOrClone
}

function build_alephone() {
    params=(--prefix="$md_inst")
    isPlatform "arm" && params+=(--with-boost-libdir=/usr/lib/arm-linux-gnueabihf)

    # if building an older release, use autogen.sh otherwise use autoreconf
    if [[ -f "autogen.sh" ]]; then
        ./autogen.sh
    else
        autoreconf -iv
    fi

    ./configure "${params[@]}"
    make clean
    make
    md_ret_require="$md_build/Source_Files/alephone"
}

function install_alephone() {
    make install
}

function game_data_alephone() {
    local version="20150620"
    if [[ "$__os_debian_ver" -ge 9 ]] || [[ -n "$__os_ubuntu_ver" ]]; then
        version="20220115"
    fi
    local release_url="https://github.com/Aleph-One-Marathon/alephone/releases/download/release-$version"

    if [[ ! -f "$romdir/ports/$md_id/Marathon/Shapes.shps" ]]; then
        downloadAndExtract "$release_url/Marathon-$version-Data.zip" "$romdir/ports/$md_id"
    fi

    if [[ ! -f "$romdir/ports/$md_id/Marathon 2/Shapes.shpA" ]]; then
        downloadAndExtract "$release_url/Marathon2-$version-Data.zip" "$romdir/ports/$md_id"
    fi

    if [[ ! -f "$romdir/ports/$md_id/Marathon Infinity/Shapes.shpA" ]]; then
        downloadAndExtract "$release_url/MarathonInfinity-$version-Data.zip" "$romdir/ports/$md_id"
    fi

    chown -R "$__user":"$__group" "$romdir/ports/$md_id"
}

function configure_alephone() {
    addPort "$md_id" "alephone" "Aleph One Engine - Marathon" "$md_inst/bin/alephone %ROM%" "$romdir/ports/$md_id/Marathon/"
    addPort "$md_id" "alephone" "Aleph One Engine - Marathon 2" "$md_inst/bin/alephone %ROM%" "$romdir/ports/$md_id/Marathon 2/"
    addPort "$md_id" "alephone" "Aleph One Engine - Marathon Infinity" "$md_inst/bin/alephone %ROM%" "$romdir/ports/$md_id/Marathon Infinity/"

    mkRomDir "ports/$md_id"

    moveConfigDir "$home/.alephone" "$md_conf_root/alephone"
    # fix for wrong config location
    if [[ -d "/alephone" ]]; then
        cp -R /alephone "$md_conf_root/"
        rm -rf /alephone
        chown "$__user":"$__group" "$md_conf_root/alephone"
    fi

    [[ "$md_mode" == "install" ]] && game_data_alephone
}
