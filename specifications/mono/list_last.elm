specifyFunction list_last
  [ ([], None)
  , ([1, 3], Some 3)
  , ([3, 2, 3], Some 3)
  , ([0], Some 0)
  , ([0, 3], Some 3)
  , ([3], Some 3)
  , ([2, 3, 0, 3], Some 3)
  , ([0, 2, 1, 1], Some 1)
  , ([1, 0, 1], Some 1)
  , ([0, 1], Some 1)
  , ([3, 0, 0], Some 0)
  , ([2], Some 2)
  , ([0, 3, 3, 2], Some 2)
  , ([0, 3, 1], Some 1)
  , ([3, 1], Some 1)
  , ([3, 0, 0, 1], Some 1)
  , ([0, 0], Some 0)
  , ([1], Some 1)
  , ([3, 1, 1], Some 1)
  , ([2, 0, 2], Some 2)
  ]
