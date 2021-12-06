open Smyth
open References

val experiment_proj :
  poly:bool -> n:int ->
  (unit -> (Lang.exp * Lang.exp) list list list) reference_projection

val specification_proj :
  poly:bool -> string reference_projection

val parse_random_proj :
  n:int -> max_k:int -> name:string -> 
  (unit -> (Lang.exp * Lang.exp) list list list) reference_projection
