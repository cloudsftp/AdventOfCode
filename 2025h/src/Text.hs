module Text
    ( capitalize
    , uncapitalize
    ) where

import Data.Char

capitalize :: String -> String
capitalize [] = []
capitalize (c:cs) = toUpper c : cs

uncapitalize :: String -> String
uncapitalize [] = []
uncapitalize (c:cs) = toLower c : cs

