module Solutions.Day06b
  ( solve
  ) where

import Data.List.Split (splitOn)
import Debug.Trace

data Operator = Add | Multiply deriving (Show)
type Problem = (Operator, [Int])

solve :: String -> Int
solve input =
  let problems = parseInput input
  in trace ("problems: " ++ show problems)
     sum $ map evaluate problems

evaluate :: Problem -> Int
evaluate (Add, values) = sum values
evaluate (Multiply, values) = product values

-- parsing

parseInput :: String -> [Problem]
parseInput input =
  let splitLines = reverse $ map reverse $ lines input
  
      operatorLine = head splitLines
      valueLines = (reverse . tail) splitLines
      
  in trace ("value lines " ++ show valueLines)
     collectProblems operatorLine valueLines [] []

collectProblems :: String -> [String] -> [Int] -> [Problem] -> [Problem]
collectProblems [] _ _ problems = problems
collectProblems (o:os) valueLines values problems = 
  let
    (digits, updatedValueLinesRev) = foldl (\(digits, updatedValueLines) (d:ds)
                                           -> (d:digits, ds:updatedValueLines))
                                  ([], []) valueLines
    updatedValueLines = reverse updatedValueLinesRev
  in if o == ' ' && all (== ' ') digits
  then collectProblems os updatedValueLines [] problems
  else let
    value = read $ reverse $ filter (/= ' ') digits
    newValues = value:values
  in if o == ' '
  then collectProblems os updatedValueLines newValues problems
  else let
    problem = (operator [o], newValues)
  in collectProblems os updatedValueLines newValues (problem:problems)

operator :: String -> Operator
operator "*" = Multiply
operator "+" = Add

