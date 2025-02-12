all:
	make vvp
	gtkwave setting.gtkw
vvp:
	iverilog -o tb.out -g2005-sv -s tb tb.sv MT48LC2M32B2_720p.v ip_sdram_tangnano20k_c.v
	vvp tb.out

clean:
	rm -rf *.out *.vcd
