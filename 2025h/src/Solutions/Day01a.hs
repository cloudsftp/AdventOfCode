module Solutions.Day01a (solve) where

import Lib

solve :: String -> Int
solve input = let state = foldl process (State { dial = 50, counter = 0 }) $ lines input
                in counter state

data State = State { dial :: Int
                   , counter :: Int
                   } deriving (Show)

data Direction = L | R deriving (Show, Read, Eq)

data Command = Command { direction :: Direction
                       , count :: Int
                       } deriving (Show)

process :: State -> String -> State
process State { dial = dial, counter = counter } line =
  let Command { direction = direction, count = count } = command line
      increase = if dial == 0 then 1 else 0
  in debug $ case direction of
          L -> State { dial = dialMod (dial - count) 100, counter = counter + increase }
          R -> State { dial = dialMod (dial + count) 100, counter = counter + increase }

dialMod :: Int -> Int -> Int
dialMod a n
  | a < 0 = dialMod (a + n) n
  | a >= n = dialMod (a - n) n
  | otherwise = a

command :: String -> Command
command line = let direction = read [head line] :: Direction
                   count = (read $ tail line) :: Int
               in debug $ Command { direction = direction, count = count }

