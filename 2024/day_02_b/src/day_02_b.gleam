import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  use content <- result.map(read_input("input"))
  use reports <- result.map(
    content
    |> list.map(fn(line) {
      line
      |> string.split(on: " ")
      |> list.map(fn(level) { int.parse(level) })
      |> result.all()
    })
    |> result.all(),
  )

  let result =
    reports
    |> list.count(dampened_is_safe)

  io.debug(result)
}

pub fn dampened_is_safe(levels: List(Int)) -> Bool {
  is_safe(levels) || dampened_records(levels) |> list.any(is_safe)
}

pub fn dampened_records(levels: List(Int)) -> List(List(Int)) {
  list.range(0, list.length(levels))
  |> list.map(fn(i) {
    list.append(list.take(levels, i - 1), list.drop(levels, i))
  })
}

pub fn is_safe(levels: List(Int)) -> Bool {
  let differences = compute_differences(levels)

  let in_range =
    differences
    |> list.map(int.absolute_value)
    |> list.all(fn(value) { 1 <= value && value <= 3 })

  let same_sign = has_same_sign(differences)

  in_range && same_sign
}

fn has_same_sign(differences: List(Int)) -> Bool {
  has_same_sign_recurse(differences, 0)
}

fn has_same_sign_recurse(differences: List(Int), sign: Int) -> Bool {
  case differences {
    [] -> True
    [value, ..differences] -> {
      use <- bool.guard(sign == 0, has_same_sign_recurse(differences, value))
      use <- bool.guard(sign * value < 0, False)
      has_same_sign_recurse(differences, value)
    }
  }
}

fn compute_differences(levels: List(Int)) -> List(Int) {
  let intermediate =
    levels
    |> list.fold_right(#([], option.None), fn(acc, value) {
      let #(differences, last_value) = acc

      case last_value {
        option.None -> #(differences, option.Some(value))
        option.Some(last_value) -> #(
          list.prepend(differences, last_value - value),
          option.Some(value),
        )
      }
    })

  let #(differences, _) = intermediate

  differences
}

pub fn read_input(file: String) -> Result(List(String), simplifile.FileError) {
  use content <- result.map(simplifile.read(file))
  let lines = string.split(content, on: "\n")

  use line <- list.filter(lines)
  !string.is_empty(line)
}
