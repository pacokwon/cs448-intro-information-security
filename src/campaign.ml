type env = {
  exe : string;
  seed_input_dir : string;
  output_dir : string;
  coverage_file : string;
  mutable step : int;
  mutable pass : int;
  mutable crash : int;
}

let mutate env seeds = let (min_trials, max_trials) = (8, 16) in
  min_trials + Random.int (max_trials - min_trials)
  |> Mutation.mutate seeds

(*
  this function updates all necessary states of the fuzzer

  return new seeds * coverage pair
*)
let update_seeds env success coverage new_coverage mutant seeds =
  let uncovered = Coverage.diff new_coverage coverage in
  if Coverage.is_empty uncovered then
    (seeds, coverage)
  else
    (Seeds.add mutant seeds, Coverage.union coverage new_coverage)

let sanitize_newline input =
  if input = "" then input else
  let length = String.length input in
  if input.[length - 1] = '\n' then
    String.sub input 0 (length - 1)
  else
    input

(*
  return seeds * coverage

  strategy: run until `test` yields false
*)
let run env test (seeds, coverage) =
  let mutant = Seeds.choose_one seeds |> sanitize_newline |> mutate env in
  let success = test env mutant in
  let new_coverage = Coverage.read env.coverage_file in
  update_seeds env success coverage new_coverage mutant seeds
