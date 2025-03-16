#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="gl4es"
rp_module_desc="GL4ES - OpenGL to OpenGL ES translation layer"
rp_module_help="GL4ES allows running OpenGL games on OpenGL ES hardware with Mesa drivers"
rp_module_licence="MIT https://github.com/ptitSeb/gl4es/blob/master/LICENSE"
rp_module_repo="git https://github.com/ptitSeb/gl4es.git master"
rp_module_section="opt"
rp_module_flags=""

function depends_gl4es() {
    getDepends cmake build-essential git gcc g++ libsdl2-dev
}

function sources_gl4es() {
    gitPullOrClone
}

function build_gl4es() {
    cd "$md_build"
    # Standard build configuration for Mesa-based systems
    cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo
    make -j"$(nproc)"
    md_ret_require="$md_build/lib/libGL.so.1"
}

function install_gl4es() {
    md_ret_files=(
        'lib/libGL.so.1'
        'LICENSE'
        'README.md'
    )
    
    # Create system-wide library directory for wider compatibility
    mkdir -p "/usr/local/lib/gl4es"
    cp "$md_inst/libGL.so.1" "/usr/local/lib/gl4es/"
}

function _create_specific_wrapper() {
    local wrapper="$1"
    local executable="$2"
    local params="$3"
    cat > "$wrapper" << EOF
#!/bin/bash
# GL4ES wrapper for $executable

# GL4ES configuration
export LIBGL_FB=1
export LIBGL_ES=2
export LIBGL_MIPMAP=1
export LIBGL_VSYNC=1

# Path to GL4ES library
export LD_LIBRARY_PATH="$md_inst:$LD_LIBRARY_PATH"
export LD_PRELOAD="$md_inst/libGL.so.1"

# Launch with GL4ES
$executable $params "\$@"
EOF
    chmod +x "$wrapper"
    chown $user:$user "$wrapper"
}

function _create_universal_wrapper() {
    # Create a universal wrapper for any command
    cat > "/usr/local/bin/gl4es-launcher" << EOF
#!/bin/bash
# Universal GL4ES launcher

# GL4ES configuration
export LIBGL_FB=1
export LIBGL_ES=2
export LIBGL_MIPMAP=1
export LIBGL_VSYNC=1

# Path to GL4ES library
export LD_LIBRARY_PATH="/usr/local/lib/gl4es:$md_inst:\$LD_LIBRARY_PATH"
export LD_PRELOAD="/usr/local/lib/gl4es/libGL.so.1"

# Launch with GL4ES
"\$@"
EOF
    chmod +x "/usr/local/bin/gl4es-launcher"
}

