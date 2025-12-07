module Solutions.Day07a
  ( solve
  ) where

import Debug.Trace

solve :: String -> Int
solve input =
  let (startPosition, splitterPositions) = parseInput input
  in trace ("start position: " ++ show startPosition ++ " splitter positions: " ++ show splitterPositions)
     0

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
  
