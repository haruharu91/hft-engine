type lit =
  | Int of int
  | Float of float
  | Money of string * float
  | String of string
  | Bool of bool
[@@deriving sexp, compare]

type binop = Add | Sub | Mul | Div | Eq | Lt | Gt | Lte | Gte | BitAnd
[@@deriving sexp, compare]

type pattern =
  | PVar of string
  | PLit of lit
  | PWildcard
[@@deriving sexp, compare]

type expr =
  | Var of string
  | Lit of lit
  | BinOp of binop * expr * expr
  | Lambda of string * expr
  | App of expr * expr
  | RecordAccess of expr * string
  | RecordCons of string * expr * expr
  | Let of string * expr * expr
  | Match of expr * (pattern * expr) list
[@@deriving sexp, compare]

type typ =
  | TVar of string
  | TInt
  | TFloat
  | TBool
  | TArrow of typ * typ
  | TRecord of row
and row =
  | REmpty
  | RCons of string * typ * row
  | RVar of string
[@@deriving sexp, compare]

type poly_type = Scheme of string list * typ
[@@deriving sexp, compare]

type syntax_mode = SOV | Infix | Sexp
[@@deriving sexp, compare]