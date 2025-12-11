module Solutions.Day11b
  ( solve
  ) where

import Data.List (delete)
import Data.List.Split (splitOn)
import Debug.Trace
import Data.Map (Map, (!))
import qualified Data.Map as Map (empty, insert)
import Data.Set (Set, member)
import qualified Data.Set as Set (empty, insert)

solve :: String -> Int
solve input =
  let connections = parseInput input
  in trace ("connections: " ++ show connections)
     numPaths connections [] "svr"

numPaths :: Map String [String] -> [String] -> String -> Int
numPaths _ visited "out" =
        if "fft" `elem` visited && "dac" `elem` visited
        then 1
        else 0
numPaths connections visited position
  | position `elem` visited = trace ("cycle --" ++ show visited) 0
  | otherwise =
        let visited' = position:visited
            next = trace (-- "accessing '" ++ position
                          -- ++ "', num visited: " ++ show (length visited)
                          -- ++
              show (reverse visited))
                   connections ! position

        in sum $ map (numPaths connections visited') next

-- parsing

parseInput :: String -> Map String [String]
parseInput input =
  let connectionPairs = map parseLine $ lines input
      collect (source, targets) = Map.insert source targets
  in foldr collect Map.empty connectionPairs

parseLine :: String -> (String, [String])
parseLine line =
  let parts = splitOn " " line

      source = delete ':' $ head parts
      targets = tail parts
  in (source, targets)
