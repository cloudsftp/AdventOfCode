module Solutions.Day04a
  ( solve
  ) where

import Data.Set (Set, fromList, fold)
import qualified Data.Set as Set (empty, insert, member, size, union)
import Debug.Trace
import Data.Ix

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
  let accessibleBoxes = foldl (collectAccessibleBoxes boxes) Set.empty boxes
  in trace (" accessible Boxes: " ++ show accessibleBoxes
           ++ "\n field: \n" ++ printField (empty, boxes) accessibleBoxes
           ++ "\n")
             
           Set.size accessibleBoxes

collectAccessibleBoxes :: Set Position -> Set Position -> Position -> Set Position
collectAccessibleBoxes boxes accessible position =
  let adjacent = adjacentBoxes position boxes
      isAccessible = Set.size adjacent < 4
  in if isAccessible
     then Set.insert position accessible
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

-- visualizing

printField :: Data -> Set Position -> String
printField (empty, boxes) accessible =
  let allPositions = Set.union empty boxes
      height = fold (max . fst) 0 allPositions
      collect output i = output ++ "\n" ++ printLine i (empty, boxes) accessible
  in foldl collect "" $ range (0, height)

printLine :: Int -> Data -> Set Position -> String
printLine i (empty, boxes) accessible =
  let allPositions = Set.union empty boxes
      width = fold (max . snd) 0 allPositions
      symbol j
       | Set.member (i, j) accessible = "X"
       | Set.member (i, j) boxes = "@"
       | Set.member (i, j) empty = "."
       | otherwise = error "should be in at least one of the sets"
      collect output j = output ++ symbol j
  in foldl collect "" $ range (0, width)

