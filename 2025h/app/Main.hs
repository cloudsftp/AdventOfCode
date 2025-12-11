module Main (main) where

import System.Environment
import Data.Map

import Lib (ExampleType (..), Part (..), ID)
import Data (readExample)
import Text (capitalize)

import qualified Solutions.Day01a (solve)
import qualified Solutions.Day01b (solve)
import qualified Solutions.Day02a (solve)
import qualified Solutions.Day02b (solve)
import qualified Solutions.Day03a (solve)
import qualified Solutions.Day03b (solve)
import qualified Solutions.Day04a (solve)
import qualified Solutions.Day04b (solve)
import qualified Solutions.Day05a (solve)
import qualified Solutions.Day05b (solve)
import qualified Solutions.Day06a (solve)
import qualified Solutions.Day06b (solve)
import qualified Solutions.Day07a (solve)
import qualified Solutions.Day07b (solve)
import qualified Solutions.Day08a (solve)
import qualified Solutions.Day08b (solve)
import qualified Solutions.Day09a (solve)
import qualified Solutions.Day09b (solve)
import qualified Solutions.Day10a (solve)
import qualified Solutions.Day10b (solve)
import qualified Solutions.Day11a (solve)

main :: IO ()
main = do
  args <- getArgs
  
  if length args < 3 then do
    putStrLn "Please specify the problem id (1-12), the part (a | b), and the input type (small | debug | big)"
    return ()
    
  else do
    let functions = fromList [ (( 1, A), Solutions.Day01a.solve)
                             , (( 1, B), Solutions.Day01b.solve)
                             , (( 2, A), Solutions.Day02a.solve)
                             , (( 2, B), Solutions.Day02b.solve)
                             , (( 3, A), Solutions.Day03a.solve)
                             , (( 3, B), Solutions.Day03b.solve)
                             , (( 4, A), Solutions.Day04a.solve)
                             , (( 4, B), Solutions.Day04b.solve)
                             , (( 5, A), Solutions.Day05a.solve)
                             , (( 5, B), Solutions.Day05b.solve)
                             , (( 6, A), Solutions.Day06a.solve)
                             , (( 6, B), Solutions.Day06b.solve)
                             , (( 7, A), Solutions.Day07a.solve)
                             , (( 7, B), Solutions.Day07b.solve)
                             , (( 8, A), Solutions.Day08a.solve)
                             , (( 8, B), Solutions.Day08b.solve)
                             , (( 9, A), Solutions.Day09a.solve)
                             , (( 9, B), Solutions.Day09b.solve)
                             , ((10, A), Solutions.Day10a.solve)
                             , ((10, B), Solutions.Day10b.solve)
                             , ((11, A), Solutions.Day11a.solve)
                             ]

        exerciseId = read (head args) :: ID
        exercisePart = read (capitalize $ args !! 1) :: Part
        exampleType = read (capitalize $ args !! 2) :: ExampleType

        input = readExample 2025 exerciseId exampleType
        function = functions ! (exerciseId, exercisePart)

    result <- fmap function input
    putStrLn $ "The result is: " ++ show result


