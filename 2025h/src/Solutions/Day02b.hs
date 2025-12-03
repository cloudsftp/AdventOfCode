module Solutions.Day02b
  ( solve
  ) where

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
isRepeating value =
  let string = show value
      l = length string
      candidates = range (1, l)
      divisors = filter (\candidate -> mod l candidate == 0 && l /= candidate) candidates
      
  in any (`isMRepeating` string) divisors

isMRepeating :: Int -> String -> Bool
isMRepeating m input =
  let chunks = splitM m input
      first = head chunks
      rest = tail chunks
      repeating = all (== first) rest
  in repeating

splitM :: Int -> String -> [String]
splitM m = reverse . splitMRecurse m []

splitMRecurse :: Int -> [String] -> String -> [String]
splitMRecurse _ acc [] = acc
splitMRecurse m acc string =
  let chunk = take m string
      rest = drop m string
  in splitMRecurse m (chunk:acc) rest

--- parsing

-- input example : 1-200,2-5
parseRanges :: String -> [Range]
parseRanges = parseRangesRec []

parseRangesRec :: [Range] -> String -> [Range]
parseRangesRec acc [] = acc
parseRangesRec acc input =
  let (rangeInput, rest) = splitString ',' input
      r = parseRange rangeInput
  in parseRangesRec (r:acc) rest

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
