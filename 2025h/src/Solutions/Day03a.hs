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
bankJoltage bank =
  let maximum = max (bankJoltageOuter bank)
                    (bankJoltage $ tail bank)
  in trace ("checking bank " ++ show bank ++ " found maximum " ++ show maximum)
           maximum
  

bankJoltageOuter :: Bank -> Int
bankJoltageOuter bank =
  let (first:rest) = bank
  in trace ("selected first digit: " ++ show first)
           (bankJoltageInner first rest)

bankJoltageInner :: Int -> Bank -> Int
bankJoltageInner _ [] = 0
bankJoltageInner first (d:ds) =
  let sum = 10 * first + d
      call = bankJoltageInner first ds
  in trace ("current sum: " ++ show sum ++ ", recursive maximum: " ++ show call)
           max sum call


-- parsing

parseInput :: String -> [Bank]
parseInput input = map parseLine $ lines input

parseLine :: String -> Bank 
parseLine = map parseCharacter

parseCharacter :: Char -> Int
parseCharacter c = read [c]
