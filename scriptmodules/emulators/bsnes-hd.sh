#!/usr/bin/env bash

rp_module_id="lr-bsnes-hd"
rp_module_desc="lr-bsnes-hd - Super Nintendo Entertainment System (SNES) Emulator"
rp_module_help="ROM Extensions: .smc .sfc\n\nCopy your SNES ROMs to $romdir/snes"
rp_module_licence="GPL3 https://raw.githubusercontent.com/libretro/bsnes/master/LICENSE"
rp_module_repo="git https://github.com/libretro/bsnes-hd.git master"
rp_module_section="opt"
rp_module_flags=""

function depends_lr-bsnes-hd() {
    getDepends build-essential libasound2-dev libudev-dev libx11-dev libxext-dev \
               libxi-dev libgbm-dev libdrm-dev
}

function sources_lr-bsnes-hd() {
    gitPullOrClone
}

function build_lr-bsnes-hd() {
    make -C bsnes/snes PLATFORM_FLAGS="-D MESA -D GLES -D KMS -D DRM"
    md_ret_require="$md_build/bsnes/snes/snes_libretro.so"
}

function install_lr-bsnes-hd() {
    md_ret_files=(
        'bsnes/snes/snes_libretro.so'
    )
}

function configure_lr-bsnes-hd() {
    mkRomDir "snes"
    ensureSystemretroconfig "snes"

    addEmulator 1 "$md_id" "snes" "$md_inst/snes_libretro.so"
    addSystem "snes"
}
