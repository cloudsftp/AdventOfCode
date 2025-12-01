module Data
  ( readExample
  ) where

import System.FilePath

import Lib
import Text

readExample :: Year -> ID -> ExampleType -> IO String
readExample year problemId exampleType = do
  let
    yearPart = show year
    idPart = leftPad0 2 $ show problemId
    typePart = uncapitalize $ show exampleType
    fileName = joinPath ["data", yearPart, idPart, typePart]
  putStrLn $ "Attemting to open file " ++ fileName ++ "\n"
  readFile fileName

leftPad0 :: Int -> String -> String
leftPad0 n xs
  | length xs >= n = xs
  | otherwise      = leftPad0 (n - 1) ('0':xs)
