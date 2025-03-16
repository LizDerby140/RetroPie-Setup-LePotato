#!/usr/bin/env bash

rp_module_id="bsnes"
rp_module_desc="bsnes - Super Nintendo Entertainment System (SNES) Emulator"
rp_module_help="ROM Extensions: .smc .sfc\n\nCopy your SNES ROMs to $romdir/snes"
rp_module_licence="GPL3 https://raw.githubusercontent.com/bsnes-emu/bsnes/master/LICENSE"
rp_module_repo="git https://github.com/bsnes-emu/bsnes.git master"
rp_module_section="opt"
rp_module_flags=""

function depends_bsnes() {
    getDepends cmake gcc g++ libx11-dev libgl1-mesa-dev libevdev-dev libudev-dev \
               libgbm-dev libdrm-dev
}

function sources_bsnes() {
    gitPullOrClone
}

function build_bsnes() {
    mkdir -p build
    cd build
    cmake -DPLATFORM_FLAGS="-D MESA -D GLES -D KMS -D DRM" ..
    make
    md_ret_require="$md_build/out/bsnes"
}

function install_bsnes() {
    md_ret_files=(
        'out/bsnes'
    )
}

function configure_bsnes() {
    mkRomDir "snes"
    addEmulator 1 "$md_id" "snes" "$md_inst/bsnes %ROM%"
    addSystem "snes"
}
