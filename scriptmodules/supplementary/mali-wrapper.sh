#!/usr/bin/env bash

rp_module_id="mali-wrapper"
rp_module_desc="Mali-450 wrapper for launching emulators with correct ENV"
rp_module_section="exp"

function install_mali-wrapper() {
    # Create wrapper script
    cat > /usr/local/bin/mali-run << _EOF_
#!/bin/bash
# Mali environment settings
export MALI_LIBS=/usr/local/lib/mali
export LD_LIBRARY_PATH=\$MALI_LIBS:\$LD_LIBRARY_PATH
export LIBGL_DRIVERS_PATH=\$MALI_LIBS
export EGL_PLATFORM=fbdev
export GALLIUM_DRIVER=lima

# Set Mali to high performance mode
if [ -f /sys/devices/platform/mali/devfreq/mali/governor ]; then
    echo performance > /sys/devices/platform/mali/devfreq/mali/governor
fi

# Launch the requested program
exec "\$@"
_EOF_
    chmod +x /usr/local/bin/mali-run
    
    # Create emulator run scripts to use the Mali wrapper
    find "$configdir" -name "*.sh" -exec sed -i 's/^[[:space:]]*"\$emubin"/mali-run "\$emubin"/g' {} \;
}
