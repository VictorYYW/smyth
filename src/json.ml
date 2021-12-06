include Yojson.Basic

type 'a parse_t = t -> 'a

let args3 (p1 : 'a parse_t) (p2 : 'b parse_t) (p3 : 'c parse_t) :
    ('a * 'b * 'c) parse_t =
 fun json ->
  match Util.to_list json with
  | [ a; b; c ] -> (p1 a, p2 b, p3 c)
  | _           -> failwith "arity error during json parsing"

let args2 (p1 : 'a parse_t) (p2 : 'b parse_t) : ('a * 'b) parse_t =
 fun json ->
  match Util.to_list json with
  | [ a; b ] -> (p1 a, p2 b)
  | _        -> failwith "arity error during json parsing"

let list (p : 'a parse_t) : 'a list parse_t =
 fun json -> Util.to_list json |> List.map p

let nested_list (p : 'a parse_t) : 'a list list parse_t =
 fun json -> Util.to_list json |> List.map (list p)

let int = Util.to_int

let bool = Util.to_bool

let var = Util.to_string
