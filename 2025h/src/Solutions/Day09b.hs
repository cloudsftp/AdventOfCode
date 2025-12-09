module Solutions.Day09b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Debug.Trace

type Tile = (Int, Int)

solve :: String -> Int
solve input =
  let tiles = parseInput input

      indexPairs = [(i, j) | i <- [0..(length tiles - 1)], j <- [i..(length tiles - 1)]]
        
  in trace ("tiles: " ++ show tiles)
     foldl max 0 [area (tiles !! i) (tiles !! j) | (i, j) <- indexPairs]

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

