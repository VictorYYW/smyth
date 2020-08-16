type Nat
  = Z ()
  | S Nat

type NatList
  = Nil ()
  | Cons (Nat, NatList)

type NatListList
  = LNil ()
  | LCons (NatList, NatListList)

-- append : NatList -> NatList -> NatList
-- append l1 l2 =
--   case l1 of
--     Nil _ ->
--       l2
--     Cons p ->
--       Cons (#2.1 p, append (#2.2 p) l2)

concat : NatListList -> NatList
concat xss =
  ??

specifyFunction concat
  [ (LNil (), [])
  , (LCons ([], LNil ()), [])
  , (LCons ([0], LNil ()), [0])
  , (LCons ([0], LCons([0], LNil ())), [0, 0])
  , (LCons ([1], LNil ()), [1])
  , (LCons ([2], LCons([1], LNil ())), [2, 1])
  , (LCons ([2, 3], LCons([1], LNil ())), [2, 3, 1])
  ]
