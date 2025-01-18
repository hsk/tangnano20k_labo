all:
	sv2v sim.sv ../src/hdmi2.sv > sim.v
	iverilog  -g2012 -o sim.out -s sim_top config.v sim.v
	vvp sim.out
	gtkwave -o sim.vcd -x
	make wave
wave:
	gtkwave setting.gtkw
w2:
	gtkwave -o sim.vcd
clean:
	rm -rf *.out *.vcd* sim.v
