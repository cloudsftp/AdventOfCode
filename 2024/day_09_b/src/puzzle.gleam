import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input.small")

  let #(files, files_rev, spaces) = parse_input(content)
  let #(files, spaces) = move_files(files, files_rev, spaces)
  io.debug(files)
  io.debug(spaces)

  let result = checksum(files, spaces)

  io.debug(result)
}

fn checksum(files: List(#(Int, Int)), spaces: List(Int)) -> Int {
  checksum_rec(files, spaces, 0, 0)
}

fn checksum_rec(
  files: List(#(Int, Int)),
  spaces: List(Int),
  index: Int,
  acc: Int,
) -> Int {
  case files {
    [] -> acc
    [#(id, size), ..rest] -> {
      io.debug(#(id, size))

      let delta =
        io.debug(list.range(index, index + size - 1))
        |> list.map(fn(index) { index * id })
        |> int.sum

      let acc = acc + delta

      let assert [space, ..spaces] = spaces
      let index = index + size + space
      io.debug(space)

      checksum_rec(rest, spaces, index, acc)
    }
  }
}

fn move_files(
  files: List(#(Int, Int)),
  files_rev: List(#(Int, Int)),
  spaces: List(Int),
) -> #(List(#(Int, Int)), List(Int)) {
  move_files_rec(files, files_rev, spaces, 0, list.length(files))
}

fn move_files_rec(
  files: List(#(Int, Int)),
  files_rev: List(#(Int, Int)),
  spaces: List(Int),
  index: Int,
  num_files: Int,
) -> #(List(#(Int, Int)), List(Int)) {
  print(files, spaces)
  case files_rev {
    [] -> #(files, spaces)
    [#(id, size), ..files_rev] -> {
      let source_pos = num_files - index - 1
      case position_to_fit_spot(spaces, size, source_pos) {
        option.None ->
          move_files_rec(files, files_rev, spaces, index + 1, num_files)
        option.Some(target_pos) -> {
          let index =
            bool.guard(target_pos + 1 == source_pos, index + 1, fn() { index })

          let files =
            files
            |> list.take(target_pos)
            |> list.append([#(id, size)])
            |> list.append(
              files
              |> list.drop(target_pos)
              |> list.take(source_pos - target_pos),
            )
            |> list.append(
              files
              |> list.drop(source_pos + 1),
            )

          let spaces = update_spaces(spaces, target_pos - 1, source_pos, size)

          move_files_rec(files, files_rev, spaces, index, num_files)
        }
      }
    }
  }
}

fn update_spaces(
  spaces: List(Int),
  target_pos: Int,
  source_pos: Int,
  size: Int,
) -> List(Int) {
  use <- bool.guard(list.is_empty(spaces), [])

  let assert [first, ..spaces] = spaces

  use <- bool.guard(target_pos == 0, [
    0,
    first - size,
    ..update_spaces(spaces, target_pos - 1, source_pos - 1, size)
  ])

  use <- bool.guard(source_pos == 2, {
    case spaces {
      [first, second, ..spaces] -> [first + size + second, ..spaces]
      [last] -> [last + size]
      [] -> [size]
    }
  })

  [first, ..update_spaces(spaces, target_pos - 1, source_pos - 1, size)]
}

fn position_to_fit_spot(
  spaces: List(Int),
  size: Int,
  limit: Int,
) -> option.Option(Int) {
  position_to_fit_spot_rec(spaces, size, limit, 1)
}

fn position_to_fit_spot_rec(
  spaces: List(Int),
  size: Int,
  limit: Int,
  index: Int,
) -> option.Option(Int) {
  use <- bool.guard(list.is_empty(spaces) || index > limit, option.None)

  let assert [first, ..rest] = spaces
  use <- bool.guard(first >= size, option.Some(index))
  position_to_fit_spot_rec(rest, size, limit, index + 1)
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
    [count, ..rest] -> {
      let #(files, spaces) = split_blocks_recursive(rest, index + 1)

      case index % 2 {
        0 -> #([#(index / 2, count), ..files], spaces)
        _ -> #(files, [count, ..spaces])
      }
    }
  }
}

fn print(files: List(#(Int, Int)), spaces: List(Int)) {
  io.print(to_string(files, spaces, ""))
}

fn to_string(files: List(#(Int, Int)), spaces: List(Int), acc: String) -> String {
  case files {
    [] -> string.append(acc, "\n")
    [#(id, size), ..files] -> {
      let acc =
        acc
        |> string.append(
          list.range(0, size - 1)
          |> list.map(fn(_) {
            id
            |> int.to_string
          })
          |> string.concat,
        )

      let acc =
        acc
        |> string.append(case spaces {
          [] -> ""
          [space, ..] if space == 0 -> ""
          [space, ..] -> {
            list.range(0, space - 1)
            |> list.map(fn(_) { "." })
            |> string.concat
          }
        })

      let spaces = case spaces {
        [] -> []
        [_, ..spaces] -> spaces
      }

      to_string(files, spaces, acc)
    }
  }
}
