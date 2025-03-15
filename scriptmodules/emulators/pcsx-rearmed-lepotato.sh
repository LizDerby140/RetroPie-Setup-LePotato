#!/usr/bin/env bash
# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="pcsx-rearmed-lepotato"
rp_module_desc="Playstation emulator - PCSX (optimized for Le Potato)"
rp_module_help="ROM Extensions: .bin .cue .cbn .img .iso .m3u .mdf .pbp .toc .z .znx\n\nCopy your PSX roms to $romdir/psx\n\nCopy the required BIOS file SCPH1001.BIN to $biosdir"
rp_module_licence="GPL2 https://raw.githubusercontent.com/notaz/pcsx_rearmed/master/COPYING"
rp_module_repo="git https://github.com/notaz/pcsx_rearmed.git master"
rp_module_section="opt"
rp_module_flags="arm armv8 neon gles kms drm !x86 !mali"

function depends_pcsx-rearmed-lepotato() {
    local depends=(
        libsdl1.2-dev
        libasound2-dev
        libpng-dev
        libx11-dev
        # Additional dependencies for Le Potato / GLES / KMS / DRM
        libgles2-mesa-dev
        libgbm-dev
        libdrm-dev
        libsdl2-dev
        libgl1-mesa-dev
        libglew-dev
        libdbus-1-dev
        libsamplerate0-dev
    )
    getDepends "${depends[@]}"
}

function sources_pcsx-rearmed-lepotato() {
    gitPullOrClone

    # Create patches directory if it doesn't exist
    mkdir -p "$md_build/patches"
    
    # Add patch for enabling GLES/KMS/DRM on Le Potato
    cat > "$md_build/patches/lepotato-gles-kms.patch" << _EOF_
diff --git a/Makefile.libretro b/Makefile.libretro
index xxxxxxx..yyyyyyy 100644
--- a/Makefile.libretro
+++ b/Makefile.libretro
@@ -53,6 +53,12 @@ ifneq ($(findstring armv,$(platform)),)
    ARCH = arm
    USE_DYNAREC = 1
    DRC_CACHE_BASE = 0
+   # Le Potato specific optimizations
+   ifneq ($(findstring aarch64,$(shell uname -m)),)
+      CFLAGS += -mtune=cortex-a53 -march=armv8-a -mfpu=neon-fp-armv8 -mfloat-abi=hard
+   else
+      CFLAGS += -mtune=cortex-a53 -march=armv8-a -mfpu=neon-fp-armv8 -mfloat-abi=hard
+   endif
 endif
 
 ifeq ($(platform),rpi4_64)
@@ -69,6 +75,7 @@ ifneq ($(findstring armv,$(platform)),)
    CFLAGS += -fPIC
    ASFLAGS = -fPIC
 endif
+   HAVE_GLES = 1
 
 # Enable OpenGL ES 2.0 renderer
 ifeq ($(HAVE_GLES), 1)
diff --git a/configure b/configure
index xxxxxxx..yyyyyyy 100755
--- a/configure
+++ b/configure
@@ -275,6 +275,13 @@ add_feature gles "OpenGL ES" 0
+# Le Potato auto-detection
+if grep -q "AML-S905X-CC\\|Le Potato" /proc/device-tree/model 2>/dev/null; then
+  enable_feature gles
+  enable_feature sdl2
+  enable_feature neon
+fi
+
 if check_sdl2; then
   if [ "$need_sdl" -a ! "$have_sdl" ]; then
     if [ "$need_sdl" = 2 ]; then
_EOF_
}

