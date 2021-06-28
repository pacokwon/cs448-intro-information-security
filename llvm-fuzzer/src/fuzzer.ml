let opt_store_passing_input = ref false

(* create directories *)
let initialize env =
  [ "pass"; "crash" ]
  |> List.iter (fun dirname ->
         try Unix.mkdir (Filename.concat env.Campaign.output_dir dirname) 0o755
         with Unix.Unix_error (Unix.EEXIST, _, _) -> ())

(*
  run the executable with the given input
  NOTE: running a sanitized binary will produce coverage

  returns int * Unix.process_status
*)
let execute exe input =
  let fd_in, fd_out = Unix.pipe () in
  let devnull = Unix.openfile "/dev/null" [ Unix.O_WRONLY ] 0o644 in
  match Unix.create_process exe [| exe |] fd_in devnull devnull with
  | 0 ->
      Unix.close devnull;
      Unix.close fd_in;
      Unix.close fd_out;
      exit 0
  | pid ->
      Unix.close devnull;
      Unix.close fd_in;
      let c_str = input ^ "\n" in
      (* write the output of the program to a file named `c_str` *)
      Unix.write_substring fd_out c_str 0 (String.length c_str) |> ignore;
      let r = Unix.waitpid [] pid in
      Unix.close fd_out;
      r

let store_passing_input env input =
  let oc =
    Filename.concat env.Campaign.output_dir "pass"
    |> Fun.flip Filename.concat ("input" ^ string_of_int env.Campaign.pass)
    |> open_out
  in
  Stdlib.output_string oc (input ^ "\n");
  env.Campaign.pass <- env.Campaign.pass + 1;
  close_out oc

let store_crashing_input env input =
  let oc =
    Filename.concat env.Campaign.output_dir "crash"
    |> Fun.flip Filename.concat ("input" ^ string_of_int env.Campaign.crash)
    |> open_out
  in
  Stdlib.output_string oc (input ^ "\n");
  env.crash <- env.crash + 1;
  close_out oc

(* run an executable with given input and return if it runs without crashing *)
let test env input =
  (* run the executable with the given input *)
  match execute env.Campaign.exe input |> snd with
  | Unix.WEXITED 0 ->
      if !opt_store_passing_input then store_passing_input env input;
      true
  | Unix.WEXITED _ | Unix.WSIGNALED _ ->
      store_crashing_input env input;
      Printf.printf "%d crashes found\n" env.Campaign.crash;
      flush stdout;
      false
  | _ -> failwith "Unknown Error"

let rec run env (seeds, coverage) =
  env.Campaign.step <- env.Campaign.step + 1;
  Campaign.run env test (seeds, coverage) |> run env
