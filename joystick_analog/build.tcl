add_file src/dualshock_controller.v src/hdmi.v src/top.v src/top.cst
set_device GW2AR-LV18QN88C8/I7 -device_version C
set_option -verilog_std sysv2017
run all
