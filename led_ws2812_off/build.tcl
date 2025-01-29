
set_device GW2AR-LV18QN88C8/I7 -device_version C
add_file -type verilog "src/ws2812.v"
add_file -type cst "src/ws2812.cst"
add_file -type sdc "src/ws2812.sdc"
set_option -top_module top
set_option -verilog_std v2001

run all
