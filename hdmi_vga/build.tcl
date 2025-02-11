add_file src/hdmi_vga.v
add_file src/top.v
add_file src/top.cst

set_device GW2AR-LV18QN88C8/I7 -device_version C
set_option -top_module top
run all
