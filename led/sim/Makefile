all:
	iverilog -o sim.out -s sim_top sim.v ../src/led.v
	vvp sim.out
	gtkwave setting.gtkw
clean:
	rm -rf *.out *.vcd
