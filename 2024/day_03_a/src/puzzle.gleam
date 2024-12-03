import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  use content <- result.map(simplifile.read("input.small"))

  io.debug(content)

  let result = 0

  io.debug(result)
}
