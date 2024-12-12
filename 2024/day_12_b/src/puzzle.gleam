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
    |> list.fold([], fn(acc, group) { list.append(group |> split, acc) })
    |> list.map(score_group)
    |> int.sum

  io.debug(result)
}

pub type Edge {
  Vert(i: Int, j: Int)
  Hor(i: Int, j: Int)
}

type Direction {
  Up
  Right
  Down
  Left
}

pub fn score_group(group: set.Set(Position)) -> Int {
  let edges = group |> get_edges
  let num_sides = edges |> walk_edges

  io.debug(#(group |> set.size, num_sides, group))

  { group |> set.size } * num_sides
}

fn walk_edges(edges: set.Set(Edge)) -> Int {
  let assert Ok(edge) =
    edges
    |> set.to_list
    |> list.first

  let direction = case edge {
    Vert(_, _) -> Down
    Hor(_, _) -> Right
  }

  edges |> walk_edges_recurse(direction, edge, edge, 0)
}

fn walk_edges_recurse(
  edges: set.Set(Edge),
  direction: Direction,
  current: Edge,
  start: Edge,
  score: Int,
) -> Int {
  let same_direction = case current, direction {
    Vert(i, j), Up -> Vert(i - 1, j)
    Vert(i, j), Down -> Vert(i + 1, j)
    Hor(i, j), Right -> Hor(i, j + 1)
    Hor(i, j), Left -> Hor(i, j - 1)
    _, _ -> panic
  }
  use <- bool.lazy_guard(edges |> set.contains(same_direction), fn() {
    walk_edges_recurse_guard(edges, direction, same_direction, start, score)
  })

  let score = score + 1

  let #(left, new_direction) = case current, direction {
    Vert(i, j), Up -> #(Hor(i, j - 1), Left)
    Vert(i, j), Down -> #(Hor(i + 1, j), Right)
    Hor(i, j), Right -> #(Vert(i - 1, j + 1), Up)
    Hor(i, j), Left -> #(Vert(i, j), Down)
    _, _ -> panic
  }
  use <- bool.lazy_guard(edges |> set.contains(left), fn() {
    walk_edges_recurse_guard(edges, new_direction, left, start, score)
  })

  let #(right, new_direction) = case current, direction {
    Vert(i, j), Up -> #(Hor(i, j), Right)
    Vert(i, j), Down -> #(Hor(i + 1, j - 1), Left)
    Hor(i, j), Right -> #(Vert(i, j + 1), Down)
    Hor(i, j), Left -> #(Vert(i - 1, j), Up)
    _, _ -> {
      panic
    }
  }
  use <- bool.lazy_guard(edges |> set.contains(right), fn() {
    walk_edges_recurse_guard(edges, new_direction, right, start, score)
  })

  io.println_error("no connecting edge")
  panic
}

fn walk_edges_recurse_guard(
  edges: set.Set(Edge),
  direction: Direction,
  current: Edge,
  start: Edge,
  score: Int,
) -> Int {
  use <- bool.guard(current == start, score)
  walk_edges_recurse(edges, direction, current, start, score)
}

pub fn get_edges(group: set.Set(Position)) -> set.Set(Edge) {
  group
  |> set.fold(set.new(), fn(edges, plot) {
    plot
    |> neighbors
    |> list.fold(edges, fn(edges, neighbor) {
      use <- bool.guard(group |> set.contains(neighbor), edges)

      edges
      |> set.insert(case plot, neighbor {
        #(i, j), #(l, k) if l == i && k < j -> Vert(i, j)
        #(i, j), #(l, k) if l == i && k > j -> Vert(i, k)
        #(i, j), #(l, k) if l < i && k == j -> Hor(i, j)
        #(i, j), #(l, k) if l > i && k == j -> Hor(l, j)
        _, _ -> panic
      })
    })
  })
}

fn neighbors(plot: Position) -> List(Position) {
  let #(i, j) = plot

  [#(i + 1, j), #(i - 1, j), #(i, j + 1), #(i, j - 1)]
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
