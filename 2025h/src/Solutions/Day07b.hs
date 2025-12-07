module Solutions.Day07b
  ( solve
  ) where

import Data.Set (Set, empty, member, insert)
import Debug.Trace

solve :: String -> Int
solve input =
  let (startPosition, splitterPositions) = parseInput input
  in trace ("start position: " ++ show startPosition ++ " splitter positions: " ++ show splitterPositions)
     sum $ map snd $ foldl step [(startPosition, 1)] splitterPositions

step :: [(Int, Int)] -> Set Int -> [(Int, Int)]
step beamPositions splitterPositions =
  foldr (\
            (p, c) beamPositions ->
            if member p splitterPositions
            then
              let updated = addBeam (p - 1, c) $ addBeam (p + 1, c) beamPositions
              in trace ("splitting " ++ show (p, c) ++ " on position " ++ show p ++ "\n" ++ show beamPositions ++ " -> " ++ show updated)
                 updated
            else
              let updated = addBeam (p, c) beamPositions
              in trace ("not splitting " ++ show (p, c) ++ " on position " ++ show p ++ show beamPositions ++ "\n -> " ++ show updated)
                 updated
        )
  [] beamPositions

addBeam :: (Int, Int) -> [(Int, Int)] -> [(Int, Int)]
addBeam (p, c) existingBeams =
  if any ((==p) . fst) existingBeams
  then foldr (\
                 (ep, ec) beams ->
                 if ep == p
                 then (ep, ec + c):beams
                 else (ep, ec):beams
             )
       [] existingBeams
  else (p, c):existingBeams

-- parsing

parseInput :: String -> (Int, [Set Int])
parseInput input =
  let firstLine:splitterLines = lines input
      startPosition = parseStart firstLine
      splitterPositions = filter (not . null) $ map parseSplitterLine splitterLines
      
  in (startPosition, splitterPositions)

parseStart :: String -> Int
parseStart line =
  let positions = filter ((=='S') . snd) $ enumerate line
  in fst $ head positions

parseSplitterLine :: String -> Set Int
parseSplitterLine line =
  foldl (flip insert) empty
  $ map fst
  $ filter ((=='^') . snd)
  $ enumerate line

enumerate :: [a] -> [(Int, a)]
enumerate = snd . foldl (\(pos, acc) e -> (pos + 1, (pos, e):acc)) (0, [])
  
