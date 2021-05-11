include Set.Make (struct
  type t = int * int

  let compare = compare
end)

let read coverage_file =
  let ic = open_in coverage_file in
  let rec loop set =
    match
      input_line ic |> String.split_on_char ',' |> List.map int_of_string
    with
    | [ line; col ] -> add (line, col) set |> loop
    | _ -> set
    | exception _ -> set
  in
  let set = loop empty in
  close_in ic;
  set
