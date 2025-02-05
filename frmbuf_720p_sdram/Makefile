all:
	gw_sh build.tcl
	cat impl/pnr/project.rpt.txt | grep LUT
	make d
d:
	openFPGALoader impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
	sleep 1
	make p
f:
	openFPGALoader -f impl/pnr/project.fs
	cat impl/pnr/project.rpt.txt | grep LUT
	sleep 1
	make p
p:
	python inp.py
clean:
	cd sim; make clean

	mv impl/pnr/*.fs impl/.
	rm -rf impl/gwsynthesis impl/pnr/* impl/temp
	mv impl/*.fs impl/pnr/.
