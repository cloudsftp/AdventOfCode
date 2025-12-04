module Solutions.Day03b
  ( solve
  ) where

import Data.List (elemIndex)

type Bank = [Int]

solve :: String -> Int
solve input = 
  let banks = parseInput input
  in sum $ map bankJoltage banks

bankJoltage :: Bank -> Int
bankJoltage bank = chooseNDigits 12 bank 0

chooseNDigits :: Int -> Bank -> Int -> Int
chooseNDigits 0 _ sum = sum
chooseNDigits n bank sum =
  let position = cutPosition n bank
      newBank = drop (position + 1) bank
      newSum = 10 * sum + bank !! position
  in chooseNDigits (n - 1) newBank newSum

cutPosition :: Int -> Bank -> Int
cutPosition n bank =
  let len = length bank
      recurse d
        | d <= 0 = error "should never happen"
        | otherwise = case elemIndex d bank of
            Nothing -> recurse (d - 1)
            Just position ->
              if len - position < n
              then recurse (d - 1)
              else position
  in recurse 9

-- parsing

parseInput :: String -> [Bank]
parseInput input = map parseLine $ lines input

parseLine :: String -> Bank 
parseLine = map parseCharacter

parseCharacter :: Char -> Int
parseCharacter c = read [c]
