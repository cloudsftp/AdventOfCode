module Solutions.Day02a
  ( solve
  ) where

import Lib
import Data.Ix

solve :: String -> Int
solve input =
  let ranges = parseRanges input
  in sum $ map sumOfRepeating ranges

--- logic

data Range = Range { start :: Int
                   , end :: Int
                   } deriving (Show)

sumOfRepeating :: Range -> Int
sumOfRepeating r = sum $ filter isRepeating (getNumbers r)

getNumbers :: Range -> [Int]
getNumbers Range { start = s, end = e } = range (s, e)

isRepeating :: Int -> Bool
isRepeating n
  | odd l     = False
  | otherwise =
    let left = take h string
        right = drop h string
    in left == right
  where string = show n
        l = length string
        h = div l 2

--- parsing

-- input example : 1-200,2-5
parseRanges :: String -> [Range]
parseRanges = parseRangesRec []

parseRangesRec :: [Range] -> String -> [Range]
parseRangesRec acc [] = acc
parseRangesRec acc input =
  let (rangeInput, rest) = splitString ',' input
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
