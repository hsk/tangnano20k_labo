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
sc8_3:
	python add.py impl/pnr/project.fs 0x100000 res/sc8_3.bin > impl/pnr/sc8_3.fs
	openFPGALoader -f impl/pnr/sc8_3.fs
sc8:
	python add.py impl/pnr/project.fs 0x100000 res/sc8.bin > impl/pnr/sc8.fs
	openFPGALoader -f impl/pnr/sc8.fs

clean:
	mv impl/pnr/*.fs impl/.
	rm -rf impl/gwsynthesis impl/pnr/* impl/temp
	mv impl/*.fs impl/pnr/.
