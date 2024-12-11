import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

pub type File =
  #(Int, Int, Int)

pub fn main() {
  let assert Ok(content) = simplifile.read("input")

  let #(files, num_files) = parse_input(content)
  let work = files |> list.reverse

  let files = move_files(work, files, num_files, 0)
  let result = files |> checksum

  io.debug(result)
}

fn checksum(files: List(File)) -> Int {
  let #(sum, _) =
    files
    |> list.fold(#(0, 0), fn(acc, file) {
      let #(sum, index) = acc
      let #(id, size, space) = file

      let delta =
        list.range(index, index + size - 1)
        |> list.map(fn(index) { index * id })
        |> int.sum
      let sum = sum + delta

      #(sum, index + size + space)
    })

  sum
}

fn move_files(
  work: List(File),
  files: List(File),
  num_files: Int,
  iteration: Int,
) -> List(File) {
  use <- bool.guard(work |> list.is_empty, files)
  let assert [file, ..work] = work

  let #(id_to_match, _, _) = file
  let source_index =
    files
    |> list.fold_until(0, fn(index, file) {
      let #(id, _, _) = file
      use <- bool.guard(id == id_to_match, list.Stop(index))
      list.Continue(index + 1)
    })

  let files = case find_free_space(files, file, 0, source_index) {
    option.None -> files
    option.Some(target_index) ->
      move_file(files, 0, target_index, source_index, file)
  }

  move_files(work, files, num_files, iteration + 1)
}

fn find_free_space(
  files: List(File),
  file: File,
  iteration: Int,
  limit: Int,
) -> option.Option(Int) {
  use <- bool.guard(iteration == limit, option.None)

  let #(_, size, _) = file
  let assert [#(_, _, space), ..files] = files

  use <- bool.guard(size <= space, option.Some(iteration))

  find_free_space(files, file, iteration + 1, limit)
}

pub fn move_file(
  files: List(File),
  iteration: Int,
  target: Int,
  source: Int,
  file: File,
) -> List(File) {
  let #(id_move, size_move, _) = file

  use <- bool.lazy_guard(iteration == target, fn() {
    let assert [#(id, size, space), ..files] = files

    [
      #(id, size, 0),
      #(id_move, size_move, space - size_move),
      ..move_file(files, iteration + 1, target, source, file)
    ]
  })

  use <- bool.lazy_guard(iteration == source - 1, fn() {
    case files {
      [#(id, size, space), #(_, freed_space, additional_space), ..files] -> [
        #(id, size, space + freed_space + additional_space),
        ..files
      ]
      _ -> panic
    }
  })

  let assert [first, ..rest] = files
  [first, ..move_file(rest, iteration + 1, target, source, file)]
}

fn parse_input(content: String) -> #(List(File), Int) {
  let assert Ok(content) =
    content
    |> string.split(on: "\n")
    |> list.first

  let assert Ok(blocks) =
    content
    |> string.to_graphemes
    |> list.map(int.parse)
    |> result.all

  let #(file_blocks, space_blocks, length) =
    blocks
    |> list.index_fold(#([], [], 0), fn(acc, block, index) {
      let #(file_blocks, space_blocks, length) = acc

      case index {
        index if index % 2 == 0 -> #(
          [block, ..file_blocks],
          space_blocks,
          length + 1,
        )
        index if index % 2 == 1 -> #(
          file_blocks,
          [block, ..space_blocks],
          length,
        )
        _ -> panic
      }
    })

  let space_blocks =
    space_blocks
    |> list.prepend(0)

  #(
    file_blocks
      |> list.zip(space_blocks)
      |> list.index_fold([], fn(acc, pair, index) {
        let id = length - index - 1
        let #(file, space) = pair

        acc
        |> list.prepend(#(id, file, space))
      }),
    length,
  )
}

fn print(files: List(File)) {
  io.print(to_string(files, ""))
}

fn to_string(files: List(File), acc: String) -> String {
  case files {
    [] -> string.append(acc, "\n")
    [#(id, size, space), ..files] -> {
      let acc =
        acc
        |> string.append(
          list.range(0, size - 1)
          |> list.map(fn(_) { id |> int.to_string })
          |> string.concat,
        )

      let acc = case space {
        0 -> acc
        space ->
          acc
          |> string.append(
            list.range(0, space - 1)
            |> list.map(fn(_) { "." })
            |> string.concat,
          )
      }

      to_string(files, acc)
    }
  }
}
