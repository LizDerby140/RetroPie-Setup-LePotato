#!/usr/bin/env bash
# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
rp_module_id="minecraft"
rp_module_desc="Minecraft - Pi Edition (with GL4ES)"
rp_module_licence="PROP"
rp_module_section="exp"
rp_module_flags="!x86"

function depends_minecraft() {
    getDepends xorg matchbox-window-manager

    # Check if GL4ES is installed
    if [[ ! -d "$rootdir/opt/gl4es" && ! -f "/usr/local/lib/gl4es/libGL.so.1" ]]; then
        printMsgs "dialog" "GL4ES is required but not installed. Please install GL4ES module first."
        exit 1
    fi
}

function install_bin_minecraft() {
    # Download Minecraft Pi Edition since it's not in Armbian repos
    mkdir -p "$md_inst"
    wget -O "$md_inst/minecraft-pi.tar.gz" "https://github.com/adafruit/Raspberry-Pi-Installer-Scripts/raw/master/minecraft-pi/minecraft-pi.tar.gz"
    tar -xvf "$md_inst/minecraft-pi.tar.gz" -C "$md_inst"
    rm "$md_inst/minecraft-pi.tar.gz"
    
    # Fix permissions
    chmod +x "$md_inst/minecraft-pi"
    
    # Create GL4ES wrapper script
    cat > "$md_inst/minecraft-gl4es.sh" << 'EOF'
#!/bin/bash
# GL4ES wrapper for Minecraft Pi Edition

# GL4ES configuration
export LIBGL_FB=1
export LIBGL_ES=2
export LIBGL_MIPMAP=1
export LIBGL_VSYNC=1

# Set up correct library paths
if [ -f "/usr/local/lib/gl4es/libGL.so.1" ]; then
    export LD_LIBRARY_PATH="/usr/local/lib/gl4es:$LD_LIBRARY_PATH"
    export LD_PRELOAD="/usr/local/lib/gl4es/libGL.so.1"
elif [ -d "/opt/retropie/opt/gl4es" ]; then
    export LD_LIBRARY_PATH="/opt/retropie/opt/gl4es:$LD_LIBRARY_PATH"
    export LD_PRELOAD="/opt/retropie/opt/gl4es/libGL.so.1"
else
    echo "GL4ES library not found!"
    exit 1
fi

# Mesa compatibility
export MESA_GL_VERSION_OVERRIDE=2.1

# Make sure Minecraft uses our bundled libraries
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/retropie/ports/minecraft/lib/arm-linux-gnueabihf"

# Launch Minecraft Pi
cd /opt/retropie/ports/minecraft
./minecraft-pi "$@"
EOF
    chmod +x "$md_inst/minecraft-gl4es.sh"
    
    # Create X session startup script
    cat > "$md_inst/start-minecraft.sh" << 'EOF'
#!/bin/bash
xset -dpms s off s noblank
matchbox-window-manager &
/opt/retropie/ports/minecraft/minecraft-gl4es.sh
EOF
    chmod +x "$md_inst/start-minecraft.sh"
}

function remove_minecraft() {
    rm -rf "$md_inst"
}

function configure_minecraft() {
    addPort "$md_id" "minecraft" "Minecraft Pi (GL4ES)" "XINIT:/opt/retropie/ports/minecraft/start-minecraft.sh"
}
