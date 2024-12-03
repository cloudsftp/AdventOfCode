import gleam/bool
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Error {
  ReadingError(simplifile.FileError)
  NoDigitsInLine(String)
  NoLines
}

pub fn main() {
  let result = calculate("input.txt")
  let _ = io.debug(result)
}

pub fn read_input(file: String) -> Result(List(String), simplifile.FileError) {
  use content <- result.map(simplifile.read(file))
  let lines = string.split(content, on: "\n")

  use line <- list.filter(lines)
  !string.is_empty(line)
}

fn calculate(file: String) -> Result(Int, Error) {
  use lines <- result.try(
    file
    |> read_input()
    |> result.map_error(ReadingError),
  )

  use values <- result.try(
    lines
    |> list.map(to_value)
    |> result.all,
  )

  values
  |> list.reduce(fn(a, b) { a + b })
  |> result.replace_error(NoLines)
}

fn to_value(line: String) -> Result(Int, Error) {
  let digits = to_digits(line)

  use first <- result.try(
    list.first(digits)
    |> result.replace_error(NoDigitsInLine(line)),
  )
  use last <- result.map(
    list.last(digits)
    |> result.replace_error(NoDigitsInLine(line)),
  )

  first * 10 + last
}

fn to_digits(line: String) -> List(Int) {
  let chars =
    line
    |> string.to_graphemes

  to_digits_recursive(chars)
}

fn to_digits_recursive(chars: List(String)) -> List(Int) {
  use <- bool.guard(list.is_empty(chars), [])
  let digit = prefix_digit(chars)

  let rest =
    chars
    |> list.drop(1)
    |> to_digits_recursive

  case digit {
    Error(_) -> rest
    Ok(digit) -> [digit, ..rest]
  }
}

fn prefix_digit(chars: List(String)) -> Result(Int, Nil) {
  case chars {
    ["o", "n", "e", ..] -> Ok(1)
    ["t", "w", "o", ..] -> Ok(2)
    ["t", "h", "r", "e", "e", ..] -> Ok(3)
    ["f", "o", "u", "r", ..] -> Ok(4)
    ["f", "i", "v", "e", ..] -> Ok(5)
    ["s", "i", "x", ..] -> Ok(6)
    ["s", "e", "v", "e", "n", ..] -> Ok(7)
    ["e", "i", "g", "h", "t", ..] -> Ok(8)
    ["n", "i", "n", "e", ..] -> Ok(9)
    ["z", "e", "r", "o", ..] -> Ok(0)
    [c, ..] -> digit_value(c)
    _ -> Error(Nil)
  }
}

fn digit_value(char: String) -> Result(Int, Nil) {
  let chars = string.to_utf_codepoints(char)
  use char <- result.try(
    chars
    |> list.first
    |> result.map(string.utf_codepoint_to_int),
  )

  use <- bool.guard(!{ 48 <= char && char <= 57 }, Error(Nil))
  Ok(char - 48)
}
