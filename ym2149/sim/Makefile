all:
	sv2v sim.sv > sim.v
	sv2v ../src/YM2149.sv > YM2149.v
	iverilog -o sim.out -s sim_top sim.v YM2149.v ../src/gen_audio.v
	vvp sim.out
	rm -rf *.out sim.v YM2149.v
	gtkwave setting.gtkw
clean:
	rm -rf *.out *.vcd sim.v YM2149.v

