#!/usr/bin/env bash

# Enhanced for Libre Le Potato (AML-S905X-CC)
# Optimized for ARMV8, NEON, GLES, KMS, DRM support
rp_module_id="mupen64plus-lepotato"
rp_module_desc="N64 emulator MUPEN64Plus (Enhanced for Le Potato with KMS/DRM)"
rp_module_help="ROM Extensions: .z64 .n64 .v64\n\nCopy your N64 roms to $romdir/n64"
rp_module_licence="GPL2 https://raw.githubusercontent.com/mupen64plus/mupen64plus-core/master/LICENSES"
rp_module_section="opt"
rp_module_flags="arm armv8 neon gles kms drm"

function _pkg_info_mupen64plus() {
    echo "Collection of separate modules for the mupen64plus n64 emulator optimized for Le Potato with KMS/DRM support"
}

function depends_mupen64plus-lepotato() {
    local depends=(
        cmake
        libsamplerate0-dev
        libspeexdsp-dev
        libsdl2-dev
        libpng-dev
        libfreetype6-dev
        fonts-freefont-ttf
        libboost-filesystem-dev
        libglu1-mesa-dev
        gcc
        g++
        make
        # Additional dependencies for KMS/DRM support
        libdrm-dev
        libgbm-dev
        libegl1-mesa-dev
        libgles2-mesa-dev
        mesa-common-dev
    )
    
    # Include platform-specific dependencies
    isPlatform "x86" && depends+=(nasm)
    getDepends "${depends[@]}"
}

function sources_mupen64plus-lepotato() {
    local repos=(
        'mupen64plus mupen64plus-core master'
        'mupen64plus mupen64plus-ui-console master'
        'mupen64plus mupen64plus-audio-sdl master'
        'mupen64plus mupen64plus-input-sdl master'
        'mupen64plus mupen64plus-rsp-hle master'
        'mupen64plus mupen64plus-video-GLideN64 master'
        # Add rice video plugin for alternative renderer
        'mupen64plus mupen64plus-video-rice master'
    )

    local repo
    for repo in "${repos[@]}"; do
        local repo_url="https://github.com/${repo%% *}/${repo#* }"
        local repo_dir="${repo#* }"
        local repo_branch="${repo##* }"
        
        if [[ $repo =~ .* ]]; then
            repo_branch="${repo##* }"
            repo_dir="${repo#* }"
            repo_dir="${repo_dir% *}"
        fi
        
        gitPullOrClone "$md_build/$repo_dir" "$repo_url" "$repo_branch"
    done

    # Get GLideN64 library
    gitPullOrClone "$md_build/GLideN64" "https://github.com/gonetz/GLideN64.git"
    
    # Apply patches if they exist in the patches folder
    pushd "$md_build"
    local patch
    if [[ -d "$scriptdir/scriptmodules/emulators/$md_id/patches" ]]; then
        for patch in "$scriptdir/scriptmodules/emulators/$md_id/patches/"*.patch; do
            if [[ -f "$patch" ]]; then
                echo "Applying patch: $patch"
                
                # Identify the target module (component) from the patch filename
                local target_module
                target_module=$(basename "$patch" | sed 's/-.*$//')
                
                # Find corresponding directory
                if [[ -d "$target_module" ]]; then
                    pushd "$target_module"
                    patch -p1 < "$patch"
                    popd
                elif [[ -d "mupen64plus-$target_module" ]]; then
                    pushd "mupen64plus-$target_module"
                    patch -p1 < "$patch"
                    popd
                else
                    echo "WARNING: Cannot find target directory for patch $patch"
                    # Apply in root directory as fallback
                    patch -p1 < "$patch"
                fi
            fi
        done
    fi
    popd
    
    # Create an ini file for GLideN64 version tracking
    cat > "$md_build/GLideN64_config_version.ini" << _EOF_
[Core]
Version = 1.99.2
_EOF_

    # Create an ini file with KMS/DRM configurations
    cat > "$md_build/KMS_DRM_config.ini" << _EOF_
[Video-General]
Fullscreen = True
UseKMS = True
UseDRM = True
_EOF_
}

