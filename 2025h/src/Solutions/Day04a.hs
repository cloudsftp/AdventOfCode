module Solutions.Day04a
  ( solve
  ) where

import Data.Set (Set, fromList)
import qualified Data.Set as Set (empty, insert, member, size, union)
import Debug.Trace

solve :: String -> Int
solve input =
  let (empty, boxes) = parseInput input
  in trace ("finished parsing"
            ++ "\n empty: " ++ show empty
            ++ "\n boxes: " ++ show boxes
            ++ "\n")
     countAccessibleBoxes (empty, boxes)

countAccessibleBoxes :: Data -> Int
countAccessibleBoxes (empty, boxes) =
   Set.size $ foldl (collectAccessibleBoxes boxes) Set.empty empty

collectAccessibleBoxes :: Set Position -> Set Position -> Position -> Set Position
collectAccessibleBoxes boxes accessible position =
  let adjacent = adjacentBoxes position boxes
      isGoodEmptySpot = not . flip Set.member adjacent
  in if isGoodEmptySpot position
     then Set.union accessible adjacent
     else accessible


adjacentBoxes :: Position -> Set Position -> Set Position
adjacentBoxes (i, j) boxes =
  let isBox = flip Set.member boxes
  in fromList $ filter isBox [ (i - 1, j)
                             , (i, j - 1)
                             , (i + 1, j)
                             , (i, j + 1)
                             , (i - 1, j - 1)
                             , (i + 1, j + 1)
                             , (i + 1, j - 1)
                             , (i - 1, j + 1)]

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
