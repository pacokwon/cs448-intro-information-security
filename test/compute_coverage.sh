#!/usr/bin/env bash
if [[ $# -lt 3 ]]; then
  echo "usage: ./compute_coverage.sh <binary> <seed> <output_dir> [timeout]"
  exit 1
fi

binary=$1
seed=$2
output_dir=$3
timeout=$4

if ! [[ $timeout ]]; then
  timeout=10
fi

timeout $timeout ../fuzzer -store_passing_input $binary $seed $output_dir

if [[ -e tmp.txt ]]; then
  rm tmp.txt
fi

files=$(find $output_dir -type f)
for file in $files; do
  $binary < $file > /dev/null
  cat ${binary}.cov >> tmp.txt
done;

cov_file=${binary}.uniq.cov
sort -u tmp.txt | tee $cov_file
echo "$(wc -l $cov_file | cut -d ' ' -f 1) lines covered by fuzzer!"
