%{
open Core
open Ast

let rec fold_app fn args =
  match args with
  | [] -> fn
  | a :: ax -> fold_app (App (fn, a)) ax

let build_sov_record field_list =
  List.fold_right field_list ~init:(Lit (Bool true)) ~f:(fun (lbl, v) acc ->
    RecordCons (lbl, v, acc))
%}

%token <int> INT
%token <float> FLOAT
%token <string> ID ATOM
%token PART_GA PART_WO PART_NI PART_DE PART_KARA PART_NO
%token RULE GIVEN YIELD WHERE
%token TURNSTILE PIPE EQ GTE LTE GT LT
%token PLUS MINUS STAR DIV
%token LPAREN RPAREN
%token EOF

%left TURNSTILE PIPE
%left EQ GTE LTE GT LT
%left PLUS MINUS
%left STAR DIV

%start <Ast.expr> parse_sov parse_proof parse_sexp

%%

/* Enforced Entry Points */

parse_sov:
  | e = sov_expr EOF { e }

parse_proof:
  | e = proof_expr EOF { e }

parse_sexp:
  | e = sexp_expr EOF { e }

/* 1. SOV Postposition Syntax */

sov_expr:
  | clause = sov_clause { clause }
  | e = primary_expr    { e }

sov_clause:
  | args = sov_args verb = ID
      { App (Var verb, build_sov_record args) }

sov_args:
  | arg = sov_particle_arg
      { [arg] }
  | args = sov_args arg = sov_particle_arg
      { args @ [arg] }

sov_particle_arg:
  | e = primary_expr PART_GA   { ("subject", e) }
  | e = primary_expr PART_WO   { ("object", e) }
  | e = primary_expr PART_NI   { ("destination", e) }
  | e = primary_expr PART_DE   { ("condition", e) }
  | e = primary_expr PART_KARA { ("source", e) }
  | e = primary_expr PART_NO field = ID
      { ("genitive_access", RecordAccess (e, field)) }

/* 2. Formal Proof / Sequent Judgment Syntax */

proof_expr:
  | RULE name = ID EQ GIVEN var = ID WHERE cond = infix_expr YIELD body = infix_expr
      { Let (name, Lambda (var, Let ("_cond", cond, body)), Var name) }
  | e1 = proof_expr TURNSTILE e2 = proof_expr
      { App (e2, e1) }
  | e1 = proof_expr PIPE e2 = proof_expr
      { App (e2, e1) }
  | e = infix_expr
      { e }

/* 3. Canonical S-Expression Syntax */

sexp_expr:
  | LPAREN op = op_symbol e1 = sexp_expr e2 = sexp_expr RPAREN
      { BinOp (op, e1, e2) }
  | LPAREN fn = ID args = list(sexp_expr) RPAREN
      { fold_app (Var fn) args }
  | id = ID                   { Var id }
  | i = INT                   { Lit (Int i) }
  | f = FLOAT                 { Lit (Float f) }
  | a = ATOM                  { Lit (String a) }

op_symbol:
  | PLUS { Add } | MINUS { Sub } | STAR { Mul } | DIV { Div }
  | GT { Gt } | LT { Lt } | EQ { Eq }

/* Common Expressions */

infix_expr:
  | e1 = infix_expr PLUS e2 = infix_expr   { BinOp (Add, e1, e2) }
  | e1 = infix_expr MINUS e2 = infix_expr  { BinOp (Sub, e1, e2) }
  | e1 = infix_expr STAR e2 = infix_expr   { BinOp (Mul, e1, e2) }
  | e1 = infix_expr DIV e2 = infix_expr    { BinOp (Div, e1, e2) }
  | e1 = infix_expr GTE e2 = infix_expr    { BinOp (Gte, e1, e2) }
  | e1 = infix_expr LTE e2 = infix_expr    { BinOp (Lte, e1, e2) }
  | e1 = infix_expr GT e2 = infix_expr     { BinOp (Gt, e1, e2) }
  | e1 = infix_expr LT e2 = infix_expr     { BinOp (Lt, e1, e2) }
  | e1 = infix_expr EQ e2 = infix_expr     { BinOp (Eq, e1, e2) }
  | e = primary_expr                        { e }

primary_expr:
  | id = ID                      { Var id }
  | i = INT                      { Lit (Int i) }
  | f = FLOAT                    { Lit (Float f) }
  | a = ATOM                     { Lit (String a) }
  | LPAREN e = infix_expr RPAREN { e }