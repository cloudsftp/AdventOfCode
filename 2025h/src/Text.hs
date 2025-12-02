module Text
    ( capitalize
    , uncapitalize
    , leftPad0
    ) where

import Data.Char

capitalize :: String -> String
capitalize [] = []
capitalize (c:cs) = toUpper c : cs

uncapitalize :: String -> String
uncapitalize [] = []
uncapitalize (c:cs) = toLower c : cs

leftPad0 :: Int -> String -> String
leftPad0 n xs
  | length xs >= n = xs
  | otherwise      = leftPad0 (n - 1) ('0':xs)
