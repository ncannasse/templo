all:
	nekoml templo/*.nml
	nekoc -link temploc.n templo/Main
	nekotools boot temploc.n
	rm -rf *.n templo/*.n
