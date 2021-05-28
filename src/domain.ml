module F = Format

module type SET = sig
  type t

  val compare : t -> t -> int

  val pp : Format.formatter -> t -> unit
end

(*
  A lattice should define these functions
 *)
module type LATTICE = sig
  include SET

  val bottom : t

  val top : t

  val order : t -> t -> bool

  val join : t -> t -> t

  val meet : t -> t -> t
end

(*
  Value Domain. Basically a set with additional operators
 *)
module type VALUE_DOMAIN = sig
  include LATTICE

  val of_int : int -> t

  val of_src : t

  val of_sanitizer : t

  val add : t -> t -> t

  val sub : t -> t -> t

  val mul : t -> t -> t

  val div : t -> t -> t

  val cmp : Llvm.Icmp.t -> t -> t -> t

  val filter : Llvm.Icmp.t -> t -> t -> t
end

(*
  Variable: SET of llvalues
 *)
module Variable : SET with type t = Llvm.llvalue = struct
  type t = Llvm.llvalue

  let compare = compare

  let pp fmt v =
    (try Utils.string_of_lhs v with Not_found -> Llvm.string_of_llvalue v)
    |> Format.fprintf fmt "Variable %s"
end

(*
  Memory Domain. Basically a set with additional operators
 *)
module type MEMORY_DOMAIN = sig
  include LATTICE

  (*
    Memory is a mapping of Identifier -> Value.
    We define the Value here.
   *)
  module Value : VALUE_DOMAIN

  val add : Variable.t -> Value.t -> t -> t

  val find : Variable.t -> t -> Value.t
end

module Graph = struct
  module Node = struct
    type t =
      | Atomic of Llvm.llvalue
      | Phi of Llvm.llvalue list
      | CondBranch of Llvm.llvalue * bool

    let compare = compare

    let pp fmt = function
      | Atomic instr -> Utils.string_of_instr instr |> Format.fprintf fmt "%s"
      | Phi instrs ->
          List.iter
            (fun instr ->
              Format.fprintf fmt "%s\n" (Utils.string_of_instr instr))
            instrs
      | CondBranch (instr, b) ->
          Format.fprintf fmt "%s (%s)"
            (Utils.string_of_instr instr)
            (Bool.to_string b)
  end

  let last_node current_block =
    Llvm.fold_left_blocks
      (fun labels b ->
        match Llvm.instr_end b with
        | Llvm.After instr -> (
            match Llvm.instr_opcode instr with
            | Llvm.Opcode.Br -> (
                match Llvm.get_branch instr with
                | Some (`Conditional (_, b1, b2)) ->
                    if b1 = current_block then
                      Node.CondBranch (instr, true) :: labels
                    else if b2 = current_block then
                      Node.CondBranch (instr, false) :: labels
                    else labels
                | Some (`Unconditional b) ->
                    if b = current_block then Node.Atomic instr :: labels
                    else labels
                | _ -> labels)
            | _ -> labels)
        | _ -> labels)
      []
      (Llvm.block_parent current_block)

  let rec all_prev_phi instr =
    match Llvm.instr_pred instr with
    | Llvm.After p -> all_prev_phi p @ [ instr ]
    | Llvm.At_start _ -> [ instr ]

  let rec pred node =
    match node with
    | Node.Atomic l | Node.CondBranch (l, _) -> (
        match Llvm.instr_pred l with
        | Llvm.At_start _ ->
            let current_block = Llvm.instr_parent l in
            last_node current_block
        | Llvm.After prev_instr -> (
            match Llvm.instr_opcode prev_instr with
            | Llvm.Opcode.PHI -> [ Node.Phi (all_prev_phi prev_instr) ]
            | _ -> [ Node.Atomic prev_instr ]))
    | Node.Phi (l :: _) -> pred (Node.Atomic l)
    | _ -> []
end

module type SIGN = sig
  type t = Bot | Pos | Neg | Zero | Top

  (* := means "destructive substitution" *)
  include VALUE_DOMAIN with type t := t
end

