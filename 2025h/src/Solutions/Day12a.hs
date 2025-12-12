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
  in trace ("gifts: " ++ show gifts ++ ", trees: " ++ show trees)
     0

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

