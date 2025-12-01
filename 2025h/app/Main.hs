module Main (main) where

import System.Environment

import Lib (ExampleType (..), ID)
import Data (readExample)
import Text (capitalize)

main :: IO ()
main = do
  args <- getArgs
  
  if (length args < 2) then do
    putStrLn "Please specify the problem id (1-12) and the input type (small | big)"
    return ()
    
  else do
    let id = read (args !! 0) :: ID
        exampleType = read (capitalize $ args !! 1) :: ExampleType

    content <- readExample 2025 id exampleType
    putStrLn ""
    putStrLn content
