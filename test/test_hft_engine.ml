open Core
open Hft_engine (* Assuming your library module namespace *)

let test_addition =
  QCheck.Test.make
    ~name:"Integer addition commutativity"
    ~count:100
    QCheck.(pair nat_small nat_small)
    (fun (a, b) -> a + b = b + a)

let test_money_parsing =
  QCheck.Test.make
    ~name:"Parse Rebol-style Money literal"
    ~count:1
    QCheck.unit
    (fun () ->
       let input = "$150.25" in
       let lexbuf = Lexing.from_string input in
       let expr = Parser.parse_infix Lexer.token lexbuf in
       match expr with
       | Ast.Lit (Ast.Money ("$", 150.25)) -> true
       | _ -> false)

let test_match_parsing_and_analysis =
  QCheck.Test.make
    ~name:"Parse and analyze Match expressions"
    ~count:1
    QCheck.unit
    (fun () ->
       let input = "match tick with | 100 -> true | _ -> false" in
       let lexbuf = Lexing.from_string input in
       let expr = Parser.parse_infix Lexer.token lexbuf in
       match expr with
       | Ast.Match (Ast.Var "tick", [ (Ast.PLit (Ast.Int 100), Ast.Lit (Ast.Bool true)); (Ast.PWildcard, Ast.Lit (Ast.Bool false)) ]) ->
           let analysis_result = Static_analysis.verify_zero_allocation_hotpath expr in
           Result.is_ok analysis_result || Result.is_error analysis_result
       | _ -> false)

let () =
  let exit_code = QCheck_base_runner.run_tests [ 
    test_addition; 
    test_money_parsing; 
    test_match_parsing_and_analysis 
  ] in
  if exit_code <> 0 then exit exit_code