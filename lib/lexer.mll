{
open Core
open Parser

exception Lexing_error of string
}

rule token = parse
  | [' ' '\t']+
      { token lexbuf }
  | '\r' | '\n' | "\r\n"
      { Lexing.new_line lexbuf; token lexbuf }
  
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

  (* Pattern Matching & Boolean Keywords *)
  | "match"     { MATCH }
  | "with"      { WITH }
  | "true"      { TRUE }
  | "false"     { FALSE }
  | "|"         { PIPE }
  | "->"        { ARROW }
  | "_"         { UNDERSCORE }

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

  (* Money Literals - Placed above floats to avoid shadowing *)
  | '$' (['0'-'9']+ '.' ['0'-'9']* as num) { 
      MONEY ("$", Float.of_string num) 
    }
  | '$' (['0'-'9']+ as num) { 
      MONEY ("$", Float.of_string num) 
    }

  (* Literals & Identifiers *)
  | '#' (['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_' '\'']* as s) { ATOM s }
  | '@' (['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_' '\'']* as s) { ATOM s }
  | ['0'-'9']+ '.' ['0'-'9']* as f { FLOAT (Float.of_string f) }
  | ['0'-'9']+ as i               { INT (Int.of_string i) }
  | ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_' '\'']* as s { ID s }
  | eof                           { EOF }
  | _ as c                        { raise (Lexing_error (Printf.sprintf "Unexpected token: %c" c)) }