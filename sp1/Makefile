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
	mv impl/pnr/project.fs impl/project.fs
	rm -rf impl/gwsynthesis impl/pnr/* impl/temp
	mv impl/project.fs impl/pnr/project.fs
.PHONY: sim
