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
  let assert Ok(content) = simplifile.read("input")

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
    |> list.fold([], fn(acc, group) { list.append(group |> split, acc) })
    |> list.map(score_group)
    |> list.map(fn(score) {
      let #(area, perimeter) = score
      area * perimeter
    })
    |> int.sum

  io.debug(result)
}

pub fn split(group: set.Set(Position)) -> List(set.Set(Position)) {
  split_rec(group, [])
}

fn split_rec(
  group: set.Set(Position),
  subgroups: List(set.Set(Position)),
) -> List(set.Set(Position)) {
  use <- bool.guard(group |> set.is_empty, subgroups)

  let #(group, seed) = group |> pop
  let #(group, subgroup) = group |> find_subgroup(seed)

  let subgroups = [subgroup, ..subgroups]
  split_rec(group, subgroups)
}

fn find_subgroup(
  group: set.Set(Position),
  seed: Position,
) -> #(set.Set(Position), set.Set(Position)) {
  group |> find_subgroup_recurse(seed, set.new() |> set.insert(seed))
}

fn find_subgroup_recurse(
  group: set.Set(Position),
  current: Position,
  subgroup: set.Set(Position),
) -> #(set.Set(Position), set.Set(Position)) {
  let #(group, neighbors) = group |> pop_neighbors(current)

  neighbors
  |> set.fold(#(group, subgroup), fn(acc, neighbor) {
    let #(group, subgroup) = acc
    let subgroup = subgroup |> set.insert(neighbor)

    group |> find_subgroup_recurse(neighbor, subgroup)
  })
}

fn pop(group: set.Set(Position)) -> #(set.Set(Position), Position) {
  let assert Ok(element) =
    group
    |> set.to_list
    |> list.first

  let group =
    group
    |> set.delete(element)

  #(group, element)
}

fn pop_neighbors(
  group: set.Set(Position),
  plot: Position,
) -> #(set.Set(Position), set.Set(Position)) {
  let neighbors =
    group
    |> set.take(
      plot
      |> neighbors,
    )

  let group =
    neighbors
    |> set.fold(group, fn(group, neighbor) {
      group
      |> set.delete(neighbor)
    })

  #(group, neighbors)
}

fn score_group(group: set.Set(Position)) -> #(Int, Int) {
  io.debug(group)
  io.debug(
    group
    |> set.fold(#(0, 0), fn(acc, plot) {
      let #(area, perimeter) = acc
      #(area + 1, perimeter + 4 - { plot |> num_neighbors(group) })
    }),
  )
}

fn num_neighbors(plot: Position, group: set.Set(Position)) -> Int {
  use neighbor <- list.count(neighbors(plot))

  group
  |> set.contains(neighbor)
}

fn neighbors(plot: Position) -> List(Position) {
  let #(i, j) = plot

  [#(i + 1, j), #(i - 1, j), #(i, j + 1), #(i, j - 1)]
}
