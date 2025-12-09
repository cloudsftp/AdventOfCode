module Solutions.Day08b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Data.List (sortOn)
import Data.Map (Map, empty, insert, delete, fromList, (!))
import Data.Set (Set, singleton, union)

data Node = Node Int Int Int deriving (Show)

solve :: String -> Int
solve input =
  let nodes = parseInput input
      pairs = computeDistances nodes
      
      groupIds = fromList [(i, i) | i <- [0..(length nodes - 1)]]
      elementIds = foldl (\acc i -> insert i (singleton i) acc) empty [0..(length nodes - 1)]
      
  in connectNodes nodes pairs (groupIds, elementIds)

connectNodes :: [Node] -> [(Int, Int)] -> Circuits -> Int
connectNodes _ [] _ = error "nu uh"
connectNodes nodes ((i, j):rest) (groupIds, elementIds) =
  if length elementIds == 2
  && any (\ids
          -> ids == singleton i
          || ids == singleton j) elementIds
  then
    let Node xi _ _ = nodes !! i
        Node xj _ _ = nodes !! j
    in xi * xj
  else
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
