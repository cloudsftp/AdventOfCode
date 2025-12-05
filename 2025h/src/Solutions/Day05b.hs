module Solutions.Day05b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Data.List (sortOn)

solve :: String -> Int
solve input =
  let (ranges, _) = parseInput input
  in numIds $ foldl collectDisjointRanges [] $ sortOn fst ranges

numIds :: [Range] -> Int
numIds = sum . map (\(l, r) -> r - l + 1)

collectDisjointRanges :: [Range] -> Range -> [Range]
collectDisjointRanges [] range = [range]
collectDisjointRanges collected (l, r)
  | rCut < l  = (l, r):collected
  | rCut >= r = collected
  | otherwise = (rCut + 1, r):collected
  where (_, rCut):_ = collected

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