module Sign : SIGN = struct
  type t = Bot | Pos | Neg | Zero | Top

  let compare = compare

  let bottom = Bot

  let top = Top

  let of_src = Top

  let of_sanitizer = Top

  (*
    reflexivity: a <= a for all a
    antisymettry: a <= b and b <= a implies a = b
    transitivity: a <= b and b <= c implies a <= c
   *)
  let order x y = match x, y with
    | Top, _ | _, Bot
    | Pos, Pos | Zero, Zero | Neg, Neg -> true
    | _ -> false

  let join x y = match x, y with
    | Top, _ | _, Top -> Top
    | Bot, other -> other
    | other, Bot -> other
    | _x, _y when _x = _y -> _x
    | _ -> Top

  let meet x y = match x, y with
    | Bot, _ | _, Bot -> Bot
    | Top, other -> other
    | other, Top -> other
    | _x, _y when _x = _y -> _x
    | _ -> Bot

  let of_int i = match i with
    | num when num > 0 -> Pos
    | num when num < 0 -> Neg
    | _ -> Zero

  let add v1 v2 = match v1, v2 with
    | Pos, Pos | Pos, Zero | Zero, Pos        -> Pos
    | Neg, Neg | Neg, Zero | Zero, Neg        -> Neg
    | Zero, Zero                              -> Zero
    | Bot, _ | _, Bot                         -> Bot
    | Top, _ | _, Top | Pos, Neg | Neg, Pos   -> Top

  let sub v1 v2 = match v1, v2 with
    | Pos, Neg | Pos, Zero | Zero, Neg        -> Pos
    | Neg, Pos | Neg, Zero | Zero, Pos        -> Neg
    | Zero, Zero                              -> Zero
    | Bot, _ | _, Bot                         -> Bot
    | Top, _ | _, Top | Pos, Pos | Neg, Neg   -> Top

  let mul v1 v2 = match v1, v2 with
    | Pos, Pos | Neg, Neg -> Pos
    | Pos, Neg | Neg, Pos -> Neg
    | Zero, _ | _, Zero   -> Zero
    | Bot, _ | _, Bot     -> Bot
    | Top, _ | _, Top     -> Top

  let div v1 v2 = match v1, v2 with
    | Bot, _ | _, Bot | _, Zero -> Bot
    | Zero, Neg | Zero, Pos -> Zero
    | _ -> Top

  (*
    Pos means true, Zero means false
   *)
  let rec cmp (pred: Llvm.Icmp.t) v1 v2 = match pred with
    | Llvm.Icmp.Eq -> (
      match v1, v2 with
        | Bot, _ | _, Bot -> Bot
        | Zero, Zero -> Pos
        | Zero, Neg | Neg, Zero | Zero, Pos
        | Pos, Zero | Pos, Neg | Neg, Pos -> Zero
        | _, _ -> Top
    )
    | Llvm.Icmp.Sgt -> (
      match v1, v2 with
        | Bot, _ | _, Bot -> Bot
        | Neg, Zero | Neg, Pos | Zero, Zero | Zero, Pos -> Zero
        | Zero, Neg | Pos, Neg | Pos, Zero -> Pos
        | _ -> Top
    )
    | Llvm.Icmp.Sge -> (
      match v1, v2 with
        | Bot, _ | _, Bot -> Bot
        | Neg, Zero | Neg, Pos | Zero, Pos -> Zero
        | Zero, Neg | Pos, Neg | Zero, Zero | Pos, Zero -> Pos
        | _ -> Top
    )
    | Llvm.Icmp.Ne | Llvm.Icmp.Slt | Llvm.Icmp.Sle -> (
      match cmp (Utils.neg_pred pred) v1 v2 with
        | Pos -> Zero
        | Zero -> Pos
        | Neg -> failwith "Invalid Result!"
        | _ as result -> result
    )
    | _ -> failwith "Unsigned comparisons are not implemented!"

  (*
    return a sound refinement of abstract numerical value `v1`
    with respect to predicate pred and abstract numerical value `v2`
   *)
  let filter pred v1 v2 = match pred with
    | Llvm.Icmp.Eq -> meet v1 v2
    | Llvm.Icmp.Ne -> v1
    | Llvm.Icmp.Sgt -> (
      match v2 with
        | Pos | Zero -> Pos
        | _ -> v1
    )
    | Llvm.Icmp.Sge -> (
      match v2 with
        | Pos -> Pos
        | _ -> v1
    )
    | Llvm.Icmp.Slt -> (
      match v2 with
        | Neg | Zero -> Neg
        | _ -> v1
    )
    | Llvm.Icmp.Sle -> (
      match v2 with
        | Neg -> Neg
        | _ -> v1
    )
    | Llvm.Icmp.Ugt
    | Llvm.Icmp.Uge
    | Llvm.Icmp.Ule
    | Llvm.Icmp.Ult -> failwith "Unsigned filters are not implemented!"

  let pp fmt = function
    | Bot -> Format.fprintf fmt "Bot"
    | Pos -> Format.fprintf fmt "Pos"
    | Neg -> Format.fprintf fmt "Neg"
    | Zero -> Format.fprintf fmt "Zero"
    | Top -> Format.fprintf fmt "Top"
