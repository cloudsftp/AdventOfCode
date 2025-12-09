module Solutions.Day09a
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Debug.Trace
import Data.List (sortBy, sortOn)

type Tile = (Int, Int)

solve :: String -> Int
solve input =
  let tiles = parseInput input

      topLeft = head $ sortOn (\(x, y) -> (x, y)) tiles
      topRight = head $ sortOn (\(x, y) -> (-x, y)) tiles
      bottomLeft = head $ sortOn (\(x, y) -> (x, -y)) tiles
      bottomRight = head $ sortOn (\(x, y) -> (-x, -y)) tiles
        
  in trace ("tiles: " ++ show tiles
            ++ " top left: " ++ show topLeft
            ++ " top right: " ++ show topRight
            ++ " bottom left: " ++ show bottomLeft
            ++ " bottom right: " ++ show bottomRight)
     max (area topLeft bottomRight) (area topRight bottomLeft)

-- areas

area :: Tile -> Tile -> Int
area (xi, yi) (xj, yj) = (abs (xi - xj) + 1) * (abs (yi - yj) + 1)

-- parsing

parseInput :: String -> [Tile]
parseInput = map parseTile . lines

parseTile :: String -> Tile
parseTile line =
  let [x, y] = splitWhen (==',') line
  in (read x, read y)

