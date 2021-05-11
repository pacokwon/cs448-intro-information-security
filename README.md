# SmaLLVM Fuzzer
The goal of this homework is to implement a fuzzer that automatically generates inputs for software testing.
The fuzzer will run a program instumented by the sanitizer you implemented in the previous homework.
The sanitizer provides concrete information about crashes and coverage that guides the fuzzer to explore diverse of execution paths.
Students will implement core parts of fuzzing:
- Function `mutate` in [src/campaign.ml](src/campaign.ml) mutates a given input and generates a new input.
- Function `update_seeds` in [src/campaign.ml](src/campaign.ml) adds a given input into the seed pool if it is *interesting*.
- Function `run` in [src/campaign.ml](src/campaign.ml) implements one iteration of the fuzzing loop.

In short, replace `failwith "Not implemented"` your own implementation in [src/campaign.ml](src/campaign.ml)
and copy your implementation of sanitizer (`instrument.ml`) from the previous homework into `src/`.

## Setup
This homework assumes that students set up the OCaml environment following the same instruction in the previous homework.
After running `make` under the root directory of this repository, you will have two executable files `sanitizer` and `fuzzer`.
The following instruction will run the fuzzer on the instrumented binary:
```
# build sanitizer and fuzzer
make

# build a sanitized executable
cd test; make

# run the fuzzer with the executable, seed directory, and output directory
../fuzzer example1 string_seed output_dir
# kill the fuzzer at some point with Ctrl-c
# or, run the fuzzer with timeout
timeout 10 ../fuzzer example1 string_seed output_dir

# reproduce the crash with an crashing input
./example1 < output_dir/crash/input1
Divide-by-zero detected at line 9 and col 13
```

## Instructions
### Fuzzing
Function `Fuzzer.run` in [src/fuzzer.ml](src/fuzzer.ml) iteratively calls `Campaign.run` in [src/campaign.ml](src/campaign.ml) that
takes function `test`, set `seeds`, and set `coverage`:
- Function `test` evaluates a generate input (string value) and returns a boolean value that represents "pass" (`true`) and "crash" (`false`) (implemented in [src/fuzzer.ml](src/fuzzer.ml)). 
- Set `seeds` is a set of current seed inputs (implemented in [src/seeds.ml](src/seeds.ml))
- Set `coverages` is a set of pairs of covered line and column (implemented in [src/coverage.ml](src/coverage.ml)). 

Notice that `seeds` and `coverages` are implemented using OCaml Set so that students can use all the library functions of [Set](https://ocaml.org/api/Set.Make.html).

Students will define and use functions `Campaign.mutate` and `Campaign.update_seed` to mutate a given input and update a given set of seeds.
Students are allowed to change the types of `Campaign.mutate` and `Campaign.update_seed`, if they want.

After running the target program using `test`, new coverage information can be loaded using function `Coverage.read` with input `env.coverage_file`. 

Function `Campaign.run` will return an updated set of seeds and coverage.

### Environment
Record `Campaign.env` contains statistics (e.g., #step, #pass, etc) as well as other metadata.
You can simply pass the value to invoke utility functions such as `test` and use the statistics in your implementation.

### Inputs
Assume that all test programs read inputs using [fgets](https://en.cppreference.com/w/c/io/fgets).
Each input file will contain a single line.

### Target Programs
For evaluation, we will run your fuzzer on two sets of programs:
- A set of small programs: "small" programs will be similar to the provided example programs in [test](test) that take string inputs.
- A json parser: we also provide a [large program](test/json_parser.c) that implements a simple json parser.
In the program, we manually injected three bugs (find `"THIS IS A BUG!"` in the source code) for your test.
In the evaluation, we will use the same program witn more hidden bugs.

More detailed evaluation criteria will be posted on the notice board.

### Setting Up Seed Inputs
The fuzzer will run with a directory of seed inputs which will be passed as an commandline argument.
We will use the provided seed inputs [test/string_seed](test/string_seed) for string inputs and [test/json_seed](test/json_seed) for json inputs.
Notice that each line in the file will be an input as test programs use `fgets`.

### Outputs
The fullzer will output crashing inputs in a given output directory. The directory will contain all crashing inputs in directory `crash`.

Passing inputs are not stored by default. If you want to output passing inputs, run the fuzzer with option `-store_pasing_input`:
```
../fuzzer -store_passing_input example1 string_seed output_dir
```
Be careful not to generate a huge number of files.

## References
- [OCaml Standard Library](http://caml.inria.fr/pub/docs/manual-ocaml/libref)
- [LLVM OCaml Binding](https://llvm.moe/ocaml/Llvm.html)
- [LLVM Language Reference](https://llvm.org/docs/LangRef.html)
