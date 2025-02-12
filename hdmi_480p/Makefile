all:
	gw_sh build.tcl
	cat impl/pnr/project.rpt.txt | grep LUT
	make d
d:
	openFPGALoader impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
f:
	openFPGALoader -f impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
clean:
	mv impl/pnr/project.fs impl/project.fs
	rm -rf impl/gwsynthesis impl/pnr/* impl/temp
	mv impl/project.fs impl/pnr/project.fs
