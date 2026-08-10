open Core
open Ast

let parse_file (mode : syntax_mode) (input : string) : (expr, string) result =
  let lexbuf = Lexing.from_string input in
  try
    match mode with
    | SOV -> Ok (Parser.parse_sov Lexer.token lexbuf)
    | Infix -> Ok (Parser.parse_infix Lexer.token lexbuf)
    | Sexp -> Ok (Parser.parse_sexp Lexer.token lexbuf)
  with
  | Failure msg -> Error (Printf.sprintf "Lexer error: %s" msg)
  | _ -> Error "Parser error: syntax error"

let print_ast (mode : syntax_mode) (e : expr) : string =
  match mode with
  | SOV -> Sexp.to_string_hum (sexp_of_expr e)
  | Infix -> Sexp.to_string_hum (sexp_of_expr e)
  | Sexp -> Sexp.to_string_hum (sexp_of_expr e)

let translate_file ~(from_mode : syntax_mode) ~(to_mode : syntax_mode) (input : string) : (string, string) result =
  match parse_file from_mode input with
  | Error err -> Error err
  | Ok ast -> Ok (print_ast to_mode ast)