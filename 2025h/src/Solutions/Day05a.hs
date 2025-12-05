module Solutions.Day05a
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Debug.Trace

solve :: String -> Int
solve input =
  let parsed = parseInput input
  in trace ("parsed input: " ++ show parsed)
        0

-- parsing

type Range = (Int, Int)

parseInput :: String -> ([Range], [Int])
parseInput = parseLines . lines

parseLines :: [String] -> ([Range], [Int])
parseLines line =
  let [rangeLines, idLines] = splitWhen null line
  in (parseRanges rangeLines, parseIds idLines)

parseRanges :: [String] -> [Range]
parseRanges = map parseRange

parseRange :: String -> Range
parseRange line =
  let [l, r] = splitWhen (=='-') line
  in (read l, read r)

parseIds :: [String] -> [Int]
parseIds = map read
