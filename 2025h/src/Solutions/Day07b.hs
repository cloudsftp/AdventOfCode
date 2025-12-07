module Solutions.Day07b
  ( solve
  ) where

import Data.Set (Set, empty, singleton, member, insert, delete)
import Debug.Trace

solve :: String -> Int
solve input =
  let (startPosition, splitterPositions) = parseInput input
  in trace ("start position: " ++ show startPosition ++ " splitter positions: " ++ show splitterPositions)
     length $ foldl step [startPosition] splitterPositions

step :: [Int] -> Set Int -> [Int]
step beamPositions splitterPositions =
  -- trace ("beams " ++ show beamPositions ++ ", splitters " ++ show splitterPositions)
  foldr (\p beamPositions ->
        if member p splitterPositions
        then (p-1):(p+1):beamPositions
        else p:beamPositions)
  [] beamPositions

-- parsing

parseInput :: String -> (Int, [Set Int])
parseInput input =
  let firstLine:splitterLines = lines input
      startPosition = parseStart firstLine
      splitterPositions = filter (not . null) $ map parseSplitterLine splitterLines
      
  in (startPosition, splitterPositions)

parseStart :: String -> Int
parseStart line =
  let positions = filter ((=='S') . snd) $ enumerate line
  in fst $ head positions

parseSplitterLine :: String -> Set Int
parseSplitterLine line =
  foldl (flip insert) empty
  $ map fst
  $ filter ((=='^') . snd)
  $ enumerate line

enumerate :: [a] -> [(Int, a)]
enumerate = snd . foldl (\(pos, acc) e -> (pos + 1, (pos, e):acc)) (0, [])
  
