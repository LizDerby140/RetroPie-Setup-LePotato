#!/usr/bin/env bash

rp_module_id="swanstation"
rp_module_desc="SwanStation - PlayStation Emulator"
rp_module_help="ROM Extensions: .iso .bin .img .pbp\n\nCopy your PlayStation ROMs to $romdir/psx"
rp_module_licence="GPL3 https://raw.githubusercontent.com/x-station/x-station/master/LICENSE"
rp_module_repo="git https://github.com/x-station/x-station.git master"
rp_module_section="opt"
rp_module_flags=""

function depends_swanstation() {
    getDepends cmake gcc g++ libx11-dev libgl1-mesa-dev libevdev-dev libudev-dev \
               libgbm-dev libdrm-dev
}

function sources_swanstation() {
    gitPullOrClone
}

function build_swanstation() {
    mkdir -p build
    cd build
    cmake -DPLATFORM_FLAGS="-D MESA -D GLES -D KMS -D DRM" ..
    make
    md_ret_require="$md_build/swanstation-qt"
}

function install_swanstation() {
    md_ret_files=(
        'swanstation-qt'
    )
}

function configure_swanstation() {
    mkRomDir "psx"
    addEmulator 1 "$md_id" "psx" "$md_inst/swanstation-qt %ROM%"
    addSystem "psx"
}
