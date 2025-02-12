all:
	gw_sh build.tcl
	cat impl/pnr/project.rpt.txt | grep LUT
	openFPGALoader -f impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
	make p
d:
	openFPGALoader -f impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
	make p
p:
	python inp.py
r:
	screen /dev/tty.usbserial-20230306211 115200
clean:
	mv impl/pnr/project.fs impl/project.fs
	rm -rf impl/gwsynthesis impl/pnr/* impl/temp
	mv impl/project.fs impl/pnr/project.fs
