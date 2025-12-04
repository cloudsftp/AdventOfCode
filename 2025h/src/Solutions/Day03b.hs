module Solutions.Day03b
  ( solve
  ) where

import Debug.Trace

import Data.Ix
import Data.Map (Map, insert, empty, foldrWithKey, (!))

type Bank = [Int]

solve :: String -> Int
solve input = 
  let banks = parseInput input
  in sum $ map bankJoltage banks

bankJoltage :: Bank -> Int
bankJoltage bank =
  let digitOccurrences = digitPositions bank
      selectedDigits = selectNDigits 9 9 (0, length bank) digitOccurrences
  in trace ("occurrences: " ++ show digitOccurrences ++ " selected digits: " ++ show selectedDigits)
           0

data Digit = Digit { digit :: Int
                   , position :: Int
                   } deriving (Show, Eq, Ord)

selectNDigits :: Int -> Int -> (Int, Int) -> Map Int [Int] -> [Digit]
selectNDigits _ 0 _ _ = []
selectNDigits d n (l, r) digits
  | r - l <= n =
    let digitIsInRange Digit { position = p } = p >= l && p < r
    in  filter digitIsInRange $ allDigits digits
  | otherwise =
    let result = [] -- choose as much digits d as possible
    in result       -- if n still greater, recurse from right to left on ranges of left-over digits

allDigits :: Map Int [Int] -> [Digit]
allDigits = foldrWithKey collectDigits []

collectDigits :: Int -> [Int] -> [Digit] -> [Digit]
collectDigits d positions ds = foldl (\acc p -> toDigit d p:acc) ds positions

toDigit :: Int -> Int -> Digit
toDigit d p = Digit { digit = d, position = p }

-- digit positions

digitPositions :: Bank -> Map Int [Int]
digitPositions bank =
  let collectOccurrences d = insert d (occurrences d bank)
  in foldl (flip collectOccurrences) empty $ range (1, 9)

data DigitCounter = DigitCollecter { current :: Int
                                   , collected :: [Int]
                                   } deriving (Show)

occurrences :: Int -> Bank -> [Int]
occurrences v bank = collected $
  foldl (\DigitCollecter { current = pos, collected = coll } d ->
           let newPosition = pos + 1
               newCollected = if v == d
                              then pos:coll
                              else coll
           in DigitCollecter { current = newPosition, collected = newCollected }
        )
        (DigitCollecter { current = 0, collected = [] })
        bank

-- parsing

parseInput :: String -> [Bank]
parseInput input = map parseLine $ lines input

parseLine :: String -> Bank 
parseLine = map parseCharacter

parseCharacter :: Char -> Int
parseCharacter c = read [c]
