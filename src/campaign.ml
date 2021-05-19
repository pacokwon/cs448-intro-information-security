type env = {
  exe : string;
  seed_input_dir : string;
  output_dir : string;
  coverage_file : string;
  mutable step : int;
  mutable pass : int;
  mutable crash : int;
}

let random_char () =
  (32 + Random.int (128 - 32) |> Char.chr |> String.make 1)

(* returns a string of random characters *)
let random_string len =
  let rec foldi num f acc =
    if num <= 0 then acc else foldi (pred num) f (f acc)
  in
  let append acc =
    random_char () :: acc
  in
  foldi len append []
  |> String.concat ""

let random_json_value () =
  let rec helper depth =
    if depth >= 4 then "null" else
    let random_json_object () =
      let rec craft size acc =
        if size = 0 then acc else
        let key = "\"" ^ random_string 10 ^ "\"" in
        let value = depth |> succ |> helper in
        (key ^ ": " ^ value) :: acc |> craft (size - 1)
      in
      let pairs = 1 + Random.int 5 |> Fun.flip craft [] in
      "{" ^ (String.concat ", " pairs) ^ "}"
    in
    let random_json_array () =
      let rec craft size acc =
        if size = 0 then acc else
        let value = depth |> succ |> helper in
        value :: acc |> craft (size - 1)
      in
      let elems = 1 + Random.int 5 |> Fun.flip craft [] in
      "[" ^ (String.concat ", " elems) ^ "]"
    in
    match Random.int 7 with
    | 0 -> Random.bool () |> string_of_bool
    | 1 -> Random.int 100 |> string_of_int
    | 2 -> Random.float 10.0 |> string_of_float
    | 3 -> random_string 10 |> fun str -> "\"" ^ str ^ "\""
    | 4 -> "null"
    | 5 -> random_json_array ()
    | 6 -> random_json_object ()
    | _ -> failwith "Never happens"
  in

  helper 0

let string_rev input =
  let length = String.length input in
  String.init length (fun i -> input.[length - i - 1])

let block_insert (seeds: Seeds.t) input =
  if input = "" then random_string 5 else
  let length = String.length input in
  let str = Random.int (length + 1) |> random_string in
  let split_index = length |> Random.int in
  let first = String.sub input 0 split_index in
  let second = String.sub input split_index (length - split_index) in
  first ^ str ^ second

let rec block_duplicate (seeds: Seeds.t) input =
  let length = String.length input in

  let idx1 = (length + 1) |> Random.int in
  let idx2 = (length + 1) |> Random.int in

  let (first_index, second_index) = (min idx1 idx2, max idx1 idx2) in
  let first = String.sub input 0 first_index in
  let middle = String.sub input first_index (second_index - first_index) in
  let last = String.sub input second_index (length - second_index) in
  first ^ middle ^ middle ^ last

let mirror (seeds: Seeds.t) input =
  let length = String.length input in
  if length <= 1 then input else
  let idx = 1 + (Random.int length / 2) in
  let half = String.sub input 0 idx in
  half ^ (string_rev half)


let block_delete (seeds: Seeds.t) input =
  let length = String.length input in

  let idx1 = (length + 1) |> Random.int in
  let idx2 = (length + 1) |> Random.int in

  let (first_index, second_index) = (min idx1 idx2, max idx1 idx2) in
  let first = String.sub input 0 first_index in
  let last = String.sub input second_index (length - second_index) in
  first ^ last

let insert (seeds: Seeds.t) input =
  let length = String.length input in
  if length <= 1 then input else
  let index = (length + 1) |> Random.int in
  let first = String.sub input 0 index in
  let second = String.sub input index (length - index) in
  first ^ random_char () ^ second

let delete (seeds: Seeds.t) input =
  let length = String.length input in
  if length <= 1 then input else
  let take = length |> Random.int in
  let first = String.sub input 0 take in
  let second = String.sub input (take + 1) (length - take - 1) in
  first ^ second

let flip (seeds: Seeds.t) input =
  let length = String.length input in
  if length <= 0 then input else
  let index = length |> Random.int in
  let first = String.sub input 0 index in
  let second = String.sub input (index + 1) (length - index - 1) in
  first ^ random_char () ^ second

let rec swap (seeds: Seeds.t) input =
  let length = String.length input in
  if length <= 1 then input else

  let idx1 = length |> Random.int in
  let idx2 = length |> Random.int in

  if idx1 = idx2 then swap seeds input (* TODO: recursion? or input? *)
  else
  let (first_index, second_index) = (min idx1 idx2, max idx1 idx2) in
  let first = String.sub input 0 first_index in
  let middle = String.sub input (first_index + 1) (second_index - first_index - 1) in
  let last = String.sub input (second_index + 1) (length - second_index - 1) in

  let first_char = String.sub input first_index 1 in
  let second_char = String.sub input second_index 1 in
  first ^ second_char ^ middle ^ first_char ^ last

let crossover (seeds: Seeds.t) seed1 =
  let seed2 = Seeds.choose_one seeds in

  let length1 = String.length seed1 in
  let length2 = String.length seed2 in

  (String.sub seed1 0 (length1 / 2)) ^ String.sub seed2 (length2 / 2) (length2 / 2)

let mutations = [| block_insert; block_delete; block_delete; swap |]
(* let mutations = [| insert; delete; swap; flip |] *)

(* apply mutation to an input `trials` times *)
let rec mutate_helper (seeds: Seeds.t) input trials =
  (* if String.contains input '\n' then exit 1 else *)
  if trials = 0 then input else
  let n = Random.int (Array.length mutations) in
  let mutant = input |> (Array.get mutations n) seeds (* mutation operator *) in
  mutate_helper seeds mutant (trials - 1)  (* recursion *)

let mutate env seeds input = let (min_trials, max_trials) = (8, 16) in
  min_trials + Random.int (max_trials - min_trials)
  |> mutate_helper seeds input

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
  let mutant = Seeds.choose_one seeds |> sanitize_newline |> mutate env seeds in
  let success = test env mutant in
  let new_coverage = Coverage.read env.coverage_file in
  update_seeds env success coverage new_coverage mutant seeds
