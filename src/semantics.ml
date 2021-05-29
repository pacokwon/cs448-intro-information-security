module D = Domain
module F = Format

module type S = sig
  module Memory : D.MEMORY_DOMAIN

  module Value : D.VALUE_DOMAIN with type t = Memory.Value.t

  val eval : Llvm.llvalue -> Memory.t -> Value.t

  val filter : Llvm.llvalue -> bool -> Memory.t -> Memory.t

  val transfer_node : Llvm.llcontext -> D.Graph.Node.t -> Memory.t -> Memory.t

  val transfer_atomic : Llvm.llcontext -> Llvm.llvalue -> Memory.t -> Memory.t

  val transfer_cond :
    Llvm.llcontext -> Llvm.llvalue -> bool -> Memory.t -> Memory.t

  val transfer_phi : Llvm.llcontext -> Llvm.llvalue list -> Memory.t -> Memory.t
end

module Make (Memory : D.MEMORY_DOMAIN) : S = struct
  exception Unsupported

  module Memory = Memory
  module Value = Memory.Value

  type expr_t = Integer | Variable | Arithmetic | Comparison
  type atomic_t = Assignment | Source | Print | Jump | Noop

  let is_arithmetic lv =
    match Llvm.instr_opcode lv with
      | Llvm.Opcode.Add | Sub | Mul | UDiv | SDiv -> true
      | _ -> false

  let is_comparison lv =
    match Llvm.icmp_predicate lv with
      | Some pred -> (
        match pred with
          | Llvm.Icmp.Eq | Ne | Sge | Sgt | Sle | Slt -> true
          | _ -> false
      )
      | _ -> false

  let get_expr_type lv =
    if Llvm.is_constant lv then Integer
    else if is_arithmetic lv then Arithmetic
    else if is_comparison lv then Comparison
    else Variable

  let get_atomic_type lv =
    if Utils.is_debug lv then Noop
    else if Utils.is_source lv then Source
    else if Utils.is_print lv then Print
    else if Llvm.instr_opcode lv |> Utils.is_assignment then Assignment
    else Jump

  let rec eval e mem =
    match e with
      | e when Llvm.is_constant e -> (
        match Llvm.int64_of_const e with
          | Some int64_val -> int64_val |> Int64.to_int |> Value.of_int
          | _ -> failwith "Expression is constant, but is not integer."
      )
      | e when e |> is_arithmetic -> (
        let v1 = eval (Llvm.operand e 0) mem in
        let v2 = eval (Llvm.operand e 1) mem in
        match Llvm.instr_opcode e with
          | Llvm.Opcode.Add -> Value.add v1 v2
          | Llvm.Opcode.Sub -> Value.sub v1 v2
          | Llvm.Opcode.Mul -> Value.mul v1 v2
          | Llvm.Opcode.UDiv | Llvm.Opcode.SDiv -> Value.div v1 v2
          | _ -> raise Unsupported
      )
      | e when e |> is_comparison -> (
        match Llvm.icmp_predicate e with
          | Some pred -> (
            let v1 = eval (Llvm.operand e 0) mem in
            let v2 = eval (Llvm.operand e 1) mem in
            Value.cmp pred v1 v2
          )
          | _ -> failwith "Not an icmp predicate!"
      )
      | e -> Memory.find e mem

  let filtered_memory icmp_instr truth memory =
    match Llvm.icmp_predicate icmp_instr with
      | None -> failwith "icmp_instr is not icmp predicate";
      | Some pred ->
        let op1 = Llvm.operand icmp_instr 0 in
        let op2 = Llvm.operand icmp_instr 1 in

        let op1_is_var = get_expr_type op1 = Variable in
        let op2_is_var = get_expr_type op2 = Variable in

        let val1 = eval op1 memory in
        let val2 = eval op2 memory in

        let pred = if truth then pred else Utils.neg_pred pred in

        let refined1 = Value.filter pred val1 val2 in
        let refined2 = Value.filter (Utils.flip_pred pred) val2 val1 in

        memory
        |> (if op1_is_var then Memory.add op1 refined1 else Fun.id)
        |> (if op2_is_var then Memory.add op2 refined2 else Fun.id)

  (* `cond` contains a conditional `br` instruction *)
  let filter cond truth memory =
    match Llvm.get_branch cond with
      | Some `Conditional (icmp_instr, _, _) -> filtered_memory icmp_instr truth memory
      | _ -> failwith "Only conditional br instructions are allowed here"

  let transfer_atomic _ instr memory =
    match get_atomic_type instr with
      | Assignment ->
          (* F.printf "assignment\n"; *)
          Memory.add instr (eval instr memory) memory
      | Source ->
          (* F.printf "Source is Here!\n"; *)
          Memory.add instr Value.top memory
      (* the instruction **itself** is the variable *)
      | Print | Jump | Noop ->
          (* F.printf "noop\n"; *)
          memory

  let transfer_cond _ instr b memory = filter instr b memory

  let transfer_phi _ instrs memory =
    let fold_func memory phi_instr =
      (* `join` all the values in the phi node *)
      let joined_value = Llvm.incoming phi_instr (* all expressions in the phi node `instr` *)
      |> List.fold_left (fun acc (expr, _) ->
        (* evaluate the expression *)
        eval expr memory |> Value.join acc
      ) (Memory.find phi_instr memory) (* this should be `Value.bottom`, in normal circumstances *)
      in

      (* phi instructions are assignments, and therefore are variables *)
      Memory.add phi_instr joined_value memory
    in
    List.fold_left fold_func memory instrs

  let transfer_node llctx node memory =
    match node with
    | Domain.Graph.Node.Atomic instr -> transfer_atomic llctx instr memory
    | Domain.Graph.Node.CondBranch (instr, b) -> transfer_cond llctx instr b memory
    | Domain.Graph.Node.Phi instrs -> transfer_phi llctx instrs memory
end
