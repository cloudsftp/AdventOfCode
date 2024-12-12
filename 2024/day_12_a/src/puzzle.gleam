import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import simplifile

type Position =
  #(Int, Int)

pub fn main() {
  let assert Ok(content) = simplifile.read("input.small")

  let plots =
    content
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })
    |> list.index_fold([], fn(plots, line, i) {
      line
      |> string.to_graphemes
      |> list.index_fold(plots, fn(plots, char, j) {
        [#(char, #(i, j)), ..plots]
      })
    })

  let groups =
    plots
    |> list.group(fn(pair) { pair.0 })
    |> dict.map_values(fn(_, plots) {
      plots
      |> list.map(fn(pair) { pair.1 })
      |> set.from_list
    })
    |> dict.values

  let result =
    groups
    |> list.map(score_group)
    |> list.map(fn(score) {
      let #(area, perimeter) = score
      area * perimeter
    })
    |> int.sum

  io.debug(result)
}

fn score_group(group: set.Set(Position)) -> #(Int, Int) {
  io.debug(group)
  io.debug(
    group
    |> set.fold(#(0, 0), fn(acc, plot) {
      let #(area, perimeter) = acc
      #(area + 1, perimeter + 4 - { plot |> neighbors(group) })
    }),
  )
}

fn neighbors(plot: Position, group: set.Set(Position)) -> Int {
  let #(i, j) = plot

  use neighbor <- list.count([
    #(i + 1, j),
    #(i - 1, j),
    #(i, j + 1),
    #(i, j - 1),
  ])

  group
  |> set.contains(neighbor)
}
