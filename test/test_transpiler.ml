open Core
open OUnit2
open Hft_engine

let extract_exn dialect = function
  | Ok x -> x
  | Error err -> failwith (Printf.sprintf "Failed in [%s]: %s" dialect err)

let test_dialect_equivalence _ =
  let path prefix = Printf.sprintf "fixtures/route_liquidity.%s.hft" prefix in

  let sov_content   = In_channel.read_all (path "sov") in
  let infix_content = In_channel.read_all (path "infix") in
  let sexp_content  = In_channel.read_all (path "sexp") in

  (* Ensure all three dialects parse successfully without crashing *)
  let _sov_ast   = extract_exn "sov" (Translator.parse_file SOV sov_content) in
  let _infix_ast = extract_exn "infix" (Translator.parse_file Infix infix_content) in
  let _sexp_ast  = extract_exn "sexp" (Translator.parse_file Sexp sexp_content) in

  assert_bool "All dialects parsed successfully" true

let suite =
  "Transpiler Tests" >::: [
    "dialect_equivalence" >:: test_dialect_equivalence;
  ]

let () = run_test_tt_main suite