module Solutions.Day08a
  ( solve
  ) where

import Debug.Trace
import Data.List.Split (splitWhen)

data Node = Node Int Int Int deriving (Show)

solve :: String -> Int
solve input =
  let nodes = parseInput input
  in trace ("nodes: " ++ show nodes)
     0

-- parsing

parseInput :: String -> [Node]
parseInput = map parseLine . lines 

parseLine :: String -> Node
parseLine line =
  let [x, y, z] = splitWhen (==',') line
  in Node (read x) (read y) (read z)
