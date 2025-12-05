module Solutions.Day05a
  ( solve
  ) where

import Data.List.Split (splitWhen)

solve :: String -> Int
solve input =
  let (ranges, ids) = parseInput input
      fresh id = any (`inRange` id) ranges
  in length $ filter fresh ids

inRange :: Range -> Int -> Bool
inRange (l, r) v = l <= v && v <= r

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