function _params_mupen64plus-lepotato() {
    local dir="$1"
    
    # Base params for all modules
    local params=("NEON=1" "VFP=1" "VFP_HARD=1" "SHAREDIR=$md_inst/share/mupen64plus" "LIBDIR=$md_inst/lib/mupen64plus")
    
    # Enhanced platform-specific optimizations for Le Potato
    if grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
        params+=("CPUFLAGS=-march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard")
        params+=("VC=1" "OPTFLAGS=-O3" "USE_GLES=1")
        
        # Add KMS/DRM support
        params+=("USE_KMS=1" "USE_DRM=1")
    fi
    
    # Special handling for some modules
    case "$dir" in
        "mupen64plus-ui-console")
            params+=("COREDIR=$md_inst/lib/mupen64plus" "PLUGINDIR=$md_inst/lib/mupen64plus")
            params+=("USE_KMS=1" "USE_DRM=1")
            ;;
        "mupen64plus-video-GLideN64")
            params+=("GLES=1" "NEON=1" "USE_KMS=1" "USE_DRM=1")
            ;;
        "mupen64plus-video-rice")
            params+=("GLES=1" "USE_KMS=1" "USE_DRM=1" "NEON=1")
            ;;
        "GLideN64")
            params+=("-DGLES2=ON" "-DNEON_OPT=ON" "-DUSE_KMS=ON" "-DUSE_DRM=ON")
            ;;
    esac
    
    echo "${params[@]}"
}

function build_mupen64plus-lepotato() {
    # Increase swap to prevent build failures
    rpSwap on 1536
    
    # Export optimization flags for all compilation
    export CFLAGS="-O3 -march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard"
    export CXXFLAGS="$CFLAGS"
    
    # Add flags for KMS/DRM support
    export CFLAGS="$CFLAGS -DUSE_KMS=1 -DUSE_DRM=1"
    export CXXFLAGS="$CXXFLAGS -DUSE_KMS=1 -DUSE_DRM=1"
    
    # Build each module
    local dir
    local params
    for dir in mupen64plus-*; do
        if [[ -f "$dir/projects/unix/Makefile" ]]; then
            echo "Building $dir..."
            params=($(_params_mupen64plus-lepotato "$dir"))
            
            # Limit to 2 cores to prevent memory exhaustion on low-memory devices
            make -j2 -C "$dir/projects/unix" "${params[@]}" clean
            make -j2 -C "$dir/projects/unix" all "${params[@]}"
        fi
    done
    
    # Build GLideN64
    echo "Building GLideN64..."
    "$md_build/GLideN64/src/getRevision.sh"
    mkdir -p "$md_build/GLideN64/projects/cmake/build"
    pushd "$md_build/GLideN64/projects/cmake/build"
    
    # Configure with enhanced Le Potato optimizations
    cmake .. \
        -DMUPENPLUSAPI=ON \
        -DVEC4_OPT=ON \
        -DUSE_SYSTEM_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DGLES2=ON \
        -DNEON_OPT=ON \
        -DCRC_ARMV8=ON \
        -DUSE_KMS=ON \
        -DUSE_DRM=ON \
        -DCMAKE_C_FLAGS="$CFLAGS" \
        -DCMAKE_CXX_FLAGS="$CXXFLAGS"
    
    # Build with limited cores to prevent out-of-memory
    make -j2
    popd
    
    # Disable swap
    rpSwap off
    
    # List of required files to verify successful build
    md_ret_require=(
        "$md_build/mupen64plus-ui-console/projects/unix/mupen64plus"
        "$md_build/mupen64plus-core/projects/unix/libmupen64plus.so.2.0.0"
        "$md_build/mupen64plus-audio-sdl/projects/unix/mupen64plus-audio-sdl.so"
        "$md_build/mupen64plus-input-sdl/projects/unix/mupen64plus-input-sdl.so"
        "$md_build/mupen64plus-rsp-hle/projects/unix/mupen64plus-rsp-hle.so"
        "$md_build/GLideN64/projects/cmake/build/plugin/Release/mupen64plus-video-GLideN64.so"
        "$md_build/mupen64plus-video-rice/projects/unix/mupen64plus-video-rice.so"
    )
}

