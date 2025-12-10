module Solutions.Day10a
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Debug.Trace

import Data.Map (Map)
import qualified Data.Map as Map (empty, insert)
import Data.Set (Set)
import qualified Data.Set as Set (empty, insert, member)


solve :: String -> Int
solve input =
  let machines = parseInput input
  in trace ("machines: " ++ show machines)
     0

type Button = Set Int
data Machine = Machine { numberOfLights :: Int
                       , indicators :: Map Int Bool
                       , buttons :: [Button]
                       } deriving (Show)

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
        in trace ("number parts: " ++ show numberParts) button
        
      buttons' = map parseButton buttonParts
      
  in Machine { numberOfLights = numberOfLights'
             , indicators = indicators'
             , buttons = buttons'
             }

filterOutBrackets :: Char -> Char -> Bool
filterOutBrackets '[' c = c /= '[' && c /= ']'
filterOutBrackets '(' c = c /= '(' && c /= ')'
filterOutBrackets '{' c = c /= '{' && c /= '}'

