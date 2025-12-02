module Solutions.Day01b
  ( solve
  ) where

import Lib

solve :: String -> Int
solve input = let state = foldl process (debug $ State { dial = 50, counter = 0 }) $ lines input
                in counter state

data State = State { dial :: Int
                   , counter :: Int
                   } deriving (Show)

data Direction = L | R deriving (Show, Read, Eq)

data Command = Command { direction :: Direction
                       , count :: Int
                       } deriving (Show)

process :: State -> String -> State
process State { dial = currentDial, counter = c } line =
  let Command { direction = d, count = m } = parseLine line
      n = 100
      nextDial = mod (currentDial + (if d == L then (-1) else 1) * m) n
      increase = div (case d of
                        R -> currentDial + m
                        L -> if currentDial == 0 then m else n + m - currentDial
                      ) n
  in debug $ State { dial = nextDial, counter = c + increase }


parseLine :: String -> Command
parseLine line = let direction = read [head line] :: Direction
                     count = (read $ tail line) :: Int
                 in debug $ Command { direction = direction, count = count }
