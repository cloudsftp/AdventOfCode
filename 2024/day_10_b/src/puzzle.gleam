import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import glearray
import simplifile

type Field =
  glearray.Array(glearray.Array(Int))

type Position =
  #(Int, Int)

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let field = parse(content)

  let height = glearray.length(field)
  let assert Ok(width) =
    field
    |> glearray.get(0)
    |> result.map(glearray.length)

  let starts = find_starts(field)

  let result =
    starts
    |> list.map(fn(start) {
      field
      |> walk(start, height, width)
    })
    |> int.sum

  io.debug(result)
}

fn walk(field: Field, start: Position, height: Int, width: Int) -> Int {
  walk_rec(field, height, width, start, 0)
}

fn walk_rec(
  field: Field,
  height: Int,
  width: Int,
  position: Position,
  reachable_level: Int,
) -> Int {
  let #(i, j) = position
  use <- bool.guard(i < 0 || i >= height || j < 0 || j >= width, 0)

  let level = field |> get_level(position)
  use <- bool.guard(level != reachable_level, 0)

  use <- bool.guard(level == 9, 1)

  [#(i + 1, j), #(i, j + 1), #(i - 1, j), #(i, j - 1)]
  |> list.map(fn(position) {
    walk_rec(field, height, width, position, level + 1)
  })
  |> int.sum
}

fn find_starts(field: Field) -> List(Position) {
  field
  |> glearray.to_list
  |> list.index_fold([], fn(acc, row, i) {
    row
    |> glearray.to_list
    |> list.index_fold(acc, fn(acc, level, j) {
      use <- bool.guard(level > 0, acc)
      [#(i, j), ..acc]
    })
  })
}

fn parse(content: String) -> Field {
  let lines =
    content
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })

  lines
  |> list.fold(glearray.new(), fn(acc, line) {
    let assert Ok(row) =
      line
      |> string.to_graphemes
      |> list.map(int.parse)
      |> result.all
      |> result.map(glearray.from_list)

    acc
    |> glearray.copy_push(row)
  })
}

fn get_level(field: Field, position: Position) -> Int {
  let #(i, j) = position

  let assert Ok(level) =
    field
    |> glearray.get(i)
    |> result.try(fn(row) {
      row
      |> glearray.get(j)
    })

  level
}
