module Solutions.Day09b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Data.List (intersperse)
import Debug.Trace
import Data.Set (Set, empty, insert, member)

type Tile = (Int, Int)

solve :: String -> Int
solve input =
  let corners = parseInput input

      cornerPairs = [(corners !! i, corners !! j)
                    | i <- [0..(length corners - 1)]
                    , j <- [i..(length corners - 1)]]

      (horizontalBorderTiles, verticalBorderTiles) = collectBorders corners

        
  in trace ("corners: " ++ show corners
            ++ "\ncorner pairs: " ++ show cornerPairs
            ++ "\n\nhorizontal: " ++ show horizontalBorderTiles
            ++ "\nvertical: " ++ show verticalBorderTiles
            ++ "\n\n" ++ renderField corners (horizontalBorderTiles, verticalBorderTiles) ++ "\n")
     0

collectBorders :: [Tile] -> (Set Tile, Set Tile)
collectBorders corners =
  let cornerPairs = [(corners !! i, corners !! j)
                    | i <- [0..(length corners - 1)]
                    , j <- [0..(length corners - 1)]
                    , j == i + 1
                      || (i == length corners - 1
                          && j == 0)
                    ]

      collect (horizontalBorderTiles, verticalBorderTiles) ((xi, yi), (xj, yj)) = 
        if xi == xj
        then let (ySmall, yBig) = orderTuple (yi, yj)
             in ( horizontalBorderTiles
                , foldr insert verticalBorderTiles [(xi, y) | y <- [ySmall..yBig]]
                )
        else let (xSmall, xBig) = orderTuple (xi, xj)
             in ( foldr insert horizontalBorderTiles [(x, yi) | x <- [xSmall..xBig]]
                , verticalBorderTiles
                )
      
   in foldl collect (empty, empty) cornerPairs

orderTuple :: (Ord a) => (a, a) -> (a, a)
orderTuple (i, j) = if i < j
                    then (i, j)
                    else (j, i)

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

renderField :: [Tile] -> (Set Tile, Set Tile) -> String
renderField corners borderTiles =
  let width = maximum (map fst corners) + 1
      height = maximum (map snd corners) + 1
  in concat
  $ intersperse "\n"
  $ map (renderLine corners borderTiles width) [0..height]

renderLine :: [Tile] -> (Set Tile, Set Tile) -> Int -> Int -> String
renderLine corners borderTiles width j =
  map (renderTile corners borderTiles j) [0..width]

renderTile :: [Tile] -> (Set Tile, Set Tile) -> Int -> Int -> Char
renderTile corners (horizontalBorderTiles, verticalBorderTiles) j i =
  if any (==(i, j)) corners then '+'
  else if member (i, j) horizontalBorderTiles then '-'
  else if member (i, j) verticalBorderTiles then '|'
  else '.'
