#!/usr/bin/env bash

LL_FILE=$1
NAME=${LL_FILE%.*}

../src/main.exe $LL_FILE &&
  clang -o $NAME $NAME.instrumented.ll runtime.c &&
  ./$NAME >$NAME.output
exit 0
