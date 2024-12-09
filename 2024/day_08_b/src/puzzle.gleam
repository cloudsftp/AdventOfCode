import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Position =
  #(Int, Int)

pub fn main() {
  let assert Ok(content) = simplifile.read("input")

  let #(antennas, height, width) = parse(content)

  let result =
    antennas
    |> dict.fold(set.new(), fn(acc, _, positions) {
      acc
      |> set.union(
        positions
        |> list.combination_pairs
        |> list.fold(set.new(), fn(acc, antennas) {
          acc
          |> set.union(compute_anti_nodes(antennas, height, width))
        }),
      )
    })
    |> set.size

  io.debug(result)
}

fn compute_anti_nodes(
  antennas: #(Position, Position),
  height: Int,
  width: Int,
) -> set.Set(Position) {
  let #(a1, a2) = antennas

  set.union(
    compute_anti_nodes_in_one_direction(#(a1, a2), height, width),
    compute_anti_nodes_in_one_direction(#(a2, a1), height, width),
  )
}

fn compute_anti_nodes_in_one_direction(
  antennas: #(Position, Position),
  height: Int,
  width: Int,
) -> set.Set(Position) {
  let #(#(i1, j1), #(i2, j2)) = antennas
  let #(id, jd) = #(i2 - i1, j2 - j1)

  let k = max_iterations(#(i2, j2), #(id, jd), height, width)

  list.range(0, k)
  |> list.map(fn(k) { #(i2 + k * id, j2 + k * jd) })
  |> set.from_list
}

fn max_iterations(
  position: Position,
  distance: Position,
  height: Int,
  width: Int,
) -> Int {
  let #(i, j) = position
  let #(id, jd) = distance

  case
    max_iterations_in_direction(i, id, height),
    max_iterations_in_direction(j, jd, width)
  {
    option.None, option.None -> panic
    option.Some(k), option.None -> k
    option.None, option.Some(k) -> k
    option.Some(k1), option.Some(k2) -> int.min(k1, k2)
  }
}

fn max_iterations_in_direction(an: Int, nd: Int, c: Int) -> option.Option(Int) {
  case nd {
    0 -> option.None
    nd if nd < 0 -> option.Some(an / -nd)
    nd -> option.Some({ c - an - 1 } / nd)
  }
}

fn parse(content: String) -> #(dict.Dict(String, List(Position)), Int, Int) {
  let lines =
    content
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })

  let height =
    lines
    |> list.length

  let assert Ok(width) =
    lines
    |> list.first
    |> result.map(string.length)

  let antennas =
    lines
    |> list.index_fold([], fn(acc, line, i) {
      line
      |> string.to_graphemes
      |> list.index_fold(acc, fn(acc, char, j) {
        case char {
          "." -> acc
          symbol ->
            acc
            |> list.prepend(#(symbol, #(i, j)))
        }
      })
    })
    |> list.group(fn(pair) {
      let #(symbol, _) = pair
      symbol
    })
    |> dict.map_values(fn(_, values) {
      values
      |> list.map(fn(pair) {
        let #(_, coordinates) = pair
        coordinates
      })
    })

  #(antennas, height, width)
}
