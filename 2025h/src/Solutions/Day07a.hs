module Solutions.Day07a
  ( solve
  ) where

import Data.Set (Set, singleton, member, insert, delete)
import Debug.Trace

solve :: String -> Int
solve input =
  let (startPosition, splitterPositions) = parseInput input
  in trace ("start position: " ++ show startPosition ++ " splitter positions: " ++ show splitterPositions)
     fst $ foldl step (0, singleton startPosition) splitterPositions

step :: (Int, Set Int) -> [Int] -> (Int, Set Int)
step (numberOfSplits, beamPositions) splitterPositions =
  foldl (\(n, ps) p ->
           if member p ps
           then (n + 1, insert (p - 1) $ insert (p + 1) $ delete p  ps)
           else (n, ps))
  (numberOfSplits, beamPositions) splitterPositions

-- parsing

parseInput :: String -> (Int, [[Int]])
parseInput input =
  let firstLine:splitterLines = lines input
      startPosition = parseStart firstLine
      splitterPositions = map parseSplitterLine splitterLines
      
  in (startPosition, splitterPositions)

parseStart :: String -> Int
parseStart line =
  let positions = filter ((=='S') . snd) $ enumerate line
  in fst $ head positions

parseSplitterLine :: String -> [Int]
parseSplitterLine line =
  map fst $ filter ((=='^') . snd) $ enumerate line

enumerate :: [a] -> [(Int, a)]
enumerate = snd . foldl (\(pos, acc) e -> (pos + 1, (pos, e):acc)) (0, [])
  
