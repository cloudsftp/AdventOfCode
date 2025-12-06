module Solutions.Day06a
  ( solve
  ) where

import Data.List.Split (splitOn)
import Debug.Trace

data Operator = Add | Multiply deriving (Show)
type Problem = (Operator, [Int])

solve :: String -> Int
solve input =
  let problems = parseInput input
  in sum $ map evaluate problems

evaluate :: Problem -> Int
evaluate (Add, values) = sum values
evaluate (Multiply, values) = product values

-- parsing

parseInput :: String -> [Problem]
parseInput input =
  let splitLines = reverse $ map splitLine $ lines input
  
      operatorLine = head splitLines
      operators = map operator operatorLine
      
      valueLines = tail splitLines
      valueLists = map (map read) valueLines
      
  in collectProblems operators valueLists []

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

