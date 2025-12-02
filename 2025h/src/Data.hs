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
