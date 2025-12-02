module Main (main) where

import System.Environment

import Lib (ExampleType (..), Part (..), ID)
import Data (readExample)
import Text (capitalize)
import qualified Solutions.Day01a (solve)
import qualified Solutions.Day01b (solve)

main :: IO ()
main = do
  args <- getArgs
  
  if length args < 3 then do
    putStrLn "Please specify the problem id (1-12), the part (a | b), and the input type (small | big)"
    return ()
    
  else do
    let exerciseId = read (args !! 0) :: ID
        exercisePart = read (capitalize $ args !! 1) :: Part
        exampleType = read (capitalize $ args !! 2) :: ExampleType

    input <- readExample 2025 exerciseId exampleType

    let solve = Solutions.Day01a.solve
        result = solve input :: Int

    putStrLn $ "The result is: " ++ show result


