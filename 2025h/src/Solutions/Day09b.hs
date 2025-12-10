module Solutions.Day09b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Data.List (sortOn)
import Debug.Trace

type Tile = (Int, Int)

solve :: String -> Int
solve input =
  let corners = parseInput input

      cornerPairs = [(corners !! i, corners !! j)
                    | i <- [0..(length corners - 1)]
                    , j <- [i..(length corners - 1)]]

      areas = sortOn (\(_, area') -> -area')
            $ map (\(i, j) -> ((i, j), area i j)) cornerPairs

      possibleAreas = filterAreas corners areas
        
  in trace ("corners: " ++ show corners)
     snd $ head possibleAreas

type Area = ((Tile, Tile), Int)
type Areas = [Area]
filterAreas :: [Tile] -> Areas -> Areas
filterAreas corners = filter (areaPossible corners)

areaPossible :: [Tile] -> Area -> Bool
areaPossible corners (((xi, yi), (xj, yj)), _) =
  let (xSmall, xBig) = orderTuple (xi, xj)
      (ySmall, yBig) = orderTuple (yi, yj)

      cornerPairs = [(corners !! i, corners !! j)
                    | i <- [0..(length corners - 1)]
                    , j <- [0..(length corners - 1)]
                    , j == i + 1
                      || (i == length corners - 1
                          && j == 0)
                    ]

  in trace ("checking area: " ++ show ((xi, yi), (xj, yj)))
     all (not . borderCuts xSmall ySmall xBig yBig) cornerPairs

borderCuts :: Int -> Int -> Int -> Int -> (Tile, Tile) -> Bool
borderCuts xRectSmall yRectSmall xRectBig yRectBig ((xi, yi), (xj, yj)) =
  -- trace ("checking border " ++ show (xi, yi) ++ " -- " ++ show (xj, yj) ++ " for area " ++ show ((xRectSmall, yRectSmall), (xRectBig, yRectBig))) $
  if xi == xj
  then -- check vertical cut
    let x = xi
        xInRect = xRectSmall < x && x < xRectBig

        (yBorderSmall, yBorderBig) = orderTuple (yi, yj)
        yInRect = yBorderSmall < yRectBig && yRectSmall < yBorderBig
    in xInRect && yInRect
  else -- check horizontal cut
    let y = yi
        yInRect = yRectSmall < y && y < yRectBig
        
        (xBorderSmall, xBorderBig) = orderTuple (xi, xj)
        xInRect = xBorderSmall < xRectBig && xRectSmall < xBorderBig
    in xInRect && yInRect

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
