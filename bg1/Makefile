all:
	gw_sh build.tcl
	cat impl/pnr/project.rpt.txt | grep LUT
	openFPGALoader impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
d:
	openFPGALoader -f impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
clean:
	rm -rf impl
