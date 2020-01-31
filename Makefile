FPMAKE_ARGS=--globalunitdir=$(shell scripts/find_global_unit_path.sh)

all: clean compile

clean:
	if test -x fpmake; then ./fpmake $(FPMAKE_ARGS) clean; rm ./fpmake; fi
	find . -name '*.o' -type f -exec rm {} \;
	rm -fr units manifest.xml src/turbogopher

compile:
	if ! test -x fpmake; then fpc fpmake.pp; fi
	fpc fpmake.pp
	./fpmake $(FPMAKE_ARGS) build

package: compile
	./fpmake $(FPMAKE_ARGS) archive

