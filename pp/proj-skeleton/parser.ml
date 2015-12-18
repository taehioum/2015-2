(* throw this exception with a proper message if you meet a parsing error. *)
exception PARSE_ERROR of string
module Syn= Syntax

type token =
  | INT of int
  | ID of string
  | PLUS
  | MINUS
  | TIMES
  | LPAREN
  | RPAREN
  | TRUE
  | FALSE
  | NULL
  | IF
  | CONS
  | CAR
  | CDR
  | LAMBDA
  | LET
  | LETREC
  | EQ
  | LT
  | GT
  | MCONS
  | MCAR
  | MCDR
  | SETMCAR
  | SETMCDR
  | RAISE
  | HANDLERS
  | EOF

(* you can use this for debugging *)
let token_printer = function
  | INT n -> string_of_int n
  | ID id -> id
  | PLUS -> "+"
  | MINUS -> "-"
  | TIMES -> "*"
  | LPAREN -> "("
  | RPAREN -> ")"
  | TRUE -> "#t"
  | FALSE -> "#f"
  | NULL -> "'()"
  | IF -> "if"
  | CONS -> "cons"
  | CAR -> "car"
  | CDR -> "cdr"
  | LAMBDA -> "lambda"
  | LET -> "let"
  | LETREC -> "letrec"
  | EQ -> "="
  | LT -> "<"
  | GT -> ">"
  | MCONS -> "mcons"
  | MCAR -> "mcar"
  | MCDR -> "mcdr"
  | SETMCAR -> "set-mcar!"
  | SETMCDR -> "set-mcdr!"
  | RAISE -> "raise"
  | HANDLERS -> "with-handlers"
  | EOF -> "eof"

(* You can get a token by calling `lexer` function like this example: *)
(* let token = lexer () in ... *)
let rev = function
  (a, b) -> (b, a)

let rev_3 = function
  (a, b, c) -> (c, b, a)

let unmatched_paren = "unmatched parenthesis"
let rec parse (lexer: unit -> token): Syn.exp_t =
  let exp = parse_helper lexer in
  if lexer() = EOF then
    exp
  else
    raise (PARSE_ERROR "trailing characters")

