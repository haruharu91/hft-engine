open Ast

module AbstractValue : sig
  type t = Stack | HeapAllocated
  [@@deriving sexp, compare]

  val join : t -> t -> t
end

type abs_env = AbstractValue.t Core.Map.M(Core.String).t

val analyze_cost : abs_env -> expr -> AbstractValue.t * int
val verify_zero_allocation_hotpath : expr -> (unit, string) result