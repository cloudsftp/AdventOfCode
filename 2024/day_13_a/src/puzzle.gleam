import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Position =
  #(Int, Int)

type Game {
  Machine(button_a: Position, button_b: Position, target: Position)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("input.small")
  let assert machines =
    content
    |> string.split(on: "\n")
    |> list.fold([[]], fn(acc, line) {
      let assert [current, ..rest] = acc

      case line |> string.is_empty {
        False -> {
          let current = [line, ..current]
          [current, ..rest]
        }
        True -> [[], ..acc]
      }
    })
    |> list.filter(fn(element) { !{ element |> list.is_empty } })
    |> list.map(parse_machine)

  let result =
    machines
    |> list.map(score)
    |> int.sum

  io.debug(result)
}

fn score(machine: Game) -> Int {
  machine
  |> score_recurse(0, #(0, 0))
  |> option.map(cost)
  |> option.unwrap(0)
}

fn score_recurse(
  machine: Game,
  iteration: Int,
  presses: #(Int, Int),
) -> option.Option(#(Int, Int)) {
  io.debug(iteration)
  use <- bool.guard(
    machine |> position(presses) == machine.target,
    option.Some(presses),
  )

  let #(current_x, current_y) = machine |> position(presses)
  let #(target_x, target_y) = machine.target

  use <- bool.guard(current_x > target_x || current_y > target_y, option.None)
  use <- bool.guard(iteration == 100, option.None)

  let #(a, b) = presses
  let left = score_recurse(machine, iteration + 1, #(a + 1, b))
  let right = score_recurse(machine, iteration + 1, #(a, b + 1))

  case left, right {
    option.None, option.None -> option.None
    option.None, option.Some(presses) -> option.Some(presses)
    option.Some(presses), option.None -> option.Some(presses)
    option.Some(left), option.Some(right) -> {
      use <- bool.guard(cost(left) <= cost(right), option.Some(left))
      option.Some(right)
    }
  }
}

fn position(machine: Game, presses: #(Int, Int)) -> #(Int, Int) {
  let #(a, b) = presses
  let #(xa, ya) = machine.button_a
  let #(xb, yb) = machine.button_b

  #(a * xa + b * xb, a * ya + b * yb)
}

fn cost(presses: #(Int, Int)) -> Int {
  let #(presses_a, presses_b) = presses
  3 * presses_a + presses_b
}

fn parse_machine(lines: List(String)) -> Game {
  let assert [line3, line2, line1] = lines
  Machine(
    button_a: parse_button(line1),
    button_b: parse_button(line2),
    target: parse_target(line3),
  )
}

fn parse_button(line: String) -> Position {
  let assert [_, _, x_part, y_part] =
    line
    |> string.replace(",", "")
    |> string.split(on: " ")

  let extract_number = fn(part) {
    let assert Ok(#(_, number)) = part |> string.split_once(on: "+")
    let assert Ok(number) = number |> int.parse
    number
  }

  #(extract_number(x_part), extract_number(y_part))
}

fn parse_target(line: String) -> Position {
  let assert [_, x_part, y_part] =
    line
    |> string.replace(",", "")
    |> string.split(on: " ")

  let extract_number = fn(part) {
    let assert Ok(#(_, number)) = part |> string.split_once(on: "=")
    let assert Ok(number) = number |> int.parse
    number
  }

  #(extract_number(x_part), extract_number(y_part))
}
