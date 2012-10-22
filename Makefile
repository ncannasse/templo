all:
	-mkdir neko
	nekoml templo/*.nml
	nekoc -link temploc2.n templo/Main
	nekotools boot temploc2.n
	mv temploc2.n temploc2.old
	rm -rf *.n templo/*.n
	mv temploc2.old temploc2.n