function install_mupen64plus-lepotato() {
    # Install each module
    local dir
    local params
    for dir in mupen64plus-*; do
        if [[ -f "$dir/projects/unix/Makefile" ]]; then
            echo "Installing $dir..."
            params=($(_params_mupen64plus-lepotato "$dir"))
            make -C "$dir/projects/unix" PREFIX="$md_inst" "${params[@]}" install
        fi
    done
    
    # Install GLideN64 and its configuration
    mkdir -p "$md_inst/lib/mupen64plus"
    mkdir -p "$md_inst/share/mupen64plus"
    
    cp "$md_build/GLideN64/ini/GLideN64.custom.ini" "$md_inst/share/mupen64plus/"
    cp "$md_build/GLideN64/projects/cmake/build/plugin/Release/mupen64plus-video-GLideN64.so" "$md_inst/lib/mupen64plus/"
    cp "$md_build/GLideN64_config_version.ini" "$md_inst/share/mupen64plus/"
    cp "$md_build/KMS_DRM_config.ini" "$md_inst/share/mupen64plus/"
}

function configure_mupen64plus-lepotato() {
    # Create enhanced helper script for launching mupen64plus with different options
    cat > "$md_inst/bin/mupen64plus.sh" << _EOF_
#!/bin/bash
VIDEO_PLUGIN="\$1"
ROM="\$2"
RESOLUTION="\$3"
PARAMS=""

if [[ -z "\$RESOLUTION" ]]; then
    RESOLUTION="320x240"
fi

# Set video resolution
if [[ "\$RESOLUTION" != "%XRES%x%YRES%" ]]; then
    PARAMS+="\$PARAMS --resolution \$RESOLUTION"
fi

# Handle auto-configuration
if [[ "\$VIDEO_PLUGIN" == "AUTO" ]]; then
    VIDEO_PLUGIN="mupen64plus-video-GLideN64"
fi

# Le Potato specific optimizations with KMS/DRM support
if grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
    # Force lower resolution for better performance
    PARAMS+="\$PARAMS --resolution 320x240"
    export SDL_AUDIODRIVER=alsa
    export AUDIODEV=hw:0,0
    
    # KMS/DRM environment variables
    export SDL_VIDEODRIVER=kmsdrm
fi

# Run with appropriate parameters
cd "\$HOME"
"\$rootdir/emulators/mupen64plus-lepotato/bin/mupen64plus" \\
    --corelib "\$rootdir/emulators/mupen64plus-lepotato/lib/mupen64plus/libmupen64plus.so.2.0.0" \\
    --plugin "\$rootdir/emulators/mupen64plus-lepotato/lib/mupen64plus/\$VIDEO_PLUGIN.so" \\
    --configdir "\$configdir/n64/mupen64plus" \\
    --datadir "\$configdir/n64/mupen64plus" \\
    --gfx "\$VIDEO_PLUGIN" \\
    \$PARAMS "\$ROM"
_EOF_

    chmod +x "$md_inst/bin/mupen64plus.sh"
    
    # Register emulators with correct options for Le Potato
    addEmulator 0 "${md_id}-GLideN64" "n64" "$md_inst/bin/mupen64plus.sh mupen64plus-video-GLideN64 %ROM% 320x240"
    addEmulator 0 "${md_id}-Rice" "n64" "$md_inst/bin/mupen64plus.sh mupen64plus-video-rice %ROM% 320x240"
    addEmulator 1 "${md_id}-auto" "n64" "$md_inst/bin/mupen64plus.sh AUTO %ROM% 320x240"
    
    # Create directories
    mkRomDir "n64"
    moveConfigDir "$home/.local/share/mupen64plus" "$md_conf_root/n64/mupen64plus"
    
    # Copy configuration files
    mkdir -p "$md_conf_root/n64/mupen64plus"
    cp -v "$md_inst/share/mupen64plus/"*.ini "$md_conf_root/n64/mupen64plus/"
    cp -v "$md_inst/share/mupen64plus/font.ttf" "$md_conf_root/n64/mupen64plus/"
    
    # Le Potato specific configuration
    if grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
        # Create specific mupen64plus.cfg with optimized settings
        cat > "$md_conf_root/n64/mupen64plus/mupen64plus.cfg" << _EOF_
[Core]
Version = 1.01
OnScreenDisplay = True
R4300Emulator = 2
DisableExtraMem = False
AutoStateSlotIncrement = False
ScreenshotPath = "/home/pi/RetroPie/screenshots"
SaveStatePath = "/home
