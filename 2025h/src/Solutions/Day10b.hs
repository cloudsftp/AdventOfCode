module Solutions.Day10b
  ( solve
  ) where

import Data.List.Split (splitWhen)
import Debug.Trace

import Data.Map (Map, (!))
import qualified Data.Map as Map (empty, insert, fromList, keys, member, adjust)
import Data.Set (Set)
import qualified Data.Set as Set (empty, insert)
import Data.Maybe (fromMaybe)


solve :: String -> Int
solve input =
  let machines = parseInput input
  in trace ("machines: " ++ show machines)
     sum $ map minPresses machines

type Button = Set Int
data Machine = Machine { numberOfCounters :: Int
                       , counters :: State
                       , buttons :: [Button]
                       } deriving (Show)

minPresses :: Machine -> Int
minPresses machine =
  let initial = Map.fromList [(i, 0) | i <- [0..numberOfCounters machine - 1]]
      result = snd $ minPresses' machine Map.empty initial
  in fromMaybe 0 result

type State = Map Int Int
type Cache = Map State (Maybe Int)

minPresses' :: Machine -> Cache -> State -> (Cache, Maybe Int)
minPresses' machine cache state
  | Map.member state cache = trace ("cache hit on state " ++ show state ++ " -> " ++ show (cache ! state)) (cache, cache ! state)
  | stateViolates (counters machine) state =
    let result = Nothing
    in (Map.insert state result cache, result)
  | targetReached (counters machine) state =
    let result = Just 0
    in (Map.insert state result cache, result)
  | otherwise =
    trace ("chache miss on state " ++ show state) $
    let recurse (cache, acc) button =
          let increaseCounter state' index =
                let previous = state' ! index
                in Map.insert index (previous + 1) state'

              newState = foldl increaseCounter state button
              
              (newCache, previousMin) = minPresses' machine cache newState

              newAcc = case (acc, previousMin) of
                (Nothing, Nothing) -> Nothing
                (Just n, Nothing) -> Just n
                (Nothing, Just m) -> Just $ m + 1
                (Just n, Just m) ->
                  if n < m + 1
                  then Just n
                  else Just $ m + 1
              
          in (newCache, newAcc)

        (newCache, result) = foldl recurse (cache, Nothing) $ buttons machine
    in (Map.insert state result newCache, result)

stateViolates :: State -> State -> Bool
stateViolates target state =
  let indices = Map.keys target
      counterOk index = state ! index <= target ! index
  in not $ all counterOk indices

targetReached :: State -> State -> Bool
targetReached target state =
  let indices = Map.keys target
      counterOk index = state ! index == target ! index
  in all counterOk indices

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
      countersValueParts = map read $ splitWhen (==',') countersPart
      numberOfCounters' = length countersValueParts

      counters' = Map.fromList [(i, countersValueParts !! i) | i <- [0..length countersValueParts - 1]]

  in Machine { numberOfCounters = numberOfCounters'
             , counters = counters'
             , buttons = buttons'
             }

filterOutBrackets :: Char -> Char -> Bool
filterOutBrackets '[' c = c /= '[' && c /= ']'
filterOutBrackets '(' c = c /= '(' && c /= ')'
filterOutBrackets '{' c = c /= '{' && c /= '}'

