import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Coordinates =
  set.Set(#(Int, Int))

pub fn main() {
  use content <- result.map(simplifile.read("input"))
  let lines =
    content
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })

  let #(x, m, a, s) = compute_coordinates(lines)

  let candidates =
    a
    |> set.to_list
    |> list.filter(fn(a) { is_x_mas(a, m, s) })

  io.debug(list.length(candidates))
}

fn is_x_mas(a: #(Int, Int), m: Coordinates, s: Coordinates) -> Bool {
  let #(i, j) = a

  let top_left_m = m |> set.contains(#(i - 1, j - 1))
  let bottom_left_m = m |> set.contains(#(i + 1, j - 1))
  let top_right_m = m |> set.contains(#(i - 1, j + 1))
  let bottom_right_m = m |> set.contains(#(i + 1, j + 1))

  let top_left_s = s |> set.contains(#(i - 1, j - 1))
  let bottom_left_s = s |> set.contains(#(i + 1, j - 1))
  let top_right_s = s |> set.contains(#(i - 1, j + 1))
  let bottom_right_s = s |> set.contains(#(i + 1, j + 1))

  { { top_left_m && bottom_right_s } || { top_left_s && bottom_right_m } }
  && { { top_right_m && bottom_left_s } || { top_right_s && bottom_left_m } }
}

fn compute_coordinates(
  lines: List(String),
) -> #(Coordinates, Coordinates, Coordinates, Coordinates) {
  let x = set.new()
  let m = set.new()
  let a = set.new()
  let s = set.new()

  let #(x, m, a, s, _) =
    lines
    |> list.fold(#(x, m, a, s, 0), process_line)

  #(x, m, a, s)
}

fn process_line(
  acc: #(Coordinates, Coordinates, Coordinates, Coordinates, Int),
  line: String,
) -> #(Coordinates, Coordinates, Coordinates, Coordinates, Int) {
  let #(x, m, a, s, i) = acc

  let #(x, m, a, s, _) = {
    use #(x, m, a, s, j), char <- list.fold(string.to_graphemes(line), #(
      x,
      m,
      a,
      s,
      0,
    ))

    let j = j + 1

    case char {
      "X" -> #(set.insert(x, #(i, j)), m, a, s, j)
      "M" -> #(x, set.insert(m, #(i, j)), a, s, j)
      "A" -> #(x, m, set.insert(a, #(i, j)), s, j)
      "S" -> #(x, m, a, set.insert(s, #(i, j)), j)
      _ -> #(x, m, a, s, j)
    }
  }

  #(x, m, a, s, i + 1)
}
