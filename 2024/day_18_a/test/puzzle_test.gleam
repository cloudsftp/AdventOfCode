import gleam/io
import gleam/list
import gleam/set
import gleeunit
import gleeunit/should
import puzzle

pub fn main() {
  gleeunit.main()
}
//pub fn possible_presses_test() {
//  let test_cases = [
//    #(1, 1, 2, [#(2, 0), #(1, 1), #(0, 2)]),
//    #(69, 27, 18_641, [#(0, 690)]),
//  ]
//
//  use #(a, b, t, presses) <- list.each(test_cases)
//  let presses = presses |> set.from_list
//
//  puzzle.possible_presses(a, b, t)
//  |> should.equal(presses)
//}
