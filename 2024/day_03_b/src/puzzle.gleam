import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  use content <- result.map(simplifile.read("input"))

  use parts <- result.map(
    content
    |> string.split(on: "do()")
    |> list.map(fn(do_part) {
      do_part
      |> string.split(on: "don't()")
      |> list.first
    })
    |> result.all,
  )

  use partial_results <- result.map(
    parts
    |> list.map(run_section)
    |> result.all,
  )

  partial_results
  |> int.sum
  |> io.debug
}

fn run_section(content: String) -> Result(Int, Nil) {
  let pattern = "mul\\((\\d{1,3}),(\\d{1,3})\\)"
  use regex <- result.try(
    pattern
    |> regexp.compile(regexp.Options(False, True))
    |> result.replace_error(Nil),
  )

  let matches = regexp.scan(regex, content)

  use argument_pairs <- result.try(
    matches
    |> list.map(fn(match) { option.all(match.submatches) })
    |> option.all
    |> to_error,
  )

  use argument_pairs <- result.try(
    argument_pairs
    |> list.map(fn(submatches) {
      submatches
      |> list.map(int.parse)
      |> result.all
    })
    |> result.all,
  )

  use argument_pairs <- result.map(
    argument_pairs
    |> list.map(fn(submatches) {
      use first <- result.try(list.first(submatches))
      use rest <- result.try(list.rest(submatches))
      use second <- result.map(list.first(rest))
      #(first, second)
    })
    |> result.all,
  )

  argument_pairs
  |> list.map(fn(pair) {
    let #(a, b) = pair
    a * b
  })
  |> int.sum
}

fn to_error(opt: option.Option(a)) -> Result(a, Nil) {
  case opt {
    option.None -> Error(Nil)
    option.Some(val) -> Ok(val)
  }
}