and parse_helper lexer =
  let app = ref false in
  let token = lexer () in
  match token with 
  | INT n -> Syn.CONST (Syn.CINT n)
  | ID v -> Syn.VAR v
  | TRUE -> Syn.CONST Syn.CTRUE
  | FALSE -> Syn.CONST Syn.CFALSE
  | NULL -> Syn.CONST Syn.CNULL
  | LPAREN -> 
        begin match lexer () with
        | ID x ->
            Syn.APP (rev ( (exp_to_list lexer []), Syn.VAR x))
        | LPAREN -> 
            begin match lexer () with
              | LAMBDA ->
                  let _ = app:= true in
                  let vl = (var_to_list lexer []) in
                  let proc = (Syn.LAMBDA (rev ((parse_helper lexer), vl))) in
                  let _ = lexer () in (*exhaust right parenthesis*)
                  let _ = lexer () in (*exhaust right parenthesis*)
                  let exp = Syn.APP (rev ( (exp_to_list lexer []), proc)) in
                  exp
              | _ -> raise (PARSE_ERROR "expect a procedure")
            end
        | PLUS -> 
            let exp = 
              Syn.ADD (rev ((parse_helper lexer), (parse_helper lexer))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | MINUS -> 
            let exp = 
              Syn.SUB (rev ((parse_helper lexer), (parse_helper lexer))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | TIMES ->
            let exp = 
              Syn.MUL (rev ((parse_helper lexer), (parse_helper lexer))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | IF ->
            let exp = 
              Syn.IF (rev_3 ((parse_helper lexer), (parse_helper lexer), (parse_helper lexer))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | CONS ->
            let exp = 
              Syn.CONS (rev ((parse_helper lexer), (parse_helper lexer))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | MCONS ->
            let exp = 
              Syn.MCONS (rev ((parse_helper lexer), (parse_helper lexer))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | CAR ->
            let exp = 
              Syn.CAR (parse_helper lexer) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | CDR ->
            let exp = 
              Syn.CDR (parse_helper lexer) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | LAMBDA ->
            let exp = 
              Syn.LAMBDA (rev ((parse_helper lexer), (var_to_list lexer []))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | LET -> 
            let exp = 
              Syn.LET (rev ((parse_helper lexer), (bind_to_list lexer [] 0))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | LETREC -> 
            let exp = 
              Syn.LETREC (rev ((parse_helper lexer), (bind_to_list lexer [] 0))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | EQ -> 
            let exp = 
              Syn.EQ (rev ((parse_helper lexer), (parse_helper lexer))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | LT ->
            let exp = 
              Syn.LT (rev ((parse_helper lexer), (parse_helper lexer))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | GT ->
            let exp = 
              Syn.GT (rev ((parse_helper lexer), (parse_helper lexer))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | MCAR ->
            let exp = 
              Syn.MCAR (parse_helper lexer) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | MCDR ->
            let exp = 
              Syn.MCDR (parse_helper lexer) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | SETMCAR ->
            let exp = 
              Syn.SETMCAR (rev ( (parse_helper lexer), (parse_helper lexer) )) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | SETMCDR ->
            let exp = 
              Syn.SETMCDR (rev ( (parse_helper lexer), (parse_helper lexer) )) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | RAISE ->
            let exp = 
              Syn.RAISE (parse_helper lexer)  in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | HANDLERS -> 
            let exp = 
              Syn.HANDLERS (rev ((parse_helper lexer), (hndls_to_list lexer []))) in
            if (lexer () = RPAREN) then
              exp
            else
              raise (PARSE_ERROR unmatched_paren)
        | INT _ | TRUE | FALSE -> 
            raise ( PARSE_ERROR ("expected a procedure") )
        | RPAREN -> raise (PARSE_ERROR "empty parenthesis")
        | _ ->  raise (PARSE_ERROR
                ((token_printer token)^" is not a part of the syntax"))
        end
  | RPAREN -> raise (PARSE_ERROR  "missing operand")
  | EOF -> raise (PARSE_ERROR  "premature eof")
  | _ ->  raise (PARSE_ERROR  ((token_printer token)^" is not a part of the syntax"))


and var_to_list (lexer: unit -> token) (vl: Syntax.var_t list): Syntax.var_t list =
  let token = lexer () in
  match token with
  | LPAREN -> (var_to_list lexer vl)
  | ID v -> (var_to_list lexer (vl@[v]))
  | RPAREN -> vl
  | _ -> raise (PARSE_ERROR "not a variable")

and bind_to_list (lexer: unit -> token) (bl: Syntax.binding_t list) cnt :Syntax.binding_t list =
  let token = lexer () in
  match token with
  | LPAREN -> (bind_to_list lexer bl (cnt+1))
  | ID v -> 
      (bind_to_list lexer (bl@[(v,parse_helper lexer)]) cnt)
  | RPAREN -> 
      if (cnt = 1) then (*consume one more paren*)
        bl
      else 
        (bind_to_list lexer bl (cnt-1))
  | _ -> raise (PARSE_ERROR "not a variable")

  (*parse exps for the number of variables in expression*)
  (*FIXME*)
and exp_to_list (lexer: unit -> token) (el: Syntax.exp_t list) :Syntax.exp_t list =
  let exp =  
    try (parse_helper lexer) with
    | PARSE_ERROR ("missing operand") -> Syn.CONST Syn.CNULL in
  match exp with 
  | Syn.CONST Syn.CNULL -> (List.rev el)
  | _ -> (exp_to_list lexer (exp::el))

and hndls_to_list lexer hl :(Syn.exp_t * Syn.exp_t) list =
  let _ = lexer () in (*exhaust one left paren*)
  let token = lexer () in
  match token with
  | LPAREN -> 
      (hndls_to_list lexer (hl@[(rev ((parse_helper lexer), (parse_helper lexer)))]))
  | RPAREN -> 
      hl
  | _ -> raise (PARSE_ERROR "expected a procedure")
