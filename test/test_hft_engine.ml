open Core

let test_addition =
  QCheck.Test.make
    ~name:"Integer addition commutativity"
    ~count:100
    QCheck.(pair nat_small nat_small)
    (fun (a, b) -> a + b = b + a)

let () =
  let exit_code = QCheck_base_runner.run_tests [ test_addition ] in
  if exit_code <> 0 then exit exit_code