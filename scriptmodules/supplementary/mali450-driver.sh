#!/usr/bin/env bash
rp_module_id="mali450-driver"
rp_module_desc="Mali-450 MP2 GPU driver setup"
rp_module_section="exp"
rp_module_flags="!x86 !rpi"

function depends_mali450-driver() {
    # Dependencies for Mali driver compilation
    getDepends xorg-dev build-essential libdrm-dev libgbm-dev
}

function sources_mali450-driver() {
    # Get Mali userspace drivers from Libre Computer's official repository
    if [[ ! -f "$md_build/mali-450-r7p0.tar.gz" ]]; then
        # Actual Mali-450 drivers from Libre Computer Project's mali-blobs repository
        downloadAndExtract "https://github.com/libre-computer-project/mali-blobs/raw/main/s905x/mali-450/r7p0/aarch64/mali-450-r7p0-01rel0-aarch64.tar.gz" "$md_build/mali-userspace"
        
        # Download the Mali FBDEV and X11 backends
        downloadAndExtract "https://github.com/libre-computer-project/linux-vendor/raw/master/drivers/gpu/arm/mali-450/mali-450-libs.tar.gz" "$md_build/mali-libs"
        
        # Likely need to also get armsoc X11 driver for proper integration
        gitPullOrClone "$md_build/xf86-video-armsoc" "https://github.com/libre-computer-project/xf86-video-armsoc.git"
    fi
}

function build_mali450-driver() {
    # Build the armsoc X11 driver
    cd "$md_build/xf86-video-armsoc"
    ./autogen.sh
    ./configure --prefix=/usr
    make clean
    make -j"$__jobs"
}

function install_mali450-driver() {
    # Install Mali userspace libraries
    mkdir -p /usr/local/lib/mali
    cp -rv "$md_build/mali-userspace/lib/"* /usr/local/lib/mali/
    
    # Install Mali headers if available
    if [[ -d "$md_build/mali-userspace/include" ]]; then
        mkdir -p /usr/local/include/mali
        cp -rv "$md_build/mali-userspace/include/"* /usr/local/include/mali/
    fi
    
    # Install additional backend libraries
    cp -rv "$md_build/mali-libs/"* /usr/local/lib/mali/
    
    # Install armsoc X11 driver
    cd "$md_build/xf86-video-armsoc"
    make install
    
    # Create Mali udev rules
    cat > /etc/udev/rules.d/50-mali.rules << *EOF*
KERNEL=="mali", MODE="0660", GROUP="video"
KERNEL=="ump", MODE="0660", GROUP="video"
*EOF*

    # Create Mali config file
    cat > /etc/ld.so.conf.d/mali-450.conf << *EOF*
/usr/local/lib/mali
*EOF*
    ldconfig

    # Create a wrapper script for setting correct environment variables
    cat > /usr/local/bin/mali-env << *EOF*
#!/bin/bash
export MALI_LIBS=/usr/local/lib/mali
export LD_LIBRARY_PATH=\$MALI_LIBS:\$LD_LIBRARY_PATH
export LIBGL_DRIVERS_PATH=/usr/local/lib/mali
exec "\$@"
*EOF*
    chmod +x /usr/local/bin/mali-env

    # Create Xorg driver configuration
    if [[ ! -d /etc/X11/xorg.conf.d ]]; then
        mkdir -p /etc/X11/xorg.conf.d
    fi
    cat > /etc/X11/xorg.conf.d/20-mali.conf << *EOF*
Section "Device"
    Identifier "Mali-450"
    Driver "armsoc"
    Option "DRI2" "true"
    Option "DRI2_PAGE_FLIP" "true"
    Option "DRI2_WAIT_VSYNC" "false"
    Option "SWcursor" "true"
    Option "Debug" "false"
EndSection
*EOF*

    # Create symbolic links for Mali libraries
    ln -sf /usr/local/lib/mali/libEGL.so /usr/lib/libEGL.so
    ln -sf /usr/local/lib/mali/libGLESv2.so /usr/lib/libGLESv2.so
    ln -sf /usr/local/lib/mali/libmali.so /usr/lib/libmali.so
    ln -sf /usr/local/lib/mali/libgbm.so /usr/lib/libgbm.so
}

function configure_mali450-driver() {
    # Update RetroArch config for Mali
    local config="$configdir/all/retroarch.cfg"
    
    # Set video driver to gl (will use the Mali libs)
    iniConfig " = " '"' "$config"
    iniSet "video_driver" "gl"
    
    # Optimal Mali-450 settings for RetroArch
    iniSet "video_smooth" "false"
    iniSet "video_threaded" "true"
    iniSet "video_gpu_screenshot" "false"
    iniSet "video_shader_enable" "false"
    iniSet "video_scale" "1.0"
    
    # Add user to video group for Mali access
    usermod -a -G video $user
    
    # Create a Mali test script
    cat > /usr/local/bin/mali-test << *EOF*
#!/bin/bash
# Simple Mali-450 test script
echo "Testing Mali-450 MP2 GPU"
export LD_LIBRARY_PATH=/usr/local/lib/mali:\$LD_LIBRARY_PATH
echo "Mali libraries:"
ls -la /usr/local/lib/mali/*.so
echo "Mali device node:"
ls -la /dev/mali
echo "Attempting to run a simple GL info tool..."
mali-env glxinfo | grep "OpenGL"
*EOF*
    chmod +x /usr/local/bin/mali-test
}
