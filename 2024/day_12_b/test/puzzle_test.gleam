import gleam/io
import gleam/list
import gleam/set
import gleeunit
import gleeunit/should
import puzzle

pub fn main() {
  gleeunit.main()
}

pub fn regex_test() {
  let test_cases = [
    #([#(0, 0), #(0, 1)], [[#(0, 0), #(0, 1)]]),
    #([#(0, 0), #(0, 1), #(1, 2)], [[#(0, 0), #(0, 1)], [#(1, 2)]]),
  ]

  use #(group, subgroups) <- list.each(test_cases)

  let group = group |> set.from_list
  let subgroups = subgroups |> list.map(set.from_list)

  io.debug(
    group
    |> puzzle.split,
  )
  |> list.all(fn(subgroup) {
    subgroups
    |> list.contains(subgroup)
  })
  |> should.be_true
}

pub fn get_edges_test() {
  let test_cases = [
    #([#(0, 0)], [
      puzzle.Vert(0, 0),
      puzzle.Hor(0, 0),
      puzzle.Vert(0, 1),
      puzzle.Hor(1, 0),
    ]),
    #([#(0, 0), #(0, 1)], [
      puzzle.Vert(0, 0),
      puzzle.Hor(0, 0),
      puzzle.Hor(0, 1),
      puzzle.Vert(0, 2),
      puzzle.Hor(1, 0),
      puzzle.Hor(1, 1),
    ]),
  ]

  use #(plots, edges) <- list.each(test_cases)

  plots
  |> set.from_list
  |> puzzle.get_edges
  |> should.equal(edges |> set.from_list)
}
