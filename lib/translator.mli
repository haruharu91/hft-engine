val parse_file : Ast.syntax_mode -> string -> (Ast.expr, string) result
val print_ast : Ast.syntax_mode -> Ast.expr -> string
val translate_file : from_mode:Ast.syntax_mode -> to_mode:Ast.syntax_mode -> string -> (string, string) result