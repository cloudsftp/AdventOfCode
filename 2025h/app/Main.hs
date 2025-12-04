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

main :: IO ()
main = do
  args <- getArgs
  
  if length args < 3 then do
    putStrLn "Please specify the problem id (1-12), the part (a | b), and the input type (small | big)"
    return ()
    
  else do
    let exerciseId = read (head args) :: ID
        exercisePart = read (capitalize $ args !! 1) :: Part
        exampleType = read (capitalize $ args !! 2) :: ExampleType

    input <- readExample 2025 exerciseId exampleType

    let functions = fromList [ (( 1, A), Solutions.Day01a.solve)
                             , (( 1, B), Solutions.Day01b.solve)
                             , (( 2, A), Solutions.Day02a.solve)
                             , (( 2, B), Solutions.Day02b.solve)
                             , (( 3, A), Solutions.Day03a.solve)
                             , (( 3, B), Solutions.Day03b.solve)
                             , (( 4, A), Solutions.Day04a.solve)
                             , (( 4, B), Solutions.Day04b.solve)
                             ]
        function = functions ! (exerciseId, exercisePart)
        result = function input :: Int

    putStrLn $ "The result is: " ++ show result


