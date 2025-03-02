#!/usr/bin/env bash

rp_module-id="s905x-modules"
rp_module_desc="S905X kernel modules and optimization"
rp_module_section="config"
rp_module_flags="!x86 !rpi"

function install_s905x-modules() {
    # Create S905X specific configuration
    cat > /etc/modprobe.d/s905x-modules.conf << _EOF_
# S905X CPU frequency scaling
options cpufreq_conservative up_threshold=95 down_threshold=40
options cpufreq_ondemand sampling_rate=100000 up_threshold=60

# Memory management for S905X
options zram num_devices=4
_EOF_

    # Create CPU configuration service
    cat > /etc/systemd/system/s905x-cpu.service << _EOF_
[Unit]
Description=S905X CPU Configuration
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
ExecStart=/bin/sh -c "echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor"
ExecStart=/bin/sh -c "echo performance > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor"
ExecStart=/bin/sh -c "echo performance > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor"
ExecStart=/bin/sh -c "echo 1512000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
ExecStart=/bin/sh -c "echo 1512000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq"
ExecStart=/bin/sh -c "echo 1512000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq"
ExecStart=/bin/sh -c "echo 1512000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
_EOF_

    # Enable the service
    systemctl enable s905x-cpu.service
    
    # Load appropriate modules
    modprobe cpufreq_conservative
    modprobe cpufreq_ondemand
    
    # Configure thermal management
    if [[ -f /sys/class/thermal/thermal_zone0/trip_point_0_temp ]]; then
        echo 70000 > /sys/class/thermal/thermal_zone0/trip_point_0_temp
        echo 85000 > /sys/class/thermal/thermal_zone0/trip_point_1_temp
    fi
}

function configure_s905x-modules() {
    # Apply optimal sysctl settings for S905X
    cat > /etc/sysctl.d/99-s905x-performance.conf << _EOF_
# S905X optimizations
vm.swappiness=10
vm.dirty_ratio=60
vm.dirty_background_ratio=30
kernel.sched_migration_cost_ns=5000000
kernel.sched_autogroup_enabled=0
_EOF_

    # Apply changes
    sysctl -p /etc/sysctl.d/99-s905x-performance.conf
    systemctl start s905x-cpu.service
}
