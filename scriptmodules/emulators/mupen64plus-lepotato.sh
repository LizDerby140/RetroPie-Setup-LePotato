#!/usr/bin/env bash

# Optimized for Libre Le Potato (Mali-450)
rp_module_id="mupen64plus"
rp_module_desc="N64 emulator MUPEN64Plus"
rp_module_help="ROM Extensions: .z64 .n64 .v64\n\nCopy your N64 roms to $romdir/n64"
rp_module_licence="GPL2 https://raw.githubusercontent.com/mupen64plus/mupen64plus-core/master/LICENSES"
rp_module_repo=":_pkg_info_mupen64plus"
rp_module_section="main"
rp_module_flags=""

function depends_mupen64plus() {
    local depends=(cmake libsamplerate0-dev libspeexdsp-dev libsdl2-dev libpng-dev libfreetype6-dev fonts-freefont-ttf libboost-filesystem-dev libglu1-mesa-dev)
    isPlatform "mesa" && depends+=(libgles2-mesa-dev)
    isPlatform "mali" && depends+=(libmali-dev)  # Ensure proper Mali drivers
    isPlatform "x86" && depends+=(nasm)
    getDepends "${depends[@]}"
}

function _get_repos_mupen64plus() {
    local repos=(
        'mupen64plus mupen64plus-core master'
        'mupen64plus mupen64plus-ui-console master'
        'mupen64plus mupen64plus-audio-sdl master'
        'mupen64plus mupen64plus-input-sdl master'
        'mupen64plus mupen64plus-rsp-hle master'
    )
    if isPlatform "mali"; then
        repos+=('mupen64plus mupen64plus-video-GLideN64 master')
    fi

    local commit=""
    local cmake_ver=$(apt-cache madison cmake | cut -d\| -f2 | sort --version-sort | head -1 | xargs)
    if compareVersions "$cmake_ver" lt 3.9; then
        commit="8a9d52b41b33d853445f0779dd2b9f5ec4ecdda8"
    fi
    repos+=("gonetz GLideN64 master $commit")

    local repo
    for repo in "${repos[@]}"; do
        echo "$repo"
    done
}

function build_mupen64plus() {
    rpSwap on 750

    local dir
    local params
    for dir in *; do
        if [[ -f "$dir/projects/unix/Makefile" ]]; then
            params=($(_params_mupen64plus $dir))

            # Enable parallel compilation
            make -j$(nproc) -C "$dir/projects/unix" "${params[@]}" clean
            make -j$(nproc) -C "$dir/projects/unix" all "${params[@]}" OPTFLAGS="$CFLAGS -O3 -flto"
        fi
    done

    # Build GLideN64
    "$md_build/GLideN64/src/getRevision.sh"
    pushd "$md_build/GLideN64/projects/cmake"

    params=("-DMUPENPLUSAPI=On" "-DVEC4_OPT=On" "-DUSE_SYSTEM_LIBS=On")
    isPlatform "mali" && params+=("-DMALI=On" "-DNEON_OPT=On")  # Mali-450 optimizations
    isPlatform "armv8" && params+=("-DCRC_ARMV8=On")
    cmake "${params[@]}" ../../src/
    make -j$(nproc)
    popd

    rpSwap off
    md_ret_require=(
        'mupen64plus-ui-console/projects/unix/mupen64plus'
        'mupen64plus-core/projects/unix/libmupen64plus.so.2.0.0'
        'mupen64plus-audio-sdl/projects/unix/mupen64plus-audio-sdl.so'
        'mupen64plus-input-sdl/projects/unix/mupen64plus-input-sdl.so'
        'mupen64plus-rsp-hle/projects/unix/mupen64plus-rsp-hle.so'
        'GLideN64/projects/cmake/plugin/Release/mupen64plus-video-GLideN64.so'
    )

    if isPlatform "mali"; then
        md_ret_require+=('mupen64plus-video-GLideN64/projects/unix/mupen64plus-video-GLideN64.so')
    fi
}

function install_mupen64plus() {
    local dir
    local params
    for dir in *; do
        if [[ -f "$dir/projects/unix/Makefile" ]]; then
            params=($(_params_mupen64plus $dir))
            make -j$(nproc) -C "$dir/projects/unix" PREFIX="$md_inst" OPTFLAGS="$CFLAGS -O3 -flto" "${params[@]}" install
        fi
    done

    cp "$md_build/GLideN64/ini/GLideN64.custom.ini" "$md_inst/share/mupen64plus/"
    cp "$md_build/GLideN64/projects/cmake/plugin/Release/mupen64plus-video-GLideN64.so" "$md_inst/lib/mupen64plus/"
    cp "$md_build/GLideN64_config_version.ini" "$md_inst/share/mupen64plus/"
}

function configure_mupen64plus() {
    local res
    local resolutions=("320x240" "640x480")
    isPlatform "mali" && res="%XRES%x%YRES%"

    addEmulator 0 "${md_id}-GLideN64" "n64" "$md_inst/bin/mupen64plus.sh mupen64plus-video-GLideN64 %ROM% $res"
    addEmulator 0 "${md_id}-gles2n64" "n64" "$md_inst/bin/mupen64plus.sh mupen64plus-video-n64 %ROM%"
    addEmulator 1 "${md_id}-auto" "n64" "$md_inst/bin/mupen64plus.sh AUTO %ROM%"

    mkRomDir "n64"
    moveConfigDir "$home/.local/share/mupen64plus" "$md_conf_root/n64/mupen64plus"

    cp "$md_data/mupen64plus.sh" "$md_inst/bin/"
    chmod +x "$md_inst/bin/mupen64plus.sh"
    mkUserDir "$md_conf_root/n64/"

    cp -v "$md_inst/share/mupen64plus/"{*.ini,font.ttf} "$md_conf_root/n64/"
}
