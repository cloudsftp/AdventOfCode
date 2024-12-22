import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import rememo/memo
import simplifile

pub fn main() {
  let assert Ok(content) = simplifile.read("input")

  let assert Ok(initial_values) =
    content
    |> string.split(on: "\n")
    |> list.filter(fn(line) { !string.is_empty(line) })
    |> list.map(int.parse)
    |> result.all

  let result =
    initial_values
    |> list.map(step_2000)
    |> int.sum

  io.debug(result)
}

const mask = 16_777_215

fn step(number: Int) -> Int {
  let shifted = number |> int.bitwise_shift_left(6)
  let number = number |> int.bitwise_exclusive_or(shifted)
  let number = number |> int.bitwise_and(mask)

  let shifted = number |> int.bitwise_shift_right(5)
  let number = number |> int.bitwise_exclusive_or(shifted)
  let number = number |> int.bitwise_and(mask)

  let shifted = number |> int.bitwise_shift_left(11)
  let number = number |> int.bitwise_exclusive_or(shifted)
  let number = number |> int.bitwise_and(mask)

  number
}

fn step_2000(initial_value: Int) -> Int {
  step_2000_rec(initial_value, 0)
}

fn step_2000_rec(current_value: Int, counter: Int) -> Int {
  use <- bool.guard(counter == 2000, current_value)

  step_2000_rec(step(current_value), counter + 1)
}
