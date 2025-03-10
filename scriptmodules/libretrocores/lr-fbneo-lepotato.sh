#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-fbneo-lepotato"
rp_module_desc="Arcade emu - FinalBurn Neo (optimized for Le Potato) port for libretro"
rp_module_help="Previously called lr-fba-next and fbalpha\n\ROM Extension: .zip\n\nCopy your FBA roms to\n$romdir/fba or\n$romdir/neogeo or\n$romdir/arcade\n\nFor NeoGeo games the neogeo.zip BIOS is required and must be placed in the same directory as your FBA roms."
rp_module_licence="NONCOM https://raw.githubusercontent.com/libretro/FBNeo/master/src/license.txt"
rp_module_repo="git https://github.com/libretro/FBNeo.git master"
rp_module_section="exp"

function _update_hook_lr-fbneo() {
    # move from old location and update emulators.cfg
    renameModule "lr-fba-next" "lr-fbalpha"
    renameModule "lr-fbalpha" "lr-fbneo"
}

function depends_lr-fbneo() {
    local depends=(
        libsdl2-dev
        libsdl2-image-dev
        zlib1g-dev
        libpng-dev
        gcc
        g++
        make
    )
    getDepends "${depends[@]}"
}

function sources_lr-fbneo() {
    gitPullOrClone
    
    # Create optimized Makefile.config for Le Potato
    cat > "$md_build/src/burner/libretro/Makefile.config" << EOF
DEBUG=0
WANT_LIBSAMPLERATE=0
HAVE_THREADS=0
EXTERNAL_ZLIB=1
EOF
}

function build_lr-fbneo() {
    cd src/burner/libretro
    
    # Le Potato specific optimizations
    local params=(
        USE_CYCLONE=1
        HAVE_NEON=0 
        USE_EXPERIMENTAL_FLAGS=0
        CPU_FLAGS="-march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard"
        OPTIMIZE="-O2 -fdata-sections -ffunction-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector"
        PLATFORM_ZLIB=1
        PLATFORM_ARM=1
        FORCE_FRAMEBUFFER=1
        LOW_MEMORY=1
    )
    
    make clean
    make "${params[@]}"
    md_ret_require="$md_build/src/burner/libretro/fbneo_libretro.so"
}

function install_lr-fbneo() {
    md_ret_files=(
        'fbahelpfilesrc/fbneo.chm'
        'src/burner/libretro/fbneo_libretro.so'
        'gamelist.txt'
        'whatsnew.html'
        'metadata'
        'dats'
    )
}

