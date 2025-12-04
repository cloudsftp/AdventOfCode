module Solutions.Day03b
  ( solve
  ) where

import Debug.Trace

import Data.Map (Map, insert, empty)
import Data.Ix

type Bank = [Int]

solve :: String -> Int
solve input = 
  let banks = parseInput input
  in sum $ map bankJoltage banks

bankJoltage :: Bank -> Int
bankJoltage bank =
  let digitOccurrences = digits bank
  in trace ("occurrences: " ++ show digitOccurrences)
           0

-- digit positions

digits :: Bank -> Map Int [Int]
digits bank = foldl (\digitOccurrences d -> insert d (occurrences d bank) digitOccurrences)
                    empty $ range (1, 9)

data DigitCounter = DigitCollecter { position :: Int
                                   , collected :: [Int]
                                   } deriving (Show)

occurrences :: Int -> Bank -> [Int]
occurrences v bank = collected $
  foldl (\DigitCollecter { position = pos, collected = coll } d ->
           let newPosition = pos + 1
               newCollected = if v == d
                              then pos:coll
                              else coll
           in DigitCollecter { position = newPosition, collected = newCollected }
        )
        (DigitCollecter { position = 0, collected = [] })
        bank

-- parsing

parseInput :: String -> [Bank]
parseInput input = map parseLine $ lines input

parseLine :: String -> Bank 
parseLine = map parseCharacter

parseCharacter :: Char -> Int
parseCharacter c = read [c]
