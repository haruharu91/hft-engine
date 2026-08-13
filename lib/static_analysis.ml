open Core
open Ast

module AbstractValue = struct
  type t = Stack | HeapAllocated
  [@@deriving sexp, compare]

  let join v1 v2 =
    match v1, v2 with
    | Stack, Stack -> Stack
    | _ -> HeapAllocated
end

type abs_env = AbstractValue.t Map.M(String).t

let rec analyze_cost (env : abs_env) (e : expr) : AbstractValue.t * int =
  match e with
  | Lit _ | Var _ -> (Stack, 0)
  | BinOp (_, e1, e2) ->
      let v1, c1 = analyze_cost env e1 in
      let v2, c2 = analyze_cost env e2 in
      (AbstractValue.join v1 v2, c1 + c2 + 1)
  | RecordAccess (e1, _) ->
      let v1, c1 = analyze_cost env e1 in
      (v1, c1 + 1)
  | RecordCons (_, e_val, e_rest) ->
      let _, c1 = analyze_cost env e_val in
      let _, c2 = analyze_cost env e_rest in
      (HeapAllocated, c1 + c2 + 10)
  | Let (v, e1, e2) ->
      let abs_v1, c1 = analyze_cost env e1 in
      let new_env = Map.set env ~key:v ~data:abs_v1 in
      let abs_v2, c2 = analyze_cost new_env e2 in
      (AbstractValue.join abs_v1 abs_v2, c1 + c2)
  | Match (scrutinee, cases) ->
      let _, scrutinee_cost = analyze_cost env scrutinee in
      let cases_cost = 
        List.fold cases ~init:0 ~f:(fun acc (_, body) -> 
          let _, body_cost = analyze_cost env body in
          acc + body_cost) 
      in
      (HeapAllocated, scrutinee_cost + cases_cost + 10)
  | Lambda _ | App _ ->
      (HeapAllocated, 100)

let verify_zero_allocation_hotpath (e : expr) : (unit, string) result =
  let abs_val, cost = analyze_cost (Map.empty (module String)) e in
  match abs_val with
  | Stack -> Ok ()
  | HeapAllocated ->
      Error (Printf.sprintf "Analysis Rejected: Hot-path allocation detected (Estimated Cycles: %d)" cost)