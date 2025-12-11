module Solutions.Day11a
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Debug.Trace
import Data.Map (Map, empty)

solve :: String -> Int
solve input =
  let connections = parseInput input
  in trace ("connections: " ++ show connections)
     0

-- parsing

parseInput :: String -> Map String [String]
parseInput input =
  let connectionPairs = map parseLine $ lines input
  in empty

parseLine :: String -> (String, [String])
parseLine line = ("", [])
