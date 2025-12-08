module Solutions.Day08b
  ( solve
  ) where

import Debug.Trace
import Data.List.Split (splitWhen)
import Data.List (sortOn)
import Data.Map (Map, empty, insert, delete, fromList, (!))
import Data.Set (Set, singleton, union)
import GHC.Float (float2Int)

data Node = Node Float Float Float deriving (Show)

solve :: String -> Int
solve input =
  let nodes = parseInput input
      pairs = computeDistances nodes
      
      groupIds = fromList [(i, i) | i <- [0..(length nodes - 1)]]
      elementIds = foldl (\acc i -> insert i (singleton i) acc) empty [0..(length nodes - 1)]
      
      result = connectNodes nodes pairs (groupIds, elementIds)

  in trace ("nodes: " ++ show nodes ++ "\npairs: " ++ show pairs ++ "\n\n")
     result

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
    in trace ("two groups? " ++ show elementIds ++ " (i, j): " ++ show (i, j))
       float2Int $ xi * xj
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
      
    in trace ("new groups: " ++ show newElementIds)
             connectNodes nodes rest (newGroupIds, newElementIds)

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

collectPairDistances :: [Node] -> [(Int, Int)] -> [(Float, (Int, Int))]
collectPairDistances _ [] = []
collectPairDistances nodes ((i, j):rest) =
  let dist = distance (nodes !! i) (nodes !! j)
  in (dist, (i, j)):collectPairDistances nodes rest

distance :: Node -> Node -> Float
distance (Node xa ya za) (Node xb yb zb) =
  sqrt $ (xa - xb) ^ 2 + (ya - yb) ^ 2 + (za - zb) ^ 2

enumerate :: [a] -> [(Int, a)]
enumerate = snd . foldl (\(pos, acc) e -> (pos + 1, (pos, e):acc)) (0, [])

-- parsing

parseInput :: String -> [Node]
parseInput = map parseLine . lines 

parseLine :: String -> Node
parseLine line =
  let [x, y, z] = splitWhen (==',') line
  in Node (read x) (read y) (read z)
