#!/usr/bin/env bash

rp_module_id="mali450-optimization"
rp_module_desc="Optimization tweaks for Mali-450 MP2 GPU"
rp_module_section="config"
rp_module_flags="!x86 !rpi"

function install_mali450-optimization() {
    # Create Mali performance configuration
    cat > /etc/mali/mali.conf << _EOF_
# Mali-450 MP2 Configuration
mali_resource_stall_delay=0
mali_memory_split=32M
mali_mem_swap_tracking=0
mali_max_job_slots=8
mali_scheduler_mode=2
_EOF_

    # Create a script to set Mali performance parameters
    cat > /usr/local/bin/mali-performance << _EOF_
#!/bin/bash
# Set Mali performance to high
echo performance > /sys/devices/platform/mali/devfreq/mali/governor
echo 500000000 > /sys/devices/platform/mali/devfreq/mali/max_freq
_EOF_
    chmod +x /usr/local/bin/mali-performance
    
    # Create a service to set performance on boot
    cat > /etc/systemd/system/mali-performance.service << _EOF_
[Unit]
Description=Mali GPU Performance Settings
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mali-performance
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
_EOF_

    systemctl enable mali-performance.service
}

function configure_mali450-optimization() {
    # Create global RetroArch configuration for Mali optimizations
    local config="$configdir/all/retroarch.cfg"
    
    # Specific Mali-450 optimizations
    iniConfig " = " '"' "$config"
    iniSet "video_max_swapchain_images" "2"
    iniSet "video_hard_sync" "false"
    iniSet "video_vsync" "false"
    iniSet "video_scale_integer" "false"
    iniSet "video_crop_overscan" "true"

# N64 optimizations for Mali-450
local n64_config="$configdir/n64/retroarch.cfg"
if [[ -f "$n64_config" ]]; then
    iniConfig " = " '"' "$n64_config"
    iniSet "video_filter" "normal2x"
    iniSet "video_shader_enable" "false"
    iniSet "video_smooth" "false"
    iniSet "video_threaded" "true"
    iniSet "video_vsync" "false"
    
fi

# PSP optimizations for Mali-450
local psp_config="$configdir/psp/retroarch.cfg"
if [[ -f "$psp_config" ]]; then
    iniConfig " = " '"' "$psp_config"
    iniSet "video_filter" "normal2x"
    iniSet "video_shader_enable" "false"
    iniSet "video_smooth" "false"
    iniSet "video_threaded" "true"
    iniSet "video_vsync" "false"

fi
}
