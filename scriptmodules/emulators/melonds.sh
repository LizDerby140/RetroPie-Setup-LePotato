#!/usr/bin/env bash

rp_module_id="melonds"
rp_module_desc="MelonDS - Nintendo DS Emulator"
rp_module_help="ROM Extensions: .nds\n\nCopy your Nintendo DS ROMs to $romdir/nds"
rp_module_licence="GPL3 https://raw.githubusercontent.com/melonDS-emu/melonDS/master/LICENSE"
rp_module_repo="git https://github.com/melonDS-emu/melonDS.git master"
rp_module_section="opt"
rp_module_flags=""

function depends_melonds() {
    getDepends cmake gcc g++ libx11-dev libgl1-mesa-dev libevdev-dev libudev-dev libpcap-dev \
               libgbm-dev libdrm-dev
}

function sources_melonds() {
    gitPullOrClone
}

function build_melonds() {
    mkdir -p build
    cd build
    cmake -DPLATFORM_FLAGS="-D MESA -D GLES -D KMS -D DRM" ..
    make
    md_ret_require="$md_build/melonDS"
}

function install_melonds() {
    md_ret_files=(
        'melonDS'
    )
}

function configure_melonds() {
    mkRomDir "nds"
    addEmulator 1 "$md_id" "nds" "$md_inst/melonDS %ROM%"
    addSystem "nds"
}
