module Solutions.Day09b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Data.List (intersperse, sortOn)
import Debug.Trace
import Data.Set (Set, empty, insert, member)
import qualified Data.Set as Set (filter)

type Tile = (Int, Int)

solve :: String -> Int
solve input =
  let corners = parseInput input

      cornerPairs = [(corners !! i, corners !! j)
                    | i <- [0..(length corners - 1)]
                    , j <- [i..(length corners - 1)]]

      areas = sortOn snd
            $ map (\(i, j) -> ((i, j), area i j)) cornerPairs

      (horizontalBorderTiles, verticalBorderTiles) = collectBorders corners
      possibleAreas = filterAreas horizontalBorderTiles verticalBorderTiles areas

        
  in trace ("corners: " ++ show corners)
            -- ++ "\ncorner pairs: " ++ show cornerPairs
            -- ++ "\n\nhorizontal: " ++ show horizontalBorderTiles
            -- ++ "\nvertical: " ++ show verticalBorderTiles)
     snd $ head possibleAreas

type Area = ((Tile, Tile), Int)
type Areas = [Area]
filterAreas :: Set Tile -> Set Tile -> Areas -> Areas
filterAreas vertical horizontal = filter (areaPossible vertical horizontal)

areaPossible :: Set Tile -> Set Tile -> Area -> Bool
areaPossible horizontal vertical (((xi, yi), (xj, yj)), _) =
  let (xSmall, xBig) = orderTuple (xi, xj)
      (ySmall, yBig) = orderTuple (yi, yj)

      rectBorderTiles =
        [(xi, y) | y <- [ySmall..yBig]] ++
        [(xj, y) | y <- [ySmall..yBig]] ++
        [(x, yi) | x <- [xSmall..xBig]] ++
        [(x, yj) | x <- [xSmall..xBig]]

  in trace ("checking area: " ++ show ((xi, yi), (xj, yj)))
     all (inside horizontal vertical) rectBorderTiles

inside :: Set Tile -> Set Tile -> Tile -> Bool
inside horizontal vertical (x, y) =
  let crossHorizontal = Set.filter ((==x) . fst) horizontal
      crossHorizontalUp = Set.filter ((>y) . snd) crossHorizontal
      crossHorizontalDown = Set.filter ((<y) . snd) crossHorizontal
  
      crossVertical = Set.filter ((==y) . snd) vertical
      crossVerticalRight = Set.filter ((>x) . fst) crossVertical
      crossVerticalLeft = Set.filter ((<x) . fst) crossVertical

  in trace ("num crossing: " ++ show ((length crossHorizontalUp), (length crossHorizontalDown), (length crossVerticalLeft), (length crossVerticalRight)))
     odd (length crossHorizontalUp)
  && odd (length crossHorizontalDown)
  && odd (length crossVerticalLeft)
  && odd (length crossVerticalRight)

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
