import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import rememo/memo
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

  use cache <- memo.create()
  let result =
    numbers
    |> list.map(fn(n) { blink(n, 0, 75, cache) })
    |> int.sum

  io.debug(result)
}

pub fn blink(n: Int, iteration: Int, limit: Int, cache) -> Int {
  use <- memo.memoize(cache, #(n, iteration))

  use <- bool.guard(iteration == limit, 1)

  case expand(n) {
    Single(n) -> blink(n, iteration + 1, limit, cache)
    Double(a, b) ->
      blink(a, iteration + 1, limit, cache)
      + blink(b, iteration + 1, limit, cache)
  }
}

type Expanded {
  Single(n: Int)
  Double(a: Int, b: Int)
}

fn expand(n: Int) -> Expanded {
  use <- bool.guard(n == 0, Single(1))

  case split_digits(n) {
    option.Some(#(first, second)) -> Double(first, second)
    option.None -> Single(n * 2024)
  }
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
