#!/usr/bin/env bash

rp_module_id="duckstation"
rp_module_desc="Duckstation - PlayStation Emulator"
rp_module_help="ROM Extensions: .iso .bin .img .eboot .pbp\n\nCopy your PlayStation ROMs to $romdir/psx"
rp_module_licence="GPL3 https://raw.githubusercontent.com/stenzek/duckstation/master/LICENSE"
rp_module_repo="git https://github.com/stenzek/duckstation.git master"
rp_module_section="opt"
rp_module_flags=""

function depends_duckstation() {
    getDepends cmake gcc g++ libx11-dev libgl1-mesa-dev libevdev-dev libudev-dev
}

function sources_duckstation() {
    gitPullOrClone
}

function build_duckstation() {
    mkdir -p build
    cd build
    cmake ..
    make
    md_ret_require="$md_build/bin/duckstation-qt"
}

function install_duckstation() {
    md_ret_files=(
        'bin/duckstation-qt'
    )
}

function configure_duckstation() {
    mkRomDir "psx"
    addEmulator 1 "$md_id" "psx" "$md_inst/duckstation-qt %ROM%"
    addSystem "psx"
}
