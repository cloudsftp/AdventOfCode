module Lib
    ( ExampleType (..)
    , Year
    , ID
    ) where

data ExampleType = Small | Big deriving (Show, Read)

type Year = Int
type ID = Int
