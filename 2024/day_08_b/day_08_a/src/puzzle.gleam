import gleam/bool
import gleam/dict
import gleam/io
import gleam/list
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
        |> list.map(compute_negative_nodes)
        |> list.fold(set.new(), fn(acc, nodes) {
          let #(node1, node2) = nodes

          acc
          |> insert_if_in_bounds(node1, height, width)
          |> insert_if_in_bounds(node2, height, width)
        }),
      )
    })
    |> set.size

  io.debug(result)
}

fn compute_negative_nodes(
  positions: #(Position, Position),
) -> #(Position, Position) {
  let #(#(i1, j1), #(i2, j2)) = positions
  #(#(2 * i2 - i1, 2 * j2 - j1), #(2 * i1 - i2, 2 * j1 - j2))
}

fn insert_if_in_bounds(
  acc: set.Set(Position),
  node: Position,
  height: Int,
  width: Int,
) -> set.Set(Position) {
  let #(i, j) = node

  let is_out_of_bounds = !{ 0 <= i && i < height && 0 <= j && j < width }

  use <- bool.guard(is_out_of_bounds, acc)
  acc
  |> set.insert(node)
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
