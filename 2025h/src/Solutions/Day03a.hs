module Solutions.Day03a
  ( solve
  ) where

import Debug.Trace

type Bank = [Int]

solve :: String -> Int
solve input = 
  let banks = parseInput input
  in sum $ map bankJoltage banks

bankJoltage :: Bank -> Int
bankJoltage [_] = 0
bankJoltage bank = max (bankJoltageOuter bank)
                       (bankJoltageOuter $ tail bank)

bankJoltageOuter :: Bank -> Int
bankJoltageOuter bank =
  let (first:rest) = bank
  in bankJoltageInner first rest


bankJoltageInner :: Int -> Bank -> Int
bankJoltageInner _ [] = 0
bankJoltageInner first (d:ds) = max (10 * first + d)
                                    (bankJoltageInner first ds)


-- parsing

parseInput :: String -> [Bank]
parseInput input = map parseLine $ lines input

parseLine :: String -> Bank 
parseLine = map parseCharacter

parseCharacter :: Char -> Int
parseCharacter c = read [c]
