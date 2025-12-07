module Solutions.Day06b
  ( solve
  ) where

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
  let splitLines = reverse $ lines input
  
      operatorLine = head splitLines
      valueLines = (reverse . tail) splitLines
      
  in collectProblems operatorLine valueLines Nothing []

collectProblems :: String -> [String] -> Maybe Problem -> [Problem] -> [Problem]
collectProblems [] _ _ problems = problems
collectProblems (o:os) valueLines Nothing problems =
  let op = operator o
      (Just value, updatedValueLines) = scrapeValue valueLines
  in collectProblems os updatedValueLines (Just (op, [value])) problems
collectProblems (_:os) valueLines (Just (op, values)) problems =
  let (maybeValue, updatedValueLines) = scrapeValue valueLines
  in case maybeValue of
    Nothing -> collectProblems os updatedValueLines Nothing ((op, values):problems)
    Just value -> collectProblems os updatedValueLines (Just (op, value:values)) problems


scrapeValue :: [String] -> (Maybe Int, [String])
scrapeValue valueLines =
  let (digits, updatedValueLines) = foldr (\(d:ds) (digits, updatedValueLines) 
                                           -> (d:digits, ds:updatedValueLines))
                                    ([], []) valueLines
  in if all (== ' ') digits
  then (Nothing, updatedValueLines)
  else (Just $ read $ filter (/= ' ') digits, updatedValueLines)

operator :: Char -> Operator
operator '*' = Multiply
operator '+' = Add

