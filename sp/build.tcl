add_file -type verilog "src/hdmi2.sv" "src/gen_audio.v" "src/gen_video.v" "src/top.v"
add_file -type cst "src/top.cst"
set_device GW2AR-LV18QN88C8/I7 -device_version C
set_option -verilog_std sysv2017
set_option -output_base_name project
set_option -top_module top
run all
