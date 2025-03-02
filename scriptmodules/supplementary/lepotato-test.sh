#!/usr/bin/env bash

rp_module_id="lepotato-test"
rp_module_desc="Test Le Potato S905X and Mali-450 configuration"
rp_module_section="config"
rp_module_flags="!x86 !rpi"

function configure_lepotato-test() {
    echo "Testing Le Potato hardware configuration..."
    
    echo "> S905X CPU Information:"
    lscpu | grep "Model name\|Architecture\|CPU max MHz"
    
    echo "> Mali-450 GPU Information:"
    if [ -e /dev/mali ]; then
        echo "Mali device node found: $(ls -la /dev/mali)"
        
        echo "> Testing Mali libraries:"
        if [ -d /usr/local/lib/mali ]; then
            ls -la /usr/local/lib/mali/*.so
        else
            echo "Mali libraries not found in /usr/local/lib/mali"
        fi
        
        echo "> Running simple OpenGL ES test:"
        mali-run glxinfo | grep "OpenGL"
    else
        echo "Mali device node not found. Check driver installation."
    fi
    
    echo "> System performance configuration:"
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$cpu: $(cat $cpu)"
    done
    
    if [ -f /sys/devices/platform/mali/devfreq/mali/governor ]; then
        echo "Mali governor: $(cat /sys/devices/platform/mali/devfreq/mali/governor)"
    fi
    
    echo "> Running RetroArch hardware test:"
    mali-run retroarch --verbose --features | grep "OpenGL\|Mali"
    }
