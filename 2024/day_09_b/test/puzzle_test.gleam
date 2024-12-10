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

pub fn move_file_test() {
  let test_cases = [
    #([#(0, 2, 2), #(1, 2, 2), #(2, 1, 2), #(3, 2, 2)], 0, 2, [
      #(0, 2, 0),
      #(2, 1, 1),
      #(1, 2, 5),
      #(3, 2, 2),
    ]),
    #([#(0, 2, 2), #(1, 2, 2), #(2, 1, 2)], 0, 2, [
      #(0, 2, 0),
      #(2, 1, 1),
      #(1, 2, 5),
    ]),
    #(
      [
        #(0, 2, 0),
        #(9, 2, 1),
        #(1, 3, 0),
        #(7, 3, 0),
        #(2, 1, 0),
        #(4, 2, 1),
        #(3, 3, 4),
        #(5, 4, 1),
        #(6, 4, 5),
        #(8, 4, 2),
      ],
      1,
      4,
      [
        #(0, 2, 0),
        #(9, 2, 0),
        #(2, 1, 0),
        #(1, 3, 0),
        #(7, 3, 1),
        #(4, 2, 1),
        #(3, 3, 4),
        #(5, 4, 1),
        #(6, 4, 5),
        #(8, 4, 2),
      ],
    ),
  ]

  use #(before, target, source, expected) <- list.each(test_cases)

  let assert Ok(file) =
    before
    |> list.drop(source)
    |> list.first

  puzzle.move_file(before, 0, target, source, file)
  |> should.equal(expected)
}
//pub fn update_spaces_test() {
//  let test_cases = [
//    #([2, 2, 2], 1, 2, 1, [0, 1, 5]),
//    #([3, 3, 3, 1, 1, 1, 1, 1, 0, 0], 1, 9, 2, [0, 1, 3, 3, 1, 1, 1, 1, 1, 2]),
//    #([0, 1, 3, 3, 1, 1, 1, 1, 1, 2], 3, 8, 3, [0, 1, 0, 0, 3, 1, 1, 1, 5, 2]),
//#([0, 1, 3, 3, 1, 1, 1, 1, 2], 2, 8, todo, []),
//  ]

//  use #(before, target, source, size, expected) <- list.each(test_cases)

//  puzzle.update_spaces(before, target, source, size)
//  |> should.equal(expected)
//}
