exception Unsupported

let string_cache = Hashtbl.create 2048

let string_of_llvalue_cache instr =
  if Hashtbl.mem string_cache instr then Hashtbl.find string_cache instr
  else
    let str = Llvm.string_of_llvalue instr |> String.trim in
    Hashtbl.add string_cache instr str;
    str

let string_of_instr = string_of_llvalue_cache

let string_of_lhs instr =
  let s = string_of_instr instr in
  let r = Str.regexp " = " in
  try
    let idx = Str.search_forward r s 0 in
    String.sub s 0 idx
  with Not_found ->
    prerr_endline ("Cannot find lhs of" ^ s);
    raise Not_found

let is_assignment = function
  | Llvm.Opcode.Invoke | Invalid2 | Add | FAdd | Sub | FSub | Mul | FMul | UDiv
  | SDiv | FDiv | URem | SRem | FRem | Shl | LShr | AShr | And | Or | Xor
  | Alloca | Load | GetElementPtr | Trunc | ZExt | SExt | FPToUI | FPToSI
  | UIToFP | SIToFP | FPTrunc | FPExt | PtrToInt | IntToPtr | BitCast | ICmp
  | FCmp | PHI | Select | UserOp1 | UserOp2 | VAArg | ExtractElement
  | InsertElement | ShuffleVector | ExtractValue | InsertValue | Call
  | LandingPad ->
      true
  | _ -> false

let is_binary_op = function
  | Llvm.Opcode.Add | FAdd | Sub | FSub | Mul | FMul | UDiv | SDiv | FDiv | URem
  | SRem | FRem | Shl | LShr | AShr | And | Or | Xor | ICmp | FCmp ->
      true
  | _ -> false

let is_unary_op = function
  | Llvm.Opcode.Trunc | ZExt | SExt | FPToUI | FPToSI | UIToFP | SIToFP
  | FPTrunc | FPExt | PtrToInt | IntToPtr | BitCast ->
      true
  | _ -> false

let is_phi instr =
  match Llvm.instr_opcode instr with Llvm.Opcode.PHI -> true | _ -> false

let is_argument exp =
  match Llvm.classify_value exp with
  | Llvm.ValueKind.Argument -> true
  | _ -> false

let string_of_exp exp =
  match Llvm.classify_value exp with
  | Llvm.ValueKind.NullValue -> "0"
  | BasicBlock | InlineAsm | MDNode | MDString | BlockAddress
  | ConstantAggregateZero | ConstantArray | ConstantDataArray
  | ConstantDataVector | ConstantExpr ->
      string_of_llvalue_cache exp
  | Argument | ConstantFP | ConstantInt ->
      let s = string_of_instr exp in
      let r = Str.regexp " " in
      let idx = Str.search_forward r s 0 in
      String.sub s (idx + 1) (String.length s - idx - 1)
  | ConstantPointerNull -> "0"
  | ConstantStruct | ConstantVector -> string_of_llvalue_cache exp
  | Function -> Llvm.value_name exp
  | GlobalIFunc | GlobalAlias -> string_of_llvalue_cache exp
  | GlobalVariable -> Llvm.value_name exp
  | UndefValue -> "undef"
  | Instruction i when is_assignment i -> string_of_lhs exp
  | Instruction _ -> string_of_instr exp

let fold_left_all_instr f a m =
  Llvm.fold_left_functions
    (fun a func ->
      if Llvm.is_declaration func then a
      else
        Llvm.fold_left_blocks
          (fun a blk -> Llvm.fold_left_instrs (fun a instr -> f a instr) a blk)
          a func)
    a m

type debug_loc = {
  filename : string;
  funname : string;
  line : int;
  column : int;
}

let debug_location llctx instr =
  let funname =
    Llvm.instr_parent instr |> Llvm.block_parent |> Llvm.value_name
  in
  let dbg = Llvm.metadata instr (Llvm.mdkind_id llctx "dbg") in
  match dbg with
  | Some s -> (
      let str = string_of_llvalue_cache s in
      let blk_mdnode = (Llvm.get_mdnode_operands s).(0) in
      let fun_mdnode = (Llvm.get_mdnode_operands blk_mdnode).(0) in
      let file_mdnode = (Llvm.get_mdnode_operands fun_mdnode).(0) in
      let filename = string_of_llvalue_cache file_mdnode in
      let filename = String.sub filename 2 (String.length filename - 3) in
      let r =
        Str.regexp "!DILocation(line: \\([0-9]+\\), column: \\([0-9]+\\)"
      in
      try
        let _ = Str.search_forward r str 0 in
        let line = Str.matched_group 1 str |> int_of_string in
        let column = Str.matched_group 2 str |> int_of_string in
        Some { filename; funname; line; column }
      with Not_found -> None )
  | None -> None

let string_of_location llctx instr =
  match debug_location llctx instr with
  | Some s ->
      s.filename ^ ":" ^ s.funname ^ ":" ^ string_of_int s.line ^ ":"
      ^ string_of_int s.column
  | None ->
      let funname =
        Llvm.instr_parent instr |> Llvm.block_parent |> Llvm.value_name
      in

      funname ^ ":0:0"

let is_llvm_function f =
  let r1 = Str.regexp "llvm\\.dbg\\..+" in
  let r2 = Str.regexp "llvm\\.lifetime\\..+" in
  Str.string_match r1 (Llvm.value_name f) 0
  || Str.string_match r2 (Llvm.value_name f) 0

let find_main llm =
  match Llvm.lookup_function "main" llm with
  | Some f -> f
  | None -> failwith "main funtion not found"

let is_debug instr =
  let callee_expr = Llvm.operand instr (Llvm.num_operands instr - 1) in
  let r1 = Str.regexp "llvm\\.dbg\\..+" in
  Str.string_match r1 (Llvm.value_name callee_expr) 0

let is_input instr =
  let callee_expr = Llvm.operand instr (Llvm.num_operands instr - 1) in
  Llvm.value_name callee_expr = "input"

let is_print instr =
  let callee_expr = Llvm.operand instr (Llvm.num_operands instr - 1) in
  Llvm.value_name callee_expr = "print"
