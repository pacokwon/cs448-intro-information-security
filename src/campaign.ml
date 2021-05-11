type env = {
  exe : string;
  seed_input_dir : string;
  output_dir : string;
  coverage_file : string;
  mutable step : int;
  mutable pass : int;
  mutable crash : int;
}

let mutate env input = failwith "Not implemented"

let update_seeds env success coverage new_coverage mutant seeds =
  failwith "Not implemented"

let run env test (seeds, coverage) = failwith "Not implemented"
