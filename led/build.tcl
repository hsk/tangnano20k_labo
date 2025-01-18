add_file -type verilog "src/led.v"
add_file -type cst "src/led.cst"
add_file -type sdc "src/led.sdc"
set_device GW2AR-LV18QN88C8/I7 -device_version C
set_option -top_module top
set_option -loading_rate 250/10
run all
