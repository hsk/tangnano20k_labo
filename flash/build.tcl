add_file src/flash_pll.v
add_file src/UartTx.v
add_file src/top.sv
add_file src/top.cst
add_file src/top.sdc

set_device GW2AR-LV18QN88C8/I7 -device_version C
set_option -verilog_std sysv2017
set_option -top_module top
set_option -use_mspi_as_gpio 1

run all
