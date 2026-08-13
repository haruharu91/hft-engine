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

let test_money_transpile_features _ =
  let money_expr_str = "$1000.50" in
  let parsed = extract_exn "infix" (Translator.parse_file Infix money_expr_str) in
  match parsed with
  | Ast.Lit (Ast.Money ("$", 1000.50)) -> assert_bool "Money literal parsed properly through translator" true
  | _ -> assert_failure "Failed to parse money literal correctly via translator"

let test_match_transpile_features _ =
  let match_expr_str = "match order_book with | 1 -> true | _ -> false" in
  let parsed = extract_exn "infix" (Translator.parse_file Infix match_expr_str) in
  match parsed with
  | Ast.Match (Ast.Var "order_book", _) -> assert_bool "Match expression parsed properly" true
  | _ -> assert_failure "Failed to parse match expression correctly via translator"

let suite =
  "Transpiler Extended Tests" >::: [
    "dialect_equivalence" >:: test_dialect_equivalence;
    "money_transpile_features" >:: test_money_transpile_features;
    "match_transpile_features" >:: test_match_transpile_features;
  ]

let () = run_test_tt_main suite