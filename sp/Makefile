all:
	gw_sh build.tcl
	cat impl/pnr/project.rpt.txt | grep LUT
	make d
d:
	openFPGALoader impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
sim:
	cd sim; make
wave:
	cd sim; make wave
clean:
	rm -rf impl
	cd sim; make clean
.PHONY: sim
