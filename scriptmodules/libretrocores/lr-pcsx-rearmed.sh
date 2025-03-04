#!/usr/bin/env bash

rp_module_id="lr-pcsx-rearmed"
rp_module_desc="PlayStation emulator - PCSX ReARMed port for libretro - Optimized for Le Potato"
rp_module_help="ROM Extensions: .bin .cue .img .mdf .pbp .toc .cbn .m3u\n\nCopy your PlayStation ROMs to $romdir/psx"
rp_module_licence="GPL2 https://raw.githubusercontent.com/libretro/pcsx_rearmed/master/COPYING"
rp_module_repo="git https://github.com/libretro/pcsx_rearmed.git master"
rp_module_section="opt"
rp_module_flags="!x86 !kms"

function sources_lr-pcsx-rearmed-lepotato() {
    gitPullOrClone
}

function build_lr-pcsx-rearmed-lepotato() {
    local params=(ARCH=arm64 HAVE_NEON=1 HAVE_LIGHTREC=1 BUILTIN_GPU=neon)
    if isPlatform "lepotato"; then
        params+=(platform=lepotato)
    fi
    make -f Makefile.libretro "${params[@]}" clean
    make -f Makefile.libretro "${params[@]}"
    md_ret_require="$md_build/pcsx_rearmed_libretro.so"
}

function install_lr-pcsx-rearmed-lepotato() {
    md_ret_files=(
        'AUTHORS'
        'ChangeLog.df'
        'COPYING'
        'pcsx_rearmed_libretro.so'
        'readme.md'
    )
}

function configure_lr-pcsx-rearmed-lepotato() {
    mkRomDir "psx"
    ensureSystemretroconfig "psx"

    addEmulator 1 "$md_id" "psx" "$md_inst/pcsx_rearmed_libretro.so"
    addSystem "psx"
    
    # Optimize for Le Potato
    local config="$configdir/psx/retroarch-core-options.cfg"
    iniConfig " = " "\"" "$config"
    iniSet "pcsx_rearmed_drc" "enabled"
    iniSet "pcsx_rearmed_spu_reverb" "disabled"
    iniSet "pcsx_rearmed_spuirq" "disabled"
    iniSet "pcsx_rearmed_nosmccheck" "enabled"
    iniSet "pcsx_rearmed_gteregsunneeded" "enabled"
    iniSet "pcsx_rearmed_dithering" "disabled"
}