end

module Taint : VALUE_DOMAIN = struct
  type t = None | Taint

  let compare = compare

  let bottom = None

  let top = Taint

  let of_int _ = None

  let of_src = Taint

  let of_sanitizer = None

  let order x y =
    match x, y with
      | None, Taint | None, None | Taint, Taint -> true
      | Taint, None -> false

  let join x y =
    match x, y with
      | None, None -> None
      | _ -> Taint

  let meet x y =
    match x, y with
      | Taint, Taint -> Taint
      | _ -> None

  let add x y =
    match x, y with
      | None, None -> None
      | _ -> Taint

  let sub = add

  let mul = add

  let div = add

  let cmp _ = add

  (*
    return a sound refinement of abstract numerical value `v1`
    with respect to predicate pred and abstract numerical value `v2`
   *)
  let filter pred v1 v2 =
    match pred with
      | Llvm.Icmp.Eq -> meet v1 v2
      | _ -> v1

  let pp fmt = function
    | None -> Format.fprintf fmt "Bot"
    | Taint -> Format.fprintf fmt "Taint"
end

module Memory (Value : VALUE_DOMAIN) :
  MEMORY_DOMAIN with type Value.t = Value.t = struct
  module M = Map.Make (Variable)
  module Value = Value

  (* M.t -> Value.t mapping *)
  type t = Value.t M.t

  let bottom = M.empty

  let top = M.empty (* NOTE: We do not use top *)

  let add = M.add

  let compare = compare

  let find x m = try M.find x m with Not_found -> Value.bottom

  (* For all variables in m1, compare the corresponding values *)
  let order m1 m2 = M.fold (
    fun lv val1 acc ->
      (* early return if acc is false *)
      if not acc then acc else
      (* get value2 from m2 *)
      let val2 = find lv m2 in
      Value.order val1 val2
  ) m1 true

  (* Join valuess that have the same key *)
  let join m1 m2 = M.union (fun _ val1 val2 -> Some (Value.join val1 val2)) m1 m2

  let meet _ _ = failwith "NOTE: We do not use meet"

  let pp fmt m =
    M.iter (fun k v -> F.fprintf fmt "%a -> %a\n" Variable.pp k Value.pp v) m
end

module Table (M : MEMORY_DOMAIN) = struct
  (*
    Graph.Node can be used because it satisfies as Map.OrderedType,
    which needs `t` and `compare`
   *)
  include Map.Make (Graph.Node)

  let last_phi instr =
    match Llvm.instr_succ instr with
    | Llvm.Before next -> (
        match Llvm.instr_opcode next with Llvm.Opcode.PHI -> false | _ -> true)
    | _ -> true

  (* construct bottom table for nodes *)
  let init llm =
    Utils.fold_left_all_instr
      (fun table instr ->
        match Llvm.instr_opcode instr with
        | Llvm.Opcode.Br -> (
            match Llvm.get_branch instr with
            | Some (`Conditional _) ->
                table
                |> add (Graph.Node.CondBranch (instr, true)) M.bottom
                |> add (Graph.Node.CondBranch (instr, false)) M.bottom
            | _ -> add (Graph.Node.Atomic instr) M.bottom table)
        | Llvm.Opcode.PHI ->
            if last_phi instr then
              add (Graph.Node.Phi (Graph.all_prev_phi instr)) M.bottom table
            else table
        | _ -> add (Graph.Node.Atomic instr) M.bottom table)
      empty llm

  let find label tbl = try find label tbl with Not_found -> M.bottom

  let pp fmt tbl =
    iter (fun k v -> F.fprintf fmt "%a -> %a\n" Graph.Node.pp k M.pp v) tbl
end
