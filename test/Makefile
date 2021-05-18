CC=@clang-10
OPT=@opt-10
RM=@rm
SAN=@../sanitizer
COV=@./compute_coverage.sh

EXAMPLE_C_FILES = $(shell find . -type f -name '*.c' | grep -v "runtime.c")
EXAMPLE_LL_FILES = $(patsubst %.c, %.ll, $(EXAMPLE_C_FILES))
EXAMPLE_BIN_FILES = $(patsubst %.c, %, $(filter %.c, $(EXAMPLE_C_FILES)))
EXAMPLE_UNIQ_COV_FILES = $(patsubst %.c, %.uniq.cov, $(filter %.c, $(EXAMPLE_C_FILES)))

all: $(EXAMPLE_BIN_FILES)

%: %.c
	$(CC) -c -emit-llvm -S -fno-discard-value-names -O0 -Xclang -disable-O0-optnone -o $*.tmp.ll $< -g
	$(OPT) -mem2reg -S -o $*.ll $*.tmp.ll
	$(RM) -f $*.tmp.ll
	$(SAN) $*.ll
	$(CC) -o $* runtime.c $*.instrumented.ll -lm

example%.uniq.cov: compute_coverage.sh example%
	@echo example$*
	$(RM) -rf example$*_output_dir/*
	$(COV) ./example$* string_seed example$*_output_dir

json_parser.uniq.cov: compute_coverage.sh json_parser
	@echo json_parser
	$(RM) -rf json_output_dir/*
	$(COV) ./json_parser json_seed json_output_dir 180

clean:
	$(RM) -f *.ll *.output *.cov $(EXAMPLE_BIN_FILES)

test: $(EXAMPLE_UNIQ_COV_FILES)
