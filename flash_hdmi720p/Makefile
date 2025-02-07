all:
	gw_sh build.tcl
	cat impl/pnr/project.rpt.txt | grep LUT
	openFPGALoader impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
d:
	openFPGALoader --external-flash -o 0x100000 res/sc8_3.bin
	openFPGALoader impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
f:
	openFPGALoader --external-flash -o 0x100000 res/sc8_3.bin
	openFPGALoader -f impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
clean:
	mv impl/pnr/*.fs impl/.
	rm -rf impl/gwsynthesis impl/pnr/* impl/temp
	mv impl/*.fs impl/pnr/.
