module Solutions.Day10b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Debug.Trace

import Data.Map (Map, (!))
import qualified Data.Map as Map (empty, insert)
import Data.Set (Set, powerSet)
import qualified Data.Set as Set (empty, insert, member, map, filter, fold)


solve :: String -> Int
solve input =
  let machines = parseInput input
  in trace ("machines: " ++ show machines)
     sum $ map minPresses machines

type Button = Set Int
data Machine = Machine { numberOfCounters :: Int
                       , counters :: Map Int Int
                       , buttons :: [Button]
                       } deriving (Show)

minPresses :: Machine -> Int
minPresses machine =
  let buttonIndices = foldr Set.insert Set.empty [0..(length (buttons machine) - 1)]
      combinations = powerSet buttonIndices

      validCombinations = Set.filter (checkValid machine) combinations
      
  in minimum $ Set.map length validCombinations


checkValid :: Machine -> Set Int -> Bool
checkValid machine buttonIndices =
  let initialIndicators = foldr (`Map.insert` False) Map.empty [0..numberOfCounters machine - 1]
  
      -- toggleIndicator indicators' i =
      --   let currentValue = indicators' ! i
      --       newValue = not currentValue
      --   in Map.insert i newValue indicators'
      --
      -- toggleIndicators indicators' i =
      --   foldl toggleIndicator indicators' $ buttons machine !! i
      --   
      -- simulated = foldl toggleIndicators initialIndicators buttonIndices
      
  in False -- simulated == counters machine

-- parsing

parseInput :: String -> [Machine]
parseInput = map parseLine . lines

parseLine :: String -> Machine
parseLine line =
  let parts = splitWhen (==' ') line
      
      buttonParts =
        map (filter (filterOutBrackets '('))
        $ take (length parts - 2)
        $ tail parts
      parseButton buttonPart =
        let numberParts = splitWhen (==',') buttonPart
            button = foldr (Set.insert . read) Set.empty numberParts
        in button
        
      buttons' = map parseButton buttonParts

      countersPart = filter (filterOutBrackets '{') $ parts !! (length parts - 1)
      countersValueParts = splitWhen (==',') countersPart
      numberOfCounters' = trace ("counter value parts: " ++ show countersValueParts) length countersValueParts

      counters' = foldr ((`Map.insert` 0) . read) Map.empty countersValueParts

  in Machine { numberOfCounters = numberOfCounters'
             , counters = counters'
             , buttons = buttons'
             }

filterOutBrackets :: Char -> Char -> Bool
filterOutBrackets '[' c = c /= '[' && c /= ']'
filterOutBrackets '(' c = c /= '(' && c /= ')'
filterOutBrackets '{' c = c /= '{' && c /= '}'

