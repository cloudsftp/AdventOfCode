module Data
  ( readExample
  , ExampleType (..))
where

import System.FilePath
import Data.Char

data ExampleType = Small | Big deriving (Show)

type Year = Int
type ID = Int

readExample :: Year -> ID -> ExampleType -> IO String
readExample year problemId exampleType = do
  let
    yearPart = show year
    idPart = leftPad0 2 $ show problemId
    typePart = uncapitalise $ show exampleType
    fileName = joinPath ["data", yearPart, idPart, typePart]
  putStrLn $ "Attemting to open file " ++ fileName
  readFile fileName

uncapitalise :: String -> String
uncapitalise [] = []
uncapitalise (c:cs) = toLower c : cs

leftPad0 :: Int -> String -> String
leftPad0 n xs
  | length xs >= n = xs
  | otherwise      = leftPad0 (n - 1) ('0':xs)
