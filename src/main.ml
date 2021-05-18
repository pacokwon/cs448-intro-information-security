module F = Format

let file_exists file =
  if Sys.file_exists file |> not then (
    F.eprintf "%s not found\n" file;
    exit 1 )

let mkdir file = if Sys.file_exists file then () else Unix.mkdir file 0o755

let sanity_check argv =
  if List.length argv <> 3 then (
    prerr_endline "usage: fuzzer [executable] [seed input dir] [output dir]";
    exit 1 );

  (* executable *)
  List.nth argv 0 |> file_exists;
  (* seed directory *)
  List.nth argv 1 |> file_exists;
  (* output directory *)
  List.nth argv 2 |> mkdir

let opts =
  [
    ( "-store_passing_input",
      Arg.Set Fuzzer.opt_store_passing_input,
      "Store all passing inputs" );
  ]

let argv = ref []

let make_absolute filename =
  if Filename.is_relative filename then
    Filename.concat (Unix.getcwd ()) filename
  else filename

let main () =
  Arg.parse opts (fun x -> argv := !argv @ [ x ]) "";
  sanity_check !argv;
  let env =
    {
      Campaign.exe = List.nth !argv 0 |> make_absolute;
      seed_input_dir = List.nth !argv 1 |> make_absolute;
      output_dir = List.nth !argv 2 |> make_absolute;
      coverage_file = (List.nth !argv 0 |> make_absolute) ^ ".cov";
      step = 0;
      pass = 0;
      crash = 0;
    }
  in
  Random.self_init ();
  Fuzzer.initialize env;
  Fuzzer.run env (Seeds.read env.seed_input_dir, Coverage.empty)

let _ = main ()
