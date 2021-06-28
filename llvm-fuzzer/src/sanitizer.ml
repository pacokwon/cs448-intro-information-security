let main argv =
  if Array.length argv <> 2 then (
    prerr_endline "sanitizer: You must specify one LLVM IR file";
    prerr_endline "sanitizer: interpreter [LLVM IR file]";
    exit 1 );
  let output_name = Filename.remove_extension argv.(1) ^ ".instrumented.ll" in
  let llctx = Llvm.create_context () in
  Llvm.MemoryBuffer.of_file argv.(1)
  |> Llvm_irreader.parse_ir llctx
  |> Instrument.run llctx
  |> Llvm.print_module output_name

let _ = main Sys.argv
