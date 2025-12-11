module Solutions.Day11a
  ( solve
  ) where

import Data.List (delete)
import Data.List.Split (splitOn)
import Debug.Trace
import Data.Map (Map, empty, insert, (!))

solve :: String -> Int
solve input =
  let connections = parseInput input
  in trace ("connections: " ++ show connections)
     numPaths connections "you"

numPaths :: Map String [String] -> String -> Int
numPaths _ "out" = 1
numPaths connections position =
  let next = connections ! position 
  in sum $ map (numPaths connections) next

-- parsing

parseInput :: String -> Map String [String]
parseInput input =
  let connectionPairs = map parseLine $ lines input
      collect (source, targets) = insert source targets
  in foldr collect empty connectionPairs

parseLine :: String -> (String, [String])
parseLine line =
  let parts = splitOn " " line

      source = delete ':' $ head parts
      targets = tail parts
  in (source, targets)
