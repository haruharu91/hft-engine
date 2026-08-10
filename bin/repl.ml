open Core
open Hft_engine

type active_dialect = 
  | SOV 
  | Infix 
  | Sexp

let dialect_to_string = function
  | SOV -> "SOV"
  | Infix -> "Infix"
  | Sexp -> "S-Expression"

let rec loop (current_dialect : active_dialect) =
  Printf.printf "\nhft [%s]> " (dialect_to_string current_dialect);
  Out_channel.flush Out_channel.stdout;
  match In_channel.input_line In_channel.stdin with
  | None | Some "exit" | Some "quit" -> print_endline "Goodbye!"
  | Some input when String.is_empty (String.strip input) -> loop current_dialect
  | Some input when String.is_prefix input ~prefix:":sov" ->
      print_endline "Switched dialect to SOV";
      loop SOV
  | Some input when String.is_prefix input ~prefix:":infix" ->
      print_endline "Switched dialect to Infix";
      loop Infix
  | Some input when String.is_prefix input ~prefix:":sexp" ->
      print_endline "Switched dialect to S-Expression";
      loop Sexp
  | Some input ->
      let dialect_arg = match current_dialect with
        | SOV -> Ast.SOV
        | Infix -> Ast.Infix
        | Sexp -> Ast.Sexp
      in
      (match Translator.parse_file dialect_arg input with
      | Ok ast ->
          print_endline "\n[Parsed AST Successfully]:";
          print_endline (Sexp.to_string_hum (Ast.sexp_of_expr ast))
      | Error err ->
          Printf.printf "\n[Parse Error]: %s\n" err);
      loop current_dialect

let () =
  print_endline "=== HFT Notation Playground REPL ===";
  print_endline "Commands: :sov, :infix, :sexp to switch dialects, or 'exit' to quit.";
  loop SOV