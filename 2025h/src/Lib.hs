module Lib
    ( ExampleType (..)
    , Year
    , ID
    , debug
    ) where

import Debug.Trace (traceShow)

debug :: Show a => a -> a
debug value = traceShow value value

data ExampleType = Small | Big deriving (Show, Read)

type Year = Int
type ID = Int
