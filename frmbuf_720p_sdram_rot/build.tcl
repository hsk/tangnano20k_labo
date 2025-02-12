add_file src/hdmi2.sv src/gen_audio.v src/serial_rx.v
add_file src/ip_sdram_tangnano20k_c.v
add_file src/table.v src/gen_video.v src/top.v
add_file src/top.cst
set_device GW2AR-LV18QN88C8/I7 -device_version C
set_option -verilog_std sysv2017
set_option -use_mspi_as_gpio 1
run all

