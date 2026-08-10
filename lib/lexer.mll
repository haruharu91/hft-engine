{
open Core
open Parser

exception Lexing_error of string
}

let white = [' ' '\t'] +
let newline = '\r' | '\n' | "\r\n"
let id = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_' '\'']*
let int = ['0'-'9']+
let float = ['0'-'9']+ '.' ['0'-'9']*

rule token = parse
  | white       { token lexbuf }
  | newline     { Lexing.new_line lexbuf; token lexbuf }
  
  (* Japanese SOV Particles *)
  | "ga"        { PART_GA }
  | "wo" | "o"  { PART_WO }
  | "ni"        { PART_NI }
  | "de"        { PART_DE }
  | "kara"      { PART_KARA }
  | "no"        { PART_NO }

  (* Formal Proof System Directives *)
  | "rule"      { RULE }
  | "given"     { GIVEN }
  | "yield"     { YIELD }
  | "where"     { WHERE }

  (* Operators & Syntactic Symbols *)
  | "|-"        { TURNSTILE }
  | "|>"        { PIPE }
  | "="         { EQ }
  | ">="        { GTE }
  | "<="        { LTE }
  | ">"         { GT }
  | "<"         { LT }
  | "+"         { PLUS }
  | "-"         { MINUS }
  | "*"         { STAR }
  | "/"         { DIV }

  (* Delimiters *)
  | "("         { LPAREN }
  | ")"         { RPAREN }

  (* Literals & Identifiers *)
  | "#" (id as s) { ATOM s }
  | float as f  { FLOAT (Float.of_string f) }
  | int as i    { INT (Int.of_string i) }
  | id as s     { ID s }
  | eof         { EOF }
  | _ as c      { raise (Lexing_error (Printf.sprintf "Unexpected token: %c" c)) }