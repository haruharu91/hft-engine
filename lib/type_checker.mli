open Ast

exception TypeError of string

type env = poly_type Core.Map.M(Core.String).t

val occurs_check : string -> typ -> bool
val instantiate : poly_type -> typ
val unify : typ -> typ -> (string, typ) Core.Hashtbl.t -> unit
val unify_rows : row -> row -> (string, typ) Core.Hashtbl.t -> unit