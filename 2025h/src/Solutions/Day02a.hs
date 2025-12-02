module Solutions.Day02a
  ( solve
  ) where

import Lib

solve :: String -> Int
solve input =
  let ranges = parseRanges input
  in sum $ map end ranges 

data Range = Range { start :: Int
                   , end :: Int
                   } deriving (Show)

-- input example : 1-200,2-5
parseRanges :: String -> [Range]
parseRanges = parseRangesRec []

parseRangesRec :: [Range] -> String -> [Range]
parseRangesRec acc [] = acc
parseRangesRec acc input =
  let (rangeInput, rest) = debug $ splitString ',' input
      range = parseRange rangeInput
  in parseRangesRec (range:acc) rest

-- input example: 1-200
parseRange :: String -> Range
parseRange input =
  let (startInput, endInput) = splitString '-' input
      start = read startInput
      end = read endInput
  in Range { start = start, end = end }

splitString :: Char -> String -> (String, String)
splitString c input =
  let part1 = takeWhile (/= c) input
      part2 = dropWhile (== c) $ dropWhile (/= c) input
  in (part1, part2)
