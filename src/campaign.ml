type env = {
  exe : string;
  seed_input_dir : string;
  output_dir : string;
  coverage_file : string;
  mutable step : int;
  mutable pass : int;
  mutable crash : int;
}

let mutate_insert input =
  let length = String.length input in
  let split_index = length |> Random.int in
  let first = String.sub input 0 split_index in
  let second = String.sub input split_index (length - split_index) in
  let random_char = 32 + Random.int (128 - 32) |> Char.chr |> String.make 1 in
  first ^ random_char ^ second

let mutate_delete input =
  let length = String.length input in
  if length <= 1 then input else
  let take = length |> Random.int in
  let first = String.sub input 0 take in
  let second = String.sub input (take + 1) (length - take - 1) in
  first ^ second

let rec mutate_flip input =
  let length = String.length input in
  if length <= 1 then input else

  let idx1 = length |> Random.int in
  let idx2 = length |> Random.int in

  if idx1 = idx2 then mutate_flip input (* TODO: recursion? or input? *)
  else
  let (first_index, second_index) = (min idx1 idx2, max idx1 idx2) in
  let first = String.sub input 0 first_index in
  let middle = String.sub input (first_index + 1) (second_index - first_index - 1) in
  let last = String.sub input (second_index + 1) (length - second_index - 1) in

  let first_char = String.sub input first_index 1 in
  let second_char = String.sub input second_index 1 in
  first ^ second_char ^ middle ^ first_char ^ last

let mutations = [| mutate_insert; mutate_delete; mutate_flip |]

(* apply mutation to an input `trials` times *)
let rec mutate_helper input trials =
  if trials = 0 then input else
  let n = Random.int (Array.length mutations) in
  input
  |> Array.get mutations n                (* mutation operator *)
  |> Fun.flip mutate_helper (trials - 1)  (* recursion *)

let mutate env input = let (min_trials, max_trials) = (10, 20) in
  let trials = min_trials + Random.int (max_trials - min_trials) in
  let mutated_seed = mutate_helper input trials in
  mutated_seed

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

(*
  return seeds * coverage

  strategy: run until `test` yields false
*)
let run env test (seeds, coverage) =
  let mutant = Seeds.choose seeds |> mutate env in
  let success = test env mutant in
  let new_coverage = Coverage.read env.coverage_file in
  update_seeds env success coverage new_coverage mutant seeds
