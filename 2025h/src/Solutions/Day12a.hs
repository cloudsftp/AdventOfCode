module Solutions.Day12a
  ( solve
  ) where

import Data.List (delete)
import Data.List.Split (splitOn)
import Debug.Trace
--import Data.Map (Map, empty)

solve :: String -> Int
solve input =
  let (gifts, trees) = parseInput input

      mapTree ((h, w), amounts) =
        let space = h * w

            tupleProduct (a, b) = a * b
            required =
              sum
              $ map tupleProduct
              $ zip amounts gifts
        
        in (space, required)

      treeSpots = map mapTree trees

      valid (space, required) = space > required
  
  in trace ("gifts: " ++ show gifts ++
            "\ntrees: " ++ show trees ++
            "\ntree spots: " ++ show treeSpots)
     length $ filter valid treeSpots

type Size = (Int, Int)
--type Gift = Map Position Bool
type Gift = Int
type Tree = (Size, [Int])



-- parsing

parseInput :: String -> ([Gift], [Tree])
parseInput input =
  let sections = splitOn [[]] $ lines input
      n = length sections

      giftSections = take (n - 1) sections
      gifts = map parseGift giftSections

      treeLines = sections !! (n - 1)
      trees = map parseTree treeLines
  
  in (gifts, trees)

parseGift :: [String] -> Gift
parseGift (_:lines') =
  let collectGiftChars acc '#' = acc + 1
      collectGiftChars acc _ = acc
      collectGiftLines = foldl collectGiftChars
  in foldl collectGiftLines 0 lines'

parseTree :: String -> Tree
parseTree line =
  let parts = splitOn " " line

      [height, width] =
        map read
        $ splitOn "x"
        $ delete ':'
        $ head parts

      amounts =
        map read
        $ tail parts
      
  in ((height, width), amounts)

