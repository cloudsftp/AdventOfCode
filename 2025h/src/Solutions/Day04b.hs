module Solutions.Day04b
  ( solve
  ) where

import Data.Set (Set, fromList, fold)
import qualified Data.Set as Set (empty, insert, member, size, delete)
import Debug.Trace
import Data.Ix

type Position = (Int, Int)
type Positions = Set Position

solve :: String -> Int
solve input =
  let boxes = parseInput input
  in trace ("finished parsing"
            ++ "\n boxes: " ++ show boxes
            ++ "\n")
     countRemovedBoxes boxes

countRemovedBoxes :: Positions -> Int
countRemovedBoxes boxes =
  let recurse boxes count =
        let accessible = foldl (collectAccessibleBoxes boxes) Set.empty boxes
            newBoxes = foldl (flip Set.delete) boxes accessible
            numAccessible = Set.size accessible
            newCount = count + numAccessible
        in trace (" accessible Boxes: " ++ show accessible
                 ++ "\n field: \n" ++ printField boxes accessible
                 ++ "\n")
                (if numAccessible <= 0
                 then count
                 else recurse newBoxes newCount)
  in recurse boxes 0

collectAccessibleBoxes :: Positions -> Positions -> Position -> Positions
collectAccessibleBoxes boxes accessible position =
  let adjacent = adjacentBoxes position boxes
      isAccessible = Set.size adjacent < 4
  in if isAccessible
     then Set.insert position accessible
     else accessible

adjacentBoxes :: Position -> Positions -> Positions
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


parseInput :: String -> Positions
parseInput = snd . foldl parseLines (0, Set.empty) . lines

parseLines :: (Int, Positions) -> String -> (Int, Positions)
parseLines (i, acc) lines' =
  let (_, newAcc) = foldl parseLine ((i, 0), acc) lines'
      newI = i + 1
  in (newI, newAcc)

parseLine :: (Position, Positions) -> Char -> (Position, Positions)
parseLine (position, boxes) c =
  let (i, j) = position
      nextData
        | c == '.' = boxes
        | c == '@' = Set.insert position boxes
        | otherwise = error "no"
      nextPosition = (i, j + 1)
 
  in (nextPosition, nextData)

-- visualizing

printField :: Positions -> Set Position -> String
printField boxes accessible =
  let height = fold (max . fst) 0 boxes
      collect output i = output ++ "\n" ++ printLine i boxes accessible
  in foldl collect "" $ range (0, height)

printLine :: Int -> Positions -> Positions -> String
printLine i boxes accessible =
  let width = fold (max . snd) 0 boxes
      symbol j
       | Set.member (i, j) accessible = "X"
       | Set.member (i, j) boxes = "@"
       | otherwise = "."
      collect output j = output ++ symbol j
  in foldl collect "" $ range (0, width)

