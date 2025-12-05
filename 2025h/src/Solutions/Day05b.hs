module Solutions.Day05b
  ( solve
  ) where

import Data.List.Split (splitWhen)

solve :: String -> Int
solve input =
  let (ranges, _) = parseInput input
  in sum $ map rangeSize ranges

rangeSize :: Range -> Int
rangeSize (l, r) = r - l + 1

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
