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
    
    # Mupen64Plus-Next specific optimizations
    iniSet "mupen64plus-rdp-plugin" "gliden64"  # Use GlideN64 for better performance
    iniSet "mupen64plus-parallel-rdp" "false"  # Disable Parallel RDP (too slow on Mali-450)
    iniSet "mupen64plus-rsp-plugin" "hle"      # Use HLE RSP for speed
    iniSet "mupen64plus-EnableFBEmulation" "False"
    iniSet "mupen64plus-cpucore" "dynamic_recompiler"  # Best performance
    
    # Parallel-N64 core-specific settings
    iniSet "parallel-n64-gfxplugin" "rice"  # Rice plugin is often the fastest
    iniSet "parallel-n64-angrylion" "false"
    iniSet "parallel-n64-gfxplugin-accuracy" "low"  # Prioritize performance
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

    # PPSSPP core-specific optimizations
    iniSet "ppsspp_cpu_core" "jit"  # Use Just-In-Time compiler for better speed
    iniSet "ppsspp_frameskip" "1"   # Light frameskip
    iniSet "ppsspp_frameskip_type" "numbered"
    iniSet "ppsspp_block_transfer_gpu" "false"  # Disabling can help on weaker GPUs
    iniSet "ppsspp_fast_memory" "true"
    iniSet "ppsspp_enable_mipmapping" "false"  # Avoid unnecessary texture processing
    iniSet "ppsspp_enable_hack_settings" "true"
    
    # Resolution and rendering settings
    iniSet "ppsspp_internal_resolution" "1"  # Keep at native resolution for best performance
    iniSet "ppsspp_texture_filtering" "0"    # No filtering for better speed
    iniSet "ppsspp_vertex_cache" "true"
    iniSet "ppsspp_enable_software_skinning" "true"
fi

    iniSet "video_threaded" "true"
    iniSet "video_vsync" "true"
    iniSet "video_crop_overscan" "true"
    iniSet "video_smooth" "false"
    # Performance settings for Reicast/Flycast
    iniSet "reicast_threaded_rendering" "enabled"
    iniSet "reicast_internal_resolution" "640x480"
    iniSet "reicast_enable_rtt" "disabled"
    iniSet "reicast_enable_purupuru" "disabled"
fi

# PlayStation (PSX) optimizations for Mali-450
local psx_config="$configdir/psx/retroarch.cfg"
if [[ -f "$psx_config" ]]; then
    iniConfig " = " '"' "$psx_config"
    iniSet "video_filter" "normal2x"
    iniSet "video_shader_enable" "false"
    iniSet "video_smooth" "false"
    iniSet "video_threaded" "true"
    # PCSX-ReARMed specific settings
    iniSet "pcsx_rearmed_frameskip" "1"
    iniSet "pcsx_rearmed_dithering" "disabled"
    iniSet "pcsx_rearmed_gpu_peops_odd_even_bit" "disabled"
    iniSet "pcsx_rearmed_gpu_peops_expand_screen_width" "disabled"
    iniSet "pcsx_rearmed_spu_reverb" "disabled"
    iniSet "pcsx_rearmed_spu_interpolation" "simple"
fi
}
