let coverage_function llctx llm =
  let void_type = Llvm.void_type llctx in
  let i32_type = Llvm.i32_type llctx in
  let coverage_type = Llvm.function_type void_type [| i32_type; i32_type |] in
  Llvm.declare_function "__coverage__" coverage_type llm

let sanitizer_function llctx llm =
  let void_type = Llvm.void_type llctx in
  let i32_type = Llvm.i32_type llctx in
  let sanitizer_type = Llvm.function_type void_type [| i32_type; i32_type; i32_type |] in
  Llvm.declare_function "__dbz_sanitizer__" sanitizer_type llm

let run llctx llm =
  let coverage = coverage_function llctx llm in
  let sanitizer = sanitizer_function llctx llm in

  let collect_instrs lst _lv =
    match _lv with
    | lv when Utils.is_debug lv |> not -> lv :: lst
    | _ -> lst
  in

  let insert_sanitizer_and_coverage lv =
    let builder = Llvm.builder_before llctx lv in
    let location = Utils.debug_location llctx lv in

    match location with
    | None -> ();
    | Some _location ->
      let line = Llvm.const_int (Llvm.i32_type llctx) (_location.line) in
      let col = Llvm.const_int (Llvm.i32_type llctx) (_location.column) in

      (* if instruction is udiv or sdiv, insert sanitizer above coverage *)
      match Llvm.instr_opcode lv with
      | Llvm.Opcode.UDiv | Llvm.Opcode.SDiv ->
        let divisor = Llvm.operand lv 1 in
        Llvm.build_call sanitizer [| divisor; line; col |] "" builder |> ignore;
      | _ -> (); |> ignore;

      (* Insert __coverage__ *)
      Llvm.build_call coverage [| line; col |] "" builder |> ignore;
  in

  let instrs = Utils.fold_left_all_instr collect_instrs [] llm in
  List.iter insert_sanitizer_and_coverage instrs;

  llm
