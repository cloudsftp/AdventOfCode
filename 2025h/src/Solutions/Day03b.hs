module Solutions.Day03b
  ( solve
  ) where

import Debug.Trace
import Data.List (tails)

type Bank = [Int]

solve :: String -> Int
solve input = 
  let banks = parseInput input
  in sum $ map bankJoltage banks

bankJoltage :: Bank -> Int
bankJoltage [_] = 0
bankJoltage bank =
  let maximum = max (bankJoltageOuter 12 0 bank)
                    (bankJoltage $ tail bank)
  in trace ("checking bank " ++ show bank ++ " found maximum " ++ show maximum)
     maximum

bankJoltageOuter :: Int -> Int -> Bank -> Int
bankJoltageOuter 0 sum _ = sum
bankJoltageOuter n sum bank =
  let banks = filter (\tail -> length tail >= n) $ tails bank
      calls = map (bankJoltageInner (n - 1) sum) banks
  in foldl max 0 calls

bankJoltageInner :: Int -> Int -> Bank -> Int
bankJoltageInner 0 sum _ = sum
bankJoltageInner n sum [] = error ("should never happen, got args: " ++ show n ++ " and " ++ show sum)
bankJoltageInner n sum (d:ds) =
  let newSum = 10 * sum + d
  in bankJoltageOuter n newSum ds

-- parsing

parseInput :: String -> [Bank]
parseInput input = map parseLine $ lines input

parseLine :: String -> Bank 
parseLine = map parseCharacter

parseCharacter :: Char -> Int
parseCharacter c = read [c]
