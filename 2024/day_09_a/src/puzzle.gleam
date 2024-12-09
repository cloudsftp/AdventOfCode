import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input")

  let #(files, files_rev, spaces) = parse_input(content)
  let result = process(files, files_rev, spaces)

  io.debug(result)
}

fn process(
  files: List(#(Int, Int)),
  files_rev: List(#(Int, Int)),
  spaces: List(Int),
) -> Int {
  let limit =
    files
    |> list.map(fn(p) { p.1 })
    |> int.sum

  process_rec(files, files_rev, spaces, 0, limit, False, 0)
}

fn process_rec(
  files: List(#(Int, Int)),
  files_rev: List(#(Int, Int)),
  spaces: List(Int),
  index: Int,
  limit: Int,
  // consume space
  consume: Bool,
  acc: Int,
) -> Int {
  use <- bool.guard(index == limit, acc)

  case consume, spaces {
    False, spaces -> {
      let #(id, last, rest) = take_block(files)
      let acc = acc + index * id

      process_rec(rest, files_rev, spaces, index + 1, limit, last, acc)
    }
    True, [0, ..rest] ->
      process_rec(files, files_rev, rest, index, limit, False, acc)
    True, spaces -> {
      let #(id, _, rest) = take_block(files_rev)
      let acc = acc + index * id

      let #(last, spaces) = take_space(spaces)

      process_rec(files, rest, spaces, index + 1, limit, !last, acc)
    }
  }
}

fn take_block(blocks: List(#(Int, Int))) -> #(Int, Bool, List(#(Int, Int))) {
  let assert [#(id, count), ..rest] = blocks
  case count - 1 {
    0 -> #(id, True, rest)
    count -> #(id, False, [#(id, count), ..rest])
  }
}

fn take_space(spaces: List(Int)) -> #(Bool, List(Int)) {
  let assert [count, ..rest] = spaces
  case count - 1 {
    0 -> #(True, rest)
    count -> #(False, [count, ..rest])
  }
}

fn parse_input(
  content: String,
) -> #(List(#(Int, Int)), List(#(Int, Int)), List(Int)) {
  let assert Ok(content) =
    content
    |> string.split(on: "\n")
    |> list.first

  let assert Ok(blocks) =
    content
    |> string.to_graphemes
    |> list.map(int.parse)
    |> result.all

  let #(files, spaces) = split_blocks_recursive(blocks, 0)
  let files_rev = list.reverse(files)
  #(files, files_rev, spaces)
}

fn split_blocks_recursive(
  blocks: List(Int),
  index: Int,
) -> #(List(#(Int, Int)), List(Int)) {
  case blocks {
    [] -> #([], [])
    [first, ..rest] -> {
      let #(files, spaces) = split_blocks_recursive(rest, index + 1)

      case index % 2 {
        0 -> #(list.prepend(files, #(index / 2, first)), spaces)
        _ -> #(files, list.prepend(spaces, first))
      }
    }
  }
}