function configure_lr-fbneo() {
    local def=1
    
    # Extra configuration for Le Potato
    if grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
        # Create optimized core options
        touch "$configdir/all/retroarch-core-options.cfg"
        
        # Add optimized settings if they don't exist
        grep -q "fbneo-frameskip" "$configdir/all/retroarch-core-options.cfg" || echo 'fbneo-frameskip = "1"' >> "$configdir/all/retroarch-core-options.cfg"
        grep -q "fbneo-cpu-speed-adjust" "$configdir/all/retroarch-core-options.cfg" || echo 'fbneo-cpu-speed-adjust = "100"' >> "$configdir/all/retroarch-core-options.cfg"
        grep -q "fbneo-allow-patched-romsets" "$configdir/all/retroarch-core-options.cfg" || echo 'fbneo-allow-patched-romsets = "enabled"' >> "$configdir/all/retroarch-core-options.cfg"
        grep -q "fbneo-neogeo-mode" "$configdir/all/retroarch-core-options.cfg" || echo 'fbneo-neogeo-mode = "MVS"' >> "$configdir/all/retroarch-core-options.cfg"
        grep -q "fbneo-vertical-mode" "$configdir/all/retroarch-core-options.cfg" || echo 'fbneo-vertical-mode = "disabled"' >> "$configdir/all/retroarch-core-options.cfg"
        grep -q "fbneo-lightgun-hide-crosshair" "$configdir/all/retroarch-core-options.cfg" || echo 'fbneo-lightgun-hide-crosshair = "enabled"' >> "$configdir/all/retroarch-core-options.cfg"
        grep -q "fbneo-controls" "$configdir/all/retroarch-core-options.cfg" || echo 'fbneo-controls = "arcade"' >> "$configdir/all/retroarch-core-options.cfg"
    fi
    
    addEmulator 0 "$md_id" "arcade" "$md_inst/fbneo_libretro.so"
    addEmulator 0 "$md_id-neocd" "arcade" "$md_inst/fbneo_libretro.so --subsystem neocd"
    addEmulator $def "$md_id" "neogeo" "$md_inst/fbneo_libretro.so"
    addEmulator 0 "$md_id-neocd" "neogeo" "$md_inst/fbneo_libretro.so --subsystem neocd"
    addEmulator $def "$md_id" "fba" "$md_inst/fbneo_libretro.so"
    addEmulator 0 "$md_id-neocd" "fba" "$md_inst/fbneo_libretro.so --subsystem neocd"

    addEmulator 0 "$md_id-pce" "pcengine" "$md_inst/fbneo_libretro.so --subsystem pce"
    addEmulator 0 "$md_id-sgx" "pcengine" "$md_inst/fbneo_libretro.so --subsystem sgx"
    addEmulator 0 "$md_id-tg" "pcengine" "$md_inst/fbneo_libretro.so --subsystem tg"
    addEmulator 0 "$md_id-gg" "gamegear" "$md_inst/fbneo_libretro.so --subsystem gg"
    addEmulator 0 "$md_id-sms" "mastersystem" "$md_inst/fbneo_libretro.so --subsystem sms"
    addEmulator 0 "$md_id-md" "megadrive" "$md_inst/fbneo_libretro.so --subsystem md"
    addEmulator 0 "$md_id-sg1k" "sg-1000" "$md_inst/fbneo_libretro.so --subsystem sg1k"
    addEmulator 0 "$md_id-cv" "coleco" "$md_inst/fbneo_libretro.so --subsystem cv"
    addEmulator 0 "$md_id-msx" "msx" "$md_inst/fbneo_libretro.so --subsystem msx"
    addEmulator 0 "$md_id-spec" "zxspectrum" "$md_inst/fbneo_libretro.so --subsystem spec"
    addEmulator 0 "$md_id-fds" "fds" "$md_inst/fbneo_libretro.so --subsystem fds"
    addEmulator 0 "$md_id-nes" "nes" "$md_inst/fbneo_libretro.so --subsystem nes"
    addEmulator 0 "$md_id-ngp" "ngp" "$md_inst/fbneo_libretro.so --subsystem ngp"
    addEmulator 0 "$md_id-ngpc" "ngpc" "$md_inst/fbneo_libretro.so --subsystem ngp"
    addEmulator 0 "$md_id-chf" "channelf" "$md_inst/fbneo_libretro.so --subsystem chf"

    local systems=(
        "arcade"
        "neogeo"
        "fba"
        "pcengine"
        "gamegear"
        "mastersystem"
        "megadrive"
        "sg-1000"
        "coleco"
        "msx"
        "zxspectrum"
        "fds"
        "nes"
        "ngp"
        "ngpc"
        "channelf"
    )

    local system
    for system in "${systems[@]}"; do
        addSystem "$system"
    done

    [[ "$md_mode" == "remove" ]] && return

    for system in "${systems[@]}"; do
        mkRomDir "$system"
        defaultRAConfig "$system"
        
        # Le Potato specific RetroArch settings
        if grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
            # Apply optimal RetroArch settings for this system on Le Potato
            ensureRetroArchConfig
            
            # Optimize core video settings
            setRetroArchCoreOption "video_threaded" "true"
            setRetroArchCoreOption "video_smooth" "false"
            setRetroArchCoreOption "video_shader_enable" "false"
            
            # Audio optimizations
            setRetroArchCoreOption "audio_sync" "false"
            setRetroArchCoreOption "audio_rate_control" "false"
            
            # Performance settings
            setRetroArchCoreOption "menu_driver" "rgui"
            
            # System-specific tweaks
            if [[ "$system" == "arcade" || "$system" == "neogeo" || "$system" == "fba" ]]; then
                # Extra optimizations for more demanding systems
                setRetroArchCoreOption "fbneo-frameskip" "1"
                setRetroArchCoreOption "fbneo-cpu-speed-adjust" "100"
            fi
        fi
    done

    # Create directories for all support files
    mkUserDir "$biosdir/fbneo"
    mkUserDir "$biosdir/fbneo/blend"
    mkUserDir "$biosdir/fbneo/cheats"
    mkUserDir "$biosdir/fbneo/patched"
    mkUserDir "$biosdir/fbneo/samples"

    # copy hiscore.dat
    cp "$md_inst/metadata/hiscore.dat" "$biosdir/fbneo/"
    chown "$__user":"$__group" "$biosdir/fbneo/hiscore.dat"

    # Set core options
    setRetroArchCoreOption "fbneo-diagnostic-input" "Hold Start"
}
