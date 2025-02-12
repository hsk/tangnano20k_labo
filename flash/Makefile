all:
	gw_sh build.tcl
	cat impl/pnr/project.rpt.txt | grep LUT
	make f
f:
	python a.py impl/pnr/project.fs
	openFPGALoader --external-flash -o 0x100000 text.txt
	openFPGALoader impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
	make p
f2:
	python a.py impl/pnr/project.fs 0x100000 text2.txt > impl/pnr/add.fs

	openFPGALoader --external-flash -o 0 impl/pnr/add.fs
	make p
p:
	python inp.py
r:
	screen /dev/tty.usbserial-20230306211 115200
clean:
	mv impl/pnr/project.fs impl/project.fs
	rm -rf impl/gwsynthesis impl/pnr/* impl/temp
	mv impl/project.fs impl/pnr/project.fs
