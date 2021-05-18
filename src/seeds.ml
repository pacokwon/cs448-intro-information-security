include Set.Make (String)

let read_file filename =
  let ic = open_in filename in
  let s = Stdlib.really_input_string ic (Stdlib.in_channel_length ic) in
  close_in ic;
  s

(*
  returns a set of file contents in `dir`

  if `dir` contains 3 files: foo, bar and baz which contains "foo", "bar" and "baz" respectively,
  then a set of ("foo", "bar", "baz") will be returned
*)
let read dir =
  (* fold through all files in `dir` *)
  Sys.readdir dir
  |> Array.fold_left
       (fun seed_inputs file ->
         Filename.concat dir file |> read_file |> Fun.flip add seed_inputs)
       empty
