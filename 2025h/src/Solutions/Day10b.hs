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
data Machine = Machine { numberOfLights :: Int
                       , indicators :: Map Int Bool
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
  let initialIndicators = foldr (`Map.insert` False) Map.empty [0..numberOfLights machine - 1]
  
      toggleIndicator indicators' i =
        let currentValue = indicators' ! i
            newValue = not currentValue
        in Map.insert i newValue indicators'
        
      toggleIndicators :: Map Int Bool -> Int -> Map Int Bool
      toggleIndicators indicators' i =
        foldl toggleIndicator indicators' $ buttons machine !! i
        
      simulated = foldl toggleIndicators initialIndicators buttonIndices
      
  in simulated == indicators machine

-- parsing

parseInput :: String -> [Machine]
parseInput = map parseLine . lines

parseLine :: String -> Machine
parseLine line =
  let parts = splitWhen (==' ') line

      indicatorsPart = filter (filterOutBrackets '[') $ head parts
      numberOfLights' = length indicatorsPart

      parseIndicator (i, acc) c = ( i + 1
                                  , if c == '#'
                                    then Map.insert i True acc
                                    else Map.insert i False acc
                                  )
      indicators' = snd $ foldl parseIndicator (0, Map.empty) indicatorsPart
      
      buttonParts =
        map (filter (filterOutBrackets '('))
        $ take (length parts - 2)
        $ tail parts
      parseButton buttonPart =
        let numberParts = splitWhen (==',') buttonPart
            button = foldr (Set.insert . read) Set.empty numberParts
        in button
        
      buttons' = map parseButton buttonParts
      
  in Machine { numberOfLights = numberOfLights'
             , indicators = indicators'
             , buttons = buttons'
             }

filterOutBrackets :: Char -> Char -> Bool
filterOutBrackets '[' c = c /= '[' && c /= ']'
filterOutBrackets '(' c = c /= '(' && c /= ')'
filterOutBrackets '{' c = c /= '{' && c /= '}'

