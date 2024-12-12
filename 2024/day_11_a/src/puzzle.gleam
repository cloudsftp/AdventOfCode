import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let assert Ok(numbers) =
    content
    |> string.split(on: "\n")
    |> list.first
    |> result.try(fn(line) {
      line
      |> string.split(on: " ")
      |> list.map(int.parse)
      |> result.all
    })

  let result =
    list.range(0, 24)
    |> list.fold(numbers, fn(numbers, _) { expand(numbers) })
    |> list.length

  io.debug(result)
}

pub fn expand(numbers: List(Int)) -> List(Int) {
  numbers
  |> list.fold_right([], fn(acc, n) {
    use <- bool.guard(n == 0, [1, ..acc])

    case split_digits(n) {
      option.Some(#(first, second)) -> [first, second, ..acc]
      option.None -> [n * 2024, ..acc]
    }
  })
}

fn split_digits(n: Int) -> option.Option(#(Int, Int)) {
  let n = n |> int.to_string
  let length = n |> string.length

  use <- bool.guard(length % 2 != 0, option.None)

  let part_length = length / 2

  let assert Ok(left) =
    n
    |> string.slice(0, part_length)
    |> int.parse

  let assert Ok(right) =
    n
    |> string.slice(part_length, part_length)
    |> int.parse

  option.Some(#(left, right))
}
