MAKE=@make
DUNE=@dune
LN=@ln -sf
RM=@rm
EXE=fuzzer
SAN=sanitizer

all:
	$(DUNE) build src/main.exe
	$(DUNE) build src/sanitizer.exe
	$(LN) _build/default/src/main.exe $(EXE)
	$(LN) _build/default/src/sanitizer.exe $(SAN)

clean:
	$(MAKE) -C test clean
	$(DUNE) clean
	$(RM) -rf $(EXE) $(SAN)
