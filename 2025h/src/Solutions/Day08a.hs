module Solutions.Day08a
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Data.List (sortOn, sortBy)
import Data.Map (Map, empty, insert, delete, fromList, (!))
import Data.Set (Set, singleton, union)

data Node = Node Int Int Int deriving (Show)

solve :: String -> Int
solve input =
  let nodes = parseInput input
      pairs = computeDistances nodes
      
      groupIds = fromList [(i, i) | i <- [0..(length nodes)]]
      elementIds = foldl (\acc i -> insert i (singleton i) acc) empty [0..(length nodes)]
      
      (_, circuits) = connectNodes nodes (take 1000 pairs) (groupIds, elementIds)

      circuitSizes =
        sortBy (flip compare)
        $ foldl (\acc circuit -> length circuit:acc)
                [] circuits
      
  in product $ take 3 circuitSizes

connectNodes :: [Node] -> [(Int, Int)] -> Circuits -> Circuits
connectNodes _ [] circuits = circuits
connectNodes nodes ((i, j):rest) (groupIds, elementIds) =
  let groupIdI = groupIds ! i
      groupIdJ = groupIds ! j

      (groupIdSmall, groupIdBig) =
        if groupIdI < groupIdJ
        then (groupIdI, groupIdJ)
        else (groupIdJ, groupIdI)

      previousGroup = elementIds ! groupIdSmall
      movedGroup = elementIds ! groupIdBig
      newGroup = union previousGroup movedGroup
      newElementIds
        = insert groupIdSmall newGroup
        $ delete groupIdBig
        $ delete groupIdSmall elementIds

      newGroupIds = foldl (\acc nodeId -> insert nodeId groupIdSmall acc)
                          groupIds movedGroup
      
  in connectNodes nodes rest (newGroupIds, newElementIds)

type Circuits = (Map Int Int, Map Int (Set Int))



-- distances 

computeDistances :: [Node] -> [(Int, Int)]
computeDistances nodes =
  let indexPairs = [(i, j)
                   | i <- [0..(length nodes - 1)]
                   , j <- [(i+1)..(length nodes - 1)]]
  in map snd
        $ sortOn fst
        $ collectPairDistances nodes indexPairs

collectPairDistances :: [Node] -> [(Int, Int)] -> [(Int, (Int, Int))]
collectPairDistances _ [] = []
collectPairDistances nodes ((i, j):rest) =
  let dist = distance (nodes !! i) (nodes !! j)
  in (dist, (i, j)):collectPairDistances nodes rest

distance :: Node -> Node -> Int
distance (Node xa ya za) (Node xb yb zb) =
  (xa - xb) ^ 2 + (ya - yb) ^ 2 + (za - zb) ^ 2

enumerate :: [a] -> [(Int, a)]
enumerate = snd . foldl (\(pos, acc) e -> (pos + 1, (pos, e):acc)) (0, [])

-- parsing

parseInput :: String -> [Node]
parseInput = map parseLine . lines 

parseLine :: String -> Node
parseLine line =
  let [x, y, z] = splitWhen (==',') line
  in Node (read x) (read y) (read z)
