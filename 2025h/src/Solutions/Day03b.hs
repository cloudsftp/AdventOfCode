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
      largestDigit = 2
      n = 3
      selectedDigits =
        selectNDigits largestDigit
                      n
                      (0, length bank)
                      digitOccurrences
  in trace ("selected digits: " ++ show selectedDigits ++ "\n")
           0 -- compute number from selected digits

data Digit = Digit { digit :: Int
                   , position :: Int
                   } deriving (Show, Eq, Ord)

selectNDigits :: Int -> Int -> (Int, Int) -> Map Int [Int] -> [Digit]
selectNDigits 0 _ _ _ = []
selectNDigits _ n _ _ | n <= 0 = []
selectNDigits d n (l, r) positions
  | r - l <= n = filter digitIsInRange $ allDigits positions
  | otherwise =
    let digits = filter digitIsInRange $ matchingDigits d positions
        numDigits = length digits
    in
      if numDigits >= n
      then take n digits
      else selectNDigitsRecursion d (n - length digits) (l, r) positions digits
  where digitIsInRange Digit { position = p } = p >= l && p < r

data DigitCollector = DigitCollector { digits :: [Digit]
                                     , lastPosition :: Int
                                     , nLeft :: Int
                                     } deriving (Show)

selectNDigitsRecursion :: Int -> Int -> (Int, Int) -> Map Int [Int] -> [Digit] -> [Digit]
selectNDigitsRecursion d n (l, r) positions ds =
  let collect digit DigitCollector { digits = ds
                                   , lastPosition = right
                                   , nLeft = nLeft
                                   } = let currentLeft = position digit + 1
                                           recDigits = selectNDigits (d - 1) nLeft (currentLeft, right) positions
                                       in trace ("collecting for d: " ++ show d ++ ", digits: " ++ show ds ++ ", lastPosition: " ++ show right ++ ", nLeft: " ++ show nLeft)
                                          DigitCollector { digits = recDigits ++ digit:ds
                                                         , lastPosition = currentLeft
                                                         , nLeft = nLeft - length recDigits
                                                         }
      DigitCollector { digits = collectedDigits
                     , lastPosition = firstDigitPosition
                     , nLeft = nLeftCollected
                     } = foldr collect (DigitCollector { digits = []
                                                       , lastPosition = r
                                                       , nLeft = n
                                                       }) ds
  in trace ("collected digits: " ++ show collectedDigits ++ ", also have n left: " ++ show nLeftCollected)
     selectNDigits nLeftCollected (d - 1) (l, firstDigitPosition) positions
     ++ collectedDigits

matchingDigits :: Int -> Map Int [Int] -> [Digit]
matchingDigits d positions = map (toDigit d) $ positions ! d

allDigits :: Map Int [Int] -> [Digit]
allDigits = foldrWithKey collectDigits []

collectDigits :: Int -> [Int] -> [Digit] -> [Digit]
collectDigits d positions ds = foldl (\acc p -> toDigit d p:acc)
                                     ds positions

toDigit :: Int -> Int -> Digit
toDigit d p = Digit { digit = d, position = p }

-- digit positions

digitPositions :: Bank -> Map Int [Int]
digitPositions bank =
  let collectOccurrences d = insert d (occurrences d bank)
  in foldl (flip collectOccurrences) empty $ range (1, 9)

data PositionCollector = PositionCollector { current :: Int
                                      , collected :: [Int]
                                      } deriving (Show)

occurrences :: Int -> Bank -> [Int]
occurrences v bank = collected $
  foldl (\PositionCollector { current = pos, collected = coll } d ->
           let newPosition = pos + 1
               newCollected = if v == d
                              then pos:coll
                              else coll
           in PositionCollector { current = newPosition, collected = newCollected }
        )
        (PositionCollector { current = 0, collected = [] })
        bank

-- parsing

parseInput :: String -> [Bank]
parseInput input = map parseLine $ lines input

parseLine :: String -> Bank 
parseLine = map parseCharacter

parseCharacter :: Char -> Int
parseCharacter c = read [c]
