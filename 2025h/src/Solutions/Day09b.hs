module Solutions.Day09b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Debug.Trace
import Data.Set (Set, empty)

type Tile = (Int, Int)

solve :: String -> Int
solve input =
  let corners = parseInput input

      cornerPairs = [(corners !! i, corners !! j)
                    | i <- [0..(length corners - 1)]
                    , j <- [i..(length corners - 1)]]

      borderTiles = collectBorders corners

        
  in trace ("corner pairs: " ++ show cornerPairs)
     0

collectBorders :: [Tile] -> Set Tile
collectBorders corners =
  let cornerPairs = [(corners !! i, corners !! j)
                    | i <- [0..(length corners - 1)]
                    , j <- [0..(length corners - 1)]
                    , j == i + 1
                      || (i == length corners - 1
                          && j == 0)
                    ]

      collect borderTiles ((xi, yi), (xj, yj)) = union borderTiles
        if xi == xj
        then foldl (\acc y)
        else
      
   in foldl collect empty cornerPairs

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

-- visualizing

