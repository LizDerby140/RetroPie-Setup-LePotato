#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="xrick"
rp_module_desc="xrick - Open source implementation of Rick Dangerous"
rp_module_help="Install the xrick data.zip to $romdir/ports/xrick/data.zip"
rp_module_licence="GPL https://raw.githubusercontent.com/RetroPie/xrick/master/README"
rp_module_repo="git https://github.com/RetroPie/xrick.git master"
rp_module_section="opt"
rp_module_flags=""

function depends_xrick() {
    getDepends libsdl1.2-dev libsdl-mixer1.2-dev libsdl-image1.2-dev zlib1g
}

function sources_xrick() {
    gitPullOrClone
}

function build_xrick() {
    make clean
    make
    md_ret_require="$md_build/xrick"
}

function install_xrick() {
    md_ret_files=(
        'README'
        'xrick'
    )
}

function configure_xrick() {
    addPort "$md_id" "xrick" "XRick" "$md_inst/xrick.sh -fullscreen" "$romdir/ports/xrick/data.zip"

    [[ "$md_mode" == "remove" ]] && return

    ln -sf "$romdir/ports/xrick/data.zip" "$md_inst/data.zip"
    # set dispmanx by default on rpi with fkms
    isPlatform "dispmanx" && ! isPlatform "videocore" && setBackend "$md_id" "dispmanx"
    # on KMS and without dispmanx, use sdl12-compat
    ! isPlatform "dispmanx" && isPlatform "kms" && setBackend "$md_id" "sdl12-compat"

    local file="$md_inst/xrick.sh"
    cat >"$file" << _EOF_
#!/usr/bin/env bash
pushd "$md_inst"
./xrick "\$@"
popd
_EOF_
    chmod +x "$file"
}
