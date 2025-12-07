module Solutions.Day07a
  ( solve
  ) where

import Debug.Trace

solve :: String -> Int
solve input =
  let _ = parseInput input
  in trace ("parsed: ")
     0

-- parsing

parseInput :: String -> ()
parseInput _ = ()
