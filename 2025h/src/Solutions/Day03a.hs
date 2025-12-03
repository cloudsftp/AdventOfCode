module Solutions.Day03a
  ( solve
  ) where

import Debug.Trace

solve :: String -> Int
solve input = trace ("parsed input: " ++ show (parseInput input)) 0

-- parsing

parseInput :: String -> [[Int]]
parseInput input = map parseLine $ lines input

parseLine :: String -> [Int]
parseLine = map parseCharacter

parseCharacter :: Char -> Int
parseCharacter c = read [c]