function build_pcsx-rearmed-lepotato() {
    # Increase swap to prevent build failures on low-memory devices
    rpSwap on 1024

    # Apply patches if they exist
    cd "$md_build"
    if [ -d "patches" ]; then
        for patch in patches/*.patch; do
            if [ -f "$patch" ]; then
                echo "Applying patch: $patch"
                patch -p1 < "$patch"
            fi
        done
    fi

    # Export optimization flags for Le Potato
    export CFLAGS="-O3 -march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard"
    export CXXFLAGS="$CFLAGS"
    export ASFLAGS="$CFLAGS"
    
    # Use NEON optimizations if available
    if isPlatform "neon"; then
        ./configure --sound-drivers=alsa --enable-neon --enable-gles --enable-sdl2
    else
        ./configure --sound-drivers=alsa --disable-neon --enable-gles --enable-sdl2
    fi
    
    # Build with reduced parallelism to avoid memory exhaustion
    make clean
    make -j2
    
    # Verify the executable was built
    md_ret_require="$md_build/pcsx"
    
    # Disable swap
    rpSwap off
}

function install_pcsx-rearmed-lepotato() {
    md_ret_files=(
        'AUTHORS'
        'COPYING'
        'ChangeLog'
        'ChangeLog.df'
        'NEWS'
        'README.md'
        'readme.txt'
        'pcsx'
    )
    
    # Create plugins directory and install plugins
    mkdir -p "$md_inst/plugins"
    cp "$md_build/plugins/spunull/spunull.so" "$md_inst/plugins/spunull.so"
    cp "$md_build/plugins/gpu_unai/gpu_unai.so" "$md_inst/plugins/gpu_unai.so"
    
    # Install GLES plugin if it exists
    if [ -f "$md_build/plugins/gpu-gles/gpu_gles.so" ]; then
        cp "$md_build/plugins/gpu-gles/gpu_gles.so" "$md_inst/plugins/gpu_gles.so"
    fi
    
    # Install peops plugin if it exists
    if [ -f "$md_build/plugins/dfxvideo/gpu_peops.so" ]; then
        cp "$md_build/plugins/dfxvideo/gpu_peops.so" "$md_inst/plugins/gpu_peops.so"
    fi
    
    # Create launcher script with optimized settings for Le Potato
    cat > "$md_inst/pcsx-lepotato.sh" << _EOF_
#!/bin/bash
# PCSX-ReARMed optimized launcher for Le Potato

# Set environment variables for best performance
export SDL_VIDEODRIVER=kmsdrm
export SDL_AUDIODRIVER=alsa
export AUDIODEV=hw:0,0

# Default to GLES renderer on Le Potato
if grep -q "AML-S905X-CC\\|Le Potato" /proc/device-tree/model 2>/dev/null; then
    # Set KMS/DRM specific variables
    export SDL_VIDEO_GL_DRIVER=libGLESv2.so
fi

# Launch the emulator with appropriate parameters
cd "$md_inst"
./pcsx -cdfile "\$1" -gpu gles -nogui
_EOF_

    chmod +x "$md_inst/pcsx-lepotato.sh"
}

function configure_pcsx-rearmed-lepotato() {
    mkRomDir "psx"
    mkUserDir "$md_conf_root/psx"
    
    # Create BIOS directory and symlink
    mkdir -p "$md_inst/bios"
    ln -sf "$biosdir/SCPH1001.BIN" "$md_inst/bios/SCPH1001.BIN"
    
    # Symlink config folder
    moveConfigDir "$md_inst/.pcsx" "$md_conf_root/psx/pcsx"
    
    # Create optimized configuration for Le Potato
    if grep -q "AML-S905X-CC\|Le Potato" /proc/device-tree/model 2>/dev/null; then
        # Create config directory if it doesn't exist
        mkdir -p "$md_conf_root/psx/pcsx/plugins"
        
        # Create optimized GPU configuration
        cat > "$md_conf_root/psx/pcsx/plugins/gpu_gles.cfg" << _EOF_
# PCSX-ReARMed GLES GPU plugin configuration for Le Potato
Windowed = 0
Resolution = 0
ShowFPS = 0
UseFrameLimit = 1
FPSDetection = 1
FrameLimit = 60
FrameSkip = 0
OffscreenDrawing = 1
FramebufferEffects = 1
FramebufferUpload = 0
TextureFilter = 2
_EOF_
        
        # Create general PCSX configuration
        cat > "$md_conf_root/psx/pcsx/pcsx.cfg" << _EOF_
Bios = SCPH1001.BIN
Gpu = builtin_gpu
Spu = builtin_spu
Xa = 0
Mdec = 0
Cdda = 0
Debug = 0
PsxOut = 0
SpuIrq = 0
RCntFix = 0
VSyncWA = 0
Cpu = 0
PsxType = 0
Cdrom = /dev/cdrom
SpuUpdate = 1
PsxAuto = 1
Net = 0
_EOF_
    fi
    
    # Register emulator
    addEmulator 0 "$md_id-gles" "psx" "$md_inst/pcsx-lepotato.sh %ROM%"
    addEmulator 1 "$md_id" "psx" "pushd $md_inst; ./pcsx -cdfile %ROM%; popd"
    
    # Register the platform
    addSystem "psx"
}
