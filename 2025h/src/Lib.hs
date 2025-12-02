module Lib
    ( ExampleType (..)
    , Year
    , Part
    , ID
    , debug
    ) where

import Debug.Trace (traceShow)

debug :: Show a => a -> a
debug value = traceShow value value
-- debug value = value

data ExampleType = Small | Big deriving (Show, Read)

type Year = Int
data Part = A | B deriving (Show, Read)
type ID = Int
