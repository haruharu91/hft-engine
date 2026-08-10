open Core
open Ast

exception TypeError of string

type env = poly_type Map.M(String).t

let rec occurs_check v = function
  | TVar name -> String.equal v name
  | TArrow (a, b) -> occurs_check v a || occurs_check v b
  | _ -> false

let instantiate (Scheme (quantified, t)) : typ =
  let subst = 
    List.map quantified ~f:(fun q -> (q, TVar (q ^ "_fresh")))
    |> Map.of_alist_exn (module String)
  in
  let rec apply = function
    | TVar name -> Map.find subst name |> Option.value ~default:(TVar name)
    | TArrow (a, b) -> TArrow (apply a, apply b)
    | TRecord row -> TRecord (apply_row row)
    | primitive -> primitive
  and apply_row = function
    | RCons (lbl, ty, rest) -> RCons (lbl, apply ty, apply_row rest)
    | RVar name -> 
        (match Map.find subst name with
         | Some (TRecord r) -> r
         | _ -> RVar name)
    | REmpty -> REmpty
  in
  apply t

let rec unify (t1 : typ) (t2 : typ) (subst : (string, typ) Hashtbl.t) : unit =
  match t1, t2 with
  | TInt, TInt | TFloat, TFloat | TBool, TBool -> ()
  | TVar a, TVar b when String.equal a b -> ()
  | TVar a, t | t, TVar a ->
      if occurs_check a t then
        raise (TypeError (Printf.sprintf "Occurs check failed for %s" a))
      else
        Hashtbl.set subst ~key:a ~data:t
  | TArrow (a1, b1), TArrow (a2, b2) ->
      unify a1 a2 subst;
      unify b1 b2 subst
  | TRecord r1, TRecord r2 -> unify_rows r1 r2 subst
  | _ -> raise (TypeError "Type mismatch in query expression")

and unify_rows r1 r2 subst =
  match r1, r2 with
  | REmpty, REmpty -> ()
  | RCons (lbl1, ty1, rest1), RCons (lbl2, ty2, rest2) when String.equal lbl1 lbl2 ->
      unify ty1 ty2 subst;
      unify_rows rest1 rest2 subst
  | _ -> raise (TypeError "Row unification failed")