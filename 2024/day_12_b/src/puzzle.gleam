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
    |> int.sum

  io.debug(result)
}

pub type Edge {
  VertRight(i: Int, j: Int)
  VertLeft(i: Int, j: Int)
  HorAbove(i: Int, j: Int)
  HorBelow(i: Int, j: Int)
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

  { group |> set.size } * num_sides
}

fn walk_edges(edges: set.Set(Edge)) -> Int {
  let #(_, perimeter) = walk_edges_rec(edges, 0)
  perimeter
}

fn walk_edges_rec(edges: set.Set(Edge), perimeter: Int) -> #(set.Set(Edge), Int) {
  use <- bool.guard(edges |> set.is_empty, #(edges, perimeter))

  let assert Ok(edge) =
    edges
    |> set.to_list
    |> list.first

  let direction = case edge {
    VertRight(_, _) -> Down
    VertLeft(_, _) -> Down
    HorAbove(_, _) -> Right
    HorBelow(_, _) -> Right
  }

  let #(edges, delta) = edges |> walk_loops_recurse(direction, edge, edge, 0)
  let perimeter = perimeter + delta

  walk_edges_rec(edges, perimeter)
}

fn walk_loops_recurse(
  edges: set.Set(Edge),
  direction: Direction,
  current: Edge,
  start: Edge,
  score: Int,
) -> #(set.Set(Edge), Int) {
  let same_direction = case current, direction {
    VertLeft(i, j), Up -> VertLeft(i - 1, j)
    VertRight(i, j), Up -> VertRight(i - 1, j)
    VertLeft(i, j), Down -> VertLeft(i + 1, j)
    VertRight(i, j), Down -> VertRight(i + 1, j)
    HorAbove(i, j), Right -> HorAbove(i, j + 1)
    HorBelow(i, j), Right -> HorBelow(i, j + 1)
    HorAbove(i, j), Left -> HorAbove(i, j - 1)
    HorBelow(i, j), Left -> HorBelow(i, j - 1)
    _, _ -> panic
  }
  use <- bool.lazy_guard(edges |> set.contains(same_direction), fn() {
    walk_loops_recurse_guard(edges, direction, same_direction, start, score)
  })

  let score = score + 1

  let #(left_turn, new_direction) = case current, direction {
    VertLeft(i, j), Down -> #(HorBelow(i, j), Right)
    VertRight(i, j), Up -> #(HorAbove(i, j), Left)
    HorAbove(i, j), Left -> #(VertLeft(i, j), Down)
    HorBelow(i, j), Right -> #(VertRight(i, j), Up)
    VertLeft(i, j), Up -> #(HorBelow(i - 1, j - 1), Left)
    VertRight(i, j), Down -> #(HorAbove(i + 1, j + 1), Right)
    HorAbove(i, j), Right -> #(VertLeft(i - 1, j + 1), Up)
    HorBelow(i, j), Left -> #(VertRight(i + 1, j - 1), Down)
    _, _ -> panic
  }
  use <- bool.lazy_guard(edges |> set.contains(left_turn), fn() {
    walk_loops_recurse_guard(edges, new_direction, left_turn, start, score)
  })

  let #(right_turn, new_direction) = case current, direction {
    VertLeft(i, j), Up -> #(HorAbove(i, j), Right)
    VertRight(i, j), Down -> #(HorBelow(i, j), Left)
    HorAbove(i, j), Right -> #(VertRight(i, j), Down)
    HorBelow(i, j), Left -> #(VertLeft(i, j), Up)
    VertLeft(i, j), Down -> #(HorAbove(i + 1, j - 1), Left)
    VertRight(i, j), Up -> #(HorBelow(i - 1, j + 1), Right)
    HorAbove(i, j), Left -> #(VertRight(i - 1, j - 1), Up)
    HorBelow(i, j), Right -> #(VertLeft(i + 1, j + 1), Down)
    _, _ -> panic
  }
  use <- bool.lazy_guard(edges |> set.contains(right_turn), fn() {
    walk_loops_recurse_guard(edges, new_direction, right_turn, start, score)
  })

  io.println_error("no connecting edge")
  panic
}

fn walk_loops_recurse_guard(
  edges: set.Set(Edge),
  direction: Direction,
  current: Edge,
  start: Edge,
  score: Int,
) -> #(set.Set(Edge), Int) {
  let edges = edges |> set.delete(current)
  use <- bool.lazy_guard(current == start, fn() {
    #(edges |> set.delete(start), score)
  })
  walk_loops_recurse(edges, direction, current, start, score)
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
        #(i, j), #(l, k) if l == i && k < j -> VertLeft(i, j)
        #(i, j), #(l, k) if l == i && k > j -> VertRight(i, j)
        #(i, j), #(l, k) if l < i && k == j -> HorAbove(i, j)
        #(i, j), #(l, k) if l > i && k == j -> HorBelow(i, j)
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

fn pop(group: set.Set(a)) -> #(set.Set(a), a) {
  let assert Ok(element) =
    group
    |> set.to_list
    |> list.first

  let group =
    group
    |> set.delete(element)

  #(group, element)
}
