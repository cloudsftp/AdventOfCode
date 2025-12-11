module Solutions.Day11b
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
     numPaths connections False False "you" -- "svr"

numPaths :: Map String [String] -> Bool -> Bool -> String -> Int
numPaths _ visitedDAC visitedFFT "out" =
  if visitedDAC && visitedFFT
  then 1
  else 0
numPaths connections visitedDAC visitedFFT position =
  let visitedDAC' = visitedDAC || position == "fft"
      visitedFFT' = visitedFFT || position == "dac"
      next = --trace ("accessing '" ++ position ++ "'")
             connections ! position
      
  in sum $ map (numPaths connections visitedDAC' visitedFFT') next

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
