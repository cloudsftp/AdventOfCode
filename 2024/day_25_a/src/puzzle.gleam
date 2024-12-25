import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let #(locks, keys) = parse(content)

  io.debug(locks)
  io.debug(keys)

  let result =
    io.debug(pairs(locks, keys))
    |> list.count(fn(pair) {
      let #(lock, key) = pair

      lock
      |> list.zip(key)
      |> list.all(fn(pair) { pair.0 + pair.1 < 8 })
    })

  io.debug(result)
}

fn pairs(list_a: List(a), list_b: List(b)) -> List(#(a, b)) {
  list_a
  |> list.fold([], fn(pairs, element_a) {
    list_b
    |> list.fold(pairs, fn(pairs, element_b) {
      [#(element_a, element_b), ..pairs]
    })
  })
}

fn parse(content: String) -> #(List(List(Int)), List(List(Int))) {
  let parts = string.split(content, on: "\n\n")

  parts
  |> list.map(string.trim)
  |> list.filter(fn(part) { !string.is_empty(part) })
  |> list.fold(#([], []), fn(acc, part) {
    let #(locks, keys) = acc

    let assert Ok(#(first_line, _)) = string.split_once(part, on: "\n")
    case first_line {
      "....." -> {
        #(locks, [count_heights(part), ..keys])
      }
      _ -> {
        #([count_heights(part), ..locks], keys)
      }
    }
  })
}

fn count_heights(part: String) -> List(Int) {
  part
  |> string.split(on: "\n")
  |> list.fold([0, 0, 0, 0, 0, 0, 0], fn(heights, line) {
    line
    |> string.to_graphemes
    |> list.zip(heights)
    |> list.map(fn(pair) {
      let #(char, height) = pair
      height
      + case char {
        "#" -> 1
        "." -> 0
        _ -> panic
      }
    })
  })
}
