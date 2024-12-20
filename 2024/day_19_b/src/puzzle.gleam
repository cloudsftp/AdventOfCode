import gleam/bool
import gleam/deque
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import glearray
import rememo/memo
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let #(available, desired) = parse(content)

  io.println(
    "number of patterns: "
    <> available |> list.length |> int.to_string
    <> ", number of desired patterns: "
    <> desired |> list.length |> int.to_string,
  )

  let result =
    desired
    |> list.map(fn(desired) {
      use cache <- memo.create()
      desired |> number_arrangements(available, cache, 0)
    })
    |> int.sum

  io.debug(result)
}

fn number_arrangements(
  desired: glearray.Array(Color),
  available: List(glearray.Array(Color)),
  cache,
  start: Int,
) -> Int {
  use <- memo.memoize(cache, start)

  use <- bool.guard(start >= { desired |> glearray.length }, 1)

  available
  |> list.fold(0, fn(acc, pattern) {
    case desired |> starts_with(start, pattern) {
      option.None -> acc
      option.Some(start) ->
        case desired |> number_arrangements(available, cache, start) {
          0 -> acc
          n -> acc + n
        }
    }
  })
}

fn starts_with(
  desired: glearray.Array(Color),
  start: Int,
  pattern: glearray.Array(Color),
) -> option.Option(Int) {
  let pattern_length = pattern |> glearray.length
  use <- bool.guard(
    pattern_length > { desired |> glearray.length } - start,
    option.None,
  )

  case
    list.range(0, pattern_length - 1)
    |> list.fold_until(True, fn(acc, i) {
      let assert Ok(a) = pattern |> glearray.get(i)
      let assert Ok(b) = desired |> glearray.get(start + i)

      case a == b {
        True -> list.Continue(acc)
        False -> list.Stop(False)
      }
    })
  {
    True -> option.Some(start + pattern_length)
    False -> option.None
  }
}

fn parse(content) -> #(List(glearray.Array(Color)), List(glearray.Array(Color))) {
  let assert Ok(#(available, desired)) = content |> string.split_once("\n\n")

  let available =
    available
    |> string.trim
    |> string.split(on: ", ")
    |> list.map(fn(part) {
      part
      |> string.to_graphemes
      |> list.map(get_color)
      |> glearray.from_list
    })

  let desired =
    desired
    |> string.trim
    |> string.split(on: "\n")
    |> list.map(fn(line) {
      line
      |> string.to_graphemes
      |> list.map(get_color)
      |> glearray.from_list
    })

  #(available, desired)
}

type Color {
  White
  Blue
  Black
  Red
  Green
}

fn get_color(char: String) -> Color {
  case char {
    "w" -> White
    "u" -> Blue
    "b" -> Black
    "r" -> Red
    "g" -> Green
    _ -> panic
  }
}
