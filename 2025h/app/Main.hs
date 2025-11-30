module Main (main) where

import Data (readExample, ExampleType (..))

main :: IO ()
main = do
  content <- readExample 2024 01 Small
  putStrLn ""
  putStrLn content
