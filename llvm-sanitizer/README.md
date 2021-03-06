# SmaLLVM Sanitizer
The goal of this homework is to implement a lightweight dynamic analysis (e.g., LLVM sanitizer) that automatically checks
for divide-by-zero errors in C programs at runtime.
Students will write an instrumentation module in [src/instrument.ml](src/instrument.ml)
that adds LLVM instructions for runtime checks.
In addition, your tool will also provide a mechanism to measure code coverage that shows
the actual instructions executed when the program runs.
Concretely, your tool will perform two kinds of instumentation:
- For **all division** instructions (`UDiv` or `SDiv`), insert a function call to `__dbz_sanitizer__` in [test/runtime.c](test/runtime.c).
The function takes three arguments: the corresponding divisor, line number and column number. If the divisor is zero, it safely terminates the execution and reports the error.
- For **all** instructions, insert a function call to `__coverage__` in [test/runtime.c](test/runtime.c). The function takes two arguments: the corresponding line number and column number. When the code is executed, it saves the coverage information into a file.

In short, replace `failwith "Not implemented"` with your own implementation in [src/instrument.ml](src/instrument.ml).

## Setup
### OCaml Environment
This homework assumes that students set up the OCaml environment following the instruction in previous homework.
For details, see [this page](https://github.com/prosyslab-classroom/llvm-primer/blob/master/README.md#Installation)

### Sanitizer
After running `make` under the root directory of this repository, you can run the sanitizer with a generated LLVM IR `test/example1.ll`:
```
# run the sanitizer and create an instrumented ll file: test/example1.instrumented.ll
./sanitizer test/example1.ll
# compile the instrumented file with the provided runtime code
clang -o example1 test/example1.instrumented.ll test/runtime.c
# run the sanitized binary and see the result
./example1
Division-by-zero detected at line 5 and column 13
# see the source code coverage of the execution; X, Y at each line mean that the execution covers line X and column Y
cat example1.cov
5,15
...
```

## Instruction

### 1. Generating LLVM IR with Debug Information
For details, see [this page](https://github.com/prosyslab-classroom/llvm-primer/blob/master/README.md#generating-llvm-ir-with-debug-information).
All the steps above can be automatically done with `make` under the `test` directory.

Make sure that your tool does not instrument debug instructions (i.e., function calls to `llvm.dbg.XXX`).
You can check whether a given call instruction is a debug instruction or not using `is_debug` in [src/utils.ml](src/utils.ml).

### 2. LLVM Data Structure and APIs
For details, see [this page](https://github.com/prosyslab-classroom/llvm-primer/blob/master/README.md#llvm-data-structure-and-apis).

### 3. Inserting New Instructions
#### Declaring extern functions
You will use API function `declare_function` to declare the extern functions for monitoring (i.e., `__dbz_sanitizer__` and `__coverage__`).
The function gives you a value for the function which will be used in call instructions.

#### Getting debug information
You will use a provided utility function, `debug_location` in [src/utils.ml](src/utils.ml) to extract the debug information of a given instruction.
The function returns source information (i.e., filename, function name, line number, and column number) if the corresponding instruction has debug information.
Notice that not all instructions have debug information. If an LLVM instruction (e.g., newly generated by compiler) does not have the corresponding debug information, the function will return `None`.

#### Inserting call instructions
You will use LLVM instruction builder APIs such as `builder_before` to specify the target position of the instrumentation.
API function `build_call` will be used to place the actual function call.

## References
- [OCaml Standard Library](http://caml.inria.fr/pub/docs/manual-ocaml/libref)
- [LLVM OCaml Binding](https://llvm.moe/ocaml/Llvm.html)
- [LLVM Language Reference](https://llvm.org/docs/LangRef.html)
