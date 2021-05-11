include Set.Make (String)

let read_file filename =
  let ic = open_in filename in
  let s = Stdlib.really_input_string ic (Stdlib.in_channel_length ic) in
  close_in ic;
  s

let read dir =
  Sys.readdir dir
  |> Array.fold_left
       (fun seed_inputs file ->
         Filename.concat dir file |> read_file |> Fun.flip add seed_inputs)
       empty
