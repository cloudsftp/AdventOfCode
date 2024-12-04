import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Direction {
  Up
  UpRight
  Right
  RightDown
  Down
  DownLeft
  Left
  LeftUp
}

type Candidates =
  List(#(Int, Int, Direction))

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
    x
    |> set.to_list
    |> list.map(fn(coordinates) {
      let #(i, j) = coordinates

      [Up, UpRight, Right, RightDown, Down, DownLeft, Left, LeftUp]
      |> list.map(fn(dir) { #(i, j, dir) })
    })
    |> list.flatten

  let candidates = walk(candidates, m)
  let candidates = walk(candidates, a)
  let candidates = walk(candidates, s)

  io.debug(list.length(candidates))
}

fn walk(candidates: Candidates, coordinates: Coordinates) -> Candidates {
  io.debug(candidates)
  use #(i, j, dir) <- list.filter_map(candidates)

  let #(i, j) = case dir {
    Up -> #(i - 1, j)
    UpRight -> #(i - 1, j + 1)
    Right -> #(i, j + 1)
    RightDown -> #(i + 1, j + 1)
    Down -> #(i + 1, j)
    DownLeft -> #(i + 1, j - 1)
    Left -> #(i, j - 1)
    LeftUp -> #(i - 1, j - 1)
  }

  let ok = coordinates |> set.contains(#(i, j))

  case ok {
    True -> Ok(#(i, j, dir))
    False -> Error(Nil)
  }
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
