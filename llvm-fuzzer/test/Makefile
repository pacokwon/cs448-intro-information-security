CC=@clang-10
OPT=@opt-10
RM=@rm
SAN=@../sanitizer

EXAMPLE_C_FILES = $(shell find . -type f -name '*.c' | grep -v "runtime.c")
EXAMPLE_LL_FILES = $(patsubst %.c, %.ll, $(EXAMPLE_C_FILES))
EXAMPLE_BIN_FILES = $(patsubst %.c, %, $(filter %.c, $(EXAMPLE_C_FILES)))

<<<<<<< HEAD
all: $(EXAMPLE_LL_FILES)

%.ll: %.c
=======
all: $(EXAMPLE_BIN_FILES)

%: %.c
>>>>>>> fuzzer/master
	$(CC) -c -emit-llvm -S -fno-discard-value-names -O0 -Xclang -disable-O0-optnone -o $*.tmp.ll $< -g
	$(OPT) -mem2reg -S -o $*.ll $*.tmp.ll
	$(RM) -f $*.tmp.ll
	$(SAN) $*.ll
<<<<<<< HEAD
	$(CC) -o $* runtime.c $*.instrumented.ll
=======
	$(CC) -o $* runtime.c $*.instrumented.ll -lm
>>>>>>> fuzzer/master

clean:
	$(RM) -f *.ll *.output *.cov $(EXAMPLE_BIN_FILES)
