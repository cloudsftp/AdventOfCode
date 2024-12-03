import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  use content <- result.map(read_input("input"))

  use pairs <- result.map(
    list.map(content, fn(line) {
      line
      |> string.split(on: " ")
      |> list.filter(fn(part) { !string.is_empty(part) })
      |> list.map(int.parse)
      |> result.all
    })
    |> result.all,
  )

  use pairs <- result.map(
    pairs
    |> list.map(fn(part_list) {
      use first <- result.try(list.first(part_list))
      use last <- result.map(list.last(part_list))
      #(first, last)
    })
    |> result.all,
  )

  let #(lista, listb) = split_pairs(pairs)

  let count = count_occurrences(listb)

  let result =
    lista
    |> list.map(fn(value) {
      count
      |> dict.get(value)
      |> result.map(fn(count) { value * count })
      |> result.unwrap(0)
    })
    |> int.sum
  io.debug(result)
}

fn count_occurrences(values: List(Int)) -> dict.Dict(Int, Int) {
  case values {
    [] -> dict.new()
    [first, ..rest] -> {
      use opt_value <- dict.upsert(count_occurrences(rest), first)
      opt_value
      |> option.map(fn(value) { value + 1 })
      |> option.unwrap(1)
    }
  }
}

fn split_pairs(pairs: List(#(Int, Int))) -> #(List(Int), List(Int)) {
  case pairs {
    [] -> #([], [])
    [first, ..rest] -> {
      let #(lista, listb) = split_pairs(rest)
      let #(a, b) = first

      #(list.prepend(lista, a), list.prepend(listb, b))
    }
  }
}

pub fn read_input(file: String) -> Result(List(String), simplifile.FileError) {
  use content <- result.map(simplifile.read(file))
  let lines = string.split(content, on: "\n")

  use line <- list.filter(lines)
  !string.is_empty(line)
}
