(* bin/transpiler.ml *)
open Core
open Hft_engine.Translator

let () =
  let source_code = "tick_stream kara (price > 100.0) de matching_engine ni filter_and_emit" in

  Printf.printf "=== Original SOV Source ===\n%s\n\n" source_code;

  match translate_file ~from_mode:SOV ~to_mode:Proof source_code with
  | Ok proof_code ->
      Printf.printf "=== Translated to Formal Proof Syntax ===\n%s\n\n" proof_code;
      
      (match translate_file ~from_mode:Proof ~to_mode:Sexp proof_code with
       | Ok sexp_code -> Printf.printf "=== Translated to S-Expression Wire Syntax ===\n%s\n" sexp_code
       | Error e -> Printf.eprintf "Translation Error: %s\n" e)
  | Error e -> Printf.eprintf "Translation Error: %s\n" e