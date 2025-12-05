module Solutions.Day05b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Data.Ix (Ix(range))
import Debug.Trace


solve :: String -> Int
solve input =
  let (ranges, _) = parseInput input
  in snd $ foldl countUniqueIds ([], 0) ranges

countUniqueIds :: ([Range], Int) -> Range -> ([Range], Int)
countUniqueIds (ranges, count) (l, r) =
  let uniqueIds = filter (not . inAnyRange ranges) $ range (l, r)
  in trace ("unique ids: " ++ show uniqueIds)
           ((l, r):ranges, count + length uniqueIds)

inAnyRange :: [Range] -> Int -> Bool
inAnyRange ranges v = any (`inRange` v) ranges

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
