import gleam/bool
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Positions =
  set.Set(#(Int, Int))

type Direction {
  Up
  Right
  Down
  Left
}

pub fn main() {
  use content <- result.try(
    simplifile.read("input")
    |> result.replace_error(Nil),
  )

  let lines =
    content
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })

  let height = list.length(lines)
  use width <- result.try(
    list.first(lines)
    |> result.map(string.length),
  )

  let blocks = parse_positions(lines, "#")
  use start_position <- result.map(
    parse_positions(lines, "^")
    |> set.to_list
    |> list.first,
  )

  let possibilities =
    start_position
    |> walk(blocks, height, width)

  Ok(io.debug(possibilities |> set.size))
}

fn walk(
  start_position: #(Int, Int),
  blocks: Positions,
  height: Int,
  width: Int,
) -> Positions {
  start_position
  |> walk_recurse(blocks, height, width, Up, set.new(), set.new())
}

fn walk_recurse(
  current_position: #(Int, Int),
  blocks: Positions,
  height: Int,
  width: Int,
  direction: Direction,
  visited: set.Set(#(#(Int, Int), Direction)),
  possibilities: Positions,
) -> Positions {
  let visited =
    visited
    |> set.insert(#(current_position, direction))

  let next_position =
    current_position
    |> step(direction)

  use <- bool.guard(
    False
      // Out of bounds
      || next_position.0 < 0
      || next_position.0 >= height
      || next_position.1 < 0
      || next_position.1 >= width,
    possibilities,
  )

  let would_block_prevous_path =
    [Up, Right, Down, Left]
    |> list.any(fn(direction) {
      visited
      |> set.contains(#(next_position, direction))
    })

  let right_turn_closes_loop =
    !would_block_prevous_path
    && check_loop(
      current_position,
      blocks |> set.insert(next_position),
      height,
      width,
      direction |> turn,
      visited,
    )

  let possibilities = case right_turn_closes_loop {
    True -> possibilities |> set.insert(next_position)
    False -> possibilities
  }

  let #(direction, next_position) = case blocks |> set.contains(next_position) {
    True -> #(direction |> turn, current_position)
    False -> #(direction, next_position)
  }

  walk_recurse(
    next_position,
    blocks,
    height,
    width,
    direction,
    visited,
    possibilities,
  )
}

fn check_loop(
  current_position: #(Int, Int),
  blocks: Positions,
  height: Int,
  width: Int,
  direction: Direction,
  visited: set.Set(#(#(Int, Int), Direction)),
) -> Bool {
  use <- bool.guard(
    visited
      |> set.contains(#(current_position, direction)),
    True,
  )

  let visited =
    visited
    |> set.insert(#(current_position, direction))

  let next_position =
    current_position
    |> step(direction)

  use <- bool.guard(
    False
      // Out of bounds
      || next_position.0 < 0
      || next_position.0 >= height
      || next_position.1 < 0
      || next_position.1 >= width,
    False,
  )

  let #(direction, next_position) = case blocks |> set.contains(next_position) {
    True -> #(direction |> turn, current_position)
    False -> #(direction, next_position)
  }

  check_loop(next_position, blocks, height, width, direction, visited)
}

fn step(current_position: #(Int, Int), direction: Direction) -> #(Int, Int) {
  let #(i, j) = current_position
  case direction {
    Up -> #(i - 1, j)
    Right -> #(i, j + 1)
    Down -> #(i + 1, j)
    Left -> #(i, j - 1)
  }
}

fn turn(direction: Direction) -> Direction {
  case direction {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
}

fn parse_positions(lines: List(String), marker: String) -> Positions {
  use positions, line, i <- list.index_fold(lines, set.new())
  use positions, character, j <- list.index_fold(
    string.to_graphemes(line),
    positions,
  )

  use <- bool.guard(character != marker, positions)
  set.insert(positions, #(i, j))
}
