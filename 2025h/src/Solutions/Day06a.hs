module Solutions.Day06a
  ( solve
  ) where

import Data.List.Split (splitOn)
import Debug.Trace

data Operator = Add | Multiply deriving (Show)
type Problem = (Operator, [Int])

solve :: String -> Int
solve input =
  let parsed = parseInput input
  in trace ("parsed: " ++ show parsed) 0

-- parsing

parseInput :: String -> [Problem]
parseInput input =
  let splitLines = reverse $ map splitLine $ lines input
  
      operatorLine = head splitLines
      operators = map operator operatorLine
      
      valueLines = tail splitLines
      valueLists = map (map read) valueLines
      
  in trace ("split lines: " ++ show splitLines)
     collectProblems operators valueLists []

collectProblems :: [Operator] -> [[Int]] -> [Problem] -> [Problem]
collectProblems [] _ problems = problems
collectProblems (o:os) valueLists problems =
  let (values, updatedValueLists) = foldl (\ (values, updatedValueLists) (v:vs)
                                           -> (v:values, vs:updatedValueLists))
                                    ([], []) valueLists
      problem = (o, values)
  in collectProblems os updatedValueLists (problem:problems)

splitLine :: String -> [String]
splitLine = filter (not . null) . splitOn [' ']

operator :: String -> Operator
operator "*" = Multiply
operator "+" = Add

