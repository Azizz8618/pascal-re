CXXFLAGS = -O3 -Wall

all: pascompl dtran

pascompl: pascompl.cc
	$(CXX) $(CXXFLAGS) -o $@ $< 

dtran: dtran.cc
	$(CXX) $(CXXFLAGS) -o $@ $< 

clean:
	rm -f pascompl dtran

# PERSO pipeline needs dispak and the disk 2048 images; see PERSO.md
perso:
	tools/init-disk-2048.sh
	tools/perso-build.sh

test-perso:
	tests/run-tests.sh
