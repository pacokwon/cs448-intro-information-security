(* returns a string of random characters *)
let random_string len =
  let rec foldi num f acc =
    if num <= 0 then acc else foldi (pred num) f (f acc)
  in
  let append acc =
    (32 + Random.int (128 - 32) |> Char.chr |> String.make 1) :: acc
  in
  foldi len append []
  |> String.concat ""

let block_insert input =
  if input = "" then random_string 5 else
  let length = String.length input in
  let str = Random.int (length + 1) |> random_string in
  let split_index = length |> Random.int in
  let first = String.sub input 0 split_index in
  let second = String.sub input split_index (length - split_index) in
  first ^ str ^ second

let rec duplicate input =
  let length = String.length input in

  let idx1 = (length + 1) |> Random.int in
  let idx2 = (length + 1) |> Random.int in

  let (first_index, second_index) = (min idx1 idx2, max idx1 idx2) in
  let first = String.sub input 0 first_index in
  let middle = String.sub input first_index (second_index - first_index) in
  let last = String.sub input second_index (length - second_index) in
  first ^ middle ^ middle ^ last

let block_delete input =
  let length = String.length input in

  let idx1 = (length + 1) |> Random.int in
  let idx2 = (length + 1) |> Random.int in

  let (first_index, second_index) = (min idx1 idx2, max idx1 idx2) in
  let first = String.sub input 0 first_index in
  let last = String.sub input second_index (length - second_index) in
  first ^ last

let delete input =
  let length = String.length input in
  if length <= 1 then input else
  let take = length |> Random.int in
  let first = String.sub input 0 take in
  let second = String.sub input (take + 1) (length - take - 1) in
  first ^ second

let rec flip input =
  let length = String.length input in
  if length <= 1 then input else

  let idx1 = length |> Random.int in
  let idx2 = length |> Random.int in

  if idx1 = idx2 then flip input (* TODO: recursion? or input? *)
  else
  let (first_index, second_index) = (min idx1 idx2, max idx1 idx2) in
  let first = String.sub input 0 first_index in
  let middle = String.sub input (first_index + 1) (second_index - first_index - 1) in
  let last = String.sub input (second_index + 1) (length - second_index - 1) in

  let first_char = String.sub input first_index 1 in
  let second_char = String.sub input second_index 1 in
  first ^ second_char ^ middle ^ first_char ^ last

let mutations = [| block_insert; duplicate; block_delete; flip |]

(* apply mutation to an input `trials` times *)
let rec mutate input trials =
  if trials = 0 then input else
  let n = Random.int (Array.length mutations) in
  input
  |> Array.get mutations n         (* mutation operator *)
  |> Fun.flip mutate (trials - 1)  (* recursion *)
