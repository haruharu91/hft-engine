open Core
open Ast

let parse_file (mode : syntax_mode) (input : string) : (Ast.expr, string) result =
  let lexbuf = Lexing.from_string input in
  try
    match mode with
    | SOV   -> Ok (Parser.parse_sov Lexer.token lexbuf)
    | Proof -> Ok (Parser.parse_proof Lexer.token lexbuf)
    | Sexp  -> Ok (Parser.parse_sexp Lexer.token lexbuf)
  with
  | Lexer.Lexing_error msg -> Error (Printf.sprintf "Lexer error: %s" msg)
  | Parser.Error -> Error (Printf.sprintf "Parser error at offset %d" (Lexing.lexeme_start lexbuf))

(* AST -> Target Syntax Code Printer *)
let rec print_ast (mode : syntax_mode) (expr : Ast.expr) : string =
  match mode with
  | Sexp  -> print_sexp expr
  | Proof -> print_proof expr
  | SOV   -> print_sov expr

and print_sexp = function
  | Var id -> id
  | Lit (Int i) -> Int.to_string i
  | Lit (Float f) -> Float.to_string f
  | Lit (String s) -> Printf.sprintf "#%s" s
  | Lit (Bool b) -> Bool.to_string b
  | BinOp (op, e1, e2) ->
      let op_str = match op with Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/" | Gt -> ">" | Lt -> "<" | Eq -> "=" | _ -> "op" in
      Printf.sprintf "(%s %s %s)" op_str (print_sexp e1) (print_sexp e2)
  | App (Var fn, arg) -> Printf.sprintf "(%s %s)" fn (print_sexp arg)
  | App (e1, e2) -> Printf.sprintf "(%s %s)" (print_sexp e1) (print_sexp e2)
  | RecordCons (lbl, v, rest) -> Printf.sprintf "(@%s: %s %s)" lbl (print_sexp v) (print_sexp rest)
  | _ -> "<expr>"

and print_proof = function
  | App (Var fn, RecordCons ("source", src, RecordCons ("condition", pred, RecordCons ("destination", dst, _)))) ->
      Printf.sprintf "%s |- %s (%s) |- emit @%s" (print_proof src) fn (print_proof pred) (print_proof dst)
  | BinOp (op, e1, e2) ->
      let op_str = match op with Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/" | Gt -> ">" | Lt -> "<" | Eq -> "=" | _ -> "op" in
      Printf.sprintf "%s %s %s" (print_proof e1) op_str (print_proof e2)
  | Var id -> id
  | Lit (Float f) -> Float.to_string f
  | _ -> "<expr>"

and print_sov = function
  | App (Var fn, RecordCons ("source", src, RecordCons ("condition", pred, RecordCons ("destination", dst, _)))) ->
      Printf.sprintf "%s kara  (%s) de  %s ni  %s" (print_sov src) (print_sov pred) (print_sov dst) fn
  | BinOp (op, e1, e2) ->
      let op_str = match op with Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/" | Gt -> ">" | Lt -> "<" | Eq -> "=" | _ -> "op" in
      Printf.sprintf "%s %s %s" (print_sov e1) op_str (print_sov e2)
  | Var id -> id
  | Lit (Float f) -> Float.to_string f
  | _ -> "<expr>"

let translate_file ~from_mode ~to_mode input =
  match parse_file from_mode input with
  | Ok ast -> Ok (print_ast to_mode ast)
  | Error err -> Error err