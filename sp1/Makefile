all:
	gw_sh build.tcl
	cat impl/pnr/project.rpt.txt | grep LUT
	make d
d:
	openFPGALoader -f impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
sim:
	cd sim; make
wave:
	cd sim; make wave
clean:
	cd sim; make clean
	rm -rf impl
.PHONY: sim
