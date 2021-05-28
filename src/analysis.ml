module D = Domain
module F = Format

(*
  Module name: Make
  Argument: Memory constrained by D.MEMORY_DOMAIN
 *)
module Make (Memory : D.MEMORY_DOMAIN) = struct
  module Semantics = Semantics.Make (Memory)
  module Table = Domain.Table (Semantics.Memory)
  module Memory = Semantics.Memory

  let run llctx table =
    let table_fold_func node value table =
      let new_memory = Semantics.transfer_node llctx node value in (* new memory *)
      Table.add node new_memory table (* update table with new memory *)
    in

    let rec loop llctx table cnt =
      (*
        iterate through the table.
        if the table does not change in the middle of iteration, just return
       *)
      Format.printf "Iteration %d\n--------------- Table ---------------\n%a-------------------------------------\n" cnt Table.pp table;
      Table.fold table_fold_func table table
      |> fun new_table ->
          Format.printf "------------- New Table -------------\n%a-------------------------------------\n" Table.pp new_table;
          if new_table = table then new_table
          else loop llctx new_table (cnt + 1)
    in

    loop llctx table 0

  let check_instr llctx instr memory =
    match Llvm.instr_opcode instr with
    | Llvm.Opcode.Call when Utils.is_sink instr ->
        let e = Llvm.operand instr 0 in
        let v = Semantics.eval e memory in
        if Memory.Value.order Memory.Value.top v then
          let location = Utils.string_of_location llctx instr in
          F.printf "Potential Tainted-flow @@ %s (%s)\n" location
            (Utils.string_of_instr instr)
        else ()
    | Llvm.Opcode.Call when Utils.is_print instr ->
        let arg = Llvm.operand instr 0 in
        let v = Semantics.eval arg memory in
        F.printf "%s @@ %s : %a\n" (Utils.string_of_lhs arg)
          (Utils.string_of_location llctx instr)
          Memory.Value.pp v
    | Llvm.Opcode.SDiv | Llvm.Opcode.UDiv ->
        let e = Llvm.operand instr 1 in
        let v = Semantics.eval e memory in
        let zero = Memory.Value.of_int 0 in
        if Memory.Value.order zero v then
          let location = Utils.string_of_location llctx instr in
          let exp = Utils.string_of_exp e in
          F.printf "Potential Division-by-zero @@ %s, %s = %a\n" location exp
            Memory.Value.pp v
        else ()
    | _ -> ()

  let check llctx table =
    Table.iter
      (fun node memory ->
        match node with
        | D.Graph.Node.Atomic instr -> check_instr llctx instr memory
        | _ -> ())
      table
end
