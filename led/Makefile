all:
	time gw_sh build.tcl
	cat impl/pnr/project.rpt.txt | grep LUT
	make d
d:
	openFPGALoader -f impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
sim:
	cd sim; make
clean:
	rm -rf impl
	cd sim; make clean
.PHONY: sim
