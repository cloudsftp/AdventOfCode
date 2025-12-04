module Solutions.Day04a
  ( solve
  ) where

import Data.Set (Set)
import qualified Data.Set as Set (empty, insert)
import Debug.Trace

solve :: String -> Int
solve input =
  let parsed = parseInput input
  in trace (show parsed) 0

-- parsing

type Position = (Int, Int)
type Data = (Set Position, Set Position)

parseInput :: String -> Data
parseInput = snd . foldl parseLines (0, (Set.empty, Set.empty)) . lines

parseLines :: (Int, Data) -> String -> (Int, Data)
parseLines (i, acc) lines' =
  let (_, newAcc) = foldl parseLine ((i, 0), acc) lines'
      newI = i + 1
  in (newI, newAcc)

parseLine :: (Position, Data) -> Char -> (Position, Data)
parseLine (position, (empty, boxes)) c =
  let (i, j) = position
      insert = Set.insert position
      nextData
        | c == '.'  = (insert empty, boxes)
        | c == '@'  = (empty, insert boxes)
        | otherwise = error "no"
      nextPosition = (i, j + 1)
 
  in (nextPosition, nextData)