function configure_gl4es() {
    # Create wrappers directory
    local wrapper_dir="$home/RetroPie/gl4es_wrappers"
    mkUserDir "$wrapper_dir"
    
    # Create universal wrapper
    _create_universal_wrapper
    
    # Create specific wrappers for major emulators
    if [[ -f "$rootdir/emulators/mupen64plus/bin/mupen64plus" ]]; then
        _create_specific_wrapper "$wrapper_dir/mupen64plus-gl4es.sh" \
                       "$rootdir/emulators/mupen64plus/bin/mupen64plus" \
                       "--configdir=$configdir/n64 --datadir=$configdir/n64 --gfx mupen64plus-video-glide64mk2 --corelib $rootdir/emulators/mupen64plus/lib/libmupen64plus.so.2 --plugin $rootdir/emulators/mupen64plus/lib/mupen64plus/mupen64plus-audio-sdl.so --plugindir $rootdir/emulators/mupen64plus/lib/mupen64plus"
        
        # Add to emulators.cfg if not already there
        if [[ -f "$configdir/n64/emulators.cfg" ]]; then
            if ! grep -q "mupen64plus-gl4es" "$configdir/n64/emulators.cfg"; then
                echo 'mupen64plus-gl4es = "'"$wrapper_dir"'/mupen64plus-gl4es.sh %ROM%"' >> "$configdir/n64/emulators.cfg"
            fi
        fi
    fi
    
    # Create wrapper for PPSSPP
    if [[ -f "$rootdir/emulators/ppsspp/PPSSPPSDL" ]]; then
        _create_specific_wrapper "$wrapper_dir/ppsspp-gl4es.sh" \
                       "$rootdir/emulators/ppsspp/PPSSPPSDL" \
                       ""
        
        # Add to emulators.cfg if not already there
        if [[ -f "$configdir/psp/emulators.cfg" ]]; then
            if ! grep -q "ppsspp-gl4es" "$configdir/psp/emulators.cfg"; then
                echo 'ppsspp-gl4es = "'"$wrapper_dir"'/ppsspp-gl4es.sh %ROM%"' >> "$configdir/psp/emulators.cfg"
            fi
        fi
    fi
    
    # Create wrapper for RetroArch
    if [[ -f "$rootdir/emulators/retroarch/bin/retroarch" ]]; then
        _create_specific_wrapper "$wrapper_dir/retroarch-gl4es.sh" \
                       "$rootdir/emulators/retroarch/bin/retroarch" \
                       "-L"
    fi
    
    # Create runcommand hooks
    cat > "$configdir/all/runcommand-onstart.sh" << 'EOF'
#!/bin/bash
# GL4ES integration for runcommand
[[ -f "$configdir/all/runcommand.cfg" ]] && source "$configdir/all/runcommand.cfg"

if [[ "$use_gl4es" == "1" ]]; then
    export LIBGL_FB=1
    export LIBGL_ES=2
    export LIBGL_MIPMAP=1
    export LIBGL_VSYNC=1
    export LD_LIBRARY_PATH="/usr/local/lib/gl4es:$rootdir/opt/gl4es:$LD_LIBRARY_PATH"
    export LD_PRELOAD="/usr/local/lib/gl4es/libGL.so.1"
    echo "GL4ES enabled globally"
fi
EOF
    chmod +x "$configdir/all/runcommand-onstart.sh"
    chown $user:$user "$configdir/all/runcommand-onstart.sh"
    
    # Create runcommand config
    if [[ -f "$configdir/all/runcommand.cfg" ]]; then
        grep -q "use_gl4es" "$configdir/all/runcommand.cfg" || echo 'use_gl4es=0' >> "$configdir/all/runcommand.cfg"
    else
        echo 'use_gl4es=0' > "$configdir/all/runcommand.cfg"
        chown $user:$user "$configdir/all/runcommand.cfg"
    fi
    
    # Create toggle script
    cat > "$wrapper_dir/toggle-gl4es.sh" << EOF
#!/bin/bash
# Toggle GL4ES globally

CONF_FILE="$configdir/all/runcommand.cfg"

if grep -q "use_gl4es=1" "\$CONF_FILE"; then
    sed -i 's/use_gl4es=1/use_gl4es=0/' "\$CONF_FILE"
    echo "GL4ES has been DISABLED globally"
else
    sed -i 's/use_gl4es=0/use_gl4es=1/' "\$CONF_FILE"
    echo "GL4ES has been ENABLED globally"
fi
EOF
    chmod +x "$wrapper_dir/toggle-gl4es.sh"
    chown $user:$user "$wrapper_dir/toggle-gl4es.sh"
    
    # Add environment variable for RetroPie launches in autostart.sh
    if [[ -f "$configdir/all/autostart.sh" ]]; then
        if ! grep -q "LD_LIBRARY_PATH.*gl4es" "$configdir/all/autostart.sh"; then
            echo 'export LD_LIBRARY_PATH="/usr/local/lib/gl4es:$LD_LIBRARY_PATH"' >> "$configdir/all/autostart.sh"
        fi
    else
        echo 'export LD_LIBRARY_PATH="/usr/local/lib/gl4es:$LD_LIBRARY_PATH"' > "$configdir/all/autostart.sh"
        chown $user:$user "$configdir/all/autostart.sh"
    fi
    
    # Automatically wrap common emulators
    local emulators=(
        "mupen64plus-next"
        "desmume"
        "openbor"
        "dhewm3"
        "quake"
        "quake2"
        "quake3"
        "superTuxKart"
        "minecraft-pi"
        "redream"
        "flycast"
        "reicast"
    )
    
    local wrapped_count=0
    for emulator in "${emulators[@]}"; do
        if command -v "$emulator" >/dev/null; then
            # Only wrap if not already wrapped
            if [[ ! -f "/usr/bin/$emulator.real" ]]; then
                mv "/usr/bin/$emulator" "/usr/bin/$emulator.real"
                cat > "/usr/bin/$emulator" << EOF
#!/bin/bash
# GL4ES wrapper for $emulator
exec /usr/local/bin/gl4es-launcher /usr/bin/$emulator.real "\$@"
EOF
                chmod +x "/usr/bin/$emulator"
                ((wrapped_count++))
            fi
        fi
    done
    
    printMsgs "dialog" "GL4ES has been installed and configured for Mesa.\n\nSpecific wrapper scripts are located in $wrapper_dir\n\nUse $wrapper_dir/toggle-gl4es.sh to enable/disable GL4ES globally.\n\nAdditionally, $wrapped_count system emulators were automatically wrapped with GL4ES.\n\nYou can select GL4ES-enabled emulators from the runcommand menu when launching games."
}

function remove_gl4es() {
    rm -rf "$home/RetroPie/gl4es_wrappers"
    rm -f "/usr/local/bin/gl4es-launcher"
    
    # Remove GL4ES entries from emulators.cfg files
    [[ -f "$configdir/n64/emulators.cfg" ]] && sed -i '/mupen64plus-gl4es/d' "$configdir/n64/emulators.cfg"
    [[ -f "$configdir/psp/emulators.cfg" ]] && sed -i '/ppsspp-gl4es/d' "$configdir/psp/emulators.cfg"
    
    # Remove runcommand hooks
    [[ -f "$configdir/all/runcommand.cfg" ]] && sed -i '/use_gl4es/d' "$configdir/all/runcommand.cfg"
    [[ -f "$configdir/all/runcommand-onstart.sh" ]] && rm "$configdir/all/runcommand-onstart.sh"
    
    # Remove environment variable from autostart.sh
    [[ -f "$configdir/all/autostart.sh" ]] && sed -i '/LD_LIBRARY_PATH.*gl4es/d' "$configdir/all/autostart.sh"
    
    # Restore original emulator binaries
    find /usr/bin -name "*.real" | while read -r file; do
        original_name=$(basename "$file" .real)
        mv "$file" "/usr/bin/$original_name"
    done
    
    # Remove system-wide library
    rm -rf "/usr/local/lib/gl4es"
}
