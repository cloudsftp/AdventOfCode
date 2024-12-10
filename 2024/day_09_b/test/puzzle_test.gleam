import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleeunit
import gleeunit/should
import puzzle

pub fn main() {
  gleeunit.main()
}

pub fn update_spaces_test() {
  let test_cases = [
    #([2, 2, 2], 1, 2, 1, [0, 1, 5]),
    #([3, 3, 3, 1, 1, 1, 1, 1, 0, 0], 1, 9, 2, [0, 1, 3, 3, 1, 1, 1, 1, 1, 2]),
    #([0, 1, 3, 3, 1, 1, 1, 1, 1, 2], 3, 8, 3, [0, 1, 0, 0, 3, 1, 1, 1, 5, 2]),
    //#([0, 1, 3, 3, 1, 1, 1, 1, 2], 2, 8, todo, []),
  ]

  use #(before, target, source, size, expected) <- list.each(test_cases)

  puzzle.update_spaces(before, target, source, size)
  |> should.equal(expected)
}
