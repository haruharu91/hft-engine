open Core
open Hft_engine

let detect_mode_from_filename (filename : string) : Ast.syntax_mode =
  if String.is_suffix filename ~suffix:".sov.hft" then SOV
  else if String.is_suffix filename ~suffix:".proof.hft" then Proof
  else if String.is_suffix filename ~suffix:".sexp.hft" then Sexp
  else failwith (Printf.sprintf "Unsupported extension on file '%s'. Expected .sov.hft, .proof.hft, or .sexp.hft" filename)

let parse_content mode content =
  let lexbuf = Lexing.from_string content in
  try
    match mode with
    | Ast.SOV   -> Ok (Parser.parse_sov Lexer.token lexbuf)
    | Ast.Proof -> Ok (Parser.parse_proof Lexer.token lexbuf)
    | Ast.Sexp  -> Ok (Parser.parse_sexp Lexer.token lexbuf)
  with
  | Lexer.Lexing_error msg -> Error (Printf.sprintf "Lexer error: %s" msg)
  | Parser.Error -> Error (Printf.sprintf "Parser error at offset %d" (Lexing.lexeme_start lexbuf))

let () =
  let sample_sov = "tick_stream kara (price > 100.0) de matching_engine ni filter_and_emit" in
  let sample_proof = "tick_stream |- filter (price > 100.0) |- emit @matching_engine" in
  let sample_sexp = "(filter_and_emit tick_stream (gt price 100.0) matching_engine)" in

  Printf.printf "=== HFT Engine Multi-Syntax Parsing Verification ===\n\n";

  List.iter
    [ ("queries/example.sov.hft", sample_sov);
      ("queries/example.proof.hft", sample_proof);
      ("queries/example.sexp.hft", sample_sexp) ]
    ~f:(fun (filename, content) ->
      let mode = detect_mode_from_filename filename in
      match parse_content mode content with
      | Ok ast ->
          Printf.printf "[PASS] File: %s\nMode: %s\nAST: %s\n\n"
            filename
            (Sexp.to_string (Ast.sexp_of_syntax_mode mode))
            (Sexp.to_string (Ast.sexp_of_expr ast))
      | Error err -> Printf.eprintf "[FAIL] File: %s -> %s\n" filename err)