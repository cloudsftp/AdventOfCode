module Solutions.Day08a
  ( solve
  ) where

import Debug.Trace
import Data.List.Split (splitWhen)
import Data.List (sortOn)
-- import Data.Heap (MinHeap, HeapItem, empty, insert)

data Node = Node Float Float Float deriving (Show)

distance :: Node -> Node -> Float
distance (Node xa ya za) (Node xb yb zb) =
  sqrt $ (xa - xb) ^ 2 + (ya - yb) ^ 2 + (za - zb) ^ 2

-- 

solve :: String -> Int
solve input =
  let nodes = parseInput input
      distances = computeDistances nodes
  in trace ("nodes: " ++ show nodes ++ "\ndistances: " ++ show distances)
     0

computeDistances :: [Node] -> [(Int, Int)]
computeDistances nodes =
  let indexPairs = [(i, j)
                   | i <- [0..(length nodes - 1)]
                   , j <- [(i+1)..(length nodes - 1)]]
  in map snd
        $ sortOn fst
        $ collectPairDistances nodes indexPairs

collectPairDistances :: [Node] -> [(Int, Int)] -> [(Float, (Int, Int))]
collectPairDistances _ [] = []
collectPairDistances nodes ((i, j):rest) =
  let dist = distance (nodes !! i) (nodes !! j)
  in (dist, (i, j)):collectPairDistances nodes rest

enumerate :: [a] -> [(Int, a)]
enumerate = snd . foldl (\(pos, acc) e -> (pos + 1, (pos, e):acc)) (0, [])

-- parsing

parseInput :: String -> [Node]
parseInput = map parseLine . lines 

parseLine :: String -> Node
parseLine line =
  let [x, y, z] = splitWhen (==',') line
  in Node (read x) (read y) (read z)
