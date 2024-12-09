import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input.small")
  let assert Ok(content) =
    content
    |> string.split(on: "\n")
    |> list.first

  let assert Ok(blocks) =
    content
    |> string.to_graphemes
    |> list.map(int.parse)
    |> result.all

  let #(file_blocks, empty_blocks) =
    blocks
    |> list.index_fold(#([], []), fn(acc, i, block) {
      let #(file_blocks, empty_blocks) = acc

      case i % 2 {
        0 -> #(list.prepend(file_blocks, block), empty_blocks)
        _ -> #(file_blocks, list.prepend(empty_blocks, block))
      }
    })

  let file_blocks_reverse = file_blocks
  let file_blocks = list.reverse(file_blocks_reverse)
  let empty_blocks = list.reverse(empty_blocks)
}
