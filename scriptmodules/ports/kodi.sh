#!/usr/bin/env bash

# This file is part of the RetroPie Project
#
# The RetroPie Project is the legal property of its developers.
# Please refer to the LICENSE file distributed with this source.
#

rp_module_id="kodi_lepotato"
rp_module_desc="Kodi - Open source home theatre software optimized for Le Potato (AML-S905X-CC)"
rp_module_licence="GPL2 https://raw.githubusercontent.com/xbmc/xbmc/master/LICENSE.md"
rp_module_section="opt"
rp_module_flags="!x86 !mali !rpi"

function depends_kodi_lepotato() {
    # Ensure we're running on Le Potato
    if ! grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
        md_ret_errors+=("This script is optimized for Le Potato (AML-S905X-CC) and may not work on other devices.")
        return 1
    fi

    getDepends git curl wget unzip lsb-release apt-transport-https software-properties-common \
               kodi kodi-peripheral-joystick kodi-vfs-libarchive kodi-inputstream-adaptive

    addUdevInputRules
}

function install_bin_kodi_lepotato() {
    # Ensure apt update is run
    __apt_update=0

    local all_pkgs=(kodi kodi-peripheral-joystick kodi-inputstream-adaptive kodi-vfs-libarchive)
    local avail_pkgs=()
    
    for pkg in "${all_pkgs[@]}"; do
        local ret=$(apt-cache madison "$pkg" 2>/dev/null)
        [[ -n "$ret" ]] && avail_pkgs+=("$pkg")
    done

    aptInstall "${avail_pkgs[@]}"
}

function configure_kodi_lepotato() {
    moveConfigDir "$home/.kodi" "$md_conf_root/kodi"

    # Create and enable systemd service for Kodi
    cat > /etc/systemd/system/kodi.service << _EOF_
[Unit]
Description=Kodi Media Center
After=systemd-user-sessions.service network-online.target sound.target
Requires=network-online.target

[Service]
User=kodi
Group=kodi
Type=simple
ExecStart=/usr/bin/kodi-standalone
Restart=on-abort
RestartSec=5

[Install]
WantedBy=multi-user.target
_EOF_

    systemctl enable kodi.service

    # Optimize system for Kodi and RetroPie
    echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
    sysctl -p /etc/sysctl.d/99-swappiness.conf

    # Create RetroPie integration
    mkdir -p "$home/RetroPie/roms/ports"
    cat > "$home/RetroPie/roms/ports/kodi.sh" << _EOF_
#!/bin/bash
systemctl start kodi.service
_EOF_
    chmod +x "$home/RetroPie/roms/ports/kodi.sh"

    addPort "$md_id" "kodi" "Kodi Media Center" "kodi-standalone"
}

function remove_kodi_lepotato() {
    aptRemove kodi
    systemctl disable kodi.service
    rm -f /etc/systemd/system/kodi.service
}
